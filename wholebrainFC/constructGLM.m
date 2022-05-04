function [X] = constructGLM(prt, NumVols, varargin)

% A function to compute a standard GLM, one predictor for condition (minus
% fixation) to test the Matlab output against the BV output.

TR =2; %hardcoded -- red flag!!

%check to see if nuisance predictors should be included
if nargin > 2
    nuisance = varargin{1};
else
    nuisance = [];
end

% build the template HRF (high temporal resolution)
hrf = twoGammaHrf( 30, .1, 0, 6, 16, ...
    1, 1, 6, 3 );
hrf = hrf/sum(hrf); % Scale hrf so when convolved with really long boxcar it will saturate at height of 1
Boxcar_template = [0 : .1 : NumVols*TR - TR ];
NumTpts_upsamp = length(Boxcar_template);


% Construct GLM regressor matrix, one predictor per condition
temp = []; Xlabel = [];
cOut = 0;
NumConds = size(prt, 2); 
for c = 1:NumConds
    
    if strcmpi(prt(c).ConditionName, 'fixation') == 0   %omit fixation condition
        cOut = cOut + 1;
        events = prt(c).OnOffsets;
        NumBlocks = size(events, 1);
        X.condNames(cOut) = prt(c).ConditionName;
        
        %build boxcar
        boxcar = zeros(1, NumTpts_upsamp);
        for b = 1:NumBlocks
            boxcar(Boxcar_template >= events(b, 1)*TR & Boxcar_template <= events(b, 2)*TR) = ones;
        end
        
        %convolve with HRF, then downsample
        pred = conv(hrf,boxcar);
        pred = pred(1:NumTpts_upsamp);
        pred = pred(1:20:end);  %downsample, for TR = 2;
        
        %save
        X_cond(:,cOut) = pred;
        Xlabel = [Xlabel; cOut];    
    end
    
    X.preds = [X_cond nuisance ones(size(pred, 1), 1)];
    X.label = Xlabel;
    X.nTrials = cOut;
end


