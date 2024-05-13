
data minTabell;
  rc = filename('mapp', "&path");
  did = dopen('mapp');
  antalElement = dnum(did);
  do i = 1 to antalElement;
    filnamn = dread(did, i);
    output;
  end;
  rc = filename('mapp');
run;

data _null_;
  rc = filename('mapp', "&path");
  did = dopen('mapp');
  antalElement = dnum(did);
  do i = 1 to antalElement;
    filnamn = dread(did, i);
    if scan(filnamn, -1) = 'csv' then 
      call execute(catx(' ', '
proc import datafile=', cats('"', "&path\", filnamn, '"'), '
            dbms=csv 
			replace
            out=', scan(filnamn, 1), '; 
run;'));
  end;
run;
