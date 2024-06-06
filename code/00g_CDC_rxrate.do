* CDC's opioid dispensing rate
* The data canbe retrieved from here: https://www.cdc.gov/overdose-prevention/data-research/facts-stats/opioid-dispensing-rate-maps.html?CDC_AAref_Val=https://www.cdc.gov/drugoverdose/rxrate-maps/opioid.html

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

import delimited "../data/1_raw/County Opioid Dispensing Rates.csv", clear 
keep if year==2020 | year==2021

rename state_county geofips
rename year Year

*Drop 1 case has null values, corresponds 
drop if opioid_dispensing_rate=="null"

destring opioid_dispensing_rate, replace 
rename opioid_dispensing_rate rxrate

save "../data/2_intermediate/rxrate_2020_2021.dta", replace