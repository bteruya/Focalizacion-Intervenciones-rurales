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
*=================*
*##1.3 Base pura*
*=================*

use "BasePuraIntegrada.dta", clear
keep if estado == "1" //activas

merge 1:1 cod_mod anexo using `winaq'
gen n_winaq = _m == 3
drop _m

merge m:1 codgeo using `censo_pen'
drop if _m == 2

codebook d_gestion if n_winaq == 1
tab d_interno if n_winaq == 1
replace n_winaq = 0  if d_interno == 0 & n_winaq == 1 // quitar los focalizados
*winaq si no cumplen con el numero de delitos

bys codgeo: egen ece_lectura_inicio = mean(L18_2)


collapse (sum) total_alumnos (sum) n_winaq_real = n_winaq (max)n_winaq ///
	(first) n_interno ece_lectura_inicio, by(codgeo)
label var total_alumnos "Total alumnos del distrito"
label var n_winaq_real "N. de núcleos Winaq DIGEBR"

gen n_winaq_teorico = 1 if inrange(total_alumnos, 2000, 5999)
replace n_winaq_teorico = 2 if inrange(total_alumnos, 6000, 9999)
replace n_winaq_teorico = 3 if inrange(total_alumnos, 10000, 19999)
replace n_winaq_teorico = 4 if total_alumnos > 20000 
label var n_winaq_teorico "N. núcleos según normativa"

tab n_winaq_real n_winaq_teorico if n_winaq == 1, m

br if n_winaq_real >= 5  
replace n_winaq_real = 4 if n_winaq_real >= 5  
gen d_ece = ece_lectura_inicio > 0.1
label var d_ece "Dummy que indica si el % alumnos del distrito en ECE lecutra > 10%"
label def d_ece 0 "Menor a 10%" 1 "Mayor a 10%"
label val d_ece d_ece 

tabstat n_winaq_real ,stat(sum) by(d_ece)

