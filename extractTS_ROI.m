function output = extractTS_ROI(subjectNumber,atlasName, varargin)
% output = extractTS(subjectList,atlasName)
% Reads in SRF, POI, ,SDM, and MTC files for a subject
% Extracts and outputs the timeseries of each voxel, labeled by POI
% subjectNumber: an integer subject number (e.g. 3)
% atlasName: a character vector of the atlas name (e.g. 'schaefer400')
%
% optional name-value inputs (all take logical values)
% 'hist': runs generateHistograms, which saves plots to disk
% 'poi': saves recolored POIs with the SD of each parcel as the parcel name
% 'rand': converts each timeseries to random noise, as a quality check

% Suppress a useless Neuroelf warning that shows up in one of the loops
warning('off','xff:BadTFFCont');

% Parse varargin
[poiGen, makeHist, randomizer] = parsevarargin(varargin);
% Convert subject number into ID
subj = strcat('STS',num2str(subjectNumber));

% % Navigate to data folder
% homeDir = pwd;
% cd .. % Move from /analysis/ to project root
% cd(['data' filesep 'deriv'])
% dataDir = pwd; % Base location of all subject folders
% % Location of independent subject .poi files for ROI restriction
% templateDir = '/data2/2020_STS_Multitask/data/sub-04/fs/sub-04-Surf2BV/';

% Get paths to use from specifyPaths() function
paths = specifyPaths;
homeDir = paths.basePath;
dataDir = paths.deriv;
templateDir = paths.template;

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
    
    % Truncate POI for later
    for i = 1:2
        poi = bv(i).poi.POI;
        templ = bv(i).template.POI;
        shortList = {templ.Name};
        longList = {poi.Name};
        truncPOI = bv(i).poi;
        truncPOI.POI = bv(i).poi.POI(ismember(longList,shortList));
        truncPOI.NrOfPOIs = bv(i).template.NrOfPOIs;
        newName = strcat(subj,'_',bv(i).hem,'_',atlasName,'_trunc.annot.poi');
        truncPOI.SaveAs(char(newName));
%         truncPOI.ClearObject; % is this causing bv(h).poi to disappear?
    end
    clear poi templ shortList longList truncPOI
    
    %% Get list of SDM and VTC files
    cd(subjDir);
    sdmList = dir('*.sdm');
    vtcList = dir('*.vtc');
    % Cells are easier to search from than structs, but we still need both
    for i = 1:length(vtcList)
        vtcCell{i} = vtcList(i).name;
    end
    
    %% Match MTC and SDM data based on filenames
    % Scans a folder for MTC files
    % Extracts header info from the filename e.g. task name, run number
    % Finds the associated VTC, PRT, and SDM based on same
    % Creates a labeled structure 'mtcPile' with data, predictors, etc.
    % Adds rows for secondary contrasts, e.g. FFA and PPA using same scan
    % mtcPile is later used to calculate betas for each contrast
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
        
        if strcmp(otask,'RestingState') %|| strcmp(otask,'BowtieRetino') %|| strcmp(task,'DynamicFaces')
            fprintf(1,'\tSkipping task %s\n',mtcList(file).name)
            cd(subjDir) % just in case
            continue
        elseif strcmp(otask,'ComboLocal')
            contrastList = {'ComboLocal','Objects'};
        elseif strcmp(otask,'DynamicFaces')
            contrastList = {'DynamicFaces','Motion-Faces'};
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
                if ~exist(filePath,'file')
                    fprintf(1,'\tWARNING! SDM not found: %s\n',filePath);
                    continue
                end
            else % if you DO have filepath from an attached PRT

                filePath = [filePath(1:end-4) '.sdm'];

            end % if filepath is empty            

            % No matter where filePath is pointing, direct it to subjDir
            filePParts = strsplit(filePath, filesep);
            filePath = [subjDir filesep filePParts{length(filePParts)}];
            
            % Finally read in the data
            sdm = xff(filePath);
            mtcPile(pfile).pred = sdm.SDMMatrix;
            mtcPile(pfile).predpath = filePath;

            filePath = vtcList(index).name;
            % Get the motion correction SDM by truncating filename
            % But if isn't in this folder, then point it to wherever the VTC was looking
            if ~exist([filePath(1:strfind(filePath,'3DMC')+3),'.sdm'],'file')
                filePath = [vtcList(index).folder,filesep,filePath(1:strfind(filePath,'3DMC')+3),'.sdm'];
            else
                filePath = [filePath(1:strfind(filePath,'3DMC')+3),'.sdm'];
            end
            sdmMot = xff(filePath);
            mtcPile(pfile).motionpred = sdmMot.SDMMatrix;
            mtcPile(pfile).motionpath = filePath;

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
    % Takes unordered mtcPile and sorts by hem, task, and run
    % Breaks up whole-hem data matrix into individual parcels, from atlas
    for file = 1:length(mtcPile)
        filename = mtcPile(file).filename;
        fprintf('\tFile: %s:\n',filename);
        
        % Get indexing info pulled from filename
%         taskID = find(strcmp(mtcPile(file).task,taskList));
        [~,~,taskID] = getConditionFromFilename(mtcPile(file).task);
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
            thisPattern = mtcPile(file).data.MTCData(:,data(j).vertices);
            if randomizer
                % Optionally randomize the timeseries, as a quality check
                mu = mean(thisPattern, 'all');
                sigma = std(thisPattern, 0, 'all');
                thisPattern = random('Normal',mu,sigma,size(thisPattern));
            end
            data(j).pattern = zscore(thisPattern);
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
        
        for t = 1:length(taskList)
            [~,~, taskID] = getConditionFromFilename(taskList{t});
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
                    error('Failed pred cat for hem = %s task = %s run = %i',hem,taskList{taskID},runNum);
                end
                temp3dmc = [temp3dmc;organized.hem(h).task(taskID).run(runNum).motionpred];
                motionpaths{runNum,1} = organized.hem(h).task(taskID).run(runNum).motionpath;
            end
            
        % Convert scalar run number column to many binary columns
        % Otherwise you're saying you expect run 1 to be lower etc
        cd(homeDir)
        runVec = tempPred(:,end);
        tempPred = convertRunCol(tempPred);
            
        % Export labeled within-task aggregated timecourse
        output.task(taskID).hem(h).data = tempData;
        output.task(taskID).pred = tempPred;
        output.task(taskID).motionpred = temp3dmc;
        output.task(taskID).predpath = predpaths;
        output.task(taskID).motionpath = motionpaths;
        output.task(taskID).runNum = runVec;
        clear predpaths motionpaths runVec
        
        % Remember that at this stage, you're inside a per-hemisphere loop
        % Calculate betas
        output.task(taskID).hem(h).data = addBetas2(tempData, tempPred);
        % Recolor parcels based on betas
            % Determine which column index to use for SD calculation
        [colInd,negInd] = getConditionFromFilename(taskList{t});
        [output.task(taskID).hem(h).data] = statSD(output.task(taskID).hem(h).data,colInd,negInd);
        % Recolor based on above calculation
        % Uses this weird method to slice an entire field into a struct
       colorMap = {output.task(taskID).hem(h).data.ColorMap};
       cm = addColors({output.task(taskID).hem(h).data.meanSDPos}, colorMap);
        [output.task(taskID).hem(h).data.ColorMapPos] = cm{:};
       cm = addColors({output.task(taskID).hem(h).data.meanSDNeg}, colorMap);
        [output.task(taskID).hem(h).data.ColorMapNeg] = cm{:};
       cm = addColors({output.task(taskID).hem(h).data.sdEffect}, colorMap);
        [output.task(taskID).hem(h).data.ColorMap] = cm{:};
        clear cm colorMap
        cd(surfDir)

        end % for task
        fprintf(1,'Done.\n');
    end % for hem
    organized = organized([]); % Don't need it anymore, so save memory
            
    %% Save new POI files for each task, recolored by metric?
    if poiGen
        generateNewPOIs();
    end % if poiGen
        %end
    %end
    cd(dataDir) % Start new subject
    bv = bv([]); % clear memory
    xff(0, 'clearallobjects'); % should just be the srf and poi at this point
catch thisError
    lineNum = thisError.stack(find(strcmp({thisError.stack.name},'extractTS_ROI'))).line;
    fprintf(1,'%s didn''t work! Error on line %i:\n',subj, lineNum);
    fprintf(1,'%s: %s\n',thisError.identifier,thisError.message);
    cd(homeDir);
    throw(thisError)
end


%% Clean up
cd(homeDir);
if makeHist
    output = generateHistograms(output);
end
if randomizer
    atlasName = [atlasName 'RAND'];
    output.atlas = atlasName;
end

fileOut = saveOutput(output, atlasName);
fprintf(1,"Subject %s saved to /ROIs/%s\n",subj,fileOut);

end

%% subfunctions
function [poiGen, makeHist, randomizer] = parsevarargin(input)
if ~isempty(input)
    % check each value
    numVals = length(input);
    assert(numVals == 2*nargout, 'Unbalanced name-value pairing!');
    
    nameList = input(1:2:numVals);
    valList = input(2:2:numVals);
    
    for i = 1:length(nameList)
    switch nameList{i}
        case 'rand'
            % Output 3: randomization flag
            % If true, will scramble the MTC data before beta calculation
            % This is a quality check, to ensure the pipeline is not biased
            % Must be a logical value
            assert(islogical(valList{i}), 'Randomizer value must be type logical!');
            % If you get here, define the output value 
            randomizer = valList{i};
        case 'poi'
            % Output 1: whether to export SD-labeled POIs
            % Our analysis has moved beyond this, so let's skip it by dflt
            assert(islogical(valList{i}), 'POI flag value must be type logical!');
            poiGen = valList{i};
        case 'hist'
            % Output 2: whether to generate histograms
            % This saves figures to disk, which can take a long time
            % Skip by default
            assert(islogical(valList{i}), 'Histogram flag value must be type logical!');
            makeHist = valList{i};
        otherwise
            error('Unknown name-value pair! Name options are rand, poi, or hist.');
    end % switch
    
    end % for each name-value pair
else % if input is empty
    %% set default values
    randomizer = false;
    poiGen = false;
    makeHist = false;
end % if input is not empty
end % function

function generateNewPOIs()
% Writes new POI files where each parcel is named and colored by a metric
% e.g. instead of having 
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
            % Prepend SD value to parcel label
            if j <= length(output.task(m).hem(h).data)
                if z == 1
                bv(h).poi.POI(conv).Name = ...
                [num2str(output.task(m).hem(h).data(j).meanSDPos) ': ' bv(h).poi.POI(conv).Name];
                elseif z == 2
                    bv(h).poi.POI(conv).Name = ...
                    [num2str(output.task(m).hem(h).data(j).meanSDNeg) ': ' bv(h).poi.POI(conv).Name];
                elseif z == 3
                    bv(h).poi.POI(conv).Name = ...
                    [num2str(output.task(m).hem(h).data(j).sdEffect) ': ' bv(h).poi.POI(conv).Name];
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
end