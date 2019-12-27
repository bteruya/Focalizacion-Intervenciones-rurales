*************************************************
*Project:		Licenciamiento Universidades  	*
*Institution:	MINEDU             				*
*Author:		Brenda Teruya					*
*Last edited:	2019-12-23          			*
*************************************************


global ruta "C:\Users\analistaup2\Google Drive\Trabajo\MINEDU_trabajo\UPP\Actividades\Focalizacion\Datos"

global universidades "$ruta\Universidades"

********************************************************************************
*Tabular número de alumnos

import excel "$universidades\Información solicitada - Programas y Alumnos 10.12.2019.xlsx", sheet("N° ALUMNOS") cellrange(A4:J9349) firstrow clear

*Hay textos dentro del régimen de estudios, usaremos unicamente los números sin los comentarios
destring RÉGIMENDEESTUDIOS, gen(n_alumno) force


table ESTADO TIPODEGESTIÓN , c(sum n_alumno)

********************************************************************************
*Abrir bd a nivel facultad nse ciclo

use "$universidades\01_Estrategia_MEF\2. Data\2. Temp\bda_estrategia_universidades.dta", clear

label var cod_uni "Cógido de universidad"
label var raw_universidad "Nombre universidad"
label var nueva_facultad "Facultad agrupada"
label var nse "NSE, SISFOH"
label var q_alumnos "N. alumnos"
label var num_ciclo_fin "N. ciclos para terminar la carrera"

drop pxq pxq_v?_delta pxq_delta pxq_v2
label var pxq_v1 "PxQ manutención en Lima y Callao"



isid cod_uni raw_universidad nueva_facultad departamento provincia distrito ciclo_ingreso nse concepto componente

label data "BD con caracteristicas de las universidades"

save "$ruta\Data sets Intermedios\Universidades.dta", replace

********************************************************************************

use "$ruta\Data sets Intermedios\Universidades.dta", clear

*Universidades sin alumnos
tab q_alumnos if cod_uni == "122" //UNIVERSIDAD PRIVADA SERGIO BERNALES S.A
tab q_alumnos if cod_uni == "126" //UNIVERSIDAD SAN ANDRÉS S.A.C.

keep if componente == "Componente 1"

isid cod_uni raw_universidad nueva_facultad departamento provincia distrito ciclo_ingreso nse 
*por universidad sin facultad
*sin ciclo ingreso
*sin filial
*sin nse

collapse (first) tipo_gestion estado (sum) q_alumnos ,by(cod_uni raw_universidad )

label var cod_uni "Cógido de universidad"
label var raw_universidad "Nombre universidad"

label data "BD a nivel de universidad con n. alumnos y ratio pobreza"
destring cod_uni , replace
save "$ruta\Data sets Intermedios\Universidades_pobreza.dta", replace


********************************************************************************
********************************************************************************
*SEDES AFORO
/*
(13) En este casillero se consigna información sobre el aforo (capacidad total de personas que alberga el local) de cada uno de los locales declarados por la universidad. La información declarada deberá corresponder a  un estudio técnico de cálculo de aforo por local, elaborado y suscrito por un consultor ingeniero o arquitecto colegiado independiente o el Certificado vigente de Inspección Técnica de Seguridad en Edificaciones que corresponda (ITSE básico, ex post, ex ante o de detalle), según la normatividad vigente. 
*/
import excel "$universidades\01_Estrategia_MEF\2. Data\wetransfer-243fc8\Informacion solicitada MEF - Sedes.xlsx", sheet("SEDES") cellrange(A3:U836) firstrow clear
drop in 1


rename CÓDIGODELOCAL312 codigo_local
rename AFORODELLOCAL13 aforo_local
rename ÁREACONSTRUIDAm212 area_construido
	
replace aforo_local = subinstr(aforo_local," ","",.)
destring aforo_local area_construido, replace force
	replace aforo_local = 0 if aforo_local  == .
replace codigo_local = subinstr(codigo_local," ","",.)
keep UNIVERSIDAD codigo_local DEPARTAMENTO	PROVINCIA	DISTRITO aforo_local area_construido

********************************************************************************
use "$universidades\01_Estrategia_MEF\2. Data\2. Temp\pobreza_movilidad", clear

merge 1:1 cod_uni using "$ruta\Data sets Intermedios\Universidades_pobreza.dta", nogen

label var r_pobreza "Ratio de alumnos pobres por univ según SISFOH"
label var q_alumnos "Total alumnos "
keep cod_uni r_pobreza r_traslado raw_universidad tipo_gestion estado q_alumnos

tabstat r_pobreza , stat(mean) by(estado)

table estado tipo_gestion , c(mean r_pobreza)

label data "BD a nivel de universidad con n. alumnos y ratio pobreza"
save "$ruta\Data sets Intermedios\Universidades_pobreza_sisfoh.dta", replace

export excel using "$ruta\Data sets Intermedios\Universidades_pobreza_sisfoh.xlsx", firstrow(varlabels) replace

