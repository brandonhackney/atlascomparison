function exportColorTable(inputName, varargin)
% Reads in the specified freesurfer .annot file, and exports a .ctab file
% You would think they would have made their own function for this...

%% error check the input
assert(ischar(inputName), 'Error with input 1: must be given as char');
x = strsplit(inputName, '.');
assert(strcmp(x{end},'annot'), 'Input must be a freesurfer annotation filename');

% Variable inputs
if nargin > 1
    outName = varargin{1};
    % Error check
    assert(ischar(outName), 'Error with input 2: must be given as char');
    y = strsplit(outName,'.');
    assert(strcmp(y{end},'txt') || strcmp(y{end},'ctab'), 'Output file must be a txt or ctab');
    
else
    % Put humpty dumpty together again
    outName = [strjoin(x(1:end-1),'.'), '.ctab'];
end
clear x y
%% read in the data
% [index, idxlabel, ctablestruct]
[~, ~, c] = read_annotation(inputName);

%% Export table data to file
if ~exist(outName, 'file')
    system(['touch ' outName]);
end

fID = fopen(outName,'w');

% Write header
% fprintf(fID, 'Var1\tVar2\tVar3_1\tVar3_2\tVar3_3\tVar4\n');

% Write table data
for i = 1:c.numEntries
    % Index, name, RGB, alpha (transparency)
    fprintf(fID, '%i\t%s\t%i\t%i\t%i\t%i\n',i-1,c.struct_names{i}, c.table(i,1), c.table(i,2), c.table(i,3), c.table(i,4) );
end
% Close file
fclose(fID);

end