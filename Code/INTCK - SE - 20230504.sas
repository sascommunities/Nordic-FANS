/*********************************************************************************/
/*                                                                               */
/*                       INTCK-funktionen                                        */
/*                                                                               */
/*********************************************************************************/
cas;

data casuser.tidTillSemestern;
  idag = today();
  startSem = '15jun2023'd;
  dagarTillSem      = intck('day', idag, startSem);
  veckodagarTillSem = intck('weekday', idag, startSem);
  veckorTillSem     = intck('week', idag, startSem, 'c');
  manaderTillSem    = intck('month', idag, startSem, 'c');
  format idag startSem yymmdd10.;
run;


/*skapa data*/
data casuser.betalningsInformation;
  do kundID = 1 to 20;
    forfallodatum = rand('integer', '01mar2023'd, '31mar2023'd);
    betalningInkommen = forfallodatum + rand('integer', -5, 20);
    output;
  end;
  format forfallodatum betalningInkommen yymmdd10.;
run;

/*Kunder som är mer än 10 veckodagar sena med sin betalning*/
proc print data=casuser.betalningsInformation;
  id kundID;
  where intck('weekday', forfallodatum, betalningInkommen) > 10;
run;
