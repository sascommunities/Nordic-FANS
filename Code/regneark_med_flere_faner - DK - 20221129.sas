/******************************************************************************/
/* Regneark med flere faner                       Erik Lund-Jensen 28-11-2022 */
/*                                                                            */
/* Demoprogram til SAS Network 29.11.2022                                     */
/*                                                                            */
/* Teknikker til at splitte et input op på en grupperingsvariabel og udskrive */
/* et regneark med en fane pr. værdi i grupperingsvariablen                   */
/******************************************************************************/

LIBNAME meetlib BASE "C:\Programming_29112922\data";

/******************************************************************************/
/* Dannelse af regneark verdion 1                                             */
/* Version med makro-loop                                                     */
/******************************************************************************/

* Dan BrugerID liste;
proc sql noprint;
   select distinct BrugerID into :Brugerliste separated by ' '
   from meetlib.skidtbrev;
quit;
%let BrugerCnt = &sqlobs;
 
* Initier ODS;
ods _all_ close;
ods excel file='C:\temp\Skidtbrev_V1.xlsx';
 
* Macro til at loope over brugerliste og udskrive separat fane for hver bruger;
%macro skrivalleark;
   %do i=1 %to &BrugerCnt;
      %let Bruger = %scan(&Brugerliste, &i, %str( ));
      ods excel options (sheet_name = "&Bruger");
      proc print data=meetlib.skidtbrev noobs; 
         where BrugerID = "&Bruger";
      run;
   %end;
%mend;
 
%skrivalleark;
ods excel close;
ods listing;


/******************************************************************************/
/* Dannelse af regneark version 2                                             */
/* Version med dannelse af dynamisk kode vha. call execute                    */
/******************************************************************************/

* Dan BrugerID liste;
proc sql noprint;
   select distinct BrugerID into :Brugerliste separated by ' '
   from meetlib.skidtbrev;
quit;
%let BrugerCnt = &sqlobs;

data _null_;
  call execute('ods _all_ close;');
  call execute('ods excel file="C:\temp\Skidtbrev_V2.xlsx";');

  tabel = skidtbrev;

  * Loop dannelse af programstump til at udskrive separat fane for en enkelt bruger;
  do i=1 to &BrugerCnt;
    Bruger = scan("&Brugerliste",i,' ');
    call execute('ods excel options (sheet_name="' || trim(Bruger) || '");');
    call execute('proc print data=meetlib.skidtbrev (where=(BrugerID = "' || trim(Bruger) || '")) noobs;');
    call execute('run;');
  end;

  call execute('ods excel close;');
  call execute('ods listing;');
run;


/******************************************************************************/
/* Dannelse af regneark version 3                                             */
/* Overlad det til ODS og proc print vha. By-variabel                         */
/******************************************************************************/

ods _all_ close;
ods excel file='C:\temp\Skidtbrev_V3.xlsx' options(sheet_name='#byval1');

proc print data=meetlib.skidtbrev noobs;
  by BrugerID;
run;

ods excel close;
ods listing;


