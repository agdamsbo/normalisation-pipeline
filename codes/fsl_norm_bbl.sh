#!/bin/bash

: <<COMMENTBLOCK
Assumes we are in the directory with subdirectories with the images we need.
Pass in 2 arguments:
1) a T1 anatomical image
2) resolution, either "1mm" or "2mm"
3) a lesion mask (1=lesion; 0=non-lesion)
e.g. lesion_norm_fsl.sh sub-001.nii.gz sub-001_LesionSmooth.nii.gz
Is expected by 00nemo_prep_pipeline.sh.
COMMENTBLOCK

# If there are less than 2 arguments
if [ $# -lt 2 ] ; then
  echo "Usage: $0 <T1w_image> <resolution (1mm or 2mm)> <lesion_mask>"
  echo "e.g. lesion_norm_fsl.sh sub-001.nii.gz 2mm sub-001_LesionSmooth.nii.gz"
  echo "This script calls runs FSL based normalisation for T1w and lesion images if available"
  echo "Requires a custom MNI152_T1_1mm.cnf file to do 1mm resolution registration"
  exit 1 ;
fi

image=$1
res=$2
lesion_mask=$3
stem=`${FSLDIR}/bin/remove_ext ${image}`
 
 #  This script is used to be able to stay in 2mm space as long as possible and just register to the desired 1mm or 2mm resolution MNI space in the end.
 #  Only 
 # 
 # I ran out of patience with bash scripting, so please just uncomment necessary lines to include/exclude lesion mask, brain mask and/or brain registration.
 
 #### Normalize everything ####
 
 # --- warp the lesion mask into MNI space, use nearest neighbour interpolation
 # This step is the least for NeMo, but the next steps can be included for quality control.
 
 if [[ -n $lesion_mask ]]; then
        
   echo "--- Normalizing lesion ---"
   applywarp -i ${lesion_mask} -w ${stem}.anat/T1_to_MNI_nonlin_field --interp=nn -r  $FSLDIR/data/standard/MNI152_T1_${res} -o ${stem}_MNI-${res}_lesion
   
   # create the binary version of the MNI lesion mask (mostly harmless, though I think
   # not needed since we are doing nearest neighbour interpolation).
   fslmaths ${stem}_MNI-${res}_lesion -thr 0.5 -bin ${stem}_MNI-${res}_lesion -odt char
 
 fi

 # --- warp the brain mask into MNI space, use nearest neighbour interpolation
 
 echo "--- Normalizing brain mask ---"
 applywarp -i ${stem}_brain_mask.nii.gz  -w ${stem}.anat/T1_to_MNI_nonlin_field --interp=nn -r $FSLDIR/data/standard/MNI152_T1_${res} -o ${stem}_MNI-${res}_brain_mask
 
 # --- warp the skull stripped brain into MNI space
 
 echo "--- Normalizing brain ---"
 applywarp -i ${stem}.anat/T1_biascorr_brain -w ${stem}.anat/T1_to_MNI_nonlin_field -r $FSLDIR/data/standard/MNI152_T1_${res} -o ${stem}_MNI-${res}_brain
 
 
 
 

 
 