create or replace function FP_LATIN
--
(SDATA in varchar2) return varchar2 is
  Result varchar2(100);
  sRUS1  varchar2(30) := 'юабцдегхийклмнопярстужшщ';
  sENG1  varchar2(30) := 'ABVGDEZIYKLMNOPRSTUFHCYE';
  sRUS2  varchar2(30) := '╗фвьчъ';
  sENG2  varchar2(30) := 'YOZHCHSHYUYA';
  sRUS3  varchar2(30) := 'ы';
  sENG3  varchar2(30) := 'SCH';
  sRUS4  varchar2(30) := 'эз';

  function CONV(SLETTER in varchar2) return varchar2 is
    SENG varchar2(10);
  begin
    SENG := SLETTER;
    for i in 1 .. length(sRUS1) loop
      SENG := replace(SENG, substr(sRUS1, i, 1), substr(sENG1, i, 1));
    end loop;
    for i in 1 .. length(sRUS2) loop
      SENG := replace(SENG, substr(sRUS2, i, 1), substr(sENG2, i * 2 - 1, 2));
    end loop;
    for i in 1 .. length(sRUS3) loop
      SENG := replace(SENG, substr(sRUS3, i, 1), substr(sENG3, i * 2 - 1, 2));
    end loop;
    for i in 1 .. length(sRUS4) loop
      SENG := replace(SENG, substr(sRUS4, i, 1), '');
    end loop;
    return SENG;
  end;
begin
  for i in 1 .. length(SDATA) loop
    Result := Result || CONV(substr(upper(sDATA), i, 1));
  end loop;
  return(Result);
end FP_LATIN;
/*create public synonym FP_LATIN for FP_LATIN;
  grant execute on FP_LATIN to public;*/
/
