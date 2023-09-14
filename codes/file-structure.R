### ============================================================================
### 
###     Setting folder destination and file naming
### 
### ============================================================================

## Source folder of data file from NeMo
source.folder <- "/Users/user/project/rawfiles"

## Root folder for data destination
destination.root <- "/Users/user/project"

## Data folder for subfolder creation
data.folder <- "main_folder"

## Set regex pattern for positive selection of subject specific files
id_pattern <- "Sub([0-9]{2})"



### ============================================================================
### 
###     Copying files to new destination
### 
### ============================================================================

## Creating the new folder destination path
data.destination <- file.path(paste(destination.root, data.folder,sep="/"))

## Listing available files on soruce folder, relative and full paths
files <- list.files(source.folder)
files.full <- list.files(source.folder,full.names = TRUE)

## Extracting leading namebits to get subject names

## No extra library version
# namebits <- lapply(strsplit(files,"_"),"[[",1) |> unlist() |> unique()
# subj <-  namebits[grep(paste0("^",id_pattern),namebits)]

# Alternative with stRoke-package
subj <- stRoke::str_extract(files,id_pattern) |> na.omit() |> unique()

## Creating folder for each subject and copying files from source
lapply(seq_along(subj), function(i) {
  if (!dir.exists(data.destination)) {
    dir.create(data.destination)
  }
  
  new.path <- file.path(data.destination, subj[i])
  ## Checks if destination exists, to enable merge.
  if (!dir.exists(new.path)) {
    dir.create(new.path)
  }
  
  files.to.copy <- grep(paste0("^", subj[i]), files)
  
  lapply(files.to.copy, function(j) {
    file.copy(
      from = files.full[j[[1]]],
      to = paste0(new.path, "/", files[j[[1]]]),
      ## No overwrite (!)
      overwrite = FALSE
    )
  })
  
})

## Copying common files (assuming non-subject specific)
commons <- grep(paste0("^(?!",id_pattern,")"),files, perl=TRUE)

lapply(commons, function(j) {
  file.copy(
    from = files.full[j[[1]]],
    to = paste0(data.destination, "/", files[j[[1]]]),
    overwrite = FALSE
  )
})
