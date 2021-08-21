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
**         (comentar)          **
*********************************
if"`c(os)'" == "MacOSX" & "`c(username)'" == "ricardo" {                        // Ricardo
	sysdir set PERSONAL "/Users/ricardo/Dropbox (CIEP)/SimuladorCIEP/5.1/simuladorCIEP/"
	*global export "/Users/ricardo/Dropbox (CIEP)/Textbook/images/"
	*global latex = "latex"
}

if "`c(os)'" == "Unix" & "`c(username)'" == "ciepmx" {                          // ServidorCIEP
	sysdir set PERSONAL "/home/ciepmx/Dropbox (CIEP)/SimuladorCIEP/5.1/simuladorCIEP/"
	*global export "/home/ciepmx/Dropbox (CIEP)/Textbook/images/"
}
adopath ++ PERSONAL





*************************
***                   ***
***    0. ARRANQUE    ***
***                   ***
*************************
*global pais "El Salvador"                                                      // OTROS PAISES (si aplica)
*global pais "Ecuador"                                                           // OTROS PAISES (si aplica)

local aniovp = substr(`"`c(current_date)'"',-4,4)                               // A{c N~}O VALOR PRESENTE
*local aniovp = 2020

local noisily "noisily"                                                         // "NOISILY" OUTPUTS
global nographs "nographs"                                                     // SUPRIMIR GRAFICAS
*global output "output"                                                         // IMPRIMIR OUTPUTS

noisily run "`c(sysdir_personal)'/Arranque.do" `aniovp'





********************************
***                          ***
***    1. CRECIMIENTO PIB    ***
***                          ***
********************************
if "$pais" == "" {
	global pib2021 = 5.3                                                        // Pre-CGPE 2022: 5.3
	global pib2022 = 3.6                                                        // Pre-CGPE 2022: 3.6
	global pib2023 = 2.5                                                        // Supuesto: 2.5
	global pib2024 = 2.5                                                        // Supuesto: 2.5
	global pib2025 = 2.5                                                        // Supuesto: 2.5
	global pib2026 = 2.5                                                        // Supuesto: 2.5
}
if "$pais" == "Ecuador" {
	global pib2021 = 2.5                                                        // Pre-CGPE 2022: 5.3
	global pib2022 = 1.3                                                        // Pre-CGPE 2022: 3.6
	global pib2023 = 1.7                                                        // Supuesto: 2.5
	global pib2024 = 2.0                                                        // Supuesto: 2.5
	global pib2025 = 2.3                                                        // Supuesto: 2.5
	global pib2026 = 2.5                                                        // Supuesto: 2.5
}

* 2026-2030 *
forvalues k=2027(1)2030 {
	*global pib`k' = $pib2026                                                   // SUPUESTO DE LARGO PLAZO
}

* 2031-2050 *
forvalues k=2031(1)2050 {
	*global pib`k' = $pib2025
}

* OTROS *
if "$pais" == "" {
	global inf2021 = 3.8                                                        // Pre-CGPE 2022: 3.8
	global inf2022 = 3.0                                                        // Pre-CGPE 2022: 3.0

	global def2021 = 3.7393                                                     // Pre-CGPE 2022: 3.7
	global def2022 = 3.2820                                                     // Pre-CGPE 2022: 3.2

	global tasaEfectiva = 6.7445                                                // Tasa de inter{c e'}s EFECTIVA
	global tipoDeCambio = 19.9487                                               // Tipo de cambio
	global depreciacion = 0.0000                                                // Depreciaci{c o'}n
}
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
`noisily' PIBDeflactor, anio(`aniovp') $nographs save geopib(2000) geodef(2010) //update //discount(3.0)
if "$pais" == "" {
	`noisily' Inflacion, anio(`aniovp') $nographs //update
	`noisily' SCN, anio(`aniovp') $nographs //update
}



**********************************************
**       1.3 Ingresos, Gastos y Deuda       **
`noisily' LIF, anio(`aniovp') $nographs by(divGA) rows(1) //update
`noisily' PEF, anio(`aniovp') $nographs rows(2) //update
`noisily' SHRFSP, anio(`aniovp') $nographs //update



*******************************
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
	noisily run `"`c(sysdir_personal)'/Households`=subinstr("${pais}"," ","",.)'.do"' `aniovp'
	if "$pais" == "" {
		noisily run `"`c(sysdir_personal)'/PerfilesSim.do"' `aniovp'
	}

	** 1.2.3 SANKEY **
	if "$pais" == "" & `c(version)' > 13.1 {
		foreach k in grupoedad decil escol sexo {
			noisily run "`c(sysdir_personal)'/Sankey.do" `k' `aniovp'
		}
	}
	global id = "`id'"
}



*********************************
***                            ***
***    2. PARTE III: GASTOS    ***
***                            ***
**********************************
scalar basica      =   21325 //    Educaci{c o'}n b{c a'}sica
scalar medsup      =   21056 //    Educaci{c o'}n media superior
scalar superi      =   38111 //    Educaci{c o'}n superior
scalar posgra      =   45788 //    Posgrado
scalar eduadu      =   19451 //    Educaci{c o'}n para adultos
scalar otrose      =    1476 //    Otros gastos educativos

scalar ssa         =     519 //    SSalud
scalar prospe      =    1081 //    IMSS-Prospera
scalar segpop      =    2406 //    Seguro Popular
scalar imss        =    6385 //    IMSS (salud)
scalar issste      =    8589 //    ISSSTE (salud)
scalar pemex       =   24178 //    Pemex (salud) + ISSFAM (salud)

scalar bienestar   =   17082 //    Pensi{c o'}n Bienestar
scalar penims      =  148107 //    Pensi{c o'}n IMSS
scalar peniss      =  237863 //    Pensi{c o'}n ISSSTE
scalar penotr      = 1497535 //    Pensi{c o'}n Pemex, CFE, Pensi{c o'}n LFC, ISSFAM, Otros

scalar servpers    =    3380 //    Servicios personales
scalar matesumi    =    1692 //    Materiales y suministros
scalar gastgene    =    1786 //    Gastos generales
scalar substran    =    1897 //    Subsidios y transferencias
scalar bienmueb    =     300 //    Bienes muebles e inmuebles
scalar obrapubl    =    3337 //    Obras p{c u'}blicas
scalar invefina    =     784 //    Inversi{c o'}n financiera
scalar partapor    =    8988 //    Participaciones y aportaciones
scalar costodeu    =    5862 //    Costo de la deuda

scalar IngBas      =       0 //    Ingreso b{c a'}sico
scalar ingbasico18 =       1 //    1: Incluye menores de 18 anios, 0: no
scalar ingbasico65 =       1 //    1: Incluye mayores de 65 anios, 0: no
***    FIN: PARAMETROS GASTOS    ***
***********************************


`noisily' GastoPC, anio(`aniovp') `nographs'





**********************************
***                             ***
***    3. PARTE II: INGRESOS    ***
***                             ***
***********************************
scalar ISRAS   = 3.499 //    ISR (asalariados): 3.453
scalar ISRPF   = 0.227 //    ISR (personas f{c i'}sicas): 0.441
scalar CuotasT = 1.515 //    Cuotas (IMSS): 1.515

scalar IVA     = 3.884 //    IVA: 3.885
scalar ISAN    = 0.030 //    ISAN: 0.030
scalar IEPS    = 2.026 //    IEPS (no petrolero + petrolero): 2.027
scalar Importa = 0.245 //    Importaciones: 0.245

scalar ISRPM   = 3.847 //    ISR (personas morales): 3.710
scalar FMP     = 1.361 //    Fondo Mexicano del Petr{c o'}leo: 1.362
scalar OYE     = 4.273 //    Organismos y empresas (IMSS + ISSSTE + Pemex + CFE): 4.274
scalar OtrosC  = 1.069 //    Productos, derechos, aprovechamientos, contribuciones: 1.070
***    FIN: PARAMETROS INGRESOS    ***
*************************************


******************************************************
***       3.1. Impuesto Sobre la Renta (ISR)       ***
*             Inferior		Superior	CF		Tasa
matrix ISR = (0.01,			7735.00,	0.0,		1.92	\	/// 1
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

*matrix ISR = (0.01,			7734.96,	0.0,		1.92	\	/// 1
              7734.97,		65651.07,	148.56,		6.40	\	/// 2
              65651.08,		115375.90,	3855.14,	10.88	\	/// 3
              115375.91,	134119.41,	9265.20,	16.00	\	/// 4
              134119.42,	160577.65,	12264.16,	17.92	\	/// 5
              160577.66,	323862.00,	17005.47,	21.36	\	/// 6
              323862.01,	510451.00,	51883.01,	23.52	\	/// 7
              510451.01,	974535.03,	95768.74,	30.00	\	/// 8
              974535.04,	1299380.04,	234993.95,	32.00	\	/// 9
              1299380.05,	3898140.10,	338944.34,	34.00	\	/// 10
              3898140.11,	5375382.60,	1222522.8,	36.00	\	/// 11
              5375382.61,	6949899.10,	1754330.1,	38.00	\	/// 12
              6949899.11,	8614081.10,	2352646.3,	40.00	\	/// 13
              8614081.11,	10287809.00,3018319.0,	42.00	\	/// 14
              10287809.01,	12082107.10,3721284.8,	44.00	\	/// 15
              12082107.11,	13872553.20,4510775.9,	46.00	\	/// 16
              13872553.21,	15763795.50,5334381.1,	48.00	\	/// 17
              15763795.51,	1E+14,		6242177.4,	50.00)		//  18

*matrix ISR = (0.01,			7734.96,	0.0,		1.92	\	/// 1
              7734.97,		65651.07,	148.56,		6.40	\	/// 2
              65651.08,		115375.90,	3855.14,	10.88	\	/// 3
              115375.91,	134119.41,	9265.20,	16.00	\	/// 4
              134119.42,	160577.65,	12264.16,	17.92	\	/// 5
              160577.66,	323862.00,	17005.47,	21.36	\	/// 6
              323862.01,	510451.00,	51883.01,	23.52	\	/// 7
              510451.01,	974535.03,	95768.74,	30.00	\	/// 8
              974535.04,	1299380.04,	234993.95,	32.00	\	/// 9
              1299380.05,	1600000.00, 338944.34,	35.00	\	/// 10
              1600000.01,	1900000.00,	444161.33,	36.00	\	/// 11
              1900000.01,	2660000.00,	552161.33,	38.00	\	/// 12
              2660000.01,	3500000.00,	840961.32,	40.00	\	/// 13
              3500000.01,	1E+14,		1176961.32,	42.00)		//  14

*             Inferior		Superior	Subsidio
matrix	SE = (0.01,			21227.52,	4884.24		\	/// 1
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
matrix DED = (5,			15,			46.28, 			0)

*            Tasa ISR PM.	% Informalidad PM
matrix PM = (30,			10.82)

* Cambios ISR *
local cambioISR = 0
if `cambioISR' != 0 & "$pais" == "" {
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

* Cambios IVA *
local cambioIVA = 0
if `cambioIVA' != 0 & "$pais" == "" {
	noisily run "`c(sysdir_personal)'/IVA_Mod.do"
}

capture confirm scalar IVA_Mod
if _rc == 0 {
	scalar IVA = IVA_Mod
}

if "$output" == "output" {
	quietly log on output
	noisily di in w "IVA: [`=string(IVAT[1,1],"%10.2f")',`=string(IVAT[2,1],"%10.0f")',`=string(IVAT[3,1],"%10.0f")',`=string(IVAT[4,1],"%10.0f")',`=string(IVAT[5,1],"%10.0f")',`=string(IVAT[6,1],"%10.0f")',`=string(IVAT[7,1],"%10.0f")',`=string(IVAT[8,1],"%10.0f")',`=string(IVAT[9,1],"%10.0f")',`=string(IVAT[10,1],"%10.0f")',`=string(IVAT[11,1],"%10.0f")',`=string(IVAT[12,1],"%10.2f")']"
	quietly log off output
}
***       FIN: PARAMETROS IVA       ***
**************************************



`noisily' TasasEfectivas, anio(`aniovp') `nographs'





****************************************/
***                                   ***
***    5. PARTE IV: REDISTRIBUCION    ***
***                                   ***
*****************************************
use `"`c(sysdir_personal)'/users/$pais/$id/households.dta"', clear
capture g AportacionesNetas = Laboral + Consumo + ISR__PM + Petroleo ///
	- Pension - Educacion - Salud - IngBasico - PenBienestar - Infra
if _rc != 0 {
	replace AportacionesNetas = Laboral + Consumo + ISR__PM + Petroleo ///
	- Pension - Educacion - Salud - IngBasico - PenBienestar - Infra
}
label var AportacionesNetas "las aportaciones netas"
save `"`c(sysdir_personal)'/users/$pais/$id/households.dta"', replace



************************************
**       5.1 REDISTRIBUCION       **
************************************
if "$pais" == "" {
	noisily Simulador AportacionesNetas [fw=factor], base("ENIGH 2018") boot(1) reboot nographs anio(`aniovp')
}
if "$pais" == "Ecuador" {
	noisily Simulador AportacionesNetas [fw=factor], base("ENIGHUR 2011-2012") boot(1) reboot nographs anio(`aniovp') folio(Identif_hog)
}



****************************************
**       5.2 CUENTA GENERACIONAL      **
****************************************
*noisily CuentasGeneracionales AportacionesNetas, anio(`aniovp') //boot(250) 	//	<-- OPTIONAL!!! Toma mucho tiempo.



***************************************************
**       5.3 PROYECCION DE LAS APORTACIONES       **
****************************************************
use `"`c(sysdir_personal)'/users/$pais/$id/bootstraps/1/AportacionesNetasREC.dta"', clear
merge 1:1 (anio) using "`c(sysdir_personal)'/users/$pais/$id/PIB.dta", nogen
replace estimacion = estimacion/1000000000
*replace estimacion = estimacion/pibYR*100

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
		ytitle("mil millones USD `aniovp'") ///
		///ytitle("% PIB") ///
		yscale(range(0)) /*ylabel(0(1)4)*/ ///
		ylabel(#5, format(%5.1fc) labsize(small)) ///
		xlabel(1990(10)2100, labsize(small) labgap(2)) ///
		xtitle("") ///
		legend(off) ///
		text(`=`MAX'[1,1]' `aniomax' "{bf:M{c a'}ximo:} `aniomax'", place(c)) ///
		text(`estimacionvp' `aniohoy' "{bf:Hoy:} `aniohoy'", place(c)) ///
		title("{bf:Proyecciones} de las aportaciones netas") subtitle("$pais") ///
		caption("{bf:Fuente}: Elaborado con el Simulador Fiscal CIEP v5.") ///
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





************************************************/
***                                           ***
***    6. PARTE IV: DEUDA + REDISTRIBUCION    ***
***                                           ***
*************************************************



****************************
**       6.1 SANKEY       **
****************************
if "$pais" == "" & "$export" != "" {
	foreach k in decil sexo grupoedad escol {
		noisily run "`c(sysdir_personal)'/SankeySF.do" `k' `aniovp'
	}
}



********************************
**       6.2 FISCAL GAP       **
********************************
noisily FiscalGap, anio(`aniovp') end(2030) aniomin(2015) //boot(250) //update










***************************/
****                    ****
****    Touchdown!!!    ****
****                    ****
****************************
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

if "$latex" != "" {
	noisily scalarlatex
}

timer off 1
timer list 1
noisily di _newline(2) in g _dup(20) ":" "  " in y round(`=r(t1)/r(nt1)',.1) in g " segs  " _dup(20) ":"
