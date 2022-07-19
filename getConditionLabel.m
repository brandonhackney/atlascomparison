function label = getConditionLabel(taskName,valence)
% label = getConditionLabel(taskName,valence)
%
% Simply return a string giving a name to a specific condition
% Where multiple conditions exist for a given valence, summarize
% e.g. if 'adult faces' and 'child faces' are both positive, say 'faces'
%
% input taskName is a string, e.g. 'BowtieRetino'
% input valence is integer 1 or 2; 1 means positive, 2 means negative
% output label is a string, e.g. 'Horizontal Meridian'
%
% DO NOT feature creep this function. It's intended to be dead simple.

errorFlag = 0;
switch taskName
    case 'AVLocal'
        % A_only, V_only, AV
        condNames = {'AV-Speech','A-orV-Speech'};
    case 'Bio-Motion'
        % biological, scrambled
        condNames = {'BioMotion','ScramBioMot'};
    case 'BowtieRetino'
        % Horizontal, Vertical, Fixation
        condNames = {'HorizontalV1','VerticalV1'};
    case 'ComboLocal'
        % adults, children, bodies, limbs, cars, instruments, houses, corridors, scrambled
        % Biasing for FFA
        condNames = {'Faces','ThingsPlaces'};
    case 'DynamicFaces'
        % static face, static scrambled, dynamic face, dynamic scrambled
        condNames = {'DynamicFaces','ScramFaceMot'};
    case 'Motion-Faces'
       % static face, static scrambled, dynamic face, dynamic scrambled
        condNames = {'DynamicFaces','StaticFaces'};
    case 'MTLocal'
        % static, motion
        condNames = {'Optic Flow','Static Dots'};
    case 'Objects'
        % adults, children, bodies, limbs, cars, instruments, houses, corridors, scrambled
        % This is ComboLocal with a secondary contrast
        condNames = {'Objects','Places'};
    case 'SocialLocal'
        % social, mechanical
        condNames = {'SocialMotion','MechanMotion'};
    case 'Speech'
        % speech, scn
        condNames = {'Syllables','ScramSyllabl'};
    case 'ToM'
        % belief, photo
        condNames = {'ToM story','Photo story'};
    otherwise
        errorFlag = 1;
end
if errorFlag == 1
    error('\n\nUNKNOWN TASK LABEL %s\n\n',filename)
end
label = condNames{valence};
end