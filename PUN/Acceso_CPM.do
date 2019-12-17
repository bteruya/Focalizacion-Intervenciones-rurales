*************************************************
*Project:		Plazas no seleccionadas en concurso de acceso a carrera pública magisterial  					*
*Institution:	MINEDU             				*
*Author:		Brenda Teruya					*
*Last edited:	2019-11-26          			*
*Input: Base pura integrada, concurso docente 2015
* PER_adm1
*************************************************
*=========*
*#0. SETUP*
*=========*

glo dd "C:\Users\analistaup2\Google Drive\Trabajo\MINEDU_trabajo\UPP\Actividades\Focalizacion"
set excelxlsxlargefile on
cd "$dd\datos"

global gis C:\Users\analistaup2\Google Drive\Trabajo\MINEDU_trabajo\UPP\Actividades\Focalizacion\Datos\GIS


/*
INDICE:
#1. PREP AUX DATA
	#1.1. Preparar todo para merge de plazas ofertadas y plazas seleccionadas
	#1.2. Hacer el merge
#2. Preparar mapa
	##
*/

*=================*
*#1. PREP AUX DATA*
*=================*

*****************************************
*#1.1. Preparar todo para merge de plazas ofertadas y plazas seleccionadas			*
*****************************************
*Nota: los docentes postulan no al codigo de plaza si no a la lista de plaza.
*la diferencia radica en que postulan a matematica de colegio A pero no a la plaza 1 de matemática del colegio A
* En ese sentido todo deberá a estar a nivel de listas plazas

*Abrir plazas ofertadas

use "Evaluación docente\1. INGRESO\dta\Base_plazas_Nombramiento_2015.dta", clear

isid cod_plaza cod_mod

duplicates report codgrupo cod_mod
*Hay hasta 12 duplicados de plazas en el mismo codmod y mismo grupo

gen n_plaza = 1

collapse (count) n_plaza ,by(cod_mod codgrupo)

tempfile plaza
save `plaza'

use "Evaluación docente\1. INGRESO\dta\Evaluados_etapa_descentralizada_Nombramiento_2015.dta", clear

isid documento codigo_modular
*esta base de datos dice por cada docente, cuantos coles postuló

gen n_docente = 1
rename codigo_modular cod_mod

merge m:1 documento using "Evaluación docente\1. INGRESO\dta\Base_Nominal_Evaluados_PUN_Nombramiento_2015", keepusing(puntaje_total)

drop if _m == 2 // quitamos a los que no pasaron a la siguiente etapa

collapse (count) n_docente (mean) puntaje_total ,by(cod_mod codgrupo)

merge 1:1 cod_mod codgrupo using `plaza'

/*
Result	#	of	obs.
			
not matched			8,328
from master			0	(_merge==1)
from using			8,328	(_merge==2)

matched			8,416	(_merge==3)
			
*/		
recode _m (1 = .) (2 = 1 "plaza no seleccionada") (3 = 0 "Plaza seleccionada"), gen(no_selec)
gen selec = no_selec == 0

label var no_selec "lista plaza no seleccionada"
label var selec "lista plaza seleccionada"

drop _m

*Hay 8328 plazas no seleccionadas
destring cod_mod , replace


preserve

use BasePuraIntegrada, clear

keep if anexo == 0
*en las bases de codigo modular, las plazas van al codigo y luego se reparten. no interesa en anexo

tempfile bpi_anexo
save `bpi_anexo'

restore

merge m:1 cod_mod using `bpi_anexo', keepusing(d_dpto codgeo)
/*
 Result                           # of obs.
    -----------------------------------------
    not matched                       153,852
        from master                         0  (_merge==1)
        from using                    153,852  (_merge==2)

    matched                            16,744  (_merge==3)
16,744 IIEE tienen plazas ofertadas
*/
drop if _m == 2

gen dpto_cod=substr(codgeo, 1, 2)
collapse (sum) selec no_selec (mean) puntaje_total, by(d_dpto dpto_cod)
rename dpto_cod CC_1

gen r_noselec = 100 * no_selec / (no_selec + selec )

save "Data sets Intermedios\no_selec_dpto.dta" , replace

shp2dta using "$gis\PER_adm\PER_adm1.shp", data("Data sets Intermedios\reg-attr.dta") coord("Data sets Intermedios\reg-coord.dta") ///
 genid(stid) gencentroids(cc) replace
 
use "Data sets Intermedios\reg-attr.dta", clear
spmap using "Data sets Intermedios\reg-coord.dta", id(stid) ocolor(black) osize(vthin)
merge 1:1 CC_1 using "Data sets Intermedios\no_selec_dpto.dta"

format r_noselec puntaje_total %9.0f

tempfile temp1
save `temp1'
preserve

use  `temp1', clear
gen labtype = 1
append using  `temp1'
replace labtype = 2 if labtype == .
replace d_dpto = string(r_noselec, "%2.0f")  if labtype == 2
gen lab_pun = d_dpto 
replace lab_pun = string(puntaje_total, "%2.0f")  if labtype == 2
keep x_cc y_cc d_dpto labtype lab_pun
save "Data sets Intermedios\spmaplabels.dta" ,replace

restore
destring CC_1, gen( dpto)
spmap r_noselec using "Data sets Intermedios\reg-coord.dta", id(dpto) fcolor(BuRd) ///
 ocolor(white ..) osize(thin ..) legend(position(2)) ///
 legtitle("Listas plazas no seleccionadas %") ///
 title("Distribución de listas plazas no seleccionadas" ///
	"según Departamento, 2015", size(small)) ///
 caption("Nota: Una lista plaza no seleccionada es aquella que no tuvo candidatos." ///
	"Por ejemplo, matemáticas en la escuela A queda desierta en la primera etapa." ///
	, size(vsmall) position(7)) ///
	 label(data("Data sets Intermedios\spmaplabels") xcoord(x_cc)  ycoord(y_cc) ///
  label(d_dpto) by(labtype) size(*0.5 ..) pos(12 0) )

graph export "Output\plazanoselec.emf", as(emf) replace
graph export "Output\plazanoselec.pdf", as(pdf) replace



spmap puntaje_total using "Data sets Intermedios\reg-coord.dta", id(dpto) fcolor(RdBu) ///
 ocolor(white ..) osize(thin ..) legend(position(2)) ///
 legtitle("Puntaje total en la PUN") ///
 title("Distribución de PUN de los que pasaron a la etapa descentralizada" ///
	"según Departamento, 2015", size(small)) ///
 caption("" ///
	"" ///
	, size(vsmall) position(7)) ///
	 label(data("Data sets Intermedios\spmaplabels") xcoord(x_cc)  ycoord(y_cc) ///
  label(lab_pun) by(labtype) size(*0.5 ..) pos(12 0) )

graph export "Output\PUN_dpto.emf", as(emf) replace
graph export "Output\PUN_dpto.pdf", as(pdf) replace


