create or replace procedure PP_SPRAVKA
-- ������� � ������� ��
(nRN   in number, --
 dFrom in date,
 dTill in date,
 sU1   in varchar2,
 sU2   in varchar2,
 sU3   in varchar2,
 sU4   in varchar2,
 sV    in varchar2 --
 ) is
  i      number;
  pdFrom date;
begin
  pdFrom := to_date('01.' || to_char(dFrom, 'mm.yyyy'), 'dd.mm.yyyy');
  -- Excel:
  prsg_excel.PREPARE;
  prsg_excel.SHEET_SELECT('����1');
  prsg_excel.CELL_DESCRIBE('����');
  prsg_excel.CELL_DESCRIBE('�����');
  prsg_Excel.LINE_DESCRIBE('������');
  prsg_Excel.LINE_DESCRIBE('����');
  for i in 1 .. 8 loop
    prsg_excel.LINE_CELL_DESCRIBE('������', '�' || i);
    prsg_excel.LINE_CELL_DESCRIBE('����', '�' || i);
  end loop;
  -- Data:
  for c in (select rownum, --
                   count(1) over() all_count,
                   sum(a.n) over() / count(1) over() all_n,
                   sum(a.u1) over() / count(1) over() all_u1,
                   sum(a.u2) over() / count(1) over() all_u2,
                   sum(a.u3) over() / count(1) over() all_u3,
                   sum(a.u4) over() / count(1) over() all_u4,
                   sum(a.u5) over() / count(1) over() all_u5,
                   sum(a.v) over() / count(1) over() all_v,
                   a.*
              from (select ag.agnfamilyname_to || ' ' || ag.agnfirstname_to || ' ' || ag.agnlastname_to sfio_to, --
                           pnvl(0, cd.psdep_name_gen, '��������� ' || cd.psdep_code || ' � ����������� ������') psdep_name_gen,
                           pnvl(0, de.name_gen, '������������� ' || de.name || ' � ����������� ������') name_gen,
                           to_char(min(pf.begeng), 'dd.mm.yyyy') sbegeng,
                           to_char(max(pf.endeng), 'dd.mm.yyyy') sendeng,
                           sum(case
                                 when sc.compch_type = 10 then
                                  sp.sum
                               end) n,
                           sum(case
                                 when sp.slcompcharges in (select SLS.SLCOMPCHARGES
                                                             from SLCOMPGR SLG, SLCOMPGRSTRUCT SLS
                                                            where SLS.PRN = SLG.RN
                                                              and SLG.CODE = sU1) then
                                  sp.sum
                               end) u1,
                           sum(case
                                 when sp.slcompcharges in (select SLS.SLCOMPCHARGES
                                                             from SLCOMPGR SLG, SLCOMPGRSTRUCT SLS
                                                            where SLS.PRN = SLG.RN
                                                              and SLG.CODE = sU2) then
                                  sp.sum
                               end) u2,
                           sum(case
                                 when sp.slcompcharges in (select SLS.SLCOMPCHARGES
                                                             from SLCOMPGR SLG, SLCOMPGRSTRUCT SLS
                                                            where SLS.PRN = SLG.RN
                                                              and SLG.CODE = sU3) then
                                  sp.sum
                               end) u3,
                           sum(case
                                 when sp.slcompcharges in (select SLS.SLCOMPCHARGES
                                                             from SLCOMPGR SLG, SLCOMPGRSTRUCT SLS
                                                            where SLS.PRN = SLG.RN
                                                              and SLG.CODE = sU4) then
                                  sp.sum
                               end) u4,
                           sum(case
                                 when (sc.compch_type = 30) --
                                      and sp.slcompcharges not in --
                                      (select SLS.SLCOMPCHARGES
                                             from SLCOMPGR SLG, SLCOMPGRSTRUCT SLS
                                            where SLS.PRN = SLG.RN
                                              and SLG.CODE in (sV, --
                                                               sU1,
                                                               sU2,
                                                               sU3,
                                                               sU4)) then
                                  sp.sum
                               end) u5,
                           sum(case
                                 when sp.slcompcharges in --
                                      (select SLS.SLCOMPCHARGES
                                         from SLCOMPGR SLG, SLCOMPGRSTRUCT SLS
                                        where SLS.PRN = SLG.RN
                                          and SLG.CODE = sV) then
                                  sp.sum
                               end) v,
                           f_smonth_base(sp.month) smonth,
                           sp.year,
                           count(1) over(partition by cp.rn) npfcount
                      from clnpspfm       pf, --
                           slpays         sp,
                           clnpersons     cp,
                           agnlist        ag,
                           clnpsdep       cd,
                           ins_department de,
                           slcompcharges  sc,
                           selectlist     sel,
                           clnpspfm       pf2,
                           clnpspfmtypes  ct
                     where pf.rn = sel.document
                       and sel.ident = nRN
                       and pf.rn = sp.clnpspfm
                       and cp.rn = pf.persrn
                       and cp.rn = pf2.persrn
                       and pf.clnpspfmtypes = ct.rn
                       and ct.is_primary = 1
                       and dTill between pf2.begeng and nvl(pf2.endeng, dTill)
                       and ag.rn = cp.pers_agent
                       and pf2.psdeprn = cd.rn
                       and pf2.deptrn = de.rn
                       and sc.rn = sp.slcompcharges
                       and sc.compch_type in (10, 30)
                       and to_date('01.' || to_char(sp.month, '00') || '.' || sp.year, 'dd.mm.yyyy') between pdFrom and dTill
                     group by cp.rn,
                              sp.month, --
                              sp.year,
                              ag.agnfamilyname_to,
                              ag.agnfirstname_to,
                              ag.agnlastname_to,
                              cd.psdep_name_gen,
                              cd.psdep_code,
                              de.name_gen,
                              de.name
                     order by to_date('01.' || to_char(sp.month, '00') || '.' || sp.year, 'dd.mm.yyyy')) a) loop
    if c.npfcount <> c.all_count then
      p_exception(0, '���������� �������� ���������� ������ ����������.');
    end if;
    if c.rownum = 1 then
      prsg_excel.CELL_VALUE_WRITE('����',
                                  '���� ' || c.sfio_to || ' � ���, ��� ��� ������������� �������� ��������� ' || c.psdep_name_gen || ' ' || c.name_gen || ' � ' || c.sbegeng || ' �. � �� ' || nvl(c.sendeng, to_char(sysdate, 'dd.mm.yyyy')) || ' �. ����� ��������:');
      prsg_excel.CELL_VALUE_WRITE('�����', c.all_v || ' ���.');
      i := prsg_Excel.LINE_APPEND('������');
    else
      i := prsg_excel.LINE_CONTINUE('������');
    end if;
    prsg_Excel.CELL_VALUE_WRITE('�1', 0, i, c.smonth || ' ' || c.year);
    prsg_Excel.CELL_VALUE_WRITE('�2', 0, i, c.n);
    prsg_Excel.CELL_VALUE_WRITE('�3', 0, i, c.u1);
    prsg_Excel.CELL_VALUE_WRITE('�4', 0, i, c.u2);
    prsg_Excel.CELL_VALUE_WRITE('�5', 0, i, c.u3);
    prsg_Excel.CELL_VALUE_WRITE('�6', 0, i, c.u4);
    prsg_Excel.CELL_VALUE_WRITE('�7', 0, i, c.u5);
    prsg_Excel.CELL_VALUE_WRITE('�8', 0, i, c.v);
    if c.rownum = c.all_count then
      i := prsg_excel.LINE_CONTINUE('����');
      prsg_Excel.CELL_VALUE_WRITE('�2', 0, i, c.all_n);
      prsg_Excel.CELL_VALUE_WRITE('�3', 0, i, c.all_u1);
      prsg_Excel.CELL_VALUE_WRITE('�4', 0, i, c.all_u2);
      prsg_Excel.CELL_VALUE_WRITE('�5', 0, i, c.all_u3);
      prsg_Excel.CELL_VALUE_WRITE('�6', 0, i, c.all_u4);
      prsg_Excel.CELL_VALUE_WRITE('�7', 0, i, c.all_u5);
      prsg_Excel.CELL_VALUE_WRITE('�8', 0, i, c.all_v);
    end if;
  end loop;
  prsg_excel.LINE_DELETE('������');
  prsg_excel.LINE_DELETE('����');
end PP_SPRAVKA;
/*
  create public synonym PP_SPRAVKA for PP_SPRAVKA;
  grant execute on PP_SPRAVKA to public;
  */
/
