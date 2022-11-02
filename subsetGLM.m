function subsetGLM(subList, atlasList)

% Loads whole-brain GLM data and subsets it, based on atlas
% Loops subject first, THEN atlas
% Doing it this way lets you keep the subject data in memory longer,
% which should hopefully speed up the process

% Almost done - add some fprintf to track progress
% Then modify the baseGLM function to drop all the atlas stuff and add tMap
% Be sure to save that one as just STSx_GLMs.mat

% Use this output to feed diceBatch2()

p = specifyPaths;
homeDir = p.basePath;
hemstr = {'LH','RH'};

fprintf(1,'Subsetting GLM files to just the STS mask, by atlas.\n');

for s = 1:length(subList)
    snum = subList(s);
    subj = ['STS', num2str(snum)];
    
    fprintf(1,'Subject %s:\n',subj);
    
    % load in the GLM file
    fprintf(1, '\tLoading data...');
    glmfname = [homeDir filesep 'ROIs' filesep 'GLM' filesep subj '_GLMs.mat'];
    input = importdata(glmfname);
    fprintf(1, 'Done.\n')
    
    for a = 1:length(atlasList)
        atlasName = atlasList{a};
        fprintf(1, '\tSubsetting GLMs for subject %s atlas %s\n:', subj, atlasName);
        
        % Extract the parcel info for this atlas
        % We will only calculate betas within the selected parcels
        fname = [homeDir filesep 'class' filesep 'data' filesep 'Classify_meanB_' atlasName '.mat'];
        Data = importdata(fname);
        
        % Duplicate the GLM data for modification
        GLM = input;
        
        for h = 1:2
            hem = hemstr{h};
            
            % Create the atlas mask, collapsing across parcels
            temp = [];
            for p = 1:length(Data.hemi(h).parcelInfo(s).parcels)
                temp = [temp; Data.hemi(h).parcelInfo(s).parcels(p).vertices];
            end
            glmMask(h).verts = sort(unique(temp)); % Sort so it's not in parcel order
            
            numCont = length(input.task);
            for t = 1:numCont
                taskName = input.task(t).name;
                fprintf(1,'\t\tTask %s %s...',taskName, hem);
                
                % Get the whole brain t-statistic map
                tMap = input.task(t).hem(h).tMap;
                numVert = input.task(t).hem(h).numVert;
                
                % Truncate map to only use parcellated region
                if length(glmMask(h).verts) == length(tMap)
                    fullMap = zeros([numVert,1]);
                    fullMap(glmMask(h).verts) = tMap;
                else
                    fullMap = zeros([numVert,1]);
                    fullMap(glmMask(h).verts) = tMap(glmMask(h).verts);
                end

                % Threshold the masked data at FDR
                df = input.task(t).hem(h).df;
                [cluster, ~] = fdrCluster(fullMap,df);

                % Export significant vertices for Dice coefficient
                GLM.task(t).hem(h).cluster = cluster;
%                 GLM.task(t).hem(h).numVert = length(tMap);
                

                
                fprintf(1,'Done.\n')
            end % for t
            
            % for each task, but after both hemispheres:
            if h == 2
                % Eliminate whole-brain tMap from output, to save space
                % bc we're exporting to a new file per atlas
                GLM.task(t).hem = rmfield(GLM.task(t).hem, 'tMap');
            end
            
        end % for h

        % Export
        fout = [homeDir filesep 'ROIs' filesep 'GLM' filesep subj '_GLMs_' atlasName '.mat'];
        fprintf(1,'\tSubject %s atlas %s done. Exporting to %s...', subj, atlasName, fout);
        save(fout,'GLM');
        fprintf(1,'Done.\n');
    end % for a
    
    fprintf(1,'Subject %s all atlases processed!\n',subj)
end % for s

fprintf(1,'\n\nGLM data subset for all subjects and atlases!\n')
end