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
    h3 = figure();
    % Scatterplots
    s3 = figure();
    % plotting variables
    histovec = [];
    mediavec = [];
    for s = 1:length(input) % subject
        for t = 1:length(input(s).task) % task
            for h = 1:2 % hemisphere
                histovec = [histovec;[input(s).task(t).hem(h).data(:).glmEffect]];
                mediavec = [mediavec;[input(s).task(t).hem(h).data(:).medianGLM]];
            end
        end
    end

    % contrast plot
    figure(h3);
    histogram(histovec,edges);
    title(sprintf('%s Homogeneity',input(1).subID));
    xlabel('Parcel SD');
    ylabel('Counts');
    med3 = double(median(histovec));
    hold on
        line([med3;med3],ylim);
        text(med3,4,sprintf('Median = %f',med3))
    hold off
    
    % Scatterplot
    figure(s3);
    plot(histovec,mediavec,'o');
    title(sprintf('%s Consistency',input(1).subID));
    xlabel('Parcel SD');
    ylabel('Parcel Median');
    
    % Save plots to file
    savefig(h3,sprintf('Plots/%s_%s_SDhistogram.fig',...
        input(1).atlas,input(1).subID));
    savefig(s3,sprintf('Plots/%s_%s_%s_scatterplot.fig',...
        input(1).atlas,input(1).subID));
    set(0,'DefaultFigureVisible','on'); % re-enable figure display
    close all;
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