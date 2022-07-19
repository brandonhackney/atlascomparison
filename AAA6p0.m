% This is a poorly-named script that will execute the entire pipeline
% Before running, please verify you have POI files for each sub/atlas combo

subjectList = [1 2 3 4 5 6 7 8 10 11];
atlasList = {'gordon333dil','glasser6p0','power6p0','schaefer400',...
    'schaefer100','schaefer200','schaefer600','schaefer800','schaefer1000'};
% Do subjects 1 and 7 after you run QC and make the MTCs
% Skip subject 9 entirely - not enough data.

% Calculate betas per parcel, generate various metrics
for a = 1:length(atlasList)
    main(subjectList,atlasList{a});
end
% Set up for classification analysis
classSetup(subjectList, atlasList); % generate class files for above metrics
batchGLM(subjectList,atlasList); % generate multi-GLM files needed for "Dice" overlap
diceBatch2(subjectList,atlasList);

% insert any FC stuff here
%
% generateOmnibus(atlasList); % aggregate all metrics into a single thing

% Run classification analysis
% WARNING: this hardcodes which atlases to use, for visualization
% Please verify this is set up properly before executing script
% atlasClassify_Batch;