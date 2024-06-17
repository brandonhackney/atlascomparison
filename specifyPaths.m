function p = specifyPaths

%relevant paths
p.basePath = fileparts(which('specifyPaths.m'));
p.root = fileparts(p.basePath); % up one level
p.baseDataPath = fullfile(p.root, 'data');
p.backup = fullfile(p.root, 'backup');
p.deriv = fullfile(p.baseDataPath, 'deriv');
p.nullDir = fullfile(p.baseDataPath, 'sub-04','fs','sub-04','label');
p.template = fullfile(p.baseDataPath, 'sub-04','fs','sub-04-Surf2BV');

% p.wbFCPath = strcat(p.basePath, 'wholebrainFC/');
% p.corrOutPath = strcat(p.wbFCPath, 'corrData/');
p.classifyPath = fullfile(p.basePath, 'class','libsvm_scripts');
p.classifyDataPath = fullfile(p.basePath, 'class','data');