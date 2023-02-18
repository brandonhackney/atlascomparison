function makePOIs(atlasName, varargin)
% atlasName must be char vector e.g. 'schaefer400'
% gets internally coverted to .annot name, e.g. schaefer400.annot
% (optional) subList is a vector of subject numbers, ie not strings
    
    % Define subject list
    if ~isempty(varargin)
        subList = varargin{1};
    else
        % Skip sub 9 because it terminated early.
        subList = [1 2 3 4 5 6 7 8 10 11];
    end
    
    % Generate POI for each subject
    for i = subList
        mySub = sprintf('STS%i',i);
        Cfg.SUBJECTS_DIR = sprintf('/data2/2020_STS_Multitask/data/deriv/%s/%s-Freesurfer/',mySub,mySub);
        Cfg.projectDir = Cfg.SUBJECTS_DIR; % sets up output folder /mySub-fsSurf2BV/
        Cfg.atlas = [atlasName '.annot'];
        fsSurf2BV(mySub,Cfg);

    end
end