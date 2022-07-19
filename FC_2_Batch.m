BasePath = '/data2/2020_STS_Multitask/analysis/';
% addpath(BasePath)

atlasList = {'schaefer100', 'schaefer200', 'schaefer400', 'schaefer600', 'schaefer800', 'schaefer1000'};

for a = 1:size(atlasList, 2)
    
    atlas = atlasList{a};
    FC_2_ComputeParcelFC(atlas, 'noprep', 'byCond')
    
end

cd(BasePath)