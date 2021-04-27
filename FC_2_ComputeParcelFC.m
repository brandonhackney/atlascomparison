clear; clc;

BasePath = '/data2/2020_STS_Multitask/analysis';
ROIPath = strcat(BasePath, '/ROIs/FC');
outPath = ROIPath;
cd(ROIPath)

atlas = 'glasser5p3';%'schaefer400';%'power5p3';%;'gordon333dil'; %
fOut = strcat('CorrMats_', atlas);

fList = dir(strcat('STS*', atlas, '*.mat'));
NumSubs = size(fList, 1);
NumTasks = 8;


for sub = 1:NumSubs

    fprintf(1, 'Loading a big file...\n');
    load(fList(sub).name)
    subID = Pattern.subID;
    CorrData(sub).subID = subID;
    fprintf(1, 'Working on %s...\n', subID);

    
    for task = 1:NumTasks
        
        taskName = Pattern.task(task).name;
        
        if ~isempty(taskName) %there might be some missing ones
            
            fprintf(1, '\ttask %s...\n', taskName);
            
            for hemi = 1:2
            
                % get data (all parcels)
                data = Pattern.task(task).hem(hemi).data;
                NumParcels = size(data, 2);
                
                if task == 1
                    CorrData(sub).hem(hemi).info = Pattern.hem(hemi).parcelInfo;
                end                
                         
                % work through each parcel
                for p = 1:NumParcels
                    
                    %get parcel data
                    tsMat = data(1).ts; 
                    NumScans = size(tsMat, 3);
                    
                    %keep only non-NaN timepoints, reshape data into single vector
                    pData = [];
                    for s = 1:NumScans 
                        [y, x] = find(isnan(tsMat(:, :, s)) == 0); 
                        in = unique(y);
                        pData = [pData; tsMat(in, :, s)];
                    end
                            
                    %calculate FC
                    corrMat = corr(pData);
                    FC(p).corrMat = corrMat;
                    
                    % compute some stats on corr matrics (upper triangle only)
                    in = find(triu(corrMat) ~= 0);
                    FC(p).meanFC = mean(corrMat(in));
                    FC(p).stdFC = std(corrMat(in));
                    
                end
                CorrData(sub).task(task).hem(hemi).FC = FC;
 
            end
            CorrData(sub).task(task).name = taskName;
        end
    end
end

cd(outPath)
save(fOut, 'CorrData', '-v7.3');
cd(BasePath)

