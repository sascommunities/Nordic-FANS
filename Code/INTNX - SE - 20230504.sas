/*********************************************************************************/
/*                                                                               */
/*                              INTNX-funktionen                                 */
/*                                                                               */
/*********************************************************************************/

/*skapa data*/
data casuser.forsaljningsinformation;
  do kundID = 1 to 20;
    forsaljningsdatum = rand('integer', '01jan2023'd, '30apr2023'd);
    output;
  end;
  format forsaljningsdatum yymmdd10.;
run;

data casuser.fakturautskick;
  set casuser.forsaljningsinformation;
  forfallodatum = intnx('month', forsaljningsdatum, 1, 'e');
  format forfallodatum yymmdd10.;
run;

proc print data=casuser.fakturautskick;
  id kundID;
run;
