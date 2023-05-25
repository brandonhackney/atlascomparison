function [templatePOI, varargout] = null_getTemplateNames(atlasGroup, varargin)
% templatePOI = null_getTemplateNames(atlasGroup, (parcelThreshold, maskThreshold))
% Subsets a whole-brain list of parcels to just those within a defined mask
% Invokes the null_parcelNames function to compare against a mask
% Output is an nx2 struct, where n is the number of atlases
% Each element in the output is a cell array of parcel names
% Col 1 is Left Hemisphere, Col 2 is Right Hemisphere
%
% Optional input 2 is the threshold amount for parcel selection,
% which gets passed on to null_parcelNames().
% If a threshold is provided here, force a recalculation of the templatePOI
% This ensures we don't end up using something we think is something else,
% since the threshold value is not saved to the output anywhere.
%
% Optional input 3 is the threshold for mask coverage (across all parcels),
% which also gets passed on to null_parcelNames().
% If no value is provided, uses 0% because anything > 0

if nargin > 1
    parcelThresh = varargin{1};
    assert(isnumeric(parcelThresh), 'Second input (optional!) must be a value between 0 and 1');
    assert(parcelThresh >= 0 && parcelThresh <= 1, 'Second input (optional!) must be a value between 0 and 1');
else
    % Use old value of 15%
    parcelThresh = 0.15;
end

if nargin > 2
    maskThresh = varargin{2};
    assert(isnumeric(maskThresh), 'Third input (optional!) must be a value between 0 and 1');
    assert(maskThresh >= 0 && maskThresh <= 1, 'Third input (optional!) must be a value between 0 and 1');
else
    % Use 0% so the parameter is ignored
    maskThresh = 0;
end

% Define atlas list, but also do some data validation first
if strcmp(atlasGroup, 'nullSMALL')
    % Ensure it uses POI files that actually exist
    atlasList = getAtlasList('null');
    if parcelThresh == 0.15
        % SMALL here means using a tighter threshold
        % So ensure that happens
        fprintf(1, 'Overriding threshold value to 0.9 to ensure we use fewer parcels\n');
        parcelThresh = 0.9;
    end   
else
    % Use what was provided
    atlasList = getAtlasList(atlasGroup);
end
numNulls = length(atlasList);

hemstr = {'lh', 'rh'};
p = specifyPaths;
templatefname = ['Template_' atlasGroup '.mat'];
templatePath = fullfile(p.basePath, templatefname);
validTemplate = false; badFile = false;
    % But if threshold was provided, force recalculation
    if nargin > 1
        badFile = true;
    end
    
while ~validTemplate % This is to avoid writing the else code twice
    if exist(templatePath, 'file') && ~badFile
        templatePOI = importdata(templatePath); % load existing file
        if ~isequal(size(templatePOI), [numNulls, 2])
            % existing file doesn't match expected size
            % loop back and move to the else block
            badFile = true; 
            % continue?
        else
            % Template matches expected size, so keep and break out
            validTemplate = true;
        end
    else
        % show a progress bar instead of printing a row for each null
        cntr = 0;
        progbar = waitbar(cntr,sprintf('Generating list of parcels to keep for each %s.', atlasGroup));

        tic;
        for n = 1:numNulls
            for hemi = 1:2
                fpath = [p.baseDataPath 'sub-04/fs/sub-04-Surf2BV/'];
                poifname = ['sub-04_',hemstr{hemi},'_',atlasList{n},'.annot.poi'];
                fname = fullfile(fpath, poifname);
                % This function expects the hemisphere to come after the first '_'
                % e.g. fname = 'sub-04_lh_null_0001.annot.poi' works
                % but fname = 'sub_04_lh...' fails
                [templatePOI{n, hemi}, naughtyList(n, hemi)] = null_parcelNames(fname, parcelThresh, maskThresh); %compare against sub-04_lh_null_xxx1.poi

                % Increment progress bar across both hemis
                cntr = 2*(n-1) + hemi;
                waitbar(cntr/(2*numNulls), progbar);
            end % for hemi
        end % for null
        close(progbar)
        toc;
        % Collapsing the naughty list across hemis tends to be all 1s
        % Try exporting without this step to see what's happening
%         naughtyList = logical(sum(naughtyList, 2));
        
        % Export so we only need to calculate it once during debugging
            save(templatePath, 'templatePOI');
            fprintf(1, 'Parcel retention lists saved to %s\n', templatePath);
            
            dropListName = fullfile(p.basePath, sprintf('Reject_%s.mat',atlasGroup));
            save(dropListName, 'naughtyList');
            fprintf(1, 'Null rejection list saved to %s\n', dropListName);
            
            if nargout > 1
                varargout{1} = naughtyList;
            end
        validTemplate = true;
    end
end % while
end