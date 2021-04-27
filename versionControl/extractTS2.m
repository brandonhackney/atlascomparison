function output = extractTS2(subjectList,atlasName)
% output = extractTS(subjectList,atlasName)
% Reads in SRF, POI, ,SDM, and MTC files for a subject
% Extracts and outputs the timeseries of each voxel, labeled by POI
% subjectList: a horizontal vector of subject numbers (e.g. [1, 3, 4...])
% atlasName: a character vector of the atlas name (e.g. 'schaefer400')


% Get list of subjects to move through
subIDs = strcat('STS',num2str(subjectList'));

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
    cd(strcat(subj,'-Freesurfer')) % Ideally scratch this line
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
    % easier than trying to control for other folders with S in the name
    if strcmp(subj,'STS1')
        folderList = ["1";"2";"3-1";"3-2"];
    elseif strcmp(subj,'STS5')
        folderList = ["1";"2-1";"2-2";"3"];
    elseif strcmp(subj,'STS9')
        folderList = ["ession1"];
    else
        folderList = ["1";"2";"3"];
    end
    sessList = strcat(subj,"-S",folderList);
    sdmList = [];
    for folder = 1:length(sessList)
        cd .. % move to subject's data dir
        cd(char(sessList(folder))) % cd requires charVec, not string
        cd(char(strcat('_BV-',subj,'-S',folderList(folder)))) % BV dir
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
        run = nameParts{4};
        
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
        mtcPile(file).data = mtc;
        mtcPile(file).session = session;
        mtcPile(file).task = task;
            taskStack{file} = task;
        mtcPile(file).run = run;
        mtcPile(file).hem = hemStr;
        mtcPile(file).filename = mtcList(file).name;

            % Find the SDM and save predictors
            % Do this here so that the MTC exists
            % The SDM filename should be the same as the MTC's PRT
            filePath = mtcPile(file).data.LinkedPRTFile;
            filePath = [filePath(1:end-4) '.sdm'];
            sdm = xff(filePath);
            mtcPile(file).pred = sdm.SDMMatrix;
            %xff(0,'clearobj',sdm); % xff is finicky
    end

    % Get counts/lists for future structure
    taskList = unique(taskStack);
    clear taskStack
    
    %% Extract timeseries from the MTCs and label vertices with POIs
    for file = 1:length(mtcList)
        % Get indexing info pulled from filename
        taskID = find(strcmp(mtcPile(file).task,taskList));
        run = mtcPile(file).run;
            runNum = str2num(run(end)); % make sure you just use the number
        hem = mtcPile(file).hem;
            if strcmp(hem,'lh')
                h = 1;
            elseif strcmp(hem,'rh')
                h = 2;
            end
        filename = mtcPile(file).filename;
        fprintf('\tFile: %s:\n',filename);
        fprintf(1,'\t\tApplying %i POIs to run %i %s...',length(bv(h).poi.POI),runNum,hem);
        
        % Label the SRF vertices with the POI names and the MTC timeseries
        data = [];
        for j = 1:length(bv(h).poi.POI)
            data(j).label = bv(h).poi.POI(j).Name;
            data(j).vertices = bv(h).poi.POI(j).Vertices;
            data(j).vertexCoord = bv(h).srf.VertexCoordinate(data(j).vertices,:);
            data(j).ColorMap = bv(h).poi.POI(j).Color;
            data(j).pattern = mtcPile(file).data.MTCData(:,data(j).vertices);
        end
        % Export labeled timecourse
        output(i).task(taskID).name = mtcPile(file).task;
        output(i).task(taskID).hem(h).name = hem;
        % Temp exports
        organized.hem(h).task(taskID).run(runNum).labelData = data;
        organized.hem(h).task(taskID).run(runNum).pred = mtcPile(file).pred;
        
        % Add run data to pred IFF more than one run exists
        % Otherwise the matrix math for the betas implodes
        if length(find(strcmp(taskList{taskID},{mtcPile.task}))) > 2
            [~, xW] = size(mtcPile(file).pred);
            organized.hem(h).task(taskID).run(runNum).pred(:,xW + 1) = runNum;
        end
        fprintf(1,'Done.\n');
    end
    clear xW
    
    fprintf(1,'\tConcatenating runs...');
    
    % Concatenate runs by task
    for h = 1:2
        if h == 1
            hem = 'lh';
        elseif h == 2
            hem = 'rh';
        end
        
        for taskID = 1:length(taskList)
            tempData = data([]);
            tempPred = [];
            tempPatt = [];
            for runNum = 1:length(organized.hem(h).task(taskID).run)
                for roi = 1:length(organized.hem(h).task(taskID).run(runNum).labelData)
                    if length(tempData) < roi
                        tempData(roi) = organized.hem(h).task(taskID).run(runNum).labelData(roi);
                    else
                        tempData(roi).pattern = [tempData(roi).pattern;organized.hem(h).task(taskID).run(runNum).labelData(roi).pattern];
                    end
                end
                tempPred = [tempPred;organized.hem(h).task(taskID).run(runNum).pred];
            end
        % Export labeled within-task aggregated timecourse
        output(i).task(taskID).hem(h).data = tempData;
        output(i).task(taskID).pred = tempPred;
        end
    end
            
    fprintf(1,'Done.\n\tCalculating betas...');
    cd(homeDir);
    % Just a heads up, output's first index is subject number
    % So you're calculating betas for all previous subjs on each loop
    % dunno if output(i) would work
    output(i) = addBetas(output(i));
    % It prints its own 'Done' confirmation
    cd(surfDir);
        for h = 1:2
            if h == 1
                hem = 'lh';
            elseif h == 2
                hem = 'rh';
            end
            % Save new POI file with new colors for each task
            fprintf(1,'\tWriting new POIs for visualization...\n');
            for m = 1:length(output(i).task)
                for j = 1:length(bv(h).poi.POI)
                    % There's an uneven number of POIs per hemisphere
                    if j <= length(output(i).task(m).hem(h).data)
                    bv(h).poi.POI(j).Color = ...
                        output(i).task(m).hem(h).data(j).ColorMap;
                    end
                    % Label with the SD value - cut out to keep names
                    %--
                    if j <= length(output(i).task(m).hem(h).data)
                    bv(h).poi.POI(j).Name = ...
                        num2str(output(i).task(m).hem(h).data(j).stdVert);
                    end
                    %--
                end
                
                taskName = output(i).task(m).name;
                newName = strcat(subj,'_',hem,'_',atlasName,'_',taskName,'.annot.poi');
                fprintf(1,'\t\t%s\n',newName)
                
                bv(h).poi.SaveAs(char(newName));
            end
        end 
        fprintf(1,'Done.\n');
        
    %end
    cd(dataDir) % Start new subject

end
% Don't save an output file because this is a function, not a script

% Clean up
cd(homeDir);
fprintf(1,"Job's finished! Don't forget to save output to ROIs folder!\n");
xff(0, 'clearallobjects');
end