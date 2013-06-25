create or replace procedure PP_EO_MO
-- Массовое изменение мемориального ордера в плане счетов
(nCOMPANY   in number,
 nIDENT     in number,
 sUNIT      in varchar2, -- Раздел (План счетов или ХО)
 sMO        in varchar2, -- Мемориальный ордер
 nEMPTYONLY in number -- Обновлять только у пустых
 ) is
  nMO PKG_STD.tREF;
begin
  if sMO is not null then
    find_memorder_code(0, nCOMPANY, sMO, nMO);
  end if;
  if sUNIT = 'AccountsPlan' then
    update dicaccs d
       set d.memorder = nMO
     where d.rn in (select document from selectlist where ident = nIDENT)
       and (nEMPTYONLY = 0 or d.memorder is null);
  elsif sUNIT = 'EconomicOperations' then
    update oprspecs os
       set os.order_rn = nMO
     where os.prn in (select document from selectlist where ident = nIDENT)
       and (nEMPTYONLY = 0 or os.order_rn is null);
  elsif sUNIT = 'EconomicOperationsSpecs' then
    update oprspecs os
       set os.order_rn = nMO
     where os.rn in (select document from selectlist where ident = nIDENT)
       and (nEMPTYONLY = 0 or os.order_rn is null);
  else
    p_exception(0,
                'Для раздела ' || sUNIT ||
                ' не указано правило исправления мемориального ордера');
  end if;
end PP_EO_MO;
/
