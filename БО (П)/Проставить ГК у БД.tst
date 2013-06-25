PL/SQL Developer Test script 3.0
15
-- Created on 30.05.2011 by Администратор 
declare
  -- Local variables here
  i integer;
begin
  -- Test statements here
  for c in (select FP_BD_GK(b.pay_info, b.agent_to) s, b.*
              from bankdocs b, doctypes dt
             where b.bank_doctype = dt.rn
               and dt.doccode in ('П/П бюджет', 'П/П ГЗ', 'П/П ПД', 'П/П ВР')
               and FP_BD_GK(b.pay_info, b.agent_to) is not null
               and prsf_prop_nget(b.company, 'BankDocuments', b.rn, 'ГК') is null) loop
    PP_BANKDOCS_UPDGK(c.rn, c.s, null);
  end loop;
end;
0
0
