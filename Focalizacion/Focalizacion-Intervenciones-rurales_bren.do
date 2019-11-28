*************************************************************************
*Project:		Focalizacion ruralidad alumnos	 			
*Institution:	MINEDU             				 			
*Author:		Brenda Teruya y María Luisa Zeta 			
*Last edited:	2019-010-15          			 			
*Objetive: 		Map out all education services provided in rural areas
**************************************************************************

*Preparamos Stata

clear all
set more off

*Definimos las rutas 

global minedu C:\Users\analistaup2\Google Drive\Trabajo\MINEDU_trabajo
global ue $minedu\UE\Proyecciones\3. Data\4. Student level

glo dd "$minedu\UPP\Actividades\Focalizacion"
set excelxlsxlargefile on
cd "$dd\datos"


********************************************************************************
*Preparamos la BD
use "BasePuraIntegrada.dta", clear

sort cod_mod anexo, stable 

*Parte I: Preparamos la BD

*Quitamos las escuelas inactivas (único criterio de exclusión) 
keep if estado == "1" 
preserve
*Acompañamiento polidocente

import excel "DIFODS\Padron_AP_2019.xlsx", sheet("Todo") cellrange(A3:E2723) firstrow clear
destring codmod, gen(cod_mod)
destring anexo, replace
keep cod_mod anexo
tempfile padron_ap
save `padron_ap'

restore
merge 1:1 cod_mod anexo using `padron_ap'

recode _merge (1 = .)(3 = 1), gen(foc_ap)
drop _m
label var foc_ap "Focalizacion 2019: Acompañamiento polidocente"

preserve
*Rutas solidarias (bici)
import excel "Rutas solidarias (bici)\BDIRS_23.10.2019.xlsx", sheet("Base IRS") ///
	cellrange(A1:I5846) firstrow clear
destring CódigoModular, gen(cod_mod)
gen anexo = 0 	

keep cod_mod anexo TOTALBICICLETAS
duplicates drop cod_mod anexo, force 
*El cod_mod 0411710 esta repetido, no importa solo queremos saber que existe
tempfile padron_bici
save `padron_bici'

restore

merge 1:1 cod_mod anexo using `padron_bici'

recode _merge (1 = .)(3 = 1), gen(foc_rutasoli)
drop _m
label var foc_rutasoli "Focalizacion 2019: Rutas solidarias"

preserve

*Subvenciones
import excel "DISER\IIEE PM Rurales_Subvención_RMN° 054-2019-MINEDU.xlsx", ///
sheet("Consolidado") cellrange(A4:Q122) clear firstrow

destring CÓDIGOMODULAR, gen(cod_mod)
gen anexo = 0
keep cod_mod anexo Comentarios

tempfile subvencion
save `subvencion'

restore
merge 1:1 cod_mod anexo using `subvencion'

recode _merge (1 = .)(3 = 1), gen(foc_subvencion)
drop _m

label var foc_subvencion "Focalizacion 2019: Subvenciones"

preserve

*Delitos
import dbase using "Censo penitenciario\512-Modulo862\01_PENALES_CAP200.dbf" , clear
egen ubigeo = concat(P201_CCDD P201_CCPP P201_CCDI) 
replace ubigeo = "" if ubigeo == "999999" 
drop if ubigeo == ""
isid ID_CARATUL INTERNO_ID
rename ubigeo codgeo

collapse (count) n_interno = INTERNO_ID , by(codgeo)
label var n_interno "N. de internos por distrito"

summ n_interno
gen d_interno = n_interno > r(mean)
label var d_interno "Dummy que indica si el n. internos > media"
label def d_interno 0 "Menor a media de internos" 1 "Mayor a media de internos"
label val d_interno d_interno 

tempfile censo_pen
save `censo_pen'


restore
merge m:1 codgeo using `censo_pen'
drop if _m == 2
drop _m

preserve

*Desercion

import excel "Censo Educativo\D._Permanencia_y_progreso-Tasa_de_deserción_permanente_en_Educación_Secundaria_(%_de_matrícula_final).xls", ///
sheet("Distrital") cellrange(B8:O1882) firstrow clear

rename CÓDIGO codgeo

*los missing tienen la letra a
keep codgeo O
replace O = "" if O == "a"

rename O desercion

tempfile desercion
save `desercion'

restore
merge m:1 codgeo using `desercion'
drop _m


preserve
*Importar Resultados del ejercicio 2018
import dbase using "Censo Educativo\2018\Resultados2018.dbf", clear case(lower)
destring cod_mod, replace
destring anexo, replace

tempfile result18
save `result18'

*Inicial Escolarizado, RETIRADOS: no desaprueban por ley
use `result18', clear
keep if nroced == "1B" //inicial
keep if cuadro == "C101" //Resultado del ejercicio
keep if tipdato == "02" // Los retirados
egen n_retirados = rowtotal(d01 - d08) // Esas son las variables con datos
label var n_retirados "N. retirados por IE"
keep cod_mod anexo n_retirados

tempfile inicial_retirados
save `inicial_retirados'

*PRONOEI retirados: no desaprueban por ley
use `result18', clear
keep if nroced == "2B" //PRONOEI
keep if cuadro == "C101" //Resultado del ejercicio
keep if tipdato == "02" // Los retirados
egen n_retirados = rowtotal(d01 - d08) // Esas son las variables con datos
label var n_retirados "N. retirados por IE"
keep cod_mod anexo n_retirados

tempfile pronoei_retirados
save `pronoei_retirados'


*Primaria retirados: desaprueban a partir de 2 primaria
use `result18', clear
keep if nroced == "3BP" //Primaria
keep if cuadro == "C101" //Resultado del ejercicio
keep if tipdato == "08" // Los retirados
egen n_retirados = rowtotal(d01 - d12) // Esas son las variables con datos
label var n_retirados "N. retirados por IE"
keep cod_mod anexo n_retirados

tempfile primaria_retirados
save `primaria_retirados'

*Primaria desaprobados: desaprueban a partir de 2 primaria
use `result18', clear
keep if nroced == "3BP" // Primaria
keep if cuadro == "C101" //Resultado del ejercicio
keep if tipdato == "05" // Los desaprobados al principio
egen n_desaprobados1 = rowtotal(d01 - d12) // Esas son las variables con datos
label var n_desaprobados1 "N. desaprobados por IE"
keep cod_mod anexo n_desaprobados1

*Los desaprobados directamente en primaria
tempfile temp1
save `temp1'


*Primaria desaprobados: luego de recuperacion
use `result18', clear
keep if nroced == "3BP" // Primaria
keep if cuadro == "C201" //Resultado del ejercicio
keep if inlist(tipdato, "03", "04", "05") 
*Los desaprobados (en la misma IE o en otra IE) o no dieron la prueba luego de ir a recuperacion
egen n_desaprobados2 = rowtotal(d01 - d12) // Esas son las variables con datos
label var n_desaprobados2 "N. desaprobados por IE"
isid cod_mod anexo tipdato

collapse (sum) n_desaprobados2, by(cod_mod anexo)

*Los desaprobados luego de ir a recuperacion
merge 1:1 cod_mod anexo using `temp1', nogen
egen n_desaprobados = rowtotal(n_desaprobados1 n_desaprobados2)
keep cod_mod anexo n_desaprobados
isid cod_mod anexo

merge 1:1 cod_mod anexo using `primaria_retirados', nogen

tempfile primaria
save `primaria'


*Secundaria retirados
use `result18', clear
keep if nroced == "3BS" // Secundaria
keep if cuadro == "C101" //Resultado del ejercicio
keep if tipdato == "08" // Los retirados
egen n_retirados = rowtotal(d01 - d10) // Esas son las variables con datos
label var n_retirados "N. retirados por IE"
keep cod_mod anexo n_retirados

*Los desaprobados directamente en primaria
tempfile secundaria_retirados
save `secundaria_retirados'

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

merge 1:1 cod_mod anexo using `secundaria_retirados', nogen

tempfile secundaria
save `secundaria'

use `inicial_retirados', clear
append using `pronoei_retirados'
append using `primaria'
append using `secundaria'

save `result18', replace

restore

merge 1:1 cod_mod anexo using `result18'
*Hay 178 IE en el 2018 que no están en 2019 base pura integrada
drop if _m == 2

drop _m


********************************************************************************
*Parte II: Creamos dummies y hacemos encode de las variables strings

encode d_niv_mod, gen(niv_mod_n)

recode niv_mod_n (1/5 = .) (6/9 = 1 "Inicial") (10 = 2 "Primaria")  ///
	(11 = 3 "Secundaria") (12/15 = .) ,gen(nivel)


encode d_gestion, gen (tipo_gestion) // variable para generar dummy de Fe y alegria 

gen foc_rutafluvial = . 
replace foc_rutafluvial = 1 if cod_mod == 0533018
replace foc_rutafluvial = 1 if cod_mod == 0808253
*solo para 2 ie en secundaria que están en la selva rural 1

*Si una IE recibe dos o más intervenciones está cuantificada dos o más veces de acuerdo al número de intervenciones

egen int_ie = rowtotal(foc_ap  foc_apmultigrado foc_apeib ///
foc_orquestando foc_expresarte foc_rutafluvial foc_rutasoli ) if !missing(ruralidad_rm093), m

*Generamos la variable de IIEE atendidas, en donde una IIEE se cuenta solo una vez asi reciba mas de una intervención. 

gen atendidas = int_ie > 0 & !missing(int_ie)

gen obs = 1 

encode d_cod_car_c19, gen(carac_19)

********************************************************************************
*Parte III: Creamos las variables contenidas en la matriz 

*A. Inicial 
tab niv_mod_n ruralidad_rm093,m
*todos los PRONOEI son urbanos
gen se_inicial = 1 if niv_mod_n == 9 & !missing(ruralidad_rm093)
*PRONOEI, los PRONOEI no tienen curriculo inicial 
replace se_inicial = 2 if foc_curriculo_inicial == 1 & !missing(ruralidad_rm093)
*curriculo inicial es solo en inicial escolarizado 

label var se_inicial "Servicios Educativos Inicial rural"
label def se_inicial 1 "PRONOEI" 2 "CEI"
label val se_inicial se_inicial 

codebook se_inicial

*B. Primaria 
gen se_primaria = 1 if carac_19 == 2 & nivel == 2 & !missing(ruralidad_rm093)
replace se_primaria = 2 if carac_19 == 3 & nivel == 2 & !missing(ruralidad_rm093)
replace se_primaria = 3 if carac_19 == 4 & nivel == 2 & !missing(ruralidad_rm093)

label var se_primaria "Servicios Educativos primaria rural"
label def se_primaria 1 "Polidocente completo" 2 "Multigrado" 3 "Unidocente" 
label val se_primaria se_primaria 

*Identificamos las escuelas Fe y Alegria 

*ssc install chartab
chartab cen_edu , noascii //chequeamos cómo luce esta string 

gen cen_nombre = upper(ustrto(ustrnormalize(cen_edu, "nfd"), "ascii", 2))

gen tot_fa=strpos(cen_nombre,"FE Y ALEGRIA")
gen tot_fa1=strpos(cen_nombre,"FE ALEGRIA")

*Generamos la variable Fe y Alegria 
	
gen fe_alegria=0 
replace fe_alegria=1 if tot_fa>0|tot_fa1>0

la var fe_alegria "Escuelas Fe y Alegria" 
*Identificamos escuelas con subvenciones

gen subvenciones = 1 if foc_subvencion == 1

gen convencional = 1 if foc_subvencion == . & fe_alegria == 0


*C. Secundaria 

gen se_secundaria = 1 if foc_jec == 1 & !missing(ruralidad_rm093) & nivel == 3
replace se_secundaria = 4 if missing(foc_jec) & !missing(ruralidad_rm093) & nivel == 3

replace se_secundaria = 2 if foc_crfa == 1 

replace se_secundaria = 3 if foc_residencias == 1

label var se_secundaria "Servicios Educativos secundaria ruralidad"
label def se_secundaria 1 "JEC rural" 2 "CRFA" 3 "Residencia" ///
4 "JER rural"
label val se_secundaria se_secundaria 
codebook se_secundaria


gen servicios_educativos_rural = .
replace servicios_educativos_rural  = 1 if niv_mod_n == 9 // PRONOEI
replace servicios_educativos_rural  = 2 if foc_curriculo_inicial == 1 // CEI 

replace servicios_educativos_rural  = 3 if nivel == 2 & carac_19 == 4 // Primaria, unidocente
replace servicios_educativos_rural  = 4 if nivel == 2 & carac_19 == 4 & fe_alegria == 1
// Primaria, unidocente, fe y alegria
replace servicios_educativos_rural  = 5 if nivel == 2 & carac_19 == 4 & subvenciones == 1 // Primaria, unidocente subvenciones
replace servicios_educativos_rural  = 6 if nivel == 2 & carac_19 == 4 & convencional == 1 // Primaria, unidocente convencional

replace servicios_educativos_rural  = 7 if nivel == 2 & carac_19 == 3 // primaria multigrado
replace servicios_educativos_rural  = 8 if nivel == 2 & carac_19 == 3 & fe_alegria == 1 // primaria multigrado fe y alegria
replace servicios_educativos_rural  = 9 if nivel == 2 & carac_19 == 3 & subvenciones == 1 // primaria multigrado subvenciones
replace servicios_educativos_rural  = 10 if nivel == 2 & carac_19 == 3 & convencional == 1 // primaria multigrado convencional

replace servicios_educativos_rural  = 11 if nivel == 2 & carac_19 == 2 // primaria polidocente

replace servicios_educativos_rural  = 12 if nivel == 3 // secundaria JER
replace servicios_educativos_rural  = 13 if foc_jec == 1 // Secundaria JEC

replace servicios_educativos_rural = . if missing(ruralidad_rm093) // excluimos lo urbano

replace servicios_educativos_rural  = 14 if foc_crfa == 1 // CRFA
replace servicios_educativos_rural  = 15 if foc_residencias == 1 //Residencia

label var servicios_educativos_rural "Servicios Educativos "
label def servicios_educativos_rural 1 "PRONOEI" 2 "CEI" 3 "Unidocente" ///
4 "Unidocente Fe y Alegria" 5 "Unidocente Subvenciones" 6 "Unidocente convencional" ///
7 "Multigrado" 8 "Multigrado Fe y Alegria" 9 "Multigrado Subvenciones" ///
10 "Multigrado convencional" 11 "Polidocente" 12 "JER" ///
13 "JEC" 14 "CRFA" 15 "SRE"

label val servicios_educativos_rural servicios_educativos_rural 

gen total_alumno_urb = total_alumnos if missing(ruralidad_rm093)
gen total_alumno_rur = total_alumnos if !missing(ruralidad_rm093)

gen L16_4_urb = L16_4/100 if missing(ruralidad_rm093)
gen L16_4_rur = L16_4/100 if !missing(ruralidad_rm093)


gen pobre_porc_urb = pobre_porc/100 if missing(ruralidad_rm093)
gen pobre_porc_rur = pobre_porc/100 if !missing(ruralidad_rm093)

*C. EIB

gen servicios_educativos = .
replace servicios_educativos  = 1 if niv_mod_n == 9 // PRONOEI
replace servicios_educativos  = 2 if foc_curriculo_inicial == 1 // CEI 

replace servicios_educativos  = 3 if nivel == 2 & carac_19 == 4 // Primaria, unidocente
replace servicios_educativos  = 4 if nivel == 2 & carac_19 == 4 & fe_alegria == 1
// Primaria, unidocente, fe y alegria
replace servicios_educativos  = 5 if nivel == 2 & carac_19 == 4 & subvenciones == 1 // Primaria, unidocente subvenciones
replace servicios_educativos  = 6 if nivel == 2 & carac_19 == 4 & convencional == 1 // Primaria, unidocente convencional

replace servicios_educativos  = 7 if nivel == 2 & carac_19 == 3 // primaria multigrado
replace servicios_educativos  = 8 if nivel == 2 & carac_19 == 3 & fe_alegria == 1 // primaria multigrado fe y alegria
replace servicios_educativos  = 9 if nivel == 2 & carac_19 == 3 & subvenciones == 1 // primaria multigrado subvenciones
replace servicios_educativos  = 10 if nivel == 2 & carac_19 == 3 & convencional == 1 // primaria multigrado convencional

replace servicios_educativos  = 11 if nivel == 2 & carac_19 == 2 // primaria polidocente

replace servicios_educativos  = 12 if nivel == 3 // secundaria JER
replace servicios_educativos  = 13 if foc_jec == 1 // Secundaria JEC
replace servicios_educativos  = 14 if foc_crfa == 1 // CRFA
replace servicios_educativos  = 15 if foc_residencias == 1 //Residencia

label var servicios_educativos "Servicios Educativos EIB (incluye urbano)"
label def servicios_educativos 1 "PRONOEI" 2 "CEI" 3 "Unidocente" ///
4 "Unidocente Fe y Alegria" 5 "Unidocente Subvenciones" 6 "Unidocente convencional" ///
7 "Multigrado" 8 "Multigrado Fe y Alegria" 9 "Multigrado Subvenciones" ///
10 "Multigrado convencional" 11 "Polidocente" 12 "JER" ///
13 "JEC" 14 "CRFA" 15 "SRE"

label val servicios_educativos servicios_educativos 

*Ratio de desaprobados y retirados

*Retirados

gen r_retirados = n_retirados/ total_alumnos
label var r_retirados "Ratio de retirados sobre matricula"

gen r_retirados_rur = r_retirados if ruralidad_rm093 != ""
gen r_retirados_urb = r_retirados if ruralidad_rm093 == ""

egen univ_desaprobado = rowtotal(talumno_siagie_2p - talumno_siagie_5s)
label var univ_desaprobado "Matricula de 2 primaria a 5 secundaria"

gen r_desaprobados = n_desaprobados/ univ_desaprobado
label var r_desaprobados "Ratio de desaprobados sobre matricula 2p-5s"

gen r_desaprobados_rur = r_desaprobados if ruralidad_rm093 != ""
gen r_desaprobados_urb = r_desaprobados if ruralidad_rm093 == ""

/////
*tablas de Mapeo

*Tabla 1
tabstat obs int_ie atendidas  , by(servicios_educativos_rural) stat(sum) 


*Tabla 2
tabstat foc_ap foc_apmultigrado foc_apeib foc_orquestando foc_expresarte  foc_rutasoli ///
, stat(sum) by(servicios_educativos_rural) 

tab servicios_educativos forma_eib_rn 

*Tabla 3 matricula

tabstat  total_alumno_rur total_alumno_urb  ,by(servicios_educativos) stat(sum)

tabstat L16_4_urb L16_4_rur  ,by(servicios_educativos) stat(mean)

tabstat pobre_porc_urb pobre_porc_rur ,by(servicios_educativos) stat(mean)

********************************************************************************
*Tablas de resultados
tabstat n_desaprobados  n_retirados , by(servicios_educativos) stat(sum)
tabstat r_desaprobados_*  r_retirados_*  , by(servicios_educativos) stat(mean)



