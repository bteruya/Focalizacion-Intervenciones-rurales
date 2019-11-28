*************************************************
*Project:		Dataprep 						*
*Institution:	MINEDU             				*
*Author:		Brenda Teruya					*
*Last edited:	2019-010-15          			*
*************************************************
*global minedu D:\Brenda GoogleDrive\Trabajo\MINEDU_trabajo

global minedu C:\Users\analistaup2\Google Drive\Trabajo\MINEDU_trabajo
global ue $minedu\UE\Proyecciones\3. Data\4. Student level

glo dd "$minedu\UPP\Actividades\Focalizacion"
set excelxlsxlargefile on
cd "$dd\datos"

*Preparar bd siagie y Base Pura Integrada
/*
use "BasePuraIntegrada.dta", clear

merge 1:m cod_mod anexo using "$ue\2017", gen(merge_siagie_bp)

label var merge_siagie_bp "Proviene de Base Pura Integrada o Siagie"
label def merge_siagie_bp 1 "Solo Base Pura Integrada" 2 "Solo Siagie" ///
	3 "Base Pura Integrada y Siagie"
label val merge_siagie_b merge_siagie_bp
codebook merge_siagie_bp


*save "Data sets Intermedios\MergeSiagieBPIntregada.dta" , replace
*/


import excel "DISER\DISER_Intervenciones MSE Secundaria Rural DISER_2020_041019.xlsx", ///
 sheet("MSE") cellrange(A3:AD195) firstrow clear
destring COD_MOD, gen(cod_mod)
destring ANEXO, gen(anexo)

keep TippoMSE cod_mod anexo NOMBRE_IE ÁREA d_gestion d_ges_dep CODGEO COD_UGEL DRE CEN_POB codccpp nlat_ie nlong_ie
tempfile diser_msr
save `diser_msr'

use padronweb25092019, clear
merge 1:1 cod_mod anexo using `diser_msr', keep(3) nogen
tempfile diser_web
save `diser_web'


use `diser_msr', clear

global determinantes  ruralidad_rm093 d_ges_dep_c19 d_gestion_c19 gestion ///
 d_gestion pobre_porc foc_jec ssbb_luz ssbb_agua ssbb_desague ///
 ssbb_completos vraem_rm093  frontera_rm093 huallaga region_nat_c19 ///
 total_alumnos total_secciones total_docentes cod_tur d_cod_tur tipo_ugel ///
 tiempo_dre_ugel

merge 1:1 cod_mod anexo using  "BasePuraIntegrada.dta", gen(base_pura) ///
 keepusing($determinantes)
*export delimited using "Data sets Intermedios\diser_iiee.csv", replace

tempfile diser_bp
save `diser_bp'

/*
merge 1:m cod_mod anexo using "$ue\2017", keep(1 3)


tempfile diser_siagie
save `diser_siagie'
*/
use `diser_bp', clear
encode TippoMSE, gen(tipo_mse)

mdesc $determinantes

replace tipo_mse = 0 if ruralidad_rm093 != "" & missing(tipo_mse)
replace tipo_mse = 4 if ruralidad_rm093 == "" & missing(tipo_mse)

label def tipo_mse 0 "Rural no MSE" 4 "Urbano no MSE", modify

codebook tipo_mse

gen rural_1=inlist(ruralidad_rm093, "Rural 1")

tab gestion, gen(gestion_)

local vars_num foc_jec ssbb_luz ssbb_agua ssbb_desague ssbb_completos  vraem_rm093  frontera_rm093 huallaga

mvencode `vars_num', override mv(0)

gen turno_m=inlist(d_cod_tur, "Manana")
gen ugel_alta=inlist(tipo_ugel, "Tipo GH", "Tipo I") if !missing(tipo_ugel)

la var rural_1 "Gradiente de ruralidad 1" 
la var gestion_1 "Publica de gestion directa"
la var gestion_2 "Publica de gestion privada"
la var gestion_3 "Privada"
la var turno_m "Turno manana"
la var ugel_alta "UGEL Desafio Territorial Alto" 

replace pobre_porc = pobre_porc / 100

 global determinantes rural_1 gestion_1 ///
 pobre_porc foc_jec ssbb_luz ssbb_agua ssbb_desague ///
 ssbb_completos  vraem_rm093  frontera_rm093 huallaga ///
 total_alumnos total_secciones total_docentes turno_m ugel_alta ///
 tiempo_dre_ugel
estimates drop _all 
bys tipo_mse: eststo: quietly estpost summarize $determinantes, listwise
esttab using "Data sets Intermedios\tabla_sum_mse.csv", cells("mean(fmt(3))") label nodepvar replace




********************************************************************************
*****************************************************************************


