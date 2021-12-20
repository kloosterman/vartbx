%_______________________________________________________________________
%
% Compute condition-wise variability for a first-level design
%_______________________________________________________________________
%
% Input
%
% job | batch job generated by tbx_cfg_variability (struct)
%
%_______________________________________________________________________
%
% Output
%
% result | batch job with result file paths (struct)
%
%_______________________________________________________________________
%
% This file is part of the Variability Toolbox for SPM
% Published by the Lifespan Neural Dynamics Group
% Provided under the GNU General Public License
% See LICENSE for terms and conditions

function result = tbx_run_variability(job)

cfg = shared_config;

%%
%% sanitize function parameters
%%
if ~exist('job','var') || isempty(job)
  error('Missing or emtpy function parameter: job')
else
  if ~isstruct(job)
    error('Invalid type: job (requires struct)')
  end
end

if ~isfield(job,'modeltype') || isempty(job.modeltype)
  error('Missing or empty field: job.modeltype')
else
  if ~isstr(job.modeltype)
    error('Invalid type: modeltype (requires string)')
  end
  if ~ismember(cfg.modeltype, job.modeltype)
    error('Invalid content: job.modeltype')
  end
end

if strcmp(job.modeltype,'lss')
  result = event_var(job);
elseif strcmp(job.modeltype,'boxcar')
  result = block_var(job);
else
  error('Invalid model type.')
end