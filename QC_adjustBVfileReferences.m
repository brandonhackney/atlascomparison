%% Folder movement
subID = 'STS3';
session = 'S3';
fsDir = sprintf('/data2/2020_STS_Multitask/data/%s/%s-Freesurfer/%s-Surf2BV',subID,subID,subID);
bvDir = sprintf('/data2/2020_STS_Multitask/data/%s/%s-%s/_BV-%s-%s',subID,subID,session,subID,session);
%% Change PRT name in MTC
% Get PRT file to insert
    cd(bvDir)
name = 'sub-STS-3_ses-3_run-4_task-DynamicFaces_4-13-12-0-33.prt';
if ~exist(name,'file')
    error('Bad PRT name!')
end
path = pwd;
prtpath = [path filesep name];
    cd(fsDir)
% Update MTC file
editMTC = 'STS3_S3_DynamicFaces_Run-4_3DMCS_LTR_THP3c_undist_rh.mtc';
rhDF = xff(editMTC);
rhDF.LinkedPRTFile = prtpath;
rhDF.SaveAs(editMTC);
rhDF.clearobj;
clear rhDF

%% Change FMR name and PRT in VTC
cd(bvDir)
vtcName = 'STS3_S3_DynamicFaces_Run-4_3DMCS_LTR_THP3c_undist.vtc';
vtc = xff(vtcName);
vtc.NameOfLinkedPRT = prtpath;
vtc.NrOfLinkedPRTs = 1;
fmrname = vtc.NameOfSourceFMR;
% modify FMR name?
vtc.NameOfSourceFMR = fmrname;
vtc.SaveAs(vtcName);
vtc.clearobj
clear vtc

%% Change VTC name in MTC
cd(bvDir)
vtcname = 'STS11_S2_Bio-Motion_Run-3_Bio1st_3DMCS_LTR_THP3c_undist.vtc';
path = pwd;
vtcpath = [path filesep vtcname];
cd(fsDir)
editMTC = 'STS11_S3_Speech_Run-3_Speech1st_3DMCS_LTR_THP3c_undist_lh.mtc';
% Update MTC file
rhDF = xff(editMTC);
rhDF.SourceVTCFile = vtcpath;
rhDF.SaveAs(editMTC);
rhDF.clearobj;
clear rhDF