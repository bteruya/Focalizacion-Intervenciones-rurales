*************************************************
*Project:		Focalizacion  	*
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
	#1.1. Focalizacion expresarte 2020	
	#1.2. Base pura
#2. CRITERIOS FOCALIZACION
#3. CRUCE CON FOC. DISER
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
*#1.1. Focalizacion expresarte 2020			*
*****************************************
import excel "DIGEBR\Padron - EXPRESARTE.xlsx", ///
 sheet("Padrón 2019 (RM083-2019)") firstrow clear
count 

destring CODIGOMODULAR, gen(cod_mod)
gen anexo = 0
tempfile expresarte
save `expresarte'



*****************************************
*#1.2. Focalizacion orquestando 2020			*
*****************************************
import excel "DIGEBR\Padron - Orquestando.xlsx", sheet("1.12 Orquestando") ///
cellrange(A3:G16) firstrow clear

destring CódigoModular, gen(cod_mod)
gen anexo = 0
tempfile orquestando
save `orquestando'

*****************************************
*#1.3. Deserción por distrito 			*
*****************************************


import excel "Censo Educativo\D._Permanencia_y_progreso-Tasa_de_deserción_permanente_en_Educación_Secundaria_(%_de_matrícula_final).xls", ///
 sheet("Distrital") cellrange(B8:O1882) firstrow clear

gen codgeo = CÓDIGO
keep codgeo O
rename O desercion_1618
replace desercion_1618 = "" if desercion_1618 == "a"
destring desercion_1618 , replace
tempfile desercion
save `desercion'


*****************************************
*#1.3. Base pura						*
*****************************************

use "BasePuraIntegrada.dta", clear
keep if estado == "1" //activas





*******************************************************************************

*==========================*
*#2. CRITERIOS FOCALIZACION EXPRESARTE*
*==========================*

/*
1. IIEE públicas
2. IIEE con plazas de Promotores Culturales
3. Ubicadas en un distrito con al menos 4 IIEE
4. Contar con las intervenciones de Soporte Pedagógico o Jornada Escolar Completa (JEC)
5. IIEE urbanas, polidocentes y que cuenten con los niveles de primaria y 
   secundaria en un solo local.
6. IIEE que funcionan solo en turno mañana, tanto para primaria y secundaria.
7. Tener una población estudiantil mayor a 200 y menor y/o igual a 1,200 alumnos

*/

/*
CRITERIOS DE FOCALIZACION 2020 - OPERATIVIZADO:
1. IIEE públicas
2. Cualquiera
3. 4 IIEE en el distrito
4. Intervenciones soporte pedagógico o JEC
5. urbanas polidocentes y primaria secundaria en el mismo local
6. turno mañana
7. alumnos entre 200 y 1200
*/

*1. IIEE públicas
gen publica = gestion != "3" //gestion privada 
label var publica "Dummy que indica si la IE es pública"
label def publica 1 "publica" 0 "privada"
label val publica publica


*2. Cualquiera

*3. 4 IIEE en el distrito
sort codgeo
gen uno = 1
by codgeo: egen n_iiee = total(uno)
replace n_iiee = . if codgeo == ""
label var n_iiee "N. de IIEE en el distrito"
codebook n_iiee


gen d_iiee = n_iiee >= 4
label var d_iiee "Dummy que indica si tiene 4 o más IIEE en el distrito"
label def d_iiee 0 "Menos de 4 IIEE en el distrito" 1 "4 o más IIEE en el distrito"
label val d_iiee d_iiee 

*4. Intervenciones soporte pedagógico o JEC
mvencode foc_jec, override mv(0)
label def foc_jec 0 "JER" 1 "JEC"
label val foc_jec foc_jec 

*5. urbanas polidocentes y primaria secundaria en el mismo local
gen urbano = ruralidad_rm093 == ""
label var urbano "Urbano o rural según gradientes de rurarlidad"
label def urbano 0 "Rural 1 2 3" 1 "Urbano"
label val urbano urbano

gen polidocente = inlist(cod_car, "3","a", "m")
tab d_cod_car polidocente


gen d_urb_polidocente = urbano == 1 & polidocente == 1

label var d_urb_polidocente "Dummy que indica urbano o polidocente"
label def d_urb_polidocente 0 "Rural y no polidocente" 1 "Urbano o polidocente"
label val d_urb_polidocente d_urb_polidocente 

sort codlocal
gen prim_sec = inlist(niv_mod, "B0", "F0" ) 
drop if prim_sec == 0 //solo primarias y secundarias

duplicates report codlocal prim_sec niv_mod
duplicates tag codlocal prim_sec niv_mod, gen(x)
*Hay que botar a las IIEE que tienen dos secundarias (o dos primarias) 
*para contar solo a las que tienen una primaria y una secundaria al menos
*por ejemplo el codlocal 033185 tiene dos secundarias, COAR ancash y 
*86577 cesar vallejo mendoza
preserve 
duplicates drop codlocal prim_sec niv_mod, force
by codlocal: egen n_prim_sec = total(prim_sec)
duplicates drop codlocal, force
gen d_prim_sec = n_prim_sec == 2
label var d_prim_sec "Dummy que indica si hay una primaria y secundaria en el mismo local"
label def d_prim_sec 0 "No mismo local" 1 "Sí mismo local"
label val d_prim_sec d_prim_sec 
keep codlocal d_prim_sec
tempfile d_prim_sec 
save `d_prim_sec'
restore

merge m:1 codlocal using `d_prim_sec', nogen
 
*6. turno mañana
gen turno_mna = cod_tur == "11"
label var turno_mna "Dummy que indica si el turno es solo de mañana"
label def turno_mna 0 "No solo mañana" 1 "Solo mañana"
label val turno_mna turno_mna 

*7. alumnos entre 200 y 1200
gen d_alumno_200y1200 = inrange(total_alumnos, 200, 1200)
tabstat total_alumnos , stat(min max) by(d_alumno_200y1200)

label var d_alumno_200y1200 "Dummy que indica si la IE tiene entre 200 y 1200 alumnos"
label def d_alumno_200y1200 0 "No tiene entre 200 y 1200 alumnos" 1 "Entre 200 y 1200 alumnos"
label val d_alumno_200y1200 d_alumno_200y1200



merge 1:1 cod_mod anexo using `expresarte'
gen expresarte = _m == 3
drop _m
label var expresarte "Focalizado para expresarte"
label def expresarte 0 "No expresarte" 1 "Sí expresarte"
label val expresarte expresarte 

codebook publica if expresarte == 1
summ n_iiee if expresarte == 1
codebook foc_jec  if expresarte == 1
codebook urbano  if expresarte == 1

tab urbano if expresarte == 1 
tab polidocente if expresarte == 1
tab d_urb_polidocente if expresarte == 1 
codebook d_prim_sec if expresarte == 1
tab  d_prim_sec d_urb_polidocente if expresarte == 1 
dis 23 + 9
codebook d_iiee  if expresarte == 1 & d_prim_sec == 1 & d_urb_polidocente == 1 

tab d_alumno_200y1200 if expresarte == 1 & d_prim_sec == 1 & d_urb_polidocente == 1 



*======================================*
*#2. CRITERIOS FOCALIZACION Orquestando*
*======================================*

/*
-IIEE de regiones que cuenten con escuelas/conservatorios de música que puedan dotar de educadores musicales a la iniciativa pedagógica ORQUESTANDO.
-IIEE ubicadas en un distrito con alto nivel de deserción/vulnerabilidad.
-IIEE de Educación Básica Regular, polidocentes completas y urbanas
-Contar con los niveles de educación primaria y educación secundaria en el mismo local
-Ubicadas en un distrito con al menos 4 IIEE
-Contar con Jornada Escolar Completa (JEC) (Observaciones: 1 IIEE no es JEC)
-IIEE que funcionan solo en turno mañana, tanto para primaria y secundaria.
-Contar con un director designado en el nivel de educación secundaria.
*/

*Algunos criterios se repiten con Expresarte, tomaré solo los adicionales

/*
1. Conservatorio cerca (NO)
2. Distrito con alta deserción
3. EBR polidocente completo y urbano (ya está)
4. Nivel primaria y secundaria juntos (ya está)
5. Al menos 4 IIEE en el distrito (ya está)
6. JEC (ya está)
7. Turno mañana (ya está)
8. Director en secundaria                                                                                                                                                            
*/


merge 1:1 cod_mod anexo using `orquestando'
gen orquestando = _m == 3
label var orquestando "IE pertenece a orquestando"
label def orquestando 0 "No orquestando" 1 "Sí orquestando"
label val orquestando orquestando 
drop _m

merge m:1 codgeo using  `desercion', nogen

*1. Conservatorio cerca (NO)

*2. Distrito con alta deserción

summ desercion_1618
gen d_desercion2 = desercion_1618 < r(mean)
label var d_desercion2 "La deserción del dist es mayor a la media del Perú"
label def d_desercion2 0 "Menor a media" 1 "Mayor a media"
label val d_desercion2 d_desercion2 

tabstat desercion_1618 , stat(mean) by(d_desercion2) //Mayor a la media tiene más desercion
tab d_desercion2 if orquestando == 1

*3. EBR polidocente completo y urbano 

tab urbano if orquestando == 1 
tab polidocente if orquestando == 1
tab d_urb_polidocente if orquestando == 1 

*4. Nivel primaria y secundaria juntos 
tab  d_prim_sec if orquestando == 1 & d_desercion2 == 1

*5. Al menos 4 IIEE en el distrito 
summ n_iiee if orquestando == 1

*6. JEC 
codebook foc_jec  if orquestando == 1 & d_desercion2 == 1

*7. Turno mañana 
tab turno_mna if orquestando == 1 & d_desercion2 == 1

*8. Director en secundaria     ????

 graph bar (count) orquestando if orquestando == 1, over(d_desercion2) blabel(total)	///
bargap(5) graphregion(color(white)) title("Según deserción", position(12) size(small))  ///
 ytitle("N. IIEE") ylabel(,nogrid ) name(Orquestando1, replace) 
 
 graph bar (count) orquestando if orquestando == 1, over(d_urb_polidocente) blabel(total)	///
bargap(5) graphregion(color(white)) title("Según urbano o polidocente", position(12) size(small))  ///
 ytitle("N. IIEE") ylabel(,nogrid) name(Orquestando2, replace) 
 
 graph bar (count) orquestando if orquestando == 1, over(d_prim_sec) blabel(total)	///
bargap(5) graphregion(color(white)) title("Según primaria y secundaria en el mismo local", size(small) position(12))  ///
 ytitle("N. IIEE") ylabel(,nogrid) name(Orquestando3, replace) 

 graph bar (min) n_iiee , over(orquestando) blabel(total)	///
bargap(5) graphregion(color(white)) title("Mínimo de IIEE en el distrito", position(12) size(small))  ///
 ytitle("Mínimo N. IIEE") ylabel(,nogrid) name(Orquestando4, replace) 

graph bar (count) orquestando if orquestando == 1, over(foc_jec) blabel(total)	///
bargap(5) graphregion(color(white)) title("Según Jornada Regular o Completa", position(12) size(small))  ///
 ytitle("N. IIEE") ylabel(,nogrid) name(Orquestando5, replace) 

 
 graph bar (count) orquestando if orquestando == 1, over(turno_mna) blabel(total)	///
bargap(5) graphregion(color(white)) title("Según condición de primaria y secundaria en el mismo local",  size(small) position(12))  ///
 ytitle("N. IIEE") ylabel(,nogrid) name(Orquestando6, replace) 

graph combine Orquestando1 Orquestando2 Orquestando3 Orquestando4 Orquestando5 Orquestando6 , ///
 graphregion(color(white))  title("Distribución de IIEE Orquestando", position(12)) ///
subtitle("De las 13 IIEE focalizadas por DIGEBR")  ///
caption("Fuente: Elaboración propria con datos de DIGEBR y Base Pura", size(vsmall) position(7))
graph export "Output\Orquestando.png", replace


*===============================END OF PROGRAM===============================*
