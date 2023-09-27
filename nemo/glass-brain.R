## Wrapper to run the average_glassbrain.py script from the NeMo tool
## Search for relevant files in provided folder based on regex
glass_brain <-
  function(data.folder,
           file.pattern,
           out.name,
           args.glass = NULL) {
    files.full <-
      list.files(data.folder, full.names = TRUE, recursive = TRUE)
    
    file.paths <-
      paste(files.full[grepl(pattern = file.pattern, files.full)], collapse = " ")
    writeLines(file.paths, "volumes.txt")
    
    system(paste(
      "python3 nemo/average_glassbrain.py -o ",
      out.name,
      " $(cat volumes.txt)",
      paste(args.glass, collapse = " ")
    ))
  }


