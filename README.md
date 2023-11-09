# Atlas Comparison
Analysis directory for atlas comparison project using 2020_STS_Multitask data, which exists in BrainVoyager format. 
Given fMRI data for multiple tasks, and an atlas template of brain subdivisions, this pipeline will parcellate the brain using the atlas, then summarize the functional data within each parcel, and finally run an SVM classifier that attempts to discriminate the different tasks based on the parcel summaries. 

# Requirements:
- This code makes heavy use of [Neuroelf](https://neuroelf.net/)
- Classification relies on the MATLAB version of [libsvm](https://www.csie.ntu.edu.tw/~cjlin/libsvm/)
- FDR thresholding relies on function mafdr() from the MATLAB Bioinformatics Toolbox
- Confusion charts rely on functions ``confusionchart`` and ``sortClasses`` added in MATLAB rev 2018b
- makePOIs uses [fsSurf2BV](https://github.com/tarrlab/Freesurfer-to-BrainVoyager), and ``null_makePOI`` is a modification of same
- The Python calls near the beginning of the pipeline rely on a modified version of [Parcellation Fragmenter](https://github.com/miykael/parcellation_fragmenter)

## Assumptions and necessary modifications
Some of these scripts start with a few assumptions, and will require tweaking before execution.
1. We assume that libsvm is installed in the MATLAB toolbox path, e.g. ``matlabroot/toolbox/libsvm-3.25/matlab/``. This expected path can be modified in the ``libsvmpath`` function.
2. We assume that this repo is nested inside a main project folder. For example, the code lives in root/analysis, and any data exists in root/data/deriv. Please modify ``specifyPaths`` to match your folder structure.
3. We assume that your data has already been preprocessed, and has been converted to BrainVoyager's surface-space file formats: functional data is in .mtc "mesh time course" format, freesurfer smoothwm surface has been converted to .srf format, and timing data is in .sdm "statistical design matrix" format.
4. We assume all functional data has been flattened out into a single folder per subject (i.e. there is no folder structure separating different tasks), so that we can use a single ``x = dir('*.mtc')`` call to get a list of all functional data at once.
5. We assume you have generated freesurfer .annot files for each subject from the atlas .gcs file, and have moved these to ``root/data/deriv/sub-xx/sub-xx_Freesurfer/``. This path can be modified in ``extractTS_ROI`` and ``null_master``.
6. ``null_makeGCS`` hardcodes some paths - please modify as necessary.
7. (Optional - null) ``randFragmenter.py`` hardcodes some paths - update as necessary.


# Usage
1. With your freesurfer output and .annot files in the proper location, run ``makePOIs('atlasNameHere');``, which will generate POI (patches of interest) files for that atlas. Repeat for every atlas you want to test.
2. Create a "template" .POI file by manually removing any parcels you want to ignore in your analysis, ideally using an independent subject's data. The result should be named "template_atlasName.POI", and should exist in the "p.template" location in ``specifyPaths``. This is not optional. If you want to do whole-brain analysis, create a template that retains all parcels.
3. With the .POI files generated and the .MTC files in subject-specific folders, modify ``AAA6p0`` to specify your atlases and subject numbers, then run it. This calculates summary statistics of the .MTC functional data based on the parcels specified in the .POI files, and outputs a data matrix ready for SVM classification. This will likely take two to three days to finish.
4. (Optional - nulls) Generate "null parcellations" for your template subject by running ``randFragmenter.py``. This outputs freesurfer .annot files. We generated 1,000 parcellations. 
5. (Optional - nulls) Run ``null_master``. This will convert your templateNull.annot files into .GCS, apply them to each subject, generate .POIs, and then extract and summarize functional data within each parcel, similar to how ``AAA6p0`` works for regular atlases.
6. With all your classification data generated, run either ``socvcont`` or ``critValCompare``. The former compares social and control tasks to each other, the latter compares atlases to null models.

## Reproducibility
If you want to use this pipeline with a different dataset, you'll need to make some additional modifications to some of the paths and internal variables.
1. Our subject data uses the non-standard prefix of e.g. STS-01 instead of sub-01. ``extractTS_ROI`` and ``makePOIs`` both implement this, if you want to modify it.
2. ``makePOIs`` and ``AAA6p0`` both hardcode a vector of subject numbers. You'll have to modify this as necessary.
3. ``getAtlasList`` generates a cell structure full of atlas names - this is useful if you are testing different groups of atlases. You'll want to modify it as necessary to specify any other set(s) of atlases.
4. ``getConditionFromFilename`` is HEAVILY used throughout this pipeline. This is where you specify all your task-related information, like the condition names and orders, and critically, what the contrasts are.
5. ``null_atlasClassify_Batch`` has a few switch statements that specify groups of atlases to compare, which of several metrics to use, and also whether to subset comparisons to 'social' or 'control' tasks as defined in ``getConditionFromFilename``.
