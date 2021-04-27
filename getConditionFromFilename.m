function [posInd,negInd, outID] = getConditionFromFilename(taskname)
errorFlag = 0;
switch taskname
    case 'AVLocal'
        % A_only, V_only, AV
        % I think we want AV?
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
        % Biasing for FFA or EBA? I'm picking FFA.
        posInd = [1,2];
        negInd = [5,6,7,8];
        outID = 3;
    case 'DynamicFaces'
        % static face, static scrambled, dynamic face, dynamic scrambled
        posInd = [3];
        negInd = [1,2,4];
        outID = 7;
    case 'MTLocal'
        % static, motion
        posInd = 2;
        negInd = 1;
        outID = 8;
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