/******************************************************************************/
/* Funktioner i formater                          Erik Lund-Jensen 28-11-2022 */
/*                                                                            */
/* Demoprogram til SAS Network 29.11.2022                                     */
/*                                                                            */
/* Teknikker til at danne en fcmp-funktion og bruge funktionen i et format    */
/* et regneark med en fane pr. værdi i grupperingsvariablen                   */
/******************************************************************************/

/******************************************************************************/
/* Funktion dato2aaruge                                                       */
/*                                                                            */
/* Omformer en dato til aaruge                                                */
/* fx 29nov2022 -> 202248                                                     */ 
/* Funktionen loades i aktuelt fcmplib, der forudsættes allokeret             */
/*                                                                            */
/* Kaldes: dato2aaruge(sasdato);                                              */
/* Returnerer: streng yyyyuu                                                  */
/*                                                                             /
/******************************************************************************/

proc fcmp outlib=fcmplib.funcs.datotid;
    function dato2aaruge(dato) $ 6;
       torsdag=intnx('week.2',dato,0,'beginning')+3;
       aaruge=put(year(torsdag)*100+week(torsdag,'v'),6.);        
       return(aaruge);
    endsub;
quit;

/******************************************************************************/
/* Test funktionen                                                            */
/******************************************************************************/

data _null_;
  dato = date();
  aaruge = dato2aaruge(dato);
   put dato ddmmyyd10. '  ' aaruge;
run;


/******************************************************************************/
/* Format aaruge                                                              */
/*                                                                            */
/* Formaterer en sasdato som åruge YYYYUU ved hjælp af funktionen             */
/* dato2aaruge. Forudsætter fcmplib allokeret.                                */ 
/*                                                                            */
/******************************************************************************/

proc format;
  value aaruge other=[dato2aaruge()];
run;


/******************************************************************************/
/* Test formatet                                                              */
/******************************************************************************/

data _null_;
  dato = date();
  put dato ddmmyyd10. '  ' dato aaruge.;
run;

/******************************************************************************/
/* sizekmgt                                                     erlu 3.7.2020 */
/*                                                                            */
/* Formaterer byteantal til KB / MB / GB / TB notation. Fungerer som det      */
/* indbyggede format sizekmg. der ikke kan håndtere størrelser over 999 GB.   */
/*                                                                            */
/******************************************************************************/

proc format library=library;
	picture sizekmgt (round default=8)
  	low - 1023 = '0009 bt'
  	1024 - 1048575 = '009.9 KB' (mult = %sysevalf(10/1024))
  	1048576 - 1073741823 = '009.9 MB' (mult = %sysevalf(10/1048576))
  	1073741824 - 1099511627775 = '009.9 GB' (mult = %sysevalf(10/1073741824))
  	1099511627776 - high = '009.9 TB' (mult = %sysevalf(10/1099511627776))
	;
run;


/******************************************************************************/
/* Funktion sizekmgt                                            erlu 1.7.2020 */
/*                                                                            */
/* Utility til brug i SAS-format sizekmgt til udskrift af filstørrelser       */
/* op til 999 PB                                                              */
/* Returner streng svarende til resultatet ved brug af det indbyggede         */
/* SAS-format sizekmg5.1, der kun kan håndtere størrelser op til GB           */
/*                                                                            */
/* Modtager antal bytes som argument                                          */
/*                                                                            */
/******************************************************************************/

proc fcmp outlib=fcmplib.funcs.utility;
  function sizekmgt(bytes) $;
    length bytefmt $8;
    if bytes = . then bytefmt = ' ';
    else do;
    f = 1;
    xbytes = bytes;
    do while (xbytes > 1000);
      f = f + 1;
      xbytes = xbytes / 1024;
    end;
    if f = 1 then bytefmt = strip(put(xbytes/1024,5.3))||'KB';
      else bytefmt = strip(put(xbytes,5.1))||choosec(f-1,'KB','MB','GB','TB','PB');
    end;
    return (bytefmt);
    endsub;
  run;
quit;

proc format;
  value sizekmgt other=[sizekmgt()];
run;

/******************************************************************************/
/* Test formatet                                                              */
/******************************************************************************/

data _null_;
  bytes = 12568978234536;
  put bytes sizekmg. '  ' bytes sizekmgt.;
run;
