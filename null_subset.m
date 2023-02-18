function null_subset(varargin)
% Take existing null classification files and drop unwanted parcels
% Generates a new slew of class files named nullSMALL
% The old list of parcels extended way too far outside STS, e.g. SPL
% This new batch adds restrictions that should keep it tight around STS

p = specifyPaths;
classPath = p.classifyDataPath;

% Define list of atlases to use
atlasList = getAtlasList('mres'); % 'null'
atlasOutList = getAtlasList('mres'); % 'nullSMALL'
numNulls = length(atlasList);

% Parse optional input - selection threshold
% If not provided, will use a default value of 90%
if nargin > 0
    % Parcel threshold - what % must be on mask?
    thresh = varargin{1};
else
    thresh = 0.9;
end

if nargin > 1
    % Mask threshold - how much of mask must parcels cover in aggregate?
    mthresh = varargin{2};
else
    mthresh = 0;
end

% Load in the Template_nullSMALL.mat file if it exists; generate otherwise
% This is a list of parcel names to keep
% Second input is a threshold - how much of parcel must be within mask?
templatePOI = null_getTemplateNames('mres', thresh, mthresh); % 'nullSMALL'

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
            if strcmp(metric, 'omnibus')
                % idk why these are different
                % I'd rather make an exception here than fix it upstream
                tooManyParcels = {Data.hemi(h).parcelInfo(:).Name};
            else
                % Every other metric looks like this
                tooManyParcels = {Data.hemi(h).parcelInfo(1).parcels(:).name};
            end
            % if keepNames is empty, set keepList empty? to avoid error
            keepList = ismember(tooManyParcels, keepNames);
            % keepList is a logical array against the original parcels
            % keepNames could be in a different order, but it won't matter
            % ismember(big, small) says which from the big list to keep
            
            % Drop from Data.hemi(h).parcelInfo(s).parcels(p)
            if strcmp(metric, 'omnibus')
                % Again, too lazy to standardize the upstream code
                Data.hemi(h).parcelInfo = Data.hemi(h).parcelInfo(keepList);
            else
                for s = 1:length(Data.hemi(h).parcelInfo)
                    Data.hemi(h).parcelInfo(s).parcels = Data.hemi(h).parcelInfo(s).parcels(keepList);
                end
            end
            % Drop from Data.hemi(h).data(:,p)
            Data.hemi(h).data = Data.hemi(h).data(:,keepList);
                
        end % hem
        % Export this modified struct to a new file
        save(fOut, 'Data');
    end % for null
    fprintf(1, ' Done.\n');
end % for metric
% fprintf(1, 'Done subsetting class files. New files saved under name nullSmall\n');
fprintf(1, 'Done subsetting class files. Old mres files overwritten.\n');

end