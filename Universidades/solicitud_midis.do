clear all
set more off

global ruta "D:\Google Drive\MEF\Universidades no licenciadas\01_Estrategia_MEF"
global ruta "C:\Users\serv_dapt001\Google Drive\MEF\Universidades no licenciadas\01_Estrategia_MEF"

global wt 		cd "$ruta\2. Data\wetransfer-243fc8"
global temp 	cd "$ruta\2. Data\2. Temp"
global tabla 	cd "$ruta\3. Tablas"
global etiq		cd "$ruta\1. Insumos\etiqueta estandar"
global pob		cd "$ruta\1. Insumos\pobreza"
global precios  cd "$ruta\1. Insumos\precios"
global sunedu   cd "$ruta\2. Data\wetransfer-243fc8\10122019"
global sunedu_0   cd "$ruta\2. Data\wetransfer-243fc8\06122019"

*	2.1) Movilidad SUNEDU
*******************************************

local a = 0
foreach sheet in "FORMULARIO F2" "Telesup"{
local a = `a' + 1
$sunedu_0
import excel using "Base F2 consolidado MEF 06.12.19 vf.xlsx", sheet("`sheet'") firstrow clear
$temp
save a_`a'_movil, replace
}

clear
forval a = 1/2{
	$temp
	append using a_`a'_movil, force
}

drop if Númerodedocumento==""
gsort Númerodedocumento -Situacióndeestudios20192Co
by Númerodedocumento: gen corr = _n
keep if corr == 1

keep if strpos(Tipodocumentodeidentidad,"DNI")

		gen raw_universidad = Universidadconlicenciadenegad
		replace raw_universidad = trim(itrim(raw_universidad))

rename (Tipodocumentodeidentidad Númerodedocumento Departamento Provincia Distrito) (tipo_documento nro_documento departamento provincia ubigeo3)		
		
keep tipo_documento nro_documento departamento provincia ubigeo3 raw_universidad Situacióndeestudios20192Co		

rename (departamento provincia ubigeo3 raw_universidad) (d2_dep d2_prov d2_distrito d2_raw_universidad)

rename Situacióndeestudios20192Co situacion_estudio

rename *, lower
gen largo = length(nro_documento)
	drop if largo > 8
	replace nro_documento = "0" + nro_documento if largo == 7
	replace nro_documento = "00" + nro_documento if largo == 6
	
	drop largo
gen largo = length(nro_documento)
	drop if largo != 8	
	drop largo

$temp
save temp_movilidad, replace

$temp
use temp_movilidad, clear
gen traslado = strpos( situacion_estudio ,"TRASLADAD")
gen num = 1
collapse (sum) num, by(d2_raw_universidad traslado)

reshape wide num, i(d2_raw_universidad) j(traslado)
replace num1 = 0 if num1 == .
gen ind = num1 / (num1 + num0)
kdensity ind


*	2.1) Matricula
*******************************************
/*
forval ano = 2017/2019{
forval parte = 1/2{
	$sunedu
	import excel using "DIGRAT-Información solicitada MEF - Matrícula 10.12.2019.xlsx", sheet("MATRICULA `ano' - PARTE `parte'") firstrow clear cellrange(A4)
	$temp
	save a_matricula_`ano'_`parte', replace
}
}
*/

clear
forval ano = 2017/2019{
forval parte = 1/2{
	$temp
	append using a_matricula_`ano'_`parte', force
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

*Table 1 para MIDIS
	
		gsort tipo_documento nro_documento -Ciclodeingreso
		by tipo_documento nro_documento: gen corr = _n
		keep if corr == 1
		keep if strpos(tipo_doc,"D.N.I.")
		
		keep tipo_documento nro_documento NombredelaSede Nombredelauniversidad Ciclodeingreso departamento provincia ubigeo3
		
		gen raw_universidad = Nombredelauniversidad
		replace raw_universidad = trim(itrim(raw_universidad))
rename *, lower
			
		$temp
		save matricula_unica, replace
		
*	2.1) Matricula
*******************************************
$temp
use matricula_unica, clear
merge 1:1 nro_documento using temp_movilidad
	drop if strpos(nro_documento,"U") | strpos(nro_documento,"Y") | strpos(nro_documento,"E")
	
	foreach x in raw_universidad d2_raw_universidad situacion_estudio{
		replace `x' = trim(itrim(`x'))
		replace `x' = upper(`x')
	}
	
	replace situacion_estudio = subinstr(situacion_estudio,"ó","Ó",.)
	
	rename ubigeo3 distrito
	compress

	$temp
	save pedido_midis, replace
	export delimited using "pedido_midis.txt", replace	
	
	
	gen num = 1
	collapse (sum) num, by(raw_universidad d2_raw_universidad situacion_estudio)