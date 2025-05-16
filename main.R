library(mtercen)
library(teRcenHttp)
library(tercenApi)
library(tercen)
library(dplyr)

ctx = tercenCtx()

if (!any(ctx$cnames == "documentId")) stop("Column factor documentId is required.")

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
  f.names <- list.files(tmpdir, full.names = TRUE, recursive = TRUE)
} else {
  f.names <- filename
}

assign("actual", 0, envir = .GlobalEnv)
task = ctx$task

headers <- ctx$op.value('Headers', as.logical, TRUE)
separator <- ctx$op.value('Separator', as.character, "Tab")
force_merge <- ctx$op.value('Force', as.logical, FALSE)

separator <- case_when(
  separator == "Comma" ~ ",",
  separator == "Tab" ~ "\t"
)

# import files in Tercen
csv_list <- f.names %>%
  lapply(function(filename) {
    data <- read.csv(filename, header = headers, sep = separator)  
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
      ctx$log(paste0('Processing CSV file: ' , filename))
    }
    data %>%
      mutate(filename = rep_len(basename(filename), nrow(.)))
  })

same_colnames <- all(sapply(csv_list, function(x) identical(colnames(x), colnames(csv_list[[1]]))))
if(!same_colnames & !force_merge) {
  stop("All files must have strictly identical column names or the 'Force' option should be set to true.")
}

csv_list %>%
  bind_rows() %>%
  mutate_if(is.logical, as.character) %>%
  mutate_if(is.integer, as.double) %>%
  mutate(.ci = as.integer(rep_len(0, nrow(.)))) %>%
  mutate(rowId = as.integer(seq(0, nrow(.)-1))) %>%
  mutate(filename_of_zip = doc$name) %>%
  ctx$addNamespace() %>%
  ctx$save()
