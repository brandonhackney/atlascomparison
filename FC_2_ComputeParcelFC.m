function FC_2_ComputeParcelFC(atlas, prep, condFlag)

% FC_2_ComputeParcelFC(atlas, prep, taskFlag)
%
% Computes timeseries based FC.
%
% atlas is the string matching the coded file names.
% prep = ['noprep', 'preproc']
% taskFlag = 0 specifies to use the entire timeseries or
% taskFlag = 1 uses the positive (targeted task) predictors.
% taskFlag = -1 uses the control task predictors.
% taskFlag = [1 -1] gets both task and control predictors


BasePath = '/data2/2020_STS_Multitask/analysis';
ROIPath = strcat(BasePath, '/ROIs/FC');
outPath = ROIPath;
cd(ROIPath)

% set up the output filename to be meaningful
if condFlag == 0
    taskOutID = 'AllTS';
else
    taskOutID = 'byCond';
end
fOut = strcat(strjoin({'CorrMats', prep, taskOutID, atlas}, '_'), '.mat');

% set up which input file to use
if strcmp(prep, 'noprep')
    fInext =  '*_noprep.mat';
else
    fInext = '*BPF.mat';
end

% start the computation
fList = [1 2 3 4 5 6 7 8 10 11];
NumSubs = size(fList, 2);
subOutIn = 0;
for sub = fList
    
    f = dir(strcat('STS', num2str(sub), '_', atlas, fInext));
    fprintf(1, 'Loading a big file...\n');
    fName = f.name;
    load(fName)
    NumTasks = size(Pattern.task, 2);
    subOutIn = subOutIn+1;
    
    temp = strsplit(fName, '_');
    subID = temp{1};
    CorrData(subOutIn).subID = subID;
    fprintf(1, '\n\nWorking on %s...\n', subID);
    
    % loop through all tasks
    for task = 1:NumTasks
        
        taskName = Pattern.task(task).name;
        CorrData(subOutIn).taskNames{task, 1} = taskName;
        fprintf(1, '\ttask %s (%i)...\n', taskName, task);
        
        
        %get condition information, restrict to specified indices
        [posInd, negInd, taskOutIn] = getConditionFromFilename(taskName);
        
        for cond = condFlag
            if cond == 1
                condIn = posInd;
                condOut = 1; %for final output 
            elseif cond == -1
                condIn = negInd;
%                 taskOutIn = taskOutIn + NumTasks; %put control conds to end
                condOut = 2;
            elseif cond == 0
                condIn = [];
                condOut = 1;
            end
           
            
            
            %get data from both hemis
            for hemi = 1:2
                
                
                % keep a record, unique to each hemi
                if task == 1
                    CorrData(subOutIn).parcels(hemi).info = Pattern.parcels(hemi);
                end
                
                
                % work through each parcel
                NumParcels = size(Pattern.task(task).data{hemi}, 2);
                meanFC = []; stdFC = [];
                
                for p = 1:NumParcels
                    
                    %get parcel data
                    tsMat = Pattern.task(task).data{hemi}(p).ts;
                    
                    if isempty(tsMat)
                        fprintf(1, 'NO DATA: Sub %i, task %i, hemi %i, condFlag %i\n', sub, task, hemi, cond);
                        
                    else
                        
                        % set up, then compute FC
                        try
                            NumScans = size(tsMat, 3);
                            
                            %seperate by condition, or take all conditions
                            if cond ~= 0
                                sdmTask = Pattern.reg(task).preds(:, condIn, :);
                            else
                                sdmTask = Pattern.reg(task).preds(:, :, :);
                            end
                            
                            % threshold out undesired timepoints, combine multiple
                            % predictors
                            sdmTask(sdmTask < .45) = NaN;
                            if length(posInd)> 1
                                sdmTask = nansum(sdmTask, 2);
                            end
                            
                            % keep only desired timepoints, discard scrubbed timepoints
                            % reshape data into single vector
                            pData = [];
                            for s = 1:NumScans
                                in = find(~isnan(sdmTask(:, 1, s)) & ~isnan(tsMat(:, 1, s)));
                                pData = [pData; tsMat(in, :, s)];
                            end
                            
                            %calculate FC
                            corrMat = atanh(corr(pData));
                            
                            % compute some stats on corr matrics (upper triangle only)
                            in = find(triu(corrMat, 1));
                            meanFC(p) = mean(corrMat(in));
                            stdFC(p) = std(corrMat(in));
                            
                        catch e
                            fprintf(1, 'Sub %i, task %i, hemi %i, condFlag %i\n', sub, task, hemi, cond);
                            fprintf(1, 'error line %i,%s \n', e.stack(1).line, e.message);
                        end
                        
                        
                        CorrData(subOutIn).meanFC(hemi).data{condOut, taskOutIn} = meanFC;
                        CorrData(subOutIn).stdFC(hemi).data{condOut, taskOutIn} = stdFC;
                        CorrData(subOutIn).condlabels(hemi).labels{condOut, taskOutIn} = [task; taskOutIn; cond]; %keep a record
                    end                   
                end
            end
        end
    end
end

fprintf(1, 'Saving results...\n');
cd(outPath)
save(fOut, 'CorrData', '-v7.3');
cd(BasePath)


