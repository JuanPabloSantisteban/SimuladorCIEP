program define INCI, rclass
quietly {
	version 13.1
	syntax varname [if] [fweight/], Folio(varlist) Relativo(name) N(name) [POST]

	noisily di _newline in y "  incidencia.ado"



	******************************
	** 0. Guardar base original **
	preserve
	local rellabel : variable label `relativo'
	levelsof `n', local(nn)



	***************************
	** 1. Variables internas **
	tempvar miembros
	egen `miembros' = count(`exp'), by(`folio')
	if "`if'" != "" {
		g hog = `=substr("`if'",3,.)'
		*replace hog = hog/`miembros'
	}
	else {
		g hog = 1 // 1/`miembros'
	}

    /*if "`=scalar(aniovp)'" == "2022" {
        local ppp = 9.684
    }
    if "`=scalar(aniovp)'" == "2020" {
        local ppp = 9.813
    }
    if "`=scalar(aniovp)'" == "2018" {
        local ppp = 9.276
    }
    if "`=scalar(aniovp)'" == "2016" {
        local ppp = 8.446
    }
    if "`=scalar(aniovp)'" == "2014" {
        local ppp = 8.045
    }*/


	tempvar varlist2
	g double `varlist2' = `varlist' /* / `ppp' */ `if'

	collapse (sum) `varlist2' hog `relativo' [`weight' = `exp'], by(`n')

	* 1.1 Comprobacion *
	tempname REC
	tabstat `varlist2', stat(sum) f(%25.2fc) save
	matrix `REC' = r(StatTotal)
	noisily di in g "  Monto:" _column(40) in y %25.0fc `REC'[1,1]

	* 1.2 Hogares *
	tempname HOG
	tabstat hog, stat(sum) f(%12.0fc) save
	matrix `HOG' = r(StatTotal)
	noisily di in g "  Hogares:" _column(40) in y %25.0fc `HOG'[1,1]

	* 1.3 Relativo *
	tempname REL
	tabstat `relativo', stat(sum) f(%25.2fc) save
	matrix `REL' = r(StatTotal)
	noisily di in g "  `rellabel':" _column(40) in y %25.0fc `REL'[1,1]

	sort `n'
	foreach k of local nn {
		if `n'[`k'] != `k' {
			replace `n' = `k' in -1
			replace `varlist2' = 0 in -1
			replace `relativo' = 1 in -1
			sort `n'
		}
	}



	***************
	** 2.0 Total **
	quietly {
		sort `n'
		set obs `=_N+1'
		
		label define `n' `=_N' "Total", add
		replace `n' = _N in `=_N'

		tempvar rectot hogtot relativo2
		egen double `rectot' = sum(`varlist2')
		egen double `hogtot' = sum(hog)
		egen double `relativo2' = sum(`relativo')

		replace hog = `hogtot' in `=_N'
		replace `varlist2' = `rectot' in `=_N'
		replace `relativo' = `relativo2' in `=_N'

		* Per capita *
		tempvar recxhog dis prop
		g double recxhog = `varlist2' / hog
		replace recxhog = 0 if recxhog == .

		* Distribucion *
		g double dis = `varlist2'/`rectot' * 100
		replace dis = 0 if dis == .

		// Proporcion como % del `relativo' //
		g double prop = `varlist2' / `relativo' * 100
	}



	*********************************
	** 3.0 Guardar resultados POST **	
	forvalues k=1(1)`=_N' {
		if "`post'" == "post" {
			post INCI (`n'[`k']) (recxhog[`k']) (dis[`k']) (prop[`k']) (hog[`k'])
		}
	}

	restore
}
end
