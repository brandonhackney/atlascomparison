% Setup
subList = [1 2 3 4 5 6 7 8 10 11]; % array of subject numbers
atlasList = {'schaefer400','glasser6p0','gordon333dil','power6p0'}; % cell array of atlas names
funcV = []; % list of vertex indices in the ground-truth localizer
mriSize = []; % dimensions of whole-brain matrix
% note: mriSize is used for logical indexing to compare funcV and parcelV
% funcV and parcelV are just indices, so they need a shared matrix
% mriSize needs to be exact because it's used to calcualte a ratio
% It should be the same across tasks per subject, so get from a random MTC.

% This part should go in a script somewhere,
% Then leave the function as a standalone
homedir = pwd;
for a = 1:length(atlasList)
    atlas = atlasList{a};
    for s = 1:length(subList)
        fname = [homedir filesep 'class' filesep 'data' filesep 'Classify_meanB_' atlasList{a} '_effect.mat'];
        load(fname)
        for h = 1:2
            for p = 1:length(Data.hemi(h).parcels)
                coeff(p,h) = diceParcel(Data.hemi(h).parcels(p).vertices,funcV,mriSize);
            end % for parcels in h
        end % for hemis in atlas
    end % for s in subjects
end % for atlas