#!/bin/bash

: <<COMMENTBLOCK
Multiple punch outs of normalised lesion masks to ensure within normalised brain mask
COMMENTBLOCK

  path=${1}
  pattern=${2}
  
  fslmaths /usr/local/fsl/data/standard/MNI152_T1_1mm_brain_mask.nii.gz -binv mni_1mm_brain_mask_inv.nii.gz

for i in `find ${path} -name ${pattern}`; do  
  
stem=`remove_ext ${i}`
echo "$i"
    fslmaths ${i} -bin -sub mni_1mm_brain_mask_inv.nii.gz -thr 0 ${stem}_punch
done


