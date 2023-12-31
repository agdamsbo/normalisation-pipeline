# Changelog

## 2024.1.1

Changed versioning scheme.

As the NeMo-tool is published without a license, the package or parts of it cannot be redistributed, and should instead be downloaded directly from the [NeMo repository](https://github.com/kjamison/nemo). This pipeline-project is shared under the FOSS-license A-GPL-v3.

This version will be the first released on Zenodo and have a DOI.

DESCRIPTION file added for easier cloning of the project. Initialise `renv` with `renv::init(bare=TRUE)`.

## 2023.10.06

This is the final version before leaving the Brain Behavior Lab for now. I have been working hard on maturing the script to better handle different use cases.

The script will run without any specifications passed to it and default to 2 mm fsl registration with or without a lesion mask. It also 1 mm registration if you follow the instructions to supply a modified `.cnf` config file to fsl, see [@sec-start]. It also does ANTs registration, but only if a lesion mask is supplied. The script also allows for lesion mask regex specification as well as regex subfolder specification. It will stopp processing if there are several lesion masks in a subfolder. The scripts in `codes/` can be located anywhere, but has to be launched from a terminal window in the parent folder of subject-wise data folder. See the [@sec-gettoit] regarding expected file structure.

Comments and questions are welcome on [GitHub Discussions](https://github.com/agdamsbo/normalisation-pipeline/discussions).


## 2023.10.05

### Notes

Restructuring of the initial book to better emphasize the more general usability of the pipeline. This will prevent renaming the repository and widen the usability. The pipeline was recently tweaked to run 1-level subfolders with or without lesion masks, and final registration space (1/2 mm) is specified on first run. The script are still a little primitive, in that they don't have a ton of control steps built in, so please stick to documentation or start modifying yourself. I'll be very happy to receive comments and PRs here on GitHub.

A few other checks has been added to make the script working a little more robustly. It will give error if several lesion masks are detected. Append data+time as suffix to original files to avoid overwriting on script re-runs.

### Changes (non-extensive)

- 00norm_pipeline.sh: everything should now have comments. Handles missing lesion masks more elegantly. Input with named flags and help section. Runs with defaults. ANTs registration option included. Renamed.

- fsl-norm-bbl.sh: now actually does registration of lesion masks, and binarises the lesion normalised lesion mask, if it is there.

- ant_reg3.sh: script included to provide optional ANTs registration. See https://github.com/ANTsX/ANTs for installation instructions. If ANTs is installed in a virtual environment, everything should be run from within this.