*****************************************************
*Project:		Focalizacion ST secundaria tutorial	*
*Institution:	MINEDU             					*
*Author:		Brenda Teruya						*
*Last edited:	2019-09-24          				*
*****************************************************

*=========*
*#0. SETUP*
*=========*

glo dd "C:\Users\analistaup2\Google Drive\Trabajo\MINEDU_trabajo\UPP\Actividades\Focalizacion"
set excelxlsxlargefile on
cd "$dd\datos"


/*
INDICE:
#1. PREP AUX DATA
	#1.1. Focalizacion ST 2020
	#1.2. Focalizacion ST 2019 
#2. CRITERIOS FOCALIZACION
#3. CRUCE CON FOC. DIGEIBIRA
#4. PRIORIZACION
#5. RANKING
#6. PROPUESTA UPP
*/

*=================*
*#1. PREP AUX DATA*
*=================*

*****************************************
*#1.1. Focalizacion ST 2020  			*
*****************************************

import excel "DISER\MSE Padrones 2020_20092019.xlsx", sheet("ST 36") ///
	cellrange(A4:O40) firstrow clear
replace CODIGOMODULAR = "" if CODIGOMODULAR == "EN TRÁMITE"
destring CODIGOMODULAR, gen(cod_mod)
rename COMUNIDADNÚCLEO comunidad_nucleo
gen anexo = 0
tempfile st2020
save `st2020'

*****************************************
*#1.1. Focalizacion ST 2019  			*
*****************************************

import excel "DISER\ST escenarios 2 all.xlsx", sheet("Anexo 2.4.PxQ") ///
	cellrange(A4:BM48) firstrow clear
destring CODIGOMODULAR, gen(cod_mod)
rename COMUNIDADNÚCLEO comunidad_nucleo

replace comunidad_nucleo = "BUENAVISTA" if comunidad_nucleo == "BUENA VISTA"
replace comunidad_nucleo = "UNION PALOMAR" if comunidad_nucleo == "LA UNION PALOMAR"
replace comunidad_nucleo = "LOS ANGELES TOTERANI" if comunidad_nucleo == "LOS ANGELES DE TOTERANI"
replace comunidad_nucleo = "SAN PABLO SHIMASHIRO" if comunidad_nucleo == "SAN PABLO DE SHIMASHIRO"
replace comunidad_nucleo = "KM 93 ALTO UBIRIKI" if comunidad_nucleo == "ALTO UBIRIKI KM 93"
replace comunidad_nucleo = "AGUACHINI" if comunidad_nucleo == "SEPTIMO UNIDOS DE SANTA FE DE AGUACHINI"
replace comunidad_nucleo = "LOS ANGELES DE IPOKI" if comunidad_nucleo == "Los Angeles de Ipoki"
replace comunidad_nucleo = "ALIANZA RIO PENEDO" if comunidad_nucleo == "Mariscal Castilla"

*keep if Foc2019 == 1	
tempfile st2019 
save `st2019'

use `st2020', clear
	
merge 1:1 comunidad_nucleo using `st2019'
drop if _m == 1
gen focalizada = _m == 3
label var focalizada "Año en que la escuela fue Focalizada"
label def focalizada 1 "Focalizada en 2020" 0 "No Focalizada" 
label val focalizada focalizada
drop if focalizada == 0
drop _m

tempfile st 
save `st'

import dbase using "C:\Users\analistaup2\Downloads\Padron_web_20190918\Padron_web.dbf", clear
destring COD_MOD , gen(cod_mod)
destring ANEXO, gen(anexo)
tempfile padron
save  `padron'


*==========================*
*#2. CRITERIOS FOCALIZACION*
*==========================*

/*
CRITERIOS DE FOCALIZACION 2020 - DISER:
-IIEE Núcleo educativo con una alta dispersión poblacional (geografía abrupta, economía, distancia entre hogares e IIEE.
-IIEE Núcleos educativos ubicados en área rural (1, 2,3).
-IIEE Núcleos educativos creadas (36) en el marco de la proyección de demanda, solicitada por la UGEL/DRE.
-IIEE Núcleos educativos que prestan servicios educativos de nivel secundaria por más de un año.
*/

/*
CRITERIOS DE FOCALIZACION 2020 - OPERATIVIZADO:
1.	Pensando cómo medir dispersión
2.	Rural 1 2 3
3.	Parte del padrón de 36 IE (st2020)
4.	Parte del padrón de focalizado 2019
*/

use "BasePuraIntegrada.dta", clear
replace ruralidad_rm093 = "Urbano" if ruralidad_rm093 == ""
 

merge 1:m cod_mod anexo using `st', nogen
tab estado focalizada, m

drop if estado == "2" //inactivas quitarlas
drop if focalizada == .

replace códigomodularcreadoparaST20 = "" if códigomodularcreadoparaST20 == "EN TRAMITE"
rename cod_mod cod_mod_antiguo
destring códigomodularcreadoparaST20, gen(cod_mod)

merge m:1 cod_mod anexo using `padron'
drop if _m == 2
drop _m


*1.	Pensando cómo medir dispersión


*2.	Rural 1 2 3
codebook ruralidad_rm093 
tab ruralidad_rm093 ,m

*3.	Parte del padrón de 36 IE (st2020)
codebook focalizada

*4.	Parte del padrón de focalizado 2019
codebook focalizada

*============================*
*#3. CRUCE CON FOC. DISER	 *
*============================*


*================*
*#4. PRIORIZACION*
*================*

/*
1. IIEE Núcleos educativos (32) que vienen implementando el servicio educativo Secundaria Tutorial.
2. IIEE Núcleos educativos creadas y que la DRE/UGEL ha solicitado su incorporación.
3. IIEE núcleos educativos que reciben el PNAE Qaliwarma.

*/

/*
CRITERIOS DE PRIORIZACION 2020 - OPERATIVIZADO:
1. Parte del padrón de focalizado 2019
2. Parte del padrón de 36 IE (st2020)
4.	Que tienen Qaliwarma 
*/

*1. Parte del padrón de focalizado 2019
codebook focalizada

*2. Parte del padrón de 36 IE (st2020)
codebook focalizada

*4.	Que tienen Qaliwarma 
gen d_qaliwarma = qali_warma == 1 //Aquí modificar para realizar el filtro
label var d_qaliwarma "IE con Qaliwarma"
label def d_qaliwarma 0 "No Qaliwarma" 1 "Sí Qaliwarma"
label val d_qaliwarma d_qaliwarma 

codebook d_qaliwarma



*===============================END OF PROGRAM===============================*

