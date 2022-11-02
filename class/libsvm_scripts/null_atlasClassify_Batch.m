clear; clc;
close all;
% add root to path
p = specifyPaths;
% addpath(p.classifyPath);
% addpath(p.basePath);


% !! Set these manually !!

% Pick data to compare: 'null', 'atlas', or 'res' for Schaefer resolutions
style = 'null';

% Pick tasks to include: 'social', 'motion', 'control', or 'all'
condID = 'all';

% Pick metrics: 'omni' for just omnibus, or 'post' for all metrics separate
% ("post" as in post-hoc test of omnibus)
omni = 'omni';

% !! Set these manually !!
% Maybe consider making it a function then...?

switch style
    case 'atlas'
        figLabels = {'Gls', 'Grd', 'Pwr', 'Sch'};
        atlasname = {'Glasser', 'Gordon', 'Power', 'Schaefer'};
        atlasID = {'glasser6p0', 'gordon333dil', 'power6p0', 'schaefer400'};
    case 'res'
        figLabels = {'100','200','400','600','800','1k'};
        atlasname = {'Schaefer 100', 'Schaefer 200', 'Schaefer 400', 'Schaefer 600', 'Schaefer 800', 'Schaefer 1,000'};
        atlasID = {'schaefer100','schaefer200','schaefer400','schaefer600','schaefer800','schaefer1000'};
    case 'null'
        numNulls = 1000;
        % lazy 'preallocation':
        for n = numNulls:-1:1
            nullnum = sprintf('%04.f',n);
            figLabels{n} = nullnum;
            atlasname{n} = ['Null #', nullnum];
            atlasID{n} = ['null_', nullnum];
        end
end

switch condID
    case 'social'
        metricID = {'meanB','overlap','stdB','meanPosB'};%  'meanFC_social', wbFC_Social
        mFig = {'Contrast', 'Spatial Agreement', 'Inhomogeneity', 'Activation'};
%         metricID = {'omnibus'};
%         mFig = {'All Metrics'};
    case 'motion'
        metricID = {'meanB','overlap','stdB','meanNegB'}; %  'meanFC_control-motion',wbFC_Motion
        mFig = {'Contrast', 'Spatial Agreement', 'Inhomogeneity', 'Activation'};
    case 'control'
        % find out what to put here
        % aiming for Bowtie, Objects, Speech?
        metricID = {'meanB','overlap','stdB','meanPosB'};
        mFig = {'Contrast', 'Spatial Agreement', 'Inhomogeneity', 'Activation'};
    case 'all'
        % can't have separate case for omnibus bc it's not a task type
        % must manually switch :/
        switch omni
            case 'omni'
                metricID = {'omnibus'};
                mFig = {'All Metrics'};
            case 'post'
                 % Essentially post-hoc tests for omnibus
                metricID = {'meanB', 'stdB', 'meanPosB', 'overlap', 'stdFC'};
                mFig = {'Contrast', 'Inhomogeneity', 'Activation', 'Spatial Agreement', 'Functional Connectivity'};
        end
    otherwise
        error = 'Incorrect condID. Pick from social, motion, control, or all.';
end

numMetrics = size(metricID,2);
numAtlases = size(atlasID,2);

hemstr = {'LH','RH'};
for h = 1:2 % hemisphere: big outer loop encompassing all
    
hem = hemstr{h};

fig = figure; % for the boxplots below
fig.Color = [1,1,1]; % white background


for m = 1:numMetrics
   for a = 1:numAtlases

       [score(m, :, a, h), confMats{m,a,h}, taskNames,truLab{m,a,h},prdLab{m,a,h}] = atlasClassify(atlasID{a}, metricID{m}, condID, h);
       if a == 1
           taskList{m} = taskNames;
       end
   end
   cd(p.basePath)

   % Generate BOXPLOTS comparing classification accuracies by metric
   subplot(1, size(metricID, 2), m), boxplot(squeeze(score(m, :, :, h))); 
   ax = gca;
   xticklabels(figLabels);
   title(strrep(mFig{m},'_',' '));
   ylim([-5,100]); % had a buffer of 105 at the top, but I like 100 better
   yticks([0:10:100]);
   chper = 100 * (1/length(taskNames)); % chance = 1/numTasks
   % round floating-point to 2 decimals: %f.2
   if m == 1; ylabel(sprintf('Classification Accuracy (chance = %.2f%%)', chper)); end
   box off; % remove right- and top- axes
   ax.TickLength = [0,0];
   ax.YGrid = 'on'; % just show horizontal lines
   wh = findobj('LineStyle', '--');
    set(wh,'LineStyle', '-'); % make whiskers not dashed
    set(wh,'Color',[0.5 0.5 0.5]); % set whisker color to 50% gray
   % still need to find whisker caps

end % for metric
% 
% % add ANOVA code here - group by atlas and metric, look for interaction
% % Need to flatten a 3D matrix into 2D, so cols are one of your factors
% % score is 7x10x4: 7 metrics, 10 subjects, 4 atlases
% % reshape to be 10x7x4, then flatten to 40x7
% % So cols = metrics, rows = tasks per atlas
% %
% %... or flatten to 7x4 by averaging dim2 out (bc it's the folds, not subs)
% % pre = squeeze(mean(score(:,:,:,h),2));
% if size(score,1) == 1 % if you only plug one metric in
%     pre = permute(score(:,:,:,h),[2 1 3]);
% else
%     pre = permute(squeeze(score(:,:,:,h)),[2 1 3]); % transpose each page
% end
% anovData = reshape(permute(pre,[1 3 2]), size(pre,1) * size(pre,3),size(pre,2));
% [pval,tbl,stats] = anova2(anovData,size(score,2));
%     tbl{2,1} = 'Metric';
%     tbl{3,1} = 'Atlas';
%     % Close the pre-generated table and make a new one w updated info
%     % Because I can't figure out how to edit the live one
%     close(gcf);
%     digits = [-1 -1 0 -1 2 4];
%     statdisptable(tbl, getString(message('stats:anova2:TwoWayANOVA')), getString(message('stats:anova2:ANOVATable')), '', digits);
% 
% fprintf('\n\nStatistical analysis of classification results in %s',hem)
% fprintf('\nAtlas:\t\tF(%i) = %f, p = %f',tbl{3,3},tbl{3,5},tbl{3,6});
% fprintf('\nMetric:\t\tF(%i) = %f, p = %f', tbl{2,3},tbl{2,5},tbl{2,6});
% fprintf('\nInteraction:\tF(%i) = %f, p = %f\n',tbl{4,3},tbl{4,5},tbl{4,6});

end % for hemisphere

%% Multiway ANOVA (more flexible than anova2)
% Include hemisphere as a factor instead of testing separately
% Can specify model parameters and variable names like an adult
% BUT need to flatten out to a 1xn vector; it can't take a matrix :(
% y is 1xn elements long, and so too must be each g in {g1,g2...gx}

% y = reshape(score,1,numel(score)); %reads rows, then cols, then pages etc
%     mtrc = zeros(size(score));
%         for e = 1:size(score,1)
%             mtrc(e,:,:,:) = e;
%         end
%         mtrc = reshape(mtrc,1,numel(mtrc));
%         mtrc = metricID(mtrc);
%     fld = zeros(size(score));
%         for e = 1:size(score,2)
%             fld(:,e,:,:) = e;
%         end
%         fld = reshape(fld,1,numel(fld));
%     atls = zeros(size(score));
%         for e = 1:size(score,3)
%             atls(:,:,e,:) = e;
%         end
%         atls = reshape(atls,1,numel(atls));
%         atls = atlasname(atls); % check this works
%     hms = zeros(size(score));
%         for e = 1:size(score,4)
%             hms(:,:,:,e) = e;
%         end
%         hms = reshape(hms,1,numel(hms));
%         HMLST = {'LH' 'RH'};
%         hms = HMLST(hms);
%         
% figure();
% varnames = {'Metric','Fold','Atlas','Hemisphere'};
% rfx = 2; %which of the above variables is a random effect?
% [pval,tbl,stats] = anovan(y,{mtrc fld atls hms},'model','interaction','varnames',varnames,'random',rfx);
% % [php, phm, phg] = multcompare(stats, 'Dimension', [1,3]); % come back and play with this - change which dims to compare

%% Make per-hemisphere figures
for h = 1:2
    hem = hemstr{h};
% Generate CONFUSION MATRICES for each atlas-metric combination
% in confMats, j is metric and k is atlas
% each cell of confMats is task x task x subject
% reuse a and m from above for count of atlases and metrics
% figure()
%     for j = 1:numMetrics
%         for k = 1:numAtlases
%         g = k + (j-1)*numAtlases;
%         subplot(numMetrics,numAtlases,g)
%             imagesc(mean(confMats{j,k,h},3),[0 1]);
%             title(sprintf('%s, %s for %s', hem, strrep(mFig{j},'_',' '),atlasname{k}));
%             xticks(1:length(taskList{j})); yticks(1:length(taskList{j}));
%             xticklabels(taskList{j});
%             yticklabels(taskList{j});
%             xtickangle(45);
%             xlabel('Predicted');
%             ylabel('Data');
%             caxis([0 1]);
% %             colorbar;
%         end % for k
%     end % for j
%     clear g j k;
% % end % for h

% smaller confusion matrix grid, for just one metric (pick meanB)
% figure()
%     for j = 1 % assuming metric 1 is meanB
%         for k = 1:a
%         g = k + (j-1)*a;
%         subplot(a/2,a/2,k)
%             imagesc(mean(confMats{j,k,h},3),[0 1]);
%             title(sprintf('%s, %s for %s', hem, strrep(mFig{j},'_',' '),atlasname{k}));
%             xticks(1:length(taskList{j})); yticks(1:length(taskList{j}));
%             xticklabels(taskList{j});
%             yticklabels(taskList{j});
%             xtickangle(45);
%             xlabel('Predicted');
%             ylabel('Data');
%             caxis([0 1]);
%             colorbar;
%         end % for k
%     end % for j
%     clear g j k;

% Generate a confusion chart, and cluster the tasks
% Requires Matlab R2018b or higher
% figure()
%     for j = 1:numMetrics
%         for k = 1:numAtlases
%         g = k + (j-1)*numAtlases;
%         subplot(numMetrics,numAtlases,g)
%         cm1 = confusionchart(truLab{j,k,h}, prdLab{j,k,h});
% %         sortClasses(cm1,'cluster'); % can set a vector of display order
% %         sortClasses(cm1,{'AVLocal', 'Bio-Motion','ComboLocal','DynamicFaces','SocialLocal','ToM','MTLocal','Motion-Faces','Objects','Speech','BowtieRetino'});
%         sortClasses(cm1,{'AVLocal', 'Bio-Motion','ComboLocal','DynamicFaces','SocialLocal','ToM','MTLocal','Objects','Speech','BowtieRetino'});
%             title(sprintf('%s, %s for %s', hem, strrep(mFig{j},'_',' '),atlasname{k}));
%         end % for k
%     end % for j
    
% Dendrograms showing the hierarchical clustering of tasks
% figure()
%     lnks = [];
%     for j = 1:numMetrics
%         for k = 1:numAtlases
%         g = k + (j-1)*numAtlases;
%         subplot(numMetrics,numAtlases,g)
%         cmt = confusionmat(truLab{j,k,h},prdLab{j,k,h});
%         dst = pdist(cmt); % calc euclidean distance
%         lnk = linkage(dst); % calc clustering
%         lnks = [lnks;lnk];
%         idx = optimalleaforder(lnk,dst); % calc ordering
%         ddlabs = taskNames(idx); %reorder task labels
%         dendrogram(lnk,'Reorder',idx,'Labels',ddlabs,'Orientation','left','ColorThreshold','default');
%             title(sprintf('%s, %s for %s', hem, strrep(mFig{j},'_',' '),atlasname{k}));
%             xlim([0,11]);
%         end % for k
%     end % for j

% Generate a histogram aggregating classification accuracy across atlases
% Use score, which is metric x subject x atlas x hemi
figure()
    for j = 1:m
        subplot(1,m,j)
            histogram(squeeze(score(j,:,:,h)));
            title(sprintf('%s',mFig{j}));
            xlim([0,101]);
            xticks([0 20 40 60 80 100]);
            xlabel('Classification Accuracy');
            ylabel('Count');
            if strcmp(style,'null')
                ylim([0, 7000]);  
            end
    end
    clear j

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