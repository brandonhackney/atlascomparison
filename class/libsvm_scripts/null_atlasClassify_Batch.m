function varargout = null_atlasClassify_Batch(varargin)
% [score], [chance%], [stdError] = null_atlasClassify_Batch([atlasStyle], [omni/post], [taskTypes], [classifierType])
%
% Runs atlasClassify on multiple atlases, plotting results
% Default is omnibus classification of normal atlases
% Optionally outputs the classification accuracy of all iterations
%
% atlasStyle is one of: atlas, sch, null, res
% omni is one of: omni, post
% taskTypes is one of: social, motion, control, or all
% classifierType is one of: svm, nyabes, or lda

% clc;
% close all;
% add root to path
p = specifyPaths;
% addpath(p.classifyPath);
% addpath(p.basePath);


% Pick data to compare:
% 'null', 'atlas', 'res' for null resolutions, or 'sch' for Schaefer resolutions
if nargin > 0
    style = varargin{1};
else
    style = 'atlas';
end

% Pick metrics: 'omni' for just omnibus, or 'post' for all metrics separate
% ("post" as in post-hoc test of omnibus)
if nargin > 1
    omni = varargin{2};
else
    omni = 'omni';
end

% Pick type of tasks to include: 'social', 'motion', 'control', or 'all'
if nargin > 2
    condID = varargin{3};
else
    condID = 'all';
end

% Pick which kind of classifier to use: 'svm', 'nbayes', or 'lda'
if nargin > 3
    ctype = varargin{4};
else
    ctype = 'svm';
end

usedTaskList = getTaskList(condID); % used to subset data from class files

numIter = 1; % default

switch style
    case 'atlas'
        figLabels = {'Sch', 'Gls', 'Grd', 'Pwr'};
        atlasname = {'Schaefer', 'Glasser', 'Gordon', 'Power'};
        atlasID = {'schaefer400','glasser6p0', 'gordon333dil', 'power6p0'};
    case 'sch'
        figLabels = {'100','200','400','600','800','1k'};
        atlasname = {'Schaefer 100', 'Schaefer 200', 'Schaefer 400', 'Schaefer 600', 'Schaefer 800', 'Schaefer 1,000'};
        atlasID = {'schaefer100','schaefer200','schaefer400','schaefer600','schaefer800','schaefer1000'};
    case 'schnull'
        figLabels = {'100','200','400','600','800','1k'};
        atlasname = {'Null 100', 'Null 200', 'Null 400', 'Null 600', 'Null 800', 'Null 1,000'};
        atlasID = {'schnull0100','schnull0200','schnull0400','schnull0600','schnull0800','schnull1000'};
    case {'res', 'mres'} % if either of these
        figLabels = {'010', '020', '050', '100', '150', '200', '250', '300'};
        atlasname = {'10 Parcels', '20 Parcels', '50 Parcels', '100 Parcels', '150 Parcels', '200 Parcels', '250 Parcels', '300 Parcels'};
        atlasID = {'res005', 'res010', 'res025', 'res050', 'res075', 'res100', 'res125', 'res150'};
    case 'null'
        figLabels = {'Null'};
        atlasname = {'Null'};
        atlasID = {'null'};
    case 'nullSMALL'
        figLabels = {'Null'};
        atlasname = {'Null'};
        atlasID = {'nullSMALL'};
    case 'atlasBIG'
        figLabels = {'Sch', 'Gls', 'Grd', 'Pwr'};
        atlasname = {'Schaefer', 'Glasser', 'Gordon', 'Power'};
        atlasID = {'schaeferBIG', 'glasserBIG', 'gordonBIG', 'powerBIG'};
    case 'fake'
        figLabels = {'Fake'};
        atlasname = {'Fake'};
        atlasID = {'fake'};
    otherwise
        error('Improper atlas name!')
end % switch style

% This returns the predefined list of iterations for the chosen atlas style
% e.g. null_0001, null_0002, etc. instead of just 'null'
[atlasfName, numIter] = getAtlasList(style);

% Load a list of which things to drop, if such a list exists
rejectfname = fullfile(p.basePath, sprintf('Reject_%s.mat',style));
if exist(rejectfname,'file')
    naughtyList = importdata(rejectfname);
else
    % keep everything
    naughtyList = false([length(atlasfName), 2]);
end


switch omni
    case 'omni'
        metricID = {'omnibus'};
        mFig = {'All Metrics'};
    case 'post'
        switch condID
            case 'social'
                metricID = {'meanB','overlap','stdB','meanPosB'};%  'meanFC_social', wbFC_Social
                mFig = {'Contrast', 'Spatial Agreement', 'Inhomogeneity', 'Activation'};
        %         metricID = {'omnibus'};
        %         mFig = {'All Metrics'};
            case 'motion'
                % Avoid using this
                metricID = {'meanB','overlap','stdB','meanNegB'}; %  'meanFC_control-motion',wbFC_Motion
                mFig = {'Contrast', 'Spatial Agreement', 'Inhomogeneity', 'Activation'};
            case 'control'
                metricID = {'meanB','overlap','stdB','meanPosB'};
                mFig = {'Contrast', 'Spatial Agreement', 'Inhomogeneity', 'Activation'};
            case 'all'
                % can't have separate case for omnibus bc it's not a task type
                % must manually switch :/

                 % Essentially post-hoc tests for omnibus
                metricID = {'meanB', 'overlap', 'stdB', 'meanPosB'};%, 'stdFC'};
                mFig = {'Contrast', 'Spatial Agreement', 'Inhomogeneity', 'Activation'};%, 'Functional Connectivity'};
            otherwise
                error('Incorrect condID. Pick from social, motion, control, or all.');
        end
end % switch omni

numMetrics = size(metricID,2);
numAtlases = size(atlasID,2);
hemstr = {'LH','RH'};

%% TEMP
% Subset to the top or bottom 50, based on an external variable
% THis worked in conjunction with something else, but I've forgotten what..
% clear atlasfName
% global Top50;
% numIter = 50;
% for z = 1:50
%     % TOP 50, LH
%     num = Top50(z,2);
%     atlasfName{z} = sprintf('%s_%04.f',atlasID{1},num);
% end

%% Calculate accuracy for each atlas
% Or load existing results bc these calculations can be very slow
% Check the 'results' folder
outDir = fullfile(p.classifyPath, '..', 'results');
outfname = strjoin({style, omni, condID, ctype, 'wFolds'}, '_');
out = fullfile(outDir, [outfname '.mat']);
if exist(out, 'file')
    load(out, 'score');
    numSubs = size(score, 2);
else
    % Get number of subjects by temporarily loading a data file
    tfname = sprintf('Classify_%s_%s.mat', metricID{1}, atlasfName{1});
    tfpath = fullfile(p.classifyDataPath, tfname);
    Data = importdata(tfpath);
    numSubs = length(Data.subID);
    clear Data tfname tfpath;
    
    % Run the calculations.
    % Preallocate score with nans
    % This way, skip trials don't get set to 0 and included in means
    score = nan([numMetrics, numSubs, numAtlases, 2, numIter]);

    for h = 1:2
    %     figure(); % to contain the plots from makeSVMweights
        for m = 1:numMetrics
           for a = 1:numAtlases
               confMats{m,a,h} = 0;
               truLab{m,a,h} = [];
               prdLab{m,a,h} = [];
               for iter = 1:numIter
                   f = nestedPosition(a,iter,numIter);
                   % If this iter is on the naughty list, then skip it
                   if naughtyList(f, h)
                       % Maybe unnecessary but I'm being CAREFUL
                       score(m, :, a, h, iter) = NaN;
                       continue
                   end

                   [score(m, :, a, h, iter), cmat, taskNames, truelabel, predlabel] = atlasClassify(atlasfName{f}, metricID{m}, condID, h, ctype);
                   if a == 1 && iter == 1
                       taskList{m} = taskNames;
                   end
                   % Concatenate data for all iterations
                   confMats{m,a,h} = confMats{m,a,h} + cmat;
                   truLab{m,a,h} = [truLab{m,a,h}; truelabel];
                   prdLab{m,a,h} = [prdLab{m,a,h}; predlabel];
               end % for iter
           end % for atlas
    %        cd(p.basePath)
        end % for metric

    end % for hemisphere
    
    % Export data with folds
    % Now that I'm using Naive Bayes, I want the fold info for plotting.
    % This is what the previous step checks for.
    save(out, 'score');
    
end % if data already exists

%% AVERAGE ACROSS FOLDS
% We need to average across all the SVM folds, because:
% 1. They are not meaningful individually, and
% 2. leaving them overloads RAM when calculating ANOVA
% the anovan() function converts your data into a square matrix,
% and when there are half a million datapoints to start with,
% you end up with a ~70GB correlation matrix.
% Averaging over fold reduces that by an order of magnitude.
% Result should be m metrics * 1 fold * a atlases * 2 hem * i iterations
errorTerm = std(score,0,2, 'omitnan') ./ sqrt(numSubs);
score = mean(score, 2);

% Now drop the fold dimension, so that it becomes m * a * h * i
scsz = size(score);
scsz(2) = [];
score = reshape(score, scsz);
errorTerm = reshape(errorTerm, scsz);
% Now, any variability comes from the iteration dimension
% If numIter == 1, you have point estimates for each metric+atlas+hem cell


% % !! I have substantially changed the shape of my main variable !!
% % Any code after this needs to be debugged - commenting it all out for now.
% 
% y = score;
% 
% %% COLLAPSE ITERATIONS
% if numIter ~= 1
%     % If you have multiple iterations, collapse them now
%     % This moves dim5 iteration to position 3 next to fold,
%     % Then reshapes to collapse fold and iteration together,
%     % Preserving the original shape before iteration was added
%     % Use dims 3 and 4 bc we measure size before permute
%     % Really want dims 4 and 5 of the permuted matrix
%     % DO NOT SQUEEZE - that removes singleton dimensions, not empty cells
%     scsz = size(score);
%     score = reshape(permute(score, [1 2 5 3 4]), scsz(1),[],scsz(3),scsz(4));
%     y = reshape(permute(y, [1 2 5 3 4]), scsz(1),[],scsz(3),scsz(4));
% end
% 
% 
% 
% %% Multiway ANOVA (more flexible than anova2)
% % Include hemisphere as a factor instead of testing separately
% % Can specify model parameters and variable names like an adult
% % BUT need to flatten out to a 1xn vector; it can't take a matrix :(
% % y is 1xn elements long, and so too must be each g in {g1,g2...gx}
% % if numIter == 1
% 
%     y = single(y); % reduce memory load
%     % Set up your design matrix by labeling each dimension of y
%     % Use the size of y before it gets reshaped into a vector
%     mtrc = zeros(size(y));
%         for e = 1:size(y,1)
%             mtrc(e,:,:,:) = e;
%         end
%         mtrc = reshape(mtrc,1,numel(mtrc));
%         mtrc = metricID(mtrc);
% %     fld = zeros(size(score));
% %         for e = 1:size(score,2)
% %             fld(:,e,:,:) = e;
% %         end
% %         fld = reshape(fld,1,numel(fld));
%     atls = zeros(size(y));
%         for e = 1:size(y,3)
%             atls(:,:,e,:) = e;
%         end
%         atls = reshape(atls,1,numel(atls));
%         atls = atlasname(atls); % check this works
%     hms = zeros(size(y));
%         for e = 1:size(y,4)
%             hms(:,:,:,e) = e;
%         end
%         hms = reshape(hms,1,numel(hms));
%         HMLST = {'LH' 'RH'};
%         hms = HMLST(hms);
%     
%     % Define design matrix
% %     dMatrix = {mtrc fld atls hms};
% %     varnames = {'Metric','Fold','Atlas','Hemisphere'};
%     dMatrix = {mtrc atls hms};
%     varnames = {'Metric', 'Atlas', 'Hemisphere'};
%     % Which of the above variables is a random effect?
% %     rfx = 2; % just fold
% 
%     % Convert input data to a 1-D vector
%     y = reshape(y,1,numel(y)); %reads rows, then cols, then pages etc
% %     [pval,tbl,stats] = anovan(y,dMatrix,'model','interaction','varnames',varnames,'random',rfx);
%     [pval,tbl,stats] = anovan(y,dMatrix,'model','interaction','varnames',varnames);
%     
%     % Graph post-hoc tests to inspect any significant interactions
% %     figure();
% %     [php, phm, phg] = multcompare(stats, 'Dimension', [1,3]); % come back and play with this - change which dims to compare
% 
% % end % if not null or res
% % %% Make per-hemisphere figures
% for h = 1:2
%     hem = hemstr{h};
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
% if ~strcmp(style,'null')
% figure()
% %     ha = tight_subplot(numMetrics, numAtlases);
%     for j = 1:numMetrics
%         for k = 1:numAtlases
%         g = k + (j-1)*numAtlases;
%         subplot(numMetrics,numAtlases,g)
% %         axes(ha(g));
%         cm1 = confusionchart(truLab{j,k,h}, prdLab{j,k,h});
% %         sortClasses(cm1,'cluster'); % can set a vector of display order
% %         sortClasses(cm1,{'AVLocal', 'Bio-Motion','ComboLocal','DynamicFaces','SocialLocal','ToM','MTLocal','Motion-Faces','Objects','Speech','BowtieRetino'});
%         sortClasses(cm1,usedTaskList);
%         % Give percentage of times, normalized to the class, not prediction
%         % ie I don't care how many times you guessed X,
%         % I care how many times you missed X and what you guessed instead
%         cm1.Normalization = 'row-normalized';
%             title(sprintf('%s, %s for %s', hem, strrep(mFig{j},'_',' '),atlasname{k}));
%         end % for k
%     end % for j
    
% end % if not null
    
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
% 
% scsz = size(score);
%  % Generate BOXPLOTS comparing classification accuracies by metric
%     fig = figure();
%     fig.Color = [1,1,1]; % white background
%     for m = 1:numMetrics
%        % Use reshape instead of squeeze in case of [1,1,x,1]
%        % That would end up with [x,1] instead of [1,x]
%         thisData = score(m,:,:,h);
%        thisData = reshape(thisData, [scsz(2),scsz(3)]);
%        % Hack solution to force it to make multiple boxplots
%        % If only 1 row, it makes a single box
%        % So double the data along dim1 so it makes all boxes
%        if numel(thisData) == numAtlases
%            thisData(2,:) = thisData(1,:);
%        end
% %        subplot(1, numMetrics, m), boxplot(squeeze(score(m, :, :, h)));
%        subplot(1, numMetrics, m), boxplot(thisData);
%        ax = gca;
%        xticklabels(figLabels);
%        title(sprintf('%s %s',strrep(mFig{m},'_',' '),hem));
%        ylim([-5,100]); % had a buffer of 105 at the top, but I like 100 better
%        yticks([0:10:100]);
%        chper = 100 * (1/length(taskNames)); % chance = 1/numTasks
%        % round floating-point to 2 decimals: %.2f
%        if m == 1; ylabel(sprintf('Classification Accuracy (chance = %.2f%%)', chper)); end
%        box off; % remove right- and top- axes
%        ax.TickLength = [0,0];
%        ax.YGrid = 'on'; % just show horizontal lines
%        wh = findobj('LineStyle', '--');
%         set(wh,'LineStyle', '-'); % make whiskers not dashed
%         set(wh,'Color',[0.5 0.5 0.5]); % set whisker color to 50% gray
%         % Find and remove whisker caps
%         bh = ax.Children.Children; allTags = get(bh, 'tag'); isCap = contains(allTags,'Adjacent'); delete(bh(isCap));
%         clear bh allTags isCap
%         % Insert chance accuracy line
%         hold on
%             xval = 0:numel(figLabels)+1;
%             yval = repmat(chper, [1, length(xval)]);
%             line(xval,yval);
%         hold off
%     end % for metric

% % Generate a histogram aggregating classification accuracy across atlases
% % Use score, which is metric x subject x atlas x hemi
% figure()
%     for j = 1:numMetrics
%         subplot(1,numMetrics,j)
%             histogram(squeeze(score(j,:,:,h)));
%             title(sprintf('%s',mFig{j}));
%             xlim([0,101]);
%             xticks([0 20 40 60 80 100]);
%             xlabel('Classification Accuracy');
%             ylabel('Count');
%             if strcmp(style,'null')
%                 ylim([0, 7000]);  
%             end
%     end
%     clear j
% % This is no longer useful, now that we've collapsed iteration and atlas

% end % for h

% 
% % % Generate a bar graph comparing classification accuracy between atlases
% % % Use score, which is metric x subject x atlas
% % % And maybe instead of subplotting, you have different color bars per atlas
% % figure()
% % for j = 1:m
% %     subplot(1,m,j)
% %         bar(squeeze(mean(score(j,:,:),2)));
% %         % add error bars
% % %         hold on
% % %         errorbar(score(j,:,:)); % this is wrong
% % %         % you need to give it x values, min of bar, and height of bar
% % %         % so manually calculate the quantiles or whatever first
% % %         hold off
% %         xticklabels(figLabels);
% %         title(sprintf('Metric = %s',metricID{j}));
% %         xlabel('Atlas');
% %         ylabel('Mean Classification accuracy');
% %         ylim([0,100]);
% % end
% % clear j

% OUTPUT
if nargout > 0
    varargout{1} = score;
end
if nargout > 1
    % Export chance percentage
    varargout{2} = 1/numel(usedTaskList);
end
if nargout > 2
    % Export standard error over fold
    varargout{3} = errorTerm;

end