program define Acentos

	syntax [varname]

	if "`=c(os)'" == "Unix" {
		if "`varlist'" != "" {
			replace `varlist' = subinstr(`varlist',"�","�",.)
			replace `varlist' = subinstr(`varlist',"�","�",.)
			replace `varlist' = subinstr(`varlist',"�","�",.)
			replace `varlist' = subinstr(`varlist',"�","�",.)
			replace `varlist' = subinstr(`varlist',"�","�",.)

			replace `varlist' = subinstr(`varlist',"�","�",.)
			replace `varlist' = subinstr(`varlist',"�","�",.)
			replace `varlist' = subinstr(`varlist',"�","�",.)
			replace `varlist' = subinstr(`varlist',"�","�",.)
			replace `varlist' = subinstr(`varlist',"�","�",.)

			replace `varlist' = subinstr(`varlist',"�","�",.)
			replace `varlist' = subinstr(`varlist',"�","�",.)
		}

		else {
			global A "�"
			global E "�"
			global I "�"
			global O "�"
			global U "�"

			global a "�"
			global e "�"
			global i "�"
			global o "�"
			global u "�"

			global NI "�"
			global ni "�"
		}
	}


	if "`=c(os)'" == "MacOSX" {
		if "`varlist'" != "" {
			replace `varlist' = subinstr(`varlist',"�","�",.)
			replace `varlist' = subinstr(`varlist',"�","�",.)
			replace `varlist' = subinstr(`varlist',"�","�",.)
			replace `varlist' = subinstr(`varlist',"Ó","�",.)
			replace `varlist' = subinstr(`varlist',"�","�",.)

			replace `varlist' = subinstr(`varlist',"á","�",.)
			replace `varlist' = subinstr(`varlist',"é","�",.)
			replace `varlist' = subinstr(`varlist',"í","�",.)
			replace `varlist' = subinstr(`varlist',"ó","�",.)
			replace `varlist' = subinstr(`varlist',"ú","�",.)

			replace `varlist' = subinstr(`varlist',"�","�",.)
			replace `varlist' = subinstr(`varlist',"�","�",.)
		}

		else {
			global A "�"
			global E "�"
			global I "�"
			global O "�"
			global U "�"

			global a "�"
			global e "�"
			global i "�"
			global o "�"
			global u "�"

			global ni "�"
			global NI "�"
		}
	}


	if "`=c(os)'" == "Windows" {
		if "`varlist'" != "" {
			replace `varlist' = subinstr(`varlist',"�","�",.)
			replace `varlist' = subinstr(`varlist',"�","�",.)
			replace `varlist' = subinstr(`varlist',"�","�",.)
			replace `varlist' = subinstr(`varlist',"�","�",.)
			replace `varlist' = subinstr(`varlist',"�","�",.)

			replace `varlist' = subinstr(`varlist',"�","�",.)
			replace `varlist' = subinstr(`varlist',"�","�",.)
			replace `varlist' = subinstr(`varlist',"�","�",.)
			replace `varlist' = subinstr(`varlist',"�","�",.)
			replace `varlist' = subinstr(`varlist',"�","�",.)

			replace `varlist' = subinstr(`varlist',"�","�",.)
			replace `varlist' = subinstr(`varlist',"�","�",.)
		}

		else {
			global A "�"
			global E "�"
			global I "�"
			global O "�"
			global U "�"

			global a "�"
			global e "�"
			global i "�"
			global o "�"
			global u "�"

			global ni "�"
		}
	}

end
