* CDC's opioid dispensing rate
* The 2023 Rural-Urban Continuum Codes from here: https://www.ers.usda.gov/data-products/rural-urban-continuum-codes/
* and saved in data/1_raw

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


import excel "../data/1_raw/Ruralurbancontinuumcodes2023.xlsx", sheet("Rural-urban Continuum Code 2023") firstrow clear

destring FIPS, replace
rename FIPS geofips

gen metro=0
replace metro=1 if inrange(RUCC_2023, 1,3)

keep geofips metro RUCC_2023

save "../data/2_intermediate/Ruralurbancontinuumcodes2023.dta", replace