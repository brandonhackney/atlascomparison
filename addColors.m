function output = addColors(input,measure)
% output = addColors(input,colInd)
% Recolors POI vertices with gradient scaled to a new calculation
%
% INPUTS
% input: a data structure w/ several ROIs' worth of vertices, patterns, etc
%
% measure: string shorthand for the field your calculation is in
%   options: 'SD' for the standard deviation in input.stdVert
    for i = 1:3
        switch measure
            case 'SD'
                if i == 1
                    values = cell2mat({input.meanPos}');
                elseif i == 2
                    values = cell2mat({input.meanNeg}');
                elseif i == 3
                    values = cell2mat({input.glmEffect}');
                end
            % Add more cases as you add new measures
            % Explicitly call the field name for the calculation's output
        end

        % Recolor the labels based on above calculation
        tempColors = cell2mat({input.ColorMap}');
        map = round(jet(256) * 255); % COLORMAP
        rescaleRGB = round(values * 255 / max(values));
        tempColors = map(rescaleRGB,:);
        colorStruct = mat2cell(tempColors,ones([length(tempColors),1]),3);
        if i == 1
            [input.ColorMapPos] = colorStruct{:};
        elseif i == 2
            [input.ColorMapNeg] = colorStruct{:};
        elseif i == 3
            [input.ColorMap] = colorStruct{:};
        end
    end
    output = input;
    
end