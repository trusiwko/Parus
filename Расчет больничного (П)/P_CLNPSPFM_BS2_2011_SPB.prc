create or replace procedure P_CLNPSPFM_BS2_2011_SPB
--
(nCOMPANY  in number, -- организация
 nIDENT    in number, -- помеченные ЛС
 sSLCOMPGR in varchar2, -- группа выплат
 dBEGIN    in date, -- отбор по периоду "В" с
 dEND      in date, -- отбор по периоду "В" по
 dFORBEGIN in date, -- отбор по периоду "ЗА" с
 dFOREND   in date, -- отбор по периоду "ЗА" по
 nCOMMON   in number, -- признак печати общей справки
 nDEKRET   in number, -- Форма для декретных
 sPOST     in varchar2,
 sFIO      in varchar2) as
  /* константы */
  -- рабочий лист
  SHEET_FORM constant PKG_STD.tSTRING := 'Расчет';
  CELL_SLP   constant PKG_STD.tSTRING := 'Вид_оплаты';
  CELL_FIO   constant PKG_STD.tSTRING := 'ФИО';
  CELL_PER   constant PKG_STD.tSTRING := 'Период';
  DETAIL2    constant PKG_STD.tSTRING := 'Детали2';
  CELL_PER1  constant PKG_STD.tSTRING := 'Период1';
  CELL_SUMZ  constant PKG_STD.tSTRING := 'CумЗаработок';
  CELL_SRZR  constant PKG_STD.tSTRING := 'Средний_заработок';
  CELL_NBOL  constant PKG_STD.tSTRING := 'Не_более';
  CELL_NMEN  constant PKG_STD.tSTRING := 'Не_менее_пособие';
  CELL_ITOG  constant PKG_STD.tSTRING := 'СуммаИтого';
  iDETAIL_1IDX integer := null;
  --  iDETAIL_1IDX         integer;
  --  iDETAIL_3IDX         integer;
  --  nLINE                integer := 0;

  nPROCESS        PKG_STD.tREF;
  nSLCOMPGR       PKG_STD.tREF;
  nYBGN           number(4);
  nMBGN           number(2);
  nYEND           number(4);
  nMEND           number(2);
  nYFORBGN        number(4);
  nMFORBGN        number(2);
  nYFOREND        number(4);
  nMFOREND        number(2);
  dCALCPRDBGN     date;
  dCALCPRDBGN2    date;
  odCALCPRDBGN    date;
  odCALCPRDBGN2   date;
  nTMP            SLPAYSPRM.NUM_VALUE%type;
  nYEARSUMLIM1    PKG_STD.tSUMM;
  nYEARSUMLIM2    PKG_STD.tSUMM;
  nDAYS           SLPAYSPRM.NUM_VALUE%type;
  nSUM            PKG_STD.tSUMM;
  nYEARSUM1       PKG_STD.tSUMM;
  nYEARSUM2       PKG_STD.tSUMM;
  dBEGIN_DATE     date;
  dEND_DATE       date;
  nABSDAYS        number;
  dFIRSTDATE      date;
  nCOUNT          number;
  nWRK            number;
  nPRC            number;
  nCALDAYS        number;
  nLIMITMIN       number;
  nLIMITMINRULE   number;
  sRELATIVE       varchar2(20);
  nCALCPRDDAYSQNT number;

begin

  /* идентификатор процесса */
  nPROCESS := GEN_IDENT;

  /* установка используемых временных таблиц */
  PKG_TEMP.SET_TEMP_USED('CLNPSPFM_SLPAYSGRPPRMREP', nPROCESS);

  FIND_SLCOMPGR_CODE(0, 0, nCOMPANY, sSLCOMPGR, nSLCOMPGR);

  /* удаление записи из таблицы */
  delete from CLNPSPFM_SLPAYSGRPPRMREP where AUTHID = UTILIZER;

  /* пролог */
  PRSG_EXCEL.PREPARE;
  /* установка текущего рабочего листа */
  PRSG_EXCEL.SHEET_SELECT(SHEET_FORM);
  /* описание */
  PRSG_EXCEL.LINE_DESCRIBE('Детали0');
  PRSG_EXCEL.LINE_CELL_DESCRIBE('Детали0', CELL_SLP);
  PRSG_EXCEL.LINE_CELL_DESCRIBE('Детали0', CELL_FIO);
  PRSG_EXCEL.LINE_CELL_DESCRIBE('Детали0', CELL_PER);
  PRSG_EXCEL.LINE_DESCRIBE('Детали1А');
  PRSG_EXCEL.LINE_CELL_DESCRIBE('Детали1А', 'Сумма1А');
  PRSG_EXCEL.LINE_CELL_DESCRIBE('Детали1А', 'Сумма2А');
  PRSG_EXCEL.LINE_CELL_DESCRIBE('Детали1А', 'Лимит1А');
  PRSG_EXCEL.LINE_CELL_DESCRIBE('Детали1А', 'Лимит2А');
  PRSG_EXCEL.LINE_CELL_DESCRIBE('Детали1А', 'Заработок1');
  PRSG_EXCEL.LINE_CELL_DESCRIBE('Детали1А', 'Заработок2');
  PRSG_EXCEL.LINE_DESCRIBE('Детали1Б');
  PRSG_EXCEL.LINE_CELL_DESCRIBE('Детали1Б', 'За_полный_месяцЗ');
  PRSG_EXCEL.LINE_DESCRIBE(DETAIL2);
  PRSG_EXCEL.LINE_CELL_DESCRIBE(DETAIL2, CELL_PER1);
  PRSG_EXCEL.LINE_CELL_DESCRIBE(DETAIL2, CELL_SUMZ);
  PRSG_EXCEL.LINE_CELL_DESCRIBE(DETAIL2, 'Длительность');
  PRSG_EXCEL.LINE_CELL_DESCRIBE(DETAIL2, 'За_полный_месяц');
  PRSG_EXCEL.LINE_CELL_DESCRIBE(DETAIL2, CELL_SRZR);
  PRSG_EXCEL.LINE_CELL_DESCRIBE(DETAIL2, 'Мин_ограничение');
  PRSG_EXCEL.LINE_CELL_DESCRIBE(DETAIL2, 'Дней');
  PRSG_EXCEL.LINE_CELL_DESCRIBE(DETAIL2, CELL_NBOL);
  PRSG_EXCEL.LINE_CELL_DESCRIBE(DETAIL2, CELL_NMEN);
  PRSG_EXCEL.LINE_CELL_DESCRIBE(DETAIL2, CELL_ITOG);
  PRSG_EXCEL.LINE_DESCRIBE('Детали2А');
  PRSG_EXCEL.LINE_DESCRIBE('Детали2Б');
  PRSG_EXCEL.LINE_CELL_DESCRIBE('Детали2Б', 'ДНВ1');
  PRSG_EXCEL.LINE_CELL_DESCRIBE('Детали2Б', 'ДНВ2');
  PRSG_EXCEL.LINE_CELL_DESCRIBE('Детали2Б', 'ДНВ3');
  PRSG_EXCEL.LINE_DESCRIBE('Детали2В');
  PRSG_EXCEL.LINE_DESCRIBE('Детали4');
  PRSG_EXCEL.LINE_CELL_DESCRIBE('Детали4', 'Должность');
  PRSG_EXCEL.LINE_CELL_DESCRIBE('Детали4', 'ФИО2');
  PRSG_EXCEL.COLUMN_DESCRIBE('Уход1');
  PRSG_EXCEL.COLUMN_DESCRIBE('БЛ1');

  -- инициализируем переменные для отбора начислений по контролируемому периоду
  nYBGN    := D_YEAR(dBEGIN);
  nMBGN    := D_MONTH(dBEGIN);
  nYEND    := D_YEAR(dEND);
  nMEND    := D_MONTH(dEND);
  nYFORBGN := D_YEAR(dFORBEGIN);
  nMFORBGN := D_MONTH(dFORBEGIN);
  nYFOREND := D_YEAR(dFOREND);
  nMFOREND := D_MONTH(dFOREND);
  -- люди
  for cGRP in (select SP.CLNPSPFM, --
                      SP.CLNPERSONS,
                      SP.RN,
                      SP.SLPAYGRND,
                      CL.PERS_AGENT,
                      A.AGNFAMILYNAME,
                      A.AGNFIRSTNAME,
                      A.AGNLASTNAME,
                      GP.dBGN,
                      GP.dEND
                 from SELECTLIST SL, --
                      SLPAYSGRP SP,
                      SLCOMPGRSTRUCT ST,
                      CLNPERSONS CL,
                      AGNLIST A,
                      (select PR.PRN, --
                              max(decode(PR.CODE, 'BGN', PR.DATE_VALUE)) dBGN,
                              max(decode(PR.CODE, 'END', PR.DATE_VALUE)) dEND
                         from SLPAYGRNDPRM PR
                        where PR.CODE in ('BGN', 'END')
                        group by PR.PRN) GP
                where SL.DOCUMENT = SP.CLNPSPFM
                  and SP.SLCOMPCHARGES = ST.SLCOMPCHARGES
                  and SP.CLNPERSONS = CL.RN
                  and CL.PERS_AGENT = A.RN
                  and ST.PRN = nSLCOMPGR
                  and SL.IDENT = nIDENT
                  and GP.PRN(+) = SP.SLPAYGRND
                  and ((dBEGIN is not null and (SP.YEAR > nYBGN or (SP.YEAR = nYBGN and SP.MONTH >= nMBGN))) or dBEGIN is null)
                  and ((dEND is not null and (SP.YEAR < nYEND or (SP.YEAR = nYEND and SP.MONTH <= nMEND))) or dEND is null)
                order by A.AGNFAMILYNAME, A.AGNFIRSTNAME, A.AGNLASTNAME, dBGN) loop
    /* начало расчетного периода */
    PKG_SLPAYSGRPPRM.GET(cGRP.RN, 'CALCPRDBGN', dCALCPRDBGN);
    PKG_SLPAYSGRPPRM.GET(cGRP.RN, 'CALCPRDBGN2', dCALCPRDBGN2);
    if dCALCPRDBGN2 is null then
      dCALCPRDBGN2 := add_months(dCALCPRDBGN, 12);
    else
      dCALCPRDBGN2 := trunc(dCALCPRDBGN2, 'Y');
    end if;
    odCALCPRDBGN  := dCALCPRDBGN;
    odCALCPRDBGN2 := dCALCPRDBGN2;
    /* годовой заработок с учетом ограничений */
    PKG_SLPAYSGRPPRM.GET(cGRP.RN, 'YEARSUMLIM1', nYEARSUMLIM1);
    PKG_SLPAYSGRPPRM.GET(cGRP.RN, 'YEARSUMLIM2', nYEARSUMLIM2);
    nYEARSUM1 := 0;
    nYEARSUM2 := 0;
    /* параметры по месяцам*/
    for i in 1 .. 24 loop
      /* заработок неиндексируемый */
      PKG_SLPAYSGRPPRM.GET(cGRP.RN, 'AVGSUM' || trim(to_char(i)), nTMP, 0);
      insert into CLNPSPFM_SLPAYSGRPPRMREP
        (RN, IDENT, CONNECT_EXT, AUTHID, MONTH, YEARFOR, MONTHFOR, AVGSUM) --
      values
        (cGRP.RN, nPROCESS, PKG_SESSION.GET_CONNECT_EXT, UTILIZER, i, D_YEAR(dCALCPRDBGN), D_MONTH(dCALCPRDBGN), nTMP);
      if i < 12 then
        dCALCPRDBGN := add_months(dCALCPRDBGN, 1);
      else
        if i > 12 then
          dCALCPRDBGN2 := add_months(dCALCPRDBGN2, 1);
        end if;
        dCALCPRDBGN := dCALCPRDBGN2;
      end if;
      if i < 13 then
        nYEARSUM1 := nYEARSUM1 + nTMP;
      else
        nYEARSUM2 := nYEARSUM2 + nTMP;
      end if;
    end loop;
  
    nABSDAYS := 0;
    -- выплаты
    for cPAYS in (select SP.SUM, --
                         SP.RN,
                         SP.SLPAYGRND,
                         SP.MONTHFOR,
                         SP.YEARFOR,
                         SC.NAME,
                         row_number() over(order by SC.NAME, SP.YEARFOR, SP.MONTHFOR) nrow,
                         count(1) over() ncount
                    from SLPAYS SP, SLCOMPCHARGES SC
                   where SP.SLPAYSGRP = cGRP.RN
                     and SP.SLCOMPCHARGES = SC.RN
                     and ((dFORBEGIN is not null and (SP.YEARFOR > nYFORBGN or (SP.YEARFOR = nYFORBGN and SP.MONTHFOR >= nMFORBGN))) or dFORBEGIN is null)
                     and ((dFOREND is not null and (SP.YEARFOR < nYFOREND or (SP.YEARFOR = nYFOREND and SP.MONTHFOR <= nMFOREND))) or dFOREND is null)
                   order by SC.NAME, SP.YEARFOR, SP.MONTHFOR) loop
      /* начало больничного (из основания начисления) */
      dBEGIN_DATE := cGRP.dBGN;
      dEND_DATE   := cGRP.dEND;
    
      if nCOMMON = 0 then
        if cPAYS.MONTHFOR <> D_MONTH(dBEGIN_DATE) then
          dBEGIN_DATE := INT2DATE(1, cPAYS.MONTHFOR, cPAYS.YEARFOR);
        end if;
        if cPAYS.MONTHFOR <> D_MONTH(dEND_DATE) then
          dEND_DATE := last_day(dBEGIN_DATE);
        end if;
      end if;
    
      if (nCOMMON = 0) or (cPAYS.NROW = 1) then
      
        if iDETAIL_1IDX is not null /*nLINE = 3*/
         then
          iDETAIL_1IDX := PRSG_EXCEL.LINE_CONTINUE('Детали0');
          PRSG_EXCEL.LINE_PAGE_BREAK;
        else
          iDETAIL_1IDX := PRSG_EXCEL.LINE_APPEND('Детали0');
        end if;
        PRSG_EXCEL.CELL_VALUE_WRITE(CELL_SLP, 0, iDETAIL_1IDX, cPAYS.NAME);
        PRSG_EXCEL.CELL_VALUE_WRITE(CELL_FIO, 0, iDETAIL_1IDX, trim(cGRP.AGNFAMILYNAME) || ' ' || trim(cGRP.AGNFIRSTNAME) || ' ' || trim(cGRP.AGNLASTNAME));
        PRSG_EXCEL.CELL_VALUE_WRITE(CELL_PER, 0, iDETAIL_1IDX, 'с ' || to_char(dBEGIN_DATE, 'dd') || '.' || to_char(dBEGIN_DATE, 'mm') || '.' || D_YEAR(dBEGIN_DATE) || ' по ' || to_char(dEND_DATE, 'dd') || '.' || to_char(dEND_DATE, 'mm') || '.' || D_YEAR(dEND_DATE));
        iDETAIL_1IDX := PRSG_EXCEL.LINE_CONTINUE('Детали1А');
        PRSG_EXCEL.CELL_VALUE_WRITE('Заработок1', 0, iDETAIL_1IDX, 'Заработок за ' || to_char(odCALCPRDBGN, 'yyyy') || ' год');
        PRSG_EXCEL.CELL_VALUE_WRITE('Заработок2', 0, iDETAIL_1IDX, 'Заработок за ' || to_char(odCALCPRDBGN2, 'yyyy') || ' год');
        PRSG_EXCEL.CELL_VALUE_WRITE('Сумма1А', 0, iDETAIL_1IDX, nYEARSUM1);
        PRSG_EXCEL.CELL_VALUE_WRITE('Сумма1А', 0, iDETAIL_1IDX, nYEARSUM1);
        PRSG_EXCEL.CELL_VALUE_WRITE('Лимит1А', 0, iDETAIL_1IDX, nYEARSUMLIM1);
        PRSG_EXCEL.CELL_VALUE_WRITE('Сумма2А', 0, iDETAIL_1IDX, nYEARSUM2);
        PRSG_EXCEL.CELL_VALUE_WRITE('Лимит2А', 0, iDETAIL_1IDX, nYEARSUMLIM2);
        iDETAIL_1IDX := PRSG_EXCEL.LINE_CONTINUE('Детали1Б');
        if nDEKRET = 1 then
          PRSG_EXCEL.CELL_VALUE_WRITE('За_полный_месяцЗ', 0, iDETAIL_1IDX, 'Сумма за полный месяц');
        else
          PRSG_EXCEL.CELL_VALUE_WRITE('За_полный_месяцЗ', 0, iDETAIL_1IDX, 'Процент');
        end if;
        nDAYS := 0;
        nSUM  := 0;
      end if;
      iDETAIL_1IDX := PRSG_EXCEL.LINE_CONTINUE(DETAIL2);
      PRSG_EXCEL.CELL_VALUE_WRITE(CELL_PER1, 0, iDETAIL_1IDX, to_char(cPAYS.MONTHFOR, '00') || '/' || cPAYS.YEARFOR);
      PRSG_EXCEL.CELL_VALUE_WRITE(CELL_SUMZ, 0, iDETAIL_1IDX, nYEARSUMLIM1 + nYEARSUMLIM2);
      /* количество дней */
      PKG_SLPAYSPRM.GET(cPAYS.RN, 'WRK', nWRK, 0);
      PRSG_EXCEL.CELL_VALUE_WRITE('Дней', 0, iDETAIL_1IDX, nWRK);
      nDAYS := nDAYS + nWRK;
      /* процент */
      PKG_SLPAYSPRM.GET(cPAYS.RN, 'PRC', nPRC, 0);
      /* средний заработок расчетный */
      PKG_SLPAYSPRM.GET(cPAYS.RN, 'CALCAVGPAY', nTMP, 0);
      PRSG_EXCEL.CELL_VALUE_WRITE(CELL_SRZR, 0, iDETAIL_1IDX, nTMP);
      if nDEKRET = 1 then
        PRSG_EXCEL.CELL_VALUE_WRITE('За_полный_месяц', 0, iDETAIL_1IDX, nTMP * 30.4 * 0.4);
      else
        --PRSG_EXCEL.CELL_VALUE_WRITE('За_полный_месяц', 0, iDETAIL_1IDX, nTMP * nWRK);
        PRSG_EXCEL.CELL_VALUE_WRITE('За_полный_месяц', 0, iDETAIL_1IDX, nPRC);
      end if;
    
      /* найдем ограничение снизу: */
      if nDEKRET = 1 then
        PKG_SLPAYGRNDPRM.GET(cPAYS.SLPAYGRND, 'RELATIVE', sRELATIVE, '');
        find_salscale_code(0, 0, nCOMPANY, 'Минимальное пособие', nLIMITMINRULE);
        if (sRELATIVE is not null) and (nLIMITMINRULE is not null) then
          P_SALSCALE_BASE_GETVAL(nLIMITMINRULE, dBEGIN_DATE, F_AGNRELATIVE_CHILD_NUMB(nCOMPANY, cGRP.PERS_AGENT, sRELATIVE), nLIMITMIN);
        else
          nLIMITMIN := 0;
        end if;
      else
        PKG_SLPAYSPRM.GET(cPAYS.RN, 'LIMITAVG', nLIMITMIN, 0);
      end if;
      PRSG_EXCEL.CELL_VALUE_WRITE('Мин_ограничение', 0, iDETAIL_1IDX, nLIMITMIN);
      /* рассчитано */
      PKG_SLPAYSPRM.GET(cPAYS.RN, 'CALCSUM', nTMP, 0);
      /* Не более */
      PKG_SLPAYSPRM.GET(cPAYS.RN, 'LIMITMAX', nTMP, 0);
      PRSG_EXCEL.CELL_VALUE_WRITE(CELL_NBOL, 0, iDETAIL_1IDX, nTMP);
      /* Не менее */
      PKG_SLPAYSPRM.GET(cPAYS.RN, 'LIMITMIN', nTMP, 0);
      PRSG_EXCEL.CELL_VALUE_WRITE(CELL_NMEN, 0, iDETAIL_1IDX, nTMP);
      /* Дни невыхода */
      PKG_SLPAYSGRPPRM.GET(cGRP.Rn, 'ABSDAYS', nABSDAYS, 0);
      /* Сумма за целый месяц */
      if nWRK = 0 then
        nWRK := null;
      end if;
      nCALDAYS := last_day(to_date('01.' || to_char(cPAYS.Monthfor, '00') || '.' || to_char(cPAYS.Yearfor), 'dd.mm.yyyy')) - to_date('01.' || to_char(cPAYS.Monthfor, '00') || '.' || to_char(cPAYS.Yearfor), 'dd.mm.yyyy') + 1;
      --PRSG_EXCEL.CELL_VALUE_WRITE('За_полный_месяц', 0, iDETAIL_1IDX, ROUND(cPAYS.SUM * nCALDAYS / nWRK, 2));
      /* Сумма */
      PRSG_EXCEL.CELL_VALUE_WRITE(CELL_ITOG, 0, iDETAIL_1IDX, cPAYS.SUM);
      nSUM := nSUM + cPAYS.SUM;
    
      nCALCPRDDAYSQNT := (add_months(odCALCPRDBGN, 12) - odCALCPRDBGN) + (add_months(odCALCPRDBGN2, 12) - odCALCPRDBGN2);
      PRSG_EXCEL.CELL_VALUE_WRITE('Длительность', 0, iDETAIL_1IDX, PKG_EXT.IIF(nCALCPRDDAYSQNT - nABSDAYS < 0, 0, nCALCPRDDAYSQNT - nABSDAYS));
    
      if nABSDAYS <> 0 then
        iDETAIL_1IDX := PRSG_EXCEL.LINE_CONTINUE('Детали2А');
        nCOUNT       := 0;
        for cDNV in (select WD.WORKDATE, --
                            lag(WD.WORKDATE) over(partition by DT.NAME order by WD.WORKDATE, DT.NAME) PREVDATE,
                            DT.NAME,
                            WD.WORKDATE - lag(WD.WORKDATE) over(partition by DT.NAME order by WD.WORKDATE, DT.NAME) nDAYS,
                            row_number() over(order by WD.WORKDATE, DT.NAME) nROW,
                            count(1) over() nCOUNT
                       from CLNPSPFMWD WD, SLDAYSTYPE DT, CLNPSPFM PF, CLNPSPFMTYPES CT
                      where WD.DAYSTYPE = DT.RN
                        and DT.SHORT_CODE in ('Б', 'Р')
                        and to_char(WD.WORKDATE, 'yyyy') in (to_char(odCALCPRDBGN, 'yyyy'), to_char(odCALCPRDBGN2, 'yyyy'))
                        and WD.PRN = PF.RN
                        and PF.CLNPSPFMTYPES = CT.RN
                        and CT.IS_PRIMARY = 1
                        and PF.PERSRN = cGRP.CLNPERSONS
                      order by WD.WORKDATE, DT.NAME) loop
          if (cDNV.nDAYS is null) then
            dFIRSTDATE := cDNV.WORKDATE;
          end if;
          if (cDNV.nDAYS <> 1) or (cDNV.nROW = cDNV.nCOUNT) then
            iDETAIL_1IDX := PRSG_EXCEL.LINE_CONTINUE('Детали2Б');
            if (cDNV.nROW = cDNV.nCOUNT) then
              nCOUNT := nCOUNT + 1;
              PRSG_EXCEL.CELL_VALUE_WRITE('ДНВ1', 0, iDETAIL_1IDX, 'с ' || to_char(dFIRSTDATE, 'dd.mm.yyyy') || ' по ' || to_char(cDNV.Workdate, 'dd.mm.yyyy'));
            else
              PRSG_EXCEL.CELL_VALUE_WRITE('ДНВ1', 0, iDETAIL_1IDX, 'с ' || to_char(dFIRSTDATE, 'dd.mm.yyyy') || ' по ' || to_char(cDNV.PREVDATE, 'dd.mm.yyyy'));
            end if;
            PRSG_EXCEL.CELL_VALUE_WRITE('ДНВ2', 0, iDETAIL_1IDX, cDNV.Name);
            PRSG_EXCEL.CELL_VALUE_WRITE('ДНВ3', 0, iDETAIL_1IDX, nCOUNT);
            dFIRSTDATE := cDNV.WORKDATE;
            nCOUNT     := 0;
            if (cDNV.nROW = cDNV.nCOUNT) then
              iDETAIL_1IDX := PRSG_EXCEL.LINE_CONTINUE('Детали2Б');
              PRSG_EXCEL.CELL_VALUE_WRITE('ДНВ2', 0, iDETAIL_1IDX, 'Итого');
              PRSG_EXCEL.CELL_VALUE_WRITE('ДНВ3', 0, iDETAIL_1IDX, cDNV.nCOUNT);
            end if;
          end if;
          nCOUNT := nCOUNT + 1;
        end loop;
        iDETAIL_1IDX := PRSG_EXCEL.LINE_CONTINUE('Детали2В');
      end if;
    
      if (cPAYS.Nrow = cPAYS.Ncount) and (cPAYS.Ncount > 1) and (nCOMMON <> 0) then
        iDETAIL_1IDX := PRSG_EXCEL.LINE_CONTINUE(DETAIL2);
        PRSG_EXCEL.CELL_VALUE_WRITE(CELL_PER1, 0, iDETAIL_1IDX, 'Итого');
        PRSG_EXCEL.CELL_VALUE_WRITE('Дней', 0, iDETAIL_1IDX, nDAYS);
        PRSG_EXCEL.CELL_VALUE_WRITE(CELL_ITOG, 0, iDETAIL_1IDX, nSUM);
      end if;
    
      -- Выводим бухгалтера либо в коце общей справки, либо в конце каждой справки
      if (cPAYS.NROW = cPAYS.NCOUNT) or (nCOMMON = 0) then
        iDETAIL_1IDX := PRSG_EXCEL.LINE_CONTINUE('Детали4');
        PRSG_EXCEL.CELL_VALUE_WRITE('Должность', 0, iDETAIL_1IDX, sPOST);
        PRSG_EXCEL.CELL_VALUE_WRITE('ФИО2', 0, iDETAIL_1IDX, sFIO);
      end if;
    
    end loop;
  
  end loop;
  /* удаление */
  PRSG_EXCEL.LINE_DELETE('Детали0');
  PRSG_EXCEL.LINE_DELETE(DETAIL2);
  PRSG_EXCEL.LINE_DELETE('Детали4');
  PRSG_EXCEL.LINE_DELETE('Детали1А');
  PRSG_EXCEL.LINE_DELETE('Детали1Б');
  PRSG_EXCEL.LINE_DELETE('Детали2А');
  PRSG_EXCEL.LINE_DELETE('Детали2Б');
  PRSG_EXCEL.LINE_DELETE('Детали2В');
  if nDEKRET = 1 then
    PRSG_EXCEL.COLUMN_DELETE('БЛ1');
  else
    PRSG_EXCEL.COLUMN_DELETE('Уход1');
  end if;

  /* подтверждение использованного идентификатора процесса */
  PKG_TEMP.CONFIRM_USED_IDENT(nPROCESS);
end P_CLNPSPFM_BS2_2011_SPB;
/
