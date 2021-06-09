% Prepare data for classification
% Reads in individual subject-atlas data files and combines per atlas
% Strips out unnecesary variables so that classification data is light
% Extremely slow bc it loads each subject file 8 times
% (because there's an outer loop for task)

% Key variables
subList = [1 2 3 4 5 6 7 8 10 11]; % Update this if new data comes in
    % Generate subIDs
    for s = 1:length(subList)
        subIDs(s,:) = pad(['STS',num2str(subList(s))],5);
    end
numTasks = 8; % excludes RestingState and BowtieRetino
atlasList = {'schaefer400','gordon333dil','glasser6p0','power6p0'};

% Paths
basedir = pwd;
outputdir = [basedir filesep 'class' filesep 'data' filesep];
datadir = [basedir filesep 'ROIs' filesep];

for m = 1:2
    if m == 1
        metric = 'meanB';
        fprintf(1,'Exporting mean betas per contrast.\n')
    else
        metric = 'stdB';
        fprintf(1,'Exporing SDs of betas per contrast.\n')
    end
    for atlas = 1:length(atlasList)
        % do prep
%         subList = dir([datadir '*' atlasList{atlas} '.mat']);

        Data = [];
            Data.subID = subIDs;
            Data.taskNames = [];
            Data.hemi = [];
        index = 0;
        fprintf(1,'\tAtlas: %s\n',atlasList{atlas})
        for task = 1:numTasks
            fprintf(1,'\t\tTask %i of %i\n',task,numTasks)
            for sub = 1:length(subList)
                % **REMEMBER** that this is an index, since we skip 9
                
                % Skip subs if they don't have a data file
                if ~exist([datadir 'STS' num2str(subList(sub)) '_' atlasList{atlas} '.mat'],'file')
                    fprintf('\t\t\tSkipping sub %i : no data\n', subList(sub))
                    continue
                    % This should only happen for sub 9, who dropped out
                    % AND it should only happen if you include 9 in subList
                    
                else
                    fprintf('\t\t\tProcessing sub %i ...', subList(sub))
                    index = index + 1;
                end

                % Load data
                inname = [datadir 'STS' num2str(subList(sub)) '_' atlasList{atlas} '.mat'];
                load(inname)
                
                % On first good run, insert constant info
                if index == 1
                    % Task names
                    if ~strcmp(Pattern.task(task),'RestingState')
                    Data.taskNames(task,:) = pad(Pattern.task(task).name,12);
                    end
                    % Parcel info
                    for h = 1:2
                        % 1 = left, 2 = right
                        Data.hemi(h).parcels.name = Pattern.task(task).hem(h).data.label;
                        Data.hemi(h).parcels.vertices = Pattern.task(task).hem(h).data.vertices;
                        Data.hemi(h).parcels.vertexCoord = Pattern.task(task).hem(h).data.vertexCoord;
                        Data.hemi(h).parcels.ColorMap = Pattern.task(task).hem(h).data.ColorMap;
                    end % for h
                end % if index == 1
                
                % Build data
                x = length(subList) * (task-1) + sub; % an index
                for h = 1:2
                    switch metric
                        case 'meanB'
                            Data.hemi(h).data(x,:) = double([Pattern.task(task).hem(h).data(:).meanEffect]);
                        case 'stdB'
                            Data.hemi(h).data(x,:) = double([Pattern.task(task).hem(h).data(:).glmEffect]);
                    end
                    % Build labels
    %                 Data.hemi(h).labels(x,1) = subList(sub);
                    Data.hemi(h).labels(x,1) = sub;
                    Data.hemi(h).labels(x,2) = task;
                end % for h
                clear Pattern
                fprintf(1,'Done.\n')
            end % for sub
            fprintf(1,'\t\tTask %i of %i done.\n',task,numTasks)
        end % for task

        % Export atlas file
        outname = [outputdir 'Classify_' metric '_' atlasList{atlas} '_effect.mat'];
        save(outname, 'Data');
        fprintf(1,'\tAtlas %s exported to %s\n',atlasList{atlas},outname)
    end % for atlas
    fprintf(1,'Metric %s done.\n',metric)
end % for m (for metric)

fprintf(1,'\n\n Job''s finished!\n')