create or replace function FP_0531702_NUM
-- ��������� ����� ��������
(NRN   in number, --
 dDATE in date) return number is
  ntemp number;
  nSVED number;
begin
  select nvl(max(dpv.num_value), 0) + 1
    into nSVED
    from docs_props_vals dpv, docs_props dp
   where dpv.docs_prop_rn = dp.rn
     and dp.code = '����� ��������'
     and dpv.unitcode = 'Contracts'
     and to_char(prsf_prop_dget(dpv.company, 'Contracts', dpv.unit_rn, '���� ��������'), 'yyyy') = to_char(dDATE, 'yyyy');
  pkg_docs_props_vals.MODIFY('����� ��������', 'Contracts', nRN, null, nSVED, null, ntemp);
  pkg_docs_props_vals.MODIFY('���� ��������', 'Contracts', nRN, null, null, dDATE, ntemp);
  return nSVED;
end FP_0531702_NUM;
/
