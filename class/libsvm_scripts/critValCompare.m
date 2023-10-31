function critValCompare(varargin)
% critValCompare(style, omni)
% Runs classification twice, one for 'atlas' and once for 'null'
% Generates confidence intervals based on 'null', prints results to screen
% Exports results to file, located in /analysis/class/results/

%% Declare constants
p = specifyPaths;

if nargin < 1
    style = 'atlas';
else
    style = varargin{1};
end
if nargin < 2
    omni = 'omni';
else
    omni = varargin{2};
end
condList = {'social', 'control'};

atlasname = getAtlasList(style);
numAtlas = numel(atlasname);

% Choose comparison data
if strcmp(style, 'atlas')
    nullName = 'nullSMALL';
elseif strcmp(style, 'sch')
    nullName = 'schnull';
else
    error('Not sure what to use as a null distribution!');
end


% Make a big outer loop to compare social and control
for c = 1:numel(condList)
condID = condList{c};
%% Generate a null distribution from the null data
% Get the null classification data
distro = null_atlasClassify_Batch(nullName,omni,condID);
scsz = size(distro);
% Which dimension has the atlas info?
% metric atlas hem iteration, so dim 4 for nulls
switch style
    case 'sch'
        iterDim = 4;
    case 'atlas'
        iterDim = [2 4];
    otherwise
        disp(nullName);
        disp(scsz);
        iterDim = input('Please specify the dimension number(s) to average over');
end
distro = single(distro); % reduce memory load

% % metric fold atlas hem
% % Except for nulls specifically, it's 1 atlas with 1000 iterations
% % So the "atlas" I'm looking for gets rolled into fold
% atlasDim = 2; 
%     dropdims = 1:length(scsz);
%     dropdims(dropdims == atlasDim) = []; % flexibly drop the atlasDim
% % collapse the non-atlas dimensions, so we're left with one score per atlas
% distro = squeeze(mean(score, dropdims));
%% Calculate the critical values of the distribution
mu = mean(distro, iterDim, 'omitnan');
sigma = std(distro, 0, iterDim, 'omitnan');
% margError = 1.96 * sigma / sqrt(numAtlas);
margError = 1.96 .* sigma;
CVlower = mu - margError;
CVupper = mu + margError;

% all terms now have dimensions of metric, atlas, hem

%% Get the atlas data
clear score
[score, chance, errorTerm] = null_atlasClassify_Batch(style,omni, condID);

scsz = size(score);
    numMetric = scsz(1);
%     numAtlas = scsz(2); % already defined above


%% Compare the atlas data to the null distribution
% % This section needs modification to compare within hem and metric, too
% for a = 1:numAtlas
%     
%     atlasID = atlasname{a};
%     
%     % Compare average score of each atlas to the critical values
% %     thisVal = mean(score(:,:,a,:), 'all');
%     thisVal = mean(score(:,a,:,:), 'all');
%     if thisVal >= CVupper || thisVal <= CVlower
%         % significant
%         fprintf(1,'Atlas %s is significantly different from null distribution!\n', atlasID);
%         fprintf(1,'Accuracy %0.2f is outside the critical bounds of %0.2f and %0.2f\n',thisVal,CVlower,CVupper);
%     else
%         %not significant
%         fprintf(1,'Atlas %s is NOT significantly different from null distribution!\n', atlasID);
%         fprintf(1,'Accuracy %0.2f is within the critical bounds of %0.2f and %0.2f\n',thisVal,CVlower,CVupper);
%     end
%     
%     % Extract some key value here to plot
%     
% end

%% Check inputs for figure labels
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

switch style
    case 'atlas'
        figLabels = {'Sch', 'Gls', 'Grd', 'Pwr'};
        atlasname = {'Schaefer', 'Glasser', 'Gordon', 'Power'};
        atlasID = {'schaefer400','glasser6p0', 'gordon333dil', 'power6p0'};
    case 'sch'
        figLabels = {'100','200','400','600','800','1k'};
        atlasname = {'Schaefer 100', 'Schaefer 200', 'Schaefer 400', 'Schaefer 600', 'Schaefer 800', 'Schaefer 1,000'};
        atlasID = {'schaefer100','schaefer200','schaefer400','schaefer600','schaefer800','schaefer1000'};
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

%% Plot results as bar charts with histogram on side
% Convert distro array into a smooth distribution plot
% Insert vertical bars representing each atlas
% Label the bars?
hemstr = {'LH', 'RH'};
for h = 1:2

    % Build a subplot grid for the things you want
    fig = figure();

        % Each metric gets a 5x5 subplot:
        % left col is histogram, remaining cols are bar graph
        xres = 5;
        yres = numMetric*(xres+1);
        x = 1:xres*yres;
        xsq = reshape(x,yres,xres)';
        
        % Define colors to use
        myColors = lines();
        myColors = myColors(1:numAtlas, :);
        
        for m = 1:numMetric
            
            % Get data
            thisData = score(m, :, h);
            
            % Get null distribution to display on side
            thisDistro = squeeze(mean(distro(m,:,h,:), [1 2]));
            
            % Calculate position in subplot grid
            col1 = (m-1) * xres + 1; % the first col of each block
            col2 = (m-1)*xres+2:m*xres; % the remaining cols of each block
            if m == numMetric
                % Use some extra space needed for the legend
                col2 = (m-1)*xres+2:m*(xres+1)-2;
            end
            p1 = xsq(1:xres,col1);
            p2 = xsq(:,col2); p2 = reshape(p2, [numel(p2) 1]);

            % Define bar graph
            subplot(xres,yres,p2);

                % Define critical value coords
                cvl = squeeze(CVlower(m,:,h));
                cvu = squeeze(CVupper(m,:,h));
                if strcmp(style, 'atlas') || strcmp(style, 'atlasBIG')
                    xval = 0:numAtlas + 1;
                    % Collapse across atlases, but not if it's multires
                    cvl = mean(cvl);
                    cvu = mean(cvu);
                    cvc = repmat([cvl,cvu-cvl], [length(xval),1]);
                elseif strcmp(style, 'sch')
                    % Double up coords to define a block per atlas
                    xval = 0:numAtlas-1;
                    xval = [xval; xval+1-eps];
                    xval = xval(:)'; % interleave that second row
                    
                    cvl = repelem(cvl,1,2)';
                    cvu = repelem(cvu, 1,2)';
                    cvc = repmat([cvl,cvu-cvl], [length(xval)/2,1]);
                    cvc = [cvl, cvu-cvl];
                end
                cvColors = [1,1,1;.92, .92, .92]; % white then light gray
                
                % Define chance accuracy line coords
                chper = 100 * chance;
%                 xval = 0:numAtlas+1;
                yval = repmat(chper, [1, length(xval)]);
                
                hold on;
                    % Draw critical value area
                    cva = area(xval,cvc);
                        cva(1).FaceColor = "none";
                        cva(2).FaceColor = [.92 .92 .92];
                    % Draw chance line
                    line(xval,yval);
                    % Draw bars on top of chance line
                    ph = bar(1,thisData,'grouped');
                    % Draw error bars
                    thisError = errorTerm(m, :, h);
                    	[numVars, numGroups] = size(thisError);
                        groupwidth = min(0.8, numGroups/(numGroups + 1.5));
                        for i = 1:numGroups
                            %Calculate center of each bar
                            x = (1:numVars) - groupwidth/2 + (2*i-1) * groupwidth / (2*numGroups);
                            errorbar(x,thisData(:,i),thisError(:,i), 'k', 'linestyle', 'none');
                        end
                hold off;

%                 bins1 = 0:1:numAtlas+1; % x axis units
                bins2 = 0:5:100; % y axis units   
                
%                 ph.CData = myColors; % recolor
                
                % Labels for the bar graph
                title(sprintf('%s %s tasks', hemstr{h}, condID));
                xticklabels({' ', mFig{m}});
%                 xticks(bins1)
%                 xticklabels(atlasname); % since there's a 0 bin
                ylim([bins2(1) bins2(end)]);
                yticks(bins2);
                yticklabels('');
                h1 = gca; set(h1, 'yaxislocation', 'right');
%                 legend(atlasname,'location','southoutside','Orientation','horizontal');
                if m == numMetric
                    [hleg, hico] = legend(['bad', 'Crit. Vals.', 'Chance', atlasname], 'location', 'northeastoutside');
                    % Delete the entry called 'bad'
                    % This is the area under the critical value band
                    % Stole this code from a forum
                    istxt = strcmp(get(hico, 'type'), 'text');
                    hicot = hico(istxt);
                    hicol = hico(~istxt);
                    delete(hicot(ismember(get(hicot, 'String'), {'bad'})));
                    delete(hicol(ismember(get(hicol, 'Tag'),    {'bad'})));

                end
            
            if ~strcmp(style, 'sch') % having many histograms is too complex
            % Define histogram
            subplot(xres,yres,p1);
                count = hist(thisDistro, bins2);
                count = count/max(count);

                ph2 = barh(bins2, 1-count);

                set(ph2, 'facecolor', 'k', 'basevalue', 1);
                xlim([-0.2 1]);
                ylim([bins2(1) bins2(end)]);
                if m == 1
                    ylabel(sprintf('SVM Accuracy (Chance = %0.2f %%)', chper));
                end
                yticks(bins2);
                xticks([]);
    %             h2 = gca;
    %             set(h2, 'ytick', bins2, 'box', 'on', 'xtick', [], 'ticklength', [0 0]);
            end
        end % for metric
        
% Export data before moving to next loop
fout = sprintf('%s_%s_%s.mat', style, omni, condID);
fpout = fullfile(p.basePath, 'class', 'results', fout);
save(fpout, 'score', 'distro', 'errorTerm', 'CVupper', 'CVlower', 'atlasname', 'metricID');

% Export figure to file

hout = strjoin({'CritVal',style, omni, condID, [hemstr{h} '.eps']},'_');
hpout = fullfile(p.basePath, 'figures', hout);
hgexport(fig, hpout);
end % for hemisphere

end % for condition