* Create a new variable with the values formatted as dates

import delimited "C:\Users\rivera30\OneDrive - NYU Langone Health\EvictionMoratoria_OD\data\2_intermediate\cusp.csv", case(preserve) clear

foreach var of varlist STEMERG-EMEND3 INITIATIONBANSTART-WVDEAREQ {
	replace `var'=substr(`var',1,10)
	replace `var'="" if `var'=="^"
	}

foreach var of varlist STEMERG-EMEND3 INITIATIONBANSTART-WVDEAREQ {
	gen d`var' = date(`var',"YMD")
	format d`var' %d
	}

	
rename STATE StateName	
rename FIPS StateFIPS 
rename POSTCODE StateAbbreviation

save "C:\Users\rivera30\OneDrive - NYU Langone Health\EvictionMoratoria_OD\data\2_intermediate\cusp_datesfmt.dta", replace
