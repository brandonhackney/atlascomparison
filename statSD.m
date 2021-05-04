function [input,calcName] = statSD(input,posInd,negInd)
% output = statSD(input,colInd)
% Calculate SD of the betas at each vertex in condition condInd
%
% INPUTS
% input: a data structure w/ several ROIs' worth of vertices, patterns, etc
%
% colInd: column index of the predictor matrix to calculate stats from.
% This varies from MTC to MTC, depending on task condition.
% e.g. MTLocal motion1st, you want 1. Static1st, you want 2 (for motion).

    for i = 1:length(input)
%         input(i).stdVert = std(mean(input(i).betaHat(posInd,:),1));
        input(i).stdPos = std(input(i).betaHat(posInd,:)');
        input(i).stdNeg = std(input(i).betaHat(negInd,:)');
        % Keep those separate just in case; actually use these means
        % This accounts for protocols with more than two conditions
        input(i).stdAll = std(reshape(input(i).betaHat([posInd negInd],:)',[1,numel(input(i).betaHat([posInd negInd],:)')]));
        input(i).meanPos = mean(input(i).stdPos,2);
        input(i).meanNeg = mean(input(i).stdNeg,2);
        input(i).glmEffect = std(mean(input(i).betaHat(posInd,:),1) - mean(input(i).betaHat(negInd,:),1));
        % Extract medians for plots
        % Again, average bc of protocols with more than two conditions 
        input(i).medianPos = mean(median(input(i).betaHat(posInd,:),2));
        input(i).medianNeg = mean(median(input(i).betaHat(negInd,:),2));
%         input(i).medianGLM = mean(median(input(i).betaHat(posInd,:)' - input(i).betaHat(negInd,:)',2));
        input(i).medianGLM = input(i).medianPos - input(i).medianNeg;
    end
    calcName = 'SD'; % send to addColors so it knows what to do
end