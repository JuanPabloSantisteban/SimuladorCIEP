program define SHRFSP, return
quietly {

	timer on 5
	**********************
	**# 1 BASE DE DATOS **
	**********************

	** 1.1 Anio valor presente **
	capture confirm scalar aniovp
	if _rc == 0 {
		local aniovp = scalar(aniovp)
	}	
	else {
		local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
		local aniovp = substr(`"`=trim("`fecha'")'"',1,4)
	}

	** 1.2 Base SHRFSP **
	capture confirm file `"`c(sysdir_personal)'/SIM/SHRFSP.dta"'
	if _rc != 0 {
		noisily run `"`c(sysdir_personal)'/UpdateSHRFSP.do"'
	}



	****************
	**# 2 SYNTAX ***
	****************
	use in 1 using `"`c(sysdir_personal)'/SIM/SHRFSP.dta"', clear
	syntax [if] [, ANIO(int `aniovp' ) DEPreciacion(int 5) NOGraphs UPDATE Base ///
		 ULTAnio(int 2013)]
	
	noisily di _newline(2) in g _dup(20) "." "{bf:  Sistema Fiscal: DEUDA $pais " in y `anio' "  }" in g _dup(20) "."

	** 2.1 PIB + Deflactor **
	PIBDeflactor, anio(`anio') nographs nooutput `update'
	local currency = currency[1]
	g Poblacion_adj = Poblacion*lambda
	tempfile PIB
	save `PIB'

	** 2.2 Datos Abiertos **
	if "`update'" == "update" {
		capture confirm file "`c(sysdir_personal)'/SIM/DatosAbiertos.dta"
		if _rc != 0 | "`update'" == "update" {
			UpdateDatosAbiertos
			local updated = r(updated)
			local ultanio = r(ultanio)
			local ultmes = r(ultmes)
		}
		else {
			local updated = "yes" // r(updated)
		}
	}
	else {
		local updated = "yes"
	}

	** 2.3 Update SHRFSP **
	if "`update'" == "update" | "`updated'" != "yes" {
		noisily run "`c(sysdir_personal)'/UpdateSHRFSP.do"
	}

	** 2.4 Bases RAW **
	use `if' using `"`c(sysdir_personal)'/SIM/SHRFSP.dta"', clear
	if "`base'" == "base" {
		exit
	}



	***************
	**# 3 MERGE ***
	***************
	sort anio
	merge m:1 (anio) using `PIB', nogen keepus(pibY pibYR var_* Poblacion* deflator lambda currency) update replace

	capture sort anio mes
	capture keep `if'

	local aniofirst = anio[1]
	local aniolast = anio[_N]
	local meslast = mes[_N]

	* 3.1 Anio, mes y observaciones iniciales y finales de la serie *
	forvalues k=1(1)`=_N' {
		if anio[`k'] == `anio' {
			local obsvp = `k'		
		}
	}
	//local anioini = anio[1]
	//local aniofin = anio[_N]
	//local mesfin = mes[_N]

	local lastexo = anio[_N]
	local obsfin = _N
	local obsvp = `obsfin'



	*****************************
	***                       ***
	**# 5 PARÁMETROS EXÓGENOS ***
	***                       ***
	*****************************
	tsset anio
	forvalues j = 1(1)`=_N' {
		* Política fiscal *
		foreach k of varlist shrfspInterno shrfspExterno ///
			rfsp rfspBalance rfspPIDIREGAS rfspIPAB rfspFONADIN rfspDeudores rfspBanca rfspAdecuaciones ///
			balprimario {
			capture confirm scalar `k'`=anio[`j']'
			if _rc == 0 {
				replace `k' = scalar(`k'`=anio[`j']')/100*pibY if anio == `=anio[`j']'
				local lastexo = `=anio[`j']'
			}
		}
		
		* Costos financieros *
		replace porInterno = shrfspInterno/(shrfspInterno+shrfspExterno) if porInterno == .
		replace porExterno = shrfspExterno/(shrfspInterno+shrfspExterno) if porExterno == .
		capture confirm scalar costodeudaInterno`=anio[`j']'
		if _rc == 0 {
			replace costodeudaInterno = scalar(costodeudaInterno`=anio[`j']')/100*porInterno*pibY if anio == `=anio[`j']'
		}		
		capture confirm scalar costodeudaExterno`=anio[`j']'
		if _rc == 0 {
			replace costodeudaExterno = scalar(costodeudaExterno`=anio[`j']')/100*porExterno*pibY if anio == `=anio[`j']'
		}
		
		* Tipo de cambio *
		capture confirm scalar tipoDeCambio`=anio[`j']'
		if _rc == 0 {
			replace tipoDeCambio = scalar(tipoDeCambio`=anio[`j']') if anio == `=anio[`j']'
		}

		replace shrfsp = shrfspInterno + shrfspExterno if anio == `=anio[`j']'
	}



	*****************
	**# 4 DISPLAY ***
	*****************
	noisily di _newline in g "{bf: " ///
		_col(44) in g %20s "`currency'" ///
		_col(66) %7s "% PIB" ///
		_col(77) %7s "Per cápita" "}"

	tempvar rfspOtros
	egen `rfspOtros' = rowtotal(rfspPIDIREGAS rfspIPAB rfspFONADIN rfspDeudores rfspBanca rfspAdecuaciones)
	tabstat rfspBalance `rfspOtros' rfsp shrfspInterno shrfspExterno shrfsp if anio == `anio', stat(sum) format(%20.0fc) save
	if _rc != 0 {
		noisily di in r "No hay informaci{c o'}n para el a{c n~}o `anio'"
		exit
	}
	tempname mattot
	matrix `mattot' = r(StatTotal)

	tabstat pibY Poblacion_adj if anio == `anio', stat(sum) format(%20.0fc) save
	tempname mattot2
	matrix `mattot2' = r(StatTotal)

	noisily di in g "  {bf:(+) Balance presupuestario" ///
		_col(44) in y %20.0fc `mattot'[1,1] ///
		_col(66) in y %7.1fc `mattot'[1,1]/`mattot2'[1,1]*100 ///
		_col(77) in y %7.0fc `mattot'[1,1]/`mattot2'[1,2] "}"
	noisily di in g "  {bf:(+) Otros RFSP" ///
		_col(44) in y %20.0fc `mattot'[1,2] ///
		_col(66) in y %7.1fc `mattot'[1,2]/`mattot2'[1,1]*100 ///
		_col(77) in y %7.0fc `mattot'[1,2]/`mattot2'[1,2] "}"
	noisily di in g _dup(83) "-"
	noisily di in g "  {bf:(=) RFSP" ///
		_col(44) in y %20.0fc `mattot'[1,3] ///
		_col(66) in y %7.1fc `mattot'[1,3]/`mattot2'[1,1]*100 ///
		_col(77) in y %7.0fc `mattot'[1,3]/`mattot2'[1,2] "}"
	noisily di in g _dup(83) "-"
	noisily di in g "  {bf:(=) SHRFSP Interna" ///
		_col(44) in y %20.0fc `mattot'[1,4] ///
		_col(66) in y %7.1fc `mattot'[1,4]/`mattot2'[1,1]*100 ///
		_col(77) in y %7.0fc `mattot'[1,4]/`mattot2'[1,2] "}"
	noisily di in g "  {bf:(=) SHRFSP Externa" ///
		_col(44) in y %20.0fc `mattot'[1,5] ///
		_col(66) in y %7.1fc `mattot'[1,5]/`mattot2'[1,1]*100 ///
		_col(77) in y %7.0fc `mattot'[1,5]/`mattot2'[1,2] "}"
	noisily di in g _dup(83) "-"
	noisily di in g "  {bf:(=) SHRFSP" ///
		_col(44) in y %20.0fc `mattot'[1,6] ///
		_col(66) in y %7.1fc `mattot'[1,6]/`mattot2'[1,1]*100 ///
		_col(77) in y %7.0fc `mattot'[1,6]/`mattot2'[1,2] "}"

	return scalar rfspBalance = `mattot'[1,1]
	return scalar rfspBalancePIB = `mattot'[1,1]/`mattot2'[1,1]*100
	return scalar rfspBalancePC = `mattot'[1,1]/`mattot2'[1,2]

	return scalar rfspOtros = `mattot'[1,2]
	return scalar rfspOtrosPIB = `mattot'[1,2]/`mattot2'[1,1]*100
	return scalar rfspOtrosPC = `mattot'[1,2]/`mattot2'[1,2]

	return scalar rfsp = `mattot'[1,3]
	return scalar rfspPIB = `mattot'[1,3]/`mattot2'[1,1]*100
	return scalar rfspPC = `mattot'[1,3]/`mattot2'[1,2]

	return scalar shrfspInterno = `mattot'[1,4]
	return scalar shrfspInternoPIB = `mattot'[1,4]/`mattot2'[1,1]*100
	return scalar shrfspInternoPC = `mattot'[1,4]/`mattot2'[1,2]

	return scalar shrfspExterno = `mattot'[1,5]
	return scalar shrfspExternoPIB = `mattot'[1,5]/`mattot2'[1,1]*100
	return scalar shrfspExternoPC = `mattot'[1,5]/`mattot2'[1,2]

	return scalar shrfsp = `mattot'[1,6]
	return scalar shrfspPIB = `mattot'[1,6]/`mattot2'[1,1]*100
	return scalar shrfspPC = `mattot'[1,6]/`mattot2'[1,2]




	*************************
	***                   ***
	**# 6 TASAS EFECTIVAS ***
	***                   ***
	*************************
	g tasaInterno = costodeudaInterno/L.shrfspInterno*100
	g tasaExterno = costodeudaExterno/L.shrfspExterno*100
	g tasaEfectiva = porInterno*tasaInterno + porExterno*tasaExterno

	g depreciacion = tipoDeCambio-L.tipoDeCambio
	g Depreciacion = (tipoDeCambio/L.tipoDeCambio-1)*100

	format tasa* depreciacion Depreciacion %7.1fc





	*********************************
	***                           ***
	**# 7 Efectos indicador deuda ***
	***                           ***
	*********************************
	foreach k of varlist shrfsp* balprimario `rfspOtros' {
		g `k'_pib = `k'/pibY*100
		g `k'_pc = `k'/Poblacion_adj/deflator
		format `k'_pib `k'_pc %10.1fc
	}

	g dif_shrfsp_pib = D.shrfsp_pib
	g dif_shrfsp_pc = D.shrfsp_pc
	format dif_* %10.1fc


	** 7.1 Efectos sobre el indicador **
	*g efectoActivos      = -(D.activosInt+D.activosExt*tipoDeCambio*1000-amortizacion)/pibY*100
	g efectoCrecimiento  = -(var_pibY/100)*L.shrfsp/pibY*100
	g efectoInflacion    = -(var_indiceY/100+var_indiceY/100*var_pibY/100)*L.shrfsp/pibY*100 
	g efectoIntereses    = ((tasaInterno/100)*L.shrfspInterno + (tasaExterno/100)*L.shrfspExterno)/pibY*100
	g efectoTipoDeCambio = (Depreciacion/100 + tasaExterno/100*Depreciacion/100)*L.shrfspExterno/pibY*100
	g efectoTotal = balprimario_pib + `rfspOtros'_pib + efectoCrecimiento + efectoInflacion + efectoIntereses + efectoTipoDeCambio
	g efectoOtros        = dif_shrfsp_pib - efectoTotal

	g efectoCrecimiento_pc  = -((Poblacion_adj-L.Poblacion_adj)/L.Poblacion_adj)*L.shrfsp/Poblacion_adj/deflator
	g efectoInflacion_pc= -(var_indiceY/100+var_indiceY/100*((Poblacion_adj-L.Poblacion_adj)/L.Poblacion_adj))*L.shrfsp/Poblacion_adj/deflator
	g efectoIntereses_pc    = (tasaInterno/100)*L.shrfspInterno/Poblacion_adj/deflator + (tasaExterno/100)*L.shrfspExterno/Poblacion_adj/deflator
	g efectoTipoDeCambio_pc = (Depreciacion/100 + tasaExterno/100*Depreciacion/100)*L.shrfspExterno/Poblacion_adj/deflator
	g efectoTotal_pc = balprimario_pc + `rfspOtros'_pc + efectoCrecimiento_pc + efectoInflacion_pc + efectoIntereses_pc + efectoTipoDeCambio_pc
	g efectoOtros_pc        = dif_shrfsp_pc - efectoTotal_pc

	g efectoPositivo = 0
	g efectoPositivo_pc = 0
	g efectoNegativo = 0
	g efectoNegativo_pc = 0
	foreach k of varlist balprimario_pib `rfspOtros'_pib efectoCrecimiento efectoInflacion ///
		efectoIntereses efectoTipoDeCambio efectoOtros {
			replace efectoPositivo = efectoPositivo + `k' if `k' > 0
			replace efectoNegativo = efectoNegativo + `k' if `k' < 0
	}
	foreach k of varlist balprimario_pc `rfspOtros'_pc efectoCrecimiento_pc efectoInflacion_pc ///
		efectoIntereses_pc efectoTipoDeCambio_pc efectoOtros_pc {
			replace efectoPositivo_pc = efectoPositivo_pc + `k' if `k' > 0
			replace efectoNegativo_pc = efectoNegativo_pc + `k' if `k' < 0
	}

	if "`nographs'" != "nographs" & "$nographs" == "" {

		** Texto **
		local j = 100/(`aniofin'-`ultanio')/2
		local i = 100/(`lastexo'-`aniofin'+1)/2
		forvalues k=1(1)`=_N' {
			if abs(efectoPositivo[`k']) > abs(efectoNegativo[`k']) & mes[`k'] == 12 & anio[`k'] >= `ultanio' & efectoPositivo[`k'] != . & efectoNegativo[`k'] != . {
				local textDeuda1 `"`textDeuda1' `=efectoPositivo[`k']+.25' `j' "{bf:`=string(shrfsp_pib[`k'],"%5.1fc")'% PIB}""'
				local textDeuda11 `"`textDeuda11' `=efectoPositivo_pc[`k']+750' `j' "{bf:`=string(shrfsp_pc[`k'],"%10.0fc")' MXN}""'
				local j = `j' + 100/(2022-`ultanio'+1)
			}
			if abs(efectoNegativo[`k']) >= abs(efectoPositivo[`k']) & mes[`k'] == 12 & anio[`k'] >= `ultanio' & efectoNegativo[`k'] != . & efectoPositivo[`k'] != . {
				local textDeuda2 `"`textDeuda2' `=efectoNegativo[`k']-.25' `j' "{bf:`=string(shrfsp_pib[`k'],"%5.1fc")'% PIB}""'
				local textDeuda22 `"`textDeuda22' `=efectoNegativo_pc[`k']-750' `j' "{bf:`=string(shrfsp_pc[`k'],"%10.0fc")' MXN}""'
				local j = `j' + 100/(2022-`ultanio'+1)
			}

			if abs(efectoPositivo[`k']) > abs(efectoNegativo[`k']) & mes[`k'] != 12 & anio[`k'] >= `ultanio' & anio[`k'] <= `lastexo' & efectoPositivo[`k'] != . & efectoNegativo[`k'] != . {
				local textDeuda3 `"`textDeuda3' `=efectoPositivo[`k']+.25' `i' "{bf:`=string(shrfsp_pib[`k'],"%5.1fc")'% PIB}""'
				local textDeuda33 `"`textDeuda33' `=efectoPositivo_pc[`k']+750' `i' "{bf:`=string(shrfsp_pc[`k'],"%10.0fc")' MXN}""'
				local i = `i' + 100/(`lastexo'-2023+1)
			}
			if abs(efectoNegativo[`k']) >= abs(efectoPositivo[`k']) & mes[`k'] != 12 & anio[`k'] >= `ultanio' & anio[`k'] <= `lastexo' & efectoNegativo[`k'] != . & efectoPositivo[`k'] != . {
				local textDeuda4 `"`textDeuda4' `=efectoNegativo[`k']-.25' `i' "{bf:`=string(shrfsp_pib[`k'],"%5.1fc")'% PIB}""'
				local textDeuda44 `"`textDeuda44' `=efectoNegativo_pc[`k']-750' `i' "{bf:`=string(shrfsp_pc[`k'],"%10.0fc")' MXN}""'
				local i = `i' + 100/(`lastexo'-2023+1)
			}
		}

		** Gráfica por PIB **
		if `"$export"' == "" {
			local graphtitle "{bf:Efectos sobre el indicador de la deuda}"
			local graphfuente "{bf:Fuente}: Elaborado por el CIEP, con informaci{c o'}n de la SHCP/EOFP, INEGI/BIE y $paqueteEconomico."
		}
		else {
			local graphtitle ""
			local graphfuente ""
		}
		graph bar balprimario_pib `rfspOtros'_pib efectoCrecimiento efectoInflacion efectoIntereses efectoTipoDeCambio efectoOtros ///
			if mes == 12 & anio >= `ultanio', ///
			over(anio, gap(0)) stack ///
			blabel(, format(%5.1fc)) outergap(0) ///
			text(`textDeuda1', color(red) size(small)) ///
			text(`textDeuda2', color(green) size(small)) ///
			ytitle("% PIB") ///
			legend(on position(6) rows(1) label(5 "Tasas de inter{c e'}s") label(4 "Inflaci{c o'}n") label(3 "Crec. Econ{c o'}mico") ///
			label(1 "Déficit Primario") label(6 "Tipo de cambio") label(2 "No presupuestario") ///
			label(7 "Otros") region(margin(zero))) ///
			name(efectoDeuda1, replace) ///
			///note("{bf:{c U'}ltimo dato}: `aniofin'm`mesfin'") ///
			title(Observado)

		graph bar balprimario_pib `rfspOtros'_pib efectoCrecimiento efectoInflacion efectoIntereses efectoTipoDeCambio efectoOtros ///
			if mes != 12 & anio <= `lastexo' & anio >= `ultanio', ///
			over(anio, gap(0)) stack ///
			blabel(, format(%5.1fc)) outergap(0) ///
			text(`textDeuda3', color(red) size(small)) ///
			text(`textDeuda4', color(green) size(small)) ///
			ytitle("") ylabel(, labcolor(white)) ///
			legend(on position(6) rows(1) label(5 "Tasas de inter{c e'}s") label(4 "Inflaci{c o'}n") label(3 "Crec. Econ{c o'}mico") ///
			label(1 "Déficit Primario") label(6 "Tipo de cambio") label(2 "No presupuestario") ///
			label(7 "Otros") region(margin(zero))) ///
			name(efectoDeuda2, replace) ///
			///note("{bf:{c U'}ltimo dato}: `aniofin'm`mesfin'") ///
			title(CGPE 2024)

		*net install grc1leg.pkg
		grc1leg efectoDeuda1 efectoDeuda2, ycommon ///
			title(`graphtitle') ///
			subtitle("{bf:Como % del PIB}") ///
			caption("`graphfuente'") ///
			name(efectoDeuda, replace) ///
		
		capture window manage close graph efectoDeuda1
		capture window manage close graph efectoDeuda2
		
		capture confirm existence $export
		if _rc == 0 {
			graph export "$export/efectoDeuda.png", replace name(efectoDeuda)
		}


		** Gráfica por persona ajustada **	
		if `"$export"' == "" {
			local graphtitle "{bf:Efectos sobre el indicador de la deuda per cápita}"
			local graphfuente "{bf:Fuente}: Elaborado por el CIEP, con informaci{c o'}n de la SHCP/EOFP, INEGI/BIE y $paqueteEconomico."
		}
		else {
			local graphtitle ""
			local graphfuente ""
		}
		graph bar balprimario_pc `rfspOtros'_pc efectoCrecimiento_pc efectoInflacion_pc efectoIntereses_pc efectoTipoDeCambio_pc efectoOtros_pc ///
			if mes == 12 & anio >= `ultanio', ///
			over(anio, gap(0)) stack ///
			blabel(, format(%10.0fc)) outergap(0) ///
			text(`textDeuda11', color(red) size(small)) ///
			text(`textDeuda22', color(green) size(small)) ///
			ytitle("`currency' `aniovp'") ///
			legend(on position(6) rows(1) label(5 "Tasas de inter{c e'}s") label(4 "Inflaci{c o'}n") label(3 "Crec. Demogr{c a'}fico") ///
			label(1 "Déficit Primario") label(6 "Tipo de cambio") label(2 "No presupuestario") ///
			label(7 "Otros") region(margin(zero))) ///
			name(efectoDeuda1PC, replace) ///
			///note("{bf:{c U'}ltimo dato}: `aniofin'm`mesfin'") ///
			title(Observado)

		graph bar balprimario_pc `rfspOtros'_pc efectoCrecimiento_pc efectoInflacion_pc efectoIntereses_pc efectoTipoDeCambio_pc efectoOtros_pc ///
			if mes != 12 & anio <= `lastexo' & anio >= `ultanio', ///
			over(anio, gap(0)) stack ///
			blabel(, format(%10.0fc)) outergap(0) ///
			text(`textDeuda33', color(red) size(small)) ///
			text(`textDeuda44', color(green) size(small)) ///
			ytitle("") ylabel(, labcolor(white)) ///
			legend(on position(6) rows(1) label(5 "Tasas de inter{c e'}s") label(4 "Inflaci{c o'}n") label(3 "Crec. Demogr{c a'}fico") ///
			label(1 "Déficit Primario") label(6 "Tipo de cambio") label(2 "No presupuestario") ///
			label(7 "Otros") region(margin(zero))) ///
			name(efectoDeuda2PC, replace) ///
			///note("{bf:{c U'}ltimo dato}: `aniofin'm`mesfin'") ///
			title(CGPE 2024)

		*net install grc1leg.pkg
		grc1leg efectoDeuda1PC efectoDeuda2PC, ycommon ///
			title(`graphtitle') ///
			subtitle("{bf:Por persona ajustada}") ///
			caption("`graphfuente'") ///
			name(efectoDeudaPC, replace) ///
		
		capture window manage close graph efectoDeuda1PC
		capture window manage close graph efectoDeuda2PC
		
		capture confirm existence $export
		if _rc == 0 {
			graph export "$export/efectoDeudaPC.png", replace name(efectoDeudaPC)
		}			
	}



	*********************************
	** 4.2 Deuda interna y externa **
	*********************************
	if "`nographs'" != "nographs" & "$nographs" == "" {
		tempvar shrfsp shrfspexterno shrfspinterno shrfspexternoG shrfspinternoG interno externo

		g `shrfsp' = shrfsp/Poblacion_adj/deflator
		g `shrfspinterno' = shrfspInterno/Poblacion_adj/deflator
		g `shrfspexterno' = shrfspExterno/Poblacion_adj/deflator

		g `shrfspinternoG' = shrfspInterno/Poblacion_adj/deflator
		g `shrfspexternoG' = `shrfspinternoG' + shrfspExterno/Poblacion_adj/deflator

		g `externo' = shrfspExterno/1000000000/deflator
		g `interno' = `externo' + shrfspInterno/1000000000/deflator

		format `shrfsp' `shrfspexterno' `shrfspinterno' `shrfspexternoG' `shrfspinternoG' `externo' `interno' %10.0fc

		** Textos sobre las gráficas **
		local j = 100/(`ultanio'-`anioshrfsp'+1)/2
		forvalues k=1(1)`=_N' {
			if `shrfsp'[`k'] != . & anio[`k'] >= `ultanio' {
				if "`anioshrfsp'" == "" {
					local anioshrfsp = anio[`k']
				}
				local text `"`text' `=shrfsp[`k']/1000000000/deflator[`k']*1.0075' `=anio[`k']' "{bf:`=string(shrfsp[`k']/pibY[`k']*100,"%5.1fc")'% PIB}""'
				if `shrfspsinPemex'[`k'] != . & anio[`k'] < `anio' {
					local textPemex `"`textPemex' `=`shrfspPemex'[`k']/2' `=anio[`k']' "{bf:`=string(`shrfspPemex'[`k'],"%10.1fc")'}""'
					local textSPemex `"`textSPemex' `=`shrfspsinPemex'[`k']/2+`shrfspPemex'[`k']/2' `=anio[`k']' "{bf:`=string(`shrfspsinPemex'[`k']-`shrfspPemex'[`k'],"%10.1fc")'}""'
				}
				*local textPC `"`textPC' `=`shrfsp'[`k']*1.0075' `=anio[`k']' "{bf:`=string(`shrfsp'[`k'],"%10.0fc")'}""'
				local j = `j' + 100/(`ultanio'-`anioshrfsp'+1)
			}
		}


		** 4.2.1 Gráfica general **
		if `"$export"' == "" {
			local graphtitle "{bf:Saldo hist{c o'}rico de RFSP}"
			local graphfuente "{bf:Fuente}: Elaborado por el CIEP, con informaci{c o'}n de la SHCP/EOFP, INEGI/BIE y $paqueteEconomico."
		}
		else {
			local graphtitle ""
			local graphfuente ""
		}
		twoway (bar `interno' anio if mes == 12, mlabel(`interno') mlabposition(7) mlabangle(90) mlabcolor(white) mlabgap(0pt)) ///
			(bar `externo' anio if mes == 12, mlabel(`externo') mlabposition(7) mlabangle(90) mlabcolor(white) mlabgap(0pt)) ///
			(bar `interno' anio if mes != 12, mlabel(`interno') mlabposition(7) mlabangle(90) mlabcolor(white) mlabgap(0pt) pstyle(p1) fintensity(inten60) lwidth(none)) ///
			(bar `externo' anio if mes != 12, mlabel(`externo') mlabposition(7) mlabangle(90) mlabcolor(white) mlabgap(0pt) pstyle(p2) fintensity(inten60) lwidth(none)) ///
			(connected shrfsp_pib anio, mlabel(shrfsp_pib) mlabposition(0) mlabcolor(black) yaxis(2) yscale(lwidth(none) axis(2)) mlabgap(0pt) pstyle(p3)) ///
			if `externo' != . & anio >= `ultanio', ///
			title(`graphtitle') ///
			subtitle("{bf:Como % del PIB}") ///
			caption("`graphfuente'") ///
			ylabel(, format(%15.0fc) labsize(small)) ///
			ylabel(, format(%10.0fc) labsize(small) axis(2)) ///
			xlabel(`ultanio'(1)`lastexo', noticks) ///	
			yscale(range(0) axis(1) noline) ///
			yscale(range(0) axis(2) noline) ///
			ytitle("mil millones `currency' `aniovp'") ///
			ytitle("% del PIB", axis(2)) ///
			xtitle("") ///
			legend(on position(6) rows(1) order(1 2) ///
			label(1 `"Interno (`=string(`interno'[`obsvp']/(`interno'[`obsvp']+`externo'[`obsvp'])*100,"%7.1fc")'% en `=anio[`obsvp']')"') ///
			label(2 `"Externo (`=string(`externo'[`obsvp']/(`interno'[`obsvp']+`externo'[`obsvp'])*100,"%7.1fc")'% en `=anio[`obsvp']')"') ///
			region(margin(zero))) ///
			name(shrfsp, replace)

		capture confirm existence $export
		if _rc == 0 {
			graph export "$export/shrfsp.png", replace name(shrfsp)
		}			


		** 4.2.2 Gráfica por persona ajustada **
		if "$export" == "" {
			local graphtitle "{bf:Saldo hist{c o'}rico por persona ajustada}"
			local graphfuente "{bf:Fuente}: Elaborado por el CIEP, con informaci{c o'}n de la SHCP/EOFP, $paqueteEconomico y CONAPO (2023)."
		}
		else {
			local graphtitle ""
			local graphfuente ""
		}
		twoway (bar `interno' anio if mes == 12, mlabel(`interno') mlabposition(7) mlabangle(90) mlabcolor(white) mlabgap(0pt)) ///
			(bar `externo' anio if mes == 12, mlabel(`externo') mlabposition(7) mlabangle(90) mlabcolor(white) mlabgap(0pt)) ///
			(bar `interno' anio if mes != 12, mlabel(`interno') mlabposition(7) mlabangle(90) mlabcolor(white) mlabgap(0pt) pstyle(p1) fintensity(inten60) lwidth(none)) ///
			(bar `externo' anio if mes != 12, mlabel(`externo') mlabposition(7) mlabangle(90) mlabcolor(white) mlabgap(0pt) pstyle(p2) fintensity(inten60) lwidth(none)) ///
			(connected `shrfsp' anio, mlabel(`shrfsp') mlabposition(0) mlabcolor(black) yaxis(2) yscale(lwidth(none) axis(2)) mlabgap(0pt) pstyle(p3)) ///
			if `shrfsp' != . & anio >= `ultanio', ///
			title(`graphtitle') ///
			subtitle("{bf:Por persona ajustada}") ///
			caption("`graphfuente'") ///
			ylabel(, format(%15.0fc) labsize(small)) ///
			ylabel(, format(%10.0fc) labsize(small) axis(2)) ///
			xlabel(`ultanio'(1)`lastexo', noticks) ///	
			///text(`textPC', placement(n) color(black) size(vsmall)) ///
			yscale(range(0) axis(1) noline) ///
			yscale(range(40000) axis(2) noline) ///
			ytitle("mil millones `currency' `aniovp'") xtitle("") ///
			ytitle("`currency' `aniovp' por persona ajustada", axis(2)) ///
			legend(on position(6) rows(1) order(1 2) ///
			label(1 `"Interno (`=string(`interno'[`obsvp']/(`interno'[`obsvp']+`externo'[`obsvp'])*100,"%7.1fc")'% en `=anio[`obsvp']')"') ///
			label(2 `"Externo (`=string(`externo'[`obsvp']/(`interno'[`obsvp']+`externo'[`obsvp'])*100,"%7.1fc")'% en `=anio[`obsvp']')"') ///
			region(margin(zero))) ///
			name(shrfsppc, replace)

		capture confirm existence $export
		if _rc == 0 {
			graph export "$export/shrfsppc.png", replace name(shrfsppc)
		}

		** Gráfica combinada **
		if `"$export"' == "" {
			local graphtitle "{bf:Saldo hist{c o'}rico de RFSP}"
			local graphfuente "{bf:Fuente}: Elaborado por el CIEP, con informaci{c o'}n de la SHCP/EOFP, INEGI/BIE y $paqueteEconomico."
		}
		else {
			local graphtitle ""
			local graphfuente ""
		}
		twoway (connected shrfsp_pib anio, mlabel(shrfsp_pib) mlabposition(0) mlabcolor(black) yscale(lwidth(none)) mlabgap(0pt)) ///
			(connected `shrfsp' anio, mlabel(`shrfsp') mlabposition(0) mlabcolor(black) yaxis(2) yscale(lwidth(none) axis(2)) mlabgap(0pt)) ///
			if `shrfsp' != . & anio >= `ultanio', ///
			title(`graphtitle') ///
			subtitle("{bf:Indicadores de la deuda pública}") ///
			caption("`graphfuente'") ///
			ylabel(, format(%15.0fc) labsize(small)) ///
			ylabel(, format(%10.0fc) labsize(small) axis(2) noticks) ///
			xlabel(`ultanio'(1)`lastexo', noticks) ///
			///yscale(range(0) axis(1) noline) ///
			///yscale(range(40000) axis(2) noline) ///
			ytitle("% PIB'") xtitle("") ///
			ytitle("`currency' `aniovp'", axis(2)) ///
			legend(on position(6) rows(1) order(1 2) ///
			label(1 "Como % del PIB") label(2 "Por persona ajustada")) ///
			name(combinada, replace)

		capture confirm existence $export
		if _rc == 0 {
			graph export "$export/combinada.png", replace name(combinada)
		}

		/** Gráfica para Pemex **
		tempvar shrfspsinPemex shrfspPemex
		g `shrfspPemex' = deudaPemex/1000000000/deflator
		replace `shrfspPemex' = 0 if `shrfspPemex' == .
		g `shrfspsinPemex' = (shrfsp)/1000000000/deflator
		replace `shrfspsinPemex' = 0 if `shrfspsinPemex' == .

		if `"$export"' == "" {
			local graphtitle "{bf:Saldo hist{c o'}rico} de RFSP"
			local graphfuente "{bf:Fuente}: Elaborado por el CIEP, con informaci{c o'}n de la SHCP/EOFP y $paqueteEconomico."
		}
		else {
			local graphtitle ""
			local graphfuente ""
		}

		twoway (bar `shrfspsinPemex' `shrfspPemex' anio if anio >= `ultanio' & anio < `anio') ///
			(bar `shrfspsinPemex' `shrfspPemex' anio if anio >= `anio') if `externo' != . & anio >= `ultanio' ///
			, title(`graphtitle') ///
			subtitle($pais) ///
			caption("`graphfuente'") ///
			ylabel(, format(%15.0fc) labsize(small)) ///
			xlabel(`ultanio'(1)`anio', noticks) ///	
			text(`textPemex' `textSPemex', color(white) size(small)) ///
			text(`text', placement(n) size(vsmall)) ///
			///text(2 `=`anio'+1.45' "{bf:Proyecci{c o'}n PE 2022}", color(white)) ///
			///text(2 `=2003+.45' "{bf:Externo}", color(white)) ///
			///text(`=2+`externosize2003'' `=2003+.45' "{bf:Interno}", color(white)) ///
			yscale(range(0) axis(1) noline) ///
			ytitle("mil millones `currency' `aniovp'") xtitle("") ///
			legend(on position(6) rows(1) order(1 2) ///
			label(1 `"Resto del SP"') ///
			label(2 `"Pemex"')) ///
			name(shrfspPemex, replace)

		capture confirm existence $export
		if _rc == 0 {
			graph export "$export/shrfspPemex.png", replace name(shrfspPemex)
		}*/


		**************************************************
		** REQUERIMIENTOS FINANCIEROS DEL SECTOR PÚBLCO **
		tempvar rfspBalance rfspAdecuacion rfspOtros rfspBalance0 rfspAdecuacion0 rfspOtros0 rfsppib rfsppc rfsp
		g `rfspOtros0' = - rfspPIDIREGAS/pibY*100 - rfspIPAB/pibY*100 - rfspFONADIN/pibY*100 - rfspDeudores/pibY*100 - rfspBanca/pibY*100
		g `rfspAdecuacion0' = - rfspAdecuacion/pibY*100		
		g `rfspBalance0' = - rfspBalance/pibY*100

		g `rfspOtros' = - rfspPIDIREGAS/pibY*100 - rfspIPAB/pibY*100 - rfspFONADIN/pibY*100 - rfspDeudores/pibY*100 - rfspBanca/pibY*100
		g `rfspAdecuacion' = `rfspOtros' - rfspAdecuacion/pibY*100 if rfspAdecuacion <= 0
		replace `rfspAdecuacion' = - rfspAdecuacion/pibY*100 if rfspAdecuacion > 0
		replace `rfspAdecuacion' = 0 if `rfspAdecuacion' == .

		g `rfspBalance' = `rfspAdecuacion' - rfspBalance/pibY*100 if rfspAdecuacion <= 0 & `rfspOtros' >= 0
		replace `rfspBalance' = rfspBalance/pibY*100 if rfspAdecuacion > 0 & `rfspOtros' < 0
		replace `rfspBalance' = `rfspOtros' - rfspBalance/pibY*100 if rfspAdecuacion > 0 & `rfspOtros' >= 0
		replace `rfspBalance' = `rfspAdecuacion' - `rfspOtros' - rfspBalance/pibY*100 if rfspAdecuacion <= 0 & `rfspOtros' < 0

		format `rfspBalance' `rfspAdecuacion' `rfspOtros' `rfspBalance0' `rfspAdecuacion0' `rfspOtros0' %5.1f
		
		g `rfsppib' = rfsp/pibY*100
		g rfsppc = rfsp/(Poblacion_adj)/deflator
		g `rfsp' = rfsp/deflator

		* Informes mensuales texto *
		tabstat `rfsp' if anio == `anio' | anio == `anio'-1, by(anio) f(%20.0fc) stat(sum) c(v) save nototal
		tempname stathoy statayer
		matrix `stathoy' = r(Stat2)
		matrix `statayer' = r(Stat1)

		g efectoPositivoRFSP = 0
		foreach k of varlist `rfspBalance0' `rfspAdecuacion0' `rfspOtros0' {
				replace efectoPositivoRFSP = efectoPositivoRFSP + `k' if `k' > 0
		}

		local j = 100/(`anio'-`ultanio'+1)/2
		forvalues k=1(1)`=_N' {
			if `rfsppib'[`k'] != . & anio[`k'] >= `ultanio' {
				local textRFSP `"`textRFSP' `=efectoPositivoRFSP[`k']+.025' `=anio[`k']' "{bf:`=string(`rfsppib'[`k'],"%5.1fc")'}""'				
				local j = `j' + 100/(`anio'-`ultanio'+1)
			}
		}

		if "$export" == "" {
			local graphtitle "{bf:Requerimientos financieros del sector p{c u'}blico}"
			local graphfuente "{bf:Fuente}: Elaborado por el CIEP, con informaci{c o'}n de la SHCP/EOFP y $paqueteEconomico."
		}
		else {
			local graphtitle ""
			local graphfuente ""
		}
		twoway (bar `rfspBalance' anio if mes == 12, mlabel(`rfspBalance0') mlabposition(6) mlabangle(0) mlabcolor(white) mlabgap(0pt)) ///
			(bar `rfspAdecuacion' anio if mes == 12, mlabel(`rfspAdecuacion0') mlabposition(6) mlabangle(0) mlabcolor(white) mlabgap(0pt)) ///
			(bar `rfspOtros' anio if mes == 12, mlabel(`rfspOtros0') mlabposition(6) mlabangle(0) mlabcolor(white) mlabgap(0pt)) ///
			(bar `rfspBalance' anio if mes != 12, mlabel(`rfspBalance0') mlabposition(6) mlabangle(0) mlabcolor(white) mlabgap(0pt) pstyle(p1) fintensity(inten60) lwidth(none)) ///
			(bar `rfspAdecuacion' anio if mes != 12, mlabel(`rfspAdecuacion0') mlabposition(6) mlabangle(0) mlabcolor(white) mlabgap(0pt) pstyle(p2) fintensity(inten60) lwidth(none)) ///
			(bar `rfspOtros' anio if mes != 12, mlabel(`rfspOtros0') mlabposition(6) mlabangle(0) mlabcolor(white) mlabgap(0pt) pstyle(p3) fintensity(inten60) lwidth(none)) ///
			if rfsp != . & anio >= `ultanio', ///
			title("`graphtitle'") ///
			subtitle($pais) xtitle("") ///
			name(rfsp, replace) ///
			ylabel(, format(%15.0fc) labsize(small)) ///
			xlabel(`ultanio'(1)`lastexo', noticks) ///	
			yscale(range(0) axis(1) noline) ///
			text(`textRFSP', placement(n) size(vsmall)) ///
			note("{bf:Nota:} Las barras opacas son proyecciones de $paqueteEconomico.") ///
			ytitle("% PIB") ///
			legend(on rows(1) label(3 "Otros ajustes") label(2 "Adecuaciones a registros") label(1 "Déficit público") ///
			region(margin(zero)) order(1 2 3)) ///
			///note("{bf:Nota:} Las barras opacas son proyecciones de $paqueteEconomico.") ///
			caption("`graphfuente'")
		capture confirm existence $export
		if _rc == 0 {
			graph export "$export/rfsp.png", replace name(rfsp)
		}			

		twoway (connected tasaInterno anio if mes == 12, mlabel(tasaInterno) mlabposition(0) mlabangle(0) mlabcolor(white) mlabgap(0pt)) ///
			(connected tasaExterno anio if mes == 12, mlabel(tasaExterno) mlabposition(0) mlabangle(0) mlabcolor(white) mlabgap(0pt)) ///
			(connected tasaInterno anio if mes != 12, mlabel(tasaInterno) mlabposition(0) mlabangle(0) mlabcolor(white) mlabgap(0pt) pstyle(p1) mcolor(%70) mlwidth(none)) ///
			(connected tasaExterno anio if mes != 12, mlabel(tasaExterno) mlabposition(0) mlabangle(0) mlabcolor(white) mlabgap(0pt) pstyle(p2) mcolor(%70) mlwidth(none)) ///
			if tasaInterno != . & anio >= `ultanio', ///
			title("Tasas de interés {bf:efectivas}") ///
			subtitle($pais) /**/ ///
			ylabel(0(2)8, format(%15.0fc) labsize(small)) ///
			ytitle("Costo Fin./Saldo Fin. * 100") ///
			legend(on position(6) rows(1) order(1 2 3 4) label(1 "Interno") label(2 "Externo") ///
			region(margin(zero))) ///
			xlabel(`ultanio'(1)`lastexo') xtitle("") ///
			name(tasasdeinteres, replace) ///
			///note("{bf:{c U'}ltimo dato}: `aniofin'm`mesfin'") ///
			caption("{bf:Fuente}: Elaborado por el CIEP, con informaci{c o'}n de la SHCP/EOFP y $paqueteEconomico.")
	}


	***********
	*** END ***
	***********
	capture drop __*
	timer off 5
	timer list 5
	noisily di _newline in g "{bf:Tiempo:} " in y round(`=r(t5)/r(nt5)',.1) in g " segs."

}

end
