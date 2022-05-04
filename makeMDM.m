% Script to generate MDM files for GLM calculation in group-surface space
% Ideally convert to function instead of hardcoding these inputs

subIDList = {'STS1', 'STS2' 'STS3' 'STS4' 'STS5' 'STS6' , 'STS7' 'STS8', 'STS10', 'STS11'};
taskList = {'AVLocal', 'Bio-Motion' 'BowtieRetino' 'ComboLocal' 'DynamicFaces' 'Motion-Faces' 'MTLocal' 'Objects' 'SocialLocal' 'Speech' 'ToM'};

paths = specifyPaths;
load([paths.basePath 'getFilePartsFromContrast.mat']);

diary 'mdmLog.txt'
fprintf(1, 'MDM creation started %s\n',datestr(now));

for h = 1:2
    if h == 1
        hem = 'LH';
    elseif h == 2
        hem = 'RH';
    end
    
    for t = 1:length(taskList)
        task = taskList{t};
        task2 = conditionList(find(strcmp({conditionList.contrast},task))).mtc;
        numFiles = 0;
        fprintf(1,'\n\n\nTask %s %s:\n',task, hem);
        fileOut = [paths.baseDataPath 'deriv' filesep 'group' filesep task '_' hem '.mdm'];
        fbody = '';
        for s = 1:length(subIDList)
            sub = subIDList{s};
            ssmPath = [paths.baseDataPath 'John-Analysis-Folders' filesep sub '-Analysis' filesep];
            sdmPath = [paths.baseDataPath 'deriv' filesep sub filesep];
            
            fprintf(1,'\n\t%s: \n',sub);
            
            % Find # runs somehow - may be variable per subject
            mtcSpec = [ssmPath sub '_*_' task2 '_Run-*_*_undist_' hem '.mtc'];
            mtcList = dir(mtcSpec);
            if isempty(mtcList)
                mtcSpec = [ssmPath sub '_*_' task2 '_Run-*_*_undist_' lower(hem) '.mtc'];
            end
            mtcList = dir(mtcSpec);
            clear mtcSpec;
            numRuns = length(mtcList);
            
            for r = 1:numRuns
                ssm = [ssmPath sub '_' hem '_SMOOTHWM_HIRES_SPH_GROUPALIGNED.ssm'];
                % Make sure you can get the specific run you want
                % JUST IN CASE one is missing and throws the indexing off
                mtcFile = [mtcList(r).folder filesep mtcList(r).name];
                    mtcParts = strsplit(mtcList(r).name,'_');
                    runName = mtcParts{4};
                    runStr = strsplit(runName,'-');
                    run = str2double(runStr{2});
                    clear mtcParts runName runStr
                fprintf(1, '\tRun %i... ', run);
                %% SDMs have weird names - use existing findPRT code
                % THis was copied out of extractTS_ROI with modifications
                % Consider converting it to a function?
                mtc = xff(mtcFile);

                % Get the VTC from the MTC name
                vtcFile = strrep(mtcFile,lower(['_' hem '.mtc']),'.vtc');
                if ~exist(vtcFile,'file')
                    vtcFile = strrep(mtcFile,['_' hem '.mtc'],'.vtc');
                end
                if ~exist(vtcFile,'file')
                    error('No VTC file matching MTC.\n\tMTC file: %s\nVTC test name: %s\n',mtcFile,vtcFile);
                end

                filePath = mtc.LinkedPRTFile;
                if ~strcmp(task, task2)
                    filePath = ''; % force it to search
                end
                if strcmp(filePath,'')
                    % MTCs made in RAWork don't have PRTs attached :(
                    % Steal them from the VTC instead, since those are untouched
                    vtc = xff(vtcFile);
                    filePath = vtc.LinkedPRTFile;
                    vtc.ClearObject; % save memory
                    if ~strcmp(task, task2) 
                        filePath = ''; % force it to search
                    end
                    if isempty(filePath)
                        % Try searching the target dir for the SDM
                        % Restrict to this run and this task
                        % Use the lookup table we build for doing this
                        % e.g. "MTLocal" to find "OpticFlowCenter"
                        % Find the row index of col 'contrast' that matches task,
                        % then use it to grab the text from col 'sdm'

                        sdmT = conditionList(find(strcmp({conditionList.contrast},task))).sdm;
                        sdmList = dir([sdmPath '*run-' num2str(run) '_task-' sdmT '*.sdm']);
                        if length(sdmList) > 1
                            % If there is more than one SDM file
                            % Already task- and run-specific
                            error('Too many SDMs - take a look here');
                        elseif length(sdmList) < 1
                            % If there's no PRT attached to the VTC, then skip.
                            % There can't be an SDM without a PRT,
                            % and without an SDM, there's no analysis.
                            fprintf(1,'Skipping file with no PRT: %s\n',mtcList(r).name);
                            continue
                        else
                            % We found it
                            filePath = [sdmPath sdmList(1).name];
                        end
                    end
                    % Convert .PRT extension to .SDM
                    if strcmp(filePath(end-4:end),'.prt') || strcmp(filePath(end-3:end),'.prt')
                        filePath = [filePath(1:end-4) '.sdm'];
                    elseif ~strcmp(filePath(end-4:end),'.sdm') && ~strcmp(filePath(end-3:end),'.sdm')
                        % account for oddball case where no extension on PRT
                        filePath = [filePath '.sdm'];
                    end
                    fprintf(1,'Assuming %s goes with %s\n',filePath,mtcList(r).name);
        %             filePath = vtcList(index).name;
        %             filePath = [filePath(1:strfind(filePath,'3DMC')-2),'.sdm'];
                    % At this point, STS9 has only 3DMC sdms (ie no regular ones)
                    % Let the script run by spitting out a warning.
                    if exist(filePath,'file')

                        sdm = filePath;
                    else
                        fprintf(1,'WARNING! SDM not found: %s\n',filePath);
                        continue
                    end
                else % if you DO have filepath from an attached PRT
                    if contains(filePath,'RAWork')
                        % Point it to data2 instead
                        filePath = [filesep,'data2',filePath(13:end)];
                    end
                    filePath = [filePath(1:end-4) '.sdm'];
                    sdm = filePath;

                end % if filePath empty
                [PATHSTR,NAME,EXT] = fileparts(filePath);
                sdm = strcat(sdmPath, NAME, EXT);
                
                mtc.ClearObject;
                clear filePath mtc vtc
                
                %% Write to text block
                numFiles = numFiles + 1;
                fbody = [fbody, sprintf('\n"%s" "%s" "%s"',ssm, mtcFile, sdm)];
                fprintf(1,'Done. \n');
            end % for run
        end % for sub
        
        % Write to file
        f = fopen(fileOut, 'w');
        % Header:
            fprintf(f, '\nFileVersion:\t\t  3');
            fprintf(f, '\nTypeOfFunctionalData: MTC');
            fprintf(f, '\n\nRFX-GLM:\t\t\t  1');
            fprintf(f, '\n\nPSCTransformation:\t  1');
            fprintf(f, '\nzTransformation:\t  0');
            fprintf(f, '\nSeparatePredictors:\t  2');
            fprintf(f, '\n\nNrOfStudies:\t\t  %i',numFiles);
        % Body:
            fprintf(f, '%s',fbody); % body copy
        fclose(f);
        fprintf(1,'\n\tFile successfully exported to %s',fileOut);
    end % for task
end % for hem
fprintf(1,'\n\n Finished creating MDM files %s.\n', datestr(now));
diary off