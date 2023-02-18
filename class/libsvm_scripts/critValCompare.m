%% Declare constants
atlasname = getAtlasList('atlas');
numAtlas = numel(atlasname);
%% Generate a null distribution from the null data
% Get the null classification data
score = null_atlasClassify_Batch('nullSMALL','omni','social');
scsz = size(score);
% Which dimension has the atlas info?
% metric fold atlas hem
% Except for nulls specifically, it's 1 atlas with 1000 iterations
% So the "atlas" I'm looking for gets rolled into fold
atlasDim = 2; 
    dropdims = 1:length(scsz);
    dropdims(dropdims == atlasDim) = []; % flexibly drop the atlasDim
% collapse the non-atlas dimensions, so we're left with one score per atlas
distro = squeeze(mean(score, dropdims));
%% Calculate the critical values of the distribution
mu = mean(distro);
sigma = std(distro);
% margError = 1.96 * sigma / sqrt(numAtlas);
margError = 1.96 * sigma;
CVlower = mu - margError;
CVupper = mu + margError;

%% Compare the atlas data to the null distribution
% Get the atlas data
clear score
score = null_atlasClassify_Batch('atlas','omni','social');

scsz = size(score);

for a = 1:numAtlas
    
    atlasID = atlasname{a};
    
    % Compare average score of each atlas to the critical values
    thisVal = mean(score(:,:,a,:), 'all');
    if thisVal >= CVupper || thisVal <= CVlower
        % significant
        fprintf(1,'Atlas %s is significantly different from null distribution!\n', atlasID);
        fprintf(1,'Accuracy %0.2f is outside the critical bounds of %0.2f and %0.2f\n',thisVal,CVlower,CVupper);
    else
        %not significant
        fprintf(1,'Atlas %s is NOT significantly different from null distribution!\n', atlasID);
        fprintf(1,'Accuracy %0.2f is within the critical bounds of %0.2f and %0.2f\n',thisVal,CVlower,CVupper);
    end
    
    % Extract some key value here to plot
    
end

% Plot results
% Convert distro array into a smooth distribution plot
% Insert vertical bars representing each atlas
% Label the bars?