#!/bin/bash

: <<COMMENTBLOCK
Concentrated and modified fsl_anat_alt_bbl.sh to allow for simple registration after manually corrected brain mask.
This is to be able to manually correct the output from optiBET, which is good, but not perfect.
First argument is the standard T1w image, second arguent is the modified brain mask.
COMMENTBLOCK

FSLDIR=/usr/local/fsl
stem=`remove_ext ${1}`
mask_stem=`remove_ext ${2}`
refmask=MNI152_T1_2mm_brain_mask_dil1

## Converting to binary mask is done to allow for esier editing of mask in seperate label in ITK-SNAP using interpolate functionality.
date; echo "--- Brain mask to binary ---"

fslmaths ${mask_stem} -thr 0.5 -bin ${mask_stem}_BIN -odt char
# fslmaths ${mask_stem}_BIN -binv ${mask_stem}_BIN_inv

date; echo "--- File handling ---"
## Rename the old brain mask and move in the modified version
immv ${stem}.anat/T1_biascorr_brain_mask.nii.gz ${stem}.anat/OLD_T1_biascorr_brain_mask.nii.gz
imcp ${mask_stem}_BIN ${stem}.anat/T1_biascorr_brain_mask.nii.gz

## Copy the modified T1w image back as the T1_biascorr
imcp ${stem}.nii.gz ${stem}.anat/T1_biascorr.nii.gz

cd ${stem}.anat

date; echo "Extracting manually masked brain"

## Here we are making up for the not-always-perfect optiBET, and will feed the output 
## to what is basically a copy-paste of the registration part of the fsl_anat_alt_bbl.sh script.

## Filling holes in brain mask
$FSLDIR/bin/fslmaths T1_biascorr_brain_mask -fillh T1_biascorr_brain_mask
## Extracting brain based on brain mask
$FSLDIR/bin/fslmaths T1_biascorr -mas T1_biascorr_brain_mask T1_biascorr_manual_brain

## Registration

date; echo "Linear registration (FLIRT)"
# Below is the linear-non-linear-applywarp steps to warp the manually masked brain to MNI and getting the warp information "T1_to_MNI_nonlin_coeff"
# for warping lesion mask and original scan. This is per standard documentation and naming according to the other bundled scripts in the pipeline.

$FSLDIR/bin/flirt -interp nearestneighbour -in T1_biascorr_manual_brain -ref ${FSLDIR}/data/standard/MNI152_T1_2mm_brain -omat T1_to_MNI_lin.mat -inweight lesionmaskinv

date; echo "Non-linear registration (FNIRT)"

$FSLDIR/bin/fnirt --in=T1_biascorr --interp=spline --ref=$FSLDIR/data/standard/MNI152_T1_2mm --aff=T1_to_MNI_lin.mat --cout=T1_to_MNI_nonlin_coeff --inmask=lesionmaskinv -v
# -v flag is used to have fnirt process output to follow the process.

date; echo "Warping to MNI space (FNIRT)"

$FSLDIR/bin/applywarp --ref=${FSLDIR}/data/standard/MNI152_T1_2mm --in=T1_biascorr_manual_brain --warp=T1_to_MNI_nonlin_coeff --out=T1_biascorr_manual_brain_to_MNI
# Apply the warp to the manually corrected brain
cd -


## Now everythin is normalised for the sake of QC

# --- warp the lesion mask into MNI space, use nearest neighbour interpolation
# This step is the least for NeMo, but the next steps can be included for quality control.
echo "--- Normalizing lesion ---"
applywarp -i ${stem}.anat/lesionmask.nii.gz --warp=${stem}.anat/T1_to_MNI_nonlin_coeff --interp=nn -r  $FSLDIR/data/standard/MNI152_T1_2mm -o ${stem}_MNI-2mm_lesion


## This is for NeMo, 2mm used for QC
echo "--- Normalizing lesion to 1mm ---"
applywarp -i ${stem}.anat/lesionmask.nii.gz --warp=${stem}.anat/T1_to_MNI_nonlin_coeff --interp=nn -r  $FSLDIR/data/standard/MNI152_T1_1mm -o ${stem}_MNI-1mm_lesion


# --- warp the brain mask into MNI space, use nearest neighbour interpolation
# --- Here we are using the provided

echo "--- Normalizing brain mask ---"
applywarp -i ${2}  --warp=${stem}.anat/T1_to_MNI_nonlin_coeff --interp=nn -r $FSLDIR/data/standard/MNI152_T1_2mm -o ${stem}_MNI-2mm_brain_mask

# echo "--- Normalizing brain mask to 1mm ---"
# applywarp -i ${2}  --warp=${stem}.anat/T1_to_MNI_nonlin_coeff --interp=nn -r $FSLDIR/data/standard/MNI152_T1_1mm -o ${stem}_MNI-1mm_brain_mask

# --- warp the skull stripped brain into MNI space

echo "--- Normalizing brain ---"
# applywarp -i ${stem}.anat/T1_biascorr_manual_brain --warp=${stem}.anat/T1_to_MNI_nonlin_coeff -r $FSLDIR/data/standard/MNI152_T1_2mm -o ${stem}_MNI-2mm_brain
# Above is the warp command, but this was already performed earlier.
imcp ${stem}.anat/T1_biascorr_manual_brain_to_MNI ${stem}_MNI-2mm_brain

echo "--- Normalizing brain to 1 mm ---"
applywarp -i ${stem}.anat/T1_biascorr_manual_brain --warp=${stem}.anat/T1_to_MNI_nonlin_coeff -r $FSLDIR/data/standard/MNI152_T1_1mm -o ${stem}_MNI-1mm_brain