#!/usr/bin/env Rscript

# Written by Candace Savonen Oct 2023

if (!("optparse" %in% installed.packages())){
  install.packages("optparse")
}

# Load the libraries
library(tidyverse)
library(googledrive)
library(optparse)

option_list <- list(
  optparse::make_option(
    c("--key"),
    type = "character",
    default = NULL,
    help = "See auth_set_up.R for what you need to put here",
  )
)

# Read the arguments passed
opt_parser <- optparse::OptionParser(option_list = option_list)
opt <- optparse::parse_args(opt_parser)

# Establish root directory
root_dir <- rprojroot::find_root(rprojroot::has_dir(".git"))

passphrase <- charToRaw(opt$key)
key <- openssl::sha256(passphrase)

# Auth it
googledrive::drive_auth(
  email = "cansav09@gmail.com",
  scopes = "https://www.googleapis.com/auth/drive",
  cache = FALSE,
  use_oob = FALSE, 
  token = unserialize(
    openssl::aes_cbc_decrypt(
      readRDS(file.path("data", "encrypted_token.rds")),
      key = key)
    )
)

# Heres all the drives we need to copy
drive_ids <- c(
  "ITCR" = "https://drive.google.com/drive/folders/0AJb5Zemj0AAkUk9PVA",
  "DataTrail" = "https://drive.google.com/drive/folders/0ACLqJ0ovmCnQUk9PVA",
  "FHDaSL - Private" = "https://drive.google.com/drive/folders/0AHPjJcp83KzEUk9PVA",
  "FHDaSL - Public" = "https://drive.google.com/drive/folders/0AGS6SAWyjWbxUk9PVA",
  "GDSCN" = "https://drive.google.com/drive/folders/0AMoBC40Yf2maUk9PVA"
)

# Make as a data.frame
drive_ids_df <- data.frame(name = names(drive_ids), url = drive_ids)

# Make this function that will do the handling of everything
copy_all_drive <- function(name, url) {

# Get the info 
drive_info <- drive_get(as_id(drive_id))

# Make a folder for this copy with todays date in it
drive_folder_name <- paste0(lubridate::today(), "-", drive_info$name, "-copy")
dir.create(drive_folder_name, showWarnings = FALSE)

# Set up folder
all_files <- googledrive::drive_ls(as_id(drive_id), recursive = TRUE)
all_files$type <- sapply(all_files$drive_resource, function(id) id$mimeType)
all_files$parents <- sapply(all_files$drive_resource, function(id) unlist(id$parents))
all_files$parent_name <- sapply(all_files$parents, function(id) googledrive::drive_get(as_id(id))$name)
all_files$full_file_path <- all_files$name

# Extract only folder names
all_folder_ids <- all_files %>%
  dplyr::filter(type == "application/vnd.google-apps.folder") %>%
  dplyr::pull(id)


## Track down what the file path name is for each file
for (folder_id in all_folder_ids) {
  grandparent_filepath <- all_files %>%
    dplyr::filter(id == folder_id) %>%
    dplyr::pull(full_file_path)

  all_files <- all_files %>%
    dplyr::mutate(full_file_path = dplyr::case_when(
      folder_id == parents ~ file.path(grandparent_filepath, full_file_path),
      TRUE ~ full_file_path
    ))
}

# Now create all the folders
all_folder_paths <- all_files %>%
  dplyr::filter(type == "application/vnd.google-apps.folder") %>%
  dplyr::pull(full_file_path)

# Create them all
sapply(file.path(drive_folder_name, unique(all_folder_paths)), dir.create, recursive = TRUE, showWarning = FALSE)


# Dowload files to their respective file paths
only_files <- all_files %>%
  dplyr::mutate(abs_file_path = file.path(drive_folder_name, full_file_path)) %>% 
  dplyr::filter(type != "application/vnd.google-apps.folder") %>% 
  dplyr::select(abs_file_path, id)

purrr::pmap(only_files, function(id, abs_file_path) {
  try(googledrive::drive_download(as_id(id), path = abs_file_path, overwrite = TRUE))
})

zip(paste(drive_folder_name, ".zip"), drive_folder_name)

}

# Do the same for each drive
purrr::pmap(drive_ids_df[2:nrow(drive_ids_df), ], function(name, url) copy_all_drive(name, url))
