function taskIn = findTaskIn(includeList, possibleList)

for t = 1:max(size(includeList))
    tName = includeList{t};
    taskIn(t) = find(strcmp(tName, possibleList.taskNames) == 1);
end