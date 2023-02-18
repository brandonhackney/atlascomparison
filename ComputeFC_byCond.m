function [meanFC, stdFC] = ComputeFC_byCond(tsMat, preds) 

% ComputeFC_byCond(tsMat, preds)
%
% Computes timeseries based FC. Takes as input a timeseries by
% voxel/vertice matrix (ie. a pattern) and a set of predictors in matrix of
% the same length as the input pattern. All inputs should be 2D.


% threshold out undesired timepoints, combine multiple predictors
preds(preds < .8) = 0;     % threshold
preds = sum(preds, 2);        % combine predictors, as needed
preds(preds == 0) = NaN;        % replace unwanted timepoints with NaN


% keep only desired timepoints, discard scrubbed timepoints
in = find(~isnan(preds) & ~isnan(tsMat(:, 1)));
pData = tsMat(in, :);

%calculate FC
corrMat = atanh(corr(pData));

% compute some stats on corr matrics (upper triangle only)
in = find(triu(corrMat, 1));
meanFC = mean(corrMat(in));
stdFC = std(corrMat(in));




