function [isused, usednames, varargout] = taskTypeConv(taskType, taskList, numSubs)
% taskType is a string, either 'social', 'motion', 'control', or 'all'
% taskList is the padded character array of task names used in class files
% output 1 is a logical array of size (numSubs x numTasks) x 1
% output 1 indicates which rows of classification data to keep
% output 2 is a list of kept task names from input taskList
% optional output 3 is a standardized version of taskList
z = whos('taskList');

if strcmp(z.class,'cell')
    numTasks = size(taskList,1);  % watch this one
elseif strcmp(z.class,'char')
    numTasks = size(taskList,1);
end
isused = zeros([numTasks,1]);
names = cell(1,numTasks);

if strcmp(taskType, 'all')
    isused = ones([numTasks * numSubs,1]);
end

keep = zeros([numTasks,1]);
for i = 1:numTasks
    if strcmp(z.class,'cell')
        taskName = strtrim(taskList{i}); % strip out the padding
    elseif strcmp(z.class, 'char')
        taskName = strtrim(taskList(i,:));
    end
%         [~, ~, ~, ~, ttype] = getConditionFromFilename(taskName);
%         if strcmp (ttype, 'both') || strcmp(ttype,taskType)
%             % say yes for all subjects under that task
%             output(((i-1)*numSubs)+(1:numSubs)) = 1;
%         end
    if ~strcmp(taskType, 'all')
        keep(i) = taskUseCheck(taskName,taskType);
        isused(((i-1)*numSubs)+(1:numSubs)) = keep(i);
    else
        keep(i) = 1;
    end
    % standardize the list of task names
    names{i} = taskName;
end
isused = logical(isused);
% Export a list of KEPT names, since 'names' is just all names in order.
usednames = names(logical(keep));
    if nargout > 2
        varargout{1} = names; % regular names
    end
end