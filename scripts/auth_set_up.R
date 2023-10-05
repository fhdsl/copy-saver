#!/usr/bin/env Rscript

# Written by Candace Savonen Oct 2023
root_dir <- rprojroot::find_root(rprojroot::has_dir(".git"))

# Get auth interactively
googledrive::drive_deauth()
googledrive::drive_auth()

# Save the Token
token <- drive_token() 

saveRDS(token, file.path("data", "token.rds"))

# Make a key that is secret
# passphrase <- charToRaw("A SECRET PHRASE HERE THAT I HAVE STORED LOCALLY")
key <- openssl::sha256(passphrase)

### Encrypt the creds and save to RDS
default_creds <- serialize(readRDS(file.path("data", "token.rds")), NULL)

encrypted <- openssl::aes_cbc_encrypt(default_creds,
                                      key = key)

# Save to RDS that we will read 
saveRDS(encrypted, file.path("data", "encrypted_token.rds"))

