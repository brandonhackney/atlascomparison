function [X, nTrials] = constructGLM(prt, NumVols, varargin)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here


    TR =2; %hardcoded -- red flag!! 

    %check to see if nuisance predictors should be included
    if nargin > 2
        nuisance = varargin{1};
    else
        nuisance = [];
    end


     hrf = twoGammaHrf( 30, .1, 0, 6, 16, ...
        1, 1, 6, 3 );
    % Scale hrf so when convolved with really long boxcar
    %   it will saturate at height of 1
    hrf = hrf/sum(hrf);
    
    Boxcar_template = [0 : .1 : NumVols*TR - TR ];
    NumTpts_upsamp = length(Boxcar_template);
    
    
    % Construct LSA regressor matrix, one predictor matrix per event
    temp = []; Xlabel = [];
    cOut = 0; nTrials = 0;
    NumConds = size(prt, 2);  %make sure to omit fixation condition
    for c = 1:NumConds

        if strcmpi(prt(c).ConditionName, 'fixation') == 0 
            cOut = cOut + 1;
            events = prt(c).OnOffsets;
            NumBlocks = size(events, 1);
            X.condNames(cOut) = prt(c).ConditionName;
        
            for b = 1:NumBlocks

                nTrials = nTrials+1;
                boxcar = zeros(1, NumTpts_upsamp);
                boxcar(Boxcar_template >= events(b, 1)*TR & Boxcar_template <= events(b, 2)*TR) = ones;

                pred = conv(hrf,boxcar);
                pred = pred(1:NumTpts_upsamp);
                pred = pred(1:20:end);  %downsample, for TR = 2;
                
                X_cond(:,b) = pred;
                Xlabel = [Xlabel; cOut];
                % use cOut instead of c to avoid reordering issue
            end
        
            temp = [temp X_cond];

        end
        X.preds = [temp nuisance];
        X.label = Xlabel;
    end
end

