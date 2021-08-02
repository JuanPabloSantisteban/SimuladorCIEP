******************************
***                        ***
***    SIMULADOR FISCAL    ***
***                        ***
******************************
clear all
macro drop _all
capture log close _all





********************************/
**    GITHUB (PROGRAMACION)    **
*********************************
if"`c(os)'" == "MacOSX" & "`c(username)'" == "ricardo" {                        // Ricardo
	sysdir set PERSONAL "/Users/ricardo/Dropbox (CIEP)/SimuladorCIEP/5.1/simuladorCIEP/"
	*global export "/Users/ricardo/Dropbox (CIEP)/Textbook/images/"
}

if "`c(os)'" == "Unix" & "`c(username)'" == "ciepmx" {                          // ServidorCIEP
	sysdir set PERSONAL "/home/ciepmx/Dropbox (CIEP)/SimuladorCIEP/5.1/simuladorCIEP/"
	*global export "/home/ciepmx/Dropbox (CIEP)/Textbook/images/"
}
adopath ++ PERSONAL                                                             // SUBIR DIRECTORIO BRANCH COMO PRINCIPAL





*************************
***                   ***
***    0. ARRANQUE    ***
***                   ***
*************************
local aniovp = substr(`"`c(current_date)'"',-4,4)                               // A{c N~}O VALOR PRESENTE
local noisily "noisily"                                                         // "NOISILY" OUTPUS
*global nographs "nographs"                                                     // SUPRIMIR GRAFICAS
*global output "output"                                                         // IMPRIMIR OUTPUTS
*global pais "El Salvador"                                                      // OTROS PAISES (si aplica)
global pais "Ecuador"                                                           // OTROS PAISES (si aplica)
local aniovp = 2020
noisily run "`c(sysdir_personal)'/Arranque.do" `aniovp'





********************************
***                          ***
***    1. CRECIMIENTO PIB    ***
***                          ***
********************************
global pib2021 = 2.5                                                            // Pre-CGPE 2022: 5.3
global pib2022 = 1.3                                                            // Pre-CGPE 2022: 3.6
global pib2023 = 1.7                                                            // Supuesto: 2.5
global pib2024 = 2.0                                                            // Supuesto: 2.5
global pib2025 = 2.3                                                            // Supuesto: 2.5
global pib2026 = 2.5                                                            // Supuesto: 2.5

* 2026-2030 *
forvalues k=2027(1)2030 {
	global pib`k' = $pib2026                                                    // SUPUESTO DE LARGO PLAZO
}

/* 2031-2050 *
forvalues k=2031(1)2050 {
	global pib`k' = $pib2025
}

* OTROS */
global inf2021 = 3.8                                                            // Pre-CGPE 2022: 3.8
global inf2022 = 3.0                                                            // Pre-CGPE 2022: 3.0

*global def2021 = 3.7393                                                         // Pre-CGPE 2022: 3.7
*global def2022 = 3.2820                                                         // Pre-CGPE 2022: 3.2

*global interesI =                                                              // Tasa de inter{c e'}s INTERNA
*global interesE =                                                              // Tasa de inter{c e'}s EXTERNA
*global porExter =                                                              // Porcentaje de deuda EXTERNA
*global tipoDeCa =                                                              // Tipo de cambio
*global deprecia =                                                              // Depreciaci{c o'}n
***    FIN: PARAMETROS PIB    ***
********************************/


*******************************
**       1.1 POBLACION       **
*forvalues k=1950(1)2100 {
foreach k in `aniovp' {
	`noisily' Poblacion, $nographs anio(`k') //update //tf(`=64.333315/2.1*1.8') //tm2044(18.9) tm4564(63.9) tm65(35.0) //aniofinal(2040) 
}


*****************************************************
**       1.2 PIB + Deflactor, Inflacion, SCN       **
`noisily' PIBDeflactor, anio(`aniovp') $nographs save //update //geo(`geo') //discount(3.0)
if "$pais" == "" {
	`noisily' Inflacion, anio(`aniovp') $nographs //update
	`noisily' SCN, anio(`aniovp') $nographs //update
}


**********************************************
**       1.3 Ingresos, Gastos y Deuda       **
`noisily' LIF, anio(`aniovp') $nographs //update
`noisily' PEF, anio(`aniovp') $nographs rows(2) //update
`noisily' SHRFSP, anio(`aniovp') $nographs //update
exit


*******************************/
**       1.3 HOUSEHOLDS       **
capture use `"`c(sysdir_personal)'/users/$pais/bootstraps/1/PensionREC.dta"', clear
if _rc != 0 | "$export" != "" {
	local id = "$id"
	global id = ""

	** 1.2.1 HOUSEHOLDS: EXPENDITURES **
	if "$pais" == "" {
		noisily run "`c(sysdir_personal)'/Expenditure.do" `aniovp'
	}

	** 1.2.2 HOUSEHOLDS: INCOMES **
	noisily run `"`c(sysdir_personal)'/Households.do"' `aniovp'
	noisily run `"`c(sysdir_personal)'/PerfilesSim.do"' `aniovp'

	** 1.2.3 SANKEY **
	if `c(version)' > 13.1 {
		foreach k in grupoedad decil escol sexo {
			noisily run "`c(sysdir_personal)'/Sankey.do" `k' `aniovp'
		}
	}
	global id = "`id'"
}



*********************************/
***                            ***
***    2. PARTE III: GASTOS    ***
***                            ***
**********************************
scalar basica      =   21666 //    Educaci{c o'}n b{c a'}sica
scalar medsup      =   21393 //    Educaci{c o'}n media superior
scalar superi      =   38720 //    Educaci{c o'}n superior
scalar posgra      =   46520 //    Posgrado
scalar eduadu      =   19762 //    Educaci{c o'}n para adultos
scalar otrose      =    1500 //    Otros gastos educativos

scalar ssa         =     528 //    SSalud
scalar prospe      =    1081 //    IMSS-Prospera
scalar segpop      =    2445 //    Seguro Popular
scalar imss        =    6487 //    IMSS (salud)
scalar issste      =    8726 //    ISSSTE (salud)
scalar pemex       =   24564 //    Pemex (salud) + ISSFAM (salud)

scalar bienestar   =   17355 //    Pensi{c o'}n Bienestar
scalar penims      =  150469 //    Pensi{c o'}n IMSS
scalar peniss      =  241652 //    Pensi{c o'}n ISSSTE
scalar penotr      = 1521475 //    Pensi{c o'}n Pemex, CFE, Pensi{c o'}n LFC, ISSFAM, Otros

scalar servpers    =    3434 //    Servicios personales
scalar matesumi    =    1720 //    Materiales y suministros
scalar gastgene    =    1815 //    Gastos generales
scalar substran    =    1928 //    Subsidios y transferencias
scalar bienmueb    =     305 //    Bienes muebles e inmuebles
scalar obrapubl    =    3390 //    Obras p{c u'}blicas
scalar invefina    =     796 //    Inversi{c o'}n financiera
scalar partapor    =    9132 //    Participaciones y aportaciones
scalar costodeu    =    5955*0 //    Costo de la deuda

scalar IngBas      =       0 //    Ingreso b{c a'}sico
scalar ingbasico18 =       1 //    1: Incluye menores de 18 anios, 0: no
scalar ingbasico65 =       1 //    1: Incluye mayores de 65 anios, 0: no
***    FIN: PARAMETROS GASTOS    ***
***********************************/

`noisily' GastoPC, anio(`aniovp') `nographs'





**********************************/
***                             ***
***    3. PARTE II: INGRESOS    ***
***                             ***
***********************************
scalar ISRAS   = 3.491 //    ISR (asalariados): 3.453
scalar ISRPF   = 0.227 //    ISR (personas f{c i'}sicas): 0.441
scalar CuotasT = 1.512 //    Cuotas (IMSS): 1.515

scalar IVA     = 3.876 //    IVA: 3.885
scalar ISAN    = 0.030 //    ISAN: 0.030
scalar IEPS    = 2.022 //    IEPS (no petrolero + petrolero): 2.027
scalar Importa = 0.244 //    Importaciones: 0.245

scalar ISRPM   = 3.839 //    ISR (personas morales): 3.710
scalar FMP     = 1.358 //    Fondo Mexicano del Petr{c o'}leo: 1.362
scalar OYE     = 4.264 //    Organismos y empresas (IMSS + ISSSTE + Pemex + CFE): 4.274
scalar OtrosC  = 1.067 //    Productos, derechos, aprovechamientos, contribuciones: 1.070
***    FIN: PARAMETROS INGRESOS    ***
*************************************/


******************************************************
***       3.1. Impuesto Sobre la Renta (ISR)       ***
*             Inferior		Superior	CF		Tasa
matrix ISR = (0.01,		7735.00,	0.0,		1.92	\	/// 1
              7735.01,		65651.07,	148.51,		6.40	\	/// 2
              65651.08,		115375.90,	3855.14,	10.88	\	/// 3
              115375.91,	134119.41,	9265.20,	16.00	\	/// 4
              134119.42,	160577.65,	12264.16,	17.92	\	/// 5
              160577.66,	323862.00,	17005.47,	21.36	\	/// 6
              323862.01,	510451.00,	51883.01,	23.52	\	/// 7
              510451.01,	974535.03,	95768.74,	30.00	\	/// 8
              974535.04,	1299380.04,	234993.95,	32.00	\	/// 9
              1299380.05,	3898140.12,	338944.34,	34.00	\	/// 10
              3898140.13,	1E+14,		1222522.76,	35.00)		//  11

*             Inferior		Superior	Subsidio
matrix	SE = (0.01,		21227.52,	4884.24		\	/// 1
              21227.53,		31840.56,	4881.96		\	/// 2
              31840.57,		41674.08,	4879.44		\	/// 3
              41674.09,		42454.44,	4713.24		\	/// 4
              42454.45,		53353.80,	4589.52		\	/// 5
              53353.81,		56606.16,	4250.76		\	/// 6
              56606.17,		64025.04,	3898.44		\	/// 7
              64025.05,		74696.04,	3535.56		\	/// 8
              74696.05,		85366.80,	3042.48		\	/// 9
              85366.81,		88587.96,	2611.32		\	/// 10
              88587.97, 	1E+14,		0)			//  11

*             Ex. SS.MM.	Ex. % ing. gravable	% Informalidad PF	% Informalidad Salarios
matrix DED = (5,		15,			46.28, 			0)

*            Tasa ISR PM.	% Informalidad PM
matrix PM = (30,		10.81)

* Cambios ISR */
local cambioISR = 0
if `cambioISR' != 0 {
	noisily run "`c(sysdir_personal)'/ISR_Mod.do"
}

capture confirm scalar ISR_AS_Mod
if _rc == 0 {
	scalar ISRAS = ISR_AS_Mod
	scalar ISRPF = ISR_PF_Mod
	scalar ISRPM = ISR_PM_Mod
}
***       FIN: PARAMETROS ISR       ***
***************************************


if "$output" == "output" {
	quietly log on output
	noisily di in w "ISRTASA: [`=string(ISR[1,4],"%10.2f")',`=string(ISR[2,4],"%10.2f")',`=string(ISR[3,4],"%10.2f")',`=string(ISR[4,4],"%10.2f")',`=string(ISR[5,4],"%10.2f")',`=string(ISR[6,4],"%10.2f")',`=string(ISR[7,4],"%10.2f")',`=string(ISR[8,4],"%10.2f")',`=string(ISR[9,4],"%10.2f")',`=string(ISR[10,4],"%10.2f")',`=string(ISR[11,4],"%10.2f")']"
	noisily di in w "ISRCUFI: [`=string(ISR[1,3],"%10.2f")',`=string(ISR[2,3],"%10.2f")',`=string(ISR[3,3],"%10.2f")',`=string(ISR[4,3],"%10.2f")',`=string(ISR[5,3],"%10.2f")',`=string(ISR[6,3],"%10.2f")',`=string(ISR[7,3],"%10.2f")',`=string(ISR[8,3],"%10.2f")',`=string(ISR[9,3],"%10.2f")',`=string(ISR[10,3],"%10.2f")',`=string(ISR[11,3],"%10.2f")']"
	noisily di in w "ISRSUBS: [`=string(SE[1,3],"%10.2f")',`=string(SE[2,3],"%10.2f")',`=string(SE[3,3],"%10.2f")',`=string(SE[4,3],"%10.2f")',`=string(SE[5,3],"%10.2f")',`=string(SE[6,3],"%10.2f")',`=string(SE[7,3],"%10.2f")',`=string(SE[8,3],"%10.2f")',`=string(SE[9,3],"%10.2f")',`=string(SE[10,3],"%10.2f")',`=string(SE[11,3],"%10.2f")',`=string(SE[12,3],"%10.2f")']"
	noisily di in w "ISRDEDU: [`=string(DED[1,1],"%10.2f")',`=string(DED[1,2],"%10.2f")',`=string(DED[1,3],"%10.2f")']"
	noisily di in w "ISRMORA: [`=string(PM[1,1],"%10.2f")',`=string(PM[1,2],"%10.2f")']"
	quietly log off output
}


********************************************************
***       3.2. Impuesto al Valor Agregado (VA)       ***
********************************************************
matrix IVAT = (16 \     ///  1  Tasa general 
               1  \     ///  2  Alimentos, 1: Tasa Cero, 2: Exento, 3: Gravado
               2  \     ///  3  Alquiler, idem
               1  \     ///  4  Canasta basica, idem
               2  \     ///  5  Educacion, idem
               3  \     ///  6  Consumo fuera del hogar, idem
               3  \     ///  7  Mascotas, idem
               1  \     ///  8  Medicinas, idem
               3  \     ///  9  Toallas sanitarias, idem
               3  \     /// 10  Otros, idem
               2  \     /// 11  Transporte local, idem
               3  \     /// 12  Transporte foraneo, idem
               39.94)   //  13  Evasion e informalidad IVA, idem

* Cambios IVA */
local cambioIVA = 0
if `cambioIVA' != 0 {
	noisily run "`c(sysdir_personal)'/IVA_Mod.do"
}

capture confirm scalar IVA_Mod
if _rc == 0 {
	scalar IVA = IVA_Mod
}
***       FIN: PARAMETROS IVA       ***
***************************************


if "$output" == "output" {
	quietly log on output
	noisily di in w "IVA: [`=string(IVAT[1,1],"%10.2f")',`=string(IVAT[2,1],"%10.0f")',`=string(IVAT[3,1],"%10.0f")',`=string(IVAT[4,1],"%10.0f")',`=string(IVAT[5,1],"%10.0f")',`=string(IVAT[6,1],"%10.0f")',`=string(IVAT[7,1],"%10.0f")',`=string(IVAT[8,1],"%10.0f")',`=string(IVAT[9,1],"%10.0f")',`=string(IVAT[10,1],"%10.0f")',`=string(IVAT[11,1],"%10.0f")',`=string(IVAT[12,1],"%10.2f")']"
	quietly log off output
}

noisily TasasEfectivas, anio(`aniovp') `nographs'





****************************************/
***                                   ***
***    5. PARTE IV: REDISTRIBUCION    ***
***                                   ***
*****************************************
use `"`c(sysdir_personal)'/users/$pais/$id/households.dta"', clear
capture g AportacionesNetas = Laboral + Consumo + ISR__PM + ing_cap_fmp ///
	- Pension - Educacion - Salud - IngBasico - PenBienestar - Infra
if _rc != 0 {
	replace AportacionesNetas = Laboral + Consumo + ISR__PM + ing_cap_fmp ///
	- Pension - Educacion - Salud - IngBasico - PenBienestar - Infra
}
label var AportacionesNetas "las aportaciones netas"
save `"`c(sysdir_personal)'/users/$pais/$id/households.dta"', replace


************************************
**       5.1 REDISTRIBUCION       **
************************************
noisily Simulador AportacionesNetas [fw=factor], base("ENIGH 2018") boot(1) reboot nographs anio(`aniovp')


****************************************
**       5.2 CUENTA GENERACIONAL      **
***************************************
noisily CuentasGeneracionales AportacionesNetas, anio(`aniovp') //boot(250) 	//	<-- OPTIONAL!!! Toma mucho tiempo.


***************************************************/
**       5.3 PROYECCION DE LAS APORTACIONES       **
****************************************************
use `"`c(sysdir_personal)'/users/$pais/$id/bootstraps/1/AportacionesNetasREC.dta"', clear
merge 1:1 (anio) using "`c(sysdir_personal)'/users/$pais/$id/PIB.dta", nogen
*replace estimacion = estimacion/1000000000000
replace estimacion = estimacion/pibYR*100

forvalues aniohoy = `aniovp'(1)`aniovp' {
*forvalues aniohoy = 1990(1)2050 {
	tabstat estimacion, stat(max) save
	tempname MAX
	matrix `MAX' = r(StatTotal)
	forvalues k=1(1)`=_N' {
		if estimacion[`k'] == `MAX'[1,1] {
			local aniomax = anio[`k']
		}
		if anio[`k'] == `aniohoy' {
			local estimacionvp = estimacion[`k']
		}
	}

	if "$nographs" == "" {
		twoway (connected estimacion anio) ///
		(connected estimacion anio if anio == `aniohoy') ///
		if anio > 1990, ///
		///ytitle("billones MXN `aniovp'") ///
		ytitle("% PIB") ///
		yscale(range(0)) /*ylabel(0(1)4)*/ ///
		ylabel(#5, format(%5.1fc) labsize(small)) ///
		xlabel(1990(10)2050, labsize(small) labgap(2)) ///
		xtitle("") ///
		legend(off) ///
		text(`=`MAX'[1,1]' `aniomax' "{bf:M{c a'}ximo:} `aniomax'", place(c)) ///
		text(`estimacionvp' `aniohoy' "{bf:Hoy:} `aniohoy'", place(c)) ///
		///title("{bf:Proyecciones} de las aportaciones netas") subtitle("$pais") ///
		///caption("Fuente: Elaborado con el Simulador Fiscal CIEP v5.") ///
		name(AportacionesNetasProj, replace)

		capture confirm existence $export
		if _rc == 0 {
			graph export "$export/AportacionesNetasProj`aniohoy'.png", replace name(AportacionesNetasProj)
		}
	}

}


if "$output" == "output" {
	forvalues k=1(5)`=_N' {
		if anio[`k'] >= 2010 {
			local out_proy = "`out_proy' `=string(estimacion[`k'],"%8.3f")',"
		}
	}

	local lengthproy = strlen("`out_proy'")
	quietly log on output
	noisily di in w "PROY: [`=substr("`out_proy'",1,`=`lengthproy'-1')']"
	noisily di in w "PROYMAX: [`aniomax']"
	quietly log off output
}




*******************************/
***                          ***
***    6. PARTE IV: DEUDA    ***
***                          ***
********************************


****************************
**       6.1 SANKEY       **
****************************
if "$export" != "" {
	foreach k in decil sexo grupoedad escol {
		noisily run "`c(sysdir_personal)'/SankeySF.do" `k' `aniovp'
	}
}


********************************
**       6.2 FISCAL GAP       **
********************************
noisily FiscalGap, anio(`aniovp') end(2030) //boot(250) //update

if "$output" == "output" {
	quietly log close output
	tempfile output1 output2 output3
	if "`=c(os)'" == "Windows" {
		filefilter "`c(sysdir_personal)'/users/$pais/$id/output.txt" `output1', from(\r\n>) to("") replace // Windows
	}
	else {
		filefilter "`c(sysdir_personal)'/users/$pais/$id/output.txt" `output1', from(\n>) to("") replace // Mac & Linux
	}
	filefilter `output1' `output2', from(" ") to("") replace
	filefilter `output2' `output3', from("_") to(" ") replace
	filefilter `output3' "`c(sysdir_personal)'/users/$pais/$id/output.txt", from(".,") to("0") replace
}





***************************/
****                    ****
****    Touchdown!!!    ****
****                    ****
****************************
if "$export" != "" {
	noisily scalarlatex
}
timer off 1
timer list 1
noisily di _newline(2) in g _dup(20) ":" "  " in y round(`=r(t1)/r(nt1)',.1) in g " segs  " _dup(20) ":"
