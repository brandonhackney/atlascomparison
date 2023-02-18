function overlaps = null_compareParcels(varargin)
% if you parcellate the same subject several times,
% what percentage of the parcels have >~90% concordance?
% What percentage of the vertices are identical across parcellations?

subnum = 'sub-04';
pths = specifyPaths;
% Find folder to look in based on subjectID
if strcmp(subnum,'sub-04')
    % Use template dir, with different folder structure
    sdir = sprintf('%s%s/fs/',pths.baseDataPath,subnum);
else
    % Use normal folder structure
    sdir = sprintf('%s%s/%s-Freesurfer/',pths.deriv,subnum,subnum);
end

numiter = 1000;
hms = {'lh','rh'};

% Define a list of atlases to compare
for a = 1:numiter
    at(a).name = ['null_', num2str(a,'%04.f')]; % 0-pad
end
% VARIANT: compare nulls to a real atlas
if nargin > 0
    atName = varargin{1};
    % Insert this name as the first item in the struct
    b = at;
    at(1).name = atName;
    at(2:numiter+1) = b;
    clear b
end

% Get list of parcels & vertices for all atlases
fprintf(1,'Getting list of data:\n')
for a = 1:length(at)
    % Set names and paths
    atlas = at(a).name;
    ppath = [sdir subnum '-Surf2BV/'];
    hem = 'lh'; % dummy value to check existence
    fname = [ppath subnum '_' hem '_' atlas '.annot.poi'];
    
    fprintf(1,'\t%s: ', atlas);
    
    % Only run this if it doesn't yet exist
    if ~exist(fname,'file')
        % execute fsSurf2BV to convert .annot to .poi
        Cfg.SUBJECTS_DIR = sdir;
        Cfg.projectDir = Cfg.SUBJECTS_DIR; % sets up output folder /mySub-fsSurf2BV/
        Cfg.atlas = [atlas '.annot'];
        fsSurf2BV(subnum,Cfg);
    end
    
    % Read in the data
    for h = 1:2
        hem = hms{h};
        % use xff to read in new .poi
        fname = [ppath subnum '_' hem '_' atlas '.annot.poi'];
        poi = xff(fname);
        % get list of vertices from POI, place in a struct or something
        at(a).name = atlas;
        at(a).hem(h).name = hem;
        at(a).hem(h).parcels = poi.POI;
        poi.clearObject; 
    end % for hem
    
    fprintf(1,'Done.\n');
    
end % for atlas


% do something to ensure you're comparing the 'same' parcels across POIs
% bone-headed loop-based solution: just compare every single parcel combo
% calculate overlap for each, save the maximum, move on to the next
% WARNING: nothing preventing the same comparitor from being saved twice...

fprintf(1,'\nCalculating parcel overlaps:\n');
% This takes about half an hour per hemisphere when comparing 1000 nulls.

overlaps = [];
for h = 1:2
    fprintf(1,'\t%s: ',hms{h});
    t1 = tic;
    for parcel = 1:length(at(1).hem(h).parcels)
        v1 = at(1).hem(h).parcels(parcel).Vertices;
        for i = 2:length(at) % compare to #1
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
    t2 = toc(t1);
    fprintf('Done. Elapsed time: %0.2f min\n',t2/60);
end % for hem
fprintf(1,'Parcel overlap calculations complete.\n');
end % function