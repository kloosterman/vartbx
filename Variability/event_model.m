%_______________________________________________________________________
%
% Compute a beta image for LS-S
%_______________________________________________________________________
%
% Input
%
% ...
%
%_______________________________________________________________________
%
% Output
%
% ...
%
%_______________________________________________________________________
%
% This file is part of the Variability Toolbox for SPM
% Published by the Lifespan Neural Dynamics Group
% Provided under the GNU General Public License
% See LICENSE for terms and conditions
function beta_img = event_model(model, sess_beta, batch_beta, coord, tmp_dir, isdryrun)

  cfg = shared_config;
  logger = shared_logger.getLogger();
  
  time_model = tic;

  %%
  %% one model for each trial of current condition over all sessions
  %%
  sess_beta.cond(1).name = 'interest';
  sess_beta.cond(1).onset = model.interest.onset;
  sess_beta.cond(1).duration = model.interest.duration;
  sess_beta.cond(2).name = 'nuisance';
  sess_beta.cond(2).onset = model.nuisance.onset;
  sess_beta.cond(2).duration = model.nuisance.duration;

  %%
  %% compute design matrix
  %%
  if not(isdryrun)

    %%
    %% avoid interactive overwrite warning during evalc
    %%
    if exist(fullfile(tmp_dir,'SPM.mat'))
        delete(fullfile(tmp_dir,'SPM.mat'));
    end

    batch_beta{1}.spm.stats.fmri_spec.dir{1} = tmp_dir;
    batch_beta{1}.spm.stats.fmri_spec.sess(1) = sess_beta;

    %%
    %% disable progress window updates
    %%
    if cfg.gui
      fig = spm_figure('FindWin','Interactive');
      set(fig,'Tag','Interactive_Protected');
    end
  
    %%
    %% hide output to avoid cluttering the terminal
    %%
    if logger.consoleLevel <= logger.DEBUG
      design = spm_jobman('serial', batch_beta);
    else
      try
        [cmd_log, design] = evalc('spm_jobman(''serial'', batch_beta)');
      catch e
        fprintf('\n\n')
        error(lasterr)
      end
    end

    %%
    %% re-enable progress window updates
    %%
    if cfg.gui
      set(fig,'Tag','Interactive');
    end
  
  end

  %%
  %% estimate model
  %%
  if not(isdryrun)
    
    %% copy every nifty into subdirectory (except SPM.mat)
    
    mkdir([tmp_dir,'/temp']);
    tmp_files = dir([tmp_dir, '/*.nii']);
    if size(tmp_files,1)>0
        movefile([tmp_dir, '/*.nii'], [tmp_dir, '/temp/'])
    end
    
    %% set up estimation
      
    estimate{1}.spm.stats.fmri_est.spmmat = design{1}.spmmat;
    estimate{1}.spm.stats.fmri_est.method.Classical = 1;

    %%
    %% disable progress window updates
    %%
    if cfg.gui
      fig = spm_figure('FindWin','Interactive');
      set(fig,'Tag','Interactive_Protected');
    end

    %%
    %% hide output to avoid cluttering the terminal
    %%
    if logger.consoleLevel <= logger.DEBUG
      spm_jobman('serial', estimate)
    else
      try
        cmd_log = evalc('spm_jobman(''serial'', estimate)');
      catch e
        fprintf('\n\n')
        error(lasterr)
      end
    end
  
    %%
    %% re-enable progress window updates
    %%
    if cfg.gui
      set(fig,'Tag','Interactive');
    end
  
  end

  %%
  %% concatenate beta images of current condition
  %%
  if not(isdryrun)
    SPM = load(fullfile(tmp_dir,'SPM.mat')); SPM = SPM.SPM;
    beta_file = fullfile(tmp_dir, SPM.Vbeta(1).fname);
    beta_hdr = spm_vol(beta_file);
    beta_vol = spm_read_vols(beta_hdr);
    beta_img = beta_vol(coord);
  else
    beta_img = rand(size(coord));
  end

end
