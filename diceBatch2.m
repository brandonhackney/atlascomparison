function diceBatch2(subList, atlasList)
% This differs from the original diceBatch by outputting classifiable data
% That is, the output matches the format of the other Classify_X files
% Only a single metric is given - percentage of parcel that has GLM in it
% So this is !! NOT actually the Dice's coefficient !!
% But hold on to the original diceBatch bc it has the other calculations
% And we may want to use those calculations later on

% Setup
pth = specifyPaths;
homedir = pth.basePath;
fprintf(1,'\n\nStarting Dice Coefficient calculations...')

for a = 1:length(atlasList)
    atlas = atlasList{a};
    fprintf(1,'Atlas %s:\n',atlas)
    for s = 1:length(subList)
        fprintf(1,'Subject %i:\n',subList(s))
        fname = fullfile(pth.classifyDataPath, ['Classify_meanB_' atlas '.mat']);
        Data = importdata(fname); % template class file
        GLM = importdata([homedir filesep 'ROIs' filesep 'GLM' filesep 'STS' num2str(subList(s)) '_GLMs_' atlas '.mat']);
        if s == 1
            Summary = Data;
        end
        maxX = length(subList) * length(GLM.task);
        for t = 1:length(GLM.task)
            fprintf(1,'\tTask %s...',GLM.task(t).name)
            x = length(subList) * (t-1) + s; % an index
            % accounts for having per subject per task order
            
            for h = 1:2
                
                numP = length(Data.hemi(h).parcelInfo(s).parcels);
                if s == 1 && t == 1
                    % Ensure no old data is left over from load
                    Summary.hemi(h).data = zeros([maxX,numP]);
                end
                for p = 1:numP
                % Return the percentage of the parcel that overlaps the GLM zone
                    Summary.hemi(h).data(x,p) = length(intersect(Data.hemi(h).parcelInfo(s).parcels(p).vertices,GLM.task(t).hem(h).cluster)) / length(Data.hemi(h).parcelInfo(s).parcels(p).vertices);
                    
                end % for p parcels in hemi
            end % for h hemis per subject
            fprintf(1,'Done.\n')
        end % for t tasks
        fprintf(1,'Subject %i done.\n',subList(s))
    end % for s subject
    % Export results to /class/data/
    Data = Summary; clear Summary
    fname = fullfile(pth.classifyDataPath,['Classify_overlap_' atlas '.mat']);
    save(fname,'Data');
    fprintf(1,'Atlas %s exported to %s\n\n',atlas,fname)
end % for a atlas

fprintf(1,'\n\nDice Coefficients done calculating.\n\n')
end