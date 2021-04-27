function statColors = applyColors(data, mapName, varargin)

% statColors = applyColors(data, mapName, varargin)
%
% Takes as input any vector and the name of the colormap to be applied.
% Option to include the [lower upper] limits on the scaling applied to the
% colormap. Default is [0 max(data)]. Outputs a vector of RGB values
% mapping to each row of the data.

if nargin > 2
    minD = varargin{1}(1);
    maxD = varargin{1}(2);
else 
    minD = min(data);
    maxD = max(data);
end

baseMap = eval(strcat(mapName, '(256)'));
map = round(baseMap * 255); 
rescaledData = round(data * 255 / maxD);

statColors = map(rescaledData,:);
