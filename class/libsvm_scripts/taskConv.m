function output = taskConv(input)
% output = taskConv(input)
% Takes as input a list of task names
% If the list is a space-padded char array, converts to cells
% Used to standardize output from atlasClassify script for graphing
% Which is only necessary because Daniel refused to use cells over chars

    if ischar(input)
        for i = 1:size(input,1)
            output{i} = strtrim(input(i,:));
        end
    elseif iscell(input)
        output = input;
    end % if
end