*************************************************
*Project:		Focalizacion  					*
*Institution:	MINEDU             				*
*Author:		Brenda Teruya					*
*Last edited:	2019-09-23          			*
*************************************************

*=========*
*#0. SETUP*
*=========*

glo dd "C:\Users\analistaup2\Google Drive\Trabajo\MINEDU_trabajo\UPP\Actividades\Focalizacion"
set excelxlsxlargefile on
cd "$dd\datos"


/*
INDICE:
#1. PREP AUX DATA
	#1.1. Focalizacion Wiñaq 2020	
	#1.2. Base pura
#2. CRITERIOS FOCALIZACION
*/

*=================*
*#1. PREP AUX DATA*
*=================*

*=================*
*##1.1. Padrón wiñaq*
*=================*

import excel "DIGEBR\Padron - Wiñaq.xlsx", ///
sheet("PADRON DEPORTIVOS_ESCUELAS") cellrange(A1:Y201) firstrow clear
destring MODULAR, gen(cod_mod)
gen anexo = 0

tempfile winaq
save `winaq'

*=================*
*##1.2. Delitos*
*=================*
import dbase using "Censo penitenciario\512-Modulo862\01_PENALES_CAP200.dbf" , clear

*=================*
*##1.3 Base pura*
*=================*

use "BasePuraIntegrada.dta", clear
keep if estado == "1" //activas

merge 1:1 cod_mod anexo using `winaq'
gen n_winaq = _m == 3
drop _m

collapse (sum) total_alumnos (sum) n_winaq_real = n_winaq (max)n_winaq, by(codgeo)
label var total_alumnos "Total alumnos del distrito"
label var n_winaq_real "N. de núcleos Winaq DIGEBR"
*merge 1:1 codgeo using `delitos'

gen n_winaq_teorico = 1 if inrange(total_alumnos, 2000, 5999)
replace n_winaq_teorico = 2 if inrange(total_alumnos, 6000, 9999)
replace n_winaq_teorico = 3 if inrange(total_alumnos, 10000, 19999)
replace n_winaq_teorico = 4 if total_alumnos > 20000 
label var n_winaq_teorico "N. núcleos según normativa"

tab n_winaq_real n_winaq_teorico if n_winaq == 1

