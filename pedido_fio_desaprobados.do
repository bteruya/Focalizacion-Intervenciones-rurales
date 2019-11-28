/**********************************************************
*************************************************************************
*Project:		Añadir variables de vulnerabilidad a la Base Pura integrada		
*Institution:	MINEDU             				 			
*Author:		B. Teruya 			
*Last edited:	2019-27-11          			 			
*Map out all education services provided in rural areas
*Input: 		"Base pura integrada", resultados del ejerricio
*Outputs:		
**************************************************************************
*/
global minedu C:\Users\analistaup2\Google Drive\Trabajo\MINEDU_trabajo
global ue $minedu\UE\Proyecciones\3. Data\4. Student level

glo dd "$minedu\UPP\Actividades\Focalizacion"
set excelxlsxlargefile on
cd "$dd\datos"

global dropbox 	T:\2020\8. Focalización

*Censo Educativo Resultados del Ejercicio

*Importar Resultados del ejercicio 2018
import dbase using "Censo Educativo\2018\Resultados2018.dbf", clear case(lower)
destring cod_mod, replace
destring anexo, replace

tempfile result18 temp1
save `result18'

*Secundaria desaprobados directamente
use `result18', clear
keep if nroced == "3BS" // Secundaria
keep if cuadro == "C101" //Resultado del ejercicio
keep if tipdato == "05" // Los desaprobados al principio
egen n_desaprobados1 = rowtotal(d01 - d10) // Esas son las variables con datos
label var n_desaprobados1 "N. desaprobados por IE"
keep cod_mod anexo n_desaprobados1

save `temp1', replace


*Secundaria desaprobados luego de recuperacion
use `result18', clear
keep if nroced == "3BS" // Secundaria
keep if cuadro == "C201" //Resultado del ejercicio
keep if inlist(tipdato, "03", "04", "05") 
*Los desaprobados (en la mismsa u otra IE) o no dieron la prueba luego de ir a recuperacion
egen n_desaprobados2 = rowtotal(d01 - d10) // Esas son las variables con datos
label var n_desaprobados2 "N. desaprobados por IE"
isid cod_mod anexo tipdato

collapse (sum) n_desaprobados2, by(cod_mod anexo)

*Los desaprobados luego de ir a recuperacion
merge 1:1 cod_mod anexo using `temp1', nogen
egen n_desaprobados = rowtotal(n_desaprobados1 n_desaprobados2)
keep cod_mod anexo n_desaprobados
isid cod_mod anexo

tempfile secundaria
save `secundaria'

*Preparamos la BD
use "BasePuraIntegrada.dta", clear
keep if d_niv_mod == "Secundaria"

merge 1:1 cod_mod anexo using  `secundaria'
mdesc n_desaprobados if foc_jec == 1

tab n_desaprobados if foc_jec == 1
replace n_desaprobados = 0 if _m != 3

drop _m

tempfile temp1
save `temp1'

import excel "ECE\ECE personas 2015 2016 2018\ECE_2018_2S_alumnos.xlsx", sheet("ECE_2018_2S_alumnos") firstrow clear

destring cod_mod7 , gen(cod_mod)
destring anexo, replace

collapse (mean) ise ,by(cod_mod anexo)

merge 1:1 cod_mod anexo using `temp1'

label var n_desaprobados "N. desaprobados por IE"

xtile q_ise = ise if foc_jec == 1, nq(5)

export excel using "Data sets Intermedios\Basepuraintegrada_desaprobados_ise.xls", sheet("variables") firstrow(variables) sheetreplace

export excel using "Data sets Intermedios\Basepuraintegrada_desaprobados_ise.xls", sheet("varlabels") firstrow(varlabels) sheetreplace
