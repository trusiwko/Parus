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
           decode(ag.sex, 1, '����������', '���������') slead1,
           decode(ag.sex, 1, '', '�') slead2,
           nvl(trim(ag.agnfamilyname_to || ' ' || ag.agnfirstname_to || ' ' || ag.agnlastname_to), ag.agnfamilyname || ' ' || ag.agnfirstname || ' ' || ag.agnlastname) sFIO
      from agnlist ag, clnpersons cp
     where ag.rn = cp.pers_agent
       and cp.rn in (select document from selectlist where ident = nIDENT);

  cursor cPAYS(nPERS in number, nSLCOMPGR in number, nYEARFROM in number, nMONTHFROM in number, nYEARTO in number, nMONTHTO in number) is
    select f_smonth_base(s.month) || ' ' || s.year || ' �.' smonth, --
           sum(s.sum) nsumm,
           round(avg(sum(s.sum)) over(), 2) navg
      from slpays s, slcompcharges sl
     where s.clnpersons = nPERS
       and sl.rn = s.slcompcharges
       and s.year >= nYEARFROM
       and s.year <= nYEARTO
       and (s.month >= nMONTHFROM or s.year > nYEARFROM)
       and (s.month <= nMONTHTO or s.year < nYEARTO)
       and ( -- ���� ����� �� ������ �/�:
            sl.rn in (select grs.slcompcharges
                        from slcompgr gr, slcompgrstruct grs
                       where gr.rn = grs.prn
                         and gr.rn = nSLCOMPGR) or
           --, ���� ����� �� �����������, ���� ��� �� �������:
            (nSLCOMPGR is null and sl.confpay_sign = 0 and sl.compch_type = 10))
     group by s.month, s.year
     order by s.year, s.month;

  procedure init is
  begin
    prsg_excel.PREPARE;
    prsg_excel.SHEET_SELECT('����1');
    prsg_excel.LINE_DESCRIBE('������');
    for i in 1 .. 2 loop
      prsg_excel.LINE_CELL_DESCRIBE('������', '�' || i);
    end loop;
    prsg_excel.CELL_DESCRIBE('���');
    prsg_excel.CELL_DESCRIBE('�������');
    prsg_excel.CELL_DESCRIBE('�������������');
    prsg_excel.CELL_DESCRIBE('��1');
    prsg_excel.CELL_DESCRIBE('��2');
    prsg_excel.CELL_DESCRIBE('������');
    prsg_excel.CELL_DESCRIBE('���������1');
  end;

  procedure fini is
  begin
    prsg_excel.LINE_DELETE('������');
  end;

begin

  init;

  find_slcompgr_code(0, 1, nCOMPANY, sSLCOMPGR, nSLCOMPGR);

  if dFROM > dTO then
    p_exception(0, '�� ����� ������� ����.');
  end if;

  for rPERS in cPERS(nIDENT) loop
    nSHEET := nSHEET + 1;
    prsg_excel.SHEET_COPY('����1', '�' || nSHEET);
    prsg_excel.SHEET_SELECT('�' || nSHEET);
    prsg_excel.CELL_VALUE_WRITE('���', rPERS.Sfio);
    prsg_excel.CELL_VALUE_WRITE('��1', '������ ' || rPERS.Slead1);
    prsg_excel.CELL_VALUE_WRITE('��2', '�������' || rPERS.Slead2 || ', ��������' || rPERS.Slead2 || ' ������ �');
    prsg_excel.CELL_VALUE_WRITE('������',
                                '� ���, ��� ��' || rPERS.Slead2 || ' � ������ � ' || d_day(dFROM) || ' ' || lower(f_smonth_base(d_month(dFROM), 1)) || ' ' || d_year(dFROM) || ' �. �� ' || d_day(dTO) || ' ' || lower(f_smonth_base(d_month(dTO), 1)) || ' ' || d_year(dTO) || ' �.');
    sMonth := num2text(months_between(trunc(dTO, 'month'), trunc(dFROM, 'month')) + 1);
    prsg_excel.CELL_VALUE_WRITE('���������1', '� �� ��������� ' || sMonth || ' ������ �������������� ������ ����������, ����������� ���������� ����� ���������');
    iROW := null;
    for rPAYS in cPAYS(rPERS.Rn, nSLCOMPGR, d_year(dFROM), d_month(dFROM), d_year(dTO), d_month(dTO)) loop
      if iROW is null then
        iROW := prsg_excel.LINE_APPEND('������');
        prsg_excel.CELL_VALUE_WRITE('�������', rPAYS.Navg);
        p_money_sum_str(nCOMPANY, rPAYS.Navg, null, sAVG);
        prsg_excel.CELL_VALUE_WRITE('�������������', sAVG);
      else
        iROW := prsg_excel.LINE_CONTINUE('������');
      end if;
      prsg_excel.CELL_VALUE_WRITE('�1', 0, iROW, rPAYS.Smonth);
      prsg_excel.CELL_VALUE_WRITE('�2', 0, iROW, rPAYS.Nsumm);
    end loop;
    if iROW is not null then
      fini;
    end if;
  end loop;

  if nSHEET > 0 then
    prsg_excel.SHEET_DELETE('����1');
  end if;

end PP_SALARY_SPR;
/
