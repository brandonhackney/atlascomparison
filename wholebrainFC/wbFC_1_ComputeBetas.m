function wbFC_1_ComputeBetas(subID, taskID)

% Data = wbFC_1_ComputeBetas(subID, taskID)
%
% This function load mtc files, then computes the betas for each condition
% associated with that run. It needs to have information about timing (path
% to prt file), and information about the estimated human subject motion
% (path to 3DMC smd files). It also seeks to regress out the global signal
% (path to vtc file - GSR is extracted from vtc volumetric white matter).
% It uses the LSA approach to calculate the betas, and does it within a
% parallel processing loop. It saves the output to a derivatives folder,
% one file per run. Condition labels are in the design matrix variable (X).

warning off

%relevant paths
p = specifyPaths();
p.outPath = strcat(p.baseDataPath, 'deriv_betaMats/');
p.derivPath = strcat(p.outPath, subID, '/');
p.subPath = strcat(p.baseDataPath, 'deriv/', subID, '/');


% BasePath = '/data2/2020_STS_Multitask/analysis/wholebrainFC';
% DataPath = strcat('/data2/2020_STS_Multitask/data/deriv/', subID, '/');
% outPath = '/data2/2020_STS_Multitask/data/deriv_betaMats/';

%get all mtc files to process, ensuring proper filename
cd(p.subPath)
load('getFilePartsFromContrast.mat')
% this is basically like a vlookup against the loaded conditionList
% if you get a hit, take the file's name instead of the task name
% allows for having multiple contrasts out of one scan
fun = @(x) strcmp(taskID, conditionList(x).contrast);
check = find(arrayfun(fun, 1:length(conditionList)));
if check
    mtcName = conditionList(check).mtc;
else
    mtcName = taskID;
    fprintf('\nError finding mtc name via getFilePartsFromContrast(); defaulting to input %s\n',taskID);
end
fList = dir(strcat('*', mtcName, '*.mtc'));

DataTemplate.subID = subID;
TR = 2;  %% This looks like a red flag

% loop through each file
for f = 1:size(fList, 1)
    
    try

        fName = fList(f).name;
        fprintf(1, '\n\nWorking on %s\n', fName);


        % Load the mtc, get relevant data 
        cd(p.subPath)
        mtc = xff(fName);
        data = mtc.MTCData;
       
        NumVerts= mtc.NrOfVertices;
        NumVols = mtc.NrOfTimePoints;
        
        % get the GSR timeseries
        vtcfName = mtc.SourceVTCFile;
%         gsr = getGSR(subID, vtcfName);
        
        refPRTfName = mtc.LinkedPRTFile;
        if contains(refPRTfName,'RAWork')
            [PATHSTR,NAME,EXT] = fileparts(refPRTfName);
            refPRTfName = strcat(p.subPath, NAME, '.prt');
        elseif isempty(refPRTfName)
            ftemp = strsplit(fName, '_');
            prttemp = dir(strcat('*STS-', ftemp{1}(4:end), '*run-', ftemp{4}(end), '*', ftemp{3}(1:3), '*prt'));  
            refPRTfName = prttemp.name;
        end
        mtc.clearobj;


        
%         % get the 3DMC sdm file
%         cd(p.subPath)
%         temp = strsplit(fName, '_');
%         ind = find(strcmp(temp, '3DMCS') == 1);
%         sdmName = strcat(strjoin(temp(1:ind-1), '_'), '_3DMC.sdm');
%         sdm = xff(sdmName);
%         mcpred = sdm.SDMMatrix;
%         sdm.clearobj;
% 
%  
%         % prepare regressors
%         voltpred = expandRegVolterra(mcpred);       %Add Volterra expansion to design matrix
%         fd = getFwd(mcpred);
%         % voltpred = [voltpred;gsr];
         
        %get prt experimental information
        prt = xff(refPRTfName);  
        prtData = prt.Cond;
        prt.clearobj;
        
%         %make lss regressors
         X = constructLSS(prtData, NumVols);%, voltpred);
        
%         % for debugging against BV, use standard GLM
%         X = constructGLM(prtData, NumVols);        
        
        %compute betas for each trial
        nTrials = X.nTrials;
        betas = NaN(nTrials, size(data, 2));
        
        tic; fprintf(1, '\tComputing betas\n');
        for trial = 1:nTrials
            predMat = X.preds(:, :, trial);
       
            % loop through every vertex using a parfor
            parfor v = 1:size(data, 2)
                temp = regress(data(:,v), predMat);
                betas(trial, v) = temp(1); %LSS: save only the beta for trialOfInterest
%                 betas(:, v) = temp(1:nTrials); single glm method
            end
        end
        fprintf(1, '\tDone in %0.2f min!\n', toc/60);
        
        
        %create the new output directory, if needed
        cd(p.outPath)
        if ~exist(subID, 'dir')
            mkdir(subID)
        end
        cd(subID);
        
        %save these as .mat files
        % inject the taskID back in
        if ~strcmp(taskID, mtcName)
            ftemp = strsplit(fName, '_');
            ftemp{3} = taskID;
            fName = strjoin(ftemp,'_');
        end
        temp = strsplit(fName, '.');
        fOut = strcat(temp{1}, '_betas.mat');
        save(fOut, 'betas', 'X', 'prtData');
       
    catch e

        fprintf(1,'There was an error on line %i! The message was:\n%s\n\n',e.stack(1).line, e.message);
        fprintf(1,'\n\nThe identifier was:\n%s\n',e.identifier);
        pause(1);
    end
end

cd(p.basePath)



