#!/bin/bash

: <<COMMENTBLOCK
Assumes we are in the directory with subdirectories with the images we need.
Pass in 2 arguments:
1) a T1 anatomical image
2) a lesion mask (1=lesion; 0=non-lesion)
e.g. lesion_norm_fsl.sh sub-001.nii.gz sub-001_LesionSmooth.nii.gz
Is expected by 00nemo_prep_pipeline.sh.
COMMENTBLOCK

# If there are less than 2 arguments
if [ $# -lt 2 ] ; then
  echo "Usage: $0 <T1w_image> <lesion_mask>"
  echo "e.g. lesion_norm_fsl.sh sub-001.nii.gz sub-001_LesionSmooth.nii.gz"
  echo "This script calls runs FSL based normalisation for T1w and lesion images"
  echo "Requires a custom MNI152_T1_1mm.cnf file"
  exit 1 ;
fi

image=$1
lesion_mask=$2
stem=`${FSLDIR}/bin/remove_ext ${image}`
 
 #  This script is used to be able to stay in 2mm space as long as possible and just register lesion mask to 1mm for the NeMo tool
 # 
 # I ran out of patience with bash scripting, so please just uncomment necessary lines to include/exclude lesion mask, brain mask and/or brain registration.
 
 #### Normalize everything ####
 
 # --- warp the lesion mask into MNI space, use nearest neighbour interpolation
 # This step is the least for NeMo, but the next steps can be included for quality control.
 echo "--- Normalizing lesion ---"
 applywarp -i ${lesion_mask} -w ${stem}.anat/T1_to_MNI_nonlin_field --interp=nn -r  $FSLDIR/data/standard/MNI152_T1_1mm -o ${stem}_MNI-1mm_lesion
 
 
 # --- warp the brain mask into MNI space, use nearest neighbour interpolation
 
 echo "--- Normalizing brain mask ---"
 applywarp -i ${stem}_brain_mask.nii.gz  -w ${stem}.anat/T1_to_MNI_nonlin_field --interp=nn -r $FSLDIR/data/standard/MNI152_T1_1mm -o ${stem}_MNI-1mm_brain_mask
 
 # --- warp the skull stripped brain into MNI space
 
 echo "--- Normalizing brain ---"
 applywarp -i ${stem}.anat/T1_biascorr_brain -w ${stem}.anat/T1_to_MNI_nonlin_field -r $FSLDIR/data/standard/MNI152_T1_1mm -o ${stem}_MNI-1mm_brain
 
 
 
 # create the binary version of the MNI lesion mask (mostly harmless, though I think
 # not needed since we are doing nearest neighbour interpolation).
 fslmaths ${stem}_MNI-1mm_lesion -thr 0.5 -bin ${stem}_MNI-1mm_lesion -odt char

 
 