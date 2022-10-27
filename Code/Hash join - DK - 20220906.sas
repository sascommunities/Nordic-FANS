
Data datojoin;
   length Dato_fra 8. Dato_til 8. Hvor $9 ;     
   if _N_=1 then do;
      declare hash S(dataset:'hashdata.hvor', multidata: 'Y');
      S.definekey('key');
      S.definedata('dato_fra', 'dato_til', 'hvor');
      S.definedone();
   end;
   call missing(key, dato_fra, dato_til, hvor);

   set hashdata.hvad;

   if s.find() = 0 then do until (s.find_next());
      if dato_fra <= dato <= dato_til then output;
   end;
run;


