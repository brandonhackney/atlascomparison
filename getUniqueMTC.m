function [fOut, pOut] = getUniqueMTC(fList, fPath, fileID)

% out = getUniqueMTC(fList, fID)
% 
% A function to get unique basis from our mtcPile variable, which I need to
% find the matching vtc's for the mtc's (to get the GSR signal).

in = find(cellfun(@(s) ~isempty(strfind(s, fileID)), fList));

b = fList(in);
c = cellfun(@(s) strsplit(s, '_'), b, 'UniformOutput', 0);

[fOut, IA, IC] = unique(cellfun(@(s) strjoin({s{1:7}}, '_'), c, 'UniformOutput', 0), 'rows', 'stable');
pOut = fPath(IA);







