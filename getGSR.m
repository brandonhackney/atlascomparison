function TC = getGSR(subID, vtcInfo)

% TC = getGSR(subID, taskName)
%
% This function is written for the STS atlas project (2020_Multitask) and
% searches for the appropriate white matter and ventricles mask and the
% proper .vtc file so that a signal can be extracted for later nuisance
% regression.
%
% Based on code originally written by Xiaojue Zhou (2018)
% modified by Emily Grossman (2021)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% start with the anatomy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% specify indices for important structures
% BrainStem = [47 46 16 15 7 8 0];
WMVentNum = [2 4 14 15 41 43 44];

% location and name of the segmented anatomy brain mask
maskDir = strcat('/data2/2020_STS_Multitask/data/',subID,'/', subID, '-Freesurfer/', subID, '/mri/');
maskfName = 'aseg.auto.mgz';

cd(maskDir)
mask = load_mgh(maskfName);

% pull out the relevant coordintaes
c = find(ismember(mask,WMVentNum));
[cortx corty cortz] = ind2sub(size(mask),c);
vox = [cortx corty cortz]; %for saving, below


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% work with the functional data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% name and location of the proper function file
[vtcPath,fBase, EXT] = fileparts(vtcInfo);
vtcfName = strcat(fBase, '.vtc ');

cd(vtcPath)
vtc = xff(vtcfName);


% align anatomical coordinates with vtc coordinates
vtcBox = [vtc.XStart vtc.YStart vtc.ZStart; vtc.XEnd vtc.YEnd vtc.ZEnd];
vtcRes = vtc.Resolution;

matCoords = round([cortx - vtcBox(1,1) corty-vtcBox(1,2) cortz-vtcBox(1,3)]/vtcRes);
vtcDim = size(vtc.VTCData);
MatBox = [vtcDim(2) vtcDim(3) vtcDim(4)];

index = (matCoords(:,1) > MatBox(1) | matCoords(:,2) > MatBox(2) | matCoords(:,3) > MatBox(3) | matCoords(:,1) <= 0 | matCoords(:,2) <= 0 | matCoords(:,3) <= 0);
clust = matCoords(~index,:);
vtcVox = unique(clust(:, :, 1), 'rows');

% extract the timeseries
brain = vtc.VTCData;

%% extract each ROI and then segment the blocks
if ~isempty(vtcVox)
    %pull out the timeseries for each voxel in the ROI
    i = 0; TC = [];
    for i = 1:size(vtcVox, 1)
        TC(:, i) = zscore(brain(:, vtcVox(i, 1), vtcVox(i, 2), vtcVox(i, 3)));
    end
    
else
    TC = [];
end %if vox is empty

vtc.ClearObject;


