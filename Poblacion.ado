*!*******************************************
*!***                                    ****
*!***    Poblacion y defunciones         ****
*!***    Bases: CONAPO 1950-2070         ****
*!***    Autor: Ricardo + Juan Pablo     ****
*!***    Fecha: 20/04/2024               ****
*!***                                    ****
*!***    Sintaxis:                       ****
*!***    Poblacion [if] [, ANIOinicial(int) ANIOFinal(int) NOGraphs UPDATE]
*!*******************************************
program define Poblacion, return
quietly {
	timer on 2

	capture mkdir `"`c(sysdir_personal)'/SIM/"'
	capture mkdir `"`c(sysdir_personal)'/SIM/graphs/"'

	** 0.1 Revisa si se puede usar la base de datos **
	capture use `"`c(sysdir_personal)'/SIM/Poblacion.dta"', clear
	if _rc != 0 {
		UpdatePoblacion
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



	*******************
	*** 1. Sintaxis ***
	*******************
	syntax [if] [, ANIOinicial(int `aniovp') ANIOFinal(int -1) NOGraphs UPDATE]

	* 1.1 Si la opción "update" es llamada, ejecuta el do-file UpdatePoblacion.do *
	if "`update'" == "update" {
		UpdatePoblacion
	}

	* if default *
	if `"`if'"' == `"if entidad == """' | `"`if'"' == "" {
		local if = `"if entidad == "Nacional""'
	}



	************************
	*** 2. Base de datos ***
	************************
	use `if' using `"`c(sysdir_personal)'/SIM/Poblacion.dta"', clear
	noisily di _newline(2) in g _dup(20) "." "{bf:   Poblaci{c o'}n: " in y "`=entidad[1]'   }" in g _dup(20) "." _newline

	* Obtiene el año inicial de la base *
	local aniofirst = anio in 1
	local entidadGName = "`=entidad[1]'"
	
	tokenize $entidadesC
	local j = 1
	foreach k of global entidadesL {
		if "`entidadGName'" == "`k'" {
			local entidadGName = "``j''"
			continue, break
		}
		local ++j
	}
	
	local entidadGName = strtoname("`entidadGName'")

	* Si no hay opción aniofinal, utiliza el último año del vector "anio" *
	if `aniofinal' == -1 {
		local aniofinal = anio in -1
	}


	** 2.1 Display inicial **
	forvalues k=`anioinicial'(1)`aniofinal' {
		tabstat poblacion if anio == `k', f(%20.0fc) stat(sum) save
		tempname POBTOT
		matrix `POBTOT' = r(StatTotal)
		noisily di in g " Personas " in y `k' in g ": " in y %15.0fc `POBTOT'[1,1]
		if `k' == `anioinicial' {
			scalar pobtot`entidadGName' = `POBTOT'[1,1]
		}
		if `k' == `aniofinal' {
			scalar pobfin`entidadGName' = `POBTOT'[1,1]
		}
	}



	***************************
	*** 3. Gráfica Pirámide ***
	***************************
	if "`nographs'" != "nographs" & "$nographs" == "" {
		preserve
		local poblacion : variable label poblacion
		
		tempvar pob2
		g `pob2' = -poblacion if sexo == 1
		replace `pob2' = poblacion if sexo == 2		
		format `pob2' %10.0fc

		* Calcula las estadísticas descriptivas y las guarda en matrices *
		* Mediana *
		tabstat edad [fw=round(abs(poblacion),1)] if anio == `anioinicial', stat(median) by(sexo) save
		tempname H`anioinicial' M`anioinicial'
		matrix `H`anioinicial'' = r(Stat1)
		matrix `M`anioinicial'' = r(Stat2)

		tabstat edad [fw=round(abs(poblacion),1)] if anio == `aniofinal', stat(median) by(sexo) save
		tempname H`aniofinal' M`aniofinal'
		matrix `H`aniofinal'' = r(Stat1)
		matrix `M`aniofinal'' = r(Stat2)

		* Distribucion inicial *
		tabstat poblacion if anio == `anioinicial' & edad < 18, stat(sum) f(%15.0fc) save
		tempname P18_`anioinicial'
		matrix `P18_`anioinicial'' = r(StatTotal)

		tabstat poblacion if anio == `anioinicial' & edad >= 18 & edad < 65, stat(sum) f(%15.0fc) save
		tempname P1865_`anioinicial'
		matrix `P1865_`anioinicial'' = r(StatTotal)

		tabstat poblacion if anio == `anioinicial' & edad >= 65, stat(sum) f(%15.0fc) save
		tempname P65_`anioinicial'
		matrix `P65_`anioinicial'' = r(StatTotal)

		tabstat poblacion if anio == `anioinicial', stat(sum) f(%15.0fc) save
		tempname P`anioinicial'
		matrix `P`anioinicial'' = r(StatTotal)

		* Distribucion final *
		tabstat poblacion if anio == `aniofinal' & edad < 18, stat(sum) f(%15.0fc) save
		tempname P18_`aniofinal'
		matrix `P18_`aniofinal'' = r(StatTotal)

		tabstat poblacion if anio == `aniofinal' & edad >= 18 & edad < 65, stat(sum) f(%15.0fc) save
		tempname P1865_`aniofinal'
		matrix `P1865_`aniofinal'' = r(StatTotal)

		tabstat poblacion if anio == `aniofinal' & edad >= 65, stat(sum) f(%15.0fc) save
		tempname P65_`aniofinal'
		matrix `P65_`aniofinal'' = r(StatTotal)

		tabstat poblacion if anio == `aniofinal', stat(sum) f(%15.0fc) save
		tempname P`aniofinal'
		matrix `P`aniofinal'' = r(StatTotal)

		* Poblacion viva *
		tempname Pviva
		capture tabstat poblacion if anio == `aniofinal' & edad >= `aniofinal'-`anioinicial', stat(sum) f(%15.0fc) save
		if _rc != 0 {
			matrix `Pviva' = J(1,1,0)
		
		}
		else {
			matrix `Pviva' = r(StatTotal)
		}

		* Población no nacida *
		tempname Pnacida
		capture tabstat poblacion if anio == `aniofinal' & edad < `aniofinal'-`anioinicial', stat(sum) f(%15.0fc) save
		if _rc != 0 {
			matrix `Pnacida' = J(1,1,0)
		
		}
		else {
			matrix `Pnacida' = r(StatTotal)
		}

		* Población hoy *
		tempname Phoy
		capture tabstat poblacion if anio == `anioinicial' & edad < 109 - (`aniofinal'-`anioinicial'), stat(sum) f(%15.0fc) save
		if _rc != 0 {
			matrix `Phoy' = J(1,1,0)
		
		}
		else {
			matrix `Phoy' = r(StatTotal)
		}

		* X label *
		tabstat poblacion if (anio == `anioinicial' | anio == `aniofinal'), stat(max) f(%15.0fc) by(sexo) save
		tempname MaxH MaxM
		matrix `MaxH' = r(Stat1)
		matrix `MaxM' = r(Stat2)

		g edad2 = edad
		replace edad2 = . if edad != 5 & edad != 10 & edad != 15 & edad != 20 ///
			& edad != 25 & edad != 30 & edad != 35 & edad != 40 & edad != 45 ///
			& edad != 50 & edad != 55 & edad != 60 & edad != 65 & edad != 70 ///
			& edad != 75 & edad != 80 & edad != 85 & edad != 90 & edad != 95 ///
			& edad != 100 & edad != 105
		g zero = 0

		if "$export" == "" {
			local graphtitle "{bf:Pirámides demográficas}"
			///local graphtitle "{bf:Population} pyramid"
			local graphfuente "{bf:Fuente}: Elaborado por el CIEP, con información de CONAPO (2023)."
		}
		else {
			local graphtitle ""
			local graphfuente ""
		}

		* Grafica sexo = 1 como negativos y sexo = 2 como positivos por grupos etarios, en el presente y futuro *
		twoway (bar `pob2' edad if sexo == 1 & anio == `anioinicial' & edad+`aniofinal'-`anioinicial' <= 109, horizontal) ///
			(bar `pob2' edad if sexo == 2 & anio == `anioinicial' & edad+`aniofinal'-`anioinicial' <= 109, horizontal) ///
			(bar `pob2' edad if sexo == 1 & anio == `anioinicial' & edad+`aniofinal'-`anioinicial' > 109, horizontal barwidth(.5) bstyle(p1bar)) ///
			(bar `pob2' edad if sexo == 2 & anio == `anioinicial' & edad+`aniofinal'-`anioinicial' > 109, horizontal barwidth(.5) bstyle(p2bar)) ///
			(sc edad2 zero if anio == `anioinicial', msymbol(i) mlabel(edad2) mlabsize(vsmall) mlabcolor("114 113 118")), ///
			legend(label(1 "Hombres") label(2 "Mujeres")) ///
			legend(off order(1 2) rows(1) region(margin(zero))) ///
			yscale(noline) ylabel(none) xscale(noline) ///
			///text(105 `=-`MaxH'[1,1]*.5' "{bf:Edad mediana}") ///
			///text(97.5 `=-`MaxH'[1,1]*.5' "Hombres: `=`H`anioinicial''[1,1]'") ///
			///text(90 `=-`MaxH'[1,1]*.5' "Mujeres: `=`M`anioinicial''[1,1]'") ///
			text(`=(109-(`aniofinal'-`anioinicial'))/2' `=-`MaxH'[1,1]*.35' "{bf: `=entidad[1]'}", size(huge) color(black)) ///
			text(`=(109-(`aniofinal'-`anioinicial'))/2' `=`MaxH'[1,1]*.35' `"`=string(`P`anioinicial''[1,1],"%20.0fc")'"', size(huge) color(black)) ///
			/*legend(label(1 "Men") label(2 "Women")) ///
			text(105 `=`MaxH'[1,1]*.618' "{bf:Population}") ///
			text(100 `=`MaxH'[1,1]*.618' `"`=string(`P`anioinicial''[1,1],"%20.0fc")'"') ///
			text(105 `=-`MaxH'[1,1]*.618' "{bf:Median age}") ///
			text(100 `=-`MaxH'[1,1]*.618' "Men: `=`H`anioinicial''[1,1]'") ///
			text(95 `=-`MaxH'[1,1]*.618' "Women: `=`M`anioinicial''[1,1]'")*/ ///
			name(P_`anioinicial'_`aniofinal'_`entidadGName'A, replace) ///
			xlabel(`=-`MaxH'[1,1]' `"`=string(`MaxH'[1,1],"%15.0fc")'"' ///
			`=-`MaxH'[1,1]/2' `"Hombres"' 0 ///
			`=`MaxM'[1,1]/2' `"Mujeres"' ///
			`=`MaxM'[1,1]' `"`=string(`MaxM'[1,1],"%15.0fc")'"', angle(horizontal)) ///
			title(`"`anioinicial'"') ///
			///subtitle(`"`=string(`P`anioinicial''[1,1],"%20.0fc")'"') ///
		

		twoway (bar `pob2' edad if sexo == 1 & anio == `aniofinal' & edad < `aniofinal'-`anioinicial', horizontal barwidth(.5)) ///
			(bar `pob2' edad if sexo == 2 & anio == `aniofinal' & edad < `aniofinal'-`anioinicial', horizontal barwidth(.5)) ///
			(bar `pob2' edad if sexo == 1 & anio == `aniofinal' & edad >= `aniofinal'-`anioinicial', horizontal barwidth(1) bstyle(p1bar)) ///
			(bar `pob2' edad if sexo == 2 & anio == `aniofinal' & edad >= `aniofinal'-`anioinicial', horizontal barwidth(1) bstyle(p2bar)) ///
			(sc edad2 zero if anio == `anioinicial', msymbol(i) mlabel(edad2) mlabsize(vsmall) mlabcolor("114 113 118")), ///
			legend(label(1 "Hombres") label(2 "Mujeres")) ///
			legend(off order(1 2) rows(1) region(margin(zero))) ///
			yscale(noline) ylabel(none) xscale(noline) ///
			text(`=((`aniofinal'-`anioinicial'))/2' `=-`MaxH'[1,1]*.35' "{bf: Por nacer}", size(huge) color(black)) ///
			text(`=((`aniofinal'-`anioinicial'))/2' `=`MaxH'[1,1]*.35' `"`=string(`Pnacida'[1,1],"%20.0fc")'"', size(huge) color(black)) ///
			text(`=(`aniofinal'-`anioinicial')+(109-(`aniofinal'-`anioinicial'))/2' `=-`MaxH'[1,1]*.35' "{bf: Vivos en `anioinicial'}", size(huge) color(black)) ///
			text(`=(`aniofinal'-`anioinicial')+(109-(`aniofinal'-`anioinicial'))/2' `=`MaxH'[1,1]*.35' `"`=string(`Pviva'[1,1],"%20.0fc")'"', size(huge) color(black)) ///
			///text(105 `=-`MaxH'[1,1]*.5' "{bf:Edad mediana}") ///
			///text(97.5 `=-`MaxH'[1,1]*.5' "Hombres: `=`H`aniofinal''[1,1]'") ///
			///text(90 `=-`MaxH'[1,1]*.5' "Mujeres: `=`M`aniofinal''[1,1]'") ///
			///text(105 `=`MaxH'[1,1]*.5' "{bf:Nacidos después de `anioinicial'} ") ///
			///text(97.5 `=`MaxH'[1,1]*.5' `"`=string(`Pnacida'[1,1],"%20.0fc")' (`=string(`Pnacida'[1,1]/`P`aniofinal''[1,1]*100,"%7.1fc")'%)"') ///
			/*legend(label(1 "Men") label(2 "Women")) ///
			text(105 `=`MaxH'[1,1]*.618' "{bf:Population}") ///
			text(100 `=`MaxH'[1,1]*.618' `"`=string(`P`anioinicial''[1,1],"%20.0fc")'"') ///
			text(105 `=-`MaxH'[1,1]*.618' "{bf:Median age}") ///
			text(100 `=-`MaxH'[1,1]*.618' "Men: `=`H`anioinicial''[1,1]'") ///
			text(95 `=-`MaxH'[1,1]*.618' "Women: `=`M`anioinicial''[1,1]'")*/ ///
			name(P_`anioinicial'_`aniofinal'_`entidadGName'B, replace) ///
			xlabel(`=-`MaxH'[1,1]' `"`=string(`MaxH'[1,1],"%15.0fc")'"' ///
			`=-`MaxH'[1,1]/2' `"Hombres"' 0 ///
			`=`MaxM'[1,1]/2' `"Mujeres"' ///
			`=`MaxM'[1,1]' `"`=string(`MaxM'[1,1],"%15.0fc")'"', angle(horizontal)) ///
			title(`"`aniofinal'"') ///
			///subtitle(`"`=string(`P`aniofinal''[1,1],"%20.0fc")'"') ///


		graph combine P_`anioinicial'_`aniofinal'_`entidadGName'A P_`anioinicial'_`aniofinal'_`entidadGName'B, ///
			title("`graphtitle'") ///
			///subtitle(${pais} `=entidad[1]') ///
			caption("`graphfuente'") ///
			name(P_`anioinicial'_`aniofinal'_`entidadGName', replace) ///

		capture window manage close graph P_`anioinicial'_`aniofinal'_`entidadGName'A
		capture window manage close graph P_`anioinicial'_`aniofinal'_`entidadGName'B

		capture mkdir "`c(sysdir_personal)'/SIM/graphs"
		graph save P_`anioinicial'_`aniofinal'_`entidadGName' "`c(sysdir_personal)'/SIM/graphs/P_`anioinicial'_`aniofinal'_`entidadGName'", replace
		if "$export" != "" {
			graph export "$export/P_`anioinicial'_`aniofinal'_`entidadGName'.png", replace name(P_`anioinicial'_`aniofinal'_`entidadGName')
		}



		*****************************************
		*** 4. Gráfica transición demográfica ***
		*****************************************
		g pob18 = poblacion if edad <= 18
		g pob1860 = poblacion if edad > 18 & edad <= 60
		g pob60 = poblacion if edad > 60

		collapse (sum) pob18 pob1860 pob60 poblacion*, by(anio entidad)
		format poblacion pob* %15.0fc

		* Distribucion *
		g pob18_2 = pob18/poblacion*100
		g pob1860_2 = pob1860/poblacion*100
		g pob60_2 = pob60/poblacion*100

		* Valores maximos *
		tabstat pob18_2 pob1860_2 pob60_2, stat(max min) save
		tempname MAX
		matrix `MAX' = r(StatTotal)

		forvalues k = 1(1)`=_N' {
			* Maximos *
			* Busca la población máxima y guarda el año y el número *
			if pob18_2[`k'] == `MAX'[1,1] {
				local x1 = anio[`k']
				local y1 = (pob18[`k'])/1000000
				local p1 = `k'
			}
			if pob1860_2[`k'] == `MAX'[1,2] {
				local x2 = anio[`k']
				local y2 = (pob1860[`k'] + pob18[`k'])/1000000
				local p2 = `k'
			}
			if pob60_2[`k'] == `MAX'[1,3] {
				local x3 = anio[`k']
				local y3 = (pob60[`k'] + pob1860[`k'] + pob18[`k'])/1000000
				local p3 = `k'
			}
			
			* Minimos *
			* Busca la población mínima y guarda el año y el número *
			if pob18_2[`k'] == `MAX'[2,1] {
				local m1 = anio[`k']
				local z1 = (pob18[`k']/2)/1000000
				local q1 = `k'
			}
			if pob1860_2[`k'] == `MAX'[2,2] {
				local m2 = anio[`k']
				local z2 = (pob1860[`k']/2 + pob18[`k'])/1000000
				local q2 = `k'
				if `m2' < 1980 {
					local place21 = "e"
					local place22 = "e"
				}
				else {
					local place21 = "w"
					local place22 = "w"
				}
			}
			if pob60_2[`k'] == `MAX'[2,3] {
				local m3 = anio[`k']
				local z3 = (pob60[`k'] + pob1860[`k'] + pob18[`k'])/1000000
				local q3 = `k'
			}
		}

		tempvar pob18 pob1860 pob60
		g `pob18' = pob18/1000000
		g `pob1860' = (pob1860 + pob18)/1000000
		g `pob60' = (pob60 + pob1860 + pob18)/1000000

		if "$export" == "" {
			local graphtitle "{bf:Transici{c o'}n demogr{c a'}fica}"
			local graphfuente "{bf:Fuente}: Elaborado por el CIEP, con información de CONAPO (2023)."
		}
		else {
			local graphtitle ""
			local graphfuente ""
		}

		twoway (area `pob60' `pob1860' `pob18' anio if anio <= `anioinicial') ///
			(area `pob60' anio if anio > `anioinicial', astyle(p1area)) ///
			(area `pob1860' anio if anio > `anioinicial', astyle(p2area)) ///
			(area `pob18' anio if anio > `anioinicial', astyle(p3area)), ///
			text(`y1' `x1' `"{bf:Max (0-18):} `=string(`MAX'[1,1],"%5.1fc")' % (`x1')"', place(s) size(medlarge) color(black)) ///
			text(`y2' `x2' `"{bf:Max (19-60):} `=string(`MAX'[1,2],"%5.1fc")' % (`x2')"', place(s) size(medlarge) color(black)) ///
			text(`y3' `x3' `"{bf:Max (61+):} `=string(`MAX'[1,3],"%5.1fc")' % (`x3')"', place(nw) size(medlarge) color(black)) ///
			text(`z1' `m1' `"{bf:Min (0-18):} `=string(`MAX'[2,1],"%5.1fc")' % (`m1')"', place(w) size(medlarge) color(black)) ///
			text(`z2' `m2' `"{bf:Min (19-60):} `=string(`MAX'[2,2],"%5.1fc")' % (`m2')"', place(`place21') size(medlarge) color(black)) ///
			text(`z3' `m3' `"{bf:Min (61+):} `=string(`MAX'[2,3],"%5.1fc")' % (`m3')"', place(ne) size(medlarge) color(black)) ///
			text(`=`POBTOT'[1,1]/1000000*.015' `=`anioinicial'-.5' "{bf:`anioinicial'}", place(nw)) ///
			xtitle("") ///
			ytitle("millones de personas") ///
			xline(`=`anioinicial'+.5') ///
			///title("`graphtitle'") ///
			title("${pais} `=entidad[1]'") ///
			///caption("`graphfuente'") ///
			legend(on label(1 "61 y más") label(2 "19 -- 60") label(3 "18 y menos") order(- "{bf:Edades:}" 3 2 1) ///
			position(6) region(margin(zero)) rows(1)) ///
			ylabel(, format(%20.0fc)) yscale(range(0)) ///
			xlabel(`aniofirst'(10)`=anio[_N]') ///
			name(E_`anioinicial'_`aniofinal'_`entidadGName', replace)
			
		graph save E_`anioinicial'_`aniofinal'_`entidadGName' "`c(sysdir_personal)'/SIM/graphs/E_`anioinicial'_`aniofinal'_`entidadGName'", replace


		*****************************************
		*** 5. Gráfica de tasa de dependencia ***
		*****************************************
		g tasaDependencia = (pob18 + pob60)/(pob1860)*100
		format tasaDependencia %10.0fc

		tabstat tasaDependencia, stat(min max) save
		forvalues k = 1(1)`=_N' {
			if tasaDependencia[`k'] == r(StatTotal)[1,1] {
				local aniotdmin = anio[`k']
			}
			if tasaDependencia[`k'] == r(StatTotal)[2,1] {
				local aniotdmax = anio[`k']
			}
			if anio[`k'] == `anioinicial' {
				local obsini = `k'
			}
		}

		noisily di _newline in g " Año con mayor tasa de dependencia: " in y `aniotdmax'
		noisily di in g " Año con menor tasa de dependencia: " in y `aniotdmin'

		if "$export" == "" {
			local graphtitle "{bf:Tasa de dependencia}"
			local graphfuente "{bf:Fuente}: Elaborado por el CIEP, con información de CONAPO (2023)."
		}
		else {
			local graphtitle ""
			local graphfuente ""
		}

		twoway (connected tasaDependencia anio if anio >= 1950 & anio <= `anioinicial', mlabel(tasaDependencia) mlabcolor(white) mlabpos(12) mlabsize(medium)) ///
			(connected tasaDependencia anio if anio > `anioinicial' & anio <= `aniofinal', mlabel(tasaDependencia) mlabcolor(white) mlabpos(12) mlabsize(medium)), ///
			///title("`graphtitle'") ///
			title("Dependientes por c/100 personas en edad de trabajar") ///
			///caption("`graphfuente'") ///
			xtitle("") ///
			text(`=tasaDependencia[`obsini']' `=anio[`obsini']' "`=string(tasaDependencia[`obsini'],"%7.0fc")'", place(n) size(large) color(black)) ///
			///xlabel(`=round(`anioinicial',5)'(5)`=round(`aniofinal',5)') ///
			xlabel(`aniofirst'(10)`aniofinal') ///
			ytitle("") ///
			///ylabel(, format(%10.0fc)) ///
			legend(off label(1 "Observado") label(2 "Proyectado") region(margin(zero)) rows(1)) ///
			name(T_`anioinicial'_`aniofinal'_`entidadGName', replace)

		graph save T_`anioinicial'_`aniofinal'_`entidadGName' "`c(sysdir_personal)'/SIM/graphs/T_`anioinicial'_`aniofinal'_`entidadGName'", replace

		graph combine E_`anioinicial'_`aniofinal'_`entidadGName' T_`anioinicial'_`aniofinal'_`entidadGName', ///
			title("{bf:Transición demográfica y tasa de dependencia}") ///
			caption("{bf:Fuente}: Elaborado por el CIEP, con información de CONAPO (2023).") ///
			name(ET_`anioinicial'_`aniofinal'_`entidadGName', replace)

		capture window manage close graph E_`anioinicial'_`aniofinal'_`entidadGName'
		capture window manage close graph T_`anioinicial'_`aniofinal'_`entidadGName'

		graph save ET_`anioinicial'_`aniofinal'_`entidadGName' "`c(sysdir_personal)'/SIM/graphs/ET_`anioinicial'_`aniofinal'_`entidadGName'", replace
		if "$export" != "" {
			graph export "$export/ET_`anioinicial'_`aniofinal'_`entidadGName'.png", replace name(ET_`anioinicial'_`aniofinal'_`entidadGName')
		}

		restore
	}


	** END **
	timer off 2
	timer list 2
	noisily di _newline in y round(`=r(t2)/r(nt2)',.1) in g " segs  "
}
end





****************************************************************************************
****                                                                                ****
****   Bases de datos de Mexico: Población, defunciones y migración internacional   ****
****                                                                                ****
****************************************************************************************
program define UpdatePoblacion
	noisily di in g "  Updating Poblacion.dta..." _newline



	********************
	*** A. Poblacion ***
	********************

	** 1. Base de datos (online) **
	import delimited "http://conapo.segob.gob.mx/work/models/CONAPO/Datos_Abiertos/pry23/00_Pob_Mitad_1950_2070.csv", clear
	*import excel "`c(sysdir_site)'../BasesCIEP/CONAPO/ConDem50a19_ProyPob20a70/0_Pob_Mitad_1950_2070.xlsx", sheet("Hoja1") firstrow case(lower) clear


	** 2. Limpia **
	capture drop renglon
	capture rename año anio
	capture rename ao anio

	rename sexo sexo0
	encode sexo0, generate(sexo)
	drop sexo0


	** 3. Guardar **
	tempfile poblacion
	save "`poblacion'"



	**********************
	*** B. Defunciones ***
	**********************

	** 1. Base de datos (online) **
	import delimited "http://conapo.segob.gob.mx/work/models/CONAPO/Datos_Abiertos/pry23/01_Defunciones_1950_2070.csv", clear
	*import excel "`c(sysdir_site)'../BasesCIEP/CONAPO/ConDem50a19_ProyPob20a70/1_Defunciones_1950_2070.xlsx", sheet("Hoja1") firstrow case(lower) clear


	** 2. Limpia **
	capture rename año anio
	capture rename ao anio
	capture rename aão anio

	rename sexo sexo0
	encode sexo0, generate(sexo)
	drop *renglon sexo0


	** 3. Guardar **
	tempfile defunciones
	save "`defunciones'"



	**********************************
	*** C. Migracion Internacional ***
	**********************************

	** 1. Base de datos (online) **
	import delimited "http://conapo.segob.gob.mx/work/models/CONAPO/Datos_Abiertos/pry23/02_mig_inter_quinquen_proyecciones.csv", clear
	*import excel "`c(sysdir_site)'../BasesCIEP/CONAPO/ConDem50a19_ProyPob20a70/2_mig_inter_quinquen_proyecciones.xlsx", sheet("Hoja1") firstrow case(lower) clear


	** 2. Limpia **
	capture rename año anio
	if _rc != 0 {
		rename ao anio
	}
	split anio, parse("-") destring
	split edad, parse("--") destring

	rename sexo sexo0
	encode sexo0, generate(sexo)
	drop renglon sexo0 anio edad

	* 2.1 Se expanden los años para rellenar los espacios entre rangos. Por ejemplo: de 0-4 a 0,1,2,3,4. *
	expand anio2-anio1
	replace emigrantes = emigrantes/(anio2-anio1)
	replace inmigrantes = inmigrantes/(anio2-anio1)
	sort entidad anio1 anio2 edad1 edad2 sexo
	by entidad anio1 anio2 edad1 edad2 sexo: g n = _n
	replace anio1 = anio1 + n
	drop anio2 n
	rename anio1 anio

	* 2.2 Se distribuyen entre edades *
	expand edad2-edad1+1
	replace emigrantes = emigrantes/(edad2-edad1+1)
	replace inmigrantes = inmigrantes/(edad2-edad1+1)
	sort entidad anio edad1 edad2 sexo
	by entidad anio edad1 edad2 sexo: g n = _n
	replace edad1 = edad1 + n - 1
	drop edad2 n
	rename edad1 edad


	** 3. Guardar **
	tempfile migracion
	save "`migracion'"



	***************/
	*** D. Union ***
	****************

	** 1. Base de datos (temporales) **
	use "`poblacion'", clear
	merge 1:1 (anio edad sexo entidad) using "`defunciones'", nogen
	merge 1:1 (anio edad sexo entidad) using "`migracion'", nogen


	** 2. Limpia **
	replace poblacion = 0 if poblacion == .
	replace emigrantes = 0 if emigrantes == .
	replace inmigrantes = 0 if inmigrantes == .

	replace entidad = "Nacional" if substr(entidad,1,3) == "Rep"
	replace entidad = "Estado de México" if entidad == "M?xico" | entidad == "México"


	** 3. Labels y formato *
	label var anio "Año"
	label var sexo "Sexo"
	label var edad "Edad"
	label var entidad "Entidad federativa"
	label var poblacion "Población"
	label var emigrantes "Emigrantes internacionales"
	label var inmigrantes "Inmigrantes internacionales"
	label var defunciones "Defunciones"
	format poblacion defunciones *migrantes %15.0fc


	** 4. Tasa de fertilidad **
	tempvar mujeresf nacimien nacimientos mujeresfert
	egen `mujeresf' = sum(poblacion) if edad >= 16 & edad <= 49 & sexo == 2, by(anio)
	egen `nacimien' = sum(poblacion) if edad == 0, by(anio)
	egen `nacimientos' = mean(`nacimien'), by(anio)
	egen `mujeresfert' = mean(`mujeresf'), by(anio)

	g tasafecundidad = `nacimientos'/`mujeresfert'*1000
	tabstat tasafecundidad, stat(mean) by(anio) f(%10.1fc) save
	label var tasafecundidad "Nacimientos por cada mil mujeres"


	** 5. Guardar bases SIM **
	order anio sexo edad entidad poblacion defunciones
	drop cve_geo 
	capture drop __*
	compress

	if `c(version)' > 13.1 {
		saveold "`c(sysdir_personal)'/SIM/Poblacion.dta", replace version(13)
	}
	else {
		save "`c(sysdir_personal)'/SIM/Poblacion.dta", replace
	}

	collapse (sum) poblacion, by(anio entidad)
	keep if entidad == "Nacional"
	if `c(version)' > 13.1 {
		saveold `"`c(sysdir_personal)'/SIM/Poblaciontot.dta"', replace version(13)
	}
	else {
		save `"`c(sysdir_personal)'/SIM/Poblaciontot.dta"', replace
	}
end
