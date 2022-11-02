function generateOmnibus(atlasList)
% INPUTS:
% atlasList is a cell array of atlas names
taskList = {'AVLocal' 'Bio-Motion' 'BowtieRetino' 'ComboLocal' 'DynamicFaces' 'Motion-Faces' 'MTLocal' 'Objects' 'SocialLocal' 'Speech' 'ToM'};
metricList = {'meanB', 'stdB', 'meanPosB', 'overlap', 'stdFC'};

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
        if m == 1
            % hold for comparison
            prevTaskList = fTskLst;
        end
        
        % prep to rearrange subjects in NUMERICAL order
        % Intended to ensure #10 comes after #9 and not before #1
        % maybe unnecessary but I'm being EXTRA careful
        sss = Data.subID;
        oldsubids = struct('ID',{},'num',[]);
        newsubids = zeros(1,length(sss));
        subIDs = cell([1,length(sss)]);
        subout = '';
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
        
        % Rearrange data into new sorted order set above
        x(1).data = []; % temp temp - reset for each metric
        x(2).data = [];
        labels(1).l = []; % only need once but this goes each time
        labels(2).l = [];
        if ~isequal(sss,subout) && ~isequal(fTskLst, prevTaskList)
            error('Subject and/or task lists are in a different order!')
        else
            % If no need to rearrange, then just slice it straight in
            x(1).data = Data.hemi(1).data;
            x(2).data = Data.hemi(2).data;
            labels(1).l = Data.hemi(1).labels;
            labels(2).l = Data.hemi(2).labels;
        end
        % horizontal concatenation of this metric
        temp(1).data = [temp(1).data x(1).data];
        temp(2).data = [temp(2).data x(2).data];
        fprintf(1,'Done.\n')
        
        prevTaskList = fTskLst; % update
    end % for metric
    
    % Set all outputs
    omnib.subID = subout; % make sure it's always the same
    omnib.taskNames = char(fTskLst); % char array padded to 12
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