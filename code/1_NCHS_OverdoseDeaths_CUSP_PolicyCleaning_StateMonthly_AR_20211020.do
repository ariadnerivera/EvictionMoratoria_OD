* Update 10/20/2021
* The data is based on data vailable 10/03/2021

* This code is to create monthly overdose death counts based on NCHS
* Provisional Drug Overdose Death Counts

import delimited "C:\Users\rivera30\OneDrive - NYU Langone Health\EvictionMoratoria_OD\raw_data\overdose\VSRR_Provisional_Drug_Overdose_Death_Counts.csv", case(preserve) clear 

*import delimited "C:\Users\rivera30\OneDrive - NYU Langone Health\EvictionMoratoria_OD\raw_data\overdose\VSRR_Provisional_Drug_Overdose_Death_Counts.csv", case(preserve) 

* https://www.cdc.gov/nchs/nvss/vsrr/drug-overdose-data.htm

* Suggested citation
* Ahmad FB, Rossen LM, Sutton P. Provisional drug overdose death counts. 
* National Center for Health Statistics. 2021. Designed by LM Rossen, 
* A Lipphardt, FB Ahmad, JM Keralis, and Y Chong: 
* National Center for Health Statistics.

*Generate variables for each of the substances

* I used DataValue

*Cleaning of mortality data begins

* Cocaine (T40.5) 
gen CocaineDeathCount=0
replace CocaineDeathCount=DataValue if Indicator=="Cocaine (T40.5)"

* Heroin (T40.1)
gen HeroinDeathCount=0
replace HeroinDeathCount=DataValue if Indicator=="Heroin (T40.1)"

* Methadone (T40.3)
gen MethadoneDeathCount=0 
replace  MethadoneDeathCount=DataValue if Indicator=="Methadone (T40.3)" 

*Natural, semi-synthetic, & synthetic opioids, incl. methadone (T40.2-T40.4)
gen RxOpioidDeathCount=0
replace RxOpioidDeathCount=DataValue if Indicator=="Natural, semi-synthetic, & synthetic opioids, incl. methadone (T40.2-T40.4)"

*Natural & semi-synthetic opioids, incl. methadone (T40.2, T40.3)
gen RxOpioidDeathCount2=0
replace RxOpioidDeathCount2=DataValue if Indicator=="Natural & semi-synthetic opioids, incl. methadone (T40.2, T40.3)"

*Natural & semi-synthetic opioids (T40.2)
gen NatSemiOpioidDeathCount=0
replace NatSemiOpioidDeathCount=DataValue if Indicator=="Natural & semi-synthetic opioids (T40.2)"

*Number of Deaths
gen DeathCount=0
replace DeathCount=DataValue if Indicator=="Number of Deaths"

*Number of Drug Overdose Deaths
gen ODdeathCount=0
replace ODdeathCount=DataValue if Indicator=="Number of Drug Overdose Deaths"

*Opioids (T40.0-T40.4,T40.6)
gen OpioidDeathCount=0
replace OpioidDeathCount=DataValue if Indicator=="Opioids (T40.0-T40.4,T40.6)"

*Percent with drugs specified
gen PctDrugSpec=0 
replace PctDrugSpec=DataValue if Indicator=="Percent with drugs specified"

*Psychostimulants with abuse potential (T43.6)
gen StimulantDeathCount=0
replace StimulantDeathCount=DataValue if Indicator=="Psychostimulants with abuse potential (T43.6)"

*Synthetic opioids, excl. methadone (T40.4)
gen SyntheticOpioidDeathCount=0
replace SyntheticOpioidDeathCount=DataValue if Indicator=="Synthetic opioids, excl. methadone (T40.4)"

* Add deaths in from NYC to NY State
replace State="NY" if State=="YC"

collapse (sum) CocaineDeathCount HeroinDeathCount MethadoneDeathCount ///
	RxOpioidDeathCount RxOpioidDeathCount2 NatSemiOpioidDeathCount ///
	DeathCount ODdeathCount OpioidDeathCount PctDrugSpec ///
	StimulantDeathCount SyntheticOpioidDeathCount, by (State Year Month)
	
gen	MonthNum=1 if Month=="January"
replace	MonthNum=2 if Month=="February"
replace	MonthNum=3 if Month=="March"
replace	MonthNum=4 if Month=="April"
replace	MonthNum=5 if Month=="May"
replace	MonthNum=6 if Month=="June"
replace	MonthNum=7 if Month=="July"
replace	MonthNum=8 if Month=="August"
replace	MonthNum=9 if Month=="September"
replace	MonthNum=10	if Month=="October"
replace	MonthNum=11	if Month=="November"
replace	MonthNum=12	if Month=="December"

order State Year Month MonthNum DeathCount PctDrugSpec ODdeathCount, first	

rename State StateAbbreviation
drop if State=="US"

gen	DayEnd=31 if Month=="January"
replace	DayEnd=28 if Month=="February"
replace	DayEnd=31 if Month=="March"
replace	DayEnd=30 if Month=="April"
replace	DayEnd=31 if Month=="May"
replace	DayEnd=30 if Month=="June"
replace	DayEnd=31 if Month=="July"
replace	DayEnd=31 if Month=="August"
replace	DayEnd=30 if Month=="September"
replace	DayEnd=31	if Month=="October"
replace	DayEnd=30	if Month=="November"
replace	DayEnd=31	if Month=="December" 

gen	DayStart=1 


*Since the deaths are the accumulated up to the end of the month, I will change
*to the beggining of the following month
gen	MonthNew="February" if Month=="January"
replace	MonthNew="March" if Month=="February"
replace	MonthNew="April" if Month=="March"
replace	MonthNew="May" if Month=="April"
replace	MonthNew="June" if Month=="May"
replace	MonthNew="July" if Month=="June"
replace	MonthNew="August" if Month=="July"
replace	MonthNew="September" if Month=="August"
replace	MonthNew="October" if Month=="September"
replace	MonthNew="November"	if Month=="October"
replace	MonthNew="December"	if Month=="November"
replace	MonthNew="January"	if Month=="December" 


*Need to gen new year for the months
gen YearNew=Year
replace YearNew=Year+1 if MonthNew=="January" 

gen	MonthNumNew=1 if MonthNew=="January"
replace	MonthNumNew=2 if MonthNew=="February"
replace	MonthNumNew=3 if MonthNew=="March"
replace	MonthNumNew=4 if MonthNew=="April"
replace	MonthNumNew=5 if MonthNew=="May"
replace	MonthNumNew=6 if MonthNew=="June"
replace	MonthNumNew=7 if MonthNew=="July"
replace	MonthNumNew=8 if MonthNew=="August"
replace	MonthNumNew=9 if MonthNew=="September"
replace	MonthNumNew=10	if MonthNew=="October"
replace	MonthNumNew=11	if MonthNew=="November"
replace	MonthNumNew=12	if MonthNew=="December"

save "C:\Users\rivera30\OneDrive - NYU Langone Health\EvictionMoratoria_OD\intermediate_data\NCHS_EarlyReleaseOverdoseDeaths_States_Monthly_AR_20210827.dta", replace

*Cleaning of policy data begins
clear
import excel "C:\Users\rivera30\OneDrive - NYU Langone Health\EvictionMoratoria_OD\raw_data\housingpolicy\COVID-19 US state policy database 6_28_2021.xlsx", sheet("State policy changes ") firstrow

foreach v of var STATE-SMALLBUSMINWAGE {
la var `v' "`=`v'[1]' `=`v'[2]'_`=`v'[3]'_`=`v'[4]'"
replace `v'="" in 1
 }

drop in 1/4

rename DATE A80DATE
rename CH A75DATE
rename CI A70DATE
rename CJ A65DATE
rename CK A60DATE
rename CL A55DATE
rename CM A50DATE
rename CN A45DATE
rename CO A40DATE
rename CP A30DATE

rename GT U20EBSTART
rename GU U20EBEND
rename GV U20EBSTART2
		
* Create a new variable with the values formatted as dates
foreach var of varlist STEMERG STEMERGEND CLSCHOOL CLDAYCR OPNCLDCR ///
	CLNURSHM STAYHOME  END_STHM CLBSNS END_BSNS FM_ALL FM_ALL2 FM_EMP ///
	FM_END FM_END2 ALCREST ALCDELIV CLREST ENDREST CLGYM ENDGYM CLMOVIE ///
	END_MOV CLOSEBAR END_BRS END_HAIR END_RELG ENDRETL CURFEWEND BCLBAR2 ///
	CLBAR2 CLMV2 CLHAIR2 CLGYM2 CLRST2 ENDREST2 END_BRS2 END_CLGYM2 ///
	END_CLHAIR2 END_CLMV2 CLBAR3 CLRST3 END_CLBAR3 END_CLRST3 QR_ALLST ///
	QR_END VAC_PLAN A80DATE A75DATE A70DATE A65DATE A60DATE A55DATE ///
	A50DATE A45DATE A40DATE A30DATE PUBDATE EMSTART EMEND ///
	EMSTART2 EMEND2 EMSTART3 EMEND3 INITIATIONBANSTART INITIATIONBANEND ///
	INITIATIONBANSTART2 INITIATIONBANEND2 HEARINGBANSTART HEARINGBANEND ///
	HEARINGBANSTART2 HEARINGBANEND2 ENFORCEBANSTART ENFORCEBANEND ///
	ENFORCEBANSTART2 ENFORCEBANEND2 C19START C19END C19START2 C19END2 ///
	PAYSTART PAYEND PAYSTART2 PAYEND2 CARESSTART CARESEND CDCSTART ///
	CDCEND LATESTART LATEEND LATESTART2 LATEEND2 SMSTART SMEND SMSTART2 ///
	URSTART UREND SNAPEBT20 SNAPEBT21 SNAPEBTSUMMER SNAPSUSP TLHLAUD ///
	TLHLMED VISITPER VISITATT VISITRES NOVISIT2 ELECPRCR ENDELECP ///
	ELECPRCR2 ENDELECP2 EBSTART EBEND EBSTART2 U20EBSTART U20EBEND ///
	U20EBSTART2 TLHLCL24 EXCEMORP CASCLOSE CASOPEN CASCLOSE2 CASOPEN2 {
	
	gen n`var'=`var'
	replace n`var'="" if n`var'=="^"
	gen n`var'2 = date(n`var',"MDY", 2020)
	drop n`var'
	rename n`var'2 n`var'
	format n`var' %d
	}

	
*foreach v of var STATE-SMALLBUSMINWAGE {
*replace `v'="" if `v'=="^"
*}

	
	
foreach v of varlist STEMERG STEMERGEND CLSCHOOL CLDAYCR OPNCLDCR ///
	CLNURSHM STAYHOME  END_STHM CLBSNS END_BSNS FM_ALL FM_ALL2 FM_EMP ///
	FM_END FM_END2 ALCREST ALCDELIV CLREST ENDREST CLGYM ENDGYM CLMOVIE ///
	END_MOV CLOSEBAR END_BRS END_HAIR END_RELG ENDRETL CURFEWEND BCLBAR2 ///
	CLBAR2 CLMV2 CLHAIR2 CLGYM2 CLRST2 ENDREST2 END_BRS2 END_CLGYM2 ///
	END_CLHAIR2 END_CLMV2 CLBAR3 CLRST3 END_CLBAR3 END_CLRST3 QR_ALLST ///
	QR_END VAC_PLAN A80DATE A75DATE A70DATE A65DATE A60DATE A55DATE ///
	A50DATE A45DATE A40DATE A30DATE PUBDATE EMSTART EMEND ///
	EMSTART2 EMEND2 EMSTART3 EMEND3 INITIATIONBANSTART INITIATIONBANEND ///
	INITIATIONBANSTART2 INITIATIONBANEND2 HEARINGBANSTART HEARINGBANEND ///
	HEARINGBANSTART2 HEARINGBANEND2 ENFORCEBANSTART ENFORCEBANEND ///
	ENFORCEBANSTART2 ENFORCEBANEND2 C19START C19END C19START2 C19END2 ///
	PAYSTART PAYEND PAYSTART2 PAYEND2 CARESSTART CARESEND CDCSTART ///
	CDCEND LATESTART LATEEND LATESTART2 LATEEND2 SMSTART SMEND SMSTART2 ///
	URSTART UREND SNAPEBT20 SNAPEBT21 SNAPEBTSUMMER SNAPSUSP TLHLAUD ///
	TLHLMED VISITPER VISITATT VISITRES NOVISIT2 ELECPRCR ENDELECP ///
	ELECPRCR2 ENDELECP2 EBSTART EBEND EBSTART2 U20EBSTART U20EBEND ///
	U20EBSTART2 TLHLCL24 EXCEMORP CASCLOSE CASOPEN CASCLOSE2 CASOPEN2 { 

	di `"`: var label `v''"' 

}	

* Only keep state variables
* keep STATE POSTCODE FIPS nSTEMERG-nCASOPEN2	


rename STATE StateName	
rename FIPS StateFIPS 
rename POSTCODE StateAbbreviation

drop in 52/999

save "C:\Users\rivera30\OneDrive - NYU Langone Health\EvictionMoratoria_OD\intermediate_data\COVID-19 US state policy database 6_28_2021.dta", replace



* Clean Unemployment rate
clear
import excel "C:\Users\rivera30\OneDrive - NYU Langone Health\EvictionMoratoria_OD\raw_data\ststdsadata\ststdsadata.xlsx", sheet("ststdsadata") cellrange(A9:K29105)


*StateAbbreviation StateName StateFIPS

rename A StateFIPS
rename B StateName
rename C Year
rename D MonthNum
rename E Population
rename F LaborForce
rename G LaborForcePctPop
rename H Employment
rename I EmpPctPop
rename J Unemployment
rename K UnempRate

destring Year MonthNum StateFIPS, replace

keep if Year>=2015

replace StateFIPS=6 if StateName=="Los Angeles County" 
replace StateFIPS=36 if StateFIPS==51000


*egen  unempweight= wtmean(UnempRate), by(StateFIPS MonthNum Year) weight(LaborForce)

collapse (mean) UnempRate [aw=LaborForce], by (StateFIPS Year MonthNum)

* Drop data after Jan 2021

drop if MonthNum>1 & Year==2021

save "C:\Users\rivera30\OneDrive - NYU Langone Health\EvictionMoratoria_OD\intermediate_data\StateMonthlyUnempRate.dta", replace



** Merge overdose deaths and policy data and unemplyment
use "C:\Users\rivera30\OneDrive - NYU Langone Health\EvictionMoratoria_OD\intermediate_data\NCHS_EarlyReleaseOverdoseDeaths_States_Monthly_AR_20210827.dta", clear
merge m:1 StateAbbreviation using "C:\Users\rivera30\OneDrive - NYU Langone Health\EvictionMoratoria_OD\intermediate_data\COVID-19 US state policy database 6_28_2021.dta", nogenerate

gen Date = mdy(MonthNum, DayStart, Year) 
format Date %d


*gen days of the month

*4,6,9,11
gen daysmonth=30 if MonthNum==4 | MonthNum==6 | MonthNum==9 | MonthNum==11

replace daysmonth=31 if MonthNum==1 | MonthNum==3 | MonthNum==5 | MonthNum==7 ///
	| MonthNum==8 | MonthNum==10 | MonthNum==12

* February 2020 leap year
replace daysmonth=29 if MonthNum==2 & (Year==2020 | Year==2016)

* February 2021 leap year
replace daysmonth=28 if MonthNum==2 & (Year!=2020 & Year!=2016)

* Create a new variable with the values formatted as dates
foreach var of varlist nSTEMERG-nCASOPEN2 {
	gen p`var'=`var'
	replace p`var'=1-[(`var'-Date)/daysmonth]
	replace p`var'=1 if Date>=`var' & `var'!=. & (p`var'<0 | p`var'>=1)
	replace p`var'=0 if Date< `var' & p`var'>=1
	replace p`var'=0 if p`var'<0
	}
	
	
	
*List of variables with ^ 
* 	
*foreach var of varlist EMEND EMEND2 INITIATIONBANEND HEARINGBANEND ///
*	HEARINGBANEND2 ENFORCEBANEND C19END	PAYEND CARESEND CDCEND ///
*	SMEND UREND {

*	replace pn`var'=9999 if `var'=="^"  
	
*	}
	
*drop nSTEMERG-nCASOPEN2

foreach var of varlist STEMERG STEMERGEND CLSCHOOL CLDAYCR OPNCLDCR ///
	CLNURSHM STAYHOME  END_STHM CLBSNS END_BSNS FM_ALL FM_ALL2 FM_EMP ///
	FM_END FM_END2 ALCREST ALCDELIV CLREST ENDREST CLGYM ENDGYM CLMOVIE ///
	END_MOV CLOSEBAR END_BRS END_HAIR END_RELG ENDRETL CURFEWEND BCLBAR2 ///
	CLBAR2 CLMV2 CLHAIR2 CLGYM2 CLRST2 ENDREST2 END_BRS2 END_CLGYM2 ///
	END_CLHAIR2 END_CLMV2 CLBAR3 CLRST3 END_CLBAR3 END_CLRST3 QR_ALLST ///
	QR_END VAC_PLAN A80DATE A75DATE A70DATE A65DATE A60DATE A55DATE ///
	A50DATE A45DATE A40DATE A30DATE PUBDATE EMSTART EMEND ///
	EMSTART2 EMEND2 EMSTART3 EMEND3 INITIATIONBANSTART INITIATIONBANEND ///
	INITIATIONBANSTART2 INITIATIONBANEND2 HEARINGBANSTART HEARINGBANEND ///
	HEARINGBANSTART2 HEARINGBANEND2 ENFORCEBANSTART ENFORCEBANEND ///
	ENFORCEBANSTART2 ENFORCEBANEND2 C19START C19END C19START2 C19END2 ///
	PAYSTART PAYEND PAYSTART2 PAYEND2 CARESSTART CARESEND CDCSTART ///
	CDCEND LATESTART LATEEND LATESTART2 LATEEND2 SMSTART SMEND SMSTART2 ///
	URSTART UREND SNAPEBT20 SNAPEBT21 SNAPEBTSUMMER SNAPSUSP TLHLAUD ///
	TLHLMED VISITPER VISITATT VISITRES NOVISIT2 ELECPRCR ENDELECP ///
	ELECPRCR2 ENDELECP2 EBSTART EBEND EBSTART2 U20EBSTART U20EBEND ///
	U20EBSTART2 TLHLCL24 EXCEMORP CASCLOSE CASOPEN CASCLOSE2 CASOPEN2 {
	
	rename pn`var' p`var'
	
	}

label var pSTEMERG "State of emergency issued state_of_emergency_start_date"
label var pSTEMERGEND "State of emergency lifted state_of_emergency_end_date"
label var pCLSCHOOL "Date closed K-12 public schools physical_distance_closure_start_date"
label var pCLDAYCR "Closed day cares physical_distance_closure_start_date"
label var pOPNCLDCR "Reopen day cares Reopening_end_date"
label var pCLNURSHM "Date banned visitors to nursing homes physical_distance_closure_start_date"
label var pSTAYHOME "Stay at home/ shelter in place shelter_start_date"
label var pEND_STHM "End/relax stay at home/shelter in place shelter_end_date"
label var pCLBSNS "Closed other non-essential businesses physical_distance_closure_start_date"
label var pEND_BSNS "Began to reopen businesses reopening_end_date"
label var pFM_ALL "Face mask mandate in public spaces masks_start_date"
label var pFM_ALL2 "Face mask mandate x2 masks_start_date"
label var pFM_EMP "Face mask mandate for employees of public-facing businesses masks_start_date"
label var pFM_END "Ended face mask mandate masks_end_date"
label var pFM_END2 "Ended face mask mandate x2 masks_end_date"
label var pALCREST "Allowed restaurants to sell takeout alcohol alcohol_firearms_start_date"
label var pALCDELIV "Allowed restaurants to deliver alcohol alcohol_firearms_start_date"
label var pCLREST "Closed restaurants except take out physical_distance_closures_start_date"
label var pENDREST "Reopen restaurants reopening_end_date"
label var pCLGYM "Closed gyms physical_distance_closures_start_date"
label var pENDGYM "Reopened gyms reopening_end_date"
label var pCLMOVIE "Closed movie theaters physical_distance_closures_start_date"
label var pEND_MOV "Reopened movie theaters reopening_end_date"
label var pCLOSEBAR "Closed Bars physical_distance_closures_start_date"
label var pEND_BRS "Reopen bars reopening_end_date"
label var pEND_HAIR "Reopened hair salons/barber shops reopening_end_date"
label var pEND_RELG "Reopened religious gatherings reopening_end_date"
label var pENDRETL "Reopened other non-essential retail reopening_end_date"
label var pCURFEWEND "Allowed businesses to reopen overnight reopening_end_date"
label var pBCLBAR2 "Began to reclose bars second_closures_start_date"
label var pCLBAR2 "Closed bars (x2) second_closures_start_date"
label var pCLMV2 "Closed movie theaters (x2) second_closures_start_date"
label var pCLHAIR2 "Closed hair salons/barber shops (x2) second_closures_start_date"
label var pCLGYM2 "Closed gyms (x2) second_closures_start_date"
label var pCLRST2 "Closed restaurants (x2) second_closures_start_date"
label var pENDREST2 "Reopened restaurants (x2) second_closures_end_date"
label var pEND_BRS2 "Reopened bars (x2) second_closures_end_date"
label var pEND_CLGYM2 "Reopened gyms (x2) second_closures_end_date"
label var pEND_CLHAIR2 "Reopened hair salons/barber shops (x2) second_closures)_end_date"
label var pEND_CLMV2 "Reopened movie theaters (x2) second_closures_end_date"
label var pCLBAR3 "Closed bars (x3) third_closures_start_date"
label var pCLRST3 "Closed restaurants (x3) third_closures_start_date"
label var pEND_CLBAR3 "Reopened bars (x3) third_closures_end_date"
label var pEND_CLRST3 "Reopened restaurants (x3) third_closures_end_date"
label var pQR_ALLST "Mandate quarantine for all individuals entering the state quarantines_start_date"
label var pQR_END "Date all mandated quarantines ended quarantines_end_date"
label var pVAC_PLAN "Date vaccine allocation plan last updated vaccine_start_date"
label var pA80DATE "Date adults ages 80+ became eligible for COVID-19 vaccination vaccine_start_date"
label var pA75DATE "Date adults ages 75+ became eligible for COVID-19 vaccination vaccine_start_date"
label var pA70DATE "Date adults ages 70+ became eligible for COVID-19 vaccination vaccine_start_date"
label var pA65DATE "Date adults ages 65+ became eligible for COVID-19 vaccination vaccine_start_date"
label var pA60DATE "Date adults ages 60+ became eligible for COVID-19 vaccination vaccine_start_date"
label var pA55DATE "Date adults ages 55+ became eligible for COVID-19 vaccination vaccine_start_date"
label var pA50DATE "Date adults ages 50+ became eligible for COVID-19 vaccination vaccine_start_date"
label var pA45DATE "Date adults ages 45+ became eligible for COVID-19 vaccination vaccine_start_date"
label var pA40DATE "Date adults ages 40+ became eligible for COVID-19 vaccination vaccine_start_date"
label var pA30DATE "Date adults ages 30+ became eligible for COVID-19 vaccination vaccine_start_date"
label var pPUBDATE "Date general public became eligible for COVID-19 vaccination vaccine_start_date"
label var pEMSTART "First overall eviction moratorium start housing_start_date"
label var pEMEND "First overall eviction moratorium end housing_end_date"
label var pEMSTART2 "Second overall eviction moratorium start housing_start_date"
label var pEMEND2 "Second overall eviction moratorium end housing_end_date"
label var pEMSTART3 "Third overall eviction moratorium start housing_start_date"
label var pEMEND3 "Third overall eviction moratorium end housing_end_date"
label var pINITIATIONBANSTART "First eviction initiation ban start housing_start_date"
label var pINITIATIONBANEND "First eviction initiation ban end housing_end_date"
label var pINITIATIONBANSTART2 "Second Eviction Initiation Ban Start housing_start_date"
label var pINITIATIONBANEND2 "Second Eviction Initiation Ban End housing_end_date"
label var pHEARINGBANSTART "First eviction hearing ban start housing_start_date"
label var pHEARINGBANEND "First eviction hearing ban end housing_end_date"
label var pHEARINGBANSTART2 "Second Eviction Hearing Ban Start housing_start_date"
label var pHEARINGBANEND2 "Second Eviction Hearing Ban End housing_end_date"
label var pENFORCEBANSTART "First eviction enforcement ban start housing_start_date"
label var pENFORCEBANEND "First eviction enforcement ban end housing_end_date"
label var pENFORCEBANSTART2 "Second Eviction Enforcement Ban Start housing_start_date"
label var pENFORCEBANEND2 "Second Eviction Enforcement Ban End housing_end_date"
label var pC19START "COVID-19 hardship limitation start housing_start_date"
label var pC19END "COVID-19 hardship limitation end housing_end_date"
label var pC19START2 "Second COVID-19 hardship limitation start housing_start_date"
label var pC19END2 "Second COVID-19 hardship limitation end housing_end_date"
label var pPAYSTART "Non-payment limitation start housing_start_date"
label var pPAYEND "Non-payment limitation end housing_end_date"
label var pPAYSTART2 "Second non-payment limitation start housing_start_date"
label var pPAYEND2 "Second non-payment limitation end housing_end_date"
label var pCARESSTART "CARES Act pleading start housing_start_date"
label var pCARESEND "CARES Act pleading end housing_end_date"
label var pCDCSTART "CDC moratorium start housing_start_date"
label var pCDCEND "CDC moratorium end housing_end_date"
label var pLATESTART "Late Fee Ban Start housing_start_date"
label var pLATEEND "Late Fee Ban End housing_end_date"
label var pLATESTART2 "Second Late Fee Ban Start housing_start_date"
label var pLATEEND2 "Second Late Fee Ban End housing_end_date"
label var pSMSTART "Utilities shutoff moratorium start housing_start_date"
label var pSMEND "Utilities shutoff moratorium expiration housing_end_date"
label var pSMSTART2 "Second utilities shutoff moratorium start housing_start_date"
label var pURSTART "Utilities reconnection start housing_start_date"
label var pUREND "Utilities reconnection end housing_end_date"
label var pSNAPEBT20 "SNAP Waiver - Pandemic EBT during school year 2019-2020 food_security_start_date"
label var pSNAPEBT21 "SNAP Waiver - Pandemic EBT during school year 2020-2021 food_security_start_date"
label var pSNAPEBTSUMMER "SNAP Waiver - Pandemic EBT during summer 2021 food_security_start_date"
label var pSNAPSUSP "SNAP Waiver - Temporary Suspension of Claims Collection food_security_start_date"
label var pTLHLAUD "Allow audio-only telehealth healthcare_delivery_start_date"
label var pTLHLMED "Allow/expand Medicaid telehealth coverage healthcare_delivery_start_date"
label var pVISITPER "Stopped personal visitation in state prisons incarceration_start_date"
label var pVISITATT "Stopped legal visitation in state prisons incarceration_start_date"
label var pVISITRES "Began to resume visitation in state prisons incarceration_end_date"
label var pNOVISIT2 "Stopped visitation in state prisons x2 incarceration_start_date"
label var pELECPRCR "Suspended elective medical procedures healthcare_delivery_start_date"
label var pENDELECP "Resumed elective medical procedures healthcare_delivery_end _date"
label var pELECPRCR2 "Suspended elective medical procedures x2 healthcare_delivery_start_date"
label var pENDELECP2 "Resumed elective medical procedures x2 healthcare_delivery_end_date"
label var pEBSTART "Extended Benefits program activated unemployment_start_date"
label var pEBEND "Extended Benefits program deactivated unemployment_end_date"
label var pEBSTART2 "Extended Benefits program activated x2 unemployment_start_date"
label var pU20EBSTART "20-week Extended Benefits program activated unemployment_start_date"
label var pU20EBEND "20-week Extended Benefits program deactivated unemployment_end_date"
label var pU20EBSTART2 "20-week Extended Benefits program activated x2 unemployment_start_date"
label var pTLHLCL24 "Use of telemedicine for schedule II-V prescriptions SUD_policies_start_date"
label var pEXCEMORP "Exceptions to emergency oral prescriptions SUD_policies_start_date"
label var pCASCLOSE "Closed casinos physical_distance_closures_start_date"
label var pCASOPEN "Reopened casinos reopening_end_date"
label var pCASCLOSE2 "Closed casinos (x2) second_closures_start_date"
label var pCASOPEN2 "Reopened casinos (x2) second_closures_end_date"

sort StateAbbreviation Date

gen modate = ym(Year, MonthNum) 
format modate %tm 

sort StateName modate
egen date=group(modate)

destring StateFIPS, replace
merge m:1 StateFIPS MonthNum Year using "C:\Users\rivera30\OneDrive - NYU Langone Health\EvictionMoratoria_OD\intermediate_data\StateMonthlyUnempRate.dta"

drop _merge

save "C:\Users\rivera30\OneDrive - NYU Langone Health\EvictionMoratoria_OD\analytic_data\State_monthly_AR_20211020.dta", replace

