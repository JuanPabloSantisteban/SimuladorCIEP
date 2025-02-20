******************************************
****                                  ****
****        PERFILES FISCALES         ****
****    INFORMACION POR INDIVIDUOS    ****
****                                  ****
******************************************
if "`1'" == "" {
	clear all
	local 1 = 2025
	scalar anioenigh = 2022
	scalar aniovp = 2025
}
else {
	if `1' >= 2022 {
		scalar anioenigh = 2022
	}
	if `1' >= 2020 & `1' < 2022 {
		scalar anioenigh = 2020
	}
	if `1' >= 2018 & `1' < 2020 {
		scalar anioenigh = 2018
	}
	if `1' >= 2016 & `1' < 2018 {
		scalar anioenigh = 2016
	}
	if `1' >= 2013 & `1' < 2016 {
		scalar anioenigh = 2014
	}
}



**********************
***                ***
**# 1. Macros: PEF ***
***                ***
**********************
PEF, anio(`1') by(desc_funcion) min(0) nographs
local Cuotas_ISSSTE = r(Cuotas_ISSSTE)
local SSFederacion = r(Aportaciones_a_Seguridad_Social) + `Cuotas_ISSSTE'

** 1.1 Educación **
PEF if divCIEP == "Educación", anio(`1') by(desc_subfuncion) min(0) nographs
local Basica = r(educacion_basica)
local Media = r(educacion_media_superio)
local Superior = r(educacion_superior)
local Adultos = r(educacion_para_adultos)
local Posgrado = r(posgrado)
local OtrosEdu = r(Gasto_neto) - `Basica' - `Media' - `Superior' - `Adultos' - `Posgrado'

** 1.2 Otros gastos **
PEF, anio(`1') by(divCIEP) min(0) nographs
local PenBienestar = r(Pension_AM)
local Otros_gastos = r(Otros_gastos) //+r(Cuotas_ISSSTE)
local Pensiones = r(Pensiones)
local Educacion = r(Educacion)
local Salud = r(Salud)
local Energía = r(Energia)
local Part_y_otras_Apor = r(Part_y_otras_Apor)

** 1.3 Infraestructura **
PEF if divCIEP == "Otras inversiones", anio(`1') by(entidad) min(0) nographs
local Aguas = r(Aguascalientes)
local BajaN = r(Baja_California)
local BajaS = r(Baja_California_Sur)
local Campe = r(Campeche)
local Coahu = r(Coahuila)
local Colim = r(Colima)
local Chiap = r(Chiapas)
local Chihu = r(Chihuahua)
local Ciuda = r(Ciudad_de_Mexico)
local Duran = r(Durango)
local Guana = r(Guanajuato)
local Guerr = r(Guerrero)
local Hidal = r(Hidalgo)
local Jalis = r(Jalisco)
local Estad = r(Estado_de_Mexico)
local Micho = r(Michoacan)
local Morel = r(Morelos)
local Nayar = r(Nayarit)
local Nuevo = r(Nuevo_Leon)
local Oaxac = r(Oaxaca)
local Puebl = r(Puebla)
local Quere = r(Queretaro)
local Quint = r(Quintana_Roo)
local SanLu = r(San_Luis_Potosi)
local Sinal = r(Sinaloa)
local Sonor = r(Sonora)
local Tabas = r(Tabasco)
local Tamau = r(Tamaulipas)
local Tlaxc = r(Tlaxcala)
local Verac = r(Veracruz)
local Yucat = r(Yucatan)
local Zacat = r(Zacatecas)
local InfraT = r(Gasto_neto)



**********************
***                ***
**# 2. Macros: LIF ***
***                ***
**********************
LIF, anio(`1') by(divSIM) nographs min(0)
local recursos = r(divSIM)
foreach k of local recursos {
	local `=substr("`k'",1,7)' = r(`k')
}
scalar IngKPublicos = `FMP'+`PEMEX'+`CFE'+`IMSS'+`ISSSTE'



***************************
***                     ***
**# 3. Ajuste Población ***
***                     *** 
**************************
use if anio == `1' using `"`c(sysdir_personal)'/SIM/Poblaciontot.dta"', clear
local ajustepob = poblacion



*************/
***        ***
**# 4. SCN ***
***        ***
**************
SCN, anio(`1') nographs



*********************************************/
***                                        ***
**# 5. Variables INGRESOS - GASTOS TOTALES ***
***                                        ***
**********************************************


** 5.3 Usar base de datos conciliada **
use "`c(sysdir_personal)'/SIM/`=anioenigh'/households.dta", clear
tabstat factor, stat(sum) f(%20.0fc) save
tempname pobenigh
matrix `pobenigh' = r(StatTotal)
replace factor = round(factor*`ajustepob'/`pobenigh'[1,1],1)
replace factor = round(factor,1)
capture g pob = 1


** 5.4 (+) Ingreso bruto **
Distribucion ingbrutotot, relativo(ingbrutotot) macro(`=scalar(PIN)')
label var ingbrutotot "Ingreso bruto total `1'"
*noisily Perfiles ingbrutotot [fw=factor], aniope(`1') aniovp(`=aniovp')
*noisily Gini ingbrutotot, hogar(folioviv foliohog) factor(factor)


** 5.5 (-) Consumo total **
Distribucion gastoanualTOT, relativo(gastoanualTOT) macro(`=scalar(ConHog)')
label var gastoanualTOT "Consumo total `1'"
*noisily Perfiles gastoanualTOT [fw=factor], aniope(`1') aniovp(`=aniovp')
*noisily Gini gastoanualTOT, hogar(folioviv foliohog) factor(factor)


** 5.6 (*) Ingresos para el módulo ISR **
Distribucion ing_bruto_tax, relativo(ing_bruto_tax) macro(`=scalar(Yl)+scalar(MixK)')
label var ing_bruto_tax "Ingresos laborales `1'"
*noisily Perfiles ing_bruto_tax [fw=factor], aniope(`1') aniovp(`=aniovp')
*noisily Gini ing_bruto_tax, hogar(folioviv foliohog) factor(factor)

Distribucion ing_subor, relativo(ing_subor) macro(`=scalar(RemSal)+scalar(ImpNetProduccionL)')
label var ing_subor "Remuneración de asalariados `1'"
*noisily Perfiles ing_subor [fw=factor], aniope(`1') aniovp(`=aniovp')
*noisily Gini ing_subor, hogar(folioviv foliohog) factor(factor)

Distribucion ing_bruto_tpm, relativo(ing_bruto_tpm) macro(`=scalar(ExNOpSoc)+scalar(ImpNetProductos)-scalar(IngKPublicos)')
label var ing_bruto_tpm "Ingresos de capital privado `1'"
*noisily Perfiles ing_bruto_tpm [fw=factor], aniope(`1') aniovp(`=aniovp')
*noisily Gini ing_bruto_tpm, hogar(folioviv foliohog) factor(factor)


****************************/
** (+) IMPUESTOS laborales **

** (+) ISR Asalariados **
Distribucion ISRAS, relativo(ISR_asalariados) macro(`ISRAS')
label var ISRAS "ISR (sueldos y salarios) `1'"
*noisily Perfiles ISRAS [fw=factor], aniope(`1') aniovp(`=aniovp')
*noisily Gini ISRAS, hogar(folioviv foliohog) factor(factor)

** (+) ISR Personas Físicas **
Distribucion ISRPF, relativo(ISR_PF) macro(`ISRPF')
label var ISRPF "ISR (personas f{c i'}sicas) `1'"
*noisily Perfiles ISRPF [fw=factor], aniope(`1') aniovp(`=aniovp')
*noisily Gini ISRPF, hogar(folioviv foliohog) factor(factor)

** (+) Cuotas obrero-patronal IMSS **
Distribucion CUOTAS if formal2 == 1, relativo(cuotasTP) macro(`CUOTAS')
replace CUOTAS = 0 if CUOTAS == .
label var CUOTAS "Cuotas IMSS `1'"
*noisily Perfiles CUOTAS [fw=factor], aniope(`1') aniovp(`=aniovp')
*noisily Gini CUOTAS, hogar(folioviv foliohog) factor(factor)

** (+) Impuestos laborales **
egen laboral = rsum(ISRAS ISRPF CUOTAS)
replace laboral = 0 if laboral == .
Distribucion Laboral, relativo(laboral) macro(`=`ISRAS'+`ISRPF'+`CUOTAS'')
label var Laboral "Impuestos laborales `1'"
*noisily Perfiles Laboral [fw=factor], aniope(`1') aniovp(`=aniovp')
*noisily Gini Laboral, hogar(folioviv foliohog) factor(factor)



*************************************/
** (+) IMPUESTOS al capital privado **

** (+) ISR Personas Morales **
Distribucion ISRPM, relativo(ISR_PM) macro(`ISRPM')
label var ISRPM "ISR (personas morales) `1'"
*noisily Perfiles ISRPM [fw=factor], aniope(`1') aniovp(`=aniovp')
*noisily Gini ISRPM, hogar(folioviv foliohog) factor(factor)

** (+) Otros de capital **
Distribucion OTROSK, relativo(ISR_PM) macro(`OTROSK')
label var OTROSK "Productos, derechos, aprovechamientos... `1'"
*noisily Perfiles OTROSK [fw=factor], aniope(`1') aniovp(`=aniovp')
*noisily Gini OTROSK, hogar(folioviv foliohog) factor(factor)

** (+) Impuestos de capital privado **
Distribucion KPrivado, relativo(ISR_PM) macro(`=`OTROSK'+`ISRPM'')
label var KPrivado "Impuestos al capital privado `1'"
*noisily Perfiles KPrivado [fw=factor], aniope(`1') aniovp(`=aniovp')
*noisily Gini KPrivado, hogar(folioviv foliohog) factor(factor)



******************************/
** (+) IMPUESTOS al consumo **

** (+) IVA **
Distribucion IVA, relativo(IVA) macro(`IVA')
label var IVA "IVA `1'"
*noisily Perfiles IVA [fw=factor], aniope(`1') aniovp(`=aniovp')
*noisily Gini IVA, hogar(folioviv foliohog) factor(factor)

** (+) ISAN **
tempvar ISANH
g `ISANH' = ISAN
drop ISAN
Distribucion ISAN, relativo(`ISANH') macro(`ISAN')
label var ISAN "ISAN `1'"
*noisily Perfiles ISAN [fw=factor], aniope(`1') aniovp(`=aniovp')
*noisily Gini ISAN, hogar(folioviv foliohog) factor(factor)

** (+) IEPS (no petrolero) **
Distribucion IEPSNP, relativo(gas_pc_BebA) macro(`IEPSNP')
label var IEPSNP "IEPS (no petrolero) `1'"
*noisily Perfiles IEPSNP [fw=factor], aniope(`1') aniovp(`=aniovp')
*noisily Gini IEPSNP, hogar(folioviv foliohog) factor(factor)

** (+) IEPS (petrolero) **
Distribucion IEPSP, relativo(gas_pc_Vehi) macro(`IEPSP')
label var IEPSP "IEPS (petrolero) `1'"
*noisily Perfiles IEPSP [fw=factor], aniope(`1') aniovp(`=aniovp')
*noisily Gini IEPSP, hogar(folioviv foliohog) factor(factor)

** (+) Importaciones **
Distribucion IMPORT, relativo(Importaciones) macro(`IMPORT')
label var IMPORT "Importaciones `1'"
*noisily Perfiles IMPORT [fw=factor], aniope(`1') aniovp(`=aniovp')
*noisily Gini IMPORT, hogar(folioviv foliohog) factor(factor)

** (+) Impuestos al consumo **
egen consumo = rsum(IVA ISAN IEPSNP IEPSP IMPORT)
replace consumo = 0 if consumo == .
Distribucion Consumo, relativo(consumo) macro(`=`IEPSP'+`IEPSNP'+`IMPORT'+`ISAN'+`IVA'')
label var Consumo "Impuestos al consumo `1'"
*noisily Perfiles Consumo [fw=factor], aniope(`1') aniovp(`=aniovp')
*noisily Gini Consumo, hogar(folioviv foliohog) factor(factor)



*************************************
** (+) INGRESOS de capital público **

** (+) Fondo Mexicano del Petróleo **
Distribucion FMP, relativo(pob) macro(`=`FMP'')
label var FMP "FMP `1'"
*noisily Perfiles FMP [fw=factor], aniope(`1') aniovp(`=aniovp')
*noisily Gini FMP, hogar(folioviv foliohog) factor(factor)

** (+) IMSS **
Distribucion IMSS, relativo(pob) macro(`=`IMSS'')
label var IMSS "IMSS `1'"
*noisily Perfiles IMSS [fw=factor], aniope(`1') aniovp(`=aniovp')
*noisily Gini IMSS, hogar(folioviv foliohog) factor(factor)

** (+) ISSSTE **
Distribucion ISSSTE, relativo(pob) macro(`=`ISSSTE'')
label var ISSSTE "ISSSTE `1'"
*noisily Perfiles ISSSTE [fw=factor], aniope(`1') aniovp(`=aniovp')
*noisily Gini ISSSTE, hogar(folioviv foliohog) factor(factor)

** (+) CFE **
Distribucion CFE, relativo(pob) macro(`=`CFE'')
label var CFE "CFE `1'"
*noisily Perfiles CFE [fw=factor], aniope(`1') aniovp(`=aniovp')
*noisily Gini CFE, hogar(folioviv foliohog) factor(factor)

** (+) PEMEX **
Distribucion PEMEX, relativo(pob) macro(`=`PEMEX'')
label var PEMEX "PEMEX `1'"
*noisily Perfiles PEMEX [fw=factor], aniope(`1') aniovp(`=aniovp')
*noisily Gini PEMEX, hogar(folioviv foliohog) factor(factor)

** (+) Impuestos y aportaciones **
capture drop ImpuestosAportaciones
egen ImpuestosAportaciones = rsum(ISRAS ISRPF CUOTAS ISRPM OTROSK IVA IEPSNP IEPSP ISAN IMPORT)
label var ImpuestosAportaciones "Impuestos y aportaciones `1'"
*noisily Perfiles ImpuestosAportaciones [fw=factor], aniope(`1') aniovp(`=aniovp')
*noisily Gini ImpuestosAportaciones, hogar(folioviv foliohog) factor(factor)



**********************/
** (+) Gasto público **

** (-) Educacion **
replace nivel = "0" + nivel if length(nivel) == 1

* Educación básica *
if `=anioenigh' == 2014 {
	tabstat factor if asis_esc == "1" & tipoesc == "1" & (nivel >= "01" & nivel <= "03") & edad <= 18, stat(sum) f(%15.0fc) save
	matrix BasAlum = r(StatTotal)
	g educacion = `Basica'/BasAlum[1,1] if asis_esc == "1" & tipoesc == "1" & (nivel >= "01" & nivel <= "03") & edad <= 18
}
if `=anioenigh' > 2014 {
	tabstat factor if asis_esc == "1" & tipoesc == "1" & (nivel >= "01" & nivel <= "07") & edad <= 18, stat(sum) f(%15.0fc) save
	matrix BasAlum = r(StatTotal)
	g educacion = `Basica'/BasAlum[1,1] if asis_esc == "1" & tipoesc == "1" & (nivel >= "01" & nivel <= "07") & edad <= 18
}

* Educación media superior *
if `=anioenigh' == 2014 {
	tabstat factor if asis_esc == "1" & tipoesc == "1" & (nivel >= "04" & nivel <= "06"), stat(sum) f(%15.0fc) save
	matrix MedAlum = r(StatTotal)
	replace educacion = `Media'/MedAlum[1,1] if asis_esc == "1" & tipoesc == "1" & (nivel >= "04" & nivel <= "06")
}
if `=anioenigh' > 2014 {
	tabstat factor if asis_esc == "1" & tipoesc == "1" & (nivel >= "08" & nivel <= "10"), stat(sum) f(%15.0fc) save
	matrix MedAlum = r(StatTotal)
	replace educacion = `Media'/MedAlum[1,1] if asis_esc == "1" & tipoesc == "1" & (nivel >= "08" & nivel <= "10")
}

* Educación superior *
if `=anioenigh' == 2014 {
	tabstat factor if asis_esc == "1" & tipoesc == "1" & (nivel >= "07" & nivel <= "08"), stat(sum) f(%15.0fc) save
	matrix SupAlum = r(StatTotal)
	replace educacion = `Superior'/SupAlum[1,1] if asis_esc == "1" & tipoesc == "1" & (nivel >= "07" & nivel <= "08")
}
if `=anioenigh' > 2014 {
	tabstat factor if asis_esc == "1" & tipoesc == "1" & (nivel >= "11" & nivel <= "12"), stat(sum) f(%15.0fc) save
	matrix SupAlum = r(StatTotal)
	replace educacion = `Superior'/SupAlum[1,1] if asis_esc == "1" & tipoesc == "1" & (nivel >= "11" & nivel <= "12")
}

* Educación posgrado *
if `=anioenigh' == 2014 {
	tabstat factor if asis_esc == "1" & tipoesc == "1" & nivel == "09", stat(sum) f(%15.0fc) save
	matrix PosAlum = r(StatTotal)
	replace educacion = `Posgrado'/PosAlum[1,1] if asis_esc == "1" & tipoesc == "1" & nivel == "09"
}
if `=anioenigh' > 2014 {
	tabstat factor if asis_esc == "1" & tipoesc == "1" & nivel == "13", stat(sum) f(%15.0fc) save
	matrix PosAlum = r(StatTotal)
	replace educacion = `Posgrado'/PosAlum[1,1] if asis_esc == "1" & tipoesc == "1" & nivel == "13"
}


* Educación para adultos *
if `=anioenigh' == 2014 {
	tabstat factor if asis_esc == "1" & tipoesc == "1" & (nivel >= "01" & nivel <= "03") & edad > 18, stat(sum) f(%15.0fc) save
	matrix AduAlum = r(StatTotal)
	replace educacion = `Adultos'/AduAlum[1,1] if asis_esc == "1" & tipoesc == "1" & (nivel >= "01" & nivel <= "03") & edad > 18
}
if `=anioenigh' > 2014 {
	tabstat factor if asis_esc == "1" & tipoesc == "1" & (nivel >= "01" & nivel <= "07") & edad > 18, stat(sum) f(%15.0fc) save
	matrix AduAlum = r(StatTotal)
	replace educacion = `Adultos'/AduAlum[1,1] if asis_esc == "1" & tipoesc == "1" & (nivel >= "01" & nivel <= "07") & edad > 18
}

* Otros gastos educativos *
replace educacion = educacion + `OtrosEdu'/(BasAlum[1,1]+MedAlum[1,1]+SupAlum[1,1]+PosAlum[1,1]+AduAlum[1,1]) if educacion != 0
replace educacion = 0 if educacion == .

Distribucion Educacion, relativo(educacion) macro(`Educacion')
label var Educacion "Educación `1'"
*noisily Perfiles Educacion if Educacion != 0 [fw=factor], aniope(`1') aniovp(`=aniovp')
*noisily Gini Educacion, hogar(folioviv foliohog) factor(factor)

** (-) Salud **
Distribucion Salud, relativo(gas_pc_Salu) macro(`Salud')
label var Salud "Salud `1'"
*noisily Perfiles Salud if Salud != 0 [fw=factor], aniope(`1') aniovp(`=aniovp') //poblacion(defunciones)
*noisily Gini Salud, hogar(folioviv foliohog) factor(factor)

** (-) Pension Bienestar **
capture rename ing_PAM ing_pam
replace ing_pam = 0 if ing_pam == .
capture g discapacidad = disc_camin != "4" | disc_ver != "4" | disc_brazo != "4" | disc_apren != "4" | disc_oir != "4" | disc_vest != "4" | disc_habla != "4" | disc_act != "4"
if _rc != 0 {
	g discapacidad = 0
}

tabstat factor if (edad >= 65 |  discapacidad == 1) & ing_pam != 0, stat(sum) f(%20.0fc) save
matrix POBLACION68 = r(StatTotal)

*capture drop Pension_AM
*g Pension_AM = `PenBienestar'/POBLACION68[1,1] if (edad >= 65 |  discapacidad == 1) & ing_pam != 0
*replace Pension_AM = 0 if Pension_AM == .
*noisily tabstat Pension_AM [fw=factor], stat(sum) f(%20.0fc)

Distribucion Pension_AM, relativo(ing_pam) macro(`PenBienestar')
label var Pension_AM "Pensi{c o'}n para adultos mayores `1'"
*noisily Perfiles Pension_AM [fw=factor], aniope(`1') aniovp(`=aniovp')
*noisily Gini Pension_AM, hogar(folioviv foliohog) factor(factor)

** (-) Pensiones **
capture drop ing_jubila_pub
g ing_jubila_pub = ing_jubila if jubilado == 1
replace ing_jubila_pub = 0 if ing_jubila_pub == .
*replace ing_jubila_pub = ing_jubila_pub + Pension_AM

Distribucion Pensiones, relativo(ing_jubila_pub) macro(`Pensiones')
replace Pensiones = Pensiones //+ Pension_AM
label var Pensiones "Pensiones `1'"
*noisily Perfiles Pensiones if Pensiones != 0 [fw=factor], aniope(`1') aniovp(`=aniovp')
*noisily Gini Pension, hogar(folioviv foliohog) factor(factor)



**********************
** (-) Otros gastos **

** (-) Inversión **
g entidad = substr(folioviv,1,2)
destring entidad, replace
local j = 1
foreach k in Aguas BajaN BajaS Campe Coahu Colim Chiap Chihu Ciuda Duran Guana ///
	Guerr Hidal Jalis Estad Micho Morel Nayar Nuevo Oaxac Puebl Quere Quint ///
	SanLu Sinal Sonor Tabas Tamau Tlaxc Verac Yucat Zacat {

	tempvar factor_`k'
	g `factor_`k'' = factor if entidad == `j'
	Distribucion Infra_`k', relativo(`factor_`k'') macro(``k'')
	local ++j
}
egen infra_entidad = rsum(Infra_*)
Distribucion Otras_inversiones, relativo(infra_entidad) macro(`InfraT')
label var Otras_inversiones "Otras inversiones `1'"
*noisily Perfiles Otras_inversiones [fw=factor], aniope(`1') aniovp(`=aniovp')
*noisily Gini Otras_inversiones, hogar(folioviv foliohog) factor(factor)

** (-) Otros gastos **
Distribucion Otros_gastos, relativo(pob) macro(`=`Otros_gastos'')
label var Otros_gastos "Otros gastos `1'"
*noisily Perfiles Otros_gastos [fw=factor], aniope(`1') aniovp(`=aniovp')
*noisily Gini Otros_gastos, hogar(folioviv foliohog) factor(factor)

** (-) Energía **
Distribucion Energia, relativo(pob) macro(`=`Energía'')
label var Energia "Energia `1'"
*noisily Perfiles Energia [fw=factor], aniope(`1') aniovp(`=aniovp')
*noisily Gini Energia, hogar(folioviv foliohog) factor(factor)

** (-) Otras Participaciones y Aportaciones **
Distribucion Part_y_otras_Apor, relativo(pob) macro(`=`Part_y_otras_Apor'')
label var Part_y_otras_Apor "Participaciones y otras aportaciones `1'"
*noisily Perfiles Part_y_otras_Apor [fw=factor], aniope(`1') aniovp(`=aniovp')
*noisily Gini Part_y_otras_Apor, hogar(folioviv foliohog) factor(factor)


*****************************
** (-) Ingreso B{c a'}sico **
g IngBasico = 0.0000000001
label var IngBasico "Ingreso b{c a'}sico `1'"
*noisily Perfiles IngBasico [fw=factor], aniope(`1') aniovp(`=aniovp')
*noisily Gini IngBasico, hogar(folioviv foliohog) factor(factor)


****************/
***           ***
*** 7. SANKEY ***
***           ***
/****************
foreach k in grupoedad sexo decil rural escol {
	run "Sankey.do" `k' `1'
}


***********************/
**# 7 DATOS ABIERTOS ***
/***********************
if "$nographs" == "" & "`nographs'" != "nographs" & `anio' == `aniovp' {
	DatosAbiertos XNA0120_s, pibvp(`ISRAS')		//    ISR salarios
	DatosAbiertos XNA0120_f, pibvp(`ISRPF')		//    ISR PF
	DatosAbiertos XNA0120_m, pibvp(`ISRPM')		//    ISR PM
	DatosAbiertos XKF0114, pibvp(`CUOTAS')		//    Cuotas IMSS
	DatosAbiertos XAB1120, pibvp(`IVA')		//    IVA
	DatosAbiertos XNA0141, pibvp(`ISAN')		//    ISAN
	DatosAbiertos XAB2122, pibvp(`IEPSP')		//    IEPS petrolero
	DatosAbiertos XAB2213, pibvp(`IEPSNP')		//    IEPS no petrolero
	DatosAbiertos XNA0136, pibvp(`IMPORT')		//    Importaciones
	DatosAbiertos FMP_Derechos, pibvp(`FMP')	//    FMP_Derechos
	DatosAbiertos XAB2110, pibvp(`PEMEX')		//    Ingresos propios Pemex
	DatosAbiertos XOA0115, pibvp(`CFE')		//    Ingresos propios CFE
	DatosAbiertos XKF0179, pibvp(`IMSS')		//    Ingresos propios IMSS
	DatosAbiertos XOA0120, pibvp(`ISSSTE')		//    Ingresos propios ISSSTE
	DatosAbiertos OtrosIngresosC, pibvp(`OTROSK')	//    Ingresos propios ISSSTE
}





***********/
***      ***
*** SAVE ***
***      ***
************
capture drop __*
compress
keep ISRAS ISRPF CUOTAS ISRPM OTROSK FMP PEMEX CFE IMSS ISSSTE IVA IEPSNP IEPSP ISAN IMPORT /// Ingresos
	Pension* Educacion Salud IngBasico Pension_AM Otros_gastos Otras_inversiones Part_y_otras_Apor Energia infra_entidad /// Gastos
	folio* numren edad sexo factor decil escol formal* ingbrutotot rural grupoedad /// Perfiles.ado
	disc* gas_pc_Salu asis_esc tipoesc nivel inst_* ing_jubila jubilado /// GastoPC.ado
	sbc cuotasTPF deduc_isr ing_bruto_tax *_tpm exen_tot prop* ing_subor // ISR_Mod.do
if `c(version)' > 13.1 {
	save "`c(sysdir_personal)'/SIM/perfiles`1'.dta", replace
}
else {
	saveold "`c(sysdir_personal)'/SIM/perfiles`1'.dta", replace version(13)	
}
