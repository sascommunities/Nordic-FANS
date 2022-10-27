libname regex '\\srvesbappsas22v\Sunddok\DW\Kildedata DIAppEPJ\LNB TEST';


*Henter røntgendata;
data t1;
set regex.ris_ydelse;
run;

*Kun XML;
data t2;
set t1;
keep xml;
run;

*Finder diagnosekoden. Der er altid kun én;
data t3;
set t2;
diag=prxparse("/(.diagnose.)(.type.)(.)(..type.)(.kode.)(\w+)(..kode.)/i");
	if prxmatch (diag,XML) then do;
		call prxposn(diag,6,pos,len);
	end;

if pos>0 then do;
		XML_diagnose_kode=substr(XML,pos,len);
end;

*drop pos len diag;
run;

*Procedurekoder m. 2 tillægskoder;
data t4;
set t3;
prockode=prxparse("/(\Wservice\W)(\Wtype\W)(\w+)(\W\Wtype\W)(\Wkode\W)(\w+)(\W\Wkode\W)(\Wtillaegskode\W)(\w+)(\W\Wtillaegskode\W)(\Wtillaegskode\W)(\w+)(\W\Wtillaegskode\W)(\W\Wservice\W)/i");
	if prxmatch(prockode,XML) then do; 
		call prxposn(prockode,6,procpos,proclen);
		call prxposn(prockode,9,til1pos,til1len);
		call prxposn(prockode,12,til2pos,til2len);
		procedurekode=substr(XML,procpos,proclen);
		tillaegskode1=substr(XML,til1pos,til1len);
		tillaegskode2=substr(XML,til2pos,til2len);
	end;
run;
*if-statement'et betyder, at der skal være match på hele strengen. Derfor kan den ikke bruges til at finde procedurer med færre tillægskoder;


*procedurekoder m. 1 tillægskode;
data t5;
set t4;
prockode2=prxparse("/(\Wservice\W)(\Wtype\W)(\w+)(\W\Wtype\W)(\Wkode\W)(\w+)(\W\Wkode\W)(\Wtillaegskode\W)(\w+)(\W\Wtillaegskode\W)(\W\Wservice\W)/i");
	if prxmatch(prockode2,XML) then do;
		call prxposn(prockode2,6,procpos,proclen);
		call prxposn(prockode2,9,til1pos,til1len);
		procedurekode=substr(XML,procpos,proclen);
		tillaegskode1=substr(XML,til1pos,til1len);
	end;
run;

*Procedurekoder u. tillægskoder;
data t6;
set t5;
prockode3=prxparse("/(\Wservice\W)(\Wtype\W)(\w+)(\W\Wtype\W)(\Wkode\W)(\w+)(\W\Wkode\W)(\W\Wservice\W)/i");
	if prxmatch(prockode3,XML) then do;
		call prxposn(prockode3,6,procpos,proclen);
		procedurekode=substr(XML,procpos,proclen);
	end;

drop diag pos len prockode prockode2 prockode3 procpos proclen til1pos til1len til2pos til2len;
	
run;