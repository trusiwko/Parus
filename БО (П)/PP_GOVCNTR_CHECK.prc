create or replace procedure PP_GOVCNTR_CHECK
-- ��������� �������� �� ���������� �����
( --
 nRN   in number,
 sUNIT in varchar2 --
 ) is
  nGovRN number := nRN;
begin
  if (sUNIT = 'GovernmentContractsFinancing') then
    select t.prn into nGovRN from govcntrfin t where t.rn = nRN;
  end if;
  -- ���� �� ����� ��:
  for c in (select fp_quarter(f.doc_date) nquarter, --
                   sum(f.summ) nsumm,
                   to_char(f.doc_date, 'yyyy') nyear,
                   f.expstruct,
                   f.econclass,
                   prsf_prop_sget(f.company, 'GovernmentContractsFinancing', f.rn, '�������') sSUBKSR,
                   e.code sECONCLASS
              from govcntr    g, --
                   govcntrfin f,
                   econclass  e
             where f.prn = g.rn
               and g.rn = nGovRN
               and e.rn = f.econclass
             group by fp_quarter(f.doc_date), --
                      to_char(f.doc_date, 'yyyy'),
                      f.expstruct,
                      f.econclass,
                      e.code,
                      prsf_prop_sget(f.company, 'GovernmentContractsFinancing', f.rn, '�������')) loop
    -- ���� �� �����
    for a in (select sum(AA.SUM_DIST) SUM_DIST
                from (select decode(c.nquarter, 1, S.SUM_DIST_Q1, 2, S.SUM_DIST_Q2, 3, S.SUM_DIST_Q3, 4, S.SUM_DIST_Q4, null) SUM_DIST,
                             (select II.ECONCLASS --
                                from EXPSTRUCTITEMS II
                               WHERE II.HIER_LEVEL = 1
                              connect by II.RN = prior II.UPRN
                               start with II.RN = I.RN) ECONCLASS,
                             I.CODE,
                             S.IS_DIST_TERM
                        from BUDGEXPEND M, BUDGEXPEND_SP S, EXPSTRUCTITEMS I
                       where M.REG_YEAR = c.nyear
                         and M.EXPSTRUCT = c.expstruct
                         and ((I.CODE is null) or (c.ssubksr is null) or (replace(I.CODE, '.') like c.ssubksr || '%'))
                         and S.PRN = M.RN
                         and S.EXPSTRUCTITEMS = I.RN) AA
               where AA.ECONCLASS = C.ECONCLASS
                 and AA.IS_DIST_TERM = 1) loop
      -- ���� �� ���� ��������� ��� ���������� �����
      for b in (select sum(f.summ) nsumm
                  from govcntr    g, --
                       govcntrfin f
                 where g.rn <> nGovRN
                   and f.prn = g.rn
                   and fp_quarter(f.doc_date) = c.nquarter
                   and to_char(f.doc_date, 'yyyy') = c.nyear
                   and f.expstruct = c.expstruct
                   and f.econclass = c.econclass
                   and ((c.sSUBKSR is null) or (prsf_prop_sget(f.company, 'GovernmentContractsFinancing', f.rn, '�������') is null) or
                       (c.sSUBKSR like prsf_prop_sget(f.company, 'GovernmentContractsFinancing', f.rn, '�������') || '%'))
                --
                ) loop
        if a.sum_dist - b.nsumm - c.nsumm < 0 then
          p_exception(0,
                      '�������� ����� �� �����: ' || chr(10) || '�����: ' || a.sum_dist || ', ' || chr(10) || '���������: ' || b.nsumm || ', ' || chr(10) || '��������: ' || c.nsumm || ', ' || chr(10) ||
                      '�������: ' || (a.sum_dist - b.nsumm) || ', ' || chr(10) || '�����: ' || c.sECONCLASS || ', ' || chr(10) || '�������: ' || c.ssubksr || ', ' || chr(10) || '������: ' ||
                      c.nquarter || ' ������� ' || c.nyear || ' �.');
        end if;
      end loop;
    end loop;
  end loop;
end PP_GOVCNTR_CHECK;
/*create public synonym PP_GOVCNTR_CHECK for PP_GOVCNTR_CHECK;
  grant execute on PP_GOVCNTR_CHECK to public;*/
/
