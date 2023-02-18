function [tMap,varargout] = simpleGLM(timeseries,designmatrix,contrast)
% [tMap, (betas), (residuals)] = simpleGLM(timeseries,designmatrix,contrast)
% Intended to take a whole-brain timeseries and compute a GLM contrast
% timeseries is an n * m matrix of fMRI values at n timepoints for m voxels
% designmatrix is an n * p matrix of n timepoints for p predictor variables
% contrast is a 1 x p vector of weights on each predictor, incl constant
% contrast can be generated by getContrastVector first
% tMap will return a 1 * m vector of t statistics for each voxel
% betas is an optional matrix of estimates
% residuals is an optional vector of error terms


    betas = (designmatrix' * designmatrix) \ designmatrix' * timeseries;
    residuals = timeseries - designmatrix * betas;
    tMap = (contrast * betas) ./ sqrt((std(residuals).^2) .* (contrast / (designmatrix' * designmatrix) * contrast'));
    
    varargout = cell(1,nargout-1);
    for i = 1:length(varargout)
        switch i
            case 1
                varargout{i} = betas;
            case 2
                varargout{i} = residuals;
            otherwise
                warning('Too many output arguments. Options are [tMap,betas,residuals]. Extra outputs ignored.')
                break
        end
    end
end