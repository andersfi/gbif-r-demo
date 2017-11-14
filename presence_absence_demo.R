############################################################################################
# download dataset https://www.gbif.org/dataset/40bfac0e-a1b5-4c9e-862e-64327195f210
# Spread data to presence/absence by event according to occurrenceStatus
############################################################################################

# Download as Darwin Core archive.
# Download as data after GBIF interpretation will fail due to missing fields
# Citation: GBIF Occurrence Download doi:10.15468/dl.7s1c2n accessed via GBIF.org on 14 Nov 2017
temp <- tempfile()
download.file(url=paste("http://api.gbif.org/v1/occurrence/download/request/0000906-171113114016250"),
              destfile=temp,quiet=FALSE)
evdata <- read.table(unz(temp, "occurrence.txt"),sep="\t",header=T)
str(evdata) # oki, here we have what we need

#-------------------------------------------------------------
# reshape data to wide format by event ----------------------
#-------------------------------------------------------------
library(tidyr)
library(dplyr)
library(stringr)

# one problem directly transforming to wide dataformat directly is that
# there may be several occurrences of one species per event.
evdata$occurrenceStatus_num <- ifelse(evdata$occurrenceStatus=="present",1,0)
evdata2 <- evdata %>%
  group_by(eventID,scientificName) %>%
  summarize(occurrenceStatus=sum(occurrenceStatus_num))
evdata2$occurrenceStatus <- ifelse(evdata2$occurrenceStatus>0,1,0)
# spread data ---
# first get cannonical names to be used as col headers
evdata2$scientificName2 <- stringr::str_replace(evdata2$scientificName," ","_")
evdata2$scientificName2 <- stringr::word(evdata2$scientificName2)

spread_data <- evdata2 %>%
  select(-scientificName) %>%
  spread(key=scientificName2,value=occurrenceStatus,fill=NA)

# get eventDate, samplingProtocol etc..
evdata_tmp <- distinct(evdata[c("eventID","samplingProtocol","eventDate")])
spread_data <- left_join(spread_data,evdata_tmp, by="eventID")

#-------------------------------------------------------------
# Get additiona habitat data for occupancy modelling ---------
#
# Appears to be encoded in the eventID. Go to orginal dataset
# endpoint to get measurment and fact table...
#
#-------------------------------------------------------------


