* Code to obtain % votes per party in the 2016 elections data
* Data originally obtained from: https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/VOQCHQ 
* Used the version published Jan 9, 2024 


clear

*****************************************************************************
* 							Structure of folders
*****************************************************************************

*	EvictionMoratoria_OD/
*	|-	code      # Where the scripts are stored
*	|-	data      # Data files organized as follows
*	|	|-	1_raw	# All files as obtained from the source
*		|-	2_intermediate 	# All intermediate dataset
*		|-	3_analytic		# Analytic datasets created	

* Make sure the structure of folders are as above. This script should be in
* EvictionMoratoria_OD/code/

* Check working directory 

pwd

* If not int the correct working directory then cd "~/EvictionMoratoria_OD/code"


*   The data was previously downoloaded and saved in 
*	/data/1_raw/elections/PresidentialElectionReturns/


*	Load dataset 
import delimited "../data/1_raw/elections/PresidentialElectionReturns/countypres_2000-2020.csv", case(preserve) clear

keep if year==2016

gen demvotes=candidatevotes if party=="DEMOCRAT"
gen repvotes=candidatevotes if party=="REPUBLICAN"
gen othervotes=candidatevotes if party!="DEMOCRAT" & party!="REPUBLICAN"

keep state state_po county_fips candidatevotes totalvotes demvotes repvotes othervotes

collapse (sum) demvotes repvotes othervotes (mean) totalvotes, by(state state_po county_fips)

gen check=demvotes+repvotes+othervotes

gen pct_repvotes=(repvotes/totalvotes)*100
gen pct_demvotes=(demvotes/totalvotes)*100
gen pct_othervotes=(othervotes/totalvotes)*100


replace county_fips="" if county_fips=="NA"

destring county_fips, replace

rename county_fips geofips
replace geofips=11001 if state_po=="DC"

keep demvotes repvotes othervotes totalvotes pct_demvotes pct_repvotes ///
	pct_othervotes geofips
	
	
* AK districts do not match county boundaries, will impute AK with state average
* Check why 36000 is in the data 
* HI county 15005 does not have election data 

	
*Drop RI federal precinct
drop if geofips==.

rename pct_repvotes pct_repvotes2016
rename pct_demvotes pct_demvotes2016 
rename pct_othervotes pct_othervotes2016

drop demvotes repvotes othervotes totalvotes

save "../data/2_intermediate/county_presidentialelectionreturns2016.dta", replace

****************************************************************************
****** Create state-level election data

import delimited "../data/1_raw/elections/PresidentialElectionReturns/countypres_2000-2020.csv", case(preserve) clear

keep if year==2016

replace county_fips="" if county_fips=="NA"

destring county_fips, replace

gen demvotes=candidatevotes if party=="DEMOCRAT"
gen repvotes=candidatevotes if party=="REPUBLICAN"
gen othervotes=candidatevotes if party!="DEMOCRAT" & party!="REPUBLICAN"

keep state state_po county_fips candidatevotes totalvotes demvotes repvotes othervotes

collapse (sum) demvotes repvotes othervotes (mean) totalvotes, by(state state_po county_fips)

rename county_fips geofips
replace geofips=11001 if state_po=="DC"

gen str5 GEOID = string(geofips,"%05.0f")
gen StateFIPS =substr(GEOID, 1,2)

destring StateFIPS, replace

order StateFIPS, first


*check has to be equal to totalvotes
bysort StateFIPS: egen totalvotes_state=total(totalvotes)
bysort StateFIPS: egen demvotes_state=total(demvotes)
bysort StateFIPS: egen repvotes_state=total(repvotes)
bysort StateFIPS: egen othervotes_state=total(othervotes)

collapse (mean) totalvotes_state demvotes_state repvotes_state othervotes_state, by(StateFIPS)

gen pct_repvotes_state=(repvotes_state/totalvotes_state)*100
gen pct_demvotes_state=(demvotes_state/totalvotes_state)*100
gen pct_othervotes_state=(othervotes_state/totalvotes_state)*100

rename pct_repvotes_state pct_repvotes_state2016
rename pct_demvotes_state pct_demvotes_state2016
rename pct_othervotes_state pct_othervotes_state2016

drop totalvotes_state demvotes_state repvotes_state othervotes_state

save "../data/2_intermediate/state_presidentialelectionreturns2016.dta", replace