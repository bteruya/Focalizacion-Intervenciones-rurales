	global ruta D:\BRENDA-documentos\OneDrive - Inter-American Development Bank Group\Trabajo BID-onedrive\docentes\simulaciones\Calculos\Dofiles\BID -dofiles
	do "$ruta\rutas_mat.do"
	cd "$directory_b"
	use output\balance_ebr, clear

	xtile ise_xt=pobrezaENAHO2015, nq(5)
	label def nse_xt 1 "muy bajo" 2 "bajo" 3 "medio" 4 "alto" 5 "muy alto"
	label val ise_xt  nse_xt
	label var ise_xt "NSE"

	gen n_doc_balance_nombrado=n_doc_nombrado-n_doc_req_entero
	
	graph box n_doc_balance_nombrado , over(ise_xt, total) noout ///
	ytitle("# de docentes requeridos por escuela", size(medsmall)) title("Distribución de requerimiento de docentes nombrados según NSE, 2017", position(12) size(medium)) ///	
	 graphregion(color(white)) ///
	caption(Fuente: Elaboración propria con datos NEXUS y SIAGIE, size(small) position(7)) ///
	note(Nota: Se exluyen los valores extremos, size(small) position(7))   	

	graph export "$graph_b\balance_nse.png", replace
	
	
	graph bar (sum) n_doc_balance_nombrado , over (d_dpto,  label(angle(45)) sort(pobrezaENAHO2015) )	///
	ytitle("# de docentes balance por escuela", size(medsmall)) title("Total de requerimiento de docentes nombrados por región, 2017", position(12) size(medlarge)) 	///	
	graphregion(color(white))	///
	caption("Fuente: Elaboración propria con datos SIAGIE y Nexus" ///
	"Nota: Departamentos ordenados de menor a mayor pobreza", size(small) position(7)) 

	graph bar (sum) n_doc_balance_nombrado , over (nivel, total )	///
	ytitle("# de docentes balance por escuela", size(medsmall)) title("Total de requerimiento de docentes nombrados por nivel, 2017", position(12) size(medlarge)) 	///	
	graphregion(color(white))	///
	caption(Fuente: Elaboración propria con datos SIAGIE y Nexus, size(small) position(7)) 

	graph bar (sum) n_doc_balance_nombrado , over (d_dpto,  label(angle(45)) sort(matri2017) )	///
	ytitle("# de docentes balance por escuela", size(medsmall)) title("Total de requerimiento de docentes nombrados por región, 2017", position(12) size(medlarge)) 	///	
	graphregion(color(white))	///
	caption("Fuente: Elaboración propria con datos SIAGIE y Nexus" ///
	"Nota: Departamentos ordenados de menor a mayor matrícula", size(small) position(7)) 
	
	graph bar (sum) n_doc_balance_nombrado if cod_car!=0 & cod_car!=4, over (cod_car, total  )	///
	ytitle("# de docentes balance por escuela", size(medsmall)) title("Total requerimiento de docentes nombrados por característica" ///
	"de enseñanza, 2017", position(12) size(medlarge)) 	///	
	graphregion(color(white))	///
	caption(Fuente: Elaboración propria con datos SIAGIE y Nexus, size(small) position(7)) 
********************************************************************************
	*GRAFICOS 1.1
global concurso "$insumo_e\Concurso Nombramiento"
global concurso15 "$concurso\DIED\2015"
global concurso17 "$concurso\DIED\2017"

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
	duplicates report listas_plazas
	duplicates tag listas_plazas, gen(x)
	tab x
	duplicates drop listas_plazas, force
	tab x
	*se van 2,887 obs de un total de 19,630, es decir el 14.7%
	
	rename COD_MOD cod_mod
	gen n_plaza=1
	collapse (sum) n_plaza ,by(cod_mod)
	
	merge 1:1 cod_mod using output\balance_ebr
	*drop if _m==2
	*replace n_doc_balance_entero=0 if _m==1
	
	xtile ise_xt=pobrezaENAHO2015, nq(5)
	label def nse_xt 1 "muy bajo" 2 "bajo" 3 "medio" 4 "alto" 5 "muy alto"
	label val ise_xt  nse_xt
	label var ise_xt "NSE"

	gen n_doc_balance_nombrado=n_doc_nombrado-n_doc_req_entero
	*replace n_doc_balance_nombrado=0 if _m==1
	gen n_nomb=-n_doc_balance_nombrado

	graph bar (sum) n_nomb n_plaza, over (d_dpto,  label(angle(45)) sort(pobrezaENAHO2015) )	///
	ytitle("# de docentes", size(medsmall)) title("Total de requerimiento de docentes nombrados y plazas ofertadas" ///
	"por región", position(12) size(medlarge)) 	///	
	graphregion(color(white)) ///
	legend(label(1 "faltantes norma 2017") label(2 "plazas ofertadas 2015")) ///
caption("Fuente: Elaboración propria con datos SIAGIE y Nexus" ///
	"Nota: Departamentos ordenados de menor a mayor pobreza", size(small) position(7)) 

	graph bar (sum) n_nomb n_plaza, over (d_dpto,  label(angle(45)) sort(matri2017) )	///
	ytitle("# de docentes", size(medsmall)) title("Total de requerimiento de docentes nombrados y plazas ofertadas" ///
	"por región", position(12) size(medlarge)) 	///	
	graphregion(color(white)) ///
	legend(label(1 "faltantes norma 2017") label(2 "plazas ofertadas 2015")) ///
caption("Fuente: Elaboración propria con datos SIAGIE y Nexus" ///
	"Nota: Departamentos ordenados de menor a mayor matrícula", size(small) position(7)) 

	graph bar (sum) n_nomb n_plaza, over (ise_xt,  label(angle(45))  )	///
	ytitle("# de docentes", size(medsmall)) title("Total de requerimiento de docentes nombrados y plazas ofertadas" ///
	"por NSE", position(12) size(medlarge)) 	///	
	graphregion(color(white)) ///
	legend(label(1 "faltantes norma 2017") label(2 "plazas ofertadas 2015")) ///
	caption("Fuente: Elaboración propria con datos SIAGIE y Nexus" ///
	, size(small) position(7)) 	
		
	graph bar (sum) n_nomb n_plaza, over (nivel  )	///
	ytitle("# de docentes", size(medsmall)) title("Total de requerimiento de docentes nombrados y plazas ofertadas" ///
	"por nivel", position(12) size(medlarge)) 	///	
	graphregion(color(white)) ///
	legend(label(1 "faltantes norma 2017") label(2 "plazas ofertadas 2015")) ///
	caption("Fuente: Elaboración propria con datos SIAGIE y Nexus" ///
	, size(small) position(7)) 		
	
	graph bar (sum) n_nomb n_plaza if cod_car!=0 & cod_car!=4, over (cod_car  )	///
	ytitle("# de docentes", size(medsmall)) title("Total de requerimiento de docentes nombrados y plazas ofertadas" ///
	"por característica de enseñanza", position(12) size(medlarge)) 	///	
	graphregion(color(white)) ///
	legend(label(1 "faltantes norma 2017") label(2 "plazas ofertadas 2015")) ///
	caption("Fuente: Elaboración propria con datos SIAGIE y Nexus" ///
	, size(small) position(7)) 		

	graph bar (sum) n_nomb n_plaza , over (area_censo  )	///
	ytitle("# de docentes", size(medsmall)) title("Total de requerimiento de docentes nombrados y plazas ofertadas" ///
	"por área geográfica", position(12) size(medlarge)) 	///	
	graphregion(color(white)) ///
	legend(label(1 "faltantes norma 2017") label(2 "plazas ofertadas 2015")) ///
	caption("Fuente: Elaboración propria con datos SIAGIE y Nexus" ///
	, size(small) position(7)) 		

********************************************************************************
	*GRÁFICOS 2
	*2.1
	