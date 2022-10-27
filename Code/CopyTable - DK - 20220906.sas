/*
Kopierer indhold fra replicate mappe til endelig destination. Makroen kører rekursivt og forøger count med 1 for hver gang, den kalder sig selv
batfilemove er navnet på movefile.bat filen inkl. stinavn
count er antallet af gange, at funktionen er blevet kørt
count sammenlignes med repeats macroen for at afgøre, om der skal forsøges flere gange
funktionen kaldes rekursivt indtil repeats er nået
*/
%macro runMoveFile(batfilemove, count);
	%put  "kører " &batfilemove.;
	%let rc=%sysfunc(system(&batfilemove.));

	%if &rc>0 %then
		%do;
			%if (&count<&repeats) %then
				%do;

					data _null_;
						rcSleep=sleep(&waitTime);
					run;

					%runMoveFile(&batfilemove., &count+1);
				%end;
			/*%else %if &rc>1 %then
				%do;
					%put ERROR: Kopieringen blev ikke gennemført, returkode &rc &dstDir. &dstFile.;
					MoveFile_Error;
				%end;*/
			%else %do;
				%put ERROR: Tabel &dstFile ikke kopieret, CopyTable fejl ved move kommando error level &rc &dstDir;
			%end;
		%end;
	%else
		%do;
			%put "Move file completed successfully";
		%end;
%mend;

/*
Slet eksisterende replicate mapper, der måtte findes på destinationen, der er ældre end 24 timer
*/
%macro deleteRepFolders(dstpath);

	data _null_;
		length kordato $10. korkl kormin $8.;
		length filnavn filnavn2 $256.;
		rc=filename("repdir","&dstpath");
		did=dopen("repdir");
		fff = sysmsg();
		put did= fff=;

		if did > 0 then
			do;
				antal=dnum(did);

				do i=1 to antal;
					cmdText="";
					filnavn=dread(did,i);
					logdato=datetime();
					filnavn2=upcase(filnavn);
					rc=	find(filnavn2,"REPLICATE_");

					if rc>0 then
						do;
							rc=filename('tmp', "&dstpath.\" || strip(filnavn));
							kordato=scan(filnavn, 2,'_');
							korkl=scan(filnavn, 3,'_');
							kormin=scan(filnavn, 4, '_');

							if (korkl ^="" and kordato ^="" and kormin ^="") then
								do;
									fildato=input(kordato, date9.);
									filkl=input(korkl, 8.);
									filmin=input(kormin, 8.);
									tid=dhms(fildato, filkl, filmin, 0);

									/*put "tid " filnavn fid fildato tid logdato;*/
									if (tid) then
										do;
											put "log fil " filnavn tid logdato;

											if tid+24*3600<datetime() then
												do;
													put "mappe slettes";
													did2=dopen("tmp");

													if did2 >0 then
														do;
															antal2=dnum(did2);

															do j=1 to antal2;
																filnavn2=dread(did2,j);
																put "Sletter fil " filnavn2;
																rc=filename('subfile', "&dstpath.\" || strip(filnavn) || '\' || strip(filnavn2));
																rc=fdelete('subfile');
															end;
														end;

													rc=dclose(did2);
													rc=fdelete("tmp");
												end;
										end;
								end;
						end;
				end;
			end;

		rc=dclose(did);
	run;

%mend;

/*
tblInput er libname på input tabellen
tblOutput er libname på output tabellen
nr er index på output tabellen
Input og output tabeller opdeles i libref og filnavne
Derved findes adressestier på filerne, der skal overflyttes og overskrives
*/
%macro replicate(tblInput, tblOutput, nr);

	%if &tblInput=&tblOutput %then %do;
		%put ERROR: Input og output fil er den samme;
		CopyTableError;
	%end;

	data dsKopi;
		* Opretter makrovariabler med navne på input og outfiler filer og mapper;
		length inTabel inLib outTabel outLib $100. srcPath dstPath tmpDir tmpFolder workspace $400. klTidText $10.;
		inLib=scan("&tblInput", 1, '.');
		inTabel=scan("&tblInput", 2,'.');
		outLib=scan("&tblOutput", 1,'.');
		outTabel=scan("&tblOutput", 2,'.');
		srcPath=pathname(inLib);
		dstPath=pathname(outLib);
		datoNu="&sysdate.";
		klTidText="&systime.";
		workspace= "&workspace.";
		tmpFolder="replicate_" || datoNu || "_" || translate(strip(klTidText),'_',':') || "_&nr";
		tmpDir=trim(dstPath) || "\" || strip(tmpFolder);
		put "input " inLib inTabel "output " outLib outTabel srcPath dstPath tmpDir;
		put "jobid &sysjobid.";

		/*
			Kopierer værdier til tilsvarende makrovariabler til brug i næste step
		*/
		call symput('srcDir', strip(srcPath));
		call symput('dstDir', strip(dstPath));
		call symput('srcFile', strip(inTabel));
		call symput('dstFile', strip(outTabel));
		call symput('tmpDir', strip(tmpDir));
	run;

	%let doCopy=0;

	data _null_;
		* Sammenligning af fildatoer;
		length srcMod dstMod $100.;
		rc=filename('srcFile', "&srcDir.\&srcFile..sas7bdat");
		fid=fopen('srcFile');
		srcMod=finfo(fid, 'Last Modified');
		rc=fclose(fid);
		rc=filename('dstFile', "&dstDir.\&dstFile..sas7bdat");
		fid=fopen('dstFile');
		dstMod=finfo(fid, 'Last Modified');
		rc=fclose(fid);
		put "fildato source: " srcMod " destination: " dstMod;

		if (dstMod ne srcMod) then
			do;
				call symput('doCopy', 1);
			end;

	run;

	%deleteRepFolders(&dstDir);

	%if &doCopy=1 %then
		%do;

			data _null_;
				set dsKopi;
				* opretter replicate mappe;
				rc=filename('dir', tmpDir);

				if (fexist('dir')=0) then
					do;
						rc=dcreate(strip(tmpFolder),strip(dstPath));
						rc=filename('dir', tmpDir);

						if (fexist('dir')=1) then
							put "Mappe oprettet";
						else put "Mappe findes ikke";
					end;
			run;

			data _null_;
				* opretter bat fil til kopiering af filer;
				filename batfile "&batfile.";
				file batfile lrecl=1000;
				put &codepage;
				put "robocopy " '"' "&srcDir" '" "' "&tmpDir" '"' " &srcFile..sas7bdat &robocopyOptions /LOG+:" '"' "&logfile." '"';

				if (fileexist("&srcDir.\&srcFile..sas7bndx")) then
					do;
						put "robocopy " '"' "&srcDir" '" "' "&tmpDir" '"' " &srcFile..sas7bndx &robocopyOptions /LOG+:" '"' "&logfile." '"';
					end;
			run;

			%let rc=%sysfunc(system(&batfile.));

			%if &rc>1 %then
				%do;
					/*Fejl*/
					%put ERROR: CopyTable Robocopy blev ikke gennemført &srcFile;
					Robocopy_Error;
				%end;
			%else
				%do;
					%put Robocopy blev gennemført;
				%end;

			data _null_;
				*opretter bat fil til flytning af filer;
				filename batfile "&batmove.";
				file batfile lrecl=1000;
				put &codepage;

				if (fileexist("&tmpDir.\&srcFile..sas7bdat")) then
					do;
						put "move /Y " '"' "&tmpDir.\&srcFile..sas7bdat" '" "' "&dstDir.\&dstFile..sas7bdat" '"';
					end;

				if (fileexist("&tmpDir.\&srcFile..sas7bndx")) then
					do;
						put "move /Y " '"' "&tmpDir.\&srcFile..sas7bndx" '" "' "&dstDir.\&dstFile..sas7bndx" '"';
					end;

				*put "rmdir " '"' "&tmpDir." '"';
			run;

			%runMoveFile(&batmove., 0);

			data _null_;
				* Sletter replicate mappe;
				filename batfile "&batRmDir.";
				file batfile lrecl=1000;
				put &codepage;
				put "rmdir /S /Q " '"' "&tmpDir." '"';
			run;

			data _null_;
				rc=system("&batRmDir");
			run;

		%end;
%mend;

%macro rensNavn(libnavn);
	%let str=%sysfunc(scan(&libnavn,1,'.'));
	%let str2=%sysfunc(scan(&libnavn, 2, '.'));
	%let str3=%sysfunc(dequote(&str2));
	%let outName=%sysfunc(cats(&str,.,&str3));
%mend;
/*
data _null_;
	rc=setlocale(DATETIME_FORMAT, '%d%b%Y:%H:%M:%S');
run;
*/

%macro CopyTable();
	%let outName=&_INPUT;

	%rensNavn(&_INPUT);
	%let srcTabel=&outName;
	%let workspace=%sysfunc(pathname(work));
	%let logfile=&workspace.\robolog.log;
	%let batfile=&workspace.\&sysjobid._robocopy.bat;
	%let batmove=&workspace.\&sysjobid._movefile.bat;
	%let batRmDir=&workspace.\&sysjobid._delFolder.bat;
	%let codepage="mode con codepage select=1252";

	data _null_;
		logfil=getoption('log');

		if logfil ne "" then
			do;
				tid=datetime();
				dato=datepart(tid);
				min=minute(tid);
				h=hour(tid);
				s=int(second(tid));
				strdato=put(dato, yymmddp10.);
				str=cats(strdato,'_',h, '.',min,'.',s,'_robocopy.log');
				logfil=cats(logfil, str);
				call symput('logfile', logfil);
			end;
	run;

	%do i=0 %to &_OUTPUT_count-1;
		%rensNavn(&&_OUTPUT&i);
		%let dstTabel=&outName;

		%replicate(&srcTabel, &dstTabel, &i);
	%end;
%mend;