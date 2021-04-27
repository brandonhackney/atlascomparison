   vtcList = dir('*.vtc');
    vtc = xff(vtcList(2).name);
    FMR = vtc.NameOfSourceFMR;
%% 3. Fix what you can
        % Specific FMR path problems
            % Define check strings
            check1 = '/home/austin/Documents/STS-Preprocessing/';
            check2 = '/media/tarrlab/sts-data/Pipeline/';
            check3 = '/Volumes/KoogleData/STS-R21/';
            katString = '/data2/2020_STS_Multitask/data/';

            % Replace the wrong path prefixes with the proper path on kat
            if contains(FMR,check1)
                    newFMR = replace(FMR,check1,katString);
            elseif contains(FMR,check2)
                    newFMR = replace(FMR,check2,katString);
            elseif contains(FMR,check3)
                    newFMR = replace(FMR,check3,katString);
            end

% Export updated path back into the VTC header
	vtc.NameOfSourceFMR = newFMR;
    filename2 = 'test.vtc';
	vtc.SaveAs(filename2); % This part writes your MATLAB var back to the file