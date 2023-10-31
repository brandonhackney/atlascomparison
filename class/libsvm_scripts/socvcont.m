% specify data to analyze
style = 'atlas';
% style = 'res';
omni = 'post';

% Get labels
switch omni
    case 'omni'
        metricID = {'omnibus'};
    case 'post'
%         metricID = {'meanB','overlap','stdB','meanPosB'};
        metricID = {'Contrast', 'Spatial Agreement', 'Inhomogeneity', 'Activation'};
end
numMetrics = length(metricID);

switch style
    case {'atlas', 'atlasBIG'}
        atlasname = {'Schaefer', 'Glasser', 'Gordon', 'Power'};
    case 'sch'
        atlasname = {'Schaefer 100', 'Schaefer 200', 'Schaefer 400', 'Schaefer 600', 'Schaefer 800', 'Schaefer 1,000'};
    case 'res'
        atlasname = getAtlasList('res');
end
numAtlases = length(atlasname);

% Get data
[y1, ~, er1] = null_atlasClassify_Batch(style, omni,'social'); y1 = single(y1);
[y2, ~, er2] = null_atlasClassify_Batch(style, omni,'control'); y2 = single(y2);

hemstr = {'LH', 'RH'};
% Plot accuracy across atlases as a line graph, with error bars for folds
figure();
for h = 1:2
    hem = hemstr{h};
    for j = 1:numMetrics % metric
%         pos = nestedPosition(h,j,numMetrics);
        pos = nestedPosition(j,h,2);
        subplot(numMetrics,2,pos); % metric by hemisphere
        x = 1:numAtlases;
        x = [x', x']; % I think?
        dat = [squeeze(mean(y1(j, :, h, :), 4))', squeeze(mean(y2(j, :, h, :), 4))' ];
        er = [squeeze(mean(er1(j, :, h, :), 4))', squeeze(mean(er2(j, :, h, :), 4))' ];
        errorbar(x, dat, er);
%         xticks([1,numAtlases]);
        xlim([0, numAtlases+1]); % add a margin
        xticks([0 x(:,1)' numAtlases+1]); % fix ticks?
        xticklabels([{''}, atlasname]); % put a blank label on 0
        xtickangle(45); % for legibility
        title(sprintf('%s %s',hem, metricID{j}));
        xlabel('Atlas');
        ylabel('Mean Classification accuracy');
        ylim([0, 100]);
        yticks(0:10:100);
        legend('Social tasks', 'Control tasks', 'Location', 'northeastoutside');
    end
end

% y1 and y2 are metric * atlas * hemisphere, with fold already averaged
% Stack into a new var y that is metric * atlas * hem * condition
% dim4 condition is 1 == social, 2 == control
y(:,:,:,1) = y1;
y(:,:,:,2) = y2;
clear y1 y2
clc;
%% ANOVA ANALYSIS
% Need to edit the below to match new dimensions
% Want to see if there's an effect of social vs control

% Set up your design matrix by labeling each dimension of y
% Use the size of y before it gets reshaped into a vector
mtrc = zeros(size(y));
    for e = 1:size(y,1)
        mtrc(e,:,:,:) = e;
    end
    mtrc = reshape(mtrc,1,numel(mtrc));
    mtrc = metricID(mtrc);
atls = zeros(size(y));
    for e = 1:size(y,2)
        atls(:,e,:,:) = e;
    end
    atls = reshape(atls,1,numel(atls));
    atls = atlasname(atls); % check this works
hms = zeros(size(y));
    for e = 1:size(y,3)
        hms(:,:,e,:) = e;
    end
    hms = reshape(hms,1,numel(hms));
    HMLST = {'LH' 'RH'};
    hms = HMLST(hms);
cnd = zeros(size(y));
    for e = 1:size(y,4)
        cnd(:,:,:,e) = e;
    end
    cnd = reshape(cnd,1,numel(cnd));
    cndList = {'Social','Control'};
    cnd = cndList(cnd);
% Define design matrix
%     dMatrix = {mtrc fld atls hms};
%     varnames = {'Metric','Fold','Atlas','Hemisphere'};

switch omni
    case 'omni'
        % Drop metric, since there's only the one
        dMatrix = {atls hms cnd};
        varnames = {'Atlas', 'Hemisphere', 'TaskType'};
    case 'post'
        dMatrix = {mtrc atls hms cnd};
        varnames = {'Metric', 'Atlas', 'Hemisphere', 'TaskType'};
end
% Which of the above variables is a random effect?
%     rfx = 2; % just fold

% Convert input data to a 1-D vector
y = reshape(y,1,numel(y)); %reads rows, then cols, then pages etc
%     [pval,tbl,stats] = anovan(y,dMatrix,'model','interaction','varnames',varnames,'random',rfx);
[pval,tbl,stats] = anovan(y,dMatrix,'model','interaction','varnames',varnames);

% Print marginal means
fprintf(1,'\nMarginal Means:\n')
for v = 1:length(varnames)
    fprintf(1,'\n')
    switch varnames{v}
        case 'Metric'
            items = metricID;
        case 'Atlas'
            items = atlasname;
        case 'Hemisphere'
            items = HMLST;
        case 'TaskType'
            items = cndList;
    end
    for i = 1:length(items)
        item = items{i};
        val = mean(y(strcmp(dMatrix{v},item)));
        fprintf(1,'%s:\t%0.2f\n',item,val);
    end
end


% Graph post-hoc tests to inspect any significant interactions
figure();
% dims = [1,4];
dims = [2,3];
[php, phm, phf, phg] = multcompare(stats, 'Dimension', dims); % come back and play with this - change which dims to compare
% Get the actual means for each item
[phg num2cell(phm)]
