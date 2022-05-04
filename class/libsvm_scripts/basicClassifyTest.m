clear; clc;

p = specifyPaths;
% NOTE: %there is a matlab function in the stats toolbox with the same name
% as the libsvm one. I will dynamically change the path to make sure I use
% the correct one
p.libsvm = '/usr/local/MATLAB/R2017a/toolbox/libsvm-3.25'; 

metricID = 'stdB';
atlasID = 'power6p0';

cd(p.classifyDataPath)
fList = dir(strcat('Classify*', metricID, '*', atlasID, '*mat'));
load(fList(1).name);

NumSubs = size(Data.subID, 1);
hemi = 1; %left hemi only

data = Data.hemi(hemi).data;
condlabels = Data.hemi(hemi).labels(:, 2);
sublabels = Data.hemi(hemi).labels(:, 1);

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
    [predicted_label, accuracy, prob_est] = svmpredict(testLabels, testData, svmStruct);
    score(:, i) = accuracy(1);
    
    
    
    %6. Optional step: Create a confusion matrix
    conMat = confusionmat(testLabels, predicted_label);
    figure; imagesc(conMat);
    
end

fprintf(1, 'Accuracy across folds:');
fprintf(1, '\t%0.2f', score(1, :));
fprintf(1, '\nMean accuracy: %0.2f\n', mean(score(1, :)));
cd(p.classifyPath)

