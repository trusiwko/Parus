create or replace procedure PP_DOGNOM_CHECK
-- ��������� �������� ��������������� ������ �� ������������
  -- ������������� ���� �� ���������� / �����������
( --
 nRN   in number, --
 sUNIT in varchar2) is
  nLimit number;
  nGovRN number := nRN;
begin
  if (sUNIT = 'GovernmentContractsFinancing') then
    select t.prn into nGovRN from govcntrfin t where t.rn = nRN;
  end if;
  -- ������� ����� �� ��������� (�� ��������� 100 000 �.):
  begin
    select t.numvalue into nLimit from constlst t where t.name = '�����_��_������������';
  exception
    when no_data_found then
      nLimit := 100000;
  end;
  -- ����� ��������� �������� ��������:
  for c in (select dpv.str_value scode,
                   fp_quarter(g.doc_date) nquarter,
                   sum(f.summ) nsumm,
                   to_char(g.doc_date, 'yyyy') nyear,
                   nvl(prsf_prop_sget(g.company, 'GovernmentContracts', g.rn, '��������������������'), '���') scontrol
              from govcntr g, govcntrfin f, docs_props dp, docs_props_vals dpv
             where g.rn = dpv.unit_rn
               and dp.code = '������������ ��� ���'
               and dp.rn = dpv.docs_prop_rn
               and f.prn = g.rn
               and g.rn = nGovRN
             group by dpv.str_value,
                      fp_quarter(g.doc_date),
                      to_char(g.doc_date, 'yyyy'),
                      nvl(prsf_prop_sget(g.company, 'GovernmentContracts', g.rn, '��������������������'), '���')) loop
    -- ������� ����� �� ����������:
    if (c.scontrol = '���') then
      -- ������� ������ � ��� ������, ���� ���� ��������
      for cc in (select sum(f.summ) nsumm
                   from govcntr g, govcntrfin f, docs_props dp, docs_props_vals dpv
                  where g.rn = dpv.unit_rn
                    and dp.code = '������������ ��� ���'
                    and dp.rn = dpv.docs_prop_rn
                    and f.prn = g.rn
                    and dpv.str_value = c.scode
                    and fp_quarter(g.doc_date) = c.nquarter
                    and to_char(g.doc_date, 'yyyy') = c.nyear --
                  having sum(f.summ) > nLimit) loop
        p_exception(0,
                    '�������� �������������� ����� �� ������������ "' || c.scode || '" �� ' || c.nquarter || '-� ������� �� ����� ' || (cc.nsumm - nLimit) || ' �.');
      end loop;
    end if;
  end loop;
end PP_DOGNOM_CHECK;
/
