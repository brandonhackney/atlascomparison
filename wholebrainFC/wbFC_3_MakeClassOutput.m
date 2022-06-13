function wbFC_3_MakeClassOutput(atlasID,taskList)

% wbFC_3_MakeClassOuput(atlasID, taskList, inFlag)
%
% Aggregates the whole-brain FC data for one atlas into two SVM-ready files
% One for the 'social' conditions, one for the 'motion' conditions
% Definitions are set up in getConditionFromFilename
%
% INPUTS:
% atlasID is a char array as used in filenames, e.g. 'glasser6p0'
% taskList is a cell array of chars giving the task names
% atlasID and taskList are both used to load files
% inFlag is an integer 1 or 2, used to index from the PCA results of step 2
% 1 returns the 'positive' conditions, 2 returns the 'negative' ones.
% e.g. the positive conditions of an FFA localizer would be the faces.

warning off
p = specifyPaths();

for c = 1:3
    if c == 1
        cond = 'Social';
    elseif c == 2
        cond = 'Motion';
    elseif c == 3
        cond = 'Control';
    end
    out = [];
    % Name the output file based on inFlag
    % So that we know what we're actually classifying
    fOut = strcat(strjoin({'Classify', 'wbFC', cond, atlasID}, '_'), '.mat');
    fprintf('\n%s: Generating classification files for whole-brain FC!\n', atlasID)
    tUsed = 0;
    for t = 1:length(taskList)
        taskID = taskList{t};
        fprintf('%s:\n',taskID)
        % Determine whether to use the positive or negative PCA data
        [pos,neg,~,~,~,soc,mot,ctl] = getConditionFromFilename(taskID);
        % soc and mot will either be empty, or else match pos or neg
        % need to convert pos to 1 and neg to 2 to index from PCA
        if strcmp(cond,'Social')
            check = soc;
        elseif strcmp(cond,'Motion')
            check = mot;
        elseif strcmp(cond,'Control')
            check = ctl;
        else
            check = [];
        end
        if isequal(check,pos)
            pcaFlag = 1;
        elseif isequal(check,neg)
            pcaFlag = 2;
        else
            % Ignore this task for this condition
            fprintf(1,'\tSkipping task - no %s conditions.\n',cond);
            continue
        end
        tUsed = tUsed + 1; % account for above skipping
        % Get the data for this task
        temp = dir(strcat(p.corrOutPath, '*', atlasID, '_', taskID, '.mat'));
        fList = {temp.name};
        % Label with condition name, not task name
        condID = getConditionLabel(taskID, pcaFlag);
        out.taskNames(tUsed,:) = pad(condID, 12);
        
        for f = 1:length(fList) % really your subject-level loop
           load([p.corrOutPath fList{f}]);
           % get subID by using strsplit on filename?
           % oh good god this puts the order as 10 11 1 2 3
           y = strsplit(fList{f},'_');
           out.subID(f,:) = pad(y{1}, 5);
           % Get the actual subject number vs the file index f
           % This hardcodes for format STSXX, which I'd like to avoid but
           sNum = str2double(strrep(y{1},'STS',[]));

           fprintf('\t%s...',out.subID(f,:))
           % Define var to index the right row for this sub-task combo
           % f is subject index, t is task index
           x = length(fList) * (tUsed-1) + f; % accounts for by-sub by-task order
           for h = 1:2
               out.hemi(h).parcelInfo(f).subID = sNum;
               out.hemi(h).parcelInfo(f).parcels = Data.hem(h).parcels;
               out.hemi(h).data(x,:) = Data.hem(h).pca(pcaFlag).var(1, :); % first component
    %            out.hemi(h).labels = [Data.hem(h).labels; f outID]; % not right
                out.hemi(h).labels(x,:) = [f tUsed];
               % labels should be subID 1 2 3 taskIndex 111222333
           end % h
           fprintf('Done.\n')
        end % f
    end % t
    Data = out; % bc every variable we loaded was also called Data
    save([p.classifyDataPath fOut], 'Data');

    fprintf('\n\nData exported to %s\n',[p.classifyDataPath fOut])
end % for inFlag
end