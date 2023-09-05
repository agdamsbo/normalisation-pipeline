# Data processing for brain and lesion normalisation

This pipeline was comprised as part of my exchange stay at the Brain Behavior Lab at UBC, Vancouver, Canada. It is my hope that the notes and script may be of help to others, myself being a new learner to FSL and everything around it.

The reason for creating this tool is to use 1mm MNI normalised lesion masks for the [NeMo tool](https://kuceyeski-wcm-web.s3.us-east-1.amazonaws.com/upload.html).

Most of the hard working scripts in this pipeline are based on the work by [Dr. Dianne Patterson, PhD](https://neuroimaging-core-docs.readthedocs.io/en/latest/index.html). I have tried my best at modifying the original scripts as little as possible for clarity, and instead created a few new scripts to work as wrappers.

The pipeline provides a set of handy tools listed below, which I will also go through:

-   R-script to organise files into subject-folders

-   Shell pipeline to process all subject folders to extract brain mask, and normalise lesion mask to 1 mm MNI space (this is the primary content)

-   Shell-script to normalise lesion mask after manual correction of brain mask (no, even using optiBET is not perfect)

-   R-script to package lesion masks to supply to the NeMo tool.

# Requirements

You need to have fsl as well as *R* installed.

## Files required for each subject

The scripts needs a T1 weighted scan and lesion mask in Nifti format. Naming should be as follows.

-   subjID_T1w.nii.gz
-   subjID_LesionMask.nii.gz

# Getting started

Script files are located in the `codes` folder like below.

```         
${ROOT}
|-- codes
   |-- 00nemo_prep_pipeline.sh
   |-- file-structure.R
   |-- fsl_1mm-norm_bbl.sh
   |-- fsl_anat_alt_bbl.sh
   |-- modified_brain_mask_bbl.sh
   |-- nemo-packing.R
   |-- optiBET.sh
   |-- prep_T1w_bbl.sh
   |-- T1_2_MNI152_1mm.cnf
|-- ...
```

1.  Move the contents of the `codes` folder to where you want your files to be located. This folder is now referred to as the root directory. Now, open a terminal window in the root directory.

1.  Start by copying a new configuration file for fsl, to do registration to 1mm MNI space (basically the same as the 2mm config, but references the 1mm MNI):

    ```         
    imcp T1_2_MNI152_1mm.cnf $FSLDIR/etc/flirtsch/T1_2_MNI152_1mm.cnf
    ```

    See [this mail thread](https://www.jiscmail.ac.uk/cgi-bin/webadmin?A2=fsl;2fa01b76.1208) for a note on the 1mm normalization. It is needed for the NeMo-tool however.

1.  Open the `file-prep.R` script and edit the first three variables. Save it and then, run the following in the terminal window:

    ```         
    Rscript file-prep.R
    ```

    Instructions are in this file. Note that, this script assumes your data files are ordered as below:
    
    ```         
    ${ORIGINAL DATAFOLDER}
    |-- sub01_T1w.nii.gz
    |-- sub01_LesionMask.nii.gz
    |-- sub02_T1w.nii.gz
    |-- sub02_LesionMask.nii.gz
    |-- subNN_T1w.nii.gz
    |-- subNN_LesionMask.nii.gz
    ```

    Now the files and folders are structured as expected, as below:
    
    ```         
    ${ROOT}
    |-- 00nemo_prep_pipeline.sh
    |-- file-structure.R
    |-- fsl_1mm-norm_bbl.sh
    |-- fsl_anat_alt_bbl.sh
    |-- modified_brain_mask_bbl.sh
    |-- nemo-packing.R
    |-- optiBET.sh
    |-- prep_T1w_bbl.sh
    |-- T1_2_MNI152_1mm.cnf
    |-- sub01
        |-- sub01_T1w.nii.gz
        |-- sub01_LesionMask.nii.gz
    |-- sub02
        |-- sub02_T1w.nii.gz
        |-- sub02_LesionMask.nii.gz
    |-- subNN
        |-- subNN_T1w.nii.gz
        |-- subNN_LesionMask.nii.gz
    ```

1.  In a terminal window, make sure your in the source directory, where your codes and scans are located.

    ```         
    sh 00nemo_prep_pipeline.sh
    ```

    Then, when ready to start processing your data, fire up the main script, and watch while your computer hums away. Or do something else in the meantime. You'll get time stamps along the way to have an idea of the progress and the time needed. The output files are written along the way, so you can manually check the output while the script works. Note that your original T1 and lesion mask will have "\_orig" appended as suffix and be substituted with corrected files. If the script gets interrupted, you can just restart it, and it will skip subjects already processed. Make sure you delete the output files, if you want the script to rerun on a specific subject.

1.  As quality control of the registration, I would open the new "SubNN_T1w.nii.gz" in fsleyes or ITK-SNAP and overlay the "SubNN_T1w_brain_mask.nii.gz" and go through to check the masking and cropping.

    -   Regarding masking: In ITK-SNAP, you can correct the brain mask manually. Working in a different label from the brain mask, you can mark additional brain area using the interpolate tool. The tool is demonstrated [here](https://youtu.be/watch?v=ZVmINdWk5R4). Save the new mask with a new name. Subtracting brain mask would be done manually, I believe. Please share, if you have a better approach.

        Having a new, modified brain mask, go to the terminal window again and write the following:

        ```     
        sh modified_brain_mask_bbl.sh SubNN/SubNN_T1w.nii.gz SubNN/MODIFIED_T1w_brain_mask.nii.gz
        ```
        
        Please notice that the naming of the modified brain mask doesn't matter.

    -   Regarding cropping: Delete all the output-files (remembering that the original files were preserved with "\_orig" suffix) and renaming the original files removing the suffix. Open the original T1 image and lesion mask in fsleyes, and manually crop the two with the same mask. After cropping, run the `00nemo_prep_pipeline.sh` script again.

1.  Now you should be ready to package for the NeMo tool. The web interface has an upload limit of 10 lesion masks. Open and edit the source-folder in the `nemo-packing.R` script. It will collect all 1mm MNI lesion masks and package in zip-files of max 10 lesion masks each and put them in the provided folder. Save and then run the following:

    ```
    Rscript nemo-packing.R
    ``` 

# Source and acknowledgements

Scripts for normalization: [link](https://neuroimaging-core-docs.readthedocs.io/en/latest/pages/lesion_normalization.html)

NeMo tool upload: [link](https://kuceyeski-wcm-web.s3.us-east-1.amazonaws.com/upload.html)

## Notes on changes from the originals

**fsl_anat_alt_bbl.sh**: It took me some time to figure out, I have to say. During the script, the working directory is changed. This makes referencing the optiBET_bbl.sh script a little tricky. I ended up going back a step with "cd -" and forward again after running optiBET_bbl.sh.

# Licensing

If nothing else is explicitly stated en the relevant files, everything in the repository is licensed under the [AGPL-v3](https://www.gnu.org/licenses/agpl-3.0.en.html).
