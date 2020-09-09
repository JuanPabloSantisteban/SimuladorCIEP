****************************
*** 2 ECONOMIA Y CUENTAS ***													Cap. 3. Sistema: de Cuentas Nacionales
****************************
timer on 99
local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
local anio = substr(`"`=trim("`fecha'")'"',1,4) // 								<-- anio base: HOY
local anio = 2021




***********************************
** PAR{c A'}METROS DEL SIMULADOR **
if "$param" == "on" {
	global id = "$id"

	*sysdir set PERSONAL "/home/ciepmx/Dropbox (CIEP)/Simulador v5/Github/simuladorCIEP"
	*adopath ++ PERSONAL
	*capture mkdir "`c(sysdir_personal)'/users/$pais/$id/"

	* Crecimiento PIB *
	global pib2020 = -8.0
	global pib2021 =  4.6
	global pib2022 =  2.6
	global pib2023 =  2.5
	global pib2024 =  2.5
	global pib2025 =  2.5
	global pib2026 =  2.5

	global def2020 =  3.568
	global def2021 =  3.425

}
***********************************/




noisily PIBDeflactor, anio(`anio') //nographs //update //discount(3.0)
if `c(version)' > 13.1 {
	saveold "`c(sysdir_personal)'/users/$pais/$id/PIB.dta", replace version(13)
}
else {
	save "`c(sysdir_personal)'/users/$pais/$id/PIB.dta", replace
}
noisily SCN, anio(`anio') //nographs




************************/
**** Touchdown!!! :) ****
*************************
timer off 99
timer list 99
noisily di _newline(2) in g _dup(20) "." "  " in y round(`=r(t99)/r(nt99)',.1) in g " segs  " _dup(20) "."
