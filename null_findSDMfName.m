function sdmPath = null_findSDMfName(prtPath)

p = specifyPaths;

[pathStr, fName, ext] = fileparts(prtPath);
sdmfName = strcat(fName, '.sdm');

out = regexp(pathStr, 'STS\d+');
% subID = pathStr(out(3):out(3)+4);
subID = pathStr(out:end);

sdmPath = strcat(p.deriv, subID, '/', sdmfName);

% Account for errors
if ~exist(sdmPath, 'file')
    sdmPath = sdmfName;
end

