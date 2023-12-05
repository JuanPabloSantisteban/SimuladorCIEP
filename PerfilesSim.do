****************************************
****                                ****
**** ARMONIZACION ENIGH + LIF + PEF ****
****    INFORMACION DE HOGARES      ****
****                                ****
****************************************
if "`1'" == "" {
	clear all
	local 1 = 2024
	scalar anioenigh = 2022
}





**********************
***                ***
*** 1. Macros: PEF ***
***                ***
**********************
PEF, anio(`1') by(desc_funcion) min(0) nographs
local Cuotas_ISSSTE = r(Cuotas_ISSSTE)
local SSFederacion = r(Aportaciones_a_Seguridad_Social) + `Cuotas_ISSSTE'

* Educación *
PEF if divCIEP == 2, anio(`1') by(desc_subfuncion) min(0) nographs
local Basica = r(Educación_Básica)
local Media = r(Educación_Media_Superior)
local Superior = r(Educación_Superior)
local Adultos = r(Educación_para_Adultos)
local Posgrado = r(Posgrado)
local OtrosEdu = r(Gasto_neto) - `Basica' - `Media' - `Superior' - `Adultos' - `Posgrado'

* Otros gastos *
PEF, anio(`1') by(divCIEP) min(0) nographs
local PenBienestar = r(Pensión_AM)
local Otros_gastos = r(Otros_gastos)+r(Cuotas_ISSSTE)
local Pensiones = r(Pensiones)
local Educacion = r(Educación)
local Salud = r(Salud)
local Energía = r(Energía)
local Part_y_otras_Apor = r(Part_y_otras_Apor)

* Infraestructura *
PEF if divCIEP == 4, anio(`1') by(entidad) min(0) nographs
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
local InfraT = r(Gasto_neto)





**********************
***                ***
*** 2. Macros: LIF ***
***                ***
**********************
LIF, anio(`1') by(divSIM) nographs min(0)
local recursos = r(divSIM)
foreach k of local recursos {
	local `=substr("`k'",1,7)' = r(`k')
}

/*LIF, anio(`1') nographs min(0) by(serie)
local IEPSAlcohol = r(XNA0203)
local IEPSTabaco = r(XNA0125)*/





***************************
***                     ***
*** 3. Ajuste Población ***
***                     *** 
**************************
use if anio == `1' using `"`c(sysdir_personal)'/SIM/Poblaciontot.dta"', clear
local ajustepob = poblacion





*************/
***        ***
*** 4. SCN ***
***        ***
**************
SCN, anio(`1') nographs





**********************************
***                            ***
*** 5. Variables Simulador.ado ***
***                            ***
**********************************

* Base de datos ENIGH - Gastos *
capture confirm file "`c(sysdir_personal)'/SIM/`=anioenigh'/expenditures.dta"
if _rc != 0 {
	noisily run "`c(sysdir_personal)'/Expenditure.do" `1'
}

* Base de datos ENIGH - Ingresos *
capture confirm file "`c(sysdir_personal)'/SIM/`=anioenigh'/households.dta"
if _rc != 0 {
	noisily run `"`c(sysdir_personal)'/Households.do"' `1'
}

* Usar base de datos conciliada *
use "`c(sysdir_personal)'/SIM/`=anioenigh'/households.dta", clear
*keep folioviv foliohog numren sexo edad factor

tabstat factor, stat(sum) f(%20.0fc) save
tempname pobenigh
matrix `pobenigh' = r(StatTotal)
replace factor = round(factor*`ajustepob'/`pobenigh'[1,1],1)
capture g pob = 1

** (+) Ingreso bruto **
Distribucion ingbrutotot, relativo(ingbrutotot) macro(`=scalar(PIN)')
label var ingbrutotot "ingreso bruto total"
*noisily Simulador ingbrutotot [fw=factor], base("ENIGH `=anioenigh'") boot(1) reboot anio(`1')
*noisily Gini ingbrutotot, hogar(folioviv foliohog) factor(factor)

** (-) Consumo total **
Distribucion gastoanualTOT, relativo(gastoanualTOT) macro(`=scalar(ConHog)')
label var gastoanualTOT "consumo total"
*noisily Simulador gastoanualTOT [fw=factor], base("ENIGH `=anioenigh'") boot(1) reboot anio(`1')
*noisily Gini gastoanualTOT, hogar(folioviv foliohog) factor(factor)



****************************/
** (+) IMPUESTOS laborales **

** (+) ISR Asalariados **
Distribucion ISRAS, relativo(ISR_asalariados) macro(`ISRAS')
label var ISRAS "ISR (Salarios)"
*noisily Simulador ISRAS [fw=factor], base("ENIGH `=anioenigh'") boot(1) reboot anio(`1')
*noisily Gini ISRAS, hogar(folioviv foliohog) factor(factor)

** (+) ISR Personas Físicas **
Distribucion ISRPF, relativo(ISR_PF) macro(`ISRPF')
label var ISRPF "ISR (personas f{c i'}sicas)"
*noisily Simulador ISRPF [fw=factor], base("ENIGH `=anioenigh'") boot(1) reboot anio(`1')
*noisily Gini ISRPF, hogar(folioviv foliohog) factor(factor)

** (+) Cuotas obrero-patronal IMSS **
Distribucion CUOTAS if formal == 1, relativo(cuotasTP) macro(`CUOTAS')
replace CUOTAS = 0 if CUOTAS == .
label var CUOTAS "cuotas IMSS"
*noisily Simulador CUOTAS [fw=factor], base("ENIGH `=anioenigh'") boot(1) reboot anio(`1')
*noisily Gini CUOTAS, hogar(folioviv foliohog) factor(factor)

** (+) Impuestos laborales **
egen laboral = rsum(ISRAS ISRPF CUOTAS)
replace laboral = 0 if laboral == .
Distribucion Laboral, relativo(laboral) macro(`=`ISRAS'+`ISRPF'+`CUOTAS'')
label var Laboral "los impuestos al ingreso laboral"
*noisily Simulador Laboral [fw=factor], base("ENIGH `=anioenigh'") boot(1) reboot anio(`1')
*noisily Gini Laboral, hogar(folioviv foliohog) factor(factor)



*************************************/
** (+) IMPUESTOS al capital privado **

** (+) ISR Personas Morales **
Distribucion ISRPM, relativo(ISR_PM) macro(`ISRPM')
label var ISRPM "ISR (personas morales)"
*noisily Simulador ISRPM [fw=factor], base("ENIGH `=anioenigh'") boot(1) reboot anio(`1')
*noisily Gini ISRPM, hogar(folioviv foliohog) factor(factor)

** (+) Otros de capital **
Distribucion OTROSK, relativo(ISR_PM) macro(`OTROSK')
label var OTROSK "Productos, derechos, aprovechamientos..."
*noisily Simulador OTROSK [fw=factor], base("ENIGH `=anioenigh'") boot(1) reboot anio(`1')
*noisily Gini OTROSK, hogar(folioviv foliohog) factor(factor)

** (+) Impuestos de capital privado **
Distribucion KPrivado, relativo(ISR_PM) macro(`=`OTROSK'+`ISRPM'')
label var KPrivado "impuestos al capital privado"
*noisily Simulador KPrivado [fw=factor], base("ENIGH `=anioenigh'") boot(1) reboot anio(`1')
*noisily Gini KPrivado, hogar(folioviv foliohog) factor(factor)



******************************/
** (+) IMPUESTOS al consumo **

** (+) IVA **
Distribucion IVA, relativo(IVATOT) macro(`IVA')
label var IVA "IVA"
*noisily Simulador IVA [fw=factor], base("ENIGH `=anioenigh'") boot(1) reboot anio(`1')
*noisily Gini IVA, hogar(folioviv foliohog) factor(factor)

** (+) ISAN **
tempvar ISANH
g `ISANH' = ISAN
drop ISAN
Distribucion ISAN, relativo(`ISANH') macro(`ISAN')
label var ISAN "ISAN"
*noisily Simulador ISAN [fw=factor], base("ENIGH `=anioenigh'") boot(1) reboot anio(`1')
*noisily Gini ISAN, hogar(folioviv foliohog) factor(factor)

** (+) IEPS (no petrolero) **
Distribucion IEPSNP, relativo(IEPSTOT) macro(`IEPSNP')
label var IEPSNP "IEPS (no petrolero)"
*noisily Simulador IEPSNP [fw=factor], base("ENIGH `=anioenigh'") boot(1) reboot anio(`1')
*noisily Gini IEPSNP, hogar(folioviv foliohog) factor(factor)

** (+) IEPS (petrolero) **
Distribucion IEPSP, relativo(IEPSTOT) macro(`IEPSP')
label var IEPSP "IEPS (petrolero)"
*noisily Simulador IEPSP [fw=factor], base("ENIGH `=anioenigh'") boot(1) reboot anio(`1')
*noisily Gini IEPSP, hogar(folioviv foliohog) factor(factor)

** (+) Importaciones **
Distribucion IMPORT, relativo(Importaciones) macro(`IMPORT')
label var IMPORT "importaciones"
*noisily Simulador IMPORT [fw=factor], base("ENIGH `=anioenigh'") boot(1) reboot anio(`1')
*noisily Gini IMPORT, hogar(folioviv foliohog) factor(factor)

** (+) Impuestos al consumo **
egen consumo = rsum(IVA ISAN IEPSNP IEPSP IMPORT)
replace consumo = 0 if consumo == .
Distribucion Consumo, relativo(consumo) macro(`=`IEPSP'+`IEPSNP'+`IMPORT'+`ISAN'+`IVA'')
label var Consumo "los impuestos al consumo"
*noisily Simulador Consumo [fw=factor], base("ENIGH `=anioenigh'") boot(1) reboot anio(`1')
*noisily Gini Consumo, hogar(folioviv foliohog) factor(factor)



*************************************
** (+) INGRESOS de capital público **

** (+) Fondo Mexicano del Petróleo **
Distribucion FMP, relativo(pob) macro(`=`FMP'')
label var FMP "FMP"
*noisily Simulador FMP [fw=factor], base("ENIGH `=anioenigh'") boot(1) reboot anio(`1')
*noisily Gini FMP, hogar(folioviv foliohog) factor(factor)

** (+) IMSS **
Distribucion IMSS, relativo(pob) macro(`=`IMSS'')
label var IMSS "IMSS"
*noisily Simulador IMSS [fw=factor], base("ENIGH `=anioenigh'") boot(1) reboot anio(`1')
*noisily Gini IMSS, hogar(folioviv foliohog) factor(factor)

** (+) ISSSTE **
Distribucion ISSSTE, relativo(pob) macro(`=`ISSSTE'')
label var ISSSTE "ISSSTE"
*noisily Simulador ISSSTE [fw=factor], base("ENIGH `=anioenigh'") boot(1) reboot anio(`1')
*noisily Gini ISSSTE, hogar(folioviv foliohog) factor(factor)

** (+) CFE **
Distribucion CFE, relativo(pob) macro(`=`CFE'')
label var CFE "CFE"
*noisily Simulador CFE [fw=factor], base("ENIGH `=anioenigh'") boot(1) reboot anio(`1')
*noisily Gini CFE, hogar(folioviv foliohog) factor(factor)

** (+) PEMEX **
Distribucion PEMEX, relativo(pob) macro(`=`PEMEX'')
label var PEMEX "PEMEX"
*noisily Simulador PEMEX [fw=factor], base("ENIGH `=anioenigh'") boot(1) reboot anio(`1')
*noisily Gini PEMEX, hogar(folioviv foliohog) factor(factor)

** (+) Impuestos y aportaciones **
capture drop ImpuestosAportaciones
egen ImpuestosAportaciones = rsum(ISRAS ISRPF CUOTAS ISRPM OTROSK IVA IEPSNP IEPSP ISAN IMPORT)
label var ImpuestosAportaciones "impuestos y aportaciones"
*noisily Simulador ImpuestosAportaciones [fw=factor], base("ENIGH `=anioenigh'") boot(1) reboot anio(`1')
*noisily Gini ImpuestosAportaciones, hogar(folioviv foliohog) factor(factor)



**********************/
** (+) Gasto público **

** (-) Educacion **
tabstat factor if asis_esc == "1" & tipoesc == "1" & (nivel >= "01" & nivel <= "07") & edad <= 18, stat(sum) f(%15.0fc) save
matrix BasAlum = r(StatTotal)

tabstat factor if asis_esc == "1" & tipoesc == "1" & (nivel >= "08" & nivel <= "10"), stat(sum) f(%15.0fc) save
matrix MedAlum = r(StatTotal)

tabstat factor if asis_esc == "1" & tipoesc == "1" & (nivel >= "11" & nivel <= "12"), stat(sum) f(%15.0fc) save
matrix SupAlum = r(StatTotal)

tabstat factor if asis_esc == "1" & tipoesc == "1" & nivel == "13", stat(sum) f(%15.0fc) save
matrix PosAlum = r(StatTotal)

tabstat factor if asis_esc == "1" & tipoesc == "1" & (nivel >= "01" & nivel <= "07") & edad > 18, stat(sum) f(%15.0fc) save
matrix AduAlum = r(StatTotal)

g educacion = `Basica'/BasAlum[1,1] if asis_esc == "1" & tipoesc == "1" & (nivel >= "01" & nivel <= "07") & edad <= 18
replace educacion = `Media'/MedAlum[1,1] if asis_esc == "1" & tipoesc == "1" & (nivel >= "08" & nivel <= "10")
replace educacion = `Superior'/SupAlum[1,1] if asis_esc == "1" & tipoesc == "1" & (nivel >= "11" & nivel <= "12")
replace educacion = `Posgrado'/PosAlum[1,1] if asis_esc == "1" & tipoesc == "1" & nivel == "13"
replace educacion = `Adultos'/AduAlum[1,1] if asis_esc == "1" & tipoesc == "1" & (nivel >= "01" & nivel <= "07") & edad > 18
replace educacion = educacion + `OtrosEdu'/(BasAlum[1,1]+MedAlum[1,1]+SupAlum[1,1]+PosAlum[1,1]+AduAlum[1,1])
replace educacion = 0 if educacion == .

Distribucion Educación, relativo(educacion) macro(`Educacion')
label var Educación "educación"
*noisily Simulador Educación [fw=factor], base("ENIGH `=anioenigh'") boot(1) reboot anio(`1')
*noisily Gini Educación, hogar(folioviv foliohog) factor(factor)

** (-) Salud **
g salud = 0
* Defunciones *
replace salud = 1.963106 if edad == 0
replace salud = .1351139 if edad == 1
replace salud = .0710421 if edad == 2
replace salud = .0499305 if edad == 3
replace salud = .0435635 if edad == 4
replace salud = .0406816 if edad == 5
replace salud = .0377997 if edad == 6
replace salud = .0366604 if edad == 7
replace salud = .0367274 if edad == 8
replace salud = .0380008 if edad == 9
replace salud = .0408157 if edad == 10
replace salud = .0454401 if edad == 11
replace salud = .0518741 if edad == 12
replace salud = .06119 if edad == 13
replace salud = .0719133 if edad == 14
replace salud = .0845803 if edad == 15
replace salud = .0985876 if edad == 16
replace salud = .1129301 if edad == 17
replace salud = .1279427 if edad == 18
replace salud = .1428213 if edad == 19
replace salud = .1573648 if edad == 20
replace salud = .1705009 if edad == 21
replace salud = .183637 if edad == 22
replace salud = .1950976 if edad == 23
replace salud = .2048156 if edad == 24
replace salud = .21259 if edad == 25
replace salud = .2184208 if edad == 26
replace salud = .2221069 if edad == 27
replace salud = .2247208 if edad == 28
replace salud = .2269995 if edad == 29
replace salud = .2280048 if edad == 30
replace salud = .2303505 if edad == 31
replace salud = .231825 if edad == 32
replace salud = .2343047 if edad == 33
replace salud = .2374547 if edad == 34
replace salud = .2412079 if edad == 35
replace salud = .2464355 if edad == 36
replace salud = .2534057 if edad == 37
replace salud = .2617162 if edad == 38
replace salud = .2727747 if edad == 39
replace salud = .2861118 if edad == 40
replace salud = .3017277 if edad == 41
replace salud = .3197563 if edad == 42
replace salud = .3391923 if edad == 43
replace salud = .3592315 if edad == 44
replace salud = .3803431 if edad == 45
replace salud = .4013206 if edad == 46
replace salud = .421963 if edad == 47
replace salud = .4438788 if edad == 48
replace salud = .4657276 if edad == 49
replace salud = .489654 if edad == 50
replace salud = .5133794 if edad == 51
replace salud = .5393164 if edad == 52
replace salud = .567063 if edad == 53
replace salud = .5955469 if edad == 54
replace salud = .6245669 if edad == 55
replace salud = .6546592 if edad == 56
replace salud = .6843494 if edad == 57
replace salud = .7137045 if edad == 58
replace salud = .740915 if edad == 59
replace salud = .7671201 if edad == 60
replace salud = .7916497 if edad == 61
replace salud = .815107 if edad == 62
replace salud = .837492 if edad == 63
replace salud = .8573301 if edad == 64
replace salud = .8764981 if edad == 65
replace salud = .8941916 if edad == 66
replace salud = .9090032 if edad == 67
replace salud = .9293775 if edad == 68
replace salud = .9522986 if edad == 69
replace salud = .9701261 if edad == 70
replace salud = .9868143 if edad == 71
replace salud = 1.002765 if edad == 72
replace salud = 1.016505 if edad == 73
replace salud = 1.02944 if edad == 74
replace salud = 1.03842 if edad == 75
replace salud = 1.047937 if edad == 76
replace salud = 1.053567 if edad == 77
replace salud = 1.053165 if edad == 78
replace salud = 1.046731 if edad == 79
replace salud = 1.037013 if edad == 80
replace salud = 1.023408 if edad == 81
replace salud = 1.005111 if edad == 82
replace salud = .9829941 if edad == 83
replace salud = .9557837 if edad == 84
replace salud = .9243509 if edad == 85
replace salud = .8868863 if edad == 86
replace salud = .844127 if edad == 87
replace salud = .7932582 if edad == 88
replace salud = .7351512 if edad == 89
replace salud = .6751676 if edad == 90
replace salud = .612168 if edad == 91
replace salud = .54756 if edad == 92
replace salud = .4848955 if edad == 93
replace salud = .4216949 if edad == 94
replace salud = .3601028 if edad == 95
replace salud = .3007894 if edad == 96
replace salud = .2456312 if edad == 97
replace salud = .1952316 if edad == 98
replace salud = .151333 if edad == 99
replace salud = .1138013 if edad == 100
replace salud = .0828377 if edad == 101
replace salud = .0587102 if edad == 102
replace salud = .0397433 if edad == 103
replace salud = .0259371 if edad == 104
replace salud = .0162861 if edad == 105
replace salud = .0092489 if edad == 106
replace salud = .0049595 if edad == 107
replace salud = .0004021 if edad == 108
replace salud = .0030159 if edad >= 109

Distribucion Salud, relativo(salud) macro(`Salud')
label var Salud "salud"
*noisily Simulador Salud [fw=factor], base("ENIGH `=anioenigh'") boot(1) reboot anio(`1') //poblacion(defunciones)
*noisily Gini Salud, hogar(folioviv foliohog) factor(factor)

** (-) Pensiones **
capture drop ing_jubila_pub
g ing_jubila_pub = ing_jubila if (formal == 1 | formal == 2 | formal == 3) & ing_jubila != 0
replace ing_jubila_pub = 0 if ing_jubila_pub == .
Distribucion Pensiones, relativo(ing_jubila_pub) macro(`Pensiones')
label var Pensiones "pensiones"
*noisily Simulador Pensiones [fw=factor], base("ENIGH `=anioenigh'") boot(1) reboot anio(`1')
*noisily Gini Pension, hogar(folioviv foliohog) factor(factor)

** (-) Pension Bienestar **
tabstat factor if edad >= 65, stat(sum) f(%20.0fc) save
matrix POBLACION68 = r(StatTotal)
capture drop Pensión_AM
g Pensión_AM = `PenBienestar'/POBLACION68[1,1] if edad >= 65
replace Pensión_AM = 0 if Pensión_AM == .
label var Pensión_AM "pensi{c o'}n para adultos mayores"
*noisily Simulador Pensión_AM if edad >= 65 [fw=factor], base("ENIGH `=anioenigh'") boot(1) reboot anio(`1')
*noisily Gini Pensión_AM, hogar(folioviv foliohog) factor(factor)



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
label var Otras_inversiones "otras inversiones"
*noisily Simulador Otras_inversiones [fw=factor], base("ENIGH `=anioenigh'") boot(1) reboot anio(`1')
*noisily Gini Otras_inversiones, hogar(folioviv foliohog) factor(factor)

** (-) Otros gastos **
Distribucion Otros_gastos, relativo(pob) macro(`=`Otros_gastos'')
label var Otros_gastos "otros gastos"
*noisily Simulador Otros_gastos [fw=factor], base("ENIGH `=anioenigh'") boot(1) reboot anio(`1')
*noisily Gini Otros_gastos, hogar(folioviv foliohog) factor(factor)

** (-) Energía **
Distribucion Energía, relativo(pob) macro(`=`Energía'')
label var Energía "energía"
*noisily Simulador Energía [fw=factor], base("ENIGH `=anioenigh'") boot(1) reboot anio(`1')
*noisily Gini Energía, hogar(folioviv foliohog) factor(factor)

** (-) Otras Participaciones y Aportaciones **
Distribucion Part_y_otras_Apor, relativo(pob) macro(`=`Part_y_otras_Apor'')
label var Part_y_otras_Apor "Participaciones y otras aportaciones"
*noisily Simulador Part_y_otras_Apor [fw=factor], base("ENIGH `=anioenigh'") boot(1) reboot anio(`1')
*noisily Gini Part_y_otras_Apor, hogar(folioviv foliohog) factor(factor)


*****************************
** (-) Ingreso B{c a'}sico **
g IngBasico = 0.0001
label var IngBasico "ingreso b{c a'}sico"
*noisily Simulador IngBasico [fw=factor], base("ENIGH `=anioenigh'") boot(1) reboot anio(`1')
*noisily Gini IngBasico, hogar(folioviv foliohog) factor(factor)





******************
***            ***
*** 6. ENGLISH ***
***            ***
/*****************
label var Laboral "Labor-based income tax"
label var CUOTAS "Social Security"
label var Consumo "Consumption tax"
label var OtrosC "Capital income"
label var Pension "Pensions"
label var PenBienestar "Bienestar pension"
label var Educacion "Education"
label var Salud "Health"
label var OtrosGas "Other expenditures"
label var IngBasico "Basic universal income"





****************/
***           ***
*** 7. SANKEY ***
***           ***
/****************
foreach k in grupoedad sexo decil rural escol {
	run "`c(sysdir_personal)'/Sankey.do" `k' `1'
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
compress
capture drop _*
keep ISRAS ISRPF CUOTAS ISRPM OTROSK FMP PEMEX CFE IMSS ISSSTE IVA IEPSNP IEPSP ISAN IMPORT /// Ingresos
	Pension Educación Salud IngBasico Pensión_AM Otros_gastos Otras_inversiones Part_y_otras_Apor Energía infra_entidad /// Gastos
	folio* numren edad sexo factor decil escol formal ingbrutotot rural grupoedad /// Simulador.ado
	//asis_esc tipoesc nivel inst_* ing_jubila jubilado // GastoPC.ado
if `c(version)' > 13.1 {
	save "`c(sysdir_personal)'/SIM/perfiles`1'.dta", replace
}
else {
	saveold "`c(sysdir_personal)'/SIM/perfiles`1'.dta", replace version(13)	
}
exit













*******************/
*** 7. TEXTBOOK ***
********************
use "`c(sysdir_personal)'/SIM/2020/households`1'.dta", clear
*noisily Simulador ing_subor [fw=factor], base("ENIGH `=anioenigh'") boot(1) reboot anio(`1')
*noisily Gini ing_subor, hogar(folioviv foliohog) factor(factor)


** (+) IEPS Alcohol **
Distribucion IEPSAlcohol, relativo(IEPS3) macro(`IEPSAlcohol')
label var IEPSAlcohol "IEPS (alcohol)"
*noisily Gini IEPSAlcohol, hogar(folioviv foliohog) factor(factor)
*noisily Simulador IEPSAlcohol [fw=factor], base("ENIGH `=anioenigh'") boot(1) reboot anio(`1')

** (+) IEPS Tabaco **
Distribucion IEPSTabaco, relativo(IEPS4) macro(`IEPSTabaco')
label var IEPSTabaco "IEPS (tabaco)"
*noisily Gini IEPSTabaco if IEPSTabaco != 0, hogar(folioviv foliohog) factor(factor)
*noisily Simulador IEPSTabaco [fw=factor], base("ENIGH `=anioenigh'") boot(1) reboot anio(`1')

** (+) TOTAL **
** (=) Ingresos Publicos **
egen IngresosPublicos = rsum(Laboral Consumo OtrosC)
label var IngresosPublicos "ingresos p{c u'}blicos"
*noisily Gini IngresosPublicos, hogar(folioviv foliohog) factor(factor)
*noisily Simulador IngresosPublicos [fw=factor], base("ENIGH `=anioenigh'") boot(1) reboot anio(`1')

*noisily Simulador ing_bruto_tpm [fw=factor], base("ENIGH `=anioenigh'") boot(1) reboot

* Sankey - NTA *
*noisily Simulador ingbrutotot [fw=factor_cola], base("ENIGH 2018") boot(1) reboot anio(2020) $nographs
*noisily Simulador gastoanualTOT [fw=factor_cola], base("ENIGH 2018") boot(1) reboot anio(2020) $nographs

replace Yk = Yk + gasto_anualDepreciacion - (ing_cap_imss + ing_cap_issste + ing_cap_cfe + ///
	ing_cap_pemex + ing_cap_fmp + ing_cap_mejoras + ing_cap_derechos + ///
	ing_cap_productos + ing_cap_aprovecha + ///
	ing_cap_otrostrib + ing_cap_otrasempr)



