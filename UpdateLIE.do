clear all
clear programs
macro drop _all
capture log close _all
*do ""`c(sysdir_site)'../../Hewlett Subnacional\Base de datos\LIE\Limpiador_INEGI_18a20.do"
local entidadesN `" "Aguascalientes" "Baja California" "Baja California Sur" "Campeche" "Coahuila" "Colima" "Chiapas" "Chihuahua" "Ciudad de México" "Durango" "Guanajuato" "Guerrero" "Hidalgo" "Jalisco" "México" "Michoacán" "Morelos" "Nayarit" "Nuevo León" "Oaxaca" "Puebla" "Querétaro" "Quintana Roo" "San Luis Potosí" "Sinaloa" "Sonora" "Tabasco" "Tamaulipas" "Tlaxcala" "Veracruz" "Yucatán" "Zacatecas" "Nacional" "'
local entidades "Ags BC BCS Camp Coah Col Chis Chih CDMX Dgo Gto Gro Hgo Jal EdoMex Mich Mor Nay NL Oax Pue Qro QRoo SLP Sin Son Tab Tamps Tlax Ver Yuc Zac"
tokenize `entidades'

global export "`c(sysdir_site)'../../Hewlett Subnacional/Documento LaTeX/images"





*********************
*** PIB Entidades ***
/*********************
import excel "`c(sysdir_site)'../basesCIEP/INEGI/SCN/PIB entidades federativas.xlsx", clear
LimpiaBIE
rename A anio
local j = 1
foreach k of varlist B-AG {
	rename `k' pibYEnt``j''
	local ++j
}
reshape long pibYEnt, i(anio) j(entidad) string
tempfile PIBEntidades
save `PIBEntidades'



*** PIB Deflactor ***
PIBDeflactor, nographs
tempfile PIBDeflactor
save `PIBDeflactor'



*** ITAEE ***
import excel "`c(sysdir_site)'../basesCIEP/INEGI/SCN/ITAEE.xlsx", clear
LimpiaBIE, nomultiply
split A, parse("/")
drop A
rename A1 anio
rename A2 trimestre
destring anio trimestre, replace
order anio trimestre

collapse (mean) B-AG, by(anio)
set obs `=_N+1'
replace anio = anio[_N-1]+1 in -1

local j = 1
foreach k of varlist B-AG {
	replace `k' = 3.4 in -1
	rename `k' ITAEE``j''
	local ++j
}
reshape long ITAEE, i(anio) j(entidad) string

merge 1:1 (anio entidad) using `PIBEntidades', nogen
merge m:1 (anio) using `PIBDeflactor', nogen keepus(deflator)

encode entidad, gen(entidadx)
xtset entidadx anio
replace pibYEnt = L.pibYEnt*(1+ITAEE/100)*deflator if pibYEnt == .

keep if anio >= 2003 & anio <= 2022
save "`c(sysdir_site)'../../Hewlett Subnacional/Base de datos/PIBEntidades.dta", replace





***************************************/
*** Poblacion por Entidad Federativa ***
/****************************************
local j = 1
foreach k of local entidadesN {
	Poblacion if entidad == "`k'", nographs
	collapse (sum) pob*, by(entidad anio)
	format pob* %10.0fc
	rename entidad entidad1
	g entidad = "``j''"
	scalar poblacion``j'' = poblaciontotal
	tempfile Pob``j''
	save `Pob``j'''
	local ++j
}
local j = 1
forvalues k=1(1)32 {
	if `k' == 1 {
		use `Pob``j''', clear
	}
	else {
		append using `Pob``j'''
	}
	local ++j
}
drop entidad1
noisily scalarlatex, logname(pob)
save "`c(sysdir_site)'../../Hewlett Subnacional/Base de datos/PobTot.dta", replace





***********************************/
*** Participaciones y sus fondos ***
/***********************************
local series28 `""" A B C D E F G H I J K L M"'
*local series28 `""""'

local series33 `""" A B C D E F G H I J K L M N O"'
*local series33 `""""'

local series23 `""" A B C"'
*local series23 `""""'

local seriesCD `""" A D E"'
*local seriesCD `""""'

local seriesCR `""""'
local seriesPSS `""""'
foreach gastofed in 28 33 PSS 23 CD CR {
	foreach fondo of local series`gastofed' {

		local serie "XAC`gastofed'`fondo'"
		local j = 1

		forvalues k=1(1)32 {
			noisily DatosAbiertos `serie'`=string(`k',"%02.0f")', nographs
			if r(error) != 2000 {
				* Limpiar base intermedia *
				split nombre, gen(entidad) parse(":")
				drop nombre
				rename entidad2 concepto
				g entidad = "``j''"
			}

			* Guardar bases estados *
			tempfile `serie'`=string(`k',"%02.0f")'
			save ``serie'`=string(`k',"%02.0f")''
			local ++j
		}

		* Unir bases estados *
		use ``serie'01', clear
		forvalues k=2(1)32 {
			append using ``serie'`=string(`k',"%02.0f")''
		}
		tempfile XAC`gastofed'`fondo'
		save `XAC`gastofed'`fondo''
	}
}

local j = 0
foreach gastofed in 28 33 PSS 23 CD CR {
	foreach fondo of local series`gastofed' {
		if `j' == 0 {
			use `XAC`gastofed'', clear
			local ++j
		}
		else {
			append using `XAC`gastofed'`fondo''
		}
	}
}
save "`c(sysdir_site)'../../Hewlett Subnacional/Base de datos/GastoFedBase.dta", replace





*****************/
*** LIEs INEGI ***
******************
use "`c(sysdir_site)'../../Hewlett Subnacional/Base de datos/LIE/INEGI/LIEs.dta"

capture replace entidad1 = "México" if entidad1 == "Mexico"
capture replace entidad1 = "Ciudad de México" if entidad1 == "CDMX"
capture replace entidad1 = "San Luis Potosí" if entidad1 == "San Luis Potosi"

replace Entidades = "veracruz" if Entidades == "veracruzdeignaciodelallave"
replace Entidades = "michoacán" if Entidades == "michoacándeocampo" | Entidades == "michoacan"
replace Entidades = "querétaro" if Entidades == "queretaro"
replace Entidades = "coahuila" if Entidades == "coahuiladezaragoza"

capture replace Entidades = lower(entidad1) if entidad1 != "" & Entidades == ""
foreach k of varlist Entidades /*entidad1 desc_entidad*/ {
	capture replace `k'= subinstr(`k', "{c a'}","á",.)
	capture replace `k'= subinstr(`k', "{c e'}","é",.)
	capture replace `k'= subinstr(`k', "{c i'}","í",.)
	capture replace `k'= subinstr(`k', "{c o'}","ó",.)
	capture replace `k'= subinstr(`k', "{c u'}","ú",.)
}

replace Entidades = subinstr(Entidades," ","",.)
local j = 1
drop entidad
g entidad = trim(desc_entidad)
if _rc != 0 {
	g entidad = ""
}
replace entidad = "EdoMex" if entidad == "Edomex"
replace entidad = "QRoo" if entidad == "Qroo"

foreach k of local entidadesN {
	replace entidad = "``j''" if Entidades == `"`=subinstr("`=lower("`k'")'"," ","",.)'"'
	local ++j
}
save "`c(sysdir_site)'../../Hewlett Subnacional/Base de datos/LIE/INEGI/LIEs.dta", replace
collapse (sum) monto, by(anio entidad tipo_ingreso)
save "`c(sysdir_site)'../../Hewlett Subnacional/Base de datos/LIE/INEGI/LIEs_colapsada.dta", replace





***********/
* Graficas *
************
use "`c(sysdir_site)'../../Hewlett Subnacional/Base de datos/GastoFedBase.dta", clear
merge m:1 (anio entidad) using "`c(sysdir_site)'../../Hewlett Subnacional/Base de datos/PIBEntidades.dta", nogen
merge m:1 (anio entidad) using "`c(sysdir_site)'../../Hewlett Subnacional/Base de datos/PobTot.dta", nogen keep(matched)
keep if anio >= 2013 & anio <= 2022


* Gasto federalizado *

g concepto2 = "Participaciones" if substr(clave,1,5) == "XAC28" & strlen(clave) == 8
replace concepto2 = "Aportaciones" if substr(clave,1,5) == "XAC33" & strlen(clave) == 8
replace concepto2 = "Provisiones salariales" if substr(clave,1,5) == "XAC23" & strlen(clave) == 8
replace concepto2 = "Convenios" if (substr(clave,1,5) == "XACCD" & strlen(clave) == 8) | (substr(clave,1,5) == "XACCR" & strlen(clave) == 7)
replace concepto2 = "Protección Social en Salud" if substr(clave,1,6) == "XACPSS"

g conceptograph = trim(concepto)
replace conceptograph = "0.136% de la RFP" if conceptograph == "0.136% de la Recaudaci?n Federal Participable"
replace conceptograph = "FGP" if conceptograph == "Fondo General de Participaciones"
replace conceptograph = "FFM" if conceptograph == "Fondo de Fomento Municipal"
replace conceptograph = "Repecos" if conceptograph == "Fondo de Compensaci?n de Repecos Intermedios"
replace conceptograph = "Fiscalización" if conceptograph == "Fondo de Fiscalizaci?n a Entidades Federativas"
replace conceptograph = "FExHi" if conceptograph == "Fondo de Extracci?n de Hidrocarburos"
replace conceptograph = "FExHi" if conceptograph == "Participaciones por el Derecho Adicional sobre la Extracci?n de Petr?leo"
replace conceptograph = "IEPS" if conceptograph == "Participaciones por el Impuesto Especial sobre Producci?n y Servicios (IEPS)"
replace conceptograph = "IEPS" if conceptograph == "Participaciones por el Impuesto Especial sobre Producci?n y Servicios de Gasolinas y Diesel (IEPS Gasolinas) Art?culo 2?.-A Fracci?n II Ley del IEPS"
replace conceptograph = "ISAN" if conceptograph == "Participaciones por el Impuesto sobre Autom?viles Nuevos (ISAN)"
replace conceptograph = "Tenencia" if conceptograph == "Participaciones por el Impuesto sobre Tenencia y Uso de Autom?viles"
replace conceptograph = "Incentivos económicos" if conceptograph == "Incentivos Econ?micos"

g inicial = strpos(concepto,"(")
g final = strpos(concepto,")")
replace conceptograph = substr(concepto,inicial+1,final-inicial-1) if substr(clave,1,5) == "XAC33" & strlen(clave) == 8

replace conceptograph = substr(concepto,inicial+1,final-inicial-1) if substr(clave,1,4) == "XACC" & strlen(clave) == 8
replace conceptograph = "Reasignación" if conceptograph == "Convenios de Reasignaci?n"

replace conceptograph = "Provisiones salariales" if concepto2 == "Provisiones salariales"

keep if ((substr(clave,1,5) == "XAC28" | substr(clave,1,5) == "XAC33" | substr(clave,1,5) == "XAC23" ///
	| substr(clave,1,5) == "XACCD") ///
	& strlen(clave) == 8) | substr(clave,1,5) == "XACCR" | substr(clave,1,6) == "XACPSS"

preserve
collapse (sum) monto (mean) poblacion deflator, by(entidad anio conceptograph concepto2)
tempvar montograph montopibYE
g `montograph' = monto/poblacion/deflator
graph bar (mean) `montograph' if anio <= 2021 & concepto2 == "Participaciones" [fw=poblacion], ///
	over(conceptograph, sort(1) descending) ///
	over(anio) ///
	asyvar stack ///
	///title(Gasto {bf:federalizado}) ///
	///subtitle(Por entidad federativa) ///
	ytitle("per c{c a'}pita (MXN 2022)") ///
	ylabel(, format(%7.0fc)) ///
	blabel(bar, format(%7.0fc)) ///
	legend(rows(2)) ///
	name(XAC28, replace)
graph export "$export/XAC28.png", replace name(XAC28)

graph bar (mean) `montograph' if anio <= 2021 & concepto2 == "Aportaciones" [fw=poblacion], ///
	over(conceptograph, sort(1) descending) ///
	over(anio) ///
	asyvar stack ///
	///title(Gasto {bf:federalizado}) ///
	///subtitle(Por entidad federativa) ///
	ytitle("per c{c a'}pita (MXN 2022)") ///
	ylabel(, format(%7.0fc)) ///
	blabel(bar, format(%7.0fc)) ///
	legend(rows(2)) ///
	name(XAC33, replace)
graph export "$export/XAC33.png", replace name(XAC33)

graph bar (mean) `montograph' if anio <= 2021 & concepto2 == "Convenios" [fw=poblacion], ///
	over(conceptograph, sort(1) descending) ///
	over(anio) ///
	asyvar stack ///
	///title(Gasto {bf:federalizado}) ///
	///subtitle(Por entidad federativa) ///
	ytitle("per c{c a'}pita (MXN 2022)") ///
	ylabel(, format(%7.0fc)) ///
	blabel(bar, format(%7.0fc)) ///
	legend(rows(1)) ///
	name(XACC, replace)
graph export "$export/XACC.png", replace name(XACC)

graph bar (mean) `montograph' if anio <= 2021 & concepto2 == "Protección Social en Salud" [fw=poblacion], ///
	over(conceptograph, sort(1) descending) ///
	over(anio) ///
	asyvar stack ///
	///title(Gasto {bf:federalizado}) ///
	///subtitle(Por entidad federativa) ///
	ytitle("per c{c a'}pita (MXN 2022)") ///
	ylabel(, format(%7.0fc)) ///
	blabel(bar, format(%7.0fc)) ///
	legend(rows(1)) ///
	name(XACPSS, replace)
graph export "$export/XACPSS.png", replace name(XACPSS)

graph bar (mean) `montograph' if anio <= 2021 & concepto2 == "Provisiones salariales" [fw=poblacion], ///
	over(conceptograph, sort(1) descending) ///
	over(anio) ///
	asyvar stack ///
	///title(Gasto {bf:federalizado}) ///
	///subtitle(Por entidad federativa) ///
	ytitle("per c{c a'}pita (MXN 2022)") ///
	ylabel(, format(%7.0fc)) ///
	blabel(bar, format(%7.0fc)) ///
	legend(rows(1)) ///
	name(XACPS, replace)
graph export "$export/XACPS.png", replace name(XACPS)

restore
preserve
collapse (sum) monto (mean) poblacion deflator, by(entidad anio concepto2)
g `montograph' = monto/poblacion/deflator
graph bar (mean) `montograph' if anio <= 2021 [fw=poblacion], ///
	over(concepto2, sort(1) descending) ///
	over(anio) ///
	asyvar stack ///
	///title(Gasto {bf:federalizado}) ///
	///subtitle(Por entidad federativa) ///
	ytitle("per c{c a'}pita (MXN 2022)") ///
	ylabel(, format(%7.0fc)) ///
	blabel(bar, format(%7.0fc)) ///
	legend(rows(1)) ///
	name(GasFed, replace)
graph export "$export/GasFed.png", replace name(GasFed)
save "`c(sysdir_site)'../../Hewlett Subnacional/Base de datos/LIEs_GF_total.dta", replace
levelsof entidad, local(entidades)
foreach k of local entidades {
	graph bar (mean) `montograph' if anio <= 2021 & entidad == "`k'" [fw=poblacion], ///
		over(concepto2, sort(1) descending) ///
		over(anio) ///
		asyvar stack ///
		///title(Gasto {bf:federalizado}) ///
		///subtitle(Por entidad federativa) ///
		ytitle("per c{c a'}pita (MXN 2022)") ///
		ylabel(, format(%7.0fc)) ///
		blabel(bar, format(%7.0fc)) ///
		legend(off) ///
		name(GasFed`k', replace)
	graph export "$export/GasFed_`k'.png", replace name(GasFed`k')

}
save "`c(sysdir_site)'../../Hewlett Subnacional/Base de datos/LIEs_GF.dta", replace

forvalues k=1(1)`=_N' {
	if anio[`k'] == 2021 {
		scalar `=substr(concepto2[`k'],1,4)'`=entidad[`k']' = `montograph'[`k']
	}
}

collapse (sum) monto poblacion (mean) deflator if anio == 2021, by(anio concepto2)
g `montograph' = monto/poblacion/deflator
forvalues k=1(1)`=_N' {
	scalar GasFed`=substr(concepto2[`k'],1,4)' = `montograph'[`k']
}
scalar GasFedGasFed = GasFedApor + GasFedConv + GasFedPart + GasFedProt + GasFedProv

restore
preserve 
collapse (sum) monto (mean) poblacion deflator pibYEnt, by(entidad anio)
g `montograph' = monto/poblacion/deflator
g `montopibYE' = monto/pibYEnt*100
forvalues k=1(1)`=_N' {
	if anio[`k'] == 2021 {
		scalar GasFed`=entidad[`k']' = `montograph'[`k']
		scalar GasFedPIB`=entidad[`k']' = `montopibYE'[`k']
	}
}

restore
collapse (sum) monto, by(entidad anio)
g tipo_ingreso = "Federalizado"
drop if anio == 2022
save "`c(sysdir_site)'../../Hewlett Subnacional/Base de datos/GastoFedSum.dta", replace

*/

* LIEs */
*
use "`c(sysdir_site)'../../Hewlett Subnacional/Base de datos/LIE/INEGI/LIEs_colapsada.dta", clear
merge 1:1 (anio entidad tipo_ingreso) using "`c(sysdir_site)'../../Hewlett Subnacional/Base de datos/GastoFedSum.dta", nogen update replace
merge m:1 (anio entidad) using "`c(sysdir_site)'../../Hewlett Subnacional/Base de datos/PIBEntidades.dta", nogen
merge m:1 (anio entidad) using "`c(sysdir_site)'../../Hewlett Subnacional/Base de datos/PobTot.dta", nogen
keep if anio >= 2018 & anio <= 2022
tempfile ajustador
save "`ajustador'"
clear
********************************************
**Estimar Impuestos faltante 2021
/*use "C:\Users\Admin\Dropbox (CIEP)\Hewlett Subnacional\Base de datos\LIE\INEGI\LIEs.dta" , clear
drop id_entidad
merge m:1 entidad using "C:\Users\Admin\Dropbox (CIEP)\Hewlett Subnacional\Base de datos\ID_entidad.dta" 
drop _merge
egen OK=anymatch(id_entidad), values(10 32 14 31 28 3 2 5 29 22 27 18 26 12 17)
tempfile original
save "`original'"

drop if anio==2021
tempfile original_sin2021
save "`original_sin2021'"
clear
use "`original'", replace

*Base a cambiar
keep if OK & concepto=="Impuestos" & anio==2021
drop OK concepto_desagregado concepto_tipo 
tempfile 2021_cambio
save "`2021_cambio'"
*Bases con estimacion
use "`original'", clear
drop if OK & concepto=="Impuestos" & anio==2021
drop OK
tempfile 2021_sin
save "`2021_sin'"
clear
*base filtrada 2018-2020
use "`original'"
keep if anio <2021
keep if OK & concepto=="Impuestos"
*collapse
collapse (sum) monto, by(anio entidad concepto concepto_desagregado concepto_tipo)
egen total=total(monto), by(anio entidad )
g perc=monto/total
*Porcentaje promedio
collapse (mean) perc, by(entidad concepto_desagregado concepto_tipo)
tempfile percen
save "`percen'"
merge m:1 entidad using "`2021_cambio'"
drop _merge
*Calculamos
g monto_estimado=monto*perc
replace monto=monto_estimado
drop perc monto_estimado
tempfile 2021_cambiada
save "`2021_cambiada'"
append using "`2021_sin'"
*replace concepto_desagregado="Impuestos" if anio==2022 & id_entidad==17 & concepto=="Impuestos"
save "C:\Users\Admin\Dropbox (CIEP)\Hewlett Subnacional\Base de datos\LIE\INEGI\LIEs.dta" , replace


*********************************************

****Ahora 2022

*******************************************
use "C:\Users\Admin\Dropbox (CIEP)\Hewlett Subnacional\Base de datos\LIE\INEGI\LIEs.dta" , clear
drop id_entidad
merge m:1 entidad using "C:\Users\Admin\Dropbox (CIEP)\Hewlett Subnacional\Base de datos\ID_entidad.dta" 
drop _merge
egen OK=anymatch(id_entidad), values(17)
tempfile original
save "`original'"

drop if anio==2022
tempfile original_sin2022
save "`original_sin2022'"
clear
use "`original'", replace

*Base a cambiar
keep if OK & concepto=="Impuestos" & anio==2022
drop OK concepto_desagregado concepto_tipo 
tempfile 2022_cambio
save "`2022_cambio'"
*Bases con estimacion
use "`original'", clear
drop if OK & concepto=="Impuestos" & anio==2022
drop OK
tempfile 2022_sin
save "`2022_sin'"
clear
*base filtrada 2018-2020
use "`original'"
keep if anio <2021
keep if OK & concepto=="Impuestos"
*collapse
collapse (sum) monto, by(anio entidad concepto concepto_desagregado concepto_tipo)
egen total=total(monto), by(anio entidad )
g perc=monto/total
*Porcentaje promedio
collapse (mean) perc, by(entidad concepto_desagregado concepto_tipo)
tempfile percen
save "`percen'"
merge m:1 entidad using "`2022_cambio'"
drop _merge
*Calculamos
g monto_estimado=monto*perc
replace monto=monto_estimado
drop perc monto_estimado
tempfile 2022_cambiada
save "`2022_cambiada'"
append using "`2022_sin'"
*replace concepto_desagregado="Impuestos" if anio==2022 & id_entidad==17 & concepto=="Impuestos"
save "C:\Users\Admin\Dropbox (CIEP)\Hewlett Subnacional\Base de datos\LIE\INEGI\LIEs.dta" , replace

*/









****************************************
use "`ajustador'", replace

save "`c(sysdir_site)'../../Hewlett Subnacional/Base de datos/IngresosEntidades.dta", replace
use "`c(sysdir_site)'../../Hewlett Subnacional/Base de datos/IngresosEntidades.dta", replace
drop if entidad=="Nacional"
preserve
collapse (sum) monto (mean) poblacion deflator, by(entidad anio tipo_ingreso)
tempvar montograph
g `montograph' = monto/poblacion/deflator
graph bar (mean) `montograph' if `montograph' != . [fw=poblacion], ///
	over(tipo_ingreso, sort(1) descending) ///
	over(anio) ///
	stack asyvars ///
	///title(Gasto {bf:federalizado}) ///
	///subtitle(Por entidad federativa) ///
	ytitle("per c{c a'}pita (MXN 2022)") ///
	ylabel(, format(%7.0fc)) ///
	blabel(bar, format(%7.0fc)) ///
	legend(rows(1)) ///
	name(LIEs, replace)
graph export "$export/LIEs.png", replace name(LIEs)
save "`c(sysdir_site)'../../Hewlett Subnacional/Base de datos/LIEs_TipoIngreso_Total.dta",replace

levelsof entidad, local(entidades)
foreach k of local entidades {
	graph bar (mean) `montograph' if `montograph' != . & entidad == "`k'" [fw=poblacion], ///
		over(tipo_ingreso, sort(1) descending) ///
		over(anio) ///
		stack asyvars ///
		///title(Gasto {bf:federalizado}) ///
		///subtitle(Por entidad federativa) ///
		ytitle("per c{c a'}pita (MXN 2022)") ///
		ylabel(, format(%7.0fc)) ///
		blabel(bar, format(%7.0fc)) ///
		legend(off) ///
		name(LIEs_`k', replace)
	graph export "$export/LIEs_`k'.png", replace name(LIEs_`k')
}


drop `montograph'
save "`c(sysdir_site)'../../Hewlett Subnacional/Base de datos/LIEs_tipoingreso.dta", replace
reshape wide monto poblacion, i(anio tipo_ingreso) j(entidad) string
reshape long
g `montograph' = monto/poblacion/deflator

forvalues k=1(1)`=_N' {
	if anio[`k'] == 2022 & tipo_ingreso[`k'] == "Federalizado" {
		scalar LIEFed`=entidad[`k']' = `montograph'[`k']
	}
	if anio[`k'] == 2022 & tipo_ingreso[`k'] == "Recursos Propios" {
		scalar LIERec`=entidad[`k']' = `montograph'[`k']
	}
	if anio[`k'] == 2022 & tipo_ingreso[`k'] == "Organismos y Empresas" {
		scalar LIEOyE`=entidad[`k']' = `montograph'[`k']
	}
	if anio[`k'] == 2022 & tipo_ingreso[`k'] == "Financiamiento" {
		scalar LIEFin`=entidad[`k']' = `montograph'[`k']
	}
}

collapse (sum) monto (mean) poblacion deflator, by(anio entidad)
tempvar montograph
g `montograph' = monto/poblacion/deflator
forvalues k=1(1)`=_N' {
	if anio[`k'] == 2022 {
		scalar LIETot`=entidad[`k']' = `montograph'[`k']
	}
}


restore
preserve

collapse (sum) monto poblacion (mean) deflator, by(anio tipo_ingreso)
tempvar montograph
g `montograph' = monto/poblacion/deflator
forvalues k=1(1)`=_N' {
	if anio[`k'] == 2022 & tipo_ingreso[`k'] == "Federalizado" {
		scalar LIEFedNac = `montograph'[`k']
	}
	if anio[`k'] == 2022 & tipo_ingreso[`k'] == "Recursos Propios" {
		scalar LIERecNac = `montograph'[`k']
	}
	if anio[`k'] == 2022 & tipo_ingreso[`k'] == "Organismos y Empresas" {
		scalar LIEOyENac = `montograph'[`k']
	}
	if anio[`k'] == 2022 & tipo_ingreso[`k'] == "Financiamiento" {
		scalar LIEFinNac = `montograph'[`k']
	}
}


restore
collapse (sum) monto poblacion (mean) deflator, by(anio)
tempvar montograph
g `montograph' = monto/poblacion/deflator
forvalues k=1(1)`=_N' {
	if anio[`k'] == 2022 {
		scalar LIETotNac = `montograph'[`k']
	}
}

noisily scalarlatex, logname(gastofed)
*/
*****************************************
**Recursos Propios
****************************************
use "`c(sysdir_site)'../../Hewlett Subnacional/Base de datos/LIE/INEGI/LIEs.dta", replace

merge m:1 (anio entidad) using "`c(sysdir_site)'../../Hewlett Subnacional/Base de datos/PIBEntidades.dta", nogen
merge m:1 (anio entidad) using "`c(sysdir_site)'../../Hewlett Subnacional/Base de datos/PobTot.dta", nogen
keep if anio >= 2018 & anio <= 2022
keep if tipo_ingreso=="Recursos Propios"
replace concepto="Contribuciones De Mejoras" if concepto=="Contribuciones de mejoras"
replace concepto="Otros Recursos Propios" if concepto=="Disponibilidad inicial" ///
	|concepto=="Otros Ingresos" ///
	|concepto=="Otros Recursos Fiscales" 

preserve
collapse (sum) monto (mean) poblacion deflator pibYEnt, by(entidad anio tipo_ingreso concepto)
keep if tipo_ingreso=="Recursos Propios"
tempvar montograph montopibYE
g `montograph' = monto/poblacion/deflator
graph bar (mean) `montograph' if `montograph' != . [fw=poblacion], ///
	over(concepto, sort(1) descending) ///
	over(anio) ///
	stack asyvars ///
	///title(Gasto {bf:federalizado}) ///
	///subtitle(Por entidad federativa) ///
	ytitle("per c{c a'}pita (MXN 2022)") ///
	ylabel(, format(%7.0fc)) ///
	blabel(bar, format(%7.0fc)) ///
	legend(rows(2)) ///
	name(Recursos_prop, replace)
graph export  "$export/`=strtoname("RP_desag")'.png", as(png) replace 
save "`c(sysdir_site)'../../Hewlett Subnacional/Base de datos/LIES_RP.dta", replace
*******Checkpoint************
levelsof entidad, local(entidades)
*
foreach k of local entidades {
	graph bar (mean) `montograph' if `montograph' != . & entidad == "`k'" [fw=poblacion], ///
		over(concepto, sort(1) descending) ///
		over(anio) ///
		stack asyvars ///
		///title(Gasto {bf:federalizado}) ///
		///subtitle(Por entidad federativa) ///
		ytitle("per c{c a'}pita (MXN 2022)") ///
		ylabel(, format(%7.0fc)) ///
		blabel(bar, format(%7.0fc)) ///
		legend(off) ///
		name(RPdesag_`k', replace)
	graph export  "$export/`=strtoname("RP_desag_`k'")'.png", as(png) replace 
}
*/

drop `montograph'

collapse (sum) monto (mean) poblacion deflator pibYEnt, by(entidad anio concepto)

reshape wide monto poblacion, i(anio concepto deflator pibYEnt) j(entidad) string
reshape long
g `montograph' = monto/poblacion/deflator



forvalues k=1(1)`=_N' {
	if anio[`k'] == 2022 & concepto[`k'] == "Aprovechamientos" {
		scalar RPaprov`=entidad[`k']' = `montograph'[`k']
	}
	if anio[`k'] == 2022 & concepto[`k'] == "Contribuciones De Mejoras" {
		scalar RPcontri`=entidad[`k']' = `montograph'[`k']
	}
	if anio[`k'] == 2022 & concepto[`k'] == "Derechos" {
		scalar RPder`=entidad[`k']' = `montograph'[`k']
	}
	if anio[`k'] == 2022 & concepto[`k'] == "Impuestos" {
		scalar RPimp`=entidad[`k']' = `montograph'[`k']
	}
	if anio[`k'] == 2022 & concepto[`k'] == "Otros Recursos Propios" {
		scalar RPotros`=entidad[`k']' = `montograph'[`k']
	}
	if anio[`k'] == 2022 & concepto[`k'] == "Productos" {
		scalar RPprod`=entidad[`k']' = `montograph'[`k']
	}
}
restore
preserve
collapse (sum) monto (mean) poblacion deflator pibYEnt, by(entidad anio)
tempvar montograph montopibYE
g `montograph' = monto/poblacion/deflator
g `montopibYE' = monto/pibYEnt*100

forvalues k=1(1)`=_N' {
	if anio[`k'] == 2022 {
		scalar RPTot`=entidad[`k']' = `montograph'[`k']
		scalar RePrPIB`=entidad[`k']' = `montopibYE'[`k']
	}
}
restore
preserve
collapse (sum) monto poblacion (mean) deflator, by(anio concepto)
tempvar montograph
g `montograph' = monto/poblacion/deflator
forvalues k=1(1)`=_N' {
	if anio[`k'] == 2022 & concepto[`k'] == "Aprovechamientos" {
		scalar RPaprovNac= `montograph'[`k']
	}
	if anio[`k'] == 2022 & concepto[`k'] == "Contribuciones De Mejoras" {
		scalar RPcontriNac= `montograph'[`k']
	}
	if anio[`k'] == 2022 & concepto[`k'] == "Derechos" {
		scalar RPderNac= `montograph'[`k']
	}
	if anio[`k'] == 2022 & concepto[`k'] == "Impuestos" {
		scalar RPimpNac = `montograph'[`k']
	}
	if anio[`k'] == 2022 & concepto[`k'] == "Otros Recursos Propios" {
		scalar RPotrosNac = `montograph'[`k']
	}
	if anio[`k'] == 2022 & concepto[`k'] == "Productos" {
		scalar RPprodNac= `montograph'[`k']
	}
}


restore
collapse (sum) monto poblacion (mean) deflator, by(anio)
tempvar montograph
g `montograph' = monto/poblacion/deflator
forvalues k=1(1)`=_N' {
	if anio[`k'] == 2022 {
		scalar RPTotNac = `montograph'[`k']
	}
}

noisily scalarlatex, logname(Recursos_propios)



*************************************************************************************
*IMPUESTOS
***********************************************************************************
use "`c(sysdir_site)'../../Hewlett Subnacional/Base de datos/LIE/INEGI/LIEs.dta", replace

merge m:1 (anio entidad) using "`c(sysdir_site)'../../Hewlett Subnacional/Base de datos/PIBEntidades.dta", nogen
merge m:1 (anio entidad) using "`c(sysdir_site)'../../Hewlett Subnacional/Base de datos/PobTot.dta", nogen
keep if anio >= 2018 & anio <= 2022
keep if tipo_ingreso=="Recursos Propios"

replace concepto_desagregado="Impuesto Sobre La Producci{c o'}n, Consumo Y Las Transacciones" if concepto_desagregado=="Impuesto sobre la producci{c o'}n, el consumo y las transacciones"
replace concepto_desagregado="Impuestos Sobre Ingresos" if concepto_desagregado=="Impuesto sobre los Ingresos" 
replace concepto_desagregado="Otros Impuestos" if concepto_desagregado=="Otros impuestos"
replace concepto_desagregado="ISN" if concepto_tipo=="ISN"
replace concepto_desagregado="Otros Impuestos" if concepto_desagregado=="Adicionales"
*preserve
keep if concepto=="Impuestos"
collapse (sum) monto (mean) poblacion deflator pibYEnt, by(entidad anio tipo_ingreso concepto_desagregado)

tempvar montograph montopibYE
g `montograph' = monto/poblacion/deflator
graph bar (mean) `montograph' if `montograph' != . [fw=poblacion], ///
	over(concepto_desagregado, sort(1) descending) ///
	over(anio) ///
	stack asyvars ///
	///title(Gasto {bf:federalizado}) ///
	///subtitle(Por entidad federativa) ///
	ytitle("per c{c a'}pita (MXN 2022)") ///
	ylabel(, format(%7.0fc)) ///
	blabel(bar, format(%7.0fc)) ///
	legend(rows(2) label(3 "Impuesto Sobre La Producción," "Consumo Y Las Transacciones")) ///
	name(Impuestos, replace)
graph export  "$export/`=strtoname("Impuestos")'.png", as(png) replace 
save "`c(sysdir_site)'../../Hewlett Subnacional/Base de datos/LIEs_Impuestos.dta", replace
*******Checkpoint************
levelsof entidad, local(entidades)

foreach k of local entidades {
	graph bar (mean) `montograph' if `montograph' != . & entidad == "`k'" [fw=poblacion], ///
		over(concepto_desagregado, sort(1) descending) ///
		over(anio) ///
		stack asyvars ///
		///title(Gasto {bf:federalizado}) ///
		///subtitle(Por entidad federativa) ///
		ytitle("per c{c a'}pita (MXN 2022)") ///
		ylabel(, format(%7.0fc)) ///
		blabel(bar, format(%7.0fc)) ///
		legend(off) name(Impuestos_`k', replace)
	graph export  "$export/`=strtoname("Impuestos_`k'")'.png", as(png) replace 
}


drop `montograph'

****************************

*Checkponit*

***************************
collapse (sum) monto (mean) poblacion deflator pibYEnt, by(entidad anio concepto)

reshape wide monto poblacion, i(anio concepto deflator pibYEnt) j(entidad) string
reshape long
g `montograph' = monto/poblacion/deflator
preserve

forvalues k=1(1)`=_N' {
	if anio[`k'] == 2022 & concepto[`k'] == "Accesorios" {
		scalar ImpAcc`=entidad[`k']' = `montograph'[`k']
	}
	if anio[`k'] == 2022 & concepto[`k'] == "ISN" {
		scalar ImpISN`=entidad[`k']' = `montograph'[`k']
	}
	if anio[`k'] == 2022 & concepto[`k'] == "Impuesto Sobre La Producci{c o'}n, Consumo Y Las Transacciones" {
		scalar ImpConsu`=entidad[`k']' = `montograph'[`k']
	}
	if anio[`k'] == 2022 & concepto[`k'] == "Impuestos Sobre Ingresos" {
		scalar ImpIng`=entidad[`k']' = `montograph'[`k']
	}
	if anio[`k'] == 2022 & concepto[`k'] == "Impuestos Sobre Patrimonio" {
		scalar ImpPatri`=entidad[`k']' = `montograph'[`k']
	}
	if anio[`k'] == 2022 & concepto[`k'] == "Otros Impuestos" {
		scalar ImpOtros`=entidad[`k']' = `montograph'[`k']
	}
	
}
restore
preserve
collapse (sum) monto (mean) poblacion deflator pibYEnt, by(entidad anio)

tempvar montograph montopibYE
g `montograph' = monto/poblacion/deflator
g `montopibYE' = monto/pibYEnt*100

forvalues k=1(1)`=_N' {
	if anio[`k'] == 2022 {
		scalar ImpTot`=entidad[`k']' = `montograph'[`k']
		scalar ImpPIB`=entidad[`k']' = `montopibYE'[`k']
	}
}
restore
preserve
collapse (sum) monto poblacion (mean) deflator, by(anio concepto)
save "`c(sysdir_site)'../../Hewlett Subnacional/Base de datos/LIEs_Impuestos.dta", replace
tempvar montograph
g `montograph' = monto/poblacion/deflator
forvalues k=1(1)`=_N' {
	if anio[`k'] == 2022 & concepto[`k'] == "Accesorios" {
		scalar ImpAccNac = `montograph'[`k']
	}
	if anio[`k'] == 2022 & concepto[`k'] == "ISN" {
		scalar ImpISNNac = `montograph'[`k']
	}
	if anio[`k'] == 2022 & concepto[`k'] == "Impuesto Sobre La Producci{c o'}n, Consumo Y Las Transacciones" {
		scalar ImpConsuNac = `montograph'[`k']
	}
	if anio[`k'] == 2022 & concepto[`k'] == "Impuestos Sobre Ingresos" {
		scalar ImpIngNac = `montograph'[`k']
	}
	if anio[`k'] == 2022 & concepto[`k'] == "Impuestos Sobre Patrimonio" {
		scalar ImpPatriNac = `montograph'[`k']
	}
	if anio[`k'] == 2022 & concepto[`k'] == "Otros Impuestos" {
		scalar ImpOtrosNac = `montograph'[`k']
	}
}


restore
collapse (sum) monto poblacion (mean) deflator, by(anio)
tempvar montograph
g `montograph' = monto/poblacion/deflator
forvalues k=1(1)`=_N' {
	if anio[`k'] == 2022 {
		scalar ImpTotNac = `montograph'[`k']
	}
}

noisily scalarlatex, logname(Impuestos)


