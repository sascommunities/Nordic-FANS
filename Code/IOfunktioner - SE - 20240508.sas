
proc contents data=sashelp.class;
run;

data minTabell;
  dsID = open('sashelp.class');
  antalRader = attrn(dsID, 'nlobs');
  etikett = attrc(dsID, 'label');
  rc = close(dsID);
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

data _null_;
  set sashelp.vcolumn(keep=name  
                           memname 
                           libname 
                           length 
                           type)
      end=sistaRaden;
    
  where libname = "INDATA"
    and upcase(name) = "KOPID"
    and type = "char";
  retain maxLength 0;
  maxLength = max(maxLength, length);
  if sistaRaden then call symputx('varLength', ifc("&type"='char', cats('$', maxLength), maxLength));
run;

data allaKopID;
  set sashelp.vcolumn(keep=name memname libname);
  where libname = 'INDATA'
    and upcase(name) = 'KOPID';
  length kopID $6;
  dsID = open(cats(libname, '.', memname, '(keep=KOPID)'));
  antalRader = attrn(dsID, 'nlobs');
  call set(dsID);
  do i = 1 to antalRader;
    rc = fetch(dsID);
    output;
  end;
  rc = close(dsID);
  keep kopID;
run;


%macro kundinfo(customer_ID);
  %local dsID 
         rc 
         customer_name 
         customer_age 
         customer_country;
  %let dsID = %sysfunc(open(indata.kunder(
                       where=(customer_ID = &customer_ID)
                       keep=customer_id
                            customer_name 
                            customer_age 
                            customer_country)));
  %syscall set(dsID);
  %let rc = %sysfunc(fetch(&dsID));
  %let rc = %sysfunc(close(&dsID));
  %sysfunc(trim(&customer_name)) från %sysfunc(trim(&customer_country)), &customer_age år gammal
%mend;

%let kund = 52;

title "Ordrar lagda av %kundinfo(&kund)";
proc print data=indata.ordrar;
  where Customer_ID = &kund;
run;

