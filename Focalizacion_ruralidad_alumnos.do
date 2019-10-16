*************************************************
*Project:		Focalizacion ruralidad alumnos	*
*Institution:	MINEDU             				*
*Author:		Brenda Teruya					*
*Last edited:	2019-010-15          			*
*************************************************
global ue C:\Users\analistaup2\Google Drive\Trabajo\MINEDU_trabajo\UE\Proyecciones\3. Data\4. Student level

glo dd "C:\Users\analistaup2\Google Drive\Trabajo\MINEDU_trabajo\UPP\Actividades\Focalizacion"
set excelxlsxlargefile on
cd "$dd\datos"

*=========*
*#0. SETUP*
*=========*

import excel "DISER\DISER_Intervenciones MSE Secundaria Rural DISER_2020_041019.xlsx", ///
 sheet("MSE") cellrange(A3:AD195) firstrow clear
destring COD_MOD, gen(cod_mod)
destring ANEXO, gen(anexo)

tempfile diser_msr
save `diser_msr'

use padronweb25092019, clear
merge 1:1 cod_mod anexo using `diser_msr', keep(3) nogen
merge 1:1 cod_mod anexo using  "BasePuraIntegrada.dta", gen(base_pura) force

drop if base_pura == 2

merge 1:m cod_mod anexo using "$ue\2017"
