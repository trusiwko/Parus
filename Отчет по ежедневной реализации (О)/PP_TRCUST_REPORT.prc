create or replace procedure PP_TRCUST_REPORT
-- Отчет по продажам за день
(nCOMPANY in number, dDATE in date, dDATETO in date, sSTORE in varchar2) is

  iROW   number;
  dROW   number;
  sROW   varchar2(1);
  nSTORE number;

  -- Кручу, верчу, запутать хочу:
  cursor cREC(dDATE in date, dDATETO in date, nSTORE in number) is
    select a.*, --
           round((a.out_sum_wotax / a.in_sum_wotax - 1) * 100, 2) perc_plus_wotax,
           round((a.out_sum_tax / a.in_sum_tax - 1) * 100, 2) perc_plus_tax,
           sum(a.g4 * (1 - a.g3)) over(order by n rows unbounded preceding) s3,
           sum(a.g3 * (1 - a.g2)) over(order by n rows unbounded preceding) s2,
           sum(a.g2 * (1 - a.g1)) over(order by n rows unbounded preceding) s1
      from (select ti.agnabbr,
                   ti.scontract,
                   gp.gtd,
                   dn.nomen_name,
                   sum(s.quant) quant,
                   sum(rp.price_wotax * s.quant) in_sum_wotax,
                   sum(rp.price_tax * s.quant) in_sum_tax,
                   sum(s.summ) out_sum_wotax,
                   sum(s.summtax) out_sum_tax,
                   sum(s.summ - rp.price_wotax * s.quant) plus_wotax,
                   --round(avg((s.summ / (rp.price_wotax * s.quant) - 1) * 100), 2) perc_plus_wotax,
                   sum(s.summtax - rp.price_tax * s.quant) plus_tax,
                   --round(avg((s.summtax / (rp.price_tax * s.quant) - 1) * 100), 2) perc_plus_tax,
                   grouping(ti.agnabbr) g1,
                   grouping(ti.scontract) g2,
                   grouping(gp.gtd) g3,
                   grouping(dn.nomen_name) g4,
                   row_number() over(order by agnabbr, scontract, gtd, nomen_name) n,
                   row_number() over(partition by agnabbr order by agnabbr, scontract, gtd, nomen_name) n1,
                   row_number() over(partition by agnabbr, scontract order by agnabbr, scontract, gtd, nomen_name) n2,
                   row_number() over(partition by agnabbr, scontract, gtd order by agnabbr, scontract, gtd, nomen_name) n3,
                   row_number() over(partition by agnabbr, scontract, gtd, nomen_name order by agnabbr, scontract, gtd, nomen_name) n4
              from storeoperjourn s, --
                   goodssupply gs,
                   (select rn, indoc, nommodif, nvl(gp.gtd, '(Пусто)') gtd from goodsparties gp) gp,
                   nommodif nm,
                   dicnomns dn,
                   (select i.party,
                           ag.agnabbr, --
                           nvl(max(dt.doccode || decode(i.confdocnumb, null, null, ' ' || i.confdocnumb) || decode(i.confdocdate, null, null, ' от ' || to_char(i.confdocdate, 'dd.mm.yyyy') || ' г.')), '(Пусто)') scontract
                      from inorders i, agnlist ag, doctypes dt
                     where ag.rn = i.contragent
                       and dt.rn(+) = i.confdoctype
                     group by i.party, --
                              ag.agnabbr) ti,
                   (select max(a.price) keep(dense_rank last order by a.adate) price_tax, --
                           max(round(a.price * (100 - a.p_value_ret) / 100, 2)) keep(dense_rank last order by a.adate) price_wotax,
                           a.prn
                      from (select rp.price, --
                                   rp.adate,
                                   max(ds.p_value) keep(dense_rank last order by ds.beg_date) p_value,
                                   max(ds.p_value_ret) keep(dense_rank last order by ds.beg_date) p_value_ret,
                                   rp.price_calc_rule,
                                   rp.prn
                              from regprice rp, dictaxis ds
                             where ds.tax_group = rp.taxgr
                               and ds.beg_date <= rp.adate
                             group by rp.price, rp.adate, rp.taxgr, rp.price_calc_rule, rp.prn) a
                     group by a.prn) rp
             where s.operdate between dDATE and dDATETO
               and s.unitcode = 'GoodsTransInvoicesToConsumers'
               and s.goodssupply = gs.rn
               and gs.prn = gp.rn
               and gp.nommodif = nm.rn
               and nm.prn = dn.rn
               and gp.indoc = ti.party
               and rp.prn(+) = gs.rn
               and gs.store = nSTORE
             group by rollup(ti.agnabbr, ti.scontract, gp.gtd, dn.nomen_name)) a
     order by n;

  procedure init(nCOMPANY in number, dDATE in date, dDATETO in date, sSTORE in varchar2, nSTORE out number) is
  begin
    find_dicstore_numb(0, nCOMPANY, sSTORE, nSTORE);
  
    prsg_excel.PREPARE;
    prsg_excel.SHEET_SELECT('Лист1');
    prsg_excel.CELL_DESCRIBE('Дата');
    prsg_excel.CELL_DESCRIBE('Склад');
    for i in 1 .. 5 loop
      prsg_excel.LINE_DESCRIBE('Строка' || i);
      for j in 1 .. 10 loop
        prsg_excel.LINE_CELL_DESCRIBE('Строка' || i, 'Д' || i || '_' || j);
      end loop;
    end loop;
    if dDATETO is null then
      prsg_excel.CELL_VALUE_WRITE('Дата', 'Отчет по продажам за ' || d_day(dDATE) || ' ' || lower(f_smonth_base(d_month(dDATE), 1)) || ' ' || d_year(dDATE) || ' г.');
    else
      prsg_excel.CELL_VALUE_WRITE('Дата',
                                  'Отчет по продажам за период с ' || d_day(dDATE) || ' ' || lower(f_smonth_base(d_month(dDATE), 1)) || ' ' || d_year(dDATE) || ' г. по ' || d_day(dDATETO) || ' ' || lower(f_smonth_base(d_month(dDATETO), 1)) || ' ' || d_year(dDATETO) || ' г.');
    end if;
    prsg_excel.CELL_VALUE_WRITE('Склад', 'По складу: ' || sSTORE);
  end;

  procedure fini is
  begin
    for i in 1 .. 5 loop
      prsg_excel.LINE_DELETE('Строка' || i);
    end loop;
  end;

begin
  init(nCOMPANY, dDATE, dDATETO, sSTORE, nSTORE);
  for rREC in cREC(dDATE, nvl(dDATETO, dDATE), nSTORE) loop
    sROW := null;
    dROW := null;
    if rREC.N1 = 1 and rREC.G1 = 0 then
      -- Добавим строку по контрагенту, пока без итогов:
      if iROW is null then
        iROW := prsg_excel.LINE_APPEND('Строка1');
      else
        iROW := prsg_excel.LINE_CONTINUE('Строка1');
      end if;
      prsg_excel.CELL_VALUE_WRITE('Д1_1', 0, iROW, rREC.Agnabbr);
      dROW := iROW;
    end if;
    if rREC.N2 = 1 and rREC.G2 = 0 then
      -- Добавим строку по договору, пока без итогов:
      iROW := prsg_excel.LINE_CONTINUE('Строка2');
      prsg_excel.CELL_VALUE_WRITE('Д2_1', 0, iROW, rREC.Scontract);
      dROW := iROW;
    end if;
    if rREC.N3 = 1 and rREC.G3 = 0 then
      -- Добавим строку по типу финансирования, пока без итогов:
      iROW := prsg_excel.LINE_CONTINUE('Строка3');
      prsg_excel.CELL_VALUE_WRITE('Д3_1', 0, iROW, rREC.Gtd);
      dROW := iROW;
    end if;
    if rREC.N4 = 1 and rREC.G4 = 0 then
      -- Добавим строку по номенклатуре, с данными
      iROW := prsg_excel.LINE_CONTINUE('Строка4');
      prsg_excel.CELL_VALUE_WRITE('Д4_1', 0, iROW, rREC.Nomen_Name);
      sROW := 4;
      dROW := iROW;
    end if;
    if rREC.G3 + rREC.G4 = 1 then
      -- Группировка по типу финансирования:
      sROW := '3';
      dROW := rREC.S3;
    end if;
    if rREC.G2 + rREC.G3 = 1 then
      -- Группировка по договору:
      sROW := '2';
      dROW := rREC.S2;
    end if;
    if rREC.G1 + rREC.G2 = 1 then
      -- Группировка по контрагенту:
      sROW := '1';
      dROW := rREC.S1;
    end if;
    if rREC.G1 = 1 then
      -- Группировка по всем контрагентам, итоговая:
      sROW := '5';
      iROW := prsg_excel.LINE_CONTINUE('Строка' || sROW);
      dROW := iROW;
      prsg_excel.CELL_VALUE_WRITE('Д' || sROW || '_1', 0, dROW, 'ИТОГО:');
    end if;
    if (sROW is not null) and (dROW is not null) then
      prsg_excel.CELL_VALUE_WRITE('Д' || sROW || '_2', 0, dROW, rREC.Quant);
      prsg_excel.CELL_VALUE_WRITE('Д' || sROW || '_3', 0, dROW, rREC.In_Sum_Wotax);
      prsg_excel.CELL_VALUE_WRITE('Д' || sROW || '_4', 0, dROW, rREC.In_Sum_Tax);
      prsg_excel.CELL_VALUE_WRITE('Д' || sROW || '_5', 0, dROW, rREC.Out_Sum_Wotax);
      prsg_excel.CELL_VALUE_WRITE('Д' || sROW || '_6', 0, dROW, rREC.Out_Sum_Tax);
      prsg_excel.CELL_VALUE_WRITE('Д' || sROW || '_7', 0, dROW, rREC.Perc_Plus_Wotax);
      prsg_excel.CELL_VALUE_WRITE('Д' || sROW || '_8', 0, dROW, rREC.Plus_Wotax);
      prsg_excel.CELL_VALUE_WRITE('Д' || sROW || '_9', 0, dROW, rREC.Perc_Plus_Tax);
      prsg_excel.CELL_VALUE_WRITE('Д' || sROW || '_10', 0, dROW, rREC.Plus_Tax);
    end if;
  end loop;
  fini;
end PP_TRCUST_REPORT;
/
