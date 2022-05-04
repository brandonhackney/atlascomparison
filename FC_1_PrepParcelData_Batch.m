clear; clc;

BasePath = '/data2/2020_STS_Multitask/analysis/';
addpath(BasePath)

subIDList = { 'STS1','STS2' 'STS3' 'STS4' 'STS5' 'STS6' , 'STS7' 'STS8', 'STS10', 'STS11'}; 
atlasList = {'gordon333dil','glasser6p0', 'power6p0'}; %{'gordon333dil'}; % 'schaefer400',   %,   , 

for a = 1:size(atlasList, 2)
    
    atlas = atlasList{a};
    
    for sub = 1:size(subIDList, 2)
        Pattern = FC_1_PrepParcelData(subIDList{sub}, atlas);
    end
    
end
cd(BasePath)

