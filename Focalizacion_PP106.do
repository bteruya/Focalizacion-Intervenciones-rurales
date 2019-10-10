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
	#1.1. Focalizacion PP106 2020	
	#1.2. Base pura
#2. CRITERIOS FOCALIZACION
*/


*=================*
*#1. PREP AUX DATA*
*=================*

*****************************************
*#1.1. Importar Censo Educativo 2018 y 2019*
*****************************************

import dbase using "Censo Educativo\2019\Matricula_01.DBF", clear
tempfile censo19_matri
save `censo19_matri'

import dbase using "Censo Educativo\2019\Matricula_03.DBF", clear
tempfile censo19_matri03
save `censo19_matri03'

import dbase using "Censo Educativo\2018\Matricula_01.DBF", clear
tempfile censo18_matri
save `censo18_matri'

*****************************************
*#1.1. Padrón web	y Base pura			*
*****************************************

import dbase using "Censo Educativo\Padron_web_20190925\Padron_web.dbf", clear
tempfile padron
save `padron'

use "BasePuraIntegrada.dta", clear
tempfile bpura
save `bpura'

*****************************************
*#1.2. Preparar bases de datos			*
*****************************************

use `censo19_matri', clear
keep if TIPOREG == "1" & NROCED == "8AI" & CUADRO == "C205"
duplicates drop COD_MOD ANEXO, force
count
keep COD_MOD ANEXO
gen servicio = "PRITE"
gen year = 2019
tempfile codmod_prite

save `codmod_prite'

use `censo18_matri', clear
keep if TIPOREG == "1" & NROCED == "8AI" & CUADRO == "C205"
duplicates drop COD_MOD ANEXO, force
count
keep COD_MOD ANEXO
gen servicio = "PRITE"
gen year = 2018
tempfile codmod_prite18
save `codmod_prite18'


use `censo19_matri', clear
keep if TIPOREG == "1" & NROCED == "8AI" & CUADRO == "C201"
duplicates drop COD_MOD ANEXO, force
count
keep COD_MOD ANEXO
gen servicio = "CEBE-Inicial"

tempfile codmod_cebei
save `codmod_cebei'

use `censo19_matri', clear
keep if TIPOREG == "1" & NROCED == "8AP" & CUADRO == "C201"
duplicates drop COD_MOD ANEXO, force
count
keep COD_MOD ANEXO
gen servicio = "CEBE-Primaria"

tempfile codmod_cebep
save `codmod_cebep'


*==========================*
*#1.3. BD DIGESE		   *
*==========================*


import excel "DIGESE\Nexus 2019.xlsx", sheet("NEXUS_09.11.2018") ///
cellrange(A1:AT6077) firstrow clear
isid CODMODCE CODPLAZA ESTPLAZA
keep if ESTPLAZA == "ACTIV"
tempfile digese
save `digese'

import excel "DIGESE\Email 04oct19\METAS DE CONTRATACIÓN PP 0106.xlsx", ///
sheet("SERVICIOS") firstrow clear cellrange(A2:O449)
tempfile metas_contrat
save `metas_contrat'


import excel "DIGESE\Email 04oct19\INCLUSIVAS ANTENDIDAS POR SAANEE.xlsx", sheet("SAANEE") cellrange(A4:M5163) firstrow clear
tempfile saanee
save `saanee'
*******************************************************************************

*==========================*
*#2. CRITERIOS FOCALIZACION*
*==========================*



*==========================*
*#2.1. PRITE			   *
*==========================*

/*
1 PEA por  PRITE 2018 
2 PEA por PRITE 2019
*/

use `codmod_prite' , clear
merge 1:1 COD_MOD ANEXO using  `codmod_prite18'
gen continuidad = _m == 3
label var continuidad "Codmod PRITE con continuidad"
label def continuidad 0 "Nuevo PRITE 2019" 1 "Continuidad PRITE"
label val continuidad continuidad 
codebook continuidad 
drop _m

merge 1:1 COD_MOD ANEXO using  `padron', keep(3)
isid CODLOCAL
keep CODLOCAL COD_MOD ANEXO D_GESTION GESTION ESTADO D_ESTADO continuidad D_DPTO

preserve

use `digese', clear
keep if SERVICIO == "PRITE"
destring CODMODCE, replace
gen dif = CODMODCE == G
tab dif //todos los codmod son iguales
tostring CODMODCE, gen(COD_MOD) format(%07.0f)
collapse (count) n_pea = dif ,by(COD_MOD)
label var n_pea "N. PEAS en PRITE de acuerdo con DIGESE"

tempfile prite_nexus
save `prite_nexus'

restore

merge 1:1 COD_MOD using  `prite_nexus'
gen n_pea_upp = (continuidad == 1) + 2*(continuidad == 0)
label var n_pea_upp "N. PEAS de acuerdo con UPP"
drop if GESTION == "3" //privada 1
drop _m
tabstat n_pea* , by(D_DPTO) stat(sum)

export excel using "Data sets Intermedios\Padron PEAS DIGESE.xls", ///
	sheet("PRITE") sheetreplace firstrow(varlabels)
	
*==========================*
*#2.2. CREBE 			   *
*==========================*
use `metas_contrat', clear

gen tot_crebe = strpos(NombredelCentroEducativo,"CREBE")
label var tot_crebe "IE CREBE"
label def tot_crebe 0 "No CREBE" 1 "Sí CREBE"
label val tot_crebe tot_crebe

keep if tot_crebe == 1
keep CódigoModular Anexo tot_crebe
rename CódigoModular COD_MOD 
tostring Anexo, gen(ANEXO)
merge 1:1 COD_MOD ANEXO using `padron'
*No hay CREBE en el padrón 
keep if _m == 1
keep COD_MOD ANEXO tot_crebe
destring COD_MOD, gen(cod_mod)
destring ANEXO, gen(anexo)
merge 1:1 cod_mod anexo using `bpura'
*No hay CREBE en base pura integrada 
keep if _m == 1
keep cod_mod anexo COD_MOD ANEXO tot_crebe

gen n_pea_upp = 1
label var n_pea_upp "N. PEAS de acuerdo con UPP"

export excel COD_MOD n_pea_upp tot_crebe using "Data sets Intermedios\Padron PEAS DIGESE.xls", ///
	sheet("CREBE") sheetreplace firstrow(varlabels)
	

	
*==========================*
*#2.3. CEBE 			   *
*==========================*
	
/*	

CEBE-SAANEE que atieneden estudiantes con sordera total de EBE inicial y EBR primaria	
1 PEA por CEBE focalizado, 4 a más estudiantes con sordera total

CEBE-SAANEE que atieneden estudiantes con sordera total de EBE avanzada y EBR secundaria	
1 PEA por CEBE focalizado 3 estudiantes con sordera total

Asignación a CEBE con mayor número de estudiantes en primaria (mayor a la media)	
1 PEA por CEBE focalizado

Estudiantes con matrícula en nivel inicial	
1 PEA cuando tiene 18 o más estudiantes

No cuenta con equipo SAANEE	
1 PEA por CEBE
1 más por se el único de la UGEL
1 más por tener brecha de atencion mayor a 90%

CEBE con núcleo de orquestando	
1 PEA por núcleo

01  PEA adicional a CEBE  que no cuenta con equipo SAANEE constituido y 
que a su vez sea el único dentro de la jurisdicción de la UGEL 

*/





