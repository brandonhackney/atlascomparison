function plotGridParcels(metric,atlasList)
% metric is either meanFC, meanB, or stdB
switch metric
    case 'meanFC'
        prefix = 'Class';
        suffix = 'preproc_Task';
    case {'meanB', 'stdB'}
        prefix = 'Classify';
        suffix = 'effect';
    otherwise
        error('Invalid metric name!')
end
close all
numAtlas = length(atlasList);
for h = 1:2
    hemisphere = '';
    if h == 1
        hemisphere = 'Left Hemisphere';
    elseif h == 2
        hemisphere = 'Right Hemisphere';
    end
    figure();
    for a = 1:numAtlas
        atlas = atlasList{a};
        dpath = 'class/data/';
        fname = [dpath prefix '_' metric '_' atlas '_' suffix '.mat'];
        load(fname)
        numTasks = size(Data.taskNames,1);
        numParcels = length(Data.hemi(h).parcels);
        pmax = max([length(Data.hemi(1).parcels),length(Data.hemi(2).parcels)]);
        for t = 1:numTasks
            x = 1:numParcels;
            y = Data.hemi(h).labels(:,2) == t;
            spind = numAtlas * (t-1) + a; 
            subplot(numTasks,numAtlas,spind)
                imagesc(Data.hemi(h).data(y,x));
                colorbar;
                colormap('jet')
                % set condition-specific color scaling
                if contains(Data.taskNames(t,:),{'MTLocal' 'DynamicFaces'})
%                     colormap('autumn')
                    switch metric
                        case 'stdB'
                            % color limit is 0:8
                            caxis([0,8]);
                        case 'meanB'
                            % color limit is -2:11
                            caxis([-2,11]);
                    end
                else
%                     colormap('summer')
                    switch metric
                        case 'stdB'
                            % color limit is 0:3
                            caxis([0,3]);
                        case 'meanB'
                            % color limit is -2:4
                            caxis([-2,4]);
                    end
                end % if MTLocal or DynamicFaces

                if t == 1
                    title({atlas Data.taskNames(t,:)});
                else
                    title(Data.taskNames(t,:));
                end
                xlabel('parcel');
                ylabel('sub');
                xlim([0.5 pmax+0.5]);
        end % for t
    end % for a
    % suptitle must come at the end. sgtitle isn't in 2017a.
%     suptitle(hemisphere);
end % for h
end