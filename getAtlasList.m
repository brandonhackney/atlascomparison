function [atlasList, varargout] = getAtlasList(atlasGroup)
% [atlasList, (numIter, numAtlas, numItems)] = getAtlasList(atlasGroup)
% Input a short code like "null"
% Get back a cell array list of atlas names
% Optional outputs return parameters like number of iterations per atlas

validList = {'atlas','null','sch','res','atlasBIG','nullSMALL'};
assert(ischar(atlasGroup), 'Input must be a string.');
assert(ismember(atlasGroup, validList), sprintf('Input options are %s', sprintf('%s, ',validList{:})));

atlasList = [];
switch atlasGroup
    case 'atlas'
        % The original 4 atlases we used
        atlasList = {'schaefer400', 'glasser6p0', 'gordon333dil', 'power6p0'};
        numAtlas = 4;
        numIter = 1;
        numItems = numAtlas * numIter;
    case 'atlasBIG'
        % The original 4 atlases we used, but add more parcels to each 
        atlasList = {'schaeferBIG', 'glasserBIG', 'gordonBIG', 'powerBIG'};
        numAtlas = 4;
        numIter = 1;
        numItems = numAtlas * numIter;
    case 'null'
        % 1000 random iterations of 173 parcels per hemisphere
        % Output is e.g. 'null_0001'
        numIter = 1000;
        numAtlas = 1; % 1000 iterations of 1 resolution
        numItems = numIter * numAtlas;
        % Specify the names of the null atlases
        atlasList = cell(1,numItems);
        for a = 1:numItems
            atlasList{a} = ['null_',num2str(a,'%04.f')];
        end
    case 'nullSMALL'
        % 1000 random iterations of 173 parcels per hemisphere
        % This eventually gets subset to end up with fewer parcels
        % Output is e.g. 'nullSMALL_0001'
        numIter = 1000;
        numAtlas = 1; % 1000 iterations of 1 resolution
        numItems = numIter * numAtlas;
        % Specify the names of the null atlases
        atlasList = cell(1,numItems);
        for a = 1:numItems
            atlasList{a} = ['nullSMALL_',num2str(a,'%04.f')];
        end
    case 'res'
        % A single iteration of null parcelations at various resolutions
        % Output is e.g. 'res150'
        resList = [150 125 100 75 50 25 10 5 2];
        numAtlas = length(resList);
        numIter = 1;
        numItems = numAtlas * numIter;
        for a = numItems:-1:1
            rnum = resList(a);
            atlasList{a} = ['res',num2str(rnum,'%03.f')];
        end

    case 'mres'
        % Multiple iterations of null parcellations at many resolutions
        % Output is e.g. 'res150_0001'
        atlasList = [];
        resList = [150 125 100 75 50 25 10 5 2];
        numAtlas = length(resList);
        numIter = 50; % how many of each resolution?
        numItems = numAtlas * numIter; % total number of things
        for r = length(resList):-1:1
            rnum = resList(r);
            rname = ['res',num2str(rnum,'%03.f')];
            for n = numIter:-1:1
                a = (r-1) * numIter + n; % calc nested position
                atlasList{a} = [rname '_' num2str(n-1,'%04.f')];
            end
        end

end % switch

% Define optional outputs
if nargout > 1
    % The number of iterations per 'atlas'
    % e.g. if you have 3 resolutions with 10 iterations each, this is 10
    varargout{2} = numIter;
end
if nargout > 2
    % The number of iteration groups
    % e.g. if you have 3 resolutions with 10 iterations each, this is 3
    varargout{3} = numAtlas;
end
if nargout > 3
    % The total number of items in atlasList
    % Kind of useless since you can just do length(atlasList)
    varargout{1} = numItems;
end

end