*************************************************
*Project:		Focalizacion ruralidad alumnos	*
*Institution:	MINEDU             				*
*Author:		Brenda Teruya					*
*Last edited:	2019-010-15          			*
*************************************************

global minedu C:\Users\analistaup2\Google Drive\Trabajo\MINEDU_trabajo
global ue $minedu\UE\Proyecciones\3. Data\4. Student level

glo dd "$minedu\UPP\Actividades\Focalizacion"
set excelxlsxlargefile on
cd "$dd\datos"


***
*tablas de Mapeo
import excel "DIFODS\Padron_AP_2019.xlsx", sheet("Todo") cellrange(A3:E2723) firstrow clear
destring codmod, gen(cod_mod)
destring anexo, replace
keep cod_mod anexo
tempfile padron_ap
save `padron_ap'

use "BasePuraIntegrada.dta", clear
keep if estado == "1" 
merge 1:1 cod_mod anexo using `padron_ap'

recode _merge (1 = .)(3 = 1), gen(foc_ap)
drop _m
label var foc_ap "Focalizacion 2019: Acompañamiento polidocente"

encode d_niv_mod, gen(niv_mod_n)

recode niv_mod_n (1/5 = .) (6/9 = 1 "Inicial") (10 = 2 "Primaria")  ///
	(11 = 3 "Secundaria") (12/15 = .) ,gen(nivel)

drop if missing(nivel)

tab niv_mod_n ruralidad_rm093,m
*todos los PRONOEI son urbanos
gen se_inicial = 1 if niv_mod_n == 9 
*PRONOEI, los PRONOEI no tienen curriculo inicial 
replace se_inicial = 2 if foc_curriculo_inicial == 1 
*curriculo inicial es solo en inicial escolarizado 

label var se_inicial "Servicios Educativos Inicial"
label def se_inicial 1 "PRONOEI" 2 "CEI"
label val se_inicial se_inicial 

codebook se_inicial
gen obs = 1 

gen se_secundaria = 1 if foc_jec == 1 & !missing(ruralidad_rm093) & nivel == 3
replace se_secundaria = 4 if missing(foc_jec) & !missing(ruralidad_rm093) & nivel == 3

replace se_secundaria = 2 if foc_crfa == 1 

replace se_secundaria = 3 if foc_residencias == 1

label var se_secundaria "Servicios Educativos secundaria"
label def se_secundaria 1 "JEC rural" 2 "CRFA" 3 "Residencia" ///
4 "JER rural"
label val se_secundaria se_secundaria 
codebook se_secundaria

encode d_cod_car_c19, gen(carac_19)
gen se_primaria = 1 if carac_19 == 2 & nivel == 2
replace se_primaria = 2 if carac_19 == 3 & nivel == 2
replace se_primaria = 3 if carac_19 == 4 & nivel == 2

gen foc_rutafluvial = . 
replace foc_rutafluvial = 1 if cod_mod == 0533018
replace foc_rutafluvial = 1 if cod_mod == 0808253
*solo para 2 ie en secundaria que están en la selva rural 1

label var se_primaria "Servicios Educativos primaria"
label def se_primaria 1 "Polidocente completo" 2 "Multigrado" 3 "Unidocente" 
label val se_primaria se_primaria 

egen tot_atendidas = rowtotal(foc_ap  foc_apmultigrado foc_apeib ///
foc_orquestando foc_expresarte foc_rutafluvial) if !missing(ruralidad_rm093), m
replace tot_atendidas =1  if tot_atendidas == 2

label var tot_atendidas "Total de IE rurales atendidas"

gen foc_jec1 = foc_jec == 1 
replace foc_jec1 = . if foc_residencias == 1 // las residencias JEC no se cuentan doble
replace foc_jec1 = . if foc_crfa == 1


tabstat foc_ap foc_apmultigrado foc_apeib  obs if nivel == 1, stat(count) by(se_inicial) 
tabstat foc_orquestando foc_expresarte  obs if nivel == 1, stat(count) by(se_inicial)
*-puros ceros, no hay itervenciones en inicial 

tabstat foc_ap foc_apmultigrado foc_apeib  obs if nivel == 3, stat(count) by(se_secundaria) 
tabstat foc_orquestando foc_expresarte obs if nivel == 3, stat(count) by(se_secundaria) 
tabstat foc_rutafluvial  obs if nivel == 3, stat(count) by(se_secundaria) 

tabstat foc_ap foc_apmultigrado foc_apeib  obs if nivel == 2, stat(count) by(se_primaria)
tabstat foc_orquestando foc_expresarte obs if nivel == 2, stat(count) by(se_primaria) 

tab  se_primaria tot_atendidas
tab  se_secundaria tot_atendidas


tabstat total_alumnos if !missing(ruralidad_rm093) & nivel == 3, stat(sum) by(se_secundaria)
tabstat total_alumnos if !missing(ruralidad_rm093) & nivel == 3, stat(sum) by(foc_jec1)
tabstat total_alumnos if missing(ruralidad_rm093) & nivel == 3, stat(sum) by(foc_jec1) //urbanos

tabstat total_alumnos if missing(ruralidad_rm093) & nivel == 3, stat(sum) by(se_secundaria)


tabstat total_alumnos if !missing(ruralidad_rm093) & nivel == 2, stat(sum) by(se_primaria) //rural
tabstat total_alumnos if missing(ruralidad_rm093) & nivel == 2, stat(sum) by(se_primaria) //urbano

tabstat total_alumnos if !missing(ruralidad_rm093) & nivel == 1, stat(sum) by(se_inicial) 
*tabstat total_alumnos if missing(ruralidad_rm093) & nivel == 1, stat(sum) by(se_inicial) //urbano

table se_inicial ruralidad_rm093 nivel , m c(sum total_alumnos) //solo son rurales

table forma_eib_rn se_inicial if nivel == 1, c(sum total_alumnos freq) mi
