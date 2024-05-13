%let make = volvo;

title "Bilar av märket &make";
proc print data=sashelp.cars;
  where make="&make";
  var make model msrp;
run;

/*         __
          |  |
          |  |
        __|  |__
        \      /
         \    /
          \  /
           \/
*/

%let make = volvo;

title "Bilar av märket &make";
proc print data=sashelp.cars;
  where make="%propcase(&make)";
  var make model msrp;
run;

/*         __
          |  |
          |  |
        __|  |__
        \      /
         \    /
          \  /
           \/
*/


title "Bilar av märket &make";
proc print data=sashelp.cars;
  where make=propcase("&make)";
  var make model msrp;
run;

/*         __
          |  |
          |  |
        __|  |__
        \      /
         \    /
          \  /
           \/
*/

title "Bilar av märket &make";
proc print data=sashelp.cars;
  where make="%sysfunc(propcase(&make))";
  var make model msrp;
run;

/*         __
          |  |
          |  |
        __|  |__
        \      /
         \    /
          \  /
           \/
*/

%macro head(tabeller=, obs=5);
  %local i;
  %do i = 1 %to ANTALTABELLER;
    proc print data=%scan(&tabeller, &i, %str( ))(obs=&obs);
    run;
  %end;
%mend head;

/*         __
          |  |
          |  |
        __|  |__
        \      /
         \    /
          \  /
           \/
*/

%macro head(tabeller=, obs=5);
  %local i t;
  %do i = 1 %to %sysfunc(countw(&tabeller, %str( )));
    %let t = %scan(&tabeller, &i, %str( ));
    title "Första &obs raderna i %upcase(&t)";
    proc print data=&t(obs=&obs);
    run;
  %end;
  title;
%mend head;

%head(tabeller=sashelp.class)
%head(tabeller=sashelp.cars sashelp.heart sashelp.shoes)
