function diceMaps(atlasList)
% Generates an average activation map per task per atlas
% Input: atlasList is a cell array of atlas names
% Relies on existing classification data in analysis/class/data
% Since these files already have all subs, no need to take it as input

paths = specifyPaths;
% Set a threshold
threshold = 0.2;
% Loop through data for each atlas, subject, etc.
fprintf(1,'\nGenerating Dice maps with threshold x > %f:',threshold);

for a = 1:length(atlasList)
    atlas = atlasList{a};
    % Load data file for this atlas (incl all subs), var == Data
    fname = [paths.basePath 'class' filesep 'data' filesep 'Classify_overlap_' atlas '.mat'];
    load(fname);
    taskList = Data.taskNames;
    numSubs = size(Data.subID, 1);
    fprintf(1,'\n\tAtlas %s: ',atlas);
    % Loop through each task bc need a separate file
    for t = 1:size(taskList,1)
        taskName = strtrim(taskList(t,:));
        fprintf(1,'\n\t\tTask %s:',taskName);
        output = [];
        for h = 1:2
            if h == 1
                hem = 'lh';
            elseif h == 2
                hem = 'rh';
            end
            fprintf(1,'\n\t\t\t%s Getting data...', hem);
            % Grab the list of parcels before looping through them
            output(h).parcels = Data.hemi(h).parcelInfo(1).parcels;
                % parcelInfo(1) because it's listing each subject
            % Grab all rows that match the current task (all subs)
            rowT = Data.hemi(h).labels(:,2) == t;
%             s = find(strcmp(subIDs,Data.subID)); % not sure this works
%             % trying to generate an array of indices of the used subIDs
%             % so that e.g. if we don't use sub02, we keep index 2 == sub03
%                 x = length(subList) * (t-1) + s; % an index vector
                for p = 1:length(output(h).parcels)
                    % Count the number of subjects with value > threshold per parcel
                    output(h).parcels(p).diceTally = sum(Data.hemi(h).data(rowT,p) > threshold);
                end % for p == parcel
            fprintf(1,' Done. Outputting file...')
        % Open the template POI file for this atlas
        tempF = [paths.baseDataPath 'sub-04/fs/sub-04-Surf2BV/' 'template_' hem '_' atlas '.annot.poi'];
        outF = [paths.baseDataPath 'deriv_betaFC_audit/' 'DiceOverlap_' taskName '_' hem '_' atlas '.annot.poi'];
        poi = xff(tempF);
        POI = poi.POI;
        % Write your metric to the POI per parcel
        for p = 1:length(POI)
            val = output(h).parcels(p).diceTally / numSubs;
            POI(p).Name = [num2str(round(val * 100)) '%: ' POI(p).Name];
        end % for parcel
        % Rescale the color info to range from 0 to numSub
        colors = addColors({output(h).parcels.diceTally},{POI.Color},numSubs);
        [POI.Color] = colors{:};
        % Export POI to new file
        poi.POI = POI;
        poi.SaveAs(outF);
        
        fprintf(1,' Done. File saved as %s',outF);
        end % for h == hemisphere
    end % for t == task
end % for a == atlas
% Clean up
xff(0,'clearallobjects')
fprintf(1,'\n\nDone exporting new POIs!\n')
end