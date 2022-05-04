function imagescMetrics(metric) %, atlas)

% metric = 'wbFC', 'overlap', 'meanB', 'stdB', 'meanPosB', 'meanNegB'
atlasList = {'schaefer400','power6p0','gordon333dil','glasser6p0'};
numAtlas = size(atlasList, 2);

dataPath = '/data2/2020_STS_Multitask/analysis/class/data';
cd(dataPath)

for h = 1:2
    if h == 1
        figure('Name', 'Hemi: Left'); 
    else
        figure('Name', 'Hemi: Right');
    end
    
    p= 0;
    for a = 1:numAtlas

        atlas = atlasList{a};
        fName = strcat('Classify_', metric, '_*', atlas, '*.mat');
        fList = dir(fName);

        load(fList(1).name)
        taskNames = Data.taskNames;
        numTasks = length(unique(Data.hemi(h).labels(:, 2)));
        
        
        if a == 1
            plotAxes = [min(min(Data.hemi(1).data))*.9 max(max(Data.hemi(1).data))*.9];
        end
      
        for t = 1:numTasks
        
            in = find(Data.hemi(h).labels(:, 2) == t); %get that task data only (all subs)

            p = p+1;
            subplot(numAtlas, numTasks, p), imagesc(Data.hemi(h).data(in, :));
            title(strcat(taskNames(t, :)));
            caxis([plotAxes(1) plotAxes(2)]); 
            
            if t == 1
                ylabel(atlas);  
            else
                ylabel('sub');  
            end

        end
    end
    figure; imagesc(Data.hemi(h).data(in, :)); colorbar
end





% 
% fName = strcat('Classify_', metric, '_*', atlas, '*.mat');
% fList = dir(fName);
% 
% load(fList(1).name)
% taskNames = Data.taskNames;
% numTasks = size(taskNames, 1);
% 
% 
% figure('Name', atlas); 
% p= 0;
% for t = 1:numTasks
%     for h = 1:2
%         p = p+1;
%         subplot(8, 2, p), imagesc(Data.hemi(h).data);
%         title(strcat(taskNames(t, :)));
%         ylabel('sub'),  caxis([0 .5]); colorbar;
%         
%         if t == numTasks
%             xlabel('parcel')
%         end
%     end
% end