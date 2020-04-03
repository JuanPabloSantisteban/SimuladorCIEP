********************************
*** Ingresos presupuestarios ***
********************************
noisily LIF, by(divGA) anio(2018)
local alingreso = r(Impuestos_al_ingreso)
local alconsumo = r(Impuestos_al_consumo)
local otrosing = r(Otros_ingresos)


******************************
*** Gastos presupuestarios ***
******************************
noisily PEF, anio(2018)
local pensiones = r(Pensiones)
local educacion = r(Educaci_c_o__n)
local salud = r(Salud)
local deuda = r(Deuda)
local otrosgas = r(Otros)

***************************
*** Encuesta de hogares ***
***************************
use "`c(sysdir_site)'../basesCIEP/Otros/EHPM2018.dta", clear
rename r106 edad
rename r104 sexo

g escol = 0 if r215a == 8 | r215a == 7 | r215a == .
replace escol = 1 if r215a == 0 | r215a == 1 | r215a == 2 | r215a == 6
replace escol = 2 if r215a == 3
replace escol = 3 if r215a == 4 | r215a == 5

label define escol 0 "Sin escolaridad" 1 "Basica" 2 "Media Superior" 3 "Superior"
label values escol escol
label var escol "Nivel de escolaridad"

xtile decil = ingpe [fw=fac00], n(10)

rename ingfa ing_bruto_tot

g formal = r422a == 1 | r422a == 2 | ///
	r422b == 1 | r422b == 2 | ///
	r422c == 1 | r422c == 2 | ///
	r422d == 1 | r422d == 2 | ///
	r422e == 1 | r422e == 2 | ///
	r422f == 1 | r422f == 2 | ///
	r422g == 1 | r422g == 2

rename fac00 factor

rename folio folioold
rename idboleta folio
rename r101 numren

** Coeficientes de consumo por edades **
g alfa = 1 if edad != .
replace alfa = alfa - .6*(20-edad)/16 if edad >= 5 & edad <= 20
replace alfa = .4 if edad <= 4

tempvar alfatot
egen `alfatot' = sum(alfa), by(folio)


*************************************
*** Distribuciones proporcionales ***
*************************************
capture program drop Distribucion
program Distribucion
	syntax varname, MACRO(real)

	tempvar vartotal proporcion
	egen double `vartotal' = sum(`varlist') if factor != 0
	replace `varlist' = `varlist'/`vartotal'*`macro'/factor if factor != 0
end


*******************************
*** Variables Simulador.ado ***
*******************************

** Ingreso **
g Ingreso = ingre if formal == 1
replace Ingreso = 0 if Ingreso == .
label var Ingreso "Impuestos al ingreso"
* Reescalar *
Distribucion Ingreso, macro(`alingreso')

** Consumo **
g Consumo = gastohog*alfa/`alfatot'
label var Consumo "Impuestos al consumo"
* Reescalar *
Distribucion Consumo, macro(`alconsumo')

** Otros ingresos **
g Otros = 1
replace Otros = 0 if Ingreso == .
label var Otros "Otros ingresos"
* Reescalar *
Distribucion Otros, macro(`otrosing')

** Pensiones **
g Pension = r44407a
replace Pension = 0 if Pension == .
label var Pension "Pensiones"
* Reescalar *
Distribucion Pension, macro(`pensiones')

** Educación **
tabstat factor, stat(sum) by(r204) f(%10.0fc) save
matrix TotAlum = r(StatTotal)
matrix BasAlum = r(Stat1)+r(Stat2)+r(Stat3)+r(Stat7)
matrix MedAlum = r(Stat4)
matrix SupAlum = r(Stat5)+r(Stat6)

g Educacion = 157.2*1000000/TotAlum[1,1] + 638.5*1000000/BasAlum[1,1] if r204 == 1 | r204 == 2 | r204 == 3 | r204 == 7
replace Educacion = 157.2*1000000/TotAlum[1,1] + 102.5*1000000/MedAlum[1,1] if r204 == 4
replace Educacion = 157.2*1000000/TotAlum[1,1] + 84.3/SupAlum[1,1] if r204 == 5 | r204 == 6
replace Educacion = 0 if Educacion == .
label var Educacion "Educación"
* Reescalar *
Distribucion Educacion, macro(`educacion')

** Salud **
g Salud = 1.5 if edad <= 4
replace Salud = 0.78 if edad >= 5 & edad <= 9
replace Salud = 0.62 if edad >= 10 & edad <= 14
replace Salud = 0.58 if edad >= 15 & edad <= 19
replace Salud = 0.63 if edad >= 20 & edad <= 24
replace Salud = 0.82 if edad >= 25 & edad <= 29
replace Salud = 0.81 if edad >= 30 & edad <= 34
replace Salud = 1.00 if edad >= 35 & edad <= 39
replace Salud = 0.97 if edad >= 40 & edad <= 44
replace Salud = 1.06 if edad >= 45 & edad <= 49
replace Salud = 1.12 if edad >= 50 & edad <= 54
replace Salud = 1.34 if edad >= 55 & edad <= 59
replace Salud = 1.60 if edad >= 60 & edad <= 64
replace Salud = 1.83 if edad >= 65 & edad <= 69
replace Salud = 2.22 if edad >= 70 & edad <= 74
replace Salud = 2.66 if edad >= 75 & edad <= 79
replace Salud = 3.36 if edad >= 80 & edad <= 84
replace Salud = 3.36 if edad >= 85 & edad <= 89
replace Salud = 3.36 if edad >= 90 & edad <= 94
replace Salud = 3.36 if edad >= 95
label var Salud "Salud"
* Reescalar *
Distribucion Salud, macro(`salud')

** Otros gastos **
g OtrosGas = 1
replace OtrosGas = 0 if Ingreso == .
label var OtrosGas "Otros gastos"
* Reescalar *
Distribucion OtrosGas, macro(`otrosgas')


***********
*** END ***
capture drop __*
merge 1:1 (folio numren) using `"`c(sysdir_site)'../basesCIEP/SIM/2018/expenditureElSalvador.dta"', nogen

compress
if `c(version)' == 15.1 {
	saveold `"`c(sysdir_site)'../basesCIEP/SIM/2018/householdsElSalvador.dta"', replace version(13)
}
else {
	save `"`c(sysdir_site)'../basesCIEP/SIM/2018/householdsElSalvador.dta"', replace
}
