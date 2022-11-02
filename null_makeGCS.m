function null_makeGCS()
% generate GCS file from many .annot files
% use system() to call freesurfer mris_ca_train()
% if output == 0, the system command was executed successfully

% make sure the system looks in the right place for freesurfer
!export FREESURFER_HOME='/usr/local/freesurfer'

sub = 'sub-04';
outsub = 'template';
fspath = '/data2/2020_STS_Multitask/data/sub-04/fs/sub-04/label';
outpath = '/data2/2020_STS_Multitask/data/sub-04/fs';

hstr = {'lh','rh'};

home = pwd;
cd(outpath);
for h = 1:2
    hem = hstr{h};
    for x = 1:1000
        % ARGUMENTS
        % define annot file name
        nstr = num2str(x,'%04.f'); % pad with 0s to 4 digits long
        fname = ['null_' nstr];
            % targets e.g. lh.null_0001.annot
            % but should probably just do lh.null.annot in 1000 subfolders
        canonsrf = 'sphere.reg';
        outfile = [outpath filesep hem '.' fname '.gcs'];
            % e.g. lh.null_0001.gcs
            % would prefer a single gcs file but...
        % required arguments: hemi canonsurf annotfile subject1 outputfile
        args = [hem ' ' canonsrf ' ' fname ' ' sub ' ' outfile];
        
        % OPTIONS
        opts = ['-sdir ' outpath ' -t /data1/fssubdir/null174_mycolortable.txt'];
        
        % build the command
        cmdStr = ['mris_ca_train ' opts ' ' args];
        % EXECUTE command, return success flag
        sflag = system(cmdStr);
        % if sflag is 0, it was successful. so:
        if sflag
            cd(home)
            error('Command not successful! Review:\n%s\n',cmdStr)
        end
    end % for 1000 annots
end % for hem
cd(home)
end