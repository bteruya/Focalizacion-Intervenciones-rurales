	global ruta D:\BRENDA-documentos\OneDrive - Inter-American Development Bank Group\Trabajo BID-onedrive\docentes\simulaciones\Calculos\Dofiles\BID -dofiles
	do "$ruta\rutas_mat.do"
	cd "$directory_b"

********************************************************************************
*profesores efectivos (horas efectivas)

	*use "$data\4_Staff Level\1_Match Nexus_SUP\bases15complete\nivel_escuela\salarios_2015.dta", clear
	*tostring cod_mod, replace format(%07.0f)
	use "$directory_e\Data\2_IIEE Level\1_Padrón Completo UPP\padron_UPP_201611.dta", clear
	keep if anexo==0
	drop _m
	
	tempfile padron_2016
	save `padron_2016', replace
	
	
	use "$nexus_bid\Nexus_2015_bid.dta", clear
	rename CodigoModular cod_mod
	tab SubtipodeTrabajador SituacionLaboral
	
	merge m:1 cod_mod using `padron_2016'
	*los merge1 son trabajadores de no escuelas, los saco
	*merge2 escuelas sin profesores, los saco
	keep if _m==3
	drop _m 
	
	gen docente= SubtipodeTrabajador ==2
	replace docente=1 if cod_car=="1" & SubtipodeTrabajador==1 
	*los directores unidocentes
	*inicial y primaria
	keep if Nivel==4|Nivel==5|Nivel==6 //inicial primaria secundaria
	keep if docente==1
	gen n_doc=1
	gen h_doc_nombrado=JornadaLaboral*(SituacionLaboral ==6)
	
	collapse (sum) h_efectiv1=JornadaLaboral n_doc h_doc_nombrado, by(cod_mod)
	label var h_efectiv1 "horas efectivas "
	gen n_doc_nombrado=h_doc_nombrado/30
	tabstat n_doc_nombrado h_efectiv1, stat(sum)
	tabstat n_* h_*, stat(sum)
	 dis 6212085/30 //bien dividido docentes nombrados
	 dis 8661984/30 //=288732.8 vs 306060 docentes totales bien calculados
	save "$esw\cálculos\graficos\h_efectiva_2015", replace
	*tienen todas las horas mezcladas

	
********************************************************************************
*HORAS REQUERIDAS
*primero secciones requeridas:
		global ini_uni			=	15
		global ini_poli_urb		=	25
		global ini_poli_rur		=	20

	*Primaria
		global prim_uni			=	20
		global prim_multi_urb	=	25
		global prim_multi_rur	=	20
		global prim_comp_urb	=	30
		global prim_comp_rur	=	25
		
	*Se	cundaria
		global sec_urb			=	30
		global sec_rur			=	25
		global horas_jes		=	35
		global horas_jec		=	45
		global jornada_jes		=	24
		global jornada_jec		=	30		
		global jornada_jen		= 	26 //no se usa

		
		
	
	/*use "input\SIAGIE 2013-2017\data_2015.dta", clear
	gen matri=1
	collapse (sum) matri, by(cod_mod)
	
	tostring cod_mod, replace format(%07.0f)
	merge 1:1 cod_mod using `padron_cod'
	*son 3 codmod que tienen matricula pero no estan en el padron2016
	*busque los 3 en escale y son privados, todo bien
	*/
	
	use "input\SIAGIE 2013-2017\data_2015.dta", clear
	gsort id_persona -fecha_registro
	duplicates tag id_persona, gen(dupli_persona)
	tab dupli_persona
	
	by id_persona: gen unique=_n //ya esta ordenado, de la fecha mas reciente a la mas antigua
	*unique sera 1 cuando sea la fecha mas reciente
	keep if unique==1
	*nos quedamos con los de la fecha de registro mas reciente, si la fecha de registro es la misma (44 casos)
	*es aleatorio

	*establecer el grado que cursa el alumno
	gen dsc_grado_noespacio= subinstr(dsc_grado," ","",.)
	
	gen grado=.
	*inicial
	replace grado=2 if id_grado==1
	replace grado=3 if id_grado ==2 
	replace grado=3 if dsc_grado_noespacio=="Grupo3años"
	replace grado=4 if  dsc_grado_noespacio=="4años" 
	replace grado=4 if dsc_grado_noespacio=="Grupo4años"
	replace grado=5 if dsc_grado_noespacio=="5años"
	replace grado=5 if dsc_grado_noespacio=="Grupo5años"
	
	*primaria
	replace grado=6 if id_grado ==4 &  dsc_grado_noespacio=="PRIMERO"
	replace grado=7 if id_grado ==5 &  dsc_grado_noespacio=="SEGUNDO"
	replace grado=8 if id_grado ==6 &  dsc_grado_noespacio=="TERCERO"
	replace grado=9 if id_grado ==7 
	replace grado=10 if id_grado ==8
	replace grado=11 if  dsc_grado_noespacio =="SEXTO"
	
	*SECUNDARIA
	replace grado=12 if id_grado == 10
	replace grado=13 if id_grado == 11
	replace grado=14 if id_grado == 12
	replace grado=15 if id_grado == 13
	replace grado=16 if id_grado == 14
	
	rename id_anio year
	rename id_seccion n_sec
	
	gen matri15=1
	collapse (sum) matri15 (max) n_sec, by(grado cod_mod)
	rename matri15 matri15_
	rename n_sec n_sec_
	reshape wide matri15_ n_sec_, i(cod_mod) j(grado)
	
	
	
	tostring cod_mod, replace format(%07.0f)
/*preserve 
	use "$data\2_IIEE Level\1_Padrón Completo UPP\padron_UPP_201611.dta", clear
	*tostring cod_mod, replace format(%07.0f)
	
	tempfile padron_cod
	save `padron_cod', replace
	
	
restore	
	
	
	merge 1:1 cod_mod using `padron_cod'
	*1 escuelas con matrícula sin padron
	*2 escuelas con padrón sin matrícula
	keep if _m==3
	drop _m
	rename rural rural_grad
	gen rural=area==0
	label def rural 1 "Rural" 0 "Urbano"
	label val rural rural
*/	
	save "$esw\cálculos\graficos\siagie_2015.dta", replace
	
	use "$esw\cálculos\graficos\siagie_2015.dta", clear
	
	
	preserve
	use "$data\2_IIEE Level\1_Padrón Completo UPP\padron_UPP_201611.dta", clear
	replace jec=jec==2015
	label def jec1 1 "JEC" 0 "JER"
	label val jec jec1
	tempfile jec
	drop _m
	keep cod_mod codlocal jec area_sig d_areasig niv_mod d_niv_mod nivel d_nivel ///
	cod_car d_cod_car
	
	save `jec', replace
	restore
	
	merge 1:1 cod_mod using `jec'
	drop if _m==2 //escuelas con padrón 2016 sin mat 2015
	drop _m
	
	drop if d_nivel=="PRONOEI" //PRONOEI CHAU
	label def niv 1 "Inicial" 2 "Primaria" 3 "Secundaria"
	label val nivel niv

	gen rural= area_sig=="2"
	label def rural 1 "Rural" 0 "Urbano"
	label val rural rural
	
	replace cod_car="" if cod_car=="a" | cod_car=="m"
	destring cod_car, replace
	
		gen ratio1		=	$ini_poli_urb 	if 	nivel==1 	& rural==0 
		replace ratio1	=	$ini_poli_rur 	if 	nivel==1 	& rural==1 
		replace ratio1	=	$prim_uni 		if 	nivel==2 					& cod_car==1
		replace ratio1	=	$prim_multi_urb if 	nivel==2 	& rural==0 	& cod_car==2
		replace ratio1	=	$prim_multi_rur if 	nivel==2	& rural==1 	& cod_car==2
		replace ratio1	=	$prim_comp_urb 	if 	nivel==2	& rural==0 		& cod_car==3
		replace ratio1	=	$prim_comp_rur 	if 	nivel==3 	& rural==1 	& cod_car==3
		replace ratio1	=	$sec_urb 		if 	nivel==3 	& rural==0
		replace ratio1	=	$sec_rur 		if 	nivel==3 	& rural==1	
	
	
	egen matri2015_ini =rowtotal(matri15_2 matri15_3 matri15_4 matri15_5)
	egen matri2015_pri= rowtotal(matri15_6 matri15_7 matri15_8 matri15_9 ///
		matri15_10 matri15_11)
	egen matri2015_sec=	rowtotal(matri15_12 matri15_13 matri15_14 matri15_15 ///
		matri15_16 )
		
	tabstat matri2015_??? , by(nivel) stat(sum)	
	dis  1014169  + 2672105  + 1903541 //matrícula total y por niveles bien creada
	
	
	gen unidocente=1 if (matri2015_ini<=	$ini_uni & rural==1 & nivel==1) | (matri2015_pri<=$prim_uni & rural==1 & nivel==2)
	replace unidocente=0 if unidocente==.
	gen multigrado=cod_car==2
	
	local a 15
	gen decimal=.
	gen entero=.
	gen cuenta_entero=0
	forval x = 2/16 {
		gen n_sec`a'_`x' = (matri`a'_`x'/ratio1)  
		replace entero= floor(n_sec`a'_`x')
		replace decimal=n_sec`a'_`x'-entero
		gen n_sec`a'_`x'_entero=entero+(decimal>0.2)
		replace cuenta_entero=cuenta_entero+1 if n_sec`a'_`x'==entero
		
	}	
	
	*drop matri_tot
	egen matri_tot=rowtotal(matri2015_ini matri2015_pri matri2015_sec)

	egen n_sec_ini=rowtotal(n_sec15_2_entero n_sec15_3_entero ///
	n_sec15_4_entero n_sec15_5_entero)
	egen n_sec_pri=rowtotal(n_sec15_6_entero n_sec15_7_entero n_sec15_8_entero ///
	n_sec15_9_entero n_sec15_10_entero n_sec15_11_entero)
	egen n_sec_sec=rowtotal(n_sec15_12_entero n_sec15_13_entero ///
	n_sec15_14_entero n_sec15_15_entero n_sec15_16_entero)
	
	
	*solo primaria tiene multigrado, reemplazaremos las secciones de primaria en otro lugar
	local a 15
	forval x = 6/11 {
	replace n_sec`a'_`x'_ente=0 if multigrado==1
	}
	
	replace entero =floor(matri2015_pri/ratio1) if multigrado==1
	replace decimal=matri2015_pri/ratio1-entero if multigrado==1
	replace n_sec_pri=entero+(decimal>0.2) if multigrado==1
	tabstat n_sec_??? matri2015_??? if multigrado==1, stat(sum) //bien creado
	dis  494626 /20
	dis  494626 /25
	*he revisado la IE 0200014, primaria multigrado rural publica JER
	*matri 34 ratio 20, n_sec 1.7 aprox 2
	
	*ajuste para unidocentes
	replace n_sec_pri=1 if unidocente==1 & nivel==2
	replace n_sec_ini=1 if unidocente==1 & nivel==1
	
	egen n_sec_tot=rowtotal(n_sec_ini n_sec_pri n_sec_sec)
	egen matri2015=rowtotal(matri2015_ini matri2015_pri matri2015_sec)
	
	tabstat n_sec_??? matri2015*, stat(sum) by(nivel)
	dis  5589815 /30
	dis  5589815 /20	
	*en secundaria el minedu realiza un calculo distinto, asume que las secciones son las que existen efectivamente
	*y no las de la normativa
	egen n_seccion=rowtotal (n_sec_2 n_sec_3 n_sec_4 n_sec_5 n_sec_6 n_sec_7 ///
	n_sec_8 n_sec_9 n_sec_10 n_sec_11 n_sec_12 n_sec_13 n_sec_14 n_sec_15 ///
	n_sec_16)
	replace n_sec_tot=n_seccion if nivel==3
*-------------------------------------------------------------------------------
local a 2015
	gen h_req`a'_ini=n_sec_tot*30 if nivel==1
	gen h_req`a'_pri=n_sec_tot*30 if nivel==2

	gen h_req`a'_secupp=n_sec_tot*35 if nivel==3 & jec==0
	replace h_req`a'_secupp=n_sec_tot*45 if nivel==3 & jec==1
	
	
	egen h_req2015=rowtotal(h_req2015_ini h_req2015_pri h_req2015_secupp )
	tabstat n_sec_??? h_req2015_* h_req2015, by(nivel) stat(sum)
	
	
	label var h_req2015 "horas requeridas por cod_mod"

	tabstat n_sec_tot matri_tot h_req2015,stat(sum) by(nivel) 
	tabstat n_sec_??? matri_tot h_req2015,stat(sum)
	
preserve 	
***********************************************************************************
use "$data\2_IIEE Level\8_Censo Escolar 2015\Stata\11_local_escolar_304_.dta", clear
	bys codlocal : gen aula_innov=p304_1=="02"
	duplicates drop codlocal, force
	keep codlocal aula_innov
	tempfile aula_innov
save `aula_innov', replace

restore 
	merge m:1 codlocal using `aula_innov', keepusing(aula_innov)
	replace aula_innov=0 if _m==1
	drop if _m==2
	drop _m
	gen h_req_innov=aula_innov*30
	replace h_req2015=h_req2015+h_req_innov
	
	
save "$esw\cálculos\graficos\h_req_nivmod_innov.dta", replace
		
********************************************************************************
use "$esw\cálculos\graficos\h_efectiva_2015.dta", clear
	merge 1:1 cod_mod using "$esw\cálculos\graficos\h_req_nivmod_innov"
	keep if _m==3 //nos quedamos con aquellas escuelas con profesores (nexus) 
	*y alumnos siagie
	drop _m
	
	/*recode dpto (15=26) (16=15) (17=16) (18=17) (19=18) (20=19) (21=20) ///
	(22=21) (23=22) (24=23) (25=24) (26=25) , gen(dpto1)
	drop dpto
	rename dpto1 dpto
	tab d_dpto dpto
	merge m:1 dpto using input\26_regiones_pob
	drop _merge
	tab Departamento d_dpto //chequeamos que esta bien creado
	*/
	gen n_doc_efect=(h_efectiv1/30)
	
	gen n_doc_req_entero=h_req2015/30 if nivel!=3
	replace  n_doc_req_entero=h_req2015/25 if nivel==3
	
	gen n_doc_balance_entero=n_doc_efect-n_doc_req_entero
	gen n_doc_bal_nomb= n_doc_nombrado-n_doc_req_entero
	save "$esw\cálculos\graficos\balance_ebr2015.dta", replace

********************************************************************************
*					plazas ofertadas!!	
********************************************************************************
	
global concurso "$insumo_e\Concurso Nombramiento"
global concurso15 "$concurso\DIED\2015"
global concurso17 "$concurso\DIED\2017"

	use "$concurso\bd_ofertadas_2015.dta", clear
isid CODIGOPLAZA

	gen codgrupo=""
	replace codgrupo="01" if GRUPODEINSCRIPCION=="EBR-INICIAL"
	replace codgrupo="02" if GRUPODEINSCRIPCION=="EBR-PRIMARIA"
	replace codgrupo="03" if GRUPODEINSCRIPCION=="EBR-PRIMARIA - EDUCACION FISICA"
	replace codgrupo="04" if GRUPODEINSCRIPCION=="EBRS-ARTE"	
	replace codgrupo="05" if GRUPODEINSCRIPCION=="EBRS-CIENCIA, TECNOLOGIA Y AMBIENTE"	
	replace codgrupo="06" if GRUPODEINSCRIPCION=="EBRS-COMUNICACION"	
	replace codgrupo="07" if GRUPODEINSCRIPCION=="EBRS-EDUCACION FISICA"	
	replace codgrupo="08" if GRUPODEINSCRIPCION=="EBRS-EDUCACION PARA EL TRABAJO"	
	replace codgrupo="09" if GRUPODEINSCRIPCION=="EBRS-EDUCACION RELIGIOSA"	
	replace codgrupo="10" if GRUPODEINSCRIPCION=="EBRS-FORMACION CIUDADANA Y CIVICA"	
	replace codgrupo="11" if GRUPODEINSCRIPCION=="EBRS-HISTORIA, GEOGRAFIA Y ECONOMIA"	
	replace codgrupo="12" if GRUPODEINSCRIPCION=="EBRS-IDIOMA/INGLES"	
	replace codgrupo="13" if GRUPODEINSCRIPCION=="EBRS-MATEMATICA"	
	replace codgrupo="14" if GRUPODEINSCRIPCION=="EBRS-PERSONA FAMILIA Y RELACIONES HUMANAS"

	/*
	egen listas_plazas=concat(COD_MOD codgrupo)
	duplicates report listas_plazas
	duplicates tag listas_plazas, gen(x)
	tab x
	duplicates drop listas_plazas, force
	tab x
	*se van 2,887 obs de un total de 19,630, es decir el 14.7%
	*/
	rename COD_MOD cod_mod
	gen n_plaza=1
	collapse (sum) n_plaza ,by(cod_mod)
	
	merge 1:1 cod_mod using "$data\2_IIEE Level\1_Padrón Completo UPP\padron_UPP_201611.dta", gen(x)
	drop if x==2
	drop x _m
	
	replace dominio=999 if dominio==.
	label def dominio 999 "sin dominio", modify
	
	label def niv 1 "Inicial" 2 "Primaria" 3 "Secundaria" 
	label val nivel niv
	
	rename codgeo ubigeo
	preserve
	
	use "$data\Pobreza\pob_distritos.dta" , clear
	collapse (first) departamento provincia distrito (mean) pobreza	,by(ubigeo)
	destring ubigeo, replace
	tostring ubigeo, replace	format(%06.0f)
	tempfile pobreza_dist
	save `pobreza_dist'
	
	
	restore
	merge m:1 ubigeo using `pobreza_dist', gen(x)
	drop if x==2 //los distritos sin plazas
	*x==3 los distritos creados sin NSE
	
	xtile NSE=pobreza, nq(5)
	replace NSE=99 if NSE==.
	label def nse 5 "Muy Alto" 4 "Alto" 3 "Medio" 2 "Bajo" 1 "Muy Bajo" 99 "Sin NSE"
	label val NSE nse
	tab pobreza NSE in 1/100
	label var NSE "NSE"
	
	
	gen uno=1
	
	tabstat n_plaza, stat(sum)
	
	tabstat n_plaza, stat(sum) by(dominio)
	
	tabstat n_plaza, stat(sum) by(nivel) 
	table nivel , c(sum n_plaza)
	
	tabstat n_plaza if cod_car!="a", stat(sum) by(d_cod_car)
	
	tabstat n_plaza, stat(sum) by(NSE) 
	table uno, c(p20 pobreza p40 pobreza p60 pobreza p80 pobreza)
	
	tabstat n_plaza, stat(sum) by(dominio) 
	tabstat n_plaza, stat(sum) by(d_areasig) 
	
	tabstat n_plaza, stat(sum) by(d_dpto) 
	
	*mezcla de características
	bys d_areasig: tabstat n_plaza, stat(sum) by(nivel)
	bys d_areasig: tabstat n_plaza if cod_car!="a", stat(sum) by(d_cod_car)	
	
	
*********************************************************************************	
	
	
	
	*plazas ofertadas vs docentes faltantes para inicial y primaria (sin secundaria)
*********************************************************************************	
	*drop if nivel==3
	
	
	merge 1:1 cod_mod using "$esw\cálculos\graficos\balance_ebr2015.dta", ///
	keepusing(n_doc_balance_entero n_doc_bal_nomb)
	drop if _m==2
	
	tabstat n_plaza, stat(sum) by(_m)
	*se excluyen 123 plazas en 122 IE
	
	gen tot=1
	
	gen faltantes_tot=-n_doc_balance_entero
	gen faltantes_nomb=-n_doc_bal_nomb
	*exportar a excel y hacer tablas
	br faltantes_tot faltantes_nomb n_plaza cod_mod
	*chequear que está bien creado
	gen compa=faltantes_nomb>=faltantes_tot
	tab compa //puros verdaderos, perfecto!
	
	gen sobra_alg= faltantes_tot<0
	gen n_pl_alg=n_plaza>0 //en toda la bd de datos por definicion se han hecho 
	*apertura de plazas
	gen sobra_nomb=faltantes_nomb<0
	//excluiremos secundaria
	
	gen matri_15alm=matri2015<=15
	label def matri_15 1 "Hasta 15" 0 "Mayor de 15"
	label val matri_15alm matri_15
	drop if nivel==3 //chau secundaria
	drop if faltantes_nomb==.
	****************************************************************************
	*plazas nacionales
	tabstat n_plaza faltantes_nomb faltantes_tot, stat(sum) 
	
	putexcel set "$esw\cálculos\graficos\plazas_oftadas.xlsx", sheet("plazas") modify
	local a A
	putexcel `a'1="Distribución de plazas ofertadas, docentes faltantes totales y solo nombrados por IE"
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
	
	sum n_plaza, d 
	local a B
	putexcel `a'2="Plazas ofertadas"
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
	
	sum faltantes_nomb, d 
	local a C
	putexcel `a'2="Docentes faltantes nombrados"
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
	
	sum faltantes_tot, d 
	local a D
	putexcel `a'2="Docentes faltantes totales"
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
	

	*por NSE

	tabstat n_plaza faltantes_nomb faltantes_tot, stat(sum) by(dominio)
	tabstat n_plaza faltantes_nomb faltantes_tot, stat(sum) by(NSE)	
	tabstat n_plaza faltantes_nomb faltantes_tot, stat(sum) by(nivel)
	
	tabstat n_plaza faltantes_nomb faltantes_tot if cod_car!="a", stat(sum) by(d_cod_car)
	
	tabstat n_plaza faltantes_nomb faltantes_tot , stat(sum) by(d_areasig)
	*por region
	*collapse (sum) n_plaza faltantes_nomb faltantes_tot (first) pobrezaENAHO2015 OrdenpobrezaENAHO2015,by(Departamento)

	tabstat n_plaza if faltantes_tot!=. , stat(sum) by(sobra_alg)

	tabstat n_plaza if faltantes_tot!=.,stat(sum) by(sobra_nomb)

	tabstat n_plaza if faltantes_tot!=. & nivel!=3 ,stat(sum) by(sobra_nomb)

	
	bys nivel: tabstat n_plaza if faltantes_tot!=. & nivel!=3 ,stat(sum) by(sobra_nomb)
	
	
	table nivel sobra_nomb , by(d_areasig) c(sum n_plaza)

	table d_cod_car sobra_nomb if nivel==2 & faltantes_tot!=. , by(d_areasig) c(sum n_plaza)
	
	table matri_15alm sobra_nomb if nivel==1 & faltantes_tot!=. , by(d_areasig) c(sum n_plaza)
