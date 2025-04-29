library(haven)
library(dplyr)

#Load overdose data by county from 2018-2020, county level data, by month.
#Data was previously extracted from the restricted-use files, this code only creates a longitudinal dataset

od2017 <- read_dta("LABPATH/EvictionMoratoria_OD/AllOverdosesMonthlyCounty/ODDeathsByCountyOccurrence17.dta")
od2018 <- read_dta("LABPATH/EvictionMoratoria_OD/AllOverdosesMonthlyCounty/ODDeathsByCountyOccurrence18.dta")
od2019 <- read_dta("LABPATH/EvictionMoratoria_OD/AllOverdosesMonthlyCounty/ODDeathsByCountyOccurrence19.dta")
od2020 <- read_dta("LABPATH/EvictionMoratoria_OD/AllOverdosesMonthlyCounty/ODDeathsByCountyOccurrence20.dta")
od2021 <- read_dta("LABPATH/EvictionMoratoria_OD/AllOverdosesMonthlyCounty/ODDeathsByCountyOccurrence21.dta")

#append all years
oddf <- rbind(od2017, od2018, od2019, od2020, od2021)

#Create a State variable
oddf$State <- oddf$StateOccurrenceFIPS

oodf <- rename(oddf, Year=year)
names(oodf)

#save file as a stata file
write_dta(oddf, "./data/2_intermediate/od_2017_2021.dta")

