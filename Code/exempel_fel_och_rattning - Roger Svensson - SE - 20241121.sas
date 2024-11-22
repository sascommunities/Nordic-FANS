* Kompletterande kladdfil med exempel som var till grund för pp-presentation SAS-FANS 20024-11-21;
proc options;
run;

data car(keep=Make Model Type Horsepower Weight);
	set sashelp.cars(obs=10);
	if Model eq ' 3.5 RL w/Navigation 4dr' then Weight=0;
run;
option DSOPTIONS=NOTE2ERR;
options varinitchk=ERROR;

data k1;
	set car;
  where Make eq 'Acura';
  where Type eq 'Sedan';
	if iamnotused eq 1 then x=1;
	KVOT=Horsepower/Weight;
run;
* NOTE: WHERE clause has been replaced.;
* NOTE: Variable iamnotused is uninitialized.;
* NOTE: Division by zero detected at line 35 column 14.;


* fix;
data k1;
	set car;
  where Make eq 'Acura';
  where also Type eq 'Sedan';
	length iamnotused x KVOT 8;
	iamnotused=.;
	x=.;
	KVOT=.;

	if iamnotused eq 1 then x=1;
	if Weight ne 0 then
		KVOT=Horsepower/Weight;
run;

* merge;
data car(keep=Make Type Cylinders) car_hp;
	Make='Audi';
	Type='Sedan';
	Cylinders=4;
	output car;
	Cylinders=6;
	output car;
	Cylinders=4;
	Horsepower=170;
	output car_hp;
	Horsepower=200;
	Cylinders=6;
	output car_hp;
run;

data car_final;
	merge car(in=a) car_hp(in=b);
	by Make;
	if a and b;
run;
* merge utan by;
options mergenoby=ERROR;

* Fix;
data car_final;
  merge 
    car(in=a)
    car_hp(in=b drop=Type)
  ;
	by Make Cylinders;
  if a and b;
run;


proc sql;
	create table car_selection as
		select
			case
				when Make eq 'Audi' then 1
				when Make eq 'BMW' then 2
			end as bil_kod
		from sashelp.cars
	;
quit;

* Fix;
proc sql;
	create table car_selection as
		select
			case
				when Make eq 'Audi' then 1
				when Make eq 'BMW' then 2
				else .E
			end as bil_kod
		from sashelp.cars
	;
quit;

%let n=1;
data x;
	length text $10;
	text=&n;
run;

* Fix;
%let n=1;
data x;
	length text $10;
	text="&n";
run;

* truncated;
data model_name(keep=new_car_name model);
	set sashelp.cars;
	length new_car_name $10;
	new_car_name = model;
run;

data model_name;
	length new_car_name $10;
	new_car_name='';
	stop;
run;

proc sql;
	insert into model_name(new_car_name)
	select substr(Model,1, 10)  from sashelp.cars;
quit;

proc append base=model_name data=sashelp.cars(keep=model rename=(model=new_car_name));run;


OPTIONS MSGLEVEL=I;
options errorcheck=STRICT;
options varinitchk=ERROR;
%put %sysfunc(getoption(dsoptions));
%let saveOption = %sysfunc(getoption(bomfile));
options nobomfile;


options varlenchk=ERROR;

* Måste stava rätt;
options noautocorrect; dsoptions=note2err;
proc options


%put &sysver;

