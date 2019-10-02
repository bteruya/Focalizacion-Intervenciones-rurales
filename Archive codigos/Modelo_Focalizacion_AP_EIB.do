*************************************
*Project:		Focalizacion AP EIB *
*Institution:	MINEDU              *
*Author:		Sebastian Calvo     *
*Last edited:	2019-09-22          *
*************************************

*=========*
*#0. SETUP*
*=========*

glo dd "C:/Users/analistaup6/Dropbox"
set excelxlsxlargefile on

/*
INDICE:
#1. PREP AUX DATA
	#1.1. Focalizacion AP EIB 2019 Y 2020
	#1.2. Tipologia de UGEL
	#1.3. VITALIDAD DE LENGUAJE
#2. CRITERIOS FOCALIZACION
#3. CRUCE CON FOC. DIGEIBIRA
#4. PRIORIZACION
	#4.1. Importar data auxiliar
	#4.1.1. Vitalidad Lengua Originaria
	#4.1.2. Tipologia UGEL
	#4.2. Calcular Varialbes de Priorizacion
*/

*******************************************************************************

*=================*
*#1. PREP AUX DATA*
*=================*

***************************************
*#1.1. Focalizacion AP EIB 2019 Y 2020*
***************************************

use "${dd}/2020/8. Focalización/1. Herramientas Generales/1. Bases/BP_Integrada_Evolución_EIB.dta", clear
keep cod_mod anexo foc_apeib foc_eib_2020
tempfile foc_apeib
save `foc_apeib'

*************************
*#1.2. Tipologia de UGEL*
*************************

import excel "${dd}/2020/3. Asistencias Técnicas/3. Reunión Resig 2020 Direcciones/2. Presentación/DIGEIBIRA/Acompañamiento EIB/BASE TIPOLOGIA UGEL FINAL V2.xlsx", ///
	sheet("BASE TIPOLOGIA UGEL FINAL 22-05") cellrange(A3:BI219) allstring clear

keep A B BI
rename (A B BI) (cod_ugel nomugel ugel_tipo)

loc alist "á é í ó ú ñ Á É Í Ó Ú Ñ"
loc blist "A E I O U N A E I O U N"
loc n : word count `alist'
forval i = 1/`n' {
	loc a : word `i' of `alist'
	loc b : word `i' of `blist'
	replace nomugel = regexr(nomugel,"`a'","`b'")
}


tempfile ugel_tipo
save `ugel_tipo'

*****************************
*#1.3. VITALIDAD DE LENGUAJE*
*****************************

import excel "${dd}/2020/3. Asistencias Técnicas/3. Reunión Resig 2020 Direcciones/2. Presentación/DIGEIBIRA/Acompañamiento EIB/2019.09.13_MaFlores_Vitalidad_Lengua_APEIB.xlsx", ///
	sheet("10.2.3.variedades") cellrange(C6:T66) allstring clear

rename C leng_grupo
rename E leng_familia
rename G leng_lengua
rename J leng_variedad
rename M leng_vitalidad

keep leng_*
keep if leng_vitalidad=="En peligro" | ///
	leng_vitalidad=="Seriamente en peligro" | leng_vitalidad=="Extinta"

tempfile leng_vitalidad
save `leng_vitalidad'

*******************************************************************************

*==========================*
*#2. CRITERIOS FOCALIZACION*
*==========================*

/*
CRITERIOS DE FOCALIZACION 2020 - DIGEIBIRA:
-II.EE. de nivel inicial (escolarizada) y primaria de la EBR que se 
 encuentran en el Registro Nacional de Instituciones educativas EIB.
-II.EE. Públicas de nivel inicial y primaria de la Educación Básica Regular.
-Unidocente, polidocente incompleta o multigrado, polidocente completa EIB.
-Públicas de gestión directa.
-Con registro de estudiantes y profesores en el SIAGIE
-Con registro de docentes en el Nexus y NEXUS,
 respectivamente.
*/

/*
CRITERIOS DE FOCALIZACION 2020 - OPERATIVIZADO:
1.	Nivel Primaria o Secundaria
2.	Forma escolarizada
3.	Gestion publica directa
4.	Se encuentra en registro EIB
5.	Registro de estudiantes en SIAGIE
6.	Registro de profesores en Nexus
*/

use "${dd}/2020/8. Focalización/1. Herramientas Generales/1. Bases/BasePuraIntegrada.dta", clear

*1.	Nivel Primaria o Secundaria
gen apeib_foca1=(nivel_ciclo=="Primaria" | substr(nivel_ciclo,1,7)=="Inicial")
*2.	Forma escolarizada
gen apeib_foca2=(d_forma=="Escolarizada")
*3.	Gestion publica directa
gen apeib_foca3=(substr(d_gestion,-7,7)=="directa")
*4.	Se encuentra en registro EIB
gen apeib_foca4=(eib_rn==1)
*5.	Registro de estudiantes en SIAGIE
gen apeib_foca5=(talumno_siagie!=.)
*6.	Registro de profesores en Nexus
gen apeib_foca6=(tdocente_nexus!=.)

*Cumple con todos los criterios
gen apeib_focatot=(apeib_foca1 & apeib_foca2 & apeib_foca3 & apeib_foca4 & ///
	apeib_foca5 & apeib_foca6)

*******************************************************************************

*============================*
*#3. CRUCE CON FOC. DIGEIBIRA*
*============================*

merge 1:1 cod_mod anexo using `foc_apeib', nogen

/*Para tener continuidad se cruza IIEE que cumplen con los criterios
con las IIEE focalizadas en 2019.*/
gen apeib_focafin = (apeib_focatot==1 & foc_apeib==1)

/*Hay 21 IIEE de gestion publico-privada que estaban focalizadas en 2019.
Se hace una excepcion para estas.*/
replace apeib_focafin=1 if (apeib_foca3==0 & foc_apeib==1)

keep if apeib_focafin

*******************************************************************************

*================*
*#4. PRIORIZACION*
*================*

******************************
*#4.1. Importar data auxiliar*
******************************

*#4.1.1. Vitalidad Lengua Originaria
clonevar leng_lengua=lengua_originaria
merge m:1 leng_lengua using `leng_vitalidad', keep(master match) nogen

*#4.1.2. Tipologia UGEL
clonevar nomugel=d_dreugel

/*
NOTA SC: Aca no se puede hacer match directo de las dos bases porque tienen
encoding distinto. La BasePuraIntegrada no reconoce los caracteres con
tilde. La "é" hace default a un caracter Unicode vacio, "ú" esta codificado
como la letra "E" mayuscula.

Hay varias opciones aca:
-Re-codificar la base original.
-Hacer una tabla de equivalencias 1:1 (puede ser en excel y luego importar a
.dta) y usarla para el merge.
-Hacer un fuzzy match de las dos bases.
*/

replace nomugel=strtrim(stritrim(nomugel))
replace nomugel = regexr(nomugel,"µ","A")
*Falta reemplazar e con tilde
replace nomugel = regexr(nomugel,"Ö","I")
replace nomugel = regexr(nomugel,"à","O")
*Falta reemplazar i con tilde
replace nomugel = regexr(nomugel,"¥","N")

*****************************************
*#4.2. Calcular Varialbes de Priorizacion*
*****************************************

/*
1.	Ruralidad 1 y 2 (RM N° 093-2019-MINEDU) 
	(Observación: 2 IIEE son urbanas)
2.	Quintil de pobreza 1 y 2 (Pendiente de evaluar)
3.	Zona VRAEM (DS N° 40-2016-PCM-VRAEM)
4.	Áreas críticas de frontera (DS N° 05-2018-RE)
5.	Zona Huallaga (Observación: Considera la RM N° 093-2019-MINEDU)
6.	Tipología de UGEL (I, GH -que tienen desafío territorial-)/ 
	RSG N° 938-2015-MINEDU)
7.	UGEL que cuentan con estudiantes de lenguas en peligro de extinción 
	(DS N° 011-2018- MINEDU) (Solicitar BD de relación UGEL)
8.	IIEE EIB con bajos resultados en ECE 2018 (Observación: Detallar el 
	porcentaje a partir del cual se consideran bajos resultados)
*/

*1.	Ruralidad 1 y 2 (RM N° 093-2019-MINEDU) 
gen apeib_prio1=(ruralidad_rm093=="Rural 1" & ruralidad_rm093=="Rural 2")

*2.	Quintil de pobreza 1 y 2 (Pendiente de evaluar)
gen apeib_prio2=(quintiles_pobreza==1 | quintiles_pobreza==2)

*3.	Zona VRAEM (DS N° 40-2016-PCM-VRAEM)
gen apeib_prio3=(vraem_rm093==1)

*4.	Áreas críticas de frontera (DS N° 05-2018-RE)
gen apeib_prio4=(ac_frontera==1)

*5.	Zona Huallaga (Observación: Considera la RM N° 093-2019-MINEDU)
gen apeib_prio5=(huallaga==1)
*6.	Tipología de UGEL (I, GH) RSG N° 938-2015-MINEDU)
*gen apeib_prio6=......etcetera

*7.	UGEL c/ lenguas en peligro de extinción (DS N° 011-2018- MINEDU)
gen apeib_prio7=(leng_vitalidad=="En peligro" | ///
	leng_vitalidad=="Seriamente en peligro" | leng_vitalidad=="Extinta")
	
*8.	IIEE EIB con bajos resultados en ECE 2018 
/*NOTA SC: Falta decidir como definimos esto. Puede ser % de alumnos en cierto
nivel. En lo personal, yo preferiria usar quintiles del pje. total de ECE. */

*===============================END OF PROGRAM===============================*
