function [fOut] = getCondVTC(fList, fileID)

% out = getUniqueMTC(fList, fID)
% 
% A function to get unique basis from our mtcPile variable, which I need to
% find the matching vtc's for the mtc's (to get the GSR signal).

in = find(cellfun(@(s) ~isempty(strfind(s, fileID)), fList));

fOut = unique(fList(in));








