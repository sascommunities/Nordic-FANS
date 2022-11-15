/*- - - - - - - - - - - - - - - - - - 
Type: Macro
Desc: A routine that writes a clean note in the log using function PUTLOG.
Author: Daniel Ringqvist, SAS
Date: 2022-11-14
FANS Network: Programming Sweden 2022-11-08
- - - - - - - - - - - - - - - - - - */

%macro LogMessage(MESSAGE=, START_TIME=, BOX_SIZE_EXTRA_LINES=);
options nostimer;
%local START_TIME;
data _null_;
	putlog 'NOTE: *-------------------------------------------*';
	lines = abs(input("&BOX_SIZE_EXTRA_LINES", best.));
	if lines > 0 then 
		do i = 1 to lines;
			putlog "NOTE: *";
		end;
	
	putlog "NOTE: * %superq(MESSAGE) : " "%sysfunc(datetime(),datetime.)";

	if "&START_TIME" ne "0" then do;		
		elapsed = put((datetime() - &START_TIME), tod8.);
		putlog "NOTE: * Elapsed time : " elapsed;
	end;

	if lines > 0 then 
		do i = 1 to lines;
			putlog "NOTE: *";
		end;

	putlog 'NOTE: *-------------------------------------------*';

run;
options stimer;
%mend LogMessage;


%LogMessage(MESSAGE=%nrstr(Step fetch&clean started), START_TIME=0, BOX_SIZE_EXTRA_LINES=1);
%let STEP_START_TIME = %sysfunc(datetime(),best.);

data _null_;
	call sleep(2,1);
run;

%LogMessage(MESSAGE=%nrstr(Step fetch&clean ended), START_TIME=&STEP_START_TIME, BOX_SIZE_EXTRA_LINES=1);
