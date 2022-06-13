clear; clc;

diary on;
BasePath = '/data2/2020_STS_Multitask/analysis/';
subIDList = {'STS1' 'STS2' 'STS3' 'STS4' 'STS5' 'STS6' , 'STS7' 'STS8', 'STS10', 'STS11'}; 
% taskList = {'Bio-Motion', 'ComboLocal','DynamicFaces', 'MTLocal', 'SocialLocal', 'AVLocal', 'Speech', 'ToM'};
taskList = {'AVLocal' 'Bio-Motion' 'BowtieRetino' 'ComboLocal' 'DynamicFaces' 'Motion-Faces' 'MTLocal' 'Objects' 'SocialLocal' 'Speech' 'ToM'};
atlasList = {'glasser6p0', 'gordon333dil', 'power6p0' 'schaefer400'};


% if exist('CorrData', 'file')
%     load('CorrData.mat');
% else
%     CorrData = [];
% end

for t = 1:length(taskList) 
    taskName = taskList{t};
    [~,~, taskID, ~] = getConditionFromFilename(taskName);
    
    for a = 1:length(atlasList)       
        atlasID = atlasList{a};
    
        for sub = 1:length(subIDList)
            subID = subIDList{sub};
            wbFC_2_ComputeFC(subID, atlasID, taskName);
                      
%             subIn = str2num(subIDList(4:end));
%             % not sure what the means expected below are???
%             tempStruct(taskID).corrMat(:, :, subIn) = out.means;
%             CorrData = setfield(CorrData, atlasList{a}, tempStruct);
        end % for sub
    end % for a
end % for t

% cd(BasePath)
% save('CorrData.m', 'CorrData');

diary off

