function generateOmnibus(atlasList)
% INPUTS:
% atlasList is a cell array of atlas names
metricList = {'meanB', 'stdB', 'meanPosB', 'overlap'}; %, 'stdFC'}; % meanFC

fprintf(1,'Aggregating all classification data into one mega file\n\n')

p = specifyPaths();
fpath = p.classifyDataPath; % ends w filesep
% take all the metrics and smash them together into one big classifier file
% does this individually per atlas, so technically can move this loop out
for a = 1:length(atlasList)
    atlas = atlasList{a};
    fprintf(1,'Atlas %s:\n',atlas)
    omnib = [];
    outname = ['Classify_omnibus_' atlas '.mat'];
    % Define header info for omnib, like task list
    temp(1).data = [];
    temp(2).data = [];
    for m = 1:length(metricList)
        metric = metricList{m};
        fprintf(1,'\tMetric %s...',metric)
        
        % Find the right file
        try % appending _effect first
        fname = strjoin({'Classify',metric,atlas,'effect.mat'},'_');
        Data = importdata([fpath fname]);
        catch
            try % excluding _effect
            fname = strjoin({'Classify',metric,[atlas,'.mat']},'_');
            Data = importdata([fpath fname]);
            catch % give up and error out
                error('Cannot find file for %s in %s. Exact name checked is:\n%s\n',metric,atlas,fname);
            end
        end
        
        % Strip out the char padding in task names
        [~,~,fTskLst] = taskTypeConv('all',Data.taskNames,1);
        
        % Z-score the data per metric first, since we don't model metric
        % By default, centers the columns (within parcels, across sub/task)
        % Specifying zscore(X, 0, 2) centers the rows instead (ie per-run)
        Data.hemi(1).data = zscore(Data.hemi(1).data, 0, 2);
        Data.hemi(2).data = zscore(Data.hemi(2).data, 0, 2);
        
        % prep to rearrange subjects in NUMERICAL order
        % Intended to ensure #10 comes after #9 and not before #1
        % maybe unnecessary but I'm being EXTRA careful
        subIDList = Data.subID;
        oldSubIDOrder = struct('ID',{},'num',[]);
        newSubIDOrder = zeros(1,length(subIDList));
        subIDs = cell([1,length(subIDList)]);
        subout = '';
        numSubs = length(subIDs);
        for oldSubInd = 1:numSubs
            oldSubIDOrder(oldSubInd).ID = strtrim(subIDList(oldSubInd,:));
            subNum = strsplit(oldSubIDOrder(oldSubInd).ID,'STS');
            oldSubIDOrder(oldSubInd).num = str2num(subNum{2});
        end
        newSubIDOrder = sort([oldSubIDOrder.num]); % sorted numerically
        for newSubInd = 1:length(newSubIDOrder)
            subIDs{newSubInd} = ['STS' num2str(newSubIDOrder(newSubInd))];
        end
        subout = char(subIDs);
        % This hasn't defined a transformation matrix;
        % Done on-the-fly below instead.
        
        % Rearrange data into new sorted order set above
        thisMetric(1).data = []; % temp temp - reset for each metric
        thisMetric(2).data = [];
        labels(1).l = []; % only need once but this goes each time
        labels(2).l = [];
        for t = 1:length(fTskLst)
            task = fTskLst{t};
            [~,~,newT] = getConditionFromFilename(task);
            taskout{newT} = task;
            for h = 1:2
                % get the task data from the right rows
                taskRows = Data.hemi(h).labels(:,2) == t;
                taskData = Data.hemi(h).data(taskRows,:);
                % re-order by sub, to be extra careful
                for newSubInd = 1:size(Data.subID,1)
                    oldSubInd = strcmp({oldSubIDOrder.ID},subIDs{newSubInd});
                    newPosition = numSubs * (newT-1) + newSubInd;
                    thisMetric(h).data(newPosition,:) = taskData(oldSubInd,:);
                    labels(h).l(newPosition,:) = [newSubInd,newT];
                end % for sub
            end % for hem
        end % for task

        % horizontal concatenation of this metric
        temp(1).data = [temp(1).data thisMetric(1).data];
        temp(2).data = [temp(2).data thisMetric(2).data];
        fprintf(1,'Done.\n')

    end % for metric
    
    % Set all outputs
    omnib.subID = subout; % make sure it's always the same
    omnib.taskNames = char(taskout);
    omnib.hemi(1).parcelInfo = Data.hemi(1).parcelInfo;
    omnib.hemi(2).parcelInfo = Data.hemi(2).parcelInfo;
    omnib.hemi(1).data = temp(1).data;
    omnib.hemi(2).data = temp(2).data;
    omnib.hemi(1).labels = labels(1).l;
    omnib.hemi(2).labels = labels(2).l;
    
    % export
    Data = omnib;
    save([fpath outname],'Data');
    fprintf(1, 'Exported to %s\n\n',[fpath outname])
end % for atlas
fprintf(1,'Done aggregating across all atlases and metrics!\n')
end % function