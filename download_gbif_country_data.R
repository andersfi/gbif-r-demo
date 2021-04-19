###############################################################################
# Search and download GBIF data from one or multipel countries based upon
# an array of country-codes
###############################################################################

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

# load country codes of interest
# rgb_country_codes("Norway", fuzzy = TRUE) - for help to find country codes
Country_codes <- c("NO","SE") # may possible also use GADMIN areas for this, but then with a different predicaament in the occ_download function 


# Get callback key from GBIF API and construct download url. 
# set user_name, e-mail, and pswd as global options first
# NB: modify if not running through rstudio
options(gbif_user=rstudioapi::askForPassword("my gbif username"))
options(gbif_email=rstudioapi::askForPassword("my registred gbif e-mail"))
options(gbif_pwd=rstudioapi::askForPassword("my gbif password"))


####### at this point make a loop for going through all country-codes of interest ... 

for i in 1:length(Country_codes){
  # Get download key. NB! Maximum of 3 download request handled simultaneously
  download_key <- occ_download(pred('hasCoordinate' , 'TRUE'),
                               pred('hasGeospatialIssue' , 'FALSE'),
                               pred('country' , Country_codes[i]),
                               pred('taxonKey' , '2346633'),
                               type="and") %>% occ_download_meta
  
  # Automatize the process: Script for calling the download at regular interval
  # - download_key from occ_download, n_try=number of trials before giving up, 
  # Sys.sleep_duration=time in seconds between each trial (adjust after the expected size of the download)
  source("https://gist.githubusercontent.com/andersfi/1e7cd54cf4d12e86f0ecc66effd86129/raw/0d40d1971427aecd0c469c062c0693320392435b/download_from_GBIF_key")
  download_GBIF_API(download_key=download_key,n_try=5,Sys.sleep_duration=15)
  
  # Or, wait for e-mail or watch on GBIF portal: https://www.gbif.org/user/download and: 
  # The download key will be shown as lasts part of the url e.g. https://www.gbif.org/occurrence/download/0003580-171002173027117
#  download.file(url=paste("http://api.gbif.org/v1/occurrence/download/request/",
#                          download_key[1],sep=""),
#                destfile=paste(download_key[1],".zip",sep=""),
#                quiet=FALSE)
  
  # This downloads the data in form of a DwC archive 
  unzip(paste(download_key[1],".zip",sep=""),exdir=paste(getwd(),"/unzipped",sep=""))
  name <- unzip(paste(download_key[1],".zip",sep=""),list=TRUE)$Name
  
  # load to dataframe (using import from rio)
  occurrence <- import(paste(getwd(),"/unzipped/occurrence.txt",sep=""))
  occ_output <- occurrence %>%
    filter(basisOfRecord=="HUMAN_OBSERVATION")
  
  # Finally, but not least important - Citation 
  paste("GBIF Occurrence Download", download_key[2], "accessed via GBIF.org on", Sys.Date())
}


