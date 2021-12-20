%_______________________________________________________________________
%
% Merge image data of all sessions condition-wise
%_______________________________________________________________________
%
% Input
%
%  session | session data of first-level design (struct)
%    index | condition-wise scan indices (3D cell array)
%    coord | mask for image data (double vector)
%
%_______________________________________________________________________
%
% Output
%
% img | condition-wise arranged image data (2D cell array)
%
%_______________________________________________________________________
%
% This file is part of the Variability Toolbox for SPM
% Published by the Lifespan Neural Dynamics Group
% Provided under the GNU General Public License
% See LICENSE for terms and conditions

function img = block_merge(session, index, coord)

  %%
  %% retrieve total number of blocks per condition
  %%
  cnd_blk_total = zeros(numel(index),1);
  for sess = 1:numel(session)
    for cnd = 1:numel(index)
      cnd_blk_total(cnd) = cnd_blk_total(cnd) + numel(index{cnd}{sess});
    end
  end

  for cnd = 1:numel(index)
    img{cnd} = cell(cnd_blk_total(cnd),1);
    blk_count{cnd} = 0;
  end

  %%
  %% session-wise loading avoids high memory peaks
  %%
  for sess = 1:numel(session)

    scan_img = block_load_data(session, sess, coord);

    %%
    %% check for embedded regressors
    %%
    if isfield(session(sess),'regress') ...
    && isstruct(session(sess).regress) ...
    && numel(session(sess).regress) >= 1
      regress_data = session(sess).regress;
      validate_regressor(regress_data, scan_img);
      embedded_regressor = [regress_data.val];
    end

    %%
    %% check for external regressors
    %%
    %% The regressor can be either stored in a Matlab data file (.mat)
    %% as a matrix named R or in a multi-column plain text file (.txt)
    %% SPM only allows a single file so we stick with that convention
    %%
    if isfield(session(sess),'multi_reg')

      regressor_file = [];
      if iscell(session(sess).multi_reg)
        if numel(session(sess).multi_reg) == 1 ...
        && not(isempty(session(sess).multi_reg{1}))
          if ischar(session(sess).multi_reg{1})
            regressor_file = session(sess).multi_reg{1};
          else
            error('Invalid type: multi_reg (requires string)')
          end
        end
      elseif ischar(session(sess).multi_reg)
       if not(isempty(session(sess).multi_reg))
         regressor_file = session(sess).multi_reg;
       end
      else
        error('Invalid type: multi_reg (requires string)')
      end

      if not(isempty(regressor_file))
        if exist(regressor_file, 'file')
          [~,~,extension] = fileparts(regressor_file);
          if strcmp(extension,'mat')
            regress_struct = load(regressor_file, 'R');
            if exist(regress_struct,'R')
              regress_data = regress_struct.R;
            end
          else
            regress_data = csvread(regressor_file);
          end
          validate_regressor(regress_data, scan_img);
          external_regressor = regress_data;
        else
          error('Regressor file not found: %s', regressor_file)
        end
      end

    end

    %%
    %% merge embedded and external regressors
    %%
    regressor = [];
    if exist('embedded_regressor')
      regressor = [regressor embedded_regressor];
    end
    if exist('external_regressor')
      regressor = [regressor external_regressor];
    end

    %%
  	%% residualize if regressors have been specified
    %%
    if not(isempty(regressor))
      scan_img = block_residualize(scan_img, regressor, sess);
    end

    %%
    %% merge blocks condition-wise
    %%
  	for cnd = 1:numel(index)
  		for blk = 1:numel(index{cnd}{sess})

        %%
        %% image data of current condition, session and block
        %%
  			block_img = scan_img(index{cnd}{sess}{blk},:);

        %%
  			%% normalize to block global mean
        %%
  			block_img = 100 * block_img / mean(mean(block_img));

        %%
        %% using cell array to delay detrending
        %%
        cur_blk = blk_count{cnd} + blk;
        num_scan = size(block_img, 2);
        img{cnd}{cur_blk} = block_img;
        img{cnd};

  		end % block
      blk_count{cnd} = blk_count{cnd} + numel(index{cnd}{sess});
  	end % condition
  end % session
end

%%
%% checks if structure or matrix contains a valid set of regressors
%%
function validate_regressor(regress_data, scan_img)

  if isstruct(regress_data)
    num_col = numel(regress_data); % session(sess).regress
  else
    num_col = size(regress_data,2);
  end

  for col = 1:num_col

    if isstruct(regress_data)
      regress_col = regress_data(col).val;
    else
      regress_col = regress_data(:, col);
    end
  
    if not(isnumeric(regress_col))
      msg = 'Regressor field contains non-numerical data';
      error(msg)
    end

    num_scan_regress = size(regress_col,1);
    num_scan_image = size(scan_img,1);

    if not(num_scan_regress == num_scan_image)
      msg = 'Differing number of scans in image data and regressor field ';
      msg = [msg sprintf('(%i vs. %i)', num_scan_image, num_scan_regress)];
      error(msg)
    end

  end % col
end

