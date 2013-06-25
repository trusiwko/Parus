create or replace procedure PP_DOGNOM_REPORT
-- Отчет по одноименной номенклатуре товаров, работ, услуг
(nyear in number) is
  i number;
begin
  prsg_excel.PREPARE;
  prsg_excel.SHEET_SELECT('Лист1');
  prsg_excel.LINE_DESCRIBE('Строка');
  for i in 1 .. 5 loop
    prsg_excel.LINE_CELL_DESCRIBE('Строка', 'Д' || i);
  end loop;
  for c in (select rownum, a.*, edv.str_value || '. ' || edv.note snomengroup
              from (select a.scode, --
                           sum(decode(a.nquarter, 1, a.nsumm, null)) ndog1,
                           sum(decode(a.nquarter, 2, a.nsumm, null)) ndog2,
                           sum(decode(a.nquarter, 3, a.nsumm, null)) ndog3,
                           sum(decode(a.nquarter, 4, a.nsumm, null)) ndog4
                      from (select dpv.str_value scode, fp_quarter(f.doc_date) nquarter, f.summ nsumm
                              from govcntr g, govcntrfin f, docs_props dp, docs_props_vals dpv
                             where g.rn = dpv.unit_rn
                               and dp.code = 'Номенклатура для зак'
                               and dp.rn = dpv.docs_prop_rn
                               and f.prn = g.rn
                               and to_char(f.doc_date, 'yyyy') = nyear
                             order by scode) a
                     group by a.scode) a,
                   extra_dicts_values edv
             where a.scode(+) = edv.str_value) loop
    if c.rownum = 1 then
      i := prsg_excel.LINE_APPEND('Строка');
    else
      i := prsg_excel.LINE_CONTINUE('Строка');
    end if;
    prsg_excel.CELL_VALUE_WRITE('Д1', 0, i, c.snomengroup);
    prsg_excel.CELL_VALUE_WRITE('Д2', 0, i, c.ndog1);
    prsg_excel.CELL_VALUE_WRITE('Д3', 0, i, c.ndog2);
    prsg_excel.CELL_VALUE_WRITE('Д4', 0, i, c.ndog3);
    prsg_excel.CELL_VALUE_WRITE('Д5', 0, i, c.ndog4);
  end loop;
  prsg_excel.LINE_DELETE('Строка');
end PP_DOGNOM_REPORT;
/*create public synonym PP_DOGNOM_REPORT for PP_DOGNOM_REPORT;
grant execute on PP_DOGNOM_REPORT to public;*/
/
