clear; clc;

load('QC_structure_16-Jul-2020.mat'); %var: output

NumSubs = length(output.subject);

fList = []; VolList = []; BBoxList = [];
for sub = 1:NumSubs
    try
        fList = cat(1, fList, {output.subject(sub).VTC.name}');
        VolList = cat(1, VolList, {output.subject(sub).VTC.numVolumes}');
        BBoxList = cat(1, BBoxList, {output.subject(sub).VTC.boundingBox}');
    catch
        pause
    end
end

% parse the filesnames for the conditions (3rd segment) and subID (1st
% segement)

for x = 1:length(fList)
    temp = strsplit(fList{x},'_');
    fList_split(x,:) = temp(1:5);
    clear temp
end
% fList_split = cellfun(@(s) strsplit(s, '_'), fList, 'UniformOutput', false);
fList_conds = cat(1, fList_split(:, 3));
fList_subID = cat(1, fList_split(:, 1));


% sort the data by the condition name 
[fList_conds_srted, I] = sort(fList_conds);
sorted = [fList_conds(I) VolList(I) fList_subID(I) fList_split(I,2) fList_split(I,4)];

% Generate summary table
myTable(:,1) = unique(sorted(:,1));
for i = 1:length(myTable)
   myTable(i,2) = sorted(find(strcmp(sorted(:,1),myTable(i,1)),1),2); 
end

%reorganize the rest to sanity check
