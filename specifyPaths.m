function p = specifyPaths

%relevant paths
p.basePath = '/data2/2020_STS_Multitask/analysis/';
p.baseDataPath ='/data2/2020_STS_Multitask/data/';

p.wbFCPath = strcat(p.basePath, 'wholebrainFC/');
p.corrOutPath = strcat(p.wbFCPath, 'corrData/');
p.classifyPath = strcat(p.basePath, 'class/libsvm_scripts/');
p.classifyDataPath = strcat(p.basePath, 'class/data/');