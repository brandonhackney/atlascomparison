function Pattern = FC_1_PrepParcelData(subID, atlas)
% clear; clc;
warning off %Note: These are turned off because missing scans give GLM singular errors

BasePath = '/data2/2020_STS_Multitask/analysis/';
ROIPath = strcat(BasePath, 'ROIs/');
outPath = strcat(BasePath, 'ROIs/FC');
% addpath(BasePath)




% get the proper input file and set up the output file
cd(ROIPath)
% subID = 'STS3';
% atlas = 'schaefer400';
fName = strcat(strjoin({subID, atlas}, '_'), '.mat');
fprintf(1, 'Working on %s, %s atlas...\n\n', subID, atlas);
load(fName)

AllData = Pattern; % save raw data because 'Pattern' is reused later
NumSubs = size(AllData, 2);
clear Pattern;

fOut = strjoin({subID, atlas, 'Cen_dtr_Volt_BPF'}, '_');

TR = 2;  %% This looks like a red flag

try
for sub = 1:NumSubs
    
    % only use viable subjects
    if isempty(AllData(sub).task)
        fprintf(1, '\n\n%%%% Subject %i is empty\n', sub);
        
        
    else
        
        fprintf(1, '\n\nWorking on subject %s\n', subID);
        %set up the basics
        subID = AllData(sub).subID;
        subData = AllData(sub).task;
        
        for task = 1:size(subData, 2)
            
            clear Data;
            Data.subID = subID;
            
            % figure out which task this is based on the full name
            taskName = subData(task).name;
            [posInd, negInd, taskID] = getConditionFromFilename(taskName);
            if isempty(posInd)
                posInd = -1; negInd = -1;
                taskID = 10; %pick a weird position to flag no task name
            end
            vtcList = getCondVTC({subData(task).mtcList.VTCpath}', taskName);
            
            
            
            % get the task predictors
            preds =subData(task).pred;
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
                    p(:, :, scan) = preds(in, end-2);
                    mp(:, :, scan) = motionpreds(in, :);
                    
                    % get GSR
                    scanIn = scanIn + 1;
                    [vtcPath, vtcName, ext] = fileparts(vtcList{scanIn});
                    fprintf(1, 'Working on %s, run %i: Using %s for GSR\n', taskName, scan, vtcName);
                    GSR(:, :, scan) = getGSR(subID, fullfile(vtcPath, strcat(vtcName, '.vtc')));
                end
                Data.motionpreds = mp;
                Data.preds = p;
                Data.GSR = squeeze(mean(GSR, 2));
                
                
                % set up final output
                Pattern(sub).subID = subID;
                Pattern(sub).reg = Data;
%                 Pattern(sub).parcels = [];
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %%       Work on regressors
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
                %% convert rotational estimates from deg to mm
                fprintf(1, 'Converting rotational estimates from deg to mm...\n');
                Data = Convert3DMCRot2mm(Data);
                
                
                
                %% Get the initial motion metrics
                RmSpikes = 0; % 1 = Set spikes to NaN
                Data = ComputeFD(Data, RmSpikes);
                
                
                %% create the full set of regressors (26 parameter model)
                GlobalSignal = 1; %1 = include
                VentPredFlag = 0; %1 = include
                RType = 'Volt';
                NumVolt = 24;
                fprintf(1, 'Creating the regressor set...%s(GS=%i, Vent = %i)\n', RType, GlobalSignal, VentPredFlag);
                Data = CreateRegressors_Volterra(Data, GlobalSignal, VentPredFlag, NumVolt);
                
                
                
                %% identify spikes
                MaxDisplace = .5;
                AdditionalTpTs = [1 2 3 4]; % also identify the surrounding timepoints
                MinChunkSize = 5;
                fprintf(1, 'Identifying Spikes...\n\tMaximum FD = %3.2f\n\tMinimum Segment Size = %i\n\tAdditional excluded volumes:', MaxDisplace, MinChunkSize);
                for i = 1:length(AdditionalTpTs)
                    fprintf(1, '%i ', AdditionalTpTs(i));
                end; fprintf(1, '\n');
                Data = IdentifySpikes(Data, MaxDisplace, AdditionalTpTs, MinChunkSize, 1);
                
                
                % censor regressors
                ResampleFlag = 0;% 0 = off
                fprintf(1, 'Censoring regressors...\n\tResample = %i\n', ResampleFlag);
                Data = RemoveSpikes(Data, 'reg', ResampleFlag, 1);
                
                
                %% detrend regressors
                fprintf(1, 'Detrending regressors...\n')
                Data = BatchDetrend(Data, 'reg');
                
                
                % basic analytics on motion predictors
                RmSpikes = 1; % 1 = Set spikes to NaN
                fprintf(1, 'Computing Framewise Displacement...\nSet Spikes to NaN = %i', RmSpikes);
                Data = ComputeFD(Data, RmSpikes);
                
                % set this up so I can reference back to it again
                CleanDataStruct = Data;
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %%      Clean data
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%               
                fprintf(1, '\nWorking on the parcel timeseries now...\n')
                             
                for hemi = 1:2
                    
                    %give minimal feedback
                    fprintf(1, 'Task %i, hemi %i...', task, hemi);
                    
                    % get the timeseries out of the larger structure
                    data = subData(task).hem(hemi).data;
                    NumParcels = size(data, 2);
                    
                     
                    for parcel = 1:NumParcels
                        
                        %clear out old stuff
                        Data = CleanDataStruct;
                        
                        %save for final output
                        if task == 1
                            parcelinfo(parcel).name = data(parcel).label;
                            parcelinfo(parcel).vertices = data(parcel).vertices;
                            parcelinfo(parcel).vertexCoord = data(parcel).vertexCoord;
                            parcelinfo(parcel).ColorMap = data(parcel).ColorMap;
                            Pattern(sub).hem(hemi).parcelInfo = parcelinfo;
                        end
                        
                        
                        %get timeseries, and restructure with scan in 3rd dimension
                        ts = data(parcel).pattern;
                        for scan = scanList
                            in = find(scanID == scan);
                            Data.ts(:, :, scan) = data(parcel).pattern(in, :); %data is currently a structure by parcel
                        end
                        
                        
                        %give minimal feedback
                        if mod(parcel, 10) == 1
                            fprintf(1, '%i...', parcel);
                        end
                        
                        
                        %% censor data
                        Data = RemoveSpikes(Data, 'ts', 0, 1);
                        
                        
                        %% detrend
                        Data = BatchDetrend(Data, 'ts');
                        
                        
                        %% regress out the motion and first derivatives using a 24 parameter model,
                        Data = RegressBatch(Data, 'ts', 'reg');
                        
                        
                        %% replace censored points with resampled points
                        ofac=8; %oversampling frequency
                        hifac=1; %highest frequency sampled
                        Data = ResampleData(Data, 'ts', 1);
                        
                        
                        %% next, bandpass filter
                        CutOffs = [.01 .1];
                        FiltOrder = 2;
                        Data = fMRI_BandpassFilt(Data, 'ts', CutOffs, FiltOrder, TR);
                        
                        
                        %% recensor
                        Data = RemoveSpikes(Data, 'ts', 0, 1);
                        
                        %save final output in the final data structure
                        parcelTS(parcel).ts = Data.ts;
                        
                        
                    end %for parcel
                    fprintf(1, 'done!\n');
                    Pattern(sub).task(taskID).name = taskName;
                    Pattern(sub).task(taskID).contrast = {posInd, negInd};
                    Pattern(sub).task(taskID).hem(hemi).data = parcelTS; %Pattern(sub).parcels(hemi) = parceldata;
                end
            end
        end
    end
end %for sub
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%       save results
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cd(outPath);

fprintf(1, 'Saving output to file...')
if ~exist('Pattern', 'var')
    save(fOut, 'Pattern', '-v7.3');
else
    save(fOut, 'Pattern', 'Pattern', '-v7.3');
end

fprintf(1, 'Done!\n');

catch e
    Pattern = [];
    fprintf(1,'The identifier was:\n%s\n',e.identifier);
    fprintf(1,'There was an error! The message was:\n%s',e.message);
end



