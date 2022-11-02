function poiOut = matchTemplatePOI(templateROIs, subPOI)

% Selects out relevant ROIs from POI file based on parcel name.
% templatePOI and subPOI are the xxx.POI structures derived from
% xff(poifName). xff files cannot be passed into and out of functions, so
% only the relevant structure is retained. Output is the same structure
% with only the relevant ROIs retained.

subROIs = {subPOI.Name}';

for roi = 1:size(templateROIs, 1)  
   ID = deblank(templateROIs(roi, :));
%    matchlist = ~cellfun(@isempty, strfind(ID, subROIs));
%     matchlist = contains(subROIs, ID); % fails if e.g. 's1' AND 's12'
    matchlist = strcmp(subROIs,ID{1});
%     fprintf(1,'%i\n',roi);
   in(roi) = find(matchlist == 1);
end
poiOut = subPOI(in);

