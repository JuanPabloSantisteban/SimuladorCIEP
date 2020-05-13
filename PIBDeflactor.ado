***               ACTUALIZACIÓN                *** 
*** 1) abrir archivos .iqy en Excel de Windows ***
*** 2) guardar y reemplazar .xls dentro de     ***
***      ./TemplateCIEP/basesCIEP/INEGI/SCN/   ***
*** 3) correr PIBDeflactor[.ado] con opción "update" ***

**** Crecimiento del PIB ****
program define PIBDeflactor, return
quietly {
	version 13.1
	** Anio valor presente **
	local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
	local aniovp = substr(`"`=trim("`fecha'")'"',1,4)
	
	syntax [, ANIOvp(int `aniovp') GEO(int 5) FIN(int -1) Graphs UPDATE DIScount(real 3)]

	
	noisily di _newline in g "{bf:PIB:} " in y "{bf:$pais} `aniovp'"


	***********************
	*** 0 Base de datos ***
	***********************
	Poblacion, anio(`aniovp') `graphs' `update'
	tabstat poblacion if anio == `aniovp', stat(sum) f(%15.0fc) save
	tempname pobtotal
	matrix `pobtotal' = r(StatTotal)

	collapse (sum) WorkingAge=poblacion if edad >= 16 & edad <= 65, by(anio)
	format WorkingAge %15.0fc
	tempfile workingage
	save `workingage'

	/* Verifica si se puede usar la base, si no es así o la opción update es llamada, 
	limpia la base y la usa */
	capture use `"`c(sysdir_site)'../basesCIEP/SIM/PIBDeflactor`=subinstr("${pais}"," ","",.)'.dta"', clear
	if _rc != 0 | "`update'" == "update" {
		run `"`c(sysdir_personal)'/PIBDeflactorBase`=subinstr("${pais}"," ","",.)'.do"'
		use `"`c(sysdir_site)'../basesCIEP/SIM/PIBDeflactor`=subinstr("${pais}"," ","",.)'.dta"', clear
	}
	local anio_first = anio[1]
	local anio_last = anio[_N]
	return scalar anio_last = `anio_last'
	capture local trim_last = trimestre[_N]
	if _rc == 0 {
		local trim_last = "q`trim_last'"
	}
	merge 1:1 (anio) using `workingage', nogen
	drop if anio < `anio_first'
	if `fin' == -1 {
		local fin = anio[_N]
	}
	global discount = `discount'



	*******************
	*** 1 Deflactor ***
	*******************
	* Time series operators: L = lag *
	tsset anio
	g double var_indiceY = (indiceY/L.indiceY-1)*100
	label var var_indiceY "Anual"

	g double var_indiceG = ((indiceY/L`=`geo''.indiceY)^(1/`geo')-1)*100
	label var var_indiceG "Promedio geom{c e'}trico (`geo' a{c n~}os)"


	***********************************************
	** 1.1 Imputar Par{c a'}metros ex{c o'}genos **
	/* Para todos los años, si existe información sobre el crecimiento del deflactor 
	utilizarla, si no existe, tomar el rezago del índice geométrico. Posteriormente
	ajustar los valores del índice con sus rezagos. */
	forvalues k=`anio_last'(1)`fin' {
		capture confirm existence ${def`k'}
		if _rc == 0 {
			replace var_indiceY = ${def`k'} if anio == `k' & trimestre != 4
			local exceptI "`exceptI'`k' (${def`k'}%), "
		}
		else {
			replace var_indiceY = L.var_indiceG if anio == `k' & trimestre != 4
		}
		replace indiceY = L.indiceY*(1+var_indiceY/100) if anio == `k' & trimestre != 4
		replace var_indiceG = ((indiceY/L`=`geo''.indiceY)^(1/`geo')-1)*100 if anio == `k' & trimestre != 4
	}	

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
		if anio[`k'] == `anio_last' {
			local obslast = `k'
			continue, break
		}
	}
	g double deflator = indiceY/indiceY[`obsvp']
	label var deflator "Deflactor"



	*************
	*** 2 PIB ***
	*************
	g double pibYR = pibY/deflator
	label var pibYR "PIB Real (`=anio[`obsvp']')"
	format pibYR %25.0fc

	g double var_pibY = (pibYR/L.pibYR-1)*100
	label var var_pibY "Anual"

	g double var_pibG = ((pibYR/L`=`geo''.pibYR)^(1/`geo')-1)*100
	label var var_pibG "Geometric mean (`geo' years)"


	***************************************
	** 2.1 Par{c a'}metros ex{c o'}genos **
	replace currency = currency[`obslast']
	local anio_exo = `anio_last'

	* Imputar *
	forvalues k=`anio_last'(1)`fin' {
		capture confirm existence ${pib`k'}
		if _rc == 0 {
			replace var_pibY = ${pib`k'} if anio == `k' & trimestre != 4
			local except "`except'`k' (${pib`k'}%), "
			local anio_exo = `k'
		}
		else {
			replace var_pibY = L.var_pibG if anio == `k' & trimestre != 4
		}
		replace pibY = L.pibY*(1+var_pibY/100)*(1+var_indiceY/100) if anio == `k' & trimestre != 4
		replace pibYR = L.pibYR*(1+var_pibY/100) if anio == `k' & trimestre != 4

		capture confirm existence ${desemp`k'}
		if _rc == 0 {
			replace WorkingAge = WorkingAge*(1-${desemp`k'}/100) if anio == `k' & trimestre != 4
		}
	}
	local except " {bf:{&Delta}} `=substr("`except'",1,`=strlen("`except'")-2')'."
	

	* Lambda (productividad) *
	g OutputPerWorker = pibYR/WorkingAge

	forvalues k=1(1)`=_N' {
		if anio[`k'] == `anio_exo' {
			local obs_exo = `k'
		}
	}

	scalar lambda = ((OutputPerWorker[`obs_exo']/OutputPerWorker[`=`obs_exo'-10'])^(1/10)-1)*100
	capture confirm existence $lambda
	if _rc == 0 {
		scalar lambda = $lambda
	}
	g lambda = (1+scalar(lambda)/100)^(anio-`aniovp')

	* Proyección de crecimiento PIB *
	replace pibYR = `=pibYR[`obs_exo']'/`=WorkingAge[`obs_exo']'*WorkingAge* ///
		(1+scalar(lambda)/100)^(anio-`anio_exo') if pibYR == .
	replace pibY = pibYR*deflator if pibY == .
	replace var_pibG = ((pibYR/L`=`geo''.pibYR)^(1/`geo')-1)*100
	replace var_pibY = (pibYR/L.pibYR-1)*100

	g double pibYVP = pibYR/(1+`discount'/100)^(anio-`=anio[`obsvp']')
	format pibYVP %20.0fc

	replace OutputPerWorker = pibYR/WorkingAge if OutputPerWorker == .


	*****************
	** 3 Simulador **
	*****************
	noisily di in g " PIB per c{c a'}pita: " in y _col(35) %10.1fc pibY[`obsvp']/`pobtotal'[1,1] in g " `=currency[`obsvp']'"
	noisily di in g " Producci{c o'}n por trabajador: " in y _col(35) %10.1fc OutputPerWorker[`obsvp'] in g " `=currency[`obsvp']'"
	noisily di in g " Lambda (productividad): " in y _col(35) %10.4f scalar(lambda) in g " %" 

	local grow_rate_LR = (pibYR[_N]/pibYR[_N-10])^(1/10)-1
	scalar pibINF = pibYR[_N]*(1+`grow_rate_LR')*(1+`discount'/100)^(`=anio[`obsvp']'-`=anio[_N]')/((`discount'/100)-`grow_rate_LR'+((`discount'/100)*`grow_rate_LR'))

	tabstat pibYVP if anio >= `aniovp', stat(sum) f(%20.0fc) save
	tempname pibYVP
	matrix `pibYVP' = r(StatTotal)

	scalar pibVPINF = `pibYVP'[1,1] + pibINF
	scalar pibY = pibY[`obsvp']
	global pib`aniovp' = var_pibY[`obsvp']

	noisily di _newline in g " Tasa de descuento: " in y _col(25) %20.1fc `discount' in g " %"
	noisily di in g " Crec. al infinito: " in y _col(25) %20.1fc var_pibY[_N] in g " %"
	noisily di in g " Defl. al infinito: " in y _col(25) %20.1fc var_indiceY[_N] in g " %"
	noisily di in g "{bf: PIB VP al infinito: " in y _col(20) %23.0fc `pibYVP'[1,1] + pibINF in g " `=currency[`obsvp']'}"

	if "`graphs'" == "graphs" {

		/* Texto sobre lineas *
		forvalues k=1(1)`=_N' {
			if var_indiceY[`k'] != . {
				local crec_deflactor `"`crec_deflactor' `=var_indiceY[`k']' `=anio[`k']' "`=string(var_indiceY[`k'],"%5.1fc")'" "'
			}
		}

		* Deflactor *
		twoway (connected var_indiceY anio if anio <= `anio_last') ///
			(connected var_indiceY anio if anio > `anio_last'), ///
			title("{bf:{c I'}ndice de precios impl{c i'}citos}") ///
			subtitle(${pais}) ///
			xlabel(`=round(anio[1],5)'(5)`=round(anio[_N],5)') ///
			ytitle("Variaci{c o'}n anual (%)") xtitle("") yline(0) ///
			text(`crec_deflactor', place(c)) ///
			legend(label(1 "Observado") label(2 "Proyectado")) ///
			caption("{it:Fuente: Elaborado por el CIEP con el Simulador v5.}") ///
			note("{bf:{c U'}ltimo dato}: `anio_last'`trim_last'.") ///
			name(deflactorH, replace)
			
		capture confirm existence $export
		if _rc == 0 {
			graph export "$export/deflactorH.png", replace name(deflactorH)
		}

		* Texto sobre lineas */
		forvalues k=1(1)`=_N' {
			if var_pibY[`k'] != . {
				local crec_PIB `"`crec_PIB' `=var_pibY[`k']' `=anio[`k']' "`=string(var_pibY[`k'],"%5.1fc")'" "'
			}
		}

		* Crecimiento PIB *
		twoway (connected var_pibY anio if anio <= `anio_last') ///
			(connected var_pibY anio if anio > `anio_last'), ///
			/// title({bf:Producto Interno Bruto}) ///
			subtitle(${pais}) ///
			xlabel(`=round(anio[1],5)'(5)`=round(anio[_N],5)') ///
			ytitle("Crecimiento real (%)") xtitle("") yline(0, lcolor(black)) ///
			text(`crec_PIB') ///
			legend(label(1 "Observado") label(2 "Proyectado")) ///
			caption("{it:Fuente: Elaborado por el CIEP con el Simulador v5.}") ///
			note("{bf:{c U'}ltimo dato}: `anio_last'`trim_last'.") ///
			name(PIBH, replace)


		* PIB real *
		tempvar pibYRmil
		g `pibYRmil' = pibYR/1000000000000
		twoway (area `pibYRmil' anio if anio <= `anio_last') ///
			(area `pibYRmil' anio if anio > `anio_last'), ///
			/// title({bf:Producto Interno Bruto}) subtitle(${pais}) ///
			ytitle(billones `=currency[`obsvp']' `aniovp') xtitle("") yline(0) ///
			text(`=`pibYRmil'[1]*.05' `=`anio_last'-.5' "`anio_last'", place(nw) color(white)) ///
			text(`=`pibYRmil'[1]*.05' `=anio[1]+.5' "Observado" ///
			`=`pibYRmil'[1]*.05' `=`anio_last'+1.5' "Proyectado", place(ne) color(white)) ///
			xlabel(`=anio[1]' `=round(anio[1],10)'(10)`=round(anio[_N],10)') ///
			ylabel(#4, format(%10.0fc)) ///
			xline(`anio_last'.5) ///
			yscale(range(0)) ///
			legend(label(1 "Observado") label(2 "Proyectado") off) ///
			note("{bf:{&lambda}}: `=string(scalar(lambda),"%6.3f")'% desde `=anio[[`=`obs_exo'-10']]'. {bf:{c U'}ltimo dato}: `anio_last'`trim_last'." "`except'") ///
			///note("{bf:Note}: Annual Labor Productivity Growth (lambda): `=string(scalar(lambda),"%6.3f")'%.") ///
			caption("Fuente: {stMono:simuladorfiscal.ciep.mx}. `c(current_date)' `c(current_time)'.") ///
			name(PIBP, replace)

		capture confirm existence $export
		if _rc == 0 {
			graph export "$export/PIB.png", replace name(PIBP)
		}
	}
	return local except "`except'"
	return local exceptI "`exceptI'"
	return scalar geo = `geo'
	return scalar discount = `discount'


	***************
	*** 4 Texto ***
	***************
	noisily di _newline in g "  A{c n~}o" _col(11) %8s "Crec. PIB" _col(25) %20s "PIB" _col(50) %5s "Crec. Def." _col(64) %8.4fc "Deflactor"
	forvalues k=`=`obsvp'-5'(1)`=`obsvp'+5' {
		if anio[`k'] <= `anio_last' | (anio[`k'] == `anio_last' & trimestre < 4) {
			noisily di in g " `=anio[`k']' " _col(10) %8.1fc in y var_pibY[`k'] " %" _col(25) %20.0fc pibY[`k'] _col(50) %8.1fc in y var_indiceY[`k'] " %" _col(65) %8.4fc deflator[`k']
		}
		else {
			capture confirm existence `firstrow'
			if _rc != 0 {
				noisily di in g _dup(72) "-"
				local firstrow "firstrow"
			}
			noisily di in g "{bf: `=anio[`k']' " _col(10) %8.1fc in y var_pibY[`k'] " %" _col(25) %20.0fc pibY[`k'] _col(50) %8.1fc in y var_indiceY[`k'] " %" _col(65) %8.4fc deflator[`k'] "}"
		}
	}
}
end
