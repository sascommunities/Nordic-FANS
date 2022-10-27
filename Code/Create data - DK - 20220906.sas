data person;
length CPR 8 Navn By $20; 
infile datalines dsd;
input CPR Navn By;
datalines;
0102034567,"Anders","Allerød"
1012625678,"Barbara","Broby"
3111727892,"Charlotte","Charlottenlund"
1706582345,"Dennis","Dalby"
;
run;
data indlag;
length CPR IndDT Sygh 8 Proc $8;
format IndDT datetime32.3;
infile datalines dsd;
input CPR IndDT : datetime32. Sygh Proc;
datalines;
0102034567, 01may2022:09:42:00, 123, "PP123"
1012625678, 13apr2022:07:33:00, 123, "PP234"
1012625678, 17apr2022:08:12:00, 123, "PP234"
3111727892, 05apr2022:13:00:00, 234, "PP123"
3111727892, 01may2022:08:00:00, 123, "PP123"
3111727892, 09may2022:09:37:00, 123, "PP235"
;
run;
data syghus;
length Sygh 8 Tekst $20;
infile datalines dsd;
input Sygh tekst;
datalines;
123, "Holbæk"
234, "Ringsted"
345, "Næstved"
run;
data priser;
length Procedure $8 FraDato TilDato Pris 8;
format Fradato Tildato date9. Pris Commax18.2;
infile datalines dsd;
input Procedure FraDato : date9. TilDato : date9. Pris;
datalines;
PP123, 01jan2022, 28feb2022, 900
PP123, 01mar2022, 31dec9999, 1000
PP234, 01jan2022, 28feb2022, 1100
PP234, 01mar2022, 31mar2022, 1200
PP234, 01apr2022, 31dec9999, 1500
PP345, 01jan2022, 31dec9999, 3000
;
run;
