% Prepare data for classification
% Reads in individual subject-atlas data files and combines per atlas
% Strips out unnecesary variables so that classification data is light
% Extremely slow bc it loads each subject file something like 8 times
% (because there's an outer loop for task)

% Key variables

%%% These need to be manually adjusted!! %%%
subList = [1 2 3 4 5 6 7 8 10 11]; % Update this if new data comes in
    % Generate subIDs
    for s = 1:length(subList)
        subIDs(s,:) = pad(['STS',num2str(subList(s))],5);
    end
load('getFilePartsFromContrast.mat');
numTasks = length(conditionList); % excludes RestingState
atlasList = {'schaefer400','gordon333dil','glasser6p0','power6p0'};
%%% These need to be manually adjusted!! %%%

% Paths
basedir = pwd;
outputdir = [basedir filesep 'class' filesep 'data' filesep];
datadir = [basedir filesep 'ROIs' filesep];

for m = 1:4
    if m == 1
        metric = 'meanB';
        fprintf(1,'Exporting mean betas per contrast.\n')
    elseif m == 2
        metric = 'stdB';
        fprintf(1,'Exporing SDs of betas per contrast.\n')
    elseif m == 3
        metric = 'meanNegB';
        fprintf(1,'Exporting mean negative activation per condition.\n')
    elseif m == 4
        metric = 'meanPosB';
        fprintf(1,'Exporting mean positive activation per condition.\n')
    end
    for atlas = 1:length(atlasList)
        % do prep
%         subList = dir([datadir '*' atlasList{atlas} '.mat']);

        Data = [];
            Data.subID = subIDs;
            Data.taskNames = '';
            Data.hemi = [];
        index = 0;
        fprintf(1,'\tAtlas: %s\n',atlasList{atlas})
        for task = 1:numTasks
            fprintf(1,'\t\tTask %i of %i\n',task,numTasks)
            goodSub = 0;
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
                    goodSub = goodSub + 1;
                end

                % Load data
                inname = [datadir 'STS' num2str(subList(sub)) '_' atlasList{atlas} '.mat'];
                load(inname)
                
                % On first good run, insert constant info
                if goodSub == 1 &&  ~strcmp(Pattern.task(task),'RestingState')
                    % Insert task name for this task
                    Data.taskNames(task,:) = pad(Pattern.task(task).name,12);
                end

                % Parcel info
                for h = 1:2
                    % 1 = left, 2 = right
                    for p = 1:length(Pattern.task(task).hem(h).data)
                        % I really hate structs like why can't I just
                        % grab the whole goddamn field at once
                    Data.hemi(h).parcelInfo(sub).subID = subList(sub);
                    Data.hemi(h).parcelInfo(sub).parcels(p).name = Pattern.task(task).hem(h).data(p).label;
                    Data.hemi(h).parcelInfo(sub).parcels(p).vertices = Pattern.task(task).hem(h).data(p).vertices;
                    Data.hemi(h).parcelInfo(sub).parcels(p).vertexCoord = Pattern.task(task).hem(h).data(p).vertexCoord;
                    Data.hemi(h).parcelInfo(sub).parcels(p).ColorMap = Pattern.task(task).hem(h).data(p).ColorMap;
                    end % for p
                end % for h

                
                % Build data
                x = length(subList) * (task-1) + sub; % an index
                    % accounts for having per subject per task order
                for h = 1:2
                    switch metric
                        case 'meanB'
                            Data.hemi(h).data(x,:) = double([Pattern.task(task).hem(h).data(:).meanEffect]);
                        case 'stdB'
                            Data.hemi(h).data(x,:) = double([Pattern.task(task).hem(h).data(:).glmEffect]);
                        case 'meanNegB'
                            Data.hemi(h).data(x,:) = double([Pattern.task(task).hem(h).data(:).meanNegActv]);
                        case 'meanPosB'
                            Data.hemi(h).data(x,:) = double([Pattern.task(task).hem(h).data(:).meanPosActv]);
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