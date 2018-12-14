*************************************
****                             ****
**** MACRO + MICRO HARMONIZATION ****
****                             ****
*************************************
if "`1'" == "" {
	local 1 = 2016
}
if `1' >= 2016 {
	local enigh = "ENIGH"
	local hogar = "folioviv foliohog"
	local enighanio = 2016
	local macroanio = 2016
	local betamin = 1							// ENIGH: 2.38
	local altimir = "no"
	local CuotasISSSTE = 79886000000					// Trabajadores y dependencias. Informe financiero y actuarial del ISSSTE (2016)
	local SubsidioEmpleo = 43707000000					// Presupuesto de gastos fiscales (2016)
	local udis = 5.4490872131						// Promedio de valor de UDIS de enero a diciembre 2016
	local smdf = 73.04							// 2016
}
if `1' == 2015 {
	local enigh = "ENIGH-MCS"
	local hogar = "proyecto folioviv foliohog"
	local enighanio = 2015
	local macroanio = 2015
	local betamin = 1.9935							// MCS: 1.9935
	local altimir = "yes"
	rename factor factor_hog
	local CuotasISSSTE = 74986000000					// Trabajadores y dependencias. Informe financiero y actuarial del ISSSTE (2015)
	local SubsidioEmpleo = 42813000000					// Presupuesto de gastos fiscales (2015)
	local udis = 5.3051696959  						// Promedio de valor de UDIS de enero a diciembre 2015
	local smdf = 70.10							// 2015
}
if `1' == 2014 {
	local enigh = "ENIGH-MCS"
	local hogar = "proyecto folioviv foliohog"
	local enighanio = 2014
	local macroanio = 2014
	local betamin = 1							// ENIGH: 2.92, MCS: 2.8191 
	local altimir = "no"
	local CuotasISSSTE = 71771000000					// Trabajadores y dependencias. Informe financiero y actuarial del ISSSTE (2014)
	local SubsidioEmpleo = 41293000000					// Presupuesto de gastos fiscales (2014)
	local udis = 5.1561230329  						// Promedio de valor de UDIS de enero a diciembre 2014
	local smdf = 67.29							// Zona A. 2014
}
if `1' == 2013 {
	local enigh = "ENIGH"
	local hogar = "folioviv foliohog"
	local enighanio = 2012
	local macroanio = 2013
	local betamin = 2.92							// ENIGH: 2.92, MCS: 2.8191 
	local altimir = "yes"
	local CuotasISSSTE = 71771000000					// Trabajadores y dependencias. Informe financiero y actuarial del ISSSTE (2014)
	local SubsidioEmpleo = 41293000000					// Presupuesto de gastos fiscales (2014)
	local udis = 5.1561230329  						// Promedio de valor de UDIS de enero a diciembre 2014
	local smdf = 67.29							// Zona A. 2014
}





***************************************
*** A. Macros 1. Cuentas Nacionales ***
***************************************
SCN, anio(`macroanio')
local PIBSCN = r(PIB)
local RemSal = r(RemSal)
local SSEmpleadores = r(SSEmpleadores)
local SSImputada = r(SSImputada)
local MixL = r(MixL)
local ExNOpSoc = r(ExNOpSoc)
local ExNOpHog = r(ExNOpHog)
local MixKN = r(MixKN)
local MixK = r(MixK)
local ROWRem = r(ROWRem)
local ROWTrans = r(ROWTrans)
local SNAAlquiler = r(Alquileres)
local SNAInmobiliarias = r(Inmobiliarias)
local SNAExBOpHog = r(ExBOpHog)
local SNAAlojamiento = r(Alojamiento)
local ServProf = r(ServProf)
local ConsMedi = r(ConsMedi)
local ConsDent = r(ConsDent)
local ConsOtro = r(ConsOtro)
local EnfeDomi = r(EnfeDomi)
local ServProfH = 67849000000
local SaludH = 196882000000





************************
*** A. Macros 2. LIF ***
************************
LIF, anio(`macroanio')
local ISRSalarios = r(ISR__asalariados_)
local ISRFisicas = r(ISR__PF_)
local ISRMorales = r(ISR__PM_)
local ISROtros = r(ISR__contratistas_y_asignatarios)
local CuotasIMSS = r(Cuotas__IMSS_)
local IMSSpropio = r(IMSS)
local ISSSTEpropio = r(ISSSTE)
local CFEpropio = r(CFE)
local Pemexpropio = r(Pemex)
local FMP = r(FMP__Derechos_petroleros)
local Deuda = r(Deuda)
local Mejoras = r(Contribuciones_de_mejoras)
local Derechos = r(Derechos)
local Productos = r(Productos)
local Aprovechamientos = r(Aprovechamientos)
local OtrosTributarios = r(Otros_tributarios)
local OtrasEmpresas = r(Otras_empresas)





************************
*** A. Macros 3. PEF ***
************************
PEF, anio(`macroanio') by(desc_funcion)
local Cuotas_ISSSTE = r(Cuotas_ISSSTE)

PEF if neto == 0 & ramo != -1 & (substr(string(objeto),1,2) == "45" ///
	| substr(string(objeto),1,2) == "47" | desc_pp == 779), anio(`macroanio') by(ramo)
local SSFederacion = r(Aportaciones_a_Seguridad_Social) + `Cuotas_ISSSTE'





************************
*** A. Macros 4. SAT ***
************************
if `macroanio' >= 2015 {
	PIBDeflactor, aniovp(`macroanio')
	forvalues k=1(1)`=_N' {
		if anio[`k'] == 2015 {
			local deflactor = deflator[`k']
		}
	}
	use "`c(sysdir_personal)'../basesCIEP/SAT/Personas fisicas/Stata/2015_labels.dta", clear
	tabstat iaarrendamiento utgravacumap utgravacumriap, stat(sum) f(%20.0fc) save
	tempname SATAbierto
	matrix `SATAbierto' = r(StatTotal)  
	local acum_arrenda = `SATAbierto'[1,1]/`deflactor'
	local util_serprof = `SATAbierto'[1,2]/`deflactor'
}
else {
	use "`c(sysdir_personal)'../basesCIEP/SAT/Personas fisicas/Stata/`macroanio'_labels.dta", clear
	tabstat iaarrendamiento utgravacumap utgravacumriap, stat(sum) f(%20.0fc) save
	tempname SATAbierto
	matrix `SATAbierto' = r(StatTotal)  
	local acum_arrenda = `SATAbierto'[1,1]
	local util_serprof = `SATAbierto'[1,2]
}




***********************************
*** B. Micro 1. ENIGH. Ingresos ***
***********************************
noisily di _newline(2) _col(04) in g "{bf:INGRESOS DE LOS HOGARES: " in y "`enigh' `enighanio'}"
use "`c(sysdir_personal)'../basesCIEP/INEGI/`enigh'/`enighanio'/ingresos.dta", clear
merge m:1 (`hogar') using "`c(sysdir_personal)'../basesCIEP/INEGI/`enigh'/`enighanio'/concentrado.dta", ///
	keepusing(factor_hog tot_integ smg) keep(matched)

* Reemplazar missings por ceros *
foreach k of varlist ing_*  {
	replace `k' = 0 if `k' == .
}

* Ingreso anualizado *
g double ing_anual = ing_tri*4
egen double ing_unico = rsum(ing_1 ing_2 ing_3 ing_4 ing_5 ing_6)

* Tipo de trabajo *
g id_trabajo = "1" if clave >= "P001" & clave <= "P013"				// Ingresos del trabajo principal
replace id_trabajo = "2" if clave >= "P014" & clave <= "P020"			// Ingresos del trabajo secundario
replace id_trabajo = "0" if id_trabajo == ""					// Ingresos ajenos al trabajo

* Salario minimo mensual *
g sm = round(smg/90,.01)





*************************************************
*** 1. IDENTIFICAR INGRESOS CONFORME A LA LEY *** 
*************************************************
* TITULO II. DE LAS PERSONAS MORALES *
*	Capitulo VIII. 	REGIMEN DE ACTIVIDADES AGRICOLAS, GANADERAS, SILVICOLAS Y PESQUERAS *
* TITULO IV. DE LAS PERSONAS FISICAS *
*	Capitulo I. 	DE LOS INGRESOS POR SALARIOS Y EN GENERAL POR LA PRESTACION DE UN SERVICIO PERSONAL SUBORDINADO *
*	Capitulo II. 	DE LOS INGRESOS POR ACTIVIDADES EMPRESARIALES Y PROFESIONALES *
*	Capitulo III.	DE LOS INGRESOS POR ARRENDAMIENTO Y EN GENERAL POR OTORGAR EL USO O GOCE TEMPORAL DE BIENES INMUEBLES *
*	Capitulo IV. 	DE LOS INGRESOS POR ENAJENACION DE BIENES *
*	Capitulo V. 	DE LOS INGRESOS POR ADQUISICION DE BIENES *
*	Capitulo VI. 	DE LOS INGRESOS POR INTERESES *
*	Capitulo VII.	DE LOS INGRESOS POR LA OBTENCION DE PREMIOS *
*	Capitulo VIII.	DE LOS INGRESOS POR DIVIDENDOS Y EN GENERAL POR LAS GANANCIAS DISTRIBUIDAS POR PERSONAS MORALES *
*	Capitulo IX. 	DE LOS DEMAS INGRESOS QUE OBTENGAN LAS PERSONAS FISICAS *



********************************************
** 1.1 Titulo II. De las Personas Morales **
** Capitulo VIII. REGIMEN DE ACTIVIDADES AGRICOLAS, GANADERAS, SILVICOLAS Y PESQUERAS **
* a. Agricultura *
g double ing_agri = ing_anual if clave == "P071" | clave == "P072" | clave == "P073" | clave == "P074" ///
	| clave == "P078" | clave == "P079" | clave == "P080" | clave == "P081"



*******************************************
** 1.2 Titulo IV De las Personas Fisicas **
** Capitulo I. DE LOS INGRESOS POR SALARIOS Y EN GENERAL POR LA PRESTACION DE UN SERVICIO PERSONAL SUBORDINADO **
noisily di _newline _col(04) in g "{bf:SUPUESTO: " in y "Los ingresos reportados por el trabajo subordinado son netos de las retenciones de ISR a asalariados.}"

* b. Sueldos, Salarios o Jornal *
g double ing_ss = ing_anual if clave == "P001" | clave == "P011" | clave == "P014" | clave == "P018"
g double p001 = ing_anual if clave == "P001"
g double p011 = ing_anual if clave == "p011"
g double p014 = ing_anual if clave == "p014"
g double p018 = ing_anual if clave == "p018"

* c. Destajo *
g double ing_desta = ing_anual if clave == "P002"

* d. Comisiones y Propinas *
g double ing_prop = ing_anual if clave == "P003"

* e. Horas extras *
g double ing_horas = ing_anual if clave == "P004"

* f. Incentivos, gratificaciones o premios *
g double ing_grati = ing_anual if clave == "P005"

* g. Primas vacacionales y otras prestaciones en efectivo *
g double ing_prima = ing_anual if clave == "P007"

* h. Reparto de utilidades *
g double ing_util = ing_anual if clave == "P008" | clave == "P015"

* i. Ganancias *
g double ing_ganan = ing_anual if clave == "P012" | clave == "P019"

* j. Aguinaldo *
g double ing_agui = ing_anual if clave == "P009" | clave == "P016"

* k. Otros *
g double ing_otros = ing_anual if clave == "P006" | clave == "P013" | clave == "P020" //| clave == "P033"

* l. Otros trabajos *
g double ing_trabajos = ing_anual if clave == "P021" | clave == "P022" | clave == "P049"

* m. Indemnizaciones *
g double ing_indemn = ing_anual if clave == "P035"

* n. Indemnizaciones 2 *
g double ing_indemn2 = ing_anual if clave == "P036"

* o. Indeminizaciones 3 *
g double ing_indemn3 = ing_anual if clave == "P034"

* p. Jubilaciones y ahorros *
g double ing_jubila = ing_anual if clave == "P032" //| clave == "P033"

* q. Seguros de Vida *
g double ing_segvida = ing_anual if clave == "P065"



************************************************************************************
** 1.3 Capitulo II. DE LOS INGRESOS POR ACTIVIDADES EMPRESARIALES Y PROFESIONALES **
noisily di _newline _col(04) in g "{bf:SUPUESTO: " in y "Los dem${a}s ingresos se reportan de manera bruta.}"
* r. Honorarios *
g double ing_honor = 0
replace ing_honor = ing_anual if clave == "P070" | clave == "P077"

* s. Actividades empresariales *
g double ing_empre = 0
replace ing_empre = ing_anual if clave == "P068" | clave == "P069" | clave == "P075" | clave == "P076" ///
	/*| clave == "P071" | clave == "P072" | clave == "P073" | clave == "P074" ///
	| clave == "P078" | clave == "P079" | clave == "P080" | clave == "P081"*/



*****************************************************************************************************************************
** 1.4 Capitulo III. DE LOS INGRESOS POR ARRENDAMIENTO Y EN GENERAL POR OTORGAR EL USO O GOCE TEMPORAL DE BIENES INMUEBLES **
* t. Renta de bienes inmuebles *
g double ing_rent = ing_anual if clave == "P023" | clave == "P024" | clave == "P025"



****************************************************************
** 1.5 Capitulo IV. DE LOS INGRESOS POR ENAJENACION DE BIENES **
* u. Enajenaciones diversas *
g double ing_enaje = ing_anual if clave == "P054" | clave == "P055" | clave == "P056" | clave == "P060"

* v. Enajenacion casa habitacion *
g double ing_enajecasa = ing_anual if clave == "P059"

* w. Enajenacion de bienes muebles *
g double ing_enajem = ing_anual if clave == "P061" | clave == "P062" | clave == "P063"



***************************************************************
** 1.6 Capitulo V. DE LOS INGRESOS POR ADQUISICION DE BIENES **
* x. Donaciones *
g double ing_dona = ing_anual if clave == "P039" | clave == "P040"



****************************************************
** 1.7 Capitulo VI. DE LOS INGRESOS POR INTERESES **
* y. Intereses *
g double ing_intereses = ing_anual if clave == "P026" | clave == "P027" | clave == "P028" | clave == "P029" | clave == "P031"



*******************************************************************
** 1.8 Capitulo VII. DE LOS INGRESOS POR LA OBTENCION DE PREMIOS **
* z. Loterias *
g double ing_loter = ing_anual if clave == "P058"



************************************************************************************************************************
** 1.9 Capitulo VIII. DE LOS INGRESOS POR DIVIDENDOS Y EN GENERAL POR LAS GANANCIAS DISBRIBUIDAS POR PERSONAS MORALES **
* aa. Acciones *
g double ing_acc = ing_anual if clave == "P050"



********************************************************************************
** 1.10 Capitulo IX. DE LOS DEMAS INGRESOS QUE OBTENGAN LAS PERSONAS FISICIAS **
* ab. `Derechos' de autor *
g double ing_autor = ing_anual if clave == "P030"

* ac. Remesas *
g double ing_remesas = ing_anual if clave == "P041"

* ad. Ingreso por trabajo de menores de 12 anios *
g double ing_trabmenor = ing_anual if clave == "P067"

* ae. Ingreso por prestamos *
g double ing_prest = ing_anual if clave == "P052" | clave == "P053" | clave == "P064"

* af. Ingreso por otras percepciones de capital *
g double ing_otrocap = ing_anual if  clave == "P066"

* ag. Retiros de ahorro *
g double ing_ahorro = ing_anual if clave == "P051"

* ah. Prestaciones de Seguridad Social y Prevision Social *
g double ing_benef = ing_anual if clave == "P037" | clave == "P038" | (clave >= "P042" & clave <= "P048")

* ai. Herencias o Legados *
g double ing_heren = ing_anual if clave == "P057"

* aj. PAM *
g double ing_PAM = ing_anual if clave == "P044"





******************************
*** 2. IDENTIFY EXEMPTIONS ***
******************************
collapse (sum) ing_* p0*, by(`hogar' numren id_trabajo sm factor_hog)
sort `hogar' numren

* Ingreso total *
egen ing_exclusivo = rsum(ing_agri - ing_autor)
replace ing_exclusivo = ing_exclusivo - ing_benef - ing_dona // Exclusiones



****************************************
** Titulo II. De las Personas Morales **
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
parrafo de este articulo hasta por los montos en el establecidos.

1. Persona Fisica
1.1. Zona A 40SMGAGC*365 = 40*67.29*365 = 982,434
1.2. Zona B 40SMGAGC*365 = 40*63.77*365 = 931,042

2. 423 SMGAGC
2.1. Zona A 423SMGAGC*365 = 423*67.29*365 = 10,389,239.55
2.2. Zona B 423SMGAGC*365 = 423*63.77*365 = 9,845,769.15   */

* a. Agricultura *
*noisily di _newline _col(04) in g "{bf:SUPUESTO: " in y "Se dedican exclusivamente a actividades agricolas si es mayor al 90%.}"
g agri = ing_agri/ing_exclusivo > .9 & ing_agri > 0			// Dummy exclusivamente agricola
g double exen_agri = min(40*sm*365,ing_agri) if agri == 0		// General
replace exen_agri = min(423*sm*365,ing_agri) if agri == 1		// Exclusivamente agricola



***************************************
** Titulo IV De las Personas Fisicas **
** Capitulo I. DE LOS INGRESOS POR SALARIOS Y EN GENERAL POR LA PRESTACION DE UN SERVICIO PERSONAL SUBORDINADO **
/* Articulo 94. Se consideran ingresos por la prestacion de un servicio personal subordinado, los salarios y demas 
prestaciones que deriven de una relacion laboral, incluyendo la participacion de los trabajadores en las utilidades 
de las empresas y las prestaciones percibidas como consecuencia de la terminacion de la relacion laboral. (...) */
* b. Sueldos, Salarios o Jornal *
g double exen_ss = min(0,ing_ss)

* c. Destajo *
g double exen_desta = min(0,ing_desta)

* d. Comisiones y Propinas *
g double exen_prop = min(0,ing_prop)

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
* e. Horas extras *
g tsm = p001/365/sm if p001 > 0
g double exen_horas = min(.5*ing_horas,5*sm*365,ing_horas)
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
* f. Incentivos, gratificaciones o premios *
g double exen_grati = min(30*sm,ing_grati)

* g. Primas vacacionales y otras prestaciones en efectivo *
g double exen_prima = min(15*sm,ing_prima)

* h. Reparto de utilidades *
g double exen_util = min(15*sm,ing_util)

* h.bis Ganancias *
g double exen_ganan = min(0,ing_ganan)

* i. Aguinaldo *
g double exen_agui = min(30*sm,ing_agui)

* j. Otros *
g double exen_otros = min(0,ing_otros)

* l. Otros trabajos *
g double exen_trabajos = min(0,ing_trabajos)

/* Articulo 93. No se pagara el impuesto sobre la renta por la obtencion de los siguientes ingresos: (...)
III. Las indemnizaciones por riesgos de trabajo o enfermedades, que se concedan de acuerdo con las leyes, por 
contratos colectivos de trabajo o por contratos Ley. */
*noisily di _newline _col(04) in g "{bf:SUPUESTO: " in y "Las indemnizaciones se conceden de acuerdo con las leyes.}"
* m. Indemnizaciones *
g double exen_indemn = ing_indemn

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
* n. Indemnizaciones 2 *
egen double salario = sum(p001), by(`hogar' numren)
g double exen_indemn2 = min(90*sm*round(ing_indemn2/salario,1),ing_indemn2)
*replace exen_indemn2 = exen_indemn2 - salario/12 if exen_indemn2 - salario/12 > 0

/* Articulo 93. No se pagara el impuesto sobre la renta por la obtencion de los siguientes ingresos: (...)
XXV. Las indemnizaciones por danios que no excedan al valor de mercado del bien de que se trate. Por el excedente 
se pagara el impuesto en los terminos de este Titulo. */
*noisily di _newline _col(04) in g "{bf:SUPUESTO: " in y "Las indemnizaciones por da${ni}os no se exceden al valor de mercado.}"
* o. Indemnizaciones 3 *
g double exen_indemn3 = ing_indemn3

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
* p. Jubilaciones y ahorros *
g double exen_jubila = min(9*sm*365,ing_jubila)

/* VIII. Los provenientes de cajas de ahorro de trabajadores y de fondos de ahorro establecidos por las empresas 
para sus trabajadores cuando reunan los requisitos de deducibilidad del Titulo II de esta Ley o, en su caso, del 
presente Titulo.*/
* q. Retiros de ahorro *
g double exen_ahorro = ing_ahorro

/* Articulo 93. No se pagara el impuesto sobre la renta por la obtencion de los siguientes ingresos: (...)
XXII.Los que se reciban por herencia o legado. */
* r. Herencias o Legados *
g double exen_heren = ing_heren

/* Articulo 93. No se pagara el impuesto sobre la renta por la obtencion de los siguientes ingresos: (...)
VII. Las prestaciones de seguridad social que otorguen las instituciones publicas.
VIII. Los percibidos con motivo de subsidios por incapacidad, becas educacionales para los trabajadores o sus hijos,
guarderias infantiles, actividades culturales y deportivas, y otras prestaciones de prevision social, de naturaleza 
analoga, que se concedan de manera general, de acuerdo con las leyes o por contratos de trabajo.*/
* s. Prestaciones de Seguridad Social y Prevision Social *
g double exen_benef = ing_benef

/* Articulo 93. No se pagara el impuesto sobre la renta por la obtencion de los siguientes ingresos: (...)
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
* t. Seguros de Vida *
g double exen_segvida = ing_segvida



********************************************************************************
** Capitulo II. DE LOS INGRESOS POR ACTIVIDADES EMPRESARIALES Y PROFESIONALES **
/* Articulo 100. (...)
Para efectos de este Capitulo se consideran:
	I. Ingresos por actividades empresariales, los provenientes de la realizacion de actividades comerciales, 
	industriales, agricolas, ganaderas, de pesca o silvicolas.
	II. Ingresos por la prestacion de un servicio profesional, las remuneraciones que deriven de un servicio 
	personal independiente y cuyos ingresos no esten considerados en el Capitulo I de este Titulo. 

Articulo 109. Los contribuyentes a que se refiere esta Seccion, deberan calcular el impuesto del ejercicio a su 
cargo en los terminos del articulo 152 de esta Ley. (...) */
noisily di _newline _col(04) in g "{bf:SUPUESTO: " in y "Se exentan el " %5.2fc (1-290533/475667)*100 "% de los servicios profesionales por remuneraciones (Censo Econ${o}mico 2014).}"
* u. Honorarios *
*g double exen_honor = min((1-47809270435/102879038489)*ing_honor,ing_honor)
g double exen_honor = min((1-290533/475667)*ing_honor,ing_honor)

* v. Actividades empresariales *
*g double exen_empre = min((1-47809270435/102879038489)*ing_empre,ing_empre)
g double exen_empre = min((1-290533/475667)*ing_empre,ing_empre)



*************************************************************************************************************************
** Capitulo III. DE LOS INGRESOS POR ARRENDAMIENTO Y EN GENERAL POR OTORGAR EL USO O GOCE TEMPORAL DE BIENES INMUEBLES **
/* Articulo 115. Las personas que obtengan ingresos por bys a que se refiere este Capitulo, podran efectuar 
las siguientes deducciones:

(...)

(Segundo Parrafo) Los contribuyentes que otorguen el uso o goce temporal de bienes inmuebles podran optar por deducir 
el 35% de los ingresos a que se refiere este Capitulo, en substitutcion de las deducciones a que este articulo se 
refiere. Quienes ejercen esta opcion podran deducir, ademas, el monto de las erogaciones por by del impuesto 
predial de dichos inmuebles correspondiente al anio de calendario o al periodo durante el cual se obtuvieron los 
ingresos en el ejercicio segun corresponda.*/

noisily di _newline _col(04) in g "{bf:SUPUESTO: " in y "Todos los ingresos por rentas optan por la opci${o}n de deducir el 35%.}"
*noisily di _newline _col(04) in g "{bf:SUPUESTO: " in y "Se supone un 2% del predial del total de los ingresos por rentas.}"
* w. Rentas de bienes inmuebles *
g double exen_rent = .35*ing_rent



************************************************************
** Capitulo IV. DE LOS INGRESOS POR ENAJENACION DE BIENES **
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

*noisily di _newline _col(04) in g "{bf:SUPUESTO: " in y "S${o}lo se considera esta opci${o}n para calcular el impuesto.}"
* x. Enajenacion de bienes *
g double exen_enaje = min(0,ing_enaje)

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

local limudis = 700000
* y. Enajenacion casa habitacion *
g double exen_enajecasa = min(`limudis'*`udis',ing_enajecasa)

/* b) Bienes muebles, distintos de las acciones, de las partes sociales, de los titulos de valor y de las 
inversiones del contribuyente, cuando en un anio de calendario la diferencia entre el total de las enajenaciones 
y el costo comprobado de la adquisicion de los bienes enajeandos, no exceda de tres veces el salario minimo general 
del area geografica del contribuyente elevado al anio. Por la utilidad que exceda se pagara el impuesto en los
terminos de este Titulo. */
*noisily di _newline _col(04) in g "{bf:SUPUESTO: " in y "Para la enajenaci${o}n de bienes muebles, nunca se sobrepasa el valor de adquisici${o}n de los bienes.}"
* z. Enajenacion de bienes muebles *
g double exen_enajem = min(3*sm*365,ing_enajem)


***********************************************************
** Capitulo V. DE LOS INGRESOS POR ADQUISICION DE BIENES **
/* Articulo 130. Se consideran ingresos por adquisicion de bienes:
I. La donacion (...)

Articulo 93. No se pagara el impuesto sobre la renta por la obtencion de los siguientes ingresos: (...)
XXIII. Los donativos en los siguientes casos: (...)
c) Los demas donativos, siempre que el valor total de los recibidos en un anio de calendario no exceda de tres veces 
el salario minimo general del area geografica del contribuyente elevado al anio. Por el excedente se pagara impuesto 
en los termino de este Titulo. */
* A. Donaciones *
g double exen_dona = min(3*sm*365,ing_dona)


************************************************
** Capitulo VI. DE LOS INGRESOS POR INTERESES **
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

LIF 2014. Art. 21. Durente el ejercicio fiscal de 2014 la tasa de retencion anual a que se refieren los articulos 54 y 135 de la 
LISR sera del 0.60%. 

RMF 2015.
I.3.5.2. Las instituciones que componen el sistema financiero podran optar por efectuar la retencion a que se refiere 
el parrafo anterior, multiplicando la tasa de 0.00167% por el promedio diario de la inversion que de lugar al pago 
de los intereses, el resultado obtenido se multiplcara por el numero de dias a que corresponda a la inversion de 
que se trate.*/
* B. Intereses *
g double exen_intereses = min(0,ing_intereses)


***************************************************************
** Capitulo VII. DE LOS INGRESOS POR LA OBTENCION DE PREMIOS **
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
*noisily di _newline _col(04) in g "{bf:SUPUESTO: " in y "Las persons f${i}sicas deber${a}n acumular los ingreso por premios a sus dem${a}s ingresos.}"
* C. Loterias *
g double exen_loter = min(0,ing_loter)


********************************************************************************************************************
** Capitulo VIII. DE LOS INGRESOS POR DIVIDENDOS Y EN GENERAL POR LAS GANANCIAS DISTRIBUIDAS POR PERSONAS MORALES **
/* Articulo 140. Las personas fisicas deberan acumular a sus demas ingresos, los percibidos por dividendos o 
utilidades. (...) */
* D. Acciones *
g double exen_acc = min(0,ing_acc)


***************************************************************************
** Capitulo IX. DE LOS DEMAS INGRESOS QUE OBTENGAN LAS PERSONAS FISICIAS **
/* Articulo 93. No se pagara el impuesto sobre la renta por la obtencion de los siguientes ingresos: (...)
XXIX. Lo que se obtenga, hasta el equivalente de veinte salarios minimos generales del area geografica del 
contribuyente elevados al anio, por permitir a terceros la publicacion de obras escritas de su creacion en libros, 
periodicos o revistas, o bien, la reproduccion en serie de grabaciones de obras musicales de su creacion (...) 
Por el excedente se pagara el impuesto en los terminos de este Titulo.

Articulo 142. Se entiende que, entre otros, son ingresos en los terminos de este Capitulo los siguientes:
XI. Los que perciban por derechos de autor, personas distintas a este. */
* E. `Derechos' de autor *
g double exen_autor = min(20*sm*365,ing_autor)

* F. Remesas *
g double exen_remesas = ing_remesas

* G. Ingreso por trabajo de menores de 12 anios *
g double exen_trabmenor = ing_trabmenor

* H. Ingreso por prestamos *
g double exen_prest = ing_prest

* I. Ingreso por otras percepciones de capital *
g double exen_otrocap = ing_otrocap





******************
*** 5. TOTALES ***
******************

* Titulo II, Capitulo IV *
egen double ing_t2_cap8 = rsum(ing_agri)
egen double exen_t2_cap8 = rsum(exen_agri)

* Titulo IV, Capitulo I *
egen double ing_t4_cap1 = rsum(ing_ss ing_desta ing_prop ing_horas ing_grati ing_prima ///
	ing_util ing_agui ing_otros ing_trabajos ing_indemn ing_indemn2 ing_indemn3 ing_jubila ///
	ing_segvida)
egen double exen_t4_cap1 = rsum(exen_ss exen_desta exen_prop exen_horas exen_grati exen_prima ///
	exen_util exen_agui exen_otros exen_trabajos exen_indemn exen_indemn2 exen_indemn3 exen_jubila ///
	exen_segvida)
egen double ing_t4_cap1_nosubsidio = rsum(ing_desta ing_prop ing_horas ing_grati ing_prima ///
	ing_util ing_agui ing_otros ing_trabajos ing_indemn ing_indemn2 ing_indemn3 ing_jubila ///
	ing_segvida)

* Titulo IV, Capitulo II *
egen double ing_t4_cap2 = rsum(ing_honor ing_empre)
egen double exen_t4_cap2 = rsum(exen_honor exen_empre)

* Titulo IV, Capitulo III *
egen double ing_t4_cap3 = rsum(ing_rent)
egen double exen_t4_cap3 = rsum(exen_rent)

* Titulo IV, Capitulo IV *
egen double ing_t4_cap4 = rsum(ing_enajecasa ing_enajem ing_enaje)
egen double exen_t4_cap4 = rsum(exen_enajecasa exen_enajem exen_enaje)

* Titulo IV, Capitulo V *
egen double ing_t4_cap5 = rsum(ing_dona)
egen double exen_t4_cap5 = rsum(exen_dona)

* Titulo IV, Capitulo VI *
egen double ing_t4_cap6 = rsum(ing_intereses)
egen double exen_t4_cap6 = rsum(exen_intereses)

* Titulo IV, Capitulo VII *
egen double ing_t4_cap7 = rsum(ing_loter)
egen double exen_t4_cap7 = rsum(exen_loter)

* Titulo IV, Capitulo VIII *
egen double ing_t4_cap8 = rsum(ing_acc ing_ganan)
egen double exen_t4_cap8 = rsum(exen_acc ing_ganan)

* Titulo IV, Capitulo IX *
egen double ing_t4_cap9 = rsum(ing_autor ing_remesas ing_trabmenor ing_prest ing_otrocap ///
	ing_ahorro ing_heren ing_benef)
egen double exen_t4_cap9 = rsum(exen_autor exen_remesas exen_trabmenor exen_prest exen_otrocap ///
	exen_ahorro exen_heren exen_benef)





************************************
*** 6. IDENTIFICAR LA FORMALIDAD ***
************************************

* Merges *
merge m:1 (`hogar' numren id_trabajo) using "`c(sysdir_personal)'../basesCIEP/INEGI/`enigh'/`enighanio'/trabajos.dta", nogen ///
	keepusing(htrab pres_* pago scian sinco subor)
g trabajos = 1 if id_trabajo != ""
merge m:1 (`hogar' numren) using "`c(sysdir_personal)'../basesCIEP/INEGI/`enigh'/`enighanio'/poblacion.dta", nogen ///
	keepusing(sexo edad trabajo_mp inscr_* inst_* atemed segpop)
merge m:1 (`hogar') using "`c(sysdir_personal)'../basesCIEP/INEGI/`enigh'/`enighanio'/concentrado.dta", nogen update replace ///
	keepusing(factor_hog tot_integ smg ubica_geo estim_alqu)
merge m:1 (folioviv) using "`c(sysdir_personal)'../basesCIEP/INEGI/`enigh'/`enighanio'/vivienda.dta", nogen ///
	keepusing(tenencia renta)
merge m:1 (`hogar' numren) using "`c(sysdir_personal)'../basesCIEP/SIM/`enighanio'/deducciones.dta", nogen keepus(deduc_isr)

noisily di _newline _col(04) in g "{bf:SUPUESTO: " in y "Las deducciones personales son beneficios para el jefe del hogar.}"
tempvar tag tag2
duplicates tag `hogar' numren, g(`tag')
bysort `hogar' numren: g `tag2' = sum(`tag')
replace deduc_isr = 0 if numren != "01" | `tag2' > 1 | deduc_isr == .

replace sm = round(smg/90,.01)							// Salario minimo diario del area geografica del contribuyente

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

noisily di _newline _col(04) in g "{bf:SUPUESTO: " in y "Los derechohabientes del IMSS, ISSSTE, ISSSTE Estatal, PEMEX, Defensa, Marina o aqu${e}llos con prestaciones sociales son el Sector Formal de la econom${i}a y quienes pagan sus impuestos.}"
* IMSS *
g byte formal = inst_1 == "1"
g byte formal2 = inst_1 == "1" & (inscr_1 == "1" | inscr_6 == "6")

* ISSSTE *
replace formal = 2 if inst_2 == "2"
replace formal2 = 2 if inst_2 == "2" & (inscr_1 == "1" /*| inscr_2 == "2" | inscr_6 == "6"*/)

* ISSSTE Estatal *
replace formal = 5 if inst_3 == "3"
replace formal2 = 5 if inst_3 == "3" & (inscr_1 == "1" /*| inscr_2 == "2" | inscr_6 == "6"*/)

* PEMEX *
replace formal = 3 if inst_4 == "4"
replace formal2 = 3 if inst_4 == "4" & (inscr_1 == "1" /*| inscr_2 == "2" | inscr_6 == "6"*/)

* Institucion medica otro *
replace formal = 4 if inst_5 == "5"
replace formal2 = 4 if inst_5 == "5" & (inscr_1 == "1" | inscr_6 == "6")

* Independiente *
replace formal = 6 if formal == 0 & (pres_1 == "01" | pres_2 == "02" | pres_3 == "03" | pres_4 == "04" | pres_5 == "05" ///
	| pres_6 == "06" | pres_7 == "07" | pres_8 == "08" | pres_9 == "09" | pres_10 == "10" | pres_11 == "11" ///
	| pres_12 == "12" | pres_13 == "13" | pres_14 == "14" | pres_15 == "15" | pres_16 == "16" | pres_17 == "17" ///
	| pres_18 == "18" | pres_19 == "19")
replace formal2 = 6 if formal2 == 0 & (pres_1 == "01" | pres_2 == "02" | pres_3 == "03" | pres_4 == "04" | pres_5 == "05" ///
	| pres_6 == "06" | pres_7 == "07" | pres_8 == "08" | pres_9 == "09" | pres_10 == "10" | pres_11 == "11" ///
	| pres_12 == "12" | pres_13 == "13" | pres_14 == "14" | pres_15 == "15" | pres_16 == "16" | pres_17 == "17" ///
	| pres_18 == "18" | pres_19 == "19") //& (inscr_1 == "1")

* Formal max *
noisily di _newline _col(04) in g "{bf:SUPUESTO: " in y "Si se paga impuestos en el trabajo principal, tambi${e}n se paga en el trabajo secundario.}"
tempvar formal_max
egen `formal_max' = max(formal), by(`hogar' numren)
replace formal = `formal_max'

* Formal dummy *
g formal_dummy = formal != 0

* Labels *
label define formalidad 1 "IMSS" 2 "ISSSTE" 3 "Pemex" 4 "Otro" 5 "ISSSTE estatal" 6 "Independiente" 0 "Informal"
label values formal formalidad
label values formal2 formalidad

label define formalidad_dummy 1 "Formal" 0 "Informal"
label values formal_dummy formalidad_dummy

/* Segun el SAT, habia 29,855,002 de asalariados en Diciembre de 2015 */
noisily di _newline(2) _col(04) in g "{bf:Paso 0: Informaci${o}n inicial}"

noisily di _newline _col(04) in g "{bf:0.1. Trabajos asalariados formales}"
noisily table formal2 [fw=factor_hog] if formal2 != 0, format(%12.0fc) row

noisily di _newline _col(04) in g "{bf:0.2. Personas formales}"
noisily table formal [fw=factor_hog] if formal != 0, format(%12.0fc) row





*************
** Totales **
egen double ing_total = rsum(ing_agri ///
	ing_ss ing_desta ing_prop ing_horas ing_grati ing_prima ///
	ing_jubila ing_agui ing_otros ing_trabajos ///
	ing_trabmenor ing_honor ing_empre ///
	ing_util ing_ganan ing_indemn ing_indemn2 ing_indemn3 ///
	ing_segvida ///
	ing_rent ///
	ing_enajecasa ing_enajem ing_enaje ///
	ing_intereses ///
	ing_dona ///
	ing_loter ///
	ing_acc ///
	ing_autor ing_remesas ing_prest ing_otrocap ing_ahorro ing_heren ing_benef)			// 35
egen double exen_total = rsum(exen_agri ///
	exen_ss exen_desta exen_prop exen_horas exen_grati exen_prima ///
	exen_jubila exen_agui exen_otros exen_trabajos ///
	exen_trabmenor exen_honor exen_empre ///
	exen_util exen_ganan exen_indemn exen_indemn2 exen_indemn3 ///
	exen_segvida ///
	exen_rent ///
	exen_enajecasa exen_enajem exen_enaje ///
	exen_intereses ///
	exen_dona ///
	exen_loter ///
	exen_acc ///
	exen_autor exen_remesas exen_prest exen_otrocap exen_ahorro exen_heren exen_benef)



*************
** Sueldos **
egen double ing_sueldos = rsum(ing_ss ing_desta ing_prop ing_horas ing_grati ing_prima ///
	ing_jubila ing_agui ing_otros ing_trabajos ing_trabmenor)					// 11
egen double exen_sueldos = rsum(exen_ss exen_desta exen_prop exen_horas exen_grati exen_prima ///
	exen_jubila exen_agui exen_otros exen_trabajos exen_trabmenor)



***********
** Mixto **
egen double ing_mixto = rsum(ing_agri ing_honor ing_empre)						// 3
egen double exen_mixto = rsum(exen_agri exen_honor exen_empre)

g double ing_mixtoL = ing_mixto*2/3
g double exen_mixtoL = exen_mixto*2/3

g double ing_mixtoK = ing_mixto*1/3
g double exen_mixtoK = exen_mixto*1/3



*************
** Laboral **
egen double ing_laboral = rsum(ing_sueldos ing_mixtoL)
egen double exen_laboral = rsum(exen_sueldos exen_mixtoL)


*************
** Capital **

* Renta de la vivienda *
noisily di _newline _col(04) in g "{bf:SUPUESTO: " in y "La renta por la vivienda y el alquiler imputado son pagados por el jefe del hogar.}"
replace renta = 0 if renta == . | numren != "01" | `tag2' > 1
replace renta = renta*12

* Alquiler imputado *
rename estim_alqu ing_estim_alqu
replace ing_estim_alqu = 0 if numren != "01"

* Alquileres *
noisily di _newline _col(04) in g "{bf:O.3.1. Renta e ingresos por alquileres}"
noisily tabstat renta ing_rent [aw=factor_hog], stat(sum) f(%20.0fc) by(formal_dummy) save
tempname RENTA
matrix `RENTA' = r(StatTotal)

replace renta = renta*(`SNAAlojamiento'-`SNAExBOpHog')/`RENTA'[1,1]
replace ing_rent = ing_rent*(`SNAAlquiler'-`SNAExBOpHog')/`RENTA'[1,2]
replace exen_rent = exen_rent*(`SNAAlquiler'-`SNAExBOpHog')/`RENTA'[1,2]

noisily di _newline _col(04) in g "{bf:0.3.2. Renta e ingresos por alquileres (escalado)}"
noisily tabstat renta ing_rent [aw=factor_hog], stat(sum) f(%20.0fc) by(formal_dummy) save


* Activdad empresarial y profesional *
noisily di _newline _col(04) in g "{bf:O.3.3. Actividad empresarial y profesional}"
noisily tabstat ing_t4_cap2 exen_t4_cap2 [aw=factor_hog], stat(sum) f(%20.0fc) by(formal_dummy) save
tempname EMPRE
matrix `EMPRE' = r(StatTotal)

noisily di _newline _col(04) in g "{bf:SUPUESTO: " in y "El " %5.2fc (1-106302/581969)*100 "% de los servicios profesionales provienen de las personas f${i}sicas (Censo Econ${o}mico 2014).}"
replace ing_t4_cap2 = ing_t4_cap2*(`ServProf'+`ConsMedi'+`ConsDent'+`ConsOtro'+`EnfeDomi')*(1-106302/581969)/`EMPRE'[1,1]
replace exen_t4_cap2 = ing_t4_cap2*(1-290533/475667)

noisily di _newline _col(04) in g "{bf:O.3.4. Actividad empresarial y profesional (escalado)}"
noisily tabstat ing_t4_cap2 exen_t4_cap2 [aw=factor_hog], stat(sum) f(%20.0fc) by(formal_dummy) save




***************
*** Totales ***
***************
replace ing_total = 0 if ing_total == .
replace ing_total = ing_total + ing_estim_alqu

egen double ing_capital = rsum(ing_util ing_ganan ing_indemn ing_indemn2 ing_indemn3 ///
	ing_segvida ///
	ing_rent ///
	ing_enajecasa ing_enajem ing_enaje ///
	ing_intereses ///
	ing_dona ///
	ing_loter ///
	ing_acc ///
	ing_autor /*ing_remesas ing_prest ing_otrocap ing_ahorro*/ ing_heren /*ing_benef*/)		// 21
egen double exen_capital = rsum(exen_util exen_ganan exen_indemn exen_indemn2 exen_indemn3 ///
	exen_segvida ///
	exen_rent ///
	exen_enajecasa exen_enajem exen_enaje ///
	exen_intereses ///
	exen_dona ///
	exen_loter ///
	exen_acc ///
	exen_autor /*exen_remesas exen_prest exen_otrocap exen_ahorro*/ exen_heren /*exen_benef*/)

* Gini's de ingresos netos *
foreach k of varlist ing_total ing_sueldos ing_mixto ing_capital ing_estim_alqu ing_laboral ing_mixto* {
	Gini `k', hogar(`hogar') individuo(numren) factor(factor_hog)
	local gini_`k' = r(gini_`k')
}

* Results *
tabstat ing_sueldos ing_mixto ing_total ing_estim_alqu ing_capital [aw=factor_hog], stat(sum) f(%25.0fc) save
tempname AnnInc
matrix `AnnInc' = r(StatTotal)


// ENIGH As Is //
noisily di _newline _col(04) in g "{bf:0.4. Ingresos " ///
	_col(44) in g "(Gini)" ///
	_col(57) in g %7s "`enigh'" ///
	_col(66) %7s "SCN" in g ///
	_col(77) %7s "Diferencia" "}"
noisily di ///
	_col(04) in g "(+) Sueldos y salarios" ///
	_col(44) in y "(" %5.3fc `gini_ing_sueldos' ")" ///
	_col(57) in y %7.3fc `AnnInc'[1,1]/`PIBSCN'*100 ///
	_col(66) in y %7.3fc `RemSal'/`PIBSCN'*100 ///
	_col(77) in y %7.1fc (`AnnInc'[1,1]/`RemSal'-1)*100 "%"
noisily di ///
	_col(04) in g "(+) Seguridad social (empleadores)" ///
	_col(44) in y "(" %5.3fc 0 ")" ///
	_col(57) in y %7.3fc 0 ///
	_col(66) in y %7.3fc `SSEmpleadores'/`PIBSCN'*100 ///
	_col(77) in y %7.1fc (0/`SSEmpleadores'-1)*100 "%"
noisily di ///
	_col(04) in g "(+) Seguridad social (imputada)" ///
	_col(44) in y "(" %5.3fc 0 ")" ///
	_col(57) in y %7.3fc 0 ///
	_col(66) in y %7.3fc `SSImputada'/`PIBSCN'*100 ///
	_col(77) in y %7.1fc (0/`SSImputada'-1)*100 "%"
noisily di ///
	_col(04) in g "(+) Ingreso mixto (laboral)" ///
	_col(44) in y "(" %5.3fc `gini_ing_mixtoL' ")" ///
	_col(57) in y %7.3fc `AnnInc'[1,2]*2/3/`PIBSCN'*100 ///
	_col(66) in y %7.3fc `MixL'/`PIBSCN'*100 ///
	_col(77) in y %7.1fc (`AnnInc'[1,2]*2/3/`MixL'-1)*100 "%"
noisily di in g _dup(84) "-"
noisily di ///
	_col(04) in g "{bf:(=) Ingreso laboral" ///
	_col(44) in y "(" %5.3fc `gini_ing_laboral' ")" ///
	_col(57) in y %7.3fc (`AnnInc'[1,1]+`AnnInc'[1,2]*2/3)/`PIBSCN'*100 ///
	_col(66) in y %7.3fc (`RemSal'+`SSEmpleadores'+`MixL')/`PIBSCN'*100 ///
	_col(77) in y %7.1fc ((`AnnInc'[1,1]+`AnnInc'[1,2]*2/3)/(`RemSal'+`SSEmpleadores'+`MixL')-1)*100 "%}"
noisily di ///
	_col(04) in g "(+) Sociedades e ISFLSH" ///
	_col(44) in y "(" %5.3fc `gini_ing_capital' ")" ///
	_col(57) in y %7.3fc `AnnInc'[1,5]/`PIBSCN'*100 ///
	_col(66) in y %7.3fc `ExNOpSoc'/`PIBSCN'*100 ///
	_col(77) in y %7.1fc (`AnnInc'[1,5]/`ExNOpSoc'-1)*100 "%"
noisily di ///
	_col(04) in g "(+) Alquiler imputado" ///
	_col(44) in y "(" %5.3fc `gini_ing_estim_alqu' ")" ///
	_col(57) in y %7.3fc `AnnInc'[1,4]/`PIBSCN'*100 ///
	_col(66) in y %7.3fc `ExNOpHog'/`PIBSCN'*100 ///
	_col(77) in y %7.1fc (`AnnInc'[1,4]/`ExNOpHog'-1)*100 "%"
noisily di ///
	_col(04) in g "(+) Ingreso mixto (capital)" ///
	_col(44) in y "(" %5.3fc `gini_ing_mixtoK' ")" ///
	_col(57) in y %7.3fc (`AnnInc'[1,2]*1/3)/`PIBSCN'*100 ///
	_col(66) in y %7.3fc `MixKN'/`PIBSCN'*100  ///
	_col(77) in y %7.1fc ((`AnnInc'[1,2]*1/3)/`MixKN'-1)*100 "%"
noisily di in g _dup(84) "-"
noisily di ///
	_col(04) in g "{bf:(=) Ingreso nacional" ///
	_col(44) in y "(" %5.3fc `gini_ing_total' ")" ///
	_col(57) in y %7.3fc `AnnInc'[1,3]/`PIBSCN'*100 ///
	_col(66) in y %7.3fc (`RemSal'+`SSEmpleadores'+`SSImputada'+`MixL'+`ExNOpSoc'+`ExNOpHog'+`MixKN')/`PIBSCN'*100 ///
	_col(77) in y %7.1fc (`AnnInc'[1,3]/(`RemSal'+`SSEmpleadores'+`SSImputada'+`MixL'+`ExNOpSoc'+`ExNOpHog'+`MixKN')-1)*100 "%}"





********************************************************************************
*** 7. RECUPERAR LOS INGRESOS BRUTOS DE LOS INGRESOS POR TRABAJO SUBORDINADO ***
********************************************************************************
/* IMSS, tasas efectivas (Informe al ejecutivo federal y al congreos de la union 
	la situacion financiera y los riesgos del IMSS, Anexo A, Cuadro A.4 , 2017) */
local TriesgoP = 1.884			// Resgos de trabajo, patron

local TgmasgT = 0.436			// Asegurados, trabajador
local TgmasgP = 5.934			// Asegurados, patron
local TgmasgF = 3.396			// Asegurados, federacion

local TgmpenT = 0.375			// Pensionados, trabajador
local TgmpenP = 1.050			// Pensionados, patron
local TgmpenF = 0.075			// Pensionados, federacion

local TinvyvidaT = 0.625		// Invalidez y vida, trabajador
local TinvyvidaP = 1.750		// Invalidez y vida, patron
local TinvyvidaF = 0.125		// Invalidez y vida, federacion

local TcestyvejT = 1.125		// Cesantia y vejez, trabajador
local TcestyvejP = 5.150		// Cesantia y vejez, patron
local TcestyvejF = 1.650		// Cesantia y vejez, federacion

local TguardP = 1.000			// Guarderias y prestaciones sociales, patron

local TcuotaSocIMSSF = 6.334		// Cuota social, federacion

* ISSSTE *
local TfondomedT = 2.750		// Salud trabajadores activos, trabajador
local TfondomedP = 7.375		// Salud trabajadores activos, patron
local TfondomedF = 3.090		// Salud trabajadores activos, federacion

local TpresperT = 0.625			// Invalidez y vida, trabajador
local TpresperP = 0.625			// Invalidez y vida, patron

local TservsocculT =  0.500		// Servicios sociales y culturales, trabajador
local TservsocculP = 0.500		// Servicios sociales y culturales, patron

local TsegriesgT = 0.000		// Riesgo de trabajo, trabajador
local TsegriesgP = 0.750		// Riesgo de trabajo, patron

local TpensjubT = 0.625			// Salud pensionados, trabajador
local TpensjubP = 0.720			// Salud pensionados, patron

local TadmingenT = 6.125		// Retiro, cesantia en edad avanzada y vejez, trabajador
local TadmingenP = 5.175		// Retiro, cesantia en edad avanzada y vejez, patron
local TadmingenF = 1.220		// Retiro, cesantia en edad avanzada y vejez, federacion

local TfvivT = 0.000			// Vivienda, trabajador
local TfvivP = 5.000			// Vivienda, patron

local TcuotaSocISSSTEF = 13.9		// Cuota social, federacion

* INFONAVIT *
local Tinfonavit = 5			// Infonavit



************************************
** 7.1. CUOTAS A LA SSEmpleadores **

* Salario Base de Cotizacion: IMSS *
g double sbc = ing_ss/360/`smdf' if (formal == 1 | formal == 3 | formal == 4 | formal == 6) & ing_ss > 0 & ing_ss != .
replace sbc = 25 if sbc > 25 & (formal == 1 | formal == 3 | formal == 4 | formal == 6) & ing_ss > 0 & ing_ss != .

* Sueldo Basico: ISSSTE *
replace sbc = ing_ss/360/`smdf' if (formal == 2 | formal == 5) & ing_ss > 0 & ing_ss != .
replace sbc = 10 if sbc > 10 & (formal == 2 | formal == 5) & ing_ss > 0 & ing_ss != .

* Ajustes *
replace sbc = 1 if sbc > 0 & sbc < 1 & (formal == 1 | formal == 6)
*replace sbc = floor(sbc) if formal != 1
*replace sbc = ceil(sbc) if formal == 1
replace sbc = sbc*`smdf'


* IMSS *
g double riesgoP = sbc*`TriesgoP'/100*360 if (formal == 1 | formal == 3 | formal == 4 | formal == 6)

g double gmasgT = sbc*`TgmasgT'/100*360 if (formal == 1 | formal == 3 | formal == 4 | formal == 6)
g double gmasgP = sbc*`TgmasgP'/100*360 if (formal == 1 | formal == 3 | formal == 4 | formal == 6)
g double gmasgF = sbc*`TgmasgF'/100*360 if (formal == 1 | formal == 3 | formal == 4 | formal == 6)

g double gmpenT = sbc*`TgmpenT'/100*360 if (formal == 1 | formal == 3 | formal == 4 | formal == 6)
g double gmpenP = sbc*`TgmpenP'/100*360 if (formal == 1 | formal == 3 | formal == 4 | formal == 6)
g double gmpenF = sbc*`TgmpenF'/100*360 if (formal == 1 | formal == 3 | formal == 4 | formal == 6)

g double invyvidaT = sbc*`TinvyvidaT'/100*360 if (formal == 1 | formal == 3 | formal == 4 | formal == 6)
g double invyvidaP = sbc*`TinvyvidaP'/100*360 if (formal == 1 | formal == 3 | formal == 4 | formal == 6)
g double invyvidaF = sbc*`TinvyvidaF'/100*360 if (formal == 1 | formal == 3 | formal == 4 | formal == 6)

g double guardP = sbc*`TguardP'/100*360 if (formal == 1 | formal == 3 | formal == 4 | formal == 6)

g double cestyvejT = sbc*`TcestyvejT'/100*360 if (formal == 1 | formal == 3 | formal == 4 | formal == 6)
g double cestyvejP = sbc*`TcestyvejP'/100*360 if (formal == 1 | formal == 3 | formal == 4 | formal == 6)
g double cestyvejF = sbc*`TcestyvejF'/100*360 if (formal == 1 | formal == 3 | formal == 4 | formal == 6)

g double cuotasocimssF = sbc*`TcuotaSocIMSSF'/100*360 if (formal == 1 | formal == 3 | formal == 4 | formal == 6) & sbc/`smdf' <= 15


* ISSSTE *
g double fondomedT = `TfondomedT'/100*sbc*360 if (formal == 2 | formal == 5)
g double fondomedP = `TfondomedP'/100*sbc*360 if (formal == 2 | formal == 5)
g double fondomedF = `TfondomedF'/100*sbc*360 if (formal == 2 | formal == 5)

g double presperT = `TpresperT'/100*sbc*360 if (formal == 2 | formal == 5)
g double presperP = `TpresperP'/100*sbc*360 if (formal == 2 | formal == 5)

g double servsocculT = `TservsocculT'/100*sbc*360 if (formal == 2 | formal == 5)
g double servsocculP = `TservsocculP'/100*sbc*360 if (formal == 2 | formal == 5)

g double segriesgT = `TsegriesgT'/100*sbc*360 if (formal == 2 | formal == 5)
g double segriesgP = `TsegriesgP'/100*sbc*360 if (formal == 2 | formal == 5)

g double pensjubT = `TpensjubT'/100*sbc*360 if (formal == 2 | formal == 5)
g double pensjubP = `TpensjubP'/100*sbc*360 if (formal == 2 | formal == 5)

g double admingenT = `TadmingenT'/100*sbc*360 if (formal == 2 | formal == 5)
g double admingenP = `TadmingenP'/100*sbc*360 if (formal == 2 | formal == 5)
g double admingenF = `TadmingenF'/100*sbc*360 if (formal == 2 | formal == 5)

g double fvivT = `TfvivT'/100*sbc*360 if (formal == 2 | formal == 5)
g double fvivP = `TfvivP'/100*sbc*360 if (formal == 2 | formal == 5)

g double cuotasocisssteF = `smdf'*`TcuotaSocISSSTEF'/100*360 if (formal2 == 2 | formal == 5)


* INFONAVIT *
g double infonavit = sbc*`Tinfonavit'/100*360 if formal != 0



******************************************
* Cuotas a la seguridad social (totales) *
egen double cuotasT = rsum(*T)
label var cuotasT "Seguridad social (trabajadores)"

egen double cuotasP = rsum(*P)
label var cuotasP "Seguridad social (patr${o}n)"

egen double cuotasF = rsum(*F)
label var cuotasF "Seguridad social (federaci${o}n)"

egen double cuotasTP = rsum(cuotasP cuotasT)
label var cuotasTP "Seguridad social (trabajadores y patr${o}n)"

egen double cuotasTPF = rsum(cuotasP cuotasT cuotasF)
label var cuotasTPF "Contribuciones a la seguridad social"

* Cuotas a la seguridad social por by *
tabstat cuotasTP [aw=factor_hog] if (formal2 == 1 | formal2 == 2), ///
	stat(sum) f(%20.0fc) save by(formal)
tempname SBCIMSS SBCISSSTE
matrix `SBCIMSS' = r(Stat1)
matrix `SBCISSSTE' = r(Stat2)

tabstat cuotasF [aw=factor_hog] if (formal2 == 1 | formal2 == 2), ///
	stat(sum) f(%20.0fc) save by(formal)
tempname SBCFED
matrix `SBCFED' = r(StatTotal)

tabstat cuotasTPF [aw=factor_hog] if formal == 6 | (formal == 1 & formal2 == 0) | (formal == 2 & formal2 == 0), ///
	stat(sum) f(%20.0fc) save by(formal)
tempname SBCIMP
matrix `SBCIMP' = r(StatTotal)

tabstat cuotasTPF [aw=factor_hog] if (formal == 3 | formal == 4 | formal == 5), ///
	stat(sum) f(%20.0fc) save by(formal)
tempname SBCOTR
matrix `SBCOTR' = r(StatTotal)

tabstat infonavit [aw=factor_hog] if (formal != 6), ///
	stat(sum) f(%20.0fc) save by(formal)
tempname SBCINF
matrix `SBCINF' = r(StatTotal)

tabstat infonavit [aw=factor_hog] if (formal == 6), ///
	stat(sum) f(%20.0fc) save by(formal)
tempname SBCINF2
matrix `SBCINF2' = r(StatTotal)

tabstat cuotasTPF [aw=factor_hog], ///
	stat(sum) f(%20.0fc) save by(formal)
tempname SBCTOTAL
matrix `SBCTOTAL' = r(StatTotal)


* Gini's de seguridad social *
tempvar cuotasIMSS cuotasISSSTE cuotasFED cuotasIMP cuotasOTR
g `cuotasIMSS' = cuotasTP if formal == 1
g `cuotasISSSTE' = cuotasTP if formal == 2
g `cuotasFED' = cuotasF if formal == 1 | formal == 2
g `cuotasIMP' = cuotasTPF if formal == 6
g `cuotasOTR' = cuotasTPF if formal != 1 & formal != 2 & formal != 6

Gini `cuotasIMSS', hogar(`hogar') individuo(numren) factor(factor_hog)
local gini_cuotasIMSS = r(gini_`cuotasIMSS')
Gini `cuotasISSSTE', hogar(`hogar') individuo(numren) factor(factor_hog)
local gini_cuotasISSSTE = r(gini_`cuotasISSSTE')
Gini `cuotasFED', hogar(`hogar') individuo(numren) factor(factor_hog)
local gini_cuotasFED = r(gini_`cuotasFED')
Gini `cuotasIMP', hogar(`hogar') individuo(numren) factor(factor_hog)
local gini_cuotasIMP = r(gini_`cuotasIMP')
Gini `cuotasOTR', hogar(`hogar') individuo(numren) factor(factor_hog)
local gini_cuotasOTR = r(gini_`cuotasOTR')
Gini cuotasTPF, hogar(`hogar') individuo(numren) factor(factor_hog)
local gini_cuotasTPF = r(gini_cuotasTPF)


// Step 1 //
noisily di _newline(2) _col(04) in g "{bf:Paso 1: Estimar las contribuciones de seguridad social}"
noisily di _newline _col(04) in g "{bf:1.1. Seguridad Social" ///
	_col(44) in g "(Gini)" ///
	_col(57) in g %7s "`enigh'" ///
	_col(66) %7s "Macro" in g ///
	_col(77) %7s "Diferencia" "}"
noisily di ///
	_col(04) in g "(+) IMSS " ///
	_col(44) in y "(" %5.3fc `gini_cuotasIMSS' ")" ///
	_col(57) in y %7.3fc `SBCIMSS'[1,1]/`PIBSCN'*100 ///
	_col(66) in y %7.3fc `CuotasIMSS'/`PIBSCN'*100 ///
	_col(77) in y %7.1fc (`SBCIMSS'[1,1]/`CuotasIMSS'-1)*100 "%"
noisily di ///
	_col(04) in g "(+) ISSSTE " ///
	_col(44) in y "(" %5.3fc `gini_cuotasISSSTE' ")" ///
	_col(57) in y %7.3fc `SBCISSSTE'[1,1]/`PIBSCN'*100 ///
	_col(66) in y %7.3fc `CuotasISSSTE'/`PIBSCN'*100 ///
	_col(77) in y %7.1fc (`SBCISSSTE'[1,1]/`CuotasISSSTE'-1)*100 "%"
noisily di ///
	_col(04) in g "(+) Federaci${o}n " ///
	_col(44) in y "(" %5.3fc `gini_cuotasFED' ")" ///
	_col(57) in y %7.3fc `SBCFED'[1,1]/`PIBSCN'*100 ///
	_col(66) in y %7.3fc `SSFederacion'/`PIBSCN'*100 ///
	_col(77) in y %7.1fc (`SBCFED'[1,1]/`SSFederacion'-1)*100 "%"
noisily di ///
	_col(04) in g "(+) Otros " ///
	_col(44) in y "(" %5.3fc `gini_cuotasOTR' ")" ///
	_col(57) in y %7.3fc (`SBCOTR'[1,1]+`SBCINF'[1,1])/`PIBSCN'*100 ///
	_col(66) in y %7.3fc ((`SSEmpleadores'+`SSImputada')-`SSFederacion'-`SSImputada'-`CuotasISSSTE'-`CuotasIMSS')/`PIBSCN'*100 ///
	_col(77) in y %7.1fc ((`SBCOTR'[1,1]+`SBCINF'[1,1])/((`SSEmpleadores'+`SSImputada')-`SSFederacion'-`SSImputada'-`CuotasISSSTE'-`CuotasIMSS')-1)*100 "%"
noisily di ///
	_col(04) in g "(+) Imputada " ///
	_col(44) in y "(" %5.3fc `gini_cuotasIMP' ")" ///
	_col(57) in y %7.3fc (`SBCIMP'[1,1]+`SBCINF2'[1,1])/`PIBSCN'*100 ///
	_col(66) in y %7.3fc `SSImputada'/`PIBSCN'*100 ///
	_col(77) in y %7.1fc ((`SBCIMP'[1,1]+`SBCINF2'[1,1])/`SSImputada'-1)*100 "%"
noisily di in g _dup(84) "-"
noisily di ///
	_col(04) in g "{bf:(=) Seguridad social" ///
	_col(44) in y "(" %5.3fc `gini_cuotasTPF' ")" ///
	_col(57) in y %7.3fc (`SBCTOTAL'[1,1]+`SBCINF'[1,1]+`SBCINF2'[1,1])/`PIBSCN'*100 ///
	_col(66) in y %7.3fc (`SSEmpleadores'+`SSImputada')/`PIBSCN'*100 ///
	_col(77) in y %7.1fc ((`SBCTOTAL'[1,1]+`SBCINF'[1,1]+`SBCINF2'[1,1])/(`SSEmpleadores'+`SSImputada')-1)*100 "%" "}"



**********************************************
** 7.2. Ingresos brutos trabajo subordinado **
* Tarifa y Subsidio Empleo: Decreto publicado en el DOF el 7 de diciembre de 2009 y el 11 de diciembre de 2013. *
*		Inferior	Superior	CF		Tasa		
matrix ISR = 	(0.00,		5952.84,	0.0,		1.92  \ 	///	1
		5952.85,	50524.92,	114.24,		6.40  \ 	///	2
		50524.93,	88793.04,	2966.76,	10.88 \ 	///	3
		88793.05,	103218.00,	7130.88,	16.00 \ 	///	4
		103218.01,	123580.20,	9438.60,	17.92 \ 	///	5
		123580.21,	249243.48,	13087.44,	21.36 \ 	///	6
		249243.49,	392841.96,	39929.04,	23.52 \ 	///	7
		392841.97,	750000.00, 	73703.40,	30.00 \ 	///	8
		750000.01,	1000000.00,	180850.82,	32.00 \ 	///	9
		1000000.01,	3000000.00,	260850.81,	34.00 \ 	///	10
		3000000.01,	1E+14, 		940850.81,	35.00)		//	11

*		Inferior	Superior	Subsidio
matrix SE = 	(0.00,		21227.52,	4884.24 \	///	1
		21227.53,	23744.40,	4881.96 \	///	2
		23744.41,	31840.56,	4318.08 \	///	3
		31840.57,	41674.08,	4123.20 \	///	4
		41674.09,	42454.44,	3723.48 \	///	5
		42454.45,	53353.80,	3581.28 \	///	6
		53353.81,	56606.16,	4250.76 \	///	7
		56606.17,	64025.04,	3898.44 \	///	8
		64025.05,	74696.04,	3535.56 \	///	9
		74696.05,	85366.80,	3042.48 \	///	10
		85366.81,	88587.96,	2611.32 \	///	11
		88587.97, 	1E+14,		0)		//	12

* Calculo de ISR retenciones por salarios *
g double ing_subor = .
g categ = .
g categI = .
g categS = .
g SE = 0
forvalues j=`=rowsof(ISR)'(-1)1 {
	forvalues k=`=rowsof(SE)'(-1)1 {
		replace ing_subor = (ing_t4_cap1 + ISR[`j',3] ///
			- ISR[`j',4]/100*ISR[`j',1] - SE[`k',3]*htrab/48 - ISR[`j',4]/100*cuotasTPF ///
			- ISR[`j',4]/100*exen_t4_cap1 + cuotasTPF) / (1-ISR[`j',4]/100) ///
			if formal != 0 & ing_t4_cap1 != 0 & htrab < 48 & categ == .

		replace ing_subor = (ing_t4_cap1 + ISR[`j',3] ///
			- ISR[`j',4]/100*ISR[`j',1] - SE[`k',3] - ISR[`j',4]/100*cuotasTPF ///
			- ISR[`j',4]/100*exen_t4_cap1 + cuotasTPF) / (1-ISR[`j',4]/100) ///
			if formal != 0 & ing_t4_cap1 != 0 & htrab >= 48 & categ == .

		replace ing_subor = (ing_t4_cap1 + ISR[`j',3] ///
			- ISR[`j',4]/100*ISR[`j',1] - ISR[`j',4]/100*cuotasTPF ///
			- ISR[`j',4]/100*exen_t4_cap1 + cuotasTPF) / (1-ISR[`j',4]/100) ///
			if formal != 0 & ing_t4_cap1 != 0 & htrab == . & categ == .

		replace categI = `j' if ing_subor - exen_t4_cap1 - cuotasTPF >= ISR[`j',1] ///
			& ing_subor - exen_t4_cap1 - cuotasTPF <= ISR[`j',2] ///
			& formal != 0 & categ == .

		replace categS = `k' if ing_subor - ing_t4_cap1_nosubsidio >= SE[`k',1] ///
			& ing_subor - ing_t4_cap1_nosubsidio <= SE[`k',2] ///
			& formal != 0 & categ == .

		replace categ = `j'`k' if ing_subor - exen_t4_cap1 - cuotasTPF >= ISR[`j',1] ///
			& ing_subor - exen_t4_cap1 - cuotasTPF <= ISR[`j',2] ///
			& ing_subor - ing_t4_cap1_nosubsidio >= SE[`k',1] ///
			& ing_subor - ing_t4_cap1_nosubsidio <= SE[`k',2] ///
			& formal != 0 & categ == .

		replace SE = SE[`k',3]*htrab/48 if formal != 0 & categ == `j'`k' & htrab < 48

		replace SE = SE[`k',3] if formal != 0 & categ == `j'`k' & htrab >= 48

		replace SE = 0 if formal != 0 & categ == `j'`k' & htrab == .
	}
}

* Conflictos *
replace ing_subor = (ing_t4_cap1 + ISR[categI,3] ///
	- ISR[categI,4]/100*ISR[categI,1] - SE[categS,3]*htrab/48 - ISR[categI,4]/100*cuotasTPF ///
	- ISR[categI,4]/100*exen_t4_cap1 + cuotasTPF) / (1-ISR[categI,4]/100) ///
	if formal != 0 & ing_t4_cap1 != 0 & htrab < 48 ///
	& categ == . & categI != . & categS != .

replace ing_subor = (ing_t4_cap1 + ISR[categI,3] ///
	- ISR[categI,4]/100*ISR[categI,1] - SE[categS,3] - ISR[categI,4]/100*cuotasTPF ///
	- ISR[categI,4]/100*exen_t4_cap1 + cuotasTPF) / (1-ISR[categI,4]/100) ///
	if formal != 0 & ing_t4_cap1 != 0 & htrab >= 48 ///
	& categ == . & categI != . & categS != .

replace ing_subor = (ing_t4_cap1 + ISR[categI,3] ///
	- ISR[categI,4]/100*ISR[categI,1] - ISR[categI,4]/100*cuotasTPF ///
	- ISR[categI,4]/100*exen_t4_cap1 + cuotasTPF) / (1-ISR[categI,4]/100) ///
	if formal != 0 & ing_t4_cap1 != 0 & htrab == . ///
	& categ == . & categI != . & categS != .

replace SE = SE[categS,3]*htrab/48 if formal != 0 & categ == . & categI != . & categS != . & htrab < 48
replace SE = SE[categS,3] if formal != 0 & categ == . & categI != . & categS != . & htrab >= 48
replace SE = 0 if formal != 0 & categ == . & categI != . & categS != . & htrab == .

* Ingreso bruto informales *
replace ing_subor = ing_t4_cap1 if formal == 0

* ISR *
g double isrE = ing_subor - ing_t4_cap1 - cuotasTP if formal != 0
replace isrE = 0 if isrE == .
label var isrE "ISR retenciones a asalariados"

* Results *
tabstat ing_subor isrE SE [aw=factor_hog], stats(sum) f(%25.0fc) by(formal) save
tempname GROSS
matrix `GROSS' = r(StatTotal)

* Gini's de ingresos brutos *
Gini ing_subor, hogar(`hogar') individuo(numren) factor(factor_hog)
local gini_ing_subor = r(gini_ing_subor)
Gini isrE, hogar(`hogar') individuo(numren) factor(factor_hog)
local gini_isrE = r(gini_isrE)
Gini SE, hogar(`hogar') individuo(numren) factor(factor_hog)
local gini_SE = r(gini_SE)

// Step 2 //
noisily di _newline(2) _col(04) in g "{bf:Paso 2: Recuperar el ingreso bruto y estimar el ISR retenido por salarios}"
noisily di in g _newline _col(04) in g "{bf:2.1. Ingresos bruto salarial" ///
	_col(44) in g "(Gini)" ///
	_col(57) in g %7s "`enigh'" ///
	_col(66) %7s "Macro" in g ///
	_col(77) %7s "Diferencia" "}"
noisily di ///
	_col(04) in g "Ingreso bruto por salarios" ///
	_col(44) in y "(" %5.3fc `gini_ing_subor' ")" ///
	_col(57) in y %7.3fc `GROSS'[1,1]/`PIBSCN'*100 ///
	_col(66) in y %7.3fc (`RemSal'+`SSEmpleadores'+`SSImputada')/`PIBSCN'*100 ///
	_col(77) in y %7.1fc (`GROSS'[1,1]/(`RemSal'+`SSEmpleadores'+`SSImputada')-1)*100 "%"
noisily di ///
	_col(04) in g "ISR retenciones a asalariados" ///
	_col(44) in y "(" %5.3fc `gini_isrE' ")" ///
	_col(57) in y %7.3fc `GROSS'[1,2]/`PIBSCN'*100 ///
	_col(66) in y %7.3fc `ISRSalarios'/`PIBSCN'*100 ///
	_col(77) in y %7.1fc (`GROSS'[1,2]/`ISRSalarios'-1)*100 "%"
noisily di ///
	_col(04) in g "Subsidio al empleo" ///
	_col(44) in y "(" %5.3fc `gini_SE' ")" ///
	_col(57) in y %7.3fc `GROSS'[1,3]/`PIBSCN'*100  ///
	_col(66) in y %7.3fc `SubsidioEmpleo'/`PIBSCN'*100 ///
	_col(77) in y %7.1fc (`GROSS'[1,3]/`SubsidioEmpleo'-1)*100 "%"

tempfile isr_pre
save `isr_pre'




***********************
*** 8. COLA DERECHA ***
***********************
if `betamin' > 1 {
	use `isr_pre', clear
	rename ing_subor ing_precola_subor
	g double ing_subor = ing_precola_subor
	local ingreso "ing_subor"
	*local sort "`hogar' numren"
	local sort "`hogar'"
	collapse (sum) `ingreso' (mean) factor_hog, by(`sort')
	gsort -`ingreso' `sort'

	g double n = sum(factor_hog)
	g double lnxi = ln(`ingreso')
	g double lnxi2 = ln(`ingreso')*factor_hog
	g double lnxm = lnxi*n
	g double slnxi = sum(lnxi2)

	g double alfa = n/(slnxi - lnxm)
	g double beta = alfa / (alfa - 1)

	sort `ingreso' `sort'

	local N = _N
	tabstat `ingreso' if beta <= `betamin' & beta > 0, stats(min) save

	tempname R
	matrix `R' = r(StatTotal)
	count if `ingreso' >= `R'[1,1]
	local count = `N' - r(N) + 1
	display `count'

	egen factorn = sum(factor_hog) if `ingreso' >= `R'[1,1]

	g double n2 = sum(factor_hog) if `ingreso' >= `R'[1,1]
	g double cdfe = n2/factorn * 100

	* Metodo 2 *
	local N1 = _N + 1
	set obs `N1'

	g double media = .
	forvalues l = `N1'(-1)`count' {
		local minn = `l' - 1
		summ `ingreso' in `minn'/`l', meanonly
		tempname A
		matrix `A' = r(mean)
		replace media = `A'[1,1] in `minn'
	}

	g double cdft = (1-(`R'[1,1]/media)^(`betamin'/(`betamin'-1)))*100 if `ingreso' >= `R'[1,1]
	g double pdft = 0 if `ingreso' >= `R'[1,1]

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

	g double factor_cola = pdft*factorn/100 if `ingreso' >= `R'[1,1]
	replace factor_cola  = factor_hog if factor_cola  == .
	replace factor_cola  = round(factor_cola)

	tabstat `ingreso' [aw=factor_cola], stats(sum) f(%25.2fc) save

	keep `sort' factor_hog factor_cola cola `ingreso'

	local ingreso_cola = `ingreso'[_N]
	tempfile isr_cola
	save `isr_cola'
}




*************************
*** 9. FINALIZAR BASE ***
*************************
use `isr_pre', clear
replace scian = substr(scian,1,2)
replace sinco = substr(sinco,1,2)
destring pago inscr_* scian sinco subor, replace

collapse (sum) ing_* exen_* cuotas* htrab isrE renta deduc_isr ///
	(mean) factor_hog* sm sbc tot_integ ///
	(max) scian formal* tipo_contribuyente sinco ///
	(min) pago inscr_* subor, by(`hogar' numren)
merge 1:1 (`hogar' numren) using "`c(sysdir_personal)'../basesCIEP/INEGI/`enigh'/`enighanio'/poblacion.dta", nogen ///
	keepusing(sexo edad nivelaprob gradoaprob)


* Formalidad *
tabstat edad [fw=factor_hog] if ing_subor != 0 | ing_mixto != 0, stat(count) f(%15.0fc) save by(formal)
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



***********************************************
** 9.1. Imputar resultados a la Cola Derecha **
if `betamin' > 1 {
	*merge 1:1 (`sort') using `isr_cola', nogen keepus(factor_cola)
	merge m:1 (`sort') using `isr_cola', nogen keepus(factor_cola)

	replace `ingreso' = `ingreso_cola' in `=_N'
	replace factor_cola = factor_hog if factor_cola == .

	tabstat factor_cola, stat(sum) f(%20.0fc) save
	tempname POBTOT
	matrix `POBTOT' = r(StatTotal)

	sort `ingreso'
	local topincomes = factor_cola[_N]
	local percentcola = `topincomes'/`POBTOT'[1,1]*100

	tempvar ingresocola
	egen double `ingresocola' = sum(`ingreso'), by(`hogar')

	tempvar ingpercentcola factorcola
	local ingcola = `ingreso'[_N]
	egen double `ingpercentcola' = sum(`ingreso') in -11/-1 if folioviv != ""
	egen double `factorcola' = sum(factor_cola) in -11/-1 if folioviv != ""

	replace `ingreso' = `ingreso' + `ingcola'*`ingreso'/`ingpercentcola' ///
		in -11/-1 if folioviv != ""
	replace factor_cola = round(factor_cola + `topincomes'*factor_cola/`factorcola') ///
		in -11/-1 if folioviv != ""
	replace isrE = isrE + `ingcola'*`ingreso'/`ingpercentcola'*.3 ///
		in -11/-1 if folioviv != ""

	foreach k of varlist ing_mixto ing_capital ing_estim_alqu {
		tabstat `k', stat(max) f(%15.0fc) save
		tempname TOPING
		matrix `TOPING' = r(StatTotal)

		tempvar temp`k'
		egen double `temp`k'' = sum(factor_cola) in -11/-1 if folioviv != "" & `k' != 0
		replace `k' = `k' + `TOPING'[1,1]*`betamin'*factor_cola/`temp`k'' ///
			in -11/-1 if folioviv != "" & `k' != 0
	}

	drop if folioviv == ""

	* Resultados de la Cola Derecha *
	tabstat ing_subor isrE [aw=factor_cola], stat(sum) f(%20.0fc) save by(formal)
	tempname TOP
	matrix `TOP' = r(StatTotal)

	noisily di _newline(2) _col(04) in g "{bf:Paso 2-BIS: Estimar la cola derecha (" in y "Beta = `betamin'" in g ")}"
	noisily di ///
	_col(04) in g "Hogares en la cola derecha " ///
		_col(57) in y %7.3fc `percentcola' "% " 

	noisily di _newline _col(04) in g "{bf:D-Bis. Ingreso bruto salarial" ///
		_col(57) in g %7s "`enigh'" ///
		_col(66) %7s "Macro" in g ///
		_col(77) %7s "Diferencia" "}"
	noisily di ///
	_col(04) in g "Ingreso bruto por salarial " ///
		_col(57) in y %7.3fc `TOP'[1,1]/`PIBSCN'*100 ///
		_col(66) in y %7.3fc (`RemSal'+`SSEmpleadores'+`SSImputada')/`PIBSCN'*100  ///
		_col(77) in y %7.1fc (`TOP'[1,1]/(`RemSal'+`SSEmpleadores'+`SSImputada')-1)*100 "%"
	noisily di ///
	_col(04) in g "ISR retenciones de asalariados " ///
		_col(57) in y %7.3fc `TOP'[1,2]/`PIBSCN'*100 ///
		_col(66) in y %7.3fc `ISRSalarios'/`PIBSCN'*100 ///
		_col(77) in y %7.1fc (`TOP'[1,2]/`ISRSalarios'-1)*100 "%"
}
else {
	g double factor_cola = factor_hog
}



**********************
** 9.2. Escolaridad **
destring gradoaprob, replace
g aniosesc = 0 if nivelaprob == "0"
replace aniosesc = 1 if nivelaprob == "1"
replace aniosesc = gradoaprob + 1 if nivelaprob == "2"
replace aniosesc = gradoaprob + 7 if nivelaprob == "3"
replace aniosesc = gradoaprob + 10 if nivelaprob == "4"
replace aniosesc = gradoaprob + 12 if nivelaprob == "6"
replace aniosesc = gradoaprob + 13 if nivelaprob == "5" | nivelaprob == "7"
replace aniosesc = gradoaprob + 18 if nivelaprob == "8"
replace aniosesc = gradoaprob + 20 if nivelaprob == "9"

g escol = 0 if nivelaprob == "0" | nivelaprob == ""
replace escol = 1 if nivelaprob == "1" | nivelaprob == "2" | nivelaprob == "3"
replace escol = 2 if nivelaprob == "4" | nivelaprob == "6"
replace escol = 3 if nivelaprob == "5" | nivelaprob == "7"
replace escol = 4 if nivelaprob == "8" | nivelaprob == "9"

* Labels *
label define escol 0 "Sin escolaridad" 1 "B${a}sica" 2 "Media Superior" 3 "Superior" 4 "Posgrado"
label values escol escol

label var escol "Nivel de escolaridad"

label values tipo_contribuyente tipo_contribuyente

label var ing_jubila "Pensiones"
label var ing_subor "Sueldos y salarios"
label var ing_mixto "Ingreso mixto"
label var ing_capital "Sociedades y ISFLSH"
label var ing_estim_alqu "Imputaci${o}n de alquiler"





*****************************
*** 10. Re-calculo de ISR ***
*****************************

* Ingreso mixto *
tabstat ing_mixto [aw=factor_cola], stat(sum) f(%20.0fc) save by(formal)
tempname ALTIMIR00
matrix `ALTIMIR00' = r(StatTotal)


* Capital *
tabstat ing_subor ing_mixto ing_capital ing_estim_alqu ing_remesas [aw=factor_cola], stat(sum) f(%20.0fc) save by(formal)
tempname ALTIMIR0
matrix `ALTIMIR0' = r(StatTotal)


// Step 5 //
local TaltimirSelf = (`MixKN'+`MixL')/`ALTIMIR00'[1,1]
local TaltimirSal = (`RemSal'+`SSEmpleadores'+`SSImputada')/`ALTIMIR0'[1,1]
local TaltimirHouse = `ExNOpHog'/`ALTIMIR0'[1,4]
local TaltimirCap = `ExNOpSoc'/`ALTIMIR0'[1,3]
local TaltimirRemesas = `ROWTrans'/`ALTIMIR0'[1,5]

if "`altimir'" == "yes" {
	replace ing_estim_alqu = ing_estim_alqu*`TaltimirHouse'
	replace ing_remesas = ing_remesas*`TaltimirRemesas'

	foreach k of varlist *_subor {
		replace `k' = `k'*`TaltimirSal'
	}

	foreach k of varlist *_agri *_trabmenor *_honor *_empre *_mixt* {
		replace `k' = `k'*`TaltimirSelf'
	}

	foreach k of varlist *_capital *_util *_ganan *_indemn *_indemn2 *_indemn3 ///
		*_segvida ///
		*_rent ///
		*_enajecasa *_enajem *_enaje ///
		*_intereses ///
		*_dona ///
		*_loter ///
		*_acc ///
		*_autor /*ing_remesas ing_prest ing_otrocap ing_ahorro*/ ing_heren /*ing_benef*/ {
		replace `k' = `k'*`TaltimirCap'
	}
}



***************
** 10.1. ISR **
noisily di _newline(2) _col(04) in g "{bf:Paso 3: Sumar ingresos por individuo y re-calcular ISR}"
g double ing_bruto_tax = ing_subor + ing_mixto + ing_capital
label var ing_bruto_tax "Ingreso gravable"

g double exen_tot = exen_t4_cap1 + exen_mixto + exen_capital
label var exen_tot "Exenciones totales"



*************
** PROBITS **
g formal_probit = formal != 0
g rural = substr(folioviv,3,1) == "6"
g edad2 = edad^2
g aniosesc2 = aniosesc^2
g por_rent = ing_rent/ing_bruto_tax
g por_servprof = ing_t4_cap2/ing_bruto_tax

g probit_renta = renta != 0

tostring scian, replace
replace scian = "9" if scian == "."
g scian2 = substr(scian,1,1)

tostring sinco, replace
replace sinco = "9" if sinco == "."
g sinco2 = substr(sinco,1,1)

replace subor = 2 if subor == .


** Probit formalidad (alquileres, produccion) **
di _newline _col(04) in g "{bf:3.1. Probit de formalidad: " in y "Alquileres, producci${o}n.}"
xi: probit formal_probit ing_bruto_tax exen_tot por_rent deduc_isr ///
	edad edad2 i.sexo aniosesc aniosesc2 rural i.sinco2 i.subor ///
	if ing_rent != 0 [pw=factor_cola]
predict double prob_renta if e(sample)

* Seleccionar individuos formales (alquileres) *
gsort -prob_renta -ing_anual
g double ing_renta_accum = sum(ing_rent*factor_cola)

noisily di _newline _col(04) in g "{bf:SUPUESTO: " in y "Se hace el cut-off en la formalidad de alquileres en " %15.0fc `acum_arrenda'/.65 " (SAT PF 2015).}"
g formal_renta = ing_renta_accum <= `acum_arrenda'/.65 & prob_renta != .	// SAT m${a}s abierto

noisily di _newline _col(04) in g "{bf:SUPUESTO: " ///
	in y "El " %5.2fc (`SNAAlojamiento'-`SNAExBOpHog')/(`SNAAlquiler'+`SNAInmobiliarias'-`SNAExBOpHog')*100 ///
	"% de los ingresos por rentas provienen de las personas f${i}sicas.}"
g ing_renta_accum_hog = ing_renta_accum*(`SNAAlojamiento'-`SNAExBOpHog')/(`SNAAlquiler'+`SNAInmobiliarias'-`SNAExBOpHog')

* Ingreso gravable (alquileres) *
replace ing_bruto_tax = ing_bruto_tax - ing_rent if formal_renta == 0 & prob_renta != . & formal != 0
replace exen_tot = exen_tot - exen_rent if formal_renta == 0 & prob_renta != . & formal != 0

replace ing_bruto_tax = ing_rent if formal_renta == 1 & prob_renta != . & formal == 0
replace exen_tot = exen_rent if formal_renta == 1 & prob_renta != . & formal == 0



** Probit formalidad (servicios profesionales, produccion) **
di _newline _col(04) in g "{bf:3.3. Probit de formalidad: " in y "Servicios profesionales, producci${o}n.}"
xi: probit formal_probit ing_bruto_tax exen_tot por_servprof deduc_isr ///
	edad edad2 i.sexo aniosesc aniosesc2 rural i.sinco2 i.subor ///
	if ing_t4_cap2 != 0 [pw=factor_cola]
predict double prob_servprof if e(sample)

* Seleccionar individuos formales (servicios profesionales) *
gsort -prob_servprof -ing_t4_cap2
g double ing_servprof_accum = sum((ing_t4_cap2-exen_t4_cap2)*factor_cola)

noisily di _newline _col(04) in g "{bf:SUPUESTO: " in y "Se hace el cut-off en la formalidad de servicios profesionales en " ///
	in y %15.0fc `util_serprof' in g " (SAT FP 2015).}"
g formal_servprof = ing_servprof_accum < `util_serprof' & prob_servprof != .		// SAT m${a}s abierto

noisily di _newline _col(04) in g "{bf:SUPUESTO: " ///
	in y "El " %5.2fc (`ServProfH'+`SaludH')/(`ServProf'+`ConsMedi'+`ConsDent'+`ConsOtro'+`EnfeDomi')*100 ///
	"% de los ingresos por servicios profesionales provienen de las personas f${i}sicas.}"
g ing_servprof_accum_hog = ing_servprof_accum*(`ServProfH'+`SaludH')/(`ServProf'+`ConsMedi'+`ConsDent'+`ConsOtro'+`EnfeDomi')

* Ingreso gravable (servicios profesionales) *
replace ing_bruto_tax = ing_bruto_tax - (ing_honor + ing_empre) if formal_servprof == 0 & prob_servprof != . & formal != 0
replace exen_tot = exen_tot - (exen_honor + exen_empre) if formal_servprof == 0 & prob_servprof != . & formal != 0

replace ing_bruto_tax = (ing_honor + ing_empre) if formal_servprof == 1 & prob_servprof != . & formal == 0
replace exen_tot = (exen_honor + exen_empre) if formal_servprof == 1 & prob_servprof != . & formal == 0



** Escalar con informaci${o}n del SAT **
noisily di _newline _col(04) in g "{bf:3.3. Deducciones personales y gastos profesionales}"
noisily tabstat deduc_isr [aw=factor_cola], stat(sum) f(%20.0fc) by(formal_dummy) save
*tempname deducfor
*matrix `deducfor' = r(StatTotal)
*replace deduc_isr = deduc_isr*67473904696/`deducfor'[1,1] if formal != 0
*replace deduc_isr = deduc_isr*67473904696/`deducfor'[1,1] if formal == 0


* Limitar deducciones *
replace deduc_isr = 5*`smdf'*365 if 5*`smdf'*365 <= 15/100*ing_bruto_tax & deduc_isr >= 5*`smdf'*365
replace deduc_isr = 15/100*ing_bruto_tax if 5*`smdf'*365 >= 15/100*ing_bruto_tax & deduc_isr >= 15/100*ing_bruto_tax

g double ISR = 0
label var ISR "ISR (f${i}sicas y asalariados)"
g categF = ""
forvalues j=`=rowsof(ISR)'(-1)1 {
	forvalues k=`=rowsof(SE)'(-1)1 {
		replace categF = "J`j'K`k'" ///
			if (ing_bruto_tax - exen_tot - deduc_isr - cuotasTPF) >= ISR[`j',1] ///
			 & (ing_bruto_tax - exen_tot - deduc_isr - cuotasTPF) <= ISR[`j',2] ///
			 & (ing_bruto_tax - exen_tot - deduc_isr - cuotasTPF) >= SE[`k',1] ///
			 & (ing_bruto_tax - exen_tot - deduc_isr - cuotasTPF) <= SE[`k',2] ///
			 //& formal != 0

		replace ISR = ISR[`j',3] + (ISR[`j',4]/100)*(ing_bruto_tax - exen_tot - deduc_isr - cuotasTPF - ISR[`j',1]) ///
			- SE[`k',3]*htrab/48 ///
			if categF == "J`j'K`k'" /*& formal != 0*/ & htrab < 48 & tipo_contribuyente == 1
		replace ISR = ISR[`j',3] + (ISR[`j',4]/100)*(ing_bruto_tax - exen_tot - deduc_isr - cuotasTPF - ISR[`j',1]) ///
			- SE[`k',3] ///
			if categF == "J`j'K`k'" /*& formal != 0*/ & htrab >= 48 & tipo_contribuyente == 1
		replace ISR = ISR[`j',3] + (ISR[`j',4]/100)*(ing_bruto_tax - exen_tot - deduc_isr - cuotasTPF - ISR[`j',1]) ///
			if categF == "J`j'K`k'" /*& formal != 0*/ & (tipo_contribuyente == 2 | htrab == 0)
	}
}

g double TE = ISR/(ing_bruto_tax - exen_tot - deduc_isr - cuotasTPF)
replace TE = 0 if TE == .

*replace ing_bruto_tax = 0 if formal == 0
replace ISR = 0 if formal == 0 & formal_renta == 0 & formal_servprof == 0


* Sankey *
g double ISR__asalariados = isrE
replace ISR__asalariados = 0 if ISR__asalariados == .
label var ISR__asalariados "ISR (retenciones por salarios)"

g double ISR__PF = ISR - isrE if ISR - isrE >= 0
replace ISR__PF = 0 if ISR__PF == .
label var ISR__PF "ISR (personas f${i}sicas)"

tabstat ISR__PF [aw=factor_cola], stat(sum) f(%25.2fc) save
tempname RESTAX0
matrix `RESTAX0' = r(StatTotal)

*replace ISR__PF = ISR__PF*(`ISRFisicas'/`RESTAX0'[1,1])

*g double ISR__ar = ISR__PF*(ing_rent - exen_rent)/(ing_bruto_tax - exen_tot - deduc_isr - cuotasTPF) if formal_renta == 1
*replace ISR__ar = 0 if ISR__ar == .
*label var ISR__ar "ISR (arrendamiento)"

g ISR__PM = ing_capital if formal != 0
label var ISR__PM "ISR (personas morales)"

g ISR__co = ing_capital if formal != 0
label var ISR__co "ISR (contratistas y asignatarios)"

g CuotasT = cuotasT if formal == 1
label var CuotasT "Cuotas IMSS (trabajadores)"

g CuotasP = cuotasP if formal == 1
label var CuotasP "Cuotas IMSS (patr${o}n)"

g IMSSISSSTE = factor_cola if formal == 1 | formal == 2
label var IMSSISSSTE "Ingresos propios IMSS e ISSSTE"

g PemexCFE = factor_cola
label var PemexCFE "Ingresos propios Pemex y CFE"

g Otros = factor_cola
label var Otros "Otros ingresos"

g FMP = factor_cola
label var FMP "Fondo Mexicano del Petr${o}leo (derechos petroleros)"

* Gini's de ISR *
Gini ISR__asalariados, hogar(`hogar') individuo(numren) factor(factor_hog)
local gini_ISR__asalariados = r(gini_ISR__asalariados)
Gini ISR__PF, hogar(`hogar') individuo(numren) factor(factor_hog)
local gini_ISR__PF = r(gini_ISR__PF)
Gini ISR, hogar(`hogar') individuo(numren) factor(factor_hog)
local gini_ISR = r(gini_ISR)

* Results *
tabstat ISR__asalariados ISR__PF [aw=factor_cola], stat(sum) f(%25.2fc) save
tempname RESTAX
matrix `RESTAX' = r(StatTotal)

global isrPF_ENIGH = `RESTAX'[1,2]/`PIBSCN'*100

// Step 4 //
noisily di _newline _col(04) in g "{bf:3.4. ISR anual" ///
	_col(44) in g "(Gini)" ///
	_col(57) in g %7s "`enigh'" ///
	_col(66) %7s "Macro" in g ///
	_col(77) %7s "Diferencia" "}"
noisily di ///
	_col(04) in g "ISR retenciones a asalariados" ///
	_col(44) in y "(" %5.3fc `gini_ISR__asalariados' ")" ///
	_col(57) in y %7.3fc `RESTAX'[1,1]/`PIBSCN'*100 ///
	_col(66) in y %7.3fc `ISRSalarios'/`PIBSCN'*100 ///
	_col(77) in y %7.1fc (`RESTAX'[1,1]/`ISRSalarios'-1)*100 "%"
noisily di ///
	_col(04) in g "ISR personas f${i}sicas" ///
	_col(44) in y "(" %5.3fc `gini_ISR__PF' ")" ///
	_col(57) in y %7.3fc `RESTAX'[1,2]/`PIBSCN'*100 ///
	_col(66) in y %7.3fc `ISRFisicas'/`PIBSCN'*100 ///
	_col(77) in y %7.1fc (`RESTAX'[1,2]/`ISRFisicas'-1)*100 "%"
noisily di in g _dup(84) "-"
noisily di ///
	_col(04) in g "ISR total" ///
	_col(44) in y "(" %5.3fc `gini_ISR' ")" ///
	_col(57) in y %7.3fc (`RESTAX'[1,1]/`PIBSCN'*100)+(`RESTAX'[1,2]/`PIBSCN'*100) ///
	_col(66) in y %7.3fc (`ISRSalarios'+`ISRFisicas')/`PIBSCN'*100 ///
	_col(77) in y %7.1fc ((`RESTAX'[1,1]+`RESTAX'[1,2])/(`ISRSalarios'+`ISRFisicas')-1)*100 "%"





*******************
*** 11. Capital ***
*******************

* Distribuciones proporcionales *
capture program drop Distribucion
program Distribucion, return
	syntax anything, RELativo(varname) MACro(real)

	tempvar TOT
	egen double `TOT' = sum(`relativo') if factor_cola != 0
	g double `anything' = `relativo'/`TOT'*`macro'/factor_cola if factor_cola != 0
end


* Compensation of employees ROW *
Distribucion ing_suborrow, relativo(ing_subor) macro(`ROWRem')
label var ing_suborrow "Remuneraci${o}n a asalariados (ROW)"


* Capital *
Distribucion ing_capitalGov, relativo(factor_cola) ///
	macro(`=`IMSSpropio'+`ISSSTEpropio'+`CFEpropio'+`Pemexpropio'+`FMP'+`Derechos'+`Productos'+`Aprovechamientos'')
replace ing_capital = ing_capital //+ ing_capitalGov


* Totales *
g double ing_bruto_tot = ing_subor + ing_mixto + ing_capital + ing_estim_alqu
label var ing_bruto_tot "Ingreso total bruto"

egen double ing_nac = rsum(ing_bruto_tot ing_suborrow ing_remesas)
label var ing_nac "Ingreso nacional"





********************
*** 12. Altimirs ***
********************
* Gini's de ingresos finales *
Gini ing_subor, hogar(`hogar') individuo(numren) factor(factor_hog)
local gini_ing_subor = r(gini_ing_subor)
Gini ing_mixto, hogar(`hogar') individuo(numren) factor(factor_hog)
local gini_ing_mixto = r(gini_ing_mixto)
Gini ing_capital, hogar(`hogar') individuo(numren) factor(factor_hog)
local gini_ing_capital = r(gini_ing_capital)
Gini ing_estim_alqu, hogar(`hogar') individuo(numren) factor(factor_hog)
local gini_ing_estim_alqu = r(gini_ing_estim_alqu)
Gini ing_nac, hogar(`hogar') individuo(numren) factor(factor_hog)
local gini_ing_nac = r(gini_ing_nac)

* Results *
tabstat ing_subor ing_mixto ing_mixtoL ing_capital ing_estim_alqu [aw=factor_cola], stat(sum) f(%20.0fc) save by(formal)	
tempname ALTIMIR
matrix `ALTIMIR' = r(StatTotal)

// Step 5 //
noisily di _newline(2) _col(04) in g "{bf:Paso 4: Factores de escala" ///
	_col(44) in g "(Gini)" ///
	_col(57) in g %7s "`enigh'" ///
	_col(66) %7s "Macro" in g ///
	_col(77) %7s "Factor" "}"
noisily di ///
	_col(04) in g " (+) Sueldos y salarios" ///
	_col(44) in y "(" %5.3fc `gini_ing_subor' ")" ///
	_col(57) in y %7.3fc `ALTIMIR'[1,1]/`PIBSCN'*100 ///
	_col(66) in y %7.3fc (`RemSal'+`SSEmpleadores'+`SSImputada')/`PIBSCN'*100 ///
	_col(77) in y %7.1fc `TaltimirSal'
noisily di ///
	_col(04) in g " (+) Ingreso mixto" ///
	_col(44) in y "(" %5.3fc `gini_ing_mixto' ")" ///
	_col(57) in y %7.3fc `ALTIMIR'[1,2]/`PIBSCN'*100 ///
	_col(66) in y %7.3fc (`MixL'+`MixKN')/`PIBSCN'*100 ///
	_col(77) in y %7.1fc `TaltimirSelf'
noisily di ///
	_col(04) in g " (+) Sociedades e ISFLSH" ///
	_col(44) in y "(" %5.3fc `gini_ing_capital' ")" ///
	_col(57) in y %7.3fc `ALTIMIR'[1,4]/`PIBSCN'*100 ///
	_col(66) in y %7.3fc `ExNOpSoc'/`PIBSCN'*100 ///
	_col(77) in y %7.1fc `TaltimirCap'
noisily di ///
	_col(04) in g " (+) Alquiler imputado" ///
	_col(44) in y "(" %5.3fc `gini_ing_estim_alqu' ")" ///
	_col(57) in y %7.3fc `ALTIMIR'[1,5]/`PIBSCN'*100 ///
	_col(66) in y %7.3fc `ExNOpHog'/`PIBSCN'*100 ///
	_col(77) in y %7.1fc `TaltimirHouse'
noisily di in g _dup(83) "-"
noisily di ///
	_col(04) in g " (=) Ingreso nacional" ///
	_col(44) in y "(" %5.3fc `gini_ing_nac' ")" ///
	_col(57) in y %7.3fc (`ALTIMIR'[1,1]+`ALTIMIR'[1,2]+`ALTIMIR'[1,4]+`ALTIMIR'[1,5])/`PIBSCN'*100 ///
	_col(66) in y %7.3fc (`RemSal'+`SSEmpleadores'+`SSImputada'+`MixL'+`MixKN'+`ExNOpSoc'+`ExNOpHog')/`PIBSCN'*100 ///
	_col(77) in y %7.1fc ((`ALTIMIR'[1,1]+`ALTIMIR'[1,2]+`ALTIMIR'[1,4]+`ALTIMIR'[1,5])/(`RemSal'+`SSEmpleadores'+`SSImputada'+`MixL'+`MixKN'+`ExNOpSoc'+`ExNOpHog'))^(-1)





****************/
*** 13. Final ***
*****************
tempvar tot_integ
egen `tot_integ' = count(edad), by(`hogar')

egen double ing_decil_hog = sum(ing_bruto_tot), by(`hogar')
g double ing_decil_pc = ing_decil_hog/`tot_integ'


* Deciles *
xtile decil = ing_decil_pc [aw=factor_hog], n(10)
xtile percentil = ing_decil_pc [aw=factor_hog], n(100)


* Guardar *
capture drop __*
format ing_* exen_* renta %10.0fc
capture mkdir "`c(sysdir_personal)'../basesCIEP/SIM/`enighanio'/"
save "`c(sysdir_personal)'../basesCIEP/SIM/`enighanio'/income.dta", replace
