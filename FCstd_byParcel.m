function FCstd_byParcel(varargin)

% Pattern = null_FC_1_PrepParcelData_NoPrep(optional: subID)
%
% a revision of the data-based version, which started from Brandon's .mat
% files of timeseries. However, those patterns were lost as part of the
% streamlining for the atlas process. So this code goes back to extracts
% the timeseries again, then reorganizes by parcel for for each atlas.
% Saves it in a .mat file organized for classification analysis (without preprocessing).

tic;
p = specifyPaths;

% figure out which subjects are being analyzed
subList = {'STS1', 'STS2', 'STS3', 'STS4', 'STS5', 'STS6', 'STS7', 'STS8', 'STS10', 'STS11', 'STS14', 'STS17'};
% atlasList = {'glasser6p0', 'gordon333dil', 'power6p0', 'schaefer400'};
atlasList = {'schaefer100', 'schaefer200', 'schaefer600', 'schaefer800', 'schaefer1000'};
hemistr = {'lh', 'rh'};


if nargin == 1 
    subList = {varargin{1}};
end

if nargin == 2
    atlasList = {varargin{2}};
end
numAtlas = size(atlasList, 2);

% set up output structure
template = cell(numAtlas, 2);
poi = cell(numAtlas, 2);

hemiStruct = struct('parcelInfo', [], 'data', [], 'labels', []);
out = struct('subID', [], 'taskNames', [], 'hemi', hemiStruct);
out = repmat(out, numAtlas, 1);


for sub = 1:size(subList, 2)
    
    % get the data
    % returns a numTasks x 2 cell with data structures within each one
    % inside the data structures are fields pattern, pred, contrast and task,
    % among others
    subID = subList{sub};
    fprintf(1, '\nLoading all the relevant timeseries. This will take about 20 sec...\n')
    subData = null_extractTS(subID);
           
    %iterate through each task
    for task = 1:size(subData, 1)
        
        % iterate through hemis
        for h = 1:2
            
            hemi = hemistr{h};
            taskName = subData(task, h).task; %get the full text task name, just in case
                                    
            % get the timeseries out of the larger structure
            data = subData(task, h).pattern;
                      
            % iterate through the atlases, for one hemi
            for atlas = 1:numAtlas
                
                %give minimal feedback
                if mod(atlas, 50) == 1, fprintf(1, '\tTask %i: %s (%s) iter %i... )\n', task, taskName, hemi, atlas); end
                
                % set up output
                if h == 1
                    out(atlas).taskNames = strvcat(out(atlas).taskNames, taskName);
                    if task == 1
                         out(atlas).subID = strvcat(out(atlas).subID, subID);
                    end
                end
                               
                % just once, set up the sub-04 template parcel list
                if isempty(template{atlas, h})
                    temp = xff(strcat(p.template, 'template_', hemistr{h}, '_', atlasList{atlas}, '.annot.poi'));
                    temp2 = temp.POI;
                    templatePOI{atlas, h} = {temp2.Name}';
                end
                
                % for each subject, get the native parcel info for th
                fName = strcat(subID, '_', hemistr{h}, '_', atlasList{atlas}, '.annot.poi'); 
                temp = xff(strcat(p.deriv, subID, '/', subID, '-Freesurfer', '/', subID, '-Surf2BV/', fName));
                poi{atlas, h} = temp.POI; 
                
                
                % select out the STS parcels                
                poiSTS = matchTemplatePOI(templatePOI{atlas, h}, poi{atlas, h});
                if task == 1
                    out(atlas).hemi(h).parcelInfo = poiSTS;
                end
                numParcels = size(poiSTS, 2);
               
                % iterate through each parcel
                stdFC = [];
                for parcel = 1:numParcels
                                        
                    %get timeseries and relevant preds
                    ts = data(:, poiSTS(parcel).Vertices);
                    preds = subData(task,h).pred(:, subData(task, h).contrast{1});
                    
                    
                    % compute FC -- need to specify which preds to use
                    [~, stdFC(parcel)] = ComputeFC_byCond(ts, preds);
                    
                end
                
                % save to output structure
                out(atlas).hemi(h).data = [out(atlas).hemi(h).data; stdFC];
                out(atlas).hemi(h).labels = [out(atlas).hemi(h).labels; [sub task]];
            end
        end
        
    end
    fprintf(1, '\n\n Subject %s finished! Time elapsed: %0.2f minutes\n', subID, toc/60);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%       save results
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

cd(p.classifyDataPath);
fprintf(1, 'Saving output files...')
for atlas = 1:numAtlas
    fOut = strcat('Classify_stdFC_', atlasList{atlas})
    Data = out(atlas);
    save(fullfile(p.classifyDataPath,fOut), 'Data');
end

fprintf(1, 'Done! (%2.2f)\n', toc/60);

