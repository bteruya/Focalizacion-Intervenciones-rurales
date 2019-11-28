// EBE - INICIAL

keep if tiporeg=="1" & nroced=="8AI" & cuadro=="C201"

gen matri_tot=d01+d02+d03+d04+d05+d06+d07+d08+d09+d10+d11+d12+d13+d14+d15+d16

gen d_tipdato=tipdato

destring d_tipdato, replace
rename d_tipdato nee
label variable nee "tipo de necesidad educativa especial"
label define lblnee 1 "Discapacidad intelectual - RM Severo/Profundo" 2 "Discapacidad auditiva - Hipoacusia"/*
*/ 3 "Discapacidad auditiva - Sordera total" 4 "Discapacidad visual - Baja visión" 5 "Discapacidad visual - Ceguera" 6 "Sordoceguera"/*
*/ 7 "Transtorno del Espectro Autista - TEA" 8 "Multidiscapacidad - MDE" 9 "ESH - Menos de 10 días" 10 "ESH - De 10 a 15 días" 11 "ESH - Más de 15 días"  12 "Otras NEE asociadas a discapacidad"
label values nee lblnee

label variable niv_mod "codigo de nivel/modalidad"
gen d_niv_mod=niv_mod
replace d_niv_mod="1" if d_niv_mod=="A1"
replace d_niv_mod="2" if d_niv_mod=="A2"
replace d_niv_mod="3" if d_niv_mod=="A3"
replace d_niv_mod="4" if d_niv_mod=="A5"
replace d_niv_mod="5" if d_niv_mod=="B0"
replace d_niv_mod="6" if d_niv_mod=="F0"
replace d_niv_mod="7" if d_niv_mod=="D1"
replace d_niv_mod="8" if d_niv_mod=="D2"
replace d_niv_mod="9" if d_niv_mod=="K0"
replace d_niv_mod="10" if d_niv_mod=="T0"
replace d_niv_mod="11" if d_niv_mod=="M0"
replace d_niv_mod="12" if d_niv_mod=="E0"
replace d_niv_mod="13" if d_niv_mod=="E1"
replace d_niv_mod="14" if d_niv_mod=="E2"
replace d_niv_mod="15" if d_niv_mod=="L0"
destring d_niv_mod, replace
label define lblniv 1 "EBR - Inicial Cuna" 2 "EBR - Inicial Jardin"/*
*/ 3 "EBR - Inicial Cuna Jardin" 4 "EBR - Inicial No Escolarizado"/*
*/ 5 "EBR - Primaria" 6 "EBR - Secundaria" 7 "EBA - Inicial e Intermedio"/*
*/ 8 "EBA - Avanzado" 9 "Formación Magisterial ISP"/*
*/ 10 "Superior Tecnologica IST" 11 "Escuela Superior de Formacion Artistica (ESFA)"/*
*/ 12 "EBE - Inicial No Escolarizado" 13 "EBE - Inicial" 14 "EBE - Primaria" 15 "Centro de Educación Técnico Productica (CETPRO)"
label values d_niv_mod lblniv

label variable ges_dep "gestion/dependencia del IE o prog educ"
gen gest_pub=0
replace gest_pub=1 if ges_dep=="A1"
replace gest_pub=1 if ges_dep=="A2"
replace gest_pub=1 if ges_dep=="A3"
replace gest_pub=1 if ges_dep=="A4"
label define lblgest 1 "publica" 0 "privada"
label values gest_pub lblgest
label variable gest_pub "=1 IE de gestion publica" 


// EBE - PRITE

keep if tiporeg=="1" & nroced=="8AI" & cuadro=="C205"

gen matri_tot=d01+d02+d03+d04+d05+d06+d07+d08

gen d_tipdato=tipdato

destring d_tipdato, replace
rename d_tipdato nee
label variable nee "tipo de necesidad educativa especial"
label define lblnee 1 "Discapacidad sensorial - Auditiva" 2 "Discapacidad sensorial - Visual"/*
*/ 3 "Discapacidad física o Motora" 4 "Discapacidad Intelectual" 5 "Discapacidad Sordoceguera" 6 "Transtorno del Espectro Autista - TEA" 7 "Otras NEE Asociadas a Discapacidad"/*
*/ 8 "Niños y niñas de alto riesgo" 9 "Niños y niñas con multidiscapacidad"
label values nee lblnee

label variable niv_mod "codigo de nivel/modalidad"
gen d_niv_mod=niv_mod
replace d_niv_mod="1" if d_niv_mod=="A1"
replace d_niv_mod="2" if d_niv_mod=="A2"
replace d_niv_mod="3" if d_niv_mod=="A3"
replace d_niv_mod="4" if d_niv_mod=="A5"
replace d_niv_mod="5" if d_niv_mod=="B0"
replace d_niv_mod="6" if d_niv_mod=="F0"
replace d_niv_mod="7" if d_niv_mod=="D1"
replace d_niv_mod="8" if d_niv_mod=="D2"
replace d_niv_mod="9" if d_niv_mod=="K0"
replace d_niv_mod="10" if d_niv_mod=="T0"
replace d_niv_mod="11" if d_niv_mod=="M0"
replace d_niv_mod="12" if d_niv_mod=="E0"
replace d_niv_mod="13" if d_niv_mod=="E1"
replace d_niv_mod="14" if d_niv_mod=="E2"
replace d_niv_mod="15" if d_niv_mod=="L0"
destring d_niv_mod, replace
label define lblniv 1 "EBR - Inicial Cuna" 2 "EBR - Inicial Jardin"/*
*/ 3 "EBR - Inicial Cuna Jardin" 4 "EBR - Inicial No Escolarizado"/*
*/ 5 "EBR - Primaria" 6 "EBR - Secundaria" 7 "EBA - Inicial e Intermedio"/*
*/ 8 "EBA - Avanzado" 9 "Formación Magisterial ISP"/*
*/ 10 "Superior Tecnologica IST" 11 "Escuela Superior de Formacion Artistica (ESFA)"/*
*/ 12 "EBE - Inicial No Escolarizado" 13 "EBE - Inicial" 14 "EBE - Primaria" 15 "Centro de Educación Técnico Productica (CETPRO)"
label values d_niv_mod lblniv

label variable ges_dep "gestion/dependencia del IE o prog educ"
gen gest_pub=0
replace gest_pub=1 if ges_dep=="A1"
replace gest_pub=1 if ges_dep=="A2"
replace gest_pub=1 if ges_dep=="A3"
replace gest_pub=1 if ges_dep=="A4"
label define lblgest 1 "publica" 0 "privada"
label values gest_pub lblgest
label variable gest_pub "=1 IE de gestion publica" 


// EBE - PRIMARIA

keep if tiporeg=="1" & nroced=="8AP" & cuadro=="C202"

gen matri_tot=d01+d02+d03+d04+d05+d06+d07+d08+d09+d10+d11+d12

gen d_tipdato=tipdato

destring d_tipdato, replace
rename d_tipdato nee
label variable nee "tipo de necesidad educativa especial"
label define lblnee 1 "Discapacidad intelectual - RM Severo/Profundo" 2 "Discapacidad auditiva - Hipoacusia"/*
*/ 3 "Discapacidad auditiva - Sordera total" 4 "Discapacidad visual - Baja visión" 5 "Discapacidad visual - Ceguera" 6 "Sordoceguera"/*
*/ 7 "Transtorno del Espectro Autista - TEA" 8 "Multidiscapacidad - MDE" 9 "ESH - Menos de 10 días" 10 "ESH - De 10 a 15 días" 11 "ESH - Más de 15 días"  12 "Otras NEE asociadas a discapacidad"
label values nee lblnee

label variable niv_mod "codigo de nivel/modalidad"
gen d_niv_mod=niv_mod
replace d_niv_mod="1" if d_niv_mod=="A1"
replace d_niv_mod="2" if d_niv_mod=="A2"
replace d_niv_mod="3" if d_niv_mod=="A3"
replace d_niv_mod="4" if d_niv_mod=="A5"
replace d_niv_mod="5" if d_niv_mod=="B0"
replace d_niv_mod="6" if d_niv_mod=="F0"
replace d_niv_mod="7" if d_niv_mod=="D1"
replace d_niv_mod="8" if d_niv_mod=="D2"
replace d_niv_mod="9" if d_niv_mod=="K0"
replace d_niv_mod="10" if d_niv_mod=="T0"
replace d_niv_mod="11" if d_niv_mod=="M0"
replace d_niv_mod="12" if d_niv_mod=="E0"
replace d_niv_mod="13" if d_niv_mod=="E1"
replace d_niv_mod="14" if d_niv_mod=="E2"
replace d_niv_mod="15" if d_niv_mod=="L0"
destring d_niv_mod, replace
label define lblniv 1 "EBR - Inicial Cuna" 2 "EBR - Inicial Jardin"/*
*/ 3 "EBR - Inicial Cuna Jardin" 4 "EBR - Inicial No Escolarizado"/*
*/ 5 "EBR - Primaria" 6 "EBR - Secundaria" 7 "EBA - Inicial e Intermedio"/*
*/ 8 "EBA - Avanzado" 9 "Formación Magisterial ISP"/*
*/ 10 "Superior Tecnologica IST" 11 "Escuela Superior de Formacion Artistica (ESFA)"/*
*/ 12 "EBE - Inicial No Escolarizado" 13 "EBE - Inicial" 14 "EBE - Primaria" 15 "Centro de Educación Técnico Productica (CETPRO)"
label values d_niv_mod lblniv

label variable ges_dep "gestion/dependencia del IE o prog educ"
gen gest_pub=0
replace gest_pub=1 if ges_dep=="A1"
replace gest_pub=1 if ges_dep=="A2"
replace gest_pub=1 if ges_dep=="A3"
replace gest_pub=1 if ges_dep=="A4"
label define lblgest 1 "publica" 0 "privada"
label values gest_pub lblgest
label variable gest_pub "=1 IE de gestion publica" 
