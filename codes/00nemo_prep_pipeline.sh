#!/bin/bash

: <<COMMENTBLOCK
30.aug.2023: This is written by Andreas G Damsbo (andreas.gdamsbo.dk) as part of exchange stay at Brain Behavior Lab, UBC, Canada

Script to run on multiple subfolders
Make sure to cd to the relevant folder. This script should run in the source folder.
This script calls lesion_norm_fsl.sh, which expects fsl_anat_alt.sh and optiBET.sh.
All child scripts are from https://neuroimaging-core-docs.readthedocs.io/en/latest/pages/fsl_anat_normalization-lesion.html

This script will try to tie everything together for preprocessing and registrering T1w and LesionMask to 1mm MNI space.
It relies on several other child scripts that have been slightly modified:
- 
- 
- 
All these scripts should be in the same folder, as this main script.

Script is written with checks to allow for re-run. If the script has been run previously but was interrupted, make sure to manually remove the *.anat folder in the last subject folder. Then re-run.
COMMENTBLOCK

DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi


for D in *; do  
  
    if [ -d "${D}" ]; then
      
      echo "### Starting with $D ###"
      
      date_time=$(date +"%D %T")
      
      t1w=`find "${D}" -name '*T1w.nii.gz'`
      lesionmask=`find "${D}" -name '*LesionMask.nii.gz'`
      
      fileStem=`remove_ext ${t1w}`
      
      sub="$D"
      
      if [ ! -d "${fileStem}.anat" ]; then
        
        echo "--- Start processing $D at $date_time ---"
        
        $DIR/prep_T1w_bbl.sh $t1w $lesionmask
      else
        echo "--- $D appears to be processed already. Carry on! ---"
      fi
      
      
      if [ `find "${D}" -name '*1mm*' | wc -l` != 0 ]; then
        
        echo "--- Normalization has already been performed ---"
        
      else 
        echo "--- Now Heading for normalization ---"
        
        ## FSL Normalisation
        
        $DIR/fsl_1mm-norm_bbl.sh $t1w ${fileStem}.anat/lesionmask
        
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


