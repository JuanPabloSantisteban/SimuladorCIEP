**************
*** SANKEY ***
**************
if "`1'" == "" {
	local 1 = "decil"
	local 2 = 2018
}

if "$pais" != "" {
	exit
}
timer on 7



****************
** 0 Economia **
SCN, anio(`2') nographs
LIF, anio(`2') nographs
local CuotasIMSS = r(Cuotas_IMSS)
local IMSSpropio = r(IMSS)-`CuotasIMSS'
local ISSSTEpropio = r(ISSSTE)
local CFEpropio = r(CFE)
local Pemexpropio = r(Pemex)
local FMP = r(FMP__Derechos_petroleros)
local Mejoras = r(Contribuciones_de_mejoras)
local Derechos = r(Derechos)
local Productos = r(Productos)
local Aprovechamientos = r(Aprovechamientos)
local OtrosTributarios = r(Otros_tributarios)
local OtrasEmpresas = r(Otras_empresas)



**********************************/
** Eje 1: Generación del ingreso **
use `"`c(sysdir_site)'../basesCIEP/SIM/2018/households`=subinstr("${pais}"," ","",.)'.dta"', clear

replace Yk = Yk - ing_estim_alqu

collapse (sum) ing_Ing_Laboral=Yl ing_Ing_Capital=Yk ///
	ing_Alquiler_imputado=ing_estim_alqu [fw=factor_cola], by(`1')

* to *
tempvar to
reshape long ing_, i(`1') j(`to') string
rename ing_ profile
encode `to', g(to)

* from *
rename `1' from

* Sector Publico *
set obs `=_N+1'
replace from = -2 in -1
replace profile = `IMSSpropio' + `ISSSTEpropio' + `CFEpropio' + ///
	`Pemexpropio' + `FMP' + `Mejoras' + `Derechos' + `Productos' + `Aprovechamientos' + ///
	`OtrosTributarios' + `OtrasEmpresas' in -1
label define `1' -2 "Sector_publico", add
replace to = 2 in -1

* ROW */
set obs `=_N+2'
replace from = -1 if from == .
label define `1' -1 "Resto del mundo", add

replace to = 3 in -1
replace profile = scalar(ROWRem) in -1

replace to = -1 in -2
replace profile = scalar(ROWTrans) in -2
label define to -1 "Remesas", add

if scalar(ComprasN) < 0 {
	set obs `=_N+1'
	replace from = -1 if from == .
	replace to = -2 in -1
	replace profile = -scalar(ComprasN) in -1
	label define to -2 "Compras por extranjeros", add
}

* Eje */
tempfile eje1
save `eje1'



********************
** Eje 4: Consumo **
use `"`c(sysdir_site)'../basesCIEP/SIM/2018/households`=subinstr("${pais}"," ","",.)'.dta"', clear

g gasto_anualAhorro = ing_bruto_tot + ing_capitalROW + ing_suborROW + ing_remesas ///
	- TOTgasto_anual - gasto_anualDepreciacion - gasto_anualComprasN - gasto_anualGobierno

collapse (sum) gasto_anual* [fw=factor_cola], by(`1')

egen gasto_Alimentos = rsum(gasto_anual1-gasto_anual3)
egen gasto_Vestido = rsum(gasto_anual5-gasto_anual6)
egen gasto__Salud = rsum(gasto_anual11)
egen gasto___Educacion_y_Recreacion = rsum(gasto_anual16-gasto_anual18)
egen gasto___Vivienda = rsum(gasto_anual7-gasto_anual10)
egen gasto___Transporte_y_Comunica = rsum(gasto_anual12-gasto_anual15)
egen gasto____Otros_gastos = rsum(gasto_anual4 gasto_anual19)
*egen gasto___Consumo_Gobierno = rsum(gasto_anualGobierno)
egen gasto_____Consumo_capital = rsum(gasto_anualDepreciacion)
*egen gasto____Ahorro = rsum(gasto_anualAhorro)
drop gasto_anual*

levelsof `1', local(`1')
foreach k of local `1' {
	local oldlabel : label (`1') `k'
	label define `1' `k' "_`oldlabel'", modify
}

* from *
tempvar from
reshape long gasto_, i(`1') j(`from') string
rename gasto_ profile
encode `from', g(from)

* to *
rename `1' to

* ROW *
set obs `=_N+1'
replace to = -3 if from == .
label define `1' -3 "_Resto del mundo", add

replace from = 99 in -1
replace profile = scalar(ROWTrans) in -1
label define from 99 "__Ing a la propiedad", add

* Sector Publico *
set obs `=_N+3'
replace to = -1 if from == .
label define `1' -1 "Gobierno", add

replace profile = scalar(SerEGob) in -1
replace from = 4 in -1

replace profile = scalar(SaluGob) in -2
replace from = 3 in -2

replace profile = scalar(ConGob) - scalar(SerEGob) - scalar(SaluGob) in -3
replace from = 7 in -3

* Ahorro *
set obs `=_N+1'
drop if from == 98
replace from = 98 in -1
replace to = -2 in -1 
replace profile = scalar(AhorroN) in -1
label define `1' -2 "__Futuro", add
label define from 98 "Ahorro", add

* Depreciacion *
replace to = -4 if from == 8
label define `1' -4 "Depreciacion", add

sort from to
tempfile eje4
save `eje4'



********************
** Eje 2: Total 1 **
use `eje1', clear
collapse (sum) profile, by(to)
rename to from

g to = 999
label define PIB 999 "Ing nacional"
label values to PIB

tempfile eje2
save `eje2'



********************
** Eje 3: Total 2 **
use `eje4', clear
collapse (sum) profile, by(from)
rename from to

g from = 999
label define PIB 999 "Ing nacional"
label values from PIB

tempfile eje3
save `eje3'



************
** Sankey **
noisily SankeySum, anio(`2') name(`1') folder(SankeySIM) a(`eje1') b(`eje2') c(`eje3') d(`eje4')

timer off 7
timer list 7
noisily di _newline in g "{bf:Tiempo:} " in y round(`=r(t7)/r(nt7)',.1) in g " segs."

