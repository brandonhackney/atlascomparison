BasePath = '/data2/2020_STS_Multitask/analysis/';
% addpath(BasePath)

subIDList = {'STS1', 'STS2', 'STS3', 'STS4', 'STS5', 'STS6', 'STS7', 'STS8', 'STS10', 'STS11'}; 
%atlasList = {'schaefer400', 'glasser6p0', 'gordon333dil','power6p0' };
% subIDList = {'STS101', 'STS102', 'STS103', 'STS104', 'STS105', 'STS106', 'STS107', 'STS108', 'STS110', 'STS111'}; %sim test 
atlasList = {'schaefer100', 'schaefer200', 'schaefer400', 'schaefer600', 'schaefer800', 'schaefer1000'};

for a = 1:size(atlasList, 2)
    
    atlas = atlasList{a};
    for sub = 1:size(subIDList, 2)
        Pattern = FC_1_ParcelData_NoPrep(subIDList{sub}, atlas);
    end
end

cd(BasePath)