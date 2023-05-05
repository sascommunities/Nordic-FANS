/*********************************************************************************/
/*                                                                               */
/*                              BIT-flaggor                                      */
/*                                                                               */
/*********************************************************************************/

data heartFlaggorNum;
  length id under30 avliden kvinna viktOver170 langdOver67 3;
  keep id under30 avliden kvinna viktOver170 langdOver67;
  set sashelp.heart(keep=AgeAtStart status sex Weight height);
  id          = _n_;
  under30     = ifn(AgeAtStart < 30, 1, 0);
  avliden     = ifn(Status = 'Alive', 1, 0);
  kvinna      = ifn(Sex = 'Female', 1, 0);
  viktOver170 = ifn(weight > 170, 1, 0);
  langdOver67 = ifn(height > 67, 1, 0);
  do _n_ = 1 to 100;
    output;
  end;
run;

data heartFlaggorChar;
  length id 3 under30 avliden kvinna viktOver170 langdOver67 $1;
  keep id under30 avliden kvinna viktOver170 langdOver67;
  set sashelp.heart(keep=AgeAtStart status sex Weight height);
  id          = _n_;
  under30     = ifc(AgeAtStart < 30, '1', '0');
  avliden     = ifc(Status = 'Alive', '1', '0');
  kvinna      = ifc(Sex = 'Female', '1', '0');
  viktOver170 = ifc(weight > 170, '1', '0');
  langdOver67 = ifc(height > 67, '1', '0');
  do i = 1 to 100;
    output;
  end;
run;

data heartFlaggorBit;
  length id 3 under30 avliden kvinna viktOver170 langdOver67 flaggByte $1;
  keep id flaggByte;
  set sashelp.heart(keep=AgeAtStart status sex Weight height);
  array b[5] $1 under30 avliden kvinna viktOver170 langdOver67;
  id          = _n_;
  under30     = ifc(AgeAtStart < 30, '1', '0');
  avliden     = ifc(Status = 'Alive', '1', '0');
  kvinna      = ifc(Sex = 'Female', '1', '0');
  viktOver170 = ifc(weight > 170, '1', '0');
  langdOver67 = ifc(height > 67, '1', '0');
  flaggByte   = input(cats(of b[*], '000'), $binary8.);
  do i = 1 to 100;
    output;
  end;
run;

options locale=SV_SE;

proc sql;
  select 
    case memname
      when 'HEARTFLAGGORNUM'  then 'Numeriska'
      when 'HEARTFLAGGORCHAR' then 'Text'
      else 'Bit'
    end "Typ av flaggor",
    filesize "Storlek på tabell" format=sizekmg.,
    nobs "Antal rader" format=nlnum12.
  from dictionary.tables
  where libname = 'WORK'
  and memname in ('HEARTFLAGGORNUM', 'HEARTFLAGGORCHAR', 'HEARTFLAGGORBIT');
quit;


data uppackadeBitflaggor;
  set heartflaggorbit;
  array b[5] $1 under30 avliden kvinna viktOver170 langdOver67;
  flaggor = put(flaggByte, $binary8.);
  do _n_ = 1 to dim(b);
    b[_n_] = substr(flaggor, _n_, 1);
  end;
  drop flaggor flaggByte;
run;


proc compare b=heartFlaggorChar c=uppackadeBitflaggor;
run;


