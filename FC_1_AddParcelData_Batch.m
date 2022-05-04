clear; clc;

BasePath = '/data2/2020_STS_Multitask/analysis/';
% addpath(BasePath)

subIDList ={'STS8'};%, 'STS10'};%, 'STS11'}; % {'STS8', 'STS10', 'STS11'}; %{'STS4', 'STS5', 'STS6'}; % {'STS1', 'STS2', 'STS3'}; %, , }; 
atlasList = {'glasser6p0', 'gordon333dil', 'power6p0' 'schaefer400'};% 
taskList = {'Bio-Motion'};%{'SocialLocal', 'ComboLocal', 'AVLocal', 'Speech', 'ToM', 'DynamicFaces'};  %'Bio-Motion', 'MT-Local', 




for t = 1:size(taskList)
    
    taskName = taskList{t};
    [~,~, taskID, ~] = getConditionFromFilename(taskName);
    
    for a = 1:size(atlasList, 2)
        
        atlas = atlasList{a};
        
        for sub = 1:size(subIDList, 2)
            out = FC_1_AddParcelData(subIDList{sub}, atlas, taskName);
            
            subIn = str2num(subIDList(4:end));
            tempStruct(taskID).corrMat(:, :, subIn) = out.Means;
            CorrData = setfield(CorrData, atlasList{a}, tempStruct);
        end
       
    end
end
cd(BasePath)

