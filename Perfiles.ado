program define Perfiles
quietly {
	timer on 7
	syntax varname [if] [fweight/], ///
		[BOOTstrap(int 1) ///
		NOGraphs NOOutput Noisily ///
		BANDwidth(int 5) ///
		MACro(string) ///
		FOLIO(string) ///
		NOKernel POBGraph ANIOVP(int -1) ANIOPE(int -1) TITLE(string) ///
		EXCEL]





	*******************
	*** 0. Defaults ***
	*******************
	if `aniovp' == -1 {
		local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
		local aniovp = substr(`"`=trim("`fecha'")'"',1,4)
	}
	if `aniope' == -1 {
		local aniope = `aniovp'
	}
	if `aniope' >= 2022 {
		local anioenigh = 2022
	}
	if `aniope' >= 2020 & `aniope' < 2022 {
		local anioenigh = 2020
	}
	if `aniope' >= 2018 & `aniope' < 2020 {
		local anioenigh = 2018
	}
	if `aniope' >= 2016 & `aniope' < 2018 {
		local anioenigh = 2016
	}
	local base = "ENIGH `anioenigh'"


	** 0.1 Macros: PIB **
	preserve
	PIBDeflactor, anio(`=anioenigh') nographs nooutput
	forvalues k=1(1)`=_N' {
		if anio[`k'] == `=anioenigh' {
			local PIB = pibY[`k']
			local deflator = deflator[`k']
			continue, break
		}
	}
	restore


	** 0.2 Texto introductorio **
	if "`title'" == "" {
		local title : variable label `varlist'
	}
	local nombre `"`=subinstr("`varlist'","_","",.)'"'
	noisily di _newline(2) in g "  {bf:Variable label: " in y "`title'}"
	noisily di in g "  {bf:Variable name: " in y "`varlist'}"
	if "`if'" != "" {
		noisily di in g "  {bf:If: " in y `"`if'}"'
	}
	else {
		noisily di in g "  {bf:If: " in y "Sin restricci{c o'}n. Todas las observaciones utilizadas.}"	
	}
	noisily di in g "  {bf:Bootstraps: " in y `bootstrap' "}" _newline


	** 0.3 Variables en valor presente **
	tempvar ingreso
	capture g double `ingreso' = ingbrutotot/`deflator'
	if _rc != 0 {
		g double `ingreso' = `varlist'/`deflator'
		label var `ingreso' "[Sin variable de ingreso total]"
	}
	else {
		local rellabel : variable label ingbrutotot
		label var `ingreso' "`rellabel'"
	}
	*replace `varlist' = `varlist'/`deflator'


	** 0.4 Base de datos inicial **
	tempfile inicial
	save `inicial', replace



	************************
	*** 1. Archivos POST ***
	************************

	** 1.1 Variables de control **
	tempvar boot
	g `boot' = .

	** 1.2 Directorios y archivos **
	capture mkdir `"`c(sysdir_site)'/users/"'
	capture mkdir `"`c(sysdir_site)'/users/$id/"'
	capture mkdir `"`c(sysdir_site)'/users/$id/graphs/"'
	capture mkdir `"`c(sysdir_site)'/users/$id/bootstraps/"'
	capture mkdir `"`c(sysdir_site)'/users/$id/bootstraps/`bootstrap'"'


	** 1.2.1 Información per cápita **
	* Output: `varlist'PC.dta *
	postfile PC2 double(estimacion contribuyentes poblacion montopc hombrespc mujerespc pob0_18pc pob19_64pc pob65pc) ///
		using `"`c(sysdir_site)'/users/$id/bootstraps/`bootstrap'/`varlist'PC2"', replace


	** 1.2.2. Información por edad y sexo **
	* Output: `varlist'PERF.dta *
	postfile PERF edad double(perfil1 perfil2 contribuyentes1 contribuyentes2 estimacion1 estimacion2 ///
		pobcont1 pobcont2 poblacion1 poblacion2) ///
		using `"`c(sysdir_site)'/users/$id/bootstraps/`bootstrap'/`varlist'PERF"', replace


	** 1.2.3. Incidencia por hogares **
	* Output: `varlist'INCI.dta *
	postfile INCI decil double(xhogar distribucion incidencia hogares) ///
		using `"`c(sysdir_site)'/users/$id/bootstraps/`bootstrap'/`varlist'INCI"', replace


	** 1.2.4. Ciclo de vida **
	* Output: `varlist'CICLO.dta *
	postfile CICLO bootstrap sexo edad decil double(poblacion `varlist') ///
		using `"`c(sysdir_site)'/users/$id/bootstraps/`bootstrap'/`varlist'CICLO"', replace


	** 1.2.5. Proyecciones demográficas de recaudación/gasto **
	* Output: `varlist'REC.dta *
	postfile REC str30 (modulo) int (bootstrap anio aniobase) ///
		double (estimacion ///
		contribuyentes poblacion montopc ///
		contribuyentes_Hom contribuyentes_Muj ///
		contribuyentes_0_24 contribuyentes_25_49 ///
		contribuyentes_50_74 contribuyentes_75_mas) ///
		using `"`c(sysdir_site)'/users/$id/bootstraps/`bootstrap'/`varlist'REC"', replace



	*********************
	*** 2. Bootstraps ***
	*********************
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

		** 2.1. Monto per capita **
		`noisily' PC `varlist' `if' [`weight' = `exp'*`boot'], post
		tempname REC
		matrix `REC' = r(REC)


		*** 2.2. Perfiles ***
		`noisily' PERF `varlist' `if' [`weight' = `exp'*`boot'], montopc(`=r(pc)') post


		*** 2.3. Incidencia por hogar **
		tempvar decil
		capture confirm variable decil
		if _rc != 0 {
			noisily di _newline in g "{bf:  No hay variable: " in y "decil" in g ". Se genera con: " in y "`varlist'" in g ".}"
			xtile `decil' = `varlist' [`weight' = `exp'*`boot'], n(10)
		}
		else {
			g `decil' = decil
		}
		`noisily' INCI `varlist' `if' [`weight' = `exp'*`boot'], folio(folioviv foliohog) n(`decil') relativo(`ingreso') post


		*** 2.4. Ciclo de Vida ***/
		`noisily' CICLO `varlist' `if' [`weight' = `exp'*`boot'], post boot(`k') decil(`decil')


		*** 2.5. Proyecciones ***
		`noisily' REC `varlist', post pob(poblacion) boot(`k') aniobase(`aniope') title(`title')
	}


	***********************
	*** 1.4. Post close ***
	noisily di _newline in y "  Simulador.ado" in g " (post-bootstraps)"
	postclose PC2
	postclose PERF
	postclose INCI
	postclose CICLO
	postclose REC



	**************************
	*** 2 Monto per capita ***
	**************************
	use `"`c(sysdir_site)'/users/$id/bootstraps/`bootstrap'/`varlist'PC2"', clear


	***********************************
	*** 2.1. Intervalo de confianza ***
	ci means estimacion
	noisily di _newline in g "  Monto:" _column(40) in y %20.0fc r(mean) ///
		in g "  I.C. (95%): " in y "+/-" %7.2fc (r(ub)/r(mean)-1)*100 "%"


	* Guardar en Excel *
	if `aniope' == 2008 {
		local col = "B"
	}
	if `aniope' == 2010 {
		local col = "C"
	}
	if `aniope' == 2012 {
		local col = "D"
	}
	if `aniope' == 2014 {
		local col = "E"
	}
	if `aniope' == 2016 {
		local col = "F"
	}
	if `aniope' == 2018 {
		local col = "G"
	}
	if `aniope' == 2020 {
		local col = "H"
	}
	if `aniope' == 2022 {
		local col = "I"
	}
	if `aniope' == 2024 {
		local col = "J"
	}

	ci means hombrespc

	* Guardar en Excel *
	if "`excel'" == "excel" {
		local j = 12
		putexcel set "`c(sysdir_site)'/users/$id/Deciles.xlsx", modify sheet("`varlist'")
		putexcel A`j' = "Hombres"
		putexcel `col'`j' = `=r(mean)', nformat(number_sep)

		ci means mujerespc
		local ++j
		putexcel A`j' = "Mujeres"
		putexcel `col'`j' = `=r(mean)', nformat(number_sep)

		ci means pob0_18pc
		local ++j
		putexcel A`j' = "0-18"
		putexcel `col'`j' = `=r(mean)', nformat(number_sep)

		ci means pob19_64pc
		local ++j
		putexcel A`j' = "19-64"
		putexcel `col'`j' = `=r(mean)', nformat(number_sep)

		ci means pob65pc
		local ++j
		putexcel A`j' = "65+"
		putexcel `col'`j' = `=r(mean)', nformat(number_sep)
	}

	*******************************
	*** 2.2 Resultados globales ***
	local RECT = r(mean)/`PIB'*100
	scalar `varlist'GPIB = `RECT'

	ci means contribuyentes
	noisily di in g "  Contribuyentes/Beneficiarios:" _column(40) in y %20.0fc r(mean) ///
		in g "  I.C. (95%): " in y "+/-" %7.2fc (r(ub)/r(mean)-1)*100 "%"
	local POBCONTT = r(mean)*`bootstrap'

	ci means poblacion
	noisily di in g "  Poblaci{c o'}n potencial:" _column(40) in y %20.0fc r(mean) ///
		in g "  I.C. (95%): " in y "+/-" %7.2fc (r(ub)/r(mean)-1)*100 "%"

	ci means montopc
	noisily di in g "  Per c{c a'}pita:" _column(40) in y %20.0fc r(mean) ///
		in g "  I.C. (95%): " in y "+/-" %7.2fc (r(ub)/r(mean)-1)*100 "%"

	* Y label *
	local ylabelpc = "Promedio"
	*local ylabelpc = "Average"



	******************
	*** 3 Perfiles ***
	/******************
	use `"`c(sysdir_site)'/users/$id/bootstraps/`bootstrap'/`varlist'PERF"', clear


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
	if "`nokernel'" == "nokernel" & "$nographs" != "nographs" & "`nographs'" != "nographs" {

		twoway line perfil1 edad, ///
			name(PerfilH`varlist', replace) ///
			title("{bf:`title'}") ///
			xtitle(edad) ///
			ytitle(`ylabelpc' equivalente) ///
			///ylabel(0(.5)1.5) ///
			subtitle(Perfil de hombres`pais') ///
			caption("{bf:Fuente}: Elaborado con el Simulador Fiscal CIEP v5.`boottext'")

		twoway line perfil2 edad, ///
			name(PerfilM`varlist', replace) ///
			title("{bf:`title'}") ///
			xtitle(edad) ///
			ytitle(`ylabelpc' equivalente) ///
			///ylabel(0(.5)1.5) ///
			subtitle(Perfil de mujeres`pais') ///
			caption("{bf:Fuente}: Elaborado con el Simulador Fiscal CIEP v5.`boottext'")

		twoway line contribuyentes1 edad, ///
			name(ContH`varlist', replace) ///
			title("{bf:`title'}") ///
			xtitle(edad) ///
			ytitle(porcentaje) yscale(range(0 100)) ///
			ylabel(0(20)100) ///
			subtitle(Participaci{c o'}n de hombres`pais') ///
			caption("{bf:Fuente}: Elaborado con el Simulador Fiscal CIEP v5.`boottext'")

		twoway line contribuyentes2 edad, ///
			name(ContM`varlist', replace) ///
			title("{bf:`title'}") ///
			xtitle(edad) ///
			ytitle(porcentaje) yscale(range(0 100)) ///
			ylabel(0(20)100) ///
			subtitle(Participaci{c o'}n de mujeres`pais') ///
			caption("{bf:Fuente}: Elaborado con el Simulador Fiscal CIEP v5.`boottext'")
	}

	* Con kernel *
	else if "$nographs" != "nographs" & "`nographs'" != "nographs" {
		lpoly perfil1 edad, bwidth(`bandwidth') ci means kernel(gaussian) degree(3) ///
			name(PerfilH`varlist', replace) generate(perfilH) at(edad) noscatter ///
			title("{bf:`title'}") ///
			xtitle(edad) ///
			ytitle(`ylabelpc' equivalent) ///
			///ylabel(0(.5)1.5) ///
			subtitle(Perfil de hombres`pais') ///
			caption("{bf:Fuente}: Elaborado con el Simulador Fiscal CIEP v5.`boottext'")
			//nograph

		lpoly perfil2 edad, bwidth(`bandwidth') ci means kernel(gaussian) degree(3) ///
			name(PerfilM`varlist', replace) generate(perfilM) at(edad) noscatter ///
			title("{bf:`title'}") ///
			xtitle(edad) ///
			ytitle(`ylabelpc' equivalent) ///
			///ylabel(0(.5)1.5) ///
			subtitle(Perfil de mujeres`pais') ///
			caption("{bf:Fuente}: Elaborado con el Simulador Fiscal CIEP v5.`boottext'")
			//nograph

		lpoly contribuyentes1 edad, bwidth(`bandwidth') ci means kernel(gaussian) degree(3) ///
			name(ContH`varlist', replace) generate(contH) at(edad) noscatter ///
			title("{bf:`title'}") ///
			xtitle(edad) ///
			ytitle(porcentaje) yscale(range(0 100)) ///
			ylabel(0(20)100) ///
			subtitle(Participaci{c o'}n de hombres`pais') ///
			caption("{bf:Fuente}: Elaborado con el Simulador Fiscal CIEP v5.`boottext'")
			//nograph

		lpoly contribuyentes2 edad, bwidth(`bandwidth') ci means kernel(gaussian) degree(3) ///
			name(ContM`varlist', replace) generate(contM) at(edad) noscatter ///
			title("{bf:`title'}") ///
			xtitle(edad) ///
			ytitle(porcentaje) yscale(range(0 100)) ///
			ylabel(0(20)100) ///
			subtitle(Participaci{c o'}n de mujeres`pais') ///
			caption("{bf:Fuente}: Elaborado con el Simulador Fiscal CIEP v5.`boottext'")
			//nograph
	}

	if "$nographs" != "nographs" & "`nographs'" != "nographs" {
		graph save PerfilH`varlist' `"`c(sysdir_site)'/users/$id/graphs/PerfilH`varlist'"', replace
		graph save PerfilM`varlist' `"`c(sysdir_site)'/users/$id/graphs/PerfilM`varlist'"', replace
		graph save ContH`varlist' `"`c(sysdir_site)'/users/$id/graphs/ContH`varlist'"', replace
		graph save ContH`varlist' `"`c(sysdir_site)'/users/$id/graphs/ContH`varlist'"', replace
	}


	**********************/
	*** 4. Incidencia *****
	***********************
	use `"`c(sysdir_site)'/users/$id/bootstraps/`bootstrap'/`varlist'INCI"', clear
	format xhogar %15.1fc
	format distribucion %6.1fc
	format incidencia %6.1fc

	label define deciles 1 "I" 2 "II" 3 "III" 4 "IV" 5 "V" 6 "VI" 7 "VII" 8 "VIII" 9 "IX" 10 "X" 11 "Nac"
	label values decil deciles


	*** 4.1 Por hogar ***
	levelsof decil, local(deciles)
	noisily di _newline in g "  Decil" _column(20) %20s "Por hogar"
	local j = 2
	foreach k of local deciles {
		ci means xhogar if decil == `k'
		local decil2 : label deciles `k'
		noisily di in g "  `decil2'" _column(20) in y %20.0fc r(mean) ///
			in g "  I.C. (95%): " in y "+/-" %7.2fc (r(ub)/r(mean)-1)*100 "%"
		scalar `varlist'`decil2' = r(mean)

		* Guardar en Excel *
		if "`excel'" == "excel" {
			if `aniope' == 2008 {
				local col = "B"
			}
			if `aniope' == 2010 {
				local col = "C"
			}
			if `aniope' == 2012 {
				local col = "D"
			}
			if `aniope' == 2014 {
				local col = "E"
			}
			if `aniope' == 2016 {
				local col = "F"
			}
			if `aniope' == 2018 {
				local col = "G"
			}
			if `aniope' == 2020 {
				local col = "H"
			}
			if `aniope' == 2022 {
				local col = "I"
			}
			if `aniope' == 2024 {
				local col = "J"
			}
			putexcel set "`c(sysdir_site)'/users/$id/Deciles.xlsx", modify sheet("`varlist'")
			putexcel A1 = "Decil"
			if "`decil2'" == "Nac" {
				local j = 17
			}
			putexcel A`j' = "`decil2'"
			putexcel `col'1 = "`aniope'"
			putexcel `col'`j' = `=scalar(`varlist'`decil2')', nformat(number_sep)
			local ++j
		}

		* Output */
		if "$output" == "output" {
			local incd = "`incd' `=string(`=`varlist'`decil2'',"%10.0f")',"
		}
	}


	*** 4.2 Distribucion ***
	noisily di _newline in g "  Decil" _column(20) %20s "Distribuci{c o'}n"
	foreach k of local deciles {
		ci means distribucion if decil == `k'
		local decil2 : label deciles `k'
		noisily di in g "  `decil2'" _column(20) in y %20.1fc r(mean) ///
			in g "  I.C. (95%): " in y "+/-" %7.2fc (r(ub)/r(mean)-1)*100 "%"
		scalar dis`varlist'`decil2' = r(mean)

		if "$output" == "output" {
			local incd2 = "`incd2' `=string(`=dis`varlist'`decil2'',"%10.1f")',"
		}
	}
	

	*** 4.3 Incidencia ***
	noisily di _newline in g "  Decil" _column(20) %20s "Incidencia (% `rellabel')"
	foreach k of local deciles {
		ci means incidencia if decil == `k'
		if r(mean) == . {
			continue
		}
		local decil2 : label deciles `k'
		noisily di in g "  `decil2'" _column(20) in y %20.1fc r(mean) ///
			in g "  I.C. (95%): " in y "+/-" %7.2fc (r(ub)/r(mean)-1)*100 "%"
		scalar inc`varlist'`decil2' = r(mean)

		if "$output" == "output" {
			local incd3 = "`incd3' `=string(`=inc`varlist'`decil2'',"%10.1f")',"
		}
	}


	** 4.4 Output **
	if "$output" != "" & "`nooutput'" == "" {
		local lengthINCD = strlen("`incd'")
		local lengthINCD2 = strlen("`incd2'")
		local lengthINCD3 = strlen("`incd3'")
		capture log on output
		noisily di in w "INCD: [`=substr("`incd'",1,`=`lengthINCD'-1')']"
		noisily di in w "INCD2: [`=substr("`incd2'",1,`=`lengthINCD2'-1')']"
		noisily di in w "INCD3: [`=substr("`incd3'",1,`=`lengthINCD3'-1')']"
		capture log off output
	}



	***********************/
	*** 5. CICLO DE VIDA ***
	************************
	use `"`c(sysdir_site)'/users/$id/bootstraps/`bootstrap'/`varlist'CICLO"', clear

	* Labels *
	label define deciles 1 "I" 2 "II" 3 "III" 4 "IV" 5 "V" 6 "VI" 7 "VII" 8 "VIII" 9 "IX" 10 "X" 11 "Nac"
	label values decil deciles

	label define sexo 1 "Hombres" 2 "Mujeres"
	label values sexo sexo

	g grupo_edad = 1
	replace grupo_edad = 2 if edad > 4
	replace grupo_edad = 3 if edad > 9
	replace grupo_edad = 4 if edad > 14
	replace grupo_edad = 5 if edad > 19
	replace grupo_edad = 6 if edad > 24
	replace grupo_edad = 7 if edad > 29
	replace grupo_edad = 8 if edad > 34
	replace grupo_edad = 9 if edad > 39
	replace grupo_edad = 10 if edad > 44
	replace grupo_edad = 11 if edad > 49
	replace grupo_edad = 12 if edad > 54
	replace grupo_edad = 13 if edad > 59
	replace grupo_edad = 14 if edad > 64
	replace grupo_edad = 15 if edad > 69
	replace grupo_edad = 16 if edad > 74
	replace grupo_edad = 17 if edad > 79
	replace grupo_edad = 18 if edad > 84
	replace grupo_edad = 19 if edad > 89
	replace grupo_edad = 20 if edad > 94
	replace grupo_edad = 21 if edad > 99
	*replace grupo_edad = 22 if edad > 104
	*replace grupo_edad = 23 if edad > 109

	label define grupo_edad 1 "0-4" 2 "5-9" 3 "10-14" 4 "15-19" ///
		5 "20-24" 6 "25-29" 7 "30-34" 8 "35-39" 9 "40-44" 10 "45-49" ///
		11 "50-54" 12 "55-59" 13 "60-64" 14 "65-69" 15 "70-74" ///
		16 "75-79" 17 "80-84" 18 "85-89" 19 "90-94" 20 "95-99" ///
		21 "100+"
	label values grupo_edad grupo_edad

	***********************************
	*** 5.1 Piramide de la variable ***
	poblaciongini `varlist', title("`title'") nombre(`nombre') ///
		boottext(`boottext') rect(`RECT') base(`base') graphs id($id) pib(`PIB') `nooutput' `nographs'



	**********************
	*** 6. RECAUDACION ***
	**********************
	use `"`c(sysdir_site)'/users/$id/bootstraps/`bootstrap'/`varlist'REC"', clear
	forvalues k=1(1)`=_N' {
		if anio[`k'] == aniobase[`k'] {
			local ajuste = `REC'[1,1]/estimacion[`k']
			continue, break
		}
	}
	replace estimacion = estimacion*`ajuste'
	*noisily tabstat estimacion if anio == 2025, format(%20.0fc)
	save `"`c(sysdir_site)'/users/$id/bootstraps/`bootstrap'/`varlist'REC"', replace

	ProyGraph `varlist' `aniope' `bootstrap' `nographs'



	******************************
	*** 7. Gráficas combinadas ***
	******************************
	if "$nographs" != "nographs" & "`nographs'" != "nographs" {
		graph combine H`varlist' `varlist'Proj, ///
			name(`=substr("`varlist'",1,10)'_`aniope', replace) ///
			title("{bf:`title'}") ///
			subtitle(" Perfil etario (MXN `aniovp') y proyección demográfica (% PIB)", margin(bottom)) ///
			caption("Fuente: Elaborado por el CIEP, con información de INEGI/`base', INEGI/BIE, CONAPO y SHCP.") ///
			note(`"Nota: Los porcentajes representan la concentración de cada grupo."') ///
			///title("`title' {bf:profile}") ///
			///subtitle(" Age profile (MXN `aniovp') and demographic projection (% GDP)", margin(bottom)) ///
			///caption("{bf:Source}: Prepared by CIEP, using data from `base'.") ///
			///note(`"{bf:Note}: Percentages in parentheses show the concentration in each group."')

		graph save `=substr("`varlist'",1,10)'_`aniope' `"`c(sysdir_site)'/users/$id/graphs/`varlist'_`aniope'.gph"', replace
		if "$export" != "" {
			graph export `"$export/`varlist'_`aniope'.png"', replace name(`=substr("`varlist'",1,10)'_`aniope')
		}
		capture window manage close graph H`varlist'
		capture window manage close graph `varlist'Proj
	}


	************/
	*** Final ***
	*************
	use `inicial', clear

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
	syntax varname, NOMbre(string) PIB(real) ///
		[TITle(string) Rect(real 100) BOOTtext(string) BASE(string) Graphs ID(string) NOOutput NOGraphs]


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
	label define `grupoval' 1 `"{bf:Deciles I-V}, `=string(`gdeclab1'+`gdeclab2'+`gdeclab3'+`gdeclab4'+`gdeclab5',"%7.0fc")'%"' ///
		2 `"{bf:VI-IX}, `=string(`gdeclab6'+`gdeclab7'+`gdeclab8'+`gdeclab9',"%7.0fc")'%"' ///
		3 `"{bf:X}, `=string(`gdeclab10',"%7.0fc")'%"'
	label values `grupo' `grupoval'
	label var `grupo' "deciles"
	scalar `varlist'GIV = `gdeclab1'+`gdeclab2'+`gdeclab3'+`gdeclab4'+`gdeclab5'
	scalar `varlist'GVIIX = `gdeclab6'+`gdeclab7'+`gdeclab8'+`gdeclab9'
	scalar `varlist'GX = `gdeclab10'


	***************
	*** 3. Sexo ***
	levelsof sexo, local(sexo)
	foreach k of local sexo {
		tabstat `varlist' if sexo == `k', stat(sum) save
		tempname GSEX
		matrix `GSEX' = r(StatTotal)
		local gsexlab`k' = `GSEX'[1,1]/`GTOT'[1,1]*100
	}
	scalar `varlist'GH = `gsexlab1'
	scalar `varlist'GM = `gsexlab2'


	*********************************
	/*** 4. Educational attainment ***
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

	tempvar formalidad
	g `formalidad' = formal != 0
	
	tempname formalidadval
	label define `formalidadval' 1 "Con seguridad social" 0 "Sin seguridad social"
	label values `formalidad' `formalidadval'
	label var `formalidad' "formalidad"

	****************/
	*** 5. Graphs ***
	graphpiramide `varlist', over(`grupo') title("`title'") rect(`rect') ///
		men(`=string(`gsexlab1',"%7.0fc")') women(`=string(`gsexlab2',"%7.0fc")') ///
		boot(`boottext') base(`base') pib(`pib') `nooutput' `nographs'
end


**********************
*** Pyramid Graphs ***
**********************
program graphpiramide
	version 13.1

	syntax varname, Over(varname) Men(string) Women(string) PIB(real) ///
		[Title(string) BOOTtext(string) Rect(real 100) BASE(string) ID(string) NOOutput NOGraphs]

	* Title *
	local titleover : variable label `over'

	****************************
	*** 1. Valores agregados ***
	tempname TOT POR
	egen double `TOT' = sum(`varlist')
	*g double `POR' = `varlist'/`pib'*100
	g double `POR' = `varlist'/poblacion

	* Max number *
	tempvar PORmax
	egen double `PORmax' = sum(`POR'), by(grupo_edad sexo)

	tabstat `PORmax', stat(max min) save
	tempname PORmaxval
	matrix `PORmaxval' = r(StatTotal)

	* By age *
	tempname AGEH AGEM
	capture tabstat `POR' if edad < 18 & sexo == 1, by(`over') stat(sum) save
	if _rc == 0 {
		matrix `AGEH' = [r(Stat1),r(Stat2),r(Stat3)]
	}
	else {
		matrix `AGEH' = J(1,3,0)
	}
	capture tabstat `POR' if edad < 18 & sexo == 2, by(`over') stat(sum) save
	if _rc == 0 {
		matrix `AGEM' = [r(Stat1),r(Stat2),r(Stat3)]
	}
	else {
		matrix `AGEM' = J(1,3,0)
	}

	tempname AGEH1 AGEM1
	capture tabstat `POR' if edad >= 18 & edad < 65 & sexo == 1, by(`over') stat(sum) save
	if _rc == 0 {
		matrix `AGEH1' = [r(Stat1),r(Stat2),r(Stat3)]
	}
	else {
		matrix `AGEH1' = J(1,3,0)
	}
	capture tabstat `POR' if edad >= 18 & edad < 65 & sexo == 2, by(`over') stat(sum) save
	if _rc == 0 {
		matrix `AGEM1' = [r(Stat1),r(Stat2),r(Stat3)]
	}
	else {
		matrix `AGEM1' = J(1,3,0)
	}

	tempname AGEH2 AGEM2
	capture tabstat `POR' if edad >= 65 & sexo == 1, by(`over') stat(sum) save
	if _rc == 0 {
		matrix `AGEH2' = [r(Stat1),r(Stat2),r(Stat3)]
	}
	else {
		matrix `AGEH2' = J(1,3,0)
	}
	capture tabstat `POR' if edad >= 65 & sexo == 2, by(`over') stat(sum) save
	if _rc == 0 {
		matrix `AGEM2' = [r(Stat1),r(Stat2),r(Stat3)]
	}
	else {
		matrix `AGEM2' = J(1,3,0)
	}


	*******************
	*** 2. GRAFICAS ***
	if "$nographs" != "nographs" & "`nographs'" != "nographs" {

		* REC % del PIB * 
		if "`rect'" != "100" {
			local rect `"{bf: Tama{c n~}o}: `=string(`rect',"%6.3fc")' % PIB"'
			*local rect `"{bf: Size}: `=string(`rect',"%6.3fc")' % GDP"'
		}
		else {
			local rect ""
		}

		* Boottext *
		if "`boottext'" != "" {
			local boottext " `boottext'"
		}

		graph bar (mean) `POR' /*if sexo == 1*/, ///
			over(`over') over(grupo_edad, axis(noextend outergap(0)) ///
			relabel(`relabel') ///
			label(labsize(vsmall))) ///
			/*stack*/ asyvars /*xalternate*/ ///
			yscale(noextend noline /*range(-7(1)7)*/) ///
			blabel(none, format(%5.1fc)) ///
			b1title(" ") ///
			///b2title(" {bf:Men} consume `men'% and {bf:women} `women'%", size(small)) ///
			b2title(" {bf:Hombres}, `men'%   {bf:mujeres}, `women'%", size(small)) ///
			///subtitle("Age profile 2022 (PPP)") ///
			///subtitle("Perfil etario") ///
			///ytitle(% PIB) ///
			ytitle("") ///
			///t2title({bf:Men} (`men'%), size(medsmall)) ///
			///ytitle(% GDP) ///
			///ylabel(`=round(`PORmaxval'[2,1],.1)'(.1)`=`PORmaxval'[1,1]', format(%7.1fc) noticks) ///
			ylabel(#5, format(%10.0fc) noticks) ///
			name(H`varlist', replace) ///
			legend(rows(1) pos(6)) ///
			///yreverse ///
			plotregion(margin(zero)) ///
			graphregion(margin(zero))
	}

	if "$output" != "" & "`nooutput'" != "nooutput" {
		g over = `over'
		label define over 1 "Deciles I-V" 2 "VI-IX" 3 "X"
		label values over over
		collapse (mean) valor=`POR', by(sexo grupo_edad over)
		reshape wide valor, i(sexo grupo_edad) j(over)
		reshape wide valor*, i(sexo) j(grupo_edad)
		reshape long valor1 valor2 valor3, i(sexo) j(grupo_edad)
		reshape long valor, i(sexo grupo_edad) j(over)
		replace valor = 0 if valor == .
		replace valor = valor/1000

		forvalues k=`=_N'(-1)1 {
			if sexo[`k'] == 1 {
				if over[`k'] == 1 {
					local aportHIV = "`aportHIV' `=string(`=valor[`k']',"%10.0f")',"
				}
				if over[`k'] == 2 {
					local aportHVIIX = "`aportHVIIX' `=string(`=valor[`k']',"%10.0f")',"
				}
				if over[`k'] == 3 {
					local aportHX = "`aportHX' `=string(`=valor[`k']',"%10.0f")',"			
				}
			}
			if sexo[`k'] == 2 {
				if over[`k'] == 1 {
					local aportMIV = "`aportMIV' `=string(`=valor[`k']',"%10.0f")',"
				}
				if over[`k'] == 2 {
					local aportMVIIX = "`aportMVIIX' `=string(`=valor[`k']',"%10.0f")',"
				}
				if over[`k'] == 3 {
					local aportMX = "`aportMX' `=string(`=valor[`k']',"%10.0f")',"			
				}		
			}
		}
		quietly log on output
		local lengthHIV = strlen("`aportHIV'")
		noisily di in w "APORTHIV: [`=substr("`aportHIV'",1,`=`lengthHIV'-1')']"
		local lengthHVIIX = strlen("`aportHVIIX'")
		noisily di in w "APORTHVIIX: [`=substr("`aportHVIIX'",1,`=`lengthHVIIX'-1')']"
		local lengthHX = strlen("`aportHX'")
		noisily di in w "APORTHX: [`=substr("`aportHX'",1,`=`lengthHX'-1')']"
		local lengthMIV = strlen("`aportMIV'")
		noisily di in w "APORTMIV: [`=substr("`aportMIV'",1,`=`lengthMIV'-1')']"
		local lengthMVIIX = strlen("`aportMVIIX'")
		noisily di in w "APORTMVIIX: [`=substr("`aportMVIIX'",1,`=`lengthMVIIX'-1')']"
		local lengthMX = strlen("`aportMX'")
		noisily di in w "APORTMX: [`=substr("`aportMX'",1,`=`lengthMX'-1')']"
		quietly log off output
	}
end

program define ProyGraph

	args varlist aniope bootstrap nographs

	PIBDeflactor, nographs nooutput
	tempfile PIB
	save `PIB'
	
	local currency = currency[1]
	local anio = r(aniovp)

	use `"`c(sysdir_site)'/users/$id/bootstraps/`bootstrap'/`varlist'REC.dta"', clear
	merge m:1 (anio) using `PIB', nogen keep(matched)

	local title = modulo[1]
	local anioi = anio[1]
	local aniof = 2040 // anio[_N]
	keep if anio <= `aniof'
	
	*replace estimacion = estimacion*lambda/1000000000000
	format estimacion %20.0fc

	replace estimacion = estimacion*lambda/pibYR*100
	format estimacion %7.3fc

	forvalues aniohoy = `aniope'(1)`aniope' {
	*forvalues aniohoy = 2022(1)2050 {
		tabstat estimacion /*if anio >= `aniope'*/, stat(max) save
		tempname MAX
		matrix `MAX' = r(StatTotal)
		forvalues k=1(1)`=_N' {
			if estimacion[`k'] == `MAX'[1,1] {
				local aniomax = anio[`k']
				local estimacionmax = estimacion[`k']
			}
			if anio[`k'] == `aniohoy' {
				local estimacionvp = estimacion[`k']
			}
		}

		if `estimacionvp' == . {
				local estimacionvp = 0
		}
		
		if `MAX'[1,1] == . {
			matrix `MAX' = J(1,1,0)
		}

		tabstat estimacion if anio == `aniof', stat(max) save
		tempname LAST
		matrix `LAST' = r(StatTotal)

		if "$nographs" != "nographs" & "`nographs'" != "nographs" {
			twoway (connected estimacion anio, lpattern(dot) msize(small)) ///
				(connected estimacion anio if anio == `aniohoy', mlabel(estimacion) mlabposition(12) mlabcolor("114 113 118")) ///
				(connected estimacion anio if anio == `aniof', mlabel(estimacion) mlabposition(12) mlabcolor("114 113 118")) ///
				/*if anio > 2020*/, ///
				///ytitle("billones `currency' `aniovp'") ///
				///ytitle("% PIB") ///
				///subtitle("Proyección demográfica, billones MXN `aniovp'") ///
				///subtitle("Demographic projection (% GDP)") ///
				ytitle("") ///
				///yscale(range(0)) /*ylabel(0(1)4)*/ ///
				ylabel(#5, format(%5.2fc) labsize(small)) ///
				yscale(range(0)) ///
				xlabel(`=round(`anioi',5)'(5)`=round(`aniof',5)' `aniohoy', labsize(small)) ///
				xtitle("") ///
				legend(off) ///
				xline(`aniohoy', lpattern(dot)) ///
				///yline(0, lpattern(solid) lcolor(black)) ///
				///text(`=`estimacionmax'*.05' `aniomax' "Este perfil, junto con" "las proyecciones demográficas," "obtiene un {bf:máximo en `aniomax'}.", size(medsmall) place(11) justification(right)) ///
				///text(`=`estimacionmax'*.05' `aniomax' "This age profile, along with" "CONAPO's demographic projections," "reaches a maximum in {bf:`aniomax'}.", size(medsmall) place(11) justification(right)) ///
				text(`=`estimacionvp'*0' `=round(`aniof',5)' "De `aniohoy' a `aniof',"  "el cambio sería" `"de {bf:`=string((`LAST'[1,1]/`estimacionvp'-1)*100,"%5.2f")'%}."', size(medsmall) place(11) justification(right)) ///
				///text(`=`estimacionvp'*0.25' `aniohoy' "From `aniohoy' to 2070,"  "its demand will" `"change in {bf:`=string((`LAST'[1,1]/`estimacionvp'-1)*100,"%5.2f")'%}."', size(medsmall) place(1) justification(left)) ///
				///title("{bf:Proyecci{c o'}n} de `title'") subtitle("$pais") ///
				///caption("{bf:Fuente}: Elaborado con el Simulador Fiscal CIEP v5.") ///
				name(`varlist'Proj, replace)
		}
	}

	if "$output" != "" & "`nooutput'" != "nooutput" {
		forvalues k=1(5)`=_N' {
			if anio[`k'] >= 2010 {
				local out_proy = "`out_proy' `=string(estimacion[`k'],"%8.3f")',"
			}
		}
		local lengthproy = strlen("`out_proy'")
		log on output
		noisily di in w "PROY: [`=substr("`out_proy'",1,`=`lengthproy'-1')']"
		noisily di in w "PROYMAX: [`aniomax']"
		log off output
	}
end
