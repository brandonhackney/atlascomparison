clear; clc;

BasePath = '/data2/2020_STS_Multitask/analysis/';
addpath(BasePath)

subIDList = {'STS3', 'STS4', 'STS10', 'STS11'}; %'STS2'
% atlas = 'schaefer400';
atlas = 'glasser5p3';
% atlas = 'power5p3';
% atlas = 'gordon333dil';

for sub = 1:size(subIDList, 2)
    Pattern = FC_1_PrepParcelData(subIDList{sub}, atlas);
end

cd(BasePath)