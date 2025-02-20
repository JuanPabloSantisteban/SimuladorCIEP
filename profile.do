*********************
***               ***
*** 1 Estilo CIEP ***
***               ***
*********************
set scheme ciepnew
graph set window fontface "Ubuntu Light"
set more off, permanently
set type double, permanently
set charset latin1, permanently

global id = "`c(username)'"
*capture mkdir "`c(sysdir_site)'/SIM/"
*capture mkdir "`c(sysdir_site)'/users/"
*capture mkdir "`c(sysdir_site)'/users/$id/"



******************************
***                        ***
*** 2 PARÁMETROS GENERALES ***
***                        ***
******************************

** 2.1 Entidades Federativas **
global entidadesL `" "Aguascalientes" "Baja California" "Baja California Sur" "Campeche" "Coahuila" "Colima" "Chiapas" "Chihuahua" "Ciudad de México" "Durango" "Guanajuato" "Guerrero" "Hidalgo" "Jalisco" "Estado de México" "Michoacán" "Morelos" "Nayarit" "Nuevo León" "Oaxaca" "Puebla" "Querétaro" "Quintana Roo" "San Luis Potosí" "Sinaloa" "Sonora" "Tabasco" "Tamaulipas" "Tlaxcala" "Veracruz" "Yucatán" "Zacatecas" "Nacional" "'
global entidadesC "Ags BC BCS Camp Coah Col Chis Chih CDMX Dgo Gto Gro Hgo Jal EdoMex Mich Mor Nay NL Oax Pue Qro QRoo SLP Sin Son Tab Tamps Tlax Ver Yuc Zac Nac"

** 2.2 Valor Presente **
local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
scalar aniovp = substr(`"`=trim("`fecha'")'"',1,4)
scalar aniovp = 2025

** 2.3 Política Fiscal **
global paqueteEconomico "CGPE 2025"
scalar anioPE = 2025

** 2.4 ENIGH **
if anioPE >= 2022 {
	scalar anioenigh = 2022
}
if anioPE >= 2020 & anioPE < 2022 {
	scalar anioenigh = 2020
}
if anioPE >= 2018 & anioPE < 2020 {
	scalar anioenigh = 2018
}
if anioPE >= 2016 & anioPE < 2018 {
	scalar anioenigh = 2016
}
if anioPE >= 2013 & anioPE < 2016 {
	scalar anioenigh = 2014
}



********************
***              ***
*** 3 BIENVENIDA ***
***              ***
********************
noisily di in w _newline(50) "{bf:Centro de Investigaci{c o'}n Econ{c o'}mica y Presupuestaria, A.C.}"
noisily di _newline(2) in g `"{bf:{stata `"projmanager "`c(sysdir_site)'/simulador.stpr""': Simulador Fiscal CIEP}}"'
noisily di in g " Información Económica:  " _col(30) in y "$paqueteEconomico" ///
	_newline in g " Año de Valor Presente:  " _col(30) in y "`=aniovp'" ///
	_newline in g " Año de ENIGH:  " _col(30) in y "`=anioenigh'" ///
	_newline in g " User: " _col(30) in y "$id"

noisily di _newline `" {stata "Poblacion":Poblacion} [if entidad == "{it:Nombre}"] [, ANIOinicial(int) ANIOFINal(int) NOGraphs]"'
noisily di `" {stata "PIBDeflactor, geopib(2010) geodef(2010)":PIBDeflactor} [, ANIOvp(int) DIScount(real) NOGraphs]"'
noisily di `" {stata "Inflacion":Inflacion} [, ANIOvp(int) NOGraphs]"'
noisily di `" {stata "SCN":SCN} [, ANIO(int) NOGraphs]"'
noisily di `" {stata "LIF":LIF} [, ANIO(int) NOGraphs MINimum(real) BY(varname) ROWS(int) COLS(int) BASE]"'
noisily di `" {stata "PEF":PEF} [if] [, ANIO(int) NOGraphs MINimum(real) BY(varname) ROWS(int) COLS(int) BASE]"'
noisily di `" {stata "SHRFSP":SHRFSP} [, ANIO(int) DEPreciacion(int) NOGraphs]"' 
noisily di `" {stata "DatosAbiertos XAB":DatosAbiertos {it:serie}} [, NOGraphs DESDE(real) MES]"' 
noisily di `" {stata "TasasEfectivas":TasasEfectivas} [, ANIO(int)]"' 
noisily di `" {stata "GastoPC":GastoPC} [, ANIO(int)]"'



*********************************
***                           ***
*** 4 PARÁMETROS PARTICULARES ***
***                           ***
*********************************

** 4.1 Economía: Crecimiento anual del Producto Interno Bruto **
global pib2024 = 2.0876 // 2.578
global pib2025 = 2.2505 // 2.5007
global pib2026 = 2.5
global pib2027 = 2.5
global pib2028 = 2.5
global pib2029 = 2.5
global pib2030 = 2.5

** 4.2 Economía: Deflactor del Producto Interno Bruto **
global def2024 = 4.6
global def2025 = 4.2521
global def2026 = 3.5
global def2027 = 3.5
global def2028 = 3.5
global def2029 = 3.5
global def2030 = 3.5

** 4.3 Economía: Inflación **
global inf2024 = 4.3
global inf2025 = 3.5
global inf2026 = 3.0
global inf2027 = 3.0
global inf2028 = 3.0
global inf2029 = 3.0
global inf2030 = 3.0

** 4.4 Deuda Pública **
scalar tasaEfectiva = 6.3782

global shrfsp2024 = 51.4
global shrfspInterno2024 = 38.5
global shrfspExterno2024 = 12.9
global rfsp2024 = 5.9
global rfspPIDIREGAS2024 = -0.02
global rfspIPAB2024 = 0.03
global rfspFONADIN2024 = 0.04
global rfspDeudores2024 = 0.01
global rfspBanca2024 = -0.01
global rfspAdecuaciones2024 = 0.81
global rfspBalance2024 = 5.0
global tipoDeCambio2024 = 18.2
global balprimario2024 = -1.4
global costodeudaInterno2024 = 3.6
global costodeudaExterno2024 = 3.6

global shrfsp2025 = 51.4
global shrfspInterno2025 = 39.8
global shrfspExterno2025 = 11.6
global rfsp2025 = 3.9
global rfspPIDIREGAS2025 = 0.15
global rfspIPAB2025 = 0.1
global rfspFONADIN2025 = 0.03
global rfspDeudores2025 = 0.01
global rfspBanca2025 = -0.01
global rfspAdecuaciones2025 = 0.44
global rfspBalance2025 = 3.2
global tipoDeCambio2025 = 18.7
global balprimario2025 = -0.6
global costodeudaInterno2025 = 3.8
global costodeudaExterno2025 = 3.8

global shrfsp2026 = 51.4
global shrfspInterno2026 = 40.5
global shrfspExterno2026 = 10.9
global rfsp2026 = 3.2
global rfspPIDIREGAS2026 = 0.1
global rfspIPAB2026 = 0.1
global rfspFONADIN2026 = 0.0
global rfspDeudores2026 = 0.0
global rfspBanca2026 = 0.0
global rfspAdecuaciones2026 = 0.3
global rfspBalance2026 = 2.7
global tipoDeCambio2026 = 18.5
global balprimario2026 = -0.5
global costodeudaInterno2026 = 3.2
global costodeudaExterno2026 = 3.2

global shrfsp2027 = 51.4
global shrfspInterno2027 = 40.8
global shrfspExterno2027 = 10.6
global rfsp2027 = 2.9
global rfspPIDIREGAS2027 = 0.1
global rfspIPAB2027 = 0.1
global rfspFONADIN2027 = 0.0
global rfspDeudores2027 = -0.1
global rfspBanca2027 = 0.0
global rfspAdecuaciones2027 = 0.3
global rfspBalance2027 = 2.4
global tipoDeCambio2027 = 18.7
global balprimario2027 = -0.5
global costodeudaInterno2027 = 2.8
global costodeudaExterno2027 = 2.8

global shrfsp2028 = 51.4
global shrfspInterno2028 = 41.1
global shrfspExterno2028 = 10.3
global rfsp2028 = 2.9
global rfspPIDIREGAS2028 = 0.1
global rfspIPAB2028 = 0.1
global rfspFONADIN2028 = 0.0
global rfspDeudores2028 = 0.0
global rfspBanca2028 = 0.0
global rfspAdecuaciones2028 = 0.3
global rfspBalance2028 = 2.4
global tipoDeCambio2028 = 18.9
global balprimario2028 = -0.4
global costodeudaInterno2028 = 2.8
global costodeudaExterno2028 = 2.8

global shrfsp2029 = 51.4
global shrfspInterno2029 = 41.4
global shrfspExterno2029 = 10.0
global rfsp2029 = 2.9
global rfspPIDIREGAS2029 = 0.1
global rfspIPAB2029 = 0.1
global rfspFONADIN2029 = 0.0
global rfspDeudores2029 = 0.0
global rfspBanca2029 = 0.0
global rfspAdecuaciones2029 = 0.3
global rfspBalance2029 = 2.4
global tipoDeCambio2029 = 19.1
global balprimario2029 = -0.4
global costodeudaInterno2029 = 2.7
global costodeudaExterno2029 = 2.7

global shrfsp2030 = 51.4
global shrfspInterno2030 = 41.7
global shrfspExterno2030 = 9.7
global rfsp2030 = 2.9
global rfspPIDIREGAS2030 = 0.1
global rfspIPAB2030 = 0.1
global rfspFONADIN2030 = 0.0
global rfspDeudores2030 = 0.0
global rfspBanca2030 = 0.0
global rfspAdecuaciones2030 = 0.3
global rfspBalance2030 = 2.4
global tipoDeCambio2030 = 19.3
global balprimario2030 = -0.4
global costodeudaInterno2030 = 2.7
global costodeudaExterno2030 = 2.7


** 4.5 Parámetros: PEF **/
** 4.5.1 Parámetros: Educación **
scalar iniciaA     =     370 //    Inicial
scalar basica      =   29529 //    Educación b{c a'}sica
scalar medsup      =   28787 //    Educación media superior
scalar superi      =   38452 //    Educación superior
scalar posgra      =   59266 //    Posgrado
scalar eduadu      =   40517 //    Educación para adultos
scalar otrose      =    1713 //    Otros gastos educativos
scalar invere      =     675 //    Inversión en educación
scalar cultur      =     146 //    Cultura, deportes y recreación
scalar invest      =     380 //    Ciencia y tecnología

** 4.5.2 Parámetros: Salud **
scalar ssa         =     276 //    SSalud
scalar imssbien    =    3728 //    IMSS-Bienestar
scalar imss        =    8923 //    IMSS (salud)
scalar issste      =   11161 //    ISSSTE (salud)
scalar pemex       =   29562 //    Pemex (salud)
scalar issfam      =   17397 //    ISSFAM (salud)
scalar invers      =     240 //    Inversión en salud

** 4.5.3 Parámetros: Pensiones **
scalar pam         =   39356 //    Pensión Bienestar
scalar penimss     =  307742 //    Pensión IMSS
scalar penisss     =  410655 //    Pensión ISSSTE
scalar penpeme     =  923092 //    Pensión Pemex
scalar penotro     = 3336107 //    Pensión CFE, LFC, ISSFAM, Ferronales

** 4.5.4 Parámetros: Energía **
scalar gascfe      =    3146 //    Gasto en CFE
scalar gaspemex    =    1129 //    Gasto en Pemex
scalar gassener    =     690 //    Gasto en SENER
scalar gasinverf   =    3182 //    Gasto en inversión (energía)
scalar gascosdeue  =    1397 //    Gasto en costo de la deuda (energía)

** 4.5.5 Parámetros: Otros gastos **
scalar gasinfra    =    3890 //    Gasto en Otras Inversiones
scalar gasotros    =    4451 //    Otros gastos
scalar gasfeder    =   10720 //    Participaciones y Otras aportaciones
scalar gascosto    =    9356 //    Gasto en Costo de la deuda

** 4.5.6 Parámetros: Transferencas **
scalar IngBas      =       0 //    Ingreso b{c a'}sico
scalar ingbasico18 =       1 //    1: Incluye menores de 18 anios, 0: no
scalar ingbasico65 =       1 //    1: Incluye mayores de 65 anios, 0: no
scalar gasmadres   =     492 //    Apoyo a madres trabajadoras
scalar gascuidados =    3339 //    Gasto en cuidados

** 4.6 Parámetros: Ingresos **
scalar ISRAS       =   3.644 //    ISR (asalariados)
scalar ISRPF       =   0.231 //    ISR (personas f{c i'}sicas)
scalar CUOTAS      =   1.663 //    Cuotas (IMSS)

scalar ISRPM       =   4.011 //    ISR (personas morales)
scalar OTROSK      =   1.278 //    Productos, derechos, aprovech.

scalar FMP         =   0.772 //    Fondo Mexicano del Petróleo
scalar PEMEX       =   2.374 //    Organismos y empresas (Pemex)
scalar CFE         =   1.487 //    Organismos y empresas (CFE)
scalar IMSS        =   0.117 //    Organismos y empresas (IMSS)
scalar ISSSTE      =   0.160 //    Organismos y empresas (ISSSTE)

scalar IVA         =   4.035 //    IVA
scalar ISAN        =   0.056 //    ISAN
scalar IEPSNP      =   0.663 //    IEPS (no petrolero)
scalar IEPSP       =   1.306 //    IEPS (petrolero)
scalar IMPORT      =   0.419 //    Importaciones

** 4.7 Parámetros: ISR **/
* Anexo 8 de la Resolución Miscelánea Fiscal para 2024 *
* Tarifa para el cálculo del impuesto correspondiente al ejericio 2024 a que se refieren los artículos 97 y 152 de la Ley del ISR
* Tabla del subsidio para el empleo aplicable a la tarifa del numeral 5 del rubro B (página 773) *
*             INFERIOR			SUPERIOR		CF		TASA
matrix ISR =  (0.01,			8952.49,		0.0,		1.92	\    /// 1
		8952.49+.01,		75984.55,		171.88,		6.40	\    /// 2
		75984.55+.01,		133536.07,		4461.94,	10.88	\    /// 3
		133536.07+.01,		155229.80,		10723.55,	16.00	\    /// 4
		155229.80+.01,		185852.57,		14194.54,	17.92	\    /// 5
		185852.57+.01,		374837.88,		19682.13,	21.36	\    /// 6
		374837.88+.01,		590795.99,		60049.40,	23.52	\    /// 7
		590795.99+.01,		1127926.84,		110842.74,	30.00	\    /// 8
		1127926.84+.01,		1503902.46,		271981.99,	32.00	\    /// 9
		1503902.46+.01,		4511707.37,		392294.17,	34.00	\    /// 10
		4511707.37+.01,		1E+12,			1414947.85,	35.00)	     //  11

*             INFERIOR			SUPERIOR		SUBSIDIO
matrix	SE =  (0.01,			1768.96*12,		407.02*12		\    /// 1
		1768.96*12+.01,		2653.38*12,		406.83*12		\    /// 2
		2653.38*12+.01,		3472.84*12,		406.62*12		\    /// 3
		3472.84*12+.01,		3537.87*12,		392.77*12		\    /// 4
		3537.87*12+.01,		4446.15*12,		382.46*12		\    /// 5
		4446.15*12+.01,		4717.18*12,		354.23*12		\    /// 6
		4717.18*12+.01,		5335.42*12,		324.87*12		\    /// 7
		5335.42*12+.01,		6224.67*12,		294.63*12		\    /// 8
		6224.67*12+.01,		7113.90*12,		253.54*12		\    /// 9
		7113.90*12+.01,		7382.33*12,		217.61*12		\    /// 10
		7382.33*12+.01,		1E+12,			0)		 	     //  11

* Artículo 151, último párrafo (LISR) *
*            Ex. SS.MM.	Ex. 	% ing. gravable		% Informalidad PF	% Informalidad Salarios
matrix DED = (5,		15,			87.30, 			25.02)

* Artículo 9, primer párrafo (LISR) * 
*           Tasa ISR PM.	% Informalidad PM
matrix PM = (30,			30.55)

** 4.8 Parámetros: IMSS e ISSSTE **
* Informe al Ejecutivo Federal y al Congreso de la Unión la situación financiera y los riesgos del IMSS 2021-2022 *
* Anexo A, Cuadro A.4 *
matrix CSS_IMSS = ///
///		PATRONES	TRABAJADORES	GOBIERNO FEDERAL
		(5.42,		0.44,			3.21	\   /// Enfermedad y maternidad, asegurados (Tgmasg*)
		1.05,		0.37,			0.08	\   /// Enfermedad y maternidad, pensionados (Tgmpen*)
		1.75,		0.63,			0.13	\   /// Invalidez y vida (Tinvyvida*)
		1.83,		0.00,			0.00	\   /// Riesgos de trabajo (Triesgo*)
		1.00,		0.00,			0.00	\   /// Guarderias y prestaciones sociales (Tguard*)
		5.15,		1.12,			1.49	\   /// Retiro, cesantia en edad avanzada y vejez (Tcestyvej*)
		0.00,		0.00,			6.55)	    //  Cuota social -- hasta 25 UMA -- (TcuotaSocIMSS*)

* Informe Financiero Actuarial ISSSTE 2021 *
matrix CSS_ISSSTE = ///
///		PATRONES	TRABAJADORES	GOBIERNO FEDERAL
		(7.375,		2.750,			391.0	\   /// Seguro de salud, trabajadores en activo y familiares (Tfondomed* / TCuotaSocISSTEF)
		0.720,		0.625,			0.000	\   /// Seguro de salud, pensionados y familiares (Tpensjub*)
		0.750,		0.000,			0.000	\   /// Riesgo de trabajo
		0.625,		0.625,			0.000	\   /// Invalidez y vida
		0.500,		0.500,			0.000	\   /// Servicios sociales y culturales
		6.125,		2+3.175,		5.500	\   /// Retiro, cesantia en edad avanzada y vejez
		0.000,		5.000,			0.000	\   /// Vivienda
		0.000,		0.000,			13.9)		//  Cuota social

** 4.9 Parámetros: IVA **
matrix IVAT = (16 \     ///  1  Tasa general 
	1  \     ///  2  Alimentos, input[1]: Tasa Cero, [2]: Exento, [3]: Gravado
	2  \     ///  3  Alquiler, idem
	1  \     ///  4  Canasta basica, idem
	2  \     ///  5  Educacion, idem
	3  \     ///  6  Consumo fuera del hogar, idem
	3  \     ///  7  Mascotas, idem
	1  \     ///  8  Medicinas, idem
	1  \     ///  9  Toallas sanitarias, idem
	3  \     /// 10  Otros, idem
	2  \     /// 11  Transporte local, idem
	3  \     /// 12  Transporte foraneo, idem
	7.77)   //  13  Evasion e informalidad IVA, input[0-100]

** 4.10 Parámetros: IEPS **
* Fuente: Ley del IEPS, Artículo 2.
*              Ad valorem	Específico
matrix IEPST = (26.5	,	0 		\ /// Cerveza y alcohol 14
		30.0	,	0 		\ /// Alcohol 14+ a 20
		53.0	,	0 		\ /// Alcohol 20+
		160.0	,	0.6166		\ /// Tabaco y cigarros
		30.0	,	0 		\ /// Juegos y sorteos
		3.0	,	0 		\ /// Telecomunicaciones
		25.0	,	0 		\ /// Bebidas energéticas
		0	,	1.5737		\ /// Bebidas saborizadas
		8.0	,	0 		\ /// Alto contenido calórico
		0	,	10.7037		\ /// Gas licuado de petróleo (propano y butano)
		0	,	21.1956		\ /// Combustibles (petróleo)
		0	,	19.8607		\ /// Combustibles (diésel)
		0	,	43.4269		\ /// Combustibles (carbón)
		0	,	21.1956		\ /// Combustibles (combustible para calentar)
		0	,	6.1752		\ /// Gasolina: magna
		0	,	5.2146		\ /// Gasolina: premium
		0	,	6.7865		) // Gasolina: diésel


			
****************
***          ***
*** 5 OUTPUT ***
***          ***
****************
if "$output" != "" {
	quietly log using `"`c(sysdir_site)'/users/$id/output.txt"', replace text name(output)
	quietly log off output
}
