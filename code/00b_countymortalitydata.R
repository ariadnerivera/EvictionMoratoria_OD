rm(list=ls())

library(haven)
library(dplyr)

#Load mortality county-month data 
#load(file = "Z:/cerdam01labSpace/MAIN DATA FILES/CDC Wonder Mortality (Restricted)/Mort2020COPY.RData")

#Load overdose data by county from 2018-2020, county level data, by month.
od2017 <- read_dta("Z:/cerdam01labSpace/EvictionMoratoria_OD/AllOverdosesMonthlyCounty/ODDeathsByCountyOccurrence17.dta")
od2018 <- read_dta("Z:/cerdam01labSpace/EvictionMoratoria_OD/AllOverdosesMonthlyCounty/ODDeathsByCountyOccurrence18.dta")
od2019 <- read_dta("Z:/cerdam01labSpace/EvictionMoratoria_OD/AllOverdosesMonthlyCounty/ODDeathsByCountyOccurrence19.dta")
od2020 <- read_dta("Z:/cerdam01labSpace/EvictionMoratoria_OD/AllOverdosesMonthlyCounty/ODDeathsByCountyOccurrence20.dta")

#append all years
oddf <- rbind(od2017, od2018, od2019, od2020)

#Create a State variable
oddf$State <- oddf$StateOccurrenceFIPS

oodf <- rename(oddf, Year=year)
names(oodf)

#save file as a stata file
write_dta(oddf, "C:/Users/rivera30/OneDrive - NYU Langone Health/EvictionMoratoria_OD/data/2_intermediate/od_2017_2020.dta")

