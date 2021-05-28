function combinePlots(subjList,atlasName)
% Wrap existing histograms into one subplot per atlas
    close all
    h1 = figure(1);
    for sind = 1:length(subjList) % subject
        s = subjList(sind);
        sp = subplot(4,3,s);
        f = openfig(['Plots' filesep atlasName '_' 'STS' num2str(s) '_SDhistogram.fig']);
        copyobj(allchild(get(f,'CurrentAxes')),sp);
            title(['STS' num2str(s)]);
        close(figure(2)); clear f;
    end
    savefig(h1,sprintf('Plots%s%s_histogram.fig',...
        filesep,atlasName));
    close all
    
% Also wrap scatterplots
    s1 = figure(1);
    for sind = 1:length(subjList) % subject
        s = subjList(sind);
        sp = subplot(4,3,s);
        f = openfig(['Plots' filesep atlasName '_' 'STS' num2str(s) '_scatterplot.fig']);
        copyobj(allchild(get(f,'CurrentAxes')),sp);
            title(['STS' num2str(s)]);
        close(figure(2)); clear f;
    end
    savefig(s1,sprintf('Plots%s%s_scatterplot.fig',...
        filesep,atlasName));
    close all
        
end