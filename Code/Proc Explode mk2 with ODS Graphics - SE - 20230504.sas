%macro setOptions;
%macro dummy;%mend dummy;

ods _all_ close; 

/* Set options to get a large animated gif */
options 	
	papersize=('35cm', '20cm') 
	printerpath=gif 
	animation=start 
	animduration=0.5 
	animloop=yes 
	animoverlay 
	nonumber 
	nodate;

goptions 
	reset=all 
	device=gif;

ods graphics / 
	width=34cm
	height=20cm 
	imagefmt=GIF;
%mend setOptions;


%macro drawIt(text_to_draw);
%macro dummy;%mend dummy;

%local text_to_draw_length;
%local i;
%let text_to_draw_length = %length(&text_to_draw);

/* Loop and create as many templates as the length of the parameter string. */
/* Each graph will draw 1 character longer of the parameter string.      */
%do I = 1 %to &text_to_draw_length;
proc template;
define statgraph draw_&I / store=work.gtl_explode; 
  begingraph / border=false;
    drawtext textattrs=(color=dark_orange size=72pt family='Courier New' weight=bold ) "%substr(&text_to_draw, 1, &I)" /     
    width=100 
	widthunit=percent
	;
  endgraph;
end;
%end;

ods path (prepend) WORK.gtl_explode(read);

/* Replay all templates and create the animated gif */
%do I = 1 %to &text_to_draw_length;
	proc sgrender data=sashelp.class template=draw_&I. ;
	run;
%end;
%mend drawIt;



/* - - - - - - - - */
/* Run it!         */
/* - - - - - - - - */


/* Set up things */
%setOptions;

/* Open ODS destination for the gif */
ods printer file='c:\temp\explode_anim.gif' style=plateau;

*%drawIt(%str(Joe Bonamassa, guitar player extraordinaire!));	
%drawIt(%str(Joe Bonamassa));	

	
/* Stop and close/save gif */
options printerpath=gif animation=stop;
ods printer close;




/* - - - - - - - - - - - */
/* Unicode               */
	
/* Set up things */
%setOptions;

ods printer file='c:\temp\explode_unicode.gif' style=plateau;

/* Select font below supporting the unicode */
proc template;
define statgraph draw_unicode / store=work.gtl_explode; 
  begingraph / border=false;
  layout overlay;

	/* A guitar */
	entry textattrs=(color=black size=144pt family='Symbola') {unicode '01f3b8'x} / valign=top;

    drawtext textattrs=(color=dark_orange size=72pt family='Courier New' weight=bold ) "Joe Bonamassa" /     
    width=100 
	widthunit=percent
	justify=center 
	anchor=center
	;	

	/* A heart */
	entry textattrs=(color=dark_red size=144pt family='Segoe UI Symbol' weight=bold ) {unicode '2665'x} / valign=bottom;

  endlayout;
  endgraph;
end;

ods path (prepend) WORK.gtl_explode(read);

proc sgrender data=sashelp.class template=draw_unicode ;
run;

/* Stop and close/save gif */
options printerpath=gif animation=stop;
ods printer close;