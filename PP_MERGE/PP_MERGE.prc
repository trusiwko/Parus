create or replace procedure PP_MERGE
-- ќбъединение двух записей таблицы
(sTable in varchar2, nCompany in number, sUNIT in varchar2, nIDENT in number, bCRN in number) is
  crn      number;
  nVERSION number;
begin
  if bCRN = 1 then
    find_acatalog_name(1, nCompany, null, sUNIT, 'јрхив', crn);
    if crn is null then
      begin
      find_version_by_company(nCOMPANY, sUNIT, nVERSION);
      exception
        when others then null;
      end;
      select a.rn
        into crn
        from acatalog a
       where a.docname = sUNIT
         and a.is_root = 1
         and (a.company = nCompany or a.version = nVERSION);
      p_acatalog_insert(NCOMPANY, crn, 'јрхив', crn);
    end if;
  end if;
  for c in (select max(s.document) rn1, --
                   min(s.document) rn2
              from selectlist s
             where s.ident = nident) loop
    UDO_UPDATE_REF_TABLE.UPDAT(sTable, c.rn1, c.rn2);
    update doclinks d set d.in_document = c.rn2 where d.in_document = c.rn1 and d.in_unitcode = sUNIT;
    update doclinks d set d.out_document = c.rn2 where d.out_document = c.rn1 and d.out_unitcode = sUNIT;
    update docinpt d set d.document = c.rn2 where d.document = c.rn1 and d.unitcode = sUNIT;
    update docoutpt d set d.document = c.rn2 where d.document = c.rn1 and d.unitcode = sUNIT;
    PP_LOG(sTable || '. ”дал€ю: ' || c.rn1 || ', добавл€ю: ' || c.rn2);
    if bCRN = 1 then
      execute immediate 'update ' || sTable || ' set crn = ' || crn || ' where rn = ' || c.rn1;
    end if;
  end loop;
end PP_MERGE;
