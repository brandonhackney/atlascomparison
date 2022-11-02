clear; clc;

% creates a simulated dataset for a single subject, single atlas, two
% conditions, to test classification code
% designed to be run in command line on a variable in memory, but saved
% here for reuse


%% makes a simulated meann FC parcel pattern
% fIn = 'CorrMats_noprep_byCond_glasser6p0.mat';
% load(fIn)
% NumSubs = size(CorrData, 2);
% for sub = 1:NumSubs
%     for hemi = 1:2
%         NumTasks = size(CorrData(sub).meanFC(hemi).data, 2);        
%         for task = 1:NumTasks            
%             NumParcels = size(CorrData(sub).meanFC(hemi).data{task}, 2);           
%             for parcel = 1:NumParcels
%                 if parcel == task
%                     CorrData(sub).meanFC(hemi).data{task}(parcel) = 1;
%                 else
%                     CorrData(sub).meanFC(hemi).data{task}(parcel) = .1;
%                 end       
%             end
%         end
%     end
% end    
% fOut = 'CorrMats_noprep_byCond_glasser6p0SIM.mat';
% save(fOut, 'CorrData')
% fprintf(1, '%s is now %s\n', fIn, fOut);



%% makes a simulated timeseries
for sub = [1 2 3 4 5 6 7 8 10 11]
    fIn = strcat('STS', num2str(sub), '_glasser6p0.mat');
    load(fIn, 'Pattern')
    NumTasks = size(Pattern.task, 2);
    for task = 1:NumTasks
        Pattern.task(task).pred = round(Pattern.task(task).pred);
        for hem = 1:2
            NumParcels = size(Pattern.task(task).hem(hem).data, 2);
            for cond = 1:2
                in = find(Pattern.task(task).pred(:, cond) == 1);
                for parcel = 1:NumParcels
                    pat = Pattern.task(task).hem(hem).data(parcel).pattern(in, :);
                    sz = size(pat);
                    if parcel == task
                        Pattern.task(task).hem(hem).data(parcel).pattern(in, :) = repmat(pat(:, 1), 1, sz(2))+rand(sz)*std(pat(:, 1))*.1;
                    end
                end
            end
        end
        
    end
    if sub < 10, fOut = strcat('STS10', num2str(sub), '_glasser6p0.mat');
    else, fOut = strcat('STS1', num2str(sub), '_glasser6p0.mat');
    end
    save(fOut, 'Pattern')
    fprintf(1, '%s is now %s\n', fIn, fOut);
end
