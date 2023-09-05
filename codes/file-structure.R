## Source folder of data file from NeMo
source.folder <- "/Users/au301842/Downloads/masks_3_nemo_output_ifod2act_20230829_201158624"

## Root folder for data destination
destination.root <- "/Users/au301842/ubc_smile"

## Data folder for subfolder creation
data.folder <- "nemo_data"

## Creating the new folder destination path
data.destination <- file.path(paste(destination.root, data.folder,sep="/"))

## Listing available files on soruce folder, relative and full paths
files <- list.files(source.folder)
files.full <- list.files(source.folder,full.names = TRUE)

## Extracting leading namebits to get subject names
namebits <- lapply(strsplit(files,"_"),"[[",1) |> unlist() |> unique()

subj <-  namebits[grep("^sub",namebits)]

## Creating folder for each subject and copying files from source
lapply(seq_along(subj), function(i) {
  if (!dir.exists(data.destination)) {
    dir.create(data.destination)
  }
  new.path <- file.path(data.destination, subj[i])
  dir.create(new.path)
  
  files.to.copy <- grep(paste0("^", subj[i]), files)
  
  lapply(files.to.copy, function(j) {
    file.copy(
      from = files.full[j[[1]]],
      to = paste0(new.path, "/", files[j[[1]]]),
      overwrite = TRUE
    )
  })
  
})

## Copying common files
commons <- grep("^(?!sub).*$",files, perl=TRUE)

lapply(commons, function(j) {
  file.copy(
    from = files.full[j[[1]]],
    to = paste0(data.destination, "/", files[j[[1]]]),
    overwrite = FALSE
  )
})
