***************************************
****                               ****
**** ARMONIZACION SCN + ENIGH 2018 ****
****    INFORMACION DE HOGARES     ****
****                               ****
***************************************
if "`1'" == "" {
	clear all
	local 1 = 2022
	scalar aniovp = 2022
	scalar anioenigh = 2022
	local enigh = "ENIGH"
	local betamin = 1			// ENIGH: 2.436
	local altimir = "yes"
	local SubsidioEmpleo = 43131000000 	// Presupuesto de gastos fiscales (2020)
	local udis = 7.380711			// Promedio de valor de UDIS de enero a diciembre 2020
	local smdf = 172.87			// Unidad de medida y actualizacion (UMA)
	local enighanio = 2022
	local segpop = "pop_insabi"
}
timer on 6
if `1' >= 2022 {
	local enigh = "ENIGH"
	local betamin = 1			// ENIGH: 2.436
	local altimir = "yes"
	local SubsidioEmpleo = 43131000000 	// Presupuesto de gastos fiscales (2020)
	local udis = 7.380711			// Promedio de valor de UDIS de enero a diciembre 2020
	local smdf = 172.87			// Unidad de medida y actualizacion (UMA)
	local enighanio = 2022
	local segpop = "pop_insabi"
}
if `1' >= 2020 & `1' < 2022 {
	local enigh = "ENIGH"
	local betamin = 1			// ENIGH: 2.436
	local altimir = "yes"
	local SubsidioEmpleo = 49997000000 	// Presupuesto de gastos fiscales (2020)
	local udis = 6.496487003		// Promedio de valor de UDIS de enero a diciembre 2020
	local smdf = 123.22			// Unidad de medida y actualizacion (UMA)
	local enighanio = 2020
	local segpop = "pop_insabi"
}
if `1' >= 2018 & `1' < 2020 {
	local enigh = "ENIGH"
	local betamin = 1			// ENIGH: 2.25
	local altimir = "yes"
	local SubsidioEmpleo = 50979000000 	// Presupuesto de gastos fiscales (2018)
	local udis = 6.054085			// Promedio de valor de UDIS de enero a diciembre 2018
	local smdf = 88.36			// Unidad de medida y actualizacion (UMA)
	local enighanio = 2018
	local segpop = "segpop"
}
if `1' >= 2016 & `1' < 2018 {
	local enigh = "ENIGH"
	local betamin = 1			// ENIGH: 2.38
	local altimir = "yes"
	local SubsidioEmpleo = 43707000000	// Presupuesto de gastos fiscales (2016)
	local udis = 5.4490872131		// Promedio de valor de UDIS de enero a diciembre 2016
	local smdf = 73.04			// Unidad de medida y actualizacion (UMA)
	local enighanio = 2016
	local segpop = "segpop"
}
if `1' >= 2014 & `1' < 2016 {
	local enigh = "ENIGH"
	local betamin = 1			// ENIGH: 2.95
	local altimir = "yes"
	local SubsidioEmpleo = 41293000000	// Presupuesto de gastos fiscales (2014)
	local udis = 5.1561230329  		// Promedio de valor de UDIS de enero a diciembre 2014
	local smdf = 67.29			// Zona A. 2014
	local enighanio = 2014
	local segpop = "segpop"
}
if `1' >= 2012 & `1' < 2014 {
	local enigh = "ENIGH"
	local betamin = 1			// ENIGH: 2.95
	local altimir = "yes"
	local SubsidioEmpleo = 41293000000	// Presupuesto de gastos fiscales (2014)
	local udis = 5.1561230329  		// Promedio de valor de UDIS de enero a diciembre 2014
	local smdf = 67.29			// Zona A. 2014
	local enighanio = 2012
	local segpop = "segpop"
}
if `1' >= 2010 & `1' < 2012 {
	local enigh = "ENIGH"
	local betamin = 1			// ENIGH: 2.95
	local altimir = "yes"
	local SubsidioEmpleo = 41293000000	// Presupuesto de gastos fiscales (2014)
	local udis = 5.1561230329  		// Promedio de valor de UDIS de enero a diciembre 2014
	local smdf = 67.29			// Zona A. 2014
	local enighanio = 2010
	local segpop = "segpop"
}
if `1' >= 2008 & `1' < 2010 {
	local enigh = "ENIGH"
	local betamin = 1			// ENIGH: 2.95
	local altimir = "yes"
	local SubsidioEmpleo = 41293000000	// Presupuesto de gastos fiscales (2014)
	local udis = 5.1561230329  		// Promedio de valor de UDIS de enero a diciembre 2014
	local smdf = 67.29			// Zona A. 2014
	local enighanio = 2008
	local segpop = "segpop"
}

** 0.1 Log-file **
capture log close households
log using "`c(sysdir_site)'/03_temp/`enighanio'/households.smcl", replace name(households)
local dir_enigh "`c(sysdir_site)'../BasesCIEP/INEGI/`enigh'/`enighanio'"

** 0.2 Bienvenida **
noisily di _newline(2) in g _dup(20) "." "{bf:   Economía generacional: " in y "INGRESOS - `enigh' `enighanio'  }" in g _dup(20) "." _newline(2)



*****************
**# 1. Macros ***
*****************
PIBDeflactor, aniovp(`enighanio') nog
forvalues k=1(1)`=_N' {
	if anio[`k'] == `enighanio' {
		local deflator = deflator[`k']
	}
}

SCN, anio(`enighanio') nographs
local PIBSCN = scalar(PIB)
local RemSal = scalar(RemSal)
local SSEmpleadores = scalar(SSEmpleadores)
local SSImputada = scalar(SSImputada)
local MixL = scalar(MixL)
local ImpNetProduccionL = scalar(ImpNetProduccionL)
local ImpNetProduccionK = scalar(ImpNetProduccionK)
local ImpNetProductos = scalar(ImpNetProductos)

local ExNOpSoc = scalar(ExNOpSoc)
local ExNOpHog = scalar(ExNOpHog)
local MixKN = scalar(MixKN)

local ROWRem = scalar(ROWRem)
local ROWTrans = scalar(ROWTrans)
local ROWProp = scalar(ROWProp)

local ComprasN = scalar(ComprasN)
local ConCapFij = scalar(ConCapFij)
local ConGob = scalar(ConGob)

** 1.2 Ajustes Rentas y Servicios Profesionales **
* Documento: Tributacion a ingresos por alquileres y servicios profesionales *
* BID, SHCP, CIEP, 2018 *
local ServProf = scalar(ServProf)
local ConsMedi = scalar(ConsMedi)
local ConsDent = scalar(ConsDent)
local ConsOtro = scalar(ConsOtro)
local EnfeDomi = scalar(EnfeDomi)
local ServProfH = scalar(ServProfH)
local SaludH = scalar(SaludH)
local SNAAlquiler = scalar(Alquileres)
local SNAInmobiliarias = scalar(Inmobiliarias)
local SNAExBOpHog = scalar(ExBOpHog)
local SNAAlojamiento = scalar(Alojamiento)

** 1.3 Macros: PEF **
PEF, anio(`enighanio') min(0) nographs
local Cuotas_ISSSTE = -r(Cuotas_ISSSTE)

capture PEF if transf_gf == 1, anio(`enighanio') by(desc_pp) min(0) nographs
local SSFederacion = r(cuota_social_seguro_de_salud_iss)+r(seguro_de_enfermedad_y_maternida)+r(seguro_de_invalidez_y_vida)+r(seguro_de_salud_para_la_familia)

PEF if divCIEP == "Educación", anio(`enighanio') by(desc_subfuncion) min(0) nographs
local Basica = r(educacion_basica)
local Media = r(educacion_media_superio)
local Superior = r(educacion_superior)
local Adultos = r(educacion_para_adultos)

PEF, anio(`enighanio') by(divCIEP) min(0) nographs
local PenBienestar = r(Pension_AM)
local OtrosGas = r(Otros)
local Pensiones = r(Pensiones)
local Educacion = r(Educación)
local Salud = r(Salud)

PEF if divCIEP == "Otras inversiones", anio(`enighanio') by(entidad) min(0) nographs
local Aguas = r(Aguascalientes)
local BajaN = r(Baja_California)
local BajaS = r(Baja_California_Sur)
local Campe = r(Campeche)
local Coahu = r(Coahuila)
local Colim = r(Colima)
local Chiap = r(Chiapas)
local Chihu = r(Chihuahua)
local Ciuda = r(Ciudad_de_México)
local Duran = r(Durango)
local Guana = r(Guanajuato)
local Guerr = r(Guerrero)
local Hidal = r(Hidalgo)
local Jalis = r(Jalisco)
local Estad = r(Estado_de_México)
local Micho = r(Michoacán)
local Morel = r(Morelos)
local Nayar = r(Nayarit)
local Nuevo = r(Nuevo_León)
local Oaxac = r(Oaxaca)
local Puebl = r(Puebla)
local Quere = r(Querétaro)
local Quint = r(Quintana_Roo)
local SanLu = r(San_Luis_Potosí)
local Sinal = r(Sinaloa)
local Sonor = r(Sonora)
local Tabas = r(Tabasco)
local Tamau = r(Tamaulipas)
local Tlaxc = r(Tlaxcala)
local Verac = r(Veracruz)
local Yucat = r(Yucatán)
local Zacat = r(Zacatecas)
local InfraT = r(StatTotal)


*********************
** 1.4 Macros: LIF **
LIF, anio(`enighanio') nographs min(0) by(divCIEP)
local ISRSalarios = r(ISR_Asa_)
local ISRFisicas = r(ISR_PF)
local ISRMorales = r(ISR_PM)
local CuotasIMSS = r(Cuotas_IMSS)
local IMSSpropio = r(IMSS) //-`CuotasIMSS'
local ISSSTEpropio = r(ISSSTE)
local CFEpropio = r(CFE)
local Pemexpropio = r(Pemex)
local FMP = r(FMP_Derechos)
local Deuda = r(Deuda)
local Mejoras = r(Contribuciones_de_mejoras)
local Derechos = r(Derechos)
local Productos = r(Productos)
local Aprovechamientos = r(Aprovechamientos)
local OtrosTributarios = r(Otros_tributarios)
local OtrasEmpresas = r(Otras_empresas)
local ISAN = r(ISAN)
local Importaciones = r(Importaciones)
local IVA = r(IVA)
local IEPS = r(IEPS)

LIF, anio(`enighanio') by(divGA) nographs min(0)
local alingreso = r(Impuestos_al_ingreso)-`ISRMorales'
local alconsumo = r(Impuestos_al_consumo)
local otrosing = r(Ingresos_de_capital)+`ISRMorales'


*********************
/** 1.5 Macros: SAT **
if `enighanio' >= 2015 {
	PIBDeflactor, aniovp(`enighanio') nographs nooutput
	forvalues k=1(1)`=_N' {
		if anio[`k'] == 2015 {
			local deflactor = deflator[`k']
		}
	}
	use "`c(sysdir_site)'../BasesCIEP/SAT/Personas fisicas/Stata/2015_labels.dta", clear
	tabstat iaarrendamiento utgravacumap utgravacumriap, stat(sum) f(%20.0fc) save
	tempname SATAbierto
	matrix `SATAbierto' = r(StatTotal)  
	local acum_arrenda = `SATAbierto'[1,1]/`deflactor'
	local util_serprof = `SATAbierto'[1,2]/`deflactor'
}
else {
	use "`c(sysdir_site)'../BasesCIEP/SAT/Personas fisicas/Stata/`enighanio'_labels.dta", clear
	tabstat iaarrendamiento utgravacumap utgravacumriap, stat(sum) f(%20.0fc) save
	tempname SATAbierto
	matrix `SATAbierto' = r(StatTotal)  
	local acum_arrenda = `SATAbierto'[1,1]
	local util_serprof = `SATAbierto'[1,2]
}


********************/
** 1.6 Macros: ISR **
if `enighanio' < 2018 {
	*			Inferior	Superior	CF		Tasa		
	matrix	ISR	=	(0.00,		5952.84,	0.0,		1.92	\	///	1
				5952.85,	50524.92,	114.24,		6.40	\ 	///	2
				50524.93,	88793.04,	2966.76,	10.88	\ 	///	3
				88793.05,	103218.00,	7130.88,	16.00	\ 	///	4
				103218.01,	123580.20,	9438.60,	17.92	\ 	///	5
				123580.21,	249243.48,	13087.44,	21.36	\ 	///	6
				249243.49,	392841.96,	39929.04,	23.52	\ 	///	7
				392841.97,	750000.00, 	73703.40,	30.00	\ 	///	8
				750000.01,	1000000.00,	180850.82,	32.00	\ 	///	9
				1000000.01,	3000000.00,	360850.81,	34.00	\ 	///	10
				3000000.01,	1E+14, 		940850.81,	35.00)		//	11

	*			Inferior	Superior	Subsidio
	matrix	SE	=	(0.00,		21227.52,	4884.24	\	///	1
				21227.53,	23744.40,	4881.96	\	///	2
				23744.41,	31840.56,	4318.08	\	///	3
				31840.57,	41674.08,	4123.20	\	///	4
				41674.09,	42454.44,	3723.48	\	///	5
				42454.45,	53353.80,	3581.28	\	///	6
				53353.81,	56606.16,	4250.76	\	///	7
				56606.17,	64025.04,	3898.44	\	///	8
				64025.05,	74696.04,	3535.56	\	///	9
				74696.05,	85366.80,	3042.48	\	///	10
				85366.81,	88587.96,	2611.32	\	///	11
				88587.97, 	1E+14,		0)		//	12
}
if `enighanio' >= 2018 & `enighanio' <= 2020 {
	*			Inferior	Superior	CF		Tasa		
	matrix	ISR	=	(0.00,		6942.20,	0.0,		1.92	\	///	1
				6942.21,	58922.16,	114.24,		6.40	\ 	///	2
				58922.17,	103550.44,	2966.76,	10.88	\ 	///	3
				103550.45,	120372.83,	7130.88,	16.00	\ 	///	4
				120372.84,	144119.23,	9438.60,	17.92	\ 	///	5
				144119.24,	290667.75,	13087.44,	21.36	\ 	///	6
				290667.76,	458132.29,	39929.04,	23.52	\ 	///	7
				458132.30,	874650.00, 	73703.40,	30.00	\ 	///	8
				874650.01,	1166200.00,	180850.82,	32.00	\ 	///	9
				1166200.01,	3498600.00,	360850.81,	34.00	\ 	///	10
				3498600.01,	1E+14, 		940850.81,	35.00)		//	11

	*			Inferior	Superior	Subsidio
	matrix	SE	=	(0.00,		1768.96*12,	407.02*12	\	///	1
				1768.96*12+.01,	2653.38*12,	406.83*12	\	///	2
				2653.38*12+.01,	3472.84*12,	406.62*12	\	///	3
				3472.84*12+.01,	3537.87*12,	392.77*12	\	///	4
				3537.87*12+.01,	4446.15*12,	382.46*12	\	///	5
				4446.15*12+.01,	4717.18*12,	354.23*12	\	///	6
				4717.18*12+.01,	5335.42*12,	324.87*12	\	///	7
				5335.42*12+.01,	6224.67*12,	294.63*12	\	///	8
				6224.67*12+.01,	7113.90*12,	253.54*12	\	///	9
				7113.90*12+.01,	7382.33*12,	217.61*12	\	///	10
				7382.33*12+.01,	1E+14,		0)				//	11
}

if `enighanio' >= 2022 {
	*			Inferior	Superior		CF				Tasa		
	matrix ISR 	= 	(0.01,		7735.00,		0.0,			1.92	\	/// 1
				7735.01,	65651.07,		148.51,			6.40	\	/// 2
				65651.08,	115375.90,		3855.14,		10.88	\	/// 3
				115375.91,	134119.41,		9265.20,		16.00	\	/// 4
				134119.42,	160577.65,		12264.16,		17.92	\	/// 5
				160577.66,	323862.00,		17005.47,		21.36	\	/// 6
				323862.01,	510451.00,		51883.01,		23.52	\	/// 7
				510451.01,	974535.03,		95768.74,		30.00	\	/// 8
				974535.04,	1299380.04,		234993.95,		32.00	\	/// 9
				1299380.05,	3898140.12,		338944.34,		34.00	\	/// 10
				3898140.13,	1E+14,			1222522.76,		35.00)		//  11

	*             		Inferior		Superior		Subsidio
	matrix	SE	=	(0.00,			1768.96*12,		407.02*12	\	///	1
				1768.96*12+.01,		2653.38*12,		406.83*12	\	///	2
				2653.38*12+.01,		3472.84*12,		406.62*12	\	///	3
				3472.84*12+.01,		3537.87*12,		392.77*12	\	///	4
				3537.87*12+.01,		4446.15*12,		382.46*12	\	///	5
				4446.15*12+.01,		4717.18*12,		354.23*12	\	///	6
				4717.18*12+.01,		5335.42*12,		324.87*12	\	///	7
				5335.42*12+.01,		6224.67*12,		294.63*12	\	///	8
				6224.67*12+.01,		7113.90*12,		253.54*12	\	///	9
				7113.90*12+.01,		7382.33*12,		217.61*12	\	///	10
				7382.33*12+.01,		1E+14,			0)				//	11
}

********************************
** 1.7 Micro 1. ENIGH. Gastos **
capture confirm file "`c(sysdir_site)'/SIM/`enighanio'/deducciones.dta"
if _rc != 0 {
	noisily run "`c(sysdir_site)'/Expenditure.do" `enighanio'
}



*************************************************
**# 2. IDENTIFICAR INGRESOS CONFORME A LA LEY ***
*************************************************
* ÍNDICE  DE LA SECCIÓN *
* TITULO II. DE LAS PERSONAS MORALES *
*	2.1 Capitulo VIII. 	REGIMEN DE ACTIVIDADES AGRICOLAS, GANADERAS, SILVICOLAS Y PESQUERAS *
* TITULO IV. DE LAS PERSONAS FISICAS *
*	2.2 Capitulo I. 	DE LOS INGRESOS POR SALARIOS Y EN GENERAL POR LA PRESTACION DE UN SERVICIO PERSONAL SUBORDINADO *
*	2.3 Capitulo II. 	DE LOS INGRESOS POR ACTIVIDADES EMPRESARIALES Y PROFESIONALES *
*	2.4 Capitulo III.	DE LOS INGRESOS POR ARRENDAMIENTO Y EN GENERAL POR OTORGAR EL USO O GOCE TEMPORAL DE BIENES INMUEBLES *
*	2.5 Capitulo IV. 	DE LOS INGRESOS POR ENAJENACION DE BIENES *
*	2.6 Capitulo V. 	DE LOS INGRESOS POR ADQUISICION DE BIENES *
*	2.7 Capitulo VI. 	DE LOS INGRESOS POR INTERESES *
*	2.8 Capitulo VII.	DE LOS INGRESOS POR LA OBTENCION DE PREMIOS *
*	2.9 Capitulo VIII.	DE LOS INGRESOS POR DIVIDENDOS Y EN GENERAL POR LAS GANANCIAS DISTRIBUIDAS POR PERSONAS MORALES *
*	2.10 Capitulo IX. 	DE LOS DEMAS INGRESOS QUE OBTENGAN LAS PERSONAS FISICAS *
use "`dir_enigh'/ingresos.dta", clear
merge m:1 (folioviv foliohog numren) using "`dir_enigh'/poblacion.dta", nogen keep(matched)
merge m:1 (folioviv foliohog) using "`dir_enigh'/concentrado.dta", nogen keepusing(estim_alqu factor)
replace numren = "01" if numren == ""

* Limpiar *
foreach k of varlist ing_*  {
	replace `k' = 0 if `k' == .
}

* Anualizar ingresos *
g ing_anual = ing_tri*4.3333

* Ingreso unico *
egen double ing_unico = rsum(ing_1 ing_2 ing_3 ing_4 ing_5 ing_6)

* Tipo de trabajo *
g id_trabajo = "1" if clave >= "P001" & clave <= "P013"			// Ingresos del trabajo principal
replace id_trabajo = "2" if clave >= "P014" & clave <= "P020"	// Ingresos del trabajo secundario
replace id_trabajo = "0" if id_trabajo == ""					// Ingresos ajenos al trabajo

* Estimación de alquiler *
rename estim_alqu ing_estim_alqu

********************************************
** 2.1 Titulo II. De las Personas Morales **
/* Artículo 7. Cuando en esta Ley se haga mención a persona moral, se entienden comprendidas, entre
otras, las sociedades mercantiles, los organismos descentralizados que realicen preponderantemente
actividades empresariales, las instituciones de crédito, las sociedades y asociaciones civiles y la
asociación en participación cuando a través de ella se realicen actividades empresariales en México. */

* a. Actividades empresariales *
g ing_empre = 0
replace ing_empre = ing_anual if clave == "P068" | clave == "P069" | clave == "P070" | clave == "P075" | clave == "P076" | clave == "P077"
egen double ing_t2_cap1 = rsum(ing_empre)

** Capitulo VIII. REGIMEN DE ACTIVIDADES AGRICOLAS, GANADERAS, SILVICOLAS Y PESQUERAS **
* b. Agricultura *
g ing_agri = ing_anual if clave == "P071" | clave == "P072" | clave == "P073" | clave == "P074" ///
	| clave == "P078" | clave == "P079" | clave == "P080" | clave == "P081"
egen double ing_t2_cap8 = rsum(ing_agri)

***************************************
** Titulo IV De las Personas Fisicas **
** 2.2 Capitulo I. DE LOS INGRESOS POR SALARIOS Y EN GENERAL POR LA PRESTACION DE UN SERVICIO PERSONAL SUBORDINADO **
noisily di _col(04) in g "{bf:SUPUESTO: " in y ///
	"Los ingresos reportados por el trabajo subordinado son netos de las retenciones de ISR a asalariados.}"

* c. Sueldos, Salarios o Jornal *
g ing_ss = ing_anual if clave == "P001" | clave == "P011" | clave == "P006" | clave == "P014" | clave == "P018"
g p001 = ing_anual if clave == "P001"
g p011 = ing_anual if clave == "P011"
g p014 = ing_anual if clave == "P014"
g p018 = ing_anual if clave == "P018"

* d. Destajo *
g ing_desta = ing_anual if clave == "P002"

* e. Comisiones y Propinas *
g ing_prop = ing_anual if clave == "P003"

* f. Horas extras *
g ing_horas = ing_anual if clave == "P004"

* g. Incentivos, gratificaciones o premios *
g ing_grati = ing_anual if clave == "P005"

* h. Primas vacacionales y otras prestaciones en efectivo *
g ing_prima = ing_anual if clave == "P007"

* i. Reparto de utilidades *
g ing_util = ing_anual if clave == "P008" | clave == "P015"

* j. Aguinaldo *
g ing_agui = ing_anual if clave == "P009" | clave == "P016"

* k. Indemnizaciones *
g jubilacion = act_pnea1 == "2"
g ing_indemn = ing_anual if clave == "P035" | (clave == "P032" & jubilacion == 0)

* l. Indemnizaciones 2 *
g ing_indemn2 = ing_anual if clave == "P036"

* m. Indeminizaciones 3 *
g ing_indemn3 = ing_anual if clave == "P034"

* n. Jubilaciones y ahorros *
g ing_jubila = ing_anual if clave == "P032" & jubilacion == 1

* TOTAL *
egen double ing_t4_cap1 = rsum(ing_ss ing_desta ing_prop ing_horas ing_grati ing_prima ing_util ing_agui ing_indemn ing_indemn2 ing_indemn3 ing_jubila)

************************************************************************************
** 2.3 Capitulo II. DE LOS INGRESOS POR ACTIVIDADES EMPRESARIALES Y PROFESIONALES **
noisily di _col(04) in g "{bf:SUPUESTO: " in y "Los dem{c a'}s ingresos se reportan de manera bruta.}"

* p. Honorarios *
g ing_honor = 0
replace ing_honor = ing_anual if clave == "P012" | clave == "P013" ///
	| clave == "P019" | clave == "P020" | clave == "P021" | clave == "P022" ///
	| clave == "P049"

* TOTAL *
egen double ing_t4_cap2 = rsum(ing_honor)
g ing_t4_cap2pf = ing_t4_cap2*((`ServProfH'+`SaludH')/(`ServProf'+`ConsMedi'+`ConsDent'+`ConsOtro'+`EnfeDomi'))
g ing_t4_cap2PM = ing_t4_cap2*(1-(`ServProfH'+`SaludH')/(`ServProf'+`ConsMedi'+`ConsDent'+`ConsOtro'+`EnfeDomi'))

*****************************************************************************************************************************
** 2.4 Capitulo III. DE LOS INGRESOS POR ARRENDAMIENTO Y EN GENERAL POR OTORGAR EL USO O GOCE TEMPORAL DE BIENES INMUEBLES **
* q. Renta de bienes inmuebles *
g ing_rent = ing_anual if clave == "P023" | clave == "P024" | clave == "P025" | clave == "P031"

* TOTAL *
egen double ing_t4_cap3 = rsum(ing_rent)
g ing_t4_cap3pf = ing_t4_cap3*((`SNAAlojamiento'-`SNAExBOpHog')/(`SNAAlquiler'+`SNAInmobiliarias'-`SNAExBOpHog'))
g ing_t4_cap3PM = ing_t4_cap3*(1-(`SNAAlojamiento'-`SNAExBOpHog')/(`SNAAlquiler'+`SNAInmobiliarias'-`SNAExBOpHog'))

****************************************************************
** 2.5 Capitulo IV. DE LOS INGRESOS POR ENAJENACION DE BIENES **
* r. Enajenaciones diversas *
g ing_enaje = ing_anual if clave == "P054" | clave == "P055" | clave == "P056" | clave == "P060"

* s. Enajenacion casa habitacion *
g ing_enajecasa = ing_anual if clave == "P059"

* t. Enajenacion de bienes muebles *
g ing_enajem = ing_anual if clave == "P061" | clave == "P062" | clave == "P063"

* TOTAL *
egen double ing_t4_cap4 = rsum(ing_enajecasa ing_enajem ing_enaje) // 3

***************************************************************
** 2.6 Capitulo V. DE LOS INGRESOS POR ADQUISICION DE BIENES **
* u. Donaciones *
g ing_dona = ing_anual if clave == "P039" | clave == "P040"

* TOTAL *
egen double ing_t4_cap5 = rsum(ing_dona)

****************************************************
** 2.7 Capitulo VI. DE LOS INGRESOS POR INTERESES **
* v. Intereses *
g ing_intereses = ing_anual if clave == "P026" | clave == "P027" | clave == "P028" | clave == "P029"

* TOTAL *
egen double ing_t4_cap6 = rsum(ing_intereses)

*******************************************************************
** 2.8 Capitulo VII. DE LOS INGRESOS POR LA OBTENCION DE PREMIOS **
* w. Loterias *
g ing_loter = ing_anual if clave == "P058"

* TOTAL *
egen double ing_t4_cap7 = rsum(ing_loter)

************************************************************************************************************************
** 2.9 Capitulo VIII. DE LOS INGRESOS POR DIVIDENDOS Y EN GENERAL POR LAS GANANCIAS DISBRIBUIDAS POR PERSONAS MORALES **
* x. Acciones *
g ing_acc = ing_anual if clave == "P050"

* TOTAL *
egen double ing_t4_cap8 = rsum(ing_acc)

********************************************************************************
** 2.10 Capitulo IX. DE LOS DEMAS INGRESOS QUE OBTENGAN LAS PERSONAS FISICIAS **
* y. Derechos de autor *
g ing_autor = ing_anual if clave == "P030"

* z. Remesas *
g ing_remesas = ing_anual if clave == "P033" | clave == "P041"

* aa. Ingreso por trabajo de menores de 12 anios *
g ing_trabmenor = ing_anual if clave == "P067"

* ab. Ingreso por prestamos *
g ing_prest = ing_anual if clave == "P052" | clave == "P053" | clave == "P064"

* ac. Ingreso por otras percepciones de capital *
g ing_otrocap = ing_anual if clave == "P066"

* ad. Retiros de ahorro o seguro de vida *
g ing_ahorro = ing_anual if clave == "P051" | clave == "P065"

* ae. Prestaciones de Seguridad Social y Prevision Social *
g ing_benef = ing_anual if clave == "P037" | clave == "P038" | (clave >= "P042" & clave <= "P048")

* af. Herencias o Legados *
g ing_heren = ing_anual if clave == "P057"

* ag. PAM *
if `enighanio' >= 2020 {
	g ing_PAM = ing_anual if clave == "P104" | clave == "P105"
}
else {
	g ing_PAM = ing_anual if clave == "P044" | clave == "P045"
}

egen double ing_t4_cap9 = rsum(ing_autor ing_remesas ing_trabmenor ing_prest ing_otrocap ing_ahorro ing_benef ing_heren)



******************************
***                        ***
**# 3. IDENTIFY EXEMPTIONS ***
***                        ***
******************************
collapse (sum) ing_* p0* (max) jubilado=jubilacion factor, by(folioviv foliohog numren id_trabajo)
sort folioviv foliohog numren

* Ingreso total *
egen ing_exclusivo = rsum(ing_agri - ing_autor)
replace ing_exclusivo = ing_exclusivo - ing_benef - ing_dona // Exclusiones

********************************************
** 3.1 Titulo II. De las Personas Morales **
** Capitulo I. REGIMEN DE ACTIVIDADES AGRICOLAS, GANADERAS, SILVICOLAS Y PESQUERAS **
* a. Actividades empresariales *
g exen_empre = min(0,ing_empre)

* TOTAL *
egen double exen_t2_cap1 = rsum(exen_empre)

** Capitulo VIII. REGIMEN DE ACTIVIDADES AGRICOLAS, GANADERAS, SILVICOLAS Y PESQUERAS **
/* Art. 74. Deberan cumplir con sus obligaciones fiscales en materia del impuesto sobre la renta conforme 
al regimen establecido en el presente Capitulo, los siguientes contribuyentes:

III. Las personas fisicas que se dediquen exclusivamente a actividades agricolas, ganaderas, silvicolas o pesqueras.

(...)

II. Para calcular y enterar el impuesto del ejercicio de cada uno de sus integrantes, determinaran la utilidad 
gravable del ejercicio aplicado al efecto de lo dispuesto en el articulo 109 de esta Ley. A la utilidad gravable 
determinada en los terminos de esta fraccion, se le aplicara la tarifa del articulo 152 de esta Ley, tratandose de 
personas fisicas, o la tasa establecida en el articulo 9 de la misma, tratandose de personas morales. 

(...)

En el caso de las personas fisicas, no pagaran el impuesto sobre la renta por los ingresos provenientes de dichas 
actividades hasta por un monto, en el ejercicio, de 40 veces el salario minimo general correspondiente al area 
geografica del contribuyente, elevado al anio.

(...)

Tratandose de personas fisicas y morales que se dediquen exclusivamente a las actividades agricolas, ganaderas, 
silvicolas o pesqueras, cuyos ingresos en el ejercicio excedan de 20 o 40 veces el salario minimo general del area 
geografica del contribuyente elevado al anio, segun corresponda, pero sean inferiores de 423 veces el salario minimo 
general del area geografica del contribuyente elevado al anio, les sera aplicable lo dispuesto en el parrafo anterior, 
por el excedente se pagara el impuesto en los terminos de septimo parrafo de este articulo, reduciendose el impuesto 
determinado conforme a la fraccion II de dicho parrafo, en un 40% tratandose de personas fisicas y en un 30% para 
personas morales. 

(...) 

Las personas fisicas y morales que se dediquen exclusivamente a las actividades agricolas, ganaderas, silvicolas o 
pesqueras, cuyos ingresos en el ejercicio rebasen los montos senialados en el decimo segundo parrafo, les sera aplicable 
la exencion prevista en el decimo primer parrafo de este articulo, por el excedente, se pagara el impuesto en los 
terminos del septimo parrafo de este articulo y sera aplicable la reduccion a que se refiere el decimo segundo
parrafo de este articulo hasta por los montos en el establecidos.*/

* b. Agricultura *
noisily di _col(04) in g "{bf:SUPUESTO: " in y ///
	"Se dedican exclusivamente a actividades agr{c i'}colas si es mayor al 90%.}"
g agri = ing_agri/ing_exclusivo > .9 & ing_agri > 0			// Dummy exclusivamente agricola
g exen_agri = min(40*`smdf'*360,ing_agri) if agri == 0		// General
replace exen_agri = min(423*`smdf'*360,ing_agri) if agri == 1		// Exclusivamente agricola

* TOTAL *
egen double exen_t2_cap8 = rsum(exen_agri)

*******************************************
** 3.2 Titulo IV De las Personas Fisicas **
** Capitulo I. DE LOS INGRESOS POR SALARIOS Y EN GENERAL POR LA PRESTACION DE UN SERVICIO PERSONAL SUBORDINADO **
/* Articulo 94. Se consideran ingresos por la prestacion de un servicio personal subordinado, los salarios y demas 
prestaciones que deriven de una relacion laboral, incluyendo la participacion de los trabajadores en las utilidades 
de las empresas y las prestaciones percibidas como consecuencia de la terminacion de la relacion laboral. (...) */

* c. Sueldos, Salarios o Jornal *
g exen_ss = min(0,ing_ss)

* d. Destajo *
g exen_desta = min(0,ing_desta)

* e. Comisiones y Propinas *
g exen_prop = min(0,ing_prop)

/* Articulo 93. No se pagara el impuesto sobre la renta por la obtencion de los siguientes ingresos:
I. Las prestaciones distintas del salario que reciban los trabajadores del salario minimo general para una
o varias areas geograficas, calculadas sobre la base de dicho salario, cuando no excedan de los minimos 
senialados por la legislacion laboral, asi como las remuneraciones por by de tiempo extraordinario
o de prestacion de servicios que se realicen en los dias de descanso sin disfrutar de otros en
sustitucion, hasta el limite establecido en la legislacion laboral, que perciban dichos trabajadores.
Tratandose de los demas trabajadores, el 50% de las remuneraciones por by de tiempo 
extraordinario o de la prestacion de servicios que se realice en los dias de descanso sin disfrutar
de otros en sustitucion, que no exceda el limite previsto en la legislacion laboral y sin que esta
exencion exceda del equivalente de cinco veces el salario minimo general del area geografica del trabajador
por cada semana de servicios. 

II. Por el excedente de las prestaciones exceptuadas del pago del impuesto a que se refiere la fraccion
anterior, se pagara el impuesto en los terminos de este Titulo*/

* f. Horas extras *
g tsm = p001/360/`smdf' if p001 > 0
g exen_horas = min(.5*ing_horas,5*`smdf'*360,ing_horas)
replace exen_horas = ing_horas if tsm <= 1

/* Articulo 93. No se pagara el impuesto sobre la renta por la obtencion de los siguientes ingresos: (...)
XIV. Las gratificaciones que reciban los trabajadores de sus patrones, durante un anio de calendario, 
hasta el equivalente del salario minimo general del area geografica del trabajador elevado a 30 dias,
cuando dichas gratificaciones se otorguen en forma general; asi como las primas vacacionales que 
otorguen los patrones durante el anio de calendario a sus trabajadores en forma general y la participacion
de los trabajadores en las utilidades de las empresas, hasta por el equivalente a 15 dias de salario
general del area geografica del trabajador, por cada uno de los bys senialados. Tratandose de primas 
dominicales hasta por el equivalente de un salario minimo general del area geografica del trabajador por 
cada domingo que se labore.

XV. Por el excedente de los ingresos a que se refiere la fraccion anterior se pagara el impuesto
en los terminos de este Titulo.*/

* g. Incentivos, gratificaciones o premios *
g exen_grati = min(30*`smdf',ing_grati)

* h. Primas vacacionales y otras prestaciones en efectivo *
g exen_prima = min(15*`smdf',ing_prima)

* i. Reparto de utilidades *
g exen_util = min(15*`smdf',ing_util)

* j. Aguinaldo *
g exen_agui = min(30*`smdf',ing_agui)

/* Articulo 93. No se pagara el impuesto sobre la renta por la obtencion de los siguientes ingresos: (...)
III. Las indemnizaciones por riesgos de trabajo o enfermedades, que se concedan de acuerdo con las leyes, por 
contratos colectivos de trabajo o por contratos Ley. */

* k. Indemnizaciones *
noisily di _col(04) in g "{bf:SUPUESTO: " in y "Las indemnizaciones se conceden de acuerdo con las leyes.}"
g exen_indemn = ing_indemn

/* Articulo 93. No se pagara el impuesto sobre la renta por la obtencion de los siguientes ingresos: (...)
XIII. Los que obtengan las personas que han estado sujetas a una relacion laboral en el momento de su separacion, 
por by de primas de antiguedad, retiro e indemnizaciones u otros pagos, asi como los obtenidos con cargo a 
la subcuenta del seguro de retiro o a la subcuenta de retiro, cestania en edad avanada y vejez, previstas en la 
Ley del Seguro Social y los que obtengan los trabajadores al servicio del Estado con cargo a la cuenta individual 
del sistema de ahorro para el retiro, prevista en la Ley del Instituto de Seguridad y Servicios Sociales de los 
Trabajadores del Estado, hasta por el equivalente a noventa veces el salario minimo general del area geografica 
del contribuyente por cada anio de servicio o de contribucion en el caso de la subcuenta del seguro de retiro, de 
la subcuenta de retiro, cestania en edad avanzada y vejez o de la cuenta individual del sistema de ahorro para el 
retiro (...) Toda fraccion de mas de seis meses se considerara un anio completo. Por el excedente se pagara el 
impuesto en los terminos de este Titulo.

Articulo 95. Cuando se obtengan ingresos por by de primas de antiguedad, retiro e indemnizaciones u otros 
pagos, por separacion, se calculara el impuesto anual, conforme a las siguientes reglas:

I. Del total de percepciones por este by, se separara una cantidad igual a la del ultimo sueldo mensual ordinario, 
la cual se sumara a los demas ingresos por los que se deba pagar el impuesto en el anio de calendario de que se trate 
y se calculara, en los terminos de este Titulo, el impuesto correspondiente a dichos ingresos. Cuando el total de las 
percepciones sean inferiores al ultimo sueldo mensual ordinario, estas se sumaran en su totalidad a los demas ingresos 
por los que se deba pagar el impuesto y no se aplicara la fraccion II de este articulo.

II. Al total de percepciones por este by se restara una cantidad igual a la del ultimo sueldo mensual ordinario y 
al resultado se le aplicara la tasa que correspondio al impuesto que seniala la fraccion anterior. El impuesto que 
resulte se sumara al calculado conforme a la fraccion que antecede.

La tasa a que se refiere la fraccion II que antecede se calculara dividiendo el impuesto senialado en la fraccion I 
anterior entre la cantidad a la cual se le aplico la tarifa del articulo 152 de esta Ley; el cociente asi obtenido 
se multiplica por cien y el producto se expresa en por ciento. */

* l. Indemnizaciones 2 *
egen double salario = sum(p001), by(folioviv foliohog numren)
g exen_indemn2 = min(90*`smdf'*round(ing_indemn2/salario,1),ing_indemn2)
replace exen_indemn2 = exen_indemn2 - salario/12 if exen_indemn2 - salario/12 > 0

/* Articulo 93. No se pagara el impuesto sobre la renta por la obtencion de los siguientes ingresos: (...)
XXV. Las indemnizaciones por danios que no excedan al valor de mercado del bien de que se trate. Por el excedente 
se pagara el impuesto en los terminos de este Titulo. */

* m. Indemnizaciones 3 *
noisily di _col(04) in g "{bf:SUPUESTO: " in y ///
	"Las indemnizaciones por da{c n~}os no se exceden al valor de mercado.}"
g exen_indemn3 = ing_indemn3

/* Articulo 93. No se pagara el impuesto sobre la renta por la obtencion de los siguientes ingresos: (...)
IV. Las jubilaciones, pensiones, haberes de retiro, asi como las pensiones vitalicias u otras formas de retiro, 
provenientes de la subcuenta del seguro de retiro o de la subcuenta de retiro, cesantia en edad avanzada y vejez, 
previstas en la Ley del Seguro Social y las provenientes de la cuenta individual del sistema de ahorro para el 
retiro prevista en la Ley del Instituto de Seguridad y Servicios Sociales de los Trabajadores del Estado, en los 
casos de invalidez, incapacidad, cesantia, vejez, retiro y muerte, cuyo monto diario no exceda de nueve veces el 
salario minimo general del area geografica del contribuyente, y el beneficio previsto en la Ley de Pension Universal. 
Por el excedente se pagara el impuesto en los terminos de este Titulo.

V. Para aplicar la exencion sobre los bys a que se refiere la fraccion anterior, se debera consdierar la 
totalidad de las pensiones y de los haberes de retiro pagados al trabajador a que se refiere la misma, independientemente 
de quien los pague. Sobre el excedente se debera efectuar la retencion en los terminos que al efecto establezca el 
Reglamento de esta Ley.*/

* n. Jubilaciones y ahorros *
g exen_jubila = min(9*`smdf',ing_jubila) if jubilado == 1

* TOTAL *
egen double exen_t4_cap1 = rsum(exen_ss exen_desta exen_prop exen_horas exen_grati exen_prima exen_agui exen_util ///
	exen_indemn exen_indemn2 exen_jubila)

************************************************************************************
** 3.3 Capitulo II. DE LOS INGRESOS POR ACTIVIDADES EMPRESARIALES Y PROFESIONALES **
/* Articulo 100. (...)
Para efectos de este Capitulo se consideran:
	I. Ingresos por actividades empresariales, los provenientes de la realizacion de actividades comerciales, 
	industriales, agricolas, ganaderas, de pesca o silvicolas.
	II. Ingresos por la prestacion de un servicio profesional, las remuneraciones que deriven de un servicio 
	personal independiente y cuyos ingresos no esten considerados en el Capitulo I de este Titulo. 

Articulo 109. Los contribuyentes a que se refiere esta Seccion, deberan calcular el impuesto del ejercicio a su 
cargo en los terminos del articulo 152 de esta Ley. (...) */

* s. Honorarios *
noisily di _col(04) in g "{bf:SUPUESTO: " in y ///
	"Se considera un " %5.2fc 0.634768962*100 ///
	"% de servicios profesionales (honorarios) como remuneraciones y gastos operativos.}" // Censo Económico 2019
g exen_honor = min(0.634768962*ing_honor,ing_honor)
egen double exen_t4_cap2 = rsum(exen_honor)

g exen_t4_cap2pf = exen_t4_cap2*((`ServProfH'+`SaludH')/(`ServProf'+`ConsMedi'+`ConsDent'+`ConsOtro'+`EnfeDomi'))
g exen_t4_cap2PM = exen_t4_cap2*(1-(`ServProfH'+`SaludH')/(`ServProf'+`ConsMedi'+`ConsDent'+`ConsOtro'+`EnfeDomi'))


*****************************************************************************************************************************
** 3.4 Capitulo III. DE LOS INGRESOS POR ARRENDAMIENTO Y EN GENERAL POR OTORGAR EL USO O GOCE TEMPORAL DE BIENES INMUEBLES **
/* Articulo 115. Las personas que obtengan ingresos por bys a que se refiere este Capitulo, podran efectuar 
las siguientes deducciones:

(...)

(Segundo Parrafo) Los contribuyentes que otorguen el uso o goce temporal de bienes inmuebles podran optar por deducir 
el 35% de los ingresos a que se refiere este Capitulo, en substitutcion de las deducciones a que este articulo se 
refiere. Quienes ejercen esta opcion podran deducir, ademas, el monto de las erogaciones por by del impuesto 
predial de dichos inmuebles correspondiente al anio de calendario o al periodo durante el cual se obtuvieron los 
ingresos en el ejercicio segun corresponda.*/

* t. Rentas de bienes inmuebles *
noisily di _col(04) in g "{bf:SUPUESTO: " in y ///
	"Todos los ingresos por rentas optan por la opción de deducir el 35%.}"
noisily di _col(04) in g "{bf:SUPUESTO: " in y ///
	"Se supone un 2% del predial del total de los ingresos por rentas.}"
g exen_rent = .35*ing_rent+.02*ing_rent

* TOTAL *
egen double exen_t4_cap3 = rsum(exen_rent)
g exen_t4_cap3pf = exen_t4_cap3*((`SNAAlojamiento'-`SNAExBOpHog')/(`SNAAlquiler'+`SNAInmobiliarias'-`SNAExBOpHog'))
g exen_t4_cap3PM = exen_t4_cap3*(1-(`SNAAlojamiento'-`SNAExBOpHog')/(`SNAAlquiler'+`SNAInmobiliarias'-`SNAExBOpHog'))



****************************************************************
** 3.5 Capitulo IV. DE LOS INGRESOS POR ENAJENACION DE BIENES **
/* Articulo 120. Las personas que obtengan ingresos por enajenacion de bienes, podran efectuar las deducciones a 
que se refiere el articulo 121 de esta Ley; con la ganancia asi determinada se calculara el impuesto anual como sigue:

I. La ganancia se dividira entre el numero de anios transcurrido entre la fecha de adquisicion y la enajenacion, 
sin exceder de 20 anios.
II. El resultado que se obtenga conforme a la fraccion anterior, sera la parte de la ganancia que se sumara a los 
demas ingresos acumulables del anio de calendario de que se trate y se calculara, en los terminos de este Titulo, el 
impuesto correspondiente a los ingresos acumulables.
III. La parte de la ganancia no acumulable se multiplicara por la tasa de impuesto que se obtenga conforme al siguiente 
parrafo. El impuesto que resulte se sumara al calculado conforme a la fraccion que antecede.

El contribuyente podra optar por calcular la tasa a que se refiere el parrafo que antecede, conforme a lo dispuesto en 
cualquiera de los dos incisos siguientes:
a) Se aplicara la tarifa que resulte conforme al articulo 152 de esta Ley a la totalidad de los ingresos acumulable 
obtenidos en el anio en que se realizo la enajenacion, disminuidos por las deduccones autorizada por la propia Ley, 
excepto las establecidas en las fracciones I, II y III del articulo 151 de la misma. El resultado asi obtenido se 
dividira entre la cantidad a la que se aplico la tarifa y el cociente sera la tasa. */


* u. Enajenacion de bienes *
noisily di _col(04) in g "{bf:SUPUESTO: " in y ///
	"Se aplica la tarifa que resulte conforme al art{c i'}culo 152 para la enajenación de bienes.}"
g exen_enaje = min(0,ing_enaje)

/* Articulo 93. No se pagara el impuesto sobre la renta por la obtencion de los siguientes ingresos: (...)
XIX. Los derivados de la enajenacion de:
a) La casa habitacion del contribuyente, siempre que el monto de la contraprestacion obtenida no exceda de 
setecientas mil unidades de inversion y (...)

Por el excedente se determinara la ganancia y se calcularan el impuesto anual y el pago provisional en los terminos 
del Capitulo IV de este Titulo, considerando las deducciones en la proporcion que resulte de dividir el excedente 
entre el monto de la contraprestacion obtenida. (...) 

La exencion prevista en este inciso sera aplicable siempre que durante los cinco anios inmediatos anteriores a la 
fecha de enajenacion de que se trate el contribuyente no hubiere enajenado otra casa habitacion por la que hubiera 
obtenido la exencion prevista en este inciso (...) 

El limite establecido en el primer parrafo de este inciso no sera aplicable cuando el enajenante demuestre haber 
residido en su casa habitacion durante los cinco anios inmediatos anteriores a la fecha de su enajenacion */

* v. Enajenacion casa habitacion *
local limudis = 700000
g exen_enajecasa = min(`limudis'*`udis',ing_enajecasa)

/* b) Bienes muebles, distintos de las acciones, de las partes sociales, de los titulos de valor y de las 
inversiones del contribuyente, cuando en un anio de calendario la diferencia entre el total de las enajenaciones 
y el costo comprobado de la adquisicion de los bienes enajeandos, no exceda de tres veces el salario minimo general 
del area geografica del contribuyente elevado al anio. Por la utilidad que exceda se pagara el impuesto en los
terminos de este Titulo. */

* w. Enajenacion de bienes muebles *
noisily di _col(04) in g "{bf:SUPUESTO: " in y ///
	"Para la enajenación de bienes muebles, nunca se sobrepasa el valor de adquisición de los bienes.}"
g exen_enajem = min(3*`smdf'*360,ing_enajem)

* TOTAL *
egen double exen_t4_cap4 = rsum(exen_enaje exen_enajecasa exen_enajem)

***************************************************************
** 3.6 Capitulo V. DE LOS INGRESOS POR ADQUISICION DE BIENES **
/* Articulo 130. Se consideran ingresos por adquisicion de bienes:
I. La donacion (...)

Articulo 93. No se pagara el impuesto sobre la renta por la obtencion de los siguientes ingresos: (...)
XXIII. Los donativos en los siguientes casos: (...)
c) Los demas donativos, siempre que el valor total de los recibidos en un anio de calendario no exceda de tres veces 
el salario minimo general del area geografica del contribuyente elevado al anio. Por el excedente se pagara impuesto 
en los termino de este Titulo. */

* x. Donaciones *
g exen_dona = min(3*`smdf'*360,ing_dona)

* TOTAL *
egen double exen_t4_cap5 = rsum(exen_dona)

****************************************************
** 3.7 Capitulo VI. DE LOS INGRESOS POR INTERESES **
/* Articulo 8. Para los efectos de esta Ley, cualquiera que sea el nombre con que se les designe, a los 
rendimientos de credito de cualquier clase. Se entiende que, entre otros, son intereses: los rendimientos 
de la deuda publica, de los bonos u obligaciones, incluyendo descuentos, primas y premios; los premios de 
reportos o de prestamos de valores; el monto de las comisiones que correspondan con motivo de apertura o 
garantia de creditos; el monto de las contraprestaciones correspondientes a la aceptacion de un aval, del 
otorgamiento de una garantia o responsabilidad e cualquier clase, excepto cuando dichas contraprestaciones
deban hacerse a instituciones de seguros o fianzas; la ganancia en la enajenacion de bonos, valores y otros 
titulos de credito, siempre que sean de los que se colocan entre el gran publico inversionista, conforme a las 
reglas generales que al efecto expida el SAT.

Ariculo 54. Las instituciones que componen el sistema financiero que efectuen pagos por intereses, deberan retener 
y enterar el impuesto aplicando la tasa que al efecto establezca el Congreso de la Union para el ejercicio de que 
se trate en el LIF sobre el monto de capital que de lugar al pago de los intereses, como pago provisional. la 
retencion se enterara ante las oficinas autorizadas, a mas tardar el dia 17 del mes inmediato siguiente a aquel al
que corresponda, y se debera expedir comprobante fiscal en el que conste el monto del pago de intereses, asi como 
el impuesto retenido.

Articulo 133. Se consideran ingresos por intereses para los efectos de este Capitulo, los establecidos en el 
articulo 8 de esta Ley y los demas que conforma a la misma tengan tratamiento de interes. 

Articulo 134. Las personas fisicas deberan acumular a sus demas ingresos lo intereses percibidos en el ejercicio. 
Tratandose de intereses pagados por sociedades que no se consideren integrantes del sistema financiero en los 
terminos de esta Ley y que deriven de titulos valor que no sean colocados entre el gran publico inversionista a 
traves de bolsas de valores autorizadas o mercados de amplia bursatilidad, los mismos se acumularan en el ejercicio 
en que se devenguen.

Articulo 135. Quienes paguen los intereses a que se refiere el articulo 133 de esta Ley, estan obligados a retener 
y enterar el impuesto aplicando la tasa que al efecto establezca el Congreso de la Union para el ejercicio de que 
se trate en la LIF sobre el monto del capital que de lugar al pago de los intereses, como pago provisional. Tratandose 
de los intereses senialados en el segundo parrafo del articulo 134 de la misma, la retencion se efectuara a la 
tasa del 20% sobre los intereses nominales.

Las personas fisicas que unicamente obtengan ingresos acumulables de los senialados en este Capitulo, podran optar 
por considerar la retencion que se efectue en los terminos de este articulo como pago definitivo, siempre que dichos 
ingresos correspondan al ejercicio de que se trate y no excedan de $100,000.00

LIF 2014. Art. 21. Durente el ejercicio fiscal de 2014 la tasa de retencion anual a que se refieren los articulos 54 y 
135 de la LISR sera del 0.60%. 

RMF 2015.
I.3.5.2. Las instituciones que componen el sistema financiero podran optar por efectuar la retencion a que se refiere 
el parrafo anterior, multiplicando la tasa de 0.00167% por el promedio diario de la inversion que de lugar al pago 
de los intereses, el resultado obtenido se multiplcara por el numero de dias a que corresponda a la inversion de 
que se trate.*/

* y. Intereses *
g exen_intereses = min(0,ing_intereses)

* TOTAL *
egen double exen_t4_cap6 = rsum(exen_intereses)

*******************************************************************
** 3.8 Capitulo VII. DE LOS INGRESOS POR LA OBTENCION DE PREMIOS **
/* Articulo 137. Se consideran ingresos por la obtencion de premios, los que deriven de la celebracion de loterias, 
rifas, sorteos, juegos con apuestas y concursos de toda clase, autorizados legalmente.

Cuando la persona que otorgue el premio pague por cuenta del contribuyente el impuesto que corresponde como retencion, 
el importe del impuesto pagado por cuenta del contribuyente se considerara como ingreso de los comprendidos en 
este Capitulo. No se considerara como premio el reintegro correspondiente al billete que permitio participar en las loterias.

Articulo 138. El impuesto por los premios de loterias, rifas, sorteos y concursos, organizados en territorio nacional, 
se calculara aplicando la tasa del 1% sobre el valor del premio correspondiente a cada boleto o billete entero, sin 
deduccion alguna, siempre que las Entidades Federativas no graven con un impuesto local los ingresos a que se refiere 
este parrafo, o el gravamen establecido no exceda del 6%. La tasa del impuesto a que se refiere este articulo sera del 
21%, en aquellas Entidades Federativas que apliquen un impuesto local sobre los ingresos a que se refiere este parrafo,
a una tasa que exceda del 6%. (...) 

Las personas fisicas que no efectuen la declaracion a que se refeire el segundo parrafo del articulo 90 de esta Ley, 
no podran considerar la retencion efectuada en los terminos de este articulo como pago definitivo y deberan acumular 
a sus demas ingresos el monto de los ingresos obtenidos en los terminos de este Capitulo. En este caso, la persona que 
obtenga el ingreso podra acreditar contra el impuesto que se determine en la delcaracion anual, la retencion del 
impuesto federal que le hubiera efectuado la persona que pago el premio en los terminos de este percepto. */

* z. Loterias *
noisily di _col(04) in g "{bf:SUPUESTO: " in y ///
	"Las personas f{c i'}sicas deber{c a'}n acumular los ingreso por premios a sus dem{c a'}s ingresos.}"
g exen_loter = min(0,ing_loter)

* TOTAL *
egen double exen_t4_cap7 = rsum(exen_loter)

************************************************************************************************************************
** 3.9 Capitulo VIII. DE LOS INGRESOS POR DIVIDENDOS Y EN GENERAL POR LAS GANANCIAS DISTRIBUIDAS POR PERSONAS MORALES **
/* Articulo 140. Las personas fisicas deberan acumular a sus demas ingresos, los percibidos por dividendos o 
utilidades. (...) */

* aa. Acciones *
g exen_acc = min(0,ing_acc)

* TOTAL *
egen double exen_t4_cap8 = rsum(exen_acc)

********************************************************************************
** 3.10 Capitulo IX. DE LOS DEMAS INGRESOS QUE OBTENGAN LAS PERSONAS FISICIAS **
/* Articulo 93. No se pagara el impuesto sobre la renta por la obtencion de los siguientes ingresos: (...)
XXIX. Lo que se obtenga, hasta el equivalente de veinte salarios minimos generales del area geografica del 
contribuyente elevados al anio, por permitir a terceros la publicacion de obras escritas de su creacion en libros, 
periodicos o revistas, o bien, la reproduccion en serie de grabaciones de obras musicales de su creacion (...) 
Por el excedente se pagara el impuesto en los terminos de este Titulo.

Articulo 142. Se entiende que, entre otros, son ingresos en los terminos de este Capitulo los siguientes:
XI. Los que perciban por derechos de autor, personas distintas a este. */

* ab. `Derechos' de autor *
g exen_autor = min(20*`smdf'*360,ing_autor)

* ac. Remesas *
g exen_remesas = ing_remesas

* ad. Ingreso por trabajo de menores de 12 anios *
g exen_trabmenor = ing_trabmenor

* ae. Ingreso por prestamos *
g exen_prest = ing_prest

* af. Ingreso por otras percepciones de capital *
g exen_otrocap = ing_otrocap

/* VIII. Los provenientes de cajas de ahorro de trabajadores y de fondos de ahorro establecidos por las empresas 
para sus trabajadores cuando reunan los requisitos de deducibilidad del Titulo II de esta Ley o, en su caso, del 
presente Titulo.

Articulo 93. No se pagara el impuesto sobre la renta por la obtencion de los siguientes ingresos: (...)
XXI. Las cantidades que paguen las instituciones de seguros a los asegurados o a sus beneficiarios cuando ocurra 
el riesgo amparado por las polizas contratadas y siempre que no se trate de seguros relacionados con bienes de 
activo fijo. Tratandose de seguros en los que el riesgo amparado sea la supervivencia del asegurado, no se pagara 
el impuesto sobre la renta por las cantidades que paguen las instituciones de seguros a sus asegurados o 
beneficiarios, siempre que la indemnizacion se pague cuando el asegurado llegue a la edad de sesenta anios y ademas 
hubieran transcurrido al menos cinco anios desde la fecha de contratacion del seguro y el momento en el que se pague 
la indemnizacion. Lo dispuesto en este parrafo solo sera aplicable cuando la prima sea pagada por el asegurado.

Tampoco se pagara el impuesto sobre la renta por las cantidades que paguen las instituciones de seguros a sus 
asegurados o a sus beneficiarios, que provengan de contratos de seguros de vida cuando la prima haya sido pagada 
directamente por el empleador en favor de sus trabajadores, siempre que los beneficios de dichos seguros se entreguen 
unicamente por muerte, invalidez, perdidas organicas o incapacidad del asegurado para realizar un trabajo personal 
remunerado(...) La exencion prevista en este parrafo no sera aplicable tratandose de las cantidades que paguen las 
instituciones de seguros por by de dividendos derivados de la poliza de seguros o su colectividad. */

* o. Retiros de ahorro *
g exen_ahorro = ing_ahorro

/* Articulo 93. No se pagara el impuesto sobre la renta por la obtencion de los siguientes ingresos: (...)
XXII.Los que se reciban por herencia o legado. */

* p. Herencias o Legados *
g exen_heren = ing_heren

/* Articulo 93. No se pagara el impuesto sobre la renta por la obtencion de los siguientes ingresos: (...)
VII. Las prestaciones de seguridad social que otorguen las instituciones publicas.
VIII. Los percibidos con motivo de subsidios por incapacidad, becas educacionales para los trabajadores o sus hijos,
guarderias infantiles, actividades culturales y deportivas, y otras prestaciones de prevision social, de naturaleza 
analoga, que se concedan de manera general, de acuerdo con las leyes o por contratos de trabajo.*/

* q. Prestaciones de Seguridad Social y Prevision Social *
g exen_benef = ing_benef

* TOTAL *
egen double exen_t4_cap9 = rsum(exen_autor exen_remesas exen_prest exen_otrocap ///
	exen_ahorro exen_indemn3 exen_heren exen_benef exen_trabmenor)



*********************************************
**# 4. SUMAR LOS TOTALES DE LAS VARIABLES ***
*********************************************

*****************
** 4.1 Sueldos **
g ing_sueldos = ing_t4_cap1
g exen_sueldos = exen_t4_cap1

***************
** 4.2 Mixto **
egen double ing_mixto = rsum(ing_t4_cap2pf ing_t4_cap3pf ing_t4_cap4 ing_t4_cap5 ing_t4_cap6 ing_t4_cap7 ing_t4_cap8 ing_t4_cap9)
egen double exen_mixto = rsum(exen_t4_cap2pf exen_t4_cap3pf exen_t4_cap4 exen_t4_cap5 exen_t4_cap6 exen_t4_cap7 exen_t4_cap8 exen_t4_cap9)

g ing_mixtoL = ing_mixto*2/3
g exen_mixtoL = exen_mixto*2/3

g ing_mixtoK = ing_mixto*1/3
g exen_mixtoK = exen_mixto*1/3

*****************
** 4.3 Laboral **
egen double ing_laboral = rsum(ing_sueldos ing_mixtoL)
egen double exen_laboral = rsum(exen_sueldos exen_mixtoL)

******************
** 4.4 Capital **
egen double ing_capital = rsum(ing_t2_cap1 ing_t2_cap8 ing_t4_cap2PM ing_t4_cap3PM)
egen double exen_capital = rsum(exen_t2_cap1 exen_t2_cap8 exen_t4_cap2PM exen_t4_cap3PM)

***************
** 4.5 Total **
egen double ing_total = rsum(ing_empre ///
	ing_agri ///
	ing_ss ing_desta ing_prop ing_horas ing_grati ing_prima ///
	ing_util ing_agui ing_jubila ing_trabmenor ///
	ing_honor ///
	ing_rent ///
	ing_enajecasa ing_enajem ing_enaje ///
	ing_dona ///
	ing_intereses ///
	ing_loter ///
	ing_acc ///
	ing_autor ing_remesas ing_prest ing_otrocap ing_ahorro ing_heren ing_benef ///
	ing_indemn ing_indemn2 ing_indemn3 ing_estim_alqu)
egen double exen_total = rsum(exen_empre ///
	exen_agri ///
	exen_ss exen_desta exen_prop exen_horas exen_grati exen_prima ///
	exen_util exen_agui exen_jubila exen_trabmenor ///
	exen_honor ///
	exen_rent ///
	exen_enajecasa exen_enajem exen_enaje ///
	exen_dona ///
	exen_intereses ///
	exen_loter ///
	exen_acc ///
	exen_autor exen_remesas exen_prest exen_otrocap exen_ahorro exen_heren exen_benef ///
	exen_indemn exen_indemn2 exen_indemn3)
replace ing_total = 0 if ing_total == .

*****************
** 4.6 Results **
foreach k of varlist ing_total ing_sueldos ing_mixto* ing_capital ing_estim_alqu ing_laboral {
	Gini `k', hogar(folioviv foliohog) factor(factor)
	local gini_`k' = r(gini_`k')
}
tabstat ing_sueldos ing_mixto ing_total ing_estim_alqu ing_capital [aw=factor], stat(sum) f(%25.0fc) save
tempname AnnInc
matrix `AnnInc' = r(StatTotal)

**********************
** 4.18 ENIGH As Is **
noisily di _newline(2) _col(04) in g "{bf:Paso 0: `enigh' vs. SCN}"
noisily di _newline _col(04) in g "{bf:Producto Interno Neto" ///
	_col(44) in g "(Gini)" ///
	_col(57) in g %7s "`enigh'" ///
	_col(66) %7s "SCN" in g ///
	_col(77) %7s "Diferencia" "}"
noisily di ///
	_col(04) in g "(+) Remuneración de asalariados" ///
	_col(44) in y "(" %5.3fc `gini_ing_sueldos' ")" ///
	_col(57) in y %7.3fc `AnnInc'[1,1]/`PIBSCN'*100 ///
	_col(66) in y %7.3fc `RemSal'/`PIBSCN'*100 ///
	_col(77) in y %7.1fc (`AnnInc'[1,1]/`RemSal'-1)*100 "%"
scalar RemSalSCNPIB = `RemSal'/`PIBSCN'*100
scalar RemSalHHSPIB = `AnnInc'[1,1]/`PIBSCN'*100
scalar giniRemSal = `gini_ing_sueldos'
scalar DifRemSal = (`AnnInc'[1,1]/`RemSal'-1)*100
noisily di ///
	_col(04) in g "(+) Contribuc. sociales" ///
	_col(44) in y "(" %5.3fc 0 ")" ///
	_col(57) in y %7.3fc 0 ///
	_col(66) in y %7.3fc (`SSEmpleadores'+`SSImputada')/`PIBSCN'*100 ///
	_col(77) in y %7.1fc (0/(`SSEmpleadores'+`SSImputada')-1)*100 "%"
scalar CSSSCNPIB = (`SSEmpleadores'+`SSImputada')/`PIBSCN'*100
scalar CSSHHSPIB = 0
scalar giniCSS = 0
scalar DifCSS = (0/(`SSEmpleadores'+`SSImputada')-1)*100
noisily di ///
	_col(04) in g "(+) Ingreso mixto (laboral)" ///
	_col(44) in y "(" %5.3fc `gini_ing_mixtoL' ")" ///
	_col(57) in y %7.3fc `AnnInc'[1,2]*2/3/`PIBSCN'*100 ///
	_col(66) in y %7.3fc `MixL'/`PIBSCN'*100 ///
	_col(77) in y %7.1fc (`AnnInc'[1,2]*2/3/`MixL'-1)*100 "%"
scalar MixLSCNPIB = `MixL'/`PIBSCN'*100
scalar MixLHHSPIB = `AnnInc'[1,2]*2/3/`PIBSCN'*100
scalar giniMixL = `gini_ing_mixtoL'
scalar DifMixL = (`AnnInc'[1,2]*2/3/`MixL'-1)*100
noisily di ///
	_col(04) in g "(+) Impuestos producción (laboral)" ///
	_col(44) in y "(" %5.3fc 0 ")" ///
	_col(57) in y %7.3fc 0 ///
	_col(66) in y %7.3fc `ImpNetProduccionL'/`PIBSCN'*100 ///
	_col(77) in y %7.1fc (0/`ImpNetProduccionL'-1)*100 "%"
scalar ImpNetProduccionLSCNPIB = `ImpNetProduccionL'/`PIBSCN'*100
scalar ImpNetProduccionLHHSPIB = 0
scalar giniImpNetProduccionL = 0
scalar DifImpNetProduccionL = (0/`ImpNetProduccionL'-1)*100
noisily di in g _dup(84) "-"
noisily di ///
	_col(04) in g "{bf:(=) Ingreso laboral" ///
	_col(44) in y "(" %5.3fc `gini_ing_laboral' ")" ///
	_col(57) in y %7.3fc (`AnnInc'[1,1]+`AnnInc'[1,2]*2/3)/`PIBSCN'*100 ///
	_col(66) in y %7.3fc (`RemSal'+`SSEmpleadores'+`SSImputada'+`MixL'+`ImpNetProduccionL')/`PIBSCN'*100 ///
	_col(77) in y %7.1fc ((`AnnInc'[1,1]+`AnnInc'[1,2]*2/3)/(`RemSal'+`SSEmpleadores' ///
		+`SSImputada'+`MixL'+`ImpNetProduccionL')-1)*100 "%}"
scalar IngLabSCNPIB = (`RemSal'+`SSEmpleadores'+`SSImputada'+`MixL'+`ImpNetProduccionL')/`PIBSCN'*100
scalar IngLabHHSPIB = (`AnnInc'[1,1]+`AnnInc'[1,2]*2/3)/`PIBSCN'*100
scalar giniIngLab = `gini_ing_laboral'
scalar DifIngLab = ((`AnnInc'[1,1]+`AnnInc'[1,2]*2/3)/(`RemSal'+`SSEmpleadores'+`SSImputada'+`MixL'+`ImpNetProduccionL')-1)*100
noisily di ///
	_col(04) in g "(+) Sociedades e ISFLSH" ///
	_col(44) in y "(" %5.3fc `gini_ing_capital' ")" ///
	_col(57) in y %7.3fc `AnnInc'[1,5]/`PIBSCN'*100 ///
	_col(66) in y %7.3fc `ExNOpSoc'/`PIBSCN'*100 ///
	_col(77) in y %7.1fc (`AnnInc'[1,5]/`ExNOpSoc'-1)*100 "%"
scalar SocSCNPIB = `ExNOpSoc'/`PIBSCN'*100
scalar SocHHSPIB = `AnnInc'[1,5]/`PIBSCN'*100
scalar giniSoc = `gini_ing_capital'
scalar DifSoc = (`AnnInc'[1,5]/`ExNOpSoc'-1)*100
noisily di ///
	_col(04) in g "(+) Alquiler imputado" ///
	_col(44) in y "(" %5.3fc `gini_ing_estim_alqu' ")" ///
	_col(57) in y %7.3fc `AnnInc'[1,4]/`PIBSCN'*100 ///
	_col(66) in y %7.3fc `ExNOpHog'/`PIBSCN'*100 ///
	_col(77) in y %7.1fc (`AnnInc'[1,4]/`ExNOpHog'-1)*100 "%"
scalar AlqSCNPIB = `ExNOpHog'/`PIBSCN'*100
scalar AlqHHSPIB = `AnnInc'[1,4]/`PIBSCN'*100
scalar giniAlq = `gini_ing_estim_alqu'
scalar DifAlq = (`AnnInc'[1,4]/`ExNOpHog'-1)*100
noisily di ///
	_col(04) in g "(+) Ingreso mixto (capital)" ///
	_col(44) in y "(" %5.3fc `gini_ing_mixtoK' ")" ///
	_col(57) in y %7.3fc (`AnnInc'[1,2]*1/3)/`PIBSCN'*100 ///
	_col(66) in y %7.3fc `MixKN'/`PIBSCN'*100  ///
	_col(77) in y %7.1fc ((`AnnInc'[1,2]*1/3)/`MixKN'-1)*100 "%"
scalar MixKSCNPIB = `MixKN'/`PIBSCN'*100
scalar MixKHHSPIB = (`AnnInc'[1,2]*1/3)/`PIBSCN'*100
scalar giniMixK = `gini_ing_mixtoK'
scalar DifMixK = ((`AnnInc'[1,2]*1/3)/`MixKN'-1)*100
noisily di ///
	_col(04) in g "(+) Impuestos producción (capital)" ///
	_col(44) in y "(" %5.3fc 0 ")" ///
	_col(57) in y %7.3fc 0 ///
	_col(66) in y %7.3fc `ImpNetProduccionK'/`PIBSCN'*100 ///
	_col(77) in y %7.1fc (0/`ImpNetProduccionK'-1)*100 "%"
scalar ImpNetProduccionKSCNPIB = `ImpNetProduccionK'/`PIBSCN'*100
scalar ImpNetProduccionKHHSPIB = 0
scalar giniImpNetProduccionK = 0
scalar DifImpNetProduccionK = (0/`ImpNetProduccionK'-1)*100
noisily di ///
	_col(04) in g "(+) Impuestos a los productos" ///
	_col(44) in y "(" %5.3fc 0 ")" ///
	_col(57) in y %7.3fc 0 ///
	_col(66) in y %7.3fc `ImpNetProductos'/`PIBSCN'*100 ///
	_col(77) in y %7.1fc (0/`ImpNetProductos'-1)*100 "%"
scalar ImpNetProductosSCNPIB = `ImpNetProductos'/`PIBSCN'*100
scalar ImpNetProductosHHSPIB = 0
scalar giniImpNetProductos = 0
scalar DifImpNetProductos = (0/`ImpNetProductos'-1)*100
noisily di in g _dup(84) "-"
noisily di ///
	_col(04) in g "{bf:(=) Producto Interno Neto" ///
	_col(44) in y "(" %5.3fc `gini_ing_total' ")" ///
	_col(57) in y %7.3fc `AnnInc'[1,3]/`PIBSCN'*100 ///
	_col(66) in y %7.3fc (`RemSal'+`SSEmpleadores'+`SSImputada'+`MixL'+`ImpNetProduccionL' ///
		+`ExNOpSoc'+`ExNOpHog'+`MixKN'+`ImpNetProduccionK'+`ImpNetProductos')/`PIBSCN'*100 ///
	_col(77) in y %7.1fc (`AnnInc'[1,3]/(`RemSal'+`SSEmpleadores'+`SSImputada'+`MixL'+`ImpNetProduccionL' ///
		+`ExNOpSoc'+`ExNOpHog'+`MixKN'+`ImpNetProduccionK'+`ImpNetProductos')-1)*100 "%}"
scalar PINSCNPIB = (`RemSal'+`SSEmpleadores'+`SSImputada'+`MixL'+`ImpNetProduccionL'+`ExNOpSoc'+`ExNOpHog' ///
	+`MixKN'+`ImpNetProduccionK'+`ImpNetProductos')/`PIBSCN'*100
scalar PINHHSPIB = `AnnInc'[1,3]/`PIBSCN'*100
scalar giniPIN = `gini_ing_total'
scalar DifPIN = (`AnnInc'[1,3]/(`RemSal'+`SSEmpleadores'+`SSImputada'+`MixL'+`ImpNetProduccionL'+`ExNOpSoc'+`ExNOpHog'+`MixKN'+`ImpNetProduccionK'+`ImpNetProductos')-1)*100
scalar DifPIBSCN = (`AnnInc'[1,3]/(`PIBSCN')-1)*100


************************************
**# 5. IDENTIFICAR LA FORMALIDAD ***
************************************
merge m:1 (folioviv foliohog numren id_trabajo) using "`dir_enigh'/trabajos.dta", ///
	nogen keepusing(htrab pres_* pago scian sinco subor)
replace scian = substr(scian,1,2)
replace sinco = substr(sinco,1,2)
destring scian sinco subor pres_*, replace

collapse (sum) ing_* exen_* htrab (max) factor* pres_* scian sinco jubilado (min) subor, by(folioviv foliohog numren)

merge m:1 (folioviv foliohog numren) using "`dir_enigh'/poblacion.dta", ///
	nogen keepusing(sexo edad trabajo_mp inscr_* inst_* atemed `segpop' hablaind)
destring hablaind, replace

merge m:1 (folioviv foliohog) using "`dir_enigh'/concentrado.dta", ///
	nogen update replace keepusing(tot_integ ubica_geo factor)

merge m:1 (folioviv) using "`dir_enigh'/vivienda.dta", ///
	nogen keepusing(tenencia renta)
tostring inst_* inscr_* pres_*, replace

merge m:1 (folioviv foliohog numren) using "`c(sysdir_site)'/SIM/`enighanio'/deducciones.dta", ///
	nogen keepus(deduc_*)

replace deduc_STrans_escolar = deduc_STrans_escolar
replace deduc_honor_medicos = deduc_honor_medicos
replace deduc_segur_medicos = deduc_segur_medicos
replace deduc_gasto_funerar = min(deduc_gasto_funerar,`smdf'*360)
replace deduc_gasto_donativ = deduc_gasto_donativ
replace deduc_gasto_colegi1 = min(deduc_gasto_colegi1,14200)
replace deduc_gasto_colegi2 = min(deduc_gasto_colegi2,12900)
replace deduc_gasto_colegi3 = min(deduc_gasto_colegi3,19900)
replace deduc_gasto_colegi4 = min(deduc_gasto_colegi4,17100)
replace deduc_gasto_colegi5 = min(deduc_gasto_colegi5,24500)
egen deduc_isr = rsum(deduc_*)

capture replace factor = factor_hog
tempvar tag tag2
duplicates tag folioviv foliohog numren, g(`tag')
bysort folioviv foliohog numren: g `tag2' = sum(`tag')
replace deduc_isr = 0 if numren != "01" | `tag2' > 1 | deduc_isr == .

* Tipo de contribuyente *
g tipo_contribuyente = 1 if (ing_t4_cap1 != 0 & ing_t4_cap1 != .)
replace tipo_contribuyente = 2 if ((ing_t4_cap2 != 0 & ing_t4_cap2 != .) ///
	| (ing_t4_cap3 != 0 & ing_t4_cap3 != .) ///
	| (ing_t4_cap5 != 0 & ing_t4_cap5 != .) ///
	| (ing_t4_cap6 != 0 & ing_t4_cap6 != .) ///
	| (ing_t4_cap7 != 0 & ing_t4_cap7 != .) ///
	| (ing_t4_cap8 != 0 & ing_t4_cap8 != .) ///
	| (ing_t2_cap8 != 0 & ing_t2_cap8 != .) ///
	| (ing_autor != 0 & ing_autor != .)) ///
	& tipo_contribuyente == .
label define tipo_contribuyente 1 "Asalariado" 2 "Persona fisica"
label values tipo_contribuyente tipo_contribuyente

noisily di _newline(2) _col(04) in g "{bf:SUPUESTO: " in y ///
	"Los derechohabientes del IMSS, ISSSTE, ISSSTE Estatal, Pemex, ISSFAM o con prestaciones laborales son el sector formal.}"

* IMSS *
g byte formal = inst_1 == "1"
g byte formal2 = inst_1 == "1" & (inscr_1 == "1" | inscr_2 == "2" | inscr_6 == "6")

* ISSSTE *
replace formal = 2 if inst_2 == "2"
replace formal2 = 2 if inst_2 == "2" & (inscr_1 == "1" | inscr_2 == "2" | inscr_6 == "6")

* ISSSTE Estatal *
replace formal = 5 if inst_3 == "3"
replace formal2 = 5 if inst_3 == "3" //& (inscr_1 == "1" | inscr_2 == "2" | inscr_6 == "6")

* Pemex *
replace formal = 3 if inst_4 == "4"
replace formal2 = 3 if inst_4 == "4" //& (inscr_1 == "1" | inscr_2 == "2" | inscr_6 == "6")

* Institucion medica otro *
replace formal = 4 if inst_5 == "5"
replace formal2 = 4 if inst_5 == "5" //& (inscr_1 == "1" | inscr_2 == "2" | inscr_6 == "6")

* Independiente *
replace formal = 6 if formal == 0 & (pres_1 == "01" | pres_2 == "02" | pres_3 == "03" | pres_4 == "04" ///
	| pres_5 == "05" | pres_6 == "06" | pres_7 == "07" | pres_8 == "08" | pres_9 == "09" | pres_10 == "10" ///
	| pres_11 == "11" | pres_12 == "12" | pres_13 == "13" | pres_14 == "14" | pres_15 == "15" | pres_16 == "16" ///
	| pres_17 == "17" | pres_18 == "18" | pres_19 == "19")
replace formal2 = 6 if formal2 == 0 & (pres_1 == "01" | pres_2 == "02" | pres_3 == "03" | pres_4 == "04" ///
	| pres_5 == "05" | pres_6 == "06" | pres_7 == "07" | pres_8 == "08" | pres_9 == "09" | pres_10 == "10" ///
	| pres_11 == "11" | pres_12 == "12" | pres_13 == "13" | pres_14 == "14" | pres_15 == "15" | pres_16 == "16" ///
	| pres_17 == "17" | pres_18 == "18" | pres_19 == "19") //& (inscr_1 == "1")

* Formal max *
noisily di _col(04) in g "{bf:SUPUESTO: " in y ///
	"Si se paga impuestos en el trabajo principal, tambi{c e'}n se paga en el trabajo secundario.}"
tempvar formal_max
egen `formal_max' = max(formal), by(folioviv foliohog numren)
replace formal = `formal_max'

* Formal dummy *
g formal_dummy = formal != 0

* Labels *
label define formalidad 1 "IMSS" 2 "ISSSTE" 3 "Pemex" 4 "Otra institución" 5 "ISSSTE estatal" 6 "Independiente" 0 "Sin acceso"
label values formal formalidad
label values formal2 formalidad

label define formalidad_dummy 1 "Formal" 0 "Informal"
label values formal_dummy formalidad_dummy

* Segun el SAT, habia 41,255,409 de asalariados en Agosto de 2018 *
di _newline(2) _col(04) in g "{bf:Paso 0: Información inicial}"
di _newline _col(04) in g "{bf:0.1. Trabajos asalariados formales}"
table formal2 [fw=factor] if formal2 != 0, nformat(%12.0fc)

di _newline _col(04) in g "{bf:0.2. Personas formales asalariados + personas físicas}"
table formal [fw=factor] if formal != 0, nformat(%12.0fc)



********************************************************************************
***                                                                          ***
**# 6. RECUPERAR LOS INGRESOS BRUTOS DE LOS INGRESOS POR TRABAJO SUBORDINADO ***
***                                                                          ***
********************************************************************************
* Informe al Ejecutivo Federal y al Congreso de la Unión la situación financiera y los riesgos del IMSS 2021-2022 *
* Anexo A, Cuadro A.4 *
matrix CSS_IMSS = ///
///		PATRONES	TRABAJADORES	GOBIERNO FEDERAL
		(5.42,		0.44,			3.21	\   /// Enfermedad y maternidad, asegurados 
		1.05,		0.37,			0.08	\   /// Enfermedad y maternidad, pensionados 
		1.75,		0.63,			0.13	\   /// Invalidez y vida
		1.83,		0.00,			0.00	\   /// Riesgos de trabajo 
		1.00,		0.00,			0.00	\   /// Guarderias y prestaciones sociales 
		5.15,		1.12,			1.49	\   /// Retiro, cesantia en edad avanzada y vejez
		0.00,		0.00,			6.55)	    //  Cuota social -- hasta 25 UMA --

* Informe Financiero Actuarial ISSSTE 2021 *
matrix CSS_ISSSTE = ///
///		PATRONES	TRABAJADORES	GOBIERNO FEDERAL
		(7.375,		2.750,			391.0	\   /// Seguro de salud, trabajadores en activo y familiares
		0.720,		0.625,			0.000	\   /// Seguro de salud, pensionados y familiares
		0.750,		0.000,			0.000	\   /// Riesgo de trabajo
		0.625,		0.625,			0.000	\   /// Invalidez y vida
		0.500,		0.500,			0.000	\   /// Servicios sociales y culturales
		6.125,		2+3.175,		5.500	\   /// Retiro, cesantia en edad avanzada y vejez
		0.000,		5.000,			0.000	\   /// Vivienda
		0.000,		0.000,			13.9)		//  Cuota social

* INFONAVIT *
local Tinfonavit = 5		// Infonavit
local Tfovissste = 5		// FOVISSSTE

***********************************
** 6.1 CUOTAS A LA SSEmpleadores **
* Salario Base de Cotizacion: IMSS *
g sbc = ing_ss/360/`smdf' if (formal2 == 1 | formal2 == 3 | formal2 == 4 | formal2 == 6) & ing_ss > 0 & ing_ss != .
replace sbc = 25 if sbc > 25 & (formal2 == 1 | formal2 == 3 | formal2 == 4 | formal2 == 6) & ing_ss > 0 & ing_ss != .
replace sbc = round(sbc) if (formal2 == 1 | formal2 == 3 | formal2 == 4 | formal2 == 6) & ing_ss > 0 & ing_ss != .

* Sueldo Basico: ISSSTE *
replace sbc = ing_ss/360/`smdf' if (formal2 == 2 | formal2 == 5) & ing_ss > 0 & ing_ss != .
replace sbc = 10 if sbc > 10 & (formal2 == 2 | formal2 == 5) & ing_ss > 0 & ing_ss != .
replace sbc = ceil(sbc) if (formal2 == 2 | formal2 == 5) & ing_ss > 0 & ing_ss != .

* Ajustes *
*replace sbc = 1 if sbc > 0 & sbc < 1 & (formal2 == 1)
replace sbc = sbc*`smdf'
replace sbc = 0 if formal2 == 0 | sbc == .

* IMSS *
g gmasgP = sbc*CSS_IMSS[1,1]/100*360 if (formal2 == 1 | formal2 == 3 | formal2 == 4 | formal2 == 6)
g gmasgT = sbc*CSS_IMSS[1,2]/100*360 if (formal2 == 1 | formal2 == 3 | formal2 == 4 | formal2 == 6)
g gmasgF = sbc*CSS_IMSS[1,3]/100*360 if (formal2 == 1 | formal2 == 3 | formal2 == 4 | formal2 == 6)

g gmpenP = sbc*CSS_IMSS[2,1]/100*360 if (formal2 == 1 | formal2 == 3 | formal2 == 4 | formal2 == 6)
g gmpenT = sbc*CSS_IMSS[2,2]/100*360 if (formal2 == 1 | formal2 == 3 | formal2 == 4 | formal2 == 6)
g gmpenF = sbc*CSS_IMSS[2,3]/100*360 if (formal2 == 1 | formal2 == 3 | formal2 == 4 | formal2 == 6)

g invyvidaP = sbc*CSS_IMSS[3,1]/100*360 if (formal2 == 1 | formal2 == 3 | formal2 == 4 | formal2 == 6)
g invyvidaT = sbc*CSS_IMSS[3,2]/100*360 if (formal2 == 1 | formal2 == 3 | formal2 == 4 | formal2 == 6)
g invyvidaF = sbc*CSS_IMSS[3,3]/100*360 if (formal2 == 1 | formal2 == 3 | formal2 == 4 | formal2 == 6)

g riesgoP = sbc*CSS_IMSS[4,1]/100*360 if (formal2 == 1 | formal2 == 3 | formal2 == 4 | formal2 == 6)
g riesgoT = sbc*CSS_IMSS[4,2]/100*360 if (formal2 == 1 | formal2 == 3 | formal2 == 4 | formal2 == 6)
g riesgoF = sbc*CSS_IMSS[4,3]/100*360 if (formal2 == 1 | formal2 == 3 | formal2 == 4 | formal2 == 6)

g guardP = sbc*CSS_IMSS[5,1]/100*360 if (formal2 == 1 | formal2 == 3 | formal2 == 4 | formal2 == 6)
g guardT = sbc*CSS_IMSS[5,2]/100*360 if (formal2 == 1 | formal2 == 3 | formal2 == 4 | formal2 == 6)
g guardF = sbc*CSS_IMSS[5,3]/100*360 if (formal2 == 1 | formal2 == 3 | formal2 == 4 | formal2 == 6)

g cestyvejP = sbc*CSS_IMSS[6,1]/100*360 if (formal2 == 1 | formal2 == 3 | formal2 == 4 | formal2 == 6)
g cestyvejT = sbc*CSS_IMSS[6,2]/100*360 if (formal2 == 1 | formal2 == 3 | formal2 == 4 | formal2 == 6)
g cestyvejF = sbc*CSS_IMSS[6,3]/100*360 if (formal2 == 1 | formal2 == 3 | formal2 == 4 | formal2 == 6)

g cuotasocimssP = CSS_IMSS[7,1]/100*360 if (formal2 == 1 | formal2 == 3 | formal2 == 4 | formal2 == 6) & sbc/`smdf' <= 15
replace cuotasocimssP = 15*CSS_IMSS[7,1]/100*360 if (formal2 == 1 | formal2 == 3 | formal2 == 4 | formal2 == 6) & sbc/`smdf' > 15
g cuotasocimssT = CSS_IMSS[7,2]/100*360 if (formal2 == 1 | formal2 == 3 | formal2 == 4 | formal2 == 6) & sbc/`smdf' <= 15
replace cuotasocimssT = 15*CSS_IMSS[7,2]/100*360 if (formal2 == 1 | formal2 == 3 | formal2 == 4 | formal2 == 6) & sbc/`smdf' > 15
g cuotasocimssF = sbc/`smdf'*CSS_IMSS[7,3]*52 if (formal2 == 1 | formal2 == 3 | formal2 == 4 | formal2 == 6) & sbc/`smdf' <= 15
replace cuotasocimssF = 15*CSS_IMSS[7,3]*52 if (formal2 == 1 | formal2 == 3 | formal2 == 4 | formal2 == 6) & sbc/`smdf' > 15

* INFONAVIT *
g infonavit = sbc*`Tinfonavit'/100*360 if (formal2 == 1 | formal2 == 3 | formal2 == 4 | formal2 == 6)
replace infonavit = 0 if infonavit == .

* ISSSTE *
g fondomedP = sbc*CSS_ISSSTE[1,1]/100*360 if (formal2 == 2 | formal2 == 5)
g fondomedT = sbc*CSS_ISSSTE[1,2]/100*360 if (formal2 == 2 | formal2 == 5)
g fondomedF = CSS_ISSSTE[1,3]*52 if (formal2 == 2 | formal2 == 5)

g pensjubP = sbc*CSS_ISSSTE[2,1]/100*360 if (formal2 == 2 | formal2 == 5)
g pensjubT = sbc*CSS_ISSSTE[2,2]/100*360 if (formal2 == 2 | formal2 == 5)
g pensjubF = sbc*CSS_ISSSTE[2,3]/100*360 if (formal2 == 2 | formal2 == 5)

g segriesgP = sbc*CSS_ISSSTE[3,1]/100 if (formal2 == 2 | formal2 == 5)
g segriesgT = sbc*CSS_ISSSTE[3,2]/100 if (formal2 == 2 | formal2 == 5)
g segriesgF = sbc*CSS_ISSSTE[3,3]/100 if (formal2 == 2 | formal2 == 5)

g presperP = sbc*CSS_ISSSTE[4,1]/100*360 if (formal2 == 2 | formal2 == 5)
g presperT = sbc*CSS_ISSSTE[4,2]/100*360 if (formal2 == 2 | formal2 == 5)
g presperF = sbc*CSS_ISSSTE[4,3]/100*360 if (formal2 == 2 | formal2 == 5)

g servsocculP = sbc*CSS_ISSSTE[5,1]/100*360 if (formal2 == 2 | formal2 == 5)
g servsocculT = sbc*CSS_ISSSTE[5,2]/100*360 if (formal2 == 2 | formal2 == 5)
g servsocculF = sbc*CSS_ISSSTE[5,3]/100*360 if (formal2 == 2 | formal2 == 5)

g admingenP = sbc*CSS_ISSSTE[6,1]/100*360 if (formal2 == 2 | formal2 == 5)
g admingenT = sbc*CSS_ISSSTE[6,2]/100*360 if (formal2 == 2 | formal2 == 5)
g admingenF = sbc*CSS_ISSSTE[6,3]/100*360 if (formal2 == 2 | formal2 == 5)

g fvivP = sbc*CSS_ISSSTE[7,1]/100*360 if (formal2 == 2 | formal2 == 5)
g fvivT = sbc*CSS_ISSSTE[7,2]/100*360 if (formal2 == 2 | formal2 == 5)
g fvivF = sbc*CSS_ISSSTE[7,3]/100*360 if (formal2 == 2 | formal2 == 5)

g cuotasocisssteP = CSS_ISSSTE[8,1]/100*360 if (formal2 == 2 | formal2 == 5)
g cuotasocisssteT = CSS_ISSSTE[8,2]/100*360 if (formal2 == 2 | formal2 == 5)
g cuotasocisssteF = CSS_ISSSTE[8,3]*52 if (formal2 == 2 | formal2 == 5)

* FOVISSSTE *
g fovissste = sbc*`Tfovissste'/100*360 if (formal2 == 2 | formal2 == 5)
replace fovissste = 0 if fovissste == .

* TOTALES *
egen double cuotasT = rsum(*T)
label var cuotasT "Seguridad social (trabajadores)"

egen double cuotasP = rsum(*P)
label var cuotasP "Seguridad social (patrón)"

egen double cuotasF = rsum(*F)
label var cuotasF "Seguridad social (federación)"

egen double cuotasTP = rsum(cuotasP cuotasT)
label var cuotasTP "Seguridad social (trabajadores y patrón)"

egen double cuotasTPF = rsum(cuotasP cuotasT cuotasF)
label var cuotasTPF "Contribuciones a la seguridad social"

* Cuotas a la seguridad social por institucion *
g cuotasIMSS = cuotasTP if formal2 == 1
g cuotasISSSTE = cuotasTP if formal2 == 2
g cuotasFED = cuotasF if formal2 == 1

g cuotasOTR = cuotasTPF if formal2 == 4 | formal2 == 2
replace cuotasOTR = cuotasOTR - cuotasTP if formal2 == 2

g cuotasIMP = cuotasTPF if formal2 == 3 | formal2 == 6 | formal2 == 5

* IMSS *
tabstat cuotasIMSS [aw=factor], stat(sum) f(%20.0fc) save
tempname SBCIMSS SBCISSSTE
matrix `SBCIMSS' = r(StatTotal)

* ISSSTE *
tabstat cuotasISSSTE [aw=factor], stat(sum) f(%20.0fc) save
matrix `SBCISSSTE' = r(StatTotal)

* Federación IMSS *
tabstat cuotasFED [aw=factor], stat(sum) f(%20.0fc) save
tempname SBCFED
matrix `SBCFED' = r(StatTotal)

* Imputado *
tabstat cuotasIMP [aw=factor], stat(sum) f(%20.0fc) save
tempname SBCIMP
matrix `SBCIMP' = r(StatTotal)

* Otros *
tabstat cuotasOTR [aw=factor], stat(sum) f(%20.0fc) save
tempname SBCOTR
matrix `SBCOTR' = r(StatTotal)

* Total *
tabstat cuotasTPF [aw=factor], stat(sum) f(%20.0fc) save
tempname SBCTOTAL
matrix `SBCTOTAL' = r(StatTotal)

* Infonavit y fovissste *
tabstat infonavit fovissste [aw=factor], stat(sum) f(%20.0fc) save
tempname SBCINF
matrix `SBCINF' = r(StatTotal)

* Gini's de seguridad social *
Gini cuotasIMSS, hogar(folioviv foliohog) factor(factor)
local gini_cuotasIMSS = r(gini_cuotasIMSS)
Gini cuotasISSSTE, hogar(folioviv foliohog) factor(factor)
local gini_cuotasISSSTE = r(gini_cuotasISSSTE)
Gini cuotasFED, hogar(folioviv foliohog) factor(factor)
local gini_cuotasFED = r(gini_cuotasFED)
Gini cuotasIMP, hogar(folioviv foliohog) factor(factor)
local gini_cuotasIMP = r(gini_cuotasIMP)
Gini cuotasOTR, hogar(folioviv foliohog) factor(factor)
local gini_cuotasOTR = r(gini_cuotasOTR)
Gini cuotasTPF, hogar(folioviv foliohog) factor(factor)
local gini_cuotasTPF = r(gini_cuotasTPF)

// Step 1 //
noisily di _newline(2) _col(04) in g "{bf:Paso 1: Estimar las contribuciones de seguridad social}"
// Define scalars first
scalar IMSSCSSSCNPIB = `CuotasIMSS'/`PIBSCN'*100
scalar IMSSCSSHHSPIB = `SBCIMSS'[1,1]/`PIBSCN'*100
scalar giniIMSSCSS = string(`gini_cuotasIMSS',"%5.3f")
scalar DifIMSSCSS = (`SBCIMSS'[1,1]/`CuotasIMSS'-1)*100

scalar ISSSTECSSSCNPIB = `Cuotas_ISSSTE'/`PIBSCN'*100
scalar ISSSTECSSHHSPIB = (`SBCISSSTE'[1,1])/`PIBSCN'*100
scalar giniISSSTECSS = string(`gini_cuotasISSSTE',"%5.3f")
scalar DifISSSTECSS = ((`SBCISSSTE'[1,1])/`Cuotas_ISSSTE'-1)*100

scalar FEDCSSSCNPIB = `SSFederacion'/`PIBSCN'*100
scalar FEDCSSHHSPIB = (`SBCFED'[1,1])/`PIBSCN'*100
scalar giniFEDCSS = string(`gini_cuotasFED',"%5.3f")
scalar DifFEDCSS = ((`SBCFED'[1,1])/`SSFederacion'-1)*100

scalar OTROCSSSCNPIB = ((`SSEmpleadores'+`SSImputada')-`SSFederacion'-`SSImputada'-`Cuotas_ISSSTE'-`CuotasIMSS')/`PIBSCN'*100
scalar OTROCSSHHSPIB = (`SBCOTR'[1,1]+`SBCINF'[1,1]+`SBCINF'[1,2])/`PIBSCN'*100
scalar giniOTROCSS = string(`gini_cuotasOTR',"%5.3f")
scalar DifOTROCSS = ((`SBCOTR'[1,1]+`SBCINF'[1,1]+`SBCINF'[1,2])/((`SSEmpleadores'+`SSImputada')-`SSFederacion'-`SSImputada'-`Cuotas_ISSSTE'-`CuotasIMSS')-1)*100

scalar IMPCSSSCNPIB = `SSImputada'/`PIBSCN'*100
scalar IMPCSSHHSPIB = (`SBCIMP'[1,1])/`PIBSCN'*100
scalar giniIMPCSS = string(`gini_cuotasIMP',"%5.3f")
scalar DifIMPCSS = ((`SBCIMP'[1,1])/`SSImputada'-1)*100

scalar CSSESCNPIB = (`SSEmpleadores'+`SSImputada')/`PIBSCN'*100
scalar CSSEHHSPIB = (`SBCTOTAL'[1,1]+`SBCINF'[1,1]+`SBCINF'[1,2])/`PIBSCN'*100
scalar DifCSSE = ((`SBCTOTAL'[1,1]+`SBCINF'[1,1]+`SBCINF'[1,2])/(`SSEmpleadores'+`SSImputada')-1)*100
scalar giniCSSE = string(`gini_cuotasTPF',"%5.3f")

// Display using defined scalars
noisily di _newline _col(04) in g "{bf:1.1. Seguridad Social" ///
	_col(44) in g "(Gini)" ///
	_col(57) in g %7s "`enigh'" ///
	_col(66) %7s "Macro" in g ///
	_col(77) %7s "Diferencia" "}"
noisily di _col(04) in g "(+) IMSS " ///
	_col(44) in y "(" %5.3fc giniIMSSCSS ")" ///
	_col(57) in y %7.3fc IMSSCSSHHSPIB ///
	 _col(66) in y %7.3fc IMSSCSSSCNPIB ///
	 _col(77) in y %7.1fc DifIMSSCSS "%"
noisily di _col(04) in g "(+) ISSSTE " ///
	_col(44) in y "(" %5.3fc giniISSSTECSS ")" ///
	_col(57) in y %7.3fc ISSSTECSSHHSPIB ///
	_col(66) in y %7.3fc ISSSTECSSSCNPIB ///
	_col(77) in y %7.1fc DifISSSTECSS "%"
noisily di _col(04) in g "(+) Federación " ///
	_col(44) in y "(" %5.3fc giniFEDCSS ")" ///
	_col(57) in y %7.3fc FEDCSSHHSPIB ///
	_col(66) in y %7.3fc FEDCSSSCNPIB ///
	_col(77) in y %7.1fc DifFEDCSS "%"
noisily di _col(04) in g "(+) Otros " ///
	_col(44) in y "(" %5.3fc giniOTROCSS ")" ///
	_col(57) in y %7.3fc OTROCSSHHSPIB ///
	_col(66) in y %7.3fc OTROCSSSCNPIB ///
	_col(77) in y %7.1fc DifOTROCSS "%"
noisily di _col(04) in g "(+) Imputada " ///
	_col(44) in y "(" %5.3fc giniIMPCSS ")" ///
	_col(57) in y %7.3fc IMPCSSHHSPIB ///
	_col(66) in y %7.3fc IMPCSSSCNPIB ///
	_col(77) in y %7.1fc DifIMPCSS "%"
noisily di in g _dup(84) "-"
noisily di _col(04) in g "{bf:(=) Cuotas a la Seguridad Social" ///
	_col(44) in y "(" %5.3fc giniCSSE ")" ///
	_col(57) in y %7.3fc CSSEHHSPIB ///
	_col(66) in y %7.3fc CSSESCNPIB ///
	_col(77) in y %7.1fc DifCSSE "%" "}"


********************************************/
** 6.2 Ingresos brutos trabajo subordinado **
* Calculo de ISR retenciones por salarios *
g ing_subor = .
g categ = ""
g SE = 0
forvalues j=`=rowsof(ISR)'(-1)1 {
	forvalues k=`=rowsof(SE)'(-1)1 {
		*replace ing_subor = (ing_t4_cap1 + ISR[`j',3] - SE[`k',3]*htrab/40 + (cuotasTPF + infonavit + fovissste) ///
			- ISR[`j',4]/100*(ISR[`j',1] + exen_t4_cap1 + (cuotasTP + infonavit + fovissste))) / (1 - ISR[`j',4]/100) ///
			if (ing_t4_cap1 != 0 & ing_t4_cap1 != .) & htrab < 40 & categ == ""
			
		replace ing_subor = (ing_t4_cap1 + ISR[`j',3] - SE[`k',3] + (cuotasTPF + infonavit + fovissste) ///
			- ISR[`j',4]/100*(ISR[`j',1] + exen_t4_cap1 + (cuotasTP + infonavit + fovissste))) / (1 - ISR[`j',4]/100) ///
			if (ing_t4_cap1 != 0 & ing_t4_cap1 != .) /*& htrab >= 40*/ & categ == ""

		replace categ = "i`j's`k'" ///
			if ing_subor - exen_t4_cap1 - (cuotasTP + infonavit + fovissste) >= ISR[`j',1] ///
			& ing_subor - exen_t4_cap1 - (cuotasTP + infonavit + fovissste) <= ISR[`j',2] ///
			& ing_subor - exen_t4_cap1 - (cuotasTP + infonavit + fovissste) >= SE[`k',1] ///
			& ing_subor - exen_t4_cap1 - (cuotasTP + infonavit + fovissste) <= SE[`k',2] ///
			& categ == ""

		*replace SE = SE[`k',3]*htrab/48 if categ == "i`j's`k'" & htrab < 40 & formal != 0
		replace SE = SE[`k',3] if categ == "i`j's`k'" /*& htrab >= 40*/ & formal != 0
	}
}

* Ingreso bruto informales *
replace ing_subor = ing_t4_cap1 if formal == 0

**********************
** 6.3 ISR salarios **
g isrE = ing_subor - ing_t4_cap1 - (cuotasTP + infonavit + fovissste) if formal != 0
replace isrE = 0 if isrE == .
label var isrE "ISR retenciones a asalariados"

tabstat ing_subor [aw=factor], stats(sum) f(%25.0fc) by(formal) save
tempname GROSS
matrix `GROSS' = r(StatTotal)

tabstat isrE SE [aw=factor] if formal != 0, stats(sum) f(%25.0fc) by(formal) save
tempname GROSSISR
matrix `GROSSISR' = r(StatTotal)

* Gini's de ingresos brutos *
Gini ing_subor, hogar(folioviv foliohog) factor(factor)
local gini_ing_subor = r(gini_ing_subor)
Gini isrE, hogar(folioviv foliohog) factor(factor)
local gini_isrE = r(gini_isrE)
Gini SE, hogar(folioviv foliohog) factor(factor)
local gini_SE = r(gini_SE)

*****************
** 6.4 Results **
noisily di _newline(2) _col(04) in g "{bf:Paso 2: Recuperar el ingreso bruto y estimar el ISR retenido por salarios}"
noisily di in g _newline _col(04) in g "{bf:2.1. Ingresos bruto salarial" ///
	_col(44) in g "(Gini)" ///
	_col(57) in g %7s "`enigh'" ///
	_col(66) %7s "Macro" in g ///
	_col(77) %7s "Diferencia" "}"
noisily di ///
	_col(04) in g "Remuneración a asalariados + CSS" ///
	_col(44) in y "(" %5.3fc `gini_ing_subor' ")" ///
	_col(57) in y %7.3fc `GROSS'[1,1]/`PIBSCN'*100 ///
	_col(66) in y %7.3fc (`RemSal'+`SSEmpleadores'+`SSImputada')/`PIBSCN'*100 ///
	_col(77) in y %7.1fc (`GROSS'[1,1]/(`RemSal'+`SSEmpleadores'+`SSImputada')-1)*100 "%"
scalar YBSCNPIB = (`RemSal'+`SSEmpleadores'+`SSImputada')/`PIBSCN'*100
scalar YBHHSPIB = `GROSS'[1,1]/`PIBSCN'*100
scalar giniYB = string(`gini_ing_subor',"%5.3f")
scalar DifYB = (`GROSS'[1,1]/(`RemSal'+`SSEmpleadores'+`SSImputada')-1)*100
noisily di ///
	_col(04) in g "ISR retenciones a asalariados" ///
	_col(44) in y "(" %5.3fc `gini_isrE' ")" ///
	_col(57) in y %7.3fc `GROSSISR'[1,1]/`PIBSCN'*100 ///
	_col(66) in y %7.3fc `ISRSalarios'/`PIBSCN'*100 ///
	_col(77) in y %7.1fc (`GROSSISR'[1,1]/`ISRSalarios'-1)*100 "%"
scalar ISRASSCNPIB = `ISRSalarios'/`PIBSCN'*100
scalar ISRASHHSPIB = `GROSSISR'[1,1]/`PIBSCN'*100
scalar giniISRAS = string(`gini_isrE',"%5.3f")
scalar DifISRAS = (`GROSSISR'[1,1]/`ISRSalarios'-1)*100
noisily di ///
	_col(04) in g "Subsidio al empleo" ///
	_col(44) in y "(" %5.3fc `gini_SE' ")" ///
	_col(57) in y %7.3fc `GROSSISR'[1,2]/`PIBSCN'*100  ///
	_col(66) in y %7.3fc `SubsidioEmpleo'/`PIBSCN'*100 ///
	_col(77) in y %7.1fc (`GROSSISR'[1,2]/`SubsidioEmpleo'-1)*100 "%"
scalar SESCNPIB = `SubsidioEmpleo'/`PIBSCN'*100
scalar SEHHSPIB = `GROSSISR'[1,2]/`PIBSCN'*100
scalar giniSE = string(`gini_SE',"%5.3f")
scalar DifSE = (`GROSSISR'[1,2]/`SubsidioEmpleo'-1)*100



**********************/
**# 7. COLA DERECHA ***
***********************
if `betamin' > 1 {
	preserve
	*egen double ing_cola = rsum(ing_subor ing_mixto ing_capital)
	egen double ing_cola = rsum(ing_subor)
	local ingreso "ing_cola"
	*local sort "folioviv foliohog numren"
	local sort "folioviv foliohog"
	collapse (sum) `ingreso' ing_capital (mean) factor, by(`sort')
	gsort -`ingreso' `sort' -ing_capital

	g n = sum(factor)
	g lnxi = ln(`ingreso')
	g lnxi2 = ln(`ingreso')*factor
	g lnxm = lnxi*n
	g slnxi = sum(lnxi2)

	g alfa = n/(slnxi - lnxm)
	g beta = alfa / (alfa - 1)

	sort `ingreso' `sort' ing_capital

	local N = _N
	tabstat `ingreso' if beta <= `betamin' & beta > 0, stats(min) save

	tempname R
	matrix `R' = r(StatTotal)
	count if `ingreso' >= `R'[1,1]
	local count = `N' - r(N) + 1
	display `count'

	egen factorn = sum(factor) if `ingreso' >= `R'[1,1]

	g n2 = sum(factor) if `ingreso' >= `R'[1,1]
	g cdfe = n2/factorn * 100

	* Metodo 2 *
	local N1 = _N + 1
	set obs `N1'

	g media = .
	forvalues l = `N1'(-1)`count' {
		local minn = `l' - 1
		summ `ingreso' in `minn'/`l', meanonly
		tempname A
		matrix `A' = r(mean)
		replace media = `A'[1,1] in `minn'
	}

	g cdft = (1-(`R'[1,1]/media)^(`betamin'/(`betamin'-1)))*100 if `ingreso' >= `R'[1,1]
	g pdft = 0 if `ingreso' >= `R'[1,1]

	g cola = 0
	forvalues l = `N1'(-1)`count' {
		local minn = `l' - 1
		local min = cdft in `minn'
		local max = cdft in `l'
		local pdf = `max' - `min'
		replace pdft = `pdf' in `l'
		replace cola = 1 in `l'
	}

	replace pdft = cdft in `count'
	
	local cdfmax = cdft in `N'
	replace pdft = 100 - `cdfmax' in `N1'

	local s`ingreso' = `ingreso' in `N'
	replace `ingreso' = `s`ingreso''*`betamin' in `N1'

	local sfactorn = factorn in `N'
	replace factorn = `sfactorn' in `N1'
	replace cola = 1 in `N1'

	g factor_cola = pdft*factorn/100 if `ingreso' >= `R'[1,1]
	replace factor_cola  = factor if factor_cola  == .
	replace factor_cola  = round(factor_cola)

	tabstat `ingreso' [aw=factor_cola], stats(sum) f(%25.2fc) save

	keep `sort' factor factor_cola cola `ingreso'

	local ingreso_cola = `ingreso'[_N]
	tempfile isr_cola
	save `isr_cola'

	restore
}



************************/
**# 8. FINALIZAR BASE ***
*************************
tempvar ingformalidadmax formalidadmax
egen `ingformalidadmax' = max(ing_total), by(folioviv foliohog numren formal)
g formalmax = formal if ing_total == `ingformalidadmax'

egen `formalidadmax' = max(formalmax), by(folioviv foliohog numren)
replace formalmax = `formalidadmax'

collapse (mean) ing_* exen_* cuotasT* infonavit fovissste htrab isrE renta deduc_isr SE ///
	(max) factor* sbc tot_integ scian formal* tipo_contribuyente sinco hablaind jubilado ///
	(min) subor, by(folioviv foliohog numren)
merge 1:1 (folioviv foliohog numren) using "`dir_enigh'/poblacion.dta", nogen ///
	keepusing(sexo edad nivelaprob gradoaprob asis_esc tipoesc nivel grado inst_* `segpop' disc*)

* Formalidad *
tabstat edad [fw=factor] if ing_subor != 0 | ing_mixto != 0, stat(count) f(%15.0fc) save by(formal)
tempname FORIMSS FORISSSTE FORPemex FOROtro FORISSSTEestatal FORIndependiente INFOR FORTOTMAT
matrix `INFOR' = r(Stat1)
matrix `FORIMSS' = r(Stat2)
matrix `FORISSSTE' = r(Stat3)
matrix `FORPemex' = r(Stat4)
matrix `FOROtro' = r(Stat5)
matrix `FORISSSTEestatal' = r(Stat6)
matrix `FORIndependiente' = r(Stat7)
matrix `FORTOTMAT' = r(StatTotal)

// Formalidad //
di in g "  IMSS " ///
	_col(44) in y %7.1fc `FORIMSS'[1,1]/`FORTOTMAT'[1,1]*100 "%"
di in g "  ISSSTE " ///
	_col(44) in y %7.1fc `FORISSSTE'[1,1]/`FORTOTMAT'[1,1]*100 "%"
di in g "  Pemex " ///
	_col(44) in y %7.1fc `FORPemex'[1,1]/`FORTOTMAT'[1,1]*100 "%"
di in g "  Otro " ///
	_col(44) in y %7.1fc `FOROtro'[1,1]/`FORTOTMAT'[1,1]*100 "%"
di in g "  ISSSTE estatal " ///
	_col(44) in y %7.1fc `FORISSSTEestatal'[1,1]/`FORTOTMAT'[1,1]*100 "%"
di in g "  Independiente " ///
	_col(44) in y %7.1fc `FORIndependiente'[1,1]/`FORTOTMAT'[1,1]*100 "%"
di in g "  Informal " ///
	_col(44) in y %7.1fc `INFOR'[1,1]/`FORTOTMAT'[1,1]*100 "%"


**********************************************
** 8.1 Imputar resultados a la Cola Derecha **
if `betamin' > 1 {
	*merge 1:1 (`sort') using `isr_cola', nogen keepus(factor_cola ing_cola)
	merge m:1 (`sort') using `isr_cola', nogen keepus(factor_cola ing_cola)

	replace `ingreso' = `ingreso_cola' in `=_N'
	replace factor_cola = factor if factor_cola == .

	tabstat factor_cola, stat(sum) f(%20.0fc) save
	tempname POBTOT
	matrix `POBTOT' = r(StatTotal)

	sort `ingreso'
	local topincomes = factor_cola[_N]
	local percentcola = `topincomes'/`POBTOT'[1,1]*100

	tempvar ingresocola
	egen double `ingresocola' = sum(`ingreso'), by(folioviv foliohog)

	tempvar ingpercentcola factorcola
	local ingcola = `ingreso'[_N]
	egen double `ingpercentcola' = sum(`ingreso') in -111/-1 if folioviv != ""
	egen double `factorcola' = sum(factor_cola) in -111/-1 if folioviv != ""

	replace `ingreso' = `ingreso' + `ingcola'*`ingreso'/`ingpercentcola' ///
		in -111/-1 if folioviv != ""
	replace factor_cola = round(factor_cola + `topincomes'*factor_cola/`factorcola') ///
		in -111/-1 if folioviv != ""
	replace isrE = isrE + `ingcola'*`ingreso'/`ingpercentcola'*.3 ///
		in -111/-1 if folioviv != ""

	foreach k of varlist ing_* {
		tabstat `k', stat(max) f(%15.0fc) save
		tempname TOPING
		matrix `TOPING' = r(StatTotal)

		tempvar temp`k'
		egen double `temp`k'' = sum(factor_cola) in -111/-1 if folioviv != "" & `k' != 0
		replace `k' = `k' + `TOPING'[1,1]*`betamin'*factor_cola/`temp`k'' ///
			in -111/-1 if folioviv != "" & `k' != 0
	}
	drop if folioviv == ""

	* Resultados de la Cola Derecha *
	tabstat ing_subor isrE [aw=factor_cola], stat(sum) f(%20.0fc) save by(formal)
	tempname TOP
	matrix `TOP' = r(StatTotal)

	Gini ing_subor, hogar(folioviv foliohog) factor(factor_cola)
	local gini_ing_subor_cola = r(gini_ing_subor)
	
	Gini isrE, hogar(folioviv foliohog) factor(factor_cola)
	local gini_isrE_cola = r(gini_isrE)

	noisily di _newline(2) _col(04) in g "{bf:Paso 2-BIS: Estimar la cola derecha (" in y "Beta = `betamin'" in g ")}"
	noisily di ///
	_col(04) in g "Hogares en la cola derecha " ///
		_col(57) in y %7.3fc `percentcola' "% " 

	noisily di _newline _col(04) in g "{bf:Ingreso bruto salarial" ///
		_col(44) in g "(Gini)" ///
		_col(57) in g %7s "`enigh'" ///
		_col(66) %7s "Macro" in g ///
		_col(77) %7s "Diferencia" "}"
	noisily di ///
	_col(04) in g "Remuneración de asalariados + CSS " ///
		_col(44) in y "(" %5.3fc `gini_ing_subor_cola' ")" ///
		_col(57) in y %7.3fc `TOP'[1,1]/`PIBSCN'*100 ///
		_col(66) in y %7.3fc (`RemSal'+`SSEmpleadores'+`SSImputada')/`PIBSCN'*100  ///
		_col(77) in y %7.1fc (`TOP'[1,1]/(`RemSal'+`SSEmpleadores'+`SSImputada')-1)*100 "%"
	noisily di ///
	_col(04) in g "ISR retenciones de asalariados " ///
		_col(44) in y "(" %5.3fc `gini_isrE_cola' ")" ///
		_col(57) in y %7.3fc `TOP'[1,2]/`PIBSCN'*100 ///
		_col(66) in y %7.3fc `ISRSalarios'/`PIBSCN'*100 ///
		_col(77) in y %7.1fc (`TOP'[1,2]/`ISRSalarios'-1)*100 "%"

	g factor_original = factor
	replace factor = factor_cola
}

*********************
** 8.3 Escolaridad **
destring gradoaprob, replace
g aniosesc = 0 //if nivelaprob == "0"
replace aniosesc = 1 if nivelaprob == "1"
replace aniosesc = gradoaprob + 1 if nivelaprob == "2"
replace aniosesc = gradoaprob + 7 if nivelaprob == "3"
replace aniosesc = gradoaprob + 10 if nivelaprob == "4"
replace aniosesc = gradoaprob + 12 if nivelaprob == "6"
replace aniosesc = gradoaprob + 13 if nivelaprob == "5" | nivelaprob == "7"
replace aniosesc = gradoaprob + 18 if nivelaprob == "8"
replace aniosesc = gradoaprob + 20 if nivelaprob == "9"

replace nivelaprob = trim(nivelaprob)
g escol = 0 if nivelaprob == "0" | nivelaprob == ""
replace escol = 1 if nivelaprob == "1" | nivelaprob == "2" | nivelaprob == "3"
replace escol = 2 if nivelaprob == "4" | nivelaprob == "6"
replace escol = 3 if nivelaprob == "5" | nivelaprob == "7"
replace escol = 4 if nivelaprob == "8" | nivelaprob == "9"

* Labels *
label define escol 0 "Sin escolaridad" 1 "Básica" 2 "Media Superior" 3 "Superior" 4 "Posgrado"
label values escol escol
label var escol "Nivel de escolaridad"

label values tipo_contribuyente tipo_contribuyente

label var ing_jubila "Pensiones"
label var ing_subor "Sueldos y salarios"
label var ing_mixto "Ingreso mixto"
label var ing_capital "Sociedades e ISFLSH"
label var ing_estim_alqu "Imputación de alquiler"



*******************
**# 9. Altimirs ***
*******************
tabstat ing_subor ing_mixto ing_capital ing_estim_alqu ing_remesas [aw=factor], stat(sum) f(%20.0fc) save by(formal)
tempname ALTIMIR0
matrix `ALTIMIR0' = r(StatTotal)

// Step 5 //
scalar TaltimirSal = (`RemSal'+`SSEmpleadores'+`SSImputada')/`ALTIMIR0'[1,1]
scalar TaltimirSelf = (`MixKN'+`MixL')/`ALTIMIR0'[1,2]
scalar TaltimirCap = (`ExNOpSoc'+`ImpNetProduccionK'*(`ExNOpSoc')/(`MixKN'+`ExNOpSoc'+`ExNOpHog') ///
	+`ImpNetProductos'*(`ExNOpSoc')/(`MixKN'+`ExNOpSoc'+`ExNOpHog') ///
	-`IMSSpropio'-`ISSSTEpropio'-`CFEpropio'-`Pemexpropio'-`FMP'-`OtrasEmpresas')/`ALTIMIR0'[1,3]
	//-`Mejoras'-`Derechos'-`Productos'-`Aprovechamientos'-`OtrosTributarios'
scalar TaltimirHouse = `ExNOpHog'/`ALTIMIR0'[1,4]
scalar TaltimirROWTrans = `ROWTrans'/`ALTIMIR0'[1,5]

if "`altimir'" == "yes" {
	noisily di in g "   Altimir: " in y "`altimir'"
	replace ing_estim_alqu = ing_estim_alqu*TaltimirHouse
	replace ing_remesas = ing_remesas*TaltimirROWTrans

	foreach k of varlist ing_subor *_t4_cap4 *_t4_cap5 *_t4_cap6 *_t4_cap7 *_t4_cap8 *_t4_cap9 {
		replace `k' = `k'*TaltimirSal
	}
	foreach k of varlist ing_mixto* *_t4_cap2pf *_t4_cap3pf *_t4_cap5 *_t4_cap6 *_t4_cap7 *_t4_cap8 *_t4_cap9 {
		replace `k' = `k'*TaltimirSelf
	}
	foreach k of varlist ing_capital ing_t2_cap1 ing_t2_cap8 ing_t4_cap2PM ing_t4_cap3PM {
		replace `k' = `k'*TaltimirCap
	}
}


*****************************
**# 10. Re-calculo de ISR ***
*****************************
noisily di _newline(2) _col(04) in g "{bf:Paso 3: Sumar ingresos por individuo y re-calcular ISR}"
egen ing_bruto_tax = rsum(ing_subor ing_t4_cap2pf ing_t4_cap3pf ing_t4_cap4 ing_t4_cap5 ///
	ing_t4_cap6 ing_t4_cap7 ing_t4_cap8 ing_t4_cap9)
replace ing_bruto_tax = 0 if ing_bruto_tax < 0
label var ing_bruto_tax "Ingreso gravable"

egen exen_tot = rsum(exen_t4_cap1 exen_t4_cap2pf exen_t4_cap3pf exen_t4_cap4 exen_t4_cap5 ///
	exen_t4_cap6 exen_t4_cap7 exen_t4_cap8 exen_t4_cap9)
label var exen_tot "Exenciones totales"

egen ing_bruto_tpm = rsum(ing_t2_cap1 ing_t2_cap8 ing_t4_cap2PM ing_t4_cap3PM)
label var ing_bruto_tpm "Ingreso gravable PM"

egen exen_tpm = rsum(exen_t2_cap1 exen_t2_cap8 exen_t4_cap2PM exen_t4_cap3PM)
label var exen_tot "Exenciones PM"

** Subsidio al empleo EMPRESAS **
Distribucion SE_empresas, relativo(ing_bruto_tpm) macro(`=`GROSSISR'[1,2]')

*******************************
** 10.1 CALCULO DE ISR FINAL **
g ISR = 0
label var ISR "ISR (f{c i'}sicas y asalariados)"

* Deducciones personales y gastos profesionales *
noisily di _newline _col(04) in g "{bf:3.1. Deducciones personales y gastos profesionales}"
noisily di _col(04) in g "{bf:SUPUESTO: " in y "Las deducciones personales son beneficios para el jefe del hogar.}"

* Limitar deducciones *
replace deduc_isr = 5*`smdf' if 5*`smdf' <= 15/100*ing_bruto_tax & deduc_isr >= 5*`smdf'
replace deduc_isr = 15/100*ing_bruto_tax if 5*`smdf' >= 15/100*ing_bruto_tax & deduc_isr >= 15/100*ing_bruto_tax

g categF = ""
forvalues j=`=rowsof(ISR)'(-1)1 {
	forvalues k=`=rowsof(SE)'(-1)1 {
		replace categF = "J`j'K`k'" ///
			if (ing_bruto_tax - exen_tot - deduc_isr - cuotasTP) >= ISR[`j',1] ///
			 & (ing_bruto_tax - exen_tot - deduc_isr - cuotasTP) <= ISR[`j',2] ///
			 & (ing_bruto_tax - exen_tot - deduc_isr - cuotasTP) >= SE[`k',1] ///
			 & (ing_bruto_tax - exen_tot - deduc_isr - cuotasTP) <= SE[`k',2]

		replace ISR = ISR[`j',3] + (ISR[`j',4]/100)*(ing_bruto_tax - exen_tot - deduc_isr - cuotasTP - ISR[`j',1]) if categF == "J`j'K`k'"
	}
}


******************
**# 11 PROBITS ***
******************
g formal_probit = formal2 != 0
g rural = substr(folioviv,3,1) == "6"
g edad2 = edad^2
g aniosesc2 = aniosesc^2

tostring scian, replace
replace scian = "9" if scian == "."
g scian2 = substr(scian,1,1)

tostring sinco, replace
replace sinco = "9" if sinco == "."
g sinco2 = substr(sinco,1,1)

replace subor = 2 if subor == .

g prop_subor = ing_subor/(ing_mixto+ing_subor+ing_capital)
replace prop_subor = 0 if prop_subor == .

g prop_mixto = ing_mixto/(ing_mixto+ing_subor+ing_capital)
replace prop_mixto = 0 if prop_mixto == .

g prop_capital = ing_capital/(ing_mixto+ing_subor+ing_capital)
replace prop_capital = 0 if prop_capital == .

foreach k of varlist ing_* {
	replace `k' = 0 if `k' == .
}

***************************************
** 10.2 Probit formalidad (salarios) **
noisily di _newline _col(04) in g "{bf:3.2. Probit de formalidad: " in y "Salarios.}"
noisily xi: probit formal_probit deduc_isr ///
	edad edad2 i.sexo aniosesc aniosesc2 rural i.sinco2 i.scian2 ///
	if ing_t4_cap1 > 0 & edad >= 16 [pw=factor]
estimates save "`c(sysdir_site)'/SIM/`enighanio'/formal_salarios", replace
predict double prob_salarios if e(sample)

* Seleccionar individuo formales (general) *
gsort -formal_probit -prob_salarios
g formal_accumSAL = sum(factor) if prob_salarios != .
egen formal_SAL = sum(factor) if prob_salarios != .
g prop_salarios = formal_accumSAL/formal_SAL

**************************************
** 10.3 Probit formalidad (fisicas) **
noisily di _newline _col(04) in g "{bf:3.3. Probit de formalidad: " in y "Personas f{c i'}sicas.}"
noisily xi: probit formal_probit deduc_isr ///
	edad edad2 i.sexo aniosesc aniosesc2 rural i.sinco2 i.scian2 ///
	if ing_t4_cap2 + ing_t4_cap3 + ing_t4_cap4 + ing_t4_cap5 ///
	+ ing_t4_cap6 + ing_t4_cap7 + ing_t4_cap8 + ing_t4_cap9 > 0 & edad >= 16 [pw=factor]
estimates save "`c(sysdir_site)'/SIM/`enighanio'/formal_fisicas", replace
predict double prob_formal if e(sample)

* Seleccionar individuo formales (general) *
gsort -formal_probit -prob_formal
g formal_accum = sum(factor) if prob_formal != .
egen formal_NAC = sum(factor) if prob_formal != .
g prop_formal = formal_accum/formal_NAC

**************************************
** 10.4 Probit formalidad (morales) **
noisily di _newline _col(04) in g "{bf:3.4. Probit de formalidad: " in y "Personas morales.}"
noisily xi: probit formal_probit deduc_isr ///
	edad edad2 i.sexo aniosesc aniosesc2 rural i.sinco2 i.scian2 ///
	if ing_bruto_tpm > 0 & edad >= 16 [pw=factor]
estimates save "`c(sysdir_site)'/SIM/`enighanio'/formal_morales", replace
predict double prob_moral if e(sample)

* Seleccionar individuo formales (general) *
gsort -formal_probit -prob_moral
g formal_accumMOR = sum(factor) if prob_moral != .
egen formal_MOR = sum(factor) if prob_moral != .
g prop_moral = formal_accumMOR/formal_MOR


***********************
** 11.1 ISR SALARIOS **
gsort -formal_probit -prob_salarios
g ISR_asalariados = ISR*(ing_subor)/(ing_bruto_tax-cuotasTPF) if prob_salarios != .
replace ISR_asalariados = 0 if ISR_asalariados == .
label var ISR_asalariados "ISR (retenciones por salarios)"

* CUT-OFF *
g ISR_asa_accum = sum(ISR_asalariados*factor) if prob_salarios != .
g formal_asalariados = ISR_asa_accum <= `ISRSalarios' & prob_salarios != .

tabstat prop_salarios if formal_asalariados == 1, stat(max) save
tempname FORAS
matrix `FORAS' = r(StatTotal)

noisily di _col(04) in g "{bf:SUPUESTO: " in y ///
	"Se hace el cut-off en " %20.0fc `ISRSalarios' ///
	". La informalidad estimada para los asalariados es de " %6.2fc (1-`FORAS'[1,1])*100 in g "%.}"
scalar asisFORMALSalarios = string((`FORAS'[1,1])*100,"%6.3f")


*******************************
** 11.2 ISR PERSONAS FISICAS **
gsort -formal_probit -prob_formal
g ISR_PF = ISR - ISR_asalariados if ISR - ISR_asalariados > 0 & prob_formal != .
replace ISR_PF = 0 if ISR_PF == .
label var ISR_PF "ISR (personas f{c i'}sicas)"

* CUT-OFF *
g ISR_PF_accum = sum(ISR_PF*factor) if prob_formal != .
g formal_fisicas = ISR_PF_accum <= `ISRFisicas' & prob_formal != .
replace ISR_PF = 0 if formal_fisicas == 0

tabstat prop_formal if formal_fisicas == 1, stat(max) save
tempname FORPF
matrix `FORPF' = r(StatTotal)

noisily di _col(04) in g "{bf:SUPUESTO: " in y ///
	"Se hace el cut-off en " %20.0fc `ISRFisicas' ///
	". La informalidad estimada para las personas f{c i'}sicas es de " %6.2fc (1-`FORPF'[1,1])*100 in g "%.}"
scalar asisFORMALFisicas = string((`FORPF'[1,1])*100,"%6.3f")


*******************************
** 11.3 ISR PERSONAS MORALES **
gsort -formal_probit -prob_moral
g ISR_PM = (ing_bruto_tpm-exen_tpm)*.3 - SE_empresas
replace ISR_PM = 0 if ISR_PM == .
label var ISR_PM "ISR (personas morales)"

* CUT-OFF *
g ISR_PM_accum = sum(ISR_PM*factor) if prob_moral != .
g formal_morales = ISR_PM_accum <= `ISRMorales'
replace ISR_PM = 0 if formal_morales == 0

tabstat prop_moral if formal_morales == 1, stat(max) save
tempname FORPM
matrix `FORPM' = r(StatTotal)

noisily di _col(04) in g "{bf:SUPUESTO: " in y ///
	"Se hace el cut-off en " %20.0fc `ISRMorales' ///
	". La informalidad estimada para las personas morales es de " %6.2fc (1-`FORPM'[1,1])*100 in g "%.}"
scalar asisFORMALMorales = string((`FORPM'[1,1])*100,"%6.3f")

********************
** 11.4 ISR TOTAL **
replace ISR = ISR_asalariados + ISR_PF + ISR_PM

Gini ISR_asalariados, hogar(folioviv foliohog) factor(factor)
local gini_ISR_asalariados = r(gini_ISR_asalariados)

Gini ISR_PF, hogar(folioviv foliohog) factor(factor)
local gini_ISR_PF = r(gini_ISR_PF)

Gini ISR_PM, hogar(folioviv foliohog) factor(factor)
local gini_ISR_PM = r(gini_ISR_PM)

Gini ISR, hogar(folioviv foliohog) factor(factor)
local gini_ISR = r(gini_ISR)

******************
** 11.5 Results **
tabstat ISR_asalariados [aw=factor] if formal_asalariados == 1, stat(sum) f(%25.2fc) save
tempname RESTAXS
matrix `RESTAXS' = r(StatTotal)

tabstat ISR_PF [aw=factor] if formal_fisicas == 1, stat(sum) f(%25.2fc) save
tempname RESTAXF
matrix `RESTAXF' = r(StatTotal)

tabstat ISR_PM [aw=factor] if formal_morales == 1, stat(sum) f(%25.2fc) save
tempname RESTAX
matrix `RESTAX' = r(StatTotal)

noisily di _newline _col(04) in g "{bf:3.4. ISR anual" ///
	_col(44) in g "(Gini)" ///
	_col(57) in g %7s "`enigh'" ///
	_col(66) %7s "Macro" in g ///
	_col(77) %7s "Diferencia" "}"
noisily di ///
	_col(04) in g "ISR retenciones a asalariados" ///
	_col(44) in y "(" %5.3fc `gini_ISR_asalariados' ")" ///
	_col(57) in y %7.3fc `RESTAXS'[1,1]/`PIBSCN'*100 ///
	_col(66) in y %7.3fc `ISRSalarios'/`PIBSCN'*100 ///
	_col(77) in y %7.1fc (`RESTAXS'[1,1]/`ISRSalarios'-1)*100 "%"
scalar ISRASFSCNPIB = `ISRSalarios'/`PIBSCN'*100  
scalar ISRASFHHSPIB = `RESTAXS'[1,1]/`PIBSCN'*100
scalar giniISRASF = string(`gini_ISR_asalariados',"%5.3f")
noisily di ///
	_col(04) in g "ISR personas f{c i'}sicas" ///
	_col(44) in y "(" %5.3fc `gini_ISR_PF' ")" ///
	_col(57) in y %7.3fc `RESTAXF'[1,1]/`PIBSCN'*100 ///
	_col(66) in y %7.3fc `ISRFisicas'/`PIBSCN'*100 ///
	_col(77) in y %7.1fc (`RESTAXF'[1,1]/`ISRFisicas'-1)*100 "%"
scalar ISRPFFSCNPIB = `ISRFisicas'/`PIBSCN'*100
scalar ISRPFFHHSPIB = `RESTAXF'[1,1]/`PIBSCN'*100
scalar giniISRPFF = string(`gini_ISR_PF',"%5.3f")
noisily di ///
	_col(04) in g "ISR personas morales" ///
	_col(44) in y "(" %5.3fc `gini_ISR_PM' ")" ///
	_col(57) in y %7.3fc `RESTAX'[1,1]/`PIBSCN'*100 ///
	_col(66) in y %7.3fc `ISRMorales'/`PIBSCN'*100 ///
	_col(77) in y %7.1fc (`RESTAX'[1,1]/`ISRMorales'-1)*100 "%"
scalar ISRPMFSCNPIB = `ISRMorales'/`PIBSCN'*100
scalar ISRPMFHHSPIB = `RESTAX'[1,1]/`PIBSCN'*100
scalar giniISRPMF = string(`gini_ISR_PM',"%5.3f")
noisily di in g _dup(84) "-"
noisily di ///
	_col(04) in g "ISR total" ///
	_col(44) in y "(" %5.3fc `gini_ISR' ")" ///
	_col(57) in y %7.3fc (`RESTAXS'[1,1]+`RESTAXF'[1,1]+`RESTAX'[1,1])/`PIBSCN'*100 ///
	_col(66) in y %7.3fc (`ISRSalarios'+`ISRFisicas'+`ISRMorales')/`PIBSCN'*100 ///
	_col(77) in y %7.1fc ((`RESTAXS'[1,1]+`RESTAXF'[1,1]+`RESTAX'[1,1])/(`ISRSalarios'+`ISRFisicas'+`ISRMorales')-1)*100 "%"
scalar ISRFSCNPIB = (`ISRSalarios'+`ISRFisicas'+`ISRMorales')/`PIBSCN'*100
scalar ISRFHHSPIB = (`RESTAXS'[1,1]+`RESTAXF'[1,1]+`RESTAX'[1,1])/`PIBSCN'*100
scalar giniISRF = string(`gini_ISR',"%5.3f")



* Distribucines finales *
Distribucion ImpNetProduccionL_subor, relativo(ing_subor) ///
	macro(`=`ImpNetProduccionL'*(`RemSal'+`SSEmpleadores'+`SSImputada')/(`RemSal'+`SSEmpleadores'+`SSImputada'+`MixL')')

Distribucion ImpNetProduccionL_mixL, relativo(ing_mixtoL) ///
	macro(`=`ImpNetProduccionL'*(`MixL')/(`RemSal'+`SSEmpleadores'+`SSImputada'+`MixL')')

Distribucion ImpNetProduccionK_mixK, relativo(ing_mixtoK) ///
	macro(`=`ImpNetProduccionK'*(`MixKN')/(`MixKN'+`ExNOpSoc'+`ExNOpHog')')

Distribucion ImpNetProduccionK_soc, relativo(ing_capital) ///
	macro(`=`ImpNetProduccionK'*(`ExNOpSoc')/(`MixKN'+`ExNOpSoc'+`ExNOpHog')')

Distribucion ImpNetProduccionK_hog, relativo(ing_estim_alqu) ///
	macro(`=`ImpNetProduccionK'*(`ExNOpHog')/(`MixKN'+`ExNOpSoc'+`ExNOpHog')')

Distribucion ImpNetProductos_mixK, relativo(ing_mixtoK) ///
	macro(`=`ImpNetProductos'*(`MixKN')/(`MixKN'+`ExNOpSoc'+`ExNOpHog')')

Distribucion ImpNetProductos_soc, relativo(ing_capital) ///
	macro(`=`ImpNetProductos'*(`ExNOpSoc')/(`MixKN'+`ExNOpSoc'+`ExNOpHog')')

Distribucion ImpNetProductos_hog, relativo(ing_estim_alqu) ///
	macro(`=`ImpNetProductos'*(`ExNOpHog')/(`MixKN'+`ExNOpSoc'+`ExNOpHog')')

Distribucion gasto_anualDepreciacion, relativo(ing_capital) macro(`ConCapFij')
Gini gasto_anualDepreciacion, hogar(folioviv foliohog) factor(factor)
local gini_gasto_anualDepreciacion = r(gini_gasto_anualDepreciac)

Distribucion gasto_anualGobierno, relativo(factor) macro(`ConGob')

Distribucion ing_capitalROW, relativo(ing_capital) macro(`ROWProp')

Distribucion ing_suborROW, relativo(ing_subor) macro(`ROWRem')

g pob = 1
Distribucion ing_cap_imss, relativo(pob) macro(`IMSSpropio')
Distribucion ing_cap_issste, relativo(pob) macro(`ISSSTEpropio')
Distribucion ing_cap_cfe, relativo(pob) macro(`CFEpropio')
Distribucion ing_cap_pemex, relativo(pob) macro(`Pemexpropio')
Distribucion ing_cap_fmp, relativo(pob) macro(`FMP')
Distribucion ing_cap_otrasempr, relativo(pob) macro(`OtrasEmpresas')
egen ing_Sector_Publico = rsum(ing_cap_imss ing_cap_issste ing_cap_cfe ing_cap_pemex ing_cap_fmp ing_cap_otrasempr)
Gini ing_Sector_Publico, hogar(folioviv foliohog) factor(factor)
local gini_ing_Sector_Publico = r(gini_ing_Sector_Publico)

* Ingresos finales *
replace ing_subor = ing_subor + ImpNetProduccionL_subor
Gini ing_subor, hogar(folioviv foliohog) factor(factor)
local gini_ing_subor = r(gini_ing_subor)

replace ing_mixtoL = ing_mixtoL + ImpNetProduccionL_mixL
replace ing_mixtoK = ing_mixtoK + ImpNetProduccionK_mixK + ImpNetProductos_mixK
replace ing_mixto = ing_mixtoL + ing_mixtoK
replace ing_mixtoL = 2/3*ing_mixto
replace ing_mixtoK = 1/3*ing_mixto
Gini ing_mixto, hogar(folioviv foliohog) factor(factor)
local gini_ing_mixto = r(gini_ing_mixto)

*replace ing_capital = ing_capital + ImpNetProduccionK_soc + ImpNetProductos_soc
Gini ing_capital, hogar(folioviv foliohog) factor(factor)
local gini_ing_capital = r(gini_ing_capital)

replace ing_estim_alqu = ing_estim_alqu + ImpNetProduccionK_hog + ImpNetProductos_hog
Gini ing_estim_alqu, hogar(folioviv foliohog) factor(factor)
local gini_ing_estim_alqu = r(gini_ing_estim_alqu)

* Totales *
egen double ingbrutotot = rsum(ing_subor ing_mixto ing_capital ing_estim_alqu ing_remesas)
label var ingbrutotot "Ingreso total bruto"

Gini ingbrutotot, hogar(folioviv foliohog) factor(factor)
local gini_ingbrutotot = r(gini_ingbrutotot)

* Results *
tabstat ing_subor ing_mixto ing_capital ing_estim_alqu gasto_anualDepreciacion ing_Sector_Publico [aw=factor], stat(sum) f(%20.0fc) save by(formal)	
tempname ALTIMIR
matrix `ALTIMIR' = r(StatTotal)

// Step 5 //
noisily di _newline(2) _col(04) in g "{bf:Paso 4: Factores de escala" ///
	_col(44) in g "(Gini)" ///
	_col(57) in g %7s "`enigh'" ///
	_col(66) %7s "Macro" in g ///
	_col(77) %7s "Factor" "}"
noisily di ///
	_col(04) in g "(+) Rem. asalariados + CSS + Impuestos" ///
	_col(44) in y "(" %5.3fc `gini_ing_subor' ")" ///
	_col(57) in y %7.3fc `ALTIMIR'[1,1]/`PIBSCN'*100 ///
	_col(66) in y %7.3fc (`RemSal'+`SSEmpleadores'+`SSImputada'+`ImpNetProduccionL'*(`RemSal' ///
		+`SSEmpleadores'+`SSImputada')/(`RemSal'+`SSEmpleadores'+`SSImputada'+`MixL'))/`PIBSCN'*100 ///
	_col(77) in y %7.3fc TaltimirSal
scalar REMFSCNPIB = (`RemSal'+`SSEmpleadores'+`SSImputada'+`ImpNetProduccionL'*(`RemSal' ///
		+`SSEmpleadores'+`SSImputada')/(`RemSal'+`SSEmpleadores'+`SSImputada'+`MixL'))/`PIBSCN'*100
scalar REMFHHSPIB = `ALTIMIR'[1,1]/`PIBSCN'*100
scalar giniREMF = string(`gini_ing_subor',"%5.3f")
noisily di ///
	_col(04) in g "(+) Ingreso mixto + Impuestos" ///
	_col(44) in y "(" %5.3fc `gini_ing_mixto' ")" ///
	_col(57) in y %7.3fc `ALTIMIR'[1,2]/`PIBSCN'*100 ///
	_col(66) in y %7.3fc (`MixL'+`MixKN'+`ImpNetProduccionL'*(`MixL')/(`RemSal' ///
		+`SSEmpleadores'+`SSImputada'+`MixL')+`ImpNetProduccionK'*(`MixKN')/(`MixKN' ///
		+`ExNOpSoc'+`ExNOpHog')+`ImpNetProductos'*(`MixKN')/(`MixKN'+`ExNOpSoc'+`ExNOpHog'))/`PIBSCN'*100 ///
	_col(77) in y %7.3fc TaltimirSelf
scalar MIXFSCNPIB = (`MixL'+`MixKN'+`ImpNetProduccionL'*(`MixL')/(`RemSal' ///
		+`SSEmpleadores'+`SSImputada'+`MixL')+`ImpNetProduccionK'*(`MixKN')/(`MixKN' ///
		+`ExNOpSoc'+`ExNOpHog')+`ImpNetProductos'*(`MixKN')/(`MixKN'+`ExNOpSoc'+`ExNOpHog'))/`PIBSCN'*100
scalar MIXFHHSPIB = `ALTIMIR'[1,2]/`PIBSCN'*100
scalar giniMIXF = string(`gini_ing_mixto',"%5.3f")
noisily di ///
	_col(04) in g "(+) Sociedades e ISFLSH + Impuestos" ///
	_col(44) in y "(" %5.3fc `gini_ing_capital' ")" ///
	_col(57) in y %7.3fc `ALTIMIR'[1,3]/`PIBSCN'*100 ///
	_col(66) in y %7.3fc (`ExNOpSoc'+`ImpNetProduccionK'*(`ExNOpSoc')/(`MixKN' ///
		+`ExNOpSoc'+`ExNOpHog')+`ImpNetProductos'*(`ExNOpSoc')/(`MixKN'+`ExNOpSoc'+`ExNOpHog') ///
		-`IMSSpropio'-`ISSSTEpropio'-`CFEpropio'-`Pemexpropio'-`FMP'-`OtrasEmpresas')/`PIBSCN'*100 ///
	_col(77) in y %7.3fc TaltimirCap
scalar SOCFSCNPIB = (`ExNOpSoc'+`ImpNetProduccionK'*(`ExNOpSoc')/(`MixKN' ///
		+`ExNOpSoc'+`ExNOpHog')+`ImpNetProductos'*(`ExNOpSoc')/(`MixKN'+`ExNOpSoc'+`ExNOpHog'))/`PIBSCN'*100
scalar SOCFHHSPIB = `ALTIMIR'[1,3]/`PIBSCN'*100
scalar giniSOCF = string(`gini_ing_capital',"%5.3f")
noisily di ///
	_col(04) in g "(+) Organismos y empresas públicas" ///
	_col(44) in y "(" %5.3fc `gini_ing_Sector_Publico' ")" ///
	_col(57) in y %7.3fc `ALTIMIR'[1,6]/`PIBSCN'*100 ///
	_col(66) in y %7.3fc (`IMSSpropio'+`ISSSTEpropio'+`CFEpropio'+`Pemexpropio'+`FMP'+`OtrasEmpresas')/`PIBSCN'*100 ///
	_col(77) in y %7.3fc 1
noisily di ///
	_col(04) in g "(+) Alquiler imputado + Impuestos" ///
	_col(44) in y "(" %5.3fc `gini_ing_estim_alqu' ")" ///
	_col(57) in y %7.3fc `ALTIMIR'[1,4]/`PIBSCN'*100 ///
	_col(66) in y %7.3fc (`ExNOpHog'+`ImpNetProduccionK'*(`ExNOpHog')/(`MixKN' ///
		+`ExNOpSoc'+`ExNOpHog')+`ImpNetProductos'*(`ExNOpHog')/(`MixKN'+`ExNOpSoc'+`ExNOpHog'))/`PIBSCN'*100 ///
	_col(77) in y %7.3fc TaltimirHouse
scalar ALQFSCNPIB = (`ExNOpHog'+`ImpNetProduccionK'*(`ExNOpHog')/(`MixKN' ///
		+`ExNOpSoc'+`ExNOpHog')+`ImpNetProductos'*(`ExNOpHog')/(`MixKN'+`ExNOpSoc'+`ExNOpHog'))/`PIBSCN'*100
scalar ALQFHHSPIB = `ALTIMIR'[1,4]/`PIBSCN'*100
scalar giniALQF = string(`gini_ing_estim_alqu',"%5.3f")
noisily di in g _dup(83) "-"
noisily di ///
	_col(04) in g "(=) Producto Interno Neto" ///
	_col(44) in y "(" %5.3fc `gini_ingbrutotot' ")" ///
	_col(57) in y %7.3fc (`ALTIMIR'[1,1]+`ALTIMIR'[1,2]+`ALTIMIR'[1,3]+`ALTIMIR'[1,4]+`ALTIMIR'[1,6])/`PIBSCN'*100 ///
	_col(66) in y %7.3fc (`RemSal'+`SSEmpleadores'+`SSImputada'+`MixL'+`MixKN'+`ExNOpSoc'+`ExNOpHog' ///
		+`ImpNetProduccionL'+`ImpNetProduccionK'+`ImpNetProductos')/`PIBSCN'*100 ///
	_col(77) in y %7.3fc ((`ALTIMIR'[1,1]+`ALTIMIR'[1,2]+`ALTIMIR'[1,3]+`ALTIMIR'[1,4]+`ALTIMIR'[1,6])/(`RemSal'+`SSEmpleadores' ///
		+`SSImputada'+`MixL'+`MixKN'+`ExNOpSoc'+`ExNOpHog'+`ImpNetProduccionL'+`ImpNetProduccionK'+`ImpNetProductos'))^(-1)
scalar PINFSCNPIB = (`RemSal'+`SSEmpleadores'+`SSImputada'+`MixL'+`MixKN'+`ExNOpSoc'+`ExNOpHog' ///
		+`ImpNetProduccionL'+`ImpNetProduccionK'+`ImpNetProductos')/`PIBSCN'*100
scalar PINFHHSPIB = (`ALTIMIR'[1,1]+`ALTIMIR'[1,2]+`ALTIMIR'[1,3]+`ALTIMIR'[1,4]+`ALTIMIR'[1,6])/`PIBSCN'*100
scalar giniPINF = string(`gini_ingbrutotot',"%5.3f")
scalar TPINF = ((`ALTIMIR'[1,1]+`ALTIMIR'[1,2]+`ALTIMIR'[1,3]+`ALTIMIR'[1,4]+`ALTIMIR'[1,6])/(`RemSal'+`SSEmpleadores' ///
		+`SSImputada'+`MixL'+`MixKN'+`ExNOpSoc'+`ExNOpHog'+`ImpNetProduccionL'+`ImpNetProduccionK'+`ImpNetProductos'))^(-1)
noisily di ///
	_col(04) in g "(+) Depreciación" ///
	_col(44) in y "(" %5.3fc `gini_gasto_anualDepreciacion' ")" ///
	_col(57) in y %7.3fc `ALTIMIR'[1,5]/`PIBSCN'*100 ///
	_col(66) in y %7.3fc (`ConCapFij')/`PIBSCN'*100 ///
	_col(77) in y %7.3fc (`ALTIMIR'[1,5]/`ConCapFij')^(-1)
scalar DEPFSCNPIB = (`ConCapFij')/`PIBSCN'*100
scalar DEPFHHSPIB = `ALTIMIR'[1,5]/`PIBSCN'*100
scalar giniDEPF = string(`gini_gasto_anualDepreciacion',"%5.3f")
scalar DifDEPF = (`ALTIMIR'[1,5]/`ConCapFij'-1)*100
noisily di in g _dup(83) "-"
noisily di ///
	_col(04) in g "(=) Producto Interno Bruto" ///
	_col(44) in y "(" %5.3fc `gini_ingbrutotot' ")" ///
	_col(57) in y %7.3fc (`ALTIMIR'[1,1]+`ALTIMIR'[1,2]+`ALTIMIR'[1,3]+`ALTIMIR'[1,4]+`ALTIMIR'[1,5]+`ALTIMIR'[1,6])/`PIBSCN'*100 ///
	_col(66) in y %7.3fc (`RemSal'+`SSEmpleadores'+`SSImputada'+`MixL'+`MixKN'+`ExNOpSoc'+`ExNOpHog' ///
		+`ImpNetProduccionL'+`ImpNetProduccionK'+`ImpNetProductos'+`ConCapFij')/`PIBSCN'*100 ///
	_col(77) in y %7.3fc ((`ALTIMIR'[1,1]+`ALTIMIR'[1,2]+`ALTIMIR'[1,3]+`ALTIMIR'[1,4]+`ALTIMIR'[1,5]+`ALTIMIR'[1,6])/(`RemSal' ///
		+`SSEmpleadores'+`SSImputada'+`MixL'+`MixKN'+`ExNOpSoc'+`ExNOpHog'+`ImpNetProduccionL'+`ImpNetProduccionK' ///
		+`ImpNetProductos'+`ConCapFij'))^(-1)
scalar FPIBSCNPIB = (`RemSal'+`SSEmpleadores'+`SSImputada'+`MixL'+`MixKN'+`ExNOpSoc'+`ExNOpHog' ///
		+`ImpNetProduccionL'+`ImpNetProduccionK'+`ImpNetProductos'+`ConCapFij')/`PIBSCN'*100
scalar FPIBHHSPIB = (`ALTIMIR'[1,1]+`ALTIMIR'[1,2]+`ALTIMIR'[1,3]+`ALTIMIR'[1,4]+`ALTIMIR'[1,5]+`ALTIMIR'[1,6])/`PIBSCN'*100
scalar giniPIBF = string(`gini_ingbrutotot',"%5.3f")



*********************************/
**# 12. Variables descriptivas ***
**********************************
merge 1:1 (folioviv foliohog numren) using "`c(sysdir_site)'/SIM/`enighanio'/expenditures.dta", nogen keepus(gas_pc_*)
merge 1:1 (folioviv foliohog numren) using "`c(sysdir_site)'/SIM/`enighanio'/consumption_categ_iva.dta", nogen keepus(IVA)
merge 1:1 (folioviv foliohog numren) using "`c(sysdir_site)'/SIM/`enighanio'/consumption_categ_ieps.dta", nogen keepus(IEPS)

tempvar tot_integ
egen `tot_integ' = count(edad), by(folioviv foliohog)

* Deciles brutos SIMULADOR *
egen double ing_decil_hog = sum(ingbrutotot), by(folioviv foliohog)
g ing_decil_pc = ing_decil_hog/`tot_integ'

xtile decil = ing_decil_pc [pw=factor/`tot_integ'], n(10)   // Ingreso per capita
*xtile decil = ing_decil_hog [pw=factor/`tot_integ'], n(10) // Ingreso por hogar
xtile quintil = ing_decil_pc [pw=factor/`tot_integ'], n(5)
xtile percentil = ing_decil_pc [pw=factor/`tot_integ'], n(100)

* Label values *
label define decil 1 "I" 2 "II" 3 "III" 4 "IV" 5 "V" 6 "VI" 7 "VII" 8 "VIII" 9 "IX" 10 "X", modify
label values decil decil

label define quintil 1 "I" 2 "II" 3 "III" 4 "IV" 5 "V"
label values quintil quintil

destring sexo, replace
label define sexo 1 "Hombres" 2 "Mujeres"
label values sexo sexo

replace rural = 2 if hablaind == 1
label define rural 1 "Rural" 0 "Urbano" 2 "Indígena"
label values rural rural

g grupoedad = 1 if edad < 5
replace grupoedad = 2 if edad >= 5 & edad < 18
replace grupoedad = 3 if edad >= 18 & edad < 25
replace grupoedad = 4 if edad >= 25 & edad < 65
replace grupoedad = 5 if edad >= 65
label define grupoedad 1 "De 0 a 4" 2 "De 5 a 17" 3 "De 18 a 24" 4 "De 25 a 64" 5 "De 65 y más"
label values grupoedad grupoedad

replace formalmax = 3 if formalmax == 4
label define formalidad 3 "Pemex y otros", modify
label values formalmax formalidad

egen gastoanualTOT = rsum(gas_pc_*)
label var gastoanualTOT "Gasto anual total"

* Compras netas fuera del pais *
Distribucion gasto_anualComprasN, relativo(gastoanualTOT) macro(`ComprasN')

* Sector público *
Distribucion ing_cap_mejoras, relativo(factor) macro(`Mejoras')
Distribucion ing_cap_derechos, relativo(factor) macro(`Derechos')
Distribucion ing_cap_productos, relativo(factor) macro(`Productos')
Distribucion ing_cap_aprovecha, relativo(factor) macro(`Aprovechamientos')
Distribucion ing_cap_otrostrib, relativo(factor) macro(`OtrosTributarios')

* Impuestos al consumo *
Distribucion ISAN, relativo(gas_pc_Vehi) macro(`ISAN')
Distribucion Importaciones, relativo(gastoanualTOT) macro(`Importaciones')
egen ImpuestosConsumoTOT = rsum(IVA IEPS ISAN Importaciones) 
*tabstat IVATOT IEPSTOT ISAN Importaciones [aw=factor], stat(sum) f(%20.0fc) save



*******************************
*** Sankey: PIB demográfico ***
/*******************************
egen double Yl = rsum(ing_subor ing_mixtoL)
label var Yl "Ingreso laboral"
noisily Perfiles Yl [fw=factor], aniope(`enighanio') aniovp(`enighanio') title("Ingreso laboral")

egen double Yk = rsum(ing_capital ing_mixtoK ing_estim_alqu gasto_anualDepreciacion)
label var Yk "Ingreso de capital"
noisily Perfiles Yk [fw=factor], aniope(`enighanio') aniovp(`enighanio') title("Ingreso de capital")

noisily Perfiles gastoanualTOT [fw=factor], aniope(`enighanio') aniovp(`enighanio') title("Gasto anual total")
noisily Perfiles ing_suborROW [fw=factor], aniope(`enighanio') aniovp(`enighanio') title("Ingreso laboral ROW")

g Ciclodevida = Yl + Yk + ing_remesas + ing_suborROW - gastoanualTOT
label var Ciclodevida "ciclo de vida"
noisily Perfiles Ciclodevida [fw=factor], aniope(`enighanio') aniovp(`enighanio') title("Ciclo de vida")

g Ahorro = ingbrutotot + ing_capitalROW + ing_suborROW + ing_remesas ///
	- gastoanualTOT - gasto_anualComprasN - gasto_anualGobierno
noisily Perfiles Ahorro [fw=factor], aniope(`enighanio') aniovp(`enighanio') title("Ahorro")
label var Ahorro "ahorro"



**********/
*** END ***
***********
capture drop __*
format ing_* exen_* renta %10.0fc
compress
if `c(version)' > 13.1 {
	saveold "`c(sysdir_site)'/SIM/`enighanio'/households.dta", replace version(13)
}
else {
	save "`c(sysdir_site)'/SIM/`enighanio'/households.dta", replace
}



*****************
** Sankeys NTA **
*****************
** Inputs: Archivo "`c(sysdir_site)'/SIM/`anio'/households.dta".
** Outputs: Archivos .json en carpeta "/var/www/html/SankeyNTA/.
//foreach k in decil sexo grupoedad escol rural {
//	run "`c(sysdir_site)'/Sankey.do" `k' `enighanio' SankeyNTA
//}


timer off 6
timer list 6
noisily di _newline in g "{bf:Tiempo:} " in y round(`=r(t6)/r(nt6)',.1) in g " segs."
log close households
