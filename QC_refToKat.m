function QC_refToKat(subList)
HomeDir = '/data2/2020_STS_Multitask/analysis/';
DataDir = '/data2/2020_STS_Multitask/data/deriv/';
BkupDir = '/data2/2020_STS_Multitask/backup/';
cd(DataDir)

for i = 1:length(subList)
    sub = subList(i); % i is useless; use actual number
    subID = ['STS',num2str(sub)];
    cd(subID)
    mtcList = dir('*.mtc');
    NumMTCs = length(mtcList);
    % find all vtcs
    for m = 1:NumMTCs
        mtc = xff(mtcList(m).name);
        % Get VTC name
        if ~isempty(mtc.SourceVTCFile)
            [vtcpath,vtc,EXT] = fileparts(mtc.SourceVTCFile);
        else
            vtc = [];
        end
        % Get PRT name
        if ~isempty(mtc.LinkedPRTFile)
            [prtpath,prt,EXT] = fileparts(mtc.LinkedPRTFile);
        else
            prt = [];
        end
        
        check1 = '/home/austin/Documents/STS-Preprocessing/';
        check2 = '/media/tarrlab/sts-data/Pipeline/';
        check3 = '/Volumes/szilard-data/STS-R21/';
        katString = '/data2/2020_STS_Multitask/data/deriv/';
        dummy = [0,0];
        
        % Fix PRT paths
        if contains(prtpath,check1)
            oldPRT = prtpath;
            prtpath = replace(prtpath,check1,katString);
            dummy(1) = 1;
        elseif contains(prtpath,check2)
            oldPRT = prtpath;
            prtpath = replace(prtpath,check2,katString);
            dummy(1) = 1;
        elseif contains(prtpath,check3)
            oldPRT = prtpath;
            prtpath = replace(prtpath,check3,katString);
            dummy(1) = 1;
        end
        % Fix VTC Paths
        if contains(vtcpath,check1)
            oldvtc = vtcpath;
            vtcpath = replace(vtcpath,check1,katString);
            dummy(2) = 1;
        elseif contains(vtcpath,check2)
            oldvtc = vtcpath;
            vtcpath = replace(vtcpath,check2,katString);
            dummy(2) = 1;
        elseif contains(vtcpath,check3)
            oldvtc = vtcpath;
            vtcpath = replace(vtcpath,check3,katString);
            dummy(2) = 1;
        end
        % Strip out Analysis dir
        bogus = [subID,'-Analysis/'];
        if contains(vtcpath,bogus)
            vtcpath = replace(vtcpath,bogus,'');
        end
        if contains(prtpath,bogus)
            prtpath = replace(prtpath,bogus,'');
        end
        % Start replacing things
        if dummy(1) == 0 && dummy(2) == 0
            fprintf('File %s ok!\n',mtcList(m).name)
        end
        if dummy(1) == 1
            fprintf('File %s\n:',mtcList(m).name)
            fprintf('\tReplacing %s with %s...',oldPRT,prtpath)
            mtc.LinkedPRTFile = [katString,prt,EXT];
            mtc.SaveAs(mtcList(m).name);
            fprintf('Done.\n')
        end
        if dummy(2) == 1
            fprintf('File %s\n:',mtcList(m).name)
            fprintf('\tReplacing %s with %s...',oldvtc,vtcpath)
            mtc.SourceVTCFile = [katString,vtc,EXT];
            mtc.SaveAs(mtcList(m).name);
            fprintf('Done.\n')
        end
        mtc.clearobj;
    end
end
cd(HomeDir)
end