function betas = null_calcBetas(mtcData, hemi)
% expects mtcData to have format (task, hemi), with .pattern and .pred

% for hemi = 1:2
    for task = 1:size(mtcData, 1)
        % starting data
        data = mtcData(task, hemi).pattern;
        pred = mtcData(task, hemi).pred;
        
        
        % add run-wise baseline predictors
%         numRuns = length(unique(mtcData(task,hemi).labels));
%         numVols = size(data, 1) / numRuns; %check this
%         
%         runPreds = zeros(numVols, numRuns);
%         for r = 1:numRuns
%             start = numVols*(r-1)+1;
%             runPreds(start:start+numVols-1, r) = ones;
%         end
%         pred = [pred runPreds];

        pred = [pred mtcData(task, hemi).labels]; % add run numbers
        pred = convertRunCol(pred); % use existing function for conversion
        
        % calculate betas
        % function expects input with input(x).pattern
        % returns output(x).betaHat for each x in input
        betas(task) = addBetas2(mtcData(task, hemi), pred);
%         betas(task, hemi).betaHat = addBetas2(data,pred);
        betas(task).contrast = mtcData(task, hemi).contrast;
%         betas(task, hemi).betaHat = out(1:end-numRuns); %eliminate extraneous betas 
    end
end

