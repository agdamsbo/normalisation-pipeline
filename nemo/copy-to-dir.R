## Wrapper function to copy files from subfolders to new folder
copy_to_dir <-
  function(source.folder,
           file.pattern,
           dir.name = "temp",
           recursive = FALSE,
           overwrite = TRUE) {
    sub.dirs <- list.dirs(source.folder, recursive = recursive)
    
    mni.files <-
      do.call(c,
              lapply(
                sub.dirs,
                list.files,
                pattern = file.pattern,
                full.names = TRUE
              ))
    mni.files.short <-
      do.call(c, lapply(sub.dirs, list.files, pattern = file.pattern))
    
    temp.dir <- paste0(source.folder, "/", dir.name)
    if (!dir.exists(temp.dir)) {
      dir.create(temp.dir)
    }
    
    lapply(seq_along(mni.files), function(i) {
      file.copy(mni.files[i],
                paste0(temp.dir, "/", mni.files.short[i]),
                overwrite = overwrite)
    })
  }