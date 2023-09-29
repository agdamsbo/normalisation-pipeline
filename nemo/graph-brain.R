## Wrapper to run the average_glassbrain.py script from the NeMo tool
## Search for relevant files in provided folder based on regex
graph_brain <-
  function(data.folder,
           file.pattern,
           id.pattern="",
           out.name="graph_chacoconn.png",
           parcellation=NULL, # Full path to the parcellation Nifti
           node.file, # Full path to the node file with with ROI coordinates; Nifti or txt
           node.view = "ortho",
           args.glass = NULL) {
    files.full <-
      list.files(data.folder, full.names = TRUE, recursive = TRUE)
    
    
    # Files subset by file name pattern to select correct data files
    file_p <- files.full[grepl(pattern = file.pattern, files.full)]
    
    # Files further subset by id name pattern to select specific ids only
    file_pi <- file_p[grep(pattern = id.pattern,file_p)]
    
    ## File names are exported to a file, seperated by single space
    writeLines(paste(file_pi, collapse = " "), "conns.txt")
    
    if (is.null(parcellation)){
      par.arg <- parcellation
    } else {
      par.arg <- paste("--bgparcellation",parcellation)
    }
    
    ## The average_glassprain.py script is run with provided extra arguments
    system(paste(
      "python3 nemo_save_average_graphbrain.py -o ",
      out.name,
      paste("--nodefile",node.file),
      paste("--nodeview",node.view),
      par.arg,
      " $(cat conns.txt)",
      paste(args.glass, collapse = " ")
    ))
    
    print(paste("Output file saved as",out.name))
  }


