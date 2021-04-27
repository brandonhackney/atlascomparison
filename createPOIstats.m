function createPOIstats(data, datafield)        

% createPOIstats(data, datafield) 
%
% Takes an input a structure with key fields subID, atlas, taskName and hemi.
% Also requires the field that has the stat to be displayed to be specified
% ('datafield'). Loads in the template poi for each atlas and replaces the
% color with the new one specified and the parcel name with the stat value.
% Save the output in the directory in which the function was called.

stats = getfield(data, datafield);

templatePath = '/data2/2020_STS_Multitask/data/sub-04/fs/sub-04-Surf2BV';
templatefName = strcat('template_', data.hem, '_', data.atlas, '.annot.poi');
outDir = strcat(templatePath, '/deriv');
outfName = strcat(strjoin({datafield, data.subID, data.taskName, data.atlas, data.hem}, '_'), '.poi');

cd(templatePath)
poi = xff(templatefName);
NumParcels = poi.NrOfPOIs;

for p = 1:NumParcels
    poi.POI(p).Name = sprintf('%.2f', stats(p));
    poi.POI(p).Color = data.color(p, :);
end

cd(outDir)
poi.SaveAs(outfName);
poi.ClearObject;