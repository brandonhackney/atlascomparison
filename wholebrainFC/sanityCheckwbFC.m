function sanityCheckwbFC
% Inspect the percent variance in the first PCA component
% In each file, take Data.hem(h).pca(1){1,:};
% Generate a histogram for each hemisphere, over all subs
% One set summarizing by parcel, one set by task
% The expectation is that the histograms will all peak in the 60-80% range
% Nothing should be too skewed toward 0% OR very close to 100%
% ...except MT is reasonably closer to 100% than STS bc this is FC
% lower-level areas will have consistent connectivity, agnostic of task
% higher-level areas will have connectivity that depends on specifics

paths = specifyPaths();
posneg = 1; % 1 = pos, 2 = neg

subList = {'STS1' 'STS2' 'STS3' 'STS4' 'STS5' 'STS6' , 'STS7' 'STS8', 'STS10', 'STS11'}; 
atlasID = 'glasser6p0';
taskList = {'AVLocal' 'Bio-Motion' 'BowtieRetino' 'ComboLocal' 'DynamicFaces' 'Motion-Faces' 'MTLocal' 'Objects' 'SocialLocal' 'Speech' 'ToM'};

% Define struct
hem = struct('byparcel',[],'bytask',[]);
for i = 1:2
    hem(i).byparcel = struct('dat',[],'name',[]);
    hem(i).bytask = struct('dat',[],'name',[]);
end

fprintf(1,'\nGetting Data:\n')
for s = 1:length(subList)
    subID = subList{s};
    fprintf(1,'\t%s...',subID)
    for t = 1:length(taskList)
        taskID = taskList{t};
        fname = [subID '_' atlasID '_' taskID '.mat'];
        load([paths.corrOutPath fname])
        for h = 1:2
            % 1 = LH, 2 = RH
            % Grab the %variance explained by first component only (of 100)
            % Each element is a different seed parcel
            x = Data.hem(h).pca(posneg).var(1,:);
            numParcel = length(x);
            for p = 1:numParcel
                % Avoid indexing something that doesn't exist yet by doing:
                if s == 1 && t == 1
                    hem(h).byparcel(p).dat = x(p);
                    hem(h).byparcel(p).name = Data.hem(h).parcels(p).Name;
                else
                    hem(h).byparcel(p).dat = [hem(h).byparcel(p).dat; x(p)];
                    
                end
                
                if s == 1 && p == 1
                    hem(h).bytask(t).dat = x(p);
                    hem(h).bytask(t).name = taskID;
                else
                    hem(h).bytask(t).dat = [hem(h).bytask(t).dat; x(p)];
                end
            end % for parcel
        end % for hem, inside task
    end % for task
    fprintf(1,' Done.\n')
end % for sub

fprintf(1,'\nPlotting results:')
for pl = 1:2 % two plot types
    if pl == 1
        fprintf(1,'\n\tBy Parcel:')
    elseif pl == 2
        fprintf(1,'\n\tBy Task:')
    end
    for h = 1:2
        % After extracting data, generate histograms per parcel
        if h == 1
            hstr = 'LH';
        elseif h == 2
            hstr = 'RH';
        end
        fprintf(1,' %s...',hstr)
        fi = (pl-1)*2 + h;
        fh(fi) = figure();
        bins = 0:10:100;
        if pl == 1
            suptitle([hstr ' by Parcel']);
            numParcels = length(hem(h).byparcel);
            spDim1 = ceil(sqrt(numParcels));
            spDim2 = floor(sqrt(numParcels));
            for p = 1:numParcels
                subplot(spDim2,spDim1,p)
                histogram(hem(h).byparcel(p).dat,bins)
                xlabel(strrep(hem(h).byparcel(p).name,'_','\_'));
                xlim([0 100])
%                 ylim([0 10])
            end % for parcel
        elseif pl == 2
            suptitle([hstr ' by Task']);
            numTasks = length(hem(h).bytask);
            spDim1 = ceil(sqrt(numTasks));
            spDim2 = floor(sqrt(numTasks));
            for t = 1:numTasks
                subplot(spDim2, spDim1, t)
                histogram(hem(h).bytask(t).dat,bins)
                xlabel(strrep(hem(h).bytask(t).name,'_','\_'));
                xlim([0 100])
%                 ylim([0 10])
            end % for task
        end % if plot type
        fprintf(1,'Done.')
    end % for hem
end % for plot

fprintf(1,'\n')
end