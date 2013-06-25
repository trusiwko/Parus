create or replace procedure P_UDO_CHESSKA_1
--
(nCOMPANY      in number,
 nIDENT        in number,
 dPERIOD_BEGIN in date,
 dPERIOD_END   in date,
 sGROUP        in varchar2,
 sSLCOMP       in varchar2, -- выплаты и удержания отмеченные
 nTYPE         in number, --1 начисления, 2 удержания, 3 отчисления, 0 ничего
 nFLAG_IDENT   in number,
 nHIDECONF     in number -- Скрывать конфеденциальные выплаты
 ) is
  SHEET_FORM constant PKG_STD.tSTRING := 'Шахматка';
  iSPEC   integer := 0;
  lastnum number := 0;
  LINE_SPEC       constant PKG_STD.tSTRING := 'SPEC';
  CELL_FIO        constant PKG_STD.tSTRING := 'ФИО';
  CELL_ITOGOSUMMA constant PKG_STD.tSTRING := 'ИтогоСумма';

  CELL_SUMMA constant PKG_STD.tSTRING := 'Сумма';

  iCOL integer := 0;
  COLUMN_COL    constant PKG_STD.tSTRING := 'COL';
  CELL_ITOG     constant PKG_STD.tSTRING := 'Итог';
  CELL_NUMBGRAF constant PKG_STD.tSTRING := 'НомГраф';
  CELL_COMP     constant PKG_STD.tSTRING := 'Начисление';

  CELL_ITHD  constant PKG_STD.tSTRING := 'ИтЗаг';
  CELL_ITGR  constant PKG_STD.tSTRING := 'ИтогГраф';
  CELL_VSEGO constant PKG_STD.tSTRING := 'Всего';
  CELL_HEAD  constant PKG_STD.tSTRING := 'Заголовок';
  CELL_USL   constant PKG_STD.tSTRING := 'Условия';

  nSUMM number := 0;
  sHEAD varchar2(160);
begin

  if dPERIOD_BEGIN > dPERIOD_END then
    p_exception(0, 'Дата "по" ' || to_char(dPERIOD_END, 'dd.mm.yyyy') || '" больше даты "c" "' || to_char(dPERIOD_BEGIN, 'dd.mm.yyyy'));
  end if;

  if nTYPE not in (1, 2, 3, 0) then
    p_exception(0, 'Тип выплат отличен от 1, 2, 3 или 0');
  end if;

  PRSG_EXCEL.PREPARE;
  PRSG_EXCEL.SHEET_SELECT(SHEET_FORM);

  PRSG_EXCEL.CELL_DESCRIBE(CELL_ITGR);
  PRSG_EXCEL.CELL_DESCRIBE(CELL_VSEGO);
  PRSG_EXCEL.CELL_DESCRIBE(CELL_HEAD);
  PRSG_EXCEL.CELL_DESCRIBE(CELL_USL);
  PRSG_EXCEL.CELL_DESCRIBE(CELL_ITHD);

  PRSG_EXCEL.LINE_DESCRIBE(LINE_SPEC);
  PRSG_EXCEL.LINE_CELL_DESCRIBE(LINE_SPEC, 'Время');
  PRSG_EXCEL.LINE_CELL_DESCRIBE(LINE_SPEC, 'Норма');
  PRSG_EXCEL.LINE_CELL_DESCRIBE(LINE_SPEC, CELL_FIO);
  PRSG_EXCEL.LINE_CELL_DESCRIBE(LINE_SPEC, CELL_SUMMA);
  PRSG_EXCEL.LINE_CELL_DESCRIBE(LINE_SPEC, CELL_ITOGOSUMMA);

  PRSG_EXCEL.COLUMN_DESCRIBE(COLUMN_COL);
  PRSG_EXCEL.COLUMN_CELL_DESCRIBE(COLUMN_COL, CELL_SUMMA);
  PRSG_EXCEL.COLUMN_CELL_DESCRIBE(COLUMN_COL, CELL_ITOG);
  PRSG_EXCEL.COLUMN_CELL_DESCRIBE(COLUMN_COL, CELL_NUMBGRAF);
  PRSG_EXCEL.COLUMN_CELL_DESCRIBE(COLUMN_COL, CELL_COMP);

  for i in (select SL.SUMM, --
                   CM.CODE,
                   CM.RW CMRW,
                   FM.AGNNAME,
                   FM.RW FMRW,
                   row_number() over(partition by CM.RW order by FM.RW) FLAG,
                   sum(SL.SUMM) over(partition by CM.RW) CMSUMM,
                   sum(SL.SUMM) over(partition by FM.RW) FMSUMM,
                   WW.WORKEDHOURS,
                   WW.HOURSNORM
              from (select SL.SLCOMPCHARGES, SL.CLNPSPFM, sum(SL.SUM) SUMM
                      from SLPAYS SL, SLCOMPCHARGES CM, SLCOMPGR G, SLCOMPGRSTRUCT GS
                     where DECODE(GS.FORMULA, '+@', to_date('01.' || trim(to_char(SL.MONTHFOR, '00')) || '.' || SL.YEARFOR, 'dd.mm.yyyy'), to_date('01.' || trim(to_char(SL.MONTH, '00')) || '.' || SL.YEAR, 'dd.mm.yyyy')) between dPERIOD_BEGIN and dPERIOD_END
                       and SL.CLNPSPFM in (select DOCUMENT
                                             from SELECTLIST
                                            where IDENT = nIDENT
                                              and nFLAG_IDENT = 1
                                           union all
                                           select SL.CLNPSPFM from dual where nFLAG_IDENT = 0)
                       and SL.SLCOMPCHARGES = CM.RN
                       and (to_date('01.' || trim(to_char(SL.MONTH, '00')) || '.' || SL.YEAR, 'dd.mm.yyyy') between dPERIOD_BEGIN and dPERIOD_END or to_date('01.' || trim(to_char(SL.MONTHFOR, '00')) || '.' || SL.YEARFOR, 'dd.mm.yyyy') between dPERIOD_BEGIN and dPERIOD_END)
                       and (CM.Confpay_Sign = 0 or nHIDECONF = 0)
                       and CM.COMPCH_TYPE = DECODE(nTYPE, 1, 10, DECODE(nTYPE, 2, 30, DECODE(nTYPE, 3, 50, CM.COMPCH_TYPE)))
                       and G.RN = GS.PRN
                       and (sGROUP is null or G.CODE = sGROUP)
                       and (sSLCOMP is null or instr(';' || sSLCOMP || ';', ';' || cm.code || ';') > 0)
                       and GS.SLCOMPCHARGES = SL.SLCOMPCHARGES
                     group by SL.SLCOMPCHARGES, SL.CLNPSPFM) SL,
                   (select CM.*, row_number() over(partition by null order by CM.NUMB) RW
                      from (select distinct CM.RN, CM.CODE, CM.NUMB
                              from SLPAYS SL, SLCOMPCHARGES CM, SLCOMPGR G, SLCOMPGRSTRUCT GS
                             where CM.COMPANY = nCOMPANY
                               and (to_date('01.' || trim(to_char(SL.MONTH, '00')) || '.' || SL.YEAR, 'dd.mm.yyyy') between dPERIOD_BEGIN and dPERIOD_END or to_date('01.' || trim(to_char(SL.MONTHFOR, '00')) || '.' || SL.YEARFOR, 'dd.mm.yyyy') between dPERIOD_BEGIN and dPERIOD_END)
                               and SL.CLNPSPFM in (select DOCUMENT
                                                     from SELECTLIST
                                                    where IDENT = nIDENT
                                                      and nFLAG_IDENT = 1
                                                   union all
                                                   select SL.CLNPSPFM from dual where nFLAG_IDENT = 0)
                               and (CM.Confpay_Sign = 0 or nHIDECONF = 0)
                               and SL.SLCOMPCHARGES = CM.RN
                               and CM.COMPCH_TYPE = DECODE(nTYPE, 1, 10, DECODE(1, 2, 30, DECODE(nTYPE, 3, 50, CM.COMPCH_TYPE)))
                               and G.RN = GS.PRN
                               and (sGROUP is null or G.CODE = sGROUP)
                               and (sSLCOMP is null or instr(';' || sSLCOMP || ';', ';' || cm.code || ';') > 0)
                               and GS.SLCOMPCHARGES = SL.SLCOMPCHARGES
                             order by NUMB) CM) CM,
                   (select FM.*, row_number() over(partition by null order by FM.AGNNAME) RW
                      from (select distinct F.RN, AG.AGNNAME
                              from SLPAYS SL, CLNPSPFM F, CLNPERSONS P, AGNLIST AG, SLCOMPCHARGES CM, SLCOMPGR G, SLCOMPGRSTRUCT GS --, SLCALCULAT CL
                             where SL.CLNPSPFM = F.RN
                               and P.PERS_AGENT = AG.RN
                               and F.PERSRN = P.RN
                               and (CM.Confpay_Sign = 0 or nHIDECONF = 0)
                               and (to_date('01.' || trim(to_char(SL.MONTH, '00')) || '.' || SL.YEAR, 'dd.mm.yyyy') between dPERIOD_BEGIN and dPERIOD_END or to_date('01.' || trim(to_char(SL.MONTHFOR, '00')) || '.' || SL.YEARFOR, 'dd.mm.yyyy') between dPERIOD_BEGIN and dPERIOD_END)
                               and F.RN in (select DOCUMENT
                                              from SELECTLIST
                                             where IDENT = nIDENT
                                               and nFLAG_IDENT = 1
                                            union all
                                            select F.RN from dual where nFLAG_IDENT = 0)
                               and SL.SLCOMPCHARGES = CM.RN
                               and CM.COMPCH_TYPE = DECODE(nTYPE, 1, 10, DECODE(nTYPE, 2, 30, DECODE(nTYPE, 3, 50, CM.COMPCH_TYPE)))
                               and G.RN = GS.PRN
                               and (sGROUP is null or G.CODE = sGROUP)
                               and (sSLCOMP is null or instr(';' || sSLCOMP || ';', ';' || cm.code || ';') > 0)
                               and GS.SLCOMPCHARGES = SL.SLCOMPCHARGES) FM) FM,
                   (select a.prn, sum(b.WORKEDHOURS) WORKEDHOURS, sum(c.HOURSNORM) HOURSNORM
                      from (select t.prn, t.schedule
                              from clnpspfmhs t
                             where t.do_act_from <= dPERIOD_END
                               and (t.do_act_to >= dPERIOD_BEGIN or t.do_act_to is null)) a,
                           (select WD.PRN nCLNPFPFM, count(WH.WORKEDHOURS) WORKEDHOURS
                              from CLNPSPFMWD WD, CLNPSPFMWH WH
                             where WD.WORKDATE between dPERIOD_BEGIN and dPERIOD_END
                               and WD.DAYSTYPE is null
                               and WH.PRN = WD.RN
                               and WH.WORKEDHOURS > 0
                             group by WD.PRN) b,
                           (select count(cc.HOURSNORM) HOURSNORM, cc.prn
                              from (select tt.prn,
                                           WS.HOURSNORM,
                                           case
                                             when tt.do_act_from < dPERIOD_BEGIN then
                                              dPERIOD_BEGIN
                                             else
                                              tt.do_act_from
                                           end dFROMDATE,
                                           case
                                             when tt.do_act_to > dPERIOD_END or tt.do_act_to is null then
                                              dPERIOD_END
                                             else
                                              tt.do_act_to
                                           end DTODATE,
                                           EP.STARTDATE + S.DAYS - 1 DDATE
                                      from WORKDAYS S, ENPERIOD EP, WORKDAYSTR WS, clnpspfmhs tt
                                     where S.PRN = EP.RN
                                       and WS.PRN = S.RN
                                          --and EP.STARTDATE + S.DAYS - 1 between dPERIOD_BEGIN and dPERIOD_END
                                       and WS.HOURSNORM > 0
                                       and tt.do_act_from <= dPERIOD_END
                                       and (tt.do_act_to >= dPERIOD_BEGIN or tt.do_act_to is null)
                                       and tt.schedule = ep.schedule) cc
                             where cc.DDATE between cc.dFROMDATE and cc.DTODATE
                             group by cc.prn) c
                     where a.prn = b.nCLNPFPFM(+)
                       and a.prn = c.prn(+)
                     group by a.prn) WW
             where SL.SLCOMPCHARGES = CM.RN
               and SL.CLNPSPFM = FM.RN
               and WW.PRN(+) = FM.RN
             order by 5) loop
  
    if i.flag = 1 then
      --добавляем колонку
      loop
        exit when i.cmrw <= iCOL;
        iCOL := PRSG_EXCEL.COLUMN_APPEND(COLUMN_COL);
      end loop;
      PRSG_EXCEL.CELL_VALUE_WRITE(CELL_COMP, i.cmrw, 0, i.code);
      PRSG_EXCEL.CELL_VALUE_WRITE(CELL_NUMBGRAF, i.cmrw, 0, i.cmrw + 1);
      PRSG_EXCEL.CELL_VALUE_WRITE(CELL_ITOG, i.cmrw, 0, i.cmsumm);
      nSUMM := nSUMM + i.cmsumm;
    end if;
  
    if i.fmrw > lastnum then
      --добавляем строку
      lastnum := i.fmrw;
      iSPEC   := PRSG_EXCEL.LINE_APPEND(LINE_SPEC);
      PRSG_EXCEL.CELL_VALUE_WRITE(CELL_FIO, 0, iSPEC /*i.fmrw*/, i.agnname);
      PRSG_EXCEL.CELL_VALUE_WRITE('Норма', 0, iSPEC /*i.fmrw*/, i.HOURSNORM);
      PRSG_EXCEL.CELL_VALUE_WRITE('Время', 0, iSPEC /*i.fmrw*/, i.WORKEDHOURS);
      PRSG_EXCEL.CELL_VALUE_WRITE(CELL_ITOGOSUMMA, 0, iSPEC /*i.fmrw*/, i.fmsumm);
    end if;
  
    PRSG_EXCEL.CELL_VALUE_WRITE(CELL_SUMMA, i.cmrw, iSPEC /*i.fmrw*/, i.summ);
  
  end loop;
  PRSG_EXCEL.LINE_DELETE(LINE_SPEC);
  PRSG_EXCEL.COLUMN_DELETE(COLUMN_COL);

  PRSG_EXCEL.CELL_VALUE_WRITE(CELL_VSEGO, nSUMM);

  case nTYPE
    when 1 then
      sHEAD := 'начилениям';
    when 2 then
      sHEAD := 'удержаниям';
    when 3 then
      sHEAD := 'отчислениям';
    else
      sHEAD := 'всем выплатам и удержаниям';
  end case;

  PRSG_EXCEL.CELL_VALUE_WRITE(CELL_ITHD, 'Итого Гр.2-' || to_char(iCOL + 1));
  PRSG_EXCEL.CELL_VALUE_WRITE(CELL_ITGR, iCOL + 2);
  PRSG_EXCEL.CELL_VALUE_WRITE(CELL_HEAD, 'Шахматная ведомость по ' || sHEAD);
  PRSG_EXCEL.CELL_VALUE_WRITE(CELL_USL, 'за период с ' || f_smonth_base(to_char(dPERIOD_BEGIN, 'mm'), 1) || to_char(dPERIOD_BEGIN, ' yyyy') || 'г. по ' || f_smonth_base(to_char(dPERIOD_END, 'mm'), 0) || to_char(dPERIOD_BEGIN, ' yyyy') || 'г.');

end P_UDO_CHESSKA_1;
/
