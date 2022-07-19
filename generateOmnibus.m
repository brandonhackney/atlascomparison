function generateOmnibus(atlasList)
% INPUTS:
% atlasList is a cell array of atlas names
taskList = {'AVLocal' 'Bio-Motion' 'BowtieRetino' 'ComboLocal' 'DynamicFaces' 'MTLocal' 'Objects' 'SocialLocal' 'Speech' 'ToM'};
metricList = {'meanB', 'stdB', 'meanPosB', 'overlap','meanFC_noprep'}; 
skipT = {'Motion-Faces'};%

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
        load([fpath fname]);
        catch
            try % excluding _effect
            fname = strjoin({'Classify',metric,[atlas,'.mat']},'_');
            load([fpath fname]);
            catch % give up and error out
                error('Cannot find file for %s in %s. Exact name checked is:\n%s\n',metric,atlas,fname);
            end
        end
        
        % Strip out the char padding in task names
        trickyDick = Data.taskNames; % whos doesn't like structs
        fTask = whos('trickyDick');
        if strcmp(fTask.class,'cell')
            for i = 1:length(Data.taskNames)
                fTskLst{i} = strtrim(Data.taskNames{i}); % strip out the padding
            end
        elseif strcmp(fTask.class, 'char')
            for i = 1:size(Data.taskNames,1)
                fTskLst{i} = strtrim(Data.taskNames(i,:));
            end
        end
        
        % prep to rearrange subjects in NUMERICAL order
        % maybe unnecessary but I'm being EXTRA careful
        sss = Data.subID;
        oldsubids = [];
        newsubids = [];
        subIDs = [];
        subout = [];
        for os = 1:size(sss,1)
            oldsubids(os).ID = strtrim(sss(os,:));
            q = strsplit(oldsubids(os).ID,'STS');
            oldsubids(os).num = str2num(q{2});
        end
        newsubids = sort([oldsubids.num]);
        for ns = 1:length(newsubids)
            subIDs{ns} = ['STS' num2str(newsubids(ns))];
            subout(ns,:) = pad(subIDs{ns},5);
        end
        
        x(1).data = []; % temp temp - reset for each metric
        x(2).data = [];
        labels(1).l = []; % only need once but this goes each time
        labels(2).l = [];
        for t = 1:length(taskList)
            task = taskList{t};
            oldTi = find(contains(fTskLst,task));
            for h = 1:2
            % get the task data from the right rows
            inds = Data.hemi(h).labels(:,2) == oldTi;
            tskd = Data.hemi(h).data(inds,:);
            tskg(h).data = [];
            % re-order by sub, to be extra careful
            for sub = 1:size(Data.subID,1)
                subi = strcmp({oldsubids.ID},subIDs{sub});
                tskg(h).data(sub,:) = tskd(subi,:);
                labels(h).l = [labels(h).l;[find(subi),t]];
            end
            x(h).data = [x(h).data; tskg(h).data];
            % do stuff to x
            
    % skip Motion-Faces since it will be identical to Dynamic in some cases
    % Thus need to change the task column numbering - verify it's good
    % Make sure you have no missing values, ie tasks always in the same order
            end % for hem
        end % for task
        % horizontal concatenation of this metric
        temp(1).data = [temp(1).data x(1).data];
        temp(2).data = [temp(2).data x(2).data];
        fprintf(1,'Done.\n')
    end % for metric
    
    % Set all outputs
    omnib.subID = subout; % make sure it's always the same
    omnib.taskNames = char(taskList'); % char array padded to 12
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