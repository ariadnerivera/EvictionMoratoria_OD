
******* Covid 19 cases
import delimited "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_confirmed_US.csv", delim(",") clear

*drop data for Jan2022 onwards
drop v722-v1154

drop if fips<1000
drop if fips>70000

keep if fips!=.
*keep fips v51-v81

reshape long v, i(fips) j(month)

*First check if there was drop within two consecutive days


rename fips geofips

bysort geofips (month): gen difference=v[_n] -v[_n-1]

*Create an indicator for those obsevations
gen negvals=0
replace negvals=1 if difference<0

*Check if there was drop, how many days the drop remained

gen diff1 = .
bysort geofips (month): replace diff1 = v[_n] - v[_n-1]

* Replace to zero the first month in the dataset
replace diff1=0 if diff1==.


local num_diffs 365

* Once there was a difference <0, then it checks within th 
forvalues i=2/`num_diffs' {
    gen diff`i' = 0
    bysort geofips (month): replace diff`i' = v[_n] - v[_n-`i']  if negvals[_n-`i'+1]==1
	replace  diff`i' = . if diff`i'>=0
}
replace diff1=. if diff1>=0


gen indicator=0

foreach var of varlist diff1-diff365 {
	replace indicator=1 if `var'<0 & `var'!=.
}

*Identifies when the drop in cases occurred
egen count_diff=rownonmiss(diff1-diff365)
*egen count_diff2=rowmiss(diff1-diff365)


gen CovidCasesCum=v 
replace CovidCasesCum=. if indicator==1

*Create a copy for reference
gen CovidCasesCum2=CovidCasesCum

bysort geofips (month): replace CovidCasesCum=(CovidCasesCum[_n+1]+CovidCasesCum[_n-1])/2 if CovidCasesCum==. & CovidCasesCum[_n+1]!=. & CovidCasesCum[_n-1]!=.
* Replaces 11,496 county-days

bysort geofips (month): replace CovidCasesCum=(CovidCasesCum[_n+2]+CovidCasesCum[_n-1])/2 if CovidCasesCum==. & CovidCasesCum[_n+1]==. & CovidCasesCum[_n-1]!=. & CovidCasesCum[_n+2]!=. 
* Replaces 3,669 county-days

*Repeat step 1
bysort geofips (month): replace CovidCasesCum=(CovidCasesCum[_n+1]+CovidCasesCum[_n-1])/2 if CovidCasesCum==. & CovidCasesCum[_n+1]!=. & CovidCasesCum[_n-1]!=.
* Replaces 3,669 county-days

******************


gen YearMonth=.

*2020
replace YearMonth = 202001 if inrange(month, 12, 21)
replace YearMonth = 202002 if inrange(month, 22, 50)
replace YearMonth = 202003 if inrange(month, 51, 81)
replace YearMonth = 202004 if inrange(month, 82, 111)
replace YearMonth = 202005 if inrange(month, 112, 142)
replace YearMonth = 202006 if inrange(month, 143, 172)
replace YearMonth = 202007 if inrange(month, 173, 203)
replace YearMonth = 202008 if inrange(month, 204, 234)
replace YearMonth = 202009 if inrange(month, 235, 264)
replace YearMonth = 202010 if inrange(month, 265, 295)
replace YearMonth = 202011 if inrange(month, 296, 325)
replace YearMonth = 202012 if inrange(month, 326, 356)

*2021
replace YearMonth = 202101 if inrange(month, 357, 387)
replace YearMonth = 202102 if inrange(month, 388, 415)
replace YearMonth = 202103 if inrange(month, 416, 446)
replace YearMonth = 202104 if inrange(month, 447, 476)
replace YearMonth = 202105 if inrange(month, 477, 507)
replace YearMonth = 202106 if inrange(month, 508, 537)
replace YearMonth = 202107 if inrange(month, 538, 568)
replace YearMonth = 202108 if inrange(month, 569, 599)
replace YearMonth = 202109 if inrange(month, 600, 629)
replace YearMonth = 202110 if inrange(month, 630, 660)
replace YearMonth = 202111 if inrange(month, 661, 690)
replace YearMonth = 202112 if inrange(month, 691, 721)

save "..\data\2_intermediate\CovidCases_CountyDay.dta", replace

use "..\data\2_intermediate\CovidCases_CountyDay.dta", clear

bysort geofips YearMonth: egen CovidCasesMax=max(CovidCasesCum)  
bysort geofips YearMonth: egen CovidCasesMax2=max(CovidCasesCum2)  

gen totobs=1

collapse (mean) CovidCasesMax CovidCasesMax2 (max) v (sum)indicator (sum)totobs, by(geofips YearMonth)

*bysort geofips (YearMonth): replace CovidCasesMax = (CovidCasesMax[_n+1] + CovidCasesMax[_n-1])/2 if CovidCasesMax==. 
*(142 real changes made)

*bysort geofips (YearMonth): replace CovidCasesMax = (CovidCasesMax[_n+2] + CovidCasesMax[_n-1])/2 if CovidCasesMax==. & CovidCasesMax[_n+1]==. 
*45 real changes made

*bysort geofips (YearMonth): replace CovidCasesMax = (CovidCasesMax[_n+1] + CovidCasesMax[_n-1])/2 if CovidCasesMax==. 
*45 real changes made

*tab geofips if CovidCasesMax==.

*If it is the last month, add november
replace CovidCasesMax=CovidCasesMax[_n-1] if YearMonth==202112 & CovidCasesMax==.

** These counties have 11 months withmissing data 
* 49001, 49005, 49007, 49013, 49015, 49017, 49019, 49021, 49025, 49047, 49053

replace CovidCasesMax=0 if CovidCasesMax!=0 & geofips==49053 | ///
	geofips==49047 | geofips==49025  | geofips==49021  | geofips==49017 | ///
	geofips==49019 | geofips==49015  | geofips==49013  | geofips==49007 | ///
	geofips==49005 | geofips==49001  | geofips==15005 

*geofips 13291	
*replace	 CovidCasesMax=round((CovidCasesMax[_n-1]*1.025)) if inrange(YearMonth, 202012, 202107) & geofips==13291 

*geofips 31117
replace	 CovidCasesMax=10 if inrange(YearMonth, 202006, 202009) & geofips==31117 

*replace CovidCasesMax=CovidCasesMax[_n-1]+2 if inrange(YearMonth, 202104, 202108) & geofips==31117 

gen CovidCasesMax_check=CovidCasesMax

**
**
bysort geofips (YearMonth): replace CovidCasesMax=round((CovidCasesMax[_n+8]+CovidCasesMax[_n-1])/2) if CovidCasesMax==. & CovidCasesMax[_n-1]!=. & CovidCasesMax[_n+1]==.  & CovidCasesMax[_n+2]==. & CovidCasesMax[_n+3]==. & CovidCasesMax[_n+4]==. & CovidCasesMax[_n+5]==. & CovidCasesMax[_n+6]==. & CovidCasesMax[_n+7]==.

bysort geofips (YearMonth): replace CovidCasesMax=round((CovidCasesMax[_n+7]+CovidCasesMax[_n-1])/2) if CovidCasesMax==. & CovidCasesMax[_n-1]!=. & CovidCasesMax[_n+1]==.  & CovidCasesMax[_n+2]==. & CovidCasesMax[_n+3]==. & CovidCasesMax[_n+4]==. & CovidCasesMax[_n+5]==. & CovidCasesMax[_n+6]==.

bysort geofips (YearMonth): replace CovidCasesMax=round((CovidCasesMax[_n+6]+CovidCasesMax[_n-1])/2) if CovidCasesMax==. & CovidCasesMax[_n-1]!=. & CovidCasesMax[_n+1]==.  & CovidCasesMax[_n+2]==. & CovidCasesMax[_n+3]==. & CovidCasesMax[_n+4]==.  & CovidCasesMax[_n+5]==.

bysort geofips (YearMonth): replace CovidCasesMax=round((CovidCasesMax[_n+5]+CovidCasesMax[_n-1])/2) if CovidCasesMax==. & CovidCasesMax[_n-1]!=. & CovidCasesMax[_n+1]==.  & CovidCasesMax[_n+2]==. & CovidCasesMax[_n+3]==. & CovidCasesMax[_n+4]==.

bysort geofips (YearMonth): replace CovidCasesMax=round((CovidCasesMax[_n+4]+CovidCasesMax[_n-1])/2) if CovidCasesMax==. & CovidCasesMax[_n-1]!=. & CovidCasesMax[_n+1]==.  & CovidCasesMax[_n+2]==. & CovidCasesMax[_n+3]==.

bysort geofips (YearMonth): replace CovidCasesMax=round((CovidCasesMax[_n+3]+CovidCasesMax[_n-1])/2) if CovidCasesMax==. & CovidCasesMax[_n-1]!=. & CovidCasesMax[_n+1]==.  & CovidCasesMax[_n+2]==.

bysort geofips (YearMonth): replace CovidCasesMax=round((CovidCasesMax[_n+2]+CovidCasesMax[_n-1])/2) if CovidCasesMax==. & CovidCasesMax[_n-1]!=. & CovidCasesMax[_n+1]==.  

bysort geofips (YearMonth): replace CovidCasesMax=round((CovidCasesMax[_n+1]+CovidCasesMax[_n-1])/2) if CovidCasesMax==. & CovidCasesMax[_n-1]!=. & CovidCasesMax[_n+1]!=.  


************************************************************
gen CovidCasesNew=. 
bysort geofips (YearMonth): replace CovidCasesNew=(CovidCasesMax[_n]-CovidCasesMax[_n-1])
replace CovidCasesNew=CovidCasesMax if YearMonth==202001


gen CovidCasesNew2=. 
bysort geofips (YearMonth): replace CovidCasesNew2=(CovidCasesMax2[_n]-CovidCasesMax2[_n-1])

replace CovidCasesNew2=CovidCasesMax2 if YearMonth==202001

gen negvals=0
replace negvals=1 if CovidCasesNew==.
replace negvals=1 if CovidCasesNew<0


gen negvals2=0
replace negvals2=1 if CovidCasesNew2==.
replace negvals2=1 if CovidCasesNew2<0

rename CovidCasesMax CovidCasesCum

keep geofips YearMonth CovidCasesNew CovidCasesCum

save "..\data\2_intermediate\CountyCovidCases_NewCum_Jan2020Dec2021.dta", replace


****** Covid 19 deaths
import delimited "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_US.csv", delim(",") clear

*drop data for Jan2022 onwards
drop v723-v1155

drop if fips<1000

drop if fips>70000

keep if fips!=.
*keep fips v51-v81

reshape long v, i(fips) j(month)

*********

rename fips geofips

bysort geofips (month): gen difference=v[_n] -v[_n-1]

*Create an indicator for those obsevations
gen negvals=0
replace negvals=1 if difference<0

*Check if there was drop, how many days the drop remained

gen diff1 = .
bysort geofips (month): replace diff1 = v[_n] - v[_n-1]

* Replace to zero the first month in the dataset
replace diff1=0 if diff1==.


local num_diffs 365

* Once there was a difference <0, then it checks within th 
forvalues i=2/`num_diffs' {
    gen diff`i' = 0
    bysort geofips (month): replace diff`i' = v[_n] - v[_n-`i']  if negvals[_n-`i'+1]==1
	replace  diff`i' = . if diff`i'>=0
}
replace diff1=. if diff1>=0


gen indicator=0

foreach var of varlist diff1-diff365 {
	replace indicator=1 if `var'<0 & `var'!=.
}

gen CovidDeathsCum=v 
replace CovidDeathsCum=. if indicator==1

*Create a copy for reference
gen CovidDeathsCum2=CovidDeathsCum

bysort geofips (month): replace CovidDeathsCum=(CovidDeathsCum[_n+1]+CovidDeathsCum[_n-1])/2 if CovidDeathsCum==. & CovidDeathsCum[_n+1]!=. & CovidDeathsCum[_n-1]!=.
* Replaces 2,081 county-days

bysort geofips (month): replace CovidDeathsCum=(CovidDeathsCum[_n+2]+CovidDeathsCum[_n-1])/2 if CovidDeathsCum==. & CovidDeathsCum[_n+1]==. & CovidDeathsCum[_n-1]!=. & CovidDeathsCum[_n+2]!=. 
* Replaces 988 county-days

*Repeat step 1
bysort geofips (month): replace CovidDeathsCum=(CovidDeathsCum[_n+1]+CovidDeathsCum[_n-1])/2 if CovidDeathsCum==. & CovidDeathsCum[_n+1]!=. & CovidDeathsCum[_n-1]!=.
* Replaces 988 county-days


*Identifies when the drop in cases occurred
egen count_diff=rownonmiss(diff1-diff365)
*egen count_diff2=rowmiss(diff1-diff365)


gen YearMonth = . 
replace YearMonth = 202001 if inrange(month, 13, 22)
replace YearMonth = 202002 if inrange(month, 23, 51)
replace YearMonth = 202003 if inrange(month, 52, 82)
replace YearMonth = 202004 if inrange(month, 83, 112)
replace YearMonth = 202005 if inrange(month, 113, 143)
replace YearMonth = 202006 if inrange(month, 144, 173)
replace YearMonth = 202007 if inrange(month, 174, 204)
replace YearMonth = 202008 if inrange(month, 205, 235)
replace YearMonth = 202009 if inrange(month, 236, 265)
replace YearMonth = 202010 if inrange(month, 266, 296)
replace YearMonth = 202011 if inrange(month, 297, 326)
replace YearMonth = 202012 if inrange(month, 327, 357)

*2021
replace YearMonth = 202101 if inrange(month, 358, 388)
replace YearMonth = 202102 if inrange(month, 389, 416)
replace YearMonth = 202103 if inrange(month, 417, 447)
replace YearMonth = 202104 if inrange(month, 448, 477)
replace YearMonth = 202105 if inrange(month, 478, 508)
replace YearMonth = 202106 if inrange(month, 509, 538)
replace YearMonth = 202107 if inrange(month, 539, 569)
replace YearMonth = 202108 if inrange(month, 570, 600)
replace YearMonth = 202109 if inrange(month, 601, 630)
replace YearMonth = 202110 if inrange(month, 631, 661)
replace YearMonth = 202111 if inrange(month, 662, 691)
replace YearMonth = 202112 if inrange(month, 692, 722)




save "..\data\2_intermediate\CovidDeaths_CountyDay.dta", replace

use "..\data\2_intermediate\CovidDeaths_CountyDay.dta", clear

bysort geofips YearMonth: egen CovidDeathsMax=max(CovidDeathsCum)  
bysort geofips YearMonth: egen CovidDeathsMax2=max(CovidDeathsCum2)  

gen totobs=1

collapse (mean) CovidDeathsMax CovidDeathsMax2 (max) v (sum)indicator (sum)totobs, by(geofips YearMonth)

*1027 & 1131 
replace CovidDeathsMax= CovidDeathsMax[_n-1] if YearMonth==202112 & (geofips==1131 | geofips==1027)

*6051
replace CovidDeathsMax= CovidDeathsMax[_n-1] if YearMonth==202112 & geofips==6051

*6081
replace CovidDeathsMax= . if YearMonth==202106 & geofips==6081
replace CovidDeathsMax= v if YearMonth==202112 & geofips==6081

*6085
replace CovidDeathsMax=. if geofips==6085 & inrange(YearMonth, 202104, 202112)
replace CovidDeathsMax=v if YearMonth==202112 & geofips==6085 

*12005
replace CovidDeathsMax=. if geofips==12005 & YearMonth==202105
replace CovidDeathsMax=394 if geofips==12005 & (YearMonth==202105 | YearMonth==202112)

*12013
replace CovidDeathsMax=. if geofips==12013 & (YearMonth==202103 | YearMonth==202104)
replace CovidDeathsMax=v if YearMonth==202112 & geofips==12013 

*12027
replace CovidDeathsMax=. if YearMonth==202105 & geofips==12027 
replace CovidDeathsMax=v if YearMonth==202112 & geofips==12027

*12031
replace CovidDeathsMax=. if YearMonth==202105 & geofips==12031 
replace CovidDeathsMax=v if YearMonth==202112 & geofips==12031

*12039
replace CovidDeathsMax=. if YearMonth==202105 & geofips==12039 
replace CovidDeathsMax=v if YearMonth==202112 & geofips==12039

*12059
replace CovidDeathsMax=. if YearMonth==202104 & geofips==12059 
replace CovidDeathsMax=v if YearMonth==202112 & geofips==12059

*12061
replace CovidDeathsMax=. if YearMonth==202105 & geofips==12061
replace CovidDeathsMax=v if YearMonth==202112 & geofips==12061

*12069
replace CovidDeathsMax=. if YearMonth==202105 & geofips==12069
replace CovidDeathsMax=v if YearMonth==202112 & geofips==12069

*12073
replace CovidDeathsMax=. if YearMonth==202106 & geofips==12073
replace CovidDeathsMax=v if YearMonth==202112 & geofips==12073

*12077
replace CovidDeathsMax=. if YearMonth==202103 & geofips==12077
replace CovidDeathsMax=v if YearMonth==202112 & geofips==12077

*12093
replace CovidDeathsMax=. if YearMonth==202105 & geofips==12093
replace CovidDeathsMax=v if YearMonth==202112 & geofips==12093

*12105
replace CovidDeathsMax=. if YearMonth==202106 & geofips==12105
replace CovidDeathsMax=v if YearMonth==202112 & geofips==12105

*12123
replace CovidDeathsMax=. if YearMonth==202105 & geofips==12123
replace CovidDeathsMax=v if YearMonth==202112 & geofips==12123

*13061
replace CovidDeathsMax=4 if inrange(YearMonth, 202110, 202112) & geofips==13061

*20095
replace CovidDeathsMax=CovidDeathsMax[_n-1] if YearMonth==202112 & geofips==20095

*20123
replace CovidDeathsMax=. if geofips==20123 & (YearMonth==202102 | YearMonth==202103)
replace CovidDeathsMax=v if geofips==20123 & YearMonth==202112

*20127
replace CovidDeathsMax=. if geofips==20127 & (YearMonth==202109 | YearMonth==202110)
replace CovidDeathsMax=v if geofips==20127 & YearMonth==202112

*20143
replace CovidDeathsMax=14 if geofips==20143 & inrange(YearMonth, 202109, 202112)

*20157
replace CovidDeathsMax=14 if geofips==20157 & inrange(YearMonth, 202110, 202112)

*31011
replace CovidDeathsMax=4 if geofips==31011 & inrange(YearMonth, 202103, 202112)

*31013
replace CovidDeathsMax=8 if geofips==31013 & inrange(YearMonth, 202101, 202112)

*31019
replace CovidDeathsMax=57 if geofips==31019 & inrange(YearMonth, 202104, 202112)

*31023
replace CovidDeathsMax=11 if geofips==31023 & inrange(YearMonth, 202103, 202112)

*31025
replace CovidDeathsMax=. if geofips==31025 & YearMonth==202102 
replace CovidDeathsMax=16 if geofips==31025 & inrange(YearMonth, 202103, 202112)

*31027
replace CovidDeathsMax=11 if geofips==31027 & inrange(YearMonth, 202103, 202112)

*31033
replace CovidDeathsMax=16 if geofips==31033 & inrange(YearMonth, 202103, 202112)

*31045
replace CovidDeathsMax=. if geofips==31045 & inrange(YearMonth, 202011, 202112)
replace CovidDeathsMax=12 if geofips==31045 & inrange(YearMonth, 202106, 202112)

*31049
replace CovidDeathsMax=1 if geofips==31049 & inrange(YearMonth, 202102, 202112)

*31059
replace CovidDeathsMax=8 if geofips==31059 & inrange(YearMonth, 202106, 202112)
replace CovidDeathsMax=. if geofips==31059 & inrange(YearMonth, 202101, 202105)

*31071
replace CovidDeathsMax=1 if geofips==31071 & inrange(YearMonth, 202011, 202112)

*31077
replace CovidDeathsMax=1 if geofips==31077 & inrange(YearMonth, 202012, 202112)

*31093
replace CovidDeathsMax=. if geofips==31093 & inrange(YearMonth, 202012, 202105)
replace CovidDeathsMax=10 if geofips==31093 & inrange(YearMonth, 202106, 202112)

*31105
replace CovidDeathsMax=1 if geofips==31105 & inrange(YearMonth, 202011, 202112)

*31109
replace CovidDeathsMax=v if geofips==31109 & inrange(YearMonth, 202105, 202112)
replace CovidDeathsMax=. if geofips==31109 & YearMonth==202104

*31123
replace CovidDeathsMax=. if geofips==31123 & inrange(YearMonth, 202012, 202105)
replace CovidDeathsMax=v if geofips==31123 & inrange(YearMonth, 202106, 202112)

*31151
replace CovidDeathsMax=2 if geofips==31151 & inrange(YearMonth, 202011, 202112)



*31153
replace CovidDeathsMax=. if geofips==31153 & YearMonth==202105
replace CovidDeathsMax=v if geofips==31153 & inrange(YearMonth, 202106, 202112)

*31157
replace CovidDeathsMax=. if geofips==31157 & inrange(YearMonth, 202012, 202105)
replace CovidDeathsMax=v if geofips==31157 & inrange(YearMonth, 202106, 202112)

*31161
replace CovidDeathsMax=. if geofips==31161 & inrange(YearMonth, 202012, 202105)
replace CovidDeathsMax=v if geofips==31161 & inrange(YearMonth, 202106, 202112)

*31173
replace CovidDeathsMax=. if geofips==31173 & inrange(YearMonth, 202104, 202105)
replace CovidDeathsMax=v if geofips==31173 & inrange(YearMonth, 202106, 202112)

*31175
replace CovidDeathsMax=. if geofips==31175 & inrange(YearMonth, 202012, 202101)
replace CovidDeathsMax=v if geofips==31175 & inrange(YearMonth, 202106, 202112)

*31179
replace CovidDeathsMax=. if geofips==31179 & inrange(YearMonth, 202102, 202103)
replace CovidDeathsMax=v if geofips==31179 & inrange(YearMonth, 202104, 202112)

*37073
replace CovidDeathsMax=18 if geofips==37073 & inrange(YearMonth, 202110, 202112)

*45065
replace CovidDeathsMax=30 if geofips==45065 & inrange(YearMonth, 202111, 202112)

*46027
replace CovidDeathsMax=15 if geofips==46027 & inrange(YearMonth, 202101, 202108)
replace CovidDeathsMax=16 if geofips==46027 & inrange(YearMonth, 202101, 202111)
replace CovidDeathsMax=v if geofips==46027 & YearMonth==202112

*49053
replace CovidDeathsMax=0 if geofips==49053

*51830
replace CovidDeathsMax=CovidDeathsMax[_n-1] if geofips==51830 & YearMonth==202112

* tab geofips  if CovidDeathsMax==. & YearMonth==202112 // no missing dat ain the last month



gen CovidDeathsMax_check=CovidDeathsMax

**
**
bysort geofips (YearMonth): replace CovidDeathsMax=round((CovidDeathsMax[_n+11]+CovidDeathsMax[_n-1])/2) if CovidDeathsMax==. & CovidDeathsMax[_n-1]!=. & CovidDeathsMax[_n+1]==.  & CovidDeathsMax[_n+2]==. & CovidDeathsMax[_n+3]==. & CovidDeathsMax[_n+4]==. & CovidDeathsMax[_n+5]==. & CovidDeathsMax[_n+6]==. & CovidDeathsMax[_n+7]==. & CovidDeathsMax[_n+8]==. & CovidDeathsMax[_n+9]==. & CovidDeathsMax[_n+10]==.

bysort geofips (YearMonth): replace CovidDeathsMax=round((CovidDeathsMax[_n+10]+CovidDeathsMax[_n-1])/2) if CovidDeathsMax==. & CovidDeathsMax[_n-1]!=. & CovidDeathsMax[_n+1]==.  & CovidDeathsMax[_n+2]==. & CovidDeathsMax[_n+3]==. & CovidDeathsMax[_n+4]==. & CovidDeathsMax[_n+5]==. & CovidDeathsMax[_n+6]==. & CovidDeathsMax[_n+7]==. & CovidDeathsMax[_n+8]==. & CovidDeathsMax[_n+9]==.

bysort geofips (YearMonth): replace CovidDeathsMax=round((CovidDeathsMax[_n+9]+CovidDeathsMax[_n-1])/2) if CovidDeathsMax==. & CovidDeathsMax[_n-1]!=. & CovidDeathsMax[_n+1]==.  & CovidDeathsMax[_n+2]==. & CovidDeathsMax[_n+3]==. & CovidDeathsMax[_n+4]==. & CovidDeathsMax[_n+5]==. & CovidDeathsMax[_n+6]==. & CovidDeathsMax[_n+7]==. & CovidDeathsMax[_n+8]==. 

bysort geofips (YearMonth): replace CovidDeathsMax=round((CovidDeathsMax[_n+8]+CovidDeathsMax[_n-1])/2) if CovidDeathsMax==. & CovidDeathsMax[_n-1]!=. & CovidDeathsMax[_n+1]==.  & CovidDeathsMax[_n+2]==. & CovidDeathsMax[_n+3]==. & CovidDeathsMax[_n+4]==. & CovidDeathsMax[_n+5]==. & CovidDeathsMax[_n+6]==. & CovidDeathsMax[_n+7]==.

bysort geofips (YearMonth): replace CovidDeathsMax=round((CovidDeathsMax[_n+7]+CovidDeathsMax[_n-1])/2) if CovidDeathsMax==. & CovidDeathsMax[_n-1]!=. & CovidDeathsMax[_n+1]==.  & CovidDeathsMax[_n+2]==. & CovidDeathsMax[_n+3]==. & CovidDeathsMax[_n+4]==. & CovidDeathsMax[_n+5]==. & CovidDeathsMax[_n+6]==.

bysort geofips (YearMonth): replace CovidDeathsMax=round((CovidDeathsMax[_n+6]+CovidDeathsMax[_n-1])/2) if CovidDeathsMax==. & CovidDeathsMax[_n-1]!=. & CovidDeathsMax[_n+1]==.  & CovidDeathsMax[_n+2]==. & CovidDeathsMax[_n+3]==. & CovidDeathsMax[_n+4]==.  & CovidDeathsMax[_n+5]==.

bysort geofips (YearMonth): replace CovidDeathsMax=round((CovidDeathsMax[_n+5]+CovidDeathsMax[_n-1])/2) if CovidDeathsMax==. & CovidDeathsMax[_n-1]!=. & CovidDeathsMax[_n+1]==.  & CovidDeathsMax[_n+2]==. & CovidDeathsMax[_n+3]==. & CovidDeathsMax[_n+4]==.

bysort geofips (YearMonth): replace CovidDeathsMax=round((CovidDeathsMax[_n+4]+CovidDeathsMax[_n-1])/2) if CovidDeathsMax==. & CovidDeathsMax[_n-1]!=. & CovidDeathsMax[_n+1]==.  & CovidDeathsMax[_n+2]==. & CovidDeathsMax[_n+3]==.

bysort geofips (YearMonth): replace CovidDeathsMax=round((CovidDeathsMax[_n+3]+CovidDeathsMax[_n-1])/2) if CovidDeathsMax==. & CovidDeathsMax[_n-1]!=. & CovidDeathsMax[_n+1]==.  & CovidDeathsMax[_n+2]==.

bysort geofips (YearMonth): replace CovidDeathsMax=round((CovidDeathsMax[_n+2]+CovidDeathsMax[_n-1])/2) if CovidDeathsMax==. & CovidDeathsMax[_n-1]!=. & CovidDeathsMax[_n+1]==.  

bysort geofips (YearMonth): replace CovidDeathsMax=round((CovidDeathsMax[_n+1]+CovidDeathsMax[_n-1])/2) if CovidDeathsMax==. & CovidDeathsMax[_n-1]!=. & CovidDeathsMax[_n+1]!=.


************************************************************
gen CovidDeathsNew=. 
bysort geofips (YearMonth): replace CovidDeathsNew=(CovidDeathsMax[_n]-CovidDeathsMax[_n-1])
replace CovidDeathsNew=CovidDeathsMax if YearMonth==202001


gen CovidDeathsNew2=. 
bysort geofips (YearMonth): replace CovidDeathsNew2=(CovidDeathsMax2[_n]-CovidDeathsMax2[_n-1])

replace CovidDeathsNew2=CovidDeathsMax2 if YearMonth==202001

gen negvals=0
replace negvals=1 if CovidDeathsNew==.
replace negvals=1 if CovidDeathsNew<0


gen negvals2=0
replace negvals2=1 if CovidDeathsNew2==.
replace negvals2=1 if CovidDeathsNew2<0

rename CovidDeathsMax CovidDeathsCum

keep geofips YearMonth CovidDeathsNew CovidDeathsCum


save "..\data\2_intermediate\CountyCovidDeath_NewCum_Jan2020Dec2021.dta", replace

