create or replace procedure PP_FOT_REPORT
-- Отчет по отработанному времени
(sCLNPSPFMTYPES in varchar2,
 dFROM          in date,
 dTILL          in date,
 nIDENT         in number --
 ) is
  cursor a(sCLNPSPFMTYPES in varchar2, dFROM in date, dTILL in date, nIDENT in number) is
    select pf.rn, --
           trim(pf.pref) || '-' || trim(pf.numb) sPERFNUMB,
           ag.agnfamilyname || ' ' || ag.agnfirstname || ' ' || ag.agnlastname sFIO,
           TP.HOURSNORM,
           TF.WORKEDHOURS,
           TF.nHOLIDAY_HRS,
           TF.nNIGHT_HRS,
           greatest(hs.do_act_from, dFROM) DO_ACT_FROM,
           least(nvl(hs.do_act_to, dTILL), dTILL) DO_ACT_TO
      from clnpspfm pf, --
           selectlist sel,
           clnpspfmhs hs,
           clnpersons cp,
           agnlist ag,
           clnpspfmtypes ct,
           (select HS.RN nPFMHSRN, --
                   sum(S.HOURSNORM /** HS.RATEACC*/) HOURSNORM
              from WORKDAYS   T, --
                   ENPERIOD   E,
                   CLNPSPFMHS HS,
                   WORKDAYSTR S
             where t.prn = e.rn
               and hs.schedule = e.schedule
               and (E.STARTDATE + T.DAYS - 1) between greatest(hs.do_act_from, dFROM) and least(nvl(hs.do_act_to, dTILL), dTILL)
               and S.PRN = T.RN
               and not exists (select null
                      from CLNPSPFMWD WT, SLDAYSTYPE WD
                     where WT.DAYSTYPE = WD.RN
                       and WT.PRN = HS.PRN
                       and WT.WORKDATE = (E.STARTDATE + T.DAYS - 1)
                       and WD.ABSENCE_SIGN = 1)
             group by HS.RN) TP,
           (select HS.RN, --
                   sum(H.WORKEDHOURS) - nvl(sum(decode(HT.CODE, 'Праздничные', H.WORKEDHOURS, 0)), 0) - nvl(sum(decode(HT.CODE, 'Ночные', H.WORKEDHOURS, 0)), 0) WORKEDHOURS,
                   sum(decode(HT.CODE, 'Праздничные', H.WORKEDHOURS, 0)) nHOLIDAY_HRS,
                   sum(decode(HT.CODE, 'Ночные', H.WORKEDHOURS, 0)) nNIGHT_HRS
              from CLNPSPFMWD     T, --
                   SLDAYSTYPE     D,
                   CLNPSPFMWH     H,
                   SL_HOURS_TYPES HT,
                   CLNPSPFMHS     HS
             where T.DAYSTYPE = D.RN(+)
               and T.PRN = HS.PRN
               and T.WORKDATE between HS.DO_ACT_FROM and nvl(HS.DO_ACT_TO, T.WORKDATE)
               and T.WORKDATE <= dTILL
               and (T.WORKDATE >= dFROM or T.WORKDATE is null)
               and H.PRN = T.RN
               and HT.RN = H.HOURSTYPE
             group by HS.RN) TF
     where hs.prn = pf.rn
       and hs.do_act_from <= dTILL
       and nvl(hs.do_act_to, dFROM) >= dFROM
       and cp.rn = pf.persrn
       and cp.pers_agent = ag.rn
       and ct.rn = pf.clnpspfmtypes
       and ';' || sCLNPSPFMTYPES || ';' like '%;' || ct.code || ';%'
       and TP.nPFMHSRN(+) = HS.RN
       and TF.RN(+) = HS.RN
       and pf.rn = sel.document
       and sel.ident = nIDENT
     order by sFIO, DO_ACT_FROM;
  i number;
begin
  prsg_excel.PREPARE;
  prsg_excel.SHEET_SELECT('Лист1');
  prsg_excel.LINE_DESCRIBE('Строка');
  prsg_excel.CELL_DESCRIBE('Период');
  prsg_excel.CELL_VALUE_WRITE('Период', 'за период с ' || to_char(dFROM, 'dd.mm.yyyy') || ' по ' || to_char(dTILL, 'dd.mm.yyyy'));
  for i in 1 .. 9 loop
    prsg_excel.LINE_CELL_DESCRIBE('Строка', 'Д' || i);
  end loop;
  for c in a(sCLNPSPFMTYPES, dFROM, dTILL, nIDENT) loop
    if i is null then
      i := prsg_excel.LINE_APPEND('Строка');
    else
      i := prsg_excel.LINE_CONTINUE('Строка');
    end if;
    prsg_excel.CELL_VALUE_WRITE('Д1', 0, i, i);
    prsg_excel.CELL_VALUE_WRITE('Д2', 0, i, c.sperfnumb);
    prsg_excel.CELL_VALUE_WRITE('Д3', 0, i, c.sfio);
    prsg_excel.CELL_VALUE_WRITE('Д4', 0, i, c.hoursnorm);
    prsg_excel.CELL_VALUE_WRITE('Д5', 0, i, c.workedhours);
    prsg_excel.CELL_VALUE_WRITE('Д6', 0, i, c.nholiday_hrs);
    prsg_excel.CELL_VALUE_WRITE('Д9', 0, i, c.nnight_hrs);
    prsg_excel.CELL_VALUE_WRITE('Д7', 0, i, to_char(c.do_act_from, 'dd.mm.yyyy'));
    prsg_excel.CELL_VALUE_WRITE('Д8', 0, i, to_char(c.do_act_to, 'dd.mm.yyyy'));
  end loop;
  prsg_excel.LINE_DELETE('Строка');
end PP_FOT_REPORT;
/
