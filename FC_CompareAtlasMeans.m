clear; clc;

BasePath = '/data2/2020_STS_Multitask/analysis/';
ROIPath = strcat(BasePath, 'ROIs/');
FCPath = strcat(BasePath, 'ROIs/FC');

cd(FCPath)

atlasList = {'schaefer400', 'gordon333dil', 'glasser5p3'}; % ,% 'power5p3'
NumAtlas = size(atlasList, 2);

temp = struct('vertices', [], 'numVerts', []);
data = struct('atlas', [], 'hem', temp);
for a = 1:NumAtlas 
   
    atlasName = atlasList{a};
    data(a).atlas = atlasName;
    fprintf(1, 'Working on %s atlas data...', atlasName);
    
    fName = strcat('CorrMats_', atlasName, '.mat');
    load(fName)
    
    NumSubs = size(CorrData, 2);
    for sub = 1:NumSubs
        
        NumTasks = size(CorrData(sub).task, 2);
        for task = 1:NumTasks
            
            if ~isempty(CorrData(sub).task(task).hem) %to prevent crashing for missing scans
                for hemi = 1:2
                    
                    %aggregate the mean parcel scores across subjects
                    data(a).hem(hemi).task{task}.meanFC(:, sub) = cell2mat({CorrData(sub).task(task).hem(hemi).FC.meanFC}');
                    data(a).hem(hemi).task{task}.stdFC(:, sub) = cell2mat({CorrData(sub).task(task).hem(hemi).FC.stdFC}');
                                                    
                    if task == 1
                        data(a).hem(hemi).verts{:, sub} = CorrData(sub).hem(hemi).info.vertices;
                    end
                    
                end
            end
        end
    end
    
    %get these now so you can use them for graph labels later
    if a == 1
        taskNames = {CorrData(sub).task(:).name}';
    end
    
    clear CorrData
end
save FCmeans data taskNames


%% relationship between parcel size and FC
meanFC = []; stdFC = []; numVerts = [];
for a = 1:NumAtlas
    
    meanAtlasFC = [];
    numAtlasVerts = [];
    meanAtlasStd = [];
    for task = 1:8
        for hemi = 1:2
            
            if ~isempty(data(a).hem(1).task{task})
                meanAtlasFC = [meanAtlasFC; cell2mat({data(a).hem(hemi).task{task}.meanFC})];
                meanAtlasStd = [meanAtlasStd; cell2mat({data(a).hem(hemi).task{task}.stdFC})]
                numAtlasVerts = [numAtlasVerts; size(data(a).hem(hemi).numVerts, 1)];
            end
        end 
    end
    meanFC = [meanFC; meanAtlasFC];
    stdFC = [stdFC; meanAtlasStd];
    numVerts = [numVerts; numAtlasVerts];
end
meanFCVect = reshape(meanFC, numel(meanFC), 1);
stdFCVect = reshape(stdFC, numel(stdFC), 1);
numVertsVect = reshape(numVerts, numel(numVerts), 1);

% plot
scatter(numVertsVect, meanFCVect);
t = strcat('Mean Parcel FC vs Size, r=', sprintf('%.2f', corr(meanFCVect, numVertsVect)));
title(t)

scatter(numVertsVect, stdFCVect);
t = strcat('Parcel StDev FC vs Size, r=', sprintf('%.2f', corr(stdFCVect, numVertsVect)));
title(t)


%% put output in poi file
for a = 1:NumAtlas
    for task = 1:8
        for hemi = 1:2
            
            if ~isempty(data(a).hem(1).task{task})
                poiData.subID = 'All';
                poiData.taskName = taskNames{task};
                poiData.atlas = data(a).atlas;
                if hemi == 1, poiData.hem = 'lh';
                else poiData.hem = 'rh';
                end
                
                % mean parcel FC
                poiData.meanFC = mean(cell2mat({data(a).hem(hemi).task{task}.meanFC}), 2);
                poiData.color = applyColors(poiData.meanFC, 'jet', [0 1]);
                createPOIstats(poiData, 'meanFC');
                
                %mean parcel FC, scaled
                numVerts
                
                
                % std parcel FC
                poiData.stdFC = mean(cell2mat({data(a).hem(hemi).task{task}.stdFC}), 2);
                poiData.color = applyColors(poiData.stdFC, 'jet', [0 1]);
                createPOIstats(poiData, 'stdFC');
                
                
                
            end
        end
    end
end



%% plot mean FS for all atlases, all parcels combined
h = figure('Name', 'Mean Parcel FC');
p = 0;
for a = 1:NumAtlas
    for task = 1:8
        p = p+1;
        
        if ~isempty(data(a).hem(1).task{task})
       
            pdata = cell2mat({data(a).hem(1).task{task}.meanFC});
            pdata2 = reshape(pdata, numel(pdata), 1);
            subplot(NumAtlas, NumTasks, p), hist(pdata2);
            hold on; 
            line([median(pdata2) median(pdata2)], [0 30], 'Color', 'r', 'LineWidth', 1, 'LineStyle', ':')
            title(taskNames{task});
            
            if mod(p, 8) == 1
                ylabel(atlasList{a});
            end
        end
    end
end



h1 = figure('Name', 'Mean Parcel StDev');
p = 0;
for a = 1:NumAtlas
    for task = 1:8
        p = p+1;
        
         if ~isempty(data(a).hem(1).task{task})
       
            pdata = cell2mat({data(a).hem(1).task{task}.stdFC});
            pdata2 = reshape(pdata, numel(pdata), 1);
            subplot(NumAtlas, NumTasks, p), hist(pdata2);
            hold on; 
            line([median(pdata2) median(pdata2)], [0 30], 'Color', 'r', 'LineWidth', 1, 'LineStyle', ':')
            title(taskNames{task});
            
             if mod(p, 8) == 1
                ylabel(atlasList{a});
            end
        end
    end
end





cd(BasePath)

