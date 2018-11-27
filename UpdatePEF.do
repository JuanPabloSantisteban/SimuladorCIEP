*****************************
**** BASE DE DATOS: PEFs ****
*****************************




************************
*** 1. BASE DE DATOS ***
************************
forvalues k=2013(1)2017 {
	import excel using "`c(sysdir_site)'/bases/PEFs/CP `k'.xlsx", clear firstrow
	drop if ciclo == .
	tostring ramo, replace
	destring aprobado ejercido, replace

	foreach j of varlist desc_* {
		replace `j' = trim(`j')
	}

	noisily tabstat aprobado ejercido, stat(sum) by(ciclo) f(%25.2fc)

	tempfile CP`k'
	save `CP`k''
}


** PEF actual **
import excel using "`c(sysdir_site)'/bases/PEFs/PEF 2018.xlsx", clear
drop if ciclo == .
tostring ramo, replace
destring aprobado, replace

foreach j of varlist desc_* {
	replace `j' = trim(`j')
}

noisily tabstat aprobado, stat(sum) by(ciclo) f(%25.2fc)

tempfile CPActual
save `CPActual'


** PEF siguiente **
import excel using "`c(sysdir_site)'/bases/PEFs/PEF 2019.xlsx", clear
drop if ciclo == .
tostring ramo, replace
capture confirm var proyecto
if _rc != 0 {
	g proyecto = .
}
destring proyecto, replace
destring aprobado, replace

noisily tabstat proyecto aprobado, stat(sum) by(ciclo) f(%25.2fc)

tempfile CPSiguiente
save `CPSiguiente'


** Append **
use `CP2013', clear
forvalues k=2014(1)2018 {
	append using `CP`k'', force
}
drop modificado devengado pagado adefas v*
order proyecto aprobado ejercido, last


** Cuotas ISSSTE **
destring proyecto aprobado ejercido, replace ignore(",")
g new = 0

set obs `=_N+1'
replace ciclo = 2013 in -1
replace aprobado = 41139800000 in -1
replace ejercido = 44835570079.16 in -1

set obs `=_N+1'
replace ciclo = 2014 in -1
replace aprobado = 42632320001 in -1
replace ejercido = 41679970244.42 in -1

set obs `=_N+1'
replace ciclo = 2015 in -1
replace aprobado = 44496476180 in -1
replace ejercido = 36157258395.67 in -1

set obs `=_N+1'
replace ciclo = 2016 in -1
replace aprobado = 74965214148 in -1
replace ejercido = 68642820898.42 in -1

set obs `=_N+1'
replace ciclo = 2017 in -1
replace aprobado = 91005191937 in -1

set obs `=_N+1'
replace ciclo = 2018 in -1
replace proyecto = 99233509443 in -1
replace aprobado = 99233509443 in -1

foreach k of varlist ramo-cartera {
	capture confirm numeric variable `k'
	if _rc == 0 {
		replace `k' = -1 if new == .
	}
	else {
		replace `k' = "Cuotas ISSSTE" if new == .
	}
}

drop new





**********************
*** 2. HOMOLOGACION ***
**********************

** Acentos **
foreach k of varlist _all {
	di in w ".", _cont
	capture confirm string variable `k'
	if _rc == 0 {
		quietly replace `k' = subinstr(`k',`"""',"",.)
		quietly replace `k' = subinstr(`k',"'","",.)
		quietly replace `k' = trim(`k')
		forvalues j=1(1)`=_N' {
			quietly replace `k' = `"`=`k'[`j']'"' in `j'
		}
	}
}


** Anio **/
rename ciclo anio


** Neto **
g byte neto = (ramo == "19" & ur == "GYN") | (ramo == "19" & ur == "GYR")


** Ramo **
replace ramo = "50" if ramo == "GYR"
replace ramo = "51" if ramo == "GYN"
replace ramo = "52" if ramo == "TZZ" | ur == "TZZ"
replace ramo = "53" if ramo == "TOQ" | ur == "TOQ"
replace ramo = "-1" if ramo == "Cuotas ISSSTE"
destring ramo, replace

replace desc_ramo = "Oficina de la Presidencia de la Rep${u}blica" if ramo == 2
replace desc_ramo = "Instituto Nacional Electoral" if ramo == 22
replace desc_ramo = "Tribunal Federal de Justicia Administrativa" if ramo == 32
replace desc_ramo = "Instituto Nacional de Transparencia, Acceso a la Informaci${o}n y Protecci${o}n de Datos Personales" if ramo == 44

replace desc_ramo = "Petr${o}leos Mexicanos" if ramo == 52
replace desc_ramo = "Comisi${o}n Federal de Electricidad" if ramo == 53

labmask ramo, values(desc_ramo)
drop desc_ramo


** Descripci${o}n Unidad Responsable **
rename desc_ur desc_ur2
encode desc_ur2 if desc_ur2 != "Cuotas ISSSTE", g(desc_ur)
replace desc_ur = -1 if desc_ur == .
label define desc_ur -1 "Cuotas ISSSTE", add
drop desc_ur2


** Descripci${o}n Finalidad **
labmask finalidad, values(desc_finalidad)
drop desc_finalidad


** Descripci${o}n Funcion **
rename desc_funcion desc_funcion2
encode desc_funcion2 if desc_funcion2 != "Cuotas ISSSTE", g(desc_funcion)
replace desc_funcion = -1 if desc_funcion == .
label define desc_funcion -1 "Cuotas ISSSTE", add
drop desc_funcion2


** Descripci${o}n Subfuncion **
rename desc_subfuncion desc_subfuncion2
encode desc_subfuncion2 if desc_subfuncion2 != "Cuotas ISSSTE", g(desc_subfuncion)
replace desc_subfuncion = -1 if desc_subfuncion == .
label define desc_subfuncion -1 "Cuotas ISSSTE", add
drop desc_subfuncion2


** Descripci${o}n Actividad Institucional **
rename desc_ai desc_ai2
encode desc_ai2 if desc_ai2 != "Cuotas ISSSTE", g(desc_ai)
replace desc_ai = -1 if desc_ai == .
label define desc_ai -1 "Cuotas ISSSTE", add
drop desc_ai2


** Descripci${o}n Modalidad **
rename desc_modalidad desc_modalidad2
encode desc_modalidad2 if desc_modalidad2 != "Cuotas ISSSTE", g(desc_modalidad)
replace desc_modalidad = -1 if desc_modalidad == .
label define desc_modalidad -1 "Cuotas ISSSTE", add
drop desc_modalidad2


** Descripci${o}n Programa Presupuestario **
rename desc_pp desc_pp2
encode desc_pp2 if desc_pp2 != "Cuotas ISSSTE", g(desc_pp)
replace desc_pp = -1 if desc_pp == .
label define desc_pp -1 "Cuotas ISSSTE", add
drop desc_pp2


** Descripci${o}n Objeto **
rename desc_objeto desc_objeto2
encode desc_objeto2 if desc_objeto2 != "Cuotas ISSSTE", g(desc_objeto)
replace desc_objeto = -1 if desc_objeto == .
label define desc_objeto -1 "Cuotas ISSSTE", add
drop desc_objeto2


** Descripci${o}n Tipo de Gasto **
rename desc_tipogasto desc_tipogasto2
encode desc_tipogasto2 if desc_tipogasto2 != "Cuotas ISSSTE", g(desc_tipogasto)
replace desc_tipogasto = -1 if desc_tipogasto == .
label define desc_tipogasto -1 "Cuotas ISSSTE", add
drop desc_tipogasto2


** Descripci${o}n Fuente **
labmask fuente, values(desc_fuente)
drop desc_fuente


** Descripci${o}n Entidad Federativa **
replace desc_entidad = trim(desc_entidad)
replace desc_entidad = "Ciudad de M${e}xico" if entidad == 9
labmask entidad, values(desc_entidad)
drop desc_entidad


** Cap${i}tulo **
drop capitulo
g capitulo = substr(string(objeto),1,1) if objeto != -1
destring capitulo, replace

label define capitulo 1 "Servicios personales" 2 "Materiales y suministros" ///
	3 "Gastos generales" 4 "Subsidios y transferencias" ///
	5 "Bienes muebles e inmuebles" 6 "Obras p${u}blicas" 7 "Inversi${o}n financiera" ///
	8 "Participaciones y aportaciones" 9 "Deuda p${u}blica" -1 "Cuotas ISSSTE"
label values capitulo capitulo


** Series **
g serie = "XNB0555" if desc_funcion == 1
replace serie = "XOA0424" if desc_funcion == 2
replace serie = "XOA0423" if desc_funcion == 3
replace serie = "XOA0410" if desc_funcion == 4
replace serie = "XOA0412" if desc_funcion == 5
replace serie = "XOA0430" if desc_funcion == 6
replace serie = "XOA0425" if desc_funcion == 7
replace serie = "XOA0428" if desc_funcion == 8
replace serie = "XOA0408" if desc_funcion == 9
replace serie = "XOA0419" if desc_funcion == 10
replace serie = "XOA0407" if desc_funcion == 11
replace serie = "XOA0402" if desc_funcion == 12
replace serie = "XOA0426" if desc_funcion == 13
replace serie = "XOA0431" if desc_funcion == 14
replace serie = "XOA0421" if desc_funcion == 15
replace serie = "XOA0413" if desc_funcion == 16
replace serie = "XOA0415" if desc_funcion == 17
replace serie = "XOA0420" if desc_funcion == 18
replace serie = "XOA0418" if desc_funcion == 19
replace serie = "XOA0409" if desc_funcion == 20
replace serie = "XOA0417" if desc_funcion == 21
replace serie = "" if desc_funcion == 22
replace serie = "XOA0411" if desc_funcion == 23
replace serie = "XAC21" if desc_funcion == 24
replace serie = "XAC2800" if desc_funcion == 25
replace serie = "XOA0427" if desc_funcion == 26
replace serie = "XOA0429" if desc_funcion == 27
replace serie = "XOA0416" if desc_funcion == 28
replace serie = "XKG0116" if desc_funcion == -1

rename serie series
encode series, generate(serie)
drop series


** Modulos **
g modulo = "uso_Pension1" if neto == 0 & ramo != -1 ///
		& (substr(string(objeto),1,2) == "45" | substr(string(objeto),1,2) == "47" | pp == 176)

replace modulo = "uso_Educaci2" if neto == 0 & ramo != -1 ///
		& (substr(string(objeto),1,2) != "45" & substr(string(objeto),1,2) != "47" & pp != 176) ///
		& desc_funcion == 10

replace modulo = "uso_Salud3" if neto == 0 & ramo != -1 ///
		& (substr(string(objeto),1,2) != "45" & substr(string(objeto),1,2) != "47" & pp != 176) ///
		& desc_funcion != 10 ///
		& desc_funcion == 21

replace modulo = "uso_Salud3" if neto == 0 & ramo != -1 ///
		& (substr(string(objeto),1,2) != "45" & substr(string(objeto),1,2) != "47" & pp != 176) ///
		& (modalidad == "E" & pp == 13 & ramo == 52)


** Saving **
order ramo desc_ur finalidad desc_funcion desc_subfuncion desc_ai desc_modalidad ///
	desc_pp desc_objeto desc_tipogasto fuente entidad serie ///
	proyecto aprobado ejercido 
format %30.0fc ramo desc_ur finalidad desc_funcion desc_subfuncion desc_ai desc_modalidad ///
	desc_pp desc_objeto desc_tipogasto fuente entidad serie
format %20.0fc proyecto aprobado ejercido

compress
save "`c(sysdir_site)'/bases/SIM/PEF.dta", replace
