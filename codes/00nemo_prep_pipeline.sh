#!/bin/bash

: <<COMMENTBLOCK
30.aug.2023: This is written by Andreas G Damsbo (andreas.gdamsbo.dk) as part of exchange stay at Brain Behavior Lab, UBC, Canada

Script to run on multiple subfolders
Make sure to cd to the relevant folder. This script should run in the source folder.
This script calls prep_T1w_bbl.sh, which expects fsl_anat_alt.sh and optiBET.sh, and then registers to desired resolution with fsl_norm_bbl.sh.
Most child scripts are from https://neuroimaging-core-docs.readthedocs.io/en/latest/pages/fsl_anat_normalization-lesion.html

This script will try to tie everything together for preprocessing and registrering T1w and LesionMask to 1mm/2mm MNI space.
All these scripts should be in the same folder, as this main script.

Script is written with checks to allow for re-run. If the script has been run previously but was interrupted, make sure to manually remove the *.anat folder in the last subject folder. Then re-run.
COMMENTBLOCK

# If no arguments are povided
if [ $# -lt 0 ] ; then
  echo "Usage: $0 <resolution (1mm or 2mm)> <lesion_mask_namepattern (defaults to 'LesionMask.nii.gz')>"
  echo "e.g. sh 00nemo_prep_pipeline.sh 1mm 'LesionMask.nii.gz' or sh 00nemo_prep_pipeline.sh 1mm"
  echo "This script wil perform skull stripping, and registration of head, brain and lesion (if available) to standard MNI space"
  echo "Requires a custom MNI152_T1_1mm.cnf file to do 1mm resolution registration"
  exit 1 ;
fi

resolution=${1}
lesionpattern=${2}

echo "This is the lesionmask: $lesionpattern"

if [[ -z "$lesionpattern" ]] ; then
  lesiontext='*LesionMask.nii.gz' 
else
  lesiontext=$lesionpattern
fi


DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi


for D in *; do  
  
    if [ -d "${D}" ]; then
      
      echo "### Starting with $D ###"
      
      date_time=$(date +"%D %T")
      
      t1w=`find "${D}" -name '*T1w.nii.gz'`
      
      # '*LesionMask.nii.gz' 
      
      lesionmask=`find "${D}" -name ${lesiontext}`
      
      fileStem=`remove_ext ${t1w}`
      
      sub="$D"
      
      if [ ! -d "${fileStem}.anat" ]; then
        
        if [[ -z "$lesionmask" ]]; then
          
          echo "--- Start processing only brain for $D at $date_time ---"
          
          $DIR/prep_T1w_bbl.sh $t1w
        
        else
        
          echo "--- Start processing brain and lesion for $D at $date_time ---"
          
          $DIR/prep_T1w_bbl.sh $t1w $lesionmask
          
        fi
        
      else
        echo "--- $D appears to be processed already. Carry on! ---"
      fi
      
      
      if [ `find "${D}" -name '*[12]mm*' | wc -l` != 0 ]; then
        
        echo "--- Normalization has already been performed ---"
        
      else 
        
        ## FSL Normalisation
        
        if [[ -z "$lesionmask" ]]; then
        
          echo "--- Now to normalization to $resolution space without a lesion ---"
          
          $DIR/fsl_norm_bbl.sh $t1w ${resolution}
        
        else
        
          echo "--- Now to normalization to $resolution space ---"
          
          $DIR/fsl_norm_bbl.sh $t1w ${resolution} ${fileStem}.anat/lesionmask
          
        fi
         
        
        ## ANTS normalisation
        ## The script ant_reg2_bbl.sh is included to offer ANTS normalisation on Linux.
        ## This scripts requires the T1 brain for normalisation
        ## brain="${fileStem}.anat/T1_biascorr_brain"
        ## $DIR/ant_reg2_bbl_bbl.sh ${brain} $lesionmask
        ## See "" for comparison of normalisation approaches.
        
      fi
      
      echo "### DONE with ${D}###"
      
    fi
done


