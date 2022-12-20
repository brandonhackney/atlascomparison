function poiOut = null_matchTemplatePOI(templateROIs, subPOI)

% Selects out relevant ROIs from POI file based on parcel name.
% templatePOI and subPOI are the xxx.POI structures derived from
% xff(poifName). xff files cannot be passed into and out of functions, so
% only the relevant structure is retained. Output is the same structure
% with only the relevant ROIs retained.

subROIs = {subPOI.Name}';
numROIs = size(templateROIs, 1);
in = zeros(numROIs,1); % 0s must be converted to blanks, used as indices

for roi = 1:numROIs  
   ID = deblank(templateROIs(roi, :));
%    matchlist = ~cellfun(@isempty, strfind(ID, subROIs));
%     matchlist = contains(subROIs, ID); % fails if e.g. 's1' AND 's12'
    matchlist = strcmp(subROIs,ID{1});
%     fprintf(1,'%i\n',roi);
    result = find(matchlist == 1);
    if ~any(result); result = 0; end % avoid an indexing issue
   in(roi) = result;
end

% drop the 0s, since these are indices
in(in == 0) = []; 

if isempty(in)
    error('No names in list2 match the template in list1!')
else
    poiOut = subPOI(in);
end
end

