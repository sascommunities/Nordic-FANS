
























/*Peka på en plats för datat*/
libname myLib "c:\workshop\myLib";

/*Generera lite data*/
data myLib.tab1;
  length a $ 20;
	a = 'text';
	b = 45;
	c = '25jul2022'd;
	format c yymmdd10.;
run;

/*Lite mer data med samma struktur frånsett variabelnamn*/
data myLib.tab2;
  length d $ 20;
	d = 'en annan text';
	e = 96;
	f = '19jun2023'd;
	format f yymmdd10.;
run;

/*Vi vill bearbeta datat på följande sätt:
    1. Ersätt alla förekomster av bokstaven e med en asterisk i den första variabeln.
    2. Subtrahera så många månader som är angivna i den andra variabeln
       från den tredje variabeln.
    3. Använd formatet date9 för den tredje variabeln.
*/

/*Först skapar vi makrovariabler med namnbyten, på formen
    bytNamn         : a=var1 b=var2 c=var3
    bytNamnTillbaka : var1=a var2=b var3=c
*/
data _null_;
	set sashelp.vcolumn(keep=libname memname varnum name) end=lastRow;
	where libname = "MYLIB"
	  and memname = "TAB1";
	length bytNamn bytNamnTillbaka $32767;
	retain bytNamn bytNamnTillbaka;
	bytNamn = catx(' ', bytNamn, cats(name, '=var', varnum));
	bytNamnTillbaka = catx(' ', bytNamnTillbaka, cats('var', varnum, '=', name));
	if lastRow then do;
		call symputx('bytNamn', bytNamn);
		call symputx('bytNamnTillbaka', bytNamnTillbaka);
	end;
run;

%put &=bytNamn &=bytNamnTillbaka;

/*Bearbeta datat*/
data work.tab1(rename=(&bytNamnTillbaka));
	set myLib.tab1(rename=(&bytNamn));
	var1 = tranwrd(var1, 'e', '*');
	var3 = intnx('month', var3, -var2, 's');
	format var3 date9.;
run;














/*********************************************************************************/
/*                                                                               */
/*                                                                               */
/*                                                                               */
/*********************************************************************************/

/*Definiera makrot*/
%macro bearbetaData(inDS=, outDS=);
	data _null_;
		set sashelp.vcolumn(keep=libname memname varnum name) end=lastRow;
		where libname = "%upcase(%scan(&inDS, 1))"
		  and memname = "%upcase(%scan(&inDS, 2))";
		length bytNamn bytNamnTillbaka $32767;
		retain bytNamn bytNamnTillbaka;
		bytNamn = catx(' ', bytNamn, cats(name, '=var', varnum));
		bytNamnTillbaka = catx(' ', bytNamnTillbaka, cats('var', varnum, '=', name));
		if lastRow then do;
			call symputx('bytNamn', bytNamn, 'L');
			call symputx('bytNamnTillbaka', bytNamnTillbaka, 'L');
		end;
	run;

	data &outDS(rename=(&bytNamnTillbaka));
		set &inDS(rename=(&bytNamn));
		var1 = tranwrd(var1, 'e', '*');
		var3 = intnx('month', var3, -var2, 's');
		format var3 date9.;
	run;
%mend;

/*Använd makrot*/
%bearbetaData(inDS=myLib.tab1, outDS=work.tab1)
%bearbetaData(inDS=myLib.tab2, outDS=work.tab2)


/*********************************************************************************/
/*                                                                               */
/*    En snyggare lösning!                                                       */
/*                                                                               */
/*********************************************************************************/


%let dsID = %sysfunc(open(mylib.tab1));
%let var3_namn = %sysfunc(varname(&dsID, 3));
%let rc = %sysfunc(close(&dsID));

data work.tab1;
  set mylib.tab1;
  array textvars [*] _character_;
  array numvars  [*] _numeric_;
  textvars[1] = tranwrd(textvars[1], 'e', '*');
  numvars[2] = intnx('month', numvars[2], -numvars[1], 's');
  format &var3_namn date9.;
run;



