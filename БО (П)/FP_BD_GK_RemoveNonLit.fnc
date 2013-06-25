create or replace function FP_BD_GK_RemoveNonLit
-- Вернем только буквы и цифры
(sInput in varchar2) return varchar2 is
  i  number;
  a  varchar2(200);
  n  number;
  ss varchar2(200) := sInput;
begin
  for i in 1 .. length(ss) - 1 loop
    if substr(ss, i, 2) = ' 0' then
      ss := substr(ss, 1, i - 1) || '  ' || substr(ss, i + 2);
    end if;
  end loop;
  for i in 1 .. length(ss) loop
    n := ascii(substr(ss, i, 1));
    if (n >= ascii('A') and n <= ascii('Z')) or (n >= ascii('a') and n <= ascii('z')) or (n >= ascii('0') and n <= ascii('9')) or (n >= ascii('А') and n <= ascii('Я')) or
       (n >= ascii('а') and n <= ascii('я')) then
      a := a || substr(ss, i, 1);
    end if;
  end loop;
  return a;
end;
/
