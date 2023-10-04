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

# If no arguments are povided the script will return an error
if [ $# -lt 0 ] ; then
  echo "Usage: $0 <resolution (1mm or 2mm)> <lesion_mask_namepattern (defaults to 'LesionMask.nii.gz')>"
  echo "e.g. sh 00nemo_prep_pipeline.sh 1mm 'LesionMask.nii.gz' or sh 00nemo_prep_pipeline.sh 1mm"
  echo "This script wil perform skull stripping, and registration of head, brain and lesion (if available) to standard MNI space"
  echo "Requires a custom MNI152_T1_1mm.cnf file to do 1mm resolution registration"
  exit 1 ;
fi

# Saving arguments with undrstandable names
resolution=${1}
lesionpattern=${2}

# The script will assume that the lesion mask is named something containing "lesion", if not mask name pattern is supplied
if [[ -z "$lesionpattern" ]] ; then
  lesiontext='*[Ll]esion*.nii.gz' 
else
  lesiontext=$lesionpattern
fi

# Getting the name of the working directory
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi

# Looping across all level 1 subfolders in the folder, from which the script is run
for D in *; do  
  
    if [ -d "${D}" ]; then
      
      date; echo "### Starting with $D ###"
      
      # Extracting the file name of the T1w image, supposing the name ends on T1w.nii.gz
      t1w=`find "${D}" -name '*T1w.nii.gz' -maxdepth 1`
      
      # Getting the lesion mask file name
      lesionmask=`find "${D}" -name ${lesiontext}  -maxdepth 1`
      
      # Printing the lesion mask file name for sanity checking
      if [[ -n "$lesionmask" ]]; then
        echo "This is the lesionmask used: $lesionmask"
      fi
      
      # Extracting file stem to supply to child scripts
      fileStem=`remove_ext ${t1w}`
      
      # Getting the subfolder name for printing status later on
      sub="$D"
      
      # Checking if .anat folder has already been created in a previous run, assuming the data has then been processed
      if [ ! -d "${fileStem}.anat" ]; then
        
        # Checking if a lesion mask has been provided
        if [[ -z "$lesionmask" ]]; then
          
          # No lesion mask
          date; echo "--- Start processing only brain for $D ---"
          
          $DIR/prep_T1w_bbl.sh $t1w
        
        else
        
          # Lesion mask provided
          date; echo "--- Start processing brain and lesion for $D ---"
          
          $DIR/prep_T1w_bbl.sh $t1w $lesionmask
          
        fi
        
      else
        
        # No skull stripping
        date; echo "--- $D appears to be processed already. Carry on! ---"
        
      fi
      
      # Checking if normalised files of the specified resolution are in the given sub-folder
      if [ `find "${D}" -name '$resolution' -maxdepth 1 | wc -l` != 0 ]; then
        
        # Normalised files are present and this step i skipped
        date; echo "--- Normalization has already been performed ---"
        
      else 
        
        # Normalised files are not present, and normalisation/registration can continue
        ## FSL Normalisation
        
        # Checking if there is a lesion mask to include
        if [[ -z "$lesionmask" ]]; then
        
          date; echo "--- Now to normalization to $resolution space without a lesion ---"
          
          $DIR/fsl_norm_bbl.sh $t1w ${resolution}
        
        else
        
          date; echo "--- Now to normalization to $resolution space ---"
          
          $DIR/fsl_norm_bbl.sh $t1w ${resolution} ${fileStem}.anat/lesionmask
          
        fi
         
        
        ## ANTS normalisation
        ## The script ant_reg2_bbl.sh is included to offer ANTS normalisation on Linux.
        ## This scripts requires the T1 brain for normalisation
        ## brain="${fileStem}.anat/T1_biascorr_brain"
        ## $DIR/ant_reg2_bbl_bbl.sh ${brain} $lesionmask
        ## See "" for comparison of normalisation approaches.
        
      fi
      
      # Done!
      date; echo "### DONE with ${D}###"
      
    fi
    
    ## Wishlist
    ## - include subject pattern specification
    ## - flag to opt for manual accept of auto cropping
    ## - handle spaces in dir-/filenames (they shouldn't be there, but you shouldn't complain either)
    
done


