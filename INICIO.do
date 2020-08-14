********************
**** WAKE UP!!! ****
/********************
clear all
macro drop _all
capture log close _all
if "`c(os)'" == "Unix" {
	cd "/home/ciepmx/Dropbox (CIEP)/Simulador v5/Github/simuladorCIEP"
	sysdir set PERSONAL "/home/ciepmx/Dropbox (CIEP)/Simulador v5/Github/simuladorCIEP"
	global export "/home/ciepmx/Dropbox (CIEP)/Textbook/images/"
}
if "`c(os)'" == "MacOSX" {
	cd "/Users/ricardo/Dropbox (CIEP)/Simulador v5/Github/simuladorCIEP"
	sysdir set PERSONAL "/Users/ricardo/Dropbox (CIEP)/Simulador v5/Github/simuladorCIEP"
	global export "/Users/ricardo/Dropbox (CIEP)/Textbook/images/"
}
adopath ++ PERSONAL




**********************/
*** 0 HELLO, WORLD! ***
***********************
timer on 1
noisily di _newline(5) in g _dup(60) ":" ///
	_newline in g _dup(20) ":" in y "  HOLA, HUMANO! 8)  " in g _dup(20) ":" ///
	_newline in g _dup(60) ":"

local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
local anio = substr(`"`=trim("`fecha'")'"',1,4) // 								<-- anio base: HOY




*******************************
*** 1 POBLACION: ENIGH 2018 ***													Cap. 2. Agentes economicos
***   Simulador v5: Intro   ***
*******************************
Poblacion, anio(`anio') graphs //`update'
noisily run Households.do 2018
view "`c(sysdir_site)'../basesCIEP/SIM/2018/households.smcl"




***************************/
*** 2 ECONOMIA Y CUENTAS ***													Cap. 3. Sistema: de Cuentas Nacionales
****************************
noisily run 2PIBWeb.do




****************
*** 3 GASTOS ***
****************
noisily run 3GastosWeb.do




******************
*** 4 INGRESOS ***
******************
noisily run 4IngresosWeb.do




******************************
** 5 Cuentas Generacionales **
******************************
noisily run 5CGWeb.do //														<-- OPTIONAL!!! Toma mucho tiempo.




************************/
**** Touchdown!!! :) ****
*************************
noisily scalarlatex
timer off 1
timer list 1
noisily di _newline(2) in g _dup(20) ":" "  " in y round(`=r(t1)/r(nt1)',.1) in g " segs  " _dup(20) ":"
