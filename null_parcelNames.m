function [names, varargout] = null_parcelNames(poiName, varargin)
% [names, (reject?)] = null_parcelNames(poiName, (parcelThreshold, maskThreshold))
%
% Generates a list of parcel names that pass a masking procedure
% Input the filename for a POI from your template subject
% specifically checks for files named e.g. sub-04_lh_null_0001.annot.poi
% Compares each parcel in the POI to the list of vertices generated by null_getVertexList
% Only checks a single POI at a time - nest in a loop to do more
% Optionally input the threshold usd to keep parcels - 
%   Default is that 15% of the parcel must fall within the mask
% After subsetting parcels, decide whether this null is acceptable overall
% Do the retained parcels cover a minimum amount of the mask?
%   If not, reject the entire null model
%   Store a logical matrix of keep or no-keep
%   Default is that 70% of STS must be represented
% Output is a cell array of parcel names that pass this masking process
% Optional second output is a logical denoting whether to REJECT this model
%   So if it's TRUE, then you should NOT keep it
%
% This 'template POI' list is intended to subset other subjects' data.
% Instead of masking each subject independently based on the vertices,
% we mask one template subject by verts, then mask others by parcel names.
% This ensures each subject has the exact same list of parcels,
% though the constituent vertices may change.


% Ensure you have a valid poiName
% Likely contains a filepath, so drop that part
[~, fname, fext] = fileparts(poiName);
if ~strcmp(fext,'.poi')
    error('First input is not a valid POI filename')
end
% Extract hemisphere string from filename
% Expect hem name to come after first underscore
fnameparts = strsplit(fname,'_');
hem = fnameparts{2}; 
if ~(strcmp(hem,'lh') || strcmp(hem,'rh'))
    error('First input does not specify hemisphere of POI!')
end

% Set the minimum overlap you require each parcel to have with the mask
% e.g. 0.9 means 90% of the parcel must fall within the mask to be kept
if nargin > 1
    parcThresh = varargin{1};
    assert(isnumeric(parcThresh), 'Threshold must be a percentage e.g. 0.5');
    assert(parcThresh >= 0 && parcThresh <= 1, 'Threshold must be a percentage e.g. 0.5');
else
    % use the original threshold
    % instead of changing this, call the function with your desired value
    parcThresh = 0.15; 
end

% Set the minimum overlap of your parcel union with the mask
% e.g. 0.9 means all retained parcels must cover 90% of the mask
if nargin > 2
    maskThresh = varargin{2};
    assert(isnumeric(maskThresh), 'Threshold must be a percentage e.g. 0.5');
    assert(maskThresh >= 0 && maskThresh <= 1, 'Threshold must be a percentage e.g. 0.5');
else
    % Use 70% by default
    % Unprincipled whole number
    maskThresh = 0.7; 
end

% Get hemisphere index from filename
if strcmp(hem,'lh')
    h = 1;
elseif strcmp(hem,'rh')
    h = 2;
end

% Get a list of vertices used in other atlases, that constitute STS
% This is the mask we compare against
verts = null_getVertexList();
% Load in a single null POI
poi = xff(poiName);
POI = poi.POI;

% Check which parcels in the POI contain vertices from the vertex list
names = [];
usedVerts = [];
for p = 1:length(POI)
    % Calculate amount of overlap required to include parcel,
    % defined as a percentage of the parcel's size.
    % e.g. if threshold is 15% and parcel has 100 vertices,
    % then at least 15 of those vertices must be within the mask.
    % BUT put a lower bound of the whole mask area
    % This allows you to still keep e.g. a whole-hemisphere parcel
    cutoff = min(parcThresh * numel(POI(p).Vertices), parcThresh * numel(verts(h).hem));
    check = intersect(verts(h).hem, POI(p).Vertices);
    if ~isempty(check) && numel(check) >= cutoff
        names = [names; {POI(p).Name}];
        usedVerts = [usedVerts; POI(p).Vertices];
    end
end
% return master poi list -> names

if nargout > 1
    % Decide whether this null is worth keeping or not
    usedArea = intersect(usedVerts, verts(h).hem);
    if length(usedArea) < maskThresh * length(verts(h).hem)
        % Too little of mask area used - reject
        varargout{1} = true;
    else
        % Keep
        varargout{1} = false;
    end
end

% clean up - xff is bad about releasing memory
poi.clearObject;
end