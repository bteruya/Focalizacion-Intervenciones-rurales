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

import dbase using "Censo Educativo\2019\Matricula_01.DBF", clear

tempfile censo19_matri
save `censo19_matri'


use `censo19_matri', clear

