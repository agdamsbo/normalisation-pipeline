#!/bin/bash

: <<COMMENTBLOCK
Concentrated and modified fsl_anat_alt_bbl.sh to allow for simple registration after manually corrected brain mask.
This is to be able to manually correct the output from optiBET, which is good, but not perfect.
First argument is the standard T1w image, second arguent is the modified brain mask.
COMMENTBLOCK

FSLDIR=/usr/local/fsl
stem=`remove_ext ${1}`
mask_stem=`remove_ext ${2}`
T1=T1
refmask=MNI152_${T1}_2mm_brain_mask_dil1

## Converting to binary mask is done to allow for esier editing of mask in seperate label in ITK-SNAP using interpolate functionality.
echo "--- Converting brain mask to binary ---"

fslmaths ${mask_stem} -thr 0.5 -bin ${mask_stem}_BIN -odt char

## Copy the modified T1w image back as the T1_biascorr
immv ${stem}.anat/${T1}_biascorr_brain_mask.nii.gz ${stem}.anat/OLD_${T1}_biascorr_brain_mask.nii.gz
imcp ${mask_stem}_BIN ${stem}.anat/${T1}_biascorr_brain_mask.nii.gz

imcp ${stem}.nii.gz ${stem}.anat/T1_biascorr.nii.gz



cd ${stem}.anat

refmask=MNI152_${T1}_2mm_brain_mask_dil1
fnirtargs=""

date; echo "Registering to standard space (non-linear)"
$FSLDIR/bin/fslmaths $FSLDIR/data/standard/MNI152_${T1}_2mm_brain_mask -fillh -dilF $refmask

$FSLDIR/bin/fnirt --in=${T1}_biascorr --ref=$FSLDIR/data/standard/MNI152_${T1}_2mm --fout=${T1}_to_MNI_nonlin_field --jout=${T1}_to_MNI_nonlin_jac --iout=${T1}_to_MNI_nonlin --logout=${T1}_to_MNI_nonlin.txt --cout=${T1}_to_MNI_nonlin_coeff --config=$FSLDIR/etc/flirtsch/${T1}_2_MNI152_2mm.cnf --aff=${T1}_to_MNI_lin.mat --refmask=$refmask $fnirtargs

date; echo "Extracting brain"

$FSLDIR/bin/fslmaths ${T1}_biascorr_brain_mask -fillh ${T1}_biascorr_brain_mask
$FSLDIR/bin/fslmaths ${T1}_biascorr -mas ${T1}_biascorr_brain_mask ${T1}_biascorr_brain


cd -


## Now everythin is normalised for the sake of QC

# --- warp the lesion mask into MNI space, use nearest neighbour interpolation
# This step is the least for NeMo, but the next steps can be included for quality control.
echo "--- Normalizing lesion ---"
applywarp -i ${stem}.anat/lesionmask.nii.gz -w ${stem}.anat/T1_to_MNI_nonlin_field --interp=nn -r  $FSLDIR/data/standard/MNI152_T1_2mm -o ${stem}_MNI-2mm_lesion


## This is for NeMo, 2mm used for QC
echo "--- Normalizing lesion to 1mm ---"
applywarp -i ${stem}.anat/lesionmask.nii.gz -w ${stem}.anat/T1_to_MNI_nonlin_field --interp=nn -r  $FSLDIR/data/standard/MNI152_T1_1mm -o ${stem}_MNI-1mm_lesion


# --- warp the brain mask into MNI space, use nearest neighbour interpolation
# --- Here we are using the provided 

echo "--- Normalizing brain mask ---"
applywarp -i ${2}  -w ${stem}.anat/T1_to_MNI_nonlin_field --interp=nn -r $FSLDIR/data/standard/MNI152_T1_2mm -o ${stem}_MNI-2mm_brain_mask


# --- warp the skull stripped brain into MNI space

echo "--- Normalizing brain ---"
applywarp -i ${stem}.anat/T1_biascorr_brain -w ${stem}.anat/T1_to_MNI_nonlin_field -r $FSLDIR/data/standard/MNI152_T1_2mm -o ${stem}_MNI-2mm_brain