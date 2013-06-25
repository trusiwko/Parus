create or replace procedure PP_DOGNOM_CONTROL
-- ������ �������� ��������������� ������ �� ������������ ����������� �������, �����, �����
(nCOMPANY in number,
 nRN      in number,
 sMSG     out varchar2 --
 ) is
  soldcontrol varchar2(3);
  snewcontrol varchar2(3);
  ntemp       number;
begin
  soldcontrol := nvl(prsf_prop_sget(nCOMPANY, 'GovernmentContracts', nRN, '��������������������'), '���');
  if soldcontrol = '���' then
    snewcontrol := '��';
    sMSG        := '�������� ����';
  else
    snewcontrol := '';
    sMSG        := '�������� ����������';
  end if;
  pkg_docs_props_vals.MODIFY('��������������������', 'GovernmentContracts', nRN, snewcontrol, null, null, ntemp);
end PP_DOGNOM_CONTROL;
/*create public synonym PP_DOGNOM_CONTROL for PP_DOGNOM_CONTROL;
  grant execute on PP_DOGNOM_CONTROL to public;*/
/
