***************************************************************************************************************************
*Objetivo: Crear una base de estudiantes de escuelas EIB 
*Nombre: María Luisa Zeta Valladolid 
*Fecha: Octubre 15, 2019 
***************************************************************************************************************************

*Preparamos Stata e identificamos los directorios

clear all
set more off 
tempfile temp1 temp2 temp3 

global root "C:\Users\ESPECIALISTAUP13\Desktop"
global dropbox "C:\Users\ESPECIALISTAUP13\Dropbox"
********************************************************************************

*Usamos la base pura integrada para hacer una caracterización a nivel de escuela 

use "$dropbox\2020\8. Focalización\1. Herramientas Generales\1. Bases\BasePuraIntegrada"

*Creamos una dummy que identifique las escuelas eib vs. las no eib 

gen eib_rn_1=0
replace eib_rn_1=1 if eib_rn==1

*Exploramos distribución entre urbano rural de las escuelas EIB

tab dareamed_c19 if eib_rn_1==1, m // 74.8 son rurales. Tiene sentido comparar EIB con no EIB rural 

*Creamos otra variable que identifica escuelas EIB, vs escuelas no EIB rurales

gen tipo_escuela=0
replace tipo_escuela=1 if eib_rn_1==1 
replace tipo_escuela=2 if eib_rn_1==0 & dareamed_c19=="Rural"



label define tipo 1 "EIB" 2 "no EIB rural" 

label value tipo_escuela tipo 

keep if tipo_escuela!=0

*Variables de interes

/*Variables: 

 ruralidad_rm093 gestion ///
 pobre_porc foc_jec ssbb_luz ssbb_agua ssbb_desague ///
 ssbb_completos  vraem_rm093  frontera_rm093 huallaga ///
 total_alumnos total_secciones total_docentes d_cod_tur tipo_ugel ///
 tiempo_dre_ugel
 
Saqué de la lista original: 
d_ges_dep_c19 d_gestion_c19  d_gestion // solo necesitamos una var de gestion 
region_nat_c19 // tiene muchos missings 
cod_tur // ya tenemos turno 
*/
 

*Creamos las dummies 
*Ruralidad: 3 gradientes, creamos la dummy de la gradiente 1 

gen rural_1= 1 if inlist(ruralidad_rm093, "Rural 1")
replace rural_1=0 if rural_1==. 

*Gestion: dummy publica de gestion directa, publica de gestion privada, privada 

foreach X of numlist 1/3 {
gen gestion_`X'=1 if gestion=="`X'"
replace gestion_`X'=0 if gestion_`X'==.
}

*Reemplzamos por 0 las missings en variables numéricas dicotómicas 

local vars_num foc_jec ssbb_luz ssbb_agua ssbb_desague ssbb_completos  vraem_rm093  frontera_rm093 huallaga

foreach var of varlist `vars_num' {
replace `var'=0 if `var'==.
}

*Variable de turno 
gen turno_m=1 if inlist(d_cod_tur, "Manana")
replace turno_m=0 if turno_m==.

*Variable tipo UGEL 

gen ugel_alta=1 if inlist(tipo_ugel, "Tipo GH", "Tipo I")
replace ugel_alta=0 if tipo_ugel!="" & ugel_alta!=1 

*Etiquetamos las variables nuevas creadas 

la var rural_1 "Gradiente de ruralidad 1" 
la var gestion_1 "Publica de gestion directa"
la var gestion_2 "Publica de gestion privada"
la var gestion_3 "Privada"
la var turno_m "Turno manana"
la var ugel_alta "UGEL Desafio Territorial Alto" 

*Creamos el global con las variables propuestas 


 global determinantes rural_1 gestion_1 ///
 pobre_porc foc_jec ssbb_luz ssbb_agua ssbb_desague ///
 ssbb_completos  vraem_rm093  frontera_rm093 huallaga ///
 total_alumnos total_secciones total_docentes turno_m ugel_alta ///
 tiempo_dre_ugel
 
bys tipo_escuela: eststo: quietly estpost summarize $determinantes, listwise

esttab using "$root\EIB\output\tabla_sum.csv", cells("mean(fmt(3))") label nodepvar replace
