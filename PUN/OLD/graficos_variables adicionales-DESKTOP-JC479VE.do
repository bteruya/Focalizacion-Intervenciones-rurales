*este dofile crea variables adicionales que se usarán en el análisis de preferencias
	global ruta D:\BRENDA-documentos\OneDrive - Inter-American Development Bank Group\Trabajo BID-onedrive\docentes\simulaciones\Calculos\Dofiles\BID -dofiles
	do "$ruta\rutas_mat.do"
	cd "$directory_b"
	global concurso "$insumo_e\Concurso Nombramiento"
	global concurso15 "$concurso\DIED\2015"
	global concurso17 "$concurso\DIED\2017"
	global output "$esw\calculos\graficos\output plazas"
********************************************************************************
********************************************************************************
********************************************************************************
****************************************************************************
	*codmod en el que trabajaban durante 2015
	use "$concurso15\1a_Evaluados_etapa_nacional_2015.dta", clear
	isid documento
	
preserve

	use "$nexus_bid\Nexus_2015_bid.dta", clear
	rename CodigoModular cod_mod

	rename DNI documento
	duplicates tag documento, gen(x)
	tab x
	codebook documento if x==5403
	drop if documento=="        "
	//los que no tienen DNI
	drop if documento=="15151515" //este dni no existe y no está en la bd evaluados
	*me quedare con la IE donde trabaje mas horas
	gsort documento -JornadaLaboral
	duplicates drop documento, force
	drop x
	tempfile nexus_dni
	save `nexus_dni', replace


restore
	merge 1:1 documento using `nexus_dni'
	*ver el merge:
	sort documento
	br documento _m if _m!=3
	
	rename _m nexus
	label drop _merge
	label def nexus 1 "No Nexus" 2 "No concurso" ///
	3 "Concurso y Nexus"
	label val nexus nexus
	codebook nexus
	drop if nexus==2
	label var nexus "Postulante presente en Nexus 2015"
	
	tab SituacionLaboral nexus,m
	*keep contrat cod_mod documento SituacionLaboral
	rename cod_mod codmod_previo
	label var codmod_previo "La IE en la que trabajaba el postulante en 2015"
	tab ganador nexus,m
	tab  SituacionLaboral ganador if nexus==3
	
	label data "Data a nivel de DNI que muestra el cod_mod en el que el docente trabajó en 2015"
	save "$output\codmod_previo_dni.dta", replace
	
****************************************************************************
****************************************************************************
	*distancias de IE a provincia
	import excel using "$esw\calculos\mapa distancias ESW\output\distancias_ie prov.xlsx", sheet("Hoja1") firstrow clear

	tostring InputID, gen(cod_mod) format(%07.0f)
	tostring TargetID, gen(prov_cod) format(%04.0f)
	
	merge 1:1 cod_mod using "$data\2_IIEE Level\1_Padrón Completo UPP\padron_UPP_201611.dta" ///
	,gen(dist)
	label var dist "tiene coordenadas"
	label def dist 2 "Sin coordenadas" 3 "Con coordenadas"
	label val dist dist
	
	tab nlat if dist==2 //todos ceros, porque no tienen coordenadas 1551 ie sin coordenadas
	label var Distance "Distancia del codmod a la capital de provicia (Qgis)"
	
	*chequear distancias
	
	tabstat Distance , by(d_areasig) stat(mean)
	tabstat Distance , by(d_areasig) stat(min mean max) //lo rural está más lejos

	tabstat Distance , by(rural) stat(min mean max) //lo rural 1 está más lejos
	
	correl Distance tiempo_ugel
	
	save "$esw\calculos\mapa distancias ESW\output\Distancia_ie_padron.dta", replace
	
********************************************************************************
********************************************************************************
*STUDENT TEACHER RATIO

*number of students
	use "input\SIAGIE 2013-2017\data_2015", clear	
	duplicates report id_persona
	duplicates report id_persona fecha_registro //cuando vemos la fecha ne la que la persona 
	gsort id_persona -fecha_registro
	duplicates tag id_persona, gen(dupli_persona)
	tab dupli_persona
	
	by id_persona: gen unique=_n //ya esta ordenado, de la fecha mas reciente a la mas antigua
	*unique sera 1 cuando sea la fecha mas reciente
	keep if unique==1
	*nos quedamos con los de la fecha de registro mas reciente, si la fecha de registro es la misma (44 casos)
	*es aleatorio

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
	
	keep year id_persona grado cod_mod id_seccion
	
	tostring id_persona, replace format(%08.0f)
	tostring cod_mod, replace format(%07.0f)
	
	
	save "$output\siagie_2015.dta", replace 
	
	
	use "$output\siagie_2015.dta",clear
	gen matri_ef2015_ = 1
	tostring cod_mod, replace format(%07.0f)
	
	rename id_seccion n_sec
	
	collapse (sum) matri_ef2015_ (max) n_sec, by(grado cod_mod)
	label data "Secciones y matricula por grado y codmod"
	save "$output\secc_efectiva_2015_b", replace
	
	use  "$output\secc_efectiva_2015_b", clear
	collapse (sum) n_sec2015=n_sec matri_tot2015=matri_ef2015_ , by(cod_mod)
	tab n_sec2015
	label var n_sec2015 "total de secciones por codmod 2015 (SIAGIE)"
	label var matri_tot2015 "total de matricula por codmod 2015 (SIAGIE)"
	label data "Secciones y matricula por codmod 2015 SIAGIE"
	save "$output\secc_efectiva_codmod_2015_b", replace
	
	*----------------------------------------------------------------------
	*numero de docentes 2015
	
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
	drop  if _m==2
	drop _m 
	
	gen docente= SubtipodeTrabajador ==2
	replace docente=1 if cod_car=="1" & SubtipodeTrabajador==1 
	*los directores unidocentes
	keep if docente==1
	gen n_doc=1
	decode Nivel, gen(nivel_nexus)
	
	collapse (sum) n_doc2015=n_doc (first) nivel_nexus , by(cod_mod)
	label var n_doc2015 "n docentes de c/codmod 2015-Nexus"
	save "$output\n_doc2015", replace
	
	use  "$output\secc_efectiva_codmod_2015_b", clear
	merge 1:1 cod_mod using "$output\n_doc2015"
	replace n_doc2015=0 if _m==1 //sin docentes
	replace matri_tot2015 =0 if _m==2 //sin matricula
	gen fuente=_m
	label def fuente 3 "Nexus-Siagie" 2 "solo Nexus" 1 "solo Siagie"
	label val fuente fuente
	label var fuente "De qué bd proviene la data"
	drop _m
	
	
	
	merge 1:1 cod_mod using "$directory_e\Data\2_IIEE Level\1_Padrón Completo UPP\padron_UPP_201611.dta", gen(padron)
	drop if padron==2
	label def padron 1 "No en Padrón" 3 "Sí en padrón"
	label val padron padron
	label var padron "Presente en padrón"
	
	tabstat matri2015 , stat(sum) by(fuente)
	tabstat doc_t , stat(sum) by(fuente)
	tabstat doc_t if fuente==1, stat(sum) by(d_niv_mod)
	correl doc_t n_doc2015
	correl matri2015 matri_tot2015
	label data "Matrícula SIAGIE y Profesores Nexus 2015, junto con Padrón 2016"
	save "$output\alumnos_docentes_codmod", replace
********************************************************************************
********************************************************************************
********************************************************************************
********************************************************************************
*georeferenciación de universidades
 import excel "$data\GIS\georeferencia de universidades.xlsx", sheet("base") ///
 cellrange(B4:K675) firstrow clear
 
	replace Latitud="" if Latitud=="N.D."
	replace Longitud="" if Longitud=="N.D."
	*la universidad peruana los andes tiene latitud pero no longitud
	
export delimited using "$data\GIS\georeferencia de universidades_csv.csv", replace

	duplicates report Códigomodular //46 tiene un solo local
	duplicates report Institución //igual que codmod
	duplicates report Dirección //
	duplicates tag Dirección, gen(dire)
	duplicates report Dirección Institución
	duplicates report Dirección Institución Descripciónlocal
		
	*hasta que decida como tomar estas duplicates, hare el merge por nombre
	duplicates drop Institución, force
	gen nombre_univ=Institución
	replace nombre_univ = subinstr(nombre_univ," ","",.) 	
	replace nombre_univ = lower(nombre_univ)
	count
	replace nombre_univ = subinstr(nombre_univ,"á","a",.) 	
	replace nombre_univ = subinstr(nombre_univ,"é","e",.) 	
	replace nombre_univ = subinstr(nombre_univ,"í","i",.) 	
	replace nombre_univ = subinstr(nombre_univ,"ó","o",.) 	
	replace nombre_univ = subinstr(nombre_univ,"ú","u",.) 	
	
	replace nombre_univ = subinstr(nombre_univ,"Á","a",.) 	
	replace nombre_univ = subinstr(nombre_univ,"É","e",.) 	
	replace nombre_univ = subinstr(nombre_univ,"Í","i",.) 	
	replace nombre_univ = subinstr(nombre_univ,"Ó","o",.) 	
	replace nombre_univ = subinstr(nombre_univ,"Ú","u",.) 	
	
	replace nombre_univ ="universidadprivadacesarvallejo" if nombre_univ=="universidadcesarvallejo"
	
	tempfile univ_coord
	save `univ_coord'


	use "$concurso15\1a_Evaluados_etapa_nacional_2015.dta", clear
	*probando hasta que decida
	duplicates drop nombre_univ, force
	count //hay 153, algunas universidades son de otros paises 
	gen nombre_univ1= nombre_univ
	replace nombre_univ = subinstr(nombre_univ," ","",.) 	
	replace nombre_univ = lower(nombre_univ)
	
	
	merge 1:1 nombre_univ using `univ_coord'
*QUEDAN las extranjeras y unos cuantos seminarios
	
	save "$output\univ_coordenadas.dta", replace
	
	/*solo se hace una vez*/
	/*
	use "$output\univ_coordenadas.dta", clear
	keep if _m==1
	keep nombre_univ nombre_univ1 Institución _merge
	export excel using "$output\univ_coordenadas_falta.xlsx", firstrow(variables) replace
	*/
	*se ponen las coordenadas y el país a mano en excel
	 
	import excel "$output\univ_coordenadas_falta_lleno.xlsx", sheet("Sheet1") ///
		firstrow clear
		drop Institución
	gen fuente="concurso only"
	drop _m
	codebook latitud
	tab pais if latitud=="",m

		merge 1:1 nombre_univ using "$output\univ_coordenadas.dta",gen(x)
		drop x
		replace Latitud=latitud if _m==1 //la nueva latitud de google
		replace Longitud = longitud if _m==1
		label var latitud "Latitud obtenida de google para los que faltaban"
		label var longitud "Longitud obtenida de google para los que faltaban"
		label var Latitud "Latitud obtenida de MINEDU"
		label var Longitud "Longitud obtenida de MINEDU"
		replace pais="peru" if _m==3
		drop if _m==2
	
		replace Latitud="" if Latitud=="no"
		replace Longitud="" if Longitud=="no"
		
	save "$output\univ_coordenadas_total.dta", replace
		
	use "$output\univ_coordenadas_total.dta",clear
	keep if _m==3
	tempfile univ_merge3
	save `univ_merge3'
	
	import excel "$data\GIS\georeferencia de universidades.xlsx", sheet("base") ///
	cellrange(B4:K675) firstrow clear
	merge m:1 Institución using `univ_merge3', gen(x)
	drop if x==1 //univ sin profesores estudiantes
	
	keep Códigomodular Institución Dirección Provincia Distrito Latitud Longitud ///
	Descripciónlocal nombre_univ nombre_univ1 pais latitud longitud fuente id _merge x
	sort Institución
	export excel using "$output\georereferencia univ match.xlsx", firstrow(variables) replace
	
	*----------------------------------------------------------------------------
	*cheuqeuamos que el merge esté bien hecho
	import excel using "$output\georereferencia univ match_educacion.xlsx", firstrow clear
	keep if educacion=="si" //solo las facultades de educacion de las personas
	duplicates report nombre_univ educacion
	duplicates tag nombre_univ educacion, gen(dupli_facu)
	
	tab nombre_univ1 if dupli_facu>0
	*hay 5 universidades con mas de una facultad de educacion
	duplicates drop nombre_univ educacion , force //haremos el merge pero luego 
	*borramos la coordenada de los duplicados poruqe no estamos seguros de que sea 
	*la region correcta 
	codebook Latitud
	keep nombre_univ educacion dupli_facu Latitud Longitud
	merge 1:1 nombre_univ using "$output\univ_coordenadas_total.dta", gen(educ) ///
	keepusing(nombre_univ nombre_univ1 pais fuente latitud longitud _m Latitud Longitud)
	
	tab _merge educ
	tab nombre_univ1 if _m==3 & educ==2 //los que si hacen match pero se perdieron al hacer las facultades
	*ya se donde queda la facultad de educación de la universidad catolica los angeles de chimbote, he mandado un email
	
	codebook Latitud
	tab nombre_univ1 if Latitud==""
	tab pais if Latitud==""
	tab nombre_univ1 if Latitud=="" & pais=="peru"
		
	*se hace match perfecto
	
	*perderé 6 facultades de educación que están en varios lugares
	codebook Latitud if _m==1
	*entre universidades extranjeras y seminarios pierdo 69/80 lugares
	codebook Latitud if _m==1 & pais!="peru"
	*hay 61/69 seminarios que no se tienen coordenadas
	
	codebook nombre_univ1 if pais=="" //todo vacío
	drop if pais=="" //la que no tiene nombre de universidad, ie los institutos
	
	keep nombre_univ educacion dupli_facu nombre_univ1 pais latitud fuente Latitud Longitud 
	
	tempfile univ_final
	save  `univ_final'
	
	
	use "$concurso15\1a_Evaluados_etapa_nacional_2015.dta", clear
	
	drop if procedencia=="Solo INS" //nos quedamos con los que han estudiado en la universidad
	
	
	count //hay 153, algunas universidades son de otros paises 
	gen nombre_univ1= nombre_univ
	replace nombre_univ = subinstr(nombre_univ," ","",.) 	
	replace nombre_univ = lower(nombre_univ)
	
	
	merge m:1 nombre_univ using `univ_final'
	*match perfecto, listo
	
	tab nombre_univ1 if Latitud==""
	drop if _m==2 //registro vacío
	 tab pais if Latitud==""
	tab nombre_univ1 if Latitud=="" & pais=="peru"
	
	replace Latitud="" if dupli_facu>0 & dupli_facu!=.
	tab nombre_univ1 if Latitud=="" & pais=="peru"
	
	tab pais if Latitud=="" &  situacion_pun=="Clasificado"

	tab nombre_univ1 if Latitud=="" &  situacion_pun=="Clasificado" & pais=="peru"
		
	keep id tipo_doc documento dupli_facu Latitud Longitud nombre_univ*
	
	gen ranking=.
	replace ranking=1 if nombre_univ=="pontificiauniversidadcatolicadelperu"
	replace ranking=2 if nombre_univ=="universidadperuanacayetanoheredia"
	replace ranking=3 if nombre_univ=="universidadnacionalmayordesanmarcos"
	replace ranking=4 if nombre_univ=="universidadnacionalagrarialamolina"
	replace ranking=5 if nombre_univ=="universidadnacionaldeingenieria"
	replace ranking=6 if nombre_univ=="universidadnacionaldesanantonioabaddelcusco"
	replace ranking=7 if nombre_univ=="universidadnacionaldetrujillo"
	*8 uni cientifica del sur, no tiene profesores de ahí
	replace ranking=9 if nombre_univ=="universidaddepiura"
	*10 u. del pacifico, no tiene profesores
	replace ranking=11 if nombre_univ=="universidadnacionaldelaltiplano"
	*12 universidad peruana de ciencias, no tiene profesores
	replace ranking=13 if nombre_univ=="universidadnacionaldelaamazoniaperuana"
	replace ranking=14 if nombre_univ=="universidaddesanmartindeporres"
	
	*15 u de lima no tiene profes
	replace ranking=16 if nombre_univ=="universidadnacionaldesanagustin"
	*17 esan no tiene profes
	replace ranking=18 if nombre_univ=="universidadricardopalma"
	replace ranking=19 if nombre_univ=="universidadcatolicasanpablo"
	replace ranking=20 if nombre_univ=="universidadsanignaciodeloyola"
	replace ranking=21 if nombre_univ=="universidadnacionalfedericovillarreal"
	replace ranking=22 if nombre_univ=="universidadnacionaldepiura"
	replace ranking=23 if nombre_univ=="universidadcatolicadesantamaria"
	replace ranking=24 if nombre_univ=="universidadnacionalpedroruizgallo"
	replace ranking=25 if nombre_univ=="universidadprivadaantenororrego"
	replace ranking=26 if nombre_univ=="universidadnacionaldelcallao"
	replace ranking=27 if nombre_univ=="universidadalasperuanas"
	replace ranking=28 if nombre_univ=="universidadnacionaldetumbes"
	*29 u. la salle no hay profes
	*30 u. san juan bautista, no hay profes
	
	replace ranking=31 if nombre_univ=="universidadandinadelcusco"
	*32 u. privada del norte, no tiene profes
	tab ranking, m //80% de personas no tienen ranking


	label data "data a nivel de dni con georreferenciación de universidades y ranking universidades"
	save  "$output\match_uni_dni.dta", replace

********************************************************************************
********************************************************************************
********************************************************************************

use "$concurso15\1a_Evaluados_etapa_nacional_2015.dta", clear
	*probando hasta que decida
	drop if procedencia=="Solo UNIV"
	duplicates drop nombre_ins, force
	count //hay 597 institutos
	gen nombre_ins1= nombre_ins
	replace nombre_ins = subinstr(nombre_ins," ","",.) 	
	replace nombre_ins = lower(nombre_ins)
	codebook nombre_ins*
	
	gen nombre_ins2=nombre_ins

	replace nombre_ins2 = subinstr(nombre_ins2,"á","a",.) 	
	replace nombre_ins2 = subinstr(nombre_ins2,"é","e",.) 	
	replace nombre_ins2 = subinstr(nombre_ins2,"í","i",.) 	
	replace nombre_ins2 = subinstr(nombre_ins2,"ó","o",.) 	
	replace nombre_ins2 = subinstr(nombre_ins2,"ú","u",.) 	
	
	replace nombre_ins2 = subinstr(nombre_ins2,"Á","a",.) 	
	replace nombre_ins2 = subinstr(nombre_ins2,"É","e",.) 	
	replace nombre_ins2 = subinstr(nombre_ins2,"Í","i",.) 	
	replace nombre_ins2 = subinstr(nombre_ins2,"Ó","o",.) 	
	replace nombre_ins2 = subinstr(nombre_ins2,"Ú","u",.) 	
	
	replace nombre_ins2 = subinstr(nombre_ins2,"Ñ","n",.) 	
	
	replace nombre_ins2 = subinstr(nombre_ins2,"-","",.) 	
	gen nombre_ins3=nombre_ins2
	
	
	
	replace nombre_ins2=subinstr(nombre_ins2,"institutodeeducacionsuperiorpedagogica","",.)
	replace nombre_ins2=subinstr(nombre_ins2,"institutosuperiordeeducacion","",.)
	replace nombre_ins2=subinstr(nombre_ins2,"institutopedagogiconacional","",.)
	replace nombre_ins2=subinstr(nombre_ins2,"escuelasuperiordeformacionartistica","",.)
	replace nombre_ins2=subinstr(nombre_ins2,"escuelasuperiordeartedramatico","",.)
	replace nombre_ins2=subinstr(nombre_ins2,"escuelasuperiordeartepublica","",.)
	replace nombre_ins2=subinstr(nombre_ins2,"institutodeeducacionsuperiortecnologico","",.)
	replace nombre_ins2=subinstr(nombre_ins2,"escuelasuperiorautonomade","",.)
	replace nombre_ins2=subinstr(nombre_ins2,"institutosuperiordemusica","",.)
	replace nombre_ins2=subinstr(nombre_ins2,"conservatorioregionaldemusicadelnortepublico","",.)
	replace nombre_ins2=subinstr(nombre_ins2,"escuelasuperiordemusica","",.)
	replace nombre_ins2=subinstr(nombre_ins2,"escuelanacionalsuperiordefolklore","",.)
	replace nombre_ins2=subinstr(nombre_ins2,"escuelanacionalsuperiordeartedramatico","",.)
	replace nombre_ins2=subinstr(nombre_ins2,"escuelanacionalsuperiorautonomade","",.)
	replace nombre_ins2=subinstr(nombre_ins2,"convervatorioregionaldemusica","",.)
	replace nombre_ins2=subinstr(nombre_ins2,"escuelasuperior","",.)
	replace nombre_ins2=subinstr(nombre_ins2,"institutosuperiordeestudiosteologicos","",.)
	replace nombre_ins2=subinstr(nombre_ins2,"institutotecnologicode","",.)
	replace nombre_ins2=subinstr(nombre_ins2,"institutodeformacionprofesionales","",.)
	*no sé que es istpa :(
	replace nombre_ins2=subinstr(nombre_ins2,"institutodeartedelauniversidad","",.)
	replace nombre_ins2=subinstr(nombre_ins2,"institutosuperiortecnologico","",.)
	replace nombre_ins2=subinstr(nombre_ins2,"institutotecnicosuperior","",.)
	replace nombre_ins2=subinstr(nombre_ins2,"institutotecnologicosuperiorprivado","",.)
	replace nombre_ins2=subinstr(nombre_ins2,"istecnologicopublico","",.)
	replace nombre_ins2=subinstr(nombre_ins2,"ist","",.)
	replace nombre_ins2=subinstr(nombre_ins2,"institutosuperiortegnologicopublico","",.)
	replace nombre_ins2=subinstr(nombre_ins2,"institutodeeducacionsuperiortecnologica","",.)
	replace nombre_ins2=subinstr(nombre_ins2,"institutotecnologicopublico","",.)
	replace nombre_ins2=subinstr(nombre_ins2,"institutodeeducaciontecnologicoprivado","",.)
	replace nombre_ins2=subinstr(nombre_ins2,"institutotecnologico","",.)
	replace nombre_ins2=subinstr(nombre_ins2,"institutosuperiorpedagogico","",.)
	replace nombre_ins2=subinstr(nombre_ins2,"institutodeeducacionsecundaria","",.)
	
	gen nom_niv=substr(nombre_ins3,1,strlen(nombre_ins3)-strlen(nombre_ins2))
	
export excel nombre_ins* using "$output\ins_nomb.xlsx", sheet("concurso1", modify) firstrow(variables) 
	duplicates tag nombre_ins2, gen(dupli_concur)
	tab dupli_concur
	duplicates report nombre_ins2
	
	
	duplicates drop nombre_ins2, force
	
	tempfile concurso_ins
	save  `concurso_ins' //los institutos que existen en el concurso

		
	 import excel "$data\GIS\data_iiee superior no universitaria.xlsx", ///
	 sheet("data_iiee") firstrow clear
		isid CodModular
		codebook NomIIEE //los nombre de las coordenadas son más cortos y están incluidos
		*en el concurso
		*hare un buscar en excel
		gen nombre_ins2=""
		replace nombre_ins2 = subinstr(NomIIEE," ","",.) 	
		replace nombre_ins2 = lower(nombre_ins2)
	replace nombre_ins2 = subinstr(nombre_ins2,"Ñ","n",.) 	
	replace nombre_ins2 = subinstr(nombre_ins2,"-","",.) 	

	codebook nombre_ins2
		tempfile coord_previo
		save `coord_previo'
		
	export excel NomIIEE nombre_ins2 CodModular using "$output\ins_nomb.xlsx", sheet("coordenadas1", modify) firstrow(variables) 
		duplicates tag nombre_ins2, gen(dupli_iiee)
		
		
		duplicates drop nombre_ins2, force
		merge 1:1 nombre_ins2 using  `concurso_ins'
	tempfile match_primero
	save `match_primero', replace
	
	use  `match_primero', clear
	
	keep if _m==3	
	
	export excel NomIIEE nombre_ins* CodModular Departamento Provincia Distrito ///
	region_evaluado Latitud Longitud dupli* ///
	using "$output\ins_nomb.xlsx", sheet("match3", modify) firstrow(variables) 
	
	*ya vimos que están todos los match bien
	*el problema es con los duplicados, tenemos que ver qué hacer con esos
	
	
	
	
	use  `match_primero', clear
	
	
	egen dupli=rowtotal( dupli*)	
		
	keep if _m==3 & dupli!=0	
		
		
	export excel NomIIEE nombre_ins* CodModular Departamento Provincia Distrito ///
	region_evaluado Latitud Longitud dupli* ///
	using "$output\ins_nomb.xlsx", sheet("match_dupli", modify) firstrow(variables) 
		
	*estos duplicados a veces son por ser pedagógico vs tecnológico, veremos el caso de 
	*cada uno
	
	keep if dupli_iiee!=0 
	keep nombre_ins2 dupli* nom_niv  nombre_ins1 region_evaluado
	merge 1:m nombre_ins2 using `coord_previo', gen(x_dupli)
	keep if x_dupli==3
	isid CodModular	
	tab nom_niv
	tab Nivel
	
	tab  Nivel nom_niv
	duplicates report nombre_ins2
	duplicates report nombre_ins2 dupli_iiee
	duplicates report CodModular
	encode nom_niv, gen(niv_concurso)
	encode Nivel, gen(niv_iiee)
	codebook niv_*
	
	br if niv_concurso==2 & niv_iiee==3
	*estos son los pedagógicos en el concurso que dicen ser tecnológicos en las coordenadas
	*estos están mal en el match porque no son los correctos, los botaré!
	drop if niv_concurso==2 & niv_iiee==3
	duplicates report nombre_ins2
	sort nombre_ins2 
	duplicates tag nombre_ins2, gen(dupli_nom2)
	br if dupli_nom2!=0
	
	preserve
	
	keep if dupli_nom2==0
	*keep nombre_ins2 CodModular
	tempfile match_pedago_tech
	save `match_pedago_tech', replace
	
	
	
	restore
		
		
	keep if dupli_nom2!=0	
	tab niv_concurso niv_iiee
	
	
	export excel region_evaluado nombre_ins2 dupli_iiee nombre_ins1 nom_niv dupli_concur dupli ///
	Ubigeo Departamento Provincia Distrito Localidad CodModular NomIIEE Nivel ///
	GesDep dupli_nom2 niv_iiee niv_concurso  ///
	using "$output\ins_nomb.xlsx", sheet("match3_round2", modify) firstrow(variables) 
		
		
	import excel using 	"$output\ins_nomb.xlsx", sheet("match3_round2_lleno") firstrow clear
	keep if nivel_match==1
	append using `match_pedago_tech', force
		
		
	isid nombre_ins2	
		
	save `match_pedago_tech', replace
	
	use  `match_primero', clear
	keep if dupli_iiee==0	
		
	append using `match_pedago_tech'	
	duplicates report nombre_ins2
	tempfile match3_compl
	save  `match3_compl'

	
	use  `match_primero', clear
	drop if _m==3 //ahora veremos los que no hicieron merge
	sort nombre_ins2
	
	drop id tipo_doc documento apellido_paterno apellido_materno nombres sexo ///
	discapacidad licenciado_ffaa fecha_nac edad grupoedad exp_publica ///
	exp_pub_rangos exp_privada exp_priv_rangos codgrupo grupo_de_inscripción ///
	mod puntaje_sp1_ct puntaje_sp2_rl puntaje_sp3_cc puntaje_pun situacion_pun ///
	selec_plaza_ebr region_selec con_asigna_plaza_ebr puntaje_plaza_ganador ganador
	
	
	export excel nombre_ins2 NomIIEE nombre_ins1 _merge CodModular ///
	using "$output\ins_nomb.xlsx", sheet("match2", modify) firstrow(variables) 

	
	
	
		
****************************************************************************
****************************************************************************
*ALTITUD!!!!!
import delimited "$esw\calculos\altitud\altitud_ie_final.csv", case(preserve) clear		
	replace cod_mod= subinstr(cod_mod,",","",.) 	
	destring cod_mod, replace
	tostring cod_mod, replace format(%07.0f)
	
	merge 1:1 cod_mod using "$directory_e\Data\2_IIEE Level\1_Padrón Completo UPP\padron_UPP_201611.dta", gen(x) keepusing(anexo)
	//1551 codmod sin coordenadas (eso ya lo sabíamos)
	drop if x==2
	drop x 
	
	tempfile altura_2016
	save `altura_2016', replace
	
	
use  "$directory_e\Data\2_IIEE Level\1_Padrón Completo UPP\padronhyperdeluxe201711.dta", clear
	keep if anexo==0
	merge 1:1 cod_mod using `altura_2016'
	//hay algunos ie que estan en 2017 pero no 2016: 7272
	*otros que estan en 2016 pero desaparecen luego: 16
	correl alt_cp PER_alt
****************************************************************************
****************************************************************************
*centroide, centro de masa
*solo para aquellos que tienen preferencias
/*
	use "$concurso15\2a_seleccion_listas_primera_fase_2015.dta", clear
	
	gen fase=1	
	
preserve

	use "$concurso15\3a_seleccion_listas_segunda_fase_2015.dta", clear
	
	gen fase=2
		ren desc_region region
		ren desc_dre_ugel dre_ugel
		ren desc_grupo_inscripcion grupo_inscripcion
		ren orde_preferencia orden_preferencia
				
		tempfile fase2
		save `fase2'
restore

	append using `fase2'
	
	save "$concurso15\selec_fase1_fase2.dta", replace

*/
	use "$concurso15\selec_fase1_fase2.dta", clear //append de ele de fase 1 y 2
	rename codigo_modular cod_mod
	isid documento listas_plazas fase
	merge m:1 cod_mod using "$data\2_IIEE Level\1_Padrón Completo UPP\padron_UPP_201611.dta", gen(x) keepusing(nlat_ie nlong_ie)
	drop if x==2
	drop x 

	destring nlat_ie nlong_ie, replace
	*export delimited cod_mod documento nlat_ie nlong_ie ///
	*using "$esw\calculos\distancia set de preferencias\set_preferencias.csv", replace
	
	
	bys documento: egen lat_mean=mean(nlat_ie )
	bys documento: egen long_mean=mean(nlong_ie )	
	label var lat_mean "Latitud del centro de masa de las IE de cada persona"
	label var long_mean "Longitud del centro de masa de las IE de cada persona"
	geodist lat_mean long_mean nlat_ie nlong_ie, gen(dist_set)
	replace dist_set=dist_set*1000
	label var dist_set "Dist. desde la IE hasta el centro de masa de cada persona en mts curva"

	summ dist_set,d
	bys documento: egen dist_set_mean=mean(dist_set )
	bys documento: egen dist_set_dsv=sd(dist_set )	
	label var dist_set_mean "Prom. distancia del set de preferencia x persona en mts curvatura"
	label var dist_set_dsv "Dsv. distancia del set de preferencia x persona en mts curvatura"
	summ dist_set_mean dist_set_dsv,d
	tabstat dist_set_mean dist_set_dsv, stat(min p25 p50 mean p75 max) format(%9.0f)

	gen dist_eucli=sqrt((nlat_ie-lat_mean)^2+(nlong_ie-long_mean)^2 )
	label var dist_eucli "Dist. euclidiana desde IE hasta centro de masa de cada persona en grados"
	
	bys documento: egen var_eucli =mean(dist_eucli^2)
	label var var_eucli "Variabilidad de la dist. euclidiana de la IE al centro de masa x persona"
	
	
	save "$output\dist_ie_centro.dta"
	
	
	
	/*	
	*duplicates drop documento, force
	*export delimited documento lat_mean long_mean ///
	*using "$esw\calculos\distancia set de preferencias\centro_masa.csv", replace
	
	*distancia en minutos
	
	*traveltime, start_x(nlong_ie) start_y(nlat_ie) end_x(long_mean) end_y(lat_mean) km
	*traveltime obsoleto
	
	/*
	net install osrmtime, ///
from("https://www.uni-regensburg.de/wirtschaftswissenschaften/vwl-moeller/forschung/index.html")
.net get osrmtime, ///
from("http://www.uni-regensburg.de/wirtschaftswissenschaften/vwl-moeller/medien/osrmtime")
.shell osrminstall.cmd
	*/
	*dificil de instalar, no encuentro los ado files
	*usaré este otro comando
	*ssc install insheetjson
	*ssc install libjson
	georoute , ///
	hereid("trpWfEUEgFrsiteMAnpC") herecode("29BREGjUAuEyOErLloYH7g") ///
	startxy(nlong_ie nlat_ie) endxy(long_mean lat_mean) ///
	km di(dist) ti(time)
	
	*/
********************************************************************************
********************************************************************************
********************************************************************************
*aula de computación	
use "$data\2_IIEE Level\8_Censo Escolar 2015\Stata\11_local_escolar.dta", clear
codebook p209_1tot
isid codlocal
gen compu=p209_1tot>0
label var compu "Tiene al menos 1 compu operativa de uso pedagogico"
label def compu 0 "Sin compu" 1 "Con compu"
label val compu compu
destring codlocal, replace
keep codlocal compu

tempfile computa
save `computa'


use  "$data\2_IIEE Level\1_Padrón Completo UPP\padron_UPP_201611.dta" , clear
destring codlocal, replace
merge m:1 codlocal using `computa', gen(x)
keep if x==3
keep codlocal compu cod_mod
	save "$output\computadora_codmod.dta"
