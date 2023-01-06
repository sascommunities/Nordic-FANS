/******************************************************************************/
/* Look Ahead                                      Erik Lund-Jensen 5-11-2022 */
/*                                                                            */
/* Demoprogram til SAS Network 29.11.2022                                     */
/*                                                                            */
/* Teknik til at se på værdien af variable i den efterfølgende observation    */
/* i forhold til den aktuelle observation i et input-datasæt                  */
/******************************************************************************/

* Testdata;
data have1;
  infile datalines;
  length ID $1;
  informat Dato_Start Dato_Slut ddmmyy10.;
  format Dato_Start Dato_Slut ddmmyyd10.;
  input ID$ Dato_Start Dato_Slut;
  datalines;
A 01-01-2018 15-06-2019
A 15-06-2019 31-10-2020
A 01-04-2021 .
B 20-03-2019 30-04-2022
C 01-02-2018 30-09-2020
C 08-08-2020 30-05-2022
C 01-04-2022 .         
C 01-06-2022 31-12-2022
D 15-08-2019 21-06-2020
D 22-06-2020 22-06-2020
D 23-06-2020 31-12-2022
;
run;

/******************************************************************************/
/* Brug af ekstra set-statement                                               */
/******************************************************************************/

* Virker ikke - der kommer til at mangle en observation i output-datasæt;
data want1 (drop = NextID Dato_Naeste);
  set have1;

  set have1 (firstobs=2 drop=Dato_Slut rename=(ID=NextID Dato_Start=Dato_Naeste));

  if ID = NextID then Diff_til_naeste = Dato_Naeste - Dato_Slut - 1;
run;

* Virker - nu holder vi styr på at læse alle observationer fra input og
  undlade at læse den ikke-eksisterende næste, når vi er i sidste observation;
data want2 (drop = NextID Dato_Naeste);
  set have1 end=end_of_data;

  if not end_of_data then 
     set have1 (firstobs=2 drop=Dato_Slut rename=(ID=NextID Dato_Start=Dato_Naeste));

  if ID = NextID and not end_of_data then Diff_til_naeste = Dato_Naeste - Dato_Slut - 1;
run;

* Virker - nu også uden at give en note om "mising values", som IKKE bør forekomme i
  loggen, fordi det signalerer, at der noget, man har glemt at tage højde for, og
  som måske medfører fejlagtigt output;
data want3 (drop = NextID Dato_Naeste);
  set have1 end=end_of_data;

  if not end_of_data then
     set have1 (firstobs=2 drop=Dato_Slut rename=(ID=NextID Dato_Start=Dato_Naeste));

  if ID = NextID and not end_of_data then
    if not (missing(Dato_Slut) or missing(Dato_Naeste)) then Diff_til_naeste = Dato_Naeste - Dato_Slut - 1;
run;


/******************************************************************************/
/* Brug af datasæt-optionen point=                                            */
/* I dette tilfælde gør den bare det samme, men den giver flere muligheder,   */
/* fordi man kan læse frit frem og tilbage, man skal blot holde styr på       */
/* hvilken observation der skal læses i forhold til den aktuelle.             */
/******************************************************************************/

data want4 (drop = NextID Dato_Naeste);
  set have1 nobs=max end=end_of_data;

  if _N_ < max then do;
    next = _N_ + 1;
    set have1 (drop=Dato_Slut rename=(ID=NextID Dato_Start=Dato_Naeste)) point=next;
  end;
    
  if ID = NextID and not end_of_data then
    if not (missing(Dato_Slut) or missing(Dato_Naeste)) then Diff_til_naeste = Dato_Naeste - Dato_Slut - 1;
run;
