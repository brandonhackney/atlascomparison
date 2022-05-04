function Pattern = FC_1_PrepParcelData(subID, atlas)

% Pattern = FC_1_PrepParcelData(subID, atlas)
%
% Starts from Brandon's .mat files of timeseries. Extracts the proper
% timeseries for each parcel the preprocesses it to get it ready for FC
% timeseries analysis.

warning off %Note: These are turned off because missing scans give GLM singular errors

BasePath = '/data2/2020_STS_Multitask/analysis/';
DataPath = strcat(BasePath, 'ROIs/');
outPath = strcat(BasePath, 'ROIs/FC');
vtcPath = '/data2/2020_STS_Multitask/data/deriv/';
% addpath(BasePath)

TR = 2;  %% This looks like a red flag


% get the proper input file and set up the output file
cd(DataPath)
fName = strcat(strjoin({subID, atlas}, '_'), '.mat');
fprintf(1, 'Working on %s, %s atlas...\n\n', subID, atlas);
load(fName)
fOut = strjoin({subID, atlas, 'Cen_dtr_Volt_BPF'}, '_');

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
        
        [posInd, negInd, taskID, numConds] = getConditionFromFilename(taskName);
        if isempty(posInd)
            posInd = -1; negInd = -1;
            taskID = 10; %pick a weird position to flag no task name
        end 
        
        % get the task predictors
        preds =subData(task).pred(:, 1:numConds);
        scanID = subData(task).runNum;
        scanList = unique(scanID)';
        
        
        
        % only keep going if I can match each run to a vtc (for GSR)
        cd(strcat(vtcPath, subID))
        vtcList = dir(strcat('*', taskName, '*.vtc'));
        cd(DataPath)
        
        if size(vtcList, 1) == size(scanList, 2)
            
            
            % get 3DMC estimates
            motionpreds = subData(task).motionpred; %3dmc parameters
            
            %re-structure data arrays to be 3D for multiruns
            clear in p mp GSR
            scanIn = 0;
            for scan = scanList
                in = find(scanID == scan);
                tempp = preds(in, :);
                tempmp = motionpreds(in, :);
                
                % get GSR
                scanIn = scanIn + 1;
                vtcName = vtcList(scanIn).name;
                vtcSubPath = strcat(vtcPath, subID, '/');
                fprintf(1, 'Working on %s, run %i: Using %s for GSR\n', taskName, scan, vtcName);
                tempGSR = getGSR(subID, fullfile(vtcSubPath, vtcName));
                
                % fix problems for aborted scans
                if scan > 1
                    if size(tempp, 1) < size(p, 1)
                        tempp(end+1:size(p, 1), :) = NaN;
                        tempmp(end+1:size(mp, 1), :) = NaN;
                        tempGSR(end+1:size(GSR, 1), :) = NaN;
                        
                    elseif size(tempp, 1) > size(p, 1)
                        p(end+1:size(tempp, 1), :) = NaN;
                        mp(end+1:size(tempmp, 1), :) = NaN;
                        GSR(end+1:size(tempGSR, 1), :, :) = NaN;
                    end
                end
                
                %store
                p(:, :, scanIn) = tempp;
                mp(:, :, scanIn) = tempmp;
                GSR(:, :, scanIn) = squeeze(mean(tempGSR, 2));
            end
            Data.motionpreds = mp;
            Data.preds = p;
            Data.GSR = GSR;
     
            
            % set up final output
            Pattern.subID = subID;
            Pattern.reg(taskID) = Data;
            Pattern.log(taskID).vtc = vtcList;
            
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
            Data = RemoveSpikes(Data, 'reg', ResampleFlag, 1, 1);
            
            
            %% detrend regressors
            fprintf(1, 'Detrending regressors...\n')
            Data = BatchDetrend(Data, 'reg', 1);
            
            
            % basic analytics on motion predictors
            RmSpikes = 1; % 1 = Set spikes to NaN
            fprintf(1, 'Computing Framewise Displacement...\nSet Spikes to NaN = %i', RmSpikes);
            Data = ComputeFD(Data, RmSpikes);
            
            % set this up so I can reference back to it again
            TemplateDataStruct = Data;
            
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
                
                parcelTS = [];
                parcelinfo = [];
                for parcel = 1:NumParcels
                    
                    %clear out old stuff
                    Data = TemplateDataStruct;
                    
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
                        meants(scanIn) = nanmean(nanmean(tempts));
                        
                    end
                    Data.ts = ts;
                    Data.meanTS = meants;
                    
                    
                    %give minimal feedback
                    if mod(parcel, 10) == 1
                        fprintf(1, '%i...', parcel);
                    end
                    
                    
                    %% censor data
                    Data = RemoveSpikes(Data, 'ts', 0, 1, 1);
                    
                    
                    %% detrend
                    Data = BatchDetrend(Data, 'ts', 1);
                    
                    
                    %% regress out the motion and first derivatives using a 24 parameter model,
                    Data = RegressBatch(Data, 'ts', 'reg', 1);
                    
                    
                    %% replace censored points with resampled points
                    ofac=8; %oversampling frequency
                    hifac=1; %highest frequency sampled
                    Data = ResampleData(Data, 'ts', 1, 1);
                    
                    
                    %% next, bandpass filter
                    CutOffs = [.01 .1];
                    FiltOrder = 2;
                    Data = fMRI_BandpassFilt(Data, 'ts', CutOffs, FiltOrder, TR, [], 1);
                    
                    
                    %% recensor
                    Data = RemoveSpikes(Data, 'ts', 0, 1, 1);
                    
                    %save final output in the final data structure
                    parcelTS(parcel).ts = Data.ts;
                    
                    
                end %for parcel
                fprintf(1, 'done!\n');
                Pattern.task(taskID).name = taskName;
                Pattern.task(taskID).contrast = {posInd, negInd};
                Pattern.task(taskID).data{hemi} = parcelTS; %Pattern(sub).parcels(hemi) = parceldata;
            end
        end
    catch e
        
        Pattern.log(taskID).error = [{e.identifier}; {e.message}];
        fprintf(1,'There was an error on line %i! The message was:\n%s\n\n',e.stack(1).line, e.message);
        fprintf(1,'\n\nThe identifier was:\n%s\n',e.identifier);
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





