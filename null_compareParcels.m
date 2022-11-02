function overlaps = null_compareParcels()
% if you parcellate the same subject several times,
% what percentage of the parcels have >~90% concordance?
% What percentage of the vertices are identical across parcellations?

subnum = 'sub-04';
outpath = '/data2/2020_STS_Multitask/data/sub-04/fs';

numiter = 3;
hms = {'lh','rh'};

for a = 1:numiter
    atlas = ['null_', num2str(a,'%04.f')]; % 0-pad
    % execute fsSurf2BV to convert .annot to .poi
    Cfg.SUBJECTS_DIR = sprintf('/data2/2020_STS_Multitask/data/%s/fs/',subnum);
    Cfg.projectDir = Cfg.SUBJECTS_DIR; % sets up output folder /mySub-fsSurf2BV/
    Cfg.atlas = [atlas '.annot'];
    fsSurf2BV(subnum,Cfg);
    
    for h = 1:2
        hem = hms{h};
        % use xff to read in new .poi
        ppath = [Cfg.projectDir subnum '-Surf2BV/'];
        fname = [ppath subnum '_' hem '_' atlas '.annot.poi'];
        poi = xff(fname);
        % get list of vertices from POI, place in a struct or something
        at(a).name = atlas;
        at(a).hem(h).name = hem;
        at(a).hem(h).parcels = poi.POI;  
    end % for hem
end % for atlas


% do something to ensure you're comparing the 'same' parcels across POIs
% bone-headed loop-based solution: just compare every single parcel combo
% calculate overlap for each, save the maximum, move on to the next
overlaps = [];
for h = 1:2
    for parcel = 1:length(at(1).hem(h).parcels)
        v1 = at(1).hem(h).parcels(parcel).Vertices;
        for i = 2:numiter % compare to #1
            temp = [];
            % looking at the vertex list for each, calculate overlap
            % take the maximum, save the index somewhere
            parcels = at(i).hem(h).parcels;
            for p = 1:length(parcels)
                v2 = parcels(p).Vertices;
                temp(p) = length(intersect(v1,v2)) / length(v1);
            end % for parcel
            overlaps(parcel,i-1,h) = max(temp);
        end % for POIs
    end % for parcel in #1
end % for hem
end % function