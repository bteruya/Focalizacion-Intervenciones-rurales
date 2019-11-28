global ruta D:\BRENDA-documentos\OneDrive - Inter-American Development Bank Group\Trabajo BID-onedrive\docentes\simulaciones\Calculos\Dofiles\BID -dofiles
do "$ruta\rutas_mat.do"
cd "$directory_b"
global concurso "$insumo_e\Concurso Nombramiento"
global concurso15 "$concurso\DIED\2015"
global concurso17 "$concurso\DIED\2017"
global output "$esw\cálculos\graficos\output plazas"

use "$concurso15\4a_Evaluados_etapa_descentralizada_2015.dta", clear  	
	isid documento listas_plazas
	gen n_assign=1
	collapse (sum) n_assign ,by(documento) //por persona, cuantas plazas fue asignado
	tempfile assign
	save `assign'

use "$concurso15\2a_seleccion_listas_primera_fase_2015.dta", clear //persona que
*selecciono plaza
	isid  id codigo_modular
	isid documento codigo_modular //cada persona establece hasta 5 codmod
	isid documento listas_plazas
	gen n_select=1
	gen fase=1
	collapse (sum) n_select (first) fase,by(documento) //por persona, cuantas plazas selecciono
	tempfile select1
	save `select1'
	merge 1:1 documento using `assign' //many fases
	
	drop if _m==2 //asignaron preferencias en segunda etapa y fueron asignados
	gen n_post=1
	
	bys _m: tabstat  n_post , by(n_select) stat (sum)
	
	merge 1:1 documento using "$concurso15\1a_Evaluados_etapa_nacional_2015.dta", gen(fase_pun)
	drop if fase_pun==2
	
	
	
	twoway kdensity puntaje_pun if _m==3 ,lwidth(thick)	///
	|| kdensity puntaje_pun if _m==1 ,lp( shortdash_dot) lwidth(thick) ///
	, legend(order(1 "Asignado" 2 "No asignado" )) 	title("Distribución del puntaje PUN según asignación MINEDU," ///
	"2015") ///
	ytitle(freq) 	xtitle(# plazas seleccionadas) ///
		graphregion(color(white))	///
	caption("Fuente: Concurso de Nombramiento 2015" ///
	, size(small) position(7)) 
		graph export "$output\n_select_pun.png", replace
	
	tab procedencia _m if procedencia!="Ambos"
	
********************************************************************************

	
	
use "$concurso15\3a_seleccion_listas_segunda_fase_2015.dta", clear //persona que
*selecciono plaza en segunda fase
	isid  id codigo_modular
	isid documento codigo_modular //cada persona establece hasta 5 codmod
	isid documento listas_plazas
	gen n_select=1
	gen fase=2
	collapse (sum) n_select (first) fase,by(documento) //por persona, cuantas plazas selecciono

	append using `select1'

	duplicates report documento  //hay 1043 personas que fueron a la primera y segunda fase
	
	sort documento fase
	collapse (sum) n_select (first) fase,by(documento)
	
	merge 1:1 documento using `assign' 
	
	merge 1:1 documento using "$concurso15\1a_Evaluados_etapa_nacional_2015.dta", gen(fase_pun)
	drop if fase_pun==2
	
	gen n_post=1
	

	
	bys _m: tabstat  n_post , by(n_select) stat (sum)
	
	twoway kdensity puntaje_pun if _m==3 ,lwidth(thick)	///
	|| kdensity puntaje_pun if _m==1 ,lp( shortdash_dot) lwidth(thick) ///
	, legend(order(1 "Asignado" 2 "No asignado" )) 	title("Distribución del puntaje PUN según asignación MINEDU," ///
	"2015") ///
	ytitle(freq) 	xtitle(# plazas seleccionadas) ///
		graphregion(color(white))	///
	caption("Fuente: Concurso de Nombramiento 2015" ///
	, size(small) position(7)) 
		graph export "$output\n_select_pun.png", replace
	
	tab procedencia _m if procedencia!="Ambos"
	tab _m if procedencia=="Ambos"

********************************************************************************
*ver caracteristicas de la plaza
use "$concurso15\4a_Evaluados_etapa_descentralizada_2015.dta", clear  	
	isid documento listas_plazas
	duplicates report listas_plazas
	gen n_post=1
	collapse (sum) n_post (first) region dre_ugel codigo_modular codgrupo ///
	grupo_inscripcion familia_prof codigo_plaza ,by(listas_plazas) 
	label var n_post "# post asignados por listaplaza"
	
	rename codigo_modular cod_mod
	tab n_post
	
	
	tempfile assign
	save `assign', replace
	
	
	merge m:1 cod_mod using "$data\2_IIEE Level\1_Padrón Completo UPP\padron_UPP_201611.dta", gen(x)
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
	label def nse 1 "Muy Alto" 2 "Alto" 3 "Medio" 4 "Bajo" 5 "Muy Bajo" 99 "Sin NSE"
	label var NSE "NSE"
	label val NSE nse
	tab pobreza NSE in 1/100
	
	
	tabstat n_post, stat(sum) by(dominio)
	tabstat n_post, stat(sum) by(nivel)
	tabstat n_post if cod_car!="a", stat(sum) by(d_cod_car)
	tabstat n_post, stat(sum) by(NSE)
	
	tabstat n_post, stat(sum) by(d_areasig) 
	
********************************************************************************
use "$concurso\bd_ofertadas_2015.dta", clear
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
	
			
	egen listas_plazas=concat(COD_MOD codgrupo)
	*quedan plazas iguales 
	
	duplicates drop listas_plazas, force
	
	merge 1:1 listas_plazas using `assign'
	*8327 listas plazas sin docente asignado

	replace n_post=0 if _m==1
	
	gen uno=1
	tabstat uno, stat(count) by(n_post) //número de listas por cada postulante que había
	
	
	*ahora, quiero comparar los docentes sin postulante asignado con postulante que asignó preferencia y que no asigno preferencia
preserve
	
use "$concurso15\2a_seleccion_listas_primera_fase_2015.dta", clear //persona que
*selecciono plaza
	isid documento listas_plazas
	gen n_pselect=1
	gen fase=1
	collapse (sum) n_pselect (first) fase,by(listas_plazas) //por lista, cuantas personas lo select
	tempfile select1
	save `select1', replace
	
use "$concurso15\3a_seleccion_listas_segunda_fase_2015.dta", clear //persona que
*selecciono plaza en segunda fase
	isid documento listas_plazas
	gen n_pselect=1
	gen fase=2
	collapse (sum) n_pselect (first) fase,by(listas_plazas) //por lista, cuantas personas lo select

	append using `select1'

	duplicates report listas_plazas , force //hay 1043 personas que fueron a la primera y segunda fase
	
	sort listas_plazas fase
	collapse (sum) n_pselect (first) fase,by(listas_plazas)
	tempfile select2
	save `select2', replace
	
restore

	merge 1:1 listas_plazas using `select2' , gen(selec)
/*	not matched                         6,284
        from master                     6,283  (selec==1)//plazas no seleccionadas
        from using                          1  (selec==2) //plaza seleccionada pero no abierta, esta es la plaza que me faltaba!

    matched                            10,460  (selec==3)
*/
	*npost 0 , selec1 son los que no tuvieron seleccion
	replace n_post=-1 if selec==1 
	drop if selec==2
	
	
	recode n_post (-1=-1) (0=0) (1/10=1) (11/20=2), gen(cat_npost)
	label def cat_npost -1 "LPlaza no seleccionada como preferida" 0 "LPlaza preferida pero no asignada" ///
	1 "1 a 10 postulantes asignados" 2 "11 a 20 postulantes asignados"
 	label val cat_npost cat_npost
	
	tab  n_post cat_npost,m //bien creado
	

	replace uno=1 if uno==. //la plaza problemática que fue seleccionada y no ofertada
	
	tab cat_npost
	
	
	rename cod_mod codmod1
	rename COD_MOD cod_mod
	
	merge m:1 cod_mod using "$data\2_IIEE Level\1_Padrón Completo UPP\padron_UPP_201611.dta", gen(pad)
	drop if pad==2
	drop _m pad
	label def niv 1 "Inicial" 2 "Primaria" 3 "Secundaria" 
	label val nivel niv
	
	tab  nivel cat_npost
	tab  d_cod_car cat_npost if cod_car!="a"
	tab  rural cat_npost,m

	
	
	
	
	
	
	
	
	
	
	
	
	
	
*LOS POSTULANTES ASIGNADOS, A QUÉ PREFERENCIA FUERON ASIGNADOS?
	
	
	use "$concurso15\2a_seleccion_listas_primera_fase_2015.dta", clear //persona que
*selecciono plaza
	isid documento listas_plazas
	gen fase=1
	tempfile select1
	save `select1', replace
	
use "$concurso15\3a_seleccion_listas_segunda_fase_2015.dta", clear //persona que
*selecciono plaza en segunda fase
	rename orde_preferencia orden_preferencia
	isid documento listas_plazas
	gen fase=2

	append using `select1'
	sort documento fase orden_preferencia
	
	by documento: gen orden=_n

	duplicates report documento listas_plazas
	duplicates tag documento listas_plazas, gen(x)
	*hay postulantes que definieron la misma lista en fase 1 y fase2, tomaré el máximo
	*porque si fueron asignados fue a la segunda fase
	
	egen orden1=max(orden), by(documento listas_plazas)
	gsort documento orden1 -orden
	duplicates drop documento orden1, force
	*hay 135 preferencias que fueron las mismas en primera y en segunda fase

	merge 1:1 documento listas_plazas using "$concurso15\4a_Evaluados_etapa_descentralizada_2015.dta" 
	
	drop if _m==1 //preferencias sin asignar
	
	recode orden (6/12=6), gen(cat_ordenpref)
	label var cat_ordenpref "Categorías de orden de preferencia de postulante"
	label def cat_ordenpref 6 "6 a 12"
	label val cat_ordenpref cat_ordenpref
	
	rename codigo_modular cod_mod
	
	merge m:1 cod_mod using "$directory_e\Data\2_IIEE Level\1_Padrón Completo UPP\padron_UPP_201611.dta", gen(pad) ///
	keepusing(d_cod_car cod_car niv_mod d_niv_mod nivel d_nivel rural)
	drop if pad==2
	drop pad _m
	
	label def nivel 1 "Inicial" 2 "Primaria" 3 "Secundaria"
	label val nivel nivel
	
	gen puntaje_fin=pje_final
	replace puntaje_fin="" if puntaje_fin=="-"
	destring puntaje_fin, replace
	
	gen pun_obs=pje_observacion
	replace pun_obs="" if pun_obs=="-"
	replace pun_obs="" if pun_obs=="NO SE PRESENTÓ"
	destring pun_obs, replace
	
	gen pun_ent=pje_entrevista
	replace pun_ent="" if pun_ent=="-"
	replace pun_ent="" if pun_ent=="NO SE PRESENTÓ"
	destring pun_ent, replace
	
	gen pun_tray=pje_trayectoria
	replace pun_tray="" if pun_tray=="-"
	destring pun_tray, replace
	
	egen pun_des=rowtotal (pun_obs pun_ent pun_tray)
	
	gsort listas_plazas -pun_des
	by listas_plazas: gen ord_des=_n
	
	recode ord_des (10/15=10) (16/20=11), gen(cat_orddes)
	label var cat_orddes "Categorías de orden de descentralizado por listasplaza"
	label def cat_orddes 10 "10 a 15" 11 "16 a 20"
	label val cat_orddes cat_orddes
		
	
	merge m:1 documento using "$concurso15\1a_Evaluados_etapa_nacional_2015.dta", ///
	gen(pun) keepusing(sexo discapacidad licenciado_ffaa fecha_nac edad exp_publica ///
	exp_privada nombre_ins ins univ nombre_univ procedencia grupo_de_inscripción ///
	puntaje_sp1_ct puntaje_sp2_rl puntaje_sp3_cc puntaje_pun situacion_pun selec_plaza_ebr )
	drop if pun==2
	drop pun
	
	
	gsort listas_plazas -puntaje_pun
	by listas_plazas: gen orden_centr=_n
	
	recode orden_centr (10/15=10) (16/20=11), gen(cat_ordcent)
	label var cat_ordcent "Categorías de orden de centralizado por listasplaza"
	label val cat_ordcent cat_orddes
	
	tab nivel cat_ordenpref
	
	tab d_cod_car cat_ordenpref if cod_car!="a"	
	
	tab rural cat_ordenpref ,m
	
	graph box pun_des , noout ///
		ytitle("Puntaje Descentralizado") title("Puntaje Descentralizado 2015", position(12)) ///	
		graphregion(color(white)) ///
		caption(Fuente: Concurso de nombramiento 2015, size(small) position(7)) 
	graph export "$output\pun_desc.png", replace
			
	tabstat pun_des, stat(mean count) by(nivel)
	
	tabstat pun_des if cod_car!="a"	, stat(mean count) by(d_cod_car)	
	tabstat pun_des, stat(mean count) by(rural) m
	
	tab  cat_orddes cat_ordenpref
	tab  cat_orddes cat_ordcent
	tab  cat_ordcent cat_ordenpref
