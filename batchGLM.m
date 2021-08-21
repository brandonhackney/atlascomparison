function output = batchGLM(subList)
% Wrapper function to calculate multi-run GLMs
% (likely going to end up having multiple functions called in this block)
% Once GLM data is extracted, threshold it and define functional regions
% Send those ROIs to diceParcel to compare against parcels
% Also outputs a struct with the whole-brain data per task per subject

fprintf(1,'Initializing...')
%% GET TASK INFO FOR FILENAMES
    load('getFilePartsFromContrast.mat')
    numCont = length(conditionList); % number of contrasts
%% 

% Navigate to data folder
homeDir = pwd;
addpath(homeDir); % ensures other functions are available
cd .. % Move from /analysis/ to project root
cd(['data' filesep 'deriv'])
dataDir = pwd; % Base location of all subject folders
fprintf(1,'Done.\n')

for s = 1:length(subList)
    subjectNumber = subList(s);
    % Convert subject number into ID
    subj = strcat('STS',num2str(subjectNumber));
    cd([dataDir filesep subj])
    
    fprintf(1,'\nSubject %s:',subj)
    for t = 1:numCont
        taskName = conditionList(t).sdm;
        f = dir(['sub-STS-' num2str(subjectNumber) '*' taskName '*.sdm']);
        % Get the predictor matrix for all runs (i.e. concatenated)
        pred = [];
        for r = 1:length(f)
            file = xff(f(r).name);
            pred = [pred;file.SDMMatrix];
            file.clearobj; 
        end % for r
        % Add run info

        % Convert run numbers to a binary matrix
        pred = convertRunCol(pred);
        for h = 1:2
            if h == 1
                hem = 'lh';
            elseif h == 2
                hem = 'rh';
            end
        
            % Get MTC patterns and concatenate
            condName = conditionList(t).mtc;
            clear f; f = dir(['*' condName '*' hem '.mtc']);
            pattern = [];
            for r = 1:length(f)
                file = xff(f(r).name);
                pattern = [pattern; file.MTCData];
                file.clearobj;
            end % for r
            
            fprintf(1,'\n\tCondition %s %s...',condName,hem)
                %tic
            % Calculate betas and residuals
            output.task(t).taskname = condName;
            output.task(t).sub(s).hem(h).name = hem;
            [posInd,negInd] = getConditionFromFilename(conditionList(t).contrast);
%             [output.task(t).sub(s).hem(h).data, fMap] = getGLM(pattern,pred,posInd,negInd);
            [fMap,output.task(t).sub(s).hem(h).data.beta,output.task(t).sub(s).hem(h).data.residuals] = simpleGLM(pattern,pred,getContrastVector(size(pred,2),posInd,negInd));
                fMap = single(fMap'); % conversion of simpleGLM output to match getGLM
                %toc
            
            % Export data to an SMP file
            SMP = xff('new:smp');
            SMP.NrOfVertices = length(fMap);
            SMP.NameOfOriginalSRF = [dataDir filesep subj filesep subj '-Freesurfer' filesep subj '-Surf2BV' filesep subj '_' hem '_smoothwm.srf'];
            SMP.Map.SMPData = fMap;
            SMP.Map.Name = conditionList(t).contrast;
            SMP.Map.DF1 = size(pattern,1) - length(posInd) - length(negInd);
            SMP.Map.BonferroniValue = length(fMap);
            
            SMP.SaveAs([dataDir filesep subj filesep subj '_' condName '_' hem '.smp']);
            SMP.clearobj;
            fprintf(1,'Done.')
        end % for h
    end % for t
    fprintf(1,'\nSubject %s done.\n',subj);
end % for s
xff(0,'clearallobjects')
cd(homeDir)
fprintf(1,'\nGLM estimation complete for %i subjects.\n', length(subList))
end
