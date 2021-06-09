function Pattern = insertRS(subNum,atlasName)
% Insert Resting State data into existing .mat file

% Convert subject number into ID
subj = strcat('STS',num2str(subNum));

% Load file to modify
filename = ['ROIs' filesep subj '_' atlasName '.mat'];
load(filename);

% Navigate to data folder
homeDir = pwd;
cd .. % Move from /analysis/ to project root
cd(['data' filesep 'deriv'])
dataDir = pwd; % Base location of all subject folders
% Location of independent subject .poi files for ROI restriction
templateDir = '/data2/2020_STS_Multitask/data/sub-04/fs/sub-04-Surf2BV/';

% Get subject data
subjDir = strcat(dataDir,filesep,subj); % All BV data should be here
    surfDir = strcat(subjDir,filesep,subj,'-Freesurfer',filesep,subj,'-Surf2BV');
    cd(surfDir)
    
    % Read in BrainVoyager files (for each hemisphere)
    % Probably need to adjust prefixes
    bv(1).hem = 'lh';
    bv(2).hem = 'rh';
    bv(1).srf = xff(strcat(subj,'_lh_smoothwm.srf'));
    bv(2).srf = xff(strcat(subj,'_rh_smoothwm.srf'));
    bv(1).poi = xff(strcat(subj,'_lh_',atlasName,'.annot.poi'));
    bv(2).poi = xff(strcat(subj,'_rh_',atlasName,'.annot.poi'));
    % Get truncated list of labels for ROI analysis
    cd(templateDir);
    bv(1).template = xff(strcat('template_lh_',atlasName,'.annot.poi'));
    bv(2).template = xff(strcat('template_rh_',atlasName,'.annot.poi'));

cd(subjDir)
sdmList = dir('*RestingState*.sdm'); % There should only be 1: 3DMC
vtcList = dir('*RestingState*.vtc'); % Just in case
mtcList = dir('*RestingState*.mtc'); % There should be 2: one for each hem

    % Cells are easier to search from than structs, but we still need both
    for i = 1:length(vtcList)
        vtcCell{i} = vtcList(i).name;
    end

if length(mtcList) > 2
    fprintf(1,'WARNING! More than 2 MTCs detected\n');
end

% read in RS SDM (3DMC only)
motsdm = xff(sdmList.name);
motpath = [sdmList.folder filesep sdmList.name];
% read in RS MTC data
for h = 1:2
    mtc(h).data = xff(mtcList(h).name);

% Start building data portion
    data = [];
    goddamnPoi = bv(h).poi.POI; % idk why it won't work without this
    for j = 1:length(bv(h).template.POI)
        data(j).label = bv(h).template.POI(j).Name;
        conv = find(strcmp(data(j).label,{goddamnPoi.Name}));
        data(j).vertices = bv(h).poi.POI(conv).Vertices;
        data(j).vertexCoord = bv(h).srf.VertexCoordinate(data(j).vertices,:);
        data(j).ColorMap = bv(h).poi.POI(conv).Color;
        data(j).pattern = mtc(h).data.MTCData(:,data(j).vertices);
        data(j).conv = conv;
    end % j
    hem(h).name = bv(h).hem;
    hem(h).data = data;
end % h

    % store RS data in existing file
    i = length(Pattern.task) + 1;
    Pattern.task(i).name = 'RestingState';
    Pattern.task(i).hem = hem;
    Pattern.task(i).motionpred = motsdm.SDMMatrix;
    Pattern.task(i).motionpath = {motpath};
% export
cd(homeDir)
save(filename,'Pattern');
% clean up before the reference is cleared
xff(0,'clearallobjects');
fprintf(1,'Added RS data to %s %s\n',subj,atlasName);
end % function