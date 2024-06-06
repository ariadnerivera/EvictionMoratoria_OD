* Code to prepare NSDUH data
* Data originally obtained from:
* 2019NSDUHsaeExcelCSVs(zip | 101.08 KB) in https://www.samhsa.gov/data/report/2018-2019-nsduh-state-prevalence-estimates
* 2021-2022 State Prevalence Tables: CSV (zip | 123.75 KB) in https://www.samhsa.gov/data/report/2021-2022-nsduh-state-prevalence-estimates
* Each zip folder was previously unzipped and saved in 1_raw folder


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


* Create a folder within 2_intermediat folder to save NSDUH extracted vars
mkdir "../data/2_intermediate/nsduh" // new folder name is nsduh

********
* 2018-2019 NSDUHs
********

* Substance use disorder prevalences are on Table 23. Substance Use Disorder in 
* the Past Year, by Age Group and State: Percentages, 
* Annual Averages Based on 2018 and 2019 NSDUHs  

import delimited "../data/1_raw/2019NSDUHsaeExcelCSVs/NSDUHsaeExcelTab23-2019.csv", rowrange(7) clear 

rename v2 StateName
rename v3 sud12plus
rename v15 sud18plus
rename v12 sud26plus

drop in 1/6

* Keep only state observations
keep State sud12plus sud18plus sud26plus

*Creat year variable
gen Year=2019

*Remove % character 
replace sud12plus = subinstr(sud12plus, "%", "",.)  
replace sud18plus = subinstr(sud18plus, "%", "",.)  
replace sud26plus = subinstr(sud26plus, "%", "",.)  

destring sud12plus sud18plus sud26plus, replace

*Save sud 2019 in the nsduh folder
save "../data/2_intermediate/nsduh/sud_2019.dta", replace 


* Need but not receiving treatment prevalences are obtained from Table 26. 
* Needing But Not Receiving Treatment at a Specialty Facility for Substance Use 
* in the Past Year, by Age Group and State: Percentages, Annual Averages Based 
* on 2018 and 2019 NSDUHs  


* Repeat steps but for "need but not receiving treatment" vars
import delimited "../data/1_raw/2019NSDUHsaeExcelCSVs/NSDUHsaeExcelTab26-2019.csv", rowrange(6) clear 

rename v2 StateName
rename v3 needtrx12plus
rename v15 needtrx18plus
rename v12 needtrx26plus

drop in 1/6

keep State needtrx12plus needtrx18plus needtrx26plus

gen Year=2019

replace needtrx12plus = subinstr(needtrx12plus, "%", "",.)  
replace needtrx18plus = subinstr(needtrx18plus, "%", "",.)  
replace needtrx26plus = subinstr(needtrx26plus, "%", "",.)  

destring needtrx12plus needtrx18plus needtrx26plus, replace

save "../data/2_intermediate/nsduh/needtrx_2019.dta", replace 


* Any mental illness prevalence obtained from Table 27. Any Mental Illness in 
* the Past Year, by Age Group and State: Percentages, Annual Averages 
* Based on 2018 and 2019 NSDUHs  

* Repeat steps but for "any mental illmness" vars
import delimited "../data/1_raw/2019NSDUHsaeExcelCSVs/NSDUHsaeExcelTab27-2019.csv", rowrange(6) clear 

rename v2 StateName
rename v3 anymentaldx18plus
rename v9 anymentaldx26plus

drop in 1/6

 
keep StateName anymentaldx18plus anymentaldx26plus

replace anymentaldx18plus = subinstr(anymentaldx18plus, "%", "",.)  
replace anymentaldx26plus = subinstr(anymentaldx26plus, "%", "",.)  

destring anymentaldx18plus anymentaldx26plus , replace
gen Year=2019


save "../data/2_intermediate/nsduh/anymentaldx2019.dta", replace 

* Merge any mental illness, need tx but not receiving, and sud 

merge 1:1 StateName using "../data/2_intermediate/nsduh/needtrx_2019.dta", nogenerate
merge 1:1 StateName using "../data/2_intermediate/nsduh/sud_2019.dta", nogenerate

save "../data/2_intermediate/nsduh/NSDUH2019.dta", replace 


********
* 2021-2022 NSDUHs
********

* Substance use disorder from Table 25. Substance Use Disorder in the Past Year: 
* Among People Aged 12 or Older; by Age Group and State, Percentages, 2021

import delimited "../data/1_raw/2021NSDUHsaeExcelTabsCSVs110322/NSDUHsaeExcelTab25-2021.csv", rowrange(7) clear

rename v2 StateName
rename v3 sud12plus
rename v15 sud18plus
rename v12 sud26plus

drop in 1/6

keep State sud12plus sud18plus sud26plus
gen Year=2021


replace sud12plus = subinstr(sud12plus, "%", "",.)  
replace sud18plus = subinstr(sud18plus, "%", "",.)  
replace sud26plus = subinstr(sud26plus, "%", "",.)  

destring sud12plus sud18plus sud26plus, replace


save "../data/2_intermediate/nsduh/sud_2021.dta", replace 

* Need but not receiving treatment from Table 28. Needing But Not Receiving 
* Treatment at a Specialty Facility for Substance Use in the Past Year: Among 
* People Aged 12 or Older; by Age Group and State, Percentages, 2021
import delimited "../data/1_raw/2021NSDUHsaeExcelTabsCSVs110322/NSDUHsaeExcelTab28-2021.csv", rowrange(8) clear 

rename v2 StateName
rename v3 needtrx12plus
rename v15 needtrx18plus
rename v12 needtrx26plus

drop in 1/6

keep State needtrx12plus needtrx18plus needtrx26plus
gen Year=2021

replace needtrx12plus = subinstr(needtrx12plus, "%", "",.)  
replace needtrx18plus = subinstr(needtrx18plus, "%", "",.)  
replace needtrx26plus = subinstr(needtrx26plus, "%", "",.)  

destring needtrx12plus needtrx18plus needtrx26plus, replace

save "../data/2_intermediate/nsduh/needtrx_2021.dta", replace 


* Any mental illness from Table 29. Any Mental Illness in the Past Year: Among 
* People Aged 18 or Older; by Age Group and State, Percentages, 2021
import delimited "../data/1_raw/2021NSDUHsaeExcelTabsCSVs110322/NSDUHsaeExcelTab29-2021.csv", rowrange(6) clear 

rename v2 StateName
rename v3 anymentaldx18plus
rename v9 anymentaldx26plus

drop in 1/6

 
keep StateName anymentaldx18plus anymentaldx26plus

replace anymentaldx18plus = subinstr(anymentaldx18plus, "%", "",.)  
replace anymentaldx26plus = subinstr(anymentaldx26plus, "%", "",.)  

destring anymentaldx18plus anymentaldx26plus , replace
gen Year=2021

save "../data/2_intermediate/nsduh/anymentaldx2021.dta", replace 

* Merge 2021 NSDUH data
merge 1:1 StateName using "../data/2_intermediate/nsduh/needtrx_2021.dta", nogenerate
merge 1:1 StateName using "../data/2_intermediate/nsduh/sud_2021.dta", nogenerate

save "../data/2_intermediate/nsduh/NSDUH2021.dta", replace

***
append using "../data/2_intermediate/nsduh/NSDUH2019.dta"

order StateName Year, first

save "../data/2_intermediate/nsduh/NSDUH_2019_2021.dta" , replace

* Change to wide format
reshape wide anymentaldx18plus anymentaldx26plus needtrx12plus ///
	needtrx26plus needtrx18plus sud12plus sud26plus ///
	sud18plus, i(StateName) j(Year)

save "../data/2_intermediate/nsduh/NSDUH_2019_2021_wide.dta" , replace
