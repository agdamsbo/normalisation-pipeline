## Source folder of data file from NeMo
source.folder <- "/Users/au301842/ubc_smile/masks_complete"

sub.dirs <- list.dirs(source.folder,recursive = FALSE)

mni.files <- do.call(c,lapply(sub.dirs, list.files, pattern="*T1w_MNI-1mm_lesion.nii.gz", full.names = TRUE))
mni.files.short <- do.call(c,lapply(sub.dirs, list.files, pattern="*T1w_MNI-1mm_lesion.nii.gz"))

temp.dir <- paste0(source.folder,"/temp")
dir.create(temp.dir)

lapply(seq_along(mni.files),function(i){
  file.copy(mni.files[i],paste0(temp.dir,"/",mni.files.short[i]),overwrite = TRUE)
  })

temp.files <- list.files(temp.dir, full.names = FALSE)

## Helper function to split vector to list in chunks of n
chunks_of_n <- function(d,n=10,label="masks_"){
  ls <- split(d, ceiling(seq_along(d)/n))
  names(ls) <- paste0(label,names(ls))
  ls
}

## Function to zip files in a folder in packs of n with label
packs_of_n <- function(folder, files=NULL, n=10, label="masks_") {
  
  if (is.null(files)) files <- list.files(folder, full.names = TRUE)
  
  files.chunks <- chunks_of_n(files, n = n, label = label)
  
  lapply(seq_along(files.chunks), function(i) {
    zip::zip(zipfile = paste0(paste(folder, names(files.chunks)[i], sep = "/"), ".zip"), files =
               files.chunks[[i]])
  })
}

oldwd <- getwd()
setwd(temp.dir)
packs_of_n(folder=source.folder, files=temp.files)
setwd(oldwd)

unlink(temp.dir, recursive = TRUE)
