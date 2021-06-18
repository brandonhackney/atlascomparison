function [posInd,negInd, outID] = getConditionFromFilename(taskname)
% [posInd,negInd, outID] = getConditionFromFilename(taskname)
% Reads in char task name
% Outputs arrays to index + and - conditions (for contrasting) from betas
% outID gets used in the FC scripts, to do ...

errorFlag = 0;
switch taskname
    case 'AVLocal'
        % A_only, V_only, AV
        posInd = 3;
        negInd = [1,2];
        outID = 4;
    case 'Bio-Motion'
        % biological, scrambled
        posInd = 1;
        negInd = 2;
        outID = 1;
    case 'ComboLocal'
        % adults, children, bodies, limbs, cars, instruments, houses, corridors, scrambled
        % Biasing for FFA, but do a second one of places vs objects
        posInd = [1,2];
        negInd = [5,6,7,8];
        outID = 3;
    case 'DynamicFaces'
        % static face, static scrambled, dynamic face, dynamic scrambled
        % Can do dynamic vs static, face vs scramble, or dynamic face vs dynamic scramble
        posInd = [3];
%         negInd = [1,2,4];
        negInd = 4;
        outID = 7;
    case 'MTLocal'
        % static, motion
        posInd = 2;
        negInd = 1;
        outID = 8;
    case 'Objects'
        % adults, children, bodies, limbs, cars, instruments, houses, corridors, scrambled
        % This is ComboLocal with a secondary contrast
        posInd = [5,6];
        negInd = [7,8];
        outID = 9;
    case 'SocialLocal'
        % social, mechanical
        posInd = 1;
        negInd = 2;
        outID = 2;
    case 'Speech'
        % speech, scn
        posInd = 1;
        negInd = 2;
        outID = 5;
    case 'ToM'
        % belief, photo
        % check with john
        posInd = 1;
        negInd = 2;
        outID = 6;
    otherwise
        errorFlag = 1;
end
if errorFlag == 1
    fprintf('\n\nUNHANDLED EXCEPTION IN: %s\nUNKNOWN PRT LABELS\n\n',filename)
    posInd = 1; % send a default value just in case?
    outID = 11;
end
end