function main(subjectList,atlasName)
% main(subjectList,atlasName)
% A wrapper for the extractTS function to allow batch extraction
% subjectList: a horizontal vector of subject numbers (e.g. [1, 3, 4...])
% atlasName: a character vector of the atlas name (e.g. 'schaefer400')

    for i = 1:length(subjectList)
        [~] = extractTS_ROI(subjectList(i),atlasName);
    end % subject
    generateBoxplots(subjectList,atlasName);
fprintf(1,'\nJob''s finished!\n');
end