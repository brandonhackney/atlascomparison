function output = extractTStemp(subjectList,atlasName)
% output = extractTS(subjectList,atlasName)
% Reads in SRF, POI, ,SDM, and MTC files for a subject
% Extracts and outputs the timeseries of each voxel, labeled by POI
% subjectList: a horizontal vector of subject numbers (e.g. [1, 3, 4...])
% atlasName: a character vector of the atlas name (e.g. 'schaefer400')


% Get list of subjects to move through
subIDs = strcat('sub-0',num2str(subjectList'));

% Navigate to data folder
homeDir = pwd;
cd ..
cd data
dataDir = pwd;

%% Cycle through each subject in subjectList
for i = 1:length(subjectList)
    subj = subIDs(i,:);
    output(i).subID = subj;
    % Display subject name
    fprintf(1,'Subject %s:\n',subj)
    
    cd(subj)
    cd('fs')
    cd(strcat(subj,'-Surf2BV'))
    surfDir = pwd;
    
    % Read in BrainVoyager files (for each hemisphere)
    bv(1).hem = 'lh';
    bv(2).hem = 'rh';
    bv(1).srf = xff(strcat(subj,'_lh_smoothwm.srf'));
    bv(2).srf = xff(strcat(subj,'_rh_smoothwm.srf'));
    bv(1).poi = xff(strcat(subj,'_lh_',atlasName,'.annot.poi'));
    bv(2).poi = xff(strcat(subj,'_rh_',atlasName,'.annot.poi'));
    
    %% Get list of SDM files... this takes a lot of effort
    cd .. % do one now, and another later because reasons
    % hard code for sub differences
    % ignore this if it actually follows BIDS
%     % easier than trying to control for other folders with S in the name
%     if strcmp(subj,'STS1')
%         folderList = ["1";"2";"3-1";"3-2"];
%     elseif strcmp(subj,'STS5')
%         folderList = ["1";"2-1";"2-2";"3"];
%     elseif strcmp(subj,'STS9')
%         folderList = ["ession1"];
%     else
%         folderList = ["1";"2";"3"];
%     end
    cd ..
    cd('bv')
    bvDir = pwd;
    sessList = dir('ses-*');
    sdmList = [];
    for folder = 1:length(sessList)
        % cd ..
        cd(char(sessList(folder).name)) % cd requires charVec, not string
%         cd(char(strcat('_BV-',subj,'-S',folderList(folder)))) % BV dir
        sdmList = [sdmList;dir('*.sdm')];
        cd ..
    end
    
    % I think I end up bypassing this whole process... facepalm
    
    cd(surfDir);
    %% Read in many MTC files
    mtcList = dir('*.mtc');
    fprintf(1,'\tFound %i MTC files.\n',length(mtcList));
    lhCount = 0;
    rhCount = 0;
    for file = 1:length(mtcList)
        mtc = xff(mtcList(file).name);
        nameParts = strsplit(mtcList(file).name,'_');
        % subID, sess, task, run, ... hem.mtc
        session = nameParts{2};
        task = nameParts{3};
        hemStr = nameParts{end}(1:2); % to strip out the file extension
        if strcmp(hemStr,'lh')
            % Do this count thing since there's a mix of hemis in the list
            lhCount = lhCount + 1;
            tempCount = lhCount;
            hem = 1;
        elseif strcmp(hemStr,'rh')
            rhCount = rhCount + 1;
            tempCount = rhCount;
            hem = 2;
        end
        bv(hem).mtc(tempCount).data = mtc;
        bv(hem).mtc(tempCount).session = session;
        bv(hem).mtc(tempCount).task = task;
        bv(hem).mtcList{tempCount} = mtcList(file).name;
            
            % Find the SDM and save predictors
            % Do this here so that the MTC exists
            % The SDM filename should be the same as the MTC's
            filePath = mtcList(file).name;
            % Extract previous additions to filename
            filePath = [filePath(1:end-length(extractAfter(filePath,'NATIVE'))) '.sdm']; % fix extension
            
            cd(bvDir);
            
            sdm = xff(filePath);
            bv(hem).mtc(tempCount).pred = sdm.SDMMatrix;
            %xff(0,'clearobj',sdm); % xff is finicky
            cd(surfDir);
    end

    %% Extract timeseries from the MTCs and label vertices with POIs
    for t = 1:length(mtcList)
        fprintf('\tFile: %s:\n',mtcList(t).name);
        % Get h from filename and don't use it as a for loop
        filename = mtcList(t).name;
        hem = filename(end-5:end-4);
        %for h = 1:2
%             if hem == 1
%                 % Left hem
%                 hem = 'lh';
%             else
%                 hem = 'rh';
%             end
        if strcmp(hem,'lh')
            h = 1;
        elseif strcmp(hem,'rh')
            h = 2;
        else
            fprintf(1,'\t\tHemisphere not detected properly! Skipping.');
            continue
        end

            fprintf(1,'\t\tApplying %i POIs to %s...',length(bv(h).poi.POI),hem);
            
            for m = 1:length(bv(h).mtcList)
                for j = 1:length(bv(h).poi.POI)
                    data(j).label = bv(h).poi.POI(j).Name;
                    data(j).vertices = bv(h).poi.POI(j).Vertices;
                    data(j).vertexCoord = bv(h).srf.VertexCoordinate(data(j).vertices,:);
                    data(j).ColorMap = bv(h).poi.POI(j).Color;
                    data(j).pattern = bv(h).mtc(m).data.MTCData(:,data(j).vertices);
                end
                
                % Export labeled timecourse
                output(i).task(m).name = bv(h).mtc(m).task;
                output(i).task(m).session = bv(h).mtc(m).session;
                output(i).task(m).hem(h).name = hem;
                output(i).task(m).hem(h).data = data;
                output(i).task(m).pred = bv(h).mtc(m).pred;
            end
            
            fprintf(1,'Done.\n\t\tCalculating betas...');
            cd(homeDir);
            output = addBetas(output);
            % It prints its own 'Done' confirmation
            cd(surfDir);
            
            % Save new POI file with new colors for each task
            fprintf(1,'\t\tWriting new POIs for visualization...');
            for m = 1:length(bv(h).mtcList)
                for j = 1:length(bv(h).poi.POI)
                    bv(h).poi.POI(j).Color = ...
                        output(i).task(m).hem(h).data(j).ColorMap;
                    % Label with the SD value - cut out to keep names
                    %--
                    bv(h).poi.POI(j).Name = ...
                        num2str(output(i).task(m).hem(h).data(j).stdVert);
                    %--
                end
                taskName = output(i).task(m).name;
                newName = strcat(subj,'_',hem,'_',atlasName,'_',taskName,'.annot.poi');
                bv(h).poi.SaveAs(char(newName));
            end
            fprintf(1,'Done.\n');
        %end
    end
    cd(dataDir) % Start new subject
end
% Don't save an output file because this is a function, not a script

% Clean up
cd(homeDir)
fprintf(1,"Job's finished! Don't forget to save output to ROIs folder!\n");
xff(0, 'clearallobjects');
end