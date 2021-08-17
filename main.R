library(tercen)
library(dplyr)

ctx = tercenCtx()

if (!any(ctx$cnames == "documentId")) stop("Column factor documentId is required")

# extract files
df <- ctx$cselect()

docId = df$documentId[1]
doc = ctx$client$fileService$get(docId)
filename = tempfile()
writeBin(ctx$client$fileService$download(docId), filename)
on.exit(unlink(filename))

# unzip if archive
if (length(grep(".zip", doc$name)) > 0) {
  tmpdir <- tempfile()
  unzip(filename, exdir = tmpdir)
  f.names <- list.files(tmpdir, full.names = TRUE)
} else {
  f.names <- filename
}

assign("actual", 0, envir = .GlobalEnv)
task = ctx$task

# import files in Tercen
f.names %>%
  lapply(function(filename){
    data = read.csv(filename, header = TRUE, sep = ",")
    if (!is.null(task)) {
      # task is null when run from RStudio
      actual = get("actual",  envir = .GlobalEnv) + 1
      assign("actual", actual, envir = .GlobalEnv)
      evt = TaskProgressEvent$new()
      evt$taskId = task$id
      evt$total = length(f.names)
      evt$actual = actual
      evt$message = paste0('processing csv file ' , filename)
      ctx$client$eventService$sendChannel(task$channelId, evt)
    } else {
      cat('processing csv file ' , filename)
    }
    data
  }) %>%
  bind_rows() %>%
  mutate_if(is.logical, as.character) %>%
  mutate_if(is.integer, as.double) %>%
  mutate(.ci = rep_len(0, nrow(.))) %>%
  mutate(filename = rep_len(basename(filename), nrow(.))) %>%
  ctx$addNamespace() %>%
  ctx$save()
