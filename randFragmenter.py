# -*- coding: utf-8 -*-
# def parcelFragmenter(subNum,baseDir,hem):

import nibabel as nb # for loading surfaces
from nilearn import plotting # for recoloring; needs matplotlib
from fragmenter import Fragment # main fragmentation class
from fragmenter import Sampler # generates null distributions
from fragmenter import colormaps # for generating new colormaps
import numpy as np # for working with parcel names

# surfPath = baseDir + subNum + '/' + subNum + '-Freesurfer/' + subNum + '/surf/'
# outPath = baseDir + 'deriv/' + subNum + '/' + subNum + '-Freesurfer/' + subNum + '-Surf2BV/'
# labelPath = baseDir + subNum + '/' + subNum + '-Freesurfer/' + subNum + '/label/'

# Define a global random state object that later gets referenced by .fit
# clusterings.kmeans has a random_state parameter of None, which makes it reference this global object
# That ensures you actually randomize and don't just use the first number each time
np.random.RandomState(seed=62989)

baseDir = '/data2/2020_STS_Multitask/data/'
subNum = 'sub-04'
surfPath = baseDir + subNum + '/fs/' + subNum + '/surf/'
outPath = baseDir + subNum + '/fs/' + subNum + '-Surf2BV/'
labelPath = baseDir + subNum + '/fs/' + subNum + '/label/'

for hem in ['lh', 'rh']:
    # Define surface file and annotation file.
    # If you are using Gifti-structured data, use ```nb.load()``` instead,
    # the vertices and faces will exists as GiftiDataArrays objects
    # Specifically needs a freesurfer file, not a BV .srf
    verts, faces = nb.freesurfer.io.read_geometry(
      surfPath + hem + '.sphere')
    
    # Instantiate a brain fragmentation class-object
    F = Fragment.Fragment(n_clusters=173)
    #F = Fragment.Fragment(n_clusters=30)
    
    numIter = 1000
    for iter in range(numIter):
        # Duplicate object and execute a unique fragmentation process
        # Use gaussian mixed models instead of default k-means
        outF = F
        outF.fit(vertices=verts, faces=faces, method='k_means')

        # pad iteration number to 4 digits, and start at 1 not 0
        # itstr = str(iter + 1).rjust(4,'0')
        itstr = str(iter).rjust(4,'0')
        # We can then save the map with:
        annot_name = labelPath + hem + '.null_' + itstr +'.annot'
        outF.write(annot_name)
