*************************************************
*Project:		Focalizacion SRE (residencia)	*
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
	#1.1. Focalizacion SRE 2020
	#1.2. Total de residencias SRE 
#2. CRITERIOS FOCALIZACION
#3. CRUCE CON FOC. DIGEIBIRA
#4. PRIORIZACION
#5. RANKING
#6. Propuesta UPP
	##6.1 Focalizacion UPP
	##6.2 Priorizacion UPP
	##6.3 Ranking UPP
*/

*=================*
*#1. PREP AUX DATA*
*=================*

*****************************************
*#1.1. Focalizacion SRE 2020			*
*****************************************

import excel "DISER\MSE Padrones 2020_20092019.xlsx", sheet("SRE 77") ///
	cellrange(A3:R80) firstrow clear
destring COD_MOD , gen(cod_mod)
gen anexo = 0

tempfile sre2020_77
save `sre2020_77'

*****************************************
*#1.2. Total de residencias SRE 		*
*****************************************

import excel "DISER\Secundaria rural - Enviado especialista\SRE\Base de datos 1XX SRE_actualizado.xlsx", ///
	sheet("TOTAL") cellrange(A3:Y176) firstrow clear
destring COD_MOD , gen(cod_mod)
gen anexo = 0

tempfile sre2020_173
save `sre2020_173'

*Nota: las 77 focalizadas son un subconjunto de las 173 identificadas como
*residencias

*****************************************
*#1.2. Total de residencias SRE 		*
*****************************************
import excel "DISER\Padrón SRE 2019 (80 IIEE).xlsx", sheet("Hoja2") ///
cellrange(A4:Y84) firstrow clear

destring COD_MOD , gen(cod_mod)
gen anexo = 0

tempfile sre_plan_multisectorial
save `sre_plan_multisectorial'


*******************************************************************************

*==========================*
*#2. CRITERIOS FOCALIZACION*
*==========================*

/*
- IIEE que brindan el servicio educativo con residencia estudiantil (RM N° 563-2018-MINEDU)
- IIEE públicas de gestión directa y pública de gestión privada.
- IIEE SRE ubicadas en área rural (1,2,3)
- IIEE ubicadas en comunidades nativas
- IIEE SRE ubicados en centros poblados categorizados en el quintil 1 y 2.
- IIEE SRE ubicadas en zonas de frontera y VRAEM

*/

/*
CRITERIOS DE FOCALIZACION 2020 - OPERATIVIZADO:
1.	Parte de la sre2020_173, totalidad de residencias
2.	IE publicas de gestión privada o gestión directa
3.	Rural 1 2 3
4.  Parte de comunidades nativas en sre2020_173
5.	Quintil 1 y 2 de pobreza según CPV
6.	Zona de VRAEM o frontera
*/

use "BasePuraIntegrada.dta", clear
keep if estado == "1" //activas
*drop if gestion == "3" //chau privadas

merge 1:1 cod_mod anexo using `sre2020_173'


merge 1:1 cod_mod anexo using `sre2020_77', gen(sre_77)
label def sre_77 1 "No Focalizada (96)" 3 "Focalizada (77)"
label val sre_77 sre_77 
label var sre_77 "¿La IE es focalizada por DISER?"

merge 1:1 cod_mod anexo using `sre_plan_multisectorial', gen(x)

*1.	Parte de la sre2020_173, totalidad de residencias
gen sre_foca1 = _merge == 3
label var sre_foca1 "Total de residencias en el país"
label def sre_foca1 0 "No residencia" 1 "Si residencia"
label val sre_foca1 sre_foca1
tab sre_foca1 sre_77
drop _m

*2.	IE publicas de gestión privada o gestión directa
gen sre_foca2 = gestion == "1" | gestion == "2" if !missing(gestion)
label var sre_foca2 "IE es pública gestión privada o gestión directa"
label def sre_foca2 0 "Privada" 1 "Publica"
label val sre_foca2 sre_foca2
tab sre_foca2 if sre_foca1 == 1

*3.	Rural 1 2 3
gen sre_foca3 = ruralidad != "" 
label var sre_foca3 "IE rurales"
label def sre_foca3 0 "Urbano" 1 "Rural"
label val sre_foca3 sre_foca3
tab sre_foca3 if sre_foca1 == 1 & sre_foca2 == 1

*4.  Parte de comunidades nativas en sre2020_173
encode Tipodelocalidad , gen(comunidad)
gen sre_foca4 = comunidad == 2
label var sre_foca4 "IE parte de comunidad nativa"
label def sre_foca4 0 "No comunidad nativa" 1 "Comunidad nativa"
label val sre_foca4 sre_foca4

tab sre_foca4 if sre_foca1 == 1 & sre_foca2 == 1 & sre_foca3 == 1


*5.	Quintil 1 y 2 de pobreza según CPV
gen sre_foca5 = quintiles_pobreza == 1 | quintiles_pobreza == 2 if !missing(gestion)
label var sre_foca5 "Criterio de pobreza"
label def sre_foca5 0 "Quintil 3 4 5" 1 "Quintil 1 2 "
label val sre_foca5 sre_foca5
tab sre_foca5 if sre_foca1 == 1 & sre_foca2 == 1 & sre_foca3 == 1 & sre_foca4 == 1

*6. Zona de VRAEM o frontera
gen sre_foca6 = frontera_rm093 == 1 | vraem_rm093 == 1
label var sre_foca6 "Criterio de zona de conflicto"
label def sre_foca6 0 "Sin conflicto" 1 "VRAEM o Huallaga o frontera"
label val sre_foca6 sre_foca6
tab sre_foca6 if sre_foca1 == 1 & sre_foca2 == 1 & sre_foca3 == 1 & sre_foca4 == 1 & sre_foca5 == 1

egen sre_focatot = rowmean(sre_foca1 sre_foca2 sre_foca3 sre_foca4 sre_foca5 sre_foca6)


*================*
*#4. PRIORIZACION*
*================*

/*
1. IIEE SRE que han sido beneficiadas (intervención) con personal CAS, dotación 
	de Kits x Minedu y AP ENDIS.
2. IIEE SRE que reciben el PNAE Qaliwarma.
3. IIEE SRE priorizadas en el “Plan Multisectorial para la atención integral 
	de las y los estudiantes de la Secundaria con Residencia Estudiantil en 
	el ámbito rural de la Amazonía, 2019-2021” (R.S. N° 154-2018-PCM)
*/

/*
CRITERIOS DE PRIORIZACION 2020 - OPERATIVIZADO:
1.	SRE focalizado en 2019
2.	Tiene Qaliwarma
3.	Plan multisectorial (IE del padrón)
*/

*1.	SRE focalizado en 2019
mvencode foc_residencias, override mv(0)
tab foc_residencias  if sre_focatot == 1

*2.	Que tienen Qaliwarma 
gen sre_prio1 = qali_warma == 1 //Aquí modificar para realizar el filtro
label var sre_prio1 "IE con Qaliwarma"
label def sre_prio1 0 "No Qaliwarma" 1 "Sí Qaliwarma"
label val sre_prio1 sre_prio1 
tab sre_prio1 if foc_residencias == 1&  sre_focatot == 1


*3.	Plan multisectorial (IE zona amazonía)
gen plan = x == 3 
label var plan "IIEE del Plan multisectorial"
label def plan 0 "No parte del plan" 1 "Parte del plan"
label val plan plan

drop x
tab plan if foc_residencias == 1&  sre_focatot == 1 & sre_prio1 == 1

*================*
*#5. RANKING	 *
*================*
label def foc_residencias 0 "No focalizada" 1 "Residencia focalizada 2019"
label val foc_residencias foc_residencias  

egen sre_priotot = rowmean(foc_residencias sre_prio1 plan) if sre_foca1 == 1

gsort -sre_focatot -sre_priotot -foc_residencias -sre_prio1 plan
*ranking según promedio de criterios de priorizacion y que sea un crfa de diser
gen sre_rank = _n if sre_foca1 == 1


br sre_rank sre_focatot sre_priotot foc_residencias sre_prio1 sre_foca1 ///
sre_foca2 sre_foca3 sre_foca4 sre_foca5 sre_foca6 plan sre_77 if sre_77 == 3

tab sre_foca1 if sre_77 == 3
tab sre_foca2 if sre_77 == 3
tab sre_foca3 if sre_77 == 3
tab sre_foca4 if sre_77 == 3
tab sre_foca5 if sre_77 == 3
tab sre_foca6 if sre_77 == 3

graph bar (count) sre_77 if sre_77 == 3, over(sre_foca3) blabel(total)	///
bargap(5) graphregion(color(white)) title("Según área", position(12))  ///
note("Nota: Rural incluye los tres gradientes de ruralidad", size(vsmall) position(7)) ///
 ytitle("N. SRE") name(SRE_rural, replace) 
 
graph bar (count) sre_77 if sre_77 == 3, over(sre_foca4) blabel(total)	///
bargap(5) graphregion(color(white)) title("Según tipo de comunidad", position(12))  ///
 ytitle("N. SRE") name(SRE_nativa, replace)
 
 
 graph bar (count) sre_77 if sre_77 == 3, over(sre_foca5) blabel(total)	///
bargap(5) graphregion(color(white)) title("Según quintiles de pobreza", position(12))  ///
 ytitle("N. SRE") name(SRE_pob, replace)

graph bar (count) sre_77 if sre_77 == 3, over(sre_foca6) blabel(total)	///
bargap(5) graphregion(color(white)) title("Según tipo de zona", position(12))  ///
 ytitle("N. SRE") name(SRE_zona, replace)
 
graph combine SRE_rural SRE_nativa SRE_pob SRE_zona , ///
 graphregion(color(white))  title("Distribución de IIEE SRE", position(12)) ///
subtitle("De las 77 IIEE focalizadas por DISER") ///
caption("Fuente: Elaboración propria con datos de DISER y Base Pura", size(vsmall) position(7)) /// 
note("Nota: Todas las SRE focalizadas son públicas y brindan el servicio de residencia", size(vsmall) position(7)) 

graph export "Output\SRE.png", replace


*=================*
*6. PROPUESTA UPP *
*=================*
*6.1 Focalizacion UPP

/*
- IIEE que brindan el servicio educativo con residencia estudiantil (RM N° 563-2018-MINEDU)
- IIEE públicas de gestión directa y pública de gestión privada.
- IIEE SRE ubicadas en área rural (1,2,3)

*/

/*
CRITERIOS DE FOCALIZACION 2020 - OPERATIVIZADO:
1.	Parte de la sre2020_173, totalidad de residencias
2.	IE publicas de gestión privada o gestión directa
3.	Rural 1 2 3
*/

*1.	Parte de la sre2020_173, totalidad de residencias
tab sre_foca1 sre_77

*2.	IE publicas de gestión privada o gestión directa
tab sre_foca2 if sre_foca1 == 1

*3.	Rural 1 2 3
tab sre_foca3 if sre_foca1 == 1 & sre_foca2 == 1

egen sre_focatot_upp = rowmean(sre_foca1 sre_foca2 sre_foca3)

*6.1 PRIORIZACION UPP

/*
1. IIEE SRE que han sido beneficiadas (intervención) con personal CAS, dotación 
	de Kits x Minedu y AP ENDIS.
2. IIEE SRE que reciben el PNAE Qaliwarma.
3. IIEE SRE priorizadas en el “Plan Multisectorial para la atención integral 
	de las y los estudiantes de la Secundaria con Residencia Estudiantil en 
	el ámbito rural de la Amazonía, 2019-2021” (R.S. N° 154-2018-PCM)
4.  Parte de comunidades nativas en sre2020_173
5.	Quintil 1 y 2 de pobreza según CPV
6.	Zona de VRAEM o frontera
*/

/*
CRITERIOS DE PRIORIZACION 2020 - OPERATIVIZADO:
1.	SRE focalizado en 2019
2.	Tiene Qaliwarma
3.	Plan multisectorial (IE del padrón)
4.  Parte de comunidades nativas en sre2020_173
5.	Quintil 1 y 2 de pobreza según CPV
6.	Zona de VRAEM o frontera
*/

*1.	SRE focalizado en 2019

tab foc_residencias  if  sre_focatot_upp == 1

*2.	Que tienen Qaliwarma 
tab sre_prio1 if foc_residencias == 1&  sre_focatot_upp == 1

*3.	Plan multisectorial (IE del padrón)
tab plan if foc_residencias == 1&  sre_focatot_upp == 1 & sre_prio1 == 1

*4.  Parte de comunidades nativas en sre2020_173
tab sre_foca4 if sre_focatot_upp == 1 & foc_residencias == 1 & sre_prio1 == 1 ///
& plan==1

*5.	Quintil 1 y 2 de pobreza según CPV
tab sre_foca5 if sre_focatot_upp == 1 & foc_residencias == 1 & sre_prio1 == 1 & ///
 sre_foca4 == 1 & plan==1

*6. Zona de VRAEM o frontera
tab sre_foca6 if sre_focatot_upp == 1 & foc_residencias == 1 & sre_prio1 == 1 & ///
 sre_foca4 == 1 & sre_foca5 == 1 & plan==1

egen sre_upp = rowmean(foc_residencias sre_prio1 plan sre_foca4 sre_foca5 sre_foca6 ) if sre_foca1 == 1

gsort -sre_focatot_upp -sre_upp -foc_residencias -sre_prio1 -plan -sre_foca4 ///
-sre_foca5 -sre_foca6
*ranking según promedio de criterios de priorizacion y que sea un crfa de diser
gen sre_rank_upp = _n if sre_foca1 == 1


br sre_rank_upp sre_focatot_upp sre_upp foc_residencias sre_prio1 plan sre_foca1 ///
sre_foca2 sre_foca3 sre_foca4 sre_foca5 sre_foca6 plan sre_77 if sre_77 == 3
 
 *****************************
 
 graph bar (count) sre_foca1 if sre_rank_upp <= 77, over(sre_foca3) blabel(total)	///
bargap(5) graphregion(color(white)) title("Según área", position(12))  ///
note("Nota: Rural incluye los tres gradientes de ruralidad", size(vsmall) position(7)) ///
 ytitle("N. SRE") name(SRE_rural, replace) 
 
 graph bar (count) sre_foca1 if sre_rank_upp <= 77, over(sre_foca4) blabel(total)	///
bargap(5) graphregion(color(white)) title("Según tipo de comunidad", position(12))  ///
 ytitle("N. SRE") name(SRE_nativa, replace)
 
 
 graph bar (count) sre_foca1 if sre_rank_upp <= 77, over(sre_foca5) blabel(total)	///
bargap(5) graphregion(color(white)) title("Según quintiles de pobreza", position(12))  ///
 ytitle("N. SRE") name(SRE_pob, replace)

 graph bar (count) sre_foca1 if sre_rank_upp <= 77, over(sre_foca6) blabel(total)	///
bargap(5) graphregion(color(white)) title("Según tipo de zona", position(12))  ///
 ytitle("N. SRE") name(SRE_zona, replace)
 
graph combine SRE_rural SRE_nativa SRE_pob SRE_zona , ///
 graphregion(color(white))  title("Distribución de IIEE SRE", position(12)) ///
subtitle("De las 77 IIEE focalizadas por UPP") ///
caption("Fuente: Elaboración propria con datos de DISER y Base Pura", size(vsmall) position(7))
graph export "Output\SRE_UPP.png", replace

 
*===============================END OF PROGRAM===============================*

