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
Usage() {
  echo "Usage: sh $0 -l <lesion_mask_namepattern> --doants --do1mm"
  echo "       sh $0 -l 'LesionMask.nii.gz'"
  echo "       sh $0 -s 'W[0-9]{2}'"
  echo "       sh $0 --do1mm"
  echo "       sh $0"
  echo " "
  echo "This wrapper script will first perform automatic biascorrection, cropping and skull stripping (using optiBET)"
  echo "and then registration of brain, brain mask and lesion (if available) to 1 or 2 mm MNI standard space."
  echo " "
  echo "To do 1 mm registration requires custom MNI152_T1_1mm.cnf (which is included with this pipeline, see documentation)"
  echo " "
  echo "Note that this script expects prep_T1w_bbl.sh, fsl_anat_alt.sh, optiBET.sh and fsl_norm_bbl.sh to be in the same folder"
  echo " "
  echo "Arguments (You may specify one or more of):"
  echo "  -l <lesion mask name pattern>     The unique regex lesion mask name pattern. (defaults to 'LesionMask.nii.gz')"
  echo "  -s <sub folder name pattern>      The unique regex name pattern for sub folders to process. (defaults to '.*', giving all subfolders)"
  echo "  --do1mm                           Perform final registration to 1mm MNI space (defaults is 2mm)"
  echo "  --doants                          Perform final ANTs registration (default method is FSL flirt and fnirt)"
  echo "  -h/--help                         Provides this help documentation, which is also printed on errors"
}

# Argument handling inspired from https://stackoverflow.com/a/31443098/21019325 as well as the fsl_anat_alt_bbl.sh, that I did not write.

# Default flag values
# Deafault registration with FSL
registration=fsl
# Assumes resolution is 2mm, changed later with flag
resolution=2mm

set -e
LOGFILE=log_$(date +"%Y%m%dT%H%M%S").txt

run() {
  echo $@ >> $LOGFILE
  $@
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    -l) lesionpattern="$2"; shift 2;;
    -s) subpattern="$2"; shift 2;;
    -h) Usage; exit 0;;
    --do1mm) resolution=1mm; shift 1;;
    --doants) registration=ants; shift 1;;
    --help) Usage; exit 0;;

    # --resolution=*) resolution="${1#*=}"; shift 1;;
    # --lesionpattern=*) lesionpattern="${1#*=}"; shift 1;;
    
    -*) echo "unknown option: $1" >&2; Usage; exit 1;;
    *) handle_argument "$1"; shift 1;;
  esac
done

# The script will assume that the lesion mask is named something containing "lesion", if not mask name pattern is supplied
if [[ -z "$lesionpattern" ]] ; then
  lesionpattern='*[Ll]esion*.nii.gz' 
fi

# 
if [[ -z "$subpattern" ]] ; then
  subdirs='.*'
else
  subdirs=$subpattern
fi

# Getting the name of the working directory
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi

# Basic log entries
echo "Script invoked at $(date +"%Y-%m-%dT%H:%M:%S")" >> $LOGFILE
echo "Final registration will be $resolution, using $registration" >> $LOGFILE
echo "Script invoked from directory = `pwd`" >> $LOGFILE
echo "Working directory is $DIR" >> $LOGFILE

# Looping across all level 1 subfolders in the folder, from which the script is run
for D in *; do  
  
    if [[ -d ${D} ]] && [[ ${D} =~ $subdirs ]]; then
      
      echo "Processing $D started at $(date +"%Y-%m-%dT%H:%M:%S")" >> $LOGFILE
      
      date; echo "### Starting with $D ###"
      
      # Extracting the file name of the T1w image, supposing the name ends on T1w.nii.gz
      t1w=`find "${D}" -maxdepth 1 -name '*T1w.nii.gz'`
      echo "Main structural image is $t1w" >> $LOGFILE
      
      # Getting the lesion mask file name
      # Please note, that I am excluding filenames we assume comes from previous normalisation and files, that were copied 
      lesionmask=`find "${D}" -maxdepth 1 -name ${lesionpattern}  ! -name '*MNI-[12]mm_*' ! -name '*_orig.nii.gz'`
      
      # Converting to array for testing (there probably is a better solution, but this works)
      lesiontest=($lesionmask)
      
      # Checking if there is more than one file matching the lesionpattern
      if [[ ${#lesiontest[@]} > 1 ]]; then
        echo "### ERROR"
        echo " "
        echo "### ${#lesiontest[@]} files matches the lesion mask pattern in $PWD/$D"
        echo "### Please have a look in that folder, to only include 1 lesion mask file"
        echo "### After you reorder the files, you can rerun the script"
        echo " "
        echo "### The files are the following:"
        echo " "
        echo "$lesionmask"
        echo "ERROR: process stopped at $(date +"%Y-%m-%dT%H:%M:%S") as ${#lesiontest[@]} lesion masks are in the subject folder of $D" >> $LOGFILE
        echo "$lesionmask" >> $LOGFILE
        echo " "
        exit 0;
      fi
      
      # Extracting file stem to supply to child scripts
      fileStem=`remove_ext ${t1w}`
      
      # Checking if .anat folder has already been created in a previous run, assuming the data has then been processed
      if [ ! -d "${fileStem}.anat" ]; then
        
        # Printing the lesion mask file name for sanity checking
        if [[ -n "$lesionmask" ]]; then
          echo "--- Lesionmask used: $lesionmask ---"
        fi
        
        # Checking if a lesion mask has been provided
        if [[ -z "$lesionmask" ]]; then
          
          # No lesion mask
          date; echo "--- Start processing only brain for $D ---"
          
          run $DIR/prep_T1w_bbl.sh $t1w
        
        else
        
          # Lesion mask provided
          date; echo "--- Start processing brain and lesion for $D ---"
          
          echo "Lesion mask used is $lesionmask" >> $LOGFILE
          
          run $DIR/prep_T1w_bbl.sh $t1w $lesionmask
          
        fi
        
      else
        
        # No skull stripping
        date; echo "--- $D appears to be processed already. Carry on! ---"
        
      fi
      
      # Checking if normalised files of the specified resolution are in the given sub-folder
      if [ `find "${D}" -maxdepth 1 -name '$resolution' | wc -l` != 0 ]; then
        
        # Normalised files are present and this step i skipped
        date; echo "--- Normalization has already been performed ---"
        
      else 
        
        # Normalised files are not present, and normalisation/registration can continue
        
        if [ $registration = ants ]; then
        
          ## Notes on ANTS normalisation
          ## 
          ## For our usecase FSL normalisation has been good enough. 
          ## ANTS may be better for your usecase.
          ## The script ant_reg3_bbl.sh is included to offer ANTS normalisation.
          ## This scripts requires the T1 brain for normalisation as well as a lesion mask
          ## Notes on comparing different approaches: https://neuroimaging-core-docs.readthedocs.io/en/latest/pages/lesion_normalization.html
        
        
          if [[ -z "$lesionmask" ]]; then
            echo "--- ANTs registration requires a lesion mask. None was found. ---"
          else
          
            date; echo "--- Now to ANTs normalization to $resolution space ---"
            
            # The script assumes the location of 
            run sh $DIR/ant_reg3_bbl.sh $t1w $resolution
          fi
          
        else
          ## FSL Normalisation
          
          # Checking if there is a lesion mask to include
          if [[ -z "$lesionmask" ]]; then
          
            date; echo "--- Now to FSL normalization to $resolution space without a lesion ---"
            
            run $DIR/fsl_norm_bbl.sh $t1w ${resolution}
          
          else
          
            date; echo "--- Now to FSL normalization to $resolution space ---"
            
            run $DIR/fsl_norm_bbl.sh $t1w ${resolution} ${fileStem}.anat/lesionmask
            
          fi
          
        fi
        
      fi
      
      # Done!
      date; echo "### DONE with ${D}###"
      
    fi
    
    ## Wishlist
    ## - include subject pattern specification
    ## - flag to opt for manual accept of auto cropping
    ## - handle spaces in dir-/filenames (they shouldn't be there, but you shouldn't complain either)
    ## - option to specify the source folder - Not needed. Open terminal in desired folder, or cd there, and then call the script
    ## - use flags to process script input - DONE
    
done


