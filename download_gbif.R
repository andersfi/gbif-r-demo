###############################################################################
# Search, download and parse occurrence data from GBIF
###############################################################################

# procedure
# a) Find species 
# b) Construct quiery and request download key
# c) Download and save data
# d) Create data.frame

#------------------------------------------------------------------------------
# Load libraries -----
#------------------------------------------------------------------------------
library(rgbif)
library(stringr)
library(rio)
library(dplyr)

#------------------------------------------------------------------------------
# Asyncronous download using the rgibf package  -----------------------------------
#------------------------------------------------------------------------------


# Find taxon key - get list of gbif key's to filter download
key <- name_suggest(q='Esox lucius', rank='species')$key[1] 
key2 <- name_suggest(q='Actinopterygii', rank='class')$key[1] 
key3 <- name_suggest(q='Carassius carassius', rank='species')$key[1]

# paste("https://www.gbif.org/species/",key3,sep="") gives you the homepage of the species

# Get callback key from GBIF API and construct download url. 
# set user_name, e-mail, and pswd as global options first
# NB: modify if not running through rstudio
options(gbif_user=rstudioapi::askForPassword("my gbif username"))
options(gbif_email=rstudioapi::askForPassword("my registred gbif e-mail"))
options(gbif_pwd=rstudioapi::askForPassword("my gbif password"))

# Get download key. NB! Maximum of 3 download request handled simultaniusly
download_key <- occ_download('taxonKey = 2346633,2366645','hasCoordinate = TRUE',
                         'hasGeospatialIssue = FALSE',
                         'country = NO',
                         'geometry = POLYGON((9.33 62.80,9.33 64.20,12.13 64.20,12.13 62.80,9.33 62.80))',
                         type="and") %>% occ_download_meta

# Automatize the process: Script for calling the download at regular interval
# - download_key from occ_download, n_try=number of trials before giving up, 
# Sys.sleep_duration=time in seconds between each trial (adjust after the expected size of the download)

source("https://gist.githubusercontent.com/andersfi/1e7cd54cf4d12e86f0ecc66effd86129/raw/0d40d1971427aecd0c469c062c0693320392435b/download_from_GBIF_key")
download_GBIF_API(download_key=download_key,n_try=5,Sys.sleep_duration=15)

# Or, wait for e-mail or watch on GBIF portal: https://www.gbif.org/user/download and: 
# The download key will be shown as lasts part of the url e.g. https://www.gbif.org/occurrence/download/0003580-171002173027117
download.file(url=paste("http://api.gbif.org/v1/occurrence/download/request/",
                        download_key[1],sep=""),
              destfile=paste(download_key[1],".zip",sep=""),
              quiet=FALSE)

# This downloads the data in form of a DwC archive 
unzip(paste(download_key[1],".zip",sep=""),exdir=paste(getwd(),"/unzipped",sep=""))
name <- unzip(paste(download_key[1],".zip",sep=""),list=TRUE)$Name

# load to dataframe (using import from rio)
occurrence <- import(paste(getwd(),"/unzipped/occurrence.txt",sep=""))

# Finally, but not least important - Citation 
paste("GBIF Occurrence Download", download_key[2], "accessed via GBIF.org on", Sys.Date())

