create or replace procedure PP_SALARY_SPR
--
(nIDENT    in number,
 nCOMPANY  in number,
 dFROM     in date,
 dTO       in date, --
 sSLCOMPGR in varchar2) is

  nSHEET    number := 0;
  iROW      number;
  nSLCOMPGR PKG_STD.tREF;
  sAVG      varchar2(2000);
  sMonth    varchar2(20);

  cursor cPERS(nIDENT in number) is
    select cp.rn, --
           decode(ag.sex, 1, 'гражданину', 'гражданке') slead1,
           decode(ag.sex, 1, '', 'а') slead2,
           nvl(trim(ag.agnfamilyname_to || ' ' || ag.agnfirstname_to || ' ' || ag.agnlastname_to), ag.agnfamilyname || ' ' || ag.agnfirstname || ' ' || ag.agnlastname) sFIO
      from agnlist ag, clnpersons cp
     where ag.rn = cp.pers_agent
       and cp.rn in (select document from selectlist where ident = nIDENT);

  cursor cPAYS(nPERS in number, nSLCOMPGR in number, nYEARFROM in number, nMONTHFROM in number, nYEARTO in number, nMONTHTO in number) is
    select f_smonth_base(s.month) || ' ' || s.year || ' г.' smonth, --
           sum(s.sum) nsumm,
           round(avg(sum(s.sum)) over(), 2) navg
      from slpays s, slcompcharges sl
     where s.clnpersons = nPERS
       and sl.rn = s.slcompcharges
       and s.year >= nYEARFROM
       and s.year <= nYEARTO
       and (s.month >= nMONTHFROM or s.year > nYEARFROM)
       and (s.month <= nMONTHTO or s.year < nYEARTO)
       and ( -- Либо отбор по группе в/у:
            sl.rn in (select grs.slcompcharges
                        from slcompgr gr, slcompgrstruct grs
                       where gr.rn = grs.prn
                         and gr.rn = nSLCOMPGR) or
           --, либо отбор по начислениям, если она не указана:
            (nSLCOMPGR is null and sl.confpay_sign = 0 and sl.compch_type = 10))
     group by s.month, s.year
     order by s.year, s.month;

  procedure init is
  begin
    prsg_excel.PREPARE;
    prsg_excel.SHEET_SELECT('Лист1');
    prsg_excel.LINE_DESCRIBE('Строка');
    for i in 1 .. 2 loop
      prsg_excel.LINE_CELL_DESCRIBE('Строка', 'Д' || i);
    end loop;
    prsg_excel.CELL_DESCRIBE('ФИО');
    prsg_excel.CELL_DESCRIBE('Средний');
    prsg_excel.CELL_DESCRIBE('СреднийСтрока');
    prsg_excel.CELL_DESCRIBE('ОК1');
    prsg_excel.CELL_DESCRIBE('ОК2');
    prsg_excel.CELL_DESCRIBE('Период');
    prsg_excel.CELL_DESCRIBE('Заголовок1');
  end;

  procedure fini is
  begin
    prsg_excel.LINE_DELETE('Строка');
  end;

begin

  init;

  find_slcompgr_code(0, 1, nCOMPANY, sSLCOMPGR, nSLCOMPGR);

  if dFROM > dTO then
    p_exception(0, 'Не верно указаны даты.');
  end if;

  for rPERS in cPERS(nIDENT) loop
    nSHEET := nSHEET + 1;
    prsg_excel.SHEET_COPY('Лист1', 'Л' || nSHEET);
    prsg_excel.SHEET_SELECT('Л' || nSHEET);
    prsg_excel.CELL_VALUE_WRITE('ФИО', rPERS.Sfio);
    prsg_excel.CELL_VALUE_WRITE('ОК1', 'Выдана ' || rPERS.Slead1);
    prsg_excel.CELL_VALUE_WRITE('ОК2', 'работал' || rPERS.Slead2 || ', проходил' || rPERS.Slead2 || ' службу в');
    prsg_excel.CELL_VALUE_WRITE('Период',
                                'в том, что он' || rPERS.Slead2 || ' в период с ' || d_day(dFROM) || ' ' || lower(f_smonth_base(d_month(dFROM), 1)) || ' ' || d_year(dFROM) || ' г. по ' || d_day(dTO) || ' ' || lower(f_smonth_base(d_month(dTO), 1)) || ' ' || d_year(dTO) || ' г.');
    sMonth := num2text(months_between(trunc(dTO, 'month'), trunc(dFROM, 'month')) + 1);
    prsg_excel.CELL_VALUE_WRITE('Заголовок1', 'и за последние ' || sMonth || ' месяца предшествующих месяцу увольнения, начисленная заработная плата составила');
    iROW := null;
    for rPAYS in cPAYS(rPERS.Rn, nSLCOMPGR, d_year(dFROM), d_month(dFROM), d_year(dTO), d_month(dTO)) loop
      if iROW is null then
        iROW := prsg_excel.LINE_APPEND('Строка');
        prsg_excel.CELL_VALUE_WRITE('Средний', rPAYS.Navg);
        p_money_sum_str(nCOMPANY, rPAYS.Navg, null, sAVG);
        prsg_excel.CELL_VALUE_WRITE('СреднийСтрока', sAVG);
      else
        iROW := prsg_excel.LINE_CONTINUE('Строка');
      end if;
      prsg_excel.CELL_VALUE_WRITE('Д1', 0, iROW, rPAYS.Smonth);
      prsg_excel.CELL_VALUE_WRITE('Д2', 0, iROW, rPAYS.Nsumm);
    end loop;
    if iROW is not null then
      fini;
    end if;
  end loop;

  if nSHEET > 0 then
    prsg_excel.SHEET_DELETE('Лист1');
  end if;

end PP_SALARY_SPR;
/
