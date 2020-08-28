program define Simulador
quietly {
	timer on 7
	version 13.1
	syntax varname [if] [fweight/], ///
		[BOOTstrap(int 1) ///
		Graphs REboot Noisily ///
		REESCalar(real 1) BANDwidth(int 5) ///
		BASE(string) GA ///
		MACro(string) BIE ///
		POBlacion(string) FOLIO(string) ///
		NOKernel POBGraph]




	*******************
	*** 0. Defaults ***
	*******************
	if "`base'" == "" {
		local base = "ENIGH 2018"
	}

	** Anio de la BASE **
	tokenize `base'
	local aniobase = `2'

	** Macros: PIB **
	preserve
	PIBDeflactor, anio(`aniobase') nographs
	tempfile PIBBASE
	save `PIBBASE'

	forvalues k=1(1)`=_N' {
		if deflator[`k'] == 1 {
			local PIB = pibY[`k']
			local aniovp = anio[`k']
			continue, break
		}
	}
	restore

	** Poblacion **
	if "`poblacion'" == "" {
		local poblacion = "poblacion"
	}

	** Folio **
	if "`folio'" == "" {
		local folio = "folio"
	}

	** T{c i'}tulo **
	local title : variable label `varlist'
	local nombre `"`=subinstr("`varlist'","_","",.)'"'

	** Texto introductorio **
	noisily di _newline(2) in g "  {bf:Variable label: " in y "`title'}"
	noisily di in g "  {bf:Variable name: " in y "`varlist'}"
	if "`if'" != "" {
		noisily di in g "  {bf:If: " in y "`if'}"
	}
	else {
		noisily di in g "  {bf:If: " in y "Sin restricci{c o'}n. Todas las observaciones utilizadas.}"	
	}
	noisily di in g "  {bf:Bootstraps: " in y `bootstrap' "}" _newline

	** Base original **
	tempfile original
	save `original', replace

	** Reescalar **
	if `reescalar' != 1 {
		tempvar vartotal proporcion
		egen `vartotal' = sum(`varlist')
		g `proporcion' = `varlist'/`vartotal'
		replace `varlist' = `proporcion'*`reescalar'/`exp'
	}




	************************
	*** 1. Archivos POST ***
	************************
	capture confirm file `"`c(sysdir_personal)'/users/$pais/bootstraps/`bootstrap'/`varlist'REC.dta"'
	if "`reboot'" == "reboot" | _rc != 0 {


		******************************
		** 1.1 Variables de control **
		tempvar cont boot
		g double `cont' = 1
		g `boot' = .


		******************
		** 1.2 Archivos **
		capture mkdir `"`c(sysdir_personal)'/users/$pais/"'
		capture mkdir `"`c(sysdir_personal)'/users/$pais/"'
		capture mkdir `"`c(sysdir_personal)'/users/$pais/graphs/"'
		capture mkdir `"`c(sysdir_personal)'/users/$pais/bootstraps/"'
		capture mkdir `"`c(sysdir_personal)'/users/$pais/bootstraps/`bootstrap'"'


		** Per c{c a'}pita **
		postfile PC double(estimacion contribuyentes poblacion montopc edad39) ///
			using `"`c(sysdir_personal)'/users/$pais/bootstraps/`bootstrap'/`varlist'PC"', replace


		** Perfiles **
		postfile PERF edad double(perfil1 perfil2 contribuyentes1 contribuyentes2 ///
			estimacion1 estimacion2 pobcont1 pobcont2 poblacion1 poblacion2) ///
			using `"`c(sysdir_personal)'/users/$pais/bootstraps/`bootstrap'/`varlist'PERF"', replace


		** Incidencia por hogares **
		postfile INCI decil double(xhogar distribucion incidencia hogares) ///
			using `"`c(sysdir_personal)'/users/$pais/bootstraps/`bootstrap'/`varlist'INCI"', replace


		** Ciclo de vida **
		postfile CICLO bootstrap sexo edad decil escol double(poblacion `varlist') ///
			using `"`c(sysdir_personal)'/users/$pais/bootstraps/`bootstrap'/`varlist'CICLO"', replace


		** Proyecciones **
		postfile REC str30 (modulo) int (bootstrap anio aniobase) ///
			double (estimacion contribuyentes poblacion ///
			contribuyentes_Hom contribuyentes_Muj ///
			contribuyentes_0_24 contribuyentes_25_49 ///
			contribuyentes_50_74 contribuyentes_75_mas) ///
			using `"`c(sysdir_personal)'/users/$pais/bootstraps/`bootstrap'/`varlist'REC"', replace



		*******************
		** 1.3 Bootstrap **
		set seed 1111
		forvalues k = 1(1)`bootstrap' {
			if `bootstrap' != 1 {
				if `k'/5 == int(`k'/5) {
					noisily di in y . _cont
				}
				bsample _N, w(`boot')
			}
			else {
				replace `boot' = 1
			}

			** 1.3.1. Monto per capita **
			** Recaudacion **
			tempname REC REC39
			capture tabstat `varlist' [`weight' = `exp'*`boot'] `if', stat(sum) f(%20.2fc) save
			if _rc == 0 {
				matrix `REC' = r(StatTotal)
			}
			else {
				matrix `REC' = J(1,1,0)
			}
			
			* Recaudacion, Edad 39, Hombres *
			if "`if'" != "" {
				local if39 = "`if' & edad == 39 & sexo == 1"
			}
			else {
				local if39 = "if edad == 39 & sexo == 1"			
			}
			capture tabstat `varlist' [`weight' = `exp'*`boot'] `if39', stat(sum) f(%20.2fc) save
			if _rc == 0 {
				matrix `REC39' = r(StatTotal)
			}
			else {
				matrix `REC39' = J(1,1,0)
			}

			** Contribuyentes **
			tempname FOR
			capture tabstat `cont' [`weight' = `exp'*`boot'] `if', stat(sum) f(%12.0fc) save
			if _rc == 0 {
				matrix `FOR' = r(StatTotal)
			}
			else {
				matrix `FOR' = J(1,1,0)
			}

			** Poblacion **
			tempname POB POB39
			capture tabstat `cont' [`weight' = `exp'*`boot'], stat(sum) f(%12.0fc) save
			if _rc == 0 {
				matrix `POB' = r(StatTotal)
			}
			else {
				matrix `POB' = J(1,1,0)
			}
			
			* Poblacion, Edad 39, Hombres *
			capture tabstat `cont' [`weight' = `exp'*`boot'] `if39', stat(sum) f(%12.0fc) save
			if _rc == 0 {
				matrix `POB39' = r(StatTotal)
			}
			else {
				matrix `POB39' = J(1,1,0)
			}


			** Monto per capita promedio **
			if `FOR'[1,1] != 0 {
				local montopc = `REC'[1,1]/`FOR'[1,1]
			}
			else {
				local montopc = 0
			}


			** Mata: PC **
			local edad39 = `REC39'[1,1]/`POB39'[1,1]
			if `edad39' == . | `edad39' == 0 {
				local pc = `montopc'
			}
			else {
				local pc = `edad39'
			}

			mata: PC = `pc'

			* Desplegar estadisticos *
			`noisily' di in y "  montopc (`aniobase')"
			`noisily' di in g "  Monto:" _column(40) in y %25.0fc `REC'[1,1]
			`noisily' di in g "  Poblaci{c o'}n:" _column(40) in y %25.0fc `POB'[1,1]
			`noisily' di in g "  Contribuyentes/Beneficiarios:" _column(40) in y %25.0fc `FOR'[1,1]
			`noisily' di in g "  Per c{c a'}pita (contr./benef.):" _column(40) in y %25.0fc `montopc'
			`noisily' di in g "  Edad 39 (poblaci{c o'}n):" _column(40) in y %25.0fc `edad39'

			* Guardar resultados POST *
			post PC (`REC'[1,1]) (`FOR'[1,1]) (`POB'[1,1]) (`montopc') (`REC39'[1,1]/`POB39'[1,1])


			*** 1.3.2. Perfiles ***
			`noisily' perfiles `varlist' `if' [`weight' = `exp'*`boot'], montopc(`pc') post


			*** 1.3.3. Incidencia por hogar ***
			capture confirm variable decil
			tempvar decil
			if _rc != 0 {
				noisily di _newline in g "{bf:  No hay variable: " in y "decil" in g ". Se cre{c o'} con: " in y "`varlist'" in g ".}"
				xtile `decil' = `varlist' [`weight' = `exp'*`boot'], n(10)
			}
			else {
				g `decil' = decil
			}

			capture confirm variable ing_bruto_tot
			tempvar ingreso
			if _rc != 0 {
				g double `ingreso' = `varlist'
				local rellabel "[Sin variable de ingreso total]"
				label var `ingreso' "[Sin variable de ingreso total]"
			}
			else {
				g double `ingreso' = ing_bruto_tot
				local rellabel : variable label ing_bruto_tot
				label var `ingreso' "`rellabel'"
			}

			`noisily' incidencia `varlist' `if' [`weight' = `exp'*`boot'], folio(`folio') n(`decil') relativo(`ingreso') post


			*** 1.3.4. Ciclo de Vida ***/
			if "`graphs'" == "graphs" {
				`noisily' CicloDeVida `varlist' `if' [`weight' = `exp'*`boot'], post boot(`k') decil(`decil')
			}


			*** 1.3.5. Proyecciones ***
			`noisily' proyecciones `varlist', `graphs' post ///
				pob(`poblacion') boot(`k') aniobase(`aniobase')
		}


		***********************
		*** 1.4. Post close ***
		postclose PC
		postclose PERF
		postclose INCI
		postclose CICLO
		postclose REC
	}


	noisily di _newline in y "  Simulador.ado" in g " (post-bootstraps)"


	**************************
	*** 2 Monto per capita ***
	**************************
	use `"`c(sysdir_personal)'/users/$pais/bootstraps/`bootstrap'/`varlist'PC"', clear


	***********************************
	*** 2.1. Intervalo de confianza ***
	ci estimacion
	noisily di _newline in g "  Monto:" _column(40) in y %20.0fc r(mean) ///
		in g "  I.C. (95%): " in y "+/-" %7.2fc (r(ub)/r(mean)-1)*100 "%"


	*******************************
	*** 2.2 Resultados globales ***
	local RECT = r(mean)/`PIB'*100

	ci contribuyentes
	noisily di in g "  Contribuyentes/Beneficiarios:" _column(40) in y %20.0fc r(mean) ///
		in g "  I.C. (95%): " in y "+/-" %7.2fc (r(ub)/r(mean)-1)*100 "%"
	local POBCONTT = r(mean)*`bootstrap'

	ci poblacion
	noisily di in g "  Poblaci{c o'}n potencial:" _column(40) in y %20.0fc r(mean) ///
		in g "  I.C. (95%): " in y "+/-" %7.2fc (r(ub)/r(mean)-1)*100 "%"

	ci montopc
	noisily di in g "  Per c{c a'}pita:" _column(40) in y %20.0fc r(mean) ///
		in g "  I.C. (95%): " in y "+/-" %7.2fc (r(ub)/r(mean)-1)*100 "%"

	ci edad39
	noisily di in g "  Edad 39:" _column(40) in y %20.0fc r(mean) ///
		in g "  I.C. (95%): " in y "+/-" %7.2fc (r(ub)/r(mean)-1)*100 "%"
	local edad39_boot = r(mean)

	* Y label *
	if `edad39_boot' == . | `edad39_boot' == 0 {
		*local ylabelpc = "Promedio"
		local ylabelpc = "Average"
	}
	else {
		*local ylabelpc = "39 a{c n~}os hombre"
		local ylabelpc = "39-year-old male"
	}


	******************
	*** 3 Perfiles ***
	******************
	use `"`c(sysdir_personal)'/users/$pais/bootstraps/`bootstrap'/`varlist'PERF"', clear


	*************************
	** 3.1 Texto bootstrap **
	if `bootstrap' > 1 {
		local boottext " Bootstraps: `bootstrap'."
	}


	***********************************
	** 3.2 Variables de los perfiles **
	if "$pais" != "" {
		local pais = ". ${pais}."
	}
	else {
		local pais = ""
	}

	* Sin kernel *
	if "`nokernel'" == "nokernel" & "`graphs'" == "graphsNO" {
		twoway line perfil1 edad, ///
			name(PerfilH`varlist', replace) ///
			title("{bf:`title'}") ///
			xtitle(edad) ///
			ytitle(`ylabelpc' equivalente) ///
			ylabel(0(.5)1.5) ///
			subtitle(Perfil de hombres`pais') ///
			caption("{it:Fuente: Elaborado por el CIEP con el Simulador v5.`boottext'}")

		twoway line perfil2 edad, ///
			name(PerfilM`varlist', replace) ///
			title("{bf:`title'}") ///
			xtitle(edad) ///
			ytitle(`ylabelpc' equivalente) ///
			ylabel(0(.5)1.5) ///
			subtitle(Perfil de mujeres`pais') ///
			caption("{it:Fuente: Elaborado por el CIEP con el Simulador v5.`boottext'}")

		twoway line contribuyentes1 edad, ///
			name(ContH`varlist', replace) ///
			title("{bf:`title'}") ///
			xtitle(edad) ///
			ytitle(porcentaje) yscale(range(0 100)) ///
			ylabel(0(20)100) ///
			subtitle(Participaci{c o'}n de hombres`pais') ///
			caption("{it:Fuente: Elaborado por el CIEP con el Simulador v5.`boottext'}")

		twoway line contribuyentes2 edad, ///
			name(ContM`varlist', replace) ///
			title("{bf:`title'}") ///
			xtitle(edad) ///
			ytitle(porcentaje) yscale(range(0 100)) ///
			ylabel(0(20)100) ///
			subtitle(Participaci{c o'}n de mujeres`pais') ///
			caption("{it:Fuente: Elaborado por el CIEP con el Simulador v5.`boottext'}")
	}

	* Con kernel *
	else if "`graphs'" == "graphsNO" {
		lpoly perfil1 edad, bwidth(`bandwidth') ci kernel(gaussian) degree(2) ///
			name(PerfilH`varlist', replace) generate(perfilH) at(edad) noscatter ///
			///title("{bf:`title'}") ///
			title("") ///
			xtitle(age) ///
			///xtitle(edad) ///
			ytitle(`ylabelpc' equivalent) ///
			///ylabel(0(.5)1.5) ///
			///subtitle(Perfil de hombres`pais') ///
			///caption("{it:Fuente: Elaborado por el CIEP con el Simulador v5.`boottext'}") ///
			//nograph

		lpoly perfil2 edad, bwidth(`bandwidth') ci kernel(gaussian) degree(2) ///
			name(PerfilM`varlist', replace) generate(perfilM) at(edad) noscatter ///
			///title("{bf:`title'}") ///
			title("") ///
			xtitle(age) ///
			///xtitle(edad) ///
			ytitle(`ylabelpc' equivalent) ///
			///ylabel(0(.5)1.5) ///
			///subtitle(Perfil de mujeres`pais') ///
			///caption("{it:Fuente: Elaborado por el CIEP con el Simulador v5.`boottext'}") ///
			//nograph

		lpoly contribuyentes1 edad, bwidth(`bandwidth') ci kernel(gaussian) degree(2) ///
			name(ContH`varlist', replace) generate(contH) at(edad) noscatter ///
			title("{bf:`title'}") ///
			xtitle(edad) ///
			ytitle(porcentaje) yscale(range(0 100)) ///
			ylabel(0(20)100) ///
			subtitle(Participaci{c o'}n de hombres`pais') ///
			caption("{it:Fuente: Elaborado por el CIEP con el Simulador v5.`boottext'}") ///
			//nograph

		lpoly contribuyentes2 edad, bwidth(`bandwidth') ci kernel(gaussian) degree(2) ///
			name(ContM`varlist', replace) generate(contM) at(edad) noscatter ///
			title("{bf:`title'}") ///
			xtitle(edad) ///
			ytitle(porcentaje) yscale(range(0 100)) ///
			ylabel(0(20)100) ///
			subtitle(Participaci{c o'}n de mujeres`pais') ///
			caption("{it:Fuente: Elaborado por el CIEP con el Simulador v5.`boottext'}") ///
			//nograph
	}

	if "`graphs'" == "graphsNO" {
		graph save PerfilH`varlist' `"`c(sysdir_personal)'/users/$pais/graphs/PerfilH`varlist'"', replace
		graph save PerfilM`varlist' `"`c(sysdir_personal)'/users/$pais/graphs/PerfilM`varlist'"', replace
		graph save ContH`varlist' `"`c(sysdir_personal)'/users/$pais/graphs/ContH`varlist'"', replace
		graph save ContH`varlist' `"`c(sysdir_personal)'/users/$pais/graphs/ContH`varlist'"', replace
	}


	***********************
	*** 4. Incidencia *****
	**********************
	use `"`c(sysdir_personal)'/users/$pais/bootstraps/`bootstrap'/`varlist'INCI"', clear
	format xhogar %15.1fc
	format distribucion %6.1fc
	format incidencia %6.1fc
	
	label define deciles 1 "I" 2 "II" 3 "III" 4 "IV" 5 "V" 6 "VI" 7 "VII" 8 "VIII" 9 "IX" 10 "X" 11 "Nacional"
	label values decil deciles


	**********************
	*** 4.1. Por hogar ***
	levelsof decil, local(deciles)
	noisily di _newline in g "  Decil" _column(20) %20s "Por hogar"
	foreach k of local deciles {
		ci xhogar if decil == `k'
		local decil2 : label deciles `k'
		noisily di in g "  `decil2'" _column(20) in y %20.0fc r(mean) ///
			in g "  I.C. (95%): " in y "+/-" %7.2fc (r(ub)/r(mean)-1)*100 "%"
	}


	*************************
	*** 4.2. Distribucion ***
	noisily di _newline in g "  Decil" _column(20) %20s "Distribuci{c o'}n"
	foreach k of local deciles {
		ci distribucion if decil == `k'
		local decil2 : label deciles `k'
		noisily di in g "  `decil2'" _column(20) in y %20.1fc r(mean) ///
			in g "  I.C. (95%): " in y "+/-" %7.2fc (r(ub)/r(mean)-1)*100 "%"
	}


	***********************
	*** 4.3. Incidencia ***
	noisily di _newline in g "  Decil" _column(20) %20s "Incidencia (% `rellabel')"
	foreach k of local deciles {
		ci incidencia if decil == `k'
		local decil2 : label deciles `k'
		noisily di in g "  `decil2'" _column(20) in y %20.1fc r(mean) ///
			in g "  I.C. (95%): " in y "+/-" %7.2fc (r(ub)/r(mean)-1)*100 "%"
	}



	***********************/
	*** 5. CICLO DE VIDA ***
	************************
	use `"`c(sysdir_personal)'/users/$pais/bootstraps/`bootstrap'/`varlist'CICLO"', clear
	
	* Labels *
	label define deciles 1 "I" 2 "II" 3 "III" 4 "IV" 5 "V" 6 "VI" 7 "VII" 8 "VIII" 9 "IX" 10 "X" 11 "Nacional"
	label values decil deciles

	replace escol = 3 if escol == 4
	label define escol 0 "Ninguna" 1 "B{c a'}sica" 2 "Media superior" 3 "Superior o posgrado"
	label values escol escol
	
	label define sexo 1 "Hombres" 2 "Mujeres"
	label values sexo sexo



	***********************************
	*** 5.1 Piramide de la variable ***
	if "`graphs'" == "graphs" {
		poblaciongini `varlist', title("`title'") nombre(`nombre') boottext(`boottext') rect(`RECT') base(`base') `graphs' id($id)
	}



	************/
	*** Final ***
	*************
	use `original', clear

	timer off 7
	timer list 7
	noisily di _newline in g "  {bf:`title' time}: " in y round(`=r(t7)/r(nt7)',.1) in g " segs."
}
end



*****************
*** Poblacion ***
*****************
program poblaciongini
	version 13.1
	syntax varname, NOMbre(string) [TITle(string) Rect(real 100) BOOTtext(string) BASE(string) Graphs ID(string)]


	*************************
	*** 1. Variable total ***
	tabstat `varlist', stat(sum) save
	tempname GTOT
	matrix `GTOT' = r(StatTotal)


	******************
	*** 2. Deciles ***
	levelsof decil, local(deciles)
	foreach k of local deciles {
		tabstat `varlist' if decil == `k', stat(sum) save
		tempname GDEC
		matrix `GDEC' = r(StatTotal)
		local gdeclab`k' = `GDEC'[1,1]/`GTOT'[1,1]*100
	}

	* Labels *
	tempvar grupo
	g `grupo' = 1 if decil <= 5
	replace `grupo' = 2 if decil > 5 & decil < 10
	replace `grupo' = 3 if decil == 10

	tempname grupoval
	label define `grupoval' 1 `"{bf:I-V} (`=string(`gdeclab1'+`gdeclab2'+`gdeclab3'+`gdeclab4'+`gdeclab5',"%7.0fc")'%)"' ///
		2 `"{bf:VI-IX} (`=string(`gdeclab6'+`gdeclab7'+`gdeclab8'+`gdeclab9',"%7.0fc")'%)"' ///
		3 `"{bf:X} (`=string(`gdeclab10',"%7.0fc")'%)"'
	label values `grupo' `grupoval'
	label var `grupo' "deciles"


	***************
	*** 3. Sexo ***
	levelsof sexo, local(sexo)
	foreach k of local sexo {
		tabstat `varlist' if sexo == `k', stat(sum) save
		tempname GSEX
		matrix `GSEX' = r(StatTotal)
		local gsexlab`k' = `GSEX'[1,1]/`GTOT'[1,1]*100
	}


	*********************************
	*** 4. Educational attainment ***
	levelsof escol, local(escol)
	foreach k of local escol {
		tabstat `varlist' if escol == `k', stat(sum) save
		tempname GESC
		matrix `GESC' = r(StatTotal)
		local gesclab`k' = `GESC'[1,1]/`GTOT'[1,1]*100
	}

	* Labels *
	tempvar grupoesc
	g `grupoesc' = 1 if escol < 2
	replace `grupoesc' = 2 if escol == 2
	replace `grupoesc' = 3 if escol > 2 & escol != .

	tempname grupoescval
	label define `grupoescval' 1 `"{bf:B{c a'}sica o menos} (`=string(`gesclab0'+`gesclab1',"%7.0fc")'%)"' ///
		2 `"{bf:Media superior} (`=string(`gesclab2',"%7.0fc")'%)"' ///
		3 `"{bf:Superior o m{c a'}s} (`=string(`gesclab3',"%7.0fc")'%)"'
	label values `grupoesc' `grupoescval'
	label var `grupoesc' "escolaridad"


	*****************
	*** 5. Graphs ***
	graphpiramide `varlist', over(`grupo') title("`title'") rect(`rect') ///
		men(`=string(`gsexlab1',"%7.0fc")') women(`=string(`gsexlab2',"%7.0fc")') ///
		boot(`boottext') base(`base')
	*graphpiramide `varlist', over(`grupoesc') title("`title'") rect(`rect') ///
		men(`=string(`gsexlab1',"%7.0fc")') women(`=string(`gsexlab2',"%7.0fc")') ///
		boot(`boottext') base(`base')
end


**********************
*** Pyramid Graphs ***
**********************
program graphpiramide
	version 13.1

	syntax varname, Over(varname) Men(string) Women(string) ///
		[Title(string) BOOTtext(string) Rect(real 100) BASE(string) ID(string)]

	* Title *
	local titleover : variable label `over'

	****************************
	*** 1. Valores agregados ***
	tempname TOT POR
	egen double `TOT' = sum(`varlist')
	g double `POR' = `varlist'/`TOT'*100

	* Max number *
	tempvar PORmax
	egen double `PORmax' = sum(`POR'), by(edad sexo)

	tabstat `PORmax', stat(max min) save
	tempname PORmaxval
	matrix `PORmaxval' = r(StatTotal)

	* By age *
	tempname AGEH AGEM
	tabstat `POR' if edad < 18 & sexo == 1, by(`over') stat(sum) save
	matrix `AGEH' = [r(Stat1),r(Stat2),r(Stat3)]
	tabstat `POR' if edad < 18 & sexo == 2, by(`over') stat(sum) save
	matrix `AGEM' = [r(Stat1),r(Stat2),r(Stat3)]

	tempname AGEH1 AGEM1
	tabstat `POR' if edad >= 18 & edad < 65 & sexo == 1, by(`over') stat(sum) save
	matrix `AGEH1' = [r(Stat1),r(Stat2),r(Stat3)]
	tabstat `POR' if edad >= 18 & edad < 65 & sexo == 2, by(`over') stat(sum) save
	matrix `AGEM1' = [r(Stat1),r(Stat2),r(Stat3)]

	tempname AGEH2 AGEM2
	tabstat `POR' if edad >= 65 & sexo == 1, by(`over') stat(sum) save
	matrix `AGEH2' = [r(Stat1),r(Stat2),r(Stat3)]
	tabstat `POR' if edad >= 65 & sexo == 2, by(`over') stat(sum) save
	matrix `AGEM2' = [r(Stat1),r(Stat2),r(Stat3)]


	*******************
	*** 2. GRAFICAS ***
	* Edades *
	forvalues k=0(1)120 {
		if `k' != 0 & `k' != 5 & `k' != 10 & `k' != 15 & `k' != 20 & `k' != 25 & `k' != 30 ///
			& `k' != 35 & `k' != 40 & `k' != 45 & `k' != 50 & `k' != 55 ///
			& `k' != 60 & `k' != 65 & `k' != 70 & `k' != 75 & `k' != 80 ///
			& `k' != 85 & `k' != 90 & `k' != 95 & `k' != 100 & `k' != 105 ///
			& `k' != 110 & `k' != 115 & `k' != 120 {
			local relabel `"`relabel' `=`k'+1' " " "'
		}
		else {
			local relabel `"`relabel' `=`k'+1' "`k'" "'
		}
	}

	* REC % del PIB * 
	if "`rect'" != "100" {
		local rect `"{bf: Tama{c n~}o}: `=string(`rect',"%6.3fc")' % PIB"'
		local rect ""
	}
	else {
		local rect ""
	}

	* Base *
	if "`base'" != "" {
		local base " `base'"
	}

	* Boottext *
	if "`boottext'" != "" {
		local boottext " `boottext'"
	}

	graph hbar (sum) `POR' if sexo == 1, ///
		over(`over') over(edad, axis(off noextend noline outergap(0)) descending ///
		relabel(`relabel')) ///
		stack asyvars xalternate ///
		yscale(noextend noline /*range(-7(1)7)*/) ///
		blabel(none, format(%5.1fc)) ///
		t2title({bf:Hombres} (`men'%), size(medsmall)) ///
		/*t2title({bf:Men} (`men'%), size(medsmall))*/ ///
		ytitle(porcentaje) ///
		/*ytitle(percentage)*/ ///
		ylabel(`=`PORmaxval'[2,1]'(1)`=`PORmaxval'[1,1]', format(%7.0fc) noticks) ///
		name(H`varlist', replace) ///
		legend(cols(4) pos(6) bmargin(zero) label(1 "") label(2 "") label(3 "`rect'") ///
		label(4 "") label(5 "") label(6 "") label(7 "") label(8 "") label(9 "") ///
		label(10 "") symxsize(0)) ///
		yreverse ///
		plotregion(margin(zero)) ///
		graphregion(margin(zero)) aspectratio(, placement(right))

	graph hbar (sum) `POR' if sexo == 2, ///
		over(`over') over(edad, axis(noextend noline outergap(0)) descending ///
		relabel(`relabel') label(labsize(vsmall) labcolor("122 122 122"))) ///
		stack asyvars ///
		yscale(noextend noline /*range(-7(1)7)*/) /// |
		blabel(none, format(%5.1fc)) ///
		t2title({bf:Mujeres} (`women'%), size(medsmall)) ///
		/*t2title({bf:Women} (`women'%), size(medsmall))*/ ///
		ytitle(porcentaje) ///
		/*ytitle(percentage)*/ ///
		ylabel(`=`PORmaxval'[2,1]'(1)`=`PORmaxval'[1,1]', format(%7.0fc) noticks) ///
		name(M`varlist', replace) ///
		legend(cols(4) pos(5) bmargin(zero) size(vsmall) keygap(1) symxsize(3) textwidth(30) forcesize) ///
		plotregion(margin(zero)) ///
		graphregion(margin(zero)) aspectratio(, placement(left))

	graph combine H`varlist' M`varlist', ///
		name(`=substr("`varlist'",1,10)'_`=substr("`titleover'",1,3)', replace) ycommon ///
		title("{bf:Perfil} de `title'") subtitle("$pais") ///
		///title("`title' by sex, age and `titleover'") ///
		caption("{it:Fuente: Elaborado con el Simulador Fiscal CIEP v5 e informaci{c o'}n del INEGI, ENIGH 2018.}" "Fecha: `c(current_date)', `c(current_time)'.") ///
		/*caption("{it: Source: Own estimations.`boottext'}")*/ ///
		note(`"{bf:Nota}: Porcentajes entre par{c e'}ntesis representan la concentraci{c o'}n de `title' en cada grupo."') ///
		/*note(`"{bf:Note}: Percentages inside parenthesis represent the concentration of `title' in each group."')*/

	*graph export `"`c(sysdir_personal)'/users/$pais/graphs/`varlist'_`titleover'.eps"', replace name(`=substr("`varlist'",1,10)'_`=substr("`titleover'",1,3)')
	graph save `=substr("`varlist'",1,10)'_`=substr("`titleover'",1,3)' `"`c(sysdir_personal)'/users/$pais/graphs/`varlist'_`titleover'.gph"', replace

	if "$export" != "" {
		graph export `"$export/`varlist'_`titleover'.png"', replace name(`=substr("`varlist'",1,10)'_`=substr("`titleover'",1,3)')
	}

	capture window manage close graph H`varlist'
	capture window manage close graph M`varlist'

end
