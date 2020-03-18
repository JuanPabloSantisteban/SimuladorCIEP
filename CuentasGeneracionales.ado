program define CuentasGeneracionales, rclass
quietly {
	timer on 95

	version 13.1
	syntax varname, ANIObase(int) [BOOTstrap(int 1) Graphs POST]

	noisily di _newline in g "{bf:Cuentas Generacionales: " in y "$pais `aniobase'}"
	local title : variable label `varlist'



	*******************************
	*** 0 Guardar base original ***
	*******************************
	preserve



	*******************
	*** 1 Poblacion ***
	*******************
	use `"`c(sysdir_site)'../basesCIEP/SIM/Poblacion`=subinstr("${pais}"," ","",.)'.dta"', clear

	sort anio
	local anio = anio[1]
	local aniofin = anio[_N]
	local edadmax = edad[_N]+1
	keep if anio >= `aniobase'

	reshape wide poblacion, i(edad sexo) j(anio)

	mkmat poblacion* if sexo == 1, matrix(HOM)
	mata: HOM = st_matrix("HOM")
	mkmat poblacion* if sexo == 2, matrix(MUJ)
	mata: MUJ = st_matrix("MUJ")

	mata: lambda = st_numscalar("lambda")


	
	****************
	** 2 Perfiles **
	****************
	use `"`c(sysdir_personal)'/users/$pais/`id'/bootstraps/`bootstrap'/`varlist'PERF"', clear
	collapse perfil1 perfil2 contribuyentes1 contribuyentes2, by(edad)

	sort edad
	mkmat perfil1 perfil2, matrix(PERFIL)
	mkmat contribuyentes1 contribuyentes2, matrix(CONT)

	mata: PERFIL = st_matrix("PERFIL")
	mata: CONTBEN = st_matrix("CONT")



	**************************
	*** 3 Monto per capita ***
	**************************
	use `"`c(sysdir_personal)'/users/$pais/`id'/bootstraps/`bootstrap'/`varlist'PC"', clear

	ci montopc
	local montopc = r(mean)

	ci edad39
	local edad39 = r(mean)

	if `edad39' == . | `edad39' == 0 {
		local pc = `montopc'
	}
	else {
		local pc = `edad39'
	}

	mata: PC = `pc'



	*****************************
	*** 4 Proyecciones Modulo ***
	*****************************
	mata GA = J(`edadmax',3,0)
	forvalues edad = 1(1)`edadmax' {
		forvalues row = 1(1)`edadmax' {
			forvalues col = 1(1)`edadmax' {
				if `row' == `col'+`edad'-1 {
					if `col' <= `aniofin'-`aniobase'+1 {
						mata GA[`edad',1] = GA[`edad',1] + ///
							PERFIL[`row',1] :* HOM[`row',`col'] * PC * ///
							(1 + lambda[1,1]/100)^(`col'-1) / (1 + ${discount}/100)^(`col'-1)
						mata GA[`edad',2] = GA[`edad',2] + ///
							PERFIL[`row',2] :* MUJ[`row',`col'] * PC * ///
							(1 + lambda[1,1]/100)^(`col'-1) / (1 + ${discount}/100)^(`col'-1)
					}
					else {
						mata GA[`edad',1] = GA[`edad',1] + ///
							PERFIL[`row',1] :* HOM[`row',`=`aniofin'-`aniobase'+1'] * PC * ///
							(1 + lambda[1,1]/100)^(`col'-1) / (1 + ${discount}/100)^(`col'-1)
						mata GA[`edad',2] = GA[`edad',2] + ///
							PERFIL[`row',2] :* MUJ[`row',`=`aniofin'-`aniobase'+1'] * PC * ///
							(1 + lambda[1,1]/100)^(`col'-1) / (1 + ${discount}/100)^(`col'-1)
					}
				}
			}
		}
	}
	mata GA[.,3] = (GA[.,1] + GA[.,2]) :/ (HOM[.,1] + MUJ[.,1])
	mata GA[.,1] = GA[.,1] :/ HOM[.,1] 
	mata GA[.,2] = GA[.,2] :/ MUJ[.,1]


	** 2.4 A Stata **
	mata: st_matrix("GA",GA)

	levelsof edad, local(edades)
	noisily di _newline in g " Edad" ///
		_column(10) %20s "Hombres" ///
		_column(20) %20s "Mujeres" ///
		_column(30) %20s "Total"
	forvalues k = 0(5)`edadmax' {
		noisily di in g _col(3) "`k'" _cont
		noisily di in g _column(10) in y %20.0fc GA[`k'+1,1] _cont
		noisily di in g _column(20) in y %20.0fc GA[`k'+1,2] _cont
		noisily di in g _column(30) in y %20.0fc GA[`k'+1,3]
	}



	***************
	*** 5 Final ***
	***************
	restore

	timer off 95
	timer list 95
	noisily di _newline in g "  {bf:Cuentas Generacionales de `title' time}: " in y round(`=r(t95)/r(nt95)',.1) in g " segs."
}
end
