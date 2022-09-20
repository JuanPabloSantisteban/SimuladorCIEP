**********************************************************
***        ACTUALIZACIÓN BASE DE DATOS                 ***
***   1) abrir archivos .iqy en Excel de Windows       ***
***   2) guardar y reemplazar .xls dentro de           ***
***      ./TemplateCIEP/basesCIEP/INEGI/SCN/           ***
***   3) correr PIBDeflactor[.ado] con opción "update" ***
**********************************************************




*!*******************************************
*!***                                    ****
*!***    Producto Interno Bruto          ****
*!***    Indice de Precios Implícitos    ****
*!***    Autor: Ricardo                  ****
*!***    Fecha: 21/Jul/21                ****
*!***                                    ****
*!*******************************************
program define PIBDeflactor, return
quietly {
	timer on 2

	** Sintaxis **
	local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
	local aniovp = substr(`"`=trim("`fecha'")'"',1,4)

	capture confirm scalar aniovp
	if _rc == 0 {
		local aniovp = scalar(aniovp)
	}

	syntax [if] [, UPDATE ANIOvp(int `aniovp') NOGraphs GEOPIB(int -1) GEODEF(int -1) ///
		FIN(int -1) SAVE NOOutput DIScount(real 3)]
	noisily di _newline(2) in g _dup(20) "." "{bf:   PIB + Deflactor:" in y " PIB `aniovp'   }" in g _dup(20) "." _newline



	************************
	*** 1 Bases de datos ***
	************************


	*******************
	** 1.1 Poblacion **
	capture use `"`c(sysdir_site)'/SIM/$pais/Poblacion.dta"', clear
	if _rc != 0 {
		if "$pais" == "" {
			noisily run "`c(sysdir_site)'/UpdatePoblacion.do"
		}
		else if "$pais" == "El Salvador" {
			noisily run "`c(sysdir_site)'/UpdatePoblacionMundial.do"
		}
		use `"`c(sysdir_site)'/SIM/$pais/Poblacion.dta"', clear
	}
	preserve
	collapse (sum) Poblacion=poblacion if entidad == "Nacional", by(anio)
	local aniomax = anio[_N]
	format Poblacion %15.0fc
	tempfile poblacion
	save "`poblacion'"
	restore

	* Working Ages *
	collapse (sum) WorkingAge=poblacion if edad >= 16 & edad <= 65 & entidad == "Nacional", by(anio)
	format WorkingAge %15.0fc
	tempfile workingage
	save "`workingage'"


	***************************************
	** 1.2 SIM/$pais/PIBDeflactorPIB.dta **
	capture use "`c(sysdir_site)'/SIM/$pais/PIBDeflactor.dta", clear
	if _rc != 0 | "`update'" == "update" {
		noisily run `"`c(sysdir_site)'/UpdatePIBDeflactor`=subinstr("${pais}"," ","",.)'.do"'
		use "`c(sysdir_site)'/SIM/$pais/PIBDeflactor.dta", clear
	}

	* Observaciones (máximo y mínimo) *
	scalar aniofirst = anio[1]
	scalar aniolast = anio[_N]
	if `aniovp' < `=scalar(aniofirst)' | `aniovp' > `aniomax' {
		noisily di in r "A{c n~}o para valor presente (`aniovp') inferior a `=scalar(aniofirst)' o superior a `aniomax'."
		exit
	}

	* PIB Trimestral Real *
	capture local trim_last = trimestre[_N]
	if _rc == 0 {
		scalar trimlast = `trim_last'
		local trim_last = " t`trim_last'"
	}
	g pibQR = pibQ/(indiceQ/100)
	g var_pibQ = (pibQR/L4.pibQR-1)*100

	noisily di in g " PIB " in y "`=scalar(aniolast)'`trim_last'" _col(33) %20.0fc pibQ[_N] in g " `=currency[_N]' ({c u'}ltimo reportado)"
	noisily di in g " Crec. " in y "`=scalar(aniolast)'`trim_last' - `=scalar(aniolast)-1'`trim_last'" _col(33) %20.1fc var_pibQ[_N] in g " %"

	* Anuazliar el PIB *
	if "$pais" == "Ecuador" {
		collapse (sum) pibY=pibQ pibYR=pibQR (last) trimestre, by(anio currency)
		replace pibY = pibY*4/trimestre
		replace pibYR = pibYR*4/trimestre
	}
	else {
		collapse (mean) pibY=pibQ pibYR=pibQR (last) trimestre, by(anio currency)
	}
	format pib* %25.0fc


	************************
	** 1.4 Merge datasets **
	merge 1:1 (anio) using "`workingage'", nogen
	merge 1:1 (anio) using "`poblacion'", nogen
	drop if anio < scalar(aniofirst)


	***************************
	** 1.3 Anios geometricos **
	if `geodef' < scalar(aniofirst) {
		local geodef = scalar(aniofirst)
	}
	local difdef = scalar(aniolast)-`geodef'

	if `geopib' < scalar(aniofirst) {
		local geopib = scalar(aniofirst)
	}
	local difpib = scalar(aniolast)-`geopib'
	scalar aniogeo = `geopib'

	if `fin' == -1 {
		local fin = anio[_N]
	}




	*******************
	*** 1 Deflactor ***
	*******************
	tsset anio
	g double indiceY = pibY/pibYR

	g double var_indiceY = (indiceY/L.indiceY-1)*100
	label var var_indiceY "Anual"

	g double var_indiceG = ((indiceY/L`=`difdef''.indiceY)^(1/(`difdef'))-1)*100
	label var var_indiceG "Promedio geom{c e'}trico (`difpib' a{c n~}os)"



	***********************************************
	** 1.1 Imputar Par{c a'}metros ex{c o'}genos **
	/* Para todos los años, si existe información sobre el crecimiento del deflactor 
	utilizarla, si no existe, tomar el rezago del índice geométrico. Posteriormente
	ajustar los valores del índice con sus rezagos. */
	local exo_def = 0
	local anio_def = `aniovp'
	forvalues k=`=scalar(aniolast)'(1)`fin' {
		capture confirm existence ${def`k'}
		if _rc == 0 {
			replace var_indiceY = ${def`k'} if anio == `k' & trimestre != 4
			local exceptI "`exceptI'${def`k'}% (`k'), "
			local anio_def = `k'
			local ++exo_def
		}
		else {
			replace var_indiceY = L.var_indiceG if anio == `k' & trimestre != 4 & var_indiceY == .
		}
		replace indiceY = L.indiceY*(1+var_indiceY/100) if anio == `k' & trimestre != 4
		replace var_indiceG = ((indiceY/L`=`difdef''.indiceY)^(1/(`difdef'))-1)*100 if anio == `k' & trimestre != 4
	}
	if "`exceptI'" != "" {
		local exceptI "`=substr("`exceptI'",1,`=strlen("`exceptI'")-2')'"
	}
	*noisily di in g "  {bf:Excepciones Deflactor}: " in y "`exceptI'"

	* Valor presente *
	if `aniovp' == -1 {
		local aniovp : di %td_CY-N-D  date("$S_DATE", "DMY")
		local aniovp = substr(`"`=trim("`aniovp'")'"',1,4)
	}
	forvalues k=1(1)`=_N' {
		if anio[`k'] == `aniovp' {
			local obsvp = `k'
			continue, break
		}
	}
	forvalues k=1(1)`=_N' {
		if anio[`k'] == `=scalar(aniolast)' {
			local obslast = `k'
			continue, break
		}
	}
	forvalues k=1(1)`=_N' {
		if anio[`k'] == 2013 {
			local obsdef = `k'
			continue, break
		}
	}	
	forvalues k=1(1)`=_N' {
		if anio[`k'] == `geodef' {
			local obsDEF = `k'
			continue, break
		}
	}	
	forvalues k=1(1)`=_N' {
		if anio[`k'] == `geopib' {
			local obsPIB = `k'
			continue, break
		}
	}

	g double deflator = indiceY/indiceY[`obsdef']
	label var deflator "Deflactor"



	*************
	*** 2 PIB ***
	*************
	label var pibYR "PIB Real (`=anio[`obsvp']')"
	format pibYR* %25.0fc

	g double var_pibY = (pibYR/L.pibYR-1)*100
	label var var_pibY "Anual"

	g double var_pibG = ((pibYR/L`=`difpib''.pibYR)^(1/(`difpib'))-1)*100
	label var var_pibG "Geometric mean (`difpib' years)"


	***************************************
	** 2.1 Par{c a'}metros ex{c o'}genos **
	replace currency = currency[`obslast']
	local anio_exo = scalar(aniolast)

	* Imputar *
	local exo_count = 0
	forvalues k=`=scalar(aniolast)'(1)`fin' {
		capture confirm existence ${pib`k'}
		if _rc == 0 {
			replace var_pibY = ${pib`k'} if anio == `k' & trimestre != 4
			local except "`except'${pib`k'}% (`k'); "
			local anio_exo = `k'
			local ++exo_count

			replace pibY = L.pibY*(1+var_pibY/100)*(1+var_indiceY/100) if anio == `k' & trimestre != 4
			replace pibYR = L.pibYR*(1+var_pibY/100) if anio == `k' & trimestre != 4
		}
	}

	if "`except'" != "" {
		local except "`=substr("`except'",1,`=strlen("`except'")-2')'"
	}
	*noisily di in g "  {bf:Excepciones PIB}: " in y "`except'"

	* Valor presentes `aniovp' *
	replace deflator = indiceY/indiceY[`obsvp']
	replace pibYR = pibY/deflator

	* Lambda (productividad) *
	g OutputPerWorker = pibYR/WorkingAge

	forvalues k=1(1)`=_N' {
		if anio[`k'] == `anio_exo' {
			local obs_exo = `k'
		}
		if anio[`k'] == `anio_def' {
			local obs_def = `k'
		}
	}
	return scalar anio_exo = `anio_exo'

	scalar llambda = ((OutputPerWorker[`obs_exo']/OutputPerWorker[`obsPIB'])^(1/(`obs_exo'-`obsPIB'))-1)*100
	scalar LLambda = ((OutputPerWorker[`obs_exo']/OutputPerWorker[1])^(1/(`obs_exo'))-1)*100
	capture confirm existence $lambda
	if _rc == 0 {
		scalar llambda = $lambda
	}
	g lambda = (1+scalar(llambda)/100)^(anio-`aniovp')


	* Proyección de crecimiento PIB *
	replace pibYR = `=pibYR[`obs_exo']'/`=WorkingAge[`obs_exo']'*WorkingAge*(1+scalar(llambda)/100)^(anio-`anio_exo') if pibYR == .
	replace pibY = pibYR*deflator if pibY == .

	* Crecimientos *
	replace var_pibG = ((pibYR/L`=`difpib''.pibYR)^(1/(`difpib'))-1)*100
	replace var_pibY = (pibYR/L.pibYR-1)*100

	g double pibYVP = pibYR/(1+`discount'/100)^(anio-`=anio[`obsvp']')
	format pibYVP %20.0fc

	replace OutputPerWorker = pibYR/WorkingAge if OutputPerWorker == .



	*****************
	** 3 Simulador **
	*****************
	noisily di _newline in g " PIB " in y anio[`obsvp'] in g " per c{c a'}pita " in y _col(43) %10.1fc pibY[`obsvp']/Poblacion[`obsvp'] in g " `=currency[`obsvp']'"
	noisily di in g " PIB " in y anio[`obsvp'] in g " por persona en edad de trabajar " in y _col(43) %10.1fc OutputPerWorker[`obsvp'] in g " `=currency[`obsvp']' (16-65 a{c n~}os)"
	noisily di _newline in g " Crecimiento promedio " in y anio[`obsPIB'] "-" anio[`obs_exo'] _col(43) %10.4f ((pibYR[`obs_exo']/pibYR[`obsPIB'])^(1/(`obs_exo'-`obsPIB'))-1)*100 in g " %" 
	noisily di in g " Lambda por trabajador " in y anio[`obsPIB'] "-" anio[`obs_exo'] _col(43) %10.4f scalar(llambda) in g " %" 
	*noisily di in g " Lambda por trabajador " in y anio[1] "-" anio[`obs_exo'] _col(35) %10.4f scalar(LLambda) in g " %" 

	local grow_rate_LR = (pibYR[_N]/pibYR[_N-10])^(1/10)-1
	*scalar pibINF = pibYR[_N]*(1+`grow_rate_LR')*(1+`discount'/100)^(`=anio[`obsvp']'-`=anio[_N]')/((`discount'/100)-`grow_rate_LR'+((`discount'/100)*`grow_rate_LR'))
	scalar pibINF = pibYR[_N] /*(1+`grow_rate_LR')*(1+`discount'/100)^(`=anio[`obsvp']'-`=anio[_N]')*/ /(1-((1+`grow_rate_LR')/(1+`discount'/100)))

	tabstat pibYVP if anio >= `aniovp', stat(sum) f(%20.0fc) save
	tempname pibYVP
	matrix `pibYVP' = r(StatTotal)

	scalar pibVPINF = `pibYVP'[1,1] + pibINF
	scalar pibY = pibY[`obsvp']
	*global pib`aniovp' = var_pibY[`obsvp']
	scalar deflatorLP = round(deflator[_N],.1)
	scalar deflatorINI = string(round(1/deflator[1],.1),"%5.1f")
	scalar anioLP = anio[_N]

	scalar anioPWI = anio[`obsPIB']
	scalar anioPWF = anio[`obs_exo']
	scalar outputPW = string(OutputPerWorker[`obsvp'],"%10.0fc")
	scalar lambdaNW = ((pibYR[`obs_exo']/pibYR[`=`obs_exo'-`difpib''])^(1/(`difpib'))-1)*100
	scalar LambdaNW = ((pibYR[`obs_exo']/pibYR[1])^(1/(`obs_exo'))-1)*100


	di _newline in g " PIB " in y "al infinito" in y _col(22) %23.0fc `pibYVP'[1,1] + pibINF in g " `=currency[`obsvp']'"
	di in g " Tasa de descuento: " in y _col(25) %20.1fc `discount' in g " %"
	di in g " Crec. al infinito: " in y _col(25) %20.1fc var_pibY[_N] in g " %"
	di in g " Defl. al infinito: " in y _col(25) %20.1fc var_indiceY[_N] in g " %"


	if "`nographs'" != "nographs" & "$nographs" == "" {
	
		* Texto sobre lineas *
		forvalues k=1(1)`=_N' {
			if var_indiceY[`k'] != . {
				local crec_deflactor `"`crec_deflactor' `=var_indiceY[`k']' `=anio[`k']' "{bf:`=string(var_indiceY[`k'],"%5.1fc")'}" "'
			}
		}

		* Graph type *
		if `exo_count'-1 <= 0 {
			local graphtype "bar"
		}
		else {
			local graphtype "area"
		}
		
		if `exo_def'-1 <= 0 {
			local graphtype2 "bar"
		}
		else {
			local graphtype2 "area"
		}

		* Deflactor var_indiceY *
		twoway (area deflator anio if (anio < scalar(aniolast) & anio >= scalar(aniofirst)) | (anio == scalar(aniolast) & trimestre == 4)) ///
			(area deflator anio if anio >= scalar(aniolast)+`exo_def') ///
			(`graphtype2' deflator anio if anio < scalar(aniolast)+`exo_def' & anio >= scalar(aniolast), lwidth(none) pstyle(p4)), ///
			title("{bf:{c I'}ndice} de precios impl{c i'}citos") ///
			subtitle(${pais}) ///
			xlabel(`=round(anio[1],5)'(5)`=round(anio[_N],5)' `aniovp') ///
			yscale(range(0)) ///
			ylabel(0(1)4, format("%3.0f")) ///
			ytitle("{c I'}ndice `aniovp' = 1.000") xtitle("") ///
			legend(label(1 "Reportado") label(2 "Proyecci{c o'}n CIEP") label(3 "Estimaci{c o'}n ($paqueteEconomico)") order(1 3 2) region(margin(zero))) ///
			caption("{bf:Fuente}: Elaborado por el CIEP, con información de INEGI/BIE.") ///
			note("{bf:Crecimiento de precios}: `=string(`=((indiceY[`obsDEF']/indice[`obs_def'])^(1/(`=`obsDEF'-`obs_def''))-1)*100',"%6.3f")'% (`=anio[[`obsDEF']]'-`=anio[`obs_def']'). {bf:{c U'}ltimo dato reportado}: `=scalar(aniolast)'`trim_last'.") ///
			name(deflactorH, replace)

		capture confirm existence $export
		if _rc == 0 {
			graph export "$export/deflactorH.png", replace name(deflactorH)
		}

		* Texto sobre lineas *
		forvalues k=1(1)`=_N' {
			if var_pibY[`k'] != . {
				local crec_PIB `"`crec_PIB' `=var_pibY[`k']' `=anio[`k']' "{bf:`=string(var_pibY[`k'],"%5.1fc")'}" "'
			}
		}

		* Crecimiento var_indiceY *
		twoway (connected var_indiceY anio if (anio < scalar(aniolast) & anio >= scalar(aniofirst)) | (anio == scalar(aniolast) & trimestre == 4), msize(large) mlwidth(vvthick)) ///
			(connected var_indiceY anio if anio >= scalar(aniolast)+`exo_def', msize(large) mlwidth(vvthick)) ///
			(connected var_indiceY anio if anio < scalar(aniolast)+`exo_def' & anio >= scalar(aniolast), pstyle(p4) msize(large) mlwidth(vvthick)), ///
			title({bf:Crecimientos} del {c i'}ndice de precios impl{c i'}citos) subtitle(${pais}) ///
			xlabel(`=round(anio[1],5)'(5)`=round(anio[_N],5)' `aniovp') ///
			ylabel(, format(%3.0f)) ///
			ytitle("Crecimiento anual (%)") xtitle("") ///
			///yline(0, lcolor(black)) ///
			text(`crec_deflactor', color(white) size(tiny)) ///
			legend(label(1 "Reportado") label(2 "Proyecci{c o'}n CIEP") label(3 "Estimaci{c o'}n ($paqueteEconomico)") order(1 3 2) region(margin(zero))) ///
			caption("{bf:Fuente}: Elaborado por el CIEP, con información de INEGI/BIE.") ///
			note("{bf:{c U'}ltimo dato reportado}: `=scalar(aniolast)'`trim_last'.") ///
			name(var_indiceYH, replace)
		capture confirm existence $export
		if _rc == 0 {
			graph export "$export/var_indiceYH.png", replace name(var_indiceYH)
		}

		* Crecimiento var_pibY *
		twoway (connected var_pibY anio if (anio < scalar(aniolast) & anio >= scalar(aniofirst)) | (anio == scalar(aniolast) & trimestre == 4), msize(large) mlwidth(vvthick)) ///
			(connected var_pibY anio if anio >= scalar(aniolast)+`exo_count', msize(large) mlwidth(vvthick)) ///
			(connected var_pibY anio if anio < scalar(aniolast)+`exo_count' & anio >= scalar(aniolast), pstyle(p4) msize(large) mlwidth(vvthick)), ///
			title({bf:Crecimientos} del Producto Interno Bruto) subtitle(${pais}) ///
			xlabel(`=round(anio[1],5)'(5)`=round(anio[_N],5)' `aniovp') ///
			ylabel(/*-6(3)6*/, format(%3.0fc)) ///
			ytitle("Crecimiento anual (%)") xtitle("") ///
			///yline(0, lcolor(white)) ///
			text(`crec_PIB', color(white) size(tiny)) ///
			legend(label(1 "Reportado") label(2 "Proyecci{c o'}n CIEP") label(3 "Estimaci{c o'}n ($paqueteEconomico)") order(1 3 2) region(margin(zero))) ///
			caption("{bf:Fuente}: Elaborado por el CIEP, con información de INEGI/BIE.") ///
			note("{bf:Crecimiento econ{c o'}mico}: `=string(`=((pibYR[`obsPIB']/pibYR[`obs_exo'])^(1/(`=`obsPIB'-`obs_exo''))-1)*100',"%6.3f")'% (`=anio[[`obsPIB']]'-`=anio[`obs_exo']'). {bf:{c U'}ltimo dato reportado}: `=scalar(aniolast)'`trim_last'.") ///
			name(PIBH, replace)
		capture confirm existence $export
		if _rc == 0 {
			graph export "$export/PIBH.png", replace name(PIBH)
		}

		* PIB real *
		tempvar pibYRmil
		g `pibYRmil' = pibYR/1000000000

		twoway (area `pibYRmil' anio if (anio < scalar(aniolast) & anio >= scalar(aniofirst)) | (anio == scalar(aniolast) & trimestre == 4)) ///
			(area `pibYRmil' anio if anio >= scalar(aniolast)+`exo_count') ///
			(`graphtype' `pibYRmil' anio if anio < scalar(aniolast)+`exo_count' & anio >= scalar(aniolast), lwidth(none) pstyle(p4)), ///
			title({bf:Flujo} del Producto Interno Bruto) subtitle(${pais}) ///
			ytitle(mil millones `=currency[`obsvp']' `aniovp') xtitle("") ///
			///ytitle(billions `=currency[`obsvp']' `aniovp') xtitle("") ///
			///text(`=`pibYRmil'[1]*.05' `=scalar(aniolast)-.5' "scalar(aniolast)", place(nw) color(white)) ///
			///text(`=`pibYRmil'[1]*.05' `=anio[1]+.5' "Reportado" ///
			///`=`pibYRmil'[1]*.05' `=scalar(aniolast)+1.5' "Proyecci{c o'}n CIEP", place(ne) color(white) size(small)) ///
			xlabel(`=round(anio[1],5)'(5)`=round(anio[_N],5)' `aniovp') ///
			ylabel(/*0(5)`=ceil(`pibYRmil'[_N])'*/, format(%20.0fc)) ///
			///xline(scalar(aniolast).5) ///
			yscale(range(0)) /*xscale(range(1993))*/ ///
			legend(label(1 "Reportado") label(2 "Proyecci{c o'}n CIEP") label(3 "Estimaci{c o'}n ($paqueteEconomico)") order(1 3 2) region(margin(zero))) ///
			///legend(label(1 "Observed") label(2 "Projected") label(3 "Estimated") order(1 3 2)) ///
			note("{bf:Productividad laboral}: `=string(scalar(llambda),"%6.3f")'% (`=anio[[`obsPIB']]'-`=anio[`obs_exo']'). {bf:{c U'}ltimo dato reportado}: `=scalar(aniolast)'`trim_last'.") ///
			///note("{bf:Note}: Annual Labor Productivity Growth: `=string(scalar(llambda),"%6.3f")'% (`=anio[[`obsPIB']]'-`=anio[`obs_exo']').") ///
			caption("{bf:Fuente}: Elaborado por el CIEP, con información de INEGI/BIE.") ///
			name(PIBP, replace)

		capture confirm existence $export
		if _rc == 0 {
			graph export "$export/PIB.png", replace name(PIBP)
		}
	}
	return local except "`except'"
	return local exceptI "`exceptI'"
	return scalar geo = `difpib'
	return scalar discount = `discount'
	return scalar aniovp = `aniovp'


	***************
	*** 4 Texto ***
	***************
	noisily di _newline in g _col(11) %~14s "Crec. PIB" _col(25) %~23s "PIB Nominal" _col(50) %~14s "Crec. {c I'}ndice" _col(64) %~14s "Deflactor"
	forvalues k=`=`obsvp'-10'(1)`=`obsvp'+10' {
		if anio[`k'] < scalar(aniolast) | (anio[`k'] == scalar(aniolast) & trimestre[`k'] == 4) {
			if "`reportado'" == "" {
				local reportado = "done"
			}
			noisily di in g " `=anio[`k']' " _col(10) %8.1fc in y var_pibY[`k'] " %" _col(25) %20.0fc pibY[`k'] _col(50) %8.1fc in y var_indiceY[`k'] " %" _col(65) %12.10fc deflator[`k']
		}
		if (anio[`k'] == scalar(aniolast) & trimestre[`k'] < 4) | (anio[`k'] <= anio[`obs_exo'] & anio[`k'] >= scalar(aniolast)) {
			if "`estimado'" == "" {
				noisily di in g %~72s "$paqueteEconomico"
				local estimado = "done"
			}
			noisily di in g "{bf: `=anio[`k']' " _col(10) %8.1fc in y var_pibY[`k'] " %" _col(25) %20.0fc pibY[`k'] _col(50) %8.1fc in y var_indiceY[`k'] " %" _col(65) %12.10fc deflator[`k'] "}"
		}
		if (anio[`k'] > scalar(aniolast)) & anio[`k'] > anio[`obs_exo'] {
			if "`proyectado'" == "" {
				noisily di in g %~72s "PROYECTADO"
				local proyectado = "done"
			}
			noisily di in g " `=anio[`k']' " _col(10) %8.1fc in y var_pibY[`k'] " %" _col(25) %20.0fc pibY[`k'] _col(50) %8.1fc in y var_indiceY[`k'] " %" _col(65) %12.10fc deflator[`k']
		}
	}


	capture drop __*
	if "`save'" == "save" {
		if `c(version)' > 13.1 {
			saveold "`c(sysdir_site)'/users/$pais/$id/PIB.dta", replace version(13)
		}
		else {
			save "`c(sysdir_site)'/users/$pais/$id/PIB.dta", replace
		}
	}

	********************
	*** 5 Output SIM ***
	********************
	if "$output" == "output" & "`nooutput'" == "" {
		quietly log on output
		noisily di in w "CRECPIB: ["  ///
			%8.1f $pib2022 ", " ///
			%8.1f $pib2023 ", " ///
			%8.1f $pib2024 ", " ///
			%8.1f $pib2025 ", " ///
			%8.1f $pib2026 ", " ///
			%8.1f $pib2027 ", " ///
			%8.1f $pib2028 ///
		"]"
		noisily di in w "CRECDEF: ["  ///
			%8.1f $def2022 ", " ///
			%8.1f $def2023 ", " ///
			%8.1f $def2024 ", " ///
			%8.1f $def2025 ", " ///
			%8.1f $def2026 ", " ///
			%8.1f $def2027 ", " ///
			%8.1f $def2028 ///
		"]"
		quietly log off output
	}

	return scalar aniolast = scalar(aniolast)

	timer off 2
	timer list 2
	noisily di _newline in g "Tiempo: " in y round(`=r(t2)/r(nt2)',.1) in g " segs."
}
end
