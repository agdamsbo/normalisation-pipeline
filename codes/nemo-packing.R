### ============================================================================
### 
###     Setting source folder and lesion files name pattern
### 
### ============================================================================

## Source folder, where lesion mask are located in subfolders for each subject
source.folder <- "/Users/user/project/rawfiles"

## Naming pattern for the MNI normalised lesion masked
mni_lesion <- "*MNI-1mm_lesion.nii.gz"

## Set regex pattern for positive selection of subject specific files
id_pattern <- "Sub([0-9]{2})"

### ============================================================================
### 
###     Copying files to new destination 
###     - will put compressed folders in source folder
### 
### ============================================================================

sub.dirs <- list.dirs(source.folder,recursive = FALSE)

mni.files <- do.call(c,lapply(sub.dirs, list.files, pattern=mni_lesion, full.names = TRUE))
mni.files.short <- do.call(c,lapply(sub.dirs, list.files, pattern=mni_lesion))

temp.dir <- paste0(source.folder,"/temp")
dir.create(temp.dir)

lapply(seq_along(mni.files),function(i){
  file.copy(mni.files[i],paste0(temp.dir,"/",mni.files.short[i]),overwrite = TRUE)
  })

temp.files <- list.files(temp.dir, full.names = FALSE)

## There are a few helpful functions in the stRoke package
require(stRoke)

# chunks_of_n <- function(d,n=10,label="masks_"){
#   ls <- split(d, ceiling(seq_along(d)/n))
#   names(ls) <- paste0(label,names(ls))
#   ls
# }

## Function to zip files in a folder in packs of n with label
packs_of_n <- function(folder, files=NULL, n=10, label="lesion_masks", pattern=NULL) {
  
  if (is.null(files)) files <- list.files(folder, full.names = TRUE)
  
  files.chunks <- chunks_of_n(d = files, n = n, even=TRUE, label = label, pattern = pattern)
  
  lapply(seq_along(files.chunks), function(i) {
    zip::zip(zipfile = paste0(paste(folder, names(files.chunks)[i], sep = "/"), ".zip"), files =
               files.chunks[[i]])
  })
}

oldwd <- getwd()
setwd(temp.dir)
packs_of_n(folder=source.folder, files=temp.files, pattern=id_pattern)
setwd(oldwd)

unlink(temp.dir, recursive = TRUE)
