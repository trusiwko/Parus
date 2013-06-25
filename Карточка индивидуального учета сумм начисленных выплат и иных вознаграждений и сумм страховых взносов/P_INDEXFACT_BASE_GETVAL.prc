create or replace procedure P_INDEXFACT_BASE_GETVAL
(
  nRN           in number,      -- RN шкалы
  dDATE         in date,        -- дата, на которую искать редакцию шкалы
  nVALUE        out number      -- значение
)
as
begin
  begin
    select M.INDEXVAL_VALUE
      into nVALUE
      from INDEXVAL M
      where M.PRN = nRN
        and M.INDEXVAL_BEGIN =
          (
            select max( M1.INDEXVAL_BEGIN )
              from INDEXVAL M1
              where M1.PRN = nRN
                and M1.INDEXVAL_BEGIN <= dDATE
          );
  exception
    when NO_DATA_FOUND then
      nVALUE := 0;
  end;
end;
/
