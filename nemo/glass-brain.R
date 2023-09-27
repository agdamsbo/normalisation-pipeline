## Wrapper to run the average_glassbrain.py script from the NeMo tool
## Search for relevant files in provided folder based on regex
glass_brain <-
  function(data.folder,
           file.pattern,
           id.pattern="",
           out.name,
           args.glass = NULL) {
    files.full <-
      list.files(data.folder, full.names = TRUE, recursive = TRUE)
    
    
    # Files subset by file name pattern to select correct data files
    file_p <- files.full[grepl(pattern = file.pattern, files.full)]
    
    # Files further subset by id name pattern to select specific ids only
    file_pi <- file_p[grep(pattern = id.pattern,file_p)]
    
    ## File names are exported to a file, seperated by single space
    writeLines(paste(file_pi, collapse = " "), "volumes.txt")
    
    ## The average_glassprain.py script is run with provided extra arguments
    system(paste(
      "python3 nemo/average_glassbrain.py -o ",
      out.name,
      " $(cat volumes.txt)",
      paste(args.glass, collapse = " ")
    ))
  }


