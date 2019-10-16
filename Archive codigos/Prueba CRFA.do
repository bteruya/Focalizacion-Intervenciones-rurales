*prueba para ver si hay CRFA en SIAGIE

global data_ue C:\Users\analistaup2\Google Drive\Trabajo\MINEDU_trabajo\UE\Proyecciones\3. Data
global data_upp C:\Users\analistaup2\Google Drive\Trabajo\MINEDU_trabajo\UPP\Actividades\Focalizacion\Datos

use "$data_ue\4. Student level\2017.dta"

merge m:1 cod_mod anexo using "$data_upp\BasePuraIntegrada.dta"
