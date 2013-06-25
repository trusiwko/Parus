create or replace procedure PP_SALREP_2
--
 is

  i number;

  procedure init is
  begin
    prsg_excel.PREPARE;
    prsg_excel.SHEET_SELECT('Лист1');
    prsg_excel.COLUMN_DESCRIBE('Столбец');
    prsg_excel.COLUMN_CELL_DESCRIBE('Столбец', 'ДЗ');
    prsg_excel.COLUMN_CELL_DESCRIBE('Столбец', 'ДА');
    prsg_excel.COLUMN_CELL_DESCRIBE('Столбец', 'ДБ');
  end;

  procedure fini is
  begin
    prsg_excel.COLUMN_DELETE('Столбец');
  end;

begin
  init;
  for c in (select a.*, b.a, b.b
              from (select sum(a.nsumm_a) nsumm_a, sum(a.nsumm_b) nsumm_b, b.rn
                      from (select sum(nsumm) nsumm, decode(ntype, 1, 1) nsumm_a, decode(ntype, 2, 1) nsumm_b, persrn
                              from (select sum(nsumm) nsumm,
                                           case
                                             when sum(rateacc) = 1 and is_primary = 1 then
                                              1
                                             else
                                              2
                                           end ntype,
                                           persrn
                                      from (select sum(decode(sl.compch_type, 10, s.sum)) nsumm, --
                                                   hs.rateacc,
                                                   ct.is_primary,
                                                   pf.persrn
                                              from slpays s, clnpspfm pf, clnpspfmhs hs, clnpspfmtypes ct, slcompcharges sl
                                             where s.year = 2012
                                               and s.monthfor = 4
                                               and pf.rn = s.clnpspfm
                                               and ct.rn = pf.clnpspfmtypes
                                               and sl.rn = s.slcompcharges
                                               and hs.prn = pf.rn
                                               and ((pf.endeng is null and hs.do_act_to is null) or (pf.endeng between hs.do_act_from and hs.do_act_to))
                                             group by ct.is_primary, pf.persrn, hs.rateacc, pf.rn) a
                                     group by is_primary, persrn)
                             group by ntype, persrn) a,
                           (select 0 rn, null a, min(to_number(t.strt_cond)) b
                              from SALSTRUC t
                             where prn = 155683498
                             group by prn
                            union all
                            select 1 rn, min(to_number(t.strt_cond)) a, min(to_number(t.strt_cond)) b
                              from SALSTRUC t
                             where prn = 155683498
                             group by prn
                            union all
                            select a.rn,
                                   a.nvalue, --
                                   lead(a.nvalue) over(order by a.nvalue) b
                              from (select t.rn, to_number(t.strt_cond) nvalue, prn from SALSTRUC t where prn = 155683498 order by nvalue) a) b
                     where a.nsumm > nvl(b.a, a.nsumm - 1)
                       and a.nsumm <= nvl(b.b, a.nsumm)
                     group by b.rn) a,
                   (select 0 rn, null a, min(to_number(t.strt_cond)) b
                      from SALSTRUC t
                     where prn = 155683498
                     group by prn
                    union all
                    select 1 rn, min(to_number(t.strt_cond)) a, min(to_number(t.strt_cond)) b
                      from SALSTRUC t
                     where prn = 155683498
                     group by prn
                    union all
                    select a.rn,
                           a.nvalue, --
                           lead(a.nvalue) over(order by a.nvalue) b
                      from (select t.rn, to_number(t.strt_cond) nvalue, prn from SALSTRUC t where prn = 155683498 order by nvalue) a) b
             where a.rn(+) = b.rn
             order by b.a nulls first, b.b) loop
    if i is null then
      i := prsg_excel.COLUMN_APPEND('Столбец');
    else
      i := prsg_excel.COLUMN_CONTINUE('Столбец');
    end if;
    if c.a is null then
      prsg_excel.CELL_VALUE_WRITE('ДЗ', i, 0, 'До ' || c.b || ' руб.');
    elsif c.a = c.b then
      prsg_excel.CELL_VALUE_WRITE('ДЗ', i, 0, 'На уровне ' || c.a || ' руб.');
    elsif c.b is null then
      prsg_excel.CELL_VALUE_WRITE('ДЗ', i, 0, 'Свыше ' || c.a || ' руб.');
    else
      prsg_excel.CELL_VALUE_WRITE('ДЗ', i, 0, c.a + 0.1 || ' - ' || c.b || ' руб.');
    end if;
    prsg_excel.CELL_VALUE_WRITE('ДА', i, 0, c.nsumm_a);
    prsg_excel.CELL_VALUE_WRITE('ДБ', i, 0, c.nsumm_b);
  end loop;
  fini;
end PP_SALREP_2;
/
