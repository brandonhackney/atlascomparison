function output = addColors(values,colorMap,varargin)
% output = addColors(values,colorMap)
% Recolors POI vertices with gradient scaled to a new calculation
% Uses the jet colorscheme - modify it yourself if you don't like it
%
% INPUTS
% values: A 1xn cell array of the values you're using, one value / cell
% colorMap: A 1xn cell array of RGB vectors
% NOTE: You can transform a struct into a cell array by doing {st.val}
% (Optional) max: The maximum value you want your data scaled to
% If this optional input is not provided, default to max(values)
%
%OUTPUT
% A cell array containing RGB values based on the values provided
% To dump this into a struct, use [struct.field] = output{:};

    values = cell2mat(values');
    values(isnan(values)) = 0; % convert any NaNs to 0
    % Define the maximum value
    if nargin > 2
        maxv = varargin{1};
    else
        maxv = max(values);
    end
    % Recolor the labels based on above calculation
    tempColors = cell2mat(colorMap');
    map = round(jet(256) * 255); % COLORMAP
    rescaleRGB = round(values * 255 / maxv) + 1; % avoid 0
    tempColors = map(rescaleRGB,:);
    colorStruct = mat2cell(tempColors,ones([length(tempColors),1]),3);

    output = colorStruct;
    
end