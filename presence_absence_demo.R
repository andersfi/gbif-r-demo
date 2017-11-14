############################################################################################
# download dataset https://www.gbif.org/dataset/c684b43a-0147-459b-ae97-0e3d9757fb92
# Spread data to presence/absence by event according to occurrenceStatus
############################################################################################

# First tried download as data after GBIF interpretation
# Citation: GBIF Occurrence Download doi:10.15468/dl.dm359q accessed via GBIF.org on 14 Nov 2017
temp <- tempfile()
download.file(url=paste("http://api.gbif.org/v1/occurrence/download/request/0000810-171113114016250"),
              destfile=temp,quiet=FALSE)
data <- read.table(unz(temp, "0000810-171113114016250.csv"),sep="\t",header=T)
str(data) # fails: does not contain the fields we need to interpret in terms of sampling-event


# Download as Darwin Core archive ------
# Citation: GBIF Occurrence Download doi:10.15468/dl.7s1c2n accessed via GBIF.org on 14 Nov 2017
temp <- tempfile()
download.file(url=paste("http://api.gbif.org/v1/occurrence/download/request/0000818-171113114016250"),
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




