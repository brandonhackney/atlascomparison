function output = addBetas(input,condInd)
% output = addBetas(input)
% Takes the output from extractTS() and inserts two outputs:
% 1. The beta series of each ROI
% 2. The SD of the betas of each vertex within each ROI
%
% INPUTS
% input: a structure w/ hierarchy input(sub).task(t).hem(h).data
% Must also include predictor matrix input(sub).task(t).pred
%
% condInd: column index of the predictor matrix to calculate betas from.
% This varies from MTC to MTC, depending on task condition.
% e.g. MTLocal motion1st, you want 1. Static1st, you want 2 (for motion).


for sub = 1:length(input)
    for task = 1:length(input(sub).task)
        % Predictor is the same for both hemispheres
        pred = input(sub).task(task).pred;
        for hem = 1:length(input(sub).task(task).hem)
            for roi = 1:length(input(sub).task(task).hem(hem).data)
                % Calculate beta based on timeseries and predictors
                % betaHat = inv(pred'*pred)*pred'*parcelTS;
                % Consider using A/b instead of inv(A)*b
                input(sub).task(task).hem(hem).data(roi).betaHat = ...
                    inv(pred'*pred)*pred'*...
                    input(sub).task(task).hem(hem).data(roi).pattern;
                % Calculate SD of the betas at each vertex
                input(sub).task(task).hem(hem).data(roi).stdVert = ...
                    std(input(sub).task(task).hem(hem).data(roi).betaHat(condInd,:));
            end % roi
            
            % Recolor the labels based on SD
            tempColors = cell2mat({input(sub).task(task).hem(hem).data.ColorMap}');
            map = round(jet(256) * 255); % COLORMAP
            SD = cell2mat({input(sub).task(task).hem(hem).data.stdVert}');
            rescaleRGB = round(SD * 255 / max(SD));
            tempColors = map(rescaleRGB,:);
            colorStruct = mat2cell(tempColors,ones([length(tempColors),1]),3);
            [input(sub).task(task).hem(hem).data.ColorMap] = colorStruct{:};
            
            
        end % hem
    end % task
end % subject
output = input;
fprintf(1,'Done.\n');
end