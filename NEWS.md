# Changelog

## 2023.10.05

### Notes

Restructuring of the initial book to better emphasize the more general usability of the pipeline. This will prevent renaming the repository and widen the usability. The pipeline was recently tweaked to run 1-level subfolders with or without lesion masks, and final registration space (1/2 mm) is specified on first run. The script are still a little primitive, in that they don't have a ton of control steps built in, so please stick to documentation or start modifying yourself. I'll be very happy to receive comments and PRs here on GitHub.

A few other checks has been added to make the script working a little more robustly. It will give error if several lesion masks are detected. Append data+time as suffix to original files to avoid overwriting on script re-runs.

### Changes (non-extensive)

- 00norm_pipeline.sh: everything should now have comments. Handles missing lesion masks more elegantly. Input with named flags and help section. Runs with defaults. ANTs registration option included. Renamed.

- fsl-norm-bbl.sh: now actually does registration of lesion masks, and binarises the lesion normalised lesion mask, if it is there.

- ant_reg3.sh: script included to provide optional ANTs registration. See https://github.com/ANTsX/ANTs for installation instructions. If ANTs is installed in a virtual environment, everything should be run from within this.