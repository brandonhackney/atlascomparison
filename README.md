# atlascomparison
Analysis directory for atlas comparison project using 2020_STS_Multitask data

Requirements:
- This code makes heavy use of [Neuroelf](https://neuroelf.net/)
- FDR thresholding relies on function mafdr() from the MATLAB Bioinformatics Toolbox
- Confusion charts rely on functions confusionchart() and sortClasses() added in MATLAB rev 2018b
- makePOIs uses fsSurf2BV(), and null_makePOI is a modification of same
- The Python calls near the beginning of the pipeline rely on a modified version of [Parcellation Fragmenter](https://github.com/miykael/parcellation_fragmenter)
