
## Simple wrapper function to find relevant files in subfolders based on regex pattern
## Passes files to "un-pikler", which just leaves un-pikled files in same dir as original

unpkl_sparse <-
  function(data.folder,
           file.pattern) {
    files.full <-
      list.files(data.folder, full.names = TRUE, recursive = TRUE)
    
    file.paths <-
      paste(files.full[grepl(pattern = file.pattern, files.full)], collapse = " ")
    writeLines(file.paths, "pkls.txt")
    
    system("python3 nemo/unpkl_sparse.py $(cat pkls.txt)")
  }

