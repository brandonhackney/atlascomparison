function [cluster,LowerThreshold] = fdrCluster(tMap,df)
% [cluster,LowerThreshold] = fdrCluster(tMap,df)
% Given an input matrix tMap, tells you which indices are q <= 0.05
% LowerThreshold tells you the cutoff point

% Calculate regular p values
pMap = 1-tcdf(tMap,df);
% Calculate adjusted p values at q = 0.05 with Benjamini Hochberg FDR
FDR = mafdr(pMap,'BHFDR',true);
% Determine the t threshold that corresponds to q = 0.05
% Complicated since there may not be an exact 0.05 value
LowerThreshold = min(tMap(FDR == min(FDR(FDR >= 0.05))));
% Generate a list of indices with q <= 0.05
cluster = find(FDR <= 0.05);