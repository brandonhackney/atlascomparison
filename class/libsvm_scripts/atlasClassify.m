function [score, conMat, varargout] = atlasClassify(atlasID, metricID, typeName, varargin)

% cd ../.. % start off in the base analysis dir so we can actually call p
p = specifyPaths;

if nargin > 3
    hemi = varargin{1};
    % please use 1 for left, 2 for right
end
if nargin > 4
    classType = varargin{2};
else
    classType = 'svm';
end

fList = dir(strcat(p.classifyDataPath, filesep, '*', metricID, '*', atlasID, '.mat'));
if length(fList) ==  1
    load([fList.folder filesep fList.name]);
    NumSubs = size(Data.subID, 1);
%     taskIn = findTaskIn(taskList, Data.taskNames); %narrow down to specific conditions
    [taskIn,taskNames, labs] = taskTypeConv(typeName,Data.taskNames, NumSubs);
        labs = labs'; % if not taskNames', then labs'.
    
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
    % preallocate vars for confusion charts
    ptlab = [];
    prlab = [];
    for i = 1:NumSubs %our outer fold (leave one subject out)
        
        
        %2. Split train/test
        in = find(sublabels == uniqueSubIDs(i)); % test subject
        testData = data(in, :);
        testLabels = condlabels(in);
        
        in = find(sublabels ~= uniqueSubIDs(i)); % training subjects
        trainData = data(in, :);
        trainLabels = condlabels(in);
        
        
        %3. Train classifier
        switch classType
            case 'svm'
                % Support Vector Machine classifier
                % NOTE: %there is a matlab function in the stats toolbox with the same name
                % as the libsvm one. I will dynamically change the path to make sure I use
                % the correct one
                % p.libsvm = '/usr/local/MATLAB/R2017a/toolbox/libsvm-3.25';
                p = libsvmpath(p); % this function is more dynamic than the above

                cd(p.libsvm)
                which svmtrain
                svmStruct = svmtrain(trainLabels, trainData);

                %4. Test trained classifier
        %         [predicted_label, accuracy, prob_est] = svmpredict(testLabels, testData, svmStruct, testData);
                [predicted_label, accuracy, prob_est] = svmpredict(testLabels, testData, svmStruct);

            case 'nbayes'
                % Naive Bayes classifier
%                 Tbl = table(trainData);
                nbStruct = fitcnb(trainData, labs(trainLabels), 'ClassNames', taskNames);
                [predicted_label, Posterior, Cost] = nbStruct.predict(testData);
                accuracy = mean(strcmp(labs(testLabels), predicted_label)) * 100;
                % predicted_label is now a cell, but later code wants inds
                % convert to indices for compatibility.
                [~,predicted_label] = ismember(predicted_label, labs);
            case 'lda'
                % Linear Discriminant Analysis classifier
                ldaStruct = fitcdiscr(trainData, labs(trainLabels));
                predicted_label = ldaStruct.predict(testData);
                accuracy = mean(strcmp(labs(testLabels), predicted_label)) * 100;
                % predicted_label is now a cell, but later code wants inds
                % convert to indices for compatibility.
                [~,predicted_label] = ismember(predicted_label, labs);
        end
        
        try
            if isnan(accuracy(1))
                score(:,i) = 0;
            else
                % accuracy has 3 elements: percent correct, MSE, and r^2.
                % We just want accuracy(1), the percent correct.
                score(:, i) = accuracy(1);
            end
        catch
            error('score has size %i while accuracy has size %i',size(score), size(accuracy))
        end
        
        
        
        %6. Optional step: Create a confusion matrix
        conMat(:,:,i) = confusionmat(testLabels, predicted_label);
        % labs defined above - uses original sort order
        % testLabels are indices based on Data.taskNames,
        % so we need to index from something that length and order.
        % But Data.taskNames could be cell or char, so we convert to labs.
%         labs = taskConv(Data.taskNames)'; % can you just use taskNames?
%         labs = taskNames';
        ptlab = [ptlab; labs(testLabels)];
        prlab = [prlab; labs(predicted_label)];
        % Output task names, if asked for (for plotting above)
        if (nargout - 2) >= 1
            % ...I shouldn't have to do this? We already truncated it
%             for t = 1:length(taskNames)
%                 temp(t) = taskUseCheck(taskNames{t},typeName);
%             end
%             varargout{1} = taskNames(logical(temp));
            varargout{1} = taskNames;
        end
        
    end % for i = subject
    % Export values for confusion charts
        if (nargout - 2) >= 2
            varargout{2} = ptlab; % test labels
        end
        if (nargout - 2) >= 3
            varargout{3} = prlab; % predicted labels
        end
        
    % Print classification accuracy
    fprintf(1, '\n\nAtlas: %s, metric: %s, Accuracy across folds:', atlasID, metricID);
    fprintf(1, '\t%0.2f', score(1, :));
    fprintf(1, '\nMean accuracy: %0.2f\n', mean(score(1, :)));
%     cd(p.classifyPath)    
else
    fprintf(1, '\n\n********* Error: More than one data file found *********');
end

cd(p.classifyPath); % return to source dir