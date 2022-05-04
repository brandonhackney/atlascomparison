function [score, conMat, varargout] = atlasClassify(atlasID, metricID, typeName, varargin)

% cd ../.. % start off in the base analysis dir so we can actually call p
p = specifyPaths;

% NOTE: %there is a matlab function in the stats toolbox with the same name
% as the libsvm one. I will dynamically change the path to make sure I use
% the correct one
p.libsvm = '/usr/local/MATLAB/R2017a/toolbox/libsvm-3.25';

if nargin > 3
    hemi = varargin{1};
    % please use 1 for left, 2 for right
end

fList = dir(strcat(p.classifyDataPath, filesep, '*', metricID, '*', atlasID, '*mat'));
if length(fList) ==  1
    load([fList.folder filesep fList.name]);
    NumSubs = size(Data.subID, 1);
%     taskList = createTaskList(typeName); %social or control
%     taskIn = findTaskIn(taskList, Data.taskNames); %narrow down to specific conditions
    [taskIn,taskNames] = taskTypeConv(typeName,Data.taskNames, NumSubs);

    
    data = double(Data.hemi(hemi).data(taskIn,:));
    condlabels = Data.hemi(hemi).labels(taskIn, 2);
    sublabels = Data.hemi(hemi).labels(taskIn, 1);
    
    % 1. mean center the data, independently per subject
    uniqueSubIDs = unique(sublabels);
    for s = 1:NumSubs
        in = find(sublabels == uniqueSubIDs(s)); %find the rows for exemplars for that subject
        m = mean(data(in, :), 1); % take the mean of all the trials (but not voxels)
        data(in, :) = data(in, :) - repmat(m, length(in), 1); % subtract to center voxels around zero
    end
    
    
    for i = 1:NumSubs %our outer fold (leave one subject out)
        
        
        %2. Split train/test
        in = find(sublabels == uniqueSubIDs(i)); % test subject
        testData = data(in, :);
        testLabels = condlabels(in);
        
        in = find(sublabels ~= uniqueSubIDs(i)); % training subjects
        trainData = data(in, :);
        trainLabels = condlabels(in);
        
        
        %3. Train classifier
        cd(p.libsvm)
        which svmtrain
        svmStruct = svmtrain(trainLabels, trainData);
        
        
        %4. Test trained classifier
        [predicted_label, accuracy, prob_est] = svmpredict(testLabels, testData, svmStruct, testData);
        score(:, i) = accuracy(1);
        
        
        
        %6. Optional step: Create a confusion matrix
        conMat(:,:,i) = confusionmat(testLabels, predicted_label);
        % Output task names, if asked for (for plotting above)
        if (nargout - 2) > 0
            % ...I shouldn't have to do this? We already truncated it
%             for t = 1:length(taskNames)
%                 temp(t) = taskUseCheck(taskNames{t},typeName);
%             end
%             varargout{1} = taskNames(logical(temp));
            varargout{1} = taskNames;
        end
        
    end
    
    fprintf(1, '\n\nAtlas: %s, metric: %s, Accuracy across folds:', atlasID, metricID);
    fprintf(1, '\t%0.2f', score(1, :));
    fprintf(1, '\nMean accuracy: %0.2f\n', mean(score(1, :)));
%     cd(p.classifyPath)
    
else
    fprintf(1, '\n\n********* Error: More than one data file found *********');
end

