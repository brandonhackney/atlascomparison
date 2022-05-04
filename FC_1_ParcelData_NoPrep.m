function Pattern = FC_1_ParcelData_NoPrep(subID, atlas)

% Pattern = FC_1_PrepParcelData_NoPrep(subID, atlas)
%
% Starts from Brandon's .mat files of timeseries. Extracts the proper
% timeseries for each parcel and saves it in a .mat file organized for an
% FC analysis (without preprocessing).


warning off %Note: These are turned off because missing scans give GLM singular errors

BasePath = '/data2/2020_STS_Multitask/analysis/';
DataPath = strcat(BasePath, 'ROIs/');
outPath = strcat(BasePath, 'ROIs/FC');
vtcPath = '/data2/2020_STS_Multitask/data/deriv/';

TR = 2;  %% This looks like a red flag


% get the proper input file and set up the output file
cd(DataPath)
fName = strcat(strjoin({subID, atlas}, '_'), '.mat');
fprintf(1, 'Working on %s, %s atlas...\n\n', subID, atlas);
load(fName)
fOut = strjoin({subID, atlas, 'noprep'}, '_');

SubData = Pattern; % save raw data because 'Pattern' is reused later
clear Pattern;

%set up the basics
fprintf(1, '\n\nWorking on subject %s\n', subID);
subID = SubData.subID;
subData = SubData.task;

for task = 1:size(subData, 2)
    
    clear Data;
    Data.subID = subID;
   
    
    try
        
        % figure out which task this is based on the full name
        taskName = subData(task).name;
        Data.taskID = taskName;
        [posInd, negInd, taskID] = getConditionFromFilename(taskName);
        if isempty(posInd)
            posInd = -1; negInd = -1;
            taskID = 10; %pick a weird position to flag no task name
        end
        vtcList = getCondVTC({subData(task).mtcList.VTCpath}', taskName);
        
        
        % get the task predictors
        preds = subData(task).pred;
        scanID = preds(:, end);
        scanList = unique(scanID)';
        
        % only keep going if I can match each run to a vtc (for GSR)
        if size(vtcList, 1) == size(scanList, 2)
            
            
            % get 3DMC estimates
            motionpreds = subData(task).motionpred; %3dmc parameters
            
            %re-structure data arrays to be 3D for multiruns
            clear in p mp GSR
            scanIn = 0;
            for scan = scanList
                in = find(scanID == scan);
                tempp = preds(in, 1:end-2);
                tempmp = motionpreds(in, :);
                
                % fix problems for aborted scans
                if scan > 1
                    if size(tempp, 1) < size(p, 1)
                        tempp(end+1:size(p, 1), :) = NaN;
                        tempmp(end+1:size(mp, 1), :) = NaN;
                        
                    elseif size(tempp, 1) > size(p, 1)
                        p(end+1:size(tempp, 1), :) = NaN;
                        mp(end+1:size(tempmp, 1), :) = NaN;
                    end
                end
                
                %store
                p(:, :, scanIn) = tempp;
                mp(:, :, scanIn) = tempmp;                
            end
            Data.motionpreds = mp;
            Data.preds = p;    
            
            % set up final output
            Pattern.subID = subID;
            Pattern.reg(taskID) = Data;
            Pattern.log(taskID).vtc = vtcList;
                       
            % set this up so I can reference back to it again
            TemplateDataStruct = Data;
            

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            fprintf(1, '\nWorking on the parcel timeseries now...\n')          
            for hemi = 1:2
                
                %give minimal feedback
                fprintf(1, 'Task %i, hemi %i...', task, hemi);
                
                % get the timeseries out of the larger structure
                data = subData(task).hem(hemi).data;
                NumParcels = size(data, 2);
                
              
                parcelTS = [];
                for parcel = 1:NumParcels
                  
                    %save for final output
                    if task == 1
                        parcelinfo(parcel).name = data(parcel).label;
                        parcelinfo(parcel).vertices = data(parcel).vertices;
                        parcelinfo(parcel).vertexCoord = data(parcel).vertexCoord;
                        parcelinfo(parcel).ColorMap = data(parcel).ColorMap;
                        Pattern.parcels(hemi).parcelInfo = parcelinfo;
                    end
                    
                    
                    %get timeseries, and restructure with scan in 3rd dimension
                    ts = []; scanIn = 0;
                    for scan = scanList
                        in = find(scanID == scan);
                        tempts = data(parcel).pattern(in, :); %data is currently a structure by parcel
                        
                        %correct for aborted scans
                        if scan > 1
                            if size(tempts, 1) > size(ts, 1)
                                ts(end+1:size(tempts, 1), :) = NaN;
                            elseif size(tempts, 1) < size(ts, 1)
                                tempts(end+1, size(ts, 1), :) = NaN;
                            end
                        end
                       scanIn = scanIn + 1;
                       ts(:, :, scanIn) = tempts;
                    end
                    parcelTS(parcel).ts = ts;
                    %save final output in the final data structure
                    
                    
                    
                end %for parcel
                fprintf(1, 'done!\n');
                Pattern.task(taskID).name = taskName;
                Pattern.task(taskID).contrast = {posInd, negInd};
                Pattern.task(taskID).data{hemi} = parcelTS; %Pattern(sub).parcels(hemi) = parceldata;
            end
        end
    catch e
        
        Pattern.log(taskID).error = [{e.identifier}; {e.message}];
        fprintf(1,'The identifier was:\n%s\n',e.identifier);
        fprintf(1,'There was an error on line %i! The message was:\n%s\n',e.stack(1).line, e.message);
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%       save results
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cd(outPath);

fprintf(1, 'Saving output to file...')
if ~exist('Pattern', 'var')
    save(fOut, 'Pattern', '-v7.3');
else
    save(fOut, 'Pattern', 'Pattern', '-v7.3');
end

fprintf(1, 'Done!\n');





