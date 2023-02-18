function [posInd,negInd, outID, varargout] = getConditionFromFilename(taskname)
% [posInd,negInd, outID, (numConds), (ttype), (social), (motion), (control)] = getConditionFromFilename(taskname)
% Reads in char task name
% Outputs arrays to index + and - conditions (for contrasting) from betas
% outID gets used in the FC scripts, to do ...
% OPTIONAL OUTPUTS:
% numConds tells you the total number of conditions in the task
% ttype tells you whether the task is considered 'social', 'motion','both, or 'control'
% social indexes specific conditions for whole-brain FC and ...?
% motion indexes specific conditions for whole-brain FC and ...?
%
% LOTS of feature creep here.
% With this many outputs, we'd probably be better off defining a class
% These are all just unchanging properties of each task - no calculations

errorFlag = 0;
switch taskname
    case 'AVLocal'
        % A_only, V_only, AV
        posInd = 3;
        negInd = [1,2];
        outID = 6;
        numConds = 3;
        ttype = 'social';
        social = 3;
        motion = [];
        control = [];
    case 'Bio-Motion'
        % biological, scrambled
        posInd = 1;
        negInd = 2;
        outID = 1;
        numConds = 2;
        ttype = 'both';
        social = 1;
        motion = 2;
        control = [];
    case 'BowtieRetino'
%         % Fixation, Horizontal, Vertical
%         posInd = 2;
%         negInd = 3;
        % Horizontal, Vertical, Fixation
        posInd = 1;
        negInd = 2;
        outID = 8;
        numConds = 2; %3; Emily changed to 2
        ttype = 'control';
        social = [];
        motion = [];
        control = 1;
    case 'ComboLocal'
        % adults, children, bodies, limbs, cars, instruments, houses, corridors, scrambled
        % Biasing for FFA, but do a second one of places vs objects
        posInd = [1,2];
        negInd = [5,6,7,8];
        outID = 4;
        numConds = 9;% Emily is confused about this one but changed it back to 8
        ttype = 'social';
        social = [1,2];
        motion = [];
        control = [];
    case 'DynamicFaces'
        % static face, static scrambled, dynamic face, dynamic scrambled
        % Can do dynamic vs static, face vs scramble, or dynamic face vs dynamic scramble
        posInd = [3];
%         negInd = [1,2,4];
        negInd = 4;
        outID = 3;
        numConds = 4;
        ttype = 'both';
        social = [3];
        motion = 4;
        control = [];
    case 'Motion-Faces'
       % static face, static scrambled, dynamic face, dynamic scrambled
        % Can do dynamic vs static, face vs scramble, or dynamic face vs dynamic scramble
        posInd = [3];
%         negInd = [1,2,4];
        negInd = 1;
        outID = 9;
        numConds = 4;
        ttype = 'control';
        social = []; % bc it's the same as DynamicFaces, so skip for classification
        motion = [];
        control = [];
    case 'MTLocal'
        % static, motion
        posInd = 2;
        negInd = 1;
        outID = 7;
        numConds = 2;
        ttype = 'control';
        social = [];
        motion = 2;
        control = [];
    case 'Objects'
        % adults, children, bodies, limbs, cars, instruments, houses, corridors, scrambled
        % This is ComboLocal with a secondary contrast
        posInd = [5,6];
        negInd = [7,8];
        outID = 10;
        numConds = 9;% 
        ttype = 'control';
        social = [];
        motion = [];
        control = posInd;
    case 'SocialLocal'
        % social, mechanical
        posInd = 1;
        negInd = 2;
        outID = 2;
        numConds = 2;
        ttype = 'both';
        social = 1;
        motion = 2;
        control = [];
    case 'Speech'
        % speech, scn
        posInd = 1;
        negInd = 2;
        outID = 11;
        numConds = 2;
        ttype = 'control';
        social = [];
        motion = [];
        control = posInd;
    case 'ToM'
        % belief, photo
        posInd = 1;
        negInd = 2;
        outID = 5;
        numConds = 2;
        ttype = 'social';
        social = 1;
        motion = [];
        control = [];
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
if nargout > 4
    varargout{2} = ttype;
end
if nargout > 5
    varargout{3} = social;
end
if nargout > 6
    varargout{4} = motion;
end
if nargout > 7
    varargout{5} = control;
end

end