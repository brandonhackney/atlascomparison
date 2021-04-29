function generateBoxplots(subjList,atlasName)
    % Boxplots
    homogvec = [];
    for sind = 1:length(subjList) % subject
        s = subjList(sind);
        load(['ROIs' filesep 'STS' num2str(s) '_' atlasName '.mat']);
        homocol = [];
        for t = 1:length(Pattern.task) % task
            for h = 2 % hemisphere
                if t == 1 && sind == 1
                    homogvec = [Pattern.task(t).hem(h).data(:).glmEffect];
                else
                    homogvec = [homogvec; [Pattern.task(t).hem(h).data(:).glmEffect]];
                end
            end
        end
%         homogvec(:,sind) = homocol;
    end
    
    b3 = figure();
    boxplot(homogvec,{Pattern.task(1).hem(2).data.label})
        title(sprintf('%s Homogeneity by Parcel, RH only',atlasName))
        ylabel('SD of parcel betas')
        xlabel('Parcel')
    savefig(b3,sprintf('Plots%s%s_boxplot.fig',...
        filesep,atlasName));
end