
* Proc SGPLOT som dialog understøttende redskab;
* - Med afsæt i Brøndby Kommunes indsats mod sygefravær gives 
	fire eksempler på, hvordan SGPLOT kan virke dialog understøttende ved
	relativt simpelt at udnytte funktionaliteten i SGPLOT.
	Alle cases er dannet med afsæt i lederønsker. ;
* Brøndby Kommune, HR-afdelingen, Kim Eriksen, kimer@brondby.dk, 43282282; 	

 	
%let bib	= G:\Personaleafd\HR-UDVIKLING\STATISTIK\Produktion\Oplaeg\SASnetvaerk;
libname bib "&bib";	

options fmtsearch=(bib work);	

* 0: Klargøring af data;
* - opsplit data for at danne analysegruppe;
data x;
set sashelp.class;
attrib syg 		informat=best10. format=commax10.0 label="Kalendersygedage";
attrib syg_lang informat=best10. format=commax10.0 label="Langtidsfravær";
attrib syg_kort informat=best10. format=commax10.0 label="Korttidsfravær";
do i=2017 to 2022;
	aar=i;
	syg=rand('uniform',0,365); *random 0-220 arbejdsdage/365 kalenderdage;
	* Sætter fake anmærkning af korttids- og langtidssfravær;
	syg_lang=0;
	if syg>28 then do;
			syg_lang=syg-28;
			syg_kort=28;
	end;
	if syg<=28 then syg_kort=syg;

	if aar=2021 then syg_last=syg;	* Manipulation til senere brug;
	if aar=2022 then do;
		syg_new=syg;
		Syg_newK=syg_kort;
		syg_last=.;					* Sætter da syg_last trækkes med ned i output;
	end;
	output ;
end;
drop i;
run;

data x1 (rename=(syg_kort=sygvis))
	 x2 (keep=name aar syg_lang rename=(syg_lang=sygvis)) ;
set x;
run;

data x_gruppe;
set x1 (in=a) x2 (in=b);
attrib analyse 		informat=$15.	format=$15.;
if a then analyse="Kortidsfravær";
if b then analyse="Langtidsfravær";
run;
	
* Henter oplysnigner til reference linje i graf;
proc sql noprint;
	select mean(syg) format=10.1 into :gns
	from x 
	where aar = 2022
	;
	select mean(sygvis) format=10.1 into :gns_kort
	from x_gruppe
	where analyse="Kortidsfravær" and aar=2022
	;
quit;


ods results=on;

* 1: Sorteret graf med individ i indenværende og sidste periode;
* - Formål: Offentlig dialog om hvorfor fravær er som det er;
* - hvordan skabes fraværet => få eller mange;
* - Visning - sorteret fra højest til lavest i gruppe orden;

* 1.1. Standard SGPLOT søjle med group;
* - Discreorder i yaxis gør at data vises i rækkefølge;
proc sort data=x_gruppe;
by descending aar  decending syg;
run;

ods graphics  /  border=off  height=24 cm width =36 cm;
proc sgplot data = x_gruppe;
	where aar=2022;
	hbar name / response=sygvis stat=sum datalabel seglabel group=analyse grouporder=data ;
	keylegend  / location=outside across=3 position=top title='' ;
	xaxis label=" "  display=all  grid minor  min=0  ;
	yaxis label=" " DISCRETEORDER=DATA;
	refline &gns. / axis=x label="Samlet - %sysfunc(strip(&gns.))";
	format sygvis commax10.0;
quit;


* 1.2. Tilføjere ekstra søjle for historik og udnytte viden i visning;
* yaxistable - categoryorder - transparency og barwidth ;
* Udvidelse af oplysninger i data;
data x;
set x;
attrib afsked	informat=$1.	 format=$1.		   label="Afsked";				* udvidelse;
attrib proces	informat=$1.	 format=$1.		   label="Proces";				* udvidelse;
if name="Alice" then afsked="X";
if syg>180  then proces="X";
run;


ods graphics  /  border=off  height=24 cm width =36 cm;
proc sgplot data = x;	
	hbar name / response=syg_new stat=sum datalabel TRANSPARENCY=0.3 grouporder=data CATEGORYORDER=RESPDESC LEGENDLABEL="Langtidsfravær" FILLATTRS= (COLOR= orange);
	hbar name / response=Syg_newK stat=sum datalabel TRANSPARENCY=0.0 grouporder=data LEGENDLABEL="Kortidsfravær" FILLATTRS= (COLOR= DodgerBlue);
	hbar name / response=syg_last stat=sum datalabel TRANSPARENCY=0.6 barwidth=0.6 LEGENDLABEL="Sygefravær sidste periode" FILLATTRS= (COLOR= green) ;
	keylegend  / location=outside across=3 position=top title='' ;
	xaxis label=" "  display=all  grid minor  min=0  ;
	yaxis label=" " DISCRETEORDER=DATA;
	refline &gns. / axis=x label="Samlet - %sysfunc(strip(&gns.))";
	refline &gns_kort. / axis=x label="Samlet kort - %sysfunc(strip(&gns_kort.))";
	yaxistable proces afsked / stat=sum classdisplay=cluster location=inside ;
	format syg_new syg_newk syg_last commax10.0;
quit;


* 2: Mønster i fravær. Medarbejdere med vedvarende højt sygefravær;
* - Fraværssamtaler - vedvarende højt fravær ;
* - Læring - vedvarende lavt fravær;
* - HEATMAPPARM - AXISTABLE - Text - yaxistable  ;
* - -- Danner en kasse ud fra x y værdier (var) og en tredje variable (response eller group) til at farve kassen;

* Sætter en variable til styring af farvekode;
data x;
set x ;
if syg<=20 then lf=1;
else if 20<syg<=120 then lf=2;
else if syg>120 then lf=3;
else lf=.;
run;

* Format reelt overflødigt grundet udfordring ved keylegend - og  colorresponse skal være num ;
* https://communities.sas.com/t5/Graphics-Programming/Discrete-legend-for-proc-sgplot-heat-map/td-p/571030;
* proc format ... lf ;

proc sgplot data=x nocycleattrs ;
	HEATMAPPARM X=aar Y=name  COLORRESPONSE=lf   / colormodel=(lightgreen lightyellow mediumred)  outline  SHOWXBINS name="v1"  discretex;  
	text x=aar y=name text=syg /*name*/  ;
	yaxistable proces afsked / stat=sum classdisplay=cluster location=inside valuehalign=center;
	xaxis display=(nolabel) type=discrete;
		legenditem type=marker name='1' / label="0->20 dage" markerattrs=(symbol=squarefilled size=9pt color=lightgreen); *new;
		legenditem type=marker name='2' / label="21->120 dage" markerattrs=(symbol=squarefilled size=9pt color=lightyellow); 
		legenditem type=marker name='3' / label="Over 120 dage" markerattrs=(symbol=squarefilled size=9pt color=mediumred); 
	keylegend "1" "2" "3" / location=outside across=3 position=bottom title='' ;;
	*format lf lf. ;
quit; 


* 3: Visualisering af tyngden i fraværet;
* - En gammel kending - ny anvendelse (GTILE);
* - Er der grupperingsmønstre - nuancering af "et tal";
* GTILE - tileby => text - ;
* colorpoints sætter intervaller - desværre ikke selv styre "trafiklys";

data x;
set x ;
attrib navn2  	informat=$35.	format=$35.;
navn2	= catx(" ",name,"Kdage=",put(syg,commax10.0),"PCT=osv");
dummyvar=1;  * organisatoriskt evt fuldtid;
run;

proc gtile data=x;
 where aar=2022;
  tile dummyvar tileby=(navn2) 
	  / colorvar=syg 
		colorramp=(BIGB  LIGB  VLIGB VPAB PAB /*green  mediumyellow  lightorange lightred red*/)
	    colorpoints=(0 0.25 0.5 0.75 1 )
		detaillevel=1
	     labellevel=1
		 CDEFAULT=white
		;
  format syg commax10.0 ;
run;quit; 

* 4: Kalendervisualisering;
* - Automatisere ledernes kalender+sprittush;
* - Afdække mønstre i fraværet (barns syg, aftenvagt, ferie, mandage/fredage);
* - Udnytte heatmapparms "blok" muligheder fremfor annotate ;

* Danner månedstekst for løbende 12 måneder;
* On the fly for at få vist måneder i den rigtige rækkefølge;
proc sql noprint;
	create table nymdfmt as
	select distinct lb12fmt, md_txt_kort
	from bib.demokalender
	order by lb12fmt
	;
quit;

data nymdfmt;
set nymdfmt;
 length label $4;
  length fmtname $10;
  length start $4;
	type    = "N";
	fmtname = "lb12fmt";
	start   = lb12fmt;
	end     = start;
	label   = md_txt_kort;
	output;
run;

proc format library=work cntlin=nymdfmt ; *obs - fmtlib printer indhold til tjek;
run;

* Henter farvevalg i ordnet rækkefølge for at sætte korrekte farver på kalenderen;
proc sql noprint;
	select distinct farvekode, farvenr_org2 into :farvevlg separated by " " , :farvenr separated by " "
	from bib.demokalender
	order by  frvtype_org2
	;
quit;

* For at farvekoder ligger korrekt skal data sorteres efter farvekode;
proc sort data=bib.demokalender; 
by frvtype_org2 ; 
run ;

proc sgplot data=bib.demokalender  nocycleattrs;
	title2 j=c	"Fravær seneste 12 måneder - Macro for periode + macro for navn";
	title3 j=c	"Sygpct.=Macro  - Arbejdssygdage=macro ";
	styleattrs datacolors=( &farvevlg. ); *rækkefølge qua 1 tælles før 11 i opgørelse;
	HEATMAPPARM x=lb12fmt Y=dag COLORGROUP=farvenr_org2    /  outline  SHOWXBINS name="v1" ; 
	text x=lb12fmt y=dag text=frvtype_org2 ;
	keylegend "v1" / SORTORDER=ASCENDING ;
	yaxis  reverse min=1 values=(1 to 31 by 1) display=(nolabel);
	xaxis display=(nolabel) ;
	format farvenr_org2 frvorg2_c.  lb12fmt lb12fmt. ;
run; quit;

