program define REC
quietly {
	version 13.1
	syntax varname, POBlacion(string) ANIObase(int) [BOOTstrap(int 1) POST title(string)]

	noisily di _newline in y "  proyecciones.ado"




	********************************
	*** 0. Guardar base original ***
	********************************
	preserve




	********************
	*** 1. Poblacion ***
	********************
	use if entidad == "Nacional" using `"`c(sysdir_site)'/04_master/$pais/Poblacion.dta"', clear
	sort anio
	local anio = anio in 1

	keep `poblacion' edad sexo anio
	reshape wide `poblacion', i(edad sexo) j(anio)

	mkmat `poblacion'* if sexo == 1, matrix(HOM)
	mata: HOM = st_matrix("HOM")
	mkmat `poblacion'* if sexo == 2, matrix(MUJ)
	mata: MUJ = st_matrix("MUJ")




	******************************
	*** 2. Proyecciones Modulo ***
	******************************
	** 2.1 Recaudacion **
	*mata: `=upper("`varlist'")' = (PC * (colsum(HOM :* PERFIL[.,1] :* CONTBEN[.,1]/100) + colsum(MUJ :* PERFIL[.,2] :* CONTBEN[.,2]/100)))
	mata: `=upper("`varlist'")' = PC * ((PERFIL[.,1]' :* CONTBEN[.,1]'/100) * HOM + (PERFIL[.,2]' :* CONTBEN[.,2]'/100) * MUJ)


	** 2.2 Contribuyentes/Beneficiarios **
	*mata: CONT = (colsum(HOM :* PERFIL[.,1] :* CONTBEN[.,1]/100) + colsum(MUJ :* PERFIL[.,2] :* CONTBEN[.,2]/100)) // Equivalentes
	*mata: CONT = ((PERFIL[.,1]' :* CONTBEN[.,1]'/100) * HOM + (PERFIL[.,2]' :* CONTBEN[.,2]'/100) * MUJ) // Equivalentes 2
	mata: CONT = ((CONTBEN[.,1]'/100) * HOM + (CONTBEN[.,2]'/100) * MUJ) // Nominal

	* Por Sexo *
	*mata: CONT_Hom = (colsum(HOM :* PERFIL[.,1] :* CONTBEN[.,1]/100)) // Equivalentes
	*mata: CONT_Hom = (PERFIL[.,1]' :* CONTBEN[.,1]'/100) * HOM // Equivalentes 2
	mata: CONT_Hom = (CONTBEN[.,1]'/100) * HOM // Nominal
	*mata: CONT_Muj = (colsum(MUJ :* PERFIL[.,2] :* CONTBEN[.,2]/100)) // Equivalentes
	*mata: CONT_Muj = (PERFIL[.,2]' :* CONTBEN[.,2]'/100) * MUJ // Equivalentes 2
	mata: CONT_Muj = (CONTBEN[.,2]'/100) * MUJ // Nominal


	* Por Edades *
	local last = rowsof(MUJ)
	mata: CONT_0_24 = ///
		(colsum(HOM[|1,1 \ 25,.|] :* PERFIL[|1,1 \ 25,1|] :* CONTBEN[|1,1 \ 25,1|]/100) + ///
		 colsum(MUJ[|1,1 \ 25,.|] :* PERFIL[|1,2 \ 25,2|] :* CONTBEN[|1,2 \ 25,2|]/100))
	mata: CONT_25_49 = ///
		(colsum(HOM[|26,1 \ 50,.|] :* PERFIL[|26,1 \ 50,1|] :* CONTBEN[|26,1 \ 50,1|]/100) + ///
		 colsum(MUJ[|26,1 \ 50,.|] :* PERFIL[|26,2 \ 50,2|] :* CONTBEN[|26,2 \ 50,2|]/100))
	mata: CONT_50_74 = ///
		(colsum(HOM[|51,1 \ 75,.|] :* PERFIL[|51,1 \ 75,1|] :* CONTBEN[|51,1 \ 75,1|]/100) + ///
		 colsum(MUJ[|51,1 \ 75,.|] :* PERFIL[|51,2 \ 75,2|] :* CONTBEN[|51,2 \ 75,2|]/100))
	mata: CONT_75_mas = ///
		(colsum(HOM[|76,1 \ .,.|] :* PERFIL[|76,1 \ `last',1|] :* CONTBEN[|76,1 \ `last',1|]/100) + ///
		 colsum(MUJ[|76,1 \ .,.|] :* PERFIL[|76,2 \ `last',2|] :* CONTBEN[|76,2 \ `last',2|]/100))


	** 2.3 Poblacion **
	mata: POB = colsum(HOM) + colsum(MUJ)


	** 2.4 A Stata **
	* Recaudacion *
	tempname `=upper("`varlist'")'
	mata: st_matrix(`"``=upper("`varlist'")''"',`=upper("`varlist'")'')
	
	* Per capita *
	tempname PC
	mata: st_matrix(`"`PC'"',PC)

	* Contribuyentes/Beneficiarios *
	tempname CONT
	mata: st_matrix(`"`CONT'"',CONT')

	* Por Sexo *
	tempname CONT_Hom CONT_Muj
	mata: st_matrix(`"`CONT_Hom'"',CONT_Hom')
	mata: st_matrix(`"`CONT_Muj'"',CONT_Muj')

	* Por Edades *
	tempname CONT_0_24 CONT_25_49 ///
		CONT_50_74 CONT_75_mas
	mata: st_matrix(`"`CONT_0_24'"',CONT_0_24')
	mata: st_matrix(`"`CONT_25_49'"',CONT_25_49')
	mata: st_matrix(`"`CONT_50_74'"',CONT_50_74')
	mata: st_matrix(`"`CONT_75_mas'"',CONT_75_mas')
	
	* Poblacion *
	tempname POB
	mata: st_matrix(`"`POB'"',POB')	



	******************************
	* 3. Guardar resultados POST *
	if "`post'" == "post" {
		forvalues k=1(1)`=rowsof(``=upper("`varlist'")'')' {
			post REC ("`title'") (`bootstrap') (`anio') (`aniobase') ///
				(``=upper("`varlist'")''[`k',1]) ///
				(`CONT'[`k',1]) (`POB'[`k',1]) (`PC'[1,1]) ///
				(`CONT_Hom'[`k',1]) (`CONT_Muj'[`k',1]) ///
				(`CONT_0_24'[`k',1]) (`CONT_25_49'[`k',1]) ///
				(`CONT_50_74'[`k',1]) (`CONT_75_mas'[`k',1]) 
			local ++anio
		}
	}



	***************
	** 4.0 Final **
	restore
}
end
