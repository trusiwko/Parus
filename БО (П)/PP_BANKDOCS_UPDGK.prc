create or replace procedure PP_BANKDOCS_UPDGK
-- ��������� ����� �� � ��
( --
 nRN    in number,
 nGK    in number, --
 sAGENT in varchar2 default null -- ���������� � �� (����� ��� �����.�����)
 ) is
  ntemp number;
begin
  pkg_docs_props_vals.MODIFY('��', 'BankDocuments', nRN, null, nGK, null, ntemp);
end PP_BANKDOCS_UPDGK;
/*create public synonym PP_BANKDOCS_UPDGK for PP_BANKDOCS_UPDGK;
  grant execute on PP_BANKDOCS_UPDGK to public;*/
/
