*************************************************
*Project:		Focalizacion SRE (residencias) 	*
*Institution:	MINEDU             				*
*Author:		Brenda Teruya					*
*Last edited:	2019-09-23          			*
*************************************************

*=========*
*#0. SETUP*
*=========*
holahoal
glo dd "D:\Brenda\Focalizacion"
set excelxlsxlargefile on
cd "$dd\datos"


/*
INDICE:
#1. PREP AUX DATA
	#1.1. Focalizacion CRFA 2020
#2. CRITERIOS FOCALIZACION
#3. CRUCE CON FOC. DISER
#4. PRIORIZACION
#5. RANKING
#6. Propuesta UPP
	##6.1 Focalizacion UPP
	##6.2 Priorizacion UPP
	##6.3 Ranking UPP
*/

*=================*
*#1. PREP AUX DATA*
*=================*

*****************************************
*#1.1. Focalizacion CRFA 2020			*
*****************************************

import excel "DISER\MSE Padrones 2020_20092019.xlsx",  sheet("SA 78") cellrange(A1:K79) firstrow clear
destring CódigomodulardeCRFA , gen(cod_mod)
gen anexo = 0

tempfile crfa2020
save `crfa2020'


*******************************************************************************

*==========================*
*#2. CRITERIOS FOCALIZACION*
*==========================*

/*
CRITERIOS DE FOCALIZACION 2020 - DISER:
-IIEE Centros Rurales de Formación en Alternativa CRFA.
-IIEE CRFA que cuentan con matrícula en el SIAGIE.
-IIEE del nivel de ruralidad 1, 2 y 3, y urbanas que atiende a 
 estudiantes que provienen de comunidades rurales.
-IIEE CRFA ubicados en centros poblados categorizados en el quintil 1 y 2.
-IIEE CRFA ubicadas en zonas de frontera, VRAEM y Huallaga

*/

/*
CRITERIOS DE FOCALIZACION 2020 - OPERATIVIZADO:
1.	Nombre de la IE "CRFA"
2.	Matricula en Siagie > 0
3.	Rural o urbana (cualquiera)
4.	Quintil 1 y 2 de pobreza según CPV
5.	Zona de conflicto
*/

use "BasePuraIntegrada.dta", clear
keep if estado == "1" //activas
drop if gestion == "3" //gestion privada drop

*1.	Nombre de la IE "CRFA" 

*Nota: Este criterio no es preciso porque hay colegios de alternancia sin el 
*nombre CRFA, por ejm la IE "38869" en CUSCO/ LA CONVENCION/ VILLA KINTIARINA
*es un CRFA sin la palabra CRFA

gen tot_crfa = strpos(cen_edu,"CRFA")
label var tot_crfa "IE CRFA"
label def tot_crfa 0 "No CRFA" 1 "Sí CRFA"
label val tot_crfa tot_crfa


*2.	Matricula en Siagie > 0
mvencode talumno_siagie, mv(0) override
gen d_matri = talumno_siagie > 0 
label var d_matri "Dummy que indica si la matricula del SIAGIE  es positiva"
label def d_matri 0 "Cero" 1 "Positiva"
label val d_matri d_matri
tab tot_crfa d_matri

*3.	Rural o urbana (cualquiera)

*4.	Quintil 1 y 2 de pobreza según CPV
gen d_pob = quintiles_pobreza == 1 | quintiles_pobreza == 2
label var d_pob "Criterio de pobreza"
label def d_pob 0 "Quintil 3 4 5" 1 "Quintil 1 2 "
label val d_pob d_pob
tab d_pob tot_crfa if d_matri == 1

*5.	Zona de conflicto
mvencode vraem_rm093 huallaga frontera_rm093, mv(0) override  
gen zona = vraem_rm093 + 2*huallaga + 3*frontera_rm093
label var zona "Zona a la que pertenece la IE"
label def zona 0 "Sin conflicto" 1 "VRAEM" 2 "Huallaga" 3 "Frontera"
label val zona zona

gen d_zona = zona != 0
label var d_zona "Criterio de zona de conflicto"
label def d_zona 0 "Sin conflicto" 1 "VRAEM o Huallaga o frontera"
label val d_zona d_zona
tab d_zona tot_crfa if d_matri == 1 & d_pob == 1

*Cumple con todos los criterios, excluye el de nombre de la IE
egen crfa_focatot=rowmean(d_matri d_pob d_zona )

*******************************************************************************

*============================*
*#3. CRUCE CON FOC. DISER	 *
*============================*

merge m:1 cod_mod using  `crfa2020', gen(crfa_2020)
label def crfa_2020 1 "No CRFA" 3 "CRFA"
label val crfa_2020 crfa_2020


*================*
*#4. PRIORIZACION*
*================*

/*
1. IIEE CRFA que  se vienen implementando el modelo de servicio educativo Secundaria en Alternancia en el 2019.
2. IIEE CRFA que cuentan con mínimo de 25 estudiantes en el SIAGIE.
3. IIEE CRFA creadas y que la DRE/UGEL ha solicitado su incorporación.
4. IIEE CRFA que reciben el PNAE Qaliwarma.
*/

/*
CRITERIOS DE PRIORIZACION 2020 - OPERATIVIZADO:
1.	CRFA focalizado en 2019
2.	Matricula de Siagie >= 25
3.	DRE/UGEL solicitan su incorporacion (no tenemos datos de esto)
4.	Que tienen Qaliwarma 
*/

*1.	CRFA focalizado en 2019 (continuidad)
gen crfa_prio1=(foc_crfa == 1)
label var crfa_prio1 "CRFA focalizado en 2019"
label def crfa_prio1 0 "No continuidad" 1 "Continuidad"
label val crfa_prio1 crfa_prio1 

tab crfa_prio1 if crfa_2020 == 3

*2.	Matricula de Siagie > 25
gen d_matri25 = talumno_siagie >= 25
label var d_matri25 "Dummy que indica si la matricula del SIAGIE  es mínimo 25"
label def d_matri25 0 "menor a 25" 1 "mayor igual a 25"
label val d_matri25 d_matri25
tab crfa_prio1 d_matri25 if crfa_2020 == 3

*3. IIEE CRFA creadas y que la DRE/UGEL ha solicitado su incorporación.
*NO

*4.	Que tienen Qaliwarma 
gen d_qaliwarma = qali_warma == 1 //Aquí modificar para realizar el filtro
label var d_qaliwarma "IE con Qaliwarma"
label def d_qaliwarma 0 "No Qaliwarma" 1 "Sí Qaliwarma"
label val d_qaliwarma d_qaliwarma 

tab crfa_prio1 d_qaliwarma if crfa_2020 == 3 & d_matri25 == 1


*================*
*#5. RANKING	 *
*================*

*Para el ranking veremos si está focalizado
gen diser_crfa = crfa_2020 == 3
label var diser_crfa "CRFA focalizado 2020"
label def diser_crfa 0 "No focalizado" 1 "CRFA 2020"
label val diser_crfa diser_crfa

egen crfa_priotot = rowmean(crfa_prio1 d_matri25 d_qaliwarma crfa_focatot diser_crfa) if tot_crfa == 1

gsort -crfa_priotot -diser_crfa -tot_crfa 
*ranking según promedio de criterios de priorizacion y que sea un crfa de diser
gen crfa_rank = _n 


br crfa_rank crfa_prio1 d_matri25 d_qaliwarma crfa_focatot diser_crfa d_matri d_pob d_zona tot_crfa 
*=================*
*6. PROPUESTA UPP *
*=================*
*6.1 Focalizacion UPP
*Trabajamos en el universo de focalizadas y no focalizadas
tab tot_crfa crfa_2020
replace tot_crfa = 1 if crfa_2020 == 3 & tot_crfa == 0 // anadiendo cen edu: 38869
*cod_mod 1405141
tab tot_crfa crfa_2020


* IIEE Centros Rurales de Formación en Alternativa CRFA. 
*(Solo focalizados por DISER)
tab diser_crfa tot_crfa //88

*2.	Matricula en Siagie > 0
tab d_matri tot_crfa //-1

*3.	Rural o urbana (cualquiera)

*6.2 Priorizacion UPP
/*
CRITERIOS DE PRIORIZACION 2020 - OPERATIVIZADO:
1.	CRFA focalizado en 2019
2.	Matricula de Siagie >= 25
3.	Que tienen Qaliwarma 
4.	Quintil 1 y 2 de pobreza según CPV
5. 	Zona de conflicto
*/

*1.	CRFA focalizado en 2019
tab crfa_prio1 if tot_crfa == 1

*2.	Matricula de Siagie >= 25
tab  d_matri25 if crfa_prio1 == 1 & tot_crfa == 1

*3. Que tienen Qaliwarma 
tab  d_qaliwarma if crfa_prio1 == 1 & d_matri25 == 1 & tot_crfa == 1

*4.	Quintil 1 y 2 de pobreza según CPV
tab d_pob  if crfa_prio1 == 1 & d_matri25 == 1 & d_qaliwarma == 1 & tot_crfa == 1


*5. 	Zona de conflicto
tab d_zona if crfa_prio1 == 1 & d_matri25 == 1 & d_qaliwarma == 1 & d_pob == 1 & tot_crfa == 1


egen crfa_prio_upp = rowmean(crfa_prio1 d_matri25 d_qaliwarma d_pob ) if tot_crfa == 1

gsort -crfa_prio_upp -d_matri -d_matri25 -d_qaliwarma -d_pob -d_zona

gen rank_upp = _n if tot_crfa == 1

br rank_upp crfa_rank diser_crfa crfa_prio1 d_matri25 d_qaliwarma  d_pob d_zona tot_crfa 




*===============================END OF PROGRAM===============================*

