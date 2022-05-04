atlasList = {'schaefer400','glasser6p0','gordon333dil','power6p0'}; % cell array of atlas names
for a = 1:length(atlasList)
    load([pwd filesep 'class' filesep 'data' filesep 'Classify_overlap_' atlasList{a} '.mat']);
    XLabels = [];
    numTasks = size(Data.taskNames,1);
    for h = 1:2
        figure();
        % Get the total number of vertices used for this hemisphere
        % It varies by subject, but I'll just assume it's roughly the same
        totalVert = 0;
            for z = 1:length(Data.hemi(h).parcelInfo(1).parcels)
                totalVert = totalVert + length(Data.hemi(h).parcelInfo(1).parcels(z).vertices);
            end
            clear z
        
        for p = 1:length(Data.hemi(h).parcelInfo(1).parcels)
            numVert = length(Data.hemi(h).parcelInfo(1).parcels(p).vertices);
            pdim = ceil(sqrt(length(Data.hemi(h).parcelInfo(1).parcels)));
            subplot(pdim,pdim,p)
            spdata = [];
            for s = 1:length(Data.hemi(h).parcelInfo)
                for i = 1:numTasks
    %                 hold on
    %                 plot([1:10],Data.hemi(h).parcels(p).taskData(i).parcelAlignment)
                    % glmAlignment is divided by the size of the GLM
                    % parcelAlignment is divided by the size of the parcel
    %                 spdata(:,i) = Data.hemi(h).parcels(p).taskData(i).glmAlignment;
                    x = size(Data.subID,1) * (i-1) + s; % an index
                    spdata(s,i) = Data.hemi(h).data(x,p);
                    XLabels{i} = Data.taskNames(i,:);
                end % for i
            end % for s
            boxplot(spdata)
            hold on
                line([0 numTasks+1], [numVert/totalVert numVert/totalVert]);
            hold off
            text(numTasks,numVert/totalVert,{'Expected' 'value'});
            xticks([1:numTasks]);
            xticklabels(XLabels);
            xtickangle(45);
            ylabel('% of parcel in GLM zone');
%             ylabel('% of GLM inside parcel');
            ylim([0,1]);
            yticks([0:0.1:1]);
%             legend(strcat('STS',num2str([1:10]')));
            title([atlasList{a} ': ' strrep(Data.hemi(h).parcelInfo(1).parcels(p).name,'_',' ')]);
        end % for p
        set(get(handle(gcf),'JavaFrame'),'Maximized',1);
%         tightfig()
    end % for h
end % for a