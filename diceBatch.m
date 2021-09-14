% Setup
subList = [1 2 3 4 5 6 7 8 10 11]; % array of subject numbers
atlasList = {'schaefer400','glasser6p0','gordon333dil','power6p0'}; % cell array of atlas names
homedir = pwd;
fprintf(1,'\n\nStarting Dice Coefficient calculations...')

for a = 1:length(atlasList)
    atlas = atlasList{a};
    fprintf(1,'Atlas %s:\n',atlasList{a})
    for s = 1:length(subList)
        fprintf(1,'Subject %i:\n',subList(s))
        fname = [homedir filesep 'class' filesep 'data' filesep 'Classify_meanB_' atlasList{a} '_effect.mat'];
        load(fname)
        load([homedir filesep 'ROIs' filesep 'GLM' filesep 'STS' num2str(subList(s)) '_GLMs.mat']);
        if s == 1
            Summary = Data;
        end
        
        for t = 1:length(GLM.task)
            fprintf(1,'\tTask %s...',GLM.task(t).name)
            for h = 1:2
                for p = 1:length(Data.hemi(h).parcels)
                    Summary.hemi(h).parcels(p).taskData(t).taskName = GLM.task(t).name;
                    Summary.hemi(h).parcels(p).taskData(t).DiceCoeff(s) = diceParcel(Data.hemi(h).parcels(p).vertices,GLM.task(t).hem(h).cluster,GLM.task(t).hem(h).numVert);
                    Summary.hemi(h).parcels(p).taskData(t).glmAlignment(s) = length(intersect(Data.hemi(h).parcels(p).vertices,GLM.task(t).hem(h).cluster)) / length(GLM.task(t).hem(h).cluster);
                    Summary.hemi(h).parcels(p).taskData(t).parcelAlignment(s) = length(intersect(Data.hemi(h).parcels(p).vertices,GLM.task(t).hem(h).cluster)) / length(Data.hemi(h).parcels(p).vertices);
                    % parcelAlignment is a new metric that measures the
                    % percentage of the parcel that overlaps the GLM zone
                    % glmAlignment is percent of GLM inside a parcel
                end % for p parcels in hemi
            end % for h hemis per subject
            fprintf(1,'Done.\n')
        end % for t tasks
        fprintf(1,'Subject %i done.\n',subList(s))
    end % for s subject
    % Export results to /class/data/
    Summary.hemi = rmfield(Summary.hemi,{'data','labels'});
    Summary.hemi(1).name = 'lh'; Summary.hemi(2).name = 'rh';
    fname = [homedir filesep 'class' filesep 'data' filesep 'Summary_Dice_' atlasList{a} '.mat'];
    save(fname,'Summary');
    fprintf(1,'Atlas %s exported to %s\n\n',atlasList{a},fname)
end % for a atlas

fprintf(1,'\n\nDice Coefficients done calculating.\n\n')