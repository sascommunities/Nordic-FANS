/*- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
Type: Macro
Desc: A routine that puts out a clean note in the log using function PUTLOG.
Author: Daniel Ringqvist, SAS
Date: 2024-03-13
FANS Network: Programming Sweden 2022-11-08
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/
/*
%put NOTE: Jobbet LADDA-DATA-TILL-CAS startade :  %sysfunc(datetime(),datetime.);
%put WARNING: Jobbet LADDA-DATA-TILL-CAS stoppade :  %sysfunc(datetime(),datetime.);
%put ERROR: Jobbet LADDA-DATA-TILL-CAS gav RC > 0 :  %sysfunc(datetime(),datetime.);

*/


%macro LogMessage(MESSAGE=, START_TIME=, BOX_SIZE_EXTRA_LINES=, EXPECTED_RUNTIME_SECONDS=);
options nostimer;
%local START_TIME BOX_SIZE_EXTRA_LINES EXPECTED_RUNTIME_SECONDS;
data _null_;
	putlog 'NOTE:    *-------------------------------------------*';
	lines = abs(input("&BOX_SIZE_EXTRA_LINES", best.));
	if lines > 0 then 
		do i = 1 to lines;
			putlog "NOTE:    *";
		end;
	
	putlog "NOTE:    * %superq(MESSAGE) : " "%sysfunc(datetime(),datetime.)";

	if "&START_TIME" ne "0" then do;		
		elapsed = put((datetime() - &START_TIME), tod8.);
      if (datetime() - &START_TIME) > &EXPECTED_RUNTIME_SECONDS then
         putlog "WARNING: * Elapsed time : " elapsed;
      else 
         putlog "NOTE:    * Elapsed time : " elapsed;
	end;

	if lines > 0 then 
		do i = 1 to lines;
			putlog "NOTE:    *";
		end;

	putlog 'NOTE:    *-------------------------------------------*';

run;
options stimer;
%mend LogMessage;


%LogMessage(MESSAGE=%nrstr(Step fetch&clean started), 
                           START_TIME=0, 
                           BOX_SIZE_EXTRA_LINES=3, 
                           EXPECTED_RUNTIME_SECONDS=0);

%let STEP_START_TIME = %sysfunc(datetime(),best.);

data _null_;
	call sleep(5,1);
run;

%LogMessage(MESSAGE=%nrstr(Step fetch&clean ended), 
                           START_TIME=&STEP_START_TIME, 
                           BOX_SIZE_EXTRA_LINES=4, 
                           EXPECTED_RUNTIME_SECONDS=4);
 
