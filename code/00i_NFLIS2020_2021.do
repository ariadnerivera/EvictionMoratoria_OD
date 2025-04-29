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

*Load dataset previously created by team

import delimited "LABPATH\MAIN DATA FILES\NFLIS Fentanyl\NFLIS_Metrics_2020.csv", clear 
rename statename StateName
rename year Year


save "..\data\2_intermediate\NFLIS2020.dta", replace


import delimited "LABPATH\NFLIS Fentanyl\NFLIS_Metrics_2021.csv", clear 
rename statename StateName
rename year Year


save "..\data\2_intermediate\NFLIS2021.dta", replace

append using "..\data\2_intermediate\NFLIS2020.dta"

save "..\data\2_intermediate\NFLIS2020_2021.dta", replace
