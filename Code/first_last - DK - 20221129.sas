/******************************************************************************/
/* Første og sidste                                Erik Lund-Jensen 5-11-2022 */
/*                                                                            */
/* Demoprogram til SAS Network 29.11.2022                                     */
/*                                                                            */
/* Teknikker til at se om den aktuelle observation er den første eller sidste */
/* i et input-datasæt eller første eller sidste observation med en given      */
/* værdi i en by-gruppe (nøglevariabel eller serie af nøglevariable)          */
/******************************************************************************/

* testdata til principper;
data have1;
  infile datalines;
  input Key1$ Key2$ value;
  datalines;
A A 1
A A 2
A B 1
A B 2
A B 2
A C 1
B A 1
B A 2
B B 1
;
run;

/******************************************************************************/
/* Første og sidste observation                                               */
/******************************************************************************/

* Brug af tællervariabel for altuel inputobs og flag for sidste observation;
data want1;
  set have1 end=end_of_data;
  FirstObs = (_N_ = 1);
  LastObs = end_of_data;
run;

* Brug af tællervariabel for altuel inputobs og antallet af observationer;
data want2;
  set have1 nobs=max;
  FirstObs = (_N_ = 1);
  LastObs = (_N_ = max);
run;

/******************************************************************************/
/* Første og sidste by-gruppe                                                 */
/******************************************************************************/

data want3;
  set have1;
  by Key1 Key2;
  FirstKey1 = first.Key1;
  LastKey1 = last.Key1;
  FirstKey2 = first.Key2;
  LastKey2 = last.Key2;
  KeyDublet = NOT (first.Key2 and last.Key2);
run;

/******************************************************************************/
/* Praktisk eksempel                                                          */
/* Dan nye ovservationer med by-gruppe-totaler og grandtotal                  */
/******************************************************************************/

* Testdata til praktisk eksempel;
data have2;
  infile datalines;
  length Afdeling $40;
  input Afdeling$ Maaned Antal;
  datalines;
HR 1 33
HR 2 42
HR 3 56
HR 4 52
HR 5 44
HR 6 38
Marketing 1 21
Marketing 2 27
Marketing 3 34
Marketing 4 28
Marketing 5 39
Marketing 6 41
Salg 1 19
Salg 2 27
Salg 3 51
Salg 4 22
Salg 5 56
Salg 6 37
;
run;

* Praktisk eksempel;
data want4; 
  set have2 end=eof; 
  by Afdeling;
  drop  Total Grandtotal;
  retain Total Grandtotal;

  if first.Afdeling then call missing(Total);
  Total + antal;
  Grandtotal + Antal;
  output;

  if last.Afdeling then do;
    Afdeling = catx(' ', Afdeling, 'i alt'); 
    Maaned = .;
    Antal = Total;
    output;
  end;

  if eof then do;
    Afdeling = 'Organisationen i alt';
    Antal = Grandtotal;
    output;
  end;
run;

/*
Et andet praktisk eksempel kan ses her:
https://communities.sas.com/t5/SAS-Programming/using-If-first-variable-and-last-variable-when-there-are/m-p/845563#M334288
*/
