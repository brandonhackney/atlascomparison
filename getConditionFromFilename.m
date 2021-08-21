function [posInd,negInd, outID, varargout] = getConditionFromFilename(taskname)
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
        numConds = 3;
    case 'Bio-Motion'
        % biological, scrambled
        posInd = 1;
        negInd = 2;
        outID = 1;
        numConds = 2;
    case 'BowtieRetino'
%         % Fixation, Horizontal, Vertical
%         posInd = 2;
%         negInd = 3;
        % Horizontal, Vertical, Fixation
        posInd = 1;
        negInd = 2;
        outID = 10;
        numConds = 3;
    case 'ComboLocal'
        % adults, children, bodies, limbs, cars, instruments, houses, corridors, scrambled
        % Biasing for FFA, but do a second one of places vs objects
        posInd = [1,2];
        negInd = [5,6,7,8];
        outID = 3;
        numConds = 9;
    case 'DynamicFaces'
        % static face, static scrambled, dynamic face, dynamic scrambled
        % Can do dynamic vs static, face vs scramble, or dynamic face vs dynamic scramble
        posInd = [3];
%         negInd = [1,2,4];
        negInd = 4;
        outID = 7;
        numConds = 4;
    case 'MTLocal'
        % static, motion
        posInd = 2;
        negInd = 1;
        outID = 8;
        numConds = 2;
    case 'Objects'
        % adults, children, bodies, limbs, cars, instruments, houses, corridors, scrambled
        % This is ComboLocal with a secondary contrast
        posInd = [5,6];
        negInd = [7,8];
        outID = 9;
        numConds = 9;
    case 'SocialLocal'
        % social, mechanical
        posInd = 1;
        negInd = 2;
        outID = 2;
        numConds = 2;
    case 'Speech'
        % speech, scn
        posInd = 1;
        negInd = 2;
        outID = 5;
        numConds = 2;
    case 'ToM'
        % belief, photo
        % check with john
        posInd = 1;
        negInd = 2;
        outID = 6;
        numConds = 2;
    otherwise
        errorFlag = 1;
end
if errorFlag == 1
    fprintf('\n\nUNHANDLED EXCEPTION IN: %s\nUNKNOWN PRT LABELS\n\n',filename)
    posInd = 1; % send a default value just in case?
    outID = 99;
end


if nargout > 3
    varargout{1} = numConds;
end

end