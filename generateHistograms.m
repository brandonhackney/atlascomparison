function input = generateHistograms(input)
% dataStruct = generateHistograms(dataStruct)
% Takes the output of extractTS_ROI and creates inhomogeneity histograms
% Makes three plots: task, control, and contrast.
% Saves to Plots folder in current directory.
% Also writes the median value from each plot into the input struct.
    set(0,'DefaultFigureVisible','off'); % suppress figure display
    numBins = 5; % while there are 14 ROIs
    edges = 0:4/numBins:4;
    % Histograms
    h1 = figure();
    h2 = figure();
    h3 = figure();
    % Scatterplots
    s1 = figure();
    s2 = figure();
    s3 = figure();
    for s = 1:length(input) % subject
        for t = 1:length(input(s).task) % task
            for h = 1:2 % hemisphere
                % task condition plot
                figure(h1);
                histogram([input(s).task(t).hem(h).data.meanPos],edges);
                title(sprintf('%s %s %s Task Conditions',...
                    input(s).subID,...
                    input(s).task(t).hem(h).name,...
                    input(s).task(t).name));
                xlabel('Parcel SD');
                ylabel('Counts');
                med1 = double(median([input(s).task(t).hem(h).data.meanPos]));
                hold on
                    line([med1;med1],ylim);
                    text(med1,max(ylim)/2,sprintf('Median = %f',med1))
                hold off
                % Scatterplot
                figure(s1);
                plot([input(s).task(t).hem(h).data(:).meanPos],...
                    [input(s).task(t).hem(h).data(:).medianPos],'o');
                title(sprintf('%s %s %s Task Conditions',...
                    input(s).subID,...
                    input(s).task(t).hem(h).name,...
                    input(s).task(t).name));
                xlabel('Parcel SD');
                ylabel('Parcel Median');
                % Save plots to file
%                 input(s).task(t).hem(h).plots(1).parcelSD = f1;
                input(s).task(t).hem(h).plots(1).median = med1;
                savefig(h1,sprintf('Plots/%s_%s_%s_task_%s_%s.fig',...
                    input(s).atlas,input(s).task(t).name,input(s).subID,'SDhistogram',input(s).task(t).hem(h).name));
                savefig(s1,sprintf('Plots/%s_%s_%s_task_%s_%s.fig',...
                    input(s).atlas,input(s).task(t).name,input(s).subID,'scatterplot',input(s).task(t).hem(h).name));
                
                % control condition plot
                figure(h2);
                histogram([input(s).task(t).hem(h).data.meanNeg],edges);
                title(sprintf('%s %s %s Control Conditions',...
                    input(s).subID,...
                    input(s).task(t).hem(h).name,...
                    input(s).task(t).name));
                xlabel('Parcel SD');
                ylabel('Counts');
                med2 = double(median([input(s).task(t).hem(h).data.meanNeg]));
                hold on
                    line([med2;med2],ylim);
                    text(med2,4,sprintf('Median = %f',med2))
                hold off
                % Scatterplot
                figure(s2);
                plot([input(s).task(t).hem(h).data(:).meanNeg],...
                    [input(s).task(t).hem(h).data(:).medianNeg],'o');
                title(sprintf('%s %s %s Control Conditions',...
                    input(s).subID,...
                    input(s).task(t).hem(h).name,...
                    input(s).task(t).name));
                xlabel('Parcel SD');
                ylabel('Parcel Median');
                % Save plots to file
%                 input(s).task(t).hem(h).plots(2).parcelSD = f2;
                input(s).task(t).hem(h).plots(2).median = med2;
                savefig(h2,sprintf('Plots/%s_%s_%s_control_%s_%s.fig',...
                    input(s).atlas,input(s).task(t).name,input(s).subID,'SDhistogram',input(s).task(t).hem(h).name));
                savefig(s2,sprintf('Plots/%s_%s_%s_control_%s_%s.fig',...
                    input(s).atlas,input(s).task(t).name,input(s).subID,'scatterplot',input(s).task(t).hem(h).name));
                
                % contrast plot
                figure(h3);
                histogram([input(s).task(t).hem(h).data.glmEffect],edges);
                title(sprintf('%s %s %s Contrast',...
                    input(s).subID,...
                    input(s).task(t).hem(h).name,...
                    input(s).task(t).name));
                xlabel('Parcel SD');
                ylabel('Counts');
                med3 = double(median([input(s).task(t).hem(h).data.glmEffect]));
                hold on
                    line([med3;med3],ylim);
                    text(med3,4,sprintf('Median = %f',med3))
                hold off
                % Scatterplot
                figure(s3);
                plot([input(s).task(t).hem(h).data(:).glmEffect],...
                    [input(s).task(t).hem(h).data(:).medianGLM],'o');
                title(sprintf('%s %s %s Contrast',...
                    input(s).subID,...
                    input(s).task(t).hem(h).name,...
                    input(s).task(t).name));
                xlabel('Parcel SD');
                ylabel('Parcel Median');
                % Save plots to file
%                 input(s).task(t).hem(h).plots(3).parcelSD = f3;
                input(s).task(t).hem(h).plots(3).median = med3;
                savefig(h3,sprintf('Plots/%s_%s_%s_contrast_%s_%s.fig',...
                    input(s).atlas,input(s).task(t).name,input(s).subID,'SDhistogram',input(s).task(t).hem(h).name));
                savefig(s3,sprintf('Plots/%s_%s_%s_contrast_%s_%s.fig',...
                    input(s).atlas,input(s).task(t).name,input(s).subID,'scatterplot',input(s).task(t).hem(h).name));
               
            end % hemisphere
        end % task
    end % subject
    set(0,'DefaultFigureVisible','on'); % re-enable figure display
end


%% This was set up ad-hoc - clean up for future
% Intended to compare the median homogeneity of different atlases
% Index 3 is pulling the median in the CONTRAST condition (eg not control)
function generateBarGraphs(input)
    figure()
    bar([schaefer.bio.medians(3),gordon.bio.medians(3);...
        schaefer.social.medians(3),gordon.social.medians(3)]);
    legend('Schaefer','Gordon');
    title('Atlas Comparison');
    xnames = {'BioMotion','SocialLocal'};
    set(gca,'xtick',[1:2],'xticklabel',xnames);
    ylabel('Median SD of parcel betas')
end