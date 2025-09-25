library(tercen)
library(data.table)
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
na_string <- ctx$op.value('NA String', as.character, "")
force_merge <- ctx$op.value('Force', as.logical, FALSE)
add_namespace <- ctx$op.value('Add namespace', as.logical, FALSE)

separator <- case_when(
  separator == "Comma" ~ ",",
  separator == "Tab" ~ "\t"
)

# import files in Tercen
csv_list <- f.names %>%
  lapply(function(filename) {
    data <- tryCatch({
      fread(filename, header = headers, sep = separator, na.strings = na_string)
    }, error = function(e) {
      stop(paste0("Error reading file ", basename(filename), ": ", e$message))
    })

    if (!is.null(task)) {
      # task is null when run from RStudio
      actual = get("actual",  envir = .GlobalEnv) + 1
      assign("actual", actual, envir = .GlobalEnv)
      evt = TaskProgressEvent$new()
      evt$taskId = task$id
      evt$total = length(f.names)
      evt$actual = actual
      evt$message = paste0('Processing CSV file: ' , filename)
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

result = csv_list %>%
  rbindlist(fill = force_merge) %>%
  mutate_if(is.logical, as.character) %>% # Convert logical to character
  mutate_if(is.integer, as.double) %>% # Convert integer to double
  mutate(.ci = as.integer(rep_len(0, nrow(.)))) %>% # Add .ci column
  mutate(rowId = as.integer(seq(0, nrow(.)-1))) %>% # Add rowId column
  mutate(filename_of_zip = doc$name) # Add filename_of_zip column

if (add_namespace) {
  result = result %>% ctx$addNamespace()
}

result %>% ctx$save()
