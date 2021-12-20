%_______________________________________________________________________
%
% Configuration and helper functions
%_______________________________________________________________________
%
% Output
%
% cfg | toolbox configuration (struct)
%
%_______________________________________________________________________
%
% This file is part of the Variability Toolbox for SPM
% Published by the Lifespan Neural Dynamics Group
% Provided under the GNU General Public License
% See LICENSE for terms and conditions

function cfg = shared_config

	%%
	%% release information
	%%
  cfg.name = 'Variability Toolbox for SPM';
  cfg.version = '0.2dev';

	%%
	%% formatting
	%%
	cfg.pad = 30;
  cfg.format = '\fontsize{16}';

  %%
  %% modeling
  %%
  cfg.modeltype = {'boxcar', 'lss'};
  cfg.metric = {'var', 'sd', 'mssd', 'sqrt_mssd'};

  %%
  %% is graphical interface available?
  %%
  if usejava('jvm') && feature('ShowFigureWindows');
    cfg.gui = true;
  else
    cfg.gui = false;
  end

  %%
  %% miscellaneous debugging options
  %%
  cfg.parallel = true; % use parallel computing toolbox
  cfg.testing = false; % use only a small subset of the data
  cfg.dryrun = false; % execute workflow but don't compute models
  cfg.keeptemp = false; % keep all intermediate results
  
  %%
  %% Initialize logger and set verbosity level (INFO/DEBUG/OFF)
  %%
  logger = shared_logger.getLogger();
  logger.setConsoleLevel(logger.INFO)
  logger.setLogLevel(logger.OFF)

  %%
  %% is the matlab desktop running?
  %%
  if cfg.gui && desktop('-inuse')
    cfg.desktop = true;
  else
    cfg.desktop = false;
  end
  
  %%
  %% is spm running?
  %%
  if cfg.gui && not(isempty(spm_figure('FindWin','Menu')))
    cfg.spm = true;
  else
    cfg.spm = false;
  end

end
