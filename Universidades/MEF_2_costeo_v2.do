clear all
set more off

global ruta "C:\Users\analistaup2\Google Drive\Trabajo\MINEDU_trabajo\UPP\Actividades\Focalizacion\Datos\Universidades\01_Estrategia_MEF"
*global ruta "C:\Users\serv_dapt001\Google Drive\MEF\Universidades no licenciadas\01_Estrategia_MEF"

global wt 		cd "$ruta\2. Data\wetransfer-243fc8"
global wt_sd1	cd "$ruta\2. Data\wetransfer-243fc8\06122019"
global wt_sd2	cd "$ruta\2. Data\wetransfer-243fc8\10122019"
global temp 	cd "$ruta\2. Data\2. Temp"
global tabla 	cd "$ruta\3. Tablas"
global etiq		cd "$ruta\1. Insumos\etiqueta estandar"
global pob		cd "$ruta\1. Insumos\pobreza"
global midis 	cd "$ruta\2. Data\midis solicitud"
global precios  cd "$ruta\1. Insumos\precios"

/*______________________________________________________________________________
	1) Precios
______________________________________________________________________________*/
$precios
import excel using "costos_universidades.xlsx", firstrow clear sheet("resumen_vf")
	rename (Concepto CostounitarioomensualS MontoanualizadoS) (concepto costo_semestral costo_anual)
	keep concepto componente costo_semestral costo_anual
	gen cod_concepto = _n
$temp
*save precios, replace

/*______________________________________________________________________________
	2) Cantidades
______________________________________________________________________________*/

*	2.1) Matricula
*******************************************
/*
forval ano = 2017/2019{
forval parte = 1/2{
	$wt
	import excel using "Información solicitada MEF - Matrícula.xlsx", sheet("MATRICULA `ano' - PARTE `parte'") firstrow clear cellrange(A4)
	$temp
	save matricula_`ano'_`parte', replace
}
}
*/

clear
forval ano = 2017/2019{
forval parte = 1/2{
	$temp
	append using matricula_`ano'_`parte', force
	cap gen sheet_ano = `ano'
	replace sheet_ano = `ano' if sheet_ano == .
	count
}
}

*Año de ingreso
gen ano_ingreso = substr(Ciclodeingreso,1,4)
tab ano_ingreso

*Eliminamos posgrado
drop if Facultad == "MAESTRIA"
drop if strpos(Facultad,"MAES")
drop if Facultad == "DOCTORADO"
drop if strpos(Facultad,"POSGRA")
drop if strpos(Facultad,"POST")

drop if strpos(Carrera,"DOCTORADO")
drop if strpos(Carrera,"MS. ")
drop if strpos(Carrera,"MS ")

drop if strpos(Carrera, "SEGUNDA")
drop if strpos(Carrera, "SEG.ESP")
drop if strpos(Carrera, "SEG. ESP")
drop if strpos(Carrera, "SEG ESP")
drop if strpos(Carrera, "MS")
drop if strpos(Carrera, "MAESTRÍA")
drop if strpos(Carrera, "MAEST")
drop if strpos(Carrera, "MAE")

drop if strpos(Carrera,"DOC ") | strpos(Carrera,"DOC.") | strpos(Carrera,"DR.")
drop if strpos(Carrera,"DOC") & strpos(Carrera,"RADO")

                                               *Eliminamos a las IES que no participan de esta evaluación
                                               drop if strpos(Nombredelauniversidad,"PNP" )
                                               drop if strpos(Nombredelauniversidad,"DIPLO" )
                                               drop if strpos(Nombredelauniversidad,"PEDAG" )
                                               drop if strpos(Nombredelauniversidad,"ESCUELA NACIONAL" )
                                               drop if strpos(Nombredelauniversidad,"BELLAS")
                                               drop if strpos(Nombredelauniversidad,"ENA")
                                               drop if strpos(Nombredelauniversidad,"ESFA")
                                               drop if strpos(Nombredelauniversidad,"MUSICA")
                                               drop if strpos(Nombredelauniversidad,"E.S.F.A.")
                                               drop if strpos(Nombredelauniversidad,"ESADT")
                                               drop if strpos(Nombredelauniversidad,"ENSAD")
                                               drop if strpos(Nombredelauniversidad,"ENSABAP")
                                               drop if strpos(Nombredelauniversidad,"CRM")
                                               drop if strpos(Nombredelauniversidad,"ESM")
                                               drop if strpos(Nombredelauniversidad,"INST")
                                               drop if strpos(Nombredelauniversidad,"TEOLO")
                                               drop if strpos(Nombredelauniversidad,"UCSANJOSÉ")
                                               drop if strpos(Nombredelauniversidad,"ENSF")
                                               drop if strpos(Nombredelauniversidad,"ESCUELA DE POSTGRADO NEUMANN")            


preserve
	keep CODIGO Nombredelauniversidad
	duplicates drop CODIGO, force
	tempfile nombre_univ
	save `nombre_univ'
restore

drop Nombredelauniversidad
merge m:1 CODIGO using `nombre_univ', nogen

*Formatos
destring N CODIGO, replace force
destring ano_ingreso, replace
drop if ano_ingreso >= 2020 | ano_ingreso == 0 | ano_ingreso == 1900
compress

*Filtros
keep if ano_ingreso >= 2010

rename Ubigeo ubigeo

*Depa y provincia
split ubigeo, parse(-)
rename ubigeo1 departamento
rename ubigeo2 provincia

*Ciclo
replace Ciclodeingreso = subinstr(Ciclodeingreso," ","",.)
replace Ciclodeingreso = subinstr(Ciclodeingreso,"-II","-02",.)
replace Ciclodeingreso = subinstr(Ciclodeingreso,"-I","-01",.)
replace Ciclodeingreso = subinstr(Ciclodeingreso,"-04","-02",.)
replace Ciclodeingreso = subinstr(Ciclodeingreso,"-03","-02",.)
replace Ciclodeingreso = subinstr(Ciclodeingreso,"-1","-01",.)
replace Ciclodeingreso = subinstr(Ciclodeingreso,"-2","-02",.)
replace Ciclodeingreso = subinstr(Ciclodeingreso,"-","",.)

*Depuracion de duplicados
replace TipodeCarné="CORRECCION" if TipodeCarné=="CORRECCIÓN"
rename (TipodeDocumentodeIdentidad DNIdelpostulante) (tipo_documento nro_documento)
	replace tipo_documento = "CEDULA DE IDENTIDAD" if strpos(tipo_documento,"IDENTIDAD")
	replace tipo_documento = "CARNE DE EXTRANJERIA" if strpos(tipo_documento,"EXTRANJERIA")


	
	
*Tasa de transición de los chicos	
	preserve
		gsort tipo_documento nro_documento -Ciclodeingreso
		by tipo_documento nro_documento: gen corr = _n
		duplicates tag tipo_documento nro_documento Nombredelauniversidad, gen(dup_univ)
		drop if dup_univ != 0 & corr != 1
		
		duplicates tag tipo_documento nro_documento, gen(dup)
		drop corr 
		
		gsort tipo_documento nro_documento -Ciclodeingreso		
		by tipo_documento nro_documento: gen corr = _n
		
		keep if corr <= 2
		
		keep tipo_documento nro_documento Nombredelauniversidad TipodeAutorizacion corr
		
		reshape wide Nombredelauniversidad TipodeAutorizacion, i(tipo_documento nro_documento) j(corr)
		rename (Nombredelauniversidad1 Nombredelauniversidad2) (raw_universidad_destino raw_universidad) 
		rename (TipodeAutorizacion1 TipodeAutorizacion2) (tipo_destino tipo_origen)
		
		drop if raw_universidad == ""
		gen movimientos = 1
		
		collapse (sum) movimientos, by(raw_universidad tipo_destino)
		
		replace tipo_destino = "PROCESO" if strpos(tipo_destino,"PROCESO")
		
		reshape wide movimientos, i(raw_universidad) j(tipo_destino) string
		replace raw_universidad = trim(itrim(raw_universidad))
		
		foreach var of varlist _all{
			cap replace `var' = 0 if `var'==. 
		}
		
		$temp
		*save movimiento_uni, replace
	restore

gsort tipo_documento nro_documento -Ciclodeingreso
	by tipo_documento nro_documento: gen temp = _n
	
*Solo nos quedamos con el ultimo ciclo del chico	
	keep if temp == 1

tab tipo_documento TipodeAutorizacion
*Son pocos los extranjeros en universidades denegadas o en proceso

/*	 Tipo de Documento de |       Tipo de Autorizacion
				Identidad |  DENEGADA  EN PROC..  LICENCI.. |     Total
	----------------------+---------------------------------+----------
	 CARNE DE EXTRANJERIA |        19      1,005      1,233 |     2,257 
	  CEDULA DE IDENTIDAD |         0         50         62 |       112 
				   D.N.I. |    41,171    288,930    937,404 | 1,267,505 
				PASAPORTE |         3         87      1,295 |     1,385 
	----------------------+---------------------------------+----------
					Total |    41,193    290,072    939,994 | 1,271,259    */
*Numero de alumnos
gen alumnos = 1

*filtro de años 
*keep if sheet_ano >= 2018

collapse (sum) alumnos , by(CODIGO Nombredelauniversidad Ciclodeingreso )

isid Nombredelauniversidad Ciclodeingreso 

drop CODIGO
reshape wide alumnos, i(Nombredelauniversidad ) j(Ciclodeingreso) string

foreach x in alumnos201001 alumnos201001 alumnos201002 alumnos201101 alumnos201102 alumnos201201 alumnos201202 alumnos201301 alumnos201302 alumnos201401 alumnos201402 alumnos201501 alumnos201502 alumnos201601 alumnos201602 alumnos201701 alumnos201702 alumnos201801 alumnos201802 alumnos201901 alumnos201902{
	replace `x' = 0 if `x' == .
}

rename Nombredelauniversidad universidad

$temp
*save drivers, replace


*******************************

*	2.1) Etiqueta de carreras
*******************************************
$etiq
import excel using "et_std_facultades.xlsx", firstrow clear sheet("alumnos")
rename NOMBREDELAFACULTAD9 nombre_facultad

foreach x in  nombre_facultad{
replace `x' = upper(`x')
	
replace `x' = subinstr(`x',"Á","A",.)	
replace `x' = subinstr(`x',"É","E",.)	
replace `x' = subinstr(`x',"Í","I",.)	
replace `x' = subinstr(`x',"Ó","O",.)	
replace `x' = subinstr(`x',"Ú","U",.)	
replace `x' = subinstr(`x',"Ñ","N",.)

replace `x' = subinstr(`x',"á","A",.)	
replace `x' = subinstr(`x',"é","E",.)	
replace `x' = subinstr(`x',"í","I",.)	
replace `x' = subinstr(`x',"ó","O",.)	
replace `x' = subinstr(`x',"ú","U",.)	
replace `x' = subinstr(`x',"ñ","N",.)
	
replace `x' = subinstr(`x',".","",.)	
replace `x' = subinstr(`x',"-","",.)	
replace `x' = subinstr(`x',"SAC","",.)	
replace `x' = subinstr(`x',"  "," ",.)	
replace `x' = subinstr(`x',"  "," ",.)	
replace `x' = trim(`x')
replace `x' = subinstr(`x'," ","",.)	
	}

duplicates drop nombre_facultad, force	
$temp
*save et_facultad_alumnos, replace

$etiq
import excel using "et_std_facultades_p2.xlsx", firstrow clear 
rename NOMBREDELAFACULTAD9 nombre_facultad
foreach x in  nombre_facultad{
replace `x' = upper(`x')
	
replace `x' = subinstr(`x',"Á","A",.)	
replace `x' = subinstr(`x',"É","E",.)	
replace `x' = subinstr(`x',"Í","I",.)	
replace `x' = subinstr(`x',"Ó","O",.)	
replace `x' = subinstr(`x',"Ú","U",.)	
replace `x' = subinstr(`x',"Ñ","N",.)

replace `x' = subinstr(`x',"á","A",.)	
replace `x' = subinstr(`x',"é","E",.)	
replace `x' = subinstr(`x',"í","I",.)	
replace `x' = subinstr(`x',"ó","O",.)	
replace `x' = subinstr(`x',"ú","U",.)	
replace `x' = subinstr(`x',"ñ","N",.)
	
replace `x' = subinstr(`x',".","",.)	
replace `x' = subinstr(`x',"-","",.)	
replace `x' = subinstr(`x',"SAC","",.)	
replace `x' = subinstr(`x',"  "," ",.)	
replace `x' = subinstr(`x',"  "," ",.)	
replace `x' = trim(`x')
replace `x' = subinstr(`x'," ","",.)	
	}
duplicates drop nombre_facultad, force		
$temp
*save et_facultad_alumnos2, replace

$etiq
import excel using "et_std_facultades.xlsx", firstrow clear sheet("Matricula")
rename Facultad nombre_facultad
foreach x in  nombre_facultad{
replace `x' = upper(`x')
	
replace `x' = subinstr(`x',"Á","A",.)	
replace `x' = subinstr(`x',"É","E",.)	
replace `x' = subinstr(`x',"Í","I",.)	
replace `x' = subinstr(`x',"Ó","O",.)	
replace `x' = subinstr(`x',"Ú","U",.)	
replace `x' = subinstr(`x',"Ñ","N",.)

replace `x' = subinstr(`x',"á","A",.)	
replace `x' = subinstr(`x',"é","E",.)	
replace `x' = subinstr(`x',"í","I",.)	
replace `x' = subinstr(`x',"ó","O",.)	
replace `x' = subinstr(`x',"ú","U",.)	
replace `x' = subinstr(`x',"ñ","N",.)
	
replace `x' = subinstr(`x',".","",.)	
replace `x' = subinstr(`x',"-","",.)	
replace `x' = subinstr(`x',"SAC","",.)	
replace `x' = subinstr(`x',"  "," ",.)	
replace `x' = subinstr(`x',"  "," ",.)	
replace `x' = trim(`x')
replace `x' = subinstr(`x'," ","",.)	
	}
duplicates drop nombre_facultad, force		
$temp
*save et_facultad_matricula, replace


*	2.2) UBIGEO por universidada (Sede)
*******************************************
$wt
import excel using "Informacion solicitada MEF - Sedes.xlsx", firstrow clear cellrange(A3)
rename CÓDIGODELOCAL312 codigo_local
rename AFORODELLOCAL13 aforo_local
rename ÁREACONSTRUIDAm212 area_construido
	
replace aforo_local = subinstr(aforo_local," ","",.)
destring aforo_local area_construido, replace force
	replace aforo_local = 0 if aforo_local  == .
replace codigo_local = subinstr(codigo_local," ","",.)
keep UNIVERSIDAD codigo_local DEPARTAMENTO	PROVINCIA	DISTRITO aforo_local area_construido
drop if UNIVERSIDAD == ""
duplicates drop UNIVERSIDAD codigo_local , force
rename *, lower

foreach x in departamento provincia distrito {
	replace `x' = upper(`x')
	replace `x' = subinstr(`x' ,"  "," ",.)	
	replace `x' = trim(`x')
}

	foreach x in universidad codigo_local{
	replace `x' = trim(`x')
	}
	
foreach x in universidad departamento provincia distrito{
	
replace `x' = subinstr(`x',"Á","A",.)	
replace `x' = subinstr(`x',"É","E",.)	
replace `x' = subinstr(`x',"Í","I",.)	
replace `x' = subinstr(`x',"Ó","O",.)	
replace `x' = subinstr(`x',"Ú","U",.)	
replace `x' = subinstr(`x',"Ñ","N",.)

replace `x' = trim(`x')
replace `x' = subinstr(`x'," ","",.)
replace `x' = subinstr(`x',".","",.)

}
	
replace universidad = subinstr(universidad,".","",.)	
replace universidad = subinstr(universidad,"-","",.)	
replace universidad = subinstr(universidad,"SAC","",.)	
replace universidad = subinstr(universidad,"  "," ",.)	
replace universidad = subinstr(universidad,"  "," ",.)	
replace universidad = trim(universidad)
replace universidad = subinstr(universidad," ","",.)	
	
replace universidad = "ESCUELADENEGOCIOSNEUMANNBUSINESSSCHOOL" if universidad == "ESCUELADEPOSTGRADONEUMANNBUSINESSSCHOOL"
replace universidad = "ESCUELADEPOSTGRADOGERENSSA" if universidad == "ESCUELADEPOSTGRADOGERENS"
replace universidad = "UNIVERSIDADANDINANESTORCACERESVELASQUEZ" if universidad == "UNIVERSIDADANDINANESTORCACERESVELASQUEZ"

replace universidad = "UNIVERSIDADCIENCIASDELASALUD" if universidad == "UMIVERSIDADCIENCIASDELASALUD"
replace universidad = "UNIVERSIDADNACIONALDELCALLAO" if universidad == "UNIVERSIDADNACIONALDELCALLAO"
replace universidad = "UNIVERSIDADNACIONALDETUMBES" if universidad == "UNIVERSIDADNACIONALDETUMBES"
replace universidad = "UNIVERSIDADPERUANADECIENCIASEINFORMATICA" if universidad == "UNIVERSIDADPERUANADECIENCIASEINFORMATICA"
replace universidad = "UNIVERSIDADPERUANALOSANDES" if universidad == "UNIVERSIDADPERUANALOSANDES"

/*
replace universidad = "UNIVERSIDADINTERAMERICANAPARAELDESARROLLOUNID" if universidad == "UNIVERSIDADINTERAMERICANAPARAELDESARROLLO"
replace universidad = "UNIVERSIDADPERUANADECIENCIASAPLICADAS(UPC)" if universidad == "UNIVERSIDADPERUANADECIENCIASAPLICADAS"

replace universidad = "UNIVERSIDADPRIVADADEHUANUCO" if universidad == "UNIVERSIDADDEHUANUCO"
*/

preserve
	gsort universidad -aforo_local
	by universidad: gen n = _n
	keep if n == 1
	drop n
	duplicates drop universidad, force
	drop codigo_local
	$temp
	*save ubigeo_univ_inputado, replace
restore
	
$temp		
*save ubigeo_univ, replace


*	2.3) Pobreza a nivel provincial
*******************************************
$pob
/*
 import excel using "Información-departamental-provincial-distrital-al-31-de-diciembre-VF-páginas-14-62.xlsx", describe	// Permite enlistar y obtener el número total de sheets
	forvalues sheet=1/`=r(N_worksheet)' {  
	local sheetname=r(worksheet_`sheet')    // Local = Nombre del sheet haciendo referencia al número de hoja
	clear
	dis "`sheetname'"
	import excel using "Información-departamental-provincial-distrital-al-31-de-diciembre-VF-páginas-14-62.xlsx", sheet("`sheetname'")  allstring
	save "file_`sheet'", replace  
	}
*/
	clear
	forval y = 1/45{
	append using file_`y', force
	}

keep A B D R T 	
rename (A B D R T) (ubigeo nom_ubigeo pob_total pob_pobre pob_pobre_extremo)

foreach x in pob_total pob_pobre pob_pobre_extremo{
	replace `x' = subinstr(`x',",","",.)
}

destring ubigeo pob_* , replace force
drop if ubigeo == .	

tostring ubigeo, replace
replace ubigeo = "0" + ubigeo if length(ubigeo)== 5

foreach y in 1 3 5{
	gen cod_`y' = substr(ubigeo,`y',2)
}

gen nivel = "distrital"
replace nivel = "provincial" if cod_5 == "00"
replace nivel = "departamental" if cod_3 == "00"

gen departamento 	= nom_ubigeo if nivel == "departamental"
gen provincia 		= nom_ubigeo if nivel == "provincial"
gen distrito 		= nom_ubigeo if nivel == "distrital"

sort ubigeo

foreach x in departamento provincia {
	replace `x' = `x'[_n-1] if `x' == ""
}

rename (cod_1 cod_3 cod_5) (cod_dep cod_prov cod_dist)
drop nom_ubigeo

replace provincia = "LIMA" if strpos(provincia,"PROVINCIA DE LIMA")

foreach x in departamento provincia distrito {
	replace `x' = upper(`x')
	replace `x' = subinstr(`x' ,"  "," ",.)	
	replace `x' = trim(`x')	
	replace `x' = subinstr(`x'," ","",.)	
	replace `x' = subinstr(`x',".","",.)	

	replace `x' = subinstr(`x',"Á","A",.)	
	replace `x' = subinstr(`x',"É","E",.)	
	replace `x' = subinstr(`x',"Í","I",.)	
	replace `x' = subinstr(`x',"Ó","O",.)	
	replace `x' = subinstr(`x',"Ú","U",.)	
	replace `x' = subinstr(`x',"Ñ","N",.)
}

gen r_pobreza = ( pob_pobre ) / pob_total
keep if nivel == "distrital"

collapse (mean) mean_r_pobreza=r_pobreza (median) median_r_pobreza=r_pobreza (max) max_r_pobreza=r_pobreza (sd) sd_r_pobreza = r_pobreza, by(cod_dep cod_prov departamento provincia)

gen double r_pobreza = mean_r_pobreza + sd_r_pobreza

$temp
*save pobreza, replace

*	2.4) Estandarización de universidades (código)
*******************************************
$etiq
import excel using "et_std_uni_COD_2.xlsx", firstrow clear sheet("alumnos")
replace raw_universidad = trim(itrim(raw_universidad))
duplicates drop raw_universidad, force
rename *, lower
$temp
*save std_uni_cod_alumnos2, replace

$etiq
import excel using "et_std_uni_COD_2.xlsx", firstrow clear sheet("matricula")
replace raw_universidad = trim(itrim(raw_universidad))
duplicates drop raw_universidad, force
rename *, lower
$temp
*save std_uni_cod_matricula2, replace


*	2.x_vf) Pobreza y movilidad a nivel de universidad (SISFOH)
*******************************************
/*
$midis
use data_minedu_sindni, clear
rename raw_universidad raw_universidad_1
gen raw_universidad = raw_universidad_1
	replace raw_universidad = d2_raw_universidad if d2_raw_universidad != ""
	
	replace raw_universidad = trim(itrim(raw_universidad)) 
	
	drop if strpos(raw_universidad,"ESCUELA") | strpos(raw_universidad,"ESAPIM") | strpos(raw_universidad,"FACULTAD")
	
	$temp
	merge m:1 raw_universidad using std_uni_cod_alumnos2, keep(match master) nogen
	merge m:1 raw_universidad using std_uni_cod_matricula2, keep(match master) nogen update
	
	gen num = 1
	
	replace situacion_estudio = "OR" if strpos(situacion_estudio,"ORIGEN")
	replace situacion_estudio = "NA" if strpos(situacion_estudio,"NINGUNO")
	replace situacion_estudio = "TR" if strpos(situacion_estudio,"TRASLADAD")
	replace situacion_estudio = "EG" if strpos(situacion_estudio,"EGRES")
		
	replace cse = "POB" if cse == "POBRE"
	replace cse = "NPB" if cse == "NO POBRE"
	replace cse = "PBX" if cse == "POBRE EXTREMO"
	
		foreach var of varlist _all{
		cap replace `var' = "NA"	if `var' == ""
		}
	
	collapse (sum) num_=num (firstnm) raw_universidad, by(cod_uni cse situacion_estudio)
	
	$temp
	save col_minedu_midis, replace
*/	

	$temp
	use col_minedu_midis, clear
	drop if cod_uni == 0
	drop raw_universidad
	
	reshape wide num_ , i(cod_uni cse) j(situacion_estudio) string
	rename num_* num_*_
	reshape wide num_*_ , i(cod_uni) j(cse) string

		foreach var of varlist _all{
		cap replace `var' = 0	if `var' == .
		}	
	

egen total_midis = rowtotal(num_*)
	
egen num_pob = rowtotal(num_*_POB num_*_PBX)	
egen den_pob = rowtotal(num_*_POB num_*_PBX num_*_NPB num_*_NA)

egen num_trs = rowtotal(num_TR_*)
egen den_trs = rowtotal(num_TR_* num_OR_* num_EG_*)

gen r_pobreza 	= num_pob/den_pob
gen r_traslado 	= num_trs/den_trs

$temp
*save pobreza_movilidad, replace


*	2.5) Matricula - II
*******************************************
$temp
use drivers, clear
	rename universidad raw_universidad
	replace raw_universidad = trim(itrim(raw_universidad))
	merge m:1 raw_universidad using std_uni_cod_matricula2, gen(merge_cod_uni) keep(master match)
	
	*br if  cod_uni == 9 | cod_uni == 86 | cod_uni == 87 | cod_uni == 106 | cod_uni == 116
	
	tostring cod_uni, replace
	duplicates drop cod_uni, force
	drop if cod_uni == "." | cod_uni == "0"
	
	merge m:1 raw_universidad using movimiento_uni, nogen keep(master match)
	rename (movimientosDENEGADA movimientosLICENCIADA movimientosPROCESO) (mov_denegada mov_licenciada mov_proceso)
	
	egen alumnos_total = rowtotal(alumnos*)
	*Ratios de movilizacion
	gen r_movilidad = (mov_licenciada + mov_proceso)/alumnos_total
	drop alumnos_total
	
	*save cod_drivers2, replace

**************************************************************
**************************************************************
**************************************************************
/*______________________________________________________________________________
	3) Preparando bases merge
______________________________________________________________________________*/

*	3.1) Base master de alumnos
*******************************************
$wt
*import excel using "Información solicitada MEF - Alumnos.xlsx", firstrow clear cellrange("A4")
$wt_sd2
import excel using "Información solicitada - Programas y Alumnos 10.12.2019.xlsx", firstrow clear cellrange("A4")

drop if UNIVERSIDAD == ""
compress

cap rename CÓDIGODELLOCAL1 codigo_local
cap rename CÓDIGODELLOCAL codigo_local
cap replace codigo_local = subinstr(codigo_local," ","",.)
cap drop if codigo_local == ""

rename NTOTALDEESTUDIANTESMATRICUL n_total
destring n_total, replace force

rename *, lower
rename (tipodegestiÓn cÓdigodeprogramadeestudios nombredelafacultad) (tipo_gestion cod_programa nombre_facultad)

rename ÚltimoperÍodoacadÉmico ultimo_ano_academico

gen raw_universidad = universidad

	*Para limpiar dichos caracteres podemos reemplazarlos con un vacío "" con el comando SUBINSTR
	foreach x in ultimo_ano_academico{
	forval i=1/47{
	cap replace `x' = subinstr(`x', "`=char(`i')'" , "" , . )
	}
	}

	foreach x in ultimo_ano_academico{
	forval i=58/259{
	cap replace `x' = subinstr(`x', "`=char(`i')'" , "" , . )
	}
	}
	
	replace ultimo_ano_academico = substr(ultimo_ano_academico,1,4)
	
	table ultimo_ano_academico, c(sum n_total) f(%20.0fc) row 
	
keep raw_universidad universidad tipo_gestion estado codigo_local cod_programa nombre_facultad n_total
	foreach x in universidad codigo_local{
	replace `x' = trim(`x')
	}

	foreach x in universidad nombre_facultad{
replace `x' = upper(`x')
	
replace `x' = subinstr(`x',"Á","A",.)	
replace `x' = subinstr(`x',"É","E",.)	
replace `x' = subinstr(`x',"Í","I",.)	
replace `x' = subinstr(`x',"Ó","O",.)	
replace `x' = subinstr(`x',"Ú","U",.)	
replace `x' = subinstr(`x',"Ñ","N",.)

replace `x' = subinstr(`x',"á","A",.)	
replace `x' = subinstr(`x',"é","E",.)	
replace `x' = subinstr(`x',"í","I",.)	
replace `x' = subinstr(`x',"ó","O",.)	
replace `x' = subinstr(`x',"ú","U",.)	
replace `x' = subinstr(`x',"ñ","N",.)
	
replace `x' = subinstr(`x',".","",.)	
replace `x' = subinstr(`x',"-","",.)	
replace `x' = subinstr(`x',"SAC","",.)	
replace `x' = subinstr(`x',"  "," ",.)	
replace `x' = subinstr(`x',"  "," ",.)	
replace `x' = trim(`x')
replace `x' = subinstr(`x'," ","",.)	

replace `x' = subinstr(`x',"SAC","",.)	
}

foreach x in nombre_facultad universidad{
drop if strpos(`x',"POSGRADO") | strpos(`x',"POSTGRADO") | strpos(`x',"POSGRDO") | strpos(`x',"PADESCUELADE") 	
}	

drop if strpos(raw_universidad,"NEUMANN")
	
$temp
*save master_alumnos, replace

**************************************************************
**************************************************************
**************************************************************
**************************************************************
**************************************************************
**************************************************************
**************************************************************
**************************************************************
**************************************************************

$temp
use master_alumnos, clear
drop if n_total == . | n_total == 0

*	3.2) Merge para obtener ubigeo
*******************************************
$temp
merge m:1 universidad codigo_local using ubigeo_univ, gen(merge_local) keep( master match )
merge m:1 universidad using ubigeo_univ_inputado, gen(merge_local2) update
	drop if merge_local2 == 2
	
	*Hay un supuesto fuerte al hacer un segundo match por solo universidad y no sedes, ya que se considera la universidad con mayor aforo como el ubigeo valido para esa universidad.
	*Se le imputa LIMA LIMA LIMA, aunque esta universidad se encuentra en Pueblo Libre, pero en la nueva versión ya no.
	/*
	foreach x in departamento provincia distrito{
		replace `x' = "LIMA" if `x' == ""
	}
	*/
	
*	3.3) Merge para obtener estandarizacion de facultad/carreras
*******************************************
$temp	
merge m:1 nombre_facultad using et_facultad_alumnos,  keep( master match ) nogen
rename Nuevafacultad nueva_facultad

/*

                        raw_universidad |      Freq.     Percent        Cum.
----------------------------------------+-----------------------------------
 UNIVERSIDAD DE INGENIERIA Y TECNOLOGIA |          6       21.43       21.43
    UNIVERSIDAD PRIVADA JUAN MEJÍA BACA |          5       17.86       39.29
               UNIVERSIDAD PRIVADA SISE |         17       60.71      100.00
----------------------------------------+-----------------------------------
                                  Total |         28      100.00

*/

replace nueva_facultad = "CIENCIAS ECONÓMICAS, ADMINISTRACIÓN, FINANZAS, ETC." if strpos(raw_universidad,"SISE")
replace nueva_facultad = "INGENIERÍA Y ARQUITECTURA" if strpos(raw_universidad,"INGENIERIA Y TECNOLO")

replace nueva_facultad = "TURISMO, HOTELERIA E INDUSTRIAS ALIMENTARIAS" if strpos(raw_universidad,"PRIVADA JUAN MEJ") & cod_programa == "P01"
replace nueva_facultad = "INGENIERÍA Y ARQUITECTURA" if strpos(raw_universidad,"PRIVADA JUAN MEJ") & cod_programa == "P02"
replace nueva_facultad = "INGENIERÍA Y ARQUITECTURA" if strpos(raw_universidad,"PRIVADA JUAN MEJ") & cod_programa == "P03"
replace nueva_facultad = "LETRAS, CIENCIAS HUMANAS Y EDUCACIÓN" if strpos(raw_universidad,"PRIVADA JUAN MEJ") & cod_programa == "P04"
replace nueva_facultad = "LETRAS, CIENCIAS HUMANAS Y EDUCACIÓN" if strpos(raw_universidad,"PRIVADA JUAN MEJ") & cod_programa == "P05"

replace nueva_facultad = "INGENIERÍA Y ARQUITECTURA" if strpos(nombre_facultad,"INGENIERIA") & nueva_facultad == ""
replace nueva_facultad = "CIENCIAS MATEMÁTICAS Y NATURALES" if strpos(nombre_facultad,"MATEMATIC") & strpos(nombre_facultad,"NATURAL") & nueva_facultad == ""
replace nueva_facultad = "CIENCIAS SOCIALES Y DERECHO" if strpos(nombre_facultad,"JURIDICASCONTABLESYSOC") & nueva_facultad == ""


/*
nueva_facultad
VACÍO
CIENCIAS ECONÓMICAS, ADMINISTRACIÓN, FINANZAS, ETC.
INGENIERÍA Y ARQUITECTURA
CIENCIAS SOCIALES Y DERECHO
LETRAS, CIENCIAS HUMANAS Y EDUCACIÓN
CIENCIAS DE LA SALUD
CIENCIAS MATEMÁTICAS Y NATURALES
TURISMO, HOTELERIA E INDUSTRIAS ALIMENTARIAS
NO CATEGORIZABLE
*/

*Completar las vacias y no categorizables incorporando la variable de carrera de una tabla anterior

*	3.5) Merge para obtener codigos de universidades
*******************************************
$temp
replace raw_universidad = trim(itrim(raw_universidad))
merge m:1 raw_universidad using std_uni_cod_alumnos2, keep(master match) gen(merge_cod_uni_alumnos)

*	3.4) Merge para obtener nivel de universidad
*******************************************
$temp
merge m:1 cod_uni using pobreza_movilidad, keep(master match) nogen
tostring cod_uni, replace	

replace estado = "EN PROCESO" if strpos(estado,"PROCESO")

gen ano_negatoria = .
	replace ano_negatoria = 2019 if strpos(estado,"DENEGADA")
	replace ano_negatoria = 2018 if strpos(estado,"DENEGADA") & (cod_uni == "26" | cod_uni == "90" | cod_uni == "93" | cod_uni == "94")
	
tab raw_universidad if (strpos(raw_universidad,"ORVAL") | strpos(raw_universidad,"INTEGRACIÓN GLOBAL") | strpos(raw_universidad,"DAD DE LAMBAY") | strpos(raw_universidad,"INVESTIGACIÓN Y NEGO"))	

bys departamento provincia estado: egen temp_pobreza = mean(r_pobreza)
bys estado ano_negatoria: egen temp_traslado = mean(r_traslado)
	
replace r_pobreza  = temp_pobreza  if r_pobreza  == .
replace r_traslado = temp_traslado if r_traslado == . & (strpos(estado,"DENEGADA") | strpos(estado,"PROCESO"))

table estado tipo_gestion, by(ano_negatoria) c(mean r_pobreza mean r_traslado) f(%20.4fc)
table raw_universidad tipo_gestion if strpos(estado,"DENEGADA"), by(ano_negatoria) c(mean r_pobreza mean r_traslado) f(%20.4fc)


*	3.6) Merge para obtener drivers de matricula por ciclo de universidades
*******************************************
merge m:1 cod_uni using cod_drivers2, keep(master match) gen(merge_cod)
	drop if merge_cod == 1 // Estoy eliminando a la facultad de teologia
	
foreach var of varlist _all{
	cap replace `var' = 0 if `var' == . 
}

*Ratios de ciclos
egen denominador = rowtotal(alumnos201001-alumnos201902)

foreach x in 201001 201002 201101 201102 201201 201202 201301 201302 201401 201402 201501 201502 201601 201602 201701 201702 201801 201802 201901 201902 {
	gen alumnos_ciclo_`x' = (alumnos`x' /  denominador) * n_total
}

*Keep variables necesarias
*keep cod_uni universidad raw_universidad tipo_gestion estado codigo_local cod_programa nombre_facultad nueva_facultad  departamento provincia distrito area_construido aforo_local r_pobreza alumnos* r_movilidad n_total 
keep cod_uni universidad raw_universidad tipo_gestion estado nueva_facultad departamento provincia distrito area_construido aforo_local r_pobreza r_movilidad r_traslado n_total alumnos_ciclo_* total_midis

*Reshape data por ciclo_ingreso
collapse (sum) alumnos_ciclo_* n_total (firstnm) total_midis area_construido aforo_local r_pobreza r_movilidad r_traslado tipo_gestion estado, by(cod_uni raw_universidad nueva_facultad departamento provincia distrito)

reshape long alumnos_ciclo_ , i(cod_uni raw_universidad nueva_facultad departamento provincia distrito) j(ciclo_ingreso)
rename alumnos_ciclo n_alumnos

*reemplazando el numero de alumnos por el traslado
replace n_alumnos = n_alumnos * (1-r_traslado)

gen n_alumnos_P	 = n_alumnos * r_pobreza
gen n_alumnos_NP = n_alumnos - n_alumnos_P

drop n_alumnos

reshape long n_alumnos_ , i(cod_uni raw_universidad nueva_facultad departamento provincia distrito ciclo_ingreso) j(nse) string

rename n_alumnos_ q_alumnos
replace q_alumnos = ceil(q_alumnos)

replace nse = "Pobres" if nse == "P"
replace nse = "No Pobres" if nse == "NP"

gen num_ciclo_fin = 10
	replace num_ciclo_fin = 14 if strpos(nueva_facultad, "SALUD")
	
tostring ciclo_ingreso, replace
encode ciclo_ingreso, gen(cod_ciclo)

gen ciclo_actual = 20 - cod_ciclo + 1
	replace ciclo_actual = 9 if ciclo_actual > 10 & strpos(nueva_facultad, "SALUD")==0
	replace ciclo_actual = 13 if ciclo_actual > 14 & strpos(nueva_facultad, "SALUD")>0

*****
*Calculamos el T
gen t = num_ciclo_fin - ceil(ciclo_actual/2)
	replace t = 10 if strpos(nueva_facultad, "SALUD")==0 & ciclo_actual <= 2
	replace t = 14 if strpos(nueva_facultad, "SALUD")>0  & ciclo_actual <= 2
*gen t = num_ciclo_fin - ciclo_actual + 2	
	*replace t = 10 if strpos(nueva_facultad, "SALUD")==0 & ciclo_actual <= 4
	*replace t = 14 if strpos(nueva_facultad, "SALUD")>0  & ciclo_actual <= 4
rename t t_ciclos

gen corr = _n
expand 12
bys corr: gen cod_concepto = _n
drop corr

$temp
merge m:1 cod_concepto using precios, nogen

/*
Componente 1	Orientación vocacional
Componente 2	Trámites/examen por traslado
Componente 2	Convalidación
Componente 3	Matrícula
Componente 3	Pensión
Componente 3	Acompañamiento académico y socioafectivo
Componente 3	Examen de rendimiento
Componente 3	Manutención con alojamiento en Lima y/o Callao
Componente 3	Manutención sin alojamiento en Lima y/o Callao
Componente 3	Manutención con alojamiento fuera de Lima y/o Callao
Componente 3	Manutención sin alojamiento fuera de Lima y/o Callao
Componente 3	Pasaje para traslado fuera de Lima y/o Callao
*/

gen lima_callao = (departamento == "LIMA" & (provincia == "LIMA" | provincia == "CALLAO"))	
gen ultimo_ano = ((ciclo_actual==9 | ciclo_actual==10) & strpos(nueva_facultad, "SALUD")==0)	 | ((ciclo_actual==13 | ciclo_actual==14) & strpos(nueva_facultad, "SALUD")>0)	

gen num_horas 	= ceil((q_alumnos/30)*4)
gen num_per 	= ceil((q_alumnos/30)/40)
gen num_dias 	= ceil((num_horas/num_per)/8)

*Componente 1
cap drop pxq
gen pxq = .
	replace pxq = 25*num_horas 	if strpos(componente, "1") & estado != "LICENCIADA" 

*Componente 2	
	replace pxq = costo_semestral*q_alumnos if strpos(componente, "2") & estado != "LICENCIADA" & strpos(concepto,"examen por traslado") & ultimo_ano == 0 & nse == "Pobres"
	replace pxq = costo_semestral*q_alumnos*ceil(ciclo_actual/2) if ciclo_actual > 2 & strpos(componente, "2") & estado != "LICENCIADA" & strpos(concepto,"Convalidación")	& ultimo_ano == 0 & nse == "Pobres"

*Componente 3	
	replace pxq = costo_semestral*q_alumnos*t_ciclos if strpos(componente, "3") & estado!="LICENCIADA" & ultimo_ano == 0 & nse == "Pobres" & strpos(concepto,"Matrícula") 
	replace pxq = costo_semestral*q_alumnos*t_ciclos if strpos(componente, "3") & estado!="LICENCIADA" & ultimo_ano == 0 & nse == "Pobres" & strpos(concepto,"Pensión") 
	replace pxq = costo_semestral*q_alumnos*t_ciclos if strpos(componente, "3") & estado!="LICENCIADA" & ultimo_ano == 0 & nse == "Pobres" & strpos(concepto,"Acompañamiento")
	
	replace pxq = costo_semestral*q_alumnos*t_ciclos if strpos(componente, "3") & estado!="LICENCIADA" & ultimo_ano == 0 & nse == "Pobres" & strpos(concepto,"Pasaje") & lima_callao == 0

	replace pxq = costo_semestral*q_alumnos 		 if strpos(componente, "3") & estado!="LICENCIADA" & ultimo_ano == 0 & nse == "Pobres" & strpos(concepto,"Examen de rendimiento") 

	replace pxq = costo_semestral*q_alumnos*t_ciclos if strpos(componente, "3") & estado!="LICENCIADA" & ultimo_ano == 0 & nse == "Pobres" & strpos(concepto,"con alojamiento en Lima") & lima_callao == 0

	gen pxq_delta = (1714-536)*5*t_ciclos*q_alumnos  if strpos(componente, "3") & estado!="LICENCIADA" & ultimo_ano == 0 & nse == "Pobres" & strpos(concepto,"Pensión")
	
	gen pxq_v1 = pxq
	gen pxq_v2 = pxq
	
	replace pxq_v1 = costo_semestral*q_alumnos*t_ciclos if strpos(componente, "3") & estado != "LICENCIADA"  & ultimo_ano == 0 & nse == "Pobres" & strpos(concepto,"sin alojamiento en Lima") & lima_callao == 1
		
	replace pxq_v2 = 0 									if strpos(componente, "3") & estado != "LICENCIADA"  & nse == "Pobres" & strpos(concepto,"sin alojamiento en Lima") & lima_callao == 1
		
foreach var of varlist _all{
	cap replace `var' = 0 if `var' == .
}

foreach x in pxq_delta pxq_v1 pxq_v2{
	replace `x' = ceil(`x')
}

gen pxq_v1_delta = pxq_v1
	replace pxq_v1_delta = pxq_delta if strpos(componente, "3") & estado!="LICENCIADA" & ultimo_ano == 0 & nse == "Pobres" & strpos(concepto,"Pensión")
gen pxq_v2_delta = pxq_v2
	replace pxq_v2_delta = pxq_delta if strpos(componente, "3") & estado!="LICENCIADA" & ultimo_ano == 0 & nse == "Pobres" & strpos(concepto,"Pensión")


replace estado = "EN PROCESO" if strpos(estado,"PROCESO")
	
$temp
*save bda_estrategia_universidades, replace
*export excel using "bda_estrategia_universidades.xlsx", first(var) replace

*****************************
*		TABLES
*****************************
$temp
use bda_estrategia_universidades, clear

table  ultimo_ano if strpos(componente,"1") ,  by(nse estado)   c(sum q_alumnos) f(%20.0fc) col row
table  raw_universidad departamento if strpos(componente,"1") & strpos(raw_universidad,"TECNOLÓGICA DEL PER") ,  c(sum q_alumnos) f(%20.0fc) col row

*0) Tablas resumen
table estado   if strpos(componente,"1"), by(concepto) c(sum q_alumnos sum pxq_v1) f(%20.0fc) row
table concepto if strpos(componente,"2") & nse == "Pobres" & ultimo_ano == 0, by(estado) c(sum q_alumnos sum pxq_v1 ) f(%20.0fc) col row
table concepto if strpos(componente,"3") & nse == "Pobres" & ultimo_ano == 0, by(estado) c(sum q_alumnos sum pxq_v1 sum pxq_v2 sum pxq_v1_delta sum pxq_v2_delta) f(%20.0fc) col row

table concepto t_ciclos if strpos(componente,"3") & nse == "Pobres"  & strpos(estado, "DENEGADA") & ultimo_ano == 0, by(estado) c(sum pxq_v1 ) f(%20.0fc) col row

*1) Anualización del monto
foreach esc in pxq_v1 pxq_v2 pxq_v1_delta pxq_v2_delta{
gen `esc'_t_0 = `esc' if strpos(componente,"1") | strpos(componente,"2") | (strpos(componente,"3") & strpos(concepto,"Examen de rendimiento"))

gen monto_por_ciclo_`esc' = ceil(`esc'/t_ciclos)
forval ciclo = 1/14{
gen `esc'_t_`ciclo' = monto_por_ciclo_`esc' 	if strpos(componente,"3") & strpos(concepto,"Examen de rendimiento")==0 & nse == "Pobres" & ultimo_ano == 0
}
forval ciclo = 1/14{
replace `esc'_t_`ciclo' = 0 					if strpos(componente,"3") & strpos(concepto,"Examen de rendimiento")==0 & nse == "Pobres" & ultimo_ano == 0 & `ciclo'>t_ciclos
}
}

foreach var of varlist _all{
	cap replace `var' = 0 if `var' == .
}



table concepto if strpos(componente,"3") & nse == "Pobres" & ultimo_ano == 0, by(estado) c(sum q_alumnos sum pxq_delta sum pxq_v1 sum pxq_v2) f(%20.0fc) col row

table concepto if strpos(componente,"2") & nse == "Pobres" & ultimo_ano == 0, by(estado) c(sum q_alumnos sum pxq_v1 ) f(%20.0fc) col row

table concepto if strpos(componente,"1"), by(estado) c(sum q_alumnos sum pxq_v1) f(%20.0fc) col row

table departamento componente if (cod_concepto == 1) & strpos(estado, "DENEGADA") , c(sum q_alumnos) f(%20.0fc)

table departamento nse componente if (cod_concepto == 2) & strpos(estado, "DENEGADA") & ultimo_ano == 0 , c(sum q_alumnos) f(%20.0fc) row col
	
table departamento componente if (cod_concepto == 4) & strpos(estado, "DENEGADA") & ultimo_ano == 0 , c(sum q_alumnos) f(%20.0fc)

table estado componente if  estado != "LICENCIADA", c(sum pxq_v1) f(%20.0fc)

table concepto componente  if  estado != "LICENCIADA", by(estado) c(sum pxq_v1 sum pxq_v2) f(%20.0fc) col row

table concepto componente  if  estado != "LICENCIADA" & nse == "Pobres" , by(estado) c(sum pxq_v1) f(%20.0fc) col row


********
*POR SALVAR (REPECHAJE)
gen repechaje = 0
	replace repechaje=1 if strpos(raw_universidad,"GONZAG")

********



global nombre_excel "bda_estrategia_unl_collapse_v4.xlsx"
******
*Tablas resumen 0
preserve
	keep if strpos(componente,"1")
	collapse (sum) q_alumnos , by(cod_uni raw_universidad estado tipo_gestion departamento provincia repechaje)
	gsort cod_uni raw_universidad -q_alumnos 
	by cod_uni raw_universidad: gen n = _n
	keep if n == 1
	
	keep cod_uni raw_universidad estado tipo_gestion departamento provincia repechaje 
	duplicates drop
	gen num_universidades = 1
	
	collapse (sum) num_universidades, by(cod_uni raw_universidad estado tipo_gestion departamento provincia repechaje)

	$temp
	*export excel using "$nombre_excel", first(var) sheet("Univ - prov",replace)
restore

*Tablas resumen 1 
preserve
	keep if strpos(componente,"1")
	collapse (sum) q_alumnos , by(cod_uni raw_universidad estado tipo_gestion departamento repechaje)
	gsort cod_uni raw_universidad -q_alumnos 
	by cod_uni raw_universidad: gen n = _n
	keep if n == 1
	
	keep cod_uni raw_universidad estado tipo_gestion departamento repechaje
	duplicates drop
	gen num_universidades = 1
	
	collapse (sum) num_universidades, by(cod_uni raw_universidad estado tipo_gestion departamento repechaje)

	$temp
	*export excel using "$nombre_excel", first(var) sheet("Univ",replace)
restore

******
*Tablas resumen 2 
preserve
	keep if strpos(componente,"1")
	
	collapse (sum) q_alumnos, by(cod_uni raw_universidad departamento estado tipo_gestion nse ultimo_ano lima_callao repechaje)

	$temp
	*export excel using "$nombre_excel", first(var) sheet("Alumnos",replace)
restore

******
*Tablas resumen 3
 
compress
collapse (sum) *_t_* , by(departamento lima_callao tipo_gestion estado nse componente concepto repechaje)

reshape long pxq_v1_t_ pxq_v2_t_ pxq_v1_delta_t_ pxq_v2_delta_t_ , i(departamento lima_callao tipo_gestion estado nse componente concepto repechaje) j(ciclo)

foreach esc in pxq_v1 pxq_v2 pxq_v1_delta pxq_v2_delta{
	rename `esc'_t_ monto_`esc'
}

reshape long monto_ , i(departamento lima_callao tipo_gestion estado nse componente concepto ciclo repechaje) j(escenario) string

gen ano = 2020
	replace ano = ano + floor(ciclo/2)

$temp
*export excel using "$nombre_excel", first(var) sheet("Esc",replace)

