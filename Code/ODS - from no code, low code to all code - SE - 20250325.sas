
/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/
/*                                                                  */
/* Cars                                                             */
/*                                                                  */
/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/
ods listing close;

%let _ODSSTYLE=HTMLBlue;
title;
footnote;

/* General options */
/* Autofilter ONLY on column 1-3 */
/* Freeze row 1 (Headers) */
ods Excel file="&ODS_REPORT_PATH.\Bilar.xlsx" 
	style=&_ODSSTYLE 
	options(autofilter='1-3' 
			frozen_headers='yes')
;

/* Options for this sheet... */
ods Excel options(sheet_name='Bilar i Asien' );

proc Print data=Sashelp.cars noobs label split='*';

	id Origin Make Model;
	var Cylinders / style={flyover='Det ska MINST vara 8 stycken...'};  
	var Horsepower EngineSize MPG_City MPG_Highway; 
	var Invoice / style={tagattr='format:###,###,##0'};
	format invoice 14. ;

	where Origin = "Asia";

run;


/* Options for this sheet... */
/* Fix labels with option FLOW= */
ods Excel options(sheet_name='Bilar i Europa' flow='table');

proc Print data=Sashelp.cars noobs label split='*';

	id Origin Make Model;
	var Cylinders / style={flyover='det ska vara V8...'};  
	var Horsepower EngineSize MPG_City MPG_Highway; 
	var Invoice / style={tagattr='format:###,###,##0'};
	format invoice 14. ;

	where Origin = "Europe" ;

run;

ods Excel close;


/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/
/*                                                                  */
/* Cars - excel func - list BY and chart for Asia - empty sheet     */
/*                                                                  */
/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/
ods listing close;

ods excel file="&ODS_REPORT_PATH.\Bränsleförbrukning.xlsx"
	Options(frozen_headers='ON' 
			autofilter='ALL' 
			sheet_interval='bygroup' 
			suppress_bylines='yes'
			sheet_label="Producerande region"
			absolute_column_width='20, 20, 20, 18, 18, 18, 18, 18'
			formulas='ON')
;

/* Shown only when printed */
title "Miles per Gallon and more...";
footnote;


/* Excel function in data */
options obs=max;
data WORK.Cars2;
	set SASHELP.Cars;
	Diff = mpg_City - mpg_highway;
	rad = strip(put(_N_+1, best.));

	Diff_Direktref = CatS('=Sum(F', rad , '-E', rad , ')');
	
run;
proc sort;
	by Origin;
run;
proc print data=WORK.Cars2 noobs;

  var Origin Make DriveTrain ; 
  var Cylinders mpg_City mpg_highway / style(HEADER)={just=c};
  var Diff / style={tagattr='format:#,##0;-#,##0'} /* format:#,##0_);[Red]\(#,##0\) */
			 style(HEADER)={just=c};
  var Diff_Direktref / style={tagattr='format:#,##0' just=right} 
					   style(HEADER)={just=c};

  by Origin;

  
run;

Title "Avg horsepower around the world";
ods Excel options(sheet_name='Bilar i Asien' );

proc sgplot data=WORK.Cars2;
	hbar Origin / response=Horsepower
				fillattrs=(color=orange) 
				fillType=gradient 
				stat=Mean 
				dataskin=Matte
	;

	xaxis discreteorder=data grid;
	yaxis discreteorder=data;
run;


/* - - - - - - - - - - - - */
/* Add a blank sheet       */
ods excel options(BLANK_SHEET='For notes...');


ods Excel close;




/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/
/*                                                                  */
/* PowerPoint - 2 containers                                        */
/*                                                                  */
/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/
%let TopN=10;

ods powerpoint file="&ODS_REPORT_PATH.\PowerPoint med 2 kolumner.pptx"
	Layout=twocontent 
	Style=Sapphire
	options(backgroundcolor="#FFFFFF" 
        transition="push" 
        effect_option="from_left" )
; 

Title "Top &TopN. bränsleförbrukning landsväg" ;

Proc sql sortseq=swedish noprint outobs=&TopN.;
  Create table WORK.TopX as
  select t1.Make, 
		t1.Model, 
		(t1.MPG_Highway / 6.21) / 4.54 as Liter_Milen 'l/mil' format=commax6.2, 
		t1.Horsepower
  from SASHELP.CARS t1
  order by Calculated Liter_Milen asc
  ;
Quit;
%Let textsize=10pt;
proc print data=WORK.TopX obs='Rank' 
	LABEL
	style(data)={font_size=&textsize.}
	style(header)={font_size=&textsize.}
	style(obsdata)={font_size=&textsize.}
	style(obsheader)={font_size=&textsize.}
	; 
 	var Model Liter_Milen ;
run; 
 
ods graphics / width=500pt height=400pt border=off ;

/* DATASKIN= NONE | CRISP | GLOSS | MATTE | PRESSED | SHEEN */
%Let DATASKIN = GLOSS;


proc sgplot data=WORK.TOPX;
	/*--Bar chart settings--*/
	hbar Model / response=Liter_Milen 
				fillattrs=(color=CXcad5e5) 
				fillType=gradient 
				stat=Mean 
				name='lm-bar' 
				dataskin=Matte
	;

	/*--Category Axis--*/
	xaxis discreteorder=data grid;

	/*--Response Axis--*/
	yaxis discreteorder=data;
run;


ods PowerPoint close;




/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/
/*                                                                  */
/* ODStext - static                                                 */
/*                                                                  */
/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/
ods listing close;

%let _ODSSTYLE=Plateau;
title;footnote;

ods Excel file="&ODS_REPORT_PATH.\ODS Odslist.xlsx" 
	options(autofilter='yes' frozen_headers='yes' )
;

/* Sheet 1 */
ods Excel options(sheet_name='Sheet1' );
proc print data=sashelp.class;run;


/* Sheet 2*/
ods Excel options(sheet_interval='NOW' sheet_name='Sheet2' );

proc odstext data=sashelp.class;
   p 'Instruktioner för xxxx' / style=systemtitle;
   p 'Hej hopp i en underrubrik' / style={fontstyle=italic};  
 
   list;
	  item 'Rad1';
     item 'Rad2';
   end;

run;

ods excel close;




/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/
/*                                                                  */
/* ODStext - dynamic                                                */
/*                                                                  */
/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/

ods listing close;

%let _ODSSTYLE=Plateau;
title;footnote;

data infotext;
  infile datalines delimiter="^";
  length textrad $ 300;
  input textrad $ ;
datalines;
Med en oöverträffad kombination av hårdhet och seghet sätter Hardox® slitplåt standarden för abrasionståligt (AR) stål över hela världen.
Tack vare dess unika kvaliteter fungerar det också som lastbärande del i många applikationer, vilket ökar möjligheterna för strukturella designinnovationer.
Abrasiva tillämpningar och aggressiva slitagemiljöer är ingen match för Hardox.
Oavsett hur slitageförhållandena ser ut har Hardox slitplåt bättre slitstyrka, högre nyttolast och längre brukstid.
Hardox-serien innefattar den ursprungliga slitplåten, tunnare och tjockare än någonsin tidigare på 0,7-160 mm men även rör och rundstång.
Din utrustning, och verksamhet, hålls igång tack vare Hardox överlägsna kvalitet, säkerhet och prestanda.
Run;

ods Excel file="&ODS_REPORT_PATH.\ODS Odslist med data.xlsx" 
	options(autofilter='yes' frozen_headers='yes') ;

/* Sheet 1 */
ods Excel Options(sheet_name='Rapport' ); 
proc print data=sashelp.class noobs;run;

/* Sheet 2*/
ods Excel Options(sheet_name='Beskrivning' sheet_label='Nisse' 
			sheet_interval='NOW' 
			absolute_column_width='100' ); 

proc odstext;
   p 'Hardox slitplåt' / style=systemtitle;
   p ' ';
   p 'Det erkänt hårda och sega stålet för tuffa miljöer' / style={fontstyle=italic};  
   p ' ';
run;
proc odstext data=infotext;
    
   p textrad ;

run;

ods excel close;




/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/
/*                                                                  */
/* ODSlist with PowerPoint - Item lists, both static and data driven */
/*                                                                  */
/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/
ods html close;
options nodate;

title 'PROC ODSLIST ITEM Static content';
ods powerpoint file="&ODS_REPORT_PATH.\DefaultStyleODSlist.ppt" ;
/*ods powerpoint(2) file="&ODS_REPORT_PATH.\PowerpointdarkStyle.ppt" style=powerpointdark;*/

proc odslist name=Slides store=sasuser.Myexampleslides print;
   cellstyle 1 as {fontsize=1cm color=purple fontweight=bold};
   item 'Fraud';
   item 'Customer Intelligence';
   item 'Social Media';
   item 'Data Mining';
   item 'High-Performance Computing';
   item 'Risk';
   item 'Data Management';
run;

/* New slide NOW */
ods powerpoint startpage=now;

/* Dynamiskt med data */
title 'PROC ODSLIST ITEM Dynamic content';
title2 'First name starting with J';

proc odslist data=sashelp.class (where=(substr(name, 1, 1) = 'J'));
   item Name;
run;

ods _all_ close;