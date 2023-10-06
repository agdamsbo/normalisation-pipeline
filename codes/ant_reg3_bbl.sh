#!/bin/bash

: <<COMMENTBLOCK
This should be the more modern approach.
Assume we are in the directory with a subdirectory containing the results of fsl_anat_alt.sh
with standard names.

Call antsRegistrationSyn.sh to do normalization following
https://github.com/stnava/BasicBrainMapping/blob/master/bbm.sh

Use antsApplyTransforms to apply the affine and warp files and create the output files.

Sourced from https://neuroimaging-core-docs.readthedocs.io/en/latest/pages/ants_anat_normalization-lesion.html#steps
Slightly modified to include custom resolution
COMMENTBLOCK

# Define variables using the results of the fsl processing
# (assumes a subdirectory *.anat with the needed files)
sub=`${FSLDIR}/bin/remove_ext ${1}`
t1=${sub}.anat/T1_biascorr.nii.gz
t1_brain_mask=${sub}.anat/T1_biascorr_brain_mask.nii.gz
lesionmask=${sub}.anat/lesionmask.nii.gz
template=${FSLDIR}/data/standard/MNI152_T1_${2}_brain.nii.gz

# create the subdirectory for the ants output
if [ ! -d ant3 ]; then
mkdir ant3
fi

# Use ImageMath to create the extracted brain
# We do not want to use the fsl extracted brain because it is missing the actual lesion area
if [ ! -e ant3/t1brain.nii.gz ]; then
ImageMath 3 ant3/t1brain.nii.gz m ${t1} ${t1_brain_mask}
fi

# Define our new brain variable
t1brain=ant3/t1brain.nii.gz

# The output file comes first in the command,
# So this command creates the inverse (negative) of the lesionmask
if [ ! -e ant3/lesionmask_inv.nii.gz ]; then
ImageMath 3 ant3/lesionmask_inv.nii.gz Neg ${lesionmask}
fi

# Define our new inverse lesion mask
lesionmask_inv=ant3/lesionmask_inv.nii.gz

if [ ! -e ant3/${sub}_T1w_MNIWarped.nii.gz ]; then
# The resulting file *MNIWarped* is the subject file in standard space
antsRegistrationSyN.sh -d 3 -f ${template} -m ${t1brain} -o ant3/${sub}_T1w_MNI -j 1 -x ${lesionmask_inv}
fi

# Apply registrations
# Note the -t in front of each of them.  The order of application is LIFO, so affine, and then warp.

# Apply the affine transform and inverse warp to the lesion file.
# Use nearest neighbour interpolation because this is a mask
if [ ! -e ant3/${sub}_MNI_lesion.nii.gz ]; then
antsApplyTransforms -d 3 -i ${lesionmask} -r ${template} -o ant3/${sub}_MNI_lesion.nii.gz -n NearestNeighbor -t ant3/${sub}_T1w_MNI1InverseWarp.nii.gz -t ant3/${sub}_T1w_MNI0GenericAffine.mat -v
fi

# Apply the affine transform and inverse warp to the original brain file
if [ ! -e ant3/${sub}_MNI_brain.nii.gz ]; then
antsApplyTransforms -d 3 -i ${t1brain} -r ${template} -o ant3/${sub}_MNI_brain.nii.gz -t ant3/${sub}_T1w_MNI1InverseWarp.nii.gz -t ant3/${sub}_T1w_MNI0GenericAffine.mat   -v
fi

# Apply the affine transform and inverse warp to the original whole head file
if [ ! -e ant3/${sub}_MNI.nii.gz ]; then
antsApplyTransforms -d 3 -i ${t1} -r ${template} -o ant3/${sub}_MNI.nii.gz -t ant3/${sub}_T1w_MNI1InverseWarp.nii.gz -t ant3/${sub}_T1w_MNI0GenericAffine.mat  -v
fi

# Apply the affine transform and inverse warp to the brain mask file.
# Use nearest neighbour interpolation because this is a mask
if [ ! -e ant3/${sub}_MNI_brain_mask.nii.gz ]; then
antsApplyTransforms -d 3 -i ${t1_brain_mask} -r ${template} -o ant3/${sub}_MNI_brain_mask.nii.gz -n NearestNeighbor -t ant3/${sub}_T1w_MNI1InverseWarp.nii.gz -t ant3/${sub}_T1w_MNI0GenericAffine.mat  -v
fi
