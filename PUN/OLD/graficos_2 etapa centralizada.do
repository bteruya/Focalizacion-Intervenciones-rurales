*global rutaD:\Brenda GoogleDrive\Trabajo\Trabajo BID\BRENDA-documentos\OneDrive\Trabajo BID-onedrive\docentes\simulaciones\Calculos\Dofiles\BID -dofiles*
*	do "$ruta\rutas_mat.do"

global directory_b D:\Brenda GoogleDrive\Trabajo\Trabajo BID\BRENDA-documentos\OneDrive\Trabajo BID-onedrive\docentes\simulaciones\Calculos



	cd "$directory_b"
global esw D:\Brenda GoogleDrive\Trabajo\Trabajo BID\BRENDA-documentos\OneDrive\Trabajo BID-onedrive\ESW
global directory_e D:\Brenda GoogleDrive\Trabajo\Trabajo BID\BRENDA-documentos\OneDriveShared\Bertoni, Eleonora - Peru School Finance
global insumo_e $directory_e\Estudio Viabilidad Salarial\BID\2_Contratación\Insumos
global concurso "$insumo_e\Concurso Nombramiento"
global concurso15 "$concurso\DIED\2015"
global concurso17 "$concurso\DIED\2017"
global output "$esw\calculos\graficos\output plazas"
	global data $directory_e\data	



import excel "$esw\calculos\graficos\Tablas.xlsx", sheet("Hoja2") firstrow clear
tostring dpto, format(%02.0f) replace
tempfile dpto
save `dpto'

	use "$concurso15\1a_Evaluados_etapa_nacional_2015.dta", clear
	merge m:1 region_evaluado using `dpto', nogen //anadir dpto a la bd de PUN
	merge m:1 dpto using "$data\1_UGEL- UE Level\regiones_dominio" //Lima Metropolitana es a parte
	replace dominio_dpt=8 if dpto=="26" //Lima metropolitana
	replace dominio_dpt=2 if dpto=="15" //Lima provincias
	drop _m
	
	*EN CUAL DE LAS TRES SUBPRUEBAS SE VE MENOR DESEMPEÑO Y MAYOR VARIABILIDAD
encode sexo, gen(sexo1)
gen edad_36=edad>36	
label var edad_36 "Mayor de 36 años"
label define yesno 1 "yes" 0 "no"
label val edad_36 yesno
gen exp_tot=exp_publica+exp_privada	
label var exp_tot "Experiencia total"
gen exp_6=exp_tot>6
label var exp_6 "Experiencia total mayor de 6 años"	
label val exp_6 yesno
	
encode procedencia, gen(instituto)	
label def ins 1 "Ambos" 2 "Solo INS" 3 "Solo UNIV" 
	
recode exp_tot (0/1=1 "1 año") (2/3=2 "2 o 3 años") (4/.=3 "4 a más"), gen(exp_3)
	
gen solo_inst= instituto
replace solo_inst=. if instituto==1
label val solo_ins ins	

egen punct_s=std(puntaje_sp1_ct)
egen punrl_s=std(puntaje_sp2_rl)
egen puncc_s=std(puntaje_sp3_cc)

preserve

	use "$data\4_Staff Level\5_Plazas Postuladas y Ofertadas\2015_innominada_vf3.dta", clear
	collapse (first) gestion_univ ,by(nombre_universidad)
	rename nombre_universidad nombre_univ
	tempfile univ
	save `univ'

	use "$data\4_Staff Level\5_Plazas Postuladas y Ofertadas\2015_innominada_vf3.dta", clear
	collapse (first) gestion_ins ,by(nombre_instituto)
	rename nombre_instituto nombre_ins
	tempfile ins
	save `ins'
	
	
restore


merge m:1 nombre_univ using `univ'
gen gestion_otro=_m==1 //son univ extranjeras y un seminario
drop _m
merge m:1 nombre_ins using `ins'
*el using que falta es de mexico, lo boto
drop if _m==2
replace gestion_otro=1 if _m==1

encode procedencia, gen(proced_num)
encode gestion_univ, gen(guniv_num)
encode gestion_ins, gen(gins_num)



gen g_univ3=.
replace g_univ3=1 if proced_num==3 & guniv_num==2
replace g_univ3=2 if proced_num==3 & guniv_num==1
replace g_univ3=3 if proced_num==2 & gins_num==2
replace g_univ3=4 if proced_num==2 & gins_num==1
label def g_univ3 1 "Univ publica" 2 "Univ privada" 3 "Instituto publico" 4 "Instituto privado"
label val g_univ3 g_univ3

gen uno=1

		/************************************************************************
					SUB PRUEBAS DE LA PUN
		************************************************************************/
		

sum puntaje_sp1_ct
local m0 = r(mean) 
local SD0 = r(sd) 
su puntaje_sp2_rl
local m1 = r(mean) 
local SD1 = r(sd) 
su puntaje_sp3_cc
local m2 = r(mean) 	
local SD2 = r(sd) 

twoway function normalden(x, `m0', `SD0'), ra(puntaje_sp1_ct) lp(solid)  || /// 
function normalden(x, `m1', `SD1'), ra(puntaje_sp2_rl) lp(dash)  lwidth(thick) || ///
function normalden(x, `m2', `SD2'), ra(puntaje_sp3_cc) lp( shortdash_dot)  lwidth(thick)  ///
legend(order(1 "Comprensión Textos" 2 "Razonamiento Lógico" 3 "Conocimientos Pedagógicos")) ytitle(Densidad) xtitle("Puntaje") ///
, title("Distribución de Puntajes Epata Centralizada", position(12) size(medlarge)) 	///	
	graphregion(color(white))	///
	caption("Fuente: Concurso de Nombramiento 2015" ///
	"Nota: Para aprobar el examen hay que sacar al menos 30, 30, 60 en CT, RL y CP" ///
	"donde el máximo es 50, 50 y 100 respectivamente", size(small) position(7)) 

	graph export "$output\3PUN.png", replace
	
	
	
	putexcel set "$esw\calculos\graficos\subpruebasPUN.xlsx", sheet("PUN_subprueba") modify
	putexcel A1="Distribución de las subpruebas de la PUN"
	local i 2
	putexcel A`i'="Estadística"
	putexcel A3="Min"
	putexcel A4="p1"
	putexcel A5="p25"
	putexcel A6="p50"
	putexcel A7="mean"
	putexcel A8="p75"
	putexcel A9="p95"
	putexcel A10="p99"
	putexcel A11="máx"
	putexcel A12="desviación estándar"
	putexcel A13="Obs"
	
	sum puntaje_sp1_ct, d  
	putexcel B2="Comprensión Textos" 
	putexcel B3=`r(min)'
	putexcel B4=`r(p1)'
	putexcel B5=`r(p25)'
	putexcel B6=`r(p50)'
	putexcel B7=`r(mean)'
	putexcel B8=`r(p75)'
	putexcel B9=`r(p95)'
	putexcel B10=`r(p99)'
	putexcel B11=`r(max)'
	putexcel B12=`r(sd)'
	putexcel B13=`r(N)'

	sum puntaje_sp2_rl, d  
	local a C
	putexcel `a'2="Razonamiento Lógico"
	putexcel `a'3=`r(min)'
	putexcel `a'4=`r(p1)'
	putexcel `a'5=`r(p25)'
	putexcel `a'6=`r(p50)'
	putexcel `a'7=`r(mean)'
	putexcel `a'8=`r(p75)'
	putexcel `a'9=`r(p95)'
	putexcel `a'10=`r(p99)'
	putexcel `a'11=`r(max)'
	putexcel `a'12=`r(sd)'
	putexcel `a'13=`r(N)'
	

	sum puntaje_sp3_cc, d  
	local a D
	putexcel `a'2="Conocimientos Pedagógicos"
	putexcel `a'3=`r(min)'
	putexcel `a'4=`r(p1)'
	putexcel `a'5=`r(p25)'
	putexcel `a'6=`r(p50)'
	putexcel `a'7=`r(mean)'
	putexcel `a'8=`r(p75)'
	putexcel `a'9=`r(p95)'
	putexcel `a'10=`r(p99)'
	putexcel `a'11=`r(max)'
	putexcel `a'12=`r(sd)'
	putexcel `a'13=`r(N)'


	*	sexo discapacidad edad exp_publica exp_pub_rangos ins univ region_evaluado
	
	*diferencias por sexo
	putexcel set "$esw\calculos\graficos\subpruebasPUN.xlsx", sheet("Sexo") replace
	putexcel A1="Diferencias entre hombres y mujeres en las tres subpruebas de la PUN"
	putexcel A2="Subprueba"
	putexcel B2="Mujer"
	putexcel C2="Hombre"
	putexcel D2="Diferencia (M-H)"
	putexcel E2="Desv. Est."
	putexcel F2="Significancia"
	
	
		estpost ttest puntaje_sp1_ct , by(sexo)
		
		local i 3
		putexcel A`i'="Comprensión Textos"
		putexcel B`i'=matrix(e(mu_1))
		putexcel C`i'=matrix(e(mu_2))
		putexcel D`i'=matrix(e(b))
		putexcel E`i'=matrix(e(se))
		putexcel F`i'="***"
		
	
		estpost ttest puntaje_sp2_rl , by(sexo)
		
		local i 4
		putexcel A`i'="Razonamiento Lógico"
		putexcel B`i'=matrix(e(mu_1))
		putexcel C`i'=matrix(e(mu_2))
		putexcel D`i'=matrix(e(b))
		putexcel E`i'=matrix(e(se))
		putexcel F`i'="***"
		
		
		
		estpost ttest puntaje_sp3_cc , by(sexo)
		
		local i 5
		putexcel A`i'="Conocimientos Pedagógicos"
		putexcel B`i'=matrix(e(mu_1))
		putexcel C`i'=matrix(e(mu_2))
		putexcel D`i'=matrix(e(b))
		putexcel E`i'=matrix(e(se))
		putexcel F`i'="***"
		putexcel F`i'="***"
		
		putexcel A6= "Observaciones"
		putexcel B6=matrix(e(N_1))
		putexcel C6=matrix(e(N_2))
		
		
	*diferencias por edad
	
	putexcel set "$esw\calculos\graficos\subpruebasPUN.xlsx", sheet("Edad") modify
	putexcel A1="Diferencias entre menores y mayores de 36 años en las tres subpruebas de la PUN"
	putexcel A2="Subprueba"
	putexcel B2="Menor igual a 36"
	putexcel C2="Mayor a 36"
	putexcel D2="Diferencia -/+"
	putexcel E2="Desv. Est."
	putexcel F2="Significancia"
	
	
		estpost ttest puntaje_sp1_ct , by(edad_36)
		
		local i 3
		putexcel A`i'="Comprensión Textos"
		putexcel B`i'=matrix(e(mu_1))
		putexcel C`i'=matrix(e(mu_2))
		putexcel D`i'=matrix(e(b))
		putexcel E`i'=matrix(e(se))
		putexcel F`i'="***"
		
	
		estpost ttest puntaje_sp2_rl , by(edad_36)
		
		local i 4
		putexcel A`i'="Razonamiento Lógico"
		putexcel B`i'=matrix(e(mu_1))
		putexcel C`i'=matrix(e(mu_2))
		putexcel D`i'=matrix(e(b))
		putexcel E`i'=matrix(e(se))
		putexcel F`i'="***"
		
		
		
		estpost ttest puntaje_sp3_cc , by(edad_36)
		
		local i 5
		putexcel A`i'="Conocimientos Pedagógicos"
		putexcel B`i'=matrix(e(mu_1))
		putexcel C`i'=matrix(e(mu_2))
		putexcel D`i'=matrix(e(b))
		putexcel E`i'=matrix(e(se))
		putexcel F`i'="***"
		putexcel F`i'="***"
		
		putexcel A6= "Observaciones"
		putexcel B6=matrix(e(N_1))
		putexcel C6=matrix(e(N_2))
		
	*diferencias por experiencia	
	putexcel set "$esw\calculos\graficos\subpruebasPUN.xlsx", sheet("Experiencia") modify
	putexcel A1="Diferencias en subpruebas de la PUN entre personas de menos y más de 6 años de experiencia"
	putexcel A2="Subprueba"
	putexcel B2="Exp menor igual a 6"
	putexcel C2="Exp mayor a 6"
	putexcel D2="Diferencia -/+"
	putexcel E2="Desv. Est."
	putexcel F2="Significancia"
	
	
		estpost ttest puntaje_sp1_ct , by(exp_6)
		
		local i 3
		putexcel A`i'="Comprensión Textos"
		putexcel B`i'=matrix(e(mu_1))
		putexcel C`i'=matrix(e(mu_2))
		putexcel D`i'=matrix(e(b))
		putexcel E`i'=matrix(e(se))
		putexcel F`i'="***"
		
	
		estpost ttest puntaje_sp2_rl , by(exp_6)
		
		local i 4
		putexcel A`i'="Razonamiento Lógico"
		putexcel B`i'=matrix(e(mu_1))
		putexcel C`i'=matrix(e(mu_2))
		putexcel D`i'=matrix(e(b))
		putexcel E`i'=matrix(e(se))
		putexcel F`i'="***"
		
		
		
		estpost ttest puntaje_sp3_cc , by(exp_6)
		
		local i 5
		putexcel A`i'="Conocimientos Pedagógicos"
		putexcel B`i'=matrix(e(mu_1))
		putexcel C`i'=matrix(e(mu_2))
		putexcel D`i'=matrix(e(b))
		putexcel E`i'=matrix(e(se))
		putexcel F`i'="***"
		putexcel F`i'="***"
		
		putexcel A6= "Observaciones"
		putexcel B6=matrix(e(N_1))
		putexcel C6=matrix(e(N_2))

	putexcel set "$esw\calculos\graficos\subpruebasPUN.xlsx", sheet("Experiencia") modify
	putexcel A8="Promedios en subpruebas de la PUN según experiencia"
	putexcel A9="Subprueba"
	putexcel B9="menos de 1 año"
	putexcel C9="2 a 3 años"
	putexcel D9="4 a más años"
	
		summ puntaje_sp1_ct if exp_3==1
		local i 10
		putexcel A`i'="Comprensión Textos"
		putexcel B`i'=`r(mean)'
		summ puntaje_sp1_ct if exp_3==2
		putexcel C`i'=`r(mean)'
		summ puntaje_sp1_ct if exp_3==3
		putexcel D`i'=`r(mean)'

		summ puntaje_sp2_rl if exp_3==1
		local i 11
		putexcel A`i'="Razonamiento lógico"
		putexcel B`i'=`r(mean)'
		summ puntaje_sp2_rl if exp_3==2
		putexcel C`i'=`r(mean)'
		summ puntaje_sp2_rl if exp_3==3
		putexcel D`i'=`r(mean)'
		
			summ puntaje_sp3_cc if exp_3==1
		local i 12
		putexcel A`i'="Comprensión de Textos"
		putexcel B`i'=`r(mean)'
		summ puntaje_sp3_cc if exp_3==2
		putexcel C`i'=`r(mean)'
		summ puntaje_sp3_cc if exp_3==3
		putexcel D`i'=`r(mean)'
	
		summ puntaje_sp3_cc if exp_3==1
		local i 13
		putexcel A`i'="Observaciones"
		putexcel B`i'=`r(N)'
		summ puntaje_sp3_cc if exp_3==2
		putexcel C`i'=`r(N)'
		summ puntaje_sp3_cc if exp_3==3
		putexcel D`i'=`r(N)'
	
		
		*comparación instituto universidad		
		
	 tabstat puntaje*, stat(mean) by(procedencia)	
estpost ttest puntaje_sp1_ct if instituto!=1, by(instituto)

	putexcel set "$esw\calculos\graficos\subpruebasPUN.xlsx", sheet("Instituto") modify
	putexcel A1="Diferencias en subpruebas de la PUN entre personas de universidades vs institutos"
	putexcel A2="Subprueba"
	putexcel B2="Instituto"
	putexcel C2="Universidad"
	putexcel D2="Diferencia (I-U)"
	putexcel E2="Desv. Est."
	putexcel F2="Significancia"
	
	
		estpost ttest puntaje_sp1_ct if instituto!=1, by(instituto)

		
		local i 3
		putexcel A`i'="Comprensión Textos"
		putexcel B`i'=matrix(e(mu_1))
		putexcel C`i'=matrix(e(mu_2))
		putexcel D`i'=matrix(e(b))
		putexcel E`i'=matrix(e(se))
		putexcel F`i'="***"
		
	
		estpost ttest puntaje_sp2_rl if instituto!=1, by(instituto)

			local i 4
		putexcel A`i'="Razonamiento Lógico"
		putexcel B`i'=matrix(e(mu_1))
		putexcel C`i'=matrix(e(mu_2))
		putexcel D`i'=matrix(e(b))
		putexcel E`i'=matrix(e(se))
		putexcel F`i'="***"
		
		
		
		estpost ttest puntaje_sp3_cc if instituto!=1, by(instituto)

		local i 5
		putexcel A`i'="Conocimientos Pedagógicos"
		putexcel B`i'=matrix(e(mu_1))
		putexcel C`i'=matrix(e(mu_2))
		putexcel D`i'=matrix(e(b))
		putexcel E`i'=matrix(e(se))
		putexcel F`i'="***"
		putexcel F`i'="***"
		
		putexcel A6= "Observaciones"
		putexcel B6=matrix(e(N_1))
		putexcel C6=matrix(e(N_2))

		*por regiones
		tabstat puntaje_sp1_ct puntaje_sp2_rl puntaje_sp3_cc , stat(mean) by( region_evaluado )
		*region seleccionado es de la segunda etapa
	
		
		
		
			
		/************************************************************************
					 PUN TOTAL
		************************************************************************/

encode situacion_pun , gen(paso)
replace paso=0 if paso==2
label val paso yesno
gen pun= puntaje_pun
gen exp_q= exp_tot^2
gen edad_q=edad^2

recode exp_tot (0/6=1) (7/16=2) (17/.=3), gen(exp_17)
label def exp17 1 "De 0 a 6 años" 2 "De 7 a 16 años" 3 "17 a más años"
label val exp_17 exp17

recode edad (0/27=1) (28/36=2) (37/.=3), gen(edad_27)
label def edad27 1 "Menor a 27 años" 2 "De 28 a 36 años" 3 "37 a más años"
label val edad_27 edad27
	
	twoway kdensity puntaje_pun ///
	,	ytitle(freq)  lwidth(thick)	///
	title("Distribución de Puntajes totales Epata Centralizada", position(12) size(medlarge)) 	///	
	graphregion(color(white))xline(120) ///
	caption("Fuente: Concurso de Nombramiento 2015" ///
	, size(small) position(7)) 
		
	putexcel set "$esw\calculos\graficos\subpruebasPUN.xlsx", sheet("PUN_tot") modify
	putexcel A1="Distribución de los puntajes de la PUN"
	local i 2
	putexcel A`i'="Estadística"
	putexcel A3="Min"
	putexcel A4="p1"
	putexcel A5="p25"
	putexcel A6="p50"
	putexcel A7="mean"
	putexcel A8="p75"
	putexcel A9="p95"
	putexcel A10="p99"
	putexcel A11="máx"
	putexcel A12="desviación estándar"
	putexcel A13="Obs"
	
	sum puntaje_pun, d  
	putexcel B2="Puntaje PUN"
	putexcel B3=`r(min)'
	putexcel B4=`r(p1)'
	putexcel B5=`r(p25)'
	putexcel B6=`r(p50)'
	putexcel B7=`r(mean)'
	putexcel B8=`r(p75)'
	putexcel B9=`r(p95)'
	putexcel B10=`r(p99)'
	putexcel B11=`r(max)'
	putexcel B12=`r(sd)'
	putexcel B13=`r(N)'
	
	twoway kdensity puntaje_pun if paso==0	, lwidth(thick) || kdensity puntaje_pun if paso==1 ,lp(dash) lwidth(thick) ///
	, legend(order(1 "No pasó PUN" 2 "Sí pasó PUN" )) title("Distribución de Puntajes totales Epata Centralizada" ///
	"distinguiendo aquellos que pasaron y no pasaron PUN") ///
	ytitle(freq) xline(120)	xtitle(Puntaje PUN) ///
		graphregion(color(white))	///
	caption("Fuente: Concurso de Nombramiento 2015" ///
	"Nota: Se aprueba la PUN con un mínimo de 120 de 200", size(small) position(7)) 

	table uno if paso==0, c(p86 puntaje_pun)
	
	putexcel set "$esw\calculos\graficos\subpruebasPUN.xlsx", sheet("PUN_tot") modify
	putexcel D1="Distribución de la PUN entre los que pasaron y no pasaron"
	local a D
	putexcel `a'2="Estadística"
	putexcel `a'3="Min"
	putexcel `a'4="p1"
	putexcel `a'5="p25"
	putexcel `a'6="p50"
	putexcel `a'7="mean"
	putexcel `a'8="p75"
	putexcel `a'9="p95"
	putexcel `a'10="p99"
	putexcel `a'11="max"
	putexcel `a'12="desviación estándar"
	putexcel `a'13="Obs"
	
	sum puntaje_pun if paso==0, d 
	local a E
	putexcel `a'2="PUN<120"
	putexcel `a'3=`r(min)'
	putexcel `a'4=`r(p1)'
	putexcel `a'5=`r(p25)'
	putexcel `a'6=`r(p50)'
	putexcel `a'7=`r(mean)'
	putexcel `a'8=`r(p75)'
	putexcel `a'9=`r(p95)'
	putexcel `a'10=`r(p99)'
	putexcel `a'11=`r(max)'
	putexcel `a'12=`r(sd)'
	putexcel `a'13=`r(N)'
	
	sum puntaje_pun if paso==1, d 
	local a F
	putexcel `a'2="PUN>120"
	putexcel `a'3=`r(min)'
	putexcel `a'4=`r(p1)'
	putexcel `a'5=`r(p25)'
	putexcel `a'6=`r(p50)'
	putexcel `a'7=`r(mean)'
	putexcel `a'8=`r(p75)'
	putexcel `a'9=`r(p95)'
	putexcel `a'10=`r(p99)'
	putexcel `a'11=`r(max)'
	putexcel `a'12=`r(sd)'
	putexcel `a'13=`r(N)'
	
	
	
	
	twoway kdensity puntaje_pun if exp_6==0	,lwidth(thick) || kdensity puntaje_pun if exp_6==1 ,lp(dash) lwidth(thick)	///
	, legend(order(1 "Menor igual a 6" 2 "Mayor a 6" )) title("Distribución de Puntajes totales Epata Centralizada" ///
	"según experiencia") ///
	ytitle(freq) 	xtitle(Puntaje PUN) ///
		graphregion(color(white))	///
	caption("Fuente: Concurso de Nombramiento 2015" ///
	, size(small) position(7)) 

	graph export "$output\PUN_2exp.png", replace

	putexcel set "$esw\calculos\graficos\subpruebasPUN.xlsx", sheet("PUN_tot") modify
	putexcel H1="Distribución de la PUN según experiencia"
	local a H
	putexcel `a'2="Estadística"
	putexcel `a'3="Min"
	putexcel `a'4="p1"
	putexcel `a'5="p25"
	putexcel `a'6="p50"
	putexcel `a'7="mean"
	putexcel `a'8="p75"
	putexcel `a'9="p95"
	putexcel `a'10="p99"
	putexcel `a'11="max"
	putexcel `a'12="desviación estándar"
	putexcel `a'13="Obs"
	
	sum puntaje_pun if exp_6==0, d 
	local a I
	putexcel `a'2="Experiencia<6"
	putexcel `a'3=`r(min)'
	putexcel `a'4=`r(p1)'
	putexcel `a'5=`r(p25)'
	putexcel `a'6=`r(p50)'
	putexcel `a'7=`r(mean)'
	putexcel `a'8=`r(p75)'
	putexcel `a'9=`r(p95)'
	putexcel `a'10=`r(p99)'
	putexcel `a'11=`r(max)'
	putexcel `a'12=`r(sd)'
	putexcel `a'13=`r(N)'
	
	sum puntaje_pun if exp_6==1, d 
	local a J
	putexcel `a'2="Experiencia>6"
	putexcel `a'3=`r(min)'
	putexcel `a'4=`r(p1)'
	putexcel `a'5=`r(p25)'
	putexcel `a'6=`r(p50)'
	putexcel `a'7=`r(mean)'
	putexcel `a'8=`r(p75)'
	putexcel `a'9=`r(p95)'
	putexcel `a'10=`r(p99)'
	putexcel `a'11=`r(max)'
	putexcel `a'12=`r(sd)'
	putexcel `a'13=`r(N)'
	
	
	distplot puntaje_pun, over(exp_6 )  lp(2 dash) lwidth(2 thick)  ///
	legend(order(1 "Menor igual a 6" 2 "Mayor a 6" )) title("Distribución acumulada de PUN Epata Centralizada" ///
	"según experiencia") ///
	ytitle(freq) 	xtitle(Puntaje PUN) ///
		graphregion(color(white))	///
	caption("Fuente: Concurso de Nombramiento 2015" ///
	"Nota: PUN= Prueba Única Nacional" ///
	, size(small) position(7)) 
	graph export "$output\CumulExp.png", replace	
	
	putexcel set "$esw\calculos\graficos\subpruebasPUN.xlsx", sheet("dom_stoc") modify
	local a A
	putexcel `a'1="Test de dominancia estocástica según experiencia"
	putexcel `a'2="La distribución que tiene mayor PUN es:"
	putexcel `a'3="Diferencia máxima"
	putexcel `a'4="p-val"
	putexcel `a'5="Significancia"
	
	
	ksmirnov puntaje_pun, by(exp_6)
	local a B
	putexcel `a'2="Experiencia más de 6 años"
	putexcel `a'3=`r(D_1)'
	putexcel `a'4=`r(p_1)'
	putexcel `a'5="***"
	
	local a C
	putexcel `a'2="Experiencia menos de 6 años"
	putexcel `a'3=`r(D_2)'
	putexcel `a'4=`r(p_2)'
	putexcel `a'5=""
	
	
	
	
	twoway kdensity puntaje_pun if exp_3==1	,lwidth(thick) || kdensity puntaje_pun if exp_3==2 ,lp(dash) lwidth(thick)	///
	|| kdensity puntaje_pun if exp_3==3 ,lp(shortdash_dot) lwidth(thick) , legend(order(1 "1 año" 2 "2 o 3 años" 3 "4 a más" )) title("Distribución de Puntajes totales Epata Centralizada" ///
	"según experiencia") ///
	ytitle(freq) 	xtitle(Puntaje PUN) ///
		graphregion(color(white))	///
	caption("Fuente: Concurso de Nombramiento 2015" ///
	, size(small) position(7)) 
	graph export "$output\PUN_3exp.png", replace
	
	
	putexcel set "$esw\calculos\graficos\subpruebasPUN.xlsx", sheet("PUN_tot") modify
	putexcel X1="Distribución de la PUN según experiencia"
	local a X
	putexcel `a'2="Estadística"
	putexcel `a'3="Min"
	putexcel `a'4="p1"
	putexcel `a'5="p25"
	putexcel `a'6="p50"
	putexcel `a'7="mean"
	putexcel `a'8="p75"
	putexcel `a'9="p95"
	putexcel `a'10="p99"
	putexcel `a'11="max"
	putexcel `a'12="desviación estándar"
	putexcel `a'13="Obs"
	
	sum puntaje_pun if exp_3==1, d 
	local a Y
	putexcel `a'2="1 año"
	putexcel `a'3=`r(min)'
	putexcel `a'4=`r(p1)'
	putexcel `a'5=`r(p25)'
	putexcel `a'6=`r(p50)'
	putexcel `a'7=`r(mean)'
	putexcel `a'8=`r(p75)'
	putexcel `a'9=`r(p95)'
	putexcel `a'10=`r(p99)'
	putexcel `a'11=`r(max)'
	putexcel `a'12=`r(sd)'
	putexcel `a'13=`r(N)'
	
	sum puntaje_pun if exp_3==2, d 
	local a Z
	putexcel `a'2="2 o 3 años"
	putexcel `a'3=`r(min)'
	putexcel `a'4=`r(p1)'
	putexcel `a'5=`r(p25)'
	putexcel `a'6=`r(p50)'
	putexcel `a'7=`r(mean)'
	putexcel `a'8=`r(p75)'
	putexcel `a'9=`r(p95)'
	putexcel `a'10=`r(p99)'
	putexcel `a'11=`r(max)'
	putexcel `a'12=`r(sd)'
	putexcel `a'13=`r(N)'
	
	sum puntaje_pun if exp_3==3, d 
	local a AA
	putexcel `a'2="4 años a más"
	putexcel `a'3=`r(min)'
	putexcel `a'4=`r(p1)'
	putexcel `a'5=`r(p25)'
	putexcel `a'6=`r(p50)'
	putexcel `a'7=`r(mean)'
	putexcel `a'8=`r(p75)'
	putexcel `a'9=`r(p95)'
	putexcel `a'10=`r(p99)'
	putexcel `a'11=`r(max)'
	putexcel `a'12=`r(sd)'
	putexcel `a'13=`r(N)'
	
	
	aaplot pun exp_tot, msymbol(o) msize(vtiny) quadratic lwidth( thick) ///
	lcolor(1 navy) ytitle("PUN") ///
	title("Relación entre Puntaje PUN y experiencia total") ///
			graphregion(color(white))	///
	caption("Fuente: Concurso de Nombramiento 2015" ///
	, size(small) position(7)) 
		graph export "$output\scatter_PunExp.png", replace
	
	reg pun exp_tot exp_q, r

twoway kdensity puntaje_pun if exp_17==1	,lwidth(thick) || kdensity puntaje_pun if exp_17==2 ,lp(dash) lwidth(thick)	///
	|| kdensity puntaje_pun if exp_17==3 ,lp(shortdash_dot) lwidth(thick) , legend(order(1 "0 a 6 años" 2 "7 o 16 años" 3 "17 a más" )) title("Distribución de Puntajes totales Epata Centralizada" ///
	"según experiencia") ///
	ytitle(freq) 	xtitle(Puntaje PUN) ///
		graphregion(color(white))	///
	caption("Fuente: Concurso de Nombramiento 2015" ///
	"Nota: El percentil 95 es 17 años y la mediana 6 años" ///
	, size(small) position(7)) 
	graph export "$output\PUN_17exp.png", replace	
	
	
	
	twoway kdensity puntaje_pun if edad_36==0 ,lwidth(thick)	 || kdensity puntaje_pun if edad_36==1 ,lp(dash) lwidth(thick)	///
	, legend(order(1 "Menor igual a 36" 2 "Mayor a 36" )) title("Distribución de Puntajes totales Epata Centralizada" ///
	"según edad") ///
	ytitle(freq) 	xtitle(Puntaje PUN) ///
		graphregion(color(white))	///
	caption("Fuente: Concurso de Nombramiento 2015" ///
	, size(small) position(7)) 
		graph export "$output\PUNedad.png", replace
	
	putexcel set "$esw\calculos\graficos\subpruebasPUN.xlsx", sheet("PUN_tot") modify
	putexcel L1="Distribución de la PUN según edad"
	local a L
	putexcel `a'2="Estadística"
	putexcel `a'3="Min"
	putexcel `a'4="p1"
	putexcel `a'5="p25"
	putexcel `a'6="p50"
	putexcel `a'7="mean"
	putexcel `a'8="p75"
	putexcel `a'9="p95"
	putexcel `a'10="p99"
	putexcel `a'11="max"
	putexcel `a'12="desviación estándar"
	putexcel `a'13="Obs"
	
	sum puntaje_pun if edad_36==0, d 
	local a M
	putexcel `a'2="Edad<36"
	putexcel `a'3=`r(min)'
	putexcel `a'4=`r(p1)'
	putexcel `a'5=`r(p25)'
	putexcel `a'6=`r(p50)'
	putexcel `a'7=`r(mean)'
	putexcel `a'8=`r(p75)'
	putexcel `a'9=`r(p95)'
	putexcel `a'10=`r(p99)'
	putexcel `a'11=`r(max)'
	putexcel `a'12=`r(sd)'
	putexcel `a'13=`r(N)'
	
	sum puntaje_pun if edad_36==1, d 
	local a N
	putexcel `a'2="Edad>36"
	putexcel `a'3=`r(min)'
	putexcel `a'4=`r(p1)'
	putexcel `a'5=`r(p25)'
	putexcel `a'6=`r(p50)'
	putexcel `a'7=`r(mean)'
	putexcel `a'8=`r(p75)'
	putexcel `a'9=`r(p95)'
	putexcel `a'10=`r(p99)'
	putexcel `a'11=`r(max)'
	putexcel `a'12=`r(sd)'
	putexcel `a'13=`r(N)'
	
	aaplot pun edad if edad<66, msymbol(o) msize(vtiny) quadratic lwidth( thick) ///
	lcolor(1 navy) title("Relación entre Puntaje PUN y Edad") ///
			graphregion(color(white))	///
	caption("Fuente: Concurso de Nombramiento 2015" ///
	"Nota: Se excluyen los postulantes mayores a 65" ///
	, size(small) position(7)) 
		graph export "$output\scatter_PUNedad.png", replace
	reg pun edad edad_q if edad<66,r
	reg pun edad edad_q ,r	

	twoway kdensity puntaje_pun if edad_27==1 ,lwidth(thick)	 || kdensity puntaje_pun if edad_27==2 ,lp(dash) lwidth(thick)	///
	|| kdensity puntaje_pun if edad_27==3 ,lp(dash) lwidth(thick) lp(shortdash_dot)	///
	, legend(order(1 "Menor igual a 27" 2 "Entre 28 y 36" 3 "37 a más" )) title("Distribución de Puntajes totales Epata Centralizada" ///
	"según edad") ///
	ytitle(freq) 	xtitle(Puntaje PUN) ///
		graphregion(color(white))	///
	caption("Fuente: Concurso de Nombramiento 2015" ///
	"Nota: El percentil 5 es 27 años y la mediana 36 años" ///
	, size(small) position(7)) 
		graph export "$output\PUNedad27.png", replace
	
	
	*---------------------
		distplot puntaje_pun, over(edad_36 )  lp(2 dash) lwidth(2 thick)  ///
	legend(order(1 "Menor igual a 36" 2 "Mayor a 36" )) title("Distribución acumulada de PUN Epata Centralizada" ///
	"según edad") ///
	ytitle(freq) 	xtitle(Puntaje PUN) ///
		graphregion(color(white))	///
	caption("Fuente: Concurso de Nombramiento 2015" ///
	"Nota: PUN= Prueba Única Nacional" ///
	, size(small) position(7)) 
		graph export "$output\CumulEdad.png", replace
	
	putexcel set "$esw\calculos\graficos\subpruebasPUN.xlsx", sheet("dom_stoc") modify
	local a E
	putexcel `a'1="Test de dominancia estocástica según edad"
	putexcel `a'2="La distribución que tiene mayor PUN es:"
	putexcel `a'3="Diferencia máxima"
	putexcel `a'4="p-val"
	putexcel `a'5="Significancia"
	
	
	ksmirnov puntaje_pun, by(edad_36)
	local a F
	putexcel `a'2="Edad más de 36 años"
	putexcel `a'3=`r(D_1)'
	putexcel `a'4=`r(p_1)'
	putexcel `a'5=""
	
	local a G
	putexcel `a'2="Edad menos de 36 años"
	putexcel `a'3=`r(D_2)'
	putexcel `a'4=`r(p_2)'
	putexcel `a'5="***"
	
	*------------------------------------------------
	
		
	twoway kdensity puntaje_pun if sexo1==1	,lwidth(thick) || kdensity puntaje_pun if sexo1==2 ,lp(dash) lwidth(thick)	///
	, legend(order(1 "Mujeres" 2 "Hombres" )) title("Distribución de Puntajes totales Epata Centralizada" ///
	"según sexo") ///
	ytitle(freq) 	xtitle(Puntaje PUN) ///
		graphregion(color(white))	///
	caption("Fuente: Concurso de Nombramiento 2015" ///
	, size(small) position(7)) 
	graph export "$output\PUNsexo.png", replace
	
	putexcel set "$esw\calculos\graficos\subpruebasPUN.xlsx", sheet("PUN_tot") modify
	putexcel P1="Distribución de la PUN según sexo"
	local a P
	putexcel `a'2="Estadística"
	putexcel `a'3="Min"
	putexcel `a'4="p1"
	putexcel `a'5="p25"
	putexcel `a'6="p50"
	putexcel `a'7="mean"
	putexcel `a'8="p75"
	putexcel `a'9="p95"
	putexcel `a'10="p99"
	putexcel `a'11="max"
	putexcel `a'12="desviación estándar"
	putexcel `a'13="Obs"
	
	sum puntaje_pun if sexo1==1, d 
	local a Q
	putexcel `a'2="Mujeres"
	putexcel `a'3=`r(min)'
	putexcel `a'4=`r(p1)'
	putexcel `a'5=`r(p25)'
	putexcel `a'6=`r(p50)'
	putexcel `a'7=`r(mean)'
	putexcel `a'8=`r(p75)'
	putexcel `a'9=`r(p95)'
	putexcel `a'10=`r(p99)'
	putexcel `a'11=`r(max)'
	putexcel `a'12=`r(sd)'
	putexcel `a'13=`r(N)'
	
	sum puntaje_pun if sexo1==2, d 
	local a R
	putexcel `a'2="Hombres"
	putexcel `a'3=`r(min)'
	putexcel `a'4=`r(p1)'
	putexcel `a'5=`r(p25)'
	putexcel `a'6=`r(p50)'
	putexcel `a'7=`r(mean)'
	putexcel `a'8=`r(p75)'
	putexcel `a'9=`r(p95)'
	putexcel `a'10=`r(p99)'
	putexcel `a'11=`r(max)'
	putexcel `a'12=`r(sd)'
	putexcel `a'13=`r(N)'
	
	distplot puntaje_pun, over(sexo1 )  lp(2 dash) lwidth(2 thick)  ///
	legend(order(1 "Mujeres" 2 "Hombres" )) title("Distribución acumulada de PUN Epata Centralizada" ///
	"según sexo") ///
	ytitle(freq) 	xtitle(Puntaje PUN) ///
		graphregion(color(white))	///
	caption("Fuente: Concurso de Nombramiento 2015" ///
	"Nota: PUN= Prueba Única Nacional" ///
	, size(small) position(7)) 
		graph export "$output\CumulSexo.png", replace
	
	putexcel set "$esw\calculos\graficos\subpruebasPUN.xlsx", sheet("dom_stoc") modify
	local a I
	putexcel `a'1="Test de dominancia estocástica según sexo"
	putexcel `a'2="La distribución que tiene mayor PUN es:"
	putexcel `a'3="Diferencia máxima"
	putexcel `a'4="p-val"
	putexcel `a'5="Significancia"
	
	
	ksmirnov puntaje_pun, by(sexo1)
	local a J
	putexcel `a'2="Hombres"
	putexcel `a'3=`r(D_1)'
	putexcel `a'4=`r(p_1)'
	putexcel `a'5="**"
	
	local a K
	putexcel `a'2="Mujeres"
	putexcel `a'3=`r(D_2)'
	putexcel `a'4=`r(p_2)'
	putexcel `a'5="***"
	
	
	
	twoway kdensity puntaje_pun if instituto==2 ,lwidth(thick)	///
	|| kdensity puntaje_pun if instituto==3 ,lp( shortdash_dot) lwidth(thick) ///
	, legend(order(1 "Instituto" 2 "Universidad" )) title("Distribución de Puntajes totales Epata Centralizada" ///
	"según institución de procedencia") ///
	ytitle(freq) 	xtitle(Puntaje PUN) ///
		graphregion(color(white))	///
	caption("Fuente: Concurso de Nombramiento 2015" ///
	, size(small) position(7)) 
		graph export "$output\PUNinst.png", replace
	
	
	
	twoway kdensity puntaje_pun if g_univ3 ==1 ,lwidth(thick)	///
	|| kdensity puntaje_pun if g_univ3 ==2 ,lp( shortdash_dot) lwidth(thick) ///
	, legend(order(1 "Univ Pública" 2 "Univ privada"  )) title("Distribución de Puntajes totales Epata Centralizada" ///
	"según gestión de la universidad") ///
	ytitle(freq) 	xtitle(Puntaje PUN) ///
		graphregion(color(white))	///
	caption("Fuente: Concurso de Nombramiento 2015" ///
	, size(small) position(7)) 
		graph export "$output\PUNuniv_g.png", replace
	
	twoway kdensity puntaje_pun if g_univ3 ==3 ,lwidth(thick)	///
	|| kdensity puntaje_pun if g_univ3 ==4 ,lp( shortdash_dot) lwidth(thick) ///
	, legend(order(1 "Ins Pública" 2 "Ins privada"  )) title("Distribución de Puntajes totales Epata Centralizada" ///
	"según gestión del Instituto") ///
	ytitle(freq) 	xtitle(Puntaje PUN) ///
		graphregion(color(white))	///
	caption("Fuente: Concurso de Nombramiento 2015" ///
	, size(small) position(7)) 
		graph export "$output\PUNins_g.png", replace
	
	putexcel set "$esw\calculos\graficos\subpruebasPUN.xlsx", sheet("PUN_tot") modify
	putexcel T1="Distribución de la PUN institución de procedencia"
	local a T
	putexcel `a'2="Estadística"
	putexcel `a'3="Min"
	putexcel `a'4="p1"
	putexcel `a'5="p25"
	putexcel `a'6="p50"
	putexcel `a'7="mean"
	putexcel `a'8="p75"
	putexcel `a'9="p95"
	putexcel `a'10="p99"
	putexcel `a'11="max"
	putexcel `a'12="desviación estándar"
	putexcel `a'13="Obs"
	
	sum puntaje_pun if instituto==2, d 
	local a U
	putexcel `a'2="Instituto"
	putexcel `a'3=`r(min)'
	putexcel `a'4=`r(p1)'
	putexcel `a'5=`r(p25)'
	putexcel `a'6=`r(p50)'
	putexcel `a'7=`r(mean)'
	putexcel `a'8=`r(p75)'
	putexcel `a'9=`r(p95)'
	putexcel `a'10=`r(p99)'
	putexcel `a'11=`r(max)'
	putexcel `a'12=`r(sd)'
	putexcel `a'13=`r(N)'
	
	sum puntaje_pun if instituto==3, d 
	local a V
	putexcel `a'2="Universidad"
	putexcel `a'3=`r(min)'
	putexcel `a'4=`r(p1)'
	putexcel `a'5=`r(p25)'
	putexcel `a'6=`r(p50)'
	putexcel `a'7=`r(mean)'
	putexcel `a'8=`r(p75)'
	putexcel `a'9=`r(p95)'
	putexcel `a'10=`r(p99)'
	putexcel `a'11=`r(max)'
	putexcel `a'12=`r(sd)'
	putexcel `a'13=`r(N)'
	

	distplot puntaje_pun, over(solo_inst )  lp(2 dash) lwidth(2 thick)  ///
	legend(order(1 "Instituto" 2 "Universidad" )) title("Distribución acumulada de PUN Epata Centralizada" ///
	"según institución de procedencia") ///
	ytitle(freq) 	xtitle(Puntaje PUN) ///
		graphregion(color(white))	///
	caption("Fuente: Concurso de Nombramiento 2015" ///
	"Nota: PUN= Prueba Única Nacional" ///
	, size(small) position(7)) 
		graph export "$output\CumulINS.png", replace
	
	putexcel set "$esw\calculos\graficos\subpruebasPUN.xlsx", sheet("dom_stoc") modify
	local a M
	putexcel `a'1="Test de dominancia estocástica según institución de procedencia"
	putexcel `a'2="La distribución que tiene mayor PUN es:"
	putexcel `a'3="Diferencia máxima"
	putexcel `a'4="p-val"
	putexcel `a'5="Significancia"
	
	
	ksmirnov puntaje_pun, by(solo_ins)
	local a N
	putexcel `a'2="Universidad"
	putexcel `a'3=`r(D_1)'
	putexcel `a'4=`r(p_1)'
	putexcel `a'5="***"
	
	local a O
	putexcel `a'2="Instituto"
	putexcel `a'3=`r(D_2)'
	putexcel `a'4=`r(p_2)'
	putexcel `a'5=""

	
	
	
	aaplot exp_tot edad , ///
	title("Relación entre edad y experiencia total") ///
			graphregion(color(white))	///
	caption("Fuente: Concurso de Nombramiento 2015" ///
	, size(small) position(7)) 
	graph export "$output\scatter_ExpEdad.png", replace

	
	*por regiones
		tabstat puntaje_pun , stat(mean) by( dominio_dpt )
