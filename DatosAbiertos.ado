program define DatosAbiertos, return
quietly {

	** 0.1 Revisa si se puede usar la base de datos **
	capture use "`c(sysdir_site)'/04_master/DatosAbiertos.dta", clear
	if _rc != 0 {
		UpdateDatosAbiertos
	}
	capture use "`c(sysdir_site)'/04_master/Deflactor.dta", clear
	if _rc != 0 {
		UpdateDeflactor
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

	** 0.3 Sintaxis del comando **
	syntax [anything] [if] [,  PIBVP(real -999) PIBVF(real -999) DESDE(real 2008) ///
		UPDATE NOGraphs REVERSE PROYeccion ZIPFILE]



	***********************
	*** 1 Base de datos ***
	***********************
	if "`update'" == "update" {
		UpdateDatosAbiertos, `update' `zipfile'
		noisily UpdateDeflactor
	}
	
	use if clave_de_concepto == "`anything'" using "`c(sysdir_site)'/04_master/DatosAbiertos.dta", clear
	*drop in -1
	merge 1:1 (anio mes) using "`c(sysdir_site)'/04_master/Deflactor.dta", nogen keep(matched)
	merge m:1 (anio) using "`c(sysdir_site)'/04_master/Poblaciontot.dta", nogen keep(matched)
	merge m:1 (anio trimestre) using "`c(sysdir_site)'/04_master/PIBDeflactor.dta", nogen

	** Limpiar **
	tsset aniomes
	drop if aniomes == .
	order inpc, last
	local currency = currency[1]
	foreach k of varlist inpc {
		capture confirm numeric variable `k'
		if _rc == 0 {
			replace `k' = L.`k' if `k' == .
		}
	}
	
	*g lambda = (1+scalar(llambda)/100)^(anio-`aniovp')
	*replace poblacion = poblacion*lambda

	if "`anything'" == "" {
		use "`c(sysdir_site)'/04_master/DatosAbiertos.dta", clear
		exit
	}
	if `=_N' == 0 {
		noisily di in r "No se encontr{c o'} la serie {bf:`anything'}."
		exit
	}
	if "`reverse'" == "reverse" {
		replace monto = -monto
	}
	tsset aniomes
	sort aniomes
	local last_anio = anio[_N]
	local last_mes = mes[_N]

	* Acentos *
	replace nombre = "Saldo histórico de los RFSP" if nombre == "Saldo hist?rico de los RFSP"
	replace nombre = "Saldo histórico de los RFSP internos" if nombre == "Saldo hist?rico de los RFSP internos"
	replace nombre = "Saldo histórico de los RFSP externos" if nombre == "Saldo hist?rico de los RFSP externos"
	replace nombre = "Requerimientos financieros del sector público" if nombre == "Requerimientos financieros del sector p¿¿blico federal (I+II)"
	replace nombre = "Requerimientos financieros del sector público" if nombre == "Requerimientos financieros del sector p??blico federal (I+II)"


	*********************************
	** 1.1 Informacion de la serie **
	noisily di _newline in g " Serie: " in y "`anything'" in g ". Nombre: " in y "`=nombre[1]'" in g "."
	
	if "`if'" != "" {
		keep `if'
	}
	
	tempvar deflactormes deflactoracum deflactor
	g `deflactoracum' = inpc if mes <= mes[_N]
	egen deflactoracum = mean(`deflactoracum'), by(anio)
	replace deflactoracum = deflactoracum/deflactoracum[_N]

	g `deflactormes' = inpc if mes == mes[_N]
	egen deflactormes = mean(`deflactormes'), by(anio)
	replace deflactormes = deflactormes/deflactormes[_N]
	
	g deflactor = inpc/inpc[_N]

	tempvar crecreal
	g montomill = monto/1000000
	format montomill %20.0fc

	g monto_pc = monto/poblacion/deflactor
	format monto_pc %10.0fc

	egen pibY = mean(pibQ), by(anio)
	g monto_pib = monto/pibY*100
	format monto_pib %7.1fc

	g `crecreal' = (montomill/L12.montomill-1)*100

	label define mes 1 "Enero" 2 "Febrero" 3 "Marzo" 4 "Abril" 5 "Mayo" 6 "Junio" ///
		7 "Julio" 8 "Agosto" 9 "Septiembre" 10 "Octubre" 11 "Noviembre" 12 "Diciembre"
	label values mes mes
	local mesname : label mes `=mes[_N]'
	local mesnameant : label mes `=mes[`=_N-1']'

	if tipo_de_informacion == "Flujo" {
		tabstat montomill deflactoracum deflactormes if mes == `=mes[_N]' & (anio == `=anio[_N]' | anio == `=anio[_N]-1'), stat(sum) by(anio) format(%10.3fc) save
		tempname meshoy mesant
		matrix `meshoy' = r(Stat2)
		matrix `mesant' = r(Stat1)

		noisily di _newline in g "  Mes " in y "`mesname' `=anio[_N]'" in g ": " _col(40) in y %20.0fc `meshoy'[1,1]/`meshoy'[1,3] in g " millones `currency'"
		noisily di in g "  Mes " in y "`mesname' `=anio[_N]-1'" in g ": " _col(40) in y %20.0fc `mesant'[1,1] in g " millones `currency'"
		noisily di in g "  " _dup(75) "-"
		noisily di in g "  Mes " in y "`mesname' `=anio[_N]-1'" in g ": " _col(40) in y %20.0fc `mesant'[1,1]/`mesant'[1,3] in g " millones `currency' `aniovp'"
		noisily di in g "  " _dup(75) "-"
		noisily di in g "  Crecimiento real: " _col(44) in y %16.1fc ((`meshoy'[1,1]/`meshoy'[1,3])/(`mesant'[1,1]/`mesant'[1,3])-1)*100 in g " %"

		tabstat montomill if mes <= `=mes[_N]' & (anio == `=anio[_N]' | anio == `=anio[_N]-1'), stat(sum) by(anio) format(%10.3fc) save
		tempname meshoyacum mesantacum
		matrix `meshoyacum' = r(Stat2)
		matrix `mesantacum' = r(Stat1)

		noisily di _newline(2) in g "  Acumulado " in y "`mesname' `=anio[_N]'" in g ": " _col(40) in y %20.0fc `meshoyacum'[1,1]/`meshoy'[1,2] in g " millones `currency'"
		noisily di in g "  Acumulado " in y "`mesname' `=anio[_N]-1'" in g ": " _col(40) in y %20.0fc `mesantacum'[1,1] in g " millones `currency'"
		noisily di in g "  " _dup(75) "-"
		noisily di in g "  Acumulado " in y "`mesname' `=anio[_N]-1'" in g ": " _col(40) in y %20.0fc `mesantacum'[1,1]/`mesant'[1,2] in g " millones `currency' `aniovp'"
		noisily di in g "  " _dup(75) "-"
		noisily di in g "  Crecimiento real: " _col(44) in y %16.1fc ((`meshoyacum'[1,1]/`meshoy'[1,2])/(`mesantacum'[1,1]/`mesant'[1,2])-1)*100 in g " %"
	}

	replace montomill = montomill/deflactor

	if tipo_de_informacion == "Saldo" {
		tabstat montomill if ((anio == `last_anio'-1 & mes == 12) | (anio == `last_anio' & mes == `last_mes')), stat(sum) by(anio) format(%7.0fc) save
		tempname meshoy mesant
		matrix `meshoy' = r(Stat2)
		matrix `mesant' = r(Stat1)

		noisily di _newline(2) in g "  Acumulado " in y "`mesname' `=anio[_N]'" in g ": " _col(40) in y %20.0fc `meshoy'[1,1] in g " millones `currency'"
		noisily di in g "  Acumulado " in y "Diciembre `=anio[_N]-1'" in g ": " _col(40) in y %20.0fc `mesant'[1,1] in g " millones `currency' `aniovp'"
		noisily di in g "  Crecimiento real: " _col(44) in y %16.1fc (`meshoy'[1,1]/`mesant'[1,1]-1)*100 in g " %"

		tabstat montomill if ((anio == `last_anio'-1 & mes == `last_mes') | (anio == `last_anio' & mes == `last_mes')), stat(sum) by(anio) format(%7.0fc) save
		tempname meshoy mesant
		matrix `meshoy' = r(Stat2)
		matrix `mesant' = r(Stat1)

		noisily di _newline in g "  Acumulado " in y "`mesname' `=anio[_N]'" in g ": " _col(40) in y %20.0fc `meshoy'[1,1] in g " per cápita `currency' `aniovp'"
		noisily di in g "  Acumulado " in y "`mesname' `=anio[_N]-1'" in g ": " _col(40) in y %20.0fc `mesant'[1,1] in g " per cápita `currency' `aniovp'"
		noisily di in g "  Crecimiento real: " _col(44) in y %16.1fc (`meshoy'[1,1]/`mesant'[1,1]-1)*100 in g " %"
	}

	tempvar finishedY finishedYY
	g `finishedY' = mes == 12
	egen `finishedYY' = max(`finishedY'), by(anio)

	tempvar montoanual propmensual
	egen `montoanual' = sum(monto) if `finishedYY' == 1 & anio >= `desde', by(anio)
	g propmensual = monto/`montoanual' if `finishedYY' == 1 & anio >= `desde'
	egen acum_prom = mean(propmensual), by(mes)


	****************************
	*** 2 Proyeccion mensual ***
	****************************
	if "`nographs'" != "nographs" & tipo_de_informacion == "Flujo" {

		** 2.1 Título de la gráfica **
		local length = length("`=nombre[1]'")
		if `length' > 60 {
			*local textsize ", size(medium)"
		}
		if `length' > 90 {
			*local textsize ", size(large)"
		}
		if `length' > 110 {
			*local textsize ", size(large)"
		}

		* Fuente *
		if "$export" == "" {
			local graphtitle `""{bf:`=nombre[1]'}"`textsize'"'
			local graphfuente "Fuente: Elaborado por el CIEP, con informaci{c o'}n de la SHCP/EOFP."
		}
		else {
			local graphfuente ""
		}

		** 2.2 Gráfica por mes calendario **
		local meses "Enero Febrero Marzo Abril Mayo Junio Julio Agosto Septiembre Octubre Noviembre Diciembre"
		tokenize "`meses'"
		tabstat acum_prom if `finishedYY' == 1, stat(mean) by(mes) f(%20.3fc) save
		forvalues k=1(1)12 {
			label define mes `k' "``k'' (`=string(r(Stat`k')[1,1]*100,"%7.1fc")'%)", modify
			local ++k
		}

		graph bar (sum) monto_pib if monto_pib != . & anio >= `desde', over(mes) over(anio) stack asyvar ///
			legend(rows(2) size(large)) ///
			name(M`anything', replace) blabel(none) ///
			ytitle("% PIB") ///
			yline(0, lcolor(black) lpattern(solid)) ///
			title(`graphtitle') ///
			ylabel(, format(%15.0fc)) ///
			note("Las cifras entre paréntesis representan la distribución promedio mensual desde `desde'.") ///
			caption("`graphfuente'")
		capture confirm existence $export
		if _rc == 0 {
			graph export "$export/M`anything'.png", replace name(M`anything')
		}


		** 2.3 Gráfica por mes **
		graph bar (sum) montomill if mes == `=mes[_N]' & anio >= `desde', over(anio) ///
			name(`mesname'`anything', replace) ///
			title("{bf:`=nombre[1]'}"`textsize') ///
			subtitle(" `mesname', millones de `=currency[1]' `aniovp'", margin(bottom)) ///
			ytitle("millones de `=currency[1]' `aniovp'") ///
			ylabel(none, format(%15.0fc)) ///
			blabel(bar, format(%10.0fc) color(white) size(small) orient(vertical)) ///
			legend(off) ///
			///yline(0, lcolor(black) lpattern(dash)) ///
			///note("{c U'}ltimo dato: `last_anio'm`last_mes'.") ///
			caption("`graphfuente'")
		capture confirm existence $export
		if _rc == 0 {
			graph export "$export/`mesname'`anything'.png", replace name(`mesname'`anything')
		}


		** 2.4 Gráfica acumulado **
		preserve
		collapse (sum) montomill if mes <= `=mes[_N]', by(nombre currency anio)
		tsset anio

		tabstat montomill, stat(min max) by(anio) save
		tempname rango
		matrix `rango' = r(StatTotal)

		graph bar (sum) montomill if anio >= `desde', over(anio) ///
			name(Acum`mesname'`anything', replace) ///
			title("{bf:`=nombre[1]'}"`textsize') ///
			subtitle(`"Acumulado a `=lower("`mesname'")'"', margin(bottom)) ///
			ytitle("millones de `=currency[1]' `aniovp'") ///
			ylabel(none, format(%15.0fc)) ///
			yscale(range(0)) ///
			blabel(bar, format(%10.0fc) color(white) size(small) orient(vertical)) ///
			legend(off) ///
			caption("`graphfuente'") ///

		restore
	}



	*************************/
	*** 2 Proyeccion anual ***
	**************************
	if tipo_de_informacion == "Flujo" {
		
		collapse (sum) monto* acum_prom (last) mes poblacion pibY deflactor if monto != ., by(anio nombre clave_de_concepto unidad_de_medida)

		if "`proyeccion'" == "proyeccion" {
			replace monto = monto/acum_prom if mes < 12
			replace monto_pib = monto/pibY*100 if mes < 12
			replace monto_pc = monto/poblacion/deflactor if mes < 12
			replace montomill = monto/1000000/deflactor if mes < 12
		}

		local textografica `"{bf:Promedio a `mesname'}: `=string(acum_prom[_N]*100,"%5.1fc")'% del total anual."'
		local palabra "Proyectado"
	}
	else if tipo_de_informacion == "Saldo" {
		tempvar maxmes
		egen `maxmes' = max(mes), by(anio)
		sort anio mes
		collapse (last) monto* mes poblacion pibY deflactor if monto != ., by(anio nombre clave_de_concepto unidad_de_medida)
		g acum_prom = 1
	}
	*tsset aniomes
	local prianio = anio in 1
	local ultanio = anio in -1
	local ultmes = mes in -1
	return local ultimoAnio = `ultanio'
	return local ultimoMes = `ultmes'

	** 2.1. Grafica **
	if "`nographs'" != "nographs" {

		if "$export" == "" {
			local graphtitle "{bf:`=nombre[1]'}"
		}
		else {
			local graphtitle ""
		}

		tabstat montomill monto_pc monto_pib, by(anio) stat(min max) save
		return list
		tempname rango
		matrix `rango' = r(StatTotal)

		/*twoway (bar montomill anio if inrange(anio, 2001, 2006), ///
					mlabel(montomill) mlabpos(7) mlabcolor(white) mlabsize(small) msize(large) mlabangle(90) barwidth(.75)) ///
			(bar montomill anio if inrange(anio, 2007, 2012), ///
					mlabel(montomill) mlabpos(7) mlabcolor(white) mlabsize(small) msize(large) mlabangle(90) barwidth(.75)) ///
			(bar montomill anio if inrange(anio, 2013, 2018), ///
					mlabel(montomill) mlabpos(7) mlabcolor(white) mlabsize(small) msize(large) mlabangle(90) barwidth(.75)) ///
			(bar montomill anio if inrange(anio, 2019, 2024), ///
					mlabel(montomill) mlabpos(7) mlabcolor(white) mlabsize(small) msize(large) mlabangle(90) barwidth(.75)) ///
			(bar montomill anio if anio > 2024, ///
					mlabel(montomill) mlabpos(7) mlabcolor(white) mlabsize(small) msize(large) mlabangle(90) barwidth(.75)) ///
			(connected monto_pc anio if anio > 2000 & anio <= 2006, ///
					yaxis(2) pstyle(p1) mlabel(monto_pc) mlabpos(12) mlabcolor("111 111 111") mlabsize(small) lpattern(dot) msize(large)) ///
			(connected monto_pc anio if anio > 2006 & anio <= 2012, ///	
					yaxis(2) pstyle(p2) mlabel(monto_pc) mlabpos(12) mlabcolor("111 111 111") mlabsize(small) lpattern(dot) msize(large)) ///
			(connected monto_pc anio if anio > 2012 & anio <= 2018, ///
					yaxis(2) pstyle(p3) mlabel(monto_pc) mlabpos(12) mlabcolor("111 111 111") mlabsize(small) lpattern(dot) msize(large)) ///
			(connected monto_pc anio if anio > 2018 & anio <= 2024, ///
					yaxis(2) pstyle(p4) mlabel(monto_pc) mlabpos(12) mlabcolor("111 111 111") mlabsize(small) lpattern(dot) msize(large)) ///
			(connected monto_pc anio if anio > 2024, ///
					yaxis(2) pstyle(p5) mlabel(monto_pc) mlabpos(12) mlabcolor("111 111 111") mlabsize(small) lpattern(dot) msize(large)) ///
			if anio > 2000, ///
			title("`graphtitle'"`textsize') ///
			subtitle(" Montos reportados (millones MXN `aniovp') y por persona", margin(bottom)) ///
			ytitle("", axis(1)) ///
			ytitle("", axis(2)) ///
			xtitle("") ///
			xlabel(`=`prianio'+1'(1)`ultanio') ///
			ylabel(none, format(%15.0fc)) ///
			yscale(range(0 `=`rango'[2,1]*1.75')) ///
			ylabel(none, axis(2) format(%7.0fc) noticks) ///
			yscale(range(0 `=`rango'[1,2]-1.75*(`rango'[2,2]-`rango'[1,2])') noline axis(2)) ///
			legend(off label(1 "Reportado") label(2 "LIF") order(1 2)) ///
			text(`text1', yaxis(2) color(white) size(large)) ///
			caption("`graphfuente'") ///
			note("{c U'}ltimo dato: `ultanio'm`ultmes'.") ///
			name(`anything'PC, replace)

		capture confirm existence $export
		if _rc == 0 {
			graph export "$export/`anything'PC.png", replace name(`anything'PC)
		}*/


		twoway (bar montomill anio if anio < `ultanio' & anio >= `desde', ///
				mlabel(montomill) mlabpos(7) mlabcolor(white) mlabsize(small) msize(large) mlabangle(90) barwidth(.75)) ///
			(bar montomill anio if anio >= `ultanio', ///
				mlabel(montomill) mlabpos(7) mlabcolor(white) mlabsize(small) msize(large) mlabangle(90) barwidth(.75)) ///
			(connected monto_pib anio if anio < `ultanio' & anio >= `desde', ///
				yaxis(2) pstyle(p1) mlabel(monto_pib) mlabpos(12) mlabcolor("111 111 111") mlabsize(medium) lpattern(dot) msize(large)) ///
			(connected monto_pib anio if anio >= `ultanio', ///
				yaxis(2) pstyle(p2) mlabel(monto_pib) mlabpos(12) mlabcolor("111 111 111") mlabsize(medium) lpattern(dot) msize(large)), ///
			title("`graphtitle'"`textsize') ///
			subtitle(" Montos reportados (millones MXN `aniovp') y como % del PIB", margin(bottom)) ///
			///b1title(`"`textografica'"') ///
			ytitle("", axis(1)) ///
			ytitle("", axis(2)) ///
			xtitle("") ///
			///xlabel(`prianio' `=round(`prianio',5)'(5)`ultanio') ///
			xlabel(`desde'(1)`ultanio') ///
			ylabel(, format(%15.0fc)) ///
			yscale(range(0 `=`rango'[2,1]*1.75')) ///
			ylabel(none, axis(2) format(%7.0fc) noticks) ///
			yscale(range(0 `=`rango'[1,3]-1.75*(`rango'[2,3]-`rango'[1,3])') noline axis(2)) ///
			legend(off label(1 "Reportado") label(2 "LIF") order(1 2)) ///
			text(`text1', yaxis(2) color(white) size(large)) ///
			caption("`graphfuente'") ///
			note("{c U'}ltimo dato: `ultanio'm`ultmes'.") ///
			name(`anything'PIB, replace)

		capture confirm existence $export
		if _rc == 0 {
			graph export "$export/`anything'PIB.png", replace name(`anything'PIB)
		}
	}
	noisily list anio mes acum_prom monto monto_pib monto_pc, separator(30) string(30)
}
end


program define UpdateDatosAbiertos, return

	syntax [, UPDATE ZIPFILE]

	************************
	*** 1. Base de datos ***
	************************
	local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
	local aniovp = substr(`"`=trim("`fecha'")'"',1,4)
	local mesvp = substr(`"`=trim("`fecha'")'"',6,2)

	capture mkdir "`c(sysdir_site)'/03_temp/Datos Abiertos/"
	capture use "`c(sysdir_site)'/04_master/DatosAbiertos.dta", clear
	if (_rc == 0 & "`update'" != "update") {	
		sort anio mes
		return local ultanio = anio[_N]
		return local ultmes = mes[_N]
		if (`aniovp' == anio[_N] & `mesvp'-2 <= mes[_N]) | (`aniovp'+1 == anio[_N] & `mesvp'-2 < 0) {
			noisily di _newline in g "Datos Abiertos: " in y "base actualizada." in g " {c U'}ltimo dato: " in y "`=anio[_N]'m`=mes[_N]'."
			return local updated = "yes"
			exit
		}
	}
	noisily di _newline in g "Datos Abiertos: " in y "ACTUALIZANDO. Favor de esperar... (5 min. aprox.)"
	*noisily di in g "{c U'}ltimo dato: " in y "`=anio[_N]'m`=mes[_N]'."

	if "`c(console)'" == "console" {
		exit
	}

	*****************************************
	** 1.1 Ingreso, gasto y financiamiento **
	if "`zipfile'" == "" {
		import delimited "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/ingreso_gasto_finan.csv", clear
	}
	else {
		cd "`c(sysdir_site)'/03_temp/Datos Abiertos"
		unzipfile "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/ingreso_gasto_finan.zip", replace
		import delimited "`c(sysdir_site)'/03_temp/Datos Abiertos/ingreso_gasto_finan.csv", clear
		save "`c(sysdir_site)'/03_temp/Datos Abiertos/ingreso_gasto_finan.dta", replace
	}
	tempfile ing
	save "`ing'"
	
	capture confirm file "`c(sysdir_site)'/03_temp/Datos Abiertos/ingreso_gasto_finan_hist.dta"
	if _rc != 0 {
		import delimited "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/ingreso_gasto_finan_hist.csv", clear
		save "`c(sysdir_site)'/03_temp/Datos Abiertos/ingreso_gasto_finan_hist.dta", replace
	}
	if "`zipfile'" == "zipfile" {
		cd "`c(sysdir_site)'/03_temp/Datos Abiertos"
		unzipfile "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/ingreso_gasto_finan_hist.zip", replace
		import delimited "`c(sysdir_site)'/03_temp/Datos Abiertos/ingreso_gasto_finan_hist.csv", clear
		save "`c(sysdir_site)'/03_temp/Datos Abiertos/ingreso_gasto_finan_hist.dta", replace
	}
	use "`c(sysdir_site)'/03_temp/Datos Abiertos/ingreso_gasto_finan_hist.dta", clear
	tempfile ingH
	save "`ingH'"

	***************
	** 1.2 Deuda **
	if "`zipfile'" == "" {
		import delimited "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/deuda_publica.csv", clear
	}
	else {
		cd "`c(sysdir_site)'/03_temp/Datos Abiertos"
		unzipfile "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/deuda_publica.zip", replace
		import delimited "`c(sysdir_site)'/03_temp/Datos Abiertos/deuda_publica.csv", clear
		save "`c(sysdir_site)'/03_temp/Datos Abiertos/deuda_publica.dta", replace
	}	
	tempfile deuda
	save "`deuda'"

	capture confirm file "`c(sysdir_site)'/03_temp/Datos Abiertos/deuda_publica_hist.dta"
	if _rc != 0 {
		import delimited "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/deuda_publica_hist.csv", clear
		save "`c(sysdir_site)'/03_temp/Datos Abiertos/deuda_publica_hist.dta", replace
	}
	if "`zipfile'" == "zipfile" {
		cd "`c(sysdir_site)'/03_temp/Datos Abiertos"
		unzipfile "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/deuda_publica_hist.zip", replace
		import delimited "`c(sysdir_site)'/03_temp/Datos Abiertos/deuda_publica_hist.csv", clear
		save "`c(sysdir_site)'/03_temp/Datos Abiertos/deuda_publica_hist.dta", replace
	}
	use "`c(sysdir_site)'/03_temp/Datos Abiertos/deuda_publica_hist.dta", clear
	tempfile deudaH
	save "`deudaH'"

	****************
	** 1.3 SHRFSP **
	if "`zipfile'" == "" {
		import delimited "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/shrfsp_deuda_amplia_actual.csv", clear
	}
	else {
		cd "`c(sysdir_site)'/03_temp/Datos Abiertos"
		unzipfile "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/shrfsp_deuda_amplia_actual.zip", replace
		import delimited "`c(sysdir_site)'/03_temp/Datos Abiertos/shrfsp_deuda_amplia_actual.csv", clear
		save "`c(sysdir_site)'/03_temp/Datos Abiertos/shrfsp_deuda_amplia_actual.dta", replace
	}
	tempfile shrf
	save "`shrf'"

	capture confirm file "`c(sysdir_site)'/03_temp/Datos Abiertos/shrfsp_deuda_amplshrfsp_deuda_amplia_antes_2014ia_actual_hist.dta"
	if _rc != 0 {
		import delimited "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/shrfsp_deuda_amplia_antes_2014.csv", clear
		save "`c(sysdir_site)'/03_temp/Datos Abiertos/shrfsp_deuda_amplia_antes_2014.dta", replace
	}
	if "`zipfile'" == "zipfile" {
		cd "`c(sysdir_site)'/03_temp/Datos Abiertos"
		unzipfile "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/shrfsp_deuda_amplia_antes_2014.zip", replace
		import delimited "`c(sysdir_site)'/03_temp/Datos Abiertos/shrfsp_deuda_amplia_antes_2014.csv", clear
		save "`c(sysdir_site)'/03_temp/Datos Abiertos/shrfsp_deuda_amplia_antes_2014.dta", replace
	}
	use "`c(sysdir_site)'/03_temp/Datos Abiertos/shrfsp_deuda_amplia_antes_2014.dta", clear
	tempfile shrfH
	save "`shrfH'"

	**************
	** 1.4 RFSP **
	if "`zipfile'" == "" {
		import delimited "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/rfsp.csv", clear
	}
	else {
		cd "`c(sysdir_site)'/03_temp/Datos Abiertos"
		unzipfile "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/rfsp.zip", replace
		import delimited "`c(sysdir_site)'/03_temp/Datos Abiertos/rfsp.csv", clear
		save "`c(sysdir_site)'/03_temp/Datos Abiertos/rfsp.dta", replace
	}
	tempfile rf
	save "`rf'"

	capture confirm file "`c(sysdir_site)'/03_temp/Datos Abiertos/rfsp_metodologia_anterior.dta"
	if _rc != 0 {
		import delimited "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/rfsp_metodologia_anterior.csv", clear
		save "`c(sysdir_site)'/03_temp/Datos Abiertos/rfsp_metodologia_anterior.dta", replace
	}
	if "`zipfile'" == "zipfile" {
		cd "`c(sysdir_site)'/03_temp/Datos Abiertos"
		unzipfile "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/rfsp_metodologia_anterior.zip", replace
		import delimited "`c(sysdir_site)'/03_temp/Datos Abiertos/rfsp_metodologia_anterior.csv", clear
		save "`c(sysdir_site)'/03_temp/Datos Abiertos/rfsp_metodologia_anterior.dta", replace
	}
	use "`c(sysdir_site)'/03_temp/Datos Abiertos/rfsp_metodologia_anterior.dta", clear
	tempfile rfH
	save "`rfH'"

	*************************************************
	** 1.5 Transferencias a Entidades y Municipios **
	if "`zipfile'" == "" {
		import delimited "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/transferencias_entidades_fed.csv", clear
	}
	else {
		cd "`c(sysdir_site)'/03_temp/Datos Abiertos"
		unzipfile "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/transferencias_entidades_fed.zip", replace
		import delimited "`c(sysdir_site)'/03_temp/Datos Abiertos/transferencias_entidades_fed.csv", clear
		save "`c(sysdir_site)'/03_temp/Datos Abiertos/transferencias_entidades_fed.dta", replace
	}
	tempfile gf
	save "`gf'"

	capture confirm file "`c(sysdir_site)'/03_temp/Datos Abiertos/transferencias_entidades_fed_hist.dta"
	if _rc != 0 {
		import delimited "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/transferencias_entidades_fed_hist.csv", clear
		save "`c(sysdir_site)'/03_temp/Datos Abiertos/transferencias_entidades_fed_hist.dta", replace
	}
	if "`zipfile'" == "zipfile" {
		cd "`c(sysdir_site)'/03_temp/Datos Abiertos"
		unzipfile "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/transferencias_entidades_fed_hist.zip", replace
		import delimited "`c(sysdir_site)'/03_temp/Datos Abiertos/transferencias_entidades_fed_hist.csv", clear
		save "`c(sysdir_site)'/03_temp/Datos Abiertos/transferencias_entidades_fed_hist.dta", replace
	}
	use "`c(sysdir_site)'/03_temp/Datos Abiertos/transferencias_entidades_fed_hist.dta", clear
	tempfile gfH
	save "`gfH'"
	
	***********************************************************
	** 1.6 Asignación y ejecución del presupuesto de egresos **
	capture confirm file "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2024.dta"
	if _rc != 0 {
		import delimited "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/asignacion_ejecucion_2024.csv", clear
		save "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2024.dta", replace
	}
	if "`zipfile'" == "zipfile" {
		cd "`c(sysdir_site)'/03_temp/Datos Abiertos"
		unzipfile "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/asignacion_ejecucion_2024.zip", replace
		import delimited "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2024.csv", clear
		save "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2024.dta", replace
	}
	use "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2024.dta", clear
	tempfile asignacion2024
	save "`asignacion2024'"

	capture confirm file "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2023.dta"
	if _rc != 0 {
		import delimited "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/asignacion_ejecucion_2023.csv", clear
		save "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2023.dta", replace
	}
	if "`zipfile'" == "zipfile" {
		cd "`c(sysdir_site)'/03_temp/Datos Abiertos"
		unzipfile "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/asignacion_ejecucion_2023.zip", replace
		import delimited "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2023.csv", clear
		save "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2023.dta", replace
	}
	use "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2023.dta", clear
	tempfile asignacion2023
	save "`asignacion2023'"

	capture confirm file "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2022.dta"
	if _rc != 0 {
		import delimited "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/asignacion_ejecucion_2022.csv", clear
		save "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2022.dta", replace
	}
	if "`zipfile'" == "zipfile" {
		cd "`c(sysdir_site)'/03_temp/Datos Abiertos"
		unzipfile "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/asignacion_ejecucion_2022.zip", replace
		import delimited "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2022.csv", clear
		save "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2022.dta", replace
	}
	use "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2022.dta", clear
	tempfile asignacion2022
	save "`asignacion2022'"

	capture confirm file "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2021.dta"
	if _rc != 0 {
		import delimited "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/asignacion_ejecucion_2021.csv", clear
		save "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2021.dta", replace
	}
	if "`zipfile'" == "zipfile" {
		cd "`c(sysdir_site)'/03_temp/Datos Abiertos"
		unzipfile "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/asignacion_ejecucion_2021.zip", replace
		import delimited "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2021.csv", clear
		save "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2021.dta", replace
	}
	use "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2021.dta", clear
	tempfile asignacion2021
	save "`asignacion2021'"

	capture confirm file "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2020.dta"
	if _rc != 0 {
		import delimited "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/asignacion_ejecucion_2020.csv", clear
		save "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2020.dta", replace
	}
	if "`zipfile'" == "zipfile" {
		cd "`c(sysdir_site)'/03_temp/Datos Abiertos"
		unzipfile "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/asignacion_ejecucion_2020.zip", replace
		import delimited "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2020.csv", clear
		save "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2020.dta", replace
	}
	use "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2020.dta", clear
	tempfile asignacion2020
	save "`asignacion2020'"

	capture confirm file "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2019.dta"
	if _rc != 0 {
		import delimited "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/asignacion_ejecucion_2019.csv", clear
		save "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2019.dta", replace
	}
	if "`zipfile'" == "zipfile" {
		cd "`c(sysdir_site)'/03_temp/Datos Abiertos"
		unzipfile "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/asignacion_ejecucion_2019.zip", replace
		import delimited "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2019.csv", clear
		save "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2019.dta", replace
	}
	use "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2019.dta", clear
	tempfile asignacion2019
	save "`asignacion2019'"

	capture confirm file "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2018.dta"
	if _rc != 0 {
		import delimited "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/asignacion_ejecucion_2018.csv", clear
		save "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2018.dta", replace
	}
	if "`zipfile'" == "zipfile" {
		cd "`c(sysdir_site)'/03_temp/Datos Abiertos"
		unzipfile "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/asignacion_ejecucion_2018.zip", replace
		import delimited "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2018.csv", clear
		save "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2018.dta", replace
	}
	use "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2018.dta", clear
	tempfile asignacion2018
	save "`asignacion2018'"

	capture confirm file "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2017.dta"
	if _rc != 0 {
		import delimited "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/asignacion_ejecucion_2017.csv", clear
		save "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2017.dta", replace
	}
	if "`zipfile'" == "zipfile" {
		cd "`c(sysdir_site)'/03_temp/Datos Abiertos"
		unzipfile "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/asignacion_ejecucion_2017.zip", replace
		import delimited "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2017.csv", clear
		save "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2017.dta", replace
	}
	use "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2017.dta", clear
	tempfile asignacion2017
	save "`asignacion2017'"

	capture confirm file "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2016.dta"
	if _rc != 0 {
		import delimited "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/asignacion_ejecucion_2016.csv", clear
		save "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2016.dta", replace
	}
	if "`zipfile'" == "zipfile" {
		cd "`c(sysdir_site)'/03_temp/Datos Abiertos"
		unzipfile "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/asignacion_ejecucion_2016.zip", replace
		import delimited "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2016.csv", clear
		save "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2016.dta", replace
	}
	use "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2016.dta", clear
	tempfile asignacion2016
	save "`asignacion2016'"

	capture confirm file "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2015.dta"
	if _rc != 0 {
		import delimited "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/asignacion_ejecucion_2015.csv", clear
		save "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2015.dta", replace
	}
	if "`zipfile'" == "zipfile" {
		cd "`c(sysdir_site)'/03_temp/Datos Abiertos"
		unzipfile "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/asignacion_ejecucion_2015.zip", replace
		import delimited "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2015.csv", clear
		save "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2015.dta", replace
	}
	use "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2015.dta", clear
	tempfile asignacion2015
	save "`asignacion2015'"

	capture confirm file "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2014.dta"
	if _rc != 0 {
		import delimited "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/asignacion_ejecucion_2014.csv", clear
		save "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2014.dta", replace
	}
	if "`zipfile'" == "zipfile" {
		cd "`c(sysdir_site)'/03_temp/Datos Abiertos"
		unzipfile "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/asignacion_ejecucion_2014.zip", replace
		import delimited "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2014.csv", clear
		save "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2014.dta", replace
	}
	use "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2014.dta", clear
	tempfile asignacion2014
	save "`asignacion2014'"

	capture confirm file "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2013.dta"
	if _rc != 0 {
		import delimited "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/asignacion_ejecucion_2013.csv", clear
		save "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2013.dta", replace
	}
	if "`zipfile'" == "zipfile" {
		cd "`c(sysdir_site)'/03_temp/Datos Abiertos"
		unzipfile "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/asignacion_ejecucion_2013.zip", replace
		import delimited "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2013.csv", clear
		save "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2013.dta", replace
	}
	use "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2013.dta", clear
	tempfile asignacion2013
	save "`asignacion2013'"

	capture confirm file "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2012.dta"
	if _rc != 0 {
		import delimited "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/asignacion_ejecucion_2012.csv", clear
		save "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2012.dta", replace
	}
	if "`zipfile'" == "zipfile" {
		cd "`c(sysdir_site)'/03_temp/Datos Abiertos"
		unzipfile "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/asignacion_ejecucion_2012.zip", replace
		import delimited "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2012.csv", clear
		save "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2012.dta", replace
	}
	use "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2012.dta", clear
	tempfile asignacion2012
	save "`asignacion2012'"

	capture confirm file "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2011.dta"
	if _rc != 0 {
		import delimited "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/asignacion_ejecucion_2011.csv", clear
		save "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2011.dta", replace
	}
	if "`zipfile'" == "zipfile" {
		cd "`c(sysdir_site)'/03_temp/Datos Abiertos"
		unzipfile "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/asignacion_ejecucion_2011.zip", replace
		import delimited "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2011.csv", clear
		save "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2011.dta", replace
	}
	use "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2011.dta", clear
	tempfile asignacion2011
	save "`asignacion2011'"

	capture confirm file "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2010.dta"
	if _rc != 0 {
		import delimited "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/asignacion_ejecucion_2010.csv", clear
		save "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2010.dta", replace
	}
	if "`zipfile'" == "zipfile" {
		cd "`c(sysdir_site)'/03_temp/Datos Abiertos"
		unzipfile "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/asignacion_ejecucion_2010.zip", replace
		import delimited "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2010.csv", clear
		save "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2010.dta", replace
	}
	use "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2010.dta", clear
	tempfile asignacion2010
	save "`asignacion2010'"

	capture confirm file "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2009.dta"
	if _rc != 0 {
		import delimited "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/asignacion_ejecucion_2009.csv", clear
		save "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2009.dta", replace
	}
	if "`zipfile'" == "zipfile" {
		cd "`c(sysdir_site)'/03_temp/Datos Abiertos"
		unzipfile "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/asignacion_ejecucion_2009.zip", replace
		import delimited "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2009.csv", clear
		save "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2009.dta", replace
	}
	use "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2009.dta", clear
	tempfile asignacion2009
	save "`asignacion2009'"

	capture confirm file "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2008.dta"
	if _rc != 0 {
		import delimited "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/asignacion_ejecucion_2008.csv", clear
		save "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2008.dta", replace
	}
	if "`zipfile'" == "zipfile" {
		cd "`c(sysdir_site)'/03_temp/Datos Abiertos"
		unzipfile "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/asignacion_ejecucion_2008.zip", replace
		import delimited "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2008.csv", clear
		save "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2008.dta", replace
	}
	use "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2008.dta", clear
	tempfile asignacion2008
	save "`asignacion2008'"

	capture confirm file "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2007.dta"
	if _rc != 0 {
		import delimited "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/asignacion_ejecucion_2007.csv", clear
		save "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2007.dta", replace
	}
	if "`zipfile'" == "zipfile" {
		cd "`c(sysdir_site)'/03_temp/Datos Abiertos"
		unzipfile "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/asignacion_ejecucion_2007.zip", replace
		import delimited "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2007.csv", clear
		save "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2007.dta", replace
	}
	use "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2007.dta", clear
	tempfile asignacion2007
	save "`asignacion2007'"

	capture confirm file "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2006.dta"
	if _rc != 0 {
		import delimited "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/asignacion_ejecucion_2006.csv", clear
		save "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2006.dta", replace
	}
	if "`zipfile'" == "zipfile" {
		cd "`c(sysdir_site)'/03_temp/Datos Abiertos"
		unzipfile "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/asignacion_ejecucion_2006.zip", replace
		import delimited "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2006.csv", clear
		save "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2006.dta", replace
	}
	use "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2006.dta", clear
	tempfile asignacion2006
	save "`asignacion2006'"

	capture confirm file "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2005.dta"
	if _rc != 0 {
		import delimited "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/asignacion_ejecucion_2005.csv", clear
		save "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2005.dta", replace
	}
	if "`zipfile'" == "zipfile" {
		cd "`c(sysdir_site)'/03_temp/Datos Abiertos"
		unzipfile "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/asignacion_ejecucion_2005.zip", replace
		import delimited "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2005.csv", clear
		save "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2005.dta", replace
	}
	use "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2005.dta", clear
	tempfile asignacion2005
	save "`asignacion2005'"

	capture confirm file "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2004.dta"
	if _rc != 0 {
		import delimited "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/asignacion_ejecucion_2004.csv", clear
		save "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2004.dta", replace
	}
	if "`zipfile'" == "zipfile" {
		cd "`c(sysdir_site)'/03_temp/Datos Abiertos"
		unzipfile "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/asignacion_ejecucion_2004.zip", replace
		import delimited "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2004.csv", clear
		save "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2004.dta", replace
	}
	use "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2004.dta", clear
	tempfile asignacion2004
	save "`asignacion2004'"

	capture confirm file "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2003.dta"
	if _rc != 0 {
		import delimited "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/asignacion_ejecucion_2003.csv", clear
		save "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2003.dta", replace
	}
	if "`zipfile'" == "zipfile" {
		cd "`c(sysdir_site)'/03_temp/Datos Abiertos"
		unzipfile "https://www.secciones.hacienda.gob.mx/work/models/estadisticas_oportunas/datos_abiertos_eopf/asignacion_ejecucion_2003.zip", replace
		import delimited "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2003.csv", clear
		save "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2003.dta", replace
	}
	use "`c(sysdir_site)'/03_temp/Datos Abiertos/asignacion_ejecucion_2003.dta", clear
	tempfile asignacion2003
	save "`asignacion2003'"



	**************
	** 2 Append **
	**************/
	use `ing', clear
	append using "`ingH'"
	append using "`deuda'"
	append using "`deudaH'"
	append using "`shrf'"
	append using "`shrfH'"
	append using "`rf'"
	append using "`rfH'"
	append using "`gf'"
	append using "`gfH'"
	append using "`asignacion2024'"
	append using "`asignacion2023'"
	append using "`asignacion2022'"
	append using "`asignacion2021'"
	append using "`asignacion2020'"
	append using "`asignacion2019'"
	append using "`asignacion2018'"
	append using "`asignacion2017'"
	append using "`asignacion2016'"
	append using "`asignacion2015'"
	append using "`asignacion2014'"
	append using "`asignacion2013'"
	append using "`asignacion2012'"
	append using "`asignacion2011'"
	append using "`asignacion2010'"
	append using "`asignacion2009'"
	append using "`asignacion2008'"
	append using "`asignacion2007'"
	append using "`asignacion2006'"
	append using "`asignacion2005'"
	append using "`asignacion2004'"
	append using "`asignacion2003'"



	****************
	*** 3 Limpia ***
	****************
	rename ciclo anio

	replace mes = "1" if mes == "Enero"
	replace mes = "2" if mes == "Febrero"
	replace mes = "3" if mes == "Marzo"
	replace mes = "4" if mes == "Abril"
	replace mes = "5" if mes == "Mayo"
	replace mes = "6" if mes == "Junio"
	replace mes = "7" if mes == "Julio"
	replace mes = "8" if mes == "Agosto"
	replace mes = "9" if mes == "Septiembre"
	replace mes = "10" if mes == "Octubre"
	replace mes = "11" if mes == "Noviembre"
	replace mes = "12" if mes == "Diciembre"
	destring mes, replace

	g trimestre = 1 if mes >= 1 & mes <= 3
	replace trimestre = 2 if mes >= 4 & mes <= 6
	replace trimestre = 3 if mes >= 7 & mes <= 9
	replace trimestre = 4 if mes >= 10 & mes <= 12

	replace monto = monto*1000 if unidad_de_medida == "Miles de Pesos"
	replace monto = monto*1000 if unidad_de_medida == "Miles de Dólares" | unidad_de_medida == "Miles de D?lares"
	format monto %20.0fc

	replace unidad_de_medida = "Pesos" if unidad_de_medida == "Miles de Pesos"
	replace unidad_de_medida = "Dólares" if unidad_de_medida == "Miles de Dólares" | unidad_de_medida == "Miles de D?lares"

	format nombre %30s

	g aniotrimestre = yq(anio,trimestre)
	format aniotrimestre %tq

	g aniomes = ym(anio,mes)
	format aniomes %tm

	label var anio "a{c n~}o"
	label var monto "Monto nominal (pesos)"	
	
	collapse (mean) monto, by(anio* mes trimestre nombre clave_de_concepto tipo_de_informacion unidad_de_medida)

	tempfile datosabiertos
	save "`datosabiertos'"



	****************
	*** 4 Extras ***
	****************

	***************************************************
	** 4.1 ISR fisicas, morales, asalariados y otros **
	import excel "`c(sysdir_site)'/01_raw/ISRInformesTrimestrales.xlsx", ///
		clear sheet("TipoDeContribuyente") firstrow case(lower)
	tsset anio trimestre
	drop total

	forvalues t = 4(-1)2 {
		foreach k of varlist pm-aux {
			replace `k' = `k' - L.`k' if trimestre == `t'
		}
	}
	tempfile isrinftrim
	save "`isrinftrim'"

	use if clave_de_concepto == "XNA0120" using "`datosabiertos'", clear
	collapse (mean) monto, by(anio* mes trimestre nombre clave_de_concepto)
	merge m:1 (anio trimestre) using "`isrinftrim'", nogen

	tempvar prop_m prop_f prop_s
	g `prop_m' = (pm+aux)/(pm+pfae+pfsae+ret_ss_pm+ret_ss_pf+aux)
	g `prop_f' = (pfae+pfsae)/(pm+pfae+pfsae+ret_ss_pm+ret_ss_pf+aux)
	g `prop_s' = (ret_ss_pm+ret_ss_pf)/(pm+pfae+pfsae+ret_ss_pm+ret_ss_pf+aux)

	noisily tabstat `prop_m' `prop_f' `prop_s', save
	tempname PROP
	matrix `PROP' = r(StatTotal)

	g double monto_m = monto*`prop_m'
	g double monto_f = monto*`prop_f'
	g double monto_s = monto*`prop_s'

	replace monto_m = monto*`PROP'[1,1] if pm == .
	replace monto_f = monto*`PROP'[1,2] if pm == .
	replace monto_s = monto*`PROP'[1,3] if pm == .

	egen double monto_pf = rsum(monto_s monto_f)

	format monto* %20.0fc
	format nombre %30s
	keep anio* mes monto_* trimestre nombre
	reshape long monto, i(anio* mes trimestre nombre) j(clave_de_concepto) string

	replace nombre = nombre+" (Morales)" if clave_de_concepto == "_m"
	replace nombre = nombre+" (F{c i'}sicas)" if clave_de_concepto == "_f"
	replace nombre = nombre+" (Salarios)" if clave_de_concepto == "_s"
	replace nombre = nombre+" (F{c i'}sicas + Salarios)" if clave_de_concepto == "_pf"

	replace clave_de_concepto = "XNA0120"+clave_de_concepto

	g tipo_de_informacion = "Flujo"
	drop if mes == .

	tempfile isr
	save "`isr'"



	***************************************
	** 4.2 ISR morales sin ISR petrolero **
	use if clave_de_concepto == "XOA0825" using `datosabiertos', clear
	rename monto monto_isrpet
	tempfile isrpet
	save "`isrpet'"

	use if clave == "XNA0120_m" using `isr', clear
	merge 1:1 (anio mes) using `isrpet', nogen

	replace monto_isrpet = 0 if monto_isrpet == .
	replace monto = monto - monto_isrpet
	drop monto_isrpet

	replace clave_de_concepto = "XNA0120_nopet"
	replace nombre = "Impuesto Sobre la Renta (Morales, no petroleros)"

	tempfile isrpmnopet
	save "`isrpmnopet'"


	***********************************
	** 4.3 Derechos petroleros y FMP **
	use if clave_de_concepto == "XOA0806" | clave_de_concepto == "XAB2123" using `datosabiertos', clear
	collapse (sum) monto, by(anio mes trimestre aniotrimestre aniomes)

	g nombre = "Derechos a los hidrocarburos // FMP"
	g clave_de_concepto = "FMP_Derechos"
	g tipo_de_informacion = "Flujo"

	tempfile fmp
	save "`fmp'"


	*************************************************
	** 4.4 Deficit Empresas Productivas del Estado **
	use if clave_de_concepto == "XAA1210" | clave_de_concepto == "XOA0101" using `datosabiertos', clear
	collapse (sum) monto, by(anio mes trimestre aniotrimestre aniomes)

	replace monto = -monto
	g clave_de_concepto = "deficit_epe"
	g nombre = "Balance presupuestario de las Empresas Productivas del Estado"
	g tipo_de_informacion = "Flujo"

	tempfile deficit_epe
	save "`deficit_epe'"


	**********************************************************
	** 4.5 Deficit Organismos y empresas de control directo **
	use if clave_de_concepto == "XKE0000" | clave_de_concepto == "XOA0105" ///
		| clave_de_concepto == "XOA0106" | clave_de_concepto == "XOA0103" using `datosabiertos', clear
	collapse (sum) monto, by(anio mes trimestre aniotrimestre aniomes)

	replace monto = -monto
	g clave_de_concepto = "deficit_oye"
	g nombre = "Balance presupuestario de los organismos y empresas de control directo"
	g tipo_de_informacion = "Flujo"

	tempfile deficit_oye
	save "`deficit_oye'"


	***************************************************
	** 4.6 Diferencias con fuentes de financiamiento **
	use if clave_de_concepto == "XOA0108" using `datosabiertos', clear

	replace monto = -monto
	replace clave_de_concepto = "XOA0108_2"
	replace tipo_de_informacion = "Flujo"

	tempfile diferencias
	save "`diferencias'"


	****************************
	** 4.7 Gasto federalizado **
	use if clave_de_concepto == "XAC2800" | clave_de_concepto == "XAC3300" using `datosabiertos', clear
	collapse (sum) monto, by(anio mes trimestre aniotrimestre aniomes)

	g clave_de_concepto = "XACGF00"
	g nombre = "Gasto Federalizado"
	g tipo_de_informacion = "Flujo"

	tempfile gastofed
	save "`gastofed'"


	************************
	** 4.7 Otros ingresos **
	use if clave_de_concepto == "XBB24" | clave_de_concepto == "XNA0151" ///
		| clave_de_concepto == "XNA0152" | clave_de_concepto == "XNA0153" ///
		| clave_de_concepto == "XOA0111" using `datosabiertos', clear
	collapse (sum) monto, by(anio mes trimestre aniotrimestre aniomes)

	g clave_de_concepto = "OtrosIngresosC"
	g nombre = "Aprov, Der, Prod, otros"
	g tipo_de_informacion = "Flujo"

	tempfile otrosingresos
	save "`otrosingresos'"



	*****************
	*** 5 Guardar ***
	*****************
	use "`datosabiertos'", clear
	append using "`isr'"
	append using "`fmp'"
	append using "`isrpmnopet'"
	append using "`deficit_epe'"
	append using "`deficit_oye'"
	append using "`diferencias'"
	append using "`gastofed'"
	append using "`otrosingresos'"

	*drop if monto == .
	*drop tema subtema sector ambito base unidad periodo* frecuencia
	replace nombre = subinstr(nombre,"  "," ",.)
	replace nombre = trim(nombre)
	compress

	if `c(version)' > 13.1 {
		saveold "`c(sysdir_site)'/04_master/DatosAbiertos.dta", replace version(13)
	}
	else {
		save "`c(sysdir_site)'/04_master/DatosAbiertos.dta", replace
	}

	noisily di in g "{c U'}ltimo dato: " in y "`=anio[_N]'m`=mes[_N]'."
end


**************************************
**** Base de datos: Deflactor.dta ****
**************************************
program define UpdateDeflactor
quietly {
	noisily di in g "  Updating Deflactor.dta..." _newline

	** 1. Importar variables de interés desde el BIE **
	run "`c(sysdir_site)'/AccesoBIE.do" "910392" "inpc"

	** 2 Label variables **
	label var inpc "Índice Nacional de Precios al Consumidor"

	** 3 Dar formato a variables **
	format inpc %8.3f

	** 4 Time Series **
	split periodo, destring p("/") //ignore("r p")
	rename periodo1 anio
	label var anio "anio"
	rename periodo2 mes
	label var mes "mes"
	drop periodo

	** 2.5 Guardar **
	order anio inpc
	compress
	noisily di in g "  Último anio: " in y anio[_N]
	noisily di in g "  Último mes: " in y mes[_N]

	save "`c(sysdir_site)'/04_master/Deflactor.dta", replace
}
end
