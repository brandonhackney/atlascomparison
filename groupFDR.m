function groupFDR
    p = specifyPaths();
    fpath = [p.baseDataPath 'deriv' filesep 'group' filesep];
    fname = {'LH.smp' 'RH.smp'};
    for h = 1:2
        filename = [fpath fname{h}];
        % load the data
        SMP = xff(filename);
        MAP = SMP.Map;
        % for each task in the file
        for i = 1:length(MAP)
            dat = SMP.Map(i).SMPData;
            df = SMP.Map(i).DF1;
            % calculate new threshold, overwrite old one
            [~, MAP(i).LowerThreshold] = fdrCluster(dat,df);
        end
        % export
        SMP.Map = MAP;
        SMP.SaveAs(filename);
        SMP.clearobj;
    end
end