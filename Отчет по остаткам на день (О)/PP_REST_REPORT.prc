create or replace procedure PP_REST_REPORT
--
(nCOMPANY in number, dDATE in date, sSTORE in varchar2) is

  iROW number;
  dROW number;
  sROW varchar2(1);

  cursor cREC(dDATE in date, sSTORES in varchar2) is
    select a.*, --
           sum(a.g5 * (1 - a.g4)) over(order by n rows unbounded preceding) s4,
           sum(a.g4 * (1 - a.g3)) over(order by n rows unbounded preceding) s3,
           sum(a.g3 * (1 - a.g2)) over(order by n rows unbounded preceding) s2,
           sum(a.g2 * (1 - a.g1)) over(order by n rows unbounded preceding) s1
      from (select az.azs_number, --
                   gp.gtd,
                   gp.agnabbr,
                   gp.scontract,
                   dn.nomen_name,
                   sum(gh.restfact) restfact,
                   sum(gh.summfact) summfact,
                   --
                   grouping(az.azs_number) g1,
                   grouping(gp.gtd) g2,
                   grouping(gp.agnabbr) g3,
                   grouping(gp.scontract) g4,
                   grouping(dn.nomen_name) g5,
                   --
                   row_number() over(order by az.azs_number, gp.gtd, gp.agnabbr, gp.scontract, dn.nomen_name) n,
                   row_number() over(partition by az.azs_number order by az.azs_number, gp.gtd, gp.agnabbr, gp.scontract, dn.nomen_name) n1,
                   row_number() over(partition by az.azs_number, gp.gtd order by az.azs_number, gp.gtd, gp.agnabbr, gp.scontract, dn.nomen_name) n2,
                   row_number() over(partition by az.azs_number, gp.gtd, gp.agnabbr order by az.azs_number, gp.gtd, gp.agnabbr, gp.scontract, dn.nomen_name) n3,
                   row_number() over(partition by az.azs_number, gp.gtd, gp.agnabbr, gp.scontract order by az.azs_number, gp.gtd, gp.agnabbr, gp.scontract, dn.nomen_name) n4,
                   row_number() over(partition by az.azs_number, gp.gtd, gp.agnabbr, gp.scontract, dn.nomen_name order by az.azs_number, gp.gtd, gp.agnabbr, gp.scontract, dn.nomen_name) n5
              from (select gp.rn, --
                           gp.indoc,
                           gp.nommodif,
                           nvl(gp.gtd, '(Пусто)') gtd,
                           nvl(ti.agnabbr, '(Пусто)') agnabbr,
                           nvl(ti.scontract, '(Пусто)') scontract
                      from goodsparties gp,
                           (select i.party,
                                   ag.agnabbr, --
                                   nvl(max(dt.doccode || decode(i.confdocnumb, null, null, ' ' || i.confdocnumb) || decode(i.confdocdate, null, null, ' от ' || to_char(i.confdocdate, 'dd.mm.yyyy') || ' г.')), '(Пусто)') scontract
                              from inorders i, agnlist ag, doctypes dt
                             where ag.rn = i.contragent
                               and dt.rn(+) = i.confdoctype
                             group by i.party, --
                                      ag.agnabbr) ti
                     where gp.indoc = ti.party(+)) gp, --
                   goodssupply gs,
                   goodssupplyhist gh,
                   azsazslistmt az,
                   nommodif nm,
                   dicnomns dn
             where gs.store = az.rn
               and instr(';' || sSTORES || ';', ';' || az.azs_number || ';') > 0
               and gs.rn = gh.prn
               and gp.rn = gs.prn
               and nm.rn = gp.nommodif
               and dn.rn = nm.prn
               and dDATE between gh.date_from and nvl(gh.date_to, dDATE)
             group by rollup(az.azs_number, --
                             gp.gtd,
                             gp.agnabbr,
                             gp.scontract,
                             dn.nomen_name)
            having sum(gh.restfact) <> 0) a
     order by n;

  procedure init(nCOMPANY in number, dDATE in date) is
  begin
    prsg_excel.PREPARE;
    prsg_excel.SHEET_SELECT('Лист1');
    prsg_excel.CELL_DESCRIBE('Дата');
    for i in 1 .. 6 loop
      prsg_excel.LINE_DESCRIBE('Строка' || i);
      for j in 1 .. 3 loop
        prsg_excel.LINE_CELL_DESCRIBE('Строка' || i, 'Д' || i || '_' || j);
      end loop;
    end loop;
    prsg_excel.CELL_VALUE_WRITE('Дата', 'Отчет по остаткам на ' || d_day(dDATE) || ' ' || lower(f_smonth_base(d_month(dDATE), 1)) || ' ' || d_year(dDATE) || ' г.');
  end;

  procedure fini is
  begin
    for i in 1 .. 6 loop
      prsg_excel.LINE_DELETE('Строка' || i);
    end loop;
  end;

begin
  init(nCOMPANY, dDATE);
  for rREC in cREC(dDATE, sSTORE) loop
    sROW := null;
    dROW := null;
    if rREC.N1 = 1 and rREC.G1 = 0 then
      -- Добавим строку по складу, пока без итогов:
      if iROW is null then
        iROW := prsg_excel.LINE_APPEND('Строка1');
      else
        iROW := prsg_excel.LINE_CONTINUE('Строка1');
      end if;
      prsg_excel.CELL_VALUE_WRITE('Д1_1', 0, iROW, rREC.Azs_Number);
      dROW := iROW;
    end if;
    if rREC.N2 = 1 and rREC.G2 = 0 then
      -- Добавим строку по типу финансирования, пока без итогов:
      iROW := prsg_excel.LINE_CONTINUE('Строка2');
      prsg_excel.CELL_VALUE_WRITE('Д2_1', 0, iROW, rREC.Gtd);
      dROW := iROW;
    end if;
    if rREC.N3 = 1 and rREC.G3 = 0 then
      -- Добавим строку по контрагенту, пока без итогов:
      iROW := prsg_excel.LINE_CONTINUE('Строка3');
      prsg_excel.CELL_VALUE_WRITE('Д3_1', 0, iROW, rREC.Agnabbr);
      dROW := iROW;
    end if;
    if rREC.N4 = 1 and rREC.G4 = 0 then
      -- Добавим строку по договору, пока без итогов:
      iROW := prsg_excel.LINE_CONTINUE('Строка4');
      prsg_excel.CELL_VALUE_WRITE('Д4_1', 0, iROW, rREC.Scontract);
      dROW := iROW;
    end if;
    if rREC.N5 = 1 and rREC.G5 = 0 then
      -- Добавим строку по номенклатуре, с данными
      iROW := prsg_excel.LINE_CONTINUE('Строка5');
      prsg_excel.CELL_VALUE_WRITE('Д5_1', 0, iROW, rREC.Nomen_Name);
      sROW := '5';
      dROW := iROW;
    end if;
    --
    if rREC.G4 + rREC.G5 = 1 then
      -- Группировка по договору:
      sROW := '4';
      dROW := rREC.S4;
    end if;
    if rREC.G3 + rREC.G4 = 1 then
      -- Группировка по контрагенту:
      sROW := '3';
      dROW := rREC.S3;
    end if;
    if rREC.G2 + rREC.G3 = 1 then
      -- Группировка по типу финансирования:
      sROW := '2';
      dROW := rREC.S2;
    end if;
    if rREC.G1 + rREC.G2 = 1 then
      -- Группировка по складу:
      sROW := '1';
      dROW := rREC.S1;
    end if;
    if rREC.G1 = 1 then
      -- Группировка по всем, итоговая:
      sROW := '6';
      iROW := prsg_excel.LINE_CONTINUE('Строка' || sROW);
      dROW := iROW;
      prsg_excel.CELL_VALUE_WRITE('Д' || sROW || '_1', 0, dROW, 'ИТОГО:');
    end if;
    if (sROW is not null) and (dROW is not null) then
      prsg_excel.CELL_VALUE_WRITE('Д' || sROW || '_2', 0, dROW, rREC.Restfact);
      prsg_excel.CELL_VALUE_WRITE('Д' || sROW || '_3', 0, dROW, rREC.Summfact);
    end if;
  end loop;
  fini;
end PP_REST_REPORT;
/
