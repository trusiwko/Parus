create or replace procedure PP_REGRESSIA
-- Отчет "Проверка фондов (регрессия)"
(nIDENT in number, BDATE in date, EDATE in DATE, sSLCOMPGR in varchar2, nERRONLY in number) is

  nMPSUMM          number := 4000;
  sSCALES_FSS      varchar2(500) := 'ФСС;ФФОМС';
  sSCALES_PFS      varchar2(500) := 'ПФС1;ПФС2;Солидарная;ПФН1;ПФН2;Доп.тариф 58.3 п.1;Доп.тариф 58.3 п.2';
  sSCALES_BEFORE67 varchar2(500) := 'ПФС1;ПФН1';
  sSCALES_AFTER66  varchar2(500) := 'ПФС2;ПФН2';
  sSCALE           SALTAXSCALE.CODE%type;
  psSCALE          SALTAXSCALE.CODE%type;
  nBASE            number;
  nBASE_CALC       number;
  nNALOG           number;
  sGROUP           varchar2(200);
  nFACT_SUM        number;
  nDISC            number;
  nNEOBL           number;

  iROW number;
  iCOL number;
  nROW number;

  cursor cSCALE(sCODE in varchar2, EDATE in date) is
    select s.percent percent, --
           lag(s.income) over(order by income) income_from,
           s.income income_to,
           row_number() over(order by income) nrow,
           sum(s.percent * s.income / 100) over(order by income) - s.percent * s.income / 100 nPREVSUM,
           count(1) over() ncount
      from SALTAXSCALE sa, SALTAXEDITS MS, SALTAXSTRUC S
     where sa.code = sCODE
       and ms.PRN = sa.rn
       and s.prn = ms.rn
       and ms.edtax_begin = (select max(ms.edtax_begin)
                               from SALTAXEDITS MS
                              where PRN = sa.rn
                                and ms.edtax_begin <= EDATE)
     order by income;

  cursor cPERS(nIDENT in number, sSLCOMPGR in varchar2, nMPSUM in number, BDATE in date, EDATE in date) is
    select a.clnpersons, --
           a.agnburn,
           a.summ_doh,
           a.summ_vmen,
           a.summ_neobl,
           a.summ_mp,
           a.MPSUM,
           a.summ_fss,
           a.summ_ffoms,
           a.summ_pfs,
           a.summ_solid,
           a.summ_dt,
           a.summ_pfn,
           a.summ_doh + a.MPSUM baza_fss, -- tfoms, ffoms
           a.summ_doh + a.MPSUM + a.summ_vmen baza_pfs, -- solid, pfn
           a.summ_neobl + a.summ_mp - a.MPSUM summ_neobl_all,
           a.summ_mp - a.MPSUM summ_disc_all,
           a.ndeptrn,
           a.summ_doh_sol1,
           a.summ_doh_sol2,
           (1 - a.contract_sign) * (a.summ_doh + a.MPSUM) baza_fss_dog
      from (select t.clnpersons as clnpersons, --
                   max(cp.contract_sign) contract_sign,
                   max(ag.agnburn) as agnburn,
                   max(decode(ct.is_primary, 1, pf.deptrn)) keep(dense_rank last order by pf.begeng) ndeptrn,
                   sum(decode(y.formula, '+', t.sum, 0)) as summ_doh, -- облагаемый доход
                   sum(decode(y.formula, 'V', t.sum, 0)) as summ_vmen, -- вмененный доход
                   sum(decode(y.formula, 'N', t.sum, 0)) as summ_neobl, -- необлагаемый доход
                   sum(decode(y.formula, 'E', t.sum, 0)) as summ_mp, -- мат.помощь
                   case
                     when (sum(decode(y.formula, 'E', t.sum, 0)) > nMPSUM) then
                      sum(decode(y.formula, 'E', t.sum, 0)) - nMPSUM
                     else
                      0
                   end MPSUM,
                   -- Фонды:
                   sum(decode(y.formula, 'S', t.sum, 0)) as summ_fss, -- ФСС
                   sum(decode(y.formula, 'F', t.sum, 0)) as summ_ffoms, -- ФФОМС
                   sum(decode(y.formula, 'C', t.sum, 0)) as summ_pfs, -- ПФС 
                   sum(decode(y.formula, 'C2', t.sum, 0)) as summ_solid, -- Солидарная
                   sum(decode(y.formula, 'DT', t.sum, 0)) as summ_dt, -- Доп.тариф
                   sum(decode(y.formula, 'H', t.sum, 0)) as summ_pfn, -- ПФН      
                   sum(decode(y.formula, '+', t.sum, 0) * pkg_clnpspfm.check_tar_sol_pfr(pf.rn, INT2DATE(1, t.MONTH, t.YEAR), 1)) summ_doh_sol1, -- облагаемый доход с учетом доп.тарифа 1
                   sum(decode(y.formula, '+', t.sum, 0) * pkg_clnpspfm.check_tar_sol_pfr(pf.rn, INT2DATE(1, t.MONTH, t.YEAR), 2)) summ_doh_sol2 -- облагаемый доход с учетом доп.тарифа 2
              from SLPAYS         t, --
                   SLCOMPGR       r,
                   SLCOMPGRSTRUCT y,
                   agnlist        ag,
                   clnpersons     cp,
                   clnpspfm       pf,
                   clnpspfmtypes  ct,
                   selectlist     sl
             where SL.IDENT = nIDENT
               and t.clnpersons = SL.DOCUMENT
               and t.agent = ag.rn
               and r.code = sSLCOMPGR
               and y.prn = r.rn
               and t.year >= to_number(to_char(BDATE, 'YYYY'))
               and t.year <= to_number(to_char(EDATE, 'YYYY'))
               and t.month >= to_number(to_char(BDATE, 'MM'))
               and t.month <= to_number(to_char(EDATE, 'MM'))
               and t.slcompcharges = y.slcompcharges
               and t.clnpspfm = pf.rn
               and pf.clnpspfmtypes = ct.rn
               and t.clnpersons = cp.rn
             GROUP by t.clnpersons) a;

  cursor cREC is
    select a.*, --
           dense_rank() over(order by GROUP_NAME, AGNFAMILYNAME, AGNFIRSTNAME, AGNLASTNAME) nROW, -- Номер ПП
           row_number() over(partition by CLNPERSONS order by GROUP_NAME, AGNFAMILYNAME, AGNFIRSTNAME, AGNLASTNAME, SCALE_CODE) nROW2, -- Если 1 - началась новая фамилия
           row_number() over(partition by GROUP_NAME order by GROUP_NAME, AGNFAMILYNAME, AGNFIRSTNAME, AGNLASTNAME, SCALE_CODE) nROW_GROUP, -- Если 1 - началась новая группа
           dense_rank() over(order by SCALE_CODE) nCOL
      from (select AG.AGNFAMILYNAME, --
                   AG.AGNFIRSTNAME,
                   AG.AGNLASTNAME,
                   DE.NAME SDEPARTMENT,
                   trim(CP.TAB_NUMB) TAB_NUMB,
                   to_char(AG.AGNBURN, 'dd.mm.yyyy') sAGNBURN,
                   decode(AG.SEX, 1, 'Муж', 'Жен') sSEX,
                   max(sERR) over(partition by TT.CLNPERSONS) sERRMAX,
                   TT.*
              from (select T.CLNPERSONS, --
                           T.DEPTRN,
                           max(decode(T.SCALE_CODE, 'ФСС', max(T.GROUP_NAME))) over(partition by T.CLNPERSONS) GROUP_NAME, -- Регрессию берем по ФСС
                           T.SCALE_CODE,
                           (T.BASE_SUM) BASE_SUM,
                           (T.FACT_SUM_DISC) FACT_SUM_DISC,
                           (T.FACT_SUM_NEOBL) FACT_SUM_NEOBL,
                           sum(T.NALOG_SUM) NALOG_SUM,
                           (T.FACT_SUM) FACT_SUM,
                           decode(sum(T.NALOG_SUM) - T.FACT_SUM, 0, null, '!') sERR
                      from TP_REGRESSIA T
                     where t.authid = user
                     group by T.CLNPERSONS, --
                              T.DEPTRN,
                              T.SCALE_CODE,
                              T.BASE_SUM,
                              T.FACT_SUM_DISC,
                              T.FACT_SUM_NEOBL,
                              T.FACT_SUM) TT,
                   CLNPERSONS CP,
                   AGNLIST AG,
                   INS_DEPARTMENT DE
             where TT.CLNPERSONS = CP.RN
               and CP.PERS_AGENT = AG.RN
               and DE.RN = TT.DEPTRN
             order by GROUP_NAME, AGNFAMILYNAME, AGNFIRSTNAME, AGNLASTNAME, SCALE_CODE) a
     where (nERRONLY = 0 or a.sERRMAX is not null)
     order by GROUP_NAME, AGNFAMILYNAME, AGNFIRSTNAME, AGNLASTNAME, SCALE_CODE;

  procedure init is
  begin
    prsg_excel.PREPARE;
    prsg_excel.SHEET_SELECT('Лист1');
    prsg_excel.CELL_DESCRIBE('Период');
    prsg_excel.LINE_DESCRIBE('Группа');
    prsg_excel.LINE_DESCRIBE('Строка');
    prsg_excel.LINE_DESCRIBE('Строка2');
    prsg_excel.COLUMN_DESCRIBE('Столбец');
    prsg_excel.LINE_CELL_DESCRIBE('Группа', 'ГруппаЯ');
    prsg_excel.LINE_CELL_DESCRIBE('Строка', 'Номер');
    prsg_excel.LINE_CELL_DESCRIBE('Строка', 'Заголовок');
    prsg_excel.LINE_CELL_DESCRIBE('Строка', 'Название');
    prsg_excel.LINE_CELL_DESCRIBE('Строка', 'Ячейка');
    prsg_excel.LINE_CELL_DESCRIBE('Строка', 'Ошибка');
    prsg_excel.COLUMN_CELL_DESCRIBE('Столбец', 'Ячейка');
    prsg_excel.COLUMN_CELL_DESCRIBE('Столбец', 'СтолбецЗ');
  end;

  procedure fini is
  begin
    prsg_excel.LINE_DELETE('Группа');
    prsg_excel.LINE_DELETE('Строка');
    prsg_excel.LINE_DELETE('Строка2');
    prsg_excel.COLUMN_DELETE('Столбец');
  end;

begin
  delete from TP_REGRESSIA t where t.authid = user;
  -- Цикл по сотрудникам:
  for rPERS in cPERS(nIDENT, sSLCOMPGR, nMPSUMM, BDATE, EDATE) loop
    -- Цикл по всем шкалам:
    for k in 1 .. stroccurs(sSCALES_FSS || ';' || sSCALES_PFS, ';') + 1 loop
      sSCALE := strtok(sSCALES_FSS || ';' || sSCALES_PFS, ';', k);
      -- Определение базы:
      if instr(sSCALES_FSS, sSCALE) > 0 then
        nBASE := rPERS.Baza_Fss;
      elsif instr(sSCALES_PFS, sSCALE) > 0 then
        nBASE := rPERS.Baza_Pfs;
      else
        nBASE := 0;
      end if;
      nBASE_CALC := nBASE;
      -- Определение факта:
      psSCALE := sSCALE;
      if sSCALE = 'ФСС' then
        nFACT_SUM  := rPERS.Summ_Fss;
        nBASE_CALC := rPERS.BAZA_FSS_DOG;
      elsif sSCALE = 'ФФОМС' then
        nFACT_SUM := rPERS.Summ_Ffoms;
      elsif sSCALE in ('ПФС1', 'ПФС2') then
        psSCALE   := 'ПФС';
        nFACT_SUM := rPERS.Summ_Pfs;
      elsif sSCALE = 'Солидарная' then
        nFACT_SUM := rPERS.Summ_Solid;
      elsif sSCALE in ('ПФН1', 'ПФН2') then
        psSCALE   := 'ПФН';
        nFACT_SUM := rPERS.Summ_Pfn;
      elsif sSCALE in ('Доп.тариф 58.3 п.1', 'Доп.тариф 58.3 п.2') then
        psSCALE    := 'Доп.тариф 58.3';
        nFACT_SUM  := rPERS.Summ_DT;
        nBASE_CALC := 0;
        if sSCALE = 'Доп.тариф 58.3 п.1' then
          nBASE_CALC := rPERS.Summ_Doh_Sol1;
        elsif sSCALE = 'Доп.тариф 58.3 п.2' then
          nBASE_CALC := rPERS.Summ_Doh_Sol2;
        end if;
        if (nBASE_CALC <> 0) then
          nBASE_CALC := nBASE_CALC + rPERS.MPSUM + rPERS.summ_vmen;
        end if;
      else
        psSCALE   := '?';
        nFACT_SUM := 0;
      end if;
    
      -- Цикл по редакциям шкалы:
      sGROUP := '';
      nNALOG := 0;
      for rSCALE in cSCALE(sSCALE, EDATE) loop
        if (nBASE > nvl(rSCALE.Income_From, nBASE - 1)) and (nBASE <= rSCALE.Income_To) then
          if rSCALE.Income_From is not null then
            sGROUP := 'От ' || rSCALE.Income_From || ' руб.';
          end if;
          if rSCALE.Nrow <> rSCALE.Ncount then
            sGROUP := sGROUP || ' До ' || rSCALE.Income_To || ' руб.';
          end if;
          nNALOG := Round((nBASE_CALC - nvl(rSCALE.Income_From, 0)) * rSCALE.Percent / 100 + rSCALE.nPREVSUM, 2);
        end if;
      end loop;
    
      nDISC  := rPERS.summ_disc_all;
      nNEOBL := rPERS.summ_neobl_all;
    
      -- Ограничение по датам рождения:
      if (D_YEAR(rPERS.Agnburn) <= 1966) and (instr(sSCALES_AFTER66, sSCALE) > 0) then
        nNALOG := 0;
      end if;
      if (D_YEAR(rPERS.Agnburn) >= 1967) and (instr(sSCALES_BEFORE67, sSCALE) > 0) then
        nNALOG := 0;
      end if;
    
      insert into TP_REGRESSIA
        (authid, ident, clnpersons, group_name, scale_code, base_sum, nalog_sum, fact_sum, fact_sum_disc, fact_sum_neobl, deptrn) --
      values
        (user, nIDENT, rPERS.Clnpersons, sGROUP, psSCALE, nBASE, nNALOG, nFACT_SUM, nDISC, nNEOBL, rPERS.ndeptrn);
    
    end loop;
  end loop;

  init;

  prsg_excel.CELL_VALUE_WRITE('Период', 'за период с ' || to_char(BDATE, 'dd.mm.yyyy') || ' г. по ' || to_char(EDATE, 'dd.mm.yyyy') || ' г.');

  for rREC in cREC loop
    if rREC.Nrow2 = 1 then
      -- Новый человечек:
      -- Добавим 6 строк:
      for i in 1 .. 6 loop
        -- Если новый лимит превышен:
        if (i = 1) and (rREC.Nrow_Group = 1) then
          if iROW is null then
            iROW := prsg_excel.LINE_APPEND('Группа');
          else
            iROW := prsg_excel.LINE_CONTINUE('Группа');
          end if;
          prsg_excel.CELL_VALUE_WRITE('ГруппаЯ', 0, iROW, rREC.Group_Name);
        end if;
        -- Добавляем строки:
        iROW := prsg_excel.LINE_CONTINUE('Строка');
        if i = 1 then
          prsg_excel.CELL_VALUE_WRITE('Номер', 0, iROW, rREC.Nrow);
          prsg_excel.CELL_VALUE_WRITE('Заголовок', 0, iROW, rREC.Agnfamilyname);
          prsg_excel.CELL_VALUE_WRITE('Название', 0, iROW, 'Сумма дохода');
        elsif i = 2 then
          prsg_excel.CELL_VALUE_WRITE('Заголовок', 0, iROW, rREC.Agnfirstname);
          prsg_excel.CELL_VALUE_WRITE('Название', 0, iROW, 'Необлагаемая сумма');
        elsif i = 3 then
          prsg_excel.CELL_VALUE_WRITE('Заголовок', 0, iROW, rREC.Agnlastname);
          prsg_excel.CELL_VALUE_WRITE('Название', 0, iROW, 'Скидка по мат.пом');
        elsif i = 4 then
          prsg_excel.CELL_VALUE_WRITE('Заголовок', 0, iROW, rREC.Tab_Numb);
          prsg_excel.CELL_VALUE_WRITE('Название', 0, iROW, 'Облагаемая сумма');
        elsif i = 5 then
          prsg_excel.CELL_VALUE_WRITE('Заголовок', 0, iROW, rREC.Sdepartment);
          prsg_excel.CELL_VALUE_WRITE('Название', 0, iROW, 'Начислено фондов');
        elsif i = 6 then
          prsg_excel.CELL_VALUE_WRITE('Заголовок', 0, iROW, rREC.Sagnburn || ' ' || rREC.Ssex);
          prsg_excel.CELL_VALUE_WRITE('Название', 0, iROW, 'Должно быть начислено');
        end if;
        prsg_excel.CELL_VALUE_WRITE('Ошибка', 0, iROW, rREC.Serrmax);
      end loop;
      -- iROW = 6я строка, iROW - 5 = 1я строка
      nROW := prsg_excel.LINE_CONTINUE('Строка2');
    end if;
    -- Добавим столбец:
    while nvl(iCOL, 0) < rREC.Ncol loop
      if iCOL is null then
        iCOL := prsg_excel.COLUMN_APPEND('Столбец');
      else
        iCOL := prsg_excel.COLUMN_CONTINUE('Столбец');
      end if;
    end loop;
    -- Выводим данные:
    prsg_excel.CELL_VALUE_WRITE('СтолбецЗ', rREC.Ncol, 0, rREC.Scale_Code);
    prsg_excel.CELL_VALUE_WRITE('Ячейка', rREC.Ncol, iROW - 5, rREC.Base_Sum + rREC.Fact_Sum_Neobl);
    prsg_excel.CELL_VALUE_WRITE('Ячейка', rREC.Ncol, iROW - 4, rREC.Fact_Sum_Neobl);
    prsg_excel.CELL_VALUE_WRITE('Ячейка', rREC.Ncol, iROW - 3, rREC.Fact_Sum_Disc);
    prsg_excel.CELL_VALUE_WRITE('Ячейка', rREC.Ncol, iROW - 2, rREC.Base_Sum);
    prsg_excel.CELL_VALUE_WRITE('Ячейка', rREC.Ncol, iROW - 1, rREC.Fact_Sum);
    prsg_excel.CELL_VALUE_WRITE('Ячейка', rREC.Ncol, iROW, rREC.Nalog_Sum);
    if rREC.Serr is not null then
      prsg_excel.CELL_ATTRIBUTE_SET('Ячейка', rREC.Ncol, iROW - 1, 'Font.ColorIndex', 3);
      prsg_excel.CELL_ATTRIBUTE_SET('Ячейка', rREC.Ncol, iROW, 'Font.ColorIndex', 3);
    end if;
  end loop;

  fini;

end PP_REGRESSIA;
/
