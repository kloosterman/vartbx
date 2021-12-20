%_______________________________________________________________________
%
% Wrapper for initializing the Parallel Computing Toolbox
%_______________________________________________________________________
%
% Input
%
% action | choose 'open' or 'close' (string)
%
%_______________________________________________________________________
%
% Output
%
% isparallel | parallel pool is available (boolean)
%
%_______________________________________________________________________
%
% This file is part of the Variability Toolbox for SPM
% Published by the Lifespan Neural Dynamics Group
% Provided under the GNU General Public License
% See LICENSE for terms and conditions
function isparallel = shared_parpool(action)

  if not(exist('action','var')) || isempty(action)
    action = 'open';
  else
    if not(ischar(action))
      error('Invalid type: action (requires string)')
    end
  end

  %
  % open worker pool
  %
  if strcmp(action,'open')

    if verLessThan('matlab', '8.2') % R2013a and prior
      if not(matlabpool('size'))
        try
          % workaround to avoid a warning in Matlab 2013a
          warning('off','MATLAB:class:errorParsingClass')
          matlabpool('open');
        catch
          lastmsg = lasterr;
          msg = 'Opening of worker pool failed.\n\n';
          msg = [msg 'Matlab R2013a and prior might require a patch for the Parallel Computing Toolbox.\n'];
          msg = [msg 'For further information see: http://www.mathworks.com/support/bugreports/919688\n'];
          fprintf('\n'); warning(sprintf(msg))
        end
      end
    else % R2013b and beyond
      if isempty(gcp('nocreate'))
        % workaround to avoid a warning in Matlab 2014b
        warning('off','parallel:cluster:DepfunError')
        if isempty(gcp('nocreate'))
          try
            myCluster = parcluster('local');
            myCluster.NumWorkers = 4;
            parpool(myCluster, 4);
          catch
            msg = 'Opening of worker pool failed.';
            fprintf('\n'); warning(sprintf(msg)); fprintf('\n')
          end
        end
      end
    end

  %
  % close worker pool
  %
  elseif strcmp(action,'close')

    if verLessThan('matlab', '8.2')
      if matlabpool('size')
        try
          matlabpool('close');
        catch
          % maybe suggest patch: http://www.mathworks.com/support/bugreports/919688
          warning('Closing of worker pool failed.')
        end
      end
    else
      delete(gcp('nocreate'))
    end

  else
    error('invalid action (''open'' or ''close'').')
  end

end
