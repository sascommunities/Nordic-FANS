
/* 1 - Basic */
PROC FREQ DATA=SASHELP.CARS
	ORDER=INTERNAL
;
	TABLES Make /

	SCORES=TABLE
	;

RUN;

/* 2 - L�gg till lite stats i toppen */
PROC FREQ DATA=SASHELP.CARS
	ORDER=INTERNAL

	/* Summering i toppen */
	NLEVELS

;
	TABLES Make /

	SCORES=TABLE
	;

RUN;

/* 3 - L�gg p� ORIGIN */
PROC FREQ DATA=SASHELP.CARS
	ORDER=INTERNAL

	/* Summering i toppen */
	NLEVELS
;
	TABLES Origin*Make /

	SCORES=TABLE
	;


RUN;

/* 4 - Ol�sligt s� vi "viker ner" MAKE */
PROC FREQ DATA=SASHELP.CARS
	ORDER=INTERNAL

	/* Summering i toppen */
	NLEVELS
;
	TABLES Origin*Make /
 
	/* Vik ner var2 */
	LIST 

	SCORES=TABLE
	;

RUN;

/* 5 - L�gg p� vikt */
PROC FREQ DATA=SASHELP.CARS
	ORDER=INTERNAL

	/* Summering i toppen */
	NLEVELS
;
	TABLES Origin*Make /
 
	/* Vik ner var2 */
	LIST 

	SCORES=TABLE
	;

	/* Anv�nd WEIGHT f�r att aggregera */
	WEIGHT MSRP
	;
RUN;



/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
/* Slutligen, f� till r�tt FORMAT f�r antal och procent    */


/* �ndra ODS path till WORK, SASUSER �r default men ofta read-only */
ods path(prepend) work.template(update);

/* �ndra LABEL och FORMAT */
proc template;
	edit Base.Freq.OneWayList;
		edit frequency;
			header="Antal";
			format=COMMAX12.;
		end;

		edit cumfrequency;
			header="Antal ack.";
			format=COMMAX12.;
		end;

		edit percent;
			header="%";
			format=NLPCT9.2;
		end;

		edit cumpercent;
			header="% ack.";
			format=NLPCT.2;
		end;
	end;
run;

proc template;
 delete Base.Freq.OneWayList;
 *delete Base.Freq.Graphics.<graph template name>;
run;
