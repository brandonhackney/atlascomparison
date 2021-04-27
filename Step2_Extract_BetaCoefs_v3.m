function Step2_Extract_BetaCoefs_v3( subID, voiType, stimIdx, nuisIdx, model, cleanMethod, customHrf )
% Step2_Extract_BetaCoefs_v3( subID, voiType, stimIdx, nuisIdx, model, cleanMethod, customHrf )
% subID is a string of the form 'sub-xx' where 'xx' is the subject id. 
% voiType is either 'cba' or 'rh_custom', or somehow otherwise is the missing
%           component of subID_[voiType].voi
% stimIdx indicates which events to model based on their indices in the
%           timing files
%           1 = precue
%           3 = action vignette
%           5 = post-cue
%           6 = button press
% nuisIdx indicates which events to model as nuisance (see idx above)
% model indicates which design matrix to produce
%           LSS = least squares single
%           LSA = least squares all
%           Decon = deconvolve the response using spike model
% cleanMethod indicates the cleaning steps to apply
%           0 = do nothing
%           1 = regress the six 3DMC parameters returned by BV
%           2 = regress the 24 parameter Voterra expansion of motion
%               estimates
%           3 = despike timepoints based on framewise displacement
%           4 = censor trials (based on framewise displacement)
%           5 = regress out the global signal (white matter + ventricles)
% customHrf (logical) indicates whether to fit a custom hrf inside each
%           voxel based on a hrf basis set and R^2

%Initial parameters
fdThresh = 0.5;  %mm
nDeconSpikes = 15;   %For deconvolution designs ONLY

% ... parameters for cutom hrf fitting process ONLY
alpha1_params = 6:.5:8;
onsetShift = 0;

%Generate label for event(s) we want modeled
stimLabel = 'event';
if ismember(1,stimIdx)
    stimLabel = strcat(stimLabel,'-precue');
end
if ismember(3,stimIdx)
    stimLabel = strcat(stimLabel,'-movie');
end
if ismember(4,stimIdx)
    stimLabel = strcat(stimLabel,'-blank2');
end
if ismember(5,stimIdx)
    stimLabel = strcat(stimLabel,'-resp');
end
if ismember(6,stimIdx)
    stimLabel = strcat(stimLabel,'-buttonpress');
end

voiStr = strrep(voiType,'_','-');

if stimIdx == 1
    stimLen = 2.5;      %duration in secs to model precue interval
else
    stimLen = [];
end

%% FILE I/O
baseDir = '/data1/2018_ActionDecoding/analysis_class/';
dataDir = '/data1/2018_ActionDecoding/data';
gsrDir = '/data1/2018_ActionDecoding/analysis_class/GSR';

%If subject id was not provided, ask user to select one
if nargin < 1
    cd(dataDir)
    subList = ListSubfolders;
    idx = listdlg('ListString',subList,'Name','Select subjects');
    subID = subList{idx};
end

subDir = strcat('/data1/2018_ActionDecoding/data/', subID);
bvDir = fullfile(subDir,'bv');
sess2Dir = fullfile(bvDir,'sess-02');
savDir = '/data1/2018_ActionDecoding/analysis_class/betas';
hrfDir = '/data1/2018_ActionDecoding/analysis_class/deconvolvedHrf';
behDir = fullfile(subDir,'beh','sess-02');

%Get list of all 3DMC files
cd(sess2Dir);
sdmList = dir('*3DMC.sdm');
cd(baseDir);

%Get list of all timing/behavioral files
cd(behDir);
eventsList = dir('*_events.tsv');
behavList = dir('*_responses.tsv');
cd(baseDir);

%Get list of all global signal files
cd(gsrDir)
gsrFid = sprintf('%s*GSRTS.mat',subID);
gsrList = dir(gsrFid);
cd(baseDir);

%Load PatternData file
cd(subDir);cd('bv');
if nargin < 2
    patternList = dir('*.mat');
    patternList = {patternList(:).name};
    idx = listdlg('ListString',patternList,'Name','Select Pattern Data');
    patternfid = patternList{idx};
else
   patternfid = sprintf('%s_%s.mat',subID,voiType); 
end
load(patternfid);    %will be read in as 'Data'

if customHrf == true
    cd(baseDir)
    load('hrfparams_Kay.mat');     %Stored in variable 'params'
    hrfType = ones(24,1);
else
    if strcmp(model,'Decon')
        hrfType = NaN(nDeconSpikes,1);
    else
        hrfType = zeros(24,1);
    end
end

%Set some imaging parameters
nScans = size(Data.patterns{1,1},3);
nRoi = size(Data.patterns,2);
nVols = 202;

%Preallocate data
Data.fd = nan(nVols,nScans); 

nTrials = 24;

%Start constructing base file name for output
basefid = sprintf('%s_voi-%s_%s_nuis',subID,voiStr,stimLabel);

if isempty(nuisIdx)
    basefid = strcat(basefid,'-none');
end
if ismember(1,nuisIdx)
    basefid = strcat(basefid,'-precue');
end
if ismember(3,nuisIdx)
    basefid = strcat(basefid,'-movie');
end
if ismember(5,nuisIdx)
    basefid = strcat(basefid,'-resp');
end
if ismember(6,nuisIdx)
    basefid = strcat(basefid,'-buttonpress');
end
    

%Add prefix for cleaning method used
basefid = strcat(basefid,'_clean');

%Create unique file names for output
if ismember(0,cleanMethod)
    basefid = strcat(basefid,'-none');
end

if ismember(1,cleanMethod)
    basefid = strcat(basefid,'-3DMC');
end

if ismember(2,cleanMethod)
    basefid = strcat(basefid,'-volterra');
end

if ismember(3,cleanMethod)
    basefid = sprintf('%s-%s%.0fmm',basefid,'despike',fdThresh*10);
    outFnameSpikeCount = sprintf('%s_SpikeCounts.txt',basefid);
end

if ismember(4,cleanMethod)
    basefid = strcat(basefid,'-censoredFD');
end

if ismember(5,cleanMethod)
    basefid = strcat(basefid,'-GSR');
end

if strcmp(model,'LSS')
    basefid = strcat(basefid,'_model-LSS');
elseif strcmp(model,'LSA')
    basefid = strcat(basefid,'_model-LSA');
elseif strcmp(model,'Decon')
    basefid = strcat(basefid,'_model-decon');
end

if customHrf == true
    basefid = strcat(basefid,'_hrf-custom');
elseif customHrf == false
    basefid = strcat(basefid,'_hrf-canonical');
end

%Add file extension to complete file name
outFnameTxt = strcat(basefid,'_betacoefs.txt');
outFnameMat = strcat(basefid,'_betacoefs.mat');
outFnameRoi = strcat(basefid,'_betacoefs_roiList.txt');

%Save list of ROIs
cd(savDir)
roiListFid = fopen(outFnameRoi,'w');
for r = 1:nRoi
    fprintf(roiListFid,'%s\n',Data.ROIlist.labels(r,:));
end
fclose(roiListFid);
cd(baseDir);


%Write header for BetaCoefs file
header = {'trialNum',...
    'scan',...
    'betaHat',...
    'cond',...
    'roi',...
    'vox',...
    'x.matlab',...
    'y.matlab',...
    'z.matlab',...
    'motion',...
    'view',...
    'action',...
    'actor',...
    'instr',...
    'resp',...
    'hrfType',...
    'alpha1',...
    'r2'};

fid = fopen(fullfile(savDir,outFnameTxt),'wt');
fprintf(fid,'%s\t',header{1:end-1});
fprintf(fid,'%s\n',header{end});
fclose(fid);

if ismember(3,cleanMethod)
    %Write header for SpikesPerTrial file
    spikesPerTrialHeader = {'trialNum','scan','totSpikes'};
    spikesPerTrialFid = fopen(fullfile(savDir,outFnameSpikeCount),'wt');
    fprintf(spikesPerTrialFid,'%s\t',spikesPerTrialHeader{1:end-1});
    fprintf(spikesPerTrialFid,'%s\n',spikesPerTrialHeader{end});
end


%% Estimate Beta Coefs
%for baselineFlag = 0:1
for baselineFlag = 0:0      %0=stim intervals, 1=null intervals
    
    for r = 1:nRoi
        
        nVox = size(Data.patterns{1,r},2);
        if baselineFlag == 0
            if strcmp(model,'Decon')
                Data.betaCoefs.stim{1,r} = NaN(nDeconSpikes,nVox,nScans);
            else
            end
        elseif baselineFlag == 1
            if strcmp(model,'Decon')
                Data.betaCoefs.stim{1,r} = NaN(nDeconSpikes,nVox,nScans);
            else
                Data.betaCoefs.null{1,r} = NaN(nTrials,nVox,nScans);
            end
        end 
        
        for scan = 1:nScans
            
            %Compute ROI averaged time course for this run
            roiTS = mean(Data.patterns{1,r}(:,:,scan),2);
            
            %load SDM file
            sdmPath = fullfile(sess2Dir,sdmList(scan).name);
            mcpred = readBvSDM(sdmPath,6);     %read in motion correction estimates from BV
            mcpred = detrend(mcpred);             %Remove linear trend
            voltpred = expandRegVolterra(mcpred);       %Add Volterra expansion to design matrix
            fd = getFwd(mcpred);
            Data.fd(:,scan) = fd;
            
            %load events file
            cd(behDir)
            events = importdata(eventsList(scan).name);
            cd(baseDir)
            
            %Load global signal (if required)
            if ismember(5,cleanMethod)
                load(fullfile(gsrDir,gsrList(scan).name));
            end
            
            %load behavioral data
            cd(behDir)
            behav = importdata(behavList(scan).name);
            behav.data(behav.data(:,1)==-1,1) = NaN;   %Replace missed responsese with missing values
            behav.data(behav.data(:,2)==-1,2) = NaN;   %Replace missed responsese with missing values
            
            %save stimulus labels
            Data.stimLabels.motion{1,scan} = behav.data(:,8);
            Data.stimLabels.view{1,scan} = behav.data(:,7);
            Data.stimLabels.action{1,scan} = behav.data(:,6);
            Data.stimLabels.actor{1,scan} = behav.data(:,5);
            Data.stimLabels.instruction{1,scan} = behav.data(:,4);
            Data.stimLabels.buttonpress{1,scan} = behav.data(:,2);
            cd(baseDir)
            
            actionLabel = behav.data(:,6);
            taskLabel = behav.data(:,4);
            
            %calculate duration of each event from timestamps
            eventsTs = events.data(:,1:2:11);
            eventsDur = eventsTs(:,2:end) - eventsTs(:,1:end-1);
            eventsDur(:,6) = behav.data(:,1);   %add rt
            %eventsDur(isnan(eventsDur(:,6)),6) = eventsDur(isnan(eventsDur(:,6)),5);
            eventsDur(:,7) = eventsDur(:,5) - eventsDur(:,6);   %Response interval - rt
            eventsDur(isnan(eventsDur(:,7)),7) = eventsDur(isnan(eventsDur(:,7)),5);
            eventsDur(:,5) = [];    %remove response interval dur (2.5 sec)
            eventsDur(:,7) = [eventsTs(2:end,1) - eventsTs(1:end-1,6); 15];
            
            
            % Make preds for nuisance events
            % 1. Pre cue
            [~, X_lsa_precue] = makeDesignMatrix(eventsDur, baselineFlag, nVols, 1, actionLabel, taskLabel, [], []);
            preCuePred = sum(X_lsa_precue,2);
            % 3. Movie
            [~, X_lsa_movie] = makeDesignMatrix(eventsDur, baselineFlag, nVols, 3, actionLabel, taskLabel, [], []);
            moviePred = sum(X_lsa_movie,2);
            % 5. Response
            [~, X_lsa_resp] = makeDesignMatrix(eventsDur, baselineFlag, nVols, 5, actionLabel, taskLabel, [], []);
            respPred = sum(X_lsa_resp,2);
            % 6. Button press
            [~, X_lsa_buttonPress] = makeDesignMatrix_buttonPress(eventsDur, baselineFlag, nVols, 6, actionLabel, taskLabel);
            buttonPressPred = sum(X_lsa_buttonPress,2);
            
            
            %Create LSS/LSA/Decon design matrix
            %Make Decon design matrix
            if strcmp(model,'Decon')
                X_decon = makeDeconMat(eventsDur, nDeconSpikes, stimIdx, nVols);
                X_decon = X_decon(1:202,:);
                
                %Adding nuisance preds now ...
                if ismember(1,nuisIdx)
                    X_decon = [X_decon preCuePred];
                    
                end
                
                if ismember(3,nuisIdx)
                    X_decon = [X_decon moviePred];
                    
                end
                
                if ismember(5,nuisIdx)
                    X_decon = [X_decon respPred];
                    
                end
                
                if ismember(6,nuisIdx)
                    X_decon = [X_decon buttonPressPred];
                    
                end
                
                
                %Add intercept
                X_decon(:,size(X_decon,2)+1) = 1;

            else
                %Make LSS or LSA matrix
                % ... for canonical Hrf (custom hrfs will need to be fit
                % inside the voxel loop (v)
                if customHrf == false
                    [X_lss, X_lsa] = makeDesignMatrix(eventsDur,baselineFlag,nVols, stimIdx, actionLabel,taskLabel,[],stimLen);
                    
                    %Adding nuisance preds now ...
                    if ismember(1,nuisIdx)
                       X_lsa = [X_lsa preCuePred];
                       X_lss(:,size(X_lss,2)+1,:) = repmat(preCuePred,1,1,nTrials);
                    end
                    
                    if ismember(3,nuisIdx)
                       X_lsa = [X_lsa moviePred];
                       X_lss(:,size(X_lss,2)+1,:) = repmat(moviePred,1,1,nTrials);
                    end
                    
                    if ismember(5,nuisIdx)
                       X_lsa = [X_lsa respPred];
                       X_lss(:,size(X_lss,2)+1,:) = repmat(respPred,1,1,nTrials);
                    end
                    
                    if ismember(6,nuisIdx)
                       X_lsa = [X_lsa buttonPressPred];
                       X_lss(:,size(X_lss,2)+1,:) = repmat(buttonPressPred,1,1,nTrials);
                    end
                    
                    
                    %Mean center the LSS design matrix
                    nrow = size(X_lss,1);
                    for dim = 1:size(X_lss,3)
                        X_lss(:,:,dim) = X_lss(:,:,dim) - ones(nrow,1) * mean(X_lss(:,:,dim));
                    end
                    
                    %Add intercept to design matrix
                    X_lsa = [X_lsa ones(nVols,1)];
                    
                    
%                 elseif customHrf == true
%                     
%                     %Use custom parameters for hrf
%                     [hrf, hrf_params] = fithrf(T0_params,alpha1_params,.1,roiTS,eventsDur, baselineFlag, nVols, stimIdx, actionLabel, taskLabel,stimLen);
%                     
%                     [X_lss, X_lsa] = makeDesignMatrix(eventsDur,baselineFlag,nVols,stimIdx,actionLabel,taskLabel,hrf, stimLen);
%                     
%                     %Adding nuisance preds now ...
%                     if ismember(1,nuisIdx)
%                        X_lsa = [X_lsa preCuePred];
%                        X_lss(:,size(X_lss,2)+1,:) = repmat(preCuePred,1,1,nTrials);
%                     end
%                     
%                     if ismember(3,nuisIdx)
%                        X_lsa = [X_lsa moviePred];
%                        X_lss(:,size(X_lss,2)+1,:) = repmat(moviePred,1,1,nTrials);
%                     end
%                     
%                     if ismember(5,nuisIdx)
%                        X_lsa = [X_lsa respPred];
%                        X_lss(:,size(X_lss,2)+1,:) = repmat(respPred,1,1,nTrials);
%                     end
%                     
%                     if ismember(6,nuisIdx)
%                        X_lsa = [X_lsa buttonPressPred];
%                        X_lss(:,size(X_lss,2)+1,:) = repmat(buttonPressPred,1,1,nTrials);
%                     end
%                     
%                     %Mean center the LSS design matrix
%                     nrow = size(X_lss,1);
%                     for dim = 1:size(X_lss,3)
%                         X_lss(:,:,dim) = X_lss(:,:,dim) - ones(nrow,1) * mean(X_lss(:,:,dim));
%                     end
%                     
%                     %Add intercept to design matrix
%                     X_lsa = [X_lsa ones(nVols,1)];
%                     
                 end
            end
            
            
            
            %Extract the beta estimates for each ROI and each voxel
            for v = 1:nVox
                %Select the appropriate time series
                Y = Data.patterns{1,r}(:,v,scan);
                
                %Find best fitting hrf here (if using custom)
                if customHrf == true
                    %Use Kendrick Kay's libray of 20 hrfs
                    %[hrf, hrfIdx, r2max] = fithrf_Kay(params,.1,Y,eventsDur, baselineFlag, nVols, stimIdx, actionLabel, taskLabel,stimLen);
                    
                    %Use custom parameters for hrf
                    [hrf, hrf_params] = fithrf(alpha1_params,onsetShift,.1,Y,eventsDur, baselineFlag, nVols, stimIdx, actionLabel, taskLabel,stimLen);
                    
                    [X_lss, X_lsa] = makeDesignMatrix(eventsDur,baselineFlag,nVols,stimIdx,actionLabel,taskLabel,hrf, stimLen, hrf_params(2));
                    
                    %Adding nuisance preds now ...
                    if ismember(1,nuisIdx)
                       X_lsa = [X_lsa preCuePred];
                       X_lss(:,size(X_lss,2)+1,:) = repmat(preCuePred,1,1,nTrials);
                    end
                    
                    if ismember(3,nuisIdx)
                       X_lsa = [X_lsa moviePred];
                       X_lss(:,size(X_lss,2)+1,:) = repmat(moviePred,1,1,nTrials);
                    end
                    
                    if ismember(5,nuisIdx)
                       X_lsa = [X_lsa respPred];
                       X_lss(:,size(X_lss,2)+1,:) = repmat(respPred,1,1,nTrials);
                    end
                    
                    if ismember(6,nuisIdx)
                       X_lsa = [X_lsa buttonPressPred];
                       X_lss(:,size(X_lss,2)+1,:) = repmat(buttonPressPred,1,1,nTrials);
                    end
                    
                    %Mean center the LSS design matrix
                    nrow = size(X_lss,1);
                    for dim = 1:size(X_lss,3)
                        X_lss(:,:,dim) = X_lss(:,:,dim) - ones(nrow,1) * mean(X_lss(:,:,dim));
                    end
                    
                    %Add intercept to design matrix
                    X_lsa = [X_lsa ones(nVols,1)];
                    
                end
                
                
                %% Create nuissance preds and clean data
                nuisPred = [];
                
                %3DMC
                if ismember(1,cleanMethod)
                    nuisPred = [nuisPred mcpred];
                end
                
                %Volterra expansion
                if ismember(2,cleanMethod)
                    nuisPred = [];
                    nuisPred = [nuisPred voltpred];
                end
                
                %Despiking
                if ismember(3,cleanMethod)
                    [spikeIdx, spikeReg] = createSpikeMat(fd,fdThresh,2);
                    nuisPred = [nuisPred spikeReg];
                    %Zero out spikes from design matrices
                    X_lss(spikeIdx,:,:) = 0;
                    X_lsa(spikeIdx,:) = 0;
                    
                    %Record number of spikes per trial
                    if baselineFlag==0 && r==1 && v==1
                        for t=1:nTrials
                            currTrial = X_lss(:,1,t);
                            trialIdx = find(currTrial ~= mode(currTrial));
                            trialSpikes = intersect(trialIdx,spikeIdx);
                            trialTotSpikes = length(trialSpikes);
                            fprintf(spikesPerTrialFid,'%i\t%i\t%i\n',t,scan,trialTotSpikes);
                        end
                    end
                end
                
                %Trial censoring
                if ismember(4,cleanMethod)
                    spikeIdx = createSpikeMat(fd,fdThresh,2);
                    if stimIdx == 6
                        trialsToScrub = censorTrials_buttonpress( eventsDur,spikeIdx,stimIdx(1) );
                    else
                        trialsToScrub = censorTrials( eventsDur,spikeIdx,stimIdx(1) );
                    end
                end
                
                %GSR
                if ismember(5,cleanMethod)
                    nuisPred = [nuisPred GSRTS];
                end
                
                %Finally, add nuisance preds to design matrix
                if cleanMethod > 0
                    
                    %Two step approach (remove nuisance signal first)
                    nuisPred = [nuisPred ones(length(nuisPred),1)];  %Add intercept to model
                    [~,~,Y] = regress(Y,nuisPred);
                    
%                     %One step approach (append nuisance preds to LSS mat)
%                     if strcmp(model,'LSS')
%                         ncolLSS = size(X_lss,2);
%                         nuisFirstPred = ncolLSS+1;
%                         nuisLastPred = nuisFirstPred+size(nuisPred,2)-1;
%                         X_lss(:,nuisFirstPred:nuisLastPred,:) = repmat(nuisPred,1,1,nTrials);
%                     end
                end
                
                %% Extract beta coefs
                if strcmp(model,'LSS')
                    betaHat = extractBetaLSS( Y, X_lss );
                elseif strcmp(model,'LSA')
                    betaHat = inv(X_lsa'*X_lsa)*X_lsa'*Y;
                    betaHat = betaHat(1:nTrials);
                elseif strcmp(model,'Decon')
                    betaHat = inv(X_decon'*X_decon)*X_decon'*Y;
                    betaHat = betaHat(1:nDeconSpikes);
                end
                
                %Remove variance accounted by viewpoint/repeated actions
                X_vp = behav.data(:,7);
                
                X_repeats = behav.data(:,6);
                X_repeats = diff(X_repeats) == 0;
                X_repeats = [0; X_repeats];
                
                X_nuisVar = [X_repeats ones(length(X_vp),1)];
                
%                 [b,~,betaHat] = regress(betaHat,X_nuisVar);
%                 betaHat = betaHat + b(2);
                
                %Censor trials (if indicated)
                if ismember(4,cleanMethod)
                   betaHat(trialsToScrub) = NaN; 
                end
                
                %Record beta data (to be saved in .mat file later)
                if baselineFlag == 0
                    Data.betaCoefs.stim{1,r}(:,v,scan) = betaHat;
                elseif baselineFlag == 1
                    Data.betaCoefs.null{1,r}(:,v,scan) = betaHat;
                end
                
                %Record beta coefficients in .txt file
                
                if strcmp(model,'Decon')
                    trialNum = (1:nDeconSpikes)';
                    scanLabel = repmat(scan,nDeconSpikes,1);
                    if baselineFlag == 0                    %1=movie, 2=baseline
                        condLabel = repmat(1,nDeconSpikes,1);    %labels for conditions
                    else
                        condLabel = repmat(2,nDeconSpikes,1);
                    end
                    roiLabel = repmat(r,nDeconSpikes,1);
                    voxLabel = repmat(v,nDeconSpikes,1);
                    x.matlab = repmat(Data.ROIlist.Data(r).MatlabIn(v,1),nDeconSpikes,1);
                    y.matlab = repmat(Data.ROIlist.Data(r).MatlabIn(v,2),nDeconSpikes,1);
                    z.matlab = repmat(Data.ROIlist.Data(r).MatlabIn(v,3),nDeconSpikes,1);
                    motionLabel = NaN(nDeconSpikes,1);
                    viewLabel = NaN(nDeconSpikes,1);
                    actionLabel = NaN(nDeconSpikes,1);
                    actorLabel = NaN(nDeconSpikes,1);
                    instrLabel = NaN(nDeconSpikes,1);
                    buttonLabel = NaN(nDeconSpikes,1);
                    
                    alpha1Params = NaN(nDeconSpikes,1);
                    r2 = NaN(nDeconSpikes,1);
             
                    
                else
                    trialNum = (1:nTrials)';
                    scanLabel = repmat(scan,nTrials,1);
                    if baselineFlag == 0                    %1=movie, 2=baseline
                        condLabel = repmat(1,nTrials,1);    %labels for conditions
                    else
                        condLabel = repmat(2,nTrials,1);
                    end
                    roiLabel = repmat(r,nTrials,1);
                    voxLabel = repmat(v,nTrials,1);
                    x.matlab = repmat(Data.ROIlist.Data(r).MatlabIn(v,1),nTrials,1);
                    y.matlab = repmat(Data.ROIlist.Data(r).MatlabIn(v,2),nTrials,1);
                    z.matlab = repmat(Data.ROIlist.Data(r).MatlabIn(v,3),nTrials,1);
                    motionLabel = behav.data(:,8);
                    viewLabel = behav.data(:,7);
                    actionLabel = behav.data(:,6);
                    actorLabel = behav.data(:,5);
                    instrLabel = behav.data(:,4);
                    buttonLabel = behav.data(:,2);
                    if customHrf == true
                        alpha1Params = repmat(hrf_params(1),nTrials,1);
                        r2 = repmat(hrf_params(3),nTrials,1);
                    else
                        alpha1Params = NaN(nTrials,1);
                        r2 = NaN(nTrials,1);
                    end
                    
                end
                
                
                betaDataTxt = [trialNum scanLabel betaHat condLabel roiLabel voxLabel x.matlab y.matlab z.matlab motionLabel viewLabel actionLabel actorLabel instrLabel buttonLabel hrfType alpha1Params r2];
                
                
                %Write .txt data
                cd(baseDir)
                dlmwrite(fullfile(savDir,outFnameTxt),betaDataTxt,'delimiter','\t','-append')
                cd(baseDir);
            end
        end
    end
end

%Save .mat file
betaData = Data;
cd(savDir)
save(outFnameMat,'betaData');
cd(baseDir);


end

function [ subFolders ] = ListSubfolders(path)
%Lists all and only the subfolders for the current path
if nargin < 1
    d = dir;
else
    d = dir(path);
end
subfolderSel = [d(:).isdir];            %logical selector vector
subFolders = {d(subfolderSel).name};
subFolders(ismember(subFolders,{'.','..'})) = [];
end