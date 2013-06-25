create or replace procedure PP_SPRAVKA
-- Справка о средней ЗП
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
  prsg_excel.SHEET_SELECT('Лист1');
  prsg_excel.CELL_DESCRIBE('Дана');
  prsg_excel.CELL_DESCRIBE('Итого');
  prsg_Excel.LINE_DESCRIBE('Строка');
  prsg_Excel.LINE_DESCRIBE('Итог');
  for i in 1 .. 8 loop
    prsg_excel.LINE_CELL_DESCRIBE('Строка', 'Д' || i);
    prsg_excel.LINE_CELL_DESCRIBE('Итог', 'И' || i);
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
                           pnvl(0, cd.psdep_name_gen, 'должность ' || cd.psdep_code || ' в родительном падеже') psdep_name_gen,
                           pnvl(0, de.name_gen, 'подразделение ' || de.name || ' в родительном падеже') name_gen,
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
      p_exception(0, 'Необходимо выделить исполнения одного сотрудника.');
    end if;
    if c.rownum = 1 then
      prsg_excel.CELL_VALUE_WRITE('Дана',
                                  'Дана ' || c.sfio_to || ' в том, что она действительно занимает должность ' || c.psdep_name_gen || ' ' || c.name_gen || ' с ' || c.sbegeng || ' г. и по ' || nvl(c.sendeng, to_char(sysdate, 'dd.mm.yyyy')) || ' г. Доход составил:');
      prsg_excel.CELL_VALUE_WRITE('Итого', c.all_v || ' руб.');
      i := prsg_Excel.LINE_APPEND('Строка');
    else
      i := prsg_excel.LINE_CONTINUE('Строка');
    end if;
    prsg_Excel.CELL_VALUE_WRITE('Д1', 0, i, c.smonth || ' ' || c.year);
    prsg_Excel.CELL_VALUE_WRITE('Д2', 0, i, c.n);
    prsg_Excel.CELL_VALUE_WRITE('Д3', 0, i, c.u1);
    prsg_Excel.CELL_VALUE_WRITE('Д4', 0, i, c.u2);
    prsg_Excel.CELL_VALUE_WRITE('Д5', 0, i, c.u3);
    prsg_Excel.CELL_VALUE_WRITE('Д6', 0, i, c.u4);
    prsg_Excel.CELL_VALUE_WRITE('Д7', 0, i, c.u5);
    prsg_Excel.CELL_VALUE_WRITE('Д8', 0, i, c.v);
    if c.rownum = c.all_count then
      i := prsg_excel.LINE_CONTINUE('Итог');
      prsg_Excel.CELL_VALUE_WRITE('И2', 0, i, c.all_n);
      prsg_Excel.CELL_VALUE_WRITE('И3', 0, i, c.all_u1);
      prsg_Excel.CELL_VALUE_WRITE('И4', 0, i, c.all_u2);
      prsg_Excel.CELL_VALUE_WRITE('И5', 0, i, c.all_u3);
      prsg_Excel.CELL_VALUE_WRITE('И6', 0, i, c.all_u4);
      prsg_Excel.CELL_VALUE_WRITE('И7', 0, i, c.all_u5);
      prsg_Excel.CELL_VALUE_WRITE('И8', 0, i, c.all_v);
    end if;
  end loop;
  prsg_excel.LINE_DELETE('Строка');
  prsg_excel.LINE_DELETE('Итог');
end PP_SPRAVKA;
/*
  create public synonym PP_SPRAVKA for PP_SPRAVKA;
  grant execute on PP_SPRAVKA to public;
  */
/
