function mtcData = null_extractTS(subID);%, masterVertList)

% takes in a poi file and the relevant subject ID, returns a structure with
% all the timeseries for those specified vertices

% Give some feedback
fprintf(1,'Subject %s:\n',subID)

% Set up paths
p = specifyPaths;

%% Get list of SDM and VTC files
subjDir = strcat(p.deriv, subID);
gohome = pwd;
cd(subjDir);

sdmList = dir('*.sdm'); % except doesn't align 1:1 with mtcList, so can't index
mtcList = dir('*.mtc');

%initialize
templateStruct = struct('mtcfName', [], 'sdmfName', [], 'vertexCoords', [], 'pattern', [], 'pred', [], 'labels', [], 'contrast', []);
mtcData(1:2) = templateStruct;

% Get the surface info at the top level, so it's only loaded once
hemStr = {'lh','rh'};
surfDir = fullfile(subjDir, [subID, '-Freesurfer'], [subID,'-Surf2BV']);
for h = 1:2
    srfName = [subID, '_', hemStr{h}, '_smoothwm.srf'];
    srf = xff(fullfile(surfDir, srfName));
    vertCoords(h).hem = srf.VertexCoordinate;
    srf.ClearObject; clear srf; % immediately return memory
end

%% Read through the MTC files to get header info etc
pfile = 0;
for file = 1:length(mtcList)
    
    % get relevant filename info
    nameParts = strsplit(mtcList(file).name,'_');
    taskName = nameParts{3};
    run = nameParts{4};
    runNum = str2double(run(5));
    hemStr = nameParts{end}(1:2); % to strip out the file extension
    
    

    if ~strcmp(taskName,'RestingState')     % only continue if not a resting state scan
        
        
        % be prepare to use this data for multiple contrasts
        if strcmp(taskName,'ComboLocal')
            contrastList = {'ComboLocal','Objects'};
        elseif strcmp(taskName,'DynamicFaces')
            contrastList = {'DynamicFaces','Motion-Faces'};
        else
            contrastList = {taskName};
        end
        
        
        %figure out which hemisphere this data is for
        if strcmp(hemStr,'lh') || strcmp(hemStr,'LH')
            hemi = 1;
        elseif strcmp(hemStr,'rh') || strcmp(hemStr,'RH')
            hemi = 2;
        end

        
        % load in the data
        mtc = xff(mtcList(file).name);
        
        % Extract PRT name for later, to infer the SDM name
        prtName = mtc.LinkedPRTFile;
        
        % Handle errors if PRT is not attached
        if isempty(prtName)
            % MTCs made in RAWork don't have PRTs attached :(
            % Steal them from the VTC instead, since those are untouched
            vtc = xff(mtc.SourceVTCFile);
            prtName = vtc.NameOfLinkedPRT;
            vtc.ClearObject; % save memory
            [~,~,prtext] = fileparts(prtName);
            if isempty(prtName)
                % If there's no PRT attached to the VTC, then skip.
                % There can't be an SDM without a PRT,
                % and without an SDM, there's no analysis.
                fprintf(1,'\tSkipping file with no PRT: %s\n',mtcList(file).name);
                continue
            elseif isempty(prtext)
                % Account for oddball case with no extension
                prtName = [prtName '.prt'];
            end
            clear vtc prtext;
            
        end
        [a,~,~] = fileparts(prtName);
        if isempty(a)
            % If no path, then attach a path
            prtPath = fullfile(subjDir, prtName);
        else
            prtPath = prtName;
        end
        clear a;
        
        % Allow reuse of an MTC but with a different contrast
        for c = 1:length(contrastList)
          
            % figure out taskID
            task = contrastList{c};
            fprintf(1,'\t%s\n',mtcList(file).name);
            [pos,neg, taskID, ~] = getConditionFromFilename(task);
            mtcData(taskID, hemi).contrast = {pos, neg};

%             
%             %increase size of output matrix if needed
%             if taskID > size(mtcData(:, hemi), 1)
%                 mtcData(taskID, hemi) = templateStruct;
%             end
                        

            % save relevant file name - fix this to separate by hemispheres
            % properly
            mtcData(taskID, hemi).mtcfName = strvcat(mtcData(taskID, hemi).mtcfName, mtcList(file).name);
                             
            % read in the mtc data
            ts = zscore(mtc.MTCData);%(:,masterVertsList)); % note the zscoring
            labels = ones(size(ts, 1), 1)*runNum;
            
            % save into structure
            mtcData(taskID, hemi).pattern = [mtcData(taskID, hemi).pattern; ts];
            mtcData(taskID, hemi).labels = [mtcData(taskID, hemi).labels; labels];    
            mtcData(taskID, hemi).vertexCoords = vertCoords(hemi).hem; % do I need to vcat??
            mtcData(taskID, hemi).task = task;

            
            % Do something to find the PRT
            
            % read in the sdm data and concatenate runs together           
            sdmPath = null_findSDMfName(prtPath);
            mtcData(taskID, hemi).sdmfName = strvcat(mtcData(taskID, hemi).sdmfName, sdmPath);
            
            sdm = xff(sdmPath);
            mtcData(taskID, hemi).pred = [mtcData(taskID, hemi).pred; sdm.SDMMatrix];
            sdm.ClearObject;
           
        end
        mtc.ClearObject; % leave it loaded for each c in contrastList
    end
end

cd(gohome);
