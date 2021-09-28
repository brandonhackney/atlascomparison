function genTaskHist(subList,atlasName)
    taskList = {'AVLocal','Bio-Motion','ComboLocal','DynamicFaces','MTLocal',...
        'SocialLocal','Speech','ToM'};
    h1 = figure();
    for t = 1:length(taskList)
        task = taskList{t};
        fprintf('\tTask %s...',task);
        numBins = 10;
        edges = 0:4/numBins:4;
        % Histograms
        % plotting variables
        histovec = [];
        mediavec = [];
        for s = 1:length(subList) % subject
            sub = subList(s);
            load(['ROIs' filesep 'STS' num2str(sub) '_' atlasName '.mat']);
                for h = 1:2 % hemisphere
                    histovec = [histovec;[Pattern.task(t).hem(h).data(:).sdEffect]'];
                    mediavec = [mediavec;[Pattern.task(t).hem(h).data(:).medianGLM]'];
                end
            clear Pattern
        end

        % contrast plot
        subplot(3,3,t)
        histogram(histovec,edges);
            title(taskList{t});
            xlabel('Parcel SD');
            ylabel('Counts');
            ylim([0,150]);
            med3 = double(median(histovec));
            hold on
                line([med3;med3],ylim);
                text(med3,4,sprintf('Median = %f',med3))
            hold off
        fprintf(1,'done.\n');
    end
    % Save plot to file
    savefig(h1,sprintf('Plots%s%s_%s_SDhistogram.fig',...
        filesep,atlasName,'task'));
    close all; clear h;
end