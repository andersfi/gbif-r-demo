###############################################################################
# Create download loop for GBIF data
# exampel with an array of country-codes

# intended use are when 
# i) downloads becomes to large to be practical, and / or
# ii) the predicaments/search strings either are impossible or slow to run 
# directly as API call (example; complex geometries over large spatial scales)
#
# The below code is a dummy-example that downloads GBIF data from Norway and 
# Sweden for pike (Esox lucius) and then select all records that have 
# basisOfRecord = HumanObervations. This exampel could off course have been done
# much quicker by a GBIF API call directly.
###############################################################################

#------------------------------------------------------------------------------
# Load libraries -----
#------------------------------------------------------------------------------
library(rgbif)
library(stringr)
library(rio)
library(dplyr)

#------------------------------------------------------------------------------
# Set a string to circle the loop over, in this case country codes-------------
#------------------------------------------------------------------------------

# load country codes of interest
# rgb_country_codes("Norway", fuzzy = TRUE) - example; help to find country codes
Country_codes <- c("NO","SE") # may possible also use GADMIN areas for this, but then with a different predicaament in the occ_download function 

#------------------------------------------------------------------------------
# Make a function for time-delay of asyncron download             -------------
#------------------------------------------------------------------------------
download_GBIF_API <- function(download_key,n_try,Sys.sleep_duration,destfile_name){
  start_time <- Sys.time()
  n_try_count <- 1
  
  download_url <- paste("http://api.gbif.org/v1/occurrence/download/request/",
                        download_key[1],sep="")
  
  try_download <- try(download.file(url=download_url,destfile=destfile_name,
                                    quiet=TRUE),silent = TRUE)
  
  while (inherits(try_download, "try-error") & n_try_count < n_try) {   
    Sys.sleep(Sys.sleep_duration)
    n_try_count <- n_try_count+1
    try_download <- try(download.file(url=download_url,destfile=destfile_name,
                                      quiet=TRUE),silent = TRUE)
    print(paste("trying... Download link not ready. Time elapsed (min):",
                round(as.numeric(paste(difftime(Sys.time(),start_time, units = "mins"))),2)))
  }
}


#------------------------------------------------------------------------------
# set user_name, e-mail, and pswd as global options first 
# NB: modify if not running through rstudio
#------------------------------------------------------------------------------

# set user_name, e-mail, and pswd as global options first
# NB: modify if not running through rstudio
options(gbif_user=rstudioapi::askForPassword("my gbif username"))
options(gbif_email=rstudioapi::askForPassword("my registred gbif e-mail"))
options(gbif_pwd=rstudioapi::askForPassword("my gbif password"))



################################################################################
# Make a loop to circulate the call over
# store data in two objects ("occ_output" for the data, and "citations" for citations)
################################################################################
occ_output <- data.frame()
occ_citations <- as.character()

for (i in 1:length(Country_codes)){
  
  # Spin of download i 
  download_key <- occ_download(pred('hasCoordinate' , 'TRUE'),
                               pred('hasGeospatialIssue' , 'FALSE'),
                               pred('country' , Country_codes[i]),
                               pred('taxonKey' , '2346633'),
                               type="and") %>% occ_download_meta
  
  # get download i
  # note the usage of asyncron download function defined above
  tmpfile <- tempfile()
  tmpdir <- tempdir()
  download_GBIF_API(download_key=download_key,n_try=15,Sys.sleep_duration=60, destfile_name=tmpfile)
  

  # This downloads the data in form of a DwC archive, extract the occurrence part
  # on the fly unzip and import to R object
  occurrences <- rio::import(unzip(tmpfile,files="occurrence.txt",exdir = tmpdir))  
  
  # do some arbitrary filtering and store output 
  occ_output_tmp <- occurrence %>%
    filter(basisOfRecord=="HUMAN_OBSERVATION") %>% 
    select(gbifID,decimalLongitude,decimalLatitude,coordinateUncertaintyInMeters,year,taxonKey,dynamicProperties) %>%
   mutate(download_select_i=Country_codes[i])
  occ_output <- bind_rows(occ_output, occ_output_tmp)
  
  # Finally, but not least important - Citation 
  occ_citations[i] <- paste("GBIF Occurrence Download", download_key[2], "accessed via GBIF.org on", Sys.Date())
}


