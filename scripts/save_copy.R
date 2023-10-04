#!/usr/bin/env Rscript

# This script collects all the quiz responses and puts them in one sheet

## Set up google credentials
googledrive::drive_auth(path = Sys.getenv("GOOGLE_AUTH_CREDS"))


# Load the libraries
library(tidyverse)
library(googledrive)

drive_id <- "https://drive.google.com/drive/folders/0AJb5Zemj0AAkUk9PVA"
folder_id <- drive_get(as_id(drive_id))

# all_files_df <- drive_find(shared_drive = as_id(drive_id))

#find files in folder
all_files <- drive_find(shared_drive = as_id(drive_id), type = "files") 

dir.create(paste0(lubridate::today(), "file-copies"), showWarnings = FALSE)

# download them all but no folder structure
lapply(all_files$id, function(file) {
    try({drive_download(file, path = )})
})


lubridate::today()