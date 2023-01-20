function null_subset()
% Take existing null classification files and drop unwanted parcels
% Generates a new slew of class files named nullSMALL
% The old list of parcels extended way too far outside STS, e.g. SPL
% This new batch 

p = specifyPaths;
classPath = p.classifyDataPath;

% Define list of atlases to use
atlasList = getAtlasList('null');
atlasOutList = getAtlasList('nullSMALL');
numNulls = length(atlasList);

% Load in the Template_nullSMALL.mat file if it exists; generate otherwise
% This is a list of parcel names to keep
% Second input is a threshold - how much of parcel must be within mask?
templatePOI = null_getTemplateNames('nullSMALL', 0.9);

% Use the parcel names in templatePOI to define a list of wanted parcels
% Drop the unwanted parcels from existing classification files
% This avoids recalculating all these metrics, since we just want less info
metricList = {'meanB','stdB','meanPosB','overlap','omnibus'};
for m = 1:length(metricList)
    metric = metricList{m};
    fprintf(1, 'Dropping unwanted parcels from %s class files...', metric);
    for n = 1:numNulls
        atlas = atlasList{n};
        atlasOut = atlasOutList{n};
        fIn = fullfile(classPath, ['Classify_', metric, '_', atlas, '.mat']);
        fOut = fullfile(classPath, ['Classify_', metric, '_', atlasOut, '.mat']);
        
        Data = importdata(fIn); % as Data
        for h = 1:2
            % Get the indices of the parcels we want to keep
            keepNames = templatePOI{n, h};
            tooManyParcels = {Data.hemi(h).parcelInfo(1).parcels(:).name};
            keepList = ismember(tooManyParcels, keepNames);
            % keepList is a logical array against the original parcels
            % keepNames could be in a different order, but it won't matter
            % ismember(big, small) says which from the big list to keep
            
            % Drop from Data.hemi(h).parcelInfo(s).parcels(p)
            for s = 1:length(Data.hemi(h).parcelInfo)
                Data.hemi(h).parcelInfo(s).parcels = Data.hemi(h).parcelInfo(s).parcels(keepList);
            end
            % Drop from Data.hemi(h).data(:,p)
            Data.hemi(h).data = Data.hemi(h).data(:,keepList);
                
        end % hem
        % Export this modified struct to a new file
        save(fOut, 'Data');
    end % for null
    fprintf(1, ' Done.\n');
end % for metric
fprintf(1, 'Done subsetting class files. New files saved under name %s\n', atlasGroup);

end