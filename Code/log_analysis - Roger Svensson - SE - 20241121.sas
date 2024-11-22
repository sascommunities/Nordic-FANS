/*  Namn:           log_analysis
 *  Beskrivning:    Analyserar loggar efter ERRORS och WARNINGS samt vissa viktiga noteringar
 *  Inparametrar:   file: <sökväg till fil>
 *                  outlib: libname där tabellerna batch_log och batch_summary sparas (default=work)
 *	Output					Skapar flera tabeller
 *                    BATCH_LOG - Allt i filen
 *                    BATCH_SUMMARY - Ihopslagning av liknande kommentarer
 *                    BATCH_SUMMARY_EXT_NOTES - Lista på utökade kontroller
 *                    BATCH_HISTORY - Sparar antalet per körning
 */
proc format;
	value com_info_grp
		0='Other'
		1='Error'
		2='Warning'
		3='Note'
		4='Deprecated'
		5='Info'
		other='Unknown'
	;
	value com_info_grp_extended
		0='Normal Note'
		1='Variable uninitialized' /* NOTE: Variable d_dag_smint is uninitialized.*/
		2='Overwritten variable'
		3='Case has no else clause'
		4='Invalid argument to function input'
		5='Division by zero detected'
		6='Format was not found or could not be loaded'
		7='MERGE statement has repeats of BY values'
		8='WHERE clause has been replaced'
		9='Character values have been converted to numeric'
		10='Character variables have defaulted to a length of'
		11='Numeric values have been converted to character values'
		12='The query requires remerging summary statistics back with the original data'
	;
quit;


%macro co_search_log;
	%_search_(string=warning:);
	%_search_(string=error:);
	%_search_(string=note:);
	%_search_(string=info:);
	%_search_(string=deprecated:);
%mend co_search_log;

%macro log_analysis(file=, outlib=work);
	%let outlib=%lowcase(&outlib);
	filename _log_ "&file";
	data log1; 
		label
			EDITOR_LINE_NO ='Line number in SAS LOG'
			LOG_TEXT='Messages on ERRORs, WARNINGs and specific NOTEs and INFOs'
		;
		drop i1 fw string; 
		retain EDITOR_LINE_NO 0; 
		infile _log_; 
		input; 
		EDITOR_LINE_NO = EDITOR_LINE_NO +1; 
		length fw $2000;
		fw=scan(_infile_, 1, '20'x); 
		%* Keep looking until last colon(:);
		if substr(fw, length(fw))=':' then; 
		else goto bottom; 

		%macro _search_(string=); 
			string = "&string."; 
			i1=index(upcase(_infile_), upcase("&string.")); 
			if i1 then goto write; 
		%mend _search_;
		%co_search_log;
			
		write:; 
			LOG_TEXT=_infile_; 
			if i1 then output; %* Make shure that only valid information is outputed;

		bottom:;
	run;

	%* Move/rename file to outlib, default work;
	data &outlib..batch_log(compress=char);
		set log1;
	run;

	%*summarize the log file; 
	proc sort data=log1(drop=EDITOR_LINE_NO) out=work.log;
		by LOG_TEXT;
	run;

	%* cleanup;
	proc sql;
		drop table log1;
	quit;


	data r;
		attrib DISTINCT_LOGTEXTNR length=8.;
		set log;
		by LOG_TEXT;
		retain DISTINCT_LOGTEXTNR;
		if _n_ eq 1 then DISTINCT_LOGTEXTNR=0;
		if FIRST.LOG_TEXT then DISTINCT_LOGTEXTNR+1;
	run;
	
	%* cleanup;
	proc sql;
		drop table log;
	quit;
	

	proc summary data=r nway; 
		class DISTINCT_LOGTEXTNR; 
		output out=log2_tmp(drop=_TYPE_ rename=(_FREQ_=NUMBER_OF_ENTRIES));
	run;

	proc sort data=log2_tmp;
		by DISTINCT_LOGTEXTNR;
	run;


	proc sort data=r out=r_nodup nodupkey;
		by DISTINCT_LOGTEXTNR;
	run;


	%* cleanup;
	proc sql;
		drop table r;
	quit;

	data &outlib..batch_summary(drop=i1 i2 i3 i4 i5 compress=char);
		attrib ORG_LOG_GROUP length=3 format=com_info_grp.;
		attrib NOTE_GROUP_EXTENDED length=3 format=com_info_grp_extended.;
		merge r_nodup(in=a) log2_tmp(in=b);
		by DISTINCT_LOGTEXTNR;
		if a and b;

		i1=index(upcase(LOG_TEXT), "ERROR:"); 
		i2=index(upcase(LOG_TEXT), "WARNING:"); 
		i3=index(upcase(LOG_TEXT), "NOTE:"); 
		i4=index(upcase(LOG_TEXT), "DEPRECATED:");
		i5=index(upcase(LOG_TEXT), "INFO:");

		if i1 eq 1 then ORG_LOG_GROUP=1;
		else if i2 eq 1 then ORG_LOG_GROUP=2;
		else if i3 eq 1 then ORG_LOG_GROUP=3;
		else if i4 eq 1 then ORG_LOG_GROUP=4;
		else if i5 eq 1 then ORG_LOG_GROUP=5;
		else ORG_LOG_GROUP=0;
	 
		NOTE_GROUP_EXTENDED=.;
		if i2 eq 1 then do;
			%* WARNING:;
			%* Klassa denna warning som ett ERROR;
			if i2 eq 1 and index(lowcase(LOG_TEXT), 'truncated record')
				then ORG_LOG_GROUP=1;
			if i2 eq 1 and index(lowcase(LOG_TEXT), 'character expression will be truncated') 
				then ORG_LOG_GROUP=1;
			NOTE_GROUP_EXTENDED=0;
		end;
		
		%* NOTE:;
		else if i3 eq 1 or i5 eq 1 then do;
	    if index(lowcase(LOG_TEXT), 'uninitialized') then NOTE_GROUP_EXTENDED=1;
			else if index(lowcase(LOG_TEXT), 'overwritten') then NOTE_GROUP_EXTENDED=2;
			else if index(lowcase(LOG_TEXT), 'a case expression has no else clause') then NOTE_GROUP_EXTENDED=3;
			else if index(lowcase(LOG_TEXT), 'invalid argument to function input') then NOTE_GROUP_EXTENDED=4;
			else if index(lowcase(LOG_TEXT), 'division by zero detected') then NOTE_GROUP_EXTENDED=5;
			else if index(lowcase(LOG_TEXT), 'was not found or could not be loaded') then NOTE_GROUP_EXTENDED=6;
			else if index(lowcase(LOG_TEXT), 'merge statement has more than one data set with repeats of by values') then NOTE_GROUP_EXTENDED=7;
			else if index(lowcase(LOG_TEXT), 'where clause has been replaced') then NOTE_GROUP_EXTENDED=8;
			else if index(lowcase(LOG_TEXT), 'character values have been converted to numeric') then NOTE_GROUP_EXTENDED=9;
			else if index(lowcase(LOG_TEXT), 'character variables have defaulted to a length of') then NOTE_GROUP_EXTENDED=10;
			else if index(lowcase(LOG_TEXT), 'numeric values have been converted to character values') then NOTE_GROUP_EXTENDED=11;
			else if index(lowcase(LOG_TEXT), 'the query requires remerging summary statistics') then NOTE_GROUP_EXTENDED=12;
									
			else NOTE_GROUP_EXTENDED=0;
	  end;
	run;

	%* Sammanställer alla anmärkningar i en ny tabell;
	data &outlib..batch_summary_ext_notes(compress=yes);
		set &outlib..batch_summary;
		where ORG_LOG_GROUP in (1,2,4) or
			ORG_LOG_GROUP in (3,5) and NOTE_GROUP_EXTENDED ge 1
		;
	run;

	%* Syftet är att kunna få en snabbsummering när man kör detta script standalone, dvs när outlib=work (default);
	%if "&outlib" eq "work" %then %do;
		%* count;
		%let antal_errors=0;
		%let antal_warnings=0;
		%let antal_notes=0;
		%let antal_notes_extended=0;
		%let antal_deprecated=0;
		proc sql noprint;
			select coalesce(sum(NUMBER_OF_ENTRIES), 0) into: antal_errors
				from BATCH_SUMMARY where ORG_LOG_GROUP=1;
			select coalesce(sum(NUMBER_OF_ENTRIES), 0) into: antal_warnings
				from BATCH_SUMMARY where ORG_LOG_GROUP=2;
			select coalesce(sum(NUMBER_OF_ENTRIES), 0) into: antal_notes
				from BATCH_SUMMARY where ORG_LOG_GROUP=3;
			/* Vi räknar ihop alla INFO med NOTE */
			select coalesce(sum(NUMBER_OF_ENTRIES), 0) into: antal_notes_extended
				from BATCH_SUMMARY where ORG_LOG_GROUP in (3,5) and NOTE_GROUP_EXTENDED>0;
			select coalesce(sum(NUMBER_OF_ENTRIES), 0) into: antal_deprecated
				from BATCH_SUMMARY where ORG_LOG_GROUP=4;
		quit;
		%let antal_errors=&antal_errors;
		%let antal_warnings=&antal_warnings;
		%let antal_notes=&antal_notes;
		%let antal_notes_extended=&antal_notes_extended;
		%let antal_deprecated=&antal_deprecated;

		%*put macro log_analysis: &antal_errors &antal_warnings &antal_notes &antal_notes_extended &antal_deprecated;

		%* Create batch_history(if it not already exist);
		%if %sysfunc(exist(batch_history)) %then %do;
			%* Do nothing;
		%end;
		%else %do;
			data batch_history(compress=yes);
				attrib DATE length=8 format=yymmdd10.;
				length ANTAL_ERRORS ANTAL_WARNINGS ANTAL_NOTES ANTAL_NOTES_EXTENDED ANTAL_DEPRECATED 8;
				attrib TSCREATED length=8 format=datetime23.2;
				retain _NUMERIC_ .;
				stop;
			run;
		%end;

		%*
		%* insert summery;
		%let today=%sysfunc(today());
		%let timestamp=%sysfunc(datetime());
		%put macro log_analysis: &today &timestamp;
		proc sql noprint constdatetime FEEDBACK;
			insert into batch_history(DATE, ANTAL_ERRORS, ANTAL_WARNINGS, ANTAL_NOTES, ANTAL_NOTES_EXTENDED, ANTAL_DEPRECATED, TSCREATED) 
				values (&today, &antal_errors, &antal_warnings, &antal_notes, &antal_notes_extended, &antal_deprecated, &timestamp);
		quit;

	%end; %* %if "&outlib" eq "work" %then %do;

	%* cleanup;
	proc sql noprint;
	proc sql;
		drop table r_nodup;
		drop table log2_tmp;
	quit;
%mend log_analysis;

/*
* Anrop (Exempel manuellt);
%log_analysis(file=D:\TEMP\test\sashelp.log);
*/

/*
* Exempel på hur man kan använda denna med SAS EG;
* Sparar logfilen på servern och analyserar denna direkt;

proc printto log="%sysfunc(pathname(work))\analys.log" new;
run;

data k1;
	set sashelp.cars(obs=100);
	where Make eq 'Audi';
	where Type eq 'Sports';
run;

proc printto;
run;
%log_analysis(file=%sysfunc(pathname(work))\analys.log);
proc print data=batch_history;run;
proc print data=BATCH_SUMMARY_EXT_NOTES;run;

*;
* Anrop (Exempel automatikt);
*;

* Följande engångsconfigurering måste göras;
*;
* Lägg till följande rader under options -> SAS-program > insert code before...;
%include "...\log_analysis.sas" /source2;

proc printto log="%sysfunc(pathname(work))\analys.log" new;
run;

* Lägg till följande i insert code after...;
proc printto;
run;

%log_analysis(file=%sysfunc(pathname(work))\analys.log);
proc print data=batch_history;run;
proc print data=BATCH_SUMMARY_EXT_NOTES;run;
*/