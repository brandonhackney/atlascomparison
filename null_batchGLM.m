function null_batchGLM(subList,varargin)
% Wrapper function to calculate multi-run GLMs as needed for diceBatch2
% Exports t-statistic maps and degrees of freedom, but doesn't do FDR yet
% Avoids using any atlas info, which is now done in subsetGLM() for speed
% Before GLM calc, pred matrix is cond x vertex, vcat by run

% INPUTS:
% subList is a vector of subject ID numbers ('STS' prefix is added within)

fprintf(1,'Initializing null_batchGLM...')

% GET TASK INFO FOR FILENAMES
    conditionList = importdata('getFilePartsFromContrast.mat');
    numCont = length(conditionList); % number of contrasts

% Navigate to data folder
paths = specifyPaths;
homeDir = paths.basePath;
dataDir = paths.deriv;
cd(dataDir);

% parse varargin
if ~isempty(varargin)
    assert(islogical(varargin{1}),'Randomizer flag must be type logical!');
    randomize = varargin{1};
else
    randomize = false;
end


fprintf(1,'Done.\n')

for s = 1:length(subList)
    subjectNumber = subList(s);
    % Convert subject number into ID
    subj = strcat('STS',num2str(subjectNumber));
    subjdir = [dataDir filesep subj filesep];
    cd(subjdir)
    clear GLM

    fprintf(1,'\nSubject %s:',subj)
    for t = 1:numCont
        taskName = conditionList(t).sdm;
        f = dir(['sub-STS-' num2str(subjectNumber) '*' taskName '*.sdm']);
        % Get the predictor matrix for all runs (i.e. concatenated)
        pred = [];
        for r = 1:length(f)
            file = xff(f(r).name);
            temppred = file.SDMMatrix;
            % Add run info
            [~, xW] = size(temppred);
            temppred(:,xW + 1) = r;
            pred = [pred;temppred];
            file.clearobj; 
        end % for r
        clear temppred
        % Convert run numbers to a binary matrix
        pred = convertRunCol(pred);

        hemstr = {'lh','rh'}; hemstr2 = {'LH','RH'};
        for h = 1:2
            hem = hemstr{h};
            % Get MTC patterns and concatenate
            condName = conditionList(t).mtc;
            contName = conditionList(t).contrast;
            clear f;
            f = dir(['*' condName '*' hem '.mtc']);
            if isempty(f)
                % Probably bc it uses 'LH' instead of 'lh', so try this
                % Specific to STS7, 14, and 17. But I like flexiblility
                hem = hemstr2{h};
                f = dir(['*' condName '*' hem '.mtc']);
            end
            pattern = [];
            for r = 1:length(f)
                file = xff(f(r).name);
                numVert = length(file.MTCData);
                
                thisData = file.MTCData;
                if randomize
                    % Replace data with random noise, of similar SD
                    thisData = random('Normal',0,std(thisData,1,'all'),size(thisData));
                else
                    % Mean-center each voxel within each run
                    thisData = thisData - mean(thisData, 1);
                end
                pattern = [pattern; thisData];
                file.clearobj;
            end % for r
            clear thisData
            
            fprintf(1,'\n\tCalculating GLMs for condition %s %s...',contName,hem)
                %tic

            [posInd,negInd] = getConditionFromFilename(contName);
            contrast = getContrastVector(size(pred,2),posInd,negInd);
            % Calculate t-statistic map
            % skip saving the whole-brain betas and residuals
            [tMap,~,~] = simpleGLM(pattern,pred,contrast);
                tMap = single(tMap'); % conversion of simpleGLM output to match getGLM
                %toc

            % Calculate degrees of freedom for later FDR thresholding
            df = size(pattern,1) - length(posInd) - length(negInd);

            % Export significant vertices for Dice coefficient
            GLM.task(t).name = conditionList(t).contrast;
            GLM.task(t).hem(h).name = hem;
            GLM.task(t).hem(h).numVert = length(tMap);
            GLM.task(t).hem(h).tMap = tMap; % may slow things down
            GLM.task(t).hem(h).df = df;

            fprintf(1,'Done.')
        end % for h
    end % for t
    
    outpath = [homeDir filesep 'ROIs' filesep 'GLM' filesep subj '_GLMs.mat'];
    fprintf(1,'\nSubject %s done. Exporting to %s', subj, outpath);
    save(outpath,'GLM');
    fprintf(1,'...Done.\n');
end % for s
xff(0,'clearallobjects')
cd(homeDir)
fprintf(1,'\nGLM estimation complete for %i subjects.\n', length(subList))
end
