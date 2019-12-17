clear
set more off

cd "C:\Users\analistaup2\Google Drive\Trabajo\MINEDU_trabajo\UPP\Actividades\Focalizacion\Codigos\Endes y juntos_PSM_DD"

*Los datos deben estar ordenados de manera aleatoria:
set seed 0.111 /*orden aleatorio, pero siempre saldrÂ´ igual*/
gen random=uniform()
sort random

/*************************************************
*Datos
**************************************************
Los datos provienen de ENDES 2013
La informaciÂ´n estÂ´ restringida a hogares ubicados en los distritos en los dos primeros quintiles de pobreza
*/

**************************************************
*Variable de interÂ´s
**************************************************

hist zhfa /*z-scorde de talla*/

preserve
collapse zhfa, by(age_months)
scatter zhfa age_months
restore

global outcome  "zhfa"

**************************************************
*Determinantes de la probabilidad de participar en JUNTOS
**************************************************

summ sv hq cd hhsize pob_mon sev_pob des_cron prom_nbi porc_cp
global controls "sv hq cd hhsize pob_mon sev_pob des_cron prom_nbi porc_cp"

**************************************************
*Resultado: Impacto de JUNTOS sobre talla-por-edad (ENDES 2013)
**************************************************
psmatch2 juntos $controls, common outcome($outcome) neighbor(1) 

sort _id
cap drop parps
gen parps = _pscore[_n1] /* grabamos el pscore de los no tratados emparejados al lado de la de los tratados */ 
 
*Diferencias en el pscore de tratados y no tratados
kdensity _pdif

*Balanceo de variables control
pstest $controls, support(_support)

*Distribucion de pscore entre tratados y no tratados antes de emparejar
twoway (hist _pscore if _treated==1 & _support==1, start(0) width(0.04) bfcolor(none)) (hist _pscore  if _treated==0 & _support==1, start(0) width(0.04) bfcolor(none) blcolor(navy) legend(label(1 "Juntos") label(2 "No Juntos")) xtitle(Propiensión a Participar) ytitle(Densidad Estimada)) /* Viendo la distribución de los tratados vs los no tratados */
*Distribucion de pscore entre tratados y no tratados después de emparejar
twoway (hist _pscore if _treated==1 & _nn==1 & _support==1, start(0) width(0.04) bfcolor(none)) (hist parps if _nn==1 & _support==1, start(0) width(0.04) bfcolor(none) blcolor(navy) legend(label(1 "Juntos") label(2 "No Juntos")) xtitle(Propiensión a Participar) ytitle(Densidad Estimada)) /* Viendo la distribución del _pscore de las observaciones emparejadas */

***Bootstrapping
bootstrap r(att), reps(200): psmatch2 juntos $controls, common outcome($outcome) neighbor(1) 

***Otras variantes
***Hasta 3 vecinos cercanos...
psmatch2 juntos $controls, common outcome($outcome) neighbor(3) 
***En un radio de 0.05...
psmatch2 juntos $controls, common outcome($outcome) radius caliper(0.05)

**************************************************
*Resultado: Impacto de JUNTOS sobre talla-por-edad CON DOBLE DIFERENCIA (ENDES 2013)
**************************************************
*** Explotando información de las cartillas de crecimiento y desarrollo (CRED)
*** Estas cartillas registran la talla de un mismo niño múltiples veces en el tiempo (a los 3, 6, 9...36 meses...)

*** Línea de base antes de los 6 meses (poca o nula exposición a Juntos entre los tratados)
keep if c_age_monthsc3<6
*** Follow-up después de los 18 meses (todos los tratados ya fueron expuestos)
keep if c_age_monthsc13>18

gen dif_haz=c_zhfac13-c_zhfac3
tab dif_haz

global outcome2 "dif_haz"
psmatch2 juntos $controls, common outcome($outcome2) neighbor(1) 


