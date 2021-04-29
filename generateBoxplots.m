function generateBoxplots(subjList,atlasName)
    % Boxplots
    homogvec = [];
    for sind = 1:length(subjList) % subject
        s = subjList(sind);
        load(['ROIs' filesep 'STS' num2str(s) '_' atlasName '.mat']);
        for t = 1:length(Pattern(s).task) % task
            for h = 1:2 % hemisphere
                homogvec(:,s) = [homogvec(:,s);Pattern(s).task(t).hem(h).data(:).glmEffect];
            end
        end
    end
    
    b3 = figure();
    boxplot(homogvec,[Pattern.task(1).hem(1).data.label])
        title('%s Homogeneity by Parcel',atlasName)
        ylabel('SD of parcel betas')
        xbalel('Parcel')
    savefig(b3,sprintf('Plots%s%s_boxplot.fig',...
        filesep,atlasName));
end