function output = addBetas2(input,pred)
% output = addBetas(input)
% Inserts the beta series of each ROI in a hemisphere, for a single task.
% This version 2.0 removes many internal layers of for loops,
% as well as the SD calculation, which is now in addColors.m
%
% INPUTS
% input: a single hemisphere of a single task's data structure
% pred: predictor matrix, e.g. from an SDM file

% Suppress warnings for nearly-singular matrices
% warning('off','MATLAB:nearlySingularMatrix')

for roi = 1:length(input)
    % Calculate beta based on timeseries and predictors
    % betaHat = inv(pred'*pred)*pred'*parcelTS;
    % inv(A)*B == A\B (as opposed to A/B == A * inv(B))
    input(roi).betaHat = ...
        (pred'*pred)\pred'*...
        input(roi).pattern;
end % roi

output = input;
% warning('on','MATLAB:nearlySingularMatrix')
end