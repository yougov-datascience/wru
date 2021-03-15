rm(list = ls())
library(wru)
library(stringr)
library(pROC)
library(dplyr)

# read in the data
ncData <- read.csv("/Users/evanrosenman/Documents/GitHub/wru/NC Voter File/ncvoter_Statewide_sample.csv")

# merge in the county FIPS codes
fipsMapping <- read.csv("/Users/evanrosenman/Documents/GitHub/wru/NC Voter File/FIPS Mapping.csv")
fipsMapping$County <- toupper(fipsMapping$County)
ncData <- merge(ncData, fipsMapping, by.x = "county_desc", by.y = "County")

# formulate the race data
ncData <- ncData[!(ncData$race_code == "U" & ncData$ethnic_code != "HL"),]
ncData$race <- ifelse(ncData$race_code %in% c("A", "B", "W"), ncData$race_code,
               ifelse(ncData$ethnic_code == "HL", "H", "O"))

# WRU approach
preds.wru <- predict_race(voter.file = 
           data.frame(surname = ncData$last_name, state = "nc", 
                      county = str_pad(ncData$Code, 3, side = "left", pad = "0")),
                      census.geo = "county", census.key = "2591cffde26d4140c933bd42f6faaf983a902dd7")
rocAucs.base <- c("white" = as.numeric(auc(roc(as.numeric(ncData$race == "W"), preds.wru$pred.whi))),
  "black" = as.numeric(auc(roc(as.numeric(ncData$race == "B"), preds.wru$pred.bla))),
  "hisp" = as.numeric(auc(roc(as.numeric(ncData$race == "H"), preds.wru$pred.his))),
  "aapi" = as.numeric(auc(roc(as.numeric(ncData$race == "A"), preds.wru$pred.asi))),
  "other" = as.numeric(auc(roc(as.numeric(ncData$race == "O"), preds.wru$pred.oth))))
rocAucs.base

# pull data for enhanced results
censusData <- get_census_data(states = "nc", census.geo = "county", key = "2591cffde26d4140c933bd42f6faaf983a902dd7")$NC$county

lastNames <- read.csv("/Users/evanrosenman/Documents/GitHub/wru/NC Voter File/nameRatios_full_last_noNC.csv")
lastNames$Total <- rowSums(lastNames[,-1])
lastNames <- lastNames[!is.na(iconv(lastNames$Name, "UTF-8", "UTF-8")),]
lastRatios <- data.frame(cbind(apply(lastNames[,-c(1, ncol(lastNames))], 2, FUN = function(x) {x/lastNames$Total}), Total = lastNames$Total))
lastRatios$LastName <- tolower(lastNames$Name)

firstNames <- read.csv("/Users/evanrosenman/Documents/GitHub/wru/NC Voter File/nameRatios_full_first_noNC.csv")
firstNames$Total <- rowSums(firstNames[,-1])
firstNames <- firstNames[!is.na(iconv(firstNames$Name, "UTF-8", "UTF-8")),]
firstRatios <- data.frame(cbind(apply(firstNames[,-c(1, ncol(firstNames))], 2, FUN = function(x) {x/firstNames$Total}), Total = firstNames$Total))
firstRatios$FirstName <- tolower(firstNames$Name)

ncData$last_name <- tolower(ncData$last_name)
ncData$first_name <- tolower(ncData$first_name)

# merge the data
ncData <- merge(ncData, lastRatios, by.x = "last_name", by.y = "LastName", all.x = TRUE)
ncData <- merge(ncData, firstRatios, by.x = "first_name", by.y = "FirstName", all.x = TRUE, suffixes = c(".last", ".first"))

ncData$paddedCounty <- str_pad(ncData$Code, 3, side = "left", pad = "0")
ncData <- merge(ncData, censusData, by.x = "paddedCounty", by.y = "county")

# generate the preds for last only
ncData$pred.whi.last <- ncData$r_whi * coalesce(ncData$White.Self.Reported.last, 1) 
ncData$pred.bla.last <- ncData$r_bla * coalesce(ncData$African.or.Af.Am.Self.Reported.last, 1) 
ncData$pred.his.last <- ncData$r_his * coalesce(ncData$Hispanic.last, 1) 
ncData$pred.asi.last <- ncData$r_asi * coalesce(ncData$East.Asian.last, 1) 
ncData$pred.oth.last <- ncData$r_oth * coalesce(ncData$Other.Undefined.Race.last, 1) 

denominators.last <- rowSums(ncData[,c("pred.whi.last", "pred.bla.last", "pred.his.last", "pred.asi.last", "pred.oth.last")])
ncData$pred.whi.last <- ncData$pred.whi.last/denominators.last
ncData$pred.bla.last <- ncData$pred.bla.last/denominators.last
ncData$pred.his.last <- ncData$pred.his.last/denominators.last
ncData$pred.asi.last <- ncData$pred.asi.last/denominators.last
ncData$pred.oth.last <- ncData$pred.oth.last/denominators.last

# generate the preds for first and last
ncData$pred.whi.both <- ncData$r_whi * coalesce(ncData$White.Self.Reported.last, 1) * coalesce(ncData$White.Self.Reported.first, 1)
ncData$pred.bla.both <- ncData$r_bla * coalesce(ncData$African.or.Af.Am.Self.Reported.last, 1) * coalesce(ncData$African.or.Af.Am.Self.Reported.first, 1)
ncData$pred.his.both <- ncData$r_his * coalesce(ncData$Hispanic.last, 1) * coalesce(ncData$Hispanic.first, 1)
ncData$pred.asi.both <- ncData$r_asi * coalesce(ncData$East.Asian.last, 1) * coalesce(ncData$East.Asian.first, 1)
ncData$pred.oth.both <- ncData$r_oth * coalesce(ncData$Other.Undefined.Race.last, 1) * coalesce(ncData$Other.Undefined.Race.first, 1)

denominators.both <- rowSums(ncData[,c("pred.whi.both", "pred.bla.both", "pred.his.both", "pred.asi.both", "pred.oth.both")])
ncData$pred.whi.both <- ncData$pred.whi.both/denominators.both
ncData$pred.bla.both <- ncData$pred.bla.both/denominators.both
ncData$pred.his.both <- ncData$pred.his.both/denominators.both
ncData$pred.asi.both <- ncData$pred.asi.both/denominators.both
ncData$pred.oth.both <- ncData$pred.oth.both/denominators.both

rocAucs.enhanced.last <- c("white" = as.numeric(auc(roc(as.numeric(ncData$race == "W"), ncData$pred.whi.last))),
                           "black" = as.numeric(auc(roc(as.numeric(ncData$race == "B"), ncData$pred.bla.last))),
                           "hisp" = as.numeric(auc(roc(as.numeric(ncData$race == "H"), ncData$pred.his.last))),
                           "aapi" = as.numeric(auc(roc(as.numeric(ncData$race == "A"), ncData$pred.asi.last))),
                           "other" = as.numeric(auc(roc(as.numeric(ncData$race == "O"), ncData$pred.oth.last))))

rocAucs.enhanced.both <- c("white" = as.numeric(auc(roc(as.numeric(ncData$race == "W"), ncData$pred.whi.both))),
                  "black" = as.numeric(auc(roc(as.numeric(ncData$race == "B"), ncData$pred.bla.both))),
                  "hisp" = as.numeric(auc(roc(as.numeric(ncData$race == "H"), ncData$pred.his.both))),
                  "aapi" = as.numeric(auc(roc(as.numeric(ncData$race == "A"), ncData$pred.asi.both))),
                  "other" = as.numeric(auc(roc(as.numeric(ncData$race == "O"), ncData$pred.oth.both))))

barplot(100*rbind(both = rocAucs.enhanced.both, 
                  last = rocAucs.enhanced.last,
                  wru = rocAucs.base), beside = TRUE, xlab = "Ethnic Group",
        ylab = "ROC AUC", legend = TRUE, main = "Prediction Improvements: NC Sample")
