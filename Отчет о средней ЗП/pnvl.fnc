create or replace function pnvl
-- Проверка на заполненность
(pException in number, --
 svalue     in varchar2,
 stext      in varchar2 --
 ) return varchar2 is
begin
  if svalue is null then
    p_exception(pException, 'Необходимо заполнить ' || stext);
  end if;
  return(svalue);
end pnvl;
/*
create public synonym pnvl for pnvl;
grant execute on pnvl to public;
*/
/
