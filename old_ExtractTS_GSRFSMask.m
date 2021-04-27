function GSRTS = ExtractTS_GSRFSMask(vtcList,subID)
%this function takes into vtclist, read in all vtcs(fMRI scans) and pre-specified freesurfer output 
%brain segmented masks including CSF, WM, and GM and output a single time x 2 global signal regressors 
%(including averaged Global signal and its first derivative). 

% originally written by Xiaojue Zhou (2018)
% modified by Emily Grossman (2021)



maskfName = strcat('/data2/2020_STS_Multitask/data/',subID,'/', subID, '-Freesurfer/', subID, '/mri/aseg.auto.mgz');
mask = load_mgh(maskfName);

% specify indices for important structures
BrainStem = [47 46 16 15 7 8 0];
WMVentNum = [2 4 14 15 41 43 44];

%%%%%%use NativeVOI2MatlabCoords to solve the voxel size issue


%%%%%%convert mask into vtc/fMRI space
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%       Convert the coordinates
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

cd(vtcList(1).folder);
vtc = xff(strcat(vtcList(1).name));
vtcBox = [vtc.XStart vtc.YStart vtc.ZStart; vtc.XEnd vtc.YEnd vtc.ZEnd];
vtcRes = vtc.Resolution;

vtcDim = size(vtc.VTCData);
MatBox = [vtcDim(2) vtcDim(3) vtcDim(4)];


%roi(1).Voxels is the x y z coordinates
%Resolution: 1
%offset 0, origin 0. Here will assume the freesurfer output is the same


% save essential data and give the user some relevant output
ROIList.Name = maskfName;
ROIList.BVNumVox = length(cortx);
matCoords = round([cortx - vtcBox(1,1) corty-vtcBox(1,2) cortz-vtcBox(1,3)]/vtcRes);


% convert to matlab coordinates for .vtc timecourse extraction
% check for expanding beyond TalBox
index = (matCoords(:,1) > MatBox(1) | matCoords(:,2) > MatBox(2) | matCoords(:,3) > MatBox(3) | matCoords(:,1) <= 0 | matCoords(:,2) <= 0 | matCoords(:,3) <= 0);
clust = matCoords(~index,:);
clustUnique = unique(clust(:, :, 1), 'rows');


% save essential data and give the user some relevant output
ROIList.MatlabIn = clustUnique;
ROIList.MatlabNumVox = size(clustUnique, 1);
ROIList.TALcoords = vox;
fprintf(1, '\t %i matlab voxels\n\n', ROIList.MatlabNumVox)
%check if this can be used


WMVentROI = ROIList;
save(fullfile(vtcList(1).folder, strcat(subID, '_WMVentROI.m')))


%%%Extract GSR time series and output 202x2 for each scan output
NumVTCs = length(vtcList);


%get the ROI timeseries
if NumVTCs < 1
    fprintf(1, '\tNo .vtc identified for subject %s\n', subID);
    
else
    for v = 1:NumVTCs       %For each .vtc, for all runs in action decoding study
        %load up the vtc
        vtcfName = vtcList(v).name;
        fprintf(1, '\tLoading %s...',vtcfName);
        vtc = xff(vtcfName);
        brain = vtc.VTCData;
        fprintf(1, 'Done!\n');
        
        %% extract each ROI and then segment the blocks
        vox = WMVentROI.MatlabIn;
        if ~isempty(vox)
            %pull out the timeseries for each voxel in the ROI
            i = 0; TC = [];
            for i = 1:size(vox, 1)
                TC(:, i) = zscore(brain(:, vox(i, 1), vox(i, 2), vox(i, 3)));
            end
            
            GSRTS(:,1,v) = mean(TC,2);
            tmpdiff(2:size(TC,1)) = diff(mean(TC,2));
            tmpdiff(1) = 0;
            GSRTS(:,2,v) = tmpdiff'; %the first derivative
        end %if vox is empty
        
        
    end %numVTCs
    

    %clean up
    clear brain   %Namaste.  :)
end %if VTC is less than 1

%% save data
save(fullfile(vtcList(1).folder, strcat(subID, '_GSRTS.mat')), 'GSRTS', 'vtcList')








