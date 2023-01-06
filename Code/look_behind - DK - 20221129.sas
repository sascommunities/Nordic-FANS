/******************************************************************************/
/* Look Behind                                     Erik Lund-Jensen 5-11-2022 */
/*                                                                            */
/* Demoprogram til SAS Network 29.11.2022                                     */
/*                                                                            */
/* Teknik til at se på værdiern af variable i en foregående observation i     */
/* forhold til den aktuelle observation i et input-datasæt                    */
/******************************************************************************/

/******************************************************************************/
/* Lag funktionen - grundlæggende                                             */
/******************************************************************************/

* testdata;
data have1 (drop=i);
  do i = 1 to 10;
    value = i**2;
    output;
  end;
run;

* Grundfunktionalitet ved kald i alle observationer;
data want1;
  set have1;
  lag1_value = lag(value);
  lag2_value = lag2(value);
run;

* Beregn forskel fra foregående observation - her med fejl;
* Lag-funktionen returnerer ikke værdien fra foregående observation,
  men værdien fra den observation, der var aktuel ved det foregående kald af lag;
data want2;
  set have1;
  if _N_ = 1 then dif = value;
  else dif = value - lag(value);
run;

* Grundfunktion, der viser faldgrube ved betinget kald;
data want3;
  set have1;
  if mod(_N_,3) = 2 then do;
    lag1_kaldt = 1;
    lag1_value = lag1(value);
    lag2_kaldt = 1;
    lag2_value = lag2(value);
  end;
run;

* Beregn forskel fra foregående observation, nu OK;
data want4 (drop=oldvalue);
  set have1;
  oldvalue = lag(value);
  if _N_ = 1 then dif = value;
  else dif = value - oldvalue;
run;

/******************************************************************************/
/* Lag funktionen - praktisk eksempel                                         */
/* Summer værdier for de sidste tre registrerede måneder                      */
/******************************************************************************/

* Testdata;
data have2;
  do ID = 1,2,3;
    do Maaned = Id to int(ranuni(1)*5)+4;
      Antal = int(ranuni(1)*30);
      output;
      end;
    end;
run;

* Praktisk eksempel;
data want5 (rename=(Maaned=Seneste_Maaned));
  set have2; 
  by ID;
  drop oVal1 oVal2 IDstart Antal;
  retain IDstart;

  oVal1 = lag(Antal);
  oVal2 = lag2(Antal);

  if first.ID then IDstart = _N_;

  if last.ID then do;
    Antal_Maaneder = _N_ - IDstart + 1;
    if Antal_Maaneder > 2 then Sum_Sidste_3_mdr = sum(Antal, oVal1, oVal2);
    output;
  end;
run;

/*
Man kan gøre præcis det samme med retainede variable, men det bliver lidt mere tricky, 
hvis man vil arbejde med flere lag-niveauer.
*/
