program define DatosAbiertos, return
quietly {

	** 0.1 Revisa si se puede usar la base de datos **
	capture use "`c(sysdir_site)'/SIM/DatosAbiertos.dta", clear
	if _rc != 0 {
		UpdateDatosAbiertos
	}

	** 0.2 Revisa si existe el scalar aniovp **
	capture confirm scalar aniovp
	if _rc == 0 {
		local aniovp = scalar(aniovp)
	}
	else {
		local aniovp : di %td_CY-N-D  date("$S_DATE", "DMY")
		local aniovp = substr(`"`=trim("`aniovp'")'"',1,4)	
	}

	syntax [anything] [if] [, NOGraphs PIBVP(real -999) PIBVF(real -999) UPDATE DESDE(real 1993) MES]



	***********************
	*** 1 Base de datos ***
	***********************
	
	** 1.1 PIB + Deflactor **
	PIBDeflactor, nographs nooutput aniovp(`aniovp')
	replace Poblacion = Poblacion*lambda
	local currency = currency[1]
	tempfile PIB
	save "`PIB'"

	** 1.2 Datos Abiertos (Estadísticas Oportunas) **
	use if clave_de_concepto == "`anything'" using "`c(sysdir_site)'/SIM/DatosAbiertos.dta", clear
	if "`anything'" == "" {
		use "`c(sysdir_site)'/SIM/DatosAbiertos.dta", clear
		exit
	}
	if `=_N' == 0 {
		noisily di in r "No se encontr{c o'} la serie {bf:`anything'}."
		exit
	}
	tsset aniomes
	sort aniomes
	local last_anio = anio[_N]
	local last_mes = mes[_N]

	* Acentos *
	replace nombre = "Saldo histórico de los RFSP" if nombre == "Saldo hist?rico de los RFSP"
	replace nombre = "Saldo histórico de los RFSP internos" if nombre == "Saldo hist?rico de los RFSP internos"
	replace nombre = "Saldo histórico de los RFSP externos" if nombre == "Saldo hist?rico de los RFSP externos"
	replace nombre = "Requerimientos financieros del sector público" if nombre == "Requerimientos financieros del sector p??blico federal (I+II)"


	*********************************
	** 1.1 Informacion de la serie **
	merge m:1 (anio) using "`PIB'", nogen keep(matched) //keepus(pibY deflator currency Poblacion*)
	noisily di _newline in g " Serie: " in y "`anything'" in g ". Nombre: " in y "`=nombre[1]'" in g "."
	*keep if anio >= 2013 & anio <= `last_anio'
	
	if "`if'" != "" {
		keep `if'
	}

	tsset aniomes
	tempvar dif_Poblacion dif2_Poblacion
	g `dif_Poblacion' = D.Poblacion
	egen `dif2_Poblacion' = max(`dif_Poblacion')
	replace Poblacion = Poblacion + `dif2_Poblacion'*mes/12

	tempvar montomill montopc crecreal
	g `montomill' = monto/1000000/deflator
	g `montopc' = monto/Poblacion/deflator
	g `crecreal' = (`montomill'/L12.`montomill'-1)*100

	label define mes 1 "Enero" 2 "Febrero" 3 "Marzo" 4 "Abril" 5 "Mayo" 6 "Junio" 7 "Julio" 8 "Agosto" 9 "Septiembre" 10 "Octubre" 11 "Noviembre" 12 "Diciembre"
	label values mes mes
	local mesname : label mes `=mes[_N]'
	local mesnameant : label mes `=mes[`=_N-1']'

	if tipo_de_informacion == "Flujo" {
		tabstat `montomill' if mes == `=mes[_N]' & (anio == `=anio[_N]' | anio == `=anio[_N]-1'), stat(sum) by(anio) format(%7.0fc) save
		tempname meshoy mesant
		matrix `meshoy' = r(Stat2)
		matrix `mesant' = r(Stat1)

		noisily di _newline in g "  Mes " in y "`mesname' `=anio[_N]'" in g ": " _col(40) in y %20.1fc `meshoy'[1,1] in g " millones `currency'"
		noisily di in g "  Mes " in y "`mesname' `=anio[_N]-1'" in g ": " _col(40) in y %20.1fc `mesant'[1,1] in g " millones `currency' `aniovp'"
		noisily di in g "  Crecimiento: " _col(44) in y %16.1fc (`meshoy'[1,1]/`mesant'[1,1]-1)*100 in g " %"

		tabstat `montomill' if mes <= `=mes[_N]' & (anio == `=anio[_N]' | anio == `=anio[_N]-1'), stat(sum) by(anio) format(%7.0fc) save
		tempname meshoy mesant
		matrix `meshoy' = r(Stat2)
		matrix `mesant' = r(Stat1)

		noisily di _newline in g "  Acumulado " in y "`mesname' `=anio[_N]'" in g ": " _col(40) in y %20.1fc `meshoy'[1,1] in g " millones `currency'"
		noisily di in g "  Acumulado " in y "`mesname' `=anio[_N]-1'" in g ": " _col(40) in y %20.1fc `mesant'[1,1] in g " millones `currency' `aniovp'"
		noisily di in g "  Crecimiento: " _col(44) in y %16.1fc (`meshoy'[1,1]/`mesant'[1,1]-1)*100 in g " %"
	}
	if tipo_de_informacion == "Saldo" {
		tabstat `montomill' if ((anio == `last_anio'-1 & mes == 12) | (anio == `last_anio' & mes == `last_mes')), stat(sum) by(anio) format(%7.0fc) save
		tempname meshoy mesant
		matrix `meshoy' = r(Stat2)
		matrix `mesant' = r(Stat1)

		noisily di _newline in g "  Acumulado " in y "`mesname' `=anio[_N]'" in g ": " _col(40) in y %20.1fc `meshoy'[1,1] in g " millones `currency'"
		noisily di in g "  Acumulado " in y "Diciembre `=anio[_N]-1'" in g ": " _col(40) in y %20.1fc `mesant'[1,1] in g " millones `currency' `aniovp'"
		noisily di in g "  Crecimiento: " _col(44) in y %16.1fc (`meshoy'[1,1]/`mesant'[1,1]-1)*100 in g " %"

		tabstat `montopc' if ((anio == `last_anio' & mes == `last_mes') | (anio == `last_anio' & mes == `=`last_mes'-1')), stat(sum) by(mes) format(%7.0fc) save
		tempname meshoy mesant
		matrix `meshoy' = r(Stat2)
		matrix `mesant' = r(Stat1)

		noisily di _newline in g "  Acumulado " in y "`mesname' `=anio[_N]'" in g ": " _col(40) in y %20.0fc `meshoy'[1,1] in g " per cápita `currency' `aniovp'"
		noisily di in g "  Acumulado " in y "`mesnameant' `=anio[_N]'" in g ": " _col(40) in y %20.0fc `mesant'[1,1] in g " per cápita `currency' `aniovp'"
		noisily di in g "  Crecimiento: " _col(44) in y %16.1fc (`meshoy'[1,1]/`mesant'[1,1]-1)*100 in g " %"
	}



	****************************
	*** 2 Proyeccion mensual ***
	****************************
	if "`nographs'" != "nographs" & tipo_de_informacion == "Flujo" {
		local length = length("`=nombre[1]'")
		if `length' > 60 {
			*local textsize ", size(medium)"
		}
		if `length' > 90 {
			*local textsize ", size(small)"
		}
		if `length' > 110 {
			*local textsize ", size(vsmall)"
		}

		tabstat `montomill' `if', stat(sum) by(mes) f(%20.0fc) save
		local j = 100/12/2
		forvalues k=1(1)12 {
			tempname monto`k'
			matrix `monto`k'' = r(Stat`k')
			local valorserie `"`valorserie' `=`monto`k''[1,1]*0' `j' "{bf:`=string(`monto`k''[1,1],"%5.1fc")'}""'
			local j = `j' + 100/12
		}

		graph bar (sum) `montomill', over(anio) over(mes) stack asyvar ///
			legend(rows(2)) ///
			name(M`anything', replace) blabel(none) ///
			ytitle("millones de `=currency[1]' `aniovp'") ///
			yline(0, lcolor(black) lpattern(solid)) ///
			title("{bf:`=nombre[1]'}"`textsize') ///
			///text(`valorserie', color(black) place(n)) ///
			subtitle("por mes calendario") ///
			ylabel(, format(%15.0fc)) ///
			note("{bf:{c U'}ltimo dato:} `last_anio'm`last_mes'.") ///
			caption("{bf:Fuente:} Elaborado por el CIEP, con información de la SHCP (Estadísticas Oportunas de Finanzas P{c u'}blicas).")

		/*preserve
		collapse (sum) `montomill', by(aniotrimestre anio trimestre nombre currency)
		forvalues k=1(1)`=_N' {
			local relab `" `relab' `k' "`=trimestre[`k']'" "'
			if anio[`k'] == `last_anio' & trimestre[`k'] == trimestre[_N] {
				local montoTrimActual = `montomill'[`k']
			}
			if anio[`k'] == `last_anio'-1 & trimestre[`k'] == trimestre[_N] {
				local montoTrimAnteri = `montomill'[`k']
			}
		}
		graph bar (sum) `montomill', over(anio) ///
			over(aniotrimestre, relabel(`relab') axis(on)) ///
			stack asyvar ///
			legend(rows(2)) ///
			name(T`anything', replace) blabel(none) ///
			ytitle("millones de `=currency[1]' `aniovp'") ///
			yline(0, lcolor(black) lpattern(solid)) ///
			title("{bf:`=nombre[1]'}"`textsize') ///
			///text(`valorserie', color(black) place(n)) ///
			subtitle("por trimestre") ///
			ylabel(, format(%15.0fc)) ///
			///b1title(`" `=string((`montoTrimActual'/`montoTrimAnteri'-1)*100,"%10.1fc")' "') ///
			note("{bf:{c U'}ltimo dato:} `last_anio'm`last_mes'.") ///
			caption("{bf:Fuente:} Elaborado por el CIEP, con información de la SHCP (Estadísticas Oportunas de Finanzas P{c u'}blicas).")
		restore*/

		graph bar (sum) `montomill' if mes == `=mes[_N]' & anio >= 2008, over(anio) ///
			name(`mesname'`anything', replace) ///
			ytitle("millones de `=currency[1]' `aniovp'") ///
			ylabel(, format(%15.0fc)) ///
			title("{bf:`=nombre[1]'}"`textsize') ///
			subtitle("`mesname'") ///
			blabel(, format(%10.0fc) position(outside) color(black) size(small)) legend(off) ///
			yline(0, lcolor(black) lpattern(solid)) ///
			///note("{bf:{c U'}ltimo dato:} `last_anio'm`last_mes'.") ///
			caption("{bf:Fuente:} Elaborado por el CIEP, con información de la SHCP (Estadísticas Oportunas de Finanzas P{c u'}blicas).")

		graph bar (sum) `montomill' if mes <= `=mes[_N]' & anio >= 2008, over(anio) ///
			name(Acum`mesname'`anything', replace) ///
			ytitle("millones de `=currency[1]' `aniovp'") ///
			ylabel(, format(%15.0fc)) ///
			title("{bf:`=nombre[1]'}"`textsize') ///
			subtitle(`"Acumulado a `=lower("`mesname'")'"') ///
			blabel(, format(%10.0fc) position(outside) color(black) size(small)) legend(off) ///
			yline(0, lcolor(black) lpattern(solid)) ///
			///note("{bf:{c U'}ltimo dato:} `last_anio'm`last_mes'.") ///
			caption("{bf:Fuente:} Elaborado por el CIEP, con información de la SHCP (Estadísticas Oportunas de Finanzas P{c u'}blicas).")

		forvalues k=1(1)`=_N' {
			if `crecreal'[`k'] != . & mes[`k'] == `=mes[_N]' {
				local textcrecreal `"`textcrecreal' `=`crecreal'[`k']' `=aniomes[`k']' "{bf:`=string(`crecreal'[`k'],"%7.1fc")'}" "'
			}
		}

		twoway (connected `crecreal' aniomes, msize(large)) if mes == `=mes[_N]', ///
			name(Crec_`mesname'`anything', replace) ///
			ytitle("%") ///
			ylabel(, format(%7.0fc)) ///
			tlabel(1994m`last_mes'(24)`last_anio'm`last_mes') ///
			ttitle("") ///
			title("{bf:`=nombre[1]'}"`textsize') ///
			yline(0, lcolor(black) lpattern(solid)) ///
			subtitle("`mesname'") legend(off) ///
			text(`textcrecreal', size(vsmall)) ///
			///note("{bf:{c U'}ltimo dato:} `last_anio'm`last_mes'.") ///
			caption("{bf:Fuente:} Elaborado por el CIEP, con información de la SHCP (Estadísticas Oportunas de Finanzas P{c u'}blicas).")
	}

	if "`nographs'" != "nographs" & tipo_de_informacion == "Saldo" {
		forvalues k=1(1)`=_N' {
			if `montopc'[`k'] != . & ((anio[`k'] >= 2000 & mes[`k'] == 12) | (anio[`k'] == `last_anio' & (mes[`k'] == `last_mes' | mes[`k'] == `last_mes'-1))) {
				local textmontopc `"`textmontopc' `=`montopc'[`k']' `=aniomes[`k']' "{bf:`=string(`montopc'[`k'],"%10.0fc")'}" "'
			}
		}
		twoway (connect `montopc' aniomes if (anio >= 2000 & mes == 12)) ///
			(connect `montopc' aniomes if (anio == `last_anio' & mes == `last_mes'-1)) ///
			(connect `montopc' aniomes if (anio == `last_anio' & mes == `last_mes')), ///
			ytitle("`=currency[1]' `aniovp'") ///
			tlabel(2000m12(24)`last_anio'm`last_mes') ///
			ylabel(, format(%15.0fc)) ///
			title("{bf:`=nombre[1]'}"`textsize') ///
			subtitle(Por persona ajustada) ///
			xtitle("") ///
			legend(label(1 "Diciembre") label(2 "`mesnameant' `last_anio'") label(3 "`mesname' `last_anio'")) ///
			text(`textmontopc', size(vsmall) place(c)) ///
			note("{bf:{c U'}ltimo dato:} `last_anio'm`last_mes'.") ///			
			caption("{bf:Fuente:} Elaborado por el CIEP, con información de la SHCP/EOFP y CONAPO (2023).") ///
			name(`anything'PC, replace)

		capture confirm existence $export
		if _rc == 0 {
			graph export "$export/`anything'PC.png", replace name(`anything'PC)
		}

	}



	*************************/
	*** 2 Proyeccion anual ***
	**************************
	if tipo_de_informacion == "Flujo" {
		tempvar montoanual propmensual
		egen `montoanual' = sum(monto) if anio < `last_anio' & anio >= `desde', by(anio)
		g `propmensual' = monto/`montoanual' if anio < `last_anio' & anio >= `desde'
		egen acum_prom = mean(`propmensual'), by(mes)
		collapse (sum) monto acum_prom (last) mes Poblacion if monto != ., by(anio nombre clave_de_concepto unidad_de_medida)
		*replace monto = monto/acum_prom if mes < 12
		local textografica `"{bf:Promedio a `mesname'}: `=string(acum_prom[_N]*100,"%5.1fc")'% del total anual."'
		local palabra "Proyectado"
	}
	else if tipo_de_informacion == "Saldo" {
		tempvar maxmes
		egen `maxmes' = max(mes), by(anio)
		*drop if mes < `maxmes'
		sort anio mes
		collapse (last) monto mes Poblacion if monto != ., by(anio nombre clave_de_concepto unidad_de_medida)
		g acum_prom = 1
	}
	*tsset aniomes
	local prianio = anio in 1
	local ultanio = anio in -1
	local ultmes = mes in -1
	return local ultimoAnio = `ultanio'
	return local ultimoMes = `ultmes'

	if `pibvf' != -999 {
		tsappend, add(1)
		local clave = clave_de_concepto[1]
		replace clave_de_concepto = "`clave'" in -1
		local nombre = nombre[1]
		replace nombre = "`nombre'" in -1
	}

	if `pibvp' != -999 {
		if `aniovp' == `last_anio'+1 {
			tsappend, add(1)
		}
		local clave = clave_de_concepto[1]
		replace clave_de_concepto = "`clave'" in -1
		local nombre = nombre[1]
		replace nombre = "`nombre'" in -1
	}

	merge m:1 (anio) using `PIB', nogen keep(matched) keepus(pibY deflator)			

	if `pibvp' != -999 {
		replace monto = `pibvp'/100*pibY if mes < 12 | mes == .
		local palabra "Estimado"
	}

	if `pibvf' != -999 {
		local textovp `"{superscript:*}{bf:`=anio[_N-1]':} `=string(monto[_N-1]/1000000,"%20.1fc")' millones de MXN"'
		replace monto = `pibvf'/100*pibY in -1
		local palabra "Estimado"
	}

	g double monto_pib = monto/pibY*100
	g double monto_pc = monto/Poblacion/deflator
	format monto_pib %7.3fc
	format monto_pc %10.1fc
	label var monto_pib "Observado (SHCP)"


	** 2.1. Grafica **
	if "`nographs'" != "nographs" {
		local serie_anio = anio[_N]
		local serie_monto = monto[_N]
		forvalues k = 1(1)`=_N' {
			if monto_pib[`k'] != . & monto_pib[`k'] != 0 {
				if mes[`k'] != 12 {
					local text1 = `"`text1' `=monto_pib[`k']' `=anio[`k']' "{bf:`=string(monto_pib[`k'],"%5.1fc")'{superscript:*}}" "'
				}
				else {
					local text1 = `"`text1' `=monto_pib[`k']' `=anio[`k']' "{bf:`=string(monto_pib[`k'],"%5.1fc")'}" "'
				}
			}
			if anio[`k'] == 2003 {
				if "`anything'" == "FMP_Derechos" | "`anything'" == "OtrosIngresosC" {
					local scalarname = subinstr("`anything'","_","",.)
				}
				else if substr("`anything'",-1,1) == "s" | substr("`anything'",-1,1) == "f" | substr("`anything'",-1,1) == "m" {
					local numone = substr("`anything'",4,1)
					local numtwo = substr("`anything'",5,1)
					local numthr = substr("`anything'",6,1)
					local numfou = substr("`anything'",7,1)
					local scalarname = substr("`anything'",1,3) + char(`=65+`numone'') + char(`=65+`numtwo'') + char(`=65+`numthr'') + char(`=65+`numfou'') + substr("`anything'",-1,1)

				}
				else {
					local scalarname = substr("`anything'",1,3) + substr("`anything'",4,1) + substr("`anything'",5,1) + substr("`anything'",6,1) + substr("`anything'",7,1)
				}
				scalar dif`scalarname'PIB = monto_pib[_N] - monto_pib[`k']
				scalar `scalarname'GEO = ((monto[_N]/(monto[`k']/deflator[`k']))^(1/(anio[_N]-anio[`k']))-1)*100
			}
		}

		* Grafica *
		if "$export" == "" {
			local graphtitle "{bf:`=nombre[1]'}"
			local graphfuente "{bf:Fuente}: Elaborado por el CIEP, con informaci{c o'}n de la SHCP/EOFP."
		}
		else {
			local graphtitle ""
			local graphfuente ""
		}

		tempvar monto
		g `monto' = monto/1000000/deflator
		twoway (area `monto' anio if anio < `aniovp') ///
			(bar `monto' anio if anio >= `aniovp') ///
			(connected monto_pib anio if anio < `aniovp', yaxis(2) pstyle(p1)) ///
			(connected monto_pib anio if anio >= `aniovp', yaxis(2) pstyle(p2)), ///
			title("`graphtitle'"`textsize') ///
			/*subtitle(Montos observados)*/ ///
			///b1title(`"`textografica'"', size(small)) ///
			///b2title(`"`textovp'"', size(small)) ///
			ytitle(millones MXN `aniovp') ///
			ytitle(% PIB, axis(2)) xtitle("") ///
			///xlabel(`prianio' `=round(`prianio',5)'(5)`ultanio') ///
			///xlabel(`prianio'(1)`ultanio') ///
			ylabel(, format(%15.0fc)) yscale(range(0)) ///
			ylabel(, axis(2) format(%5.1fc) noticks) ///
			yscale(range(0) noline axis(2)) ///
			legend(off label(1 "Reportado") label(2 "LIF") order(1 2)) ///
			text(`text1', yaxis(2) color(white) size(vsmall)) ///
			caption("`graphfuente'") ///
			note("{bf:{c U'}ltimo dato:} `ultanio'm`ultmes'.") ///
			name(H`anything', replace)
		
		capture confirm existence $export
		if _rc == 0 {
			graph export "$export/H`anything'.png", replace name(H`anything')
		}
	}
	noisily list anio monto acum_prom mes monto_pib monto_pc, separator(30) string(30)
}
end
