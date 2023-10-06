nemo_collect <- function(data.folder, 
                         id.pattern,
                         file.pattern,
                         roi.names
){
  files <- list.files(data.folder,full.names = TRUE)
  foi <- grep(pattern = file.pattern,files)
  
  # Files subset by file name pattern to select correct data files
  files_p <- files[foi]
  
  # Files further subset by id name pattern to select specific ids only
  files_pi <- files_p[grep(pattern = file.pattern,files_p)]
  
  df <- data.frame(do.call(rbind, lapply(files_pi, function(i) {
    read.csv(i, sep = "\t", header = FALSE)
  })))
  
  colnames(df) <- roi.names
  
  if (id.pattern!=""){
    ids <- sub(paste0(".*?(",id.pattern,").*$"),"\\1",files_pi)
  } else {ids <- LETTERS[seq_along(files_pi)]}
  
  data.frame(id=ids,df)
}
