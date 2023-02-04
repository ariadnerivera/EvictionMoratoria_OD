* Last update April 22nd 20222

* Set working directory
cd "C:\Users\rivera30\OneDrive - NYU Langone Health\EvictionMoratoria_OD\data"


* The folders need to have the following structure
***** data
*		|
*		|-- 1_raw
*		|-- 2_intermediate
*		|-- 3_analytic


*Eviction moratoria rating from Eviction lab, convert to dta

* The rating data comes from here: https://evictionlab.org/covid-policy-scorecard/#scorecard-resources 
import delimited "1_raw\EvictionMoraltoriaRating_EvictionLab.csv", clear 
rename ïstate State
label variable State ""
save "2_intermediate\evictionmoratoriarating.dta", replace


use "2_intermediate\od_2017_2020.dta", clear

gen statename=State
merge m:1 statename using "1_raw\2_states_fips.dta"
drop _merge

gen str2 StateFIPS = string( fipscode ,"%02.0f")
drop fipscode

gen geofips=StateFIPS+CountyOccurrenceFIPS
destring geofips, replace

rename year Year

* Shannon County, South Dakota (46-113)
 *Changed name and code to Oglala Lakota County (46-102) effective May 1, 2015.
replace geofips=46102 if geofips==46113
 
*Wade Hampton Census Area, Alaska (02-270)
*Changed name and code to Kusilvak Census Area (02-158) effective July 1, 2015.
replace geofips=2158 if geofips==2270

save "2_intermediate\od_2017_2020_geofips.dta", replace

import delimited "2_intermediate\acs_2017_2020.csv", case(preserve) clear 
drop v1 Unnamed0

drop if geofips>=72000

* Chugach Census Area, Alaska (02-063): Created from part of former 
* Valdez-Cordova Census Area (02-261) effective January 02, 2019.

* Copper River Census Area, Alaska (02-066): Created from part of former 
* Valdez-Cordova Census Area (02-261) effective January 02, 2019.

* Need to combine 02-063 & 02-066
replace geofips=2261 if geofips==2063 | geofips==2066

collapse (sum) totpop housingunits renterhousingunits poprenterhousing ///
	poppovertystatus pop18_64poverty rent30_49inc rent50plusinc ///
	(mean) mhhinc gini, by(geofips Year)

expand 12
bysort geofips Year : gen group_index = _n
gen str2 MonthDeath = string( group_index ,"%02.0f")


merge 1:1 geofips Year MonthDeath using "2_intermediate\od_2017_2020_geofips.dta"

* In census data but not in all years of mortality data
* Based on https://github.com/kjhealy/fips-codes/blob/master/state_and_county_fips_master.csv master
*
				
*  geofips |      2017       2018       2019       2020 |     Total
*-----------+--------------------------------------------+----------
*      2282 |         1          0          0          0 |         1 * Yakutat City and Borough in AK, this one is weird because only appears in one year... should have been already since 1990 https://www.census.gov/programs-surveys/geography/technical-documentation/county-changes.1990.html
*     15005 |         1          0          1          1 |         3 * Kalawao County in HI * where exiled people with Hansen's disease in the 1960s
*     31007 |         0          0          1          0 |         1 * Banner County in NE
*     31113 |         0          0          1          0 |         1 * Logan County in NE
*     31117 |         0          1          0          0 |         1 * McPherson County in NE
*     31171 |         0          1          1          0 |         2 * Thomas County in NE
*     46075 |         0          1          0          0 |         1 * Jones County in SD
*     48269 |         0          0          0          1 |         1 * King County in TX
*-----------+--------------------------------------------+----------
*     Total |         2          3          4          4 |        13 

* Replace with 0, counties with no mortality data
replace ODDeathOccurrenceCount=0 if _merge==1 & ODDeathOccurrenceCount==.

drop StateOccurrenceFIPS CountyOccurrenceFIPS StateCountyOccurrenceFIPS ///
	statename  _merge

destring StateFIPS, replace

gen str5 geofips2 = string( geofips ,"%05.0f")
gen state = substr(geofips2, 1,2)
destring state, replace
replace StateFIPS=state if StateFIPS==.
drop state geofips2

merge m:1 StateFIPS using "2_intermediate\cusp_datesfmt.dta"

drop _merge
replace State=StateAbbreviation if State==""

merge m:1 State using "2_intermediate\evictionmoratoriarating.dta"
 
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
replace	DayEnd=31	if MonthDeath=="10"
replace	DayEnd=30	if MonthDeath=="11"
replace	DayEnd=31	if MonthDeath=="12" 

gen	DayStart=1 

*gen days of the month
*4,6,9,11
gen daysmonth=30 if MonthDeath=="04" | MonthDeath=="06" | ///
	MonthDeath=="09" | MonthDeath=="11"

replace daysmonth=31 if MonthDeath=="01" | MonthDeath=="03" ///
	| MonthDeath=="05" | MonthDeath=="07"| MonthDeath=="08" ///
	| MonthDeath=="10" | MonthDeath=="12"

* February 2020 leap year
replace daysmonth=29 if MonthDeath=="02" & Year==2020

destring MonthDeath Year, replace

gen Date = mdy(MonthDeath, DayStart, Year) 
format Date %d

* Create proportion of variables formatted as dates
foreach var of varlist dSTEMERG-dWVDEAREQ {
	gen p`var'=`var'
	replace p`var'=1-[(`var'-Date)/daysmonth]
	replace p`var'=1 if Date>=`var' & `var'!=. & (p`var'<0 | p`var'>=1)
	replace p`var'=0 if Date< `var' & p`var'>=1
	replace p`var'=0 if p`var'<0
	}
	
foreach var of varlist STEMERG-EMEND3 INITIATIONBANSTART-WVDEAREQ {
	rename pd`var' p`var'
	}
	

destring MonthDeath, replace

gen Month = string(MonthDeath, "%02.0f")
tostring Year, replace

gen YearMonth=Year+Month

*drop dSTEMERG-dWVDEAREQ


** Create a variable Moratoria for the months or proportion of the month
** each state had a moratoria (turn off, turn on, turn off... variable)
*First moratoria start date
gen Moratoria=pEMSTART 
*First moratoria end date
replace Moratoria=abs(Moratoria-pEMEND) if pEMSTART>0 & pEMEND!=0
*Second moratoria start
replace Moratoria=pEMSTART2 if pEMEND!=0 & pEMSTART2!=0
*Second moratoria end date
replace Moratoria=abs(Moratoria-pEMEND2) if  pEMSTART2!=0 & pEMEND2!=0 
*Third moratoria start
replace Moratoria=pEMSTART3 if pEMEND2!=0 & pEMSTART3!=0
*Third moratoria end
replace Moratoria=(abs(Moratoria-pEMEND3)) if  pEMSTART3!=0 & pEMEND3!=0 

gen Moratoria1=pEMSTART
replace Moratoria1=abs(Moratoria-pEMEND) if pEMSTART>0 & pEMEND!=0
replace Moratoria1=. if pEMEND>0 | pEMEND!=0

gen Moratoria2=pEMSTART2 if pEMEND!=0 & pEMSTART2!=0
replace Moratoria2=abs(Moratoria2-pEMEND2) if  pEMSTART2!=0 & pEMEND2!=0 
replace Moratoria2=. if pEMEND2>0 | pEMEND2!=0

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
merge 1:1 geofips YearMonth using "C:\Users\rivera30\OneDrive - NYU Langone Health\EvictionMoratoria_OD\data\2_intermediate\CountyCovidCases_JanDec2020.dta"
drop if _merge==2
drop _merge

*** Merge covid deaths
merge 1:1 geofips YearMonth using "C:\Users\rivera30\OneDrive - NYU Langone Health\EvictionMoratoria_OD\data\2_intermediate\CountyCovidDeaths_JanDec2020.dta"
drop if _merge==2
drop _merge
replace CovidCases=0 if CovidCases==.
replace CovidDeaths=0 if CovidDeaths==.


** Need to ask Bianca about the update son the composite score
*** Merge with Tarlie's composite Covid-19 burden index
** gen fips=geofips
** gen month=MonthDeath

*merge m:1 fips month using "Z:\cerdam01labSpace\MAIN DATA FILES\NEMSIS\Project_Big Events_Preliminary\COVID Composite Score\covidburden.dta" 
** merge m:1 fips month using "Z:\cerdam01labSpace\MAIN DATA FILES\Big Events (inc. COVID Surveillance)\COVID Surveillance\COVID Composite Score\Original Score_Spring 2022\covidburden.dta" 

** gen compositecovid=composite
** replace compositecovid=. if YearMonth>201701 & YearMonth<202001

*tsset geofips YearMonth
*bysort geofips : carryforward compositecovid, gen(CovidBurdenIndex)

*egen countiescount = count(YearMonth), by (geofips)

*drop v1 composite _merge compositecovid 
replace death=0 if YearMonth<202001
replace case=0 if YearMonth<202001

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

export delimited using "3_analytic\analysis_county.csv", replace

*Create an aggregated database with counts and states and if they ever passed a moratoria or not
import delimited "3_analytic\analysis_county.csv", case(preserve) clear 
collapse (sum) totpop ODDeathOccurrenceCount, by (StateAbbreviation YearMonth TimeCont InterventionState)
gen OverdoseDeathRate=(ODDeathOccurrenceCount/totpop)*100000
export delimited using "3_analytic\oddeaths_statemonth.csv", replace

*Create an aggregated database with counts and states and if they ever passed a moratoria or not
import delimited "3_analytic\analysis_county.csv", case(preserve) clear 
keep if InterventionState==1
collapse (sum) totpop ODDeathOccurrenceCount , by(YearMonth TimeCont )
gen OverdoseDeathRate=(ODDeathOccurrenceCount/totpop)*100000
export delimited using "3_analytic\oddeaths_monthbyintervention44.csv", replace

*Create an aggregated database with 12 states that mantained a moratoria throughout 2020
import delimited "3_analytic\analysis_county.csv", case(preserve) clear 
gen OverdoseDeathRatetest=(ODDeathOccurrenceCount/totpop)*100000
keep if InterventionState12==1
collapse (sum) totpop ODDeathOccurrenceCount (mean) OverdoseDeathRatetest, by(YearMonth TimeCont)
gen OverdoseDeathRate=(ODDeathOccurrenceCount/totpop)*100000
export delimited using "3_analytic\oddeaths_monthbyintervention12.csv", replace

** This is the diverging means, what I had in the test
import delimited "3_analytic\analysis_county.csv", case(preserve) clear 
gen OverdoseDeathRatetest=(ODDeathOccurrenceCount/totpop)*100000
collapse (sum) totpop ODDeathOccurrenceCount (mean) OverdoseDeathRate , by(YearMonth TimeCont InterventionState)
export delimited using "3_analytic\oddeaths_monthbyintervention.csv", replace
