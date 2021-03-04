****************************
****  LIMPIA INEGI BIE  ****
****      SCN, SNA      ****
****************************
program define LimpiaBIE

	syntax [anything] [, NOMultiply]
	drop if B == ""

	foreach k of varlist _all {

		* Nombre *
		local name = reverse(`k'[1])
		local name2 = `k'[2]

		* Busca la posición de > en el string name, si existe el símbolo, el nombre cambia *
		* al substring que termina en la posición *
		local pos = strpos("`name'",">")
		if `pos' > 0 {
			local name = substr("`name'",1,`pos')
		}
		local name = reverse("`name'")

		* Limpia el nombre de símbolos *
		local name = subinstr("`name'",">","",.)
		local name = subinstr("`name'","r1","",.)
		local name = subinstr("`name'","p1","",.)
		local name = subinstr("`name'","/","",.)

		* Acentos *
		local name = subinstr("`name'","â€¡","{c a'}",.)
		local name = subinstr("`name'","Å½","{c e'}",.)
		local name = subinstr("`name'","â€™","{c i'}",.)
		local name = subinstr("`name'","â€”","{c o'}",.)
		local name = subinstr("`name'","Å“","{c u'}",.)
		local name = subinstr("`name'","Ã§","{c A'}",.)
		local name = subinstr("`name'","Æ’","{c E'}",.)
		local name = subinstr("`name'","Ãª","{c I'}",.)
		local name = subinstr("`name'","Ã®","{c O'}",.)
		local name = subinstr("`name'","Ã²","{c U'}",.)
		
		local name2 = subinstr("`name2'","â€¡","{c a'}",.)
		local name2 = subinstr("`name2'","Å½","{c e'}",.)
		local name2 = subinstr("`name2'","â€™","{c i'}",.)
		local name2 = subinstr("`name2'","â€”","{c o'}",.)
		local name2 = subinstr("`name2'","Å“","{c u'}",.)
		local name2 = subinstr("`name2'","Ã§","{c A'}",.)
		local name2 = subinstr("`name2'","Æ’","{c E'}",.)
		local name2 = subinstr("`name2'","Ãª","{c I'}",.)
		local name2 = subinstr("`name2'","Ã®","{c O'}",.)
		local name2 = subinstr("`name2'","Ã²","{c U'}",.)

		* Trim *
		local name = trim("`name'")
		local name = itrim("`name'")

		local name2 = trim("`name2'")
		local name2 = itrim("`name2'")

		* Nombre final *
		replace `k' = "`name', `name2'" in 1

		* Label *
		label var `k' "`=`k'[1]'"

		* Periodo *
		replace `k' = subinstr(`k',"p/","",.)
		replace `k' = subinstr(`k',"r/","",.)
		replace `k' = subinstr(`k',"ND","",.)
	}

	drop in 1
	drop if A == ""
	destring _all, replace	

	* Pesos *
	if "`nomultiply'" == "" {
		foreach k of varlist _all {
			local label : var label `k'
			if `"`=substr("`label'",1,7)'"' != "Periodo" {
				replace `k' = `k'*1000000
				format `k' %20.0fc
				recast double `k'
			}
		}
	}

	* Rename *
	foreach k of varlist _all {
		local label : var label `k'
		if `"`=substr("`label'",1,7)'"' != "Periodo" {
			rename `k' `k'`anything'
		}
	}	

	compress
end
