function varargout = null_makePOI(subjName, Cfg)
% (output) = null_makePOI(subjName, Cfg)
% Bypasses most of fsSurf2BV to just create a POI file per el. in Cfg.atlas
% i.e. intentionally avoids creating new .srf files etc
% optionally outputs the POI struct, which bypasses saving a file to disk
%
% Cfg needs some adjusting before calling this function:
% Cfg.SUBJECTS_DIR is the base Freesurfer dir where /subjName/label exists
% It must not end with a slash, e.g. must be ~/fs and not ~/fs/
% Cfg.atlas is a cell array of 'name.annot' strings to cycle through
% Defaults: BA_exvivo.annot, aparc.a2009s.annot, aparc.DKTatlas.annot
% We want something more like {'null-0001.annot', 'null-0002.annot'} etc.
% DO NOT specify hemisphere in Cfg.atlas - both done automatically
% IF YOU ONLY WANT ONE HEMISPHERE, set e.g. Cfg.hemis = {'lh'};
%
% Generates an output dir subjname-Surf2BV in the Cfg.projectDir
% If Cfg.projectDir is not specified, defaults to ''. So please specify.


%--------------------------------------------------------------------------
%SET UP CFG
%--------------------------------------------------------------------------

%ENVIRONMENT VARIABLES
if ~isfield(Cfg, 'FREESURFER_HOME'), Cfg.FREESURFER_HOME = '/usr/local/freesurfer'; else end;
%if ~isfield(Cfg, 'FREESURFER_HOME'), Cfg.FREESURFER_HOME = '/Volumes/KoogleData/freesurfer'; else end;
if ~isfield(Cfg,'SUBJECTS_DIR'), Cfg.SUBJECTS_DIR = '/usr/local/freesurfer/subjects'; else end;
%if ~isfield(Cfg,'SUBJECTS_DIR'), Cfg.SUBJECTS_DIR = '/Volumes/KoogleData/freesurfer/subjects'; else end;
%CONFIGURATION
if ~isfield(Cfg, 'projectDir'), Cfg.projectDir = ''; else end;
if ~isfield(Cfg, 'hemis'), Cfg.hemis = {'lh', 'rh'}; else end
if ~isfield(Cfg, 'surfaceTypes'), Cfg.surfaceTypes = {'inflated', 'pial', 'smoothwm', 'sphere'}; else end;
% NOTE: change in atlas name from BA.annot to BA_exvivo.annot in latest
% version of FS (11/20/17 JP)
% if ~isfield(Cfg, 'atlas'), Cfg.atlas = {'BA.annot', 'aparc.a2009s.annot', 'aparc.DKTatlas40.annot', 'Yeo2011_7Networks_N1000.annot', 'Yeo2011_17Networks_N1000.annot'}; else end;
if ~isfield(Cfg, 'atlas'), Cfg.atlas = {'BA_exvivo.annot', 'aparc.a2009s.annot', 'aparc.DKTatlas.annot'}; else end;
%; 'BA.annot', Note: 'PALS_B12_Brodmann.annot' fails
if ~isfield(Cfg, 'nSubClusters'), Cfg.nSubClusters = 0; else end;%for segmenting each labeled area into spatially distinct clusters

% display(Cfg)

setenv( 'SUBJECTS_DIR', Cfg.SUBJECTS_DIR);
setenv( 'FREESURFER_HOME', Cfg.FREESURFER_HOME); %such as /Applications/freesurfer

saveFlag = nargout;

if isdir(fullfile(Cfg.SUBJECTS_DIR, subjName))
    %if provided with a path to a directory, interpret this as the
    %subject-directory
    Cfg.currentSubjectName = subjName;
    POI = processSubject(subjName, Cfg, saveFlag);
    %fsSurf2BVlogging(subjName);
else
    %interpret this as a search string
    d=dir(fullfile(Cfg.projectDir, subjName));
    numSubs = numel(d);
%     fprintf('Found %d subjects matching %s\n', numSubs, subjName);
    h = waitbar(0,'Creating vmrs, srfs, and pois ...');
    for iSub = 1:numel(d)
        waitbar(iSub/numel(d), sprintf('Creating vmrs, srfs, and pois %d/%d', iSub, numSubs));
        Cfg.currentSubjectName = d(iSub).name;
        POI = processSubject(d(iSub).name, Cfg, saveFlag);

        % Add logging 
        %fsSurf2BVlogging(subjName);
    end
    close(h);
    
end
% OUTPUT STAGE
if nargout > 0
    varargout{1} = POI;
end

end

function vout = processSubject(subjName, Cfg, saveFlag)
if ~isfield('Cfg', 'bvDir')
    Cfg.bvDir = fullfile(Cfg.projectDir, [subjName, '-Surf2BV']);
end
% Although consider adding a /null/ subdir
if ~exist(Cfg.bvDir, 'dir')
    mkdir(Cfg.bvDir)
end

%--------------------------------------------------------------------------
%CREATE POIS
%--------------------------------------------------------------------------
% fprintf(1, 'CREATING POI-FILES FROM ATLASES:\n');
if ~iscell(Cfg.atlas)
    Cfg.atlas = {Cfg.atlas};
end

% fprintf(1, '%s\n', Cfg.atlas{:});

for iHemi = 1:numel(Cfg.hemis)
    strHemi = Cfg.hemis{iHemi};
    
    %SUBJECT SPECIFIC SURFACE (inflated may work best)
    fnSurf = fullfile(Cfg.SUBJECTS_DIR, subjName, 'surf', [strHemi, '.', Cfg.surfaceTypes{1}]);
    %READ SURFACE
    [v,~]=freesurfer_read_surf(fnSurf);
    
    for iAtlas=1:numel(Cfg.atlas)
        %e.g. 7 NETWORK ATLAS
        fnAnnot = fullfile(Cfg.SUBJECTS_DIR, subjName, 'label', [strHemi, '.', Cfg.atlas{iAtlas}]);
        fnPoi = fullfile(Cfg.bvDir, [subjName, '_', strHemi, '_', Cfg.atlas{iAtlas}, '.poi']);
        vout = makePoiFromAnnot(fnAnnot, fnPoi, v, Cfg, saveFlag);
    end
end
end

function vout = makePoiFromAnnot(inAnnotFileName, outPoiFileName, v, Cfg, saveFlag)
%READ ANNOTION (e.g. RS-ATLAS)
% Create subject-level one if it doesn't exist
if ~exist(inAnnotFileName, 'file')
%     fprintf('Mapping atlas to subject space.\n');
    %which hemisphere are we talking about?
    [thisSubjectDir, areaID, ~] = fileparts(inAnnotFileName);
    [thisHemi, rmdr] = strtok(areaID, '.');
    %which atlas are we talking about?
    thisAtlas = rmdr(2:end);
    outAnnotFileName = fullfile(thisSubjectDir, sprintf('%s.%s.annot', thisHemi, thisAtlas));

    %mri_surf2surf --srcsubject fsaverage --trgsubject $1 --hemi lh --sval-annot $SUBJECTS_DIR/fsaverage/label/lh.Yeo2011_7Networks_N1000.annot --tval $SUBJECTS_DIR/$1/label/lh.Yeo2011_7Networks_N1000.annot
    strCmd = sprintf('! %s/bin/mri_surf2surf --srcsubject fsaverage --trgsubject %s --hemi %s --sval-annot %s/fsaverage/label/%s.%s --tval %s',...
        Cfg.FREESURFER_HOME, Cfg.currentSubjectName, thisHemi, Cfg.SUBJECTS_DIR, thisHemi, thisAtlas, outAnnotFileName);
%     fprintf(1, '**********************************************************\n');
%     fprintf(1, 'EXECUTING SHELL COMMAND: %s\n', strCmd);
%     fprintf(1, '**********************************************************\n');
    eval(strCmd)
end

% fprintf(1, '-------------------------------------------------------------------------------\n');
% fprintf(1, 'Current atlas (annotation file)\n');
% fprintf(1, '%s\n', inAnnotFileName);
% fprintf(1, '-------------------------------------------------------------------------------\n');

[vertices, label, colortable] = read_annotation(inAnnotFileName);


%MAKE A POI FILE FROM ANNOTATION
poi = xff('new:poi');
labels = unique(label);
nLabels = numel(labels);

for i = 1:nLabels
    idx = find(label == labels(i));
    idxColorTable = find(labels(i) == colortable.table(:, end));
    if isempty(idxColorTable)
        thisStructName = 'NA';
        thisColor = [0 0 0];
    else
        thisStructName = colortable.struct_names{idxColorTable};
        thisColor = colortable.table(idxColorTable, 1:3);
    end
    if i > 1
        %MAKE A COPY OF FIRST ENTRY
        poi.POI(i) = poi.POI(1);
    end
    %UPDATE WITH CURRENT DATA
    poi.POI(i).Name = thisStructName;
    poi.POI(i).Color = thisColor;
    poi.POI(i).NrOfVertices = length(idx);
    poi.POI(i).Vertices = idx;
    %choose a vertex in the center of an area as reference (this may not be the best one)
    centroid = mean(v(idx, :));
    delta = [(v(idx, 1) - centroid(1)).^2, (v(idx, 2) - centroid(2)).^2, (v(idx, 3) - centroid(3)).^2];
    [~, idxminval] = min(sum(delta, 2));
    poi.POI(i).LabelVertex = idx(idxminval); 
end
poi.NrOfMeshVertices = size(vertices, 1);
poi.NrOfPOIs = nLabels;

% OUTPUT STAGE
% If user asks for poi struct directly, assume no files are wanted
if saveFlag > 0
    vout = poi.POI;
else
    vout = {}; % Don't bother holding on to something not asked for
%     fprintf(1, 'SAVING %s\n\n', outPoiFileName);
    poi.SaveAs(outPoiFileName);
end
poi.ClearObject;

if Cfg.nSubClusters > 0
    %MAKE A CLUSTERED POI
    poiClustered = xff('new:poi');
    labelVec = colortable.table(2:end, end); %WE ARE NOT INTERESTED IN THE FIRST LABEL
    structNames = colortable.struct_names(2:end);
    colors = colortable.table(2:end, 1:3);
    nLabels = numel(structNames);
    nClusters = Cfg.nSubClusters;
    poiIdx = 0;
    for i = 1:nLabels
        cases = find(label == labelVec(i));
        if ~isempty(cases)
%             f(1, 'Clustering network %d: %s ... \n', i, structNames{i});
            poiIdx = poiIdx + 1;
            if poiIdx > 1
                %MAKE A COPY OF FIRST ENTRY
                poiClustered.POI(poiIdx) = poiClustered.POI(1);
            end
            
            vertexIdx = vertices(cases) + 1;
            poiClustered.POI(poiIdx).Name = structNames{i};
            poiClustered.POI(poiIdx).Color = floor(colors(i, :));
            poiClustered.POI(poiIdx).NrOfVertices = length(cases);
            poiClustered.POI(poiIdx).Vertices = vertexIdx;
            
            %T = clusterdata(v(vertexIdx, :),nClusters);
            T = kmeans(v(vertexIdx, :), nClusters);
            clustervals = unique(T);
            for c = 1:numel(clustervals)
                poiIdx = poiIdx + 1;
                idxThisCluster = find(T == clustervals(c));
                
                if poiIdx > 1
                    %MAKE A COPY OF FIRST ENTRY
                    poiClustered.POI(poiIdx) = poiClustered.POI(1);
                end
                %UPDATE WITH CURRENT DATA
                poiClustered.POI(poiIdx).Name = sprintf('%s_c%d', structNames{i}, c);
                poiClustered.POI(poiIdx).Color = floor(colors(i, :)/c); %EACH CLUSTER BECOMES DARKER
                poiClustered.POI(poiIdx).NrOfVertices = length(idxThisCluster);
                poiClustered.POI(poiIdx).Vertices = vertexIdx(idxThisCluster);
                poiClustered.POI(i).LabelVertex = poiClustered.POI(poiIdx).Vertices(1); %lazy solution
            end
        end
    end
    poiClustered.NrOfMeshVertices = size(vertices, 1);
    poiClustered.NrOfPOIs = poiIdx;
    [strPath, strPre, strPost] = fileparts(outPoiFileName);
    outPoiFileNameClustered = fullfile(strPath, [strPre, '_clustered', strPost]);
%     fprintf(1, 'SAVING %s\n', outPoiFileNameClustered);
    
    poiClustered.SaveAs(outPoiFileNameClustered);
    poiClustered.ClearObject;
end
end