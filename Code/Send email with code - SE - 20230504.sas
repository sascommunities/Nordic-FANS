%macro DeleteFile(file);
%if %sysfunc(fileexist(&file)) ge 1 %then %do;
   %let rc=%sysfunc(filename(temp,&file));
   %let rc=%sysfunc(fdelete(&temp));
%end; 
%else %put Filen "&file" finns ej.;
%mend DeleteFile; 
*%DeleteFile(c:\test.txt);


/* ersätt <din epost-server> */
options emailsys=smtp emailhost=<din epost-server> emailport=25;


%macro SkickaEpost(EMAIL_TO=, EMAIL_CC=, EMAIL_BCC=);
%macro dummy;%mend dummy;
%local EMAIL_ATTACHMENT EMAIL_SUBJECT REPORT_TITLE EMAIL_CC EMAIL_BCC ;
%let EMAIL_ATTACHMENT = %str(C:\temp\Motorvolym_snitt_per_märke);
%let EMAIL_SUBJECT=%str(Motorvolym per märke);
%Let REPORT_TITLE = %str(Motorvolym (snitt) per märke.);
%let EMAIL_CC=%str( );
%let EMAIL_BCC=%str( );

/* Remove file first */
%DeleteFile(file=&EMAIL_ATTACHMENT.); 

PROC SQL noprint;
   CREATE TABLE WORK.ENGINESIZE AS 
   SELECT t1.Origin, 
          t1.Make length=100, 
          t1.Model, 
          t1.Type, 
          t1.EngineSize ,
			 CatS('https://www.', t1.Make, '.com') as URL_link 
      FROM SASHELP.CARS t1
		WHERE t1.Origin = 'Europe'
      ORDER BY t1.Origin,
               t1.Make,
               t1.Model,
               t1.Type;
QUIT;

/* Öppna Excel destination */
ods excel style=Plateau file="&EMAIL_ATTACHMENT..xlsx" 
		options(sheet_label='Motorvolym ' 
		sheet_interval='bygroup' 
		frozen_headers='YES' 
		autofilter='ALL'
		embedded_titles="OFF"
		suppress_bylines='YES'
		absolute_column_width='35, 12, 12, 12, 12, 12, 12'
		absolute_row_height='18'
		formulas='ON'
		tab_color='rgba(249, 180, 45, 0.5)'
		flow = 'TABLE'); 

Proc Print data=WORK.ENGINESIZE (drop=URL_link) noobs;
	label;
	ID Model;
	Var Origin Type EngineSize;
	By Make;
	label EngineSize = 'EngineSize (L)';
run;

ods excel close; 

/* Öppna PowerPoint destination */
ods powerpoint style=PowerPointLight file="&EMAIL_ATTACHMENT..pptx" ; 
 
ods graphics / reset width=700px height=600px imagemap;
proc sgplot data=WORK.ENGINESIZE;
	vbar Type / response=EngineSize fillattrs=(color=CXFF8224 
		transparency=0.25) datalabel fillType=gradient stat=mean nostatlabel;
	xaxis display=(nolabel);
	yaxis grid;
	by Make;
run;
ods graphics / reset;


ods powerpoint close; 

/* Nu mejlar vi... */
FILENAME mailbox EMAIL to=("&EMAIL_TO.") cc=("&EMAIL_CC.") bcc=("&EMAIL_BCC.") 
	Subject="&EMAIL_SUBJECT"
	Content_Type="text/html"
	ATTACH=("&EMAIL_ATTACHMENT..xlsx" "&EMAIL_ATTACHMENT..pptx")
	;

Title justify=center bcolor=white color=black "&REPORT_TITLE.";

ods html style=HTMLBlue file=mailbox ;

Proc Report data=WORK.ENGINESIZE (drop=URL_link)
	style (header) = [background=white foreground=black ] 
	style (column) = [background=white foreground=black ]
	;
	Define Make / display format=$Char100. style(column)={foreground=blue Flyover="Klicka för att öppna tillverkarens webbsida."}; 

   Compute Make;
	   Call define(_col_,'url', CatS('https://www.', Make, '.com'));
	endcomp;
run;

ods html close;
filename mailbox clear;
%Mend SkickaEpost;

%SkickaEpost(EMAIL_TO=Daniel@swe.sas.com);


