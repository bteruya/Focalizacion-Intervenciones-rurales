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
	
tempfile st2019 
save `st2019'

use `st2020', clear
	
merge 1:1 comunidad_nucleo using `st2019'
rename _m focalizada
label var focalizada "Año en que la escuela fue Focalizada"
label def focalizada 1 "Focalizada en 2020" 2 "Focalizada en 2019" 3 "Focalizada en 2019 y 2020"
label val focalizada focalizada

tempfile st 
save `st'

use "BasePuraIntegrada.dta", clear
merge 1:m cod_mod anexo using `st'
drop _m
replace códigomodularcreadoparaST20 = "" if códigomodularcreadoparaST20 == "EN TRAMITE"
rename cod_mod cod_mod_antiguo
destring códigomodularcreadoparaST20, gen(cod_mod)

preserve

import dbase using "C:\Users\analistaup2\Downloads\Padron_web_20190918\Padron_web.dbf", clear
destring COD_MOD , gen(cod_mod)
destring ANEXO, gen(anexo)
tempfile padron
save  `padron'

restore

merge m:1 cod_mod anexo using `padron'
	
/*las dos IE que faltan en la base pura focalizadas en 2020 se ubican en Pasco
PROVINCIA	DISTRITO
OXAPAMPA	CONTITUCIÓN
OXAPAMPA	POZUSO
*/	

*===============================END OF PROGRAM===============================*

