function taskList = getTaskList(taskType)
% taskList = getTaskList(taskType)
% taskType is one of: social, motion, control, or all
% output is a list of all tasks that fit that type, formatted as cell
% You can also provide no input to quickly get the full list of tasks.
%
% Works by loading a list of all possible tasks, then subsetting.
% Most useful for the end stage of classification, when you might want to
% flexibly exclude some tasks without completely re-generating the files.


% Validate input
if ~exist('taskType', 'var')
    taskType = 'all'; % set default
end
checkList = {'social','motion','control','all'};
emsg = 'Invalid input: taskType must be type char, one of: social, motion, control, or all';
assert(sum(contains(checkList, taskType)), emsg);

% Specify folder, just in case we're currently somewhere else
p = specifyPaths();
fdir = p.basePath;
fname = 'getFilePartsFromContrast.mat';
fpath = fullfile(fdir, fname);

% Get the list of tasks to start from
contrastList = importdata(fpath);
fullTaskList = {contrastList(:).contrast};

% Re-order the tasks from alphabetical to grouped order
newOrder = cell(length(fullTaskList), 1);
for i = 1:length(fullTaskList)
    task = fullTaskList{i};
    [~,~,taskInd] = getConditionFromFilename(task);
    newOrder{taskInd} = task;
end

% Truncate the list based on task type
[~,taskList] = taskTypeConv(taskType,newOrder,1);

end