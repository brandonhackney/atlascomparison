function dataOut = FC_1_AddParcelData(subID, atlas, taskName)

% dataOut = FC_1_AddParcelData(subID, atlas, taskName)
%
% An add-on function to fill in the data missing after running FC_1 due to
% idiosyncracies or other causes.

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

% figure out which task this is, get some info        
% input side
taskIn= find(strcmp(taskName, {Pattern.task.name}), 1);

% output side
[posInd, negInd, taskID, numConds] = getConditionFromFilename(taskName);
if isempty(posInd)
    posInd = -1; negInd = -1;
    taskID = 10; %pick a weird position to flag no task name
end

%set up the basics
fprintf(1, '\n\nWorking on subject %s\n', subID);
subID = Pattern.subID;
subData = Pattern.task(taskIn);

% taskData.subID = subID; %for final output
tempData.subID = subID; %for working output
tempData.taskID = taskName; %save in output file
clear Pattern; %clear this because it is big and will be used later

% match each run to a vtc (for GSR)
cd(strcat(vtcPath, subID))
vtcList = dir(strcat('*', taskName, '*.vtc'));
cd(DataPath)

% get the task predictors
preds =subData.pred(:, 1:numConds);
scanID = subData.runNum;
scanList = unique(scanID)';


try    
    % get 3DMC estimates
    motionpreds = subData.motionpred; %3dmc parameters
    
    %re-structure data arrays to be 3D for multiruns
    clear in
    p = []; mp = []; GSR = [];
    scanIn = 0;
    for scan = scanList
        in = find(scanID == scan);
        
        tempp = preds;
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
    tempData.motionpreds = mp;
    tempData.preds = p;
    tempData.GSR = GSR;
%     taskData.reg = tempData; %save regressors into final output

   
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%       Work on regressors
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %% convert rotational estimates from deg to mm
    fprintf(1, 'Converting rotational estimates from deg to mm...\n');
    tempData = Convert3DMCRot2mm(tempData);
    
    
    
    %% Get the initial motion metrics
    RmSpikes = 0; % 1 = Set spikes to NaN
    tempData = ComputeFD(tempData, RmSpikes);
    
    
    %% create the full set of regressors (26 parameter model)
    GlobalSignal = 1; %1 = include
    VentPredFlag = 0; %1 = include
    RType = 'Volt';
    NumVolt = 24;
    fprintf(1, 'Creating the regressor set...%s(GS=%i, Vent = %i)\n', RType, GlobalSignal, VentPredFlag);
    tempData = CreateRegressors_Volterra(tempData, GlobalSignal, VentPredFlag, NumVolt);
    
    
    
    %% identify spikes
    MaxDisplace = .5;
    AdditionalTpTs = [1 2 3 4]; % also identify the surrounding timepoints
    MinChunkSize = 5;
    fprintf(1, 'Identifying Spikes...\n\tMaximum FD = %3.2f\n\tMinimum Segment Size = %i\n\tAdditional excluded volumes:', MaxDisplace, MinChunkSize);
    for i = 1:length(AdditionalTpTs)
        fprintf(1, '%i ', AdditionalTpTs(i));
    end; fprintf(1, '\n');
    tempData = IdentifySpikes(tempData, MaxDisplace, AdditionalTpTs, MinChunkSize, 1);
    
    
    % censor regressors
    ResampleFlag = 0;% 0 = off
    fprintf(1, 'Censoring regressors...\n\tResample = %i\n', ResampleFlag);
    tempData = RemoveSpikes(tempData, 'reg', ResampleFlag, 1, 1);
    
    
    %% detrend regressors
    fprintf(1, 'Detrending regressors...\n')
    tempData = BatchDetrend(tempData, 'reg', 1);
    
    
    % basic analytics on motion predictors
    RmSpikes = 1; % 1 = Set spikes to NaN
    fprintf(1, 'Computing Framewise Displacement...\nSet Spikes to NaN = %i', RmSpikes);
    tempData = ComputeFD(tempData, RmSpikes);
    
    % set this up so I can reference back to it again
    TemplateDataStruct = tempData;
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%      Clean data
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    fprintf(1, '\nWorking on the parcel timeseries now...\n')
    
    for hemi = 1:2
        
        %give minimal feedback
        fprintf(1, 'Task %s, hemi %i...', taskName, hemi);
        
        % get the timeseries out of the larger structure
        data = subData.hem(hemi).data;
        NumParcels = size(data, 2);
        
        parcelTS = [];
        for parcel = 1:NumParcels
            
            %clear out old stuff
            tempData = TemplateDataStruct;
            
            
            %get timeseries, and restructure with scan in 3rd dimension
%             ts = data(parcel).pattern;
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
                meants(scan) = nanmean(nanmean(tempts));
                
            end
            tempData.ts = ts;
            tempData.meanTS = meants;
            
            %give minimal feedback
            if mod(parcel, 10) == 1
                fprintf(1, '%i...', parcel);
            end
            
            
            %% censor data
            tempData = RemoveSpikes(tempData, 'ts', 0, 1, 1);
            
            
            %% detrend
            tempData = BatchDetrend(tempData, 'ts', 1);
            
            
            %% regress out the motion and first derivatives using a 24 parameter model,
            tempData = RegressBatch(tempData, 'ts', 'reg', 1);
            
            
            %% replace censored points with resampled points
            ofac=8; %oversampling frequency
            hifac=1; %highest frequency sampled
            tempData = ResampleData(tempData, 'ts', 1, 1);
            
            
            %% next, bandpass filter
            CutOffs = [.01 .1];
            FiltOrder = 2;
            tempData = fMRI_BandpassFilt(tempData, 'ts', CutOffs, FiltOrder, TR, [], 1);
            
            
            %% recensor
            tempData = RemoveSpikes(tempData, 'ts', 0, 1, 1);
            
            %save final output in the final data structure
            parcelTS(parcel).ts = tempData.ts;
            
            
        end %for parcel
        fprintf(1, 'done!\n');
        dataOut{hemi} = parcelTS; %Pattern(sub).parcels(hemi) = parceldata;
    end

catch e
    
    log.error = [{e.identifier}; {e.message}];
    fprintf(1,'There was an error on line %i! The message was:\n%s\n\n',e.stack(1).line, e.message);
    fprintf(1,'\n\nThe identifier was:\n%s\n',e.identifier);
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%       save results
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% adding to an existing file
fOut = strjoin({subID, atlas, 'Cen_dtr_Volt_BPF'}, '_');
cd(outPath)
load(fOut); %var: Pattern

Pattern.reg(taskID).subID = subID;
Pattern.reg(taskID).taskID = taskName;
Pattern.reg(taskID).motionpreds = tempData.motionpreds;
Pattern.reg(taskID).preds = tempData.preds;
Pattern.reg(taskID).GSR = tempData.GSR;

Pattern.task(taskID).name = taskName;
Pattern.task(taskID).contrast = {posInd, negInd};
Pattern.task(taskID).data = dataOut;

Pattern.log(taskID).vtc = vtcList;



fprintf(1, 'Saving output to file...')
if ~exist('Pattern', 'var')
    save(fOut, 'Pattern', '-v7.3');
else
    save(fOut, 'Pattern', 'Pattern', '-v7.3');
end

fprintf(1, 'Done!\n');





