program define LIF, return
quietly {
	timer on 4

	** 0.1 Anio valor presente **
	capture confirm scalar aniovp
	if _rc == 0 {
		local aniovp = scalar(aniovp)
	}
	else {
		local fecha : di %td_CY-N-D  date("$S_DATE", "DMY")
		local aniovp = substr(`"`=trim("`fecha'")'"',1,4)
	}

	** 0.2 Base LIF **
	capture confirm file "`c(sysdir_site)'/04_master/LIF.dta"
	if _rc != 0 {
		noisily UpdateLIF
	}



	***************
	*** 1 SYNTAX **
	***************
	use in 1 using "`c(sysdir_site)'/04_master/LIF.dta", clear
	syntax [if] [, ANIO(int `aniovp' ) BY(varname) ///
		UPDATE NOGraphs Base ///
		MINimum(real 0.5) DESDE(int -1) ///
		EOFP PROYeccion ///
		ROWS(int 1) COLS(int 5) ///
		TITle(string)]

	noisily di _newline(2) in g _dup(20) "." "{bf:   Sistema Fiscal:" in y " INGRESOS `anio'   }" in g _dup(20) "."

	* 1.1 Valor año mínimo *
	if `desde' == -1 {
		local desde = `anio'-10
	}

	* 1.2 Títulos y fuentes *
	if "`title'" == "" {
		local graphtitle "{bf:Ingresos presupuestarios}"
		local graphfuente "Fuente: Elaborado por el CIEP, con informaci{c o'}n de la SHCP/EOFP y $paqueteEconomico."
	}
	else {
		local graphtitle "{bf:`title'}"
		local graphfuente ""
	}

	** 1.3 Base RAW **
	if "`base'" == "base" {
		use `if' using "`c(sysdir_site)'/04_master/LIF.dta", clear
		exit
	}

	** 1.4 Valor default `by' **
	if "`by'" == "" {
		local by = "divPE"
	}



	****************
	*** 2. DATOS ***
	****************

	** 2.1 PIB + Deflactor **
	PIBDeflactor, anio(`anio') nographs nooutput `update'
	local currency = currency[1]
	forvalues k=1(1)`=_N' {
		if anio[`k'] == `anio' {
			local pibYR`anio' = pibYR[`k']
		}
		if anio[`k'] == `desde' {
			local pibYR`desde' = pibYR[`k']
		}
	}
	tempfile PIB
	save `PIB'

	** 2.2 Datos Abiertos **
	if "`update'" == "update" {
		capture confirm file "`c(sysdir_site)'/04_master/DatosAbiertos.dta"
		if _rc != 0 | "`update'" == "update" {
			DatosAbiertos, update
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

	** 2.3 Update LIF **
	if "`update'" == "update" | "`updated'" != "yes" {
		noisily UpdateLIF
	}



	***************
	*** 3 Merge ***
	***************
	use "`c(sysdir_site)'/04_master/LIF.dta", clear
	*drop if nombre == ""
	sort anio mes
	merge m:1 (anio) using `PIB', nogen keepus(pibY indiceY deflator lambda var_pibY) update replace keep(matched)
	local aniofirst = anio[1]
	local aniolast = anio[_N]

	** 3.1 Utilizar LIF o ILIF **
	if "`proyeccion'" == "proyeccion" {
		replace recaudacion = monto/acum_prom if mes < 12 & divLIF != 10
	}
	if "`eofp'" == "eofp" {
		replace recaudacion = monto if mes < 12
	}
	replace recaudacion = ILIF if mes == .

	** 3.2 Valores como % del PIB **
	foreach k of varlist recaudacion monto LIF ILIF {
		g double `k'PIB = `k'/pibY*100
	}
	g double recaudacionR = recaudacion/deflator
	egen double recaudacionTOT = sum(recaudacion), by(anio)
	format *PIB %10.3fc
	format recaudacionR recaudacionTOT %20.0fc



	******************
	*** 4 RESUMIDO ***
	******************
	capture keep `if'
	*keep if anio >= `desde'-1
	tempvar resumido recaudacionPIB
	g resumido = `by'

	capture label copy `by' label
	if _rc != 0 {
		label copy num`by' label
	}
	label values resumido label

	egen `recaudacionPIB' = max(recaudacionPIB) /*if anio >= 2010*/, by(`by')
	replace resumido = 999 if abs(`recaudacionPIB') < `minimum' //| recaudacionPIB == . | recaudacionPIB == 0 //& divCIEP != 15 
	label define label 999 `"< `=string(`minimum',"%5.1fc")'% PIB"', add modify

	* Especiales *
	capture replace nombre = subinstr(nombre,"Impuesto especial sobre producci{c o'}n y servicios de ","",.)
	capture replace nombre = subinstr(nombre,"alimentos no b{c a'}sicos con alta densidad cal{c o'}rica","comida chatarra",.)
	capture replace nombre = subinstr(nombre,"/","_",.)
	

	********************
	** 4. Display LIF **
	noisily di _newline in g "{bf: A. Ingresos presupuestarios (`by')}" ///
		_newline ///
		_col(30) in g %20s "`currency'" ///
		_col(52) %7s "% PIB" ///
		_col(61) %7s "% Tot"

	capture tabstat recaudacion recaudacionPIB if anio == `anio', by(`by') stat(sum) f(%20.0fc) save
	if _rc != 0 {
		noisily di in r "No hay informaci{c o'}n para el a{c n~}o `anio'."
		exit
	}
	tempname mattot
	matrix `mattot' = r(StatTotal)

	local k = 1
	while "`=r(name`k')'" != "." {
		tempname mat`k'
		matrix `mat`k'' = r(Stat`k')

		* Display text *
		if substr(`"`=r(name`k')'"',1,31) ==`"'"'' {
			local disptext = substr(`"`=r(name`k')'"',1,30)
		}
		else {
			local disptext = substr(`"`=r(name`k')'"',1,31)
		}
		local name = strtoname(`"`disptext'"')

		* Display *
		//return scalar `name' = `mat`k''[1,1]
		//return scalar `name'PIB = `mat`k''[1,2]
		//return scalar `name'Tot = `mat`k''[1,1]/`mattot'[1,1]*100
		local `by' `"``by'' `name'"'

		noisily di in g `"  (+) `disptext'"' ///
			_col(30) in y %20.0fc `mat`k''[1,1] ///
			_col(52) in y %7.3fc `mat`k''[1,2] ///
			_col(61) in y %7.1fc `mat`k''[1,1]/`mattot'[1,1]*100
		local ++k
	}
	return local `by' `"``by''"'

	noisily di in g _dup(68) "-"
	noisily di in g "{bf:  (=) Ingresos totales" ///
		_col(30) in y %20.0fc `mattot'[1,1] ///
		_col(52) in y %7.3fc `mattot'[1,2] ///
		_col(61) in y %7.1fc `mattot'[1,1]/`mattot'[1,1]*100 "}"

	return scalar `=strtoname("Ingresos totales")' = `mattot'[1,1]


	***************************
	** 4.2 Division Resumido **
	noisily di _newline in g "{bf: B. Ingresos presupuestarios (divResumido)}" ///
		_newline ///
		_col(30) in g %20s "`currency'" ///
		_col(52) %7s "% PIB" ///
		_col(61) %7s "% Real"

	preserve
	collapse (sum) recaudacion recaudacionPIB recaudacionR (max) recaudacionTOT pibY deflator if divLIF != 10, by(anio resumido)
	reshape wide recaudacion*, i(anio) j(resumido)
	reshape long

	capture tabstat recaudacionR if anio == `desde', by(resumido) stat(sum) f(%20.1fc) save
	if _rc == 0 {
		tempname sindeudatotpre
		matrix `sindeudatotpre' = r(StatTotal)
		local k = 1
		while "`=r(name`k')'" != "." {
			tempname pre`k'
			matrix `pre`k'' = r(Stat`k')
			local ++k
		}
	}

	tabstat recaudacion recaudacionPIB if anio == `anio', by(resumido) stat(sum) f(%20.1fc) save
	tempname sindeudatot
	matrix `sindeudatot' = r(StatTotal)

	local k = 1
	while "`=r(name`k')'" != "." {
		tempname mat`k'
		matrix `mat`k'' = r(Stat`k')

		* Display text *
		if substr(`"`=r(name`k')'"',1,25) == `"'"' {
			local disptext = substr(`"`=r(name`k')'"',1,24)
		}
		else {
			local disptext = substr(`"`=r(name`k')'"',1,25)
		}
		local name = strtoname(`"`disptext'"')

		* Display *
		return scalar `=strtoname("`=r(name`k')'")' = `mat`k''[1,1]
		return scalar `=strtoname("`=r(name`k')'")'PIB = `mat`k''[1,2]
		return scalar `=strtoname("`=r(name`k')'")'C = ((`mat`k''[1,1]/`pre`k''[1,1])^(1/(`=`anio'-`desde''))-1)*100
		local divResumido `"`divResumido' `=strtoname(abbrev("`=r(name`k')'",7))'"'

		noisily di in g "  (+) `=r(name`k')'" ///
			_col(30) in y %20.0fc `mat`k''[1,1] ///
			_col(52) in y %7.3fc `mat`k''[1,2] ///
			_col(61) in y %7.1fc ((`mat`k''[1,1]/`pre`k''[1,1])^(1/(`=`anio'-`desde''))-1)*100
		local ++k
	}
	return local divResumido `"`divResumido'"'

	noisily di in g _dup(68) "-"
	noisily di in g "{bf:  (=) Ingresos (sin deuda)" ///
		_col(30) in y %20.0fc `sindeudatot'[1,1] ///
		_col(52) in y %7.3fc `sindeudatot'[1,2] ///
		_col(61) in y %7.1fc ((`sindeudatot'[1,1]/`sindeudatotpre'[1,1])^(1/(`=`anio'-`desde''))-1)*100 "}"
	
	return scalar Ingresos_sin_deuda = `sindeudatot'[1,1]
	return scalar Ingresos_sin_deudaPIB = `sindeudatot'[1,2]
	return scalar Ingresos_sin_deudaC = ((`sindeudatot'[1,1]/`sindeudatotpre'[1,1])^(1/(`=`anio'-`desde''))-1)*100


	**********************
	** 4.3 Crecimientos **
	noisily di _newline in g "{bf: C. Cambios:" in y " `desde' - `anio'" in g " (% PIB)}" ///
		_newline ///
		_col(33) %7s "`desde'" ///
		_col(43) %7s "`anio'" ///
		_col(52) %7s "Dif" ///
		_col(61) %7s "Dif %"

	tabstat recaudacion recaudacionPIB if anio == `anio', by(resumido) stat(sum) f(%20.0fc) save
	tempname mattot
	matrix `mattot' = r(StatTotal)

	local k = 1
	while "`=r(name`k')'" != "." {
		tempname mat`k'
		matrix `mat`k'' = r(Stat`k')
		local ++k
	}

	capture tabstat recaudacion recaudacionPIB if anio == `desde', by(resumido) stat(sum) f(%20.1fc) save
	if _rc == 0 {
		tempname mattot5
		matrix `mattot5' = r(StatTotal)

		local k = 1
		while "`=r(name`k')'" != "." {
			tempname mat5`k'
			matrix `mat5`k'' = r(Stat`k')

			if substr(`"`=r(name`k')'"',1,25) == `"'"' {
				local disptext = substr(`"`=r(name`k')'"',1,24)
			}
			else {
				local disptext = substr(`"`=r(name`k')'"',1,25)
			}

			if `mat`k''[1,1] != . & `mat5`k''[1,1] != . {
				noisily di in g `"  (+) `disptext'"' ///
					_col(33) in y %7.3fc `mat5`k''[1,2] ///
					_col(43) in y %7.3fc `mat`k''[1,2] ///
					_col(52) in y %7.3fc `mat`k''[1,2]-`mat5`k''[1,2] ///
					_col(61) in y %7.1fc (`mat`k''[1,2]-`mat5`k''[1,2])/`mat5`k''[1,2]*100
			}
			local ++k
		}

		noisily di in g _dup(68) "-"
		noisily di in g "{bf:  (=) Ingresos" ///
			_col(33) in y %7.3fc `mattot5'[1,2] ///
			_col(43) in y %7.3fc `mattot'[1,2] ///
			_col(52) in y %7.3fc `mattot'[1,2]-`mattot5'[1,2] ///
			_col(61) in y %7.1fc (`mattot'[1,2]-`mattot5'[1,2])/`mattot5'[1,2]*100 "}"
	}
	restore


	***********************
	** 4.4 Elasticidades **
	noisily di _newline in g "{bf: D. Elasticidades:" in y " `desde' - `anio'}" in g ///
		_newline ///
		_col(33) %7s "%G" ///
		_col(43) %7s "%G pibR" ///
		_col(52) %7s "Elastic"

	tabstat recaudacionR recaudacionPIB if anio == `anio' & divLIF != 10, by(resumido) stat(sum) f(%20.3fc) save missing
	tempname mattot
	matrix `mattot' = r(StatTotal)
	local k = 1
	while "`=r(name`k')'" != "." {
		tempname mat`k'
		matrix `mat`k'' = r(Stat`k')
		local ++k
	}

	capture tabstat recaudacionR recaudacionPIB if anio == `desde' & divLIF != 10, by(resumido) stat(sum) f(%20.3fc) save missing
	if _rc == 0 {
		tempname mattot5
		matrix `mattot5' = r(StatTotal)
		local k = 1
		while "`=r(name`k')'" != "." {
			tempname mat5`k'
			matrix `mat5`k'' = r(Stat`k')
			
			if `mat`k''[1,1] != . & `mat5`k''[1,1] != . {
				noisily di in g "  (+) `=r(name`k')'" ///
					_col(33) in y %7.3fc (((`mat`k''[1,1]/`mat5`k''[1,1])^(1/(`=`anio'-`desde''))-1)*100) ///
					_col(43) in y %7.3fc (((`pibYR`anio''/`pibYR`desde'')^(1/(`=`anio'-`desde''))-1)*100) ///
					_col(52) in y %7.3fc (((`mat`k''[1,1]/`mat5`k''[1,1])^(1/(`=`anio'-`desde''))-1))/ ///
					(((`pibYR`anio''/`pibYR`desde'')^(1/(`=`anio'-`desde''))-1))
			}
			return scalar E`=strtoname("`=r(name`k')'")' = (((`mat`k''[1,1]/`mat5`k''[1,1])^(1/(`=`anio'-`desde''))-1))/ ///
					(((`pibYR`anio''/`pibYR`desde'')^(1/(`=`anio'-`desde''))-1))
			local E`=strtoname("`=r(name`k')'")' = (((`mat`k''[1,1]/`mat5`k''[1,1])^(1/(`=`anio'-`desde''))-1))/ ///
					(((`pibYR`anio''/`pibYR`desde'')^(1/(`=`anio'-`desde''))-1))
			local ++k
		}

		noisily di in g _dup(59) "-"
		noisily di in g "{bf:  (=) Ingresos totales" ///
				_col(33) in y %7.3fc (((`mattot'[1,1]/`mattot5'[1,1])^(1/(`=`anio'-`desde''))-1)*100) ///
				_col(43) in y %7.3fc (((`pibYR`anio''/`pibYR`desde'')^(1/(`=`anio'-`desde''))-1)*100) ///
				_col(52) in y %7.3fc (((`mattot'[1,1]/`mattot5'[1,1])^(1/(`=`anio'-`desde''))-1)*100)/ ///
				(((`pibYR`anio''/`pibYR`desde'')^(1/(`=`anio'-`desde''))-1)*100) "}"
	}



	******************
	* Returns Extras *
	capture tabstat recaudacion recaudacionPIB if anio == `anio' & nombre == "Cuotas a la seguridad social (IMSS)", stat(sum) f(%20.1fc) save
	tempname cuotas
	matrix `cuotas' = r(StatTotal)
	return scalar Cuotas_IMSS = `cuotas'[1,1]

	capture tabstat recaudacion recaudacionPIB if anio == `anio' & divCIEP == 12, stat(sum) by(nombre) f(%20.1fc) save
	
	tempname ieps
	matrix `ieps'1 = r(Stat1)
	return scalar Alcohol = `ieps'1[1,1]

	matrix `ieps'2 = r(Stat2)
	return scalar AlimNoBa = `ieps'2[1,1]

	matrix `ieps'7 = r(Stat7)
	return scalar Juegos = `ieps'7[1,1]
	
	matrix `ieps'6 = r(Stat6)
	return scalar Cervezas = `ieps'6[1,1]
	
	matrix `ieps'9 = r(Stat9)
	return scalar Tabacos = `ieps'9[1,1]
	
	matrix `ieps'10 = r(Stat10)
	return scalar Telecom = `ieps'10[1,1]
	
	matrix `ieps'3 = r(Stat3)
	return scalar Energiza = `ieps'3[1,1]

	matrix `ieps'4 = r(Stat4)
	return scalar Saboriza = `ieps'4[1,1]

	matrix `ieps'5 = r(Stat5)
	return scalar Fosiles = `ieps'5[1,1]



	*******************
	*** 5. Gráficos ***
	*++****++++++++++**
	if "`nographs'" != "nographs" & "$nographs" == "" {
		*preserve

		* Normalizar valores a billones *
		*replace recaudacion=recaudacion/deflator/1000000000000
		*replace monto=monto/deflator/1000000000000
		*replace LIF=LIF/deflator/1000000000000

		collapse (sum) recaudacion recaudacionR recaudacionPIB (max) recaudacionTOT pibY deflator if anio >= `desde', by(anio resumido)
		levelsof resumido, local(lev_resumido)
		label values resumido label

		* Ciclo para poner los paréntesis (% del total) en el legend *
		tabstat recaudacionPIB if anio == `anio', by(resumido) stat(sum) f(%20.0fc) save
		tempname SUM
		matrix `SUM' = r(StatTotal)

		local totlev = 0
		local inten = 0
		foreach k of local lev_resumido {
			local ++totlev
			tempname SUM`totlev'
			matrix `SUM`totlev'' = r(Stat`totlev')

			local legend`k' : label label `k'
			*local legend`k' = substr("`legend`k''",1,20)
			local legend = `"`legend' label(`totlev' "{bf:`legend`k''}")"'  
			//"(`=string(`SUM`totlev''[1,1]/`SUM'[1,1]*100,"%7.1fc")'%)"

			tempvar recaudacionPIB`k' connectedPIB`k' connectedTOT`k'
			egen `recaudacionPIB`k'' = sum(recaudacionPIB) if resumido >= `k', by(anio)
			replace `recaudacionPIB`k'' = 0 if `recaudacionPIB`k'' == .
			label var `recaudacionPIB`k'' "`legend`k''"

			egen `connectedTOT`k'' = sum(recaudacionR), by(anio)
			g `connectedPIB`k'' = recaudacionR/`connectedTOT`k''*100 if resumido == `k'
			format `recaudacionPIB`k'' `connectedPIB`k'' %7.1fc
			* pstyle(p1) finten(`=100-`inten'')
			local extras = `"`extras' (bar `recaudacionPIB`k'' anio if anio <= `anio' & resumido == `k', mlabpos(6) mlabcolor("111 111 111") barwidth(.8)) "'
			if `inten' <= .6 {
				local inten = `inten' + 20
			}
			else {
				local inten = `inten' + 10
			}
		}
		local legend `"`legend' label(`=`totlev'+1' "Recaudación total")"'
		
		* Ciclo para determinar el orden de mayor a menor, según gastoneto *
		tempvar ordervar
		bysort anio: g `ordervar' = _n
		gsort -anio -recaudacion
		forvalues k=1(1)`=_N'{
			if anio[`k'] == `anio' {
				local order "`order' `=`ordervar'[`k']'"
			}
		}
		sort anio resumido

		tempvar recaudacionbar recaudacionline recaudacionby
		g `recaudacionbar' = recaudacionR
		replace `recaudacionbar' = 0 if `recaudacionbar' == .

		egen `recaudacionby' = sum(recaudacion), by(anio)
		g `recaudacionline' = `recaudacionby'/pibY*100
		format recaudacion* `recaudacionbar' `recaudacionline' `recaudacionby' %15.1fc
		label var `recaudacionline' "Como % del PIB"

		* Información agregada *
		egen recaudacionPIBTOT = sum(recaudacionPIB), by(anio)
		format recaudacionPIBTOT %7.1fc


		***********
		** Texto **
		* Máximo *
		tabstat recaudacionPIBTOT `recaudacionline', stat(max) by(anio) save
		tempname maxPIBTOT
		matrix `maxPIBTOT' = r(StatTotal)

		* Inicial *
		tabstat recaudacionPIBTOT if anio == `desde', stat(max) save by(anio)
		tempname iniPIBTOT
		matrix `iniPIBTOT' = r(StatTotal)

		* Final *
		tabstat recaudacionPIBTOT if anio == `anio', stat(max) save by(anio)
		tempname finPIBTOT
		matrix `finPIBTOT' = r(StatTotal)

		* Cambios * 
		if (`finPIBTOT'[1,1]-`iniPIBTOT'[1,1]) > 0 {
			local cambio = "aumentó"
		}
		else {
			local cambio = "disminuyó"
		}

		twoway `extras' ///
			(connected `recaudacionline' anio if resumido == resumido[1], mlabpos(12) mlabcolor("111 111 111") mlabel(`recaudacionline') yaxis(2) mlabsize(large)) ///
			///(scatter recaudacionPIBTOT anio if resumido == resumido[1], mlabpos(12) mlabcolor("111 111 111") mlabel(recaudacionPIBTOT) mlabsize(large) mcolor(white) lcolor(white)) ///
			if anio <= `anio', ///
			///over(resumido, sort(1) descending) over(anio, gap(30)) ///
			///stack asyvars blabel(bar, format(%7.1fc)) outergap(0) ///
			name(ingresos`by'PIB, replace) ///
			title("`graphtitle'") ///
			yscale(range(0 `=`maxPIBTOT'[1,1]*1.75')) ///
			yscale(range(-50 `=`maxPIBTOT'[1,2]*1.1') axis(2) noline) ///
			ylabel(, format(%7.1fc) labsize(small)) ///
			ylabel(none, axis(2)) ///
			xlabel(`desde'(1)`anio') ///
			xtitle("") ///
			ytitle("billones de `currency' `aniovp'") ///
			ytitle("", axis(2)) ///
			///subtitle("Recaudación, como % del PIB") ///
			legend(on position(6) rows(`rows') cols(`cols') `legend' order(`order') justification(left)) ///
			/// Added text 
			///text(`=recaudacionPIBTOT[1]' `=anio[1]' "{bf:% PIB}", placement(6)) ///
			///text(`=`recaudacionline'[1]' `=anio[1]' "{bf:% LIF}", placement(6) yaxis(2)) ///
			b1title("De `desde' a `anio', la {bf:recaudación `cambio' `=string(abs(`finPIBTOT'[1,1]-`iniPIBTOT'[1,1]),"%7.1fc")'} puntos porcentuales del PIB.")

		/*grc1leg ///
		///graph combine ///
		ingresos`by'PIB ingresosMXN`by' , ///
			title("{bf:`graphtitle'}") ///
			caption("Fuente: Elaborado por el CIEP, con informaci{c o'}n de SHCP/EOFP, INEGI/BIE y $paqueteEconomico.") ///
			name(ingresos`by', replace) xcommon */

		*capture window manage close graph ingresosMXN`by'
		*capture window manage close graph ingresos`by'PIB
	
		graph save ingresos`by'PIB "`c(sysdir_site)'/04_master/graphs/ingresos`by'PIB", replace
		if "$export" != "" {
			graph export "$export/ingresos`by'PIB.png", as(png) name("ingresos`by'PIB") replace
		}
		*restore
	}



	***********
	*** END ***
	***********
	capture drop __*
	timer off 4
	timer list 4
	noisily di _newline in g "Tiempo: " in y round(`=r(t4)/r(nt4)',.1) in g " segs."
}
end



*************************
****                 ****
**** UpdateLIF.do    ****
**** De .xlsx a .dta ****
****                 ****
*************************
program define UpdateLIF


	************************
	*** 1. BASE DE DATOS ***
	************************
	import excel `"`c(sysdir_site)'/01_raw/LIFs.xlsx"', clear firstrow
	foreach k of varlist _all {
		capture confirm string variable `k'
		if _rc == 0 {
			if `k'[1] == "" {
				drop `k'
			}
		}
		else {
			if `k'[1] == . {
				drop `k'
			}
		}
	}
	drop if numdivLIF == .

	** Encode **
	foreach k of varlist div* {
		capture confirm variable num`k'
		if _rc == 0 {
			capture which labmask
			if _rc != 0 {
				net install labutil.pkg
			}
			labmask num`k', values(`k')
			drop `k'
			rename num`k' `k'
			continue
		}
		rename `k' `k's
		encode `k's, gen(`k')
		drop `k's
	}
	order div* concepto
	destring LIF*, replace
	reshape long LIF ILIF, i(div* concepto serie) j(anio)
	format div* LIF* ILIF* %20.0fc
	format concepto %30s



	*******************************
	*** 2. SHCP: Datos Abiertos ***
	*******************************
	preserve
	levelsof serie, local(serie)
	foreach k of local serie {
		if "`k'" != "NA" {
			noisily DatosAbiertos `k', nog

			rename clave_de_concepto serie
			keep anio serie nombre monto mes acum_prom

			tempfile `k'
			quietly save ``k''
		}
	}
	restore


	** 2.1.1 Append **
	collapse (sum) LIF ILIF, by(div* serie anio)
	foreach k of local serie {
		if "`k'" != "NA" {
			joinby (anio serie) using ``k'', unmatched(both) update
			drop _merge
		}
	}

	rename serie series
	encode series, generate(serie)
	drop series


	** 2.1.2 Fill the blanks **
	forvalues j=1(1)`=_N' {
		foreach k of varlist div* nombre serie {
			capture confirm numeric variable `k'
			if _rc == 0 {
				if `k'[`j'] != . {
					quietly replace `k' = `k'[`j'] if `k' == . & serie == serie[`j'] & serie[`j'] != .
				}
			}
			else {
				if `k'[`j'] != "" {
					quietly replace `k' = `k'[`j'] if `k' == "" & serie == serie[`j'] & serie[`j'] != .
				}
			}
		}
	}



	**************************************
	** Recaudacion observada y estimada **
	capture confirm variable monto
	if _rc == 0 {
		g recaudacion = monto if mes == 12									// Se reemplazan con lo observado
		g concepto = nombre
	}
	else {
		g monto = .
		g recaudacion = .
		g concepto = ""
	}

	replace recaudacion = LIF if mes != 12
	replace recaudacion = ILIF if recaudacion == . & LIF == . & ILIF != .			// De lo contrario, es ILIF
	format recaudacion %20.0fc

	capture order div* nombre serie anio LIF ILIF monto
	compress
	sort div* nombre serie anio
	save "`c(sysdir_site)'/04_master/LIF.dta", replace
end
