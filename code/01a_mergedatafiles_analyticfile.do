* This code finalizes data preparation and creates analytic file 

clear

*****************************************************************************
* 							Structure of folders
*****************************************************************************

*	EvictionMoratoria_OD/
*	|-	code      # Where the scripts are stored
*	|-	data      # Data files organized as follows
*	|	|-	1_raw			# All files as obtained from the source
*		|-	2_intermediate 	# All intermediate dataset
*		|-	3_analytic		# Analytic datasets created	
*	|-	Results   # Where results are stored

* Make sure the structure of folders are as above. This script should be in
* EvictionMoratoria_OD/code/

* Check working directory 

pwd

******************************************************************************
*				Overdose county-level data from 2017 to 2021                 *
******************************************************************************

* This section creates final county overdose death data that can be merged with
* the other dataset.The overdose data was retrieved and extracted previously 
* from the restricted-use mortality files


* Load county-level dataset
use "..\data\2_intermediate\od_2017_2021.dta", clear

gen statename=State
merge m:1 statename using "..\data\1_raw\2_states_fips.dta"
drop _merge

gen str2 StateFIPS = string( fipscode ,"%02.0f")
drop fipscode

gen geofips=StateFIPS+CountyOccurrenceFIPS
destring geofips, replace

rename year Year

* Some county changes made so these can be merged with ACS data

* Shannon County, South Dakota (46-113)
 *Changed name and code to Oglala Lakota County (46-102) effective May 1, 2015.
replace geofips=46102 if geofips==46113
 
*Wade Hampton Census Area, Alaska (02-270)
*Changed name and code to Kusilvak Census Area (02-158) effective July 1, 2015.
replace geofips=2158 if geofips==2270

* Create YearMonth variable
tostring Year, replace

gen YearMonth=Year+MonthDeath
destring YearMonth, replace
destring StateFIPS, replace
destring Year, replace


* Keep only data 2020-2021
tab Year
keep if Year>=2020
tab Year

save "..\data\2_intermediate\od_2020_2021_geofips.dta", replace


******************************************************************************
*		   				Demographic data prep for merging              		 *
******************************************************************************

*This is the dataset created with 00c_ACSCounydata.ipynb
import delimited "..\data\2_intermediate\acs_2019_2021.csv", case(preserve) clear 

drop v1 Unnamed0

*Drop PR
drop if geofips>=72000

* Chugach Census Area, Alaska (02-063): Created from part of former 
* Valdez-Cordova Census Area (02-261) effective January 02, 2019.

* Copper River Census Area, Alaska (02-066): Created from part of former 
* Valdez-Cordova Census Area (02-261) effective January 02, 2019.

* Need to combine 02-063 & 02-066
replace geofips=2261 if geofips==2063 | geofips==2066

collapse (sum) totpop pop18under pop18_34 pop35to64 pop65plus popfemale popNH ///
	popNHWhite popNHBlack popNHAIAN popNHAsian popNHAPI popNHOther ///
	popNH2plus popHispanic renterocchousingunits onepers_renterhu ///
	twopers_renterhu threepers_renterhu fourpers_renterhu fivepers_renterhu ///
	sixpers_renterhu sevenpluspers_renterhu pop25plus lessHS highschool ///
	highschoolplus pop16plus popunemp households householdsSSI housholdsPAI hhlowquintile ///
	hhsecondquintile hhthirdquintile hhfourthquintile hhfifthquintile ///
	vacanthu vacanthurent vacanthusale vacanthuother poprenterhousing ///
	renterhu occroomhalfless occroomhalfto1 occroom1to1half ///
	occroom1halftotwo occroom2plus rent30to49 rent50plus ///
	poppoovertystatus popinpoverty popatorabovepoverty families ///
	ratioincpovunder2 ratioincpov2to3 ratioincpov3to4 ratioincpov4to5 ///
	ratioincpov5plus popcivnoninspop popwithouthealthins pophealthins ///
	publichealthins privatehealthins area ///
	(mean) mhhinc gini, by(geofips Year StateFIPS)

xtset geofips Year

*Lag vars for overcrowding and other housing variables

gen L_occroomhalfless = l.occroomhalfless
gen L_occroomhalfto1 = l.occroomhalfto1
gen L_occroom1to1half = l.occroom1to1half
gen L_occroom1halftotwo = l.occroom1halftotwo
gen L_occroom2plus = l.occroom2plus
gen L_renterhu = l.renterhu

* ACS data is annual, this creates a monthly dataset	
expand 12
bysort geofips Year : gen group_index = _n
gen str2 MonthNum = string( group_index ,"%02.0f")

* Create pct variables
foreach V of varlist pop18under pop18_34 pop35to64 pop65plus popfemale popNH ///
	popNHWhite popNHBlack popHispanic {
     gen pct_`V'=(`V'/totpop)*100
}

gen pct_popNHOther=((popNHAIAN+popNHAsian+popNHAPI+popNHOther+popNH2plus)/totpop)*100

gen pct_HSplus = ((highschool+highschoolplus)/pop25plus)*100
gen pct_unemp=  (popunemp/pop16plus)*100
gen pct_hhssinc = (householdsSSI/households)*100
gen pct_hhpai = (housholdsPAI/households)*100
gen pct_poprenterhu = (poprenterhousing/totpop)*100
gen pct_poppoverty = (popinpoverty/ poppoovertystatus)*100
gen pct_rent30to49 = (rent30to49/renterhu)*100
gen pct_rent50plus = (rent50plus/renterhu)*100
gen pct_pophealthins = (pophealthins/popcivnoninspop)*100


gen str5 fipscode = string( geofips ,"%05.0f")


******************************************************************************
*		   				Merge with RUCC data        	               		 *
******************************************************************************

*************************************************
* Add rural-urban codes
* The Rural Urban Continuum Codes come from 
* https://www.ers.usda.gov/data-products/rural-urban-continuum-codes/ 


*This RUCC data is for 2003 and 2013
merge m:1 fipscode using "..\data\2_intermediate\RUCC.dta"


*Information on county boundary changes: https://www.census.gov/programs-surveys/geography/technical-documentation/county-changes.2010.html#list-tab-957819518 

replace RUCC_2013=6 if fipscode=="46102"
replace RUCC_2003=7 if fipscode=="46102"

replace RUCC_2013=9 if fipscode=="02158"
replace RUCC_2003=9 if fipscode=="02158"


drop if _merge==2

drop pop2010 RUCC_2003 pop2000 metro2013 metro2003 _merge

gen metro2013=0
replace metro2013=1 if RUCC_2013!=. & RUCC_2013<4

tostring Year, replace

gen YearMonth=Year+MonthNum

destring YearMonth, replace

drop MonthNum

destring Year, replace
drop if Year==2019

* Updated to include RUCC 2023, uses Census 2020 data
merge m:1 geofips using "..\data\2_intermediate\Ruralurbancontinuumcodes2023.dta"

drop if geofips>60000

* Connecticut had several county boundary changes. The crosswalk can be found here: https://www.census.gov/programs-surveys/geography/technical-documentation/county-changes.html 

* If the counties are now a mix of metro/non-metro counties, replace with 2013 measure
tab metro if geofips==9120 | geofips==9140 | geofips==9190
replace metro=1 if geofips==9001

tab geofips metro if geofips==9110 | geofips==9140 | geofips==9160
tab metro2013 if geofips==9003
replace metro=1 if geofips==9003

tab geofips metro if geofips==9140 | geofips==9160
tab metro2013 if geofips==9005
replace metro=0 if geofips==9005

tab geofips metro if geofips==9130
replace metro=1 if geofips==9007

tab geofips metro if geofips==9140 | geofips==9170
replace metro=1 if geofips==9009

tab geofips metro if geofips==9130 | geofips==9150 | geofips==9180
tab metro2013 if geofips==9011
replace metro=1 if geofips==9011

tab geofips metro if geofips==9110 | geofips==9150
tab metro2013 if geofips==9013
replace metro=1 if geofips==9013

tab geofips metro if geofips==9180 | geofips==9150
tab metro2013 if geofips==9015
replace metro=1 if geofips==9015


* Chugach Census Area, Alaska (02-063): Created from part of former 
* Valdez-Cordova Census Area (02-261) effective January 02, 2019.

* Copper River Census Area, Alaska (02-066): Created from part of former 
* Valdez-Cordova Census Area (02-261) effective January 02, 2019.

* Need to combine 02-063 & 02-066
replace metro=0 if geofips==2261

drop if _merge==2
drop _merge

save "..\data\2_intermediate\acs_county_2020_2021_clean.dta", replace


******************************************************************************
*		   				Create state-level demographic variables           	 *
******************************************************************************


*** The demographic datafile is created in 00c_ACSCountyData.ipynb
import delimited "..\data\2_intermediate\acs_2019_2021.csv", case(preserve) clear 

*import delimited "2_intermediate\acs_2020_2021.csv", case(preserve) clear 
drop v1 Unnamed0

drop if geofips>=72000

* Chugach Census Area, Alaska (02-063): Created from part of former 
* Valdez-Cordova Census Area (02-261) effective January 02, 2019.

* Copper River Census Area, Alaska (02-066): Created from part of former 
* Valdez-Cordova Census Area (02-261) effective January 02, 2019.

* Need to combine 02-063 & 02-066
replace geofips=2261 if geofips==2063 | geofips==2066


collapse (sum) totpop pop18under pop18_34 pop35to64 pop65plus popfemale popNH ///
	popNHWhite popNHBlack popNHAIAN popNHAsian popNHAPI popNHOther ///
	popNH2plus popHispanic renterocchousingunits onepers_renterhu ///
	twopers_renterhu threepers_renterhu fourpers_renterhu fivepers_renterhu ///
	sixpers_renterhu sevenpluspers_renterhu pop25plus lessHS highschool ///
	highschoolplus pop16plus popunemp households householdsSSI housholdsPAI hhlowquintile ///
	hhsecondquintile hhthirdquintile hhfourthquintile hhfifthquintile ///
	vacanthu vacanthurent vacanthusale vacanthuother poprenterhousing ///
	renterhu occroomhalfless occroomhalfto1 occroom1to1half ///
	occroom1halftotwo occroom2plus rent30to49 rent50plus ///
	poppoovertystatus popinpoverty popatorabovepoverty families ///
	ratioincpovunder2 ratioincpov2to3 ratioincpov3to4 ratioincpov4to5 ///
	ratioincpov5plus popcivnoninspop popwithouthealthins pophealthins ///
	publichealthins privatehealthins area ///
	(mean) mhhinc gini, by(geofips Year StateFIPS)

xtset geofips Year

*Lag vars for overcrowding
gen L_occroomhalfless = l.occroomhalfless
gen L_occroomhalfto1 = l.occroomhalfto1
gen L_occroom1to1half = l.occroom1to1half
gen L_occroom1halftotwo = l.occroom1halftotwo
gen L_occroom2plus = l.occroom2plus
gen L_renterhu = l.renterhu
	
drop if Year==2019

collapse (sum) totpop pop18under pop18_34 pop35to64 pop65plus popfemale popNH ///
	popNHWhite popNHBlack popNHAIAN popNHAsian popNHAPI popNHOther ///
	popNH2plus popHispanic renterocchousingunits onepers_renterhu ///
	twopers_renterhu threepers_renterhu fourpers_renterhu fivepers_renterhu ///
	sixpers_renterhu sevenpluspers_renterhu pop25plus lessHS highschool ///
	highschoolplus pop16plus popunemp households householdsSSI housholdsPAI hhlowquintile ///
	hhsecondquintile hhthirdquintile hhfourthquintile hhfifthquintile ///
	vacanthu vacanthurent vacanthusale vacanthuother poprenterhousing ///
	renterhu occroomhalfless occroomhalfto1 occroom1to1half ///
	occroom1halftotwo occroom2plus rent30to49 rent50plus ///
	poppoovertystatus popinpoverty popatorabovepoverty families ///
	ratioincpovunder2 ratioincpov2to3 ratioincpov3to4 ratioincpov4to5 ///
	ratioincpov5plus popcivnoninspop popwithouthealthins pophealthins ///
	publichealthins privatehealthins area L_occroomhalfless L_occroomhalfto1 ///
	L_occroom1to1half L_occroom1halftotwo L_occroom2plus L_renterhu ///
	(mean) mhhinc gini, by(Year StateFIPS)


* Create percentage variables
foreach V of varlist pop18under pop18_34 pop35to64 pop65plus popfemale popNH ///
	popNHWhite popNHBlack popHispanic {
     gen pct_`V'_state=(`V'/totpop)*100
}

gen pct_popNHOther_state=((popNHAIAN+popNHAsian+popNHAPI+popNHOther+popNH2plus)/totpop)*100

gen pct_HSplus_state= ((highschool+highschoolplus)/pop25plus)*100 /* universe is pop 25+ */
gen pct_unemp_state=  (popunemp/pop16plus)*100 /* universe is pop 16+ */
gen pct_hhssinc_state = (householdsSSI/households)*100
gen pct_hhpai_state = (housholdsPAI/households)*100

gen pct_poprenterhu_state = (poprenterhousing/totpop)*100

gen pct_poppoverty_state = (popinpoverty/ poppoovertystatus)*100
gen pct_rent30to49_state = (rent30to49/renterhu)*100
gen pct_rent50plus_state = (rent50plus/renterhu)*100
gen pct_pophealthins_state = (pophealthins/popcivnoninspop)*100

foreach var of varlist totpop-gini {
	rename `var' `var'_state
}


save "..\data\2_intermediate\acs_state_2020_2021_clean.dta", replace



******************************************************************************
*		   			COVID-19 Eviction Housing Policy Scorecard 	           	 *
******************************************************************************

* Convert score file from csv to dta
* Data source: https://evictionlab.org/covid-policy-scorecard/#scorecard-resources 
import delimited "..\data\1_raw\EvictionMoraltoriaRating_EvictionLab.csv", clear 
rename state State
label variable State ""
xtile elrating_tertile = el_rating if el_rating>0, nquantiles(3)

save "..\data\2_intermediate\evictionmoratoriarating.dta", replace



******************************************************************************
******************************************************************************
******************************************************************************
*		   					Merge data 							           	 *
******************************************************************************
******************************************************************************
******************************************************************************

* Demographic data 
*use ".\2_intermediate\acs_county_2020_2021_clean.dta", clear 
use "..\data\2_intermediate\acs_county_2019_2021_clean.dta", clear 

destring Year, replace
*tostring YearMonth, replace 
*gen Year=substr(YearMonth, 1,4)
*destring Year YearMonth, replace

* Merge with state ACS data
merge m:1 StateFIPS Year using "..\data\2_intermediate\acs_state_2020_2021_clean.dta"
drop _merge

* Merge with overdose data
merge m:1 geofips YearMonth using "..\data\2_intermediate\od_2020_2021_geofips.dta"

*1657 counties did not have overdose death data
rename _merge odmissing
replace ODDeathOccurrenceCount=0 if ODDeathOccurrenceCount==.

* CUSP policy data
destring StateFIPS, replace
merge m:1 StateFIPS using "..\data\2_intermediate\cusp_datesfmt.dta"

drop _merge

replace State=StateAbbreviation if State==""

merge m:1 State using "..\data\2_intermediate\evictionmoratoriarating.dta"
drop _merge State

* We have a list of 3,142 counties
gen	DayEnd=31 if MonthDeath=="01"
replace	DayEnd=28 if MonthDeath=="02"
replace	DayEnd=31 if MonthDeath=="03"
replace	DayEnd=30 if MonthDeath=="04"
replace	DayEnd=31 if MonthDeath=="05"
replace	DayEnd=30 if MonthDeath=="06"
replace	DayEnd=31 if MonthDeath=="07"
replace	DayEnd=31 if MonthDeath=="08"
replace	DayEnd=30 if MonthDeath=="09"
replace	DayEnd=31 if MonthDeath=="10"
replace	DayEnd=30 if MonthDeath=="11"
replace	DayEnd=31 if MonthDeath=="12" 

gen	DayStart=1 

*gen days of the month
*4,6,9,11
gen daysmonth=30 if MonthDeath=="04" | MonthDeath=="06" | ///
	MonthDeath=="09" | MonthDeath=="11"s

replace daysmonth=31 if MonthDeath=="01" | MonthDeath=="03" ///
	| MonthDeath=="05" | MonthDeath=="07"| MonthDeath=="08" ///
	| MonthDeath=="10" | MonthDeath=="12"

* February 2020 leap year
replace daysmonth=29 if MonthDeath=="02" & Year==2020

destring MonthDeath Year, replace

gen Date = mdy(MonthDeath, DayStart, Year) 
format Date %d

*Fix issue with Date variable, counties do not have info
preserve
keep Date geofips YearMonth StateFIPS daysmonth
collapse (mean) Date daysmonth, by(StateFIPS YearMonth)

replace daysmonth=28 if YearMonth==202102
rename Date Date2
rename daysmonth daysmonth2
save "..\data\2_intermediate\Date2.dta", replace
restore

merge m:1 StateFIPS YearMonth using "..\data\2_intermediate\Date2.dta"
replace Date=Date2 if Date==.
replace daysmonth=daysmonth2 if daysmonth==.

drop Date2 _merge daysmonth2

* Create proportion of variables formatted as dates
foreach var of varlist dSTEMERG-dCASOPEN2 {
	gen p`var'=`var'
	replace p`var'=1-[(`var'-Date)/daysmonth]
	replace p`var'=1 if Date>=`var' & `var'!=. & (p`var'<0 | p`var'>=1)
	replace p`var'=0 if Date< `var' & p`var'>=1
	replace p`var'=0 if p`var'<0
	}
	
foreach var of varlist  STEMERG-CASOPEN2 {
	rename pd`var' p`var'
	}
	
*gen Month = string(MonthDeath, "%02.0f")
*tostring Year, replace

*gen YearMonth=Year+Month
tostring YearMonth Year, replace
gen Month =substr(YearMonth, 5,6)


preserve
collapse (mean) pSTEMERG-pCASOPEN2, by(StateAbbreviation StateFIPS Year Month)
keep if Year>="2020"
drop if Year=="2020" & (Month=="01" | Month=="02" | Month=="03")

save "..\data\2_intermediate\cusp_state_pol.dta", replace

restore

*drop dSTEMERG-dWVDEAREQ


** Create a variable Moratoria for the months or proportion of the month
** each state had a moratoria (turn off, turn on, turn off... variable)
*First moratoria start date
gen Moratoria=pEMSTART 
replace Moratoria=1-pEMEND if pEMSTART>0 & pEMEND!=0
replace Moratoria=pEMSTART2 if pEMEND!=0 & pEMSTART2!=0
replace Moratoria=1-pEMEND2 if  pEMSTART2!=0 & pEMEND2!=0 
replace Moratoria=pEMSTART3 if pEMEND2!=0 & pEMSTART3!=0
replace Moratoria=1-pEMEND3 if  pEMSTART3!=0 & pEMEND3!=0 

* Create separate variables for each moratorium

* First moratorium
gen Moratoria1=pEMSTART
replace Moratoria1=abs(Moratoria-pEMEND) if pEMSTART>0 & pEMEND!=0
replace Moratoria1=. if pEMEND>0 | pEMEND!=0

* Second moratorium
gen Moratoria2=pEMSTART2 if pEMEND!=0 & pEMSTART2!=0
replace Moratoria2=abs(Moratoria2-pEMEND2) if  pEMSTART2!=0 & pEMEND2!=0 
replace Moratoria2=. if pEMEND2>0 | pEMEND2!=0

* Third moratorium
gen Moratoria3=pEMSTART3 if pEMEND2!=0 & pEMSTART3!=0
replace Moratoria3=(abs(Moratoria-pEMEND3)) if  pEMSTART3!=0 & pEMEND3!=0 
replace Moratoria3=. if pEMEND3>0 | pEMEND3!=0

replace Moratoria2=0 if Moratoria2==.
replace Moratoria3=0 if Moratoria3==.

sort YearMonth

egen TimeCont=group(YearMonth)
gen MoratoriaEver=pEMSTART
replace MoratoriaEver=1 if pEMSTART>0

gen _mend=month(dEMSTART) 

gen timeToTreat = MonthDeath - _mend if YearMonth>"202001"

destring YearMonth, replace

*** Merge covid cases
merge 1:1 geofips YearMonth using "..\data\2_intermediate\CountyCovidCases_NewCum_Jan2020Dec2021.dta"
drop _merge

*** Merge covid deaths
merge 1:1 geofips YearMonth using "..\data\2_intermediate\CountyCovidDeaths_NewCum_Jan2020Dec2021.dta"

drop _merge

* State level covid variables 
*merge m:1 StateFIPS YearMonth using  ".\2_intermediate\StateCovidDeathsCases_Jan2020_Dec2021.dta"
merge m:1 StateFIPS YearMonth using  "..\data\2_intermediate\StateCovidDeathsCases_NewCum_Jan2020_Dec2021.dta"

drop _merge 

*** Merge with 2016 elections data 
merge m:1 geofips using "..\data\2_intermediate\county_presidentialelectionreturns2016.dta"
drop if _merge==2
drop _merge 

merge m:1 StateFIPS using "..\data\2_intermediate\state_presidentialelectionreturns2016.dta"

replace pct_demvotes2016=0 if geofips==15005
replace pct_repvotes2016=0 if geofips==15005
replace pct_othervotes2016=0 if geofips==15005

replace pct_demvotes2016=pct_demvotes_state2016 if pct_demvotes2016==.
replace pct_repvotes2016=pct_repvotes_state2016 if pct_repvotes2016==.
replace pct_othervotes2016=pct_othervotes_state2016 if pct_othervotes2016==.

drop _merge 

* Merge with opioid prescribing rate
destring Year, replace 
merge m:1 geofips Year using  "..\data\2_intermediate\rxrate_2020_2021.dta"

replace rxrate=0 if rxrate==.
drop _merge 

* Add baseline overdose death count 
merge m:1 geofips using  "..\data\2_intermediate\od_total2019_geofips.dta"
rename ODDeathOccurrenceCount2019 odcounts2019
replace odcounts2019=0 if odcounts2019==.
drop _merge

*** add nsduh data 

merge m:1 StateName Year using  "..\data\2_intermediate\nsduh\NSDUH_2019_2021.dta"
drop if _merge==2
drop _merge

merge m:1 StateName using "..\data\2_intermediate\nsduh\NSDUH_2019_2021_wide.dta" 
drop _merge

gen anymentaldx18plus_p = .
replace anymentaldx18plus_p=anymentaldx18plus2019 if Year==2020
replace anymentaldx18plus_p=anymentaldx18plus2021 if Year==2021

gen anymentaldx26plus_p =.
replace anymentaldx26plus_p=anymentaldx26plus2019 if Year==2020
replace anymentaldx26plus_p=anymentaldx26plus2021 if Year==2021

gen needtrx12plus_p =.
replace needtrx12plus_p=needtrx12plus2019 if Year==2020
replace needtrx12plus_p=needtrx12plus2021 if Year==2021

gen needtrx18plus_p =.
replace needtrx18plus_p=needtrx18plus2019 if Year==2020
replace needtrx18plus_p=needtrx18plus2021 if Year==2021

gen needtrx26plus_p =.
replace needtrx26plus_p=needtrx26plus2019 if Year==2020
replace needtrx26plus_p=needtrx26plus2021 if Year==2021

gen sud12plus_p =.
replace sud12plus_p=sud12plus2019 if Year==2020
replace sud12plus_p=sud12plus2021 if Year==2021

gen sud18plus_p =.
replace sud18plus_p=sud18plus2019 if Year==2020
replace sud18plus_p=sud18plus2021 if Year==2021

gen sud26plus_p =.
replace sud26plus_p=sud26plus2019 if Year==2020
replace sud26plus_p=sud26plus2021 if Year==2021
 

drop anymentaldx18plus2019 anymentaldx26plus2019 needtrx12plus2019 ///
	needtrx26plus2019 needtrx18plus2019 sud12plus2019 sud26plus2019 ///
	sud18plus2019 anymentaldx18plus2021 anymentaldx26plus2021 ///
	needtrx12plus2021 needtrx26plus2021 needtrx18plus2021 sud12plus2021 ///
	sud26plus2021 sud18plus2021

tostring Year, replace

gen InterventionState=1 
replace InterventionState=0 if (StateAbbreviation=="AR" | ///
	StateAbbreviation=="GA" | StateAbbreviation=="MO"  | ///
	StateAbbreviation=="OH" | StateAbbreviation=="OK" | ///
	StateAbbreviation=="SD" | StateAbbreviation=="WY")
	
	
gen InterventionState12=0
replace InterventionState12=1 if (StateAbbreviation=="CA" | ///
	StateAbbreviation=="CT" | StateAbbreviation=="DC" | ///
	StateAbbreviation=="HI" | StateAbbreviation=="IL" | ///
	StateAbbreviation=="MD" | StateAbbreviation=="MN" | ///
	StateAbbreviation=="NJ" | StateAbbreviation=="NY" | ///
	StateAbbreviation=="OR" | StateAbbreviation=="VT" | ///
	StateAbbreviation=="WA")
			   
	*Create timeToTreat is the post variable for MoratoriaEver 0 for 
replace timeToTreat=timeToTreat*MoratoriaEver
replace timeToTreat=0 if MoratoriaEver==0 & timeToTreat==.
tab StateFIPS if YearMonth==202012
tab timeToTreat, mi	
	
*All States first Moratoria month in April	
gen MoratoriaApril=MoratoriaEver
replace MoratoriaApril=0 if YearMonth==202003

*Create Post, for intervention starting in April for all states
gen _mend2=_mend
replace _mend2=4 if _mend==3
gen timeToTreatApril = MonthDeath - _mend2 if YearMonth>202001

*Create timeToTreat in April the post variable for MoratoriaEver 0 for 
replace timeToTreatApril=timeToTreatApril*MoratoriaApril
replace timeToTreatApril=0 if MoratoriaApril==0 & timeToTreatApril==.
tab StateFIPS if YearMonth==202012
tab timeToTreatApril, mi	

sort geofips

egen CountyFipsNum=group(geofips)

sort StateFIPS
egen StateFIPSnum=group(StateFIPS)


gen enactedmoratoria=1
replace enactedmoratoria=0 if StateAbbreviation=="AK" | ///
	StateAbbreviation=="GA" | StateAbbreviation=="MO" | StateAbbreviation=="OH" | ///
	StateAbbreviation=="OK" | StateAbbreviation=="SD" | StateAbbreviation=="WY"


gen moratoriaapril=0
replace moratoriaapril=1 if StateAbbreviation=="AL" | StateAbbreviation=="CO" | ///
	StateAbbreviation=="FL" | StateAbbreviation=="MS" | StateAbbreviation=="UT"
	
gen moratoriamarch=0 
replace moratoriamarch=1 if moratoriaapril==0 & enactedmoratoria==1

*AK, GA, MO, OH, OK, SD, WY

distinct StateAbbreviation if moratoriamarch==1

gen TimeCentered=0
replace TimeCentered=(TimeCont-39) if moratoriamarch==1
replace TimeCentered=(TimeCont-40) if moratoriaapril==1
replace  TimeCentered=0 if enactedmoratoria==0

sort geofips
egen county_num = group(geofips)

gen str5 GEOID = string(geofips,"%05.0f")

egen MonthNum = group (YearMonth)

gen str5 CountyFIPS1 = string(geofips,"%05.0f")

*replace unemprate=0 if geofips==15005

*Replace missing data for some counties

*Replace with mhhinc with the 2021 value
replace mhhinc=38659 if geofips==48243

*Replace with mhhinc with the 2020 value
replace mhhinc=44076 if geofips==48301

*Merge with vaccination rate data by county

merge 1:1 geofips YearMonth using "..\data\2_intermediate\vaccinations_dec2020_may2023_clean.dta"

drop if Year>"2021"
drop if geofips==66010


foreach var of varlist administered_dose1_recip administered_dose1_pop_pct ///
	administered_dose1_recip_5plus administered_dose1_recip_5pluspo ///
	administered_dose1_recip_12plus administered_dose1_recip_12plusp /// 	
	administered_dose1_recip_18plus administered_dose1_recip_18plusp ///
	administered_dose1_recip_65plus administered_dose1_recip_65plusp ///
	series_complete_yes series_complete_pop_pct series_complete_5plus ///
	series_complete_5pluspop_pct series_complete_5to17 ///
	series_complete_5to17pop_pct series_complete_12plus ///
	series_complete_12pluspop_pct series_complete_18plus ///
	series_complete_18pluspop_pct series_complete_65plus ///
	series_complete_65pluspop_pct booster_doses booster_doses_vax_pct ///
	booster_doses_5plus booster_doses_5plus_vax_pct booster_doses_12plus ///
	booster_doses_12plus_vax_pct booster_doses_18plus ///
	booster_doses_18plus_vax_pct booster_doses_50plus ///
	booster_doses_50plus_vax_pct booster_doses_65plus ///
	booster_doses_65plus_vax_pct second_booster_50plus ///
	second_booster_50plus_vax_pct second_booster_65plus ///
	second_booster_65plus_vax_pct series_complete_pop_pct_svi /// 
	series_complete_5pluspop_pct_svi series_complete_5to17pop_pct_svi ///
	series_complete_12pluspop_pct_sv series_complete_18pluspop_pct_sv ///
	series_complete_65pluspop_pct_sv ///
	series_complete_pop_pct_ur_equit series_complete_5pluspop_pct_ur_ ///
	series_complete_5to17pop_pct_ur_ series_complete_12pluspop_pct_ur ///
	series_complete_18pluspop_pct_ur series_complete_65pluspop_pct_ur ///
	booster_doses_vax_pct_svi booster_doses_12plusvax_pct_svi ///
	booster_doses_18plusvax_pct_svi booster_doses_65plusvax_pct_svi ///
	booster_doses_vax_pct_ur_equity booster_doses_12plusvax_pct_ur_e ///
	booster_doses_18plusvax_pct_ur_e booster_doses_65plusvax_pct_ur_e ///
	census2019 census2019_5pluspop census2019_5to17pop census2019_12pluspop ///
	census2019_18pluspop census2019_65pluspop bivalent_booster_5plus ///
	bivalent_booster_5plus_pop_pct bivalent_booster_12plus ///
	bivalent_booster_12plus_pop_pct bivalent_booster_18plus ///
	bivalent_booster_18plus_pop_pct bivalent_booster_65plus ///
	bivalent_booster_65plus_pop_pct {
		destring `var', replace
		replace  `var'=0 if  `var'==.
		
	}

drop _merge


**************

*** Merge with oxford index

merge m:1 StateName YearMonth using "..\data\2_intermediate\OxCGRT_mean_bystate_2020_2021.dta"
drop _merge 

*Merge with community transmission rate data by county

merge 1:1 geofips YearMonth using "..\data\2_intermediate\communitytransmisson_2020_2021.dta"

drop _merge

egen administered_dose1_recip_state = total(administered_dose1_recip), by(StateFIPS YearMonth)
gen administered_dose1_pop_pct_state=(administered_dose1_recip_state/totpop_state)*100

* Merge econ impact index 
merge 1:1 geofips YearMonth using "..\data\2_intermediate\econimpactindex_clean.dta"
replace econimpactindex=1 if _merge==1
drop _merge

** Merge unemployment LAUS

merge 1:1 geofips YearMonth using "..\data\2_intermediate\unemp_blscounty_monthly_unemp_clean.dta"

egen  lausunemp_meanstate = median(lau_unemprate), by(StateFIPS YearMonth)
replace lau_unemprate=lausunemp_meanstate if lau_unemprate==.
drop _merge

egen econimpactindex_median = median(econimpactindex), by(StateFIPS YearMonth)

egen comtransmissioncat_state = mean(comtransmissioncat), by(StateFIPS YearMonth)
egen medcomtranscat_state=median(medcomtranscat), by(StateFIPS YearMonth)


export delimited using "..\data\3_analytic\analysis_county_jan2020_dec2021.csv", replace
save  "..\data\3_analytic\analysis_county_jan2020_dec2021.dta", replace


* Make final changes to dataset
use  "..\data\3_analytic\analysis_county_jan2020_dec2021.dta", clear
*Drop data prior March 2020
keep if YearMonth >202003

*Create a copy of the Moratoria variable
gen MoratoriaO=Moratoria

*Create changes for analyses 

replace Moratoria = 1 if Moratoria>0 & YearMonth==202004

replace Moratoria = 1 if StateAbbreviation=="CO" & YearMonth>=202007 & YearMonth<202010
replace Moratoria = 1 if StateAbbreviation=="KS" & YearMonth>=202006 & YearMonth<202008
replace Moratoria = 1 if StateAbbreviation=="NC" & YearMonth>=202007 & YearMonth<202010
replace Moratoria = 1 if StateAbbreviation=="MA" & YearMonth>=202011
replace Moratoria = 1 if StateAbbreviation=="NV" & YearMonth>=202011
replace Moratoria = 1 if StateAbbreviation=="VA" & YearMonth>=202007

replace Moratoria=1 if Moratoria>0

gen LiftMoratoria=0 if Moratoria==1
replace LiftMoratoria=1 if Moratoria==0

gen mevend1=month(dEMEND)
gen mevend2=month(dEMEND2)
gen mevend3=month(dEMEND3)
gen str2 monthevend1 = string(mevend1,"%02.0f")
gen str2 monthevend2 = string(mevend2,"%02.0f")
gen str2 monthevend3 = string(mevend3,"%02.0f")

gen yevend1=year(dEMEND)
gen yevend2=year(dEMEND2)
gen yevend3=year(dEMEND3)

tostring yevend1 yevend2 yevend3, replace
 
gen datem1 = yevend1 + monthevend1
gen datem2 = yevend2 + monthevend2
gen datem3 = yevend3 + monthevend3
replace datem1="" if datem1==".."
replace datem2="" if datem2==".."
replace datem3="" if datem3==".."
destring datem1 datem2 datem3, replace

gen datelift=datem1
replace datelift=datem2 if datem2!=.
replace datelift=datem3 if datem3!=.

* datelift2 - if the moratorium was lifted in the second half of the month, 
* then the following month is treated as the first treatment period

* Massachusetts only had one month without... currently treating as if they had 
* the moratoria during the whole period
replace datelift=. if StateAbbreviation=="MA"

*Treat ND as if they had lifted in May 2020
replace datelift=202005 if StateAbbreviation=="ND"

gen datelift2=datelift

replace datelift2=202006 if StateAbbreviation=="AL" | StateAbbreviation=="IA" ///
	| StateAbbreviation=="MT" ///
	| StateAbbreviation=="NE" |  StateAbbreviation=="TX" ///
	| StateAbbreviation=="WV" | StateAbbreviation=="WI"

replace datelift2=202007 if StateAbbreviation=="LA" 

replace datelift2=202009 if StateAbbreviation=="KY" 
replace datelift2=202011 if StateAbbreviation=="AZ" 


replace datelift2=202106 if StateAbbreviation=="KS" | StateAbbreviation=="NV" 

*Restart so the first month is April 2020
drop MonthNum
egen MonthNum = group (YearMonth)

gen LiftMoratoriaEver=1
replace LiftMoratoriaEver=0 if StateAbbreviation=="CA" | StateAbbreviation=="DC" |  ///
	StateAbbreviation=="IL" | StateAbbreviation=="MA" | StateAbbreviation=="MN" | ///
	StateAbbreviation=="NJ" | StateAbbreviation=="NM" | StateAbbreviation=="NY"


* Create variable indicating the month the moratorium was lifted
gen MonthNumLift=0
replace MonthNumLift=2	if datelift2==202005
replace MonthNumLift=3	if datelift2==202006
replace MonthNumLift=4	if datelift2==202007
replace MonthNumLift=5	if datelift2==202008
replace MonthNumLift=6	if datelift2==202009
replace MonthNumLift=7	if datelift2==202010
replace MonthNumLift=8	if datelift2==202011
replace MonthNumLift=10	if datelift2==202101
replace MonthNumLift=15	if datelift2==202106
replace MonthNumLift=16	if datelift2==202107
replace MonthNumLift=17	if datelift2==202108

gen TimeSinceLifting=MonthNum-MonthNumLift 
replace TimeSinceLifting =0 if TimeSinceLifting==.

* Create dummy variable where 0 untreated and 1 treated 
drop LiftMoratoria
gen LiftMoratoria=0 
replace LiftMoratoria=1 if datelift2<=YearMonth

** in counties with missing data impute median
*replace mhhinc=55556   if mhhinc==.  
*replace gini=.442    if gini==.  

* create overdose death rate
gen odrate=(ODDeathOccurrenceCount/totpop)*100000

* Drop states that never passed eviction moratoria
drop if StateAbbreviation=="AR" | StateAbbreviation=="GA" | ///
	StateAbbreviation=="MO"| StateAbbreviation=="OH" | ///
	StateAbbreviation=="OK"| StateAbbreviation=="SD" | StateAbbreviation=="WY"

	
* Rate of COVID-19 incident cases and deaths
* county-level 
gen covidratenew= (CovidCasesNew/totpop)*1000
gen coviddeathratenew= (CovidDeathsNew/totpop)*1000

gen covidratecum= (CovidCasesCum/totpop)*1000
gen coviddeathratecum= (CovidDeathsCum/totpop)*1000
 
* state-level
gen covidratenew_state= (CovidCasesNew_state/totpop_state)*1000
gen coviddeathratenew_state= (CovidDeathsNew_state/totpop_state)*1000

gen covidratecum_state= (CovidCasesCum_state/totpop_state)*1000
gen coviddeathratecum_state= (CovidDeathsCum_state/totpop_state)*1000


gen popdensity=(totpop/area)
gen popdensity_state=(totpop_state/area_state)

** Create a variable for specific policies

* End of state of emergency
gen StateEmergency=pSTEMERG 
replace StateEmergency=0 if pSTEMERGEND>0.5
replace StateEmergency=1 if pSTEMERG2>0.5

* End of state of business closures
gen EndBusinsesClosures=0
replace  EndBusinsesClosures=1 if pEND_BSNS>0.5


gen buptelehealt=0
replace buptelehealt=1 if pTLHlBUPR>0.5

gen opioidtakehome=0 
replace opioidtakehome=1 if pEXTOPFL>0.5

gen  homedelivery=0
replace homedelivery=1 if pHMDLVOP>0.5

gen telemedicinescheduleIIV=0
replace telemedicinescheduleIIV=1 if pTLHLCL24>0.5

*** Add state-level demographic data

gen CDC_moratoria=0
replace CDC_moratoria=1 if pCDCSTART>0.5
replace CDC_moratoria=0 if pCDCEND>0.5 & CDC_moratoria==1


gen CaresAct=0
replace CaresAct=pCARESSTART
replace CaresAct=(1- pCARESEND) if pCARESSTART>0 & pCARESEND>0


* Eviction rate
*Need to figure the discrepancy
*merge m:1 geofips using  "2_intermediate\county_eviction_estimates2018.dta"

*Check missing data 
*keep geofips StateFIPS Year YearMonth MonthNum totpop area mhhinc gini pct_pop18under pct_pop18_34 pct_pop35to64 pct_pop65plus pct_popfemale pct_popNH pct_popNHWhite pct_popNHBlack pct_popHispanic pct_popNHOther pct_HSplus pct_unemp pct_hhssinc pct_hhpai pct_poprenterhu pct_poppoverty pct_rent30to49 pct_rent50plus pct_pophealthins metro rxrate pct_pop18under_state pct_pop18_34_state pct_pop35to64_state pct_pop65plus_state pct_popfemale_state pct_popNH_state pct_popNHWhite_state pct_popNHBlack_state pct_popHispanic_state pct_popNHOther_state pct_HSplus_state pct_unemp_state pct_hhssinc_state pct_hhpai_state  pct_poprenterhu_state pct_poppoverty_state pct_rent30to49_state pct_rent50plus_state pct_pophealthins_state ODDeathOccurrenceCount CovidCases CovidDeaths unemprate pct_repvotes pct_demvotes pct_othervotes pct_repvotes_state pct_demvotes_state pct_othervotes_state covidrate coviddeathrate popdensity StateEmergency LiftMoratoria EndBusinsesClosures buptelehealt opioidtakehome homedelivery telemedicinescheduleIIV CDC_moratoria odrate

*mdesc

*Add gaps in LiftMoratoria 


*drop LiftMoratoriaO

gen LiftMoratoriaO=1-MoratoriaO

gen LiftMoratoriaObin=LiftMoratoriaO
replace LiftMoratoriaObin=1 if LiftMoratoriaO>0.5
replace LiftMoratoriaObin=0 if LiftMoratoriaO<=0.5

*replace MoratoriaO=1 if MoratoriaO>=0.5
*replace MoratoriaO=0 if MoratoriaO<0.5

*Check if it is correct
*collapse (mean) MoratoriaO, by (StateFIPS YearMonth)
*reshape wide Moratoria, i(StateFIPS) j(YearMonth)


*gen LiftMoratoriaO=0 if MoratoriaO==1
*replace LiftMoratoriaO=1 if MoratoriaO==0

tab YearMonth MoratoriaO if StateName=="Colorado" 

egen odtotal_state = total(ODDeathOccurrenceCount), by(StateFIPS YearMonth)
gen odrate_state=(odtotal_state/totpop_state)*100000

destring Year, replace 


* Merge with NFLIS data
merge m:1 StateName Year using "..\data\2_intermediate\NFLIS2020_2021.dta"
keep if _merge==3
drop _merge

* Create severe overcrowding variable
gen overcrowding = occroom1halftotwo + occroom2plus
gen pct_overcrowding = (overcrowding/ renterhu)*100
gen overcrowding_state = occroom1halftotwo_state + occroom2plus_state
gen pct_overcrowding_state = (overcrowding_state/ renterhu_state)*100

gen L_overcrowding = L_occroom1halftotwo + L_occroom2plus
gen L_pct_overcrowding = (L_overcrowding/ L_renterhu)*100


gen L_overcrowding_state = L_occroom1halftotwo_state + L_occroom2plus_state
gen L_pct_overcrowding_state = (L_overcrowding_state/ L_renterhu_state)*100

replace CaresAct=1 if CaresAct>0.5
replace CaresAct=0 if CaresAct<=0.5


tab StateFIPS YearMonth if CDC_moratoria==1

*replace CDC_moratoria=0 if YearMonth>=202109

gen odcount=ODDeathOccurrenceCount
replace odcount=. if MonthNum==1

egen cumodcount=total(odcount), by (geofips)

gen cumodrate=(cumodcount/totpop)*100000
gen cumodratemon=cumodrate/20


bysort geofips (MonthNum): gen cum_sum_odcount = sum(odcount)
gen cumodrate2 = (cum_sum_odcount/totpop)*100000

drop cumodratemon2

gen cumodratemon2 = (cumodrate/(MonthNum-1)) if MonthNum>1

gen cumodratemon2 = cumodrate2/(MonthNum-1) if MonthNum>1
gen cumodratemon3 = cumodrate2/20 if MonthNum>1


** Gen lag covs, to check model
xtset geofips MonthNum
*bysort geofips: gen L_covidrate_state = l.covidrate_state
*replace L_covidrate_state=covidrate_state if L_covidrate_state==.

bysort geofips: gen L_covidratenew_state = l.covidratenew_state
replace L_covidratenew_state=covidratenew_state if L_covidratenew_state==.

*bysort geofips: gen L_coviddeathrate_state = l.coviddeathrate_state
*replace L_coviddeathrate_state=coviddeathrate_state if L_coviddeathrate_state==.

bysort geofips: gen L_coviddeathratenew_state = l.coviddeathratenew_state
replace L_coviddeathratenew_state=coviddeathratenew_state if L_coviddeathratenew_state==.

bysort geofips: gen L_GovernmentResponseIndex = l.GovernmentResponseIndex
replace L_GovernmentResponseIndex=GovernmentResponseIndex if L_GovernmentResponseIndex==.

bysort geofips: gen L_econimpactindex_median= l.econimpactindex_median
replace L_econimpactindex_median=econimpactindex_median if L_econimpactindex_median==.


*Eviction moratoria in place defined as any moratoria

tab LiftMoratoriaObin CDC_moratoria

gen LiftMoratoriaAny = LiftMoratoriaObin
replace LiftMoratoriaAny = 0 if CDC_moratoria == 1



export delimited using "..\data\3_analytic\analysis_county_march2020_dec2021.csv", replace
save  "..\data\3_analytic\analysis_county_march2020_dec2021.dta", replace

*Create file for policy shift... will be used for lmtp

xtset geofips MonthNum

bysort geofips: gen L_LiftMoratoria = l.LiftMoratoria
replace L_LiftMoratoria=LiftMoratoria if L_LiftMoratoria==.


bysort geofips: gen L_LiftMoratoriaObin = l.LiftMoratoriaObin
replace L_LiftMoratoriaObin=LiftMoratoriaObin if L_LiftMoratoriaObin==.

replace LiftMoratoria=. 
replace LiftMoratoria=L_LiftMoratoria

replace LiftMoratoriaObin=. 
replace LiftMoratoriaObin=L_LiftMoratoriaObin


drop L_LiftMoratoriaObin L_LiftMoratoria


save  "..\data\3_analytic\analysis_county_march2020_dec2021_mtp.dta", replace

