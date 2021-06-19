function output = extractTS_ROI(subjectNumber,atlasName)
% output = extractTS(subjectList,atlasName)
% Reads in SRF, POI, ,SDM, and MTC files for a subject
% Extracts and outputs the timeseries of each voxel, labeled by POI
% subjectNumber: an integer subject number (e.g. 3)
% atlasName: a character vector of the atlas name (e.g. 'schaefer400')

% Suppress a useless Neuroelf warning that shows up in one of the loops
warning('off','xff:BadTFFCont');

% Convert subject number into ID
subj = strcat('STS',num2str(subjectNumber));

% Navigate to data folder
homeDir = pwd;
cd .. % Move from /analysis/ to project root
cd(['data' filesep 'deriv'])
dataDir = pwd; % Base location of all subject folders
% Location of independent subject .poi files for ROI restriction
templateDir = '/data2/2020_STS_Multitask/data/sub-04/fs/sub-04-Surf2BV/';

%% Begin data extraction for this subject

    try
    output.subID = subj;
    output.atlas = atlasName;
    % Display subject name
    fprintf(1,'Subject %s:\n',subj)
    
    subjDir = strcat(dataDir,filesep,subj); % All BV data should be here
    surfDir = strcat(subjDir,filesep,subj,'-Freesurfer',filesep,subj,'-Surf2BV');
    cd(surfDir)
    
    % Read in BrainVoyager files (for each hemisphere)
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
    cd(surfDir)
    
    %% Get list of SDM and VTC files
    cd(subjDir);
    sdmList = dir('*.sdm');
    vtcList = dir('*.vtc');
    % Cells are easier to search from than structs, but we still need both
    for i = 1:length(vtcList)
        vtcCell{i} = vtcList(i).name;
    end
    
    %% Read in many MTC files
    cd(subjDir);
    mtcList = dir('*.mtc');
    fprintf(1,'\tFound %i MTC files.\n',length(mtcList));
    lhCount = 0;
    rhCount = 0;
    pfile = 0;
    for file = 1:length(mtcList)
        mtc = xff(mtcList(file).name);
        nameParts = strsplit(mtcList(file).name,'_');
        % subID, sess, task, run, ... hem.mtc
        session = nameParts{2};
        otask = nameParts{3};
        run = nameParts{4};
        
        if strcmp(otask,'RestingState') || strcmp(otask,'BowtieRetino') %|| strcmp(task,'DynamicFaces')
            fprintf(1,'\tSkipping file %s\n',mtcList(file).name)
            cd(subjDir) % just in case
            continue
        elseif strcmp(otask,'ComboLocal')
            contrastList = {'ComboLocal','Objects'};
        else
            contrastList = {otask};
            task = otask;
        end
        
        hemStr = nameParts{end}(1:2); % to strip out the file extension
        if strcmp(hemStr,'lh') || strcmp(hemStr,'LH')
            % Do this count thing since there's a mix of hemis in the list
            lhCount = lhCount + 1;
            tempCount = lhCount;
            hem = 1;
        elseif strcmp(hemStr,'rh') || strcmp(hemStr,'RH')
            rhCount = rhCount + 1;
            tempCount = rhCount;
            hem = 2;
        end
        for x = 1:length(contrastList)
            % Allow reuse of an MTC but with a different contrast
            task = contrastList{x};
        pfile = pfile + 1; % pfile for mtcPile, file for mtcList
        mtcPile(pfile).data = mtc;
        mtcPile(pfile).session = session;
        mtcPile(pfile).task = task;
            taskStack{pfile} = task;
        mtcPile(pfile).run = run;
        mtcPile(pfile).hem = hemStr;
        mtcPile(pfile).filename = mtcList(file).name;
        mtcPile(pfile).path = mtcList(file).folder;
        
        %%% Find the SDMs and save predictors
        % Do this here while the MTC is still in memory because
        % The normal SDM filename should be the same as the MTC's PRT.
        % The 3DMC SDM filename is based on the VTC/MTC filename,
        % But since VTClist is by session while mtcPile is by task,
        % Find the index from vtcList.name that contains task && run.
        index = find(contains(vtcCell,otask) & contains(vtcCell,run));

%         if strcmp(nameParts{end},'lh.mtc') % account for 2 per sdm
%             index = (file + 1)/2;
%         else
%             index = file/2;
%         end
        mtcPile(pfile).VTCpath = strcat(vtcList(index).folder,'/',vtcList(index).name);
        filePath = mtcPile(pfile).data.LinkedPRTFile;
        if strcmp(filePath,'')
            % MTCs made in RAWork don't have PRTs attached :(
            % Steal them from the VTC instead, since those are untouched
            vtc = xff(vtcList(index).name);
            filePath = vtc.NameOfLinkedPRT;
            vtc.ClearObject; % save memory
            if isempty(filePath)
                % If there's no PRT attached to the VTC, then skip.
                % There can't be an SDM without a PRT,
                % and without an SDM, there's no analysis.
                fprintf(1,'\tSkipping file with no PRT: %s\n',mtcList(file).name);
                cd(subjDir);
                mtcPile(pfile).pred = [];
                mtcPile(pfile).motionpred = [];
                continue
            end
            if strcmp(filePath(end-4:end),'.prt') || strcmp(filePath(end-3:end),'.prt')
                filePath = [filePath(1:end-4) '.sdm'];
            else
                % account for oddball case where no extension on PRT
                filePath = [filePath '.sdm'];
            end
            fprintf(1,'\tAssuming %s goes with %s\n',filePath,mtcList(file).name);
%             filePath = vtcList(index).name;
%             filePath = [filePath(1:strfind(filePath,'3DMC')-2),'.sdm'];
            % At this point, STS9 has only 3DMC sdms (ie no regular ones)
            % Let the script run by spitting out a warning.
            if exist(filePath,'file')

                sdm = xff(filePath);
                mtcPile(pfile).pred = sdm.SDMMatrix;
                mtcPile(pfile).predpath = filePath;
            else
                fprintf(1,'\tWARNING! SDM not found: %s\n',filePath);
                continue
            end
            filePath = vtcList(index).name;
            filePath = [filePath(1:strfind(filePath,'3DMC')+3),'.sdm'];
            sdmMot = xff(filePath);
            mtcPile(pfile).motionpred = sdmMot.SDMMatrix;
            mtcPile(pfile).motionpath = filePath;
        else % if you DO have filepath from an attached PRT
            if contains(filePath,'RAWork')
                % Point it to data2 instead
                filePath = [filesep,'data2',filePath(13:end)];
            end
            filePath = [filePath(1:end-4) '.sdm'];
            sdm = xff(filePath);
            mtcPile(pfile).pred = sdm.SDMMatrix;
            mtcPile(pfile).predpath = filePath;

            filePath = vtcList(index).name;
            if ~exist([filePath(1:strfind(filePath,'3DMC')+3),'.sdm'],'file')
                filePath = [vtcList(index).folder,filesep,filePath(1:strfind(filePath,'3DMC')+3),'.sdm'];
            else
                filePath = [filePath(1:strfind(filePath,'3DMC')+3),'.sdm'];
            end
            sdmMot = xff(filePath);
            mtcPile(pfile).motionpred = sdmMot.SDMMatrix;
            mtcPile(pfile).motionpath = filePath;

        end % if filepath is empty
            sdm.ClearObject;
            sdmMot.ClearObject;
            clear filePath
            if x == length(contrastList)
                mtcPile(pfile).finalUse = true;
            else
                mtcPile(pfile).finalUse = false;
            end
        end % for x in contrastList
    end % for file in mtcList

    % Get counts/lists for future structure
    % remove empty elements of taskStack and mtcPile
    mtcPile = mtcPile(~arrayfun(@(x) isempty(x.pred),mtcPile));
    taskStack = taskStack(~cellfun(@isempty, taskStack));
    taskList = unique(taskStack);
    clear taskStack

    
    %% Extract timeseries from the MTCs and label vertices with POIs
    for file = 1:length(mtcPile)
        filename = mtcPile(file).filename;
        fprintf('\tFile: %s:\n',filename);
        
        % Get indexing info pulled from filename
        taskID = find(strcmp(mtcPile(file).task,taskList));
        run = mtcPile(file).run;
%             runNum = str2double(run(end)); % make sure you just use the number
            runNum = str2double(run(5));
        hem = mtcPile(file).hem;
            if strcmp(hem,'lh') || strcmp(hem,'LH')
                h = 1;
            elseif strcmp(hem,'rh') || strcmp(hem,'RH')
                h = 2;
            end

        fprintf(1,'\t\tApplying %i POIs to run %i %s...',length(bv(h).template.POI),runNum,hem);
        
        % Label the SRF vertices with the POI names and the MTC timeseries
        data = [];
        goddamnPoi = bv(h).poi.POI; % idk why it won't work without this
        for j = 1:length(bv(h).template.POI)
            data(j).label = bv(h).template.POI(j).Name;
            conv = find(strcmp(data(j).label,{goddamnPoi.Name}));
            data(j).vertices = bv(h).poi.POI(conv).Vertices;
            data(j).vertexCoord = bv(h).srf.VertexCoordinate(data(j).vertices,:);
            data(j).ColorMap = bv(h).poi.POI(conv).Color;
            data(j).pattern = mtcPile(file).data.MTCData(:,data(j).vertices);
            data(j).conv = conv;
            

        end

       
        % Export labeled timecourse
        output.task(taskID).name = mtcPile(file).task;
        output.task(taskID).hem(h).name = hem;
        output.task(taskID).mtcList = mtcPile; % this still has xff data
        % Temp exports
        organized.hem(h).task(taskID).run(runNum).labelData = data;
        organized.hem(h).task(taskID).run(runNum).pred = mtcPile(file).pred;
        organized.hem(h).task(taskID).run(runNum).motionpred = mtcPile(file).motionpred;
        organized.hem(h).task(taskID).run(runNum).predpath = mtcPile(file).predpath;
        organized.hem(h).task(taskID).run(runNum).motionpath = mtcPile(file).motionpath;
        
        clear goddamnPoi
        if mtcPile(file).finalUse == true
            mtcPile(file).data.ClearObject;
        end
        output.task(taskID).mtcList = rmfield(output.task(taskID).mtcList,'data'); % don't export the xff data

        % This is the last point the original MTC file is used.
        % Everything after this is a derivative variable,
        % So it's safe to clear the xff data.
       
        
        % Add run data to pred, but only if more than one run exists
        % Otherwise the matrix math for the betas implodes
        % Calculate as having more than 2 MTCs with the task name,
        % since if there's one run, you will have 2 MTCs (one per hemi)
        if length(find(strcmp(taskList{taskID},{mtcPile.task}))) > 2
            [~, xW] = size(mtcPile(file).pred);
            organized.hem(h).task(taskID).run(runNum).pred(:,xW + 1) = runNum;
        end
        fprintf(1,'Done.\n');
    end
    clear xW
    fprintf(1,'\tConcatenating runs, calculating betas, generating stats...');
    
    %% Concatenate runs by task
    for h = 1:2
        if h == 1
            hem = 'lh';
        elseif h == 2
            hem = 'rh';
        end
        
        for taskID = 1:length(taskList)
            tempData = data([]); % get the field headers
                data = data([]); % it's unused now; clear memory
            tempPred = [];
            temp3dmc = [];
            predpaths = [];
            motionpaths = [];
            for runNum = 1:length(organized.hem(h).task(taskID).run)
                for roi = 1:length(organized.hem(h).task(taskID).run(runNum).labelData)
                    if runNum == 1 || length(tempData) < roi
                    % Get labels, vertices, etc on first run of each ROI
                    % Avoid 0-indexing if you're missing run 1
                        tempData(roi) = organized.hem(h).task(taskID).run(runNum).labelData(roi);
                    else
                        % JUST update the pattern by concatenating
                        tempData(roi).pattern = [tempData(roi).pattern;organized.hem(h).task(taskID).run(runNum).labelData(roi).pattern];
                    end
                end
                % Add predictors once per run (ie not for every ROI)
                try
                    tempPred = [tempPred;organized.hem(h).task(taskID).run(runNum).pred];
                    predpaths{runNum,1} = organized.hem(h).task(taskID).run(runNum).predpath;
                catch
                    error('Failed pred cat for hem = %s task = %s run = %s',h,taskID,runNum);
                end
                temp3dmc = [temp3dmc;organized.hem(h).task(taskID).run(runNum).motionpred];
                motionpaths{runNum,1} = organized.hem(h).task(taskID).run(runNum).motionpath;
            end
        % Export labeled within-task aggregated timecourse
        output.task(taskID).hem(h).data = tempData;
        output.task(taskID).pred = tempPred;
        output.task(taskID).motionpred = temp3dmc;
        output.task(taskID).predpath = predpaths;
        output.task(taskID).motionpath = motionpaths;
        clear predpaths motionpaths
        
        % Remember that at this stage, you're inside a per-hemisphere loop
        % Calculate betas
        cd(homeDir)
        output.task(taskID).hem(h).data = addBetas2(tempData, tempPred);
        % Recolor parcels based on betas
            % Determine which column index to use for SD calculation
        [colInd,negInd] = getConditionFromFilename(taskList{taskID});
        [output.task(taskID).hem(h).data,calcName] = statSD(output.task(taskID).hem(h).data,colInd,negInd);
        % Recolor based on above calculation
        output.task(taskID).hem(h).data = addColors(output.task(taskID).hem(h).data,calcName);
        cd(surfDir)

        end
        fprintf(1,'Done.\n');
    end
    organized = organized([]); % Don't need it anymore, so save memory
    
%     fprintf(1,'Done.\n\tCalculating betas...');
%     cd(homeDir);
%     
%     % Determine what column number to use as input 2 here.
%     % Oh shit that depends on the task, so you can't do everything at once
%     betaInd = 1;
%     output = addBetas(output,betaInd);
%     % It prints its own 'Done' confirmation
%     cd(surfDir);
            
            % Save new POI file with new colors for each task
            fprintf(1,'\tWriting new POIs for visualization...\n');
            cd(surfDir);
            for h = 1:2
                for m = 1:length(output.task)
                    for z = 1:3 % plus, minus, effect
                        if z == 1
                            effect = 'posCond';
                        elseif z == 2
                            effect = 'negCond';
                        elseif z == 3
                            effect = 'contrastCond';
                        end
                  % Reset it each time to ensure you don't compound data
                    if h == 1
                        hem = 'lh';
                        if exist(strcat(subj,'_lh_',atlasName,'.annot.poi'),'file')
                            bv(1).poi = xff(strcat(subj,'_lh_',atlasName,'.annot.poi'));
                        elseif exist(strcat(subj,'_LH_',atlasName,'.annot.poi'),'file')
                            bv(1).poi = xff(strcat(subj,'_LH_',atlasName,'.annot.poi'));
                        end
                    elseif h == 2
                        hem = 'rh';
                        if exist(strcat(subj,'_rh_',atlasName,'.annot.poi'),'file')
                            bv(2).poi = xff(strcat(subj,'_rh_',atlasName,'.annot.poi'));
                        elseif exist(strcat(subj,'_RH_',atlasName,'.annot.poi'),'file')
                            bv(2).poi = xff(strcat(subj,'_RH_',atlasName,'.annot.poi'));
                        end
                    end  
                    
                    convArray = [];
                    for j = 1:length(bv(h).template.POI)
                        conv = output.task(m).hem(h).data(j).conv;
                        convArray(j) = conv;
                        % There's an uneven number of POIs per hemisphere
                        if j <= length(output.task(m).hem(h).data)
                            if z == 1
                                % plus
                            bv(h).poi.POI(conv).Color = ...
                                output.task(m).hem(h).data(j).ColorMapPos;
                            elseif z == 2
                                % neg
                            bv(h).poi.POI(conv).Color = ...
                                output.task(m).hem(h).data(j).ColorMapNeg;
                            elseif z == 3
                                % effect
                            bv(h).poi.POI(conv).Color = ...
                                output.task(m).hem(h).data(j).ColorMap;
                            end
                        end
                        % Label with the SD value - cut out to keep names
                        %--
                        if j <= length(output.task(m).hem(h).data)
                            if z == 1
                            bv(h).poi.POI(conv).Name = ...
                            num2str(output.task(m).hem(h).data(j).meanPos);
                            elseif z == 2
                                bv(h).poi.POI(conv).Name = ...
                                num2str(output.task(m).hem(h).data(j).meanNeg);
                            elseif z == 3
                                bv(h).poi.POI(conv).Name = ...
                                num2str(output.task(m).hem(h).data(j).glmEffect);
                            end
                        end
                        %--
                        
                        
                    end
                    
                    % Remove unaltered entries from POI w/ logical array
                    reaper = ones([length(bv(h).poi.POI),1]);
                    reaper(convArray) = 0;
                    goddamnPoi = bv(h).poi.POI;
                    goddamnPoi(logical(reaper)) = [];
                    bv(h).poi.POI = goddamnPoi;
                    bv(h).poi.NrOfPOIs = bv(h).template.NrOfPOIs;
                    clear convArray reaper goddamnPoi;
                    
                    taskName = output.task(m).name;
                    newName = strcat(subj,'_',hem,'_',atlasName,'_',taskName,'_',effect,'_trunc.annot.poi');
                    fprintf(1,'\t\t%s\n',newName)

                    bv(h).poi.SaveAs(char(newName));
                    end % condition (z)
                end % task (m)
            end % hem
            fprintf(1,'Done.\n');
        %end
    %end
    cd(dataDir) % Start new subject
    bv = bv([]); % clear memory
    xff(0, 'clearallobjects'); % should just be the srf and poi at this point
    catch thisError
        fprintf(1,'%s didn''t work:\n',subj);
        fprintf(1,'%s: %s\n',thisError.identifier,thisError.message);
        cd(homeDir);
        throw(thisError)
    end


% Clean up
cd(homeDir);
output = generateHistograms(output);
fileOut = saveOutput(output, atlasName);
fprintf(1,"Subject %s saved to /ROIs/%s\n",subj,fileOut);

end