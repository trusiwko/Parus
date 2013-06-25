create or replace procedure PP_BANKDOCS_UPDGK
-- Процедура связи ГК с БД
( --
 nRN    in number,
 nGK    in number, --
 sAGENT in varchar2 default null -- Контрагент в БД (нужен для польз.формы)
 ) is
  ntemp number;
begin
  pkg_docs_props_vals.MODIFY('ГК', 'BankDocuments', nRN, null, nGK, null, ntemp);
end PP_BANKDOCS_UPDGK;
/*create public synonym PP_BANKDOCS_UPDGK for PP_BANKDOCS_UPDGK;
  grant execute on PP_BANKDOCS_UPDGK to public;*/
/
