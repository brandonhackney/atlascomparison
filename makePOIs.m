function makePOIs(atlasName)
% atlasName must be char of format 'x.annot', e.g. 'schaefer400.annot'
    
    % skip sub 1 because it won't generate .annot files atm
    % There is now a sub 7 in this folder.
    % Skip sub 9 because it terminated early.
    A = [2 3 4 5 6 7 8 10 11];
    for i = A
        mySub = sprintf('STS%i',i);
        Cfg.SUBJECTS_DIR = sprintf('/data2/2020_STS_Multitask/data/%s/%s-Freesurfer/',mySub,mySub);
        Cfg.projectDir = Cfg.SUBJECTS_DIR; % sets up output folder /mySub-fsSurf2BV/
        Cfg.atlas = atlasName;
        fsSurf2BV(mySub,Cfg);

    end
end