[![DOI](https://zenodo.org/badge/687180387.svg)](https://zenodo.org/doi/10.5281/zenodo.10469422)


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

You need to have [fsl](https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/FSL) as well as [*R*](https://www.r-project.org/) and [RStudio (or similar)](https://posit.co/downloads/) installed. I also highly recommend the package [ITK-SNAP](http://itksnap.org/pmwiki/pmwiki.php?n=Main.HomePage), which can be used for some (semi-)manual mask modifications.

## Files required for each subject

The scripts needs a T1 weighted scan and lesion mask in Nifti format. Naming should be as follows.

-   subjID_T1w.nii.gz
-   subjID_LesionMask.nii.gz

# Instructions

Step-by-step documentation and notes are [provided here](https://agdamsbo.github.io/normalisation-pipeline/).

# Source and acknowledgements

Scripts for normalization: [link](https://neuroimaging-core-docs.readthedocs.io/en/latest/pages/lesion_normalization.html)

NeMo tool upload: [link](https://kuceyeski-wcm-web.s3.us-east-1.amazonaws.com/upload.html)

## Notes on changes from the originals

**fsl_anat_alt_bbl.sh**: It took me some time to figure out, I have to say. During the script, the working directory is changed. This makes referencing the optiBET_bbl.sh script a little tricky. I ended up going back a step with "cd -" and forward again after running optiBET_bbl.sh.

# Licensing

If nothing else is explicitly stated en the relevant files, everything in the repository is licensed under the [AGPL-v3](https://www.gnu.org/licenses/agpl-3.0.en.html).
