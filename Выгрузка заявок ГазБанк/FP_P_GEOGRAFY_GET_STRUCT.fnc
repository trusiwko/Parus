create or replace function FP_P_GEOGRAFY_GET_STRUCT
-- Возврат адреса
( --
 nGEOGRAFY in number,
 nType     in number,
 sField    in varchar2 default 'name' --
 ) return varchar2 is
begin
  for rREC in (select G.GEOGRNAME as NAME, --
                      G.GEOGRTYPE as TYPE,
                      G.CODE,
                      B.NAME      sLTYPE
                 from GEOGRAFY G, LOCALITYTYPE B
                 where G.LOCALITYKIND = B.RN(+)
                start with G.RN = nGEOGRAFY
               connect by prior G.PRN = G.RN) loop
    if rREC.TYPE = nType then
      if (sField = 'name') then
        return rREC.NAME || ' ' || rRec.sLTYPE;
      else
        return rREC.CODE;
      end if;
    end if;
  end loop;
  return(null);
end FP_P_GEOGRAFY_GET_STRUCT;
/*create public synonym FP_P_GEOGRAFY_GET_STRUCT for FP_P_GEOGRAFY_GET_STRUCT;
  grant execute on FP_P_GEOGRAFY_GET_STRUCT to public;*/
/
