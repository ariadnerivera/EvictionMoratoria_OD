
* Vaccination and community transmission data
* This code has to run after 00j_covidhospitalizations_vaccinations_communitytransmission.ipynb

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

 

*** Vaccinations 
use "../data/2_intermediate/vaccinations_dec2020_may2023.dta", clear

* Generate Year variable
gen Year = substr(date, 1, 4)

* Generate Month variable
gen Month = substr(date, 6, 2)

* Generate YearMonth variable to link with other datasets
gen YearMonth =  Year+Month

*destring mmwr_week, replace
*sort fips YearMonth mmwr_week

gen day = substr(date, 1, 10)
destring day, ignore("-") replace

egen double max_day = max(day), by(fips YearMonth)

*Check that the last day of the month is the max_day 
gen test=0
replace test=1 if max_day==day
tab date test
tab YearMonth test

keep if max_day==day

drop max_day test

* Check if I have duplicate counties by month 
egen id=group( fips YearMonth)
duplicates tag id, generate(dupl)

* Drop counties without county indentifier
drop if fips=="UNK"

gen geofips=fips

destring geofips, replace

*Drop PR
drop if geofips>=72000

destring YearMonth, replace

save "../data/2_intermediate/vaccinations_dec2020_may2023_clean.dta", replace

export delimited using "../data/2_intermediate/vaccinations_dec2020_may2023_clean.csv", replace

*Community transmission data
use "../data/2_intermediate/communitytransmisson_jan222020_oct182022.dta", clear

gen Year = substr(date, 1, 4)

gen Month = substr(date, 6, 2)

gen YearMonth =  Year+Month

destring percent_test_results_reported, replace

gen comtransmissioncat=.
replace comtransmissioncat=1 if community_transmission_level=="low"
replace comtransmissioncat=2 if community_transmission_level=="moderate"
replace comtransmissioncat=3 if community_transmission_level=="substantial"
replace comtransmissioncat=4 if community_transmission_level=="high"

replace cases_per_100k_7_day_count="" if cases_per_100k_7_day_count=="suppressed"
destring cases_per_100k_7_day_count, replace

destring cases_per_100k_7_day_count, ignore(",") replace

gen missing=0 
replace missing=1 if cases_per_100k_7_day_count==.

gen obs=1

destring fips_code, replace

replace fips_code=2261 if fips_code==2063 | fips_code==2066

*Obtain mean and median by month and county
collapse (mean) cases_per_100k_7_day_count percent_test_results_reported ///
	comtransmissioncat (sum) missing obs ///
	(median) medcases=cases_per_100k_7_day_count ///
	medpcttest=percent_test_results_reported ///
	medcomtranscat=comtransmissioncat, by (YearMonth fips_code)

	
drop if Year>="2022"

replace medpcttest=0 if YearMonth<"202003" & medpcttest==.

replace medpcttest=0 if medcases==0 & medpcttest==.

rename fips_code geofips
destring YearMonth, replace

save "../data/2_intermediate/communitytransmisson_2020_2021.dta", replace
