
******* Covid 19 cases
import delimited "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_confirmed_US.csv", delim(",") clear


*drop data for Jan2021 onwards
drop v357-v873
drop if fips<1000

egen YearMonth202001 = rowtotal(v12-v21)
egen YearMonth202002 = rowtotal(v22-v50)
egen YearMonth202003 = rowtotal(v51-v81)
egen YearMonth202004 = rowtotal(v82-v111)
egen YearMonth202005 = rowtotal(v112-v142)
egen YearMonth202006 = rowtotal(v143-v172)
egen YearMonth202007 = rowtotal(v173-v203)
egen YearMonth202008 = rowtotal(v204-v234)
egen YearMonth202009 = rowtotal(v235-v264)
egen YearMonth202010 = rowtotal(v265-v295)
egen YearMonth202011 = rowtotal(v296-v325)
egen YearMonth202012 = rowtotal(v326-v356)

keep if fips!=.
keep fips YearMonth202001-YearMonth202012

reshape long YearMonth, i(fips) j(YearMonth2)
rename YearMonth CovidCases
rename YearMonth2 YearMonth
rename fips geofips
drop if geofips>70000

save "C:\Users\rivera30\OneDrive - NYU Langone Health\EvictionMoratoria_OD\data\2_intermediate\CountyCovidCases_JanDec2020.dta", replace

****** Covid 19 deaths
import delimited "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_US.csv", delim(",") clear
drop v358-v874
drop if fips<1000

egen YearMonth202001 = rowtotal(v13-v22)
egen YearMonth202002 = rowtotal(v23-v51)
egen YearMonth202003 = rowtotal(v52-v82)
egen YearMonth202004 = rowtotal(v83-v112)
egen YearMonth202005 = rowtotal(v113-v143)
egen YearMonth202006 = rowtotal(v144-v173)
egen YearMonth202007 = rowtotal(v174-v204)
egen YearMonth202008 = rowtotal(v205-v235)
egen YearMonth202009 = rowtotal(v236-v265)
egen YearMonth202010 = rowtotal(v266-v296)
egen YearMonth202011 = rowtotal(v297-v326)
egen YearMonth202012 = rowtotal(v327-v357)

keep if fips!=.
keep fips YearMonth202001-YearMonth202012

reshape long YearMonth, i(fips) j(YearMonth2)
rename YearMonth CovidDeaths
rename YearMonth2 YearMonth
rename fips geofips
drop if geofips>70000

save "C:\Users\rivera30\OneDrive - NYU Langone Health\EvictionMoratoria_OD\data\2_intermediate\CountyCovidDeaths_JanDec2020.dta", replace

