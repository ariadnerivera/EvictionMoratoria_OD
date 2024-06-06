* This code creates the median value of the OxCGRT indeces. This code should be 
* ran after 00_ Retrieve_OxCGRT_index.ipynb that creates file OxCGRT_US.dta


clear

pwd

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
use "../data/2_intermediate/OxCGRT_US.dta", clear

tab RegionName
rename RegionName StateName
replace StateName="District of Columbia"  if StateName=="Washington DC"
tostring Date, replace

* Substract year and month from the Date variable
gen YearMonth=substr(Date, 1, 6)

* Obtain median by month and state
collapse (median) StringencyIndex_Average GovernmentResponseIndex_Average ///
	ContainmentHealthIndex_Average EconomicSupportIndex, by(StateName YearMonth)

sort StateName YearMonth

destring YearMonth, replace

* Restrict to Months in 2020 and 2021 
keep if YearMonth<202201

* Save in intermediate folder
save "../data/2_intermediate/OxCGRT_mean_bystate_2020_2021.dta" , replace