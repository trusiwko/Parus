create or replace procedure PP_INV_RULE
-- Массовое исправление правила отработки в ИК
(nCOMPANY in number,
 nIDENT   in number,
 sOPER    in varchar2 -- Правило отработки ИК
 ) is
  nOPER PKG_STD.tREF;
begin
  find_invopermodel_code(0, 1, nCOMPANY, sOPER, nOPER);
  update inventory i
     set i.oper_rule = nOPER --
   where i.rn in (select document --
                    from selectlist
                   where ident = nIDENT);
end PP_INV_RULE;
/
