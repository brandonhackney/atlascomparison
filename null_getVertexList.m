function vertList = null_getVertexList(varargin)
% Loads already-created template POI files and extracts the vertices
% Template here means a POI that has been subset to just the STS parcels
% Intended to use the vertex list to subset null parcellations to STS
p = specifyPaths();

if nargin > 0
    atList = varargin{1};
    assert(iscell(atList), 'Input must be a cell list of atlas names');
else
    atList = {'glasser6p0','gordon333dil','power6p0','schaefer400'};
end

hms = {'lh','rh'};
subnum = 'template';
fpath = [p.baseDataPath 'sub-04/fs/sub-04-Surf2BV/'];
vertList(1).hem = [];
vertList(2).hem = [];
for a = 1:length(atList)
    atlas = atList{a};
    for h = 1:2
        hem = hms{h};
        fname = [subnum '_' hem '_' atlas '.annot.poi'];
        poi = xff([fpath fname]);
        parcels = poi.POI;
        temp = [];
        for p = 1:length(parcels)
            temp = [temp; parcels(p).Vertices];
        end
%         vertList(h).hem = unique([vertList(h).hem; temp]);
        vertList(h).hem = unique(temp); % This returns just Schaefer
        % unique() automatically sorts data
    end % for h
end % for a
end % function