clear; clc;

BasePath = '/data2/2020_STS_Multitask/analysis/';
subIDList = {'STS1' 'STS2' 'STS3' 'STS4' 'STS5' 'STS6', 'STS7' 'STS8', 'STS10', 'STS11'};
taskIDList = {'Bio-Motion', 'ComboLocal','DynamicFaces', 'MTLocal', 'SocialLocal', 'AVLocal', 'Speech', 'ToM', 'BowtieRetino'};

for t = 1:size(taskIDList, 2)
    taskName = taskIDList{t};
    cd
    for sub = 1:size(subIDList, 2)       
        wbFC_1_ComputeBetas(subIDList{sub}, taskName); 
        xff(0, 'clearallobjects')
    end    
end

cd(BasePath)

