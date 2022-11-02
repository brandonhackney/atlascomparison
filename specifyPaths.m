function p = specifyPaths

%relevant paths
p.root = '/data2/2020_STS_Multitask/';
p.basePath = strcat(p.root, 'analysis/');
p.baseDataPath = strcat(p.root, 'data/');
p.backup = strcat(p.root, 'backup/');
p.deriv = strcat(p.baseDataPath, 'deriv/');
p.nullDir = strcat(p.baseDataPath, 'sub-04/fs/sub-04/label/');
p.template = strcat(p.baseDataPath, 'sub-04/fs/sub-04-Surf2BV/');

% p.wbFCPath = strcat(p.basePath, 'wholebrainFC/');
% p.corrOutPath = strcat(p.wbFCPath, 'corrData/');
p.classifyPath = strcat(p.basePath, 'class/libsvm_scripts/');
p.classifyDataPath = strcat(p.basePath, 'class/data/');