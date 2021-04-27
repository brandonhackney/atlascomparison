clear; clc;

BasePath = '/data2/2020_STS_Multitask/analysis/';
ROIPath = strcat(BasePath, 'ROIs/');
FCPath = strcat(BasePath, 'ROIs/FC');
smpPathBase = '/data2/2020_STS_Multitask/data';
smpPathExt = 'bv/'

% templatePath = '/data2/2020_STS_Multitask/data/sub-04/fs/sub-04-Surf2BV';
% poiPath = strcat(templatePath, '/deriv');

atlasList = {'schaefer400', 'gordon333dil', 'glasser5p3'}; % ,% 'power5p3'
NumAtlas = size(atlasList, 2);

%% calculate effect of task on  output in poi file
atlasList = {'schaefer400', 'gordon333dil', 'glasser5p3'}; % ,% 'power5p3'
NumAtlas = size(atlasList, 2);

cd(FCPath)
load('FCmeans')

%initialize the hierachical data structure
temp = struct('numVerts', []);
data = struct('atlas', [], 'hem', temp);

for a = 1:NumAtlas 
   
    atlasName = atlasList{a};
    data(a).atlas = atlasName;
    fprintf(1, 'Working on %s atlas data...', atlasName);
        
    NumSubs = size(CorrData, 2);
    for sub = 1:NumSubs
       
        for hemi = 1:2
            
            NumTasks = size(CorrData(sub).task, 2);
            for task = 1:NumTasks
        
                    if ~isempty(CorrData(sub).task(task).hem) %to prevent crashing for missing scans
          
                    data(a).hem(hemi).task{task}.meanFC(:, sub) = cell2mat({CorrData(sub).task(task).hem(hemi).FC.meanFC}');
                    data(a).hem(hemi).task{task}.stdFC(:, sub) = cell2mat({CorrData(sub).task(task).hem(hemi).FC.stdFC}');
                    
                    data(a).hem(hemi).vertices(:, sub) = cell2mat({CorrData(sub).task(task).hem(hemi).FC.info.vertices}');
                    
                    
                    subPath = strcat(dataDir
                    cd
          
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