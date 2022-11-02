function names = null_parcelNames(poiName)
% names = null_parcelNames(poiName)
% Selects out parcels to use as a master list from sub-04
% specifically checks files named e.g. sub-04_lh_null_0001.annot.poi

% Ensure you have a valid poiName
% Likely contains a filepath, so drop that part
[~, fname, fext] = fileparts(poiName);
if ~strcmp(fext,'.poi')
    error('First input is not a valid POI filename')
end
if ~(strcmp(fname(8:9),'lh') || strcmp(fname(8:9),'rh'))
    error('First input does not specify hemisphere of POI!')
end

% Get hemisphere index from filename
if strcmp(fname(8:9),'lh')
    h = 1;
elseif strcmp(fname(8:9),'rh')
    h = 2;
end

% Get a list of vertices used in other atlases, that constitute STS
verts = null_getVertexList();
% Load in a single null POI
poi = xff(poiName);
POI = poi.POI;

% Check which parcels in the POI contain vertices from the vertex list
names = [];
for p = 1:length(POI)
    if intersect(verts(h).hem, POI(p).Vertices)  % consider thresholding to e.g. need at least 100 verts of intersection
        names = [names; {POI(p).Name}];
    end
end
% return master poi list -> names

% clean up - xff is bad about releasing memory
poi.clearObject;
end