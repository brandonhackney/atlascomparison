function generateBoxplotsTask(subjList,atlasName)
% Boxplots
b = figure();
% I don't like manually defining it, but I also don't want to load early
taskList = {'AVLocal','Bio-Motion','ComboLocal','DynamicFaces','MTLocal',...
    'SocialLocal','Speech','ToM'};
    for t = 1:length(taskList) % task
        homogvec = [];
        for sind = 1:length(subjList) % subject
            s = subjList(sind);
            load(['ROIs' filesep 'STS' num2str(s) '_' atlasName '.mat']);
            for h = 2 % hemisphere
                if sind == 1
                    homogvec = [Pattern.task(t).hem(h).data(:).glmEffect];
                % switch glmEffect for meanEffect after running new statSD
                else
                    homogvec = [homogvec; [Pattern.task(t).hem(h).data(:).glmEffect]];
                end
            end % hem
        end % sub
%         homogvec(:,sind) = homocol;
    subplot(8,1,t)
    boxplot(homogvec,{Pattern.task(1).hem(2).data.label})
        title(sprintf('%s',Pattern.task(t).name))
%         ylabel('Mean beta')
        ylabel('SD of Betas');
%         xlabel('Parcel (RH only)')
        ylim([0 5]);
        yticks(0:5);
    end % task
    savefig(b,sprintf('Plots%s%s_task_boxplot.fig',...
        filesep,atlasName));
end