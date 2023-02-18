function varargout = libsvmpath(varargin)
% [ , (p)] = libsvmpath( , [p])
% Simple function that checks whether there is a libsvm folder on the
% matlab installation path
% Given an optional input and output, saves the path as a struct field
% Otherwise prints it to the command window

    % Go to your matlab install folder and into 'toolbox'
    expectedDir = [matlabroot filesep 'toolbox' filesep];
    % Look for any libsvm folder
    x = dir([expectedDir 'libsvm*']);
    if ~isempty(x)
        dname = [expectedDir x(1).name filesep 'matlab' filesep];
        % result should be something like this:
        % '/usr/local/MATLAB/R2020b/toolbox/libsvm-3.25/matlab'
    else
        et = ['No libsvm folder found!\n', ...
        'Verify it exists in %s\n',...
        'If not, download from https://github.com/cjlin1/libsvm','\n'];
        error(et, expectedDir)
    end
    % output
    if nargout < 1
        % if no output provided, just print path to command line
        print(dname)
    else
        % Export path as a struct field
        % Intended for use with specifyPaths()
        if nargin >= 1
            p = varargin{1};
        end
        p.libsvm = dname;
        varargout{1} = p;
    end
end