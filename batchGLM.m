function output = batchGLM(subList, atlasList)
% Wrapper function to calculate multi-run GLMs
% Once GLM data is extracted, threshold it and define functional regions
% Send those ROIs to diceParcel to compare against parcels
% Also outputs a struct with the whole-brain data per task per subject
% BEWARE that uses up a TON of memory
% So if you don't NEED it, call without an output, and I can save memory.
%
% INPUTS:
% subList is a vector of subject ID numbers (prefix is added within)
% atlasList is a cell array

fprintf(1,'Initializing...')

%% GET TASK INFO FOR FILENAMES
    load('getFilePartsFromContrast.mat')
    numCont = length(conditionList); % number of contrasts
%% 

% Navigate to data folder
paths = specifyPaths;
homeDir = paths.basePath;
dataDir = paths.deriv;
cd(dataDir);
% homeDir = pwd;
% addpath(homeDir); % ensures other functions are available
% cd .. % Move from /analysis/ to project root
% cd(['data' filesep 'deriv'])
% dataDir = pwd; % Base location of all subject folders
fprintf(1,'Done.\n')

for a = 1:length(atlasList)
    atlasName = atlasList{a};
    fprintf(1,'\nAtlas %s:',atlasName)
    
    % Extract the parcel info for this atlas
    % We will only calculate betas within the selected parcels
    fname = [homeDir filesep 'class' filesep 'data' filesep 'Classify_meanB_' atlasName '.mat'];
    load(fname)
    
    for s = 1:length(subList)
        subjectNumber = subList(s);
        % Convert subject number into ID
        subj = strcat('STS',num2str(subjectNumber));
        cd([dataDir filesep subj])
        clear GLM
        
        for h = 1:2
            temp = [];
            for p = 1:length(Data.hemi(h).parcelInfo(s).parcels)
                temp = [temp; Data.hemi(h).parcelInfo(s).parcels(p).vertices];
            end
            glmMask(h).verts = sort(unique(temp)); % Sort so it's not in parcel order
        end
        clear temp

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
                maskPattern = [];
                for r = 1:length(f)
                    file = xff(f(r).name);
                    numVert = length(file.MTCData);
                    pattern = [pattern; file.MTCData];
                    % Truncate pattern to only use parcel vertices
%                     maskPattern = [maskPattern; file.MTCData(:,glmMask(h).verts)];
                    file.clearobj;
                end % for r

                fprintf(1,'\n\tCondition %s %s...',contName,hem)
                    %tic
                % Calculate betas and residuals
                output.task(t).taskname = contName;
                output.task(t).sub(s).hem(h).name = hem;
                [posInd,negInd] = getConditionFromFilename(contName);
                [tMap,output.task(t).sub(s).hem(h).data.beta,output.task(t).sub(s).hem(h).data.residuals] = simpleGLM(pattern,pred,getContrastVector(size(pred,2),posInd,negInd));
                    tMap = single(tMap'); % conversion of simpleGLM output to match getGLM
                    
                    % Save memory
                    if nargout < 1
                        clear output
                    end
                    % Truncate map to only use parcellated region
                    if length(glmMask(h).verts) == length(tMap)
                        fullMap = zeros([numVert,1]);
                        fullMap(glmMask(h).verts) = tMap;
                    else
                        fullMap = zeros([numVert,1]);
                        fullMap(glmMask(h).verts) = tMap(glmMask(h).verts);
                    end
                    %toc

                % Calculate t threshold from FDR
%                 df = size(pattern,1) - length(posInd) - length(negInd);
                df = size(pattern,1) - length(posInd) - length(negInd);
                [cluster,LowerThreshold] = fdrCluster(fullMap,df);

                % Export significant vertices for Dice coefficient
                GLM.task(t).name = conditionList(t).contrast;
                GLM.task(t).hem(h).name = hem;
                GLM.task(t).hem(h).cluster = cluster;
                GLM.task(t).hem(h).numVert = length(tMap);

                % Export data to an SMP file
                SMP = xff('new:smp');
                SMP.NrOfVertices = numVert;
                SMP.NameOfOriginalSRF = [dataDir filesep subj filesep subj '-Freesurfer' filesep subj '-Surf2BV' filesep subj '_' hem '_smoothwm.srf'];
                SMP.Map.SMPData = fullMap;
                SMP.Map.Name = conditionList(t).contrast;
                SMP.Map.DF1 = df;
                SMP.Map.BonferroniValue = length(tMap);
                SMP.Map.LowerThreshold = LowerThreshold;

                SMP.SaveAs([dataDir filesep subj filesep subj '_' atlasName '_' contName '_' hem '.smp']);
                SMP.clearobj;
                fprintf(1,'Done.')
            end % for h
        end % for t
        fprintf(1,'\nSubject %s done.\n',subj);
        save([homeDir filesep 'ROIs' filesep 'GLM' filesep subj '_GLMs_' atlasName '.mat'],'GLM');
    end % for s
end % for a
xff(0,'clearallobjects')
cd(homeDir)
fprintf(1,'\nGLM estimation complete for %i subjects.\n', length(subList))
end
