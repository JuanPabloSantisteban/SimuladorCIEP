******************************************************************
****                                                          ****
**** A.2. MACRO + MICRO HARMONIZATION: HOUSEHOLD EXPENDITURES ****
****                                                          ****
******************************************************************



*********************
***               ***
***  0. Defaults  ***
***               ***
*********************
timer on 15
if "`1'" == "" {
	clear all
	scalar anioenigh = 2022
	local claveiva = "*2018"
}
else {
	if `1' >= 2022 {
		scalar anioenigh = 2022
		local claveiva = "*2018"
	}
	if `1' >= 2020 & `1' < 2022 {
		scalar anioenigh = 2020
		local claveiva = "*2018"
	}
	if `1' >= 2018 & `1' < 2020 {
		scalar anioenigh = 2018
		local claveiva = "*2018"
	}
	if `1' >= 2016 & `1' < 2018 {
		scalar anioenigh = 2016
		local claveiva = "*2014"
	}
	if `1' >= 2013 & `1' < 2016 {
		scalar anioenigh = 2014
		local claveiva = "*2014"
	}
}


** 0.1 Directorios y log files **
capture log close expenditures
capture mkdir "`c(sysdir_site)'/03_temp/`=anioenigh'"
log using "`c(sysdir_site)'/03_temp/`=anioenigh'/expenditures.smcl", replace name(expenditures)


** 0.2 Texto introductorio **
noisily di _newline(2) in g _dup(20) "." "{bf:   Economía generacional: " in y "GASTOS - ENIGH `=anioenigh'  }" in g _dup(20) "."





**********************************
***                            ***
***  1. DATOS MACROECONóMICOS  ***
***                            ***
**********************************

** 1.1 Sistema de Cuentas Nacionales **
SCN, anio(`=anioenigh') nographs


** 1.2 SHCP: Datos Abiertos **
LIF, anio(`=anioenigh') by(divCIEP) nographs min(0)
local IVA = r(IVA)
local IEPSNP = r(IEPS__no_petrolero_) //+r(IEPS__petrolero_)
local IepsTabaco = r(Tabacos)
local IepsJuegos = r(Juegos)
local IepsTelecom = r(Telecom)
local IepsBebidasEner = r(Energiza)
local IepsBebidasSabor = r(Saboriza)
local IepsAltoContCal = r(AlimNoBa)
local IepsCombustibles = r(Fosiles)
local IepsGasolinas = r(IEPS__petrolero_)
local IepsAlcohol_20 = r(Alcohol)*.2
local IepsAlcohol_20_ = r(Alcohol)*.2
local IepsCervezas = r(Alcohol)*.6


** 1.3 Población **
Poblacion, anio(`=anioenigh') nographs
tabstat poblacion if anio == `=anioenigh', stat(sum) save f(%15.0fc)
local pobtotNacional = r(StatTotal)[1,1]




**********************************
***                            ***
***  2. DATOS MICROECONóMICOS  ***
***                            ***
**********************************
capture confirm file "`c(sysdir_site)'/03_temp/`=anioenigh'/preconsumption.dta"
*if _rc != 0 {
if _rc == 0 {

	** 2.1. Base de datos de gastos de los hogares **
	use "`c(sysdir_site)'/01_raw/ENIGH/`=anioenigh'/gastospersona.dta", clear
	append using "`c(sysdir_site)'/01_raw/ENIGH/`=anioenigh'/gastohogar.dta"
	append using "`c(sysdir_site)'/01_raw/ENIGH/`=anioenigh'/gastotarjetas.dta"
	append using "`c(sysdir_site)'/01_raw/ENIGH/`=anioenigh'/erogaciones.dta"


	** 2.2. Gasto anual **
	egen gasto_anual = rsum(gas_nm_tri gasto_tri)
	replace gasto_anual = gasto_anual*4
	format gasto_anual %10.2fc


	** 2.3. Variables sociodemograficas **
	merge m:1 (folioviv foliohog) using "`c(sysdir_site)'/01_raw/ENIGH/`=anioenigh'/concentrado.dta", nogen keepus(factor) update replace
	merge m:1 (folioviv) using "`c(sysdir_site)'/01_raw/ENIGH/`=anioenigh'/vivienda.dta", keepus(ubica_geo tenencia) nogen update replace
	capture rename factor_hog factor


	** 2.4. Quitar gastos "no necesarios" **
	// T916: gasto en regalos a personas ajenas al hogar, erogaciones financieras y de capital. 
	// N012: Pérdidas y robos de dinero
	drop if clave == "T916" | clave == "N012"


	** 2.5. Gasto en educación *
	replace inscrip = 0 if inscrip == . & clave >= "E001" & clave <= "E007"
	replace colegia = 0 if colegia == . & clave >= "E001" & clave <= "E007"
	replace material = 0 if material == . & clave >= "E001" & clave <= "E007"
	//replace gasto_anual = inscrip + colegia*12 + material if clave >= "E001" & clave <= "E007"


	** 2.6. Deducciones personales del ISR **
	g deduc_gasto_colegi1 = gasto_anual if clave == "E001"
	g deduc_gasto_colegi2 = gasto_anual if clave == "E002"
	g deduc_gasto_colegi3 = gasto_anual if clave == "E003"
	g deduc_gasto_colegi4 = gasto_anual if clave == "E007"
	g deduc_gasto_colegi5 = gasto_anual if clave == "E004"
	g deduc_STrans_escolar = gasto_anual if clave == "E013"
	g deduc_honor_medicos = gasto_anual if (clave >= "J001" & clave <= "J003") ///
		| (clave >= "J007" & clave <= "J008") | (clave >= "J011" & clave <= "J012") ///
		| (clave >= "J016" & clave <= "J019") | (clave >= "J039" & clave <= "J041")
	g deduc_segur_medicos = gasto_anual if clave == "J071"
	g deduc_gasto_funerar = gasto_anual if clave == "N002"
	g deduc_gasto_donativ = gasto_anual if clave == "N014"


	** 2.7. Unión de claves de IVA y IEPS **
	merge m:1 (clave) using "`c(sysdir_site)'/01_raw/ENIGH/`=anioenigh'/clave_iva.dta", ///
		nogen keepus(descripcion `claveiva' clase_de_actividad*) keep(matched master)
	encode iva201, gen(tiva)
	compress
	tempfile pre_iva
	save `pre_iva'

	use "`c(sysdir_site)'/01_raw/censo_eco.dta", clear
	/* a218a: Participación de la prestación de servicios profesionales, científicos y 
	técnicos en el total de ingresos por suministro de bienes y servicios: Porcentaje 
	de los ingresos a valor de venta que obtuvo la unidad económica por la prestación 
	de servicios profesionales, científicos y técnicos a terceros, en el total de los 
	ingresos que tuvo la unidad económica en 2018. Resulta de dividir el total de los 
	ingresos por la prestación de servicios profesionales, científicos y técnicos, entre 
	el total de ingresos por suministro de bienes y servicios, multiplicado por 100.*/
	/* a201a: Valor agregado censal bruto a producción bruta total : Porcentaje del 
	valor de la producción que se añade durante el proceso de trabajo por la actividad 
	creadora y de STransformación realizada por el personal ocupado, el capital y la 
	organización (factores de la producción), ejercida sobre los materiales que se 
	consumen en la realización de la actividad económica, respecto del valor de todos 
	los bienes y servicios producidos o comercializados por la unidad económica como 
	resultado del ejercicio de sus actividades.*/
	/* a111a: Producción bruta total (millones de pesos): Es el valor de todos los bienes 
	y servicios producidos o comercializados por la unidad económica como resultado del 
	ejercicio de sus actividades, comprendiendo el valor de los productos elaborados; el 
	margen bruto de comercialización; las obras ejecutadas; los ingresos por la prestación 
	de servicios, así como el alquiler de maquinaria y equipo, y otros bienes muebles e 
	inmuebles; el valor de los activos fijos producidos para uso propio, entre otros. 
	Incluye la variación de existencias de productos en proceso. Los bienes y servicios 
	se valoran a precios productor.*/
	tabstat a218a a201a [aw=a111a] if length(codigo) == 2, save by(codigo)
	tempname PR11 PR21 PR22 PR23 PR43 PR46 PR51 PR52 PR53 PR54 PR55 PR56 PR61 PR62 PR71 PR72 PR81 PR
	matrix `PR11' = r(Stat1)
	matrix `PR21' = r(Stat2)
	matrix `PR22' = r(Stat3)
	matrix `PR23' = r(Stat4)
	matrix `PR43' = r(Stat5)
	matrix `PR46' = r(Stat6)
	matrix `PR51' = r(Stat7)
	matrix `PR52' = r(Stat8)
	matrix `PR53' = r(Stat9)
	matrix `PR54' = r(Stat10)
	matrix `PR55' = r(Stat11)
	matrix `PR56' = r(Stat12)
	matrix `PR61' = r(Stat13)
	matrix `PR62' = r(Stat14)
	matrix `PR71' = r(Stat15)
	matrix `PR72' = r(Stat16)
	matrix `PR81' = r(Stat18)
	matrix `PR' = r(StatTotal)


	** 2.8. Unión de censo económico **
	forvalues k=1(1)6 {
		use "`c(sysdir_site)'/01_raw/censo_eco.dta", clear
		g num = length(codigo)
		drop if num != 6
		keep if id_estrato == .

		keep codigo a201a
		rename codigo clase_de_actividad`k'
		rename a201a valoragregado
		g proporcion = valoragregado/100
		
		merge 1:m (clase_de_actividad`k') using `pre_iva', nogen keep(matched using)
		save `pre_iva', replace
	}

	order folioviv-porcentaje_ieps201 *1 *2 *3 *4 *5 *6
	/* Valor agregado diferente a servicios profesionales de la actividad económica */
	replace proporcion = (1-`PR11'[1,1]/100)*`PR11'[1,2]/100 if substr(clase_de_actividad1,1,2) == "11" | proporcion == . | proporcion < 0
	replace proporcion = (1-`PR21'[1,1]/100)*`PR21'[1,2]/100 if substr(clase_de_actividad1,1,2) == "21" | proporcion == . | proporcion < 0
	replace proporcion = (1-`PR22'[1,1]/100)*`PR22'[1,2]/100 if substr(clase_de_actividad1,1,2) == "22" | proporcion == . | proporcion < 0
	replace proporcion = (1-`PR23'[1,1]/100)*`PR23'[1,2]/100 if substr(clase_de_actividad1,1,2) == "23" | proporcion == . | proporcion < 0
	replace proporcion = (1-`PR43'[1,1]/100)*`PR43'[1,2]/100 if substr(clase_de_actividad1,1,2) == "43" | proporcion == . | proporcion < 0
	replace proporcion = (1-`PR46'[1,1]/100)*`PR46'[1,2]/100 if substr(clase_de_actividad1,1,2) == "46" | proporcion == . | proporcion < 0
	replace proporcion = (1-`PR51'[1,1]/100)*`PR51'[1,2]/100 if substr(clase_de_actividad1,1,2) == "51" | proporcion == . | proporcion < 0
	replace proporcion = (1-`PR52'[1,1]/100)*`PR52'[1,2]/100 if substr(clase_de_actividad1,1,2) == "52" | proporcion == . | proporcion < 0
	replace proporcion = (1-`PR53'[1,1]/100)*`PR53'[1,2]/100 if substr(clase_de_actividad1,1,2) == "53" | proporcion == . | proporcion < 0
	replace proporcion = (1-`PR54'[1,1]/100)*`PR54'[1,2]/100 if substr(clase_de_actividad1,1,2) == "54" | proporcion == . | proporcion < 0
	replace proporcion = (1-`PR55'[1,1]/100)*`PR55'[1,2]/100 if substr(clase_de_actividad1,1,2) == "55" | proporcion == . | proporcion < 0
	replace proporcion = (1-`PR56'[1,1]/100)*`PR56'[1,2]/100 if substr(clase_de_actividad1,1,2) == "56" | proporcion == . | proporcion < 0
	replace proporcion = (1-`PR61'[1,1]/100)*`PR61'[1,2]/100 if substr(clase_de_actividad1,1,2) == "61" | proporcion == . | proporcion < 0
	replace proporcion = (1-`PR62'[1,1]/100)*`PR62'[1,2]/100 if substr(clase_de_actividad1,1,2) == "62" | proporcion == . | proporcion < 0
	replace proporcion = (1-`PR71'[1,1]/100)*`PR71'[1,2]/100 if substr(clase_de_actividad1,1,2) == "71" | proporcion == . | proporcion < 0
	replace proporcion = (1-`PR72'[1,1]/100)*`PR72'[1,2]/100 if substr(clase_de_actividad1,1,2) == "72" | proporcion == . | proporcion < 0
	replace proporcion = (1-`PR81'[1,1]/100)*`PR81'[1,2]/100 if substr(clase_de_actividad1,1,2) == "81" | proporcion == . | proporcion < 0
	replace proporcion = (1-`PR'[1,1]/100)*`PR'[1,2]/100 if clase_de_actividad1 == "000000" | proporcion == . | proporcion < 0
	noisily di in g "Proporcion: " in y (1-`PR'[1,1]/100)*`PR'[1,2]/100*100 "%"


	** 2.9. Estado y ubicación geográfica ***
	g estado = substr(folioviv,1,2)
	replace ubica_geo = substr(ubica_geo,1,5)
	destring ubica_geo estado, replace

	* Frontera norte *
	g front = estado==2 | estado==3 ///
		| ubica_geo==05002 | ubica_geo==05012 | ubica_geo==05013 | ubica_geo==05014 ///
		| ubica_geo==05022 | ubica_geo==05023 | ubica_geo==05025 | ubica_geo==05038 ///
		| ubica_geo==08005 | ubica_geo==08015 | ubica_geo==08028 | ubica_geo==08035 ///
		| ubica_geo==08037 | ubica_geo==08042 | ubica_geo==08052 | ubica_geo==08053 ///
		| ubica_geo==19005 | ubica_geo==26002 | ubica_geo==26004 | ubica_geo==26017 ///
		| ubica_geo==26019 | ubica_geo==26027 | ubica_geo==26035 | ubica_geo==26039 ///
		| ubica_geo==26043 | ubica_geo==26048 | ubica_geo==26055 | ubica_geo==26059 ///
		| ubica_geo==26060 | ubica_geo==26070 | ubica_geo==28007 | ubica_geo==28014 ///
		| ubica_geo==28015 | ubica_geo==28022 | ubica_geo==28024 | ubica_geo==28025 ///
		| ubica_geo==28027 | ubica_geo==28032 | ubica_geo==28033 | ubica_geo==28040 ///
	/* Frontera sur */ ///
		| estado== 23      | ubica_geo==04010 | ubica_geo==04011 | ubica_geo==07006 ///
		| ubica_geo==07010 | ubica_geo==07015 | ubica_geo==07019 ///
		| ubica_geo==07034 | ubica_geo==07035 | ubica_geo==07036 | ubica_geo==07041 ///
		| ubica_geo==07053 | ubica_geo==07055 | ubica_geo==07057 ///
		| ubica_geo==07059 | ubica_geo==07052 | ubica_geo==07070 | ubica_geo==07087 ///
		| ubica_geo==07089 | ubica_geo==07099 | ubica_geo==07102 ///
		| ubica_geo==07105 | ubica_geo==07114 | ubica_geo==07115 | ubica_geo==07116 ///
		| ubica_geo==20079 | ubica_geo==27001 | ubica_geo==27017


	** 2.10. Variables auxiliares **
	g letra = substr(clave,1,1)
	g letra2 = substr(clave,2,1)
	replace letra2 = "" if letra2 != "R" & letra2 != "B"

	g num = substr(clave,2,.) if letra2 != "R" & letra2 != "B"
	replace num = substr(clave,3,.) if letra2 == "R" | letra2 == "B"
	destring num, replace
	replace num = num - 900 if letra == "T" & (letra2 != "R" & letra2 != "B")

	g rentab = tenencia == "1" | tenencia == "3"


	** 2.11. SNA categorías **
	g categ = 1 if letra == "A" & num <= 214
	replace categ = 1 if letra == "T" & num == 1
	replace categ = 2 if letra == "A" & num >= 215 & num <= 222
	replace categ = 3 if letra == "A" & num >= 223 & num <= 238
	replace categ = 4 if letra == "A" & num >= 239 & num <= 241
	replace categ = 5 if letra == "H" & num <= 83
	replace categ = 5 if letra == "T" & num == 9
	replace categ = 6 if letra == "H" & num >= 84 & num <= 122
	replace categ = 7 if letra == "G" & num <= 4
	replace categ = 7 if letra == "G" & num >= 101
	replace categ = 7 if letra == "R" & num >= 3 & num <= 4
	replace categ = 8 if letra == "R" & num == 2
	replace categ = 9 if letra == "R" & num == 1
	replace categ = 10 if letra == "G" & num >= 5 & num <= 16
	replace categ = 10 if letra == "R" & num == 13
	replace categ = 10 if letra == "K"
	replace categ = 10 if letra == "T" & num == 7
	replace categ = 10 if letra == "T" & num == 12
	replace categ = 11 if letra == "J"
	replace categ = 11 if letra == "T" & num == 11
	replace categ = 12 if letra == "M" & num >= 7 & num <= 8
	replace categ = 13 if letra == "F" & num >= 7
	replace categ = 13 if letra == "R" & num == 12
	replace categ = 14 if letra == "B"
	replace categ = 14 if letra == "M" & num <= 6
	replace categ = 14 if letra == "T" & num == 2
	replace categ = 14 if letra == "T" & num == 14
	replace categ = 15 if letra == "F" & num <= 6
	replace categ = 15 if letra == "R" & num >= 5 & num <= 11
	replace categ = 15 if letra == "T" & num == 6
	replace categ = 16 if letra == "E" & num >= 8
	replace categ = 16 if letra == "L" & num <= 26
	replace categ = 16 if letra == "T" & num == 5
	replace categ = 16 if letra == "T" & num == 13
	replace categ = 17 if letra == "E" & num <= 7
	replace categ = 18 if letra == "A" & num >= 242 & num <= 247
	replace categ = 18 if letra == "N" & num >= 3 & num <= 5
	replace categ = 19 if letra == "C"
	replace categ = 19 if letra == "D"
	replace categ = 19 if letra == "H" & num >= 123
	replace categ = 19 if letra == "I"
	replace categ = 19 if letra == "L" & num >= 27
	replace categ = 19 if letra == "M" & num >= 9 & num <= 18
	replace categ = 19 if letra == "N" & num <= 2
	replace categ = 19 if letra == "N" & num >= 6
	replace categ = 19 if letra == "T" & num == 3
	replace categ = 19 if letra == "T" & num == 4
	replace categ = 19 if letra == "T" & num == 8
	replace categ = 19 if letra == "T" & num == 10
	replace categ = 19 if letra == "T" & num == 15
	replace categ = 19 if categ == .

	label define categ 1 "Alim" /// Alimentos
		2 "BebN" /// Bebidas no alcohólicas
		3 "BebA" /// Bebidas alcohólicas
		4 "Taba" /// Tabaco
		5 "Vest" /// Prendas de vestir
		6 "Calz" /// Calzado
		7 "AlojT" /// Alquileres y vivienda
		8 "Agua" /// Agua
		9 "Elec" /// Electricidad
		10 "HogaT" /// Artículos para el hogar
		11 "SaluT" /// Salud
		12 "Vehi" /// Adquisición de vehículos
		13 "FTra" /// Transporte personal
		14 "STra" /// Servicios de transporte
		15 "ComuT" /// Comunicaciones
		16 "RecrT" /// Recreación y cultura
		17 "EducT" /// Educación
		18 "RestT" /// Restaurantes y hoteles
		19 "DiveT" // Otros diversos
	label values categ categ


	** 2.12 IVA categorías **
	g categ_iva = 1 if letra == "A"
	replace categ_iva = 2 if letra == "A" & ((num >= 198 & num <= 202) | (num >= 243 & num <= 247))
	replace categ_iva = 3 if letra == "A" & ((num == 1 | num == 4 | num == 9 | num == 10 | num == 12 | num == 13 | num == 19 | num == 25 | num == 34 | num == 38 | num == 42 | num == 48 | num == 55 | num == 57 | num == 58 | num == 59 | num == 62 | num == 66 | num == 75 | num == 85 | num == 87 | num == 91 | num == 93 | num == 95 | num == 102 | num == 112 | num == 115 | num == 116 | num == 117 | num == 118 | num == 124 | num == 137 | num == 154 | num == 158 | num == 160 | num == 166 | num == 173 | num == 200 | num == 215 | num == 220 | num == 243 | num == 244 | num == 245 | num == 202))
	replace categ_iva = 4 if (letra == "L" & (num == 029)) | (letra == "A" & (num == 213 | num == 214))
	replace categ_iva = 5 if letra == "J" & ((num == 9 | (num >= 20 & num <= 38) | num == 42 | (num >= 44 & num <= 59) | num == 64))
	replace categ_iva = 6 if letra == "B"
	replace categ_iva = 7 if (letra == "M" & num == 1) | (letra == "B" & num == 6)
	replace categ_iva = 8 if letra == "E" & (num >= 1 & num <= 7)
	replace categ_iva = 9 if letra == "G" & ((num >= 1 & num <= 3) | (num >= 101 & num <= 106))
	replace categ_iva = 10 if letra == "D" & num == 15
	replace categ_iva = 11 if categ_iva == . //& tiva != .

	label define categ_iva 1 "Alimentos" ///
		2 "FueraHog" ///
		3 "CanastaBas" ///
		4 "Mascotas" ///
		5 "Medicinas" ///
		6 "TransporteLoc" ///
		7 "TransporteFor" ///
		8 "Educación" ///
		9 "Alquiler" ///
		10 "Mujer" ///
		11 "Otros"
	label values categ_iva categ_iva


	** 2.13 IEPS categorías **
	g categ_ieps = 1 if (letra == "A" & (num == 224))
	replace categ_ieps = 2 if (letra == "A" & num == 225 | num == 226 | num == 227 | num == 228 | num == 231 | num == 232 | num == 234)
	replace categ_ieps = 3 if (letra == "A" & (num == 223 | num == 229 | num == 230 | num == 233 | num == 235 | num == 236 | num == 237 | num == 238))
	replace categ_ieps = 4 if (letra == "A" & (num >= 239 & num <= 241))
	replace categ_ieps = 5 if (letra == "E" & num == 031)
	replace categ_ieps = 6 if (letra == "F" & (num >= 1 & num <= 3)) ///
		| (letra == "K" & num == 3) | (letra == "R" & ((num >= 5 & num <= 7) | (num >= 9 & num <= 11)))
	replace categ_ieps = 7 if (letra == "A" & num == 221)
	replace categ_ieps = 8 if (letra == "A" & (num == 219 | num == 220))
	replace categ_ieps = 9 if (letra == "A" & (num == 106 | (num >= 180 & num <= 182) | (num >= 205 & num <= 209)))
	replace categ_ieps = 10 if (letra == "G" & (num >= 9 & num <= 11))
	replace categ_ieps = 11 if (letra == "F" & (num >= 7 & num <= 9))
	replace categ_ieps = 12 if categ_ieps == .

	label define categ_ieps 1 "Cervezas" ///
		2 "Alcohol 20" ///
		3 "Alcohol 20+" ///
		4 "Tabaco" ///
		5 "Juegos" ///
		6 "Telecom" ///
		7 "BebidasEner" ///
		8 "BebidasSabor" ///
		9 "AltoContCal" ///
		10 "Combustibles" ///
		11 "Gasolinas" ///
		12 "Sin IEPS"
	label values categ_ieps categ_ieps


	** 2.15. Informalidad **
	g informal = lugar_comp == "01" | lugar_comp == "02" | lugar_comp == "03" | lugar_comp == "17"	// Informalidad


	** 2.16. Cálculo de la cantidad anual **
	replace cantidad = cantidad*365 if frecuencia == "1"
	replace cantidad = cantidad*52 if frecuencia == "2"
	replace cantidad = cantidad*12 if frecuencia == "3"
	replace cantidad = cantidad*4 if frecuencia == "4"
	replace cantidad = 1 if frecuencia == "5" | frecuencia == "6" 
	replace cantidad = 1 if frecuencia == "0" | frecuencia == ""
	replace cantidad = 1 if gasto_anual > 0 & cantidad == 0

	* Educación *
	replace cantidad = 1 if letra == "E" & (num >= 1 & num <= 7) //& publica == 0

	** 2.17. Cálculo de cantidad de gasolinas **
	replace cantidad = gasto/13.98*52 if clave == "F007"
	replace cantidad = gasto/14.81*52 if clave == "F008"
	replace cantidad = gasto/14.63*52 if clave == "F009"


	** 2.18. Guardar pre-base **
	capture drop __*
	compress
	sort folioviv foliohog numren clave

	if `c(version)' > 13.1 {
		saveold "`c(sysdir_site)'/03_temp/`=anioenigh'/preconsumption.dta", replace version(13)
	}
	else {
		save "`c(sysdir_site)'/03_temp/`=anioenigh'/preconsumption.dta", replace
	}


	** 2.19. Deducciones personales del ISR **
	collapse (sum) deduc_*, by(folioviv foliohog numren)
	replace numren = "01"
	collapse (sum) deduc_*, by(folioviv foliohog numren)

	if `c(version)' > 13.1 {
		saveold "`c(sysdir_site)'/03_temp/`=anioenigh'/deducciones.dta", replace version(13)
	}
	else {
		save "`c(sysdir_site)'/03_temp/`=anioenigh'/deducciones.dta", replace
	}
}





********************************************************
***                                                  ***
***  3. Integración consumo de hogares + individuos  ***
***                                                  ***
********************************************************
foreach categ in categ /*categ_iva categ_ieps*/ {
	capture confirm file "`c(sysdir_site)'/04_master/`=anioenigh'/consumption_`categ'_pc.dta"
	*if _rc != 0 {
	if _rc == 0 {

		** 3.1 Consumo de los individuos **
		use "`c(sysdir_site)'/03_temp/`=anioenigh'/preconsumption.dta", clear
		drop if gasto_anual == 0 | numren == ""
		collapse (sum) gas_ind=gasto_anual cant_ind=cantidad (mean) proporcion, by(folioviv foliohog numren `categ')

		decode `categ', gen(categs)
		replace categs = strtoname(categs)
		drop `categ'

		levelsof categs, local(categs)
		reshape wide gas_ind cant_ind proporcion, i(folioviv foliohog numren) j(categs) string
		reshape long
		replace gas_ind = 0 if gas_ind == .
		replace cant_ind = 0 if cant_ind == .

		tabstat proporcion, stat(mean) f(%20.0fc) save
		replace proporcion = r(StatTotal)[1,1] if proporcion == .

		reshape wide gas_ind cant_ind proporcion, i(folioviv foliohog numren) j(categs) string

		tempfile gastoindividuos
		save `gastoindividuos'


		** 3.2 Consumo de los hogares **
		use "`c(sysdir_site)'/03_temp/`=anioenigh'/preconsumption.dta", clear
		drop if gasto_anual == 0 | numren != ""
		collapse (sum) gas_hog=gasto_anual cant_hog=cantidad (mean) proporcion, by(folioviv foliohog `categ')

		decode `categ', gen(categs)
		replace categs = strtoname(categs)
		drop `categ'

		levelsof categs, local(categs)
		reshape wide gas_hog cant_hog proporcion, i(folioviv foliohog) j(categs) string
		reshape long
		replace gas_hog = 0 if gas_hog == .
		replace cant_hog = 0 if cant_hog == .

		tabstat proporcion, stat(mean) f(%20.0fc) save
		replace proporcion = r(StatTotal)[1,1] if proporcion == .

		reshape wide gas_hog cant_hog proporcion, i(folioviv foliohog) j(categs) string


		** 3.3 Consumo de los hogares + individuos **
		merge 1:m (folioviv foliohog) using "`c(sysdir_site)'/01_raw/ENIGH/`=anioenigh'/poblacion.dta", nogen keepus(numren edad sexo)
		merge m:1 (folioviv foliohog) using "`c(sysdir_site)'/01_raw/ENIGH/`=anioenigh'/concentrado.dta", nogen keepus(factor)
		egen tot_integ = count(factor), by(folioviv foliohog)
		
		foreach k of varlist *hog* {
			if "`k'" == "foliohog" continue
			replace `k' = `k'/tot_integ
		}

		merge 1:1 (folioviv foliohog numren) using `gastoindividuos', nogen keepus(*_ind* proporcion*)
		*merge 1:1 (folioviv foliohog numren) using "`c(sysdir_site)'/04_master/`=anioenigh'/households.dta", nogen keepus(decil)

		** 3.4 Gasto per cápita **
		noisily di in g `"`categs'"'
		foreach k of local categs {
		*foreach k in Vest {
			local k = strtoname("`k'")
			foreach vars in cant_ gas_ {
				if "`vars'" == "gas_" {
					local title = "Gasto"
				}
				if "`vars'" == "cant_" {
					local title = "Cantidad"
				}
				
				* Gasto por hogar *
				capture replace `vars'hog`k' = 0 if `vars'hog`k' == .
				if _rc != 0 {
					g `vars'hog`k' = 0
				}
				*noisily tabstat `vars'hog`k' [fw=factor], stat(sum) f(%20.0fc)

				* Outliers *
				*tabstat `vars'hog`k' if `vars'hog`k' != 0, stat(p99 p95) save
				*g hogar_outlier = 1 if `vars'hog`k' >= r(StatTotal)[1,1] & r(StatTotal)[1,1] != r(StatTotal)[2,1]

				* Gasto por individuo *
				capture replace `vars'ind`k' = 0 if `vars'ind`k' == .
				if _rc != 0 {
					g `vars'ind`k' = 0
				}
				*noisily tabstat `vars'ind`k' [fw=factor], stat(sum) f(%20.0fc)

				* Outliers *
				*tabstat `vars'ind`k' if `vars'ind`k' != 0, stat(p99 p95) save
				*g ind_outlier = 1 if `vars'ind`k' >= r(StatTotal)[1,1] & r(StatTotal)[1,1] != r(StatTotal)[2,1]

				g `vars'pc_`k' = `vars'hog`k' //+ `vars'ind`k'
				local label = subinstr("`title' per cápita en `k'","_"," ",.)
				label var `vars'pc_`k' "`label'"

				* Perfil original *
				*tempvar `vars'pc_`k'
				*g ``vars'pc_`k'' = `vars'pc_`k'
				*label var ``vars'pc_`k'' "`title' per cápita en `k' (original)"
				*noisily Perfiles ``vars'pc_`k'' [fw=factor] ///
					if ``vars'pc_`k'' != 0 /*& hogar_outlier == . & ind_outlier == .*/, aniope(`=anioenigh')

				* Iteraciones *
				noisily di in y "`k': " _cont
				local salto = 3
				forvalues iter=1(1)10 {
					noisily di in w "`iter' " _cont
					forvalues edades=0(`salto')109 {
						forvalues sexos=1(1)2 {
							capture tabstat `vars'pc_`k' [fw=factor] ///
								if (edad >= `edades' & edad <= `edades'+`salto'-1) ///
								& sexo == "`sexos'" ///
								, stat(mean) f(%20.0fc) save
							if _rc != 0 {
								local valor = 0
							}
							else {
								local valor = r(StatTotal)[1,1]
							}
							replace `vars'pc_`k' = round(`valor',.01) ///
								if (edad >= `edades' & edad <= `edades'+`salto'-1) & sexo == "`sexos'"
							replace `vars'pc_`k' = .01 ///
								if `vars'pc_`k' == 0
						}
					}
					egen equivalencias`k' = sum(`vars'pc_`k'), by(folioviv foliohog)
					replace `vars'pc_`k' = `vars'hog`k'*tot_integ*`vars'pc_`k'/equivalencias`k'
					drop equivalencias`k'
				}
				replace `vars'pc_`k' = `vars'pc_`k' + `vars'ind`k'
				*noisily tabstat `vars'pc_`k' `vars'hog`k' `vars'ind`k' [fw=factor], stat(sum) f(%20.0fc)
				
				*noisily Perfiles `vars'pc_`k' [fw=factor] ///
					if `vars'pc_`k' != 0 /*& hogar_outlier == . & ind_outlier == .*/, aniope(`=anioenigh') ///
					title(`title' per cápita en `k')
				*capture g precio_`k' = gas_pc_`k'/cant_pc_`k'
				*drop *outlier
			}
			noisily di
			*noisily tabstat precio_`k' gas_pc_`k' cant_pc_`k' [fw=factor] if cant_pc_`k' > 0.01, stat(mean) f(%10.2fc)
		}

		** 3.5 Coeficientes de consumo por edades **
		g alfa = 1 if edad != .
		replace alfa = alfa - .6*(20-edad)/16 if edad >= 5 & edad <= 20
		replace alfa = .4 if edad <= 4

		** Guardar pre-base individuos **
		capture drop __*
		compress
		sort folioviv foliohog numren
		capture mkdir "`c(sysdir_site)'/04_master/`=anioenigh'"
		save "`c(sysdir_site)'/04_master/`=anioenigh'/consumption_`categ'_pc.dta", replace
	}
}





*****************************/
***                        ***
***  4. Aggregated values  ***
***                        ***
******************************
use "`c(sysdir_site)'/04_master/`=anioenigh'/consumption_categ_pc.dta", replace
merge m:1 (folioviv foliohog) using "`c(sysdir_site)'/01_raw/ENIGH/`=anioenigh'/concentrado.dta", nogen keepus(factor)
*merge 1:1 (folioviv foliohog numren) using "`c(sysdir_site)'/01_raw/CONEVAL/2022/Base final/pobreza_20.dta", nogen keepus(decil)
capture rename factor_hog factor
order folioviv foliohog numren
drop *_hog* *_ind*

egen gasto_pc = rsum(gas_pc*)
label var gasto_pc "Gasto total per cápita"

Gini gasto_pc, hogar(folioviv foliohog) factor(factor)
local gini_gasto_pc = r(gini_gasto_pc)
scalar ginigastopc = `gini_gasto_pc'

scalar MTot = 0
foreach k in Alim BebN BebA Taba Vest Calz AlojT Agua Elec HogaT SaluT Vehi FTra STra ComuT RecrT EducT RestT DiveT {
	if "`k'" == "Alim" {
		label var gas_pc_Alim "Alimentos"
	}
	if "`k'" == "BebN" {
		label var gas_pc_BebN "Bebidas no alcohólicas"
	}
	if "`k'" == "BebA" {
		label var gas_pc_BebA "Bebidas alcohólicas"
	}
	if "`k'" == "Taba" {
		label var gas_pc_Taba "Tabaco"
	}
	if "`k'" == "Vest" {
		label var gas_pc_Vest "Prendas de vestir"
	}
	if "`k'" == "Calz" {
		label var gas_pc_Calz "Calzado"
	}
	if "`k'" == "AlojT" {
		label var gas_pc_AlojT "Alquileres y vivienda"
	}
	if "`k'" == "Agua" {
		label var gas_pc_Agua "Agua"
	}
	if "`k'" == "Elec" {
		label var gas_pc_Elec "Electricidad"
	}
	if "`k'" == "HogaT" {
		label var gas_pc_HogaT "Artículos para el hogar"
	}
	if "`k'" == "SaluT" {
		label var gas_pc_SaluT "Salud"
	}
	if "`k'" == "Vehi" {
		label var gas_pc_Vehi "Adquisición de vehículos"
	}
	if "`k'" == "FTra" {
		label var gas_pc_FTra "Transporte personal"
	}
	if "`k'" == "STra" {
		label var gas_pc_STra "Servicios de transporte"
	}
	if "`k'" == "ComuT" {
		label var gas_pc_ComuT "Comunicaciones"
	}
	if "`k'" == "RecrT" {
		label var gas_pc_RecrT "Recreación y cultura"
	}
	if "`k'" == "EducT" {
		label var gas_pc_EducT "Educación"
	}
	if "`k'" == "RestT" {
		label var gas_pc_RestT "Restaurantes y hoteles"
	}
	if "`k'" == "DiveT" {
		label var gas_pc_DiveT "Otros diversos"
	}
	tabstat gas_pc_`k' [aw=factor], stat(sum) f(%20.0fc) save
	scalar M`k' = r(StatTotal)[1,1]
	scalar E`k'PIB = M`k'/PIB*100
	scalar E`k'PC = M`k'/`pobtotNacional'

	Gini gas_pc_`k', hogar(folioviv foliohog) factor(factor)
	local gini`k' = r(gini_gas_pc_`k')
	scalar gini`k' = `gini`k''

	scalar MTot = MTot + M`k'
}
scalar ETotPIB = MTot/PIB*100
scalar ETotPC = MTot/`pobtotNacional'


* Display de resultados *
noisily di _newline in g "{bf: A. Gasto inicial" ///
	_col(44) in g "(Gini)" ///
	_col(55) in g %7s "ENIGH" ///
	_col(66) %7s "SCN" in g ///
	_col(77) %7s "Dif. %" "}"
noisily di in g "  (+) Alimentos " ///
	_col(44) in y "(" %5.3fc giniAlim ")" ///
	_col(55) in y %7.3fc MAlim/PIB*100 ///
	_col(66) %7.3fc Alim/PIB*100 ///
	_col(77) %6.1fc (MAlim/Alim-1)*100 "%"
noisily di in g "  (+) Bebidas no alcohólicas " ///
	_col(44) in y "(" %5.3fc giniBebN ")" ///
	_col(55) in y %7.3fc MBebN/PIB*100 ///
	_col(66) %7.3fc BebN/PIB*100 ///
	_col(77) %6.1fc (MBebN/BebN-1)*100 "%"
noisily di in g "  (+) Bebidas alcohólicas " ///
	_col(44) in y "(" %5.3fc giniBebA ")" ///
	_col(55) in y %7.3fc MBebA/PIB*100 ///
	_col(66) %7.3fc BebA/PIB*100 ///
	_col(77) %6.1fc (MBebA/BebA-1)*100 "%"
noisily di in g "  (+) Tabaco " ///
	_col(44) in y "(" %5.3fc giniTaba ")" ///
	_col(55) in y %7.3fc MTaba/PIB*100 ///
	_col(66) %7.3fc Taba/PIB*100 ///
	_col(77) %6.1fc (MTaba/Taba-1)*100 "%"
noisily di in g "  (+) Prendas de vestir " ///
	_col(44) in y "(" %5.3fc giniVest ")" ///
	_col(55) in y %7.3fc MVest/PIB*100 ///
	_col(66) %7.3fc Vest/PIB*100 ///
	_col(77) %6.1fc (MVest/Vest-1)*100 "%"
noisily di in g "  (+) Calzado " ///
	_col(44) in y "(" %5.3fc giniCalz ")" ///
	_col(55) in y %7.3fc MCalz/PIB*100 ///
	_col(66) %7.3fc Calz/PIB*100 ///
	_col(77) %6.1fc (MCalz/Calz-1)*100 "%"
noisily di in g "  (+) Vivienda " ///
	_col(44) in y "(" %5.3fc giniAlojT ")" ///
	_col(55) in y %7.3fc MAlojT/PIB*100 ///
	_col(66) %7.3fc AlojT/PIB*100 ///
	_col(77) %6.1fc (MAlojT/AlojT-1)*100 "%"
noisily di in g "  (+) Agua " ///
	_col(44) in y "(" %5.3fc giniAgua ")" ///
	_col(55) in y %7.3fc MAgua/PIB*100 ///
	_col(66) %7.3fc Agua/PIB*100 ///
	_col(77) %6.1fc (MAgua/Agua-1)*100 "%"
noisily di in g "  (+) Electricidad " ///
	_col(44) in y "(" %5.3fc giniElec ")" ///
	_col(55) in y %7.3fc MElec/PIB*100 ///
	_col(66) %7.3fc Elec/PIB*100 ///
	_col(77) %6.1fc (MElec/Elec-1)*100 "%"
noisily di in g "  (+) Artículos para el hogar " ///
	_col(44) in y "(" %5.3fc giniHogaT ")" ///
	_col(55) in y %7.3fc MHogaT/PIB*100 ///
	_col(66) %7.3fc HogaT/PIB*100 ///
	_col(77) %6.1fc (MHogaT/HogaT-1)*100 "%"
noisily di in g "  (+) Salud " ///
	_col(44) in y "(" %5.3fc giniSaluT ")" ///
	_col(55) in y %7.3fc MSaluT/PIB*100 ///
	_col(66) %7.3fc SaluT/PIB*100 ///
	_col(77) %6.1fc (MSaluT/SaluT-1)*100 "%"
noisily di in g "  (+) Aquisición de vehículos " ///
	_col(44) in y "(" %5.3fc giniVehi ")" ///
	_col(55) in y %7.3fc MVehi/PIB*100 ///
	_col(66) %7.3fc Vehi/PIB*100 ///
	_col(77) %6.1fc (MVehi/Vehi-1)*100 "%"
noisily di in g "  (+) Funcionamiento de STransporte " ///
	_col(44) in y "(" %5.3fc giniFTra ")" ///
	_col(55) in y %7.3fc MFTra/PIB*100 ///
	_col(66) %7.3fc FTra/PIB*100 ///
	_col(77) %6.1fc (MFTra/FTra-1)*100 "%"
noisily di in g "  (+) Servicios de STransporte " ///
	_col(44) in y "(" %5.3fc giniSTra ")" ///
	_col(55) in y %7.3fc MSTra/PIB*100 ///
	_col(66) %7.3fc STra/PIB*100 ///
	_col(77) %6.1fc (MSTra/STra-1)*100 "%"
noisily di in g "  (+) Comunicaciones " ///
	_col(44) in y "(" %5.3fc giniComuT ")" ///
	_col(55) in y %7.3fc MComuT/PIB*100 ///
	_col(66) %7.3fc ComuT/PIB*100 ///
	_col(77) %6.1fc (MComuT/ComuT-1)*100 "%"
noisily di in g "  (+) Recreación y cultura " ///
	_col(44) in y "(" %5.3fc giniRecrT ")" ///
	_col(55) in y %7.3fc MRecrT/PIB*100 ///
	_col(66) %7.3fc RecrT/PIB*100 ///
	_col(77) %6.1fc (MRecrT/RecrT-1)*100 "%"
noisily di in g "  (+) Educación " ///
	_col(44) in y "(" %5.3fc giniEducT ")" ///
	_col(55) in y %7.3fc MEducT/PIB*100 ///
	_col(66) %7.3fc EducT/PIB*100 ///
	_col(77) %6.1fc (MEducT/EducT-1)*100 "%"
noisily di in g "  (+) Restaurantes y hoteles" ///
	_col(44) in y "(" %5.3fc giniRestT ")" ///
	_col(55) in y %7.3fc MRestT/PIB*100 ///
	_col(66) %7.3fc RestT/PIB*100 ///
	_col(77) %6.1fc (MRestT/RestT-1)*100 "%"
noisily di in g "  (+) Bienes y servicios diveresos " ///
	_col(44) in y "(" %5.3fc giniDiveT ")" ///
	_col(55) in y %7.3fc MDiveT/PIB*100 ///
	_col(66) %7.3fc DiveT/PIB*100 ///
	_col(77) %6.1fc (MDiveT/DiveT-1)*100 "%"
noisily di in g _dup(84) "-"
noisily di in g "{bf:  (=) Total " ///
	_col(44) in y "(" %5.3fc ginigastopc ")" ///
	_col(55) in y %7.3fc MTot/PIB*100 ///
	_col(66) %7.3fc ConHog/PIB*100 ///
	_col(77) %6.1fc (MTot/ConHog-1)*100 "}" "%"


** 4.1. Factores de escala  **
scalar MMTot = 0
foreach k in Alim BebN BebA Taba Vest Calz AlojT Agua Elec HogaT SaluT Vehi FTra STra ComuT RecrT EducT RestT DiveT {
	scalar TT`k' = (M`k'/`k')^(-1)
	scalar Dif`k' = ((M`k'/`k')-1)*100
	replace gas_pc_`k' = gas_pc_`k'*scalar(TT`k')

	tabstat gas_pc_`k' [aw=factor], stat(sum) f(%20.0fc) save
	scalar MM`k' = r(StatTotal)[1,1]
	scalar EE`k'PIB = MM`k'/PIB*100
	scalar EE`k'PC = MM`k'/`pobtotNacional'

	scalar MMTot = MMTot + MM`k'
}
scalar EETotPIB = MMTot/PIB*100
scalar EETotPC = MMTot/`pobtotNacional'


** 4.2 Display de resultados **
noisily di _newline in g "{bf: B. Gasto ajustado" ///
	_col(44) in g %20s "ENIGH" ///
	_col(66) %6s "Macro" in g ///
	_col(77) %6s  "Dif. %}"
noisily di in g "  (+) Alimentos " ///
	_col(44) in y %20.3fc MMAlim/PIB*100 ///
	_col(66) %7.3fc Alim/PIB*100 ///
	_col(77) %6.1fc (MMAlim/Alim-1)*100
noisily di in g "  (+) Bebidas no alcohólicas " ///
	_col(44) in y %20.3fc MMBebN/PIB*100 ///
	_col(66) %7.3fc BebN/PIB*100 ///
	_col(77) %6.1fc (MMBebN/BebN-1)*100
noisily di in g "  (+) Bebidas alcohólicas " ///
	_col(44) in y %20.3fc MMBebA/PIB*100 ///
	_col(66) %7.3fc BebA/PIB*100 ///
	_col(77) %6.1fc (MMBebA/BebA-1)*100
noisily di in g "  (+) Tabaco " ///
	_col(44) in y %20.3fc MMTaba/PIB*100 ///
	_col(66) %7.3fc Taba/PIB*100 ///
	_col(77) %6.1fc (MMTaba/Taba-1)*100
noisily di in g "  (+) Prendas de vestir " ///
	_col(44) in y %20.3fc MMVest/PIB*100 ///
	_col(66) %7.3fc Vest/PIB*100 ///
	_col(77) %6.1fc (MMVest/Vest-1)*100
noisily di in g "  (+) Calzado " ///
	_col(44) in y %20.3fc MMCalz/PIB*100 ///
	_col(66) %7.3fc Calz/PIB*100 ///
	_col(77) %6.1fc (MMCalz/Calz-1)*100
noisily di in g "  (+) Vivienda " ///
	_col(44) in y %20.3fc MMAlojT/PIB*100 ///
	_col(66) %7.3fc AlojT/PIB*100 ///
	_col(77) %6.1fc (MMAlojT/AlojT-1)*100
noisily di in g "  (+) Agua " ///
	_col(44) in y %20.3fc MMAgua/PIB*100 ///
	_col(66) %7.3fc Agua/PIB*100 ///
	_col(77) %6.1fc (MMAgua/Agua-1)*100
noisily di in g "  (+) Electricidad " ///
	_col(44) in y %20.3fc MMElec/PIB*100 ///
	_col(66) %7.3fc Elec/PIB*100 ///
	_col(77) %6.1fc (MMElec/Elec-1)*100
noisily di in g "  (+) Artículos para el hogar " ///
	_col(44) in y %20.3fc MMHogaT/PIB*100 ///
	_col(66) %7.3fc HogaT/PIB*100 ///
	_col(77) %6.1fc (MMHogaT/HogaT-1)*100
noisily di in g "  (+) Salud " ///
	_col(44) in y %20.3fc MMSaluT/PIB*100 ///
	_col(66) %7.3fc SaluT/PIB*100 ///
	_col(77) %6.1fc (MMSaluT/SaluT-1)*100
noisily di in g "  (+) Aquisición de vehículos " ///
	_col(44) in y %20.3fc MMVehi/PIB*100 ///
	_col(66) %7.3fc Vehi/PIB*100 ///
	_col(77) %6.1fc (MMVehi/Vehi-1)*100
noisily di in g "  (+) Funcionamiento de STransporte " ///
	_col(44) in y %20.3fc MMFTra/PIB*100 ///
	_col(66) %7.3fc FTra/PIB*100 ///
	_col(77) %6.1fc (MMFTra/FTra-1)*100
noisily di in g "  (+) Servicios de STransporte " ///
	_col(44) in y %20.3fc MMSTra/PIB*100 ///
	_col(66) %7.3fc STra/PIB*100 ///
	_col(77) %6.1fc (MMSTra/STra-1)*100
noisily di in g "  (+) Comunicaciones " ///
	_col(44) in y %20.3fc MMComuT/PIB*100 ///
	_col(66) %7.3fc ComuT/PIB*100 ///
	_col(77) %6.1fc (MMComuT/ComuT-1)*100
noisily di in g "  (+) Recreación y cultura " ///
	_col(44) in y %20.3fc MMRecrT/PIB*100 ///
	_col(66) %7.3fc RecrT/PIB*100 ///
	_col(77) %6.1fc (MMRecrT/RecrT-1)*100
noisily di in g "  (+) Educación " ///
	_col(44) in y %20.3fc MMEducT/PIB*100 ///
	_col(66) %7.3fc EducT/PIB*100 ///
	_col(77) %6.1fc (MMEducT/EducT-1)*100
noisily di in g "  (+) Restaurantes y hoteles" ///
	_col(44) in y %20.3fc MMRestT/PIB*100 ///
	_col(66) %7.3fc RestT/PIB*100 ///
	_col(77) %6.1fc (MMRestT/RestT-1)*100
noisily di in g "  (+) Bienes y servicios diveresos " ///
	_col(44) in y %20.3fc MMDiveT/PIB*100 ///
	_col(66) %7.3fc DiveT/PIB*100 ///
	_col(77) %6.1fc (MMDiveT/DiveT-1)*100
noisily di in g _dup(84) "-"
noisily di in g "  (=) Total Consumo " ///
	_col(44) in y %20.3fc MMTot/PIB*100 ///
	_col(66) %7.3fc ConHog/PIB*100 ///
	_col(77) %6.1fc (MMTot/ConHog-1)*100


** 4.3. Guardar base **
if `c(version)' > 13.1 {
	saveold "`c(sysdir_site)'/04_master/`=anioenigh'/expenditures.dta", replace version(13)
}
else {
	save "`c(sysdir_site)'/04_master/`=anioenigh'/expenditures.dta", replace
}




*************/
***        ***
*** 5. IVA ***
***        ***
**************
if `=anioenigh' >= 2014 {
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
}

use "`c(sysdir_site)'/04_master/`=anioenigh'/consumption_categ_iva_pc.dta", clear
merge m:1 (folioviv foliohog) using "`c(sysdir_site)'/01_raw/ENIGH/`=anioenigh'/concentrado.dta", nogen keepus(factor)
capture rename factor_hog factor
order folioviv foliohog numren
drop *_hog* *_ind*

*merge 1:1 (folioviv foliohog numren) using "`c(sysdir_site)'/01_raw/CONEVAL/2022/Base final/pobreza_20.dta", nogen keepus(decil)
reshape long gas_pc_ cant_pc_ proporcion, i(folioviv foliohog numren) j(categs) string


** 5.1. Cálculo de precios **
replace gas_pc_ = gas_pc_*ConHog/MTot
replace cant_pc_ = cant_pc_*ConHog/MTot
g precio = gas_pc_/cant_pc_
tabstat precio gas_pc_ cant_pc_ [aw=factor], f(%20.0fc) by(categs)


** 5.2. Cálculo del IVA **
capture drop IVA
g IVA = 0
levelsof categs, local(categs)
local j = 2
foreach k of local categs {
	if IVAT[`j',1] == 2 {
		replace IVA = IVA + precio*cant_pc_*proporcion*IVAT[1,1]/100/(1+IVAT[1,1]/100) if categs == "`k'"
	}
	if IVAT[`j',1] == 3 {
		replace IVA = IVA + precio*cant_pc_*IVAT[1,1]/100/(1+IVAT[1,1]/100) if categs == "`k'"
	}
	local ++j
}
noisily tabstat IVA [aw=factor], stat(sum) f(%20.0fc) save
scalar IVA = r(StatTotal)[1,1]

noisily di in g "IVA Observado: " in y %20.0fc `IVA'

Gini IVA, hogar(folioviv foliohog) factor(factor)
local gini_IVA = r(gini_IVA)
scalar giniIVA = `gini_IVA'


** 5.3. Display de resultados **
noisily di _newline in g "{bf: C. IVA" ///
	_col(44) in g "(Gini)" ///
	_col(55) in g %7s "ENIGH" ///
	_col(66) %6s "Macro" in g ///
	_col(77) %6s  "Informalidad %}"
noisily di in g "  Total " ///
	_col(44) in y "(" %5.3fc giniIVA ")" ///
	_col(55) in y %7.3fc scalar(IVA)/PIB*100 ///
	_col(66) %7.3fc `IVA'/PIB*100 ///
	_col(77) %6.2fc (1-`IVA'/scalar(IVA))*100 "%"

save "`c(sysdir_site)'/04_master/`=anioenigh'/categ_iva.dta", replace
collapse (sum) IVA, by(folioviv foliohog numren)
save "`c(sysdir_site)'/04_master/`=anioenigh'/consumption_categ_iva.dta", replace





**************/
***         ***
*** 6. IEPS ***
***         ***
***************
if `=anioenigh' >= 2014 {
	matrix IEPST = (26.5	,		0 			\ /// Cervezas y licores
				30.0	,		0 			\ /// Alcohol 14+ a 20
				53.0	,		0 			\ /// Alcohol 20+
				8.0		,		0 			\ /// Alto contenido calórico
				25.0	,		0 			\ /// Bebidas energéticas
				0		,		1.5737		\ /// Bebidas saborizadas
				0		,		19.8607		\ /// Combustibles (diesel)
				30.0	,		0 			\ /// Juegos y sorteos
				160.0	,		0.6166		\ /// Tabaco y cigarros
				3.0		,		0 			) //  Telecomunicaciones
}

use "`c(sysdir_site)'/04_master/`=anioenigh'/consumption_categ_ieps_pc.dta", clear
drop gas_hog* cant_hog* gas_ind* cant_ind*

*merge 1:1 (folioviv foliohog numren) using "`c(sysdir_site)'/01_raw/CONEVAL/2022/Base final/pobreza_20.dta", nogen keepus(decil)
reshape long gas_pc_ cant_pc_ proporcion, i(folioviv foliohog numren) j(categs) string


** 6.1. Cálculo de precios **
g precio = gas_pc_/cant_pc_*ConHog/MTot
noisily tabstat precio gas_pc_ cant_pc_ [aw=factor], f(%20.0fc) by(categs)


** 6.2. Cálculo del IEPS **
capture drop IEPS
g IEPS = 0
levelsof categs, local(categs)
local j = 0
foreach k of local categs {
	local ++j
	if "`k'" == "Gasolinas" | "`k'" == "Sin_IEPS" {
		continue
	}
	else if "`k'" == "Alcohol" {
		replace IEPS = IEPS + ((precio)*proporcion*((IEPST[`j',1]+IEPST[`j'+1,1]+IEPST[`j'+2,1])/3/100) + IEPST[`j',2])*cant_pc_ if categs == "`k'"
		local j = `j' + 2
		continue
	}
	else {
		replace IEPS = IEPS + ((precio)*proporcion*(IEPST[`j',1]/100) + IEPST[`j',2])*cant_pc_ if categs == "`k'"
	}
}

tabstat IEPS [aw=factor], stat(sum) f(%20.0fc) save by(categs)
scalar IEPS = r(StatTotal)[1,1]
foreach k of local categs {
	local j = 1
	while "`=r(name`j')'" != "`k'" {
		local ++j
	}
	matrix IEPS`k' = r(Stat`j')
	local name`k' = "`=r(name`j')'"
}
foreach k of local categs {
	Gini IEPS if categs == "`k'", hogar(folioviv foliohog) factor(factor)
	local gini_ieps`k' = r(gini_IEPS)
	scalar gini_ieps`k' = `gini_ieps`k''
}

Gini IEPS, hogar(folioviv foliohog) factor(factor)
local gini_IEPS = r(gini_IEPS)
scalar gini_IEPS = `gini_IEPS'


** 6.3. Display de resultados **
noisily di _newline in g "{bf: D. IEPS" ///
	_col(44) in g "(Gini)" ///
	_col(55) in g %7s "ENIGH" ///
	_col(66) %6s "Macro" in g ///
	_col(77) %6s  "Informalidad %}"
foreach k of local categs {
	if "`k'" != "Sin_IEPS" {
		noisily di in g "  (+) `name`k''" ///
			_col(44) in y "(" %5.3fc gini_ieps`k' ")" ///
			_col(55) in y %7.3fc IEPS`k'[1,1]/PIB*100 ///
			_col(66) in y %7.3fc `Ieps`k''/PIB*100 ///
			_col(77) in y %6.1fc (IEPS`k'[1,1]/`Ieps`k''-1)*100 "%"
	}
}
noisily di in g _dup(84) "-"
noisily di in g "  Total " ///
	_col(44) in y "(" %5.3fc gini_IEPS ")" ///
	_col(55) in y %7.3fc scalar(IEPS)/PIB*100 ///
	_col(66) %7.3fc `IEPSNP'/PIB*100 ///
	_col(77) %6.1fc -(`IEPSNP'/scalar(IEPS)-1)*100 "%"

collapse (sum) IEPS, by(folioviv foliohog numren)
save "`c(sysdir_site)'/04_master/`=anioenigh'/consumption_categ_ieps.dta", replace



timer off 15
timer list 15
noisily di _newline in g "{bf:Tiempo:} " in y round(`=r(t15)/r(nt15)',.1) in g " segs."
log close expenditures
