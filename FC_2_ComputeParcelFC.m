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
% fOut = strcat(strjoin({'CorrMats', prep, taskOutID, atlas}, '_'), 'SIM.mat');
fOut = strcat(strjoin({'CorrMats', prep, taskOutID, atlas}, '_'), '.mat');

% set up which input file to use
if strcmp(prep, 'noprep')
    fInext =  '*_noprep.mat';
else
    fInext = '*BPF.mat';
end

% start the computation
fList = [1 2 3 4 5 6 7 8 10 11]; %[101 102 103 104 105 106 107 108 110 111];%
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
        condIn = 1;
        condOut = 1;
%         posInd = 1;
        cond = Pattern.task(task).contrast(1);
%         [~, negInd, taskOutIn, ~, ~, posInd] = getConditionFromFilename(taskName);
          

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

                        % select relevant conditions
                        sdmTask = Pattern.reg(task).preds(:, condIn, :);
                                            
                        % threshold out undesired timepoints, combine multiple
                        % predictors
                        sdmTask(sdmTask < .8) = 0;     % threshold
                        sdmIn = sum(sdmTask, 2);        % combine predictors, as needed
                        sdmIn(sdmIn == 0) = NaN;        % replace unwanted timepoints with NaN

                        
                        % keep only desired timepoints, discard scrubbed timepoints
                        % reshape data into single vector
                        pData = [];
                        for s = 1:NumScans
                            in = find(~isnan(sdmIn(:,1, s)) & ~isnan(tsMat(:, 1, s)));
                            pData = [pData; tsMat(in, :, s)];
                        end

                        %calculate FC
                        corrMat = atanh(corr(pData));

                        % compute some stats on corr matrics (upper triangle only)
                        in = find(triu(corrMat, 1));
                        meanFC(p) = mean(corrMat(in));
                        stdFC(p) = std(corrMat(in));

                    catch e
                        fprintf(1, 'Sub %i, task %i, hemi %i\n', sub, task, hemi);
                        fprintf(1, 'error line %i,%s \n', e.stack(1).line, e.message);
                    end
                        
                        
                    CorrData(subOutIn).meanFC(hemi).data{task} = meanFC;
                    CorrData(subOutIn).stdFC(hemi).data{task} = stdFC;
                    CorrData(subOutIn).condlabels(hemi).labels{task} = [task; 1; cond]; %keep a record
                end                   
            end
        end
    end
end


fprintf(1, 'Saving results...\n');
cd(outPath)
save(fOut, 'CorrData', '-v7.3');
cd(BasePath)


