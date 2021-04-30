function megascatter(subList)
% Generate one big scatterplot of parcel SD vs size, across everything
    x = [];
    y = [];
    atlasList = {'schaefer400','gordon333dil','glasser6p0','power6p0'};
    s1 = figure();
    
    for a = 1:length(atlasList)
        atlas = atlasList{a};
        fprintf(1,'Plotting %s...',atlas);
        for s = 1:length(subList)
            sub = ['STS',num2str(subList(s))];
            load(['ROIs' filesep sub '_' atlas '.mat']);
            for t = 1:length(Pattern.task)
                [posInd,negInd, ~] = getConditionFromFilename(Pattern.task(t).name);
                for h = 1:2
                    for p = 1:length(Pattern.task(t).hem(h).data)
                        newy = Pattern.task(t).hem(h).data(p).betaHat([posInd negInd],:)';
                        y = [y;std(reshape(newy,[1,numel(newy)]))];
                        x = [x;length(Pattern.task(t).hem(h).data(p).vertices)];
                        newy = [];
                    end
                end
            end
        end
    
        % Make plots
        subplot(length(atlasList),1,a)
        plot(x,y,'o');
            title([atlas ' SNR']);
            xlabel('Parcel SD');
            ylabel('Number of Vertices');
            xlim([0 20]);
        fprintf(1,'Done.\n')
    end
    
    savefig(s1,sprintf('Plots%sallAtlas_SNR.fig',...
        filesep));
end