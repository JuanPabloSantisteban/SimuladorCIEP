*!*******************************************
*!***                                    ****
*!***    Sistema de Cuentas Nacionales   ****
*!***    BIE/INEGI                       ****
*!***    Autor: Ricardo                  ****
*!***    Fecha: 17/Oct/22                ****
*!***                                    ****
*!*******************************************
program define SCN, return
quietly {
	timer on 33

	** 0.2 Revisa si existe el scalar aniovp **
	capture confirm scalar aniovp
	if _rc == 0 {
		local aniovp = scalar(aniovp)
	}
	else {
		local aniovp : di %td_CY-N-D  date("$S_DATE", "DMY")
		local aniovp = substr(`"`=trim("`aniovp'")'"',1,4)
	}

	capture use in 1 using "`c(sysdir_site)'/04_master/SCN.dta", clear
	syntax [, ANIO(int `aniovp') NOGraphs UPDATE ANIOMax(int `=`aniovp'+15')]

	noisily di _newline(2) in g _dup(20) "." "{bf:   Econom{c i'}a:" in y " SCN `anio'   }" in g _dup(20) "." _newline



	***
	*** 1. Databases and variable definitions
	***
	capture confirm file "`c(sysdir_site)'/04_master/SCN.dta"
	if _rc != 0 | "`update'" == "update" {
		noisily di in g "  Updating SCN.dta..." _newline
		UpdateSCN `update'
	}

	** 1.1. PIBDeflactor
	PIBDeflactor, anio(`anio') nographs nooutput
	local anio_exo = r(anio_exo)
	local geo = r(geo)

	tempfile basepib
	save `basepib'



	**************************
	** 1.1. Merge databases **
	use "`c(sysdir_site)'/04_master/SCN.dta", clear
	merge 1:1 (anio) using `basepib', nogen
	tsset anio



	******************************
	** 1.2. Forecast & Pastcast **
	order indiceY-lambda, last

	* guarda el {c u'}ltimo año para el que hay un valor de PIB *
	forvalues k = `=_N'(-1)1 {
		if RemSalSS[`k'] != . {
			local latest = anio[`k']
			continue, break
		}
	}

	/* Calcula los valores futuros de las variables a partir de la {c u'}ltima 
	observaci{c o'}n y los valores anteriores de 2002 a 1993 (utiliza la tasa de 
	crecimiento del PIB en t{c e'}rminos nominales */
	foreach k of varlist RemSalSS-IngDisp {
		replace `k' = L.`k'*pibYR/L.pibYR*indiceY/L.indiceY if `k' == .
		forvalues j = 2002(-1)1993 {
			replace `k' = F.`k'*L.pibYR/pibYR*L.indiceY/indiceY if anio == `j'
		}
	}
	

	*******************************/
	** 1.3. Construir cuentas (C) **

	** R.1. Observacion **
	forvalues k = 1(1)`=_N' {
		if anio[`k'] == `anio' {
			local obs = `k'
			continue, break
		}
	}


	**
	** A. Generaci{c o'}n de la producci{c o'}n
	**
	noisily di _newline in y "{bf: A. Cuenta: de producci{c o'}n (bruta)" in g ///
		_col(44) in g %20s "MXN" ///
		_col(66) %7s "% PIB" "}" 
	noisily di in g "  (+) Producci{c o'}n bruta" ///
		_col(44) in y %20.0fc ProdT[`obs'] ///
		_col(66) in y %7.3fc ProdT[`obs']/PIB[`obs']*100
	noisily di in g "  (-) Consumo intermedio" ///
		_col(44) in y %20.0fc ConsInt[`obs'] ///
		_col(66) in y %7.3fc ConsInt[`obs']/PIB[`obs']*100
	noisily di in g _dup(72) "-"
	noisily di in g "{bf:  (=) Valor agregado" ///
		_col(44) in y %20.0fc (ProdT[`obs']-ConsInt[`obs']) ///
		_col(66) in y %7.3fc (ProdT[`obs']-ConsInt[`obs'])/PIB[`obs']*100 "}"
	noisily di in g "  (+) Impuestos a los productos" ///
		_col(44) in y %20.0fc (ImpNet[`obs']) ///
		_col(66) in y %7.3fc (ImpNet[`obs'])/PIB[`obs']*100
	noisily di in g _dup(72) "-"
	noisily di in g "{bf:  (=) Producto Interno Bruto" ///
		_col(44) in y %20.0fc (PIB[`obs']) ///
		_col(66) in y %7.3fc (PIB[`obs'])/PIB[`obs']*100 "}"

		
	* Returns *
	scalar ProdBruta = ProdT[`obs']
	scalar ProdBrutaPIB = ProdT[`obs']/PIB[`obs']*100

	scalar ConsInter = ConsInt[`obs']
	scalar ConsInterPIB = ConsInt[`obs']/PIB[`obs']*100

	scalar ValoAgreg = (ProdT[`obs']-ConsInt[`obs'])
	scalar ValoAgregPIB = (ProdT[`obs']-ConsInt[`obs'])/PIB[`obs']*100

	scalar ImpuProdu = ImpNet[`obs']
	scalar ImpuProduPIB = ImpNet[`obs']/PIB[`obs']*100


	**
	** B. Generaci{c o'}n de ingresos
	**

	* Ajustes Remuneraciones a asalariados y Seguridad Social *
	replace RemSal = RemSal - SSImputada

	** B.1. Ingreso mixto **
	g double MixN = IngMixto - DepMix
	format MixN %20.0fc
	label var MixN "Ingreso mixto neto"
	
	g double MixL = MixN*2/3 				//	<-- NTA metodolog{c i'}a
	format MixL %20.0fc
	label var MixL "Ingreso mixto (laboral)"

	g double MixK = MixN*1/3 + DepMix 		//	<-- NTA metodolog{c i'}­a
	format MixK %20.0fc
	label var MixK "Ingreso mixto (capital)"

	g double MixKN = MixK - DepMix
	format MixKN %20.0fc
	label var MixKN "Ingreso mixto neto (capital)"

	g double ROW = ROWRemR + ROWTransR + ROWPropR - ROWTransP - ROWPropP - ROWPropP
	format ROW %20.0fc
	label var ROW "Resto del mundo"

	** B.3. Ingreso de capital neto **
	g double ExNOpSoc = ExNOpNoFin + ExNOpFin + ExNOpISFLSH
	format ExNOpSoc %20.0fc
	label var ExNOpSoc "Sociedades e ISFLSH"
	*replace ExNOpSoc = PIN - RemSalSS - MixN - (ImpProductos + SubProductos) - (ImpProduccion + SubProduccion)

	** B.4 Ingreso de capital **
	g double Capital = ExNOpSoc + MixKN + ExNOpHog + ExNOpGob
	format Capital %20.0fc
	label var Capital "Ingreso de capital"

	** B.5. Impuestos Netos **
	g double ImpNetProduccion = ImpProduccion + SubProduccion
	format ImpNetProduccion %20.0fc
	label var ImpNetProduccion "Impuestos netos a la producci{c o'}n e importaciones"

	g double ImpNetProduccionL = ImpNetProduccion*(RemSalSS + MixL)/(RemSalSS + MixL + Capital)
	format ImpNetProduccionL %20.0fc
	label var ImpNetProduccion "Impuestos netos a la producci{c o'}n e importaciones (laboral)"

	g double ImpNetProduccionK = ImpNetProduccion - ImpNetProduccionL
	format ImpNetProduccionK %20.0fc
	label var ImpNetProduccionK "Impuestos netos a la producci{c o'}n e importaciones (capital)"

	g double ImpNetProductos = ImpProductos - SubProd
	format ImpNetProductos %20.0fc
	label var ImpNetProductos "Impuestos netos sobre los productos"

	g double ImpuestosNetos = Imp - Sub
	format ImpNet %20.0fc
	label var ImpNet "Impuestos sobre los productos, producci{c o'}n e importaciones"	

	** B.6. Ingreso laboral bruto **
	g double Yl = RemSalSS + MixL + ImpNetProduccionL
	format Yl %20.0fc
	label var Yl "Ingreso laboral"

	** B.7. Ingresos de capital con impuestos *
	g double CapIncImp = Capital + ImpNetProduccionK + ImpNet
	format CapIncImp %20.0fc
	label var CapIncImp "Ingreso de capital (netos con impuestos)"

	** B.8. Producto Interno Neto **
	noisily di _newline in y "{bf: B.1. Cuenta: distribuc{c o'}n del ingreso" in g ///
		_col(44) in g %20s "MXN" ///
		_col(66) %7s "% PIB" "}" 
	noisily di in g "  (+) Remuneraci{c o'}n de asalariados" ///
		_col(44) in y %20.0fc RemSal[`obs'] ///
		_col(66) in y %7.3fc RemSal[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Contribuciones sociales" ///
		_col(44) in y %20.0fc SSEmpleadores[`obs']+SSImputada[`obs'] ///
		_col(66) in y %7.3fc (SSEmpleadores[`obs']+SSImputada[`obs'])/PIB[`obs']*100
	noisily di in g "  (+) Ingreso mixto (laboral)" ///
		_col(44) in y %20.0fc MixL[`obs']  ///
		_col(66) in y %7.3fc MixL[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Impuestos a la producci{c o'}n (laboral)" ///
		_col(44) in y %20.0fc ImpNetProduccionL[`obs']  ///
		_col(66) in y %7.3fc ImpNetProduccionL[`obs']/PIB[`obs']*100
	noisily di in g _dup(72) "-"
	noisily di in g "{bf:  (=) Ingresos laborales" ///
		_col(44) in y %20.0fc Yl[`obs'] ///
		_col(66) in y %7.3fc Yl[`obs']/PIB[`obs']*100 "}"

	noisily di in g "  (+) Ingresos de capital (neto + imp.)" ///
		_col(44) in y %20.0fc CapIncImp[`obs'] ///
		_col(66) in y %7.3fc CapIncImp[`obs'] /PIB[`obs']*100

	noisily di in g _dup(72) "-"
	noisily di in g "{bf:  (=) Producto Interno Neto" ///
		_col(44) in y %20.0fc PIN[`obs'] ///
		_col(66) in y %7.3fc PIN[`obs']/PIB[`obs']*100 "}"
	noisily di in g "  (+) Consumo de capital fijo" ///
		_col(44) in y %20.0fc CapFij[`obs'] ///
		_col(66) in y %7.3fc CapFij[`obs']/PIB[`obs']*100
	noisily di in g _dup(72) "-"
	noisily di in g "{bf:  (=) Producto Interno Bruto" ///
		_col(44) in y %20.0fc PIB[`obs'] ///
		_col(66) in y %7.3fc PIB[`obs']/PIB[`obs']*100 "}"

	** R.4. Returns ***
	scalar RemSal = RemSal[`obs']
	scalar RemSalPIB = RemSal[`obs']/PIB[`obs']*100

	scalar SSocial = SSEmpleadores[`obs'] + SSImputada[`obs']
	scalar SSocialPIB = (SSEmpleadores[`obs'] + SSImputada[`obs'])/PIB[`obs']*100

	scalar MixL = MixL[`obs']
	scalar MixLPIB = MixL[`obs']/PIB[`obs']*100

	scalar ImpNetProduccionL = ImpNetProduccionL[`obs']
	scalar ImpNetProduccionLPIB = ImpNetProduccionL[`obs']/PIB[`obs']*100

	scalar Yl = Yl[`obs']
	scalar YlPIB = Yl[`obs']/PIB[`obs']*100
	scalar CapIncImp = CapIncImp[`obs']
	scalar CapIncImpPIB = CapIncImp[`obs']/PIB[`obs']*100

	scalar PIN = PIN[`obs']
	scalar PINPIB = PIN[`obs']/PIB[`obs']*100
	scalar CapFij = CapFij[`obs']
	scalar CapFijPIB = CapFij[`obs']/PIB[`obs']*100

	scalar PIB = PIB[`obs']
	scalar PIPIB = PIB[`obs']/PIB[`obs']*100
	
	g geoPIB = (((PIB/deflator)/(L5.PIB/L5.deflator))^(1/5)-1)*100
	scalar crecpibpGEO = geoPIB[`obs']
	scalar crecpibfGEO = geoPIB[`=`obs'+5']

	scalar SSEmpleadores = SSEmpleadores[`obs']
	scalar SSEmpleadoresPIB = SSEmpleadores[`obs']/PIB[`obs']*100
	
	scalar SSImputada = SSImputada[`obs']
	scalar SSImputadaPIB = SSImputada[`obs']/PIB[`obs']*100


	* Cuenta de capital *
	noisily di _newline in y "{bf: B.2. Cuenta: de los ingresos de capital" in g ///
		_col(44) in g %20s "MXN" ///
		_col(66) %7s "% PIB" "}" 
	noisily di in g "  (+) Sociedades e ISFLSH" ///
		_col(44) in y %20.0fc ExNOpSoc[`obs'] ///
		_col(66) in y %7.3fc ExNOpSoc[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Ingreso mixto (capital)" ///
		_col(44) in y %20.0fc MixKN[`obs'] ///
		_col(66) in y %7.3fc MixKN[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Alquiler imputado" ///
		_col(44) in y %20.0fc ExNOpHog[`obs'] ///
		_col(66) in y %7.3fc ExNOpHog[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Gobierno" ///
		_col(44) in y %20.0fc ExNOpGob[`obs'] ///
		_col(66) in y %7.3fc ExNOpGob[`obs']
	noisily di in g _dup(72) "-"
	noisily di in g "{bf:  (=) Ingresos de capital (neto) " ///
		_col(44) in y %20.0fc Capital[`obs'] ///
		_col(66) in y %7.3fc Capital[`obs']/PIB[`obs']*100 "}"
	noisily di in g _dup(72) "-"
	noisily di in g "  (+) Impuestos a los productos" ///
		_col(44) in y %20.0fc ImpNet[`obs'] ///
		_col(66) in y %7.3fc ImpNet[`obs'] /PIB[`obs']*100
	noisily di in g "  (+) Impuestos a la producci{c o'}n (capital)" ///
		_col(44) in y %20.0fc ImpNetProduccionK[`obs']  ///
		_col(66) in y %7.3fc ImpNetProduccionK[`obs']/PIB[`obs']*100
	noisily di in g _dup(72) "-"
	noisily di in g "{bf:  (=) Ingresos de capital (neto + imp.) " ///
		_col(44) in y %20.0fc CapIncImp[`obs'] ///
		_col(66) in y %7.3fc CapIncImp[`obs']/PIB[`obs']*100 "}"

	* Returns *
	scalar ExNOpSoc = ExNOpSoc[`obs']
	scalar ExNOpSocPIB = ExNOpSoc[`obs']/PIB[`obs']*100

	scalar MixK = MixK[`obs']
	scalar MixKPIB = MixK[`obs']/PIB[`obs']*100	
	
	scalar MixKN = MixKN[`obs']
	scalar MixKNPIB = MixKN[`obs']/PIB[`obs']*100

	scalar ExNOpHog = ExNOpHog[`obs']
	scalar ExNOpHogPIB = ExNOpHog[`obs']/PIB[`obs']*100

	scalar ExNOpGob = ExNOpGob[`obs']
	scalar ExNOpGobPIB = ExNOpGob[`obs']/PIB[`obs']*100

	scalar Capital = Capital[`obs']
	scalar CapitalPIB = Capital[`obs']/PIB[`obs']*100

	scalar ImpNet = ImpNet[`obs']
	scalar ImpNetPIB = ImpNet[`obs']/PIB[`obs']*100

	scalar ImpNetProduccionK = ImpNetProduccionK[`obs']
	scalar ImpNetProduccionKPIB = ImpNetProduccionK[`obs']/PIB[`obs']*100


	** C.9. Resto del Mundo **
	g double AhorroN = IngDisp - ConHog - ConGob - ComprasN
	format AhorroN %20.0fc

	** Validaci{c o'}n **
	*g double PIBval = RemSalSS + IngMixto + ExBOpSinMix + ImpNet + ImpNetProduccion
	*format PIBval %20.0fc
	*label var PIBval "PIB (validaci{c o'}n)"

	** C.6. ROW, Compensation of Employees, pagadas **
	*replace ROWRemP = PIN + CapFij + ROWRemR + ROWPropR ///
		- ROWPropP + ROWTransR - ROWTransP - PIBval

	g double ROWRem = ROWRemR // - ROWRemP
	format ROWRem %20.0fc
	label var ROWRem "Remuneraci{c o'}n de asalariados"

	g double ROWTrans = ROWTransR - ROWTransP
	format ROWTrans %20.0fc
	label var ROWTrans "Transferencias corrientes"

	g double ROWProp = ROWPropR - ROWPropP
	format ROWProp %20.0fc
	label var ROWProp "Ingresos a la propiedad"




	*************************
	*** 2. Resultados (R) ***
	*************************
	** R.3. Graph **
	if "`nographs'" != "nographs" & "$nographs" == "" {
		tempvar Laboral Capital Depreciacion
		g `Laboral' = (Yl)/deflator/1000000000000
		label var `Laboral' "Ingresos laborales"
		g `Capital' = (CapIncImp + Yl)/deflator/1000000000000
		label var `Capital' "Ingresos de capital"
		g `Depreciacion' = (CapFij + CapIncImp + Yl)/deflator/1000000000000
		label var `Depreciacion' "Depreciaci{c o'}n"
		format `Depreciacion' %7.0fc
		
		if `anio_exo'-`latest' == 1 {
			local graphtype "bar"
		}
		else {
			local graphtype "bar"
		}

		if "$export" == "" {
			local graphtitle = "{bf:Distribuci{c o'}n} del ingreso"
			local graphfuente = "{bf:Fuente}: Elaborado por el CIEP, con información de INEGI/BIE."
		}
		else {
			local graphtitle = ""
			local graphfuente = ""
		}

		tabstat `Depreciacion', stat(max) save
		tempname DEPMAX
		matrix `DEPMAX' = r(StatTotal)

		twoway (bar `Depreciacion' anio if anio <= `aniomax', pstyle(p1) lwidth(none) barwidth(.75) mlabel(`Depreciacion') mlabpos(12) mlabcolor(black) mlabsize(large)) ///
			(bar `Capital' anio if anio <= `aniomax', pstyle(p2) lwidth(none) barwidth(.75)) ///
			(bar `Laboral' anio if anio <= `aniomax', pstyle(p3) lwidth(none) barwidth(.75)) ///
			(`graphtype' `Depreciacion' anio if anio <= `anio_exo' & anio > `aniomax', pstyle(p1) lwidth(none) barwidth(.75) mlabel(`Depreciacion') mlabpos(12) mlabcolor(black) mlabsize(large) fintensity(50)) ///
			(`graphtype' `Capital' anio if anio <= `anio_exo' & anio > `aniomax', pstyle(p2) lwidth(none) barwidth(.75) fintensity(50)) ///
			(`graphtype' `Laboral' anio if anio <= `anio_exo' & anio > `aniomax', pstyle(p3) lwidth(none) barwidth(.75) fintensity(50)) ///
			(bar `Depreciacion' anio if anio > `aniomax' & anio > `anio_exo', pstyle(p1) lwidth(none) barwidth(.75)) ///
			(bar `Capital' anio if anio > `aniomax' & anio > `anio_exo', pstyle(p2) lwidth(none) barwidth(.75)) ///
			(bar `Laboral' anio if anio > `aniomax' & anio > `anio_exo', pstyle(p3) lwidth(none) barwidth(.75)), ///
			title("`graphtitle'") ///
			caption("`graphfuente'") ///
			legend(cols(3) order(1 2 3) region(margin(zero))) ///
			xtitle("") ///
			text(0 `=`latest'+1' "{bf:$paqueteEconomico}", color("111 111 111") place(1) justification(left) bcolor(white) box size(medlarge)) ///
			text(0 `=anio[1]' "{bf:billones MXN `anio'}", color("111 111 111") place(1) justification(left) bcolor(white) box size(medlarge)) ///
			///text(`=`Depreciacion'[1]*.05' `=anio[_N]-7.5' "{bf:Proyecci{c o'}n CIEP}", place(ne) color(white)) ///
			xlabel(`=round(anio[1],5)'(5)`=round(anio[_N],5)' `anio') ///
			ylabel(none, format(%20.0fc)) ///
			ytitle("") ///
			yscale(range(0)) xscale(range(1993)) ///
			note("{bf:{c U'}ltimo dato reportado}: `aniomax'.") ///
			name(gdp_generacion, replace)

		capture mkdir "`c(sysdir_site)'/05_graphs/"
		graph save gdp_generacion "`c(sysdir_site)'/05_graphs/gdp_generacion", replace
		capture confirm existence $export
		if _rc == 0 {
			graph export "$export/gdp_generacion.png", replace name(gdp_generacion)
		}
	}

	** R.5 Display (de la producci{c o'}n al ingreso) ***
	noisily di _newline in y "{bf: C. Distribuci{c o'}n secundaria del ing" in g ///
		_col(44) in g %20s "MXN" ///
		_col(66) %7s "% PIB" "}" 
	noisily di in g "{bf:  (+) Producto Interno Bruto" ///
		_col(44) in y %20.0fc PIB[`obs'] ///
		_col(66) in y %7.3fc PIB[`obs']/PIB[`obs']*100 "}"
	noisily di in g "  (-) Consumo de capital fijo" ///
		_col(44) in y %20.0fc CapFij[`obs'] ///
		_col(66) in y %7.3fc CapFij[`obs']/PIB[`obs']*100
	noisily di in g _dup(72) "-"
	noisily di in g "{bf:  (=) Producto Interno Neto" ///
		_col(44) in y %20.0fc PIN[`obs'] ///
		_col(66) in y %7.3fc PIN[`obs']/PIB[`obs']*100 "}"
	noisily di in g "  (+) Remuneraci{c o'}n a asalaraidos (ROW)" ///
		_col(44) in y %20.0fc ROWRem[`obs'] ///
		_col(66) in y %7.3fc ROWRem[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Ingresos a la propiedad (ROW)" ///
		_col(44) in y %20.0fc ROWProp[`obs'] ///
		_col(66) in y %7.3fc ROWProp[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Transferencias corrientes (ROW)" ///
		_col(44) in y %20.0fc ROWTrans[`obs'] ///
		_col(66) in y %7.3fc ROWTrans[`obs']/PIB[`obs']*100
	noisily di in g _dup(72) "-"
	noisily di in g "{bf:  (=) Ingreso nacional disponible" ///
		_col(44) in y %20.0fc IngDisp[`obs']-CapFij[`obs'] ///
		_col(66) in y %7.3fc (IngDisp[`obs']-CapFij[`obs'])/PIB[`obs']*100 "}"

	* Returns *
	scalar ROWRem = ROWRem[`obs']
	scalar ROWRemPIB = ROWRem[`obs']/PIB[`obs']*100

	scalar ROWProp = ROWProp[`obs']
	scalar ROWPropPIB = ROWProp[`obs']/PIB[`obs']*100

	scalar ROWTrans = ROWTrans[`obs']
	scalar ROWTransPIB = ROWTrans[`obs']/PIB[`obs']*100
	
	scalar ROW = ROW[`obs']
	scalar ROWPIB = ROW[`obs']/PIB[`obs']*100

	scalar IngDisp = IngDisp[`obs']
	scalar IngDispPIB = IngDisp[`obs']/PIB[`obs']*100

	* R.6 Consumo *
	noisily di _newline in y "{bf: D. Utilizaci{c o'}n del ingreso disp" in g ///
		_col(44) in g "MXN" ///
		_col(66) in g "% PIB" "}"
	noisily di in g "  (+) Consumo de hogares e ISFLSH" ///
		_col(44) in y %20.0fc ConHog[`obs'] ///
		_col(66) in y %7.3fc ConHog[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Consumo de gobierno" ///
		_col(44) in y %20.0fc ConGob[`obs'] ///
		_col(66) in y %7.3fc ConGob[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Compras netas" ///
		_col(44) in y %20.0fc ComprasN[`obs'] ///
		_col(66) in y %7.3fc ComprasN[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Ahorro bruto" ///
		_col(44) in y %20.0fc AhorroN[`obs'] ///
		_col(66) in y %7.3fc AhorroN[`obs']/PIB[`obs']*100
	noisily di in g _dup(72) "-"
	noisily di in g "  (-) Consumo de capital fijo" ///
		_col(44) in y %20.0fc CapFij[`obs'] ///
		_col(66) in y %7.3fc CapFij[`obs']/PIB[`obs']*100
	noisily di in g _dup(72) "-"
	noisily di in g "{bf:  (=) Ingreso nacional disponible" ///
		_col(44) in y %20.0fc IngDisp[`obs']-CapFij[`obs'] ///
		_col(66) in y %7.3fc (IngDisp[`obs']-CapFij[`obs'])/PIB[`obs']*100 "}"

	* Returns *
	scalar ConHog = ConHog[`obs']
	scalar ConHogPIB = ConHog[`obs']/PIB[`obs']*100

	scalar ConGob = ConGob[`obs']
	scalar ConGobPIB = ConGob[`obs']/PIB[`obs']*100

	scalar ComprasN = ComprasN[`obs']
	scalar ComprasNPIB = ComprasN[`obs']/PIB[`obs']*100

	scalar AhorroN = AhorroN[`obs']
	scalar AhorroNPIB = AhorroN[`obs']/PIB[`obs']*100
	scalar AhorroNPC = AhorroN[`obs']/poblacion[`obs']

	** R.3. Graph **
	if "`nographs'" != "nographs" & "$nographs" == "" {
		tempvar ConHog ConGob ComprasN AhorroN
		g `ComprasN' = (ComprasN)/deflator/1000000000000
		label var `ComprasN' "Compras netas"
		g `ConHog' = (ConHog + ComprasN)/deflator/1000000000000
		label var `ConHog' "Consumo de hogares"
		g `ConGob' = (ConGob + ConHog + ComprasN)/deflator/1000000000000
		label var `ConGob' "Consumo de gobierno"
		g `AhorroN' = (AhorroN + ConGob + ConHog + ComprasN)/deflator/1000000000000
		label var `AhorroN' "Ahorro neto"
		format `AhorroN' %7.0fc

		if "$export" == "" {
			local graphtitle = "{bf:Utilizaci{c o'}n} del ingreso disponible"
			local graphfuente = "{bf:Fuente}: Elaborado por el CIEP, con información de INEGI/BIE."
		}
		else {
			local graphtitle = ""
			local graphfuente = ""
		}
		
		twoway (bar `AhorroN' anio if anio <= `aniomax', pstyle(p1) lwidth(none) barwidth(.75) mlabel(`AhorroN') mlabpos(12) mlabcolor(black) mlabsize(large)) ///
			(bar `ConGob' anio if anio <= `aniomax', pstyle(p2) lwidth(none) barwidth(.75)) ///
			(bar `ConHog' anio if anio <= `aniomax', pstyle(p3) lwidth(none) barwidth(.75)) ///
			(bar `ComprasN' anio if anio <= `aniomax', pstyle(p4) lwidth(none) barwidth(.75)) ///
			(`graphtype' `AhorroN' anio if anio <= `anio_exo' & anio > `aniomax', ///
				pstyle(p1) lwidth(none) barwidth(.75) mlabel(`AhorroN') ///
				mlabpos(12) mlabcolor(black) mlabsize(large) fintensity(50)) ///
			(`graphtype' `ConGob' anio if anio <= `anio_exo' & anio > `aniomax', pstyle(p2) lwidth(none) barwidth(.75) fintensity(50)) ///
			(`graphtype' `ConHog' anio if anio <= `anio_exo' & anio > `aniomax', pstyle(p3) lwidth(none) barwidth(.75) fintensity(50)) ///
			(`graphtype' `ComprasN' anio if anio <= `anio_exo' & anio > `aniomax', pstyle(p4) lwidth(none) barwidth(.75) fintensity(50)) ///
			(bar `AhorroN' anio if anio > `aniomax' & anio > `anio_exo', pstyle(p1) lwidth(none)) ///
			(bar `ConGob' anio if anio > `aniomax' & anio > `anio_exo', pstyle(p2) lwidth(none)) ///
			(bar `ConHog' anio if anio > `aniomax' & anio > `anio_exo', pstyle(p3) lwidth(none)) ///
			(bar `ComprasN' anio if anio > `aniomax' & anio > `anio_exo', pstyle(p4) lwidth(none)), ///
			title("`graphtitle'") ///
			caption("`graphfuente'") ///
			legend(cols(4) order(1 2 3 4) region(margin(zero))) ///
			xtitle("") ///
			text(0 `=`latest'+1' "{bf:$paqueteEconomico}", color("111 111 111") place(1) justification(left) bcolor(white) box size(medlarge)) ///
			text(0 `=anio[1]' "{bf:billones MXN `anio'}", color("111 111 111") place(1) justification(left) bcolor(white) box size(medlarge)) ///
			///text(`=`AhorroN'[1]*0' `=anio[_N]-7.5' "{bf:Proyecci{c o'}n CIEP}", place(ne) color(white)) ///
			xlabel(`=round(anio[1],5)'(5)`=round(anio[_N],5)' `anio') ///
			ylabel(none, format(%20.0fc)) ///
			ytitle("") ///
			yscale(range(0)) xscale(range(1993)) ///
			note("{bf:{c U'}ltimo dato reportado}: `aniomax'.") ///
			name(gdp_utilizacion, replace)

		graph save gdp_utilizacion "`c(sysdir_site)'/05_graphs/gdp_utilizacion", replace
		capture confirm existence $export
		if _rc == 0 {
			graph export "$export/gdp_utilizacion.png", replace name(gdp_utilizacion)
		}
	}



	* Cuenta de consumo *
	* --- TABLA DE CONSUMO Y PORCENTAJE SOBRE EL PIB ---
	noisily di _newline in y "{bf: E. Consumo de hogares e ISFLSH" in g ///
		_col(44) in g "MXN" ///
		_col(66) in g "% PIB" "}"
	* ------------------- CATEGORÍA: ALIMENTOS Y BEBIDAS -------------------
	* Composite: Alimentos y bebidas
	noisily di in g "  (+) Alimentos y bebidas" ///
		_col(44) in y %20.0fc AlimBebT[`obs'] ///
		_col(66) in y %7.3fc AlimBebT[`obs']/PIB[`obs']*100
	* Alimentos
	noisily di in g "      Alimentos" ///
		_col(44) in y %20.0fc Alim[`obs'] ///
		_col(66) in y %7.3fc Alim[`obs']/PIB[`obs']*100
	* Bebidas no alcohólicas
	noisily di in g "      Bebidas no alcohólicas" ///
		_col(44) in y %20.0fc BebN[`obs'] ///
		_col(66) in y %7.3fc BebN[`obs']/PIB[`obs']*100
	* ------------------- CATEGORÍA: BEBIDAS ALCOHÓLICAS Y TABACO -------------------
	* Composite: Bebidas alcohólicas y tabaco
	noisily di in g "  (+) Bebidas alcohólicas y tabaco" ///
		_col(44) in y %20.0fc BebTabT[`obs'] ///
		_col(66) in y %7.3fc BebTabT[`obs']/PIB[`obs']*100
	* Bebidas alcohólicas
	noisily di in g "      Bebidas alcohólicas" ///
		_col(44) in y %20.0fc BebA[`obs'] ///
		_col(66) in y %7.3fc BebA[`obs']/PIB[`obs']*100
	* Tabaco
	noisily di in g "      Tabaco" ///
		_col(44) in y %20.0fc Taba[`obs'] ///
		_col(66) in y %7.3fc Taba[`obs']/PIB[`obs']*100
	* ------------------- CATEGORÍA: PRENDAS DE VESTIR Y CALZADO -------------------
	* Composite: Prendas de vestir y calzado
	noisily di in g "  (+) Prendas de vestir y calzado" ///
		_col(44) in y %20.0fc VestCalT[`obs'] ///
		_col(66) in y %7.3fc VestCalT[`obs']/PIB[`obs']*100
	* Prendas de vestir
	noisily di in g "      Prendas de vestir" ///
		_col(44) in y %20.0fc Vest[`obs'] ///
		_col(66) in y %7.3fc Vest[`obs']/PIB[`obs']*100
	* Calzado
	noisily di in g "      Calzado" ///
		_col(44) in y %20.0fc Calz[`obs'] ///
		_col(66) in y %7.3fc Calz[`obs']/PIB[`obs']*100
	* ------------------- CATEGORÍA: ALQUILER EFECTIVO Y CONSERVACIÓN DE LA VIVIENDA -------------------
	* Se deja una sola variable: AlojT = Alojamiento + Nc
	noisily di in g "  (+) Alquiler efectivo y conservación" ///
		_col(44) in y %20.0fc AlojT[`obs'] ///
		_col(66) in y %7.3fc AlojT[`obs']/PIB[`obs']*100
	* ------------------- CATEGORÍA: AGUA Y ELECTRICIDAD -------------------
	* Agua
	noisily di in g "      Agua" ///
		_col(44) in y %20.0fc Agua[`obs'] ///
		_col(66) in y %7.3fc Agua[`obs']/PIB[`obs']*100
	* Electricidad, gas y otros combustibles
	noisily di in g "      Electricidad, gas, otros combustibles" ///
		_col(44) in y %20.0fc Elec[`obs'] ///
		_col(66) in y %7.3fc Elec[`obs']/PIB[`obs']*100
	* ------------------- CATEGORÍA: ARTÍCULOS PARA EL HOGAR -------------------
	noisily di in g "  (+) Artículos para el hogar" ///
		_col(44) in y %20.0fc HogaT[`obs'] ///
		_col(66) in y %7.3fc HogaT[`obs']/PIB[`obs']*100
	* ------------------- CATEGORÍA: SALUD -------------------
	* Se utiliza el valor calculado de Xc como Salud (SaluT)
	noisily di in g "  (+) Salud" ///
		_col(44) in y %20.0fc SaluT[`obs'] ///
		_col(66) in y %7.3fc SaluT[`obs']/PIB[`obs']*100
	* ------------------- CATEGORÍA: TRANSPORTE -------------------
	* Adquisición de vehículos
	* Composite: Transporte (suma de Vehi, FTra y STra)
	noisily di in g "  (+) Transporte" ///
		_col(44) in y %20.0fc TraT[`obs'] ///
		_col(66) in y %7.3fc TraT[`obs']/PIB[`obs']*100
	noisily di in g "      Adquisición de vehículos" ///
		_col(44) in y %20.0fc Vehi[`obs'] ///
		_col(66) in y %7.3fc Vehi[`obs']/PIB[`obs']*100
	* Funcionamiento de transporte
	noisily di in g "      Funcionamiento de transporte" ///
		_col(44) in y %20.0fc FTra[`obs'] ///
		_col(66) in y %7.3fc FTra[`obs']/PIB[`obs']*100
	* Servicios de transporte
	noisily di in g "      Servicios de transporte" ///
		_col(44) in y %20.0fc STra[`obs'] ///
		_col(66) in y %7.3fc STra[`obs']/PIB[`obs']*100
	* ------------------- CATEGORÍA: COMUNICACIONES -------------------
	noisily di in g "  (+) Comunicaciones" ///
		_col(44) in y %20.0fc ComuT[`obs'] ///
		_col(66) in y %7.3fc ComuT[`obs']/PIB[`obs']*100
	* ------------------- CATEGORÍA: RECREACIÓN Y CULTURA -------------------
	noisily di in g "  (+) Recreación y cultura" ///
		_col(44) in y %20.0fc RecrT[`obs'] ///
		_col(66) in y %7.3fc RecrT[`obs']/PIB[`obs']*100
	* ------------------- CATEGORÍA: EDUCACIÓN -------------------
	noisily di in g "  (+) Educación" ///
		_col(44) in y %20.0fc EducT[`obs'] ///
		_col(66) in y %7.3fc EducT[`obs']/PIB[`obs']*100
	* ------------------- CATEGORÍA: RESTAURANTES Y BIENES DIVERSOS -------------------
	* Restaurantes y hoteles
	noisily di in g "  (+) Restaurantes y hoteles" ///
		_col(44) in y %20.0fc RestT[`obs'] ///
		_col(66) in y %7.3fc RestT[`obs']/PIB[`obs']*100
	* Bienes y servicios diversos
	noisily di in g "  (+) Bienes y servicios diversos" ///
		_col(44) in y %20.0fc DiveT[`obs'] ///
		_col(66) in y %7.3fc DiveT[`obs']/PIB[`obs']*100
	noisily di in g _dup(72) "-"
	noisily di in g "  (=) Consumo de los hogares" ///
		_col(44) in y %20.0fc ConHog[`obs'] ///
		_col(66) in y %7.3fc ConHog[`obs']/PIB[`obs']*100


	* Returns *
	* Variables ya calculadas (usando los indicadores originales)
	scalar Alim      = Alim[`obs']
	scalar AlimPIB   = Alim[`obs']/PIB[`obs']*100

	scalar BebN      = BebN[`obs']
	scalar BebNPIB   = BebN[`obs']/PIB[`obs']*100

	scalar BebA      = BebA[`obs']
	scalar BebAPIB   = BebA[`obs']/PIB[`obs']*100

	scalar Taba      = Taba[`obs']
	scalar TabaPIB   = Taba[`obs']/PIB[`obs']*100

	scalar Vest      = Vest[`obs']
	scalar VestPIB   = Vest[`obs']/PIB[`obs']*100

	scalar Calz      = Calz[`obs']
	scalar CalzPIB   = Calz[`obs']/PIB[`obs']*100

	* Renombrado: Alquiler (se guarda en AlojT)
	scalar AlojT     = AlojT[`obs']
	scalar AlojTPIB  = AlojT[`obs']/PIB[`obs']*100

	scalar Agua      = Agua[`obs']
	scalar AguaPIB   = Agua[`obs']/PIB[`obs']*100

	scalar Elec      = Elec[`obs']
	scalar ElecPIB   = Elec[`obs']/PIB[`obs']*100

	* Renombrado: Artículos para el hogar -> HogaT
	scalar HogaT     = HogaT[`obs']
	scalar HogaTPIB  = HogaT[`obs']/PIB[`obs']*100

	* Salud (se asocia a SaluT)
	scalar SaluT     = SaluT[`obs']
	scalar SaluTPIB  = SaluT[`obs']/PIB[`obs']*100

	scalar Vehi      = Vehi[`obs']
	scalar VehiPIB   = Vehi[`obs']/PIB[`obs']*100

	scalar FTra      = FTra[`obs']
	scalar FTraPIB   = FTra[`obs']/PIB[`obs']*100

	scalar STra      = STra[`obs']
	scalar STraPIB   = STra[`obs']/PIB[`obs']*100

	* Comunicaciones renombrado -> ComuT
	scalar ComuT     = ComuT[`obs']
	scalar ComuTPIB  = ComuT[`obs']/PIB[`obs']*100

	scalar RecrT     = RecrT[`obs']
	scalar RecrTPIB  = RecrT[`obs']/PIB[`obs']*100

	scalar EducT     = EducT[`obs']
	scalar EducTPIB  = EducT[`obs']/PIB[`obs']*100

	scalar RestT     = RestT[`obs']
	scalar RestTPIB  = RestT[`obs']/PIB[`obs']*100

	scalar DiveT     = DiveT[`obs']
	scalar DiveTPIB  = DiveT[`obs']/PIB[`obs']*100

	* --- SCALARS COMPUUESTOS ---
	scalar AlimBebT      = Alim + BebN
	scalar AlimBebTPIB   = (Alim + BebN)/PIB[`obs']*100

	scalar BebTabT       = BebA + Taba
	scalar BebTabTPIB    = (BebA + Taba)/PIB[`obs']*100

	scalar VestCalT      = Vest + Calz
	scalar VestCalTPIB   = (Vest + Calz)/PIB[`obs']*100

	scalar TraT          = Vehi + FTra + STra
	scalar TraTPIB       = (Vehi + FTra + STra)/PIB[`obs']*100
	
	scalar Prof541_T = Prof541_T[`obs']
	scalar Salud6211 = Salud6211[`obs']
	scalar Salud6212 = Salud6212[`obs']
	scalar Salud6213 = Salud6213[`obs']
	scalar Salud6216 = Salud6216[`obs']

	scalar ConsPriv_62 = ConsPriv_62[`obs']

	scalar Inmob5311 = Inmob5311[`obs']
	scalar Inmob5312 = Inmob5312[`obs']
	scalar ExBOpHog = ExBOpHog[`obs']
	scalar AlojT = AlojT[`obs']

	* Display table header
	noisily di _newline in y "{bf: F. Consumo (gobierno)" in g ///
		_col(44) in y %20s "MXN" ///
		_col(66) in y %7s "% PIB" "}" 

	* Display de sectores con texto abreviado
	noisily di in g "  (+) 11 Agric., cría, pesca" ///
		_col(44) in y %20.0fc GovAgr[`obs'] ///
		_col(66) in y %7.3fc GovAgr[`obs']/PIB[`obs']*100

	noisily di in g "  (+) 21 Minería" ///
		_col(44) in y %20.0fc GovMin[`obs'] ///
		_col(66) in y %7.3fc GovMin[`obs']/PIB[`obs']*100

	noisily di in g "  (+) Electricidad, gas, otros combustibles" ///
		_col(44) in y %20.0fc GovEner[`obs'] ///
		_col(66) in y %7.3fc GovEner[`obs']/PIB[`obs']*100

	noisily di in g "  (+) 23 Construcción" ///
		_col(44) in y %20.0fc GovConstr[`obs'] ///
		_col(66) in y %7.3fc GovConstr[`obs']/PIB[`obs']*100

	noisily di in g "  (+) 31-33 Manufacturas" ///
		_col(44) in y %20.0fc GovManuf[`obs'] ///
		_col(66) in y %7.3fc GovManuf[`obs']/PIB[`obs']*100

	noisily di in g "  (+) 43 Comercio mayor" ///
		_col(44) in y %20.0fc GovMayor[`obs'] ///
		_col(66) in y %7.3fc GovMayor[`obs']/PIB[`obs']*100

	noisily di in g "  (+) 46 Comercio menor" ///
		_col(44) in y %20.0fc GovMenor[`obs'] ///
		_col(66) in y %7.3fc GovMenor[`obs']/PIB[`obs']*100

	noisily di in g "  (+) 48-49 Transp. y correos" ///
		_col(44) in y %20.0fc GovTrans[`obs'] ///
		_col(66) in y %7.3fc GovTrans[`obs']/PIB[`obs']*100

	noisily di in g "  (+) 51 Info. medios" ///
		_col(44) in y %20.0fc GovInfo[`obs'] ///
		_col(66) in y %7.3fc GovInfo[`obs']/PIB[`obs']*100

	noisily di in g "  (+) 52 Finan. y seguros" ///
		_col(44) in y %20.0fc GovFin[`obs'] ///
		_col(66) in y %7.3fc GovFin[`obs']/PIB[`obs']*100

	noisily di in g "  (+) 53 Inmob. y alquiler" ///
		_col(44) in y %20.0fc GovInmob[`obs'] ///
		_col(66) in y %7.3fc GovInmob[`obs']/PIB[`obs']*100

	noisily di in g "  (+) 54 Prof. y técnicos" ///
		_col(44) in y %20.0fc GovProf[`obs'] ///
		_col(66) in y %7.3fc GovProf[`obs']/PIB[`obs']*100

	noisily di in g "  (+) 55 Corporativos" ///
		_col(44) in y %20.0fc GovCorp[`obs'] ///
		_col(66) in y %7.3fc GovCorp[`obs']/PIB[`obs']*100

	noisily di in g "  (+) 56 Apoyo y residuos" ///
		_col(44) in y %20.0fc GovApoyo[`obs'] ///
		_col(66) in y %7.3fc GovApoyo[`obs']/PIB[`obs']*100

	noisily di in g "  (+) 61 Educativos" ///
		_col(44) in y %20.0fc GovEdu[`obs'] ///
		_col(66) in y %7.3fc GovEdu[`obs']/PIB[`obs']*100

	noisily di in g "  (+) 62 Salud y asistencia" ///
		_col(44) in y %20.0fc GovSalud[`obs'] ///
		_col(66) in y %7.3fc GovSalud[`obs']/PIB[`obs']*100

	noisily di in g "  (+) 71 Recrea. y deportivos" ///
		_col(44) in y %20.0fc GovRecrea[`obs'] ///
		_col(66) in y %7.3fc GovRecrea[`obs']/PIB[`obs']*100

	noisily di in g "  (+) 72 Aloj. y alimentos" ///
		_col(44) in y %20.0fc GovAloj[`obs'] ///
		_col(66) in y %7.3fc GovAloj[`obs']/PIB[`obs']*100

	noisily di in g "  (+) 81 Otros servicios" ///
		_col(44) in y %20.0fc GovOtros[`obs'] ///
		_col(66) in y %7.3fc GovOtros[`obs']/PIB[`obs']*100

	noisily di in g "  (+) 93 Legisl. y justicia" ///
		_col(44) in y %20.0fc GovLegis[`obs'] ///
		_col(66) in y %7.3fc GovLegis[`obs']/PIB[`obs']*100

	noisily di in g "  (+) P.721 Compras ext." ///
		_col(44) in y %20.0fc GovCompExt[`obs'] ///
		_col(66) in y %7.3fc GovCompExt[`obs']/PIB[`obs']*100

	noisily di in g _dup(72) "-"
	noisily di in g "{bf:  (=) Consumo (gobierno)" ///
		_col(44) in y %20.0fc ConGob[`obs'] ///
		_col(66) in y %7.3fc ConGob[`obs']/PIB[`obs']*100 "}"		

	* Returns (scalar calculations)
	scalar AgriGob   = GovAgr[`obs']
	scalar AgriGobPIB = GovAgr[`obs'] / PIB[`obs'] * 100

	scalar MineGob   = GovMin[`obs']
	scalar MineGobPIB = GovMin[`obs'] / PIB[`obs'] * 100

	scalar ElecGob   = GovEner[`obs']
	scalar ElecGobPIB = GovEner[`obs'] / PIB[`obs'] * 100

	scalar ConsGob   = GovConstr[`obs']
	scalar ConsGobPIB = GovConstr[`obs'] / PIB[`obs'] * 100

	scalar ManuGob   = GovManuf[`obs']
	scalar ManuGobPIB = GovManuf[`obs'] / PIB[`obs'] * 100

	scalar ComMGob   = GovMayor[`obs']
	scalar ComMGobPIB = GovMayor[`obs'] / PIB[`obs'] * 100

	scalar CommGob   = GovMenor[`obs']
	scalar CommGobPIB = GovMenor[`obs'] / PIB[`obs'] * 100

	scalar TranGob   = GovTrans[`obs']
	scalar TranGobPIB = GovTrans[`obs'] / PIB[`obs'] * 100

	scalar MediGob   = GovInfo[`obs']
	scalar MediGobPIB = GovInfo[`obs'] / PIB[`obs'] * 100

	scalar SerFGob   = GovFin[`obs']
	scalar SerFGobPIB = GovFin[`obs'] / PIB[`obs'] * 100

	scalar SerIGob   = GovInmob[`obs']
	scalar SerIGobPIB = GovInmob[`obs'] / PIB[`obs'] * 100

	scalar SerPGob   = GovProf[`obs']
	scalar SerPGobPIB = GovProf[`obs'] / PIB[`obs'] * 100

	scalar DireGob   = GovCorp[`obs']
	scalar DireGobPIB = GovCorp[`obs'] / PIB[`obs'] * 100

	scalar SerNGob   = GovApoyo[`obs']
	scalar SerNGobPIB = GovApoyo[`obs'] / PIB[`obs'] * 100

	scalar SerEGob   = GovEdu[`obs']
	scalar SerEGobPIB = GovEdu[`obs'] / PIB[`obs'] * 100

	scalar SaluGob   = GovSalud[`obs']
	scalar SaluGobPIB = GovSalud[`obs'] / PIB[`obs'] * 100

	scalar CultGob   = GovRecrea[`obs']
	scalar CultGobPIB = GovRecrea[`obs'] / PIB[`obs'] * 100

	scalar AlojGob   = GovAloj[`obs']
	scalar AlojGobPIB = GovAloj[`obs'] / PIB[`obs'] * 100

	scalar OtroGob   = GovOtros[`obs']
	scalar OtroGobPIB = GovOtros[`obs'] / PIB[`obs'] * 100

	scalar GobiGob   = GovLegis[`obs']
	scalar GobiGobPIB = GovLegis[`obs'] / PIB[`obs'] * 100

	scalar CompGob   = GovCompExt[`obs']
	scalar CompGobPIB = GovCompExt[`obs'] / PIB[`obs'] * 100

	noisily di _newline in g "{bf: G. Cuenta: " in y "actividad econ{c o'}mica" in g ///
		_col(44) in g %20s "MXN" ///
		_col(66) %7s "% PIB" "}" 
	noisily di in g "  (+) Agricultura, cr{c i'}a, etc." ///
		_col(44) in y %20.0fc Agr_T[`obs'] ///
		_col(66) in y %7.3fc Agr_T[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Miner{c i'}a" ///
		_col(44) in y %20.0fc Min_T[`obs'] ///
		_col(66) in y %7.3fc Min_T[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Generaci{c o'}n, ... energ{c i'}a el{c e'}ctrica" ///
		_col(44) in y %20.0fc Ener_T[`obs'] ///
		_col(66) in y %7.3fc Ener_T[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Construcci{c o'}n" ///
		_col(44) in y %20.0fc Const_T[`obs'] ///
		_col(66) in y %7.3fc Const_T[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Industrias manufactureras" ///
		_col(44) in y %20.0fc Manu_T[`obs'] ///
		_col(66) in y %7.3fc Manu_T[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Comercio al por mayor" ///
		_col(44) in y %20.0fc ComMayor_T[`obs'] ///
		_col(66) in y %7.3fc ComMayor_T[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Comercio al por menor" ///
		_col(44) in y %20.0fc ComMenor_T[`obs'] ///
		_col(66) in y %7.3fc ComMenor_T[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Transportes, correos y almacen..." ///
		_col(44) in y %20.0fc Trans_T[`obs'] ///
		_col(66) in y %7.3fc Trans_T[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Informaci{c o'}n en medios masivos" ///
		_col(44) in y %20.0fc Medios_T[`obs'] ///
		_col(66) in y %7.3fc Medios_T[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Servicios financieros y de seguridad" ///
		_col(44) in y %20.0fc FinSeg_T[`obs'] ///
		_col(66) in y %7.3fc FinSeg_T[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Servicios inmobiliarios..." ///
		_col(44) in y %20.0fc Inmob_T[`obs'] ///
		_col(66) in y %7.3fc Inmob_T[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Servicios profesionales..." ///
		_col(44) in y %20.0fc Prof_T[`obs'] ///
		_col(66) in y %7.3fc Prof_T[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Direcci{c o'}n de corporativos y empresas" ///
		_col(44) in y %20.0fc Corp_T[`obs'] ///
		_col(66) in y %7.3fc Corp_T[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Servicios de apoyo a los negocios..." ///
		_col(44) in y %20.0fc Apoyo_T[`obs'] ///
		_col(66) in y %7.3fc Apoyo_T[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Servicios educativos" ///
		_col(44) in y %20.0fc Edu_T[`obs'] ///
		_col(66) in y %7.3fc Edu_T[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Servicios de salud y de asistencia..." ///
		_col(44) in y %20.0fc Salud_T[`obs'] ///
		_col(66) in y %7.3fc Salud_T[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Servicios de espar. culturales..." ///
		_col(44) in y %20.0fc Recre_T[`obs'] ///
		_col(66) in y %7.3fc Recre_T[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Servicios de alojamiento temporal..." ///
		_col(44) in y %20.0fc AloPrep_T[`obs'] ///
		_col(66) in y %7.3fc AloPrep_T[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Otros servicios excepto gobierno" ///
		_col(44) in y %20.0fc Otros_T[`obs'] ///
		_col(66) in y %7.3fc Otros_T[`obs']/PIB[`obs']*100
	noisily di in g "  (+) Actividades de gobierno..." ///
		_col(44) in y %20.0fc Legis_T[`obs'] ///
		_col(66) in y %7.3fc Legis_T[`obs']/PIB[`obs']*100
	noisily di in g _dup(72) "-"
	noisily di in g "{bf:  (=) Valor Agregado Bruto" ///
		_col(44) in y %20.0fc ValAg_T[`obs'] ///
		_col(66) in y %7.3fc ValAg_T[`obs']/PIB[`obs']*100 "}"
	noisily di in g "  (+) Impuestos a los productos" ///
		_col(44) in y %20.0fc ImpProd_T[`obs'] ///
		_col(66) in y %7.3fc ImpProd_T[`obs'] /PIB[`obs']*100
	noisily di in g _dup(72) "-"
	noisily di in g "{bf:  (=) Producto Interno Bruto" ///
		_col(44) in y %20.0fc PIB_T[`obs'] ///
		_col(66) in y %7.3fc PIB_T[`obs']/PIB[`obs']*100 "}"

	timer off 33
	timer list 33
	noisily di _newline in g "Tiempo: " in y round(`=r(t33)/r(nt33)',.1) in g " segs."
}
end


program define UpdateSCN

	args update

	***
	*** 1.1. Importar Cuenta de generación del ingreso
	***
	run "`c(sysdir_site)'/AccesoBIE.do" "724014 724015 724016 724017 724018 724019 724020 724021 724022 724023 724024 724025" "RemSalSS RemSal SSEmpleadores Imp ImpProductos ImpTipoIVA ImpImport OtrImp ImpProduccion Sub ExBOp PIB"

	** 1.2 Label variables **
	label var RemSalSS "Remuneraciones a asalariados + CSS"
	label var RemSal "Remuneraciones a asalariados"
	label var SSEmpleadores "CSS empleadores"
	label var Imp "Impuestos a la producción"
	label var ImpProductos "Impuestos a los productos"
	label var ImpTipoIVA "Impuestos tipo IVA"
	label var ImpImport "Impuestos sobre importaciones"
	label var OtrImp "Otros impuestos"
	label var ImpProduccion "Impuestos a la producción"
	label var Sub "Subsidios (total)"
	label var ExBOp "Excedente bruto de operación"
	label var PIB "Producto Interno Bruto"

	** 1.3 Dar formato a variables **
	foreach k of varlist RemSalSS - PIB {
		replace `k' = `k'*1000000
		replace `k' = 0 if `k' == .
	}

	** 1.4 Time Series **
	rename periodo anio
	label var anio "anio"

	** 1.5 Guardar **
	compress
	tempfile GenIng
	save `GenIng'


	***
	*** 2.1. Importar Producción bruta
	***
	run "`c(sysdir_site)'/AccesoBIE.do" "723651 723652 723653 723654 723655 723656 723657 723658 723659 723660 723661 723662 723663 723664 723665 723666 723667 723668 723669 723670 723671 723672" "RecT ProdT ProdMer ProdUF ProdNM ImpNet ImpProd SubProd ImpT ImpBien ImpServ UsosT ConsInt GcfT GcfI GcfC Fbcf VarExis ExpT ExpBien ExpServ DiscEst"

	** 2.2 Label variables **
	label var RecT      "Recursos totales"
	label var ProdT     "Producción total"
	label var ProdMer   "Producción de mercado"
	label var ProdUF    "Producción de uso final propio"
	label var ProdNM    "Producción no de mercado"
	label var ImpNet    "Impuestos netos"
	label var ImpProd   "Impuestos a los productos"
	label var SubProd   "Subsidios a los productos"
	label var ImpT      "Importaciones totales"
	label var ImpBien   "Importaciones de bienes"
	label var ImpServ   "Importaciones de servicios"
	label var UsosT     "Usos totales"
	label var ConsInt   "Consumo intermedio"
	label var GcfT      "Gasto de consumo final"
	label var GcfI      "Gasto de consumo final individual"
	label var GcfC      "Gasto de consumo final colectivo"
	label var Fbcf      "Formación bruta de capital fijo"
	label var VarExis   "Variación de existencias"
	label var ExpT      "Exportaciones totales"
	label var ExpBien   "Exportaciones de bienes"
	label var ExpServ   "Exportaciones de servicios"
	label var DiscEst   "Discrepancia estadística"

	** 2.3 Dar formato a variables **
	foreach k of varlist RecT - DiscEst {
		replace `k' = `k'*1000000
		replace `k' = 0 if `k' == .
	}

	** 2.4 Time Series **
	rename periodo anio
	label var anio "anio"

	** 2.5 Guardar **
	compress
	tempfile ProdBru
	save `ProdBru'


	***
	*** 3.1. Cuenta del ingreso nacional disponible
	***
	run "`c(sysdir_site)'/AccesoBIE.do" "724026 724027 724028 724029 724030 724031 724032 724033 724034 724035 724036 724037" "UsosT PIBVA CapFij PIN ROWRemR ROWRemP ROWPropR ROWPropP ROWTransR ROWTransP RecT IngNacD"

	** 3.2 Label variables **
	label var UsosT       "Usos totales"
	label var PIBVA       "Producto Interno Bruto a precios de mercado"
	label var CapFij      "Consumo de capital fijo"
	label var PIN         "Producto interno neto"
	label var ROWRemR     "Remuneraciones recibidas del resto del mundo"
	label var ROWRemP     "Remuneraciones pagadas al resto del mundo"
	label var ROWPropR    "Ingresos a la propiedad recibidos del resto del mundo"
	label var ROWPropP    "Ingresos a la propiedad pagados al resto del mundo"
	label var ROWTransR   "Transferencias recibidas del resto del mundo"
	label var ROWTransP   "Transferencias pagadas al resto del mundo"
	label var RecT        "Recursos totales"
	label var IngNacD     "Ingreso nacional disponible"

	** 3.3 Dar formato a variables **
	foreach k of varlist UsosT - IngNacD {
		replace `k' = `k'*1000000
		replace `k' = 0 if `k' == .
	}

	** 3.4 Time Series **
	rename periodo anio
	label var anio "anio"

	** 3.5 Guardar **
	compress
	tempfile IngNacDis
	save `IngNacDis'


	***
	*** 4.1. Consumo de hogares e ISFLSH
	***
	run "`c(sysdir_site)'/AccesoBIE.do" "724600 724601 724602 724603 724604 724605 724606 724607 724608 724609 724610 724611 724612 724613 724614 724615 724616 724617 724618 724619 724620 724621 724622 724623 724624 724625 724626 724627 724628 724629 724630 724631 724632 724633 724634 724635 724636 724637 724638 724639 724640 724641 724642 724643 724644 724645 724646 724647 724648 724649 724650 724651 724652 724653 724654 724655 724656" "ConHog AlimBebT Alim BebN BebTabT BebA Taba VestCalT Vest Calz AlojT Alqu CRep Agua Elec HogaT Mueb Text Arte Vajil Herr ConH SaluT Smed Sext Hosp TraT Vehi FTra STra ComuT Post TelEq TelS RecrT Audi Durab ArtEq Culs Publ Turis EducT PrePri Secu PostNT Terc NoAtr RestT Comi Hote DiveT Cuid EfeP Prot Segu ServF OtrS"

	** 4.2 Label variables **
	label var ConHog "Consumo de hogares e ISFLSH"
	label var AlimBebT "Alimentos y bebidas"
	label var Alim "Alimentos"
	label var BebN "Bebidas no alcohólicas"
	label var BebTabT "Bebidas alcohólicas y tabaco"
	label var BebA "Bebidas alcohólicas"
	label var Taba "Tabaco"
	label var VestCalT "Prendas de vestir y calzado"
	label var Vest "Prendas de vestir"
	label var Calz "Calzado"
	label var AlojT "Alquiler efectivo y conservación de la vivienda"
	label var Alqu "Alquiler efectivo"
	label var CRep "Conservación y reparación de la vivienda"
	label var Agua "Agua"
	label var Elec "Electricidad, gas y otros combustibles"
	label var HogaT "Artículos para el hogar"
	label var Mueb "Muebles"
	label var Text "Textiles"
	label var Arte "Artefactos eléctricos"
	label var Vajil "Vajillas y utensilios"
	label var Herr "Herramientas"
	label var ConH "Consumo de salud"
	label var SaluT "Salud"
	label var Smed "Servicios médicos"
	label var Sext "Servicios dentales"
	label var Hosp "Hospitales"
	label var TraT "Transporte"
	label var Vehi "Adquisición de vehículos"
	label var FTra "Funcionamiento de transporte"
	label var STra "Servicios de transporte"
	label var ComuT "Comunicaciones"
	label var Post "Correos"
	label var TelEq "Teléfonos y equipo de comunicación"
	label var TelS "Servicios telefónicos"
	label var RecrT "Recreación y cultura"
	label var Audi "Aparatos de audio y video"
	label var Durab "Durables"
	label var ArtEq "Artículos de esparcimiento"
	label var Culs "Cultura"
	label var Publ "Publicaciones"
	label var Turis "Turismo"
	label var EducT "Educación"
	label var PrePri "Preescolar y primaria"
	label var Secu "Secundaria"
	label var PostNT "Postsecundaria no terciaria"
	label var Terc "Terciaria"
	label var NoAtr "No atribuible"
	label var RestT "Restaurantes y hoteles"
	label var Comi "Comidas"
	label var Hote "Hoteles"
	label var DiveT "Bienes y servicios diversos"
	label var Cuid "Cuidado personal"
	label var EfeP "Efectos personales"
	label var Prot "Productos de protección"
	label var Segu "Seguros"
	label var ServF "Servicios financieros"
	label var OtrS "Otros servicios"
	
	** 4.3 Dar formato a variables **
	foreach k of varlist ConHog - OtrS {
		replace `k' = `k'*1000000
		replace `k' = 0 if `k' == .
	}

	** 4.4 Time Series **
	rename periodo anio
	label var anio "anio"

	** 4.5 Guardar **
	compress
	tempfile ConHog
	save `ConHog'


	***
	*** 5.1. Gasto de consumo privado
	***
	run "`c(sysdir_site)'/AccesoBIE.do" "724771 724772 724773 724774 724775 724776 724777" "GastPrivT BienDur BienSemi BienNoDur Serv SubMerc ComprasN"

	** 5.2 Label variables **
	label var GastPrivT "Gastos de consumo privado - Total"
	label var BienDur    "Bienes duraderos"
	label var BienSemi   "Bienes semi duraderos"
	label var BienNoDur  "Bienes no duraderos"
	label var Serv       "Servicios"
	label var SubMerc    "Subtotal gastos mercado interior"
	label var ComprasN   "Compras netas de residentes y no residentes"

	** 5.3 Dar formato a variables **
	foreach k of varlist GastPrivT - ComprasN {
		replace `k' = `k'*1000000
		replace `k' = 0 if `k' == .
	}

	** 5.4 Time Series **
	rename periodo anio
	label var anio "anio"

	** 5.5 Guardar **
	compress
	tempfile GastPriv
	save `GastPriv'


	***
	*** 6.1. Gasto de consumo del gobierno
	***
	run "`c(sysdir_site)'/AccesoBIE.do" ///
    "724959 724960 724961 724962 724963 724964 724965 724966 724967 724968 724969 724970 724971 724972 724973 724974 724975 724976 724977 724978 724979 724980" ///
    "ConGob GovAgr GovMin GovEner GovConstr GovManuf GovMayor GovMenor GovTrans GovInfo GovFin GovInmob GovProf GovCorp GovApoyo GovEdu GovSalud GovRecrea GovAloj GovOtros GovLegis GovCompExt"

    **  6.2 Label variables **
	label var ConGob   "Gastos de consumo de gobierno general - Total"
	label var GovAgr     "11 Agricultura, cría y explotación de animales, aprovechamiento forestal, pesca y caza"
	label var GovMin     "21 Minería"
	label var GovEner    "22 Generación, transmisión, distribución y comercialización de energía eléctrica, suministro de agua y de gas natural"
	label var GovConstr  "23 Construcción"
	label var GovManuf   "31-33 Industrias manufactureras"
	label var GovMayor   "43 Comercio al por mayor"
	label var GovMenor   "46 Comercio al por menor"
	label var GovTrans   "48-49 Transportes, correos y almacenamiento"
	label var GovInfo    "51 Información en medios masivos"
	label var GovFin     "52 Servicios financieros y de seguros"
	label var GovInmob   "53 Servicios inmobiliarios y de alquiler de bienes muebles e intangibles"
	label var GovProf    "54 Servicios profesionales, científicos y técnicos"
	label var GovCorp    "55 Corporativos"
	label var GovApoyo   "56 Servicios de apoyo a los negocios y manejo de residuos, y servicios de remediación"
	label var GovEdu     "61 Servicios educativos"
	label var GovSalud   "62 Servicios de salud y de asistencia social"
	label var GovRecrea  "71 Servicios de esparcimiento culturales y deportivos, y otros servicios recreativos"
	label var GovAloj    "72 Servicios de alojamiento temporal y de preparación de alimentos y bebidas"
	label var GovOtros   "81 Otros servicios excepto actividades gubernamentales"
	label var GovLegis   "93 Actividades legislativas, gubernamentales, de impartición de justicia y de organismos internacionales y extraterritoriales"
	label var GovCompExt "P.721 Compras directas en el exterior por residentes"

	**  6.3 Dar formato a variables **
	foreach k of varlist ConGob - GovCompExt {
		replace `k' = `k'*1000000
		replace `k' = 0 if `k' == .
	}

	**  6.4 Time Series **
	rename periodo anio
	label var anio "anio"

	**  6.5 Guardar **
	compress
	tempfile GovCons
	save `GovCons'


	***
	*** 7.1.1 PIB por actividad económica (Parte 1)
	***
	run "`c(sysdir_site)'/AccesoBIE.do" ///
	"779804 779805 779806 779807 779808 779809 779810 779811 779812 779813 779814 779815 779816 779817 779818 779819 779820 779821 779822 779823 779824 779825 779826 779827 779828 779829 779830 779831 779832 779833 779834 779835 779836 779837 779838 779839 779840 779841 779842 779843 779844 779845 779846 779847 779848 779849 779850 779851 779852 779853 779854 779855 779856 779857 779858 779859 779860 779861 779862 779863 779864 779865 779866 779867 779868 779869 779870 779871 779872 779873" ///
	"PIB_T ImpProd_T ValAg_T Agr_T Agr111_T Agr1111 Agr1112 Agr1113 Agr1114 Agr1119 Agr112_T Agr1121 Agr1122 Agr1123 Agr1124 Agr1125 Agr1129 Agr113_T Agr1131 Agr1132 Agr1133 Agr114_T Agr1141 Agr1142 Agr115_T Agr1151 Agr1152 Agr1153 Min_T Min211_T Min2111 Min212_T Min2121 Min2122 Min2123 Min213_T Min2131 Ener_T Ener221_T Ener2211 Ener2212 Ener2213 Const_T Const236_T Const2361 Const2362 Const237_T Const2371 Const2372 Const2373 Const2379 Const238_T Const2381 Const2382 Const2383 Const2389 Manu_T Manu311_T Manu3111 Manu3112 Manu3113 Manu3114 Manu3115 Manu3116 Manu3117 Manu3118 Manu3119 Manu312_T Manu3121 Manu3122"

    ** 7.1.2 Label variables **
	label var PIB_T     "Producto Interno Bruto"
	label var ImpProd_T "Impuestos sobre los productos, netos"
	label var ValAg_T   "Valor agregado bruto"

    /* Sector 11: Agricultura, cría y explotación, aprovechamiento forestal, pesca y caza */
	label var Agr_T     "Total sector 11"

    /* Subsector 111: Agricultura */
	label var Agr111_T  "Total subsector 111: Agricultura"
	label var Agr1111   "1111 Cultivo de semillas oleaginosas, leguminosas y cereales"
	label var Agr1112   "1112 Cultivo de hortalizas"
	label var Agr1113   "1113 Cultivo de frutales y nueces"
	label var Agr1114   "1114 Cultivo en invernaderos y floricultura"
	label var Agr1119   "1119 Otros cultivos"

    /* Subsector 112: Cría y explotación de animales */
	label var Agr112_T  "Total subsector 112: Cría y explotación de animales"
	label var Agr1121   "1121 Explotación de bovinos"
	label var Agr1122   "1122 Explotación de porcinos"
	label var Agr1123   "1123 Explotación avícola"
	label var Agr1124   "1124 Explotación de ovinos y caprinos"
	label var Agr1125   "1125 Acuicultura"
	label var Agr1129   "1129 Explotación de otros animales"

    /* Subsector 113: Aprovechamiento forestal */
	label var Agr113_T  "Total subsector 113: Aprovechamiento forestal"
	label var Agr1131   "1131 Silvicultura"
	label var Agr1132   "1132 Viveros y recolección de productos forestales"
	label var Agr1133   "1133 Tala de árboles"

    /* Subsector 114: Pesca, caza y captura */
	label var Agr114_T  "Total subsector 114: Pesca, caza y captura"
	label var Agr1141   "1141 Pesca"
	label var Agr1142   "1142 Caza y captura"

    /* Subsector 115: Servicios relacionados con actividades agropecuarias y forestales */
	label var Agr115_T  "Total subsector 115: Servicios agropecuarios y forestales"
	label var Agr1151   "1151 Servicios relacionados con la agricultura"
	label var Agr1152   "1152 Servicios relacionados con la cría y explotación de animales"
	label var Agr1153   "1153 Servicios relacionados con el aprovechamiento forestal"

    /* Sector 21: Minería */
	label var Min_T      "Total sector 21"
	label var Min211_T   "Total sector 211: Extracción de petróleo y gas"
	label var Min2111    "2111 Extracción de petróleo y gas"
	label var Min212_T   "Total subsector 212: Minería de minerales metálicos y no metálicos, excepto petróleo y gas"
	label var Min2121    "2121 Minería de carbón mineral"
	label var Min2122    "2122 Minería de minerales metálicos"
	label var Min2123    "2123 Minería de minerales no metálicos"
	label var Min213_T   "Total sector 213: Servicios relacionados con la minería"
	label var Min2131    "2131 Servicios relacionados con la minería"

    /* Sector 22: Energía, agua y gas */
	label var Ener_T     "Total sector 22"
	label var Ener221_T  "Total sector 221: Generación, transmisión, distribución y comercialización de energía, agua y gas"
	label var Ener2211   "2211 Generación, transmisión, distribución y comercialización de energía eléctrica"
	label var Ener2212   "2212 Suministro de gas natural por ductos"
	label var Ener2213   "2213 Captación, tratamiento y suministro de agua"

    /* Sector 23: Construcción */
	label var Const_T    "Total sector 23"
    /* Subsector 236: Edificación */
	label var Const236_T "Total subsector 236: Edificación"
	label var Const2361  "2361 Edificación residencial"
	label var Const2362  "2362 Edificación no residencial"
    /* Subsector 237: Obras de ingeniería civil */
	label var Const237_T "Total subsector 237: Construcción de obras de ingeniería civil"
	label var Const2371  "2371 Obras para suministro de agua, petróleo, gas, energía y telecomunicaciones"
	label var Const2372  "2372 División de terrenos y obras de urbanización"
	label var Const2373  "2373 Construcción de vías de comunicación"
	label var Const2379  "2379 Otras construcciones de ingeniería civil"
    /* Subsector 238: Trabajos especializados para la construcción */
	label var Const238_T "Total subsector 238: Trabajos especializados para la construcción"
	label var Const2381  "2381 Cimentaciones, montaje de estructuras prefabricadas y trabajos en exteriores"
	label var Const2382  "2382 Instalaciones y equipamiento en construcciones"
	label var Const2383  "2383 Trabajos de acabados en edificaciones"
	label var Const2389  "2389 Otros trabajos especializados para la construcción"

	/* Sector 31-33: Industrias manufacturer*/
	label var Manu_T     "Total sector 31-33: Industrias manufactureras"
    /* Subsector 311: Industria alimentaria */
	label var Manu311_T  "Total subsector 311: Industria alimentaria"
	label var Manu3111   "3111 Elaboración de alimentos para animales"
	label var Manu3112   "3112 Molienda de granos y semillas, y obtención de aceites y grasas"
	label var Manu3113   "3113 Elaboración de azúcares, chocolates, dulces y similares"
	label var Manu3114   "3114 Conservación de frutas, verduras, guisos y otros alimentos preparados"
	label var Manu3115   "3115 Elaboración de productos lácteos"
	label var Manu3116   "3116 Matanza, empacado y procesamiento de carne"
	label var Manu3117   "3117 Preparación y envasado de pescados y mariscos"
	label var Manu3118   "3118 Elaboración de productos de panadería y tortillas"
	label var Manu3119   "3119 Otras industrias alimentarias"

    /* Subsector 312: Industria de las bebidas y del tabaco */
	label var Manu312_T  "Total subsector 312: Industria de bebidas y tabaco"
	label var Manu3121   "3121 Industria de las bebidas"
	label var Manu3122   "3122 Industria del tabaco"

	**  7.1.3 Dar formato a variables **
	foreach k of varlist PIB_T - Manu3122 {
		replace `k' = `k'*1000000
		replace `k' = 0 if `k' == .
	}

	**  7.1.4 Time Series **
	rename periodo anio
	label var anio "anio"

	**  7.1.5 Guardar **
	compress
	tempfile PIBAE1
	save `PIBAE1'


	***
	*** 7.2.1 PIB por actividad económica (Parte 2)
	***
	run "`c(sysdir_site)'/AccesoBIE.do" ///
	"779874 779875 779876 779877 779878 779879 779880 779881 779882 779883 779884 779885 779886 779887 779888 779889 779890 779891 779892 779893 779894 779895 779896 779897 779898 779899 779900 779901 779902 779903 779904 779905 779906 779907 779908 779909 779910 779911 779912 779913 779914 779915 779916 779917 779918 779919 779920 779921 779922 779923 779924 779925 779926 779927 779928 779929 779930 779931 779932 779933 779934 779935 779936 779937 779938 779939 779940 779941 779942 779943" ///
	"Manu313_T Manu3131 Manu3132 Manu3133 Manu314_T Manu3141 Manu3149 Manu315_T Manu3151 Manu3152 Manu3159 Manu316_T Manu3161 Manu3162 Manu3169 Manu321_T Manu3211 Manu3212 Manu3219 Manu322_T Manu3221 Manu3222 Manu323_T Manu3231 Manu324_T Manu3241 Manu325_T Manu3251 Manu3252 Manu3253 Manu3254 Manu3255 Manu3256 Manu3259 Manu326_T Manu3261 Manu3262 Manu327_T Manu3271 Manu3272 Manu3273 Manu3274 Manu3279 Manu331_T Manu3311 Manu3312 Manu3313 Manu3314 Manu3315 Manu332_T Manu3321 Manu3322 Manu3323 Manu3324 Manu3325 Manu3326 Manu3327 Manu3328 Manu3329 Manu333_T Manu3331 Manu3332 Manu3333 Manu3334 Manu3335 Manu3336 Manu3339 Manu334_T Manu3341 Manu3342"

	** 7.2.2 Label variables **

    /* Subsector 313: Insumos textiles y acabado */
	label var Manu313_T  "Total subsector 313: Insumos textiles y acabado"
	label var Manu3131   "3131 Preparación e hilado de fibras y fabricación de hilos"
	label var Manu3132   "3132 Fabricación de telas"
	label var Manu3133   "3133 Acabado de productos textiles y fabricación de telas recubiertas"

    /* Subsector 314: Productos textiles (excepto prendas) */
	label var Manu314_T  "Total subsector 314: Productos textiles (excepto prendas)"
	label var Manu3141   "3141 Confección de alfombras, blancos y similares"
	label var Manu3149   "3149 Otros productos textiles, excepto prendas"

    /* Subsector 315: Prendas de vestir */
	label var Manu315_T  "Total subsector 315: Prendas de vestir"
	label var Manu3151   "3151 Prendas de vestir de tejido de punto"
	label var Manu3152   "3152 Confección de prendas de vestir"
	label var Manu3159   "3159 Accesorios de vestir y otras prendas no clasificadas"

    /* Subsector 316: Cuero y productos relacionados */
	label var Manu316_T  "Total subsector 316: Curtido, acabado y productos de cuero"
	label var Manu3161   "3161 Curtido y acabado de cuero y piel"
	label var Manu3162   "3162 Fabricación de calzado"
	label var Manu3169   "3169 Otros productos de cuero y materiales sucedáneos"

    /* Subsector 321: Industria de la madera */
	label var Manu321_T  "Total subsector 321: Industria de la madera"
	label var Manu3211   "3211 Aserrado y conservación de la madera"
	label var Manu3212   "3212 Laminados y aglutinados de madera"
	label var Manu3219   "3219 Otros productos de madera"

    /* Subsector 322: Industria del papel */
	label var Manu322_T  "Total subsector 322: Industria del papel"
	label var Manu3221   "3221 Fabricación de pulpa, papel y cartón"
	label var Manu3222   "3222 Productos de cartón y papel"

    /* Subsector 323: Impresión e industrias conexas */
	label var Manu323_T  "Total subsector 323: Impresión e industrias conexas"
	label var Manu3231   "3231 Impresión e industrias conexas"

    /* Subsector 324: Productos derivados del petróleo y del carbón */
	label var Manu324_T  "Total subsector 324: Productos derivados del petróleo y del carbón"
	label var Manu3241   "3241 Productos derivados del petróleo y del carbón"

    /* Subsector 325: Industria química */
	label var Manu325_T  "Total subsector 325: Industria química"
	label var Manu3251   "3251 Productos químicos básicos"
	label var Manu3252   "3252 Resinas, hules y fibras químicas"
	label var Manu3253   "3253 Fertilizantes, pesticidas y agroquímicos"
	label var Manu3254   "3254 Productos farmacéuticos"
	label var Manu3255   "3255 Pinturas, recubrimientos y adhesivos"
	label var Manu3256   "3256 Jabones, limpiadores y tocador"
	label var Manu3259   "3259 Otros productos químicos"

    /* Subsector 326: Plástico y hule */
	label var Manu326_T  "Total subsector 326: Industria del plástico y del hule"
	label var Manu3261   "3261 Productos de plástico"
	label var Manu3262   "3262 Productos de hule"

    /* Subsector 327: Productos a base de minerales no metálicos */
	label var Manu327_T  "Total subsector 327: Productos a base de minerales no metálicos"
	label var Manu3271   "3271 Productos de arcilla y minerales refractarios"
	label var Manu3272   "3272 Productos de vidrio"
	label var Manu3273   "3273 Cemento y productos de concreto"
	label var Manu3274   "3274 Cal, yeso y productos de yeso"
	label var Manu3279   "3279 Otros productos a base de minerales no metálicos"

    /* Subsector 331: Industrias metálicas básicas */
	label var Manu331_T  "Total subsector 331: Industrias metálicas básicas"
	label var Manu3311   "3311 Industria básica del hierro y del acero"
	label var Manu3312   "3312 Productos de hierro y acero"
	label var Manu3313   "3313 Industria básica del aluminio"
	label var Manu3314   "3314 Metales no ferrosos, excepto aluminio"
	label var Manu3315   "3315 Moldeo por fundición de piezas metálicas"

    /* Subsector 332: Productos metálicos */
	label var Manu332_T  "Total subsector 332: Productos metálicos"
	label var Manu3321   "3321 Productos metálicos forjados y troquelados"
	label var Manu3322   "3322 Herramientas de mano y utensilios metálicos"
	label var Manu3323   "3323 Estructuras metálicas y productos de herrería"
	label var Manu3324   "3324 Calderas, tanques y envases metálicos"
	label var Manu3325   "3325 Herrajes y cerraduras"
	label var Manu3326   "3326 Productos de alambre y resortes"
	label var Manu3327   "3327 Maquinado de piezas y fabricación de tornillos"
	label var Manu3328   "3328 Recubrimientos y terminados metálicos"
	label var Manu3329   "3329 Otros productos metálicos"

    /* Subsector 333: Maquinaria y equipo */
	label var Manu333_T  "Total subsector 333: Maquinaria y equipo"
	label var Manu3331   "3331 Maquinaria agropecuaria, para construcción y extractiva"
	label var Manu3332   "3332 Maquinaria para industrias manufactureras, except. metalmecánica"
	label var Manu3333   "3333 Maquinaria para comercio y servicios"
	label var Manu3334   "3334 Equipo de aire acondicionado, calefacción y refrigeración"
	label var Manu3335   "3335 Maquinaria para la industria metalmecánica"
	label var Manu3336   "3336 Motores, turbinas y transmisiones"
	label var Manu3339   "3339 Otra maquinaria y equipo para la industria en general"

    /* Subsector 334: Equipo electrónico (computación, comunicación, medición, etc.) */
	label var Manu334_T  "Total subsector 334: Equipo electrónico"
	label var Manu3341   "3341 Computadoras y equipo periférico"
	label var Manu3342   "3342 Equipo de comunicación"

	**  7.2.3 Dar formato a variables **
	foreach k of varlist Manu313_T - Manu3342 {
		replace `k' = `k'*1000000
		replace `k' = 0 if `k' == .
	}

	**  7.2.4 Time Series **
	rename periodo anio
	label var anio "anio"

	**  7.2.5 Guardar **
	compress
	tempfile PIBAE2
	save `PIBAE2'


	***
	*** 7.3.1 PIB por actividad económica (Parte 3)
	***
	run "`c(sysdir_site)'/AccesoBIE.do" ///
	"779944 779945 779946 779947 779948 779949 779950 779951 779952 779953 779954 779955 779956 779957 779958 779959 779960 779961 779962 779963 779964 779965 779966 779967 779968 779969 779970 779971 779972 779973 779974 779975 779976 779977 779978 779979 779980 779981 779982 779983 779984 779985 779986 779987 779988 779989 779990 779991 779992 779993 779994 779995 779996 779997" ///
	"Manu3343 Manu3344 Manu3345 Manu3346 Manu335_T Manu3351 Manu3352 Manu3353 Manu3359 Manu336_T Manu3361 Manu3362 Manu3363 Manu3364 Manu3365 Manu3366 Manu3369 Manu337_T Manu3371 Manu3372 Manu3379 Manu339_T Manu3391 Manu3399 ComMayor_T ComMayor430_T ComMayor4300 ComMenor_T ComMenor460_T ComMenor4600 Trans_T TransAereo_T TransAereoReg TransAereoNoReg TransFerro_T TransFerro TransAgua_T TransMaritimo TransAguasInt AutoCarga_T AutoCargaGen AutoCargaEsp TransTerrestre_T TransTer_Urb TransTer_Foraneo TaxiLimus TransEscolar AutobusChofer TransTerOtro TransDuctos_T TransDuct_Petro TransDuct_Gas TransDuct_Otros TransTur_T"

	** 7.3.2 Label variables **

	/* Subsector 334: Equipo electrónico (computación, comunicación, medición, etc.) */
	label var Manu3343   "3343 Equipo de audio y video"
	label var Manu3344   "3344 Componentes electrónicos"
	label var Manu3345   "3345 Instrumentos de medición, control, navegación y equipo médico"
	label var Manu3346   "3346 Medios magnéticos y ópticos"

    /* Subsector 335: Accesorios y aparatos eléctricos */
	label var Manu335_T  "Total subsector 335: Accesorios, aparatos eléctricos y equipo de generación de energía"
	label var Manu3351   "3351 Accesorios de iluminación"
	label var Manu3352   "3352 Aparatos eléctricos de uso doméstico"
	label var Manu3353   "3353 Equipo de generación y distribución de energía eléctrica"
	label var Manu3359   "3359 Otros equipos y accesorios eléctricos"

    /* Subsector 336: Equipo de transporte */
	label var Manu336_T  "Total subsector 336: Equipo de transporte"
	label var Manu3361   "3361 Fabricación de automóviles y camiones"
	label var Manu3362   "3362 Carrocerías y remolques"
	label var Manu3363   "3363 Partes para vehículos automotores"
	label var Manu3364   "3364 Equipo aeroespacial"
	label var Manu3365   "3365 Equipo ferroviario"
	label var Manu3366   "3366 Embarcaciones"
	label var Manu3369   "3369 Otro equipo de transporte"

    /* Subsector 337: Muebles, colchones y persianas */
	label var Manu337_T  "Total subsector 337: Muebles, colchones y persianas"
	label var Manu3371   "3371 Muebles, excepto de oficina y estantería"
	label var Manu3372   "3372 Muebles de oficina y estantería"
	label var Manu3379   "3379 Colchones, persianas y cortineros"

    /* Subsector 339: Otras industrias manufactureras */
	label var Manu339_T  "Total subsector 339: Otras industrias manufactureras"
	label var Manu3391   "3391 Equipo no electrónico y material desechable para uso médico, dental y de laboratorio, y artículos oftálmicos"
	label var Manu3399   "3399 Otras industrias manufactureras"

    /* Sector 43: Comercio al por mayor */
	label var ComMayor_T      "Total sector 43: Comercio al por mayor"
	label var ComMayor430_T   "Total subsector 430: Comercio al por mayor"
	label var ComMayor4300    "4300 Comercio al por mayor"

    /* Sector 46: Comercio al por menor */
	label var ComMenor_T      "Total sector 46: Comercio al por menor"
	label var ComMenor460_T   "Total subsector 460: Comercio al por menor"
	label var ComMenor4600    "4600 Comercio al por menor"

    /* Sector 48-49: Transportes, correos y almacenamiento */
	label var Trans_T         "Total sector 48-49: Transportes, correos y almacenamiento"

    /* 481 Transporte aéreo */
	label var TransAereo_T    "Total subsector 481: Transporte aéreo"
	label var TransAereoReg   "4811 Transporte aéreo regular"
	label var TransAereoNoReg "4812 Transporte aéreo no regular"

    /* 482 Transporte por ferrocarril */
	label var TransFerro_T    "Total subsector 482: Transporte por ferrocarril"
	label var TransFerro      "4821 Transporte por ferrocarril"

    /* 483 Transporte por agua */
	label var TransAgua_T     "Total subsector 483: Transporte por agua"
	label var TransMaritimo   "4831 Transporte marítimo"
	label var TransAguasInt   "4832 Transporte por aguas interiores"

    /* 484 Autotransporte de carga */
	label var AutoCarga_T     "Total subsector 484: Autotransporte de carga"
	label var AutoCargaGen    "4841 Autotransporte de carga general"
	label var AutoCargaEsp    "4842 Autotransporte de carga especializado"

    /* 485 Transporte terrestre de pasajeros, excepto por ferrocarril */
	label var TransTerrestre_T "Total subsector 485: Transporte terrestre de pasajeros"
	label var TransTer_Urb     "4851 Transporte colectivo urbano y suburbano de ruta fija"
	label var TransTer_Foraneo "4852 Transporte colectivo foráneo de ruta fija"
	label var TaxiLimus       "4853 Servicio de taxis y limusinas"
	label var TransEscolar     "4854 Transporte escolar y de personal"
	label var AutobusChofer    "4855 Alquiler de autobuses con chofer"
	label var TransTerOtro     "4859 Otro transporte terrestre de pasajeros"

    /* 486 Transporte por ductos */
	label var TransDuctos_T   "Total subsector 486: Transporte por ductos"
	label var TransDuct_Petro "4861 Transporte de petróleo crudo por ductos"
	label var TransDuct_Gas   "4862 Transporte de gas natural por ductos"
	label var TransDuct_Otros "4869 Transporte por ductos de otros productos"

    /* 487 Transporte turístico */
	label var TransTur_T      "Total subsector 487: Transporte turístico"

	** 7.3.3 Dar formato a variables **
	foreach k of varlist Manu3343 - TransTur_T {
		replace `k' = `k'*1000000
		replace `k' = 0 if `k' == .
	}

	** 7.3.4 Time Series **
	rename periodo anio
	label var anio "anio"

	** 7.3.5 Guardar **
	compress
	tempfile PIBAE3
	save `PIBAE3'


	***
	*** 7.4.1 PIB por actividad económica (Parte 4)
	***
	run "`c(sysdir_site)'/AccesoBIE.do" ///
	"779998 779999 780000 780001 780002 780003 780004 780005 780006 780007 780008 780009 780010 780011 780012 780013 780014 780015 780016 780017 780018 780019 780020 780021 780022 780023 780024 780025 780026 780027 780028 780029 780030 780031 780032 780033 780034 780035 780036 780037 780038 780039 780040 780041 780042 780043 780044 780045 780046 780047 780048 780049 780050 780051 780052 780053 780054 780055 780056 780057 780058 780059 780060 780061 780062 780063 780064 780065 780066 780067 780068 780069 780070 780071 780072 780073 780074 780075 780076 780077 780078 780079 780080 780081 780082" ///
	"TransTurTierra TransTurAgua TransTurOtro ServTrans_T ServTransAereo ServTransFerro ServTransAgua ServTransCarretera ServTransInter ServTransOtros ServPost_T ServPost ServMensaj_T ServMensajFor ServMensajLoc ServAlmac_T ServAlmac Medios_T Medios511_T Medios5111 Medios5112 Medios512_T Medios5121 Medios5122 Medios515_T Medios5151 Medios5152 Medios517_T Medios5173 Medios5174 Medios5179 Medios518_T Medios5182 Medios519_T Medios5191 FinSeg_T Fin521_T Fin5211 Fin522_T Fin5221 Fin5222 Fin5223 Fin5224 Fin5225 Fin523_T Fin5231 Fin5232 Fin5239 Fin524_T Fin5241 Fin5242 Fin525_T Fin5251 Fin5252 Inmob_T Inmob531_T Inmob5311 Inmob5312 Inmob5313 Inmob532_T Inmob5321 Inmob5322 Inmob5323 Inmob5324 Inmob533_T Inmob5331 Prof_T Prof541_T Prof5411 Prof5412 Prof5413 Prof5414 Prof5415 Prof5416 Prof5417 Prof5418 Prof5419 Corp_T Corp551_T Corp5511 Apoyo_T Apoyo561_T Apoyo5611 Apoyo5612 Apoyo5613"

	** 7.4.2 Label variables **

	/* 487 Transporte turístico */	
	label var TransTurTierra  "4871 Transporte turístico por tierra"
	label var TransTurAgua    "4872 Transporte turístico por agua"
	label var TransTurOtro    "4879 Otro transporte turístico"

    /* 488 Servicios relacionados con el transporte */
	label var ServTrans_T     "Total subsector 488: Servicios relacionados con el transporte"
	label var ServTransAereo  "4881 Servicios relacionados con el transporte aéreo"
	label var ServTransFerro  "4882 Servicios relacionados con el transporte por ferrocarril"
	label var ServTransAgua   "4883 Servicios relacionados con el transporte por agua"
	label var ServTransCarre  "4884 Servicios relacionados con el transporte por carretera"
	label var ServTransInter  "4885 Servicios de intermediación para el transporte de carga"
	label var ServTransOtros  "4889 Otros servicios relacionados con el transporte"

    /* 491 Servicios postales */
	label var ServPost_T      "Total subsector 491: Servicios postales"
	label var ServPost        "4911 Servicios postales"

    /* 492 Servicios de mensajería y paquetería */
	label var ServMensaj_T    "Total subsector 492: Servicios de mensajería y paquetería"
	label var ServMensajFor   "4921 Servicios de mensajería y paquetería foránea"
	label var ServMensajLoc   "4922 Servicios de mensajería y paquetería local"

    /* 493 Servicios de almacenamiento */
	label var ServAlmac_T     "Total subsector 493: Servicios de almacenamiento"
	label var ServAlmac       "4931 Servicios de almacenamiento"

    /* Sector 51: Información en medios masivos */
	label var Medios_T      "Total sector 51"
    /* Subsector 511 */
	label var Medios511_T   "Total subsector 511: Edición de periódicos, revistas, libros, software, etc."
	label var Medios5111    "5111 Edición de periódicos, revistas, libros y similares"
	label var Medios5112    "5112 Edición de software y reproducción integrada"
    /* Subsector 512 */
	label var Medios512_T   "Total subsector 512: Industria fílmica y del video, e industria del sonido"
	label var Medios5121    "5121 Industria fílmica y del video"
	label var Medios5122    "5122 Industria del sonido"
    /* Subsector 515 */
	label var Medios515_T   "Total subsector 515: Radio y televisión"
	label var Medios5151    "5151 Transmisión de programas de radio y televisión"
	label var Medios5152    "5152 Producción de programación para cable/satélite"
    /* Subsector 517 */
	label var Medios517_T   "Total subsector 517: Telecomunicaciones"
	label var Medios5173    "5173 Operadores alámbricos e inalámbricos"
	label var Medios5174    "5174 Operadores vía satélite"
	label var Medios5179    "5179 Otros servicios de telecomunicaciones"
    /* Subsector 518 */
	label var Medios518_T   "Total subsector 518: Procesamiento electrónico de información, hospedaje, etc."
	label var Medios5182    "5182 Procesamiento electrónico, hospedaje, y otros"
    /* Subsector 519 */
	label var Medios519_T   "Total subsector 519: Otros servicios de información"
	label var Medios5191    "5191 Otros servicios de información"

    /* Sector 52: Servicios financieros y de seguros */
	label var FinSeg_T      "Total sector 52"
    /* Subsector 521 */
	label var Fin521_T      "Total subsector 521: Banca central"
	label var Fin5211       "5211 Banca central"
    /* Subsector 522 */
	label var Fin522_T      "Total subsector 522: Instituciones de intermediación no bursátil"
	label var Fin5221       "5221 Banca múltiple"
	label var Fin5222       "5222 Instituciones de fomento económico"
	label var Fin5223       "5223 Uniones de crédito e instituciones de ahorro"
	label var Fin5224       "5224 Otras instituciones de intermediación no bursátil"
	label var Fin5225       "5225 Servicios relacionados con la intermediación"
    /* Subsector 523 */
	label var Fin523_T      "Total subsector 523: Actividades bursátiles y cambiarias"
	label var Fin5231       "5231 Casas de bolsa, cambio y centros cambiarios"
	label var Fin5232       "5232 Bolsa de valores"
	label var Fin5239       "5239 Asesoría en inversiones y otros"
    /* Subsector 524 */
	label var Fin524_T      "Total subsector 524: Compañías de seguros, fianzas y administración de fondos"
	label var Fin5241       "5241 Instituciones de seguros y fianzas"
	label var Fin5242       "5242 Servicios relacionados con seguros y fianzas"
    /* Subsector 525 */
	label var Fin525_T      "Total subsector 525: Sociedades de inversión"
	label var Fin5251       "5251 Sociedades de inversión especializadas en fondos para el retiro"
	label var Fin5252       "5252 Fondos de inversión"

    /* Sector 53: Servicios inmobiliarios y de alquiler de bienes muebles e intangibles */
	label var Inmob_T       "Total sector 53"
    /* Subsector 531 */
	label var Inmob531_T    "Total subsector 531: Servicios inmobiliarios"
	label var Inmob5311     "5311 Alquiler sin intermediación de bienes raíces"
	label var Inmob5312     "5312 Inmob5312 y corredores"
	label var Inmob5313     "5313 Servicios relacionados inmobiliarios"
    /* Subsector 532 */
	label var Inmob532_T    "Total subsector 532: Alquiler de bienes muebles"
	label var Inmob5321     "5321 Alquiler de automóviles y otros transportes terrestres"
	label var Inmob5322     "5322 Alquiler de artículos para el hogar y personales"
	label var Inmob5323     "5323 Centros generales de alquiler"
	label var Inmob5324     "5324 Alquiler de maquinaria y equipo"
    /* Subsector 533 */
	label var Inmob533_T    "Total subsector 533: Servicios de alquiler de marcas, patentes y franquicias"
	label var Inmob5331     "5331 Servicios de alquiler de marcas, patentes y franquicias"

    /* Sector 54: Servicios profesionales, científicos y técnicos */
	label var Prof_T        "Total sector 54"
    /* Subsector 541 */
	label var Prof541_T     "Total subsector 541: Servicios profesionales, científicos y técnicos"
	label var Prof5411      "5411 Servicios legales"
	label var Prof5412      "5412 Servicios de contabilidad y auditoría"
	label var Prof5413      "5413 Servicios de arquitectura, ingeniería y afines"
	label var Prof5414      "5414 Diseño especializado"
	label var Prof5415      "5415 Servicios de diseño de sistemas de cómputo"
	label var Prof5416      "5416 Consultoría administrativa, científica y técnica"
	label var Prof5417      "5417 Investigación científica y desarrollo"
	label var Prof5418      "5418 Servicios de publicidad y afines"
	label var Prof5419      "5419 Otros servicios profesionales, científicos y técnicos"

    /* Sector 55: Corporativos */
	label var Corp_T        "Total sector 55"
    /* Subsector 551 */
	label var Corp551_T     "Total subsector 551: Corporativos"
	label var Corp5511      "5511 Corporativos"

    /* Sector 56: Servicios de apoyo a los negocios y manejo de residuos, y servicios de remediación */
	label var Apoyo_T       "Total sector 56"
    /* Subsector 561 */
	label var Apoyo561_T    "Total subsector 561: Servicios de apoyo a los negocios"
	label var Apoyo5611     "5611 Administración de negocios"
	label var Apoyo5612     "5612 Servicios combinados de apoyo en instalaciones"
	label var Apoyo5613     "5613 Servicios de empleo"

	** 7.4.3 Dar formato a variables **
	foreach k of varlist TransTurTierra - Apoyo5613 {
		replace `k' = `k'*1000000
		replace `k' = 0 if `k' == .
	}

	** 7.4.4 Time Series **
	rename periodo anio
	label var anio "anio"

	** 7.4.5 Guardar **
	compress
	tempfile PIBAE4
	save `PIBAE4'


	***
	*** 7.5.1 PIB por actividad económica (Parte 5)
	***
	run "`c(sysdir_site)'/AccesoBIE.do" ///
	"780083 780084 780085 780086 780087 780088 780089 780090 780091 780092 780093 780094 780095 780096 780097 780098 780099 780100 780101 780102 780103 780104 780105 780106 780107 780108 780109 780110 780111 780112 780113 780114 780115 780116 780117 780118 780119 780120 780121 780122 780123 780124 780125 780126 780127 780128 780129 780130 780131 780132 780133 780134 780135 780136 780137 780138 780139 780140 780141 780142 780143 780144 780145 780146 780147 780148 780149 780150 780151 780152 780153 780154 780155 780156 780157 780158 780159 780160 780161 780162 780163 780164 780165 780166 780167 780168 780169 780170 780171 780172 780173 780174" ///	
	"Apoyo5614 Apoyo5615 Apoyo5616 Apoyo5617 Apoyo5619 Apoyo562_T Apoyo5621 Apoyo5622 Apoyo5629 Edu_T Edu611_T Edu6111 Edu6112 Edu6113 Edu6114 Edu6115 Edu6116 Edu6117 Salud_T Salud621_T Salud6211 Salud6212 Salud6213 Salud6214 Salud6215 Salud6216 Salud6219 Salud622_T Salud6221 Salud6222 Salud6223 Salud623_T Salud6231 Salud6232 Salud6233 Salud6239 Salud624_T Salud6241 Salud6242 Salud6243 Salud6244 Recre_T Recre711_T Recre7111 Recre7112 Recre7113 Recre7114 Recre7115 Recre712_T Recre7121 Recre713_T Recre7131 Recre7132 Recre7139 AloPrep_T AloPrep721_T AloPrep7211 AloPrep7212 AloPrep7213 AloPrep722_T AloPrep7223 AloPrep7224 AloPrep7225 Otros_T Otros811_T Otros8111 Otros8112 Otros8113 Otros8114 Otros812_T Otros8121 Otros8122 Otros8123 Otros8124 Otros8129 Otros813_T Otros8131 Otros8132 Otros814_T Otros8141 Legis_T Legis931_T Legis9311 Legis9312 Legis9313 Legis9314 Legis9315 Legis9316 Legis9317 Legis9318 Legis932_T Legis9321"

	** 7.5.2 Label variables **

	/* Sector 56: Servicios de apoyo a los negocios y manejo de residuos, y servicios de remediación */
	label var Apoyo5614     "5614 Apoyo secretarial, fotocopiado, cobranza, etc."
	label var Apoyo5615     "5615 Agencias de viajes y reservaciones"
	label var Apoyo5616     "5616 Servicios de investigación, protección y seguridad"
	label var Apoyo5617     "5617 Servicios de limpieza"
	label var Apoyo5619     "5619 Otros servicios de apoyo a los negocios"
    /* Subsector 562 */
	label var Apoyo562_T    "Total subsector 562: Manejo de residuos y desechos, y remediación"
	label var Apoyo5621     "5621 Recolección de residuos"
	label var Apoyo5622     "5622 Tratamiento y disposición final de residuos"
	label var Apoyo5629     "5629 Remediación, recuperación y otros"

    /* Sector 61: Servicios educativos */
	label var Edu_T         "Total sector 61"
    /* Subsector 611 */
	label var Edu611_T      "Total subsector 611: Servicios educativos"
	label var Edu6111       "6111 Escuelas de educación básica, media y especiales"
	label var Edu6112       "6112 Escuelas de educación técnica superior"
	label var Edu6113       "6113 Escuelas de educación superior"
	label var Edu6114       "6114 Escuelas comerciales, de computación y capacitación para ejecutivos"
	label var Edu6115       "6115 Escuelas de oficios"
	label var Edu6116       "6116 Otros servicios educativos"
	label var Edu6117       "6117 Servicios de apoyo a la educación"

    /* Sector 62: Servicios de salud y de asistencia social */
	label var Salud_T       "Total sector 62"
    /* Subsector 621 */
	label var Salud621_T    "Total subsector 621: Servicios médicos de consulta externa y afines"
	label var Salud6211     "6211 Consultorios médicos"
	label var Salud6212     "6212 Consultorios dentales"
	label var Salud6213     "6213 Otros consultorios para el cuidado de la salud"
	label var Salud6214     "6214 Centros de atención sin hospitalización"
	label var Salud6215     "6215 Laboratorios médicos y de diagnóstico"
	label var Salud6216     "6216 Servicios de enfermería a domicilio"
	label var Salud6219     "6219 Servicios de ambulancias y auxiliares"
    /* Subsector 622 */
	label var Salud622_T    "Total subsector 622: Hospitales"
	label var Salud6221     "6221 Hospitales generales"
	label var Salud6222     "6222 Hospitales psiquiátricos y para adicción"
	label var Salud6223     "6223 Hospitales de otras especialidades"
    /* Subsector 623 */
	label var Salud623_T    "Total subsector 623: Residencias de asistencia social y para cuidado de la salud"
	label var Salud6231     "6231 Residencias con cuidados de enfermería"
	label var Salud6232     "6232 Residencias para cuidado de personas con problemas mentales y adicciones"
	label var Salud6233     "6233 Asilos y residencias para ancianos"
	label var Salud6239     "6239 Orfanatos y otras residencias de asistencia social"
    /* Subsector 624 */
	label var Salud624_T    "Total subsector 624: Otros servicios de asistencia social"
	label var Salud6241     "6241 Servicios de orientación y trabajo social"
	label var Salud6242     "6242 Servicios comunitarios de alimentación, refugio y emergencia"
	label var Salud6243     "6243 Capacitación para el trabajo"
	label var Salud6244     "6244 Guarderías"

    /* Sector 71: Servicios de esparcimiento culturales y deportivos, y otros servicios recreativos */
	label var Recre_T      "Total sector 71"
	label var Recre711_T   "Total subsector 711: Servicios artísticos, culturales y deportivos, y otros servicios relacionados"
	label var Recre7111    "7111 Compañías y grupos de espectáculos artísticos y culturales"
	label var Recre7112    "7112 Deportistas y equipos deportivos profesionales"
	label var Recre7113    "7113 Promotores de espectáculos artísticos, culturales, deportivos y similares"
	label var Recre7114    "7114 Agentes y representantes de artistas, deportistas y similares"
	label var Recre7115    "7115 Artistas, escritores y técnicos independientes"
	label var Recre712_T   "Total subsector 712: Museos, sitios históricos, zoológicos y similares"
	label var Recre7121    "7121 Museos, sitios históricos, zoológicos y similares"
	label var Recre713_T   "Total subsector 713: Servicios de entretenimiento en instalaciones recreativas y otros servicios recreativos"
	label var Recre7131    "7131 Parques con instalaciones recreativas y casas de juegos electrónicos"
	label var Recre7132    "7132 Casinos, loterías y otros juegos de azar"
	label var Recre7139    "7139 Otros servicios recreativos"

    /* Sector 72: Servicios de alojamiento temporal y de preparación de alimentos y bebidas */
	label var AloPrep_T    "Total sector 72"
	label var AloPrep721_T "Total subsector 721: Servicios de alojamiento temporal"
	label var AloPrep7211  "7211 Hoteles, moteles y similares"
	label var AloPrep7212  "7212 Campamentos y albergues recreativos"
	label var AloPrep7213  "7213 Pensiones y casas de huéspedes, y departamentos y casas amueblados con servicios de hotelería"
	label var AloPrep722_T "Total subsector 722: Servicios de preparación de alimentos y bebidas"
	label var AloPrep7223  "7223 Servicios de preparación de alimentos por encargo"
	label var AloPrep7224  "7224 Centros nocturnos, bares, cantinas y similares"
	label var AloPrep7225  "7225 Servicios de preparación de alimentos y bebidas alcohólicas y no alcohólicas"

    /* Sector 81: Otros servicios excepto actividades gubernamentales */
	label var Otros_T      "Total sector 81"
	label var Otros811_T   "Total subsector 811: Servicios de reparación y mantenimiento"
	label var Otros8111    "8111 Reparación y mantenimiento de automóviles y camiones"
	label var Otros8112    "8112 Reparación y mantenimiento de equipo electrónico y de precisión"
	label var Otros8113    "8113 Reparación y mantenimiento de maquinaria y equipo agropecuario, industrial, comercial y de servicios"
	label var Otros8114    "8114 Reparación y mantenimiento de artículos para el hogar y personales"
	label var Otros812_T   "Total subsector 812: Servicios personales"
	label var Otros8121    "8121 Salones, clínicas de belleza, baños públicos y bolerías"
	label var Otros8122    "8122 Lavanderías y tintorerías"
	label var Otros8123    "8123 Servicios funerarios y administración de cementerios"
	label var Otros8124    "8124 Estacionamientos y pensiones para vehículos automotores"
	label var Otros8129    "8129 Servicios de revelado e impresión de fotografías y otros servicios personales"
	label var Otros813_T   "Total subsector 813: Asociaciones y organizaciones"
	label var Otros8131    "8131 Asociaciones y organizaciones comerciales, laborales, profesionales y recreativas"
	label var Otros8132    "8132 Asociaciones y organizaciones religiosas, políticas y civiles"
	label var Otros814_T   "Total subsector 814: Hogares con empleados domésticos"
	label var Otros8141    "8141 Hogares con empleados domésticos"

    /* Sector 93: Actividades legislativas, gubernamentales, de impartición de justicia y de organismos internacionales y extraterritoriales */
	label var Legis_T      "Total sector 93"
	label var Legis931_T   "Total subsector 931: Actividades legislativas, gubernamentales y de impartición de justicia"
	label var Legis9311    "9311 Órganos legislativos"
	label var Legis9312    "9312 Administración pública en general"
	label var Legis9313    "9313 Regulación y fomento del desarrollo económico"
	label var Legis9314    "9314 Impartición de justicia y mantenimiento del orden público"
	label var Legis9315    "9315 Regulación y fomento de actividades para mejorar y preservar el medio ambiente"
	label var Legis9316    "9316 Actividades administrativas de instituciones de bienestar social"
	label var Legis9317    "9317 Relaciones exteriores"
	label var Legis9318    "9318 Actividades de seguridad nacional"
	label var Legis932_T   "Total subsector 932: Organismos internacionales y extraterritoriales"
	label var Legis9321    "9321 Organismos internacionales y extraterritoriales"

	** 7.5.3 Dar formato a variables **
	foreach k of varlist Apoyo5614 - Legis9321 {
		replace `k' = `k'*1000000
		replace `k' = 0 if `k' == .
	}

	** 7.5.4 Time Series **
	rename periodo anio
	label var anio "anio"

	** 7.5.5 Guardar **
	compress
	tempfile PIBAE5
	save `PIBAE5'


	***
	*** 8.1 Consumo privado en bienes y servicios, por actividad económica
	***
	run "`c(sysdir_site)'/AccesoBIE.do" ///
	"725114 725115 725116 725117 725118 725119 725120 725121 725122 725123 725124 725125 725126 725127 725128 725129 725130 725131 725132 725133 725134 725135" ///
	"ConsPriv_T ConsPriv_11 ConsPriv_21 ConsPriv_22 ConsPriv_23 ConsPriv_31_33 ConsPriv_43 ConsPriv_46 ConsPriv_48_49 ConsPriv_51 ConsPriv_52 ConsPriv_53 ConsPriv_54 ConsPriv_55 ConsPriv_56 ConsPriv_61 ConsPriv_62 ConsPriv_71 ConsPriv_72 ConsPriv_81 ConsPriv_93 ConsPriv_P721"

	** 8.2 Label variables **
	label var ConsPriv_T   "Gastos de consumo privado de bienes y servicios - Total"
	label var ConsPriv_11  "11 Agricultura, cría y explotación de animales, aprovechamiento forestal, pesca y caza"
	label var ConsPriv_21  "21 Minería"
	label var ConsPriv_22  "22 Generación, transmisión, distribución y comercialización de energía eléctrica, suministro de agua y de gas natural por ductos"
	label var ConsPriv_23  "23 Construcción"
	label var ConsPriv_31_33 "31-33 Industrias manufactureras"
	label var ConsPriv_43  "43 Comercio al por mayor"
	label var ConsPriv_46  "46 Comercio al por menor"
	label var ConsPriv_48_49 "48-49 Transportes, correos y almacenamiento"
	label var ConsPriv_51  "51 Información en medios masivos"
	label var ConsPriv_52  "52 Servicios financieros y de seguros"
	label var ConsPriv_53  "53 Servicios inmobiliarios y de alquiler de bienes muebles e intangibles"
	label var ConsPriv_54  "54 Servicios profesionales, científicos y técnicos"
	label var ConsPriv_55  "55 Corporativos"
	label var ConsPriv_56  "56 Servicios de apoyo a los negocios y manejo de residuos, y servicios de remediación"
	label var ConsPriv_61  "61 Servicios educativos"
	label var ConsPriv_62  "62 Servicios de salud y de asistencia social"
	label var ConsPriv_71  "71 Servicios de esparcimiento culturales y deportivos, y otros servicios recreativos"
	label var ConsPriv_72  "72 Servicios de alojamiento temporal y de preparación de alimentos y bebidas"
	label var ConsPriv_81  "81 Otros servicios excepto actividades gubernamentales"
	label var ConsPriv_93  "93 Actividades legislativas, gubernamentales, de impartición de justicia y de organismos internacionales y extraterritoriales"
	label var ConsPriv_P721 "P.721 Compras directas en el exterior por residentes:"	

	** 8.3 Dar formato a variables **
	foreach k of varlist ConsPriv_T - ConsPriv_P721 {
		replace `k' = `k'*1000000
		replace `k' = 0 if `k' == .
	}

	** 8.4 Time Series **
	rename periodo anio
	label var anio "anio"

	** 8.5 Guardar **
	compress
	tempfile SecExt
	save `SecExt'

	**/
	*** 9. Ingreso mixto bruto
	***
	capture confirm file "`c(sysdir_site)'/03_temp/SCN/CSI_99.xlsx"
	if _rc != 0 | "`update'" == "update" {
		capture mkdir "`c(sysdir_site)'/03_temp/"
		capture mkdir "`c(sysdir_site)'/03_temp/SCN/"
		cd "`c(sysdir_site)'/03_temp/SCN/"
		unzipfile "https://www.inegi.org.mx/contenidos/programas/si/2018/tabulados/ori/tabulados_CSI.zip", replace
	}

	import excel using "`c(sysdir_site)'/03_temp/SCN/CSI_99.xlsx", cellrange(B60:AP60) clear
	local anio = 2003
	local dos = 1
	foreach k of varlist _all {
		if `dos' == 2 {
			drop `k'
			local dos = 1
			continue
		}
		rename `k' IngMxito_`anio'
		local ++anio
		local ++dos
	}

	g id = _n
	reshape long IngMxito_, i(id) j(anio) string
	rename IngMxito_ IngMixto

	replace IngMixto = IngMixto*1000000
	destring anio, replace

	order anio
	format IngMixto %20.0fc
	
	tempfile IngMixto
	save `IngMixto'

	***
	*** 10. Cuotas a la seguridad social imputada
	***
	import excel using "`c(sysdir_site)'/03_temp/SCN/CSI_99.xlsx", cellrange(B41:AP41) clear
	local anio = 2003
	local dos = 1
	foreach k of varlist _all {
		if `dos' == 2 {
			drop `k'
			local dos = 1
			continue
		}
		rename `k' SSImputada_`anio'
		local ++anio
		local ++dos
	}

	g id = _n
	reshape long SSImputada_, i(id) j(anio) string
	rename SSImputada_ SSImputada

	replace SSImputada = SSImputada*1000000
	destring anio, replace

	order anio
	format SSImputada %20.0fc

	tempfile SSImputada
	save `SSImputada'


	***
	*** 11. Subsidios a los productos, producci{c o'}n e importaciones
	***
	import excel using "`c(sysdir_site)'/03_temp/SCN/CSI_99.xlsx", cellrange(B54:AP54) clear
	local anio = 2003
	local dos = 1
	foreach k of varlist _all {
		if `dos' == 2 {
			drop `k'
			local dos = 1
			continue
		}
		rename `k' SubProductos_`anio'
		local ++anio
		local ++dos
	}

	g id = _n
	reshape long SubProductos_, i(id) j(anio) string
	rename SubProductos_ SubProductos

	replace SubProductos = SubProductos*1000000
	destring anio, replace

	order anio
	format SubProductos %20.0fc

	tempfile SubProductos
	save `SubProductos'


	***
	*** 12. Otros subsidios a la producci{c o'}n
	***
	import excel using "`c(sysdir_site)'/03_temp/SCN/CSI_99.xlsx", cellrange(B58:AP58) clear
	local anio = 2003
	local dos = 1
	foreach k of varlist _all {
		if `dos' == 2 {
			drop `k'
			local dos = 1
			continue
		}
		rename `k' SubProduccion_`anio'
		local ++anio
		local ++dos
	}

	g id = _n
	reshape long SubProduccion_, i(id) j(anio) string
	rename SubProduccion_ SubProduccion

	replace SubProduccion = SubProduccion*1000000
	destring anio, replace

	order anio
	format SubProduccion %20.0fc

	tempfile SubProduccion
	save `SubProduccion'


	***
	*** 13. Depreciaci{c o'}n del ingreso mixto
	***
	import excel using "`c(sysdir_site)'/03_temp/SCN/CSI_99.xlsx", cellrange(B62:AP62) clear
	local anio = 2003
	local dos = 1
	foreach k of varlist _all {
		if `dos' == 2 {
			drop `k'
			local dos = 1
			continue
		}
		rename `k' DepMix_`anio'
		local ++anio
		local ++dos
	}

	g id = _n
	reshape long DepMix_, i(id) j(anio) string
	rename DepMix_ DepMix

	replace DepMix = DepMix*1000000
	destring anio, replace

	order anio
	format DepMix %20.0fc

	tempfile DepMix
	save `DepMix'


	***
	*** 14. Excedente bruto de operaci{c o'}n No Financiero
	***
	import excel using "`c(sysdir_site)'/03_temp/SCN/CSI_102.xlsx", cellrange(B59:AP59) clear
	local anio = 2003
	local dos = 1
	foreach k of varlist _all {
		if `dos' == 2 {
			drop `k'
			local dos = 1
			continue
		}
		rename `k' ExBOpNoFin_`anio'
		local ++anio
		local ++dos
	}

	g id = _n
	reshape long ExBOpNoFin_, i(id) j(anio) string
	rename ExBOpNoFin_ ExBOpNoFin

	replace ExBOpNoFin = ExBOpNoFin*1000000
	destring anio, replace

	order anio
	format ExBOpNoFin %20.0fc

	tempfile ExBOpNoFin
	save `ExBOpNoFin'


	***
	*** 15. Excedente bruto de operaci{c o'}n Financiero
	***
	import excel using "`c(sysdir_site)'/03_temp/SCN/CSI_105.xlsx", cellrange(B59:AP59) clear
	local anio = 2003
	local dos = 1
	foreach k of varlist _all {
		if `dos' == 2 {
			drop `k'
			local dos = 1
			continue
		}
		rename `k' ExBOpFin_`anio'
		local ++anio
		local ++dos
	}

	g id = _n
	reshape long ExBOpFin_, i(id) j(anio) string
	rename ExBOpFin_ ExBOpFin

	replace ExBOpFin = ExBOpFin*1000000
	destring anio, replace

	order anio
	format ExBOpFin %20.0fc

	tempfile ExBOpFin
	save `ExBOpFin'


	***
	*** 16. Excedente bruto de operaci{c o'}n ISFLSH
	***
	import excel using "`c(sysdir_site)'/03_temp/SCN/CSI_114.xlsx", cellrange(B59:AP59) clear
	local anio = 2003
	local dos = 1
	foreach k of varlist _all {
		if `dos' == 2 {
			drop `k'
			local dos = 1
			continue
		}
		rename `k' ExBOpISFLSH_`anio'
		local ++anio
		local ++dos
	}

	g id = _n
	reshape long ExBOpISFLSH_, i(id) j(anio) string
	rename ExBOpISFLSH_ ExBOpISFLSH

	replace ExBOpISFLSH = ExBOpISFLSH*1000000
	destring anio, replace

	order anio
	format ExBOpISFLSH %20.0fc

	tempfile ExBOpISFLSH
	save `ExBOpISFLSH'


	***
	*** 17. Excedente bruto de operaci{c o'}n Hogares
	***
	import excel using "`c(sysdir_site)'/03_temp/SCN/CSI_111.xlsx", cellrange(B59:AP59) clear
	local anio = 2003
	local dos = 1
	foreach k of varlist _all {
		if `dos' == 2 {
			drop `k'
			local dos = 1
			continue
		}
		rename `k' ExBOpHog_`anio'
		local ++anio
		local ++dos
	}

	g id = _n
	reshape long ExBOpHog_, i(id) j(anio) string
	rename ExBOpHog_ ExBOpHog

	replace ExBOpHog = ExBOpHog*1000000
	destring anio, replace

	order anio
	format ExBOpHog %20.0fc

	tempfile ExBOpHog
	save `ExBOpHog'


	***
	*** 18. Excedente bruto de operaci{c o'}n Gobierno
	***
	import excel using "`c(sysdir_site)'/03_temp/SCN/CSI_108.xlsx", cellrange(B59:AP59) clear
	local anio = 2003
	local dos = 1
	foreach k of varlist _all {
		if `dos' == 2 {
			drop `k'
			local dos = 1
			continue
		}
		rename `k' ExBOpGob_`anio'
		local ++anio
		local ++dos
	}

	g id = _n
	reshape long ExBOpGob_, i(id) j(anio) string
	rename ExBOpGob_ ExBOpGob

	replace ExBOpGob = ExBOpGob*1000000
	destring anio, replace

	order anio
	format ExBOpGob %20.0fc

	tempfile ExBOpGob
	save `ExBOpGob'


	***
	*** 19. Excedente neto de operaci{c o'}n No Financiero
	***
	import excel using "`c(sysdir_site)'/03_temp/SCN/CSI_102.xlsx", cellrange(B63:AP63) clear
	local anio = 2003
	local dos = 1
	foreach k of varlist _all {
		if `dos' == 2 {
			drop `k'
			local dos = 1
			continue
		}
		rename `k' ExNOpNoFin_`anio'
		local ++anio
		local ++dos
	}

	g id = _n
	reshape long ExNOpNoFin_, i(id) j(anio) string
	rename ExNOpNoFin_ ExNOpNoFin

	replace ExNOpNoFin = ExNOpNoFin*1000000
	destring anio, replace

	order anio
	format ExNOpNoFin %20.0fc

	tempfile ExNOpNoFin
	save `ExNOpNoFin'


	***
	*** 20. Excedente neto de operaci{c o'}n Financiero
	***
	import excel using "`c(sysdir_site)'/03_temp/SCN/CSI_105.xlsx", cellrange(B63:AP63) clear
	local anio = 2003
	local dos = 1
	foreach k of varlist _all {
		if `dos' == 2 {
			drop `k'
			local dos = 1
			continue
		}
		rename `k' ExNOpFin_`anio'
		local ++anio
		local ++dos
	}

	g id = _n
	reshape long ExNOpFin_, i(id) j(anio) string
	rename ExNOpFin_ ExNOpFin

	replace ExNOpFin = ExNOpFin*1000000
	destring anio, replace

	order anio
	format ExNOpFin %20.0fc

	tempfile ExNOpFin
	save `ExNOpFin'


	***
	*** 21. Excedente neto de operaci{c o'}n ISFLSH
	***
	import excel using "`c(sysdir_site)'/03_temp/SCN/CSI_114.xlsx", cellrange(B63:AP63) clear
	local anio = 2003
	local dos = 1
	foreach k of varlist _all {
		if `dos' == 2 {
			drop `k'
			local dos = 1
			continue
		}
		rename `k' ExNOpISFLSH_`anio'
		local ++anio
		local ++dos
	}

	g id = _n
	reshape long ExNOpISFLSH_, i(id) j(anio) string
	rename ExNOpISFLSH_ ExNOpISFLSH

	replace ExNOpISFLSH = ExNOpISFLSH*1000000
	destring anio, replace

	order anio
	format ExNOpISFLSH %20.0fc

	tempfile ExNOpISFLSH
	save `ExNOpISFLSH'


	***
	*** 22. Excedente neto de operaci{c o'}n Hogares
	***
	import excel using "`c(sysdir_site)'/03_temp/SCN/CSI_111.xlsx", cellrange(B63:AP63) clear
	local anio = 2003
	local dos = 1
	foreach k of varlist _all {
		if `dos' == 2 {
			drop `k'
			local dos = 1
			continue
		}
		rename `k' ExNOpHog_`anio'
		local ++anio
		local ++dos
	}

	g id = _n
	reshape long ExNOpHog_, i(id) j(anio) string
	rename ExNOpHog_ ExNOpHog

	replace ExNOpHog = ExNOpHog*1000000
	destring anio, replace

	order anio
	format ExNOpHog %20.0fc

	tempfile ExNOpHog
	save `ExNOpHog'


	***
	*** 23. Excedente neto de operaci{c o'}n Gobierno
	***
	import excel using "`c(sysdir_site)'/03_temp/SCN/CSI_108.xlsx", cellrange(B63:AP63) clear
	local anio = 2003
	local dos = 1
	foreach k of varlist _all {
		if `dos' == 2 {
			drop `k'
			local dos = 1
			continue
		}
		rename `k' ExNOpGob_`anio'
		local ++anio
		local ++dos
	}

	g id = _n
	reshape long ExNOpGob_, i(id) j(anio) string
	rename ExNOpGob_ ExNOpGob

	replace ExNOpGob = ExNOpGob*1000000
	destring anio, replace

	order anio
	format ExNOpGob %20.0fc

	tempfile ExNOpGob
	save `ExNOpGob'


	***
	*** 24. Ahorro bruto
	***
	import excel using "`c(sysdir_site)'/03_temp/SCN/CSI_99.xlsx", cellrange(B170:AP170) clear
	local anio = 2003
	local dos = 1
	foreach k of varlist _all {
		if `dos' == 2 {
			drop `k'
			local dos = 1
			continue
		}
		rename `k' AhorroB_`anio'
		local ++anio
		local ++dos
	}

	g id = _n
	reshape long AhorroB_, i(id) j(anio) string
	rename AhorroB_ AhorroB

	replace AhorroB = AhorroB*1000000
	destring anio, replace

	order anio
	format AhorroB %20.0fc

	tempfile AhorroB
	save `AhorroB'


	***
	*** 25. Ingreso disponible bruto
	***
	import excel using "`c(sysdir_site)'/03_temp/SCN/CSI_99.xlsx", cellrange(B152:AP152) clear
	local anio = 2003
	local dos = 1
	foreach k of varlist _all {
		if `dos' == 2 {
			drop `k'
			local dos = 1
			continue
		}
		rename `k' IngDisp_`anio'
		local ++anio
		local ++dos
	}

	g id = _n
	reshape long IngDisp_, i(id) j(anio) string
	rename IngDisp_ IngDisp

	replace IngDisp = IngDisp*1000000
	destring anio, replace

	order anio
	format IngDisp %20.0fc

	tempfile IngDisp
	save `IngDisp'


	***
	*** 26. Merge bases
	***
	use `GenIng', clear
	merge 1:1 anio using `ProdBru', nogen
	merge 1:1 anio using `IngNacDis', nogen
	merge 1:1 anio using `ConHog', nogen
	merge 1:1 anio using `GastPriv', nogen
	merge 1:1 anio using `GovCons', nogen
	merge 1:1 anio using `PIBAE1', nogen
	merge 1:1 anio using `PIBAE2', nogen
	merge 1:1 anio using `PIBAE3', nogen
	merge 1:1 anio using `PIBAE4', nogen
	merge 1:1 anio using `PIBAE5', nogen
	merge 1:1 anio using `SecExt', nogen
	merge 1:1 anio using `IngMixto', nogen
	merge 1:1 anio using `SSImputada', nogen
	merge 1:1 anio using `SubProductos', nogen
	merge 1:1 anio using `SubProduccion', nogen
	merge 1:1 anio using `DepMix', nogen
	merge 1:1 anio using `ExBOpNoFin', nogen
	merge 1:1 anio using `ExBOpFin', nogen
	merge 1:1 anio using `ExBOpISFLSH', nogen
	merge 1:1 anio using `ExBOpHog', nogen
	merge 1:1 anio using `ExBOpGob', nogen
	merge 1:1 anio using `ExNOpNoFin', nogen
	merge 1:1 anio using `ExNOpFin', nogen
	merge 1:1 anio using `ExNOpISFLSH', nogen
	merge 1:1 anio using `ExNOpHog', nogen
	merge 1:1 anio using `ExNOpGob', nogen
	merge 1:1 anio using `AhorroB', nogen
	merge 1:1 anio using `IngDisp', nogen
	merge 1:1 (anio) using "`c(sysdir_site)'/04_master/Poblaciontot.dta", nogen keep(matched)
	tsset anio

	save "`c(sysdir_site)'/04_master/SCN.dta", replace
end
