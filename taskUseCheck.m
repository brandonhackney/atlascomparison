function output = taskUseCheck(taskName,taskType)
    [~, ~, ~, ~, ttype] = getConditionFromFilename(taskName);
    if ((strcmp(taskType, 'social') || strcmp(taskType, 'motion')) && strcmp(ttype, 'both')) || strcmp(ttype,taskType) || strcmp(taskType, 'all')
        output = 1;
    else
        output = 0;
    end
end