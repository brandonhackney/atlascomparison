clear; clc;

BaseDir = pwd;
AtlasTemplatePath = '/data2/2020_STS_Multitask/data/sub-04/fs/sub-04-Surf2BV/';

cd(AtlasTemplatePath)
for hemi = 1:2
    if hemi == 1
        fBase = 'template_lh*'
    else
        fBase = 'template_rh*'
    end
   
    fList = dir(fBase);
    
    for a = 1:length(fList)
        templatefName = fList(a).name;
        
        template = xff(templatefName);
        
        NumPOIs = template.NrOfPOIs;
        clear poiList;
        for p = 1:NumPOIs
            poiList(p).name = template.POI(p).Name;
            poiList(p).num = template.POI(p).NrOfVertices;
        end
        meanSize = mean(cell2mat({poiList.num}'));
        
        
        if hemi == 1
            atlas(a).fName_lh = templatefName;
            atlas(a).numParcels_lh = NumPOIs;
            atlas(a).pois_lh = poiList;
            atlas(a).meanNumVerts_lh = meanSize;
            
        else
            atlas(a).fName_rh = templatefName;
            atlas(a).numParcels_rh = NumPOIs;
            atlas(a).pois_rh = poiList;
            atlas(a).meanNumVerts_rh = meanSize;
        end

    end

end
struct2table(atlas)

cd(BaseDir)
