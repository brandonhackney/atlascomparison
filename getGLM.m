function [output,tMap] = getGLM(timeseries,designmatrix, posInd, negInd)
% Timeseries is an n-by-m pattern matrix of n timepoints and m vertices
% Designmatrix is an n-by-p design matrix of n timepoints and p predictors
% posInd
% Output is a length-m structure with fields beta and residuals
% tMap is a length-m 'single' vector of t values per vertex
% tMap is intended to be placed in an SMP file as SMP.Map.SMPData
%
% I figured it was easier to wrap it up in a structure since 
%   different tasks will have different numbers of predictors.
% This way, you don't have to worry about output size when doing batch runs

    numVerts = size(timeseries,2);
    output = struct('beta',[],'residuals',[],'contrast',[]);
    output(numVerts).beta = []; % initialize size of output
    tMap = zeros([1,numVerts]); % initialize size of t vector
    contvec = getContrastVector(size(designmatrix,2),posInd,negInd); % e.g. [+1 +1 -2 0] or [+1 -1 0]
    parfor vert = 1:numVerts
        % Calculate the initial beta estimates and residuals
        [output(vert).beta,~,output(vert).residuals] = regress(timeseries(:,vert),designmatrix);
        % Use posInd and negInd to establish a weighted contrast of betas
        output(vert).contrast = (sum(output(vert).beta(posInd))./length(posInd)) - (sum(output(vert).beta(negInd))./length(negInd));
        % Scale the contrast by its standard error to get t vals
        % (which of course is complicated by matrix math)
        tMap(vert) = output(vert).contrast / sqrt((std(output(vert).residuals).^2) .* contvec / (designmatrix' * designmatrix) * contvec');
        % output(vert).Pvalue = ?? maybe we don't need them
    end
    tMap = single(tMap); % prepare for insertion into SMP file
end