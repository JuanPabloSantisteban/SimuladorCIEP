**************************
**** HOLA, HUMANO! :) ****
**** SET UP FRAMEWORK ****
**************************
if "`c(os)'" == "Unix" {
	sysdir set SITE "/home/ciepmx/Dropbox (CIEP)/Github/simuladorCIEP"
	sysdir set PERSONAL "/home/ciepmx/Dropbox (CIEP)/TemplateCIEP/simuladorCIEP"
}
if "`c(os)'" == "MacOSX" {
	sysdir set SITE "/Users/ricardo/Dropbox (CIEP)/Github/simuladorCIEP"
	sysdir set PERSONAL "/Users/ricardo/Dropbox (CIEP)/TemplateCIEP/simuladorCIEP"
}
clear all
timer on 1




*********************
*** 1. Parametros ***
*********************
global anioVP = 2019
global pib2018 = 2.5						// pib[input]
global pib2019 = 3.0						// pib[input]
global def2018 = 4.8						// def[input]
global def2019 = 3.3						// def[input]

local graphs "graphs"
local update ""




***********************
*** 2. Informativos ***
***********************
do "`c(sysdir_site)'/UpdateDatosAbiertos.do"			// TO UPDATE: uncomment to actualizar bases de Datos Abiertos de SHCP
Poblacion, `graphs'						// update: rarely used
SCN, `graphs'							// TO UPDATE: abrir y guardar archivos .iqy (./bases/INEGI/SCN/)
PIBDeflactor, `graphs'						// TO UPDATE: abrir y guardar archivos .iqy (./bases/INEGI/SCN/)




*******************/
*** 3. Escencial ***
********************
noisily LIF, `graphs' `update'
noisily PEF, `graphs' `update' rows(3) datos			// DATOS: con informacion de DatosAbiertos.





********************/
*** 4. Incidencia ***
*********************
noisily run "`c(sysdir_site)'/Income.do" 2016
noisily run "`c(sysdir_site)'/Expenditure.do" 2016
*noisily SHRFSP, graphs update



*noisily Eficiencia
*noisily Eficiencia, reboot graphs noisily update
*noisily TransfNetas, graphs update




**********************/
*** 3. Simulaciones ***
/***********************
local id "MexTax"
capture mkdir "`c(sysdir_personal)'/users/`id'/"
capture log using "`c(sysdir_personal)'/users/`id'/log `c(current_date)'", replace
noisily di _newline(5) in g _dup(50) "+" in y "$simuladorCIEP. (ID: `id'): `c(current_date)' `c(current_time)'" in g _dup(50) "+"



************
************
** Gastos **

* Educaci${o}n *
scalar sbasica = 1.993								// Educaci${o}n b${a}sica
scalar smedias = 0.410								// Educaci${o}n media superior
scalar ssuperi = 0.521								// Educaci${o}n superior
scalar sposgra = 0.033								// Posgrado

* Pensiones *
scalar spam    = 0.172								// Pensi${o}n para adultos mayores
scalar spenims = 1.678								// Pensi${o}n IMSS
scalar speniss = 0.901								// Pensi${o}n ISSSTE
scalar spenpem = 0.278								// Pensi${o}n Pemex
scalar spencfe = 0.168								// Pensi${o}n CFE
scalar spenlfc = 0.426								// Pensi${o}n LFC, ISSFAM, Otros

* Salud *
scalar sssa    = 0.212								// SSalud
scalar ssegpop = 0.706								// Seguro Popular
scalar simss   = 1.205								// IMSS (salud)
scalar sissste = 0.239								// ISSSTE (salud)
scalar sprospe = 0.052								// IMSS-Prospera
scalar spemex  = 0.097								// Pemex (salud)

* Extras *
scalar singbas = 0.000								// Ingreso b${a}sico	
scalar pamgeneral = 1								// PAM general
scalar ivageneral = 1								// IVA general
scalar ingbasico18 = 1								// Ingreso b${a}sico a menores de 18 a${ni}os
scalar ingbasico65 = 1								// Ingreso b${a}sico a mayores de 65 a${ni}os

* Otros gastos *
scalar servpers = 1.813								// Servicios personales
scalar matesumi = 0.933								// Materiales y suministros
scalar gastgene = 0.853								// Gastos generales
scalar substran = 1.455								// Subsidios y transferencias
scalar bienmueb = 0.196								// Bienes muebles e inmuebles
scalar obrapubl = 1.265								// Obras p${u}blicas
scalar invefina = 0.094								// Inversi${o}n financiera
scalar partapor = 4.428								// Participaciones y aportaciones
scalar deudpubl = 2.890								// Deuda p${u}blica



**************
** Ingresos **
**************

* Al ingreso *
scalar sISR__as = 2.901								// ISR (asalariados)
scalar sISR__PF = 0.402								// ISR (personas f${i}sicas)
scalar sCuotasT = 1.345								// Cuotas (IMSS)

* Al consumo *
scalar sIVA     = 3.813 							//+2.901+0.402+1.345+.709+1.125+.046+.206+2.3+(singbas*.24*(1-.06608))+(spam*.24*(1-.06608))								// IVA
scalar sIEPS    = (0.709 + 1.125) 						// IEPS (no petrolero + petrolero)
scalar sISAN    = 0.046								// ISAN
scalar sImporta = 0.206								// Importaciones

* Al capital *
scalar sISR__PM = 3.508								// ISR (personas morales)
scalar sFMP_Der = 1.986								// Fondo Mexicano del Petr${o}leo
scalar sOYE     = (0.119 + 0.228 + 1.841 + 1.656)				// Organismos y empresas (IMSS + ISSSTE + Pemex + CFE)

*noisily TasaFairTax `=sIVA-((singbas*.24*(1-.06608))+(spam*.24*(1-.06608)))'




********************
** 3.1 Resultados **
global depreMXN = 0					// % de depreciaci${o}n (SHRFSP.ado)

run "`c(sysdir_personal)'/Modulos.do" `id' $anioVP
noisily Eficiencia, id(`id') graphs
*noisily TransfNetas, id(`id') graphs reboot //noisily
*noisily SHRFSP, id(`id') graphs

capture log close





*********************/
*** 4. Touch Down! ***
**********************
timer off 1
timer list 1
noisily di _newline in g _dup(55) "+" in y round(`=r(t1)/r(nt1)',.1) in g " segs." _dup(55) "+" _newline(5)
