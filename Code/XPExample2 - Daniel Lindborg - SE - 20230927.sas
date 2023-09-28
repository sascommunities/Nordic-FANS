%include "/opt/sas/sasdata/developers/daniel/FANS/XPMacro.sas";


/*
  Example:
  Run two different datasteps in two different sub sessions in parallell.
  
  Step 1:
  Start session1
  Submit datastep to session1. The submit will run in background, meaning no waiting time, you will instantly get a reply
  with a JOB ID.

  Step 2:
  Start session2
  Submit datastep to session2. The submit will run in background, meaning no waiting time, you will instantly get a reply
  with a JOB ID.

  Step 3:
  Wait for the first submit to complete with polling macro
  When finished, wait for second submit to complete
  
  Step 4:
  Back to main program, do what ever you want with output in the sub sessions

  Step 5:
  Destroy both sessions
  
*/

/* ------------------------------------*/
/* Start job 1 */
/* ------------------------------------*/

/* Start a new compute session */
/* Name the input macrovars of your choice. They will contain values when macro is done */
%global session1 workloc1;
%XPCreateComputeSession(replySessionIdMacroVar=session1, replyWorkLocMacroVar=workloc1);
%put &session1 &workloc1;

/* 
  Run a sas program in the new compute session 
  Pass the session id value, valid sas code
  Jobid will contain the id of the sas job. Important when polling the job
*/

%let sascode1=%nrstr(
  
  data fromsession1;
    set sashelp.class;
    time_slept=sleep(3,1);
  run;

);;

%put &sascode1;
%global jobId1;
%XPRunSASProgram(sessionId=&session1, sascode=&sascode1, replyJobIdMacroVar=jobId1);
%put &jobId1;


/* ------------------------------------*/
/* Start job 2 */
/* ------------------------------------*/
/* Start a new compute session */
/* Name the input macrovars of your choice. They will contain values when macro is done */
%global session2 workloc2;
%XPCreateComputeSession(replySessionIdMacroVar=session2, replyWorkLocMacroVar=workloc2);
%put &session2 &workloc2;

/* 
  Run a sas program in the new compute session 
  Pass the session id value, valid sas code
  Jobid will contain the id of the sas job. Important when polling the job
*/

%let sascode2=%nrstr(
  
  data fromsession2;
    set sashelp.class;
    time_slept=sleep(3,1);
  run;

);;

%put &sascode2;
%global jobId2;
%XPRunSASProgram(sessionId=&session2, sascode=&sascode2, replyJobIdMacroVar=jobId2);
%put &jobId2;









/* Poll job, will run until sas program is finished 
   Pass the sessionid, jobid, and macrovariable which will contain the response.
*/
%global jobState1;
%XPPollJob(sessionId=&session1, jobId=&jobId1, replyStateMacroVar=jobState1, pollInterval=2);
%put &jobState1;


%global jobState2;
%XPPollJob(sessionId=&session2, jobId=&jobId2, replyStateMacroVar=jobState2, pollInterval=2);
%put &jobState2;



libname rwork1 "&workloc1";
libname rwork2 "&workloc2";




/* Delete sas session when done*/
%XPDeleteComputeSession(sessionId=&session1);


/* Delete sas session when done*/
%XPDeleteComputeSession(sessionId=&session2);









