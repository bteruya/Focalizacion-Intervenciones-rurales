*************************************************
*Project:		Focalizacion  JEC					*
*Institution:	MINEDU             				*
*Author:		Brenda Teruya					*
*Last edited:	2019-09-23          			*
*************************************************

glo dd "C:\Users\analistaup2\Google Drive\Trabajo\MINEDU_trabajo\UPP\Actividades\Focalizacion"
set excelxlsxlargefile on
cd "$dd\datos"

use "BasePuraIntegrada.dta", clear

tabstat foc_jec , stat(sum) by(d_dpto)

	graph bar (sum) foc_jec , over(d_dpto) 	///
	bargap(5) graphregion(color(white)) title("Total de JEC por region", position(12))  ///
	caption("Fuente: Elaboración propria con datos Padron educativo", size(vsmall) position(7)) ///	
	note("", size(vsmall) position(7)) ///
	 ytitle("N. JEC") 
	graph export "Output\JEC_region.png", replace
	


