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
}

if "`c(os)'" == "Unix" & "`c(username)'" == "ciepmx" {                          // ServidorCIEP
	sysdir set PERSONAL "/SIM/OUT/5/5.1/"
}
adopath ++ PERSONAL





************************/
***                   ***
***    0. ARRANQUE    ***
***                   ***
*************************
global id = "`c(username)'"                                                     // ID DEL USUARIO

local noisily "noisily"                                                         // "NOISILY" OUTPUTS
global nographs "nographs"                                                      // SUPRIMIR GRAFICAS
global output "output"                                                          // IMPRIMIR OUTPUTS (WEB)

local aniovp = substr(`"`c(current_date)'"',-4,4)                               // A{c N~}O VALOR PRESENTE
noisily run "`c(sysdir_personal)'/Arranque.do" `aniovp'

** OUTPUT SIMULADOR **
if "$output" == "output" {
	quietly log using "`c(sysdir_personal)'/users/$pais/$id/outputcorto.txt", replace text name(output)
	quietly log off output
}




********************************
***                          ***
***    1. CRECIMIENTO PIB    ***
***                          ***
********************************

* 2021-2027 *
global pib2021 = 6.3                                                    // CGPE 2022: 6.3
global pib2022 = 4.1                                                    // CGPE 2022: 4.1
global pib2023 = 3.4                                                    // Supuesto: 2.5
global pib2024 = 2.8                                                    // Supuesto: 2.5
global pib2025 = 2.5                                                    // Supuesto: 2.5
global pib2026 = 2.5                                                    // Supuesto: 2.5
global pib2027 = 2.5                                                    // Supuesto: 2.5

* 2026-2030 *
forvalues k=2027(1)2030 {
	global pib`k' = $pib2026                                                // SUPUESTO DE LARGO PLAZO
}

* OTROS */
global inf2021 = 5.7                                                    // CGPE 2022: 5.7
global inf2022 = 3.4                                                    // CGPE 2022: 3.4
global inf2023 = 3.0                                                    // CGPE 2022: 3.0
global inf2024 = 3.0                                                    // CGPE 2022: 3.0
global inf2025 = 3.0                                                    // CGPE 2022: 3.0
global inf2026 = 3.0                                                    // CGPE 2022: 3.0
global inf2027 = 3.0                                                    // CGPE 2022: 3.0

global def2021 = 6.2295                                                 // CGPE 2022: 6.2
global def2022 = 3.7080                                                 // CGPE 2022: 3.7
global def2023 = 3.5000                                                 // CGPE 2022: 3.5
global def2024 = 3.5000                                                 // CGPE 2022: 3.5
global def2025 = 3.5000                                                 // CGPE 2022: 3.5
global def2026 = 3.5000                                                 // CGPE 2022: 3.5
global def2027 = 3.5000                                                 // CGPE 2022: 3.5

global tasaEfectiva = 5.8131                                           // Tasa de inter{c e'}s EFECTIVA
global tipoDeCambio = 20.200                                           // Tipo de cambio
global depreciacion = 0.2000                                           // Depreciaci{c o'}n

local aniovp = 2022
local folio "folioviv foliohog"                                         // Folio del hogar
local anioend = 2030
***    FIN: PARAMETROS PIB    ***
********************************/



*******************************
**       1.1 POBLACION       **
/*forvalues k=1950(1)2100 {
foreach k in `aniovp' {
	`noisily' Poblacion, `nographs' anio(`k') //update //tf(`=64.333315/2.1*1.8') //tm2044(18.9) tm4564(63.9) tm65(35.0) //aniofinal(2040) 
}



****************************************************/
**       1.2 PIB + Deflactor, Inflacion, SCN       **
`noisily' PIBDeflactor, anio(`aniovp') `nographs' save geopib(2000) geodef(2010) discount(5.0) //update
if "$pais" == "" {
	`noisily' Inflacion, anio(`aniovp') `nographs' //update
	`noisily' SCN, anio(`aniovp') `nographs' //update
}



**********************************************
/**       1.3 Ingresos, Gastos y Deuda       **
`noisily' LIF, anio(`aniovp') `nographs' by(divGA) rows(1) //update
`noisily' PEF, anio(`aniovp') `nographs' rows(2) //update
`noisily' SHRFSP, anio(`aniovp') `nographs' //update



*******************************/
**       1.4 HOUSEHOLDS       **
capture use `"`c(sysdir_personal)'/users/$pais/bootstraps/1/PensionREC.dta"', clear
if _rc != 0 | "$export" != "" {
	local id = "$id"
	global id = ""

	** 1.2.1 HOUSEHOLDS: EXPENDITURES **
	noisily run "`c(sysdir_personal)'/Expenditure.do" `aniovp'

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
/**********************************
scalar basica      =   23113 //    Educaci{c o'}n b{c a'}sica
scalar medsup      =   21871 //    Educaci{c o'}n media superior
scalar superi      =   34743 //    Educaci{c o'}n superior
scalar posgra      =   54764 //    Posgrado
scalar eduadu      =  113600 //    Educaci{c o'}n para adultos
scalar otrose      =    1567 //    Otros gastos educativos

scalar ssa         =     519 //    SSalud
scalar prospe      =    1081 //    IMSS-Prospera
scalar segpop      =    2443 //    Seguro Popular
scalar imss        =    6250 //    IMSS (salud)
scalar issste      =    8410 //    ISSSTE (salud)
scalar pemex       =   23536 //    Pemex (salud) + ISSFAM (salud)

scalar bienestar   =   16799 //    Pensi{c o'}n Bienestar
scalar penims      =  128233 //    Pensi{c o'}n IMSS
scalar peniss      =  215747 //    Pensi{c o'}n ISSSTE
scalar penotr      = 1359427 //    Pensi{c o'}n Pemex, CFE, Pensi{c o'}n LFC, ISSFAM, Otros

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
scalar ingbasico65 =       1 //    1: Incluye mayores de 65 anios, 0: no*/

`noisily' GastoPC, anio(`aniovp') `nographs'
***    FIN: SIMULADOR GASTOS    ***
***********************************





**********************************/
***                             ***
***    3. PARTE II: INGRESOS    ***
***                             ***
/***********************************
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





*****************************************************/
***                                                ***
***       3.1. Impuesto Sobre la Renta (ISR)       ***
***                                                ***
******************************************************
*             Inferior		Superior	CF		Tasa
matrix ISR =  (0.01,		7735.00,	0.0,		1.92	\	/// 1
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
matrix	SE =  (0.01,		21227.52,	4884.24		\	/// 1
              21227.53,		23744.40,	4881.96		\	/// 2
              23744.41,		31840.56,	4879.44		\	/// 3
              31840.57,		41674.08,	4879.44		\	/// 4
              41674.09,		42454.44,	4713.24		\	/// 5
              42454.45,		53353.80,	4589.52		\	/// 6
              53353.81,		56606.16,	4250.76		\	/// 7
              56606.17,		64025.04,	3898.44		\	/// 8
              64025.05,		74696.04,	3535.56		\	/// 9
              74696.05,		85366.80,	3042.48		\	/// 10
              85366.81,		88587.96,	2611.32		\	/// 11
              88587.97, 	1E+14,		0)			//  12

*            Ex. SS.MM.	Ex. % ing. gravable		% Informalidad PF	% Informalidad Salarios
matrix DED = (5,			15,					46.28, 				0)

*           Tasa ISR PM.	% Informalidad PM
matrix PM = (30,			11.88)

* OUTPUTS (WEB) *
if "$output" == "output" {
	quietly log on output
	noisily di in w "ISRTASA: [`=string(ISR[1,4],"%10.2f")',`=string(ISR[2,4],"%10.2f")',`=string(ISR[3,4],"%10.2f")',`=string(ISR[4,4],"%10.2f")',`=string(ISR[5,4],"%10.2f")',`=string(ISR[6,4],"%10.2f")',`=string(ISR[7,4],"%10.2f")',`=string(ISR[8,4],"%10.2f")',`=string(ISR[9,4],"%10.2f")',`=string(ISR[10,4],"%10.2f")',`=string(ISR[11,4],"%10.2f")']"
	noisily di in w "ISRCUFI: [`=string(ISR[1,3],"%10.2f")',`=string(ISR[2,3],"%10.2f")',`=string(ISR[3,3],"%10.2f")',`=string(ISR[4,3],"%10.2f")',`=string(ISR[5,3],"%10.2f")',`=string(ISR[6,3],"%10.2f")',`=string(ISR[7,3],"%10.2f")',`=string(ISR[8,3],"%10.2f")',`=string(ISR[9,3],"%10.2f")',`=string(ISR[10,3],"%10.2f")',`=string(ISR[11,3],"%10.2f")']"
	noisily di in w "ISRSUBS: [`=string(SE[1,3],"%10.2f")',`=string(SE[2,3],"%10.2f")',`=string(SE[3,3],"%10.2f")',`=string(SE[4,3],"%10.2f")',`=string(SE[5,3],"%10.2f")',`=string(SE[6,3],"%10.2f")',`=string(SE[7,3],"%10.2f")',`=string(SE[8,3],"%10.2f")',`=string(SE[9,3],"%10.2f")',`=string(SE[10,3],"%10.2f")',`=string(SE[11,3],"%10.2f")',`=string(SE[12,3],"%10.2f")']"
	noisily di in w "ISRDEDU: [`=string(DED[1,1],"%10.2f")',`=string(DED[1,2],"%10.2f")',`=string(DED[1,3],"%10.2f")',`=string(DED[1,4],"%10.2f")']"
	noisily di in w "ISRMORA: [`=string(PM[1,1],"%10.2f")',`=string(PM[1,2],"%10.2f")']"
	quietly log off output
}

* Cambios ISR *
if "`cambioisr'" == "1" & "$pais" == "" {
	noisily run "`c(sysdir_personal)'/ISR_Mod.do"
	scalar ISRAS = ISR_AS_Mod
	scalar ISRPF = ISR_PF_Mod
	scalar ISRPM = ISR_PM_Mod
}
***       FIN: SIMULADOR ISR       ***
**************************************





*********************************************************
***                                                   ***
***       3.2. Impuesto al Valor Agregado (IVA)       ***
***                                                   ***
*********************************************************
matrix IVAT = (16 \     ///  1  Tasa general 
               1  \     ///  2  Alimentos, input[1]: Tasa Cero, [2]: Exento, [3]: Gravado
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
               19.06)   //  13  Evasion e informalidad IVA, input[0-100]

* OUTPUTS (WEB) *
if "$output" == "output" {
	quietly log on output
	noisily di in w "IVA: [`=string(IVAT[1,1],"%10.2f")',`=string(IVAT[2,1],"%10.0f")',`=string(IVAT[3,1],"%10.0f")',`=string(IVAT[4,1],"%10.0f")',`=string(IVAT[5,1],"%10.0f")',`=string(IVAT[6,1],"%10.0f")',`=string(IVAT[7,1],"%10.0f")',`=string(IVAT[8,1],"%10.0f")',`=string(IVAT[9,1],"%10.0f")',`=string(IVAT[10,1],"%10.0f")',`=string(IVAT[11,1],"%10.0f")',`=string(IVAT[12,1],"%10.2f")']"
	quietly log off output
}

* Cambios IVA *
if "`cambioiva'" == "1" & "$pais" == "" {
	noisily run "`c(sysdir_personal)'/IVA_Mod.do"
	scalar IVA = IVA_Mod
}
***       FIN: SIMULADOR IVA       ***
*************************************/



`noisily' TasasEfectivas, anio(`aniovp') `nographs'
***    FIN: SIMULADOR INGRESOS    ***
*************************************









***************************/
****                    ****
****    Touchdown!!!    ****
****                    ****
****************************
if "$output" == "output" {
	quietly log close output
	tempfile output1 output2 output3
	if "`=c(os)'" == "Windows" {
		filefilter "`c(sysdir_personal)'/users/$pais/$id/outputcorto.txt" `output1', from(\r\n>) to("") replace // Windows
	}
	else {
		filefilter "`c(sysdir_personal)'/users/$pais/$id/outputcorto.txt" `output1', from(\n>) to("") replace // Mac & Linux
	}
	filefilter `output1' `output2', from(" ") to("") replace
	filefilter `output2' `output3', from("_") to(" ") replace
	filefilter `output3' "`c(sysdir_personal)'/users/$pais/$id/outputcorto.txt", from(".,") to("0") replace
}

if "$latex" != "" {
	noisily scalarlatex
}

timer off 1
timer list 1
noisily di _newline(2) in g _dup(20) ":" "  " in y round(`=r(t1)/r(nt1)',.1) in g " segs  " _dup(20) ":"
