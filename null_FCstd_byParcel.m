function null_FCstd_byParcel(varargin)

% Pattern = null_FC_1_PrepParcelData_NoPrep(optional: subID)
%
% a revision of the data-based version, which started from Brandon's .mat
% files of timeseries. However, those patterns were lost as part of the
% streamlining for the null process. So this code goes back to extracts
% the timeseries again, then reorganizes by parcel for for each atlas.
% Saves it in a .mat file organized for classification analysis (without preprocessing).

tic;
p = specifyPaths;

numNull = 1000; % set up for null iterations
TR = 2;  %% This looks like a red flag
poi = cell(numNull, 2);
hemistr = {'lh', 'rh'};

% set up output structure
hemiStruct = struct('parcelInfo', [], 'data', [], 'labels', []);
out = struct('subID', [], 'taskNames', [], 'hemi', hemiStruct);
out = repmat(out, numNull, 1);

% figure out which subjects are being analyzed
if nargin > 0
    subList = {varargin{1}};
else
    subList = {'STS1', 'STS2', 'STS3', 'STS4', 'STS5', 'STS6', 'STS7', 'STS8', 'STS10', 'STS11', 'STS14', 'STS17'};
end


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
                        
            % set up template file for STS parcel selection 
            templatePath = fullfile(p.basePath, 'nullTemplate.mat');
            if exist(templatePath, 'file')
                load(templatePath);
            else
                fprintf(1, '\nERROR: TEMPLATE FILE FOR %s:%s NOT FOUND \n', subID, atlas);
            end
            
            % get the timeseries out of the larger structure
            data = subData(task, h).pattern;
                      
            % iterate through the atlases, for one hemi
            for null = 1:numNull
                
                %give minimal feedback
                if mod(null, 50) == 1, fprintf(1, '\tTask %i: %s (%s) iter %i... )\n', task, taskName, hemi, null); end
                
                % set up output
                if h == 1
                    out(null).taskNames = strvcat(out(null).taskNames, taskName);
                    if task == 1
                         out(null).subID = strvcat(out(null).subID, subID);
                    end
                end
                
                
                % set up atlas, create poi from annot
                atlas = sprintf('null_%04.f',null);
                if isempty(poi{null, h})
                    nullfName_nohemi = [atlas, '.annot'];
                    Cfg.SUBJECTS_DIR = fullfile(p.deriv, subID, [subID, '-Freesurfer']);
                    Cfg.projectDir = Cfg.SUBJECTS_DIR;
                    Cfg.hemis = {hemi};
                    Cfg.atlas = nullfName_nohemi;
                    poi{null, h} = null_makePOI(subID, Cfg); % nice function
                end
                
                
                % select out the STS parcels
                poiSTS = matchTemplatePOI(templatePOI{null, h}, poi{null, h});
                if task == 1
                    out(null).hemi(h).parcelInfo = poiSTS;
                end
                numParcels = size(poiSTS, 2);
               
                
                stdFC = [];
                for parcel = 1:numParcels
                                        
                    %get timeseries and relevant preds
                    ts = data(:, poiSTS(parcel).Vertices);
                    preds = subData(task,h).pred(:, subData(task, h).contrast{1});
                    
                    
                    % compute FC -- need to specify which preds to use
                    [~, stdFC(parcel)] = ComputeFC_byCond(ts, preds);
                    
                end
                
                % save to output structure
                out(null).hemi(h).data = [out(null).hemi(h).data; stdFC];
                out(null).hemi(h).labels = [out(null).hemi(h).labels; [sub task]];
            end
        end
        
    end
    fprintf(1, '\n\n Subject %s finished! Time elapsed: %0.2f hours\n', subID, toc/60);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%       save results
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

cd(p.classifyDataPath);
fprintf(1, 'Saving output files...')
for null = 1:numNull
    fOut = strcat('Classify_stdFC_', sprintf('null_%04.f',null))
    Data = out(null);
    save(fullfile(p.classifyDataPath,fOut), 'Data');
end

fprintf(1, 'Done! (%2.2f)\n', toc/60);

