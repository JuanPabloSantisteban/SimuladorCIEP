*************************************
***                               ***
*** Simulador Impuestos al Tabaco ***
***                               ***
*************************************
clear all
macro drop _all
capture log close _all
timer on 1





******************************************************
***                                                ***
***    0. DIRECTORIOS DE TRABAJO (PROGRAMACION)    ***
***                                                ***
******************************************************
if "`c(username)'" == "ricardo" {                                               // Mac Ricardo
	sysdir set SITE "/Users/ricardo/CIEP Dropbox/Ricardo Cantú/SimuladorCIEP/tabaco/Nov2022/"
}
if "`c(username)'" == "maaci" {                                                 // Ale Macías
	sysdir set SITE "C:\Users\maaci\Dropbox (CIEP)\Bloomberg Tabaco\2020\Simulador impuestos tabaco\"
}
if "`c(username)'" == "Admin" {                                                 // Leslie
	sysdir set SITE "C:\Users\Admin\Documents\GitHub\SimuladorCIEP"
}
if "`c(username)'" == "ciepmx" & "`c(console)'" == "" {                         // Linux ServidorCIEP
	sysdir set SITE "/home/ciepmx/CIEP Dropbox/Ricardo Cantú/SimuladorCIEP/5.3/SimuladorCIEP/"
}
if "`c(username)'" == "ciepmx" & "`c(console)'" == "console" {                  // Linux ServidorCIEP (WEB)
	sysdir set SITE "/SIM/OUT/tabaco/Nov2022/"
}





************************/
***                   ***
***    1. OPCIONES    ***
***                   ***
*************************
*global output "output"                                                         // IMPRIMIR OUTPUTS (WEB)
*global nographs "nographs"                                                     // SUPRIMIR GRAFICAS





***************************************
***                                 ***
***    2. PARÁMETROS DEL USUARIO    ***
***                                 ***
***************************************

** Impuesto Específico **
** En 2020 0.49   pesos por cigarro. Cajetilla de 20 = 9.8 pesos    **
** En 2021 0.51   pesos por cigarro. Cajetilla de 20 = 10.2 pesos   **
** En 2022 0.5484 pesos por cigarro. Cajetilla de 20 = 10.968 pesos **
local stax   = 0.5484                                                           // PARAMETRO 1 Estatus Quo
local stax_1 = 0.5484                                                           // PARAMETRO 1 A MODIFICAR
*local stax_1 = {{ieps_pesos}}                                                  // PARAMETRO 1 A MODIFICAR (WEB)

** Impuesto Ad Valorem **
** En 2020, 2021 y 2022: 160% **
local advala   = 160/100                                                        // PARAMETRO 2 Estatus Quo
local advala_1 = 160/100                                                        // PARAMETRO 2 A MODIFICAR 
*local advala_1 = {{ieps_porcentaje}}/100                                       // PARAMETRO 2 A MODIFICAR (WEB)

** IVA o VAT **
** En 2020, 2021 y 2022: 16% sobre el precio total **
local vat = 16/100

** Elasticidad: calculada por CIEP (2019) **
local elasticidad = -0.4240

** Margen: se asume un margen de 10.72% sobre el precio menos IVA **
** (Waters, Sainz de Miera & Reynales, 2010) **
local margen = .1072





****************************************
***                                  ***
***    3. CÁLCULO DEL ESTATUS QUO    ***
***                                  ***
****************************************

** Los precios de la base de datos incluyen impuestos; i.e. precios finales al consumidor **
use "`c(sysdir_site)'/tabaco/Nov2022/bases/tobaccotaxes.dta", clear

** IVA por cajetilla **
g vatxpack = precio*`vat'/(1+`vat')

** Margen del minorista **
g minmargen = (precio-vatxpack)*`margen'/(1+`margen')

** Impuesto específico por cajetilla **
g stxpack = `stax'*20

** Ad-valorem por cajetilla **
g avxpack = (precio-vatxpack-minmargen-stxpack)*`advala'/(1+`advala')

** Precio de la industria **
g pindustry = precio-vatxpack-minmargen-stxpack-avxpack

** Cambio en el precio **
g camb_precio = vatxpack+minmargen+stxpack+avxpack+pindustry



****************************
** Resultados estatus quo **
****************************

** Proporcion de impuesto sobre el precio **
g taxshare = ((vatxpack+stxpack+avxpack)/precio)*100

** Retail sales **
g rsales = sales*precio

** Recaudación por IVA **
g vatrev = sales*vatxpack

** Ingreso al minorista **
g minrev = sales*minmargen

** Ingreso por impuesto específico **
g strev = sales*stxpack
label var strev "Impuesto específico"

** Ingreso por Ad valorem **
g advrev = (sales*avxpack)
label var advrev "Impuesto ad-valorem"

** Ingresos de la industria **
g indusrev = (sales*pindustry)

** Participaciones **
g participa8=(strev+advrev)*0.08
g participa23=((strev+advrev)-participa8)*0.2339
g participaciones=participa8+participa23
g asalud=(strev+advrev)-participaciones





**************************************
***                                ***
***    4. CÁLCULO DEL ESCENARIO    ***
***                                ***
**************************************
g pindustry_1 = pindustry //*1.055				// <-- ¿DE DÓNDE VIENE ESTE DATO?

** Ad Valorem por cajetilla **
g avxpack_1 = (pindustry_1)*`advala_1'

** Impuesto especí­fico por cajetilla **
g stxpack_1 = `stax_1'*20

** Margen del minorista. Proporción fija respecto al precio mayorista. **
g minmargen_1 = minmargen //  (pindustry_1)*0.353243602			// <-- ¿DE DÓNDE VIENE ESTE DATO?

** IVA promedio por cajetilla **
g vatxpack_1 = (pindustry_1+stxpack_1+avxpack_1+minmargen_1)*`vat'

** Cambio en el precio **
g precio_1 = vatxpack_1+minmargen_1+stxpack_1+avxpack_1+pindustry_1



******************
*** Resultados ***
******************

** Cambio en ventas **
g sales_1=(sales*(((precio_1-precio)/precio)*`elasticidad'))+sales

** Proporción de impuesto sobre el precio **
g taxshare_1=((vatxpack_1+stxpack_1+avxpack_1)/precio_1)*100

** Retail sales **
g rsales_1=(sales_1*precio_1)

** Ingreso por IVA **
g vatrev_1=(sales_1*vatxpack_1)

** Ingreso al minorista **
g minrev_1=(sales_1*minmargen_1)

** Ingreso por impuesto especí­fico **
g strev_1=(sales_1*stxpack_1)
label var strev_1 "Impuesto específico"

** Ingreso por ad valorem **
g advrev_1=(sales_1*avxpack_1)
label var advrev_1 "Impuesto ad-valorem"

** Ingresos de la industria **
g indusrev_1=(sales_1*pindustry)

** Cambio en precio **
g deltaprecio=(precio_1-precio)/precio

** Participaciones **
gen participa8_1=(strev_1+advrev_1)*0.08
gen participa23_1=((strev_1+advrev_1)-participa8_1)*0.2339
gen participaciones_1=participa8_1+participa23_1
gen asalud_1=(strev_1+advrev_1)-participaciones_1



****************
*** Graficas ***
****************
if "$nographs" == "" {
	** Recaudacion por IEPS a tabaco **
	graph bar (asis) strev advrev if marca=="Cigarros", stack title(Estatus quo) name(Estatus, replace)
	graph bar (asis) strev_1 advrev_1 if marca=="Cigarros", stack title(Escenario 1) name(E1, replace)
	graph combine Estatus E1, title(Recaudación por IEPS a tabaco) ycommon name(RecIEPS, replace)
	window manage close graph Estatus
	window manage close graph E1

	** Cambio en ventas **
	graph bar (asis) sales sales_1 if marca=="Cigarros", ///
		title(Venta de cajetillas de cigarros) subtitle(Millones de cajetillas) ///
		name(Ventas, replace) legend(label(1 "Estatus Quo") label(2 "Escenario"))
}



***************************/
*** Outputs INFOGRAFÍA 1 ***
****************************
capture scalar drop pibY pibVPINF pibINF lambda
scalar aa_stax_1 = `stax_1'
scalar ab_advala_1 = `advala_1'*100
scalar ba_strev = strev[_N] + advrev[_N]
scalar bb_strev_1 = strev_1[_N] + advrev_1[_N]
scalar ca_participaciones_1 = participaciones_1[_N]
scalar cb_asalud_1 = asalud_1[_N]
scalar da_sales = sales[_N]
scalar db_sales = sales_1[_N]
scalar dc_sales = (sales_1[_N]/sales[_N]-1)*100
scalar ea_taxshare = taxshare[_N]
scalar eb_taxshare_1 = taxshare_1[_N]
scalar fa_precio = precio[_N]
scalar fb_precio_1 = precio_1[_N]





**************************************
***                                ***
***    5. ENTIDADES FEDERATIVAS    ***
***                                ***
**************************************
*if "$update" != "" {

	* Coeficientes de 2020 y 2021 *
	import excel "`c(sysdir_site)'/tabaco/Nov2022/bases/coeficientes.xlsx", sheet("Stata") firstrow clear
	levelsof entidad, local(entidades)
	tempfile coeficientes
	save `coeficientes'

	* Poblacion por entidad federativa *
	local j = 1
	foreach k of local entidades {
		noisily di _newline(3) "`k'"
		Poblacion if entidad == "`k'", nog
		collapse (sum) poblacion if anio == 2022, by(entidad anio)
		tempfile `j'
		save ``j''
		local ++j
	}

	* Unión de bases *
	use `coeficientes', clear
	g poblacion = .
	local j = 1
	foreach k of local entidades {
		noisily di _newline(3) "`k'"
		*use ``k'', clear
		merge 1:1 (entidad) using ``j'', nogen update
		local ++j
	}
	format %12.0fc poblacion
	sort cve_ent
	compress
	save "`c(sysdir_site)'/tabaco/Nov2022/bases/entidades.dta", replace
	preserve
	
	** Recaudación IEPS Tabaco anual **
	LIF, anio(2022)
	local recaudacion = r(Tabacos)

	** 8% directo **
	local directo8 = `recaudacion'*0.08

	** 92% restante de IEPS Tabaco se distribuye según los porcentajes de la LCF **
	** En la nota metodológica se ponen los porcentajes sobre el total de IEPS a tabaco **
	local ieps92  = `recaudacion'*0.92
	local fgp     = `ieps92'*0.2
	local litoral = `ieps92'*0.00136
	local ffm     = `ieps92'*0.01
	local ffr     = `ieps92'*0.0125
	*g fgp2        = recaudacion*0.184   	//servirá para la comprobación
	*g litoral2    = recaudacion*0.001256   // servirá para la comprobación

	* Distribucion estatal del 8% directo *
	restore
	g directo_estatal_21 = `directo8'*directo_estatal_1

	* Distribucion estatal del FGP *
	g fgp_estatal_21 = `fgp'*fgp_estatal_1

	* Distribucion estatal del litoral *
	g litoral_estatal_21 = `litoral'*litoral_estatal_1

	* Distribucion estatal del FFM *
	g ffm_estatal_21 = `ffm'*ffm_estatal_1

	* Distribucion estatal del FFR *
	g ffr_estatal_21 = `ffr'*ffr_estatal_1

	/*IEPS de tabaco total por Estado. El total de IEPS a tabaco por estado da 
	más en stata que en excel, creo que es por el número de decimales usados
	en cada programa*/

	* Total de IEPs a tabaco en estatus quo *
	egen iepst_estatal_21 = rsum(fgp_estatal_21 litoral_estatal_21 ffm_estatal_21 ///
		ffr_estatal_21 directo_estatal_21)

	* Distribucion porcuental de IEPS de tabaco estatal *
	*gen piepst_estatal_21=iepst_estatal_21/12497.96 // <-- ¿DE DÓNDE VIENE ESTE DATO?

	* Guardar los datos que no son actualizables *
	compress
	save "`c(sysdir_site)'/tabaco/Nov2022/bases/entidades.dta", replace
*}

use "`c(sysdir_site)'/tabaco/Nov2022/bases/entidades.dta", clear




























ex
gen stax_1=stax*20
local advalb_1 = advala/(1+advala)
*gen vata=0.16
*gen vatb=vata/(1+vata)
*gen vat_1= vata/(1+vata)
*gen elasticidad=-0.4240
*gen elasticidad_1=elasticidad*(1.2)


***********************************
*Esto es 2021 (hasta septiembre)
***********************************
























*********************************
***SimulaciÃ³n***
*********************************

**8% directo**
gen recaudacion_sim=59220.1   // <-- ¿DE DÓNDE VIENE ESTE DATO?
*gen recaudacion_sim=scalar(bb_strev_sim)
gen directo8_sim=recaudacion_sim*0.08

*el 92% restante de IEPS a tabaco se distribuye segun los porcentajes de la LCF; en la nota metodologica se ponen los porcentajes sobre el total de IEPS a tabaco
gen ieps92_sim=recaudacion_sim*0.92
gen fgp_sim=ieps92_sim*0.2
gen fgp2_sim=recaudacion_sim*0.184
gen litoral_sim=ieps92_sim*0.00136
gen litoral2_sim=recaudacion_sim*0.001256
gen ffm_sim=ieps92_sim*0.01
gen ffr_sim=ieps92_sim*0.0125


***********************************
*Esto es 2020 (anual)
***********************************
*Distribucion estatal del FGP*
gen fgp_estatal_20 = fgp_sim*fgp_estatal_0

*Distribucion estatal del litoral*
gen litoral_estatal_20 = litoral_sim*litoral_estatal_0

*Distribucion estatal del FFM*
gen ffm_estatal_20 = ffm_sim*ffm_estatal_0

*Distribucion estatal del FFR*
gen ffr_estatal_20 = ffr_sim*ffr_estatal_0

*Distribucion estatal del 8% directo*
gen directo_estatal_20 = directo8_sim*directo_estatal_0

	
	
/*IEPS de tabaco total por Estado. El total de IEPS a tabaco por estado da mÃ¡s
 en stata que en excel, creo que es por el nÃºmero de decimales usados en cada 
 programa*/
 
*Total de IEPs a tabaco en estatus quo*
gen iepst_estatal_20=fgp_estatal_20+litoral_estatal_20+ffm_estatal_20+ffr_estatal_20+directo_estatal_20

*distribucion porcuental deÃ± IEPS de tabaco estatal*
gen piepst_estatal_20=iepst_estatal_20/16875.96 


********************************************************************************
***************************DIFERENCIA ENTRE ESCENARIOS**************************
********************************************************************************

gen diferencia=iepst_estatal_20-iepst_estatal_21

****Crecimeinto recursos a estados ieps tabaco**

gen crecimiento = (diferencia/iepst_estatal_21)


********************************************************************************
***comprobación de que da igual aplicando porcentajes sobre el 100% del ieps***
*****************a tabaco o sobre el 92% del IEPS a tabaco*********************
********************************************************************************


gen fgp_estatal_3 = fgp2 * fgp_estatal_0
gen dif = fgp_estatal_3 - fgp_estatal_21
tab dif
	
	
gen litoral_estatal_3=litoral2 * litoral_estatal_0
gen dif_lit=litoral_estatal_3-litoral_estatal_21
tab dif_lit


**************/
*** Outputs ***
***************
forvalues k=1(1)32 {
	scalar DIF`k' = diferencia[`k']
	scalar IEPS`k' = iepst_estatal_20[`k']
	scalar orig`k' = iepst_estatal_20[`k']/scalar(bb_strev_sim)
	scalar dif`k' = diferencia[`k']/iepst_estatal_20[`k']
}
scalar crecimiento = crecimiento[_N]


noisily di _newline(3) in g "{bf:Tabaco} output de Entidades Federativas"
quietly log using "{{ruta}}/output.txt", name(scalar) replace text
*quietly log using "outputEstados.txt", name(scalar) replace text
noisily scalar list
quietly log close scalar




********************************************************************************
*********** InfografÃ­a 3 - Beneficios del aumento del IEPS al tabaco **********
********************************************************************************
*gen deltaprecio=0.43
*local deltaprecio=0.43
*gen elasticidad=-0.424
*local elaticidad=-0.424

** InformaciÃ³n de ENIGH 2020** Todos los valores son trimestrales
gen exp_tot=28228.96
la var exp_tot "Gasto total del hogar" 
gen hh_smoke=.0485 //cambie por enigh 2020 nota: en 2018 el porcentaje de hogares es 5.34%, pero aqui estaba puesto el valor de .00534 en 2020 el porcentaje es 4.85%, voy a poner el valor como .0485 que creo es el correcto
la var hh_smoke "ProporciÃ³n de hogares que reportan fumar"
gen exp_cig=.0025293 //secambio por lo de la enigh 2020
la var exp_cig "ProporciÃ³n de gasto en tabaco respecto al gasto total"
gen exp_salud=.093 //se actualizo con el que se utilizo en el reporte de 2021. Es de un estudio de Reynales, en el reporte esta la fuente completa
la var exp_salud "ProporciÃ³n de gasto en salud respecto al gasto total"
gen ilwy=.0019
la var ilwy "Income loss: working years	%"
gen exp_tab_p= 1263.159 //se actualizo con ENIGH 2020. Es el gasto en tabaco trimestral promedio de los hogares fumadores
la var exp_tab_p "Gasto en tabaco"


**Ganancias en ingresos: gasto en tabaco - %**
gen gi_gt=(((1+deltaprecio)*(1+elasticidad*deltaprecio)-1)*exp_cig)*-100

**Ganancias en ingresos: gasto en tabaco - $$**
gen gi_gt_p=(gi_gt*exp_tot)/100

**Ganancias en ingresos: gasto en salud - %**
gen gi_gs=(((1+elasticidad*deltaprecio)-1)*exp_salud)*-100

**Ganancias en ingresos: gasto en salud - $$**
gen gi_gs_p=(gi_gs*exp_tot)/100

**Ganancias en ingreso: dias de vida perdidos - %**
gen gi_yll=(((1+elasticidad*deltaprecio)-1)*ilwy)*-100

**Ganancias en ingreso: dias de vida perdidos - %**
gen gi_yll_p=(gi_yll*exp_tot)/100


****************/
*** Outputs 3 ***
*****************
capture scalar drop pibY pibVPINF pibINF lambda
scalar gi_gt = string(gi_gt[_N],"%10.1f")
scalar gi_gs = string(gi_gs[_N],"%10.1f")
scalar gi_yll = string(gi_yll[_N],"%10.1f")
scalar gi_gt_p = string(gi_gt_p[_N],"%10.1f")
scalar gi_gs_p = string(gi_gs_p[_N],"%10.1f")
scalar gi_yll_p = string(gi_yll_p[_N],"%10.1f")

noisily di _newline(3) in g "{bf:Tabaco} output"
quietly log using "{{ruta}}/output.txt", name(scalar) replace text
*quietly log using "output.txt", name(scalar) replace text
noisily scalar list
quietly log close scalar


noisily run "ccr_entidades_new.do"



** exit, clear STATA **
** 5 valores de resultados **
** ejecutar con  /usr/local/stata15/stata-se -q do_tobaccotaxes.do **

********************************************************************************
********************** Infografía 3 - Efecto empobrecedor **********************
********************************************************************************

clear
version 13
set mem 1000m
set more off



capture log close

cd "D:\Dropbox (CIEP)\Bloomberg Tabaco\2021\STATA"

log using "./empobrecedor.smcl", replace 

use Datos.dta

gen exptotal = gasto_mon*4 //gasto monetario del hogar al aÃ±o
gen exptobac = tabaco*4 //gasto anual en tabaco del hogar
gen exphealth = salud*4 //gasto anual en salud del hogar
gen expfood = (alimentos-tabaco)*4 //gasto anual en alimentos del hogar
gen expeducn = educacion*4 //gasto anual en educacion del hogar
gen exphousing = vivienda*4 //gasto anual en vivienda del hogar. Incluye renta, predial, agua y electricidad
gen expcloths = vesti_calz*4 //gasto anual en vestimenta y calzado del hogar.
gen expentertmnt = (esparci+paq_turist)*4 //gasto anual en esparcimiento del hogar
gen exptransport = (publico+foraneo+mantenim)*4 //gasto anual en transportacion del hogar. Incluye publico, foraneo, mantenimiento de carros
gen expdurable = adqui_vehi*4 //gasto anual del hogar en bienes duraderos. Incluye solo compra de vehiculos.
gen expother = (limpieza+comunica+personales+transf_gas)*4 //otros gastos anuales del hogar. Incuye limpieza, comonicaciones, gastos personales y ttransferencias como regalos.
gen hsize = tot_integ // TamaÃ±o del hogar
gen meanedu = promedioestudio //promedio de aÃ±os de estudio en el hogar
gen maxedu = estudiomaximo // aÃ±os maximos de estudio de alguien del hogar
gen sgroup = est_socio // variable que representa estrato socioeconomico de 1 a 4 en donde 1 es bajo
gen asexratio = hombres/mujeres //ratio de hombres a mujeres en el hogar. Es total, no es posible identificar cuantos menores son hombre o mujer.
gen hweight = factor //es el factor de expansion
gen npl = 19043.52

*following loop generate per capita expendituers and label them
foreach X in total tobac health{
gen pce`X'=exp`X'/hsize
label var pce`X' "percapita expenditure of `X'"
}
*SAF is Smoking (tobacco use) attributable fraction estimated externally
scalar SAF=0.54
replace pcehealth=pcehealth*SAF
*If SAF for SHS exposure is available, instead multiply the pcehealth
*variable with the sum of both SAFs

ren pcetotal pce //gasto total per capita
gen pcet=pce-pcetobac // gasto total per capita sin contar tabaco
label var pcet "pce-expenditure on tobacco"
gen pceh=pcet-pcehealth //gasto total per capita sin contar el gasto total en tabaco y en gastos medidcos relacionados al tabaco
label var pceh "pct-tobacco attributable health care exp."
gen pcehh=pce-pcehealth //gasto total per capita sin contar el gasto total en gastos medidcos relacionados al tabaco
gen pweight=hweight*hsize
*generating an indicator variable for poverty
gen povdum = 0
replace povdum = 1 if pce <= npl
proportion povdum [fw = pweight]
*the following user written module also gives identical result for HCR
*along with other poverty measures. To use this, first apply the following
*command without the star.
*ssc install povdeco, replace
povdeco pce [fw=pweight], varpline(npl)
*Code for computing changes in HCR and number of poor in one shot
local subtr pce pcet pcehh pceh
local nvar: word count `subtr'
matrix M = J(`nvar', 2, .)
forvalues i = 1/`nvar' {
local X: word `i' of `subtr'
qui gen ind = (`X'<=npl)
qui sum ind [fw=pweight]
matrix M[`i', 1] = r(mean)
matrix M[`i', 2] = r(sum)
drop ind
} 
matrix rownames M = `subtr'
matrix colnames M = HCR Poor
*the following lists the results with special formating options
matlist M, cspec(& %12s | %5.4f & %9.0f &) rspec(--&&&-)
log close




timer off 1
timer list 1
noisily di _newline(2) in g _dup(20) ":" "  " in y "TOUCH-DOWN!!!  " round(`=r(t1)/r(nt1)',.1) in g " segs  " _dup(20) ":"
