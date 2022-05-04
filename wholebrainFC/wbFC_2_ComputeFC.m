function wbFC_2_ComputeFC(subID, atlasID, taskID)

% Data = wbFC_2_ComputeFC(subID, atlasID, taskID)
%
% Computes whole-brain FC to STS_Multitask atlas data. Starts
% with a preprocessed mtc file and works through each parcel vertex
% as a seed. Computes whole-brain correlation map for that vertex.
% Outputs the first 100 components of a PCA, as well as the map.
%
% Inputs:
% subID is a string e.g. 'STS1'
% atlasID is a string e.g. 'glasser6p0'
% taskID is a string e.g. 'SocialLocal'
% (The above should match the use in filenames)


warning off

% relevant paths
p = specifyPaths();
BasePath = p.wbFCPath;
DataPath = strcat(p.baseDataPath, 'deriv_betaMats/', subID, '/');
atlasPath = strcat(p.baseDataPath, 'deriv/', subID, '/', subID, '-Freesurfer/', subID, '-Surf2BV/');
% sdmPath = strcat('/data2/2020_STS_Multitask/data/deriv/', subID, '/');
outPath = p.corrOutPath;
fOut = strcat(strjoin({subID, atlasID, taskID}, '_'), '.mat');


% get list of files matching input parameters
temp = dir(strcat(DataPath, '*', taskID, '*Run*'));
fList = {temp.name};
hemiFlag = contains(upper(fList), 'RH')+1; % so that LH == 1, RH == 2


% set up output file
Data.subID = subID;
Data.atlas = atlasID;
Data.task = taskID;

diary wbFC2_log.txt
fprintf('\n%s %s %s:\n', subID, atlasID, taskID);
try
    % concatenate the betaseries into one giant timeseries (and condition labels)
    allData = cell(1,2);
    labels = cell(1,2);
    tic;
    for f = 1:size(fList, 2) % each run and hem, given a task and sub

        % Load the mat and concatenate onto existing stack
%         cd(DataPath)
        load([DataPath fList{f}]);
        allData{hemiFlag(f)} = [allData{hemiFlag(f)}; betas];
        labels{hemiFlag(f)} = [labels{hemiFlag(f)}; X.label];
        % X.label is an index for condition of interest
        % but what happens for scans like Combo when there's multiple??
    end
    fprintf(1, '\nFinished loading data in %0.2f min!\n', toc/60);

    % get the parcel info
%     cd(atlasPath);
    
    for h = 1:2
        if h == 1
            hemstr = 'lh';
        elseif h == 2
            hemstr = 'rh';
        end
        
        % Get parcel & vertex info from the truncated POI
        poi = xff(strcat(atlasPath, subID, '_', hemstr, '_', atlasID, '_trunc.annot.poi'));
        parcels = poi.POI;
        NumParcels = size(parcels, 2);
        Data.hem(h).parcels = parcels;
        Data.hem(h).numVerts = size(allData{h}, 2);
        
        % Set up the timepoints to include
        [posInd, negInd, ~] = getConditionFromFilename(taskID);
        for c = 1:2 % loop over positive and negative task conditions
            if c == 1
                condition = 'Positive';
                in = find(ismember(labels{h}, posInd));
            elseif c == 2
                condition = 'Negative';
                in = find(ismember(labels{h}, negInd));
            end

    %         cd(BasePath)
            fprintf(1, 'Computing %s vertex correlations for %s parcels: ', condition, hemstr);
            tic;
            for p = 1:NumParcels
                fprintf(1, '%i...', p);
                % get vertex info from the seed parcel
                parcelVerts = parcels(p).Vertices;
                numParcelVerts = size(parcelVerts, 1);

                %loop through all vertices in the parcel
                %STS seed
                % correlate with data from both hemispheres
                corrMaps = single(NaN(numParcelVerts, size(allData{1}, 2)+ size(allData{2}, 2)));
                parfor v = 1:numParcelVerts
                    corrMaps(v, :) = corr(allData{h}(in, parcelVerts(v)), [allData{1}(in, :) allData{2}(in, :)]);
                end
%                 toc; % measure time taken for each parcel

                %probably a good idea to save these correlation matrices to the
                %hard drive? But note that each one is ~numVerticesPerParcel x ~200,000. Per task. 
                %That might be kinda big. I'm not sure. If we save it, put it in
                %it's own derivatives file so it doesn't get mixed up with other
                %stuff.

                % take variance explained by first components
                [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED] = pca(corrMaps');
                %saving the first 100 components for later
                % UNLESS there are less than 100 bc cmp = numParcelVerts
                % In which case pad it with 0s
                    if length(EXPLAINED) < 100
                        EXPLAINED(length(EXPLAINED)+1:100) = 0;
                    end
                pcaOut.var(:, p) = EXPLAINED(1:100); 
                pcaOut.map1(:, p) = SCORE(:, 1);
                clear COEFF SCORE LATENT TSQUARED EXPLAINED

            end % for p = parcels
            Data.hem(h).pca(c).condition = condition;
            Data.hem(h).pca(c).var = pcaOut.var;
            Data.hem(h).pca(c).map1 = pcaOut.map1;
            clear pcaOut
            fprintf(1, '\nFinished all parcels in %0.2f min!\n', toc/60);
        end % for c = condition
        poi.ClearObject;
    end % for h = hemisphere
catch e

    fprintf(1,'There was an error on line %i! The message was:\n%s\n\n',e.stack(1).line, e.message);
    fprintf(1,'\n\nThe identifier was:\n%s\n',e.identifier);
    pause(1);
end

% cd(outPath)
save([outPath fOut], 'Data');


% cd(BasePath)
diary off
end

