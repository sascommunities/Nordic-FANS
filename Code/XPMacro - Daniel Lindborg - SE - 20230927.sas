/* The following macros are contained in this file (XPMacro.sas) :               */
/*                                                                               */
/* 1. macro XPCreateComputeSession(replySessionIdMacroVar,replyWorkLocMacroVar)  */
/* 2. macro XPRunSASProgram(sessionId, sascode, replyJobIdMacroVar)              */
/* 3. macro XPPollJob(sessionId,jobId, replyStateMacroVar, pollInterval=5)       */
/* 4. macro XPDeleteComputeSession(sessionId)                                    */


/* S T A R T   A   N E W   S A S   S E S S I O N */

%macro XPCreateComputeSession(replySessionIdMacroVar,replyWorkLocMacroVar);

options nonotes;
filename resp temp;
filename resp_hdr temp;
filename resp clear;
filename resp_hdr clear;
filename resp temp;
filename resp_hdr temp;

options notes;
%put NOTE: Trying to start new compute session;
%let BASE_URI=%sysfunc(getoption(servicesbaseurl));
options nonotes;

proc http url="&BASE_URI./compute/contexts/2f37c4d0-c604-44b1-a8d0-feec21c2a20e/sessions"
  method='post'
  oauth_bearer=sas_services
  out=resp
  ct="application/json"
  headerout=resp_hdr
  headerout_overwrite;
run; 
quit;

options notes;

%if &SYS_PROCHTTP_STATUS_CODE eq 201 %then
%do;
  options nonotes;
  libname resp json;

  data _null_;
    set resp.alldata;
    if trim(p1) eq "id" then call symput("&replySessionIdMacroVar", trim(value));
  run;

  options notes;
  %put NOTE: New compute session started;
  %put NOTE: Compute session id: &&&replySessionIdMacroVar;
  options nonotes;

  filename resp temp;
  filename resp_hdr temp;

  options notes;
  %let BASE_URI=%sysfunc(getoption(servicesbaseurl));
  %put NOTE: Get SAS Work location;
  options nonotes;

  proc http url="&BASE_URI./compute/sessions/&&&replySessionIdMacroVar/data/WORK"
    method='get'
    oauth_bearer=sas_services
    out=resp
    ct="application/json"
    headerout=resp_hdr
    headerout_overwrite;
  run; 
  quit;

  libname resp json;

  data _null_;
    set resp.root;
    call symput("&replyWorkLocMacroVar", physicalName);
  run;

  options notes;
  %put NOTE: SAS Work location: &&&replyWorkLocMacroVar;
%end;
%else
%do;
  %put ERRORCODES &SYS_PROCHTTP_STATUS_CODE &SYS_PROCHTTP_STATUS_PHRASE;
  %put ERROR: Could not start a new Compute session;
%end;

%mend XPCreateComputeSession;



/* E X E C U T E   P R O G R A M */

%macro XPRunSASProgram(sessionId, sascode, replyJobIdMacroVar);

options nonotes;

/* Start of setting macro variables in remote session */
%let xpworkpath = %sysfunc(pathname(work)); 
proc sql noprint;
  create table xpmacrovars as
  select distinct(name) as name from sashelp.vmacro
   where 
    scope='GLOBAL' 
    and substr(name,1,3)  ne 'SYS' 
    and substr(name,1,1)  ne '_' 
	and substr(name,1,15) ne 'SASWORKLOCATION' 
    and substr(name,1,8)  ne 'TWORKLOC'
	and substr(name,1,13) ne 'CLIENTMACHINE'
	and substr(name,1,9)  ne 'GRAPHINIT'
	and substr(name,1,4)  ne 'PAGE'
	and substr(name,1,9)  ne 'GRAPHTERM'
	and substr(name,1,14) ne 'AFTER_ASSEMBLY'
	and substr(name,1,17) ne 'SAS_BASE_PGM_PATH';
quit;

%let xpuniquename=XP%sysfunc(substr(%sysfunc(compress(%sysfunc(uuidgen()), '-')),1,30));
data &xpuniquename;
  set xpmacrovars;
  length mvalue $32000;
  mvalue=symget(name);
run;

/* Create remote code to set macro variables in remote session */
filename precode temp;
data _null_;
  file precode;
  put "libname xpwpath ""&xpworkpath"";" 
  / 'data _null_;'
  / 'set xpwpath.&xpuniquename;'
  /  'call symput(name,strip(mvalue) );'
  / 'run;';
run;

/* Create %include for setting macro variables in remote session. It will run before the requested program */
%let XPPrecodePgm=%sysfunc(pathname(precode));
%let XPSetMacroVars=%nrstr(%include) %tslit(&XPPrecodePgm);

filename jsonin temp;
filename jsonin clear;
filename jsonin temp;

data _null_;
  file jsonin; 	
  put "{ ""code"" : ""&XPSetMacroVars.;&sascode;"",  ""variables"": { ""xpworkpath""  : ""&xpworkpath"", ""xpuniquename""  : ""&xpuniquename"" }}";
run;

%let BASE_URI=%sysfunc(getoption(servicesbaseurl));

filename resp clear;
filename resp_hdr clear;
filename resp temp;
filename resp_hdr temp;

options notes;
%put NOTE: Trying to run sas program in compute session &sessionId;
options nonotes;

proc http url="&BASE_URI./compute/sessions/&sessionId/jobs" 
  method='post'
  oauth_bearer=sas_services
  in=jsonin
  out=resp
  ct="application/json"
  headerout=resp_hdr
  headerout_overwrite;
run; 
quit;



%if &SYS_PROCHTTP_STATUS_CODE eq 201 %then
%do;
options nonotes;
libname resp json;

  data _null_;
    set resp.alldata;
    if trim(p1) eq "id" then call symput("&replyJobIdMacroVar", trim(value));
  run;

  options notes;
  %put NOTE: New compute job started;
  %put NOTE: Compute session id: &sessionId;
  %put NOTE: Jobid: &&&replyJobIdMacroVar;
  %put NOTE: Get state: &BASE_URI./compute/sessions/&sessionId/jobs/&&&replyJobIdMacroVar/state;
  %put NOTE: Get log: &BASE_URI./compute/sessions/&sessionId/jobs/&&&replyJobIdMacroVar/log;
%end;
%else
%do;
  %put ERRORCODES &SYS_PROCHTTP_STATUS_CODE &SYS_PROCHTTP_STATUS_PHRASE;
  %put ERROR: Could not run sas program in a compute session;
%end;
options notes;

%mend XPRunSASProgram;



/* P O L L   S A S   J O B */

%macro XPGetSASProgramState(sessionId, jobId, replyStateMacroVar);

options nonotes;
filename resp clear;
filename resp_hdr clear;
filename resp temp;
filename resp_hdr temp;

%let BASE_URI=%sysfunc(getoption(servicesbaseurl));

proc http url="&BASE_URI./compute/sessions/&sessionId/jobs/&jobId/state" 
  method='get'
  oauth_bearer=sas_services
  out=resp
  ct="application/json"
  headerout=resp_hdr
  headerout_overwrite;
run; 
quit;

options notes;
options nonotes;

data _null_;
  infile resp;
  input state $;
  call symputx("&replyStateMacroVar",state );
run;

options notes;

%mend XPGetSASProgramState;


%macro XPPollJob(sessionId,jobId, replyStateMacroVar, pollInterval=5);

  %let BASE_URI=%sysfunc(getoption(servicesbaseurl));

  %XPGetSASProgramState(sessionId=&sessionId, jobId=&jobId, replyStateMacroVar=&replyStateMacroVar);

  %do %while ("&&&replyStateMacroVar" eq "pending" or "&&&replyStateMacroVar" eq "running");
    option nonotes;

    data _null_;
      time_slept=sleep(&pollInterval,1);
    run;

    options notes;

    %XPGetSASProgramState(sessionId=&session1, jobId=&jobId1, replyStateMacroVar=&replyStateMacroVar);
    %put NOTE: Get state: &BASE_URI./compute/sessions/&sessionId/jobs/&jobId/state;
    %put NOTE: State is &&&replyStateMacroVar;
  %end;

  %put NOTE: Get log: &BASE_URI./compute/sessions/&sessionId/jobs/&jobId/log;

  filename resp temp;

  proc http url="&BASE_URI./compute/sessions/&sessionId/jobs/&jobId/log" 
    method='get'
    oauth_bearer=sas_services
    out=resp
    ct="application/json"
    headerout_overwrite;
  run; 
  quit;

  libname resp json;

  data _null_;
    set resp.items end=end;
    if _n_ eq 1 then
    do;
      put "--------------- REMOTE SESSION LOG  ---------------";
      put "&BASE_URI./compute/sessions/&sessionId/jobs/&jobId/log";
    end;
    put line;
    if end then put "--------------- END OF REMOTE SESSION LOG  ---------------";
  run;

  libname resp clear;

%mend XPPollJob;



/* D E L E T E   S E S S I O N */

%macro XPDeleteComputeSession(sessionId);

  options nonotes;
  filename resp clear;
  filename resp_hdr clear;
  filename resp temp;
  filename resp_hdr temp;

  options notes;
  %put NOTE: Trying to delete new compute session;
  %let BASE_URI=%sysfunc(getoption(servicesbaseurl));

  proc http url="&BASE_URI./compute/sessions/&sessionId"
    method='delete'
    oauth_bearer=sas_services
    out=resp
    ct="application/json"
    headerout=resp_hdr
    headerout_overwrite;
  run;

%mend XPDeleteComputeSession;


/**********************************************************************************/
