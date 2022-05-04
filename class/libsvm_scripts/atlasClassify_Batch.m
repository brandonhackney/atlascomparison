% clear; clc;
% close all;
% add root to path
p = specifyPaths;
% addpath(p.classifyPath);
% addpath(p.basePath);

figLabels = {'Gl', 'Go', 'P', 'S'};
atlasID = {'glasser6p0', 'gordon333dil', 'power6p0', 'schaefer400'};

condID = 'social';
% consider looping instead. would need to loop figures as well.
switch condID
    case 'social'
        metricID = {'wbFC_positive','meanB','overlap','stdB','meanPosB'};% 'meanFC_social', 
    case 'motion'
        metricID = {'wbFC_negative','meanB','overlap','stdB','meanNegB'}; % 'meanFC_control-motion',
    case 'control'
        % find out what to put here
        % aiming for Bowtie, Objects, Speech?
    case 'all'
        % See if you also care about meanFC?
        metricID = {'wbFC_positive','wbFC_negative','meanB', 'stdB', 'meanPosB', 'overlap'}; % {'wbFC_positive'}
    otherwise
        error = 'Incorrect condID. Pick from social, motion, control, or all.';
end

for h = 1:2 % hemisphere: big outer loop encompassing all
    
if h == 1
    hem = 'LH';
elseif h == 2
    hem = 'RH';
end


figure; % for the boxplots below

for m = 1:size(metricID, 2)
   for a = 1:size(atlasID, 2)

       [score(m, :, a, h), confMats{m,a,h}, taskNames] = atlasClassify(atlasID{a}, metricID{m}, condID, h);
       if a == 1
           taskList{m} = taskNames;
       end
   end
   cd(p.basePath)

   % Generate boxplots comparing classification accuracies by metric
   subplot(1, size(metricID, 2), m), boxplot(squeeze(score(m, :, :, h))); 
   xticklabels(figLabels);
   title(strrep(metricID{m},'_',' '));
   ylim([-5,105]);
   yticks([0:10:100]);

end
% add ANOVA code here - group by atlas and metric, look for interaction
% Need to flatten a 3D matrix into 2D, so cols are one of your factors
% score is 7x10x4: 7 metrics, 10 subjects, 4 atlases
% reshape to be 10x7x4, then flatten to 40x7
% So cols = metrics, rows = tasks per atlas
%
%... or flatten to 7x4 by averaging dim2 out (bc it's the folds, not subs)
% pre = squeeze(mean(score(:,:,:,h),2));

pre = permute(squeeze(score(:,:,:,h)),[2 1 3]); % transpose each page
anovData = reshape(permute(pre,[1 3 2]), size(pre,1) * size(pre,3),size(pre,2));
[pval,tbl,stats] = anova2(anovData,size(score,2));
    tbl{2,1} = 'Metric';
    tbl{3,1} = 'Atlas';
    % Close the pre-generated table and make a new one w updated info
    % Because I can't figure out how to edit the live one
    close(gcf);
    digits = [-1 -1 0 -1 2 4];
    statdisptable(tbl, getString(message('stats:anova2:TwoWayANOVA')), getString(message('stats:anova2:ANOVATable')), '', digits);

    
fprintf('\n\nStatistical analysis of classification results in %s',hem)
fprintf('\nAtlas:\t\tF(%i) = %f, p = %f',tbl{3,3},tbl{3,5},tbl{3,6});
fprintf('\nMetric:\t\tF(%i) = %f, p = %f', tbl{2,3},tbl{2,5},tbl{2,6});
fprintf('\nInteraction:\tF(%i) = %f, p = %f\n',tbl{4,3},tbl{4,5},tbl{4,6});


% Generate confusion matrices for each atlas-metric combination
% in confMats, j is metric and k is atlas
% each cell of confMats is task x task x subject
% reuse a and m from above for count of atlases and metrics
figure()
    for j = 1:m
        for k = 1:a
        g = k + (j-1)*a;
        subplot(m,a,g)
            imagesc(mean(confMats{j,k,h},3));
            title(sprintf('%s, Metric = %s, Atlas = %s', hem, strrep(metricID{j},'_',' '),atlasID{k}));
            xticks(1:length(taskNames)); yticks(1:length(taskNames));
            xticklabels(taskList{j});
            yticklabels(taskList{j});
            xtickangle(45);
            xlabel('Predicted');
            ylabel('Data');
            colorbar;
        end % for k
    end % for j
    clear g j k;
end % for h

% % Generate a bar graph comparing classification accuracy between atlases
% % Use score, which is metric x subject x atlas
% % And maybe instead of subplotting, you have different color bars per atlas
% figure()
% for j = 1:m
%     subplot(1,m,j)
%         bar(squeeze(mean(score(j,:,:),2)));
%         % add error bars
% %         hold on
% %         errorbar(score(j,:,:)); % this is wrong
% %         % you need to give it x values, min of bar, and height of bar
% %         % so manually calculate the quantiles or whatever first
% %         hold off
%         xticklabels(figLabels);
%         title(sprintf('Metric = %s',metricID{j}));
%         xlabel('Atlas');
%         ylabel('Mean Classification accuracy');
%         ylim([0,100]);
% end
% clear j