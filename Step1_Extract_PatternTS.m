function Step1_Extract_PatternTS(subID, voiType)

% Step1_Extract_PatternTS(subID, voiType). subID is a string. voiType is
% either 'local' or 'rh_custom', or somehow otherwise is the missing
% component of subID_[voiType].voi

warning off;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%       get the important files and directories
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

BaseDir = '/data1/2018_ActionDecoding/analysis_class/';
DataDir = strcat('/data1/2018_ActionDecoding/data/', subID, '/bv/');

namesIFGLH= cellstr(char('ContA_PFCl_1',...
    'ContA_PFCl_2',...
    'ContA_PFCl_3', ...
    'ContA_PFCl_4',...    
    'ContA_PFCl_7',...
    'DefaultB_PFCv_7',...
    'DefaultB_PFCv_9'));
namesIFGRH = cellstr(char('ContA_PFCl_1',...
    'ContA_PFCl_2',...
    'ContA_PFCl_5',...
    'DefaultB_PFCv_5',...
    'SalVentAttnB_PFCl_1'));
namesControl = cellstr(char('17Networks_RH_SomMotB_S2_14',...
    '17Networks_RH_SomMotB_S2_8',...
    '17Networks_RH_SomMotB_S2_16',...
    '17Networks_RH_SomMotB_S2_9',...
    '17Networks_RH_SomMotB_S2_17',...
    '17Networks_RH_SomMotB_S2_19',...
    '17Networks_RH_SomMotB_S2_22',...
    '17Networks_RH_SomMotA_20',...
    '17Networks_RH_SomMotA_33',...
    '17Networks_RH_SomMotA_26',...
    '17Networks_RH_SomMotA_29',...
    '17Networks_RH_SomMotA_37'));
namesMotorRH = cellstr(char('17Networks_RH_SomMotB_S2_14',...
    '17Networks_RH_SomMotB_S2_8',...
    '17Networks_RH_SomMotB_S2_16',...
    '17Networks_RH_SomMotB_S2_9',...
    '17Networks_RH_SomMotB_S2_17',...
    '17Networks_RH_SomMotB_S2_19',...
    '17Networks_RH_SomMotB_S2_22'));
namesAuditoryRH = cellstr(char('17Networks_RH_SomMotB_S2_8',...
    '17Networks_RH_SomMotB_S2_9'));
namesMtloRH = cellstr(char('hMT_RH',...
    'LO_RH'));
namesMTloLH = cellstr(char('hMT_LH',...
    'LO_LH'));

%Get path to .voi file (must already be created)
if strcmp(voiType,'rh_IFG')
    voiPathfName = strcat(DataDir, subID, '_', 'rh_custom','.voi');
elseif strcmp(voiType, 'lh_IFG')
        voiPathfName = strcat(DataDir, subID, '_', 'rh_custom','.voi');
elseif strcmp(voiType,'rh_control')
    voiPathfName = strcat(DataDir, subID, '_', 'rh_custom','.voi');
elseif strcmp(voiType,'rh_motor')
    voiPathfName = strcat(DataDir, subID, '_', 'rh_custom','.voi');
elseif strcmp(voiType,'rh_auditory')
    voiPathfName = strcat(DataDir, subID, '_', 'rh_custom','.voi');
elseif strcmp(voiType,'mtlo')
    voiPathfName = strcat(DataDir, subID, '_', 'local','.voi');
else
    voiPathfName = strcat(DataDir, subID, '_', voiType,'.voi');
end

vtcPrefix = '*actdecode*NATIVE.vtc';
% vtcPathfName = strcat(DataDir, vtcPrefix);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%       get the ROI timeseries
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cd(DataDir); %enter the data directory
vtcList = dir(vtcPrefix);
NumVTCs = length(vtcList);

if NumVTCs < 1
    fprintf(1, '\tNo .vtc identified for subject %s\n', subID);
    
else
    MeanTS = [];
    for v = 1:NumVTCs       %For each .vtc
        
        
        %load up the vtc
        vtcfName = vtcList(v).name;
        
        if v == 1
            %% convert to matlab indices
            ROI = NativeVOI2MatlabCoords(voiPathfName, strcat(DataDir, vtcfName));
            NumROIs = length(ROI(1).Data);
            namesROI = cellstr(ROI.labels);
            
            
            if strcmp(voiType,'lh_IFG')
                roiIdx = find(contains(namesROI,namesIFGLH));
                NumROIs = 1;
                allVoxIdx = [];
                for idx = 1:length(roiIdx)
                    allVoxIdx = [allVoxIdx; ROI.Data(roiIdx(idx)).MatlabIn];
                end
                allVoxIdx = unique(allVoxIdx,'rows');
                ROI.Data(1).MatlabIn = allVoxIdx;
                ROI.labels = 'IFG_LH';
                ROI.Data(2:length(ROI.Data)) = [];
            elseif strcmp(voiType,'rh_IFG')
                roiIdx = find(contains(namesROI,namesIFGRH));
                NumROIs = 1;
                allVoxIdx = [];
                for idx = 1:length(roiIdx)
                    allVoxIdx = [allVoxIdx; ROI.Data(roiIdx(idx)).MatlabIn];
                end
                allVoxIdx = unique(allVoxIdx,'rows');
                ROI.Data(1).MatlabIn = allVoxIdx;
                ROI.labels = 'IFG_RH';
                ROI.Data(2:length(ROI.Data)) = [];
            elseif strcmp(voiType,'rh_control')
                roiIdx = find(contains(namesROI,namesControl));
                NumROIs = 1;
                allVoxIdx = [];
                for idx = 1:length(roiIdx)
                    allVoxIdx = [allVoxIdx; ROI.Data(roiIdx(idx)).MatlabIn];
                end
                allVoxIdx = unique(allVoxIdx,'rows');
                ROI.Data(1).MatlabIn = allVoxIdx;
                ROI.labels = 'SomMot_RH';
                ROI.Data(2:length(ROI.Data)) = [];
            elseif strcmp(voiType,'rh_motor')
                roiIdx = find(contains(namesROI,namesMotorRH));
                NumROIs = 1;
                allVoxIdx = [];
                for idx = 1:length(roiIdx)
                    allVoxIdx = [allVoxIdx; ROI.Data(roiIdx(idx)).MatlabIn];
                end
                allVoxIdx = unique(allVoxIdx,'rows');
                ROI.Data(1).MatlabIn = allVoxIdx;
                ROI.labels = 'SomMot_RH';
                ROI.Data(2:length(ROI.Data)) = [];
            elseif strcmp(voiType,'rh_auditory')
                roiIdx = find(contains(namesROI,namesAuditoryRH));
                NumROIs = 1;
                allVoxIdx = [];
                for idx = 1:length(roiIdx)
                    allVoxIdx = [allVoxIdx; ROI.Data(roiIdx(idx)).MatlabIn];
                end
                allVoxIdx = unique(allVoxIdx,'rows');
                ROI.Data(1).MatlabIn = allVoxIdx;
                ROI.labels = 'Auditory_RH';
                ROI.Data(2:length(ROI.Data)) = [];
            elseif strcmp(voiType,'mtlo')
                roiIdxRH = find(contains(namesROI,namesMtloRH));
                roiIdxLH = find(contains(namesROI,namesMTloLH));
                                
                NumROIs = 2;
                allVoxIdx = [];
                for idx = 1:length(roiIdxRH)
                    allVoxIdx = [allVoxIdx; ROI.Data(roiIdxRH(idx)).MatlabIn];
                end
                allVoxIdx = unique(allVoxIdx,'rows');
                ROI.Data(1).MatlabIn = allVoxIdx;
                
                allVoxIdx = [];
                for idx = 1:length(roiIdxLH)
                    allVoxIdx = [allVoxIdx; ROI.Data(roiIdxLH(idx)).MatlabIn];
                end
                allVoxIdx = unique(allVoxIdx,'rows');
                ROI.Data(2).MatlabIn = allVoxIdx;
                
                
                ROI.labels = char('mtlo_RH','mtlo_LH');
                ROI.Data(3:length(ROI.Data)) = [];
            end
            
            if strcmp(voiType,'rh_IFG')
                voi2matOut = strcat(subID,'_',voiType,'_','VOI2Mat.mat');
                save(voi2matOut,'ROI');
            elseif strcmp(voiType,'lh_IFG')
                voi2matOut = strcat(subID,'_',voiType,'_','VOI2Mat.mat');
                save(voi2matOut,'ROI');
            end
            
        end
        
        
        fprintf(1, '\tLoading %s...',vtcfName);
        vtc = xff(vtcfName);
        brain = vtc.VTCData;
        fprintf(1, 'Done!\n');
        
        
        %% extract each ROI and then segment the blocks
        for r = 1:NumROIs
            
            vox = ROI(1).Data(r).MatlabIn;
            
            %Check to make sure voxelIndices doesn't contain
            %(0,0,0)
            xtest = find(vox(:,1)==0);
            ytest = find(vox(:,2)==0);
            ztest = find(vox(:,3)==0);
            indRm = intersect(intersect(xtest,ytest),ztest);
            vox(indRm,:) = [];
            
            
            if ~isempty(vox)
                
                %pull out the timeseries for each voxel in the ROI
                i = 0; TC = [];
                for i = 1:size(vox, 1)
                    TC(:, i) = zscore(brain(:, vox(i, 1), vox(i, 2), vox(i, 3)));
                end
                
                PatternTS{r}(:, :, v) = TC;
            end
        end
    end
    
    %clean up
    clear brain   %Namaste.  :)
end

%% save data
Data.homeDir = BaseDir;
Data.subID = subID;
Data.path = DataDir;
Data.vtc = vtcList;
Data.ROIlist = ROI;
Data.patterns = PatternTS;


cd(DataDir);
fprintf(1, 'saving...\n')
fOut = strcat(subID, '_', voiType);
save(fOut, 'Data', '-v7.3')

cd(BaseDir);







