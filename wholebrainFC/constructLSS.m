function [X] = constructLSS(prt, NumVols, varargin)

% Computes trial-wise betas using the LSS approach

TR =2; %hardcoded -- red flag!!

%check to see if nuisance predictors should be included
if nargin > 2
    nuisance = varargin{1};
else
    nuisance = [];
end


%build a template HRF (high temporal resolution)
hrf = twoGammaHrf( 30, .1, 0, 4, 16, 1, 1, 6, 3 );
hrf = hrf/sum(hrf);  % Scale hrf so when convolved with really long boxcar it will saturate at height of 1
Boxcar_template = [0 : .1 : NumVols*TR - TR ];
NumTpts_upsamp = length(Boxcar_template);


% Construct boxcar model for each event (regress later), one predictor matrix per event
temp = []; Xlabel = [];
cOut = 0; trialIn = 0;
NumConds = size(prt, 2);  %make sure to omit fixation condition
for c = 1:NumConds
    
    if strcmpi(prt(c).ConditionName, 'fixation') == 0
        cOut = cOut + 1;
        events = prt(c).OnOffsets;
        NumBlocks = size(events, 1);
        X.condNames(cOut) = prt(c).ConditionName;
        
        % loop through each event of that condition, save labels
        for b = 1:NumBlocks
            trialIn = trialIn+1;
            boxcar(:, trialIn) = zeros(1, NumTpts_upsamp);
            boxcar(Boxcar_template >= events(b, 1)*TR & Boxcar_template <= events(b, 2)*TR, trialIn) = ones;
            Xlabel = [Xlabel; cOut];
        end
        
    end
end

% convolve and make 3D
nTrials = size(boxcar, 2);
for trial = 1:nTrials
    
    % start with the full matrix
    temp = boxcar;
    
    % isolate predictor of interest
    pred = conv(hrf,temp(:, trial));
    
    % all other trials
    temp(:, trial) = []; %remove trial of interest
    alltrials = sum(temp, 2);
    pred(:, 2) = conv(hrf, alltrials);
    
    %resample to units of volumes
    pred = pred(1:NumTpts_upsamp, :);
    pred = pred(1:20:end, :);  %downsample, for TR = 2;
    
    %append additional regressors and save
    X_cond(:, :, trial) = [pred nuisance ones(size(pred, 1), 1)]; %append 
    
end
X.preds = X_cond;
X.label = Xlabel;
X.nTrials = nTrials;


