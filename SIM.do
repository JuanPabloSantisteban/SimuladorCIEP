****
**** SIMULADOR FISCAL CIEP
**** ver: ReadMe.md
****
clear all
macro drop _all
capture log close _all
timer on 1



***
*** 0. Setup
***
if "`c(username)'" == "ricardo" {						// iMac Ricardo
	sysdir set SITE "/Users/ricardo/CIEP Dropbox/Ricardo Cantú/SimuladoresCIEP/SimuladorCIEP/"
	sysdir set PERSONAL "/Users/ricardo/"
	*global export "/Users/ricardo/CIEP Dropbox/TextbookCIEP/images"
}
else if "`c(username)'" == "servidorciep" {				// Servidor CIEP
	sysdir set SITE "/home/servidorciep/CIEP Dropbox/Ricardo Cantú/SimuladoresCIEP/SimuladorCIEP/"
	sysdir set PERSONAL "/home/servidorciep/"
	*global export "/home/servidorciep/CIEP Dropbox/TextbookCIEP/images"
}
else if "`c(console)'" != "" {							// Servidor Web
	sysdir set SITE "/SIM/OUT/6/"
}

** 0.2 Parámetros y opciones iniciales
noisily run "`c(sysdir_site)'/profile.do"
global id = "ciepmx"								// IDENTIFICADOR DEL USUARIO
*global nographs "nographs"							// SUPRIMIR GRAFICAS
*global output "output"								// ARCHIVO DE SALIDA (WEB)
*global update "update"								// UPDATE BASES DE DATOS
*global textbook "textbook"							// SCALAR TO LATEX



***
**# 1. DEMOGRAFÍA
/***
*foreach entidad of global entidadesL {
	noisily Poblacion if entidad == "`entidad'", anioi(`=aniovp') aniofinal(`=`=aniovp'+25') $update
*}



***
**# 2. ECONOMÍA
***
** 2.1 Producto Interno Bruto 
noisily PIBDeflactor, aniovp(`=aniovp') geodef(1993) geopib(1993) $update $textbook

** 2.2 Sistema de Cuentas Nacionales
noisily SCN, anio(2023) $update



**/
**# 3. HOGARES
***
** 3.1 Encuesta Nacional de Ingresos y Gastos de los Hogares (Usos) **
capture confirm file "`c(sysdir_site)'/04_master/`=anioenigh'/expenditures.dta"
if _rc != 0 ///
	noisily run "`c(sysdir_site)'/Expenditure.do" `=anioenigh'
ex
** 3.2 Encuesta Nacional de Ingresos y Gastos de los Hogares (Recursos) **
capture confirm file "`c(sysdir_site)'/SIM/`=anioenigh'/households.dta"
if _rc != 0 ///
	noisily run `"`c(sysdir_site)'/Households.do"' `=anioenigh'


ex
**/
**# 3. SISTEMA FISCAL
***

** 3.1 Ley de Ingresos de la Federación
noisily LIF, by(divSIM) rows(1) anio(`=anioPE') desde(`=anioPE-1') min(0) title("Ingresos presupuestarios") $update

** 3.2 Presupuesto de Egresos de la Federación
noisily PEF, by(divSIM) rows(2) min(0) anio(`=anioPE') desde(`=anioPE-1') title("Gasto presupuestario") $update

** 3.3 Saldo Histórico de Requerimientos Financieros del Sector Público **
noisily SHRFSP, anio(`=anioPE-1') ultanio(2008) $update $textbook
ex
** 3.4 Subnacionales
//noisily run "Subnacional.do" //$update

** 3.5 Perfiles
forvalues anio = `=anioPE'(1)`=anioPE' {
	noisily di in y "PerfilesSim `anio'"
	capture confirm file "`c(sysdir_site)'/SIM/perfiles`anio'.dta"
	if _rc != 0 | "$update" == "update" ///
		noisily run "`c(sysdir_site)'/PerfilesSim.do" `anio'
}



**/
**# 4. MÓDULOS SIMULADOR
/***
if "`cambioisrpf'" == "1" {
	noisily run "`c(sysdir_site)'/ISR_Mod.do"
	scalar ISRAS  = ISR_AS_Mod
	scalar ISRPF  = ISR_PF_Mod
	scalar ISRPM  = ISR_PM_Mod
	scalar CUOTAS = CUOTAS_Mod
}
if "`cambioiva'" == "1" {
	noisily run "`c(sysdir_site)'/IVA_Mod.do"
	scalar IVA = IVA_Mod
}

** 4.1 Integración de módulos
noisily TasasEfectivas, anio(`=anioPE')
noisily GastoPC, aniope(`=anioPE') aniovp(`=aniovp')



**/
**# 5. CICLO DE VIDA
***
use `"`c(sysdir_site)'/users/$id/ingresos.dta"', clear
merge 1:1 (folioviv foliohog numren) using "`c(sysdir_site)'/users/$id/gastos.dta", nogen
capture merge 1:1 (folioviv foliohog numren) using "`c(sysdir_site)'/users/$id/isr_mod.dta", ///
	nogen replace update keepus(ISRAS ISRPF ISRPM CUOTAS)
capture merge 1:1 (folioviv foliohog numren) using "`c(sysdir_site)'/users/$id/iva_mod.dta", ///
	nogen replace update keepus(IVA)

** 5.1 (+) Impuestos y aportaciones
capture drop ImpuestosAportaciones
egen ImpuestosAportaciones = rsum(ISRPM ISRAS ISRPF CUOTAS IVA IEPSNP IEPSP ISAN IMPORT) // FMP OTROSK
label var ImpuestosAportaciones "Impuestos y otras contribuciones"
*noisily Perfiles ImpuestosAportaciones [fw=factor], aniovp(`=aniovp') aniope(`=anioPE') $nographs //boot(10)

** 5.2 (-) Impuestos y aportaciones
capture drop Transferencias
egen Transferencias = rsum(Pensiones Pensión_AM IngBasico Educación Salud) // Otras_inversiones
label var Transferencias "Transferencias públicas"
*noisily Perfiles Transferencias [fw=factor], aniovp(`=aniovp') aniope(`=anioPE') $nographs //boot(10)
*noisily Simulador Transferencias [fw=factor], aniovp(`=aniovp') aniope(`=anioPE') $nographs reboot //boot(10)

** 5.3 (=) Aportaciones netas
capture drop AportacionesNetas
g AportacionesNetas = ImpuestosAportaciones - Transferencias
label var AportacionesNetas "Ciclo de vida de las aportaciones netas"
*noisily Perfiles AportacionesNetas [fw=factor], aniovp(`=aniovp') aniope(`=anioPE') $nographs //boot(10)
noisily Simulador AportacionesNetas [fw=factor], aniovp(`=aniovp') aniope(`=anioPE') $nographs reboot //boot(10)

** 5.4 (*) Cuentas generacionales
*noisily CuentasGeneracionales AportacionesNetas, anio(`=anioPE') discount(7)



**/
**# 6. PARTE IV: DEUDA + FISCAL GAP
***

** 6.1 Brecha fiscal
noisily FiscalGap, anio(`=anioPE') end(2030) aniomin(2015) $nographs desde(`=anioPE-15') discount(10) //update

/** 6.2 Sankey del sistema fiscal
foreach k in decil grupoedad /*sexo rural escol*/ {
	noisily run "`c(sysdir_site)'/SankeySF.do" `k' `=anioPE'
}



***/
**** Touchdown!!!
****
if "$output" == "output" ///
	run "`c(sysdir_site)'/output.do"
timer off 1
timer list 1
noisily di _newline(2) in g _dup(20) ":" "  " in y "TOUCH-DOWN!!!  " round(`=r(t1)/r(nt1)',.1) in g " segs  " _dup(20) ":"
