* Set wd

cd "C:\Users\rivera30\OneDrive - NYU Langone Health\EvictionMoratoria_OD"

* Load Dataset
import delimited ".\data\2_intermediate\cusp.csv", case(preserve) clear

* Rename geo vars so these are consistent with other databases	
rename STATE StateName	
rename FIPS StateFIPS 
rename POSTCODE StateAbbreviation

*name in db 20EBSTART
rename v181 EB20START

*name in db 20EBEND
rename v182 EB20END

*name in db 20EBSTART2
rename v183 EB20START2

*name in db 20EBEND2
rename v184 EB20END2

keep STEMERG-END_BSNS FM_ALL FM_ALL2 FM_EMP-FM_END2 FMSCHOOLBAN FMLOCALBAN ///
	STOPFMBAN ALCREST ALCDELIV ENDREST ENDGYM-VAC_PLAN EMSTART EMEND ///
	EMSTART2 EMEND2 EMSTART3 EMEND3 INITIATIONBANSTART-UREND TLHLAUD TLHLMED ///
	ELECPRCR ENDELECP ELECNOSTART ELECPRCR2 ENDELECP2 EBSTART EBEND EBSTART2 ///
	EBEND2 TLHlBUPR-CASOPEN2 EB20START-EB20END2 StateName StateAbbreviation StateFIPS

* Create a new variable with the values formatted as dates
	
foreach var of varlist STEMERG-CASOPEN2 {
	replace `var'=substr(`var',1,10)
	replace `var'="" if `var'=="^"
	}

foreach var of varlist STEMERG-CASOPEN2 {
	gen d`var' = date(`var',"YMD")
	format d`var' %d
	}

 
save ".\data\2_intermediate\cusp_datesfmt.dta", replace

* Create dataset for correlation
	
foreach var of varlist STEMERG-CASOPEN2 {
		gen dummy_`var'= d`var'
		replace dummy_`var'=1 if d`var'!=. 
		replace dummy_`var'=0 if dummy_`var'==.
	}

	

keep StateAbbreviation dummy_EMSTART dummy_EMEND dummy_STEMERG2 dummy_CLSCHOOL dummy_CLDAYCR dummy_INITIATIONBANSTART dummy_HEARINGBANSTART dummy_ENFORCEBANSTART dummy_C19START dummy_PAYSTART dummy_CARESSTART dummy_CDCSTART dummy_LATESTART dummy_SMSTART dummy_URSTART dummy_TLHlBUPR dummy_EXTOPFL dummy_HMDLVOP dummy_TLHLCL24 dummy_EXCEMORP dummy_WVDEAREQ dummy_ELECPRCR dummy_STAYHOME dummy_TLHLMED dummy_EBSTART


renpfix dummy_

save ".\data\2_intermediate\cusp_dummypol_state.dta", replace

