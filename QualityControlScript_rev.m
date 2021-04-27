%% Quality Control script for 2020_STS_Multitask
% Loops through all subject folders, finds all VTCs, and reads headers
% Checks for errors like incorrect or missing protocol files
% Exports a log file and a .mat file identifying any issues
%
% QC_structure.mat has one structure variable organized as follows:
% Output:
% output.folder is a character string of the data superfolder
% output.runtime is a dateime object of the time the script was started
% output.subject is a structure of all subjects looped through
% output.subject(n).ID is a character string of the nth subject's ID
% output.subject(n).Directory is the folder containing that subject's data
% output.subject(n).VTCList is the dir() output of all VTCs in that folder
% output.subject(n).VTC is a structure with the header info of each scan
% output.subject(n).VTC(s).name is the filename of subject n's sth VTC
% output.subject(n).VTC(s).FMR is the path of the .fmr attached to that VTC
% output.subject(n).VTC(s).protocol is the name of the attached .prt
% output.subject(n).VTC(s).boundingBox is [XStart XEnd YStart YEnd...]
% output.subject(n).VTC(s).numVolumes is the number of volumes in VTC s
% output.subject(n).VTC(s).TR is the repetition time of the scan
% output.subject(n).VTC(s).orientation is Radiological, Neurological, or
%   unknown
% output.subject(n).VTC(s).refSpace is native, ACPC, or TAL
% output.subject(n).VTC(s).errors is a string listing all errors in the VTC
% output.errorList is a structure listing all scans that had errors
% output.errorList(e).scan lists the name of the eth scan with an error
% output.errorList(e).subject lists the subject number
% output.errorList(e).errors is a string listing all errors for that VTC
%
% Errors that this script will identify:
% -Whether the VTC has no attached protocol file
% -Whether an attached protocol cannot be found by its filepath
% -Whether the orientation (Neuro vs Radio) is unknown
% -Whether the reference space (Native, ACPC, TAL) is unknown
%
% Errors this script does not yet identify:
% -Whether the attached protocol file matches the scan
% -Whether the VTC has the correct number of volumes
% -Anything related to the bounding box
%
% Things this script will fix:
% -Will rewrite linked FMR or PRT filepaths if they point outside kat,
%  but this assumes that the file exists in the same relative place on kat.

% init
clear; clc;
close all;
convTally = [0 0 0];
refTally = [0 0 0 0];
prtTally = 0;
errorInd = 0;

% Create log file
diaryName = strcat('QC_Script_',datestr(today),'.txt');
diary(diaryName);


% Write log file header
fprintf(1,'QUALITY CONTROL SCRIPT\nRun on %s\n\n',datetime);

warning('off')
HomeDir = '/data2/2020_STS_Multitask/analysis/';
DataDir = '/data2/2020_STS_Multitask/data/';
BkupDir = '/data2/2020_STS_Multitask/backup/';
cd(DataDir)

% write script header
output.folder = DataDir;
output.runTime = datetime;

% find all folders starting with 'STS' (expect format STS00)
dirList = dir('STS*');
NumSub = length(dirList);
% for sub = 1:NumSub
for sub = 8
    
    % set up the local path, taking into account subID
    subID = dirList(sub).name;
    subDir = strcat(DataDir, subID);
    
        % Output
        output.subject(sub).ID = subID;
        output.subject(sub).Directory = subDir;
        
    fprintf(1, 'Subject %i: ', sub);
    
    % Move into subject directory
     cd(subDir)
    analysisDir = strcat(subDir,'/',subID,'-Analysis/'); % temporary
    cd(analysisDir) % temporary
%      % Get list of session directories in subDir
%      tempSessList = dir(strcat(subID,'-S*'));
%      
%      % Eliminate ScanNotes, Struct, Surf2BV, etc that aren't scans
%         % Can't index with sessDir(length(sessDir.name)<5) bc many inputs
%         tempNumScan = length(tempSessList);
%         ind = 0;
%         clear sessList
%         for temp = 1:tempNumScan
%             % Skip if it grabbed a file instead of a folder
%             if tempSessList(temp).isdir == 1
%                 test1 = tempSessList(temp).name;
%                 cd(test1)
%                 if ~exist(strcat('_BV-',test1),'dir')
%                     % skip
%                     ind = ind;
%                 else
%                     ind = ind + 1;
%                     sessList(ind) = tempSessList(temp);
%                 end
%                 cd(subDir)
%             end
%         end
%         clear tempSessList tempNumScan temp test1 ind
%         
%     numScan = length(sessList);
%     cd(subDir)
    
%     % Generate a VTC list that pulls from each scan directory
%     clear vtcList
%     for scan = 1:numScan
%      % Move into correct subdirectory eg '_BV-STS1-S1'
%         scanNum = sessList(scan).name;
%         scanDir = strcat(sessList(scan).folder,'/',scanNum,'/_BV-',scanNum);
%         cd(scanDir)
%      
%      % Get list of VTCs in scanDir and add to list for this subject
%         temp = dir('*.vtc');
%         
%         if ~isempty(temp)
%             if exist('vtcList','var')
%                 % Insert scan number
%                 [temp.scan] = deal(erase(scanNum,strcat(subID,'-')));
%                 vtcList = [vtcList;temp];
%             else
%                 [temp.scan] = deal(erase(scanNum,strcat(subID,'-')));
%                 vtcList = temp;
%             end
%         end
%         clear temp 
%     end
%     
    vtcList = dir('*.vtc'); % temporary
    numScan = 1; % Temporary
    scan = 1; % temporary
     if isempty(vtcList)
         fprintf(1, 'No .vtcs found!\n');
         % skip the processing
     else
         fprintf(1, 'Found %i vtc files in %i folders\n', length(vtcList), numScan);
         output.subject(sub).VTClist = vtcList;
         NumVTCs = length(vtcList);
         % find all vtcs
         for v = 1:NumVTCs
             cd(vtcList(v).folder)
             vtc = xff(vtcList(v).name);
        %%  1. Get header information
            % get prt filename
            %  add a default value to prevent crashing on empty prts
             %tempPrt = vtc.NameOfLinkedPRT;
             if ~isempty(vtc.NameOfLinkedPRT)
                 [PATHSTR,prt,EXT] = fileparts(vtc.NameOfLinkedPRT);
             else
                 prt = [];
             end

             FMR = vtc.NameOfSourceFMR; % Name of functional file
             % get other info
             NumVols = vtc.NrOfVolumes; % # vols in this scan
             TR = vtc.TR; % the scan TR
             
             % get information about bounding box
             box = [vtc.XStart vtc.XEnd vtc.YStart vtc.YEnd vtc.ZStart vtc.ZEnd];
                % !! Switched from ZXY to XYZ on May 17 2020 !!
            
            % get left-right convention
                switch vtc.Convention
                    case 1
                        orient = "Radiological";
                        convTally(1) = convTally(1) + 1;
                    case 2
                        orient = "Neurological";
                        convTally(2) = convTally(2) + 1;
                    case 0
                        orient = "unknown";
                        convTally(3) = convTally(3) + 1;
                    otherwise
                        orient = vtc.Convention;
                        % This should never happen
                end

            % get reference space
                switch vtc.ReferenceSpace
                    case 1
                        atlas = "native";
                        refTally(1) = refTally(1) + 1;
                    case 2
                        atlas = "ACPC";
                        refTally(2) = refTally(2) + 1;
                    case 3
                        atlas = "TAL";
                        refTally(3) = refTally(3) + 1;
                    case 0
                        atlas = "unknown";
                        refTally(4) = refTally(4) + 1;
                    otherwise
                        atlas = vtc.ReferenceSpace;
                        % This should never happen
                end

        %% 2. Check for errors
            errors = [];
            if isempty(prt)
                % Generate error code
                errors = strcat(errors,"No protocol file! ");
                prtTally = prtTally + 1;
%             elseif ~exist(vtc.NameOfLinkedPRT,'file')
%                     % If the listed protocol file can't be found
%                     errors = strcat(errors,"Attached PRT not on KAT! ");
% Nothing ever passes this test bc you'd need to scan the entire server
% As written, I think this only checks the current working directory
            end
            
            if orient == "unknown"
                % Generate error code
                errors = strcat(errors,"Unknown orientation! ");
            end
            if atlas == "unknown"
                % Generate error code
                errors = strcat(errors,"Unknown reference space! ");
            end
            
        % Output errors
            if ~isempty(errors)
                errorInd = errorInd + 1;
                output.errorList(errorInd).subject = subID;
                output.errorList(errorInd).scan = vtcList(v).name;
                output.errorList(errorInd).errors = errors;
            end
%         %% 3. Fix what you can
%         % Specific FMR path problems
%             % Define check strings
%             check1 = '/home/austin/Documents/STS-Preprocessing/';
%             check2 = '/media/tarrlab/sts-data/Pipeline/';
%             check3 = '/Volumes/KoogleData/STS-R21/';
%             katString = '/data2/2020_STS_Multitask/data/';
% 
%             % Replace the wrong path prefixes with the proper path on kat
%             dummy = 0;
%             if contains(FMR,check1)
%                 oldFMR = FMR;
%                 FMR = replace(FMR,check1,katString);
%                 dummy = 1;
%             elseif contains(FMR,check2)
%                 oldFMR = FMR;
%                 FMR = replace(FMR,check2,katString);
%                 dummy = 1;
%             elseif contains(FMR,check3)
%                 oldFMR = FMR;
%                 FMR = replace(FMR,check3,katString);
%                 dummy = 1;
%             end
%             
%             if dummy == 1
%                 longDir = replace(vtcList(v).folder,DataDir,BkupDir);
%                 if longDir(end) ~= '/', longDir = [longDir,'/']; end
%                 
%                 % Check for backup directory and create if not exist
%                 if ~exist(longDir, 'dir'), mkdir(longDir); end
%                 
%                 % Copy original file to backup dir
%                 filename = vtc.FilenameOnDisk;
%                 filename2 = replace(filename,DataDir,BkupDir);
%                 % But avoid overwriting if it already exists
%                 if ~exist(filename2,'file')
%                     vtc.SaveAs(filename2);
%                 end
%                 
%                 % Export updated path to new VTC in data dir
%                 vtc.NameOfSourceFMR = FMR;
%                 vtc.SaveAs(filename);
%             end
%             
%             clear check1 check2 check3 katString longDir filename filename2
        %% 4. Log and output results
            % include prt, # nvols, TR
             fprintf(1, '\t%s:\n',vtcList(v).name);
%              fprintf(1, '\t\tScan Number : %s\n',vtcList(v).scan);
             fprintf(1, '\t\tFMR File    : %s\n',FMR);
             fprintf(1, '\t\tProtocolFile: %s\n',prt);
             fprintf(1, '\t\tBounding Box: %i %i %i %i %i %i\n', box);
             fprintf(1, '\t\tNum Volumes : %i\n',NumVols);
             fprintf(1, '\t\tTR          : %f\n',TR);
             fprintf(1, '\t\tOrientation : %s\n',orient);
             fprintf(1, '\t\tRefSpace    : %s\n',atlas);
             fprintf(1, '\t\tErrors      : %s\n',errors);
             
        % Save header info to a structure, one array per subject
            output.subject(sub).VTC(v).name = vtcList(v).name;
%             output.subject(sub).VTC(v).scan = vtcList(v).scan;
            output.subject(sub).VTC(v).FMR = FMR;
            output.subject(sub).VTC(v).protocol = prt;
            output.subject(sub).VTC(v).boundingBox = box;
            output.subject(sub).VTC(v).numVolumes = NumVols;
            output.subject(sub).VTC(v).TR = TR;
            output.subject(sub).VTC(v).orientation = orient;
            output.subject(sub).VTC(v).refSpace = atlas;
            output.subject(sub).VTC(v).errors = errors;
        
%         % Account for edits
%             if dummy == 1
%             output.subject(sub).VTC(v).oldFMR = oldFMR;
%             end
%             clear dummy
            
        % Close VTC to save memory
            vtc.clearobj;
        % Clear variables to prevent duplication on empty
        clear atlas box FMR NumVols orient prt TR
         end % for each VTC
         fprintf(1, '\n')
     end % if VTC list is empty
     
end % for each sub

% Calculate the dimensions of the bounding boxes based on the coordinates
for x = 1:length(output.subject)
    temp = output.subject(x).VTC(1).boundingBox;
    output.subject(x).BBoxDim(1) = temp(2) - temp(1);
    output.subject(x).BBoxDim(2) = temp(4) - temp(3);
    output.subject(x).BBoxDim(3) = temp(6) - temp(5);
    clear temp;
end
clear x;

%% Save the structure to the analysis directory
cd(HomeDir)
save(strcat('QC_structure_',datestr(today),'.mat'),'output');
%% Clean up
fprintf(1,'\n\n--RESULTS--');
fprintf(1,'\nNumber in Native space = %i\nNumber in ACPC space = %i\nNumber in TAL space = %i\nNumber in unknown space = %i\n',refTally);
fprintf(1,'\nNumber of Radiological = %i\nNumber of Neurological = %i\nNumber of unknown orientations = %i\n',convTally);
fprintf(1,'\nNumber of missing protocols = %i\n',prtTally);
fprintf(1,'\nJob completed %s\n',datetime);
diary off
