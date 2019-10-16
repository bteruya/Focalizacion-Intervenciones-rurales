*************************************************
*Project:		Dataprep 						*
*Institution:	MINEDU             				*
*Author:		Brenda Teruya					*
*Last edited:	2019-010-15          			*
*************************************************
global minedu D:\Brenda GoogleDrive\Trabajo\MINEDU_trabajo
global ue $minedu\UE\Proyecciones\3. Data\4. Student level

glo dd "$minedu\UPP\Actividades\Focalizacion"
set excelxlsxlargefile on
cd "$dd\datos"

*Preparar bd siagie y Base Pura Integrada

use "BasePuraIntegrada.dta", clear

merge 1:m cod_mod anexo using "$ue\2017", gen(merge_siagie_bp)

label var merge_siagie_bp "Proviene de Base Pura Integrada o Siagie"
label def merge_siagie_bp 1 "Solo Base Pura Integrada" 2 "Solo Siagie" ///
	3 "Base Pura Integrada y Siagie"
label val merge_siagie_b merge_siagie_bp
codebook merge_siagie_bp
