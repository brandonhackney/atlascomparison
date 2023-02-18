clear; clc;

p = specifyPaths;


% load the matlab calculated betas
cd(p.baseDataPath)
cd('deriv_betaMats/STS4/')
load STS4_S1_SocialLocal_Run-1_Social1st_3DMCS_LTR_THP3c_undist_lh_betas;
betaMatlab = betas([1 3 5 7 2 4 6 8], :); %re-order to match the BVbeta order
betaMatlab_vect = reshape(betaMatlab, 1, numel(betaMatlab)); %reshape to allow easy plotting

%load the BV calculated betas
cd(p.baseDataPath)
cd('deriv_betaFC_audit/STS4/')
b = xff('STS4_S1_SocialLocal_Run-1_v2.glm');
betaBV = b.GLMData.BetaMaps(:, 1:8)';
betaBV_vect = reshape(betaBV, 1, numel(betaBV));

%plot scatterplot and compute the correlation coefficient
scatter(betaMatlab_vect, betaBV_vect);
corrcoef(betaMatlab_vect, betaBV_vect)
