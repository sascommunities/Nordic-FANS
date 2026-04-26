%let HOMEPATH=%str(/srv/nfs/kubedata/compute-landingzone/DanielR);
%let JSON_PATH = %str(&HOMEPATH/duck);
%put &=HOMEPATH;
%put &=JSON_PATH;

/* - - - - - - */
/* JSON        */
/* - - - - - - */

/* Export to json with sastags */
proc json out="&JSON_PATH/cars.json";
    export sashelp.cars;
run;

/* Export to json with NOsastags */
proc json out="&JSON_PATH./cars_nosastags.json";
    export sashelp.cars / nosastags;
run;

/* Import json file*/
filename f_cars "&JSON_PATH/cars.json";
libname j_cars JSON fileref=f_cars;

data WORK.j2s_cars;
    set j_cars.SASTABLEDATA_CARS;
run;
proc datasets lib=j_cars; quit;
data work.temp;
  set j_cars.alldata;
run;

/* NOsastags. Nu heter tabellen ROOT */
filename f_cars "&JSON_PATH/cars_nosastags.json";
libname j_cars JSON fileref=f_cars;

proc sql;
    create table WORK.V8 as
    select Origin, Make, Model
    from j_cars.ROOT
    where cylinders > 6;
quit;




libname duck duckdb file_type=json file_path="&JSON_PATH" ;

/*
proc contents data=duck.cars_nosastags;run;quit;
*/

 /* SAS datastep */
data WORK.cars; 
    set duck.cars_nosastags;
run;

 /* SAS SQL */
proc sql;
    create table WORK.V8 as
    select Origin, Make, Model
    from duck.cars_nosastags
    where cylinders > 6;
quit;

/* Pass-thru SQl to duckDB */
libname ducklib duckdb;
*options noquotelenmax;
proc sql;
    
	connect using ducklib;

	create table WORK.JSON_to_Cars_V8 as
	SELECT * from connection to ducklib 
    (
        select * 
        from read_json("&JSON_PATH./cars_nosastags.json")
        where Cylinders > 6
    );
quit;


/* jsonL (JSON Lines) */
proc sql;

	connect using ducklib;

	create table WORK.amazon_auto_reviews as
	SELECT * from connection to ducklib 
    (
        select * 
        from read_json("&JSON_PATH./Amazon_reviews_Automotive_5.json.gz")    
    );
quit;





/* - - - - - - */
/* CSV         */
/* - - - - - - */

/* Export data as CSV */
proc export data=SASHELP.Cars file="&HOMEPATH/data/cars.csv" REPLACE;
run;

libname ducklib duckdb;
proc sql;
    
	connect using ducklib;

	create table WORK.CSV_to_Cars_4cyl as
	SELECT * from connection to ducklib (
        select Make, Model, Horsepower 
        from read_csv("&HOMEPATH./data/cars.csv")
        where Cylinders = 4
    );
quit;


/* - - - - - - - - - - - - */
/*                         */
/* Fancy DuckDB statements */
/*                         */
/* - - - - - - - - - - - - */

data DUCKLIB.CARS;
    set SASHELP.CARS;
run;

/* EXCLUDE vs SAS Keep/Drop  */
proc sql;
    
	connect using ducklib;

	create table DUCKLIB.Cars_Asia as
	SELECT * from connection to ducklib (
        select * EXCLUDE Origin 
        from CARS
        where Origin = 'Asia'
    );
quit;


/* PIVOT */

/* Create sample data  */
proc sql;
    
	connect using ducklib;
	EXECUTE (

    CREATE or REPLACE TABLE cities (country VARCHAR, name VARCHAR, year INTEGER, population INTEGER);
    INSERT INTO cities VALUES
    ('NL', 'Amsterdam', 2000, 1005),
    ('NL', 'Amsterdam', 2010, 1065),
    ('NL', 'Amsterdam', 2020, 1158),
    ('US', 'Seattle', 2000, 564),
    ('US', 'Seattle', 2010, 608),
    ('US', 'Seattle', 2020, 738),
    ('US', 'New York City', 2000, 8015),
    ('US', 'New York City', 2010, 8175),
    ('US', 'New York City', 2020, 8772);

    ) by ducklib;

    select * from ducklib.Cities;
quit;

proc sql;
	connect using ducklib;

	SELECT * from connection to ducklib 
    (

    SELECT * FROM cities
    PIVOT ( sum(population)
            FOR year IN (2000, 2010, 2020)
            GROUP BY country
          )

    );
quit;

/* ...Också mot CARS... */

proc sql;
    
	connect using ducklib;

	SELECT * from connection to ducklib 
    (

    SELECT * from Cars
    PIVOT ( sum(MPG_Highway)
            FOR DriveTrain IN ('Front', 'Rear')
            GROUP BY Origin 
          )

    );
quit;