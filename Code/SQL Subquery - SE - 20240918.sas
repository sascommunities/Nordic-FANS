/* Testdata */
title;footnote; 
PROC SQL;

CREATE TABLE WORK.dept (
	deptno     num,  
	dname      char(15),  
	loc        char(15),
   employees  num
	);

INSERT into WORK.dept
	VALUES (10, 'ACCOUNTING', 'NEW YORK', 50)
	VALUES (20, 'RESEARCH',   'DALLAS', 75)
	VALUES (30, 'SALES',      'CHICAGO', 90)
	VALUES (40, 'OPERATIONS', 'BOSTON', 200)
;

CREATE TABLE WORK.emp (
	empno    num,  
	ename    CHAR(10),  
	job      CHAR(9),  
	mgr      num,  
	hiredate num format=yymmdd10.,  
	sal      num format=commax12.2, 
	deptno   num  
);

INSERT into WORK.emp
	VALUES (7839, 'KING',  'PRESIDENT', NULL, '17nov1981'd, 5000, 10)
	VALUES (7698, 'BLAKE', 'MANAGER',   7839, '1may1981'd, 2850, 30)
	VALUES (7782, 'CLARK', 'MANAGER',   7839, '9jun1981'd, 2450, 10)
	VALUES (7566, 'JONES', 'MANAGER',   7839, '2apr1981'd, 2975, 20)
	VALUES (7788, 'SCOTT', 'ANALYST',   7566, '13jul1987'd, 3000, 20)
	VALUES (7902, 'FORD',  'ANALYST',   7566, '3dec1981'd, 3000, 20)
;

QUIT;


/*

En sub query kan användas t.ex i en:
- WHERE 
- FROM 
- SELECT 

*/

/* 
*   *  *   *  *****  ****   *****  
*   *  *   *  *      *   *  *      
*   *  *   *  *      *   *  *      
*   *  *****  ****   ****   ****   
* * *  *   *  *      * *    *      
** **  *   *  *      *  *   *      
*   *  *   *  *****  *   *  *****
*/


/* Bara de som jobbar i ACCOUNTING. */
PROC SQL;
title h=7 "inner join";
SELECT emp.*
FROM WORK.emp INNER JOIN WORK.dept 
	ON (emp.deptno = dept.deptno AND dept.dname = 'ACCOUNTING')
;
QUIT;

/* Samma resultat men nu med subquery */
PROC SQL _method;
	title h=7 "sub query";
	SELECT emp.*
	FROM WORK.emp 
	WHERE	emp.deptno in (select subdept.deptno from WORK.dept as subdept 
                         where subdept.dname = 'ACCOUNTING')
;
QUIT;

/* Och som Correlated sub query, dvs den refererar till huvud-selecten */
PROC SQL _method;
	title h=7 "Correlated sub query";
	SELECT emp.*
	FROM WORK.emp 
	WHERE	exists (select 1 from WORK.dept as subdept 
                  where emp.deptno = subdept.deptno AND subdept.dname = 'ACCOUNTING')
;
QUIT;

/* Lite svårare. Correlated sub query med en aggregering */
PROC SQL _method;
	title h=7 "Correlated sub query";
	SELECT emp.*
	FROM WORK.emp 
	WHERE	exists (select 1 from WORK.dept as subdept 
                  having AVG(subdept.employees) < 110)
;
QUIT;


PROC SQL;
   CREATE TABLE WORK.expensive AS 
   SELECT t1.Make, 
          t1.Model, 
          t1.MSRP 
      FROM SASHELP.CARS t1
      WHERE t1.MSRP >= (
         SELECT /* AVG_of_MSRP */
           (AVG(t1.MSRP)) AS AVG_of_MSRP
             FROM SASHELP.CARS t1
      );
QUIT;

/* 
*****  ****    ***   *   *  
*      *   *  *   *  ** **  
*      *   *  *   *  * * *  
****   ****   *   *  *   *  
*      * *    *   *  *   *  
*      *  *   *   *  *   *  
*      *   *   ***   *   * 
*/

/* Lite data om bilhandlare... */
%put &SYSLAST. ;
PROC DS2 ;
title h=7 "Lite data om bilhandlare mha DS2...";
data WORK.Bilhandlare / overwrite=yes;
	declare char(15) Make Bilhandlare ;
	method run();
		Make = 'Audi';Bilhandlare = 'Audi Sverige';OUTPUT;
		Make = 'BMW';Bilhandlare = 'Bavaria';OUTPUT;
		Make = 'Jaguar';Bilhandlare = 'Hedin Bil';OUTPUT;
		Make = 'Land Rover';Bilhandlare = 'Landrover';OUTPUT;
		Make = 'MINI';Bilhandlare = 'Bilia';OUTPUT;
		Make = 'Mercedes-Benz';Bilhandlare = 'Mercedes-Benz';OUTPUT;
		Make = 'Porsche';Bilhandlare = 'Porsche Sverige';OUTPUT;
		Make = 'Saab';Bilhandlare = 'N/A';OUTPUT;
		Make = 'Volkswagen';Bilhandlare = 'Aftén Bil';OUTPUT;
		Make = 'Volvo';Bilhandlare = 'VolvoCars';OUTPUT;
	end;
enddata;
run;
data ;
	method run();
		set WORK.Bilhandlare;
	end;
   enddata;
run;
quit;
%put &SYSLAST. ;

PROC SQL ;
title h=7 "Sub query som datakälla";
	SELECT t1.Bilhandlare, 
			 t1.Make, 
			 CARS.Type, 
			 CARS.Model, 
			 CARS.Horsepower,
			 CARS.L_Mil FORMAT=commax12.2 "L/mil Stad" 
	  FROM WORK.Bilhandlare t1 inner join 
	  		 (select Make, Horsepower, Type, Model, ((235.214583 / MPG_City) / 10) as L_Mil
				 from SASHELP.CARS where Origin='Europe') as CARS
		 ON CARS.Make=t1.Make 
     
;
QUIT;


/* 
 ***   *****  *      *****   ***   *****  
*   *  *      *      *      *   *    *    
 *     *      *      *      *        *    
  *    ****   *      ****   *        *    
   *   *      *      *      *        *    
*   *  *      *      *      *   *    *    
 ***   *****  *****  *****   ***     *
*/

PROC SQL _method _tree;
title h=7 "Sub query som kolumn";
	SELECT CARS.Make, 
			 CARS.Model, 
 			 CARS.Type, 
			 CARS.MPG_City,
			 (select Avg(MPG_City) from SASHELP.CARS) as Avg_MPG_City format=numx4.1,
			 (select Min(MPG_City) from SASHELP.CARS) as Min_MPG_City format=numx4.1,
			 (select Max(MPG_City) from SASHELP.CARS) as Max_MPG_City format=numx4.1
	  FROM SASHELP.CARS  
;
QUIT;








/*data WORK.Bilhandlare;*/
/*length Make Bilhandlare $ 15;*/
/*Make = 'Audi';Bilhandlare = 'Audi Sverige';OUTPUT;*/
/*Make = 'BMW';Bilhandlare = 'Bavaria';OUTPUT;*/
/*Make = 'Jaguar';Bilhandlare = 'Hedin Bil';OUTPUT;*/
/*Make = 'Land Rover';Bilhandlare = 'Landrover';OUTPUT;*/
/*Make = 'MINI';Bilhandlare = 'Bilia';OUTPUT;*/
/*Make = 'Mercedes-Benz';Bilhandlare = 'Mercedes-Benz';OUTPUT;*/
/*Make = 'Porsche';Bilhandlare = 'Porsche Sverige';OUTPUT;*/
/*Make = 'Saab';Bilhandlare = 'N/A';OUTPUT;*/
/*Make = 'Volkswagen';Bilhandlare = 'Aftén Bil';OUTPUT;*/
/*Make = 'Volvo';Bilhandlare = 'VolvoCars';OUTPUT;*/
/*run;*/