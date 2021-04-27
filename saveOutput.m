function filename = saveOutput(Pattern, atlas)
% Expects output to already have the atlas name in output(1).atlasName
% Outputs to ROIs folder with name e.g. STS3_schaefer400.mat

% Try to suppress Neuroelf warning - not sure if this is the right one.
warning('off','xff:BadTFFCont');

    filename = sprintf('%s_%s.mat',Pattern.subID,atlas);
    save(['ROIs/' filename],'Pattern');
end