* This code cleans unemployment from BLS LAUS county level data & the 
* Economic Perfomance Index

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

*****************************************************************************
* 							LAUS Data
*****************************************************************************

* This code has tu run after running 00_cleanunemploymentdata_bls.ipynb that 
* creates "unemp_blscounty_monthly_unemp.dta"


* Read county-level unemployment data

use "../data/2_intermediate/unemp_blscounty_monthly_unemp.dta", clear
destring geofips YearMonth, replace
keep geofips YearMonth lau_unemprate

*Restrict to study period
keep if YearMonth>201912 & YearMonth<202201

save "../data/2_intermediate/unemp_blscounty_monthly_unemp_clean.dta" , replace


clear 

*****************************************************************************
* 							County Economic Impact
*****************************************************************************

* Clean Economic Impact Index data was obtained from here: https://anl.app.box.com/s/q0e8ub9jzjyemg0x1y2clt01hkqxpg76
* Downloaded files were saved in \data\1_raw\County Economic Impact Index/

import excel using "../data/1_raw/County Economic Impact Index/CEII Year-Over-Year Data 20220919.xlsx", firstrow sheet("econ index") cellrange(A1:CL3222)

keep area_fips state county index*

destring area_fips, replace

* Drop jurstictions that are not US states/DC
drop if area_fips>57000

rename area_fips geofips
destring index_mar20 index_apr20, replace

rename index_jan20 index202001
rename index_feb20 index202002
rename index_mar20 index202003
rename index_apr20 index202004
rename index_may20 index202005
rename index_jun20 index202006
rename index_jul20 index202007
rename index_aug20 index202008
rename index_sep20 index202009
rename index_oct20 index202010
rename index_nov20 index202011
rename index_dec20 index202012
rename index_jan21 index202101
rename index_feb21 index202102
rename index_mar21 index202103
rename index_apr21 index202104
rename index_may21 index202105
rename index_jun21 index202106
rename index_jul21 index202107 
rename index_aug21 index202108
rename index_sep21 index202109 
rename index_oct21 index202110 
rename index_nov21 index202111
rename index_dec21 index202112

reshape long index, i(geofips) j(YearMonth)

rename index econimpactindex

save "..\data\2_intermediate\econimpactindex_clean.dta" , replace

