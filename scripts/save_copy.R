#!/usr/bin/env Rscript

root_dir <- rprojroot::find_root(rprojroot::has_dir(".git"))

authenticate <- function() {
    googledrive::drive_deauth()
    token <- googledrive::drive_auth(
      email = "cansav09@gmail.com",
      path = NULL,
      scopes = "https://www.googleapis.com/auth/drive",
      # Get new token if it doesn't exist
      cache = ".secrets/",
      use_oob = FALSE,
      token = NULL
    )
    token <- drive_token() 
    
}

# Load the libraries
library(tidyverse)
library(googledrive)

drive_ids <- list(
  "https://drive.google.com/drive/folders/0AJb5Zemj0AAkUk9PVA",
  "https://drive.google.com/drive/folders/0ACLqJ0ovmCnQUk9PVA",
  "https://drive.google.com/drive/folders/0AHPjJcp83KzEUk9PVA",
  "https://drive.google.com/drive/folders/0AGS6SAWyjWbxUk9PVA",
  "https://drive.google.com/drive/folders/0AMoBC40Yf2maUk9PVA"
  )

drive_id <- drive_ids[[1]]
drive_info <- drive_get(as_id(drive_id))

drive_folder_name <- paste0(lubridate::today(), drive_info$name, "-copy")

dir.create(drive_folder_name , showWarnings = FALSE)

# Set up folder
all_files <- googledrive::drive_ls(as_id(drive_id), recursive = TRUE)
all_files$type <- sapply(all_files$drive_resource, function(id) id$mimeType)
all_files$parents <- sapply(all_files$drive_resource, function(id) unlist(id$parents))
all_files$parent_name <- sapply(all_files$parents, function(id) googledrive::drive_get(as_id(id))$name)
all_files$full_file_path <-  all_files$name

# Extract only folder names 
all_folder_ids <- all_files %>% 
  dplyr::filter(type == "application/vnd.google-apps.folder")  %>% 
  dplyr::pull(id)


## Track down what the file path name is for each file
for (folder_id in all_folder_ids) {
  
  grandparent_filepath <- all_files %>% 
    dplyr::filter(name == folder) %>% 
    dplyr::pull(full_file_path) 

  all_files <- all_files %>% 
    dplyr::mutate(full_file_path = dplyr::case_when( 
      folder_id == parents ~ file.path(grandparent_filepath, full_file_path), 
      TRUE ~ full_file_path
      ))
}

# Now create all the folders
all_folder_paths <- all_files %>% 
  dplyr::filter(type == "application/vnd.google-apps.folder")  %>% 
  dplyr::pull(full_file_path) 

# Create them all
sapply(unique(all_folder_paths), dir.create, recursive = TRUE, showWarning = FALSE)


try(googledrive::drive_download(as_id(file_id), overwrite = TRUE)))



