create or replace procedure PP_0531702
-- �������� � �������� ��������� �������������
(nCOMPANY  in number,
 nIDENT    in number,
 dOPERDATE in date,
 sRUK      in varchar2,
 sRUKFIO   in varchar2,
 sFORM     in varchar2 default null,
 sNUMB     in varchar2 default null -- ����� ������ �� ���������������
 ) is
  i          number;
  k          number := 0;
  ntemp      number := null;
  pdOPERDATE date;
  psFORM     varchar2(7) := nvl(sFORM, '0531702');

  cursor a(nIDENT in number) is
    select a.rn,
           docname,
           ndoctype,
           ext_number,
           doc_date,
           begin_date,
           end_date,
           doc_sumtax,
           curcode,
           doc_sumtax_base,
           avans_sum,
           avans_percent,
           agnin,
           agnname,
           agnidnumb,
           reason_code,
           scountry,
           scountrycode,
           saddress,
           phone,
           agnacc,
           bankname,
           bankfcodeacc,
           bankcorracc,
           nzakaztype,
           szakaztype,
           reg_number,
           reg_date,
           sconfbo,
           sconfbonumb,
           dconfbodate,
           subject,
           duty_numb,
           duty_date,
           ubp_code,
           ft_code,
           ft_name,
           ls_num,
           dr_code,
           dr_name,
           fin_name,
           nsved,
           dsved
      from VP_0531702_M a, SELECTLIST S
     where a.rn = s.document
       and s.IDENT = nIDENT;

  cursor b(nPRN in number, dYEAR in date) is
    select prn, --
           seconclass,
           sexpstruct,
           subject,
           jan,
           feb,
           mar,
           apr,
           may,
           jun,
           jul,
           aug,
           sep,
           oct,
           nov,
           dec,
           all_summ
      from VP_0531702_S a
     where a.prn = nPRN
       and sYEAR = to_char(dYEAR, 'yyyy');

begin

  prsg_excel.PREPARE;
  -- ������ ��������:
  prsg_excel.SHEET_SELECT('���.1');
  prsg_excel.CELL_DESCRIBE('����');
  if psFORM = '0531702' then
    prsg_excel.CELL_DESCRIBE('�������������');
  elsif psFORM = '0531706' then
    prsg_excel.CELL_DESCRIBE('�����������');
  else
    p_exception(0, '�� ������� ����� ' || psFORM);
  end if;
  prsg_excel.CELL_DESCRIBE('�����');
  prsg_excel.CELL_DESCRIBE('�����');
  prsg_excel.CELL_DESCRIBE('�����');
  prsg_excel.CELL_DESCRIBE('����������');
  prsg_excel.CELL_DESCRIBE('������');
  prsg_excel.CELL_DESCRIBE('��');
  prsg_excel.CELL_DESCRIBE('����');
  prsg_excel.CELL_DESCRIBE('�������');
  prsg_excel.CELL_DESCRIBE('������');
  prsg_excel.CELL_DESCRIBE('��');
  prsg_excel.CELL_DESCRIBE('��');
  prsg_excel.CELL_DESCRIBE('����');
  for i in 1 .. 10 loop
    prsg_excel.CELL_DESCRIBE('�1_' || i);
  end loop;
  for i in 1 .. 12 loop
    prsg_excel.CELL_DESCRIBE('�2_' || i);
  end loop;
  for i in 1 .. 6 loop
    prsg_excel.CELL_DESCRIBE('�3_' || i);
    prsg_excel.CELL_DESCRIBE('�4_' || i);
  end loop;
  -- ������ ��������:
  prsg_excel.SHEET_SELECT('���.2');
  if psFORM = '0531702' then
    prsg_excel.CELL_DESCRIBE('��');
    prsg_excel.CELL_DESCRIBE('�������������2');
  elsif psFORM = '0531706' then
    prsg_excel.CELL_DESCRIBE('�����������2');
  end if;
  prsg_excel.CELL_DESCRIBE('�����2');
  prsg_excel.CELL_DESCRIBE('�����2');
  prsg_excel.CELL_DESCRIBE('�����2');
  prsg_excel.LINE_DESCRIBE('������');
  prsg_excel.LINE_DESCRIBE('������2');
  for i in 1 .. 23 loop
    if i <= 14 then
      prsg_excel.LINE_CELL_DESCRIBE('������', '�5_' || i);
    else
      prsg_excel.LINE_CELL_DESCRIBE('������2', '�5_' || i);
    end if;
  end loop;
  prsg_excel.LINE_CELL_DESCRIBE('������2', '�5_1_2');
  prsg_excel.CELL_DESCRIBE('������������');
  prsg_excel.CELL_DESCRIBE('���������������');
  prsg_excel.CELL_DESCRIBE('������������');
  prsg_excel.CELL_DESCRIBE('�����');
  prsg_excel.CELL_DESCRIBE('�����');
  prsg_excel.CELL_DESCRIBE('�����');
  -- ������� ������:
  for c in a(nIDENT) loop
    -- ��������� ���� "����� ��������":
    if c.nsved is null then
      c.nsved := FP_0531702_NUM(c.rn, dOPERDATE);
    end if;
    if psFORM = '0531702' then
      pdOPERDATE := nvl(c.dsved, dOPERDATE);
    else
      pdOPERDATE := dOPERDATE;
    end if;
    -- �������� �����:
    prsg_excel.SHEET_COPY('���.1', '��' || c.nsved || '_1');
    prsg_excel.SHEET_COPY('���.2', '��' || c.nsved || '_2');
    -- ������ ����:
    prsg_excel.SHEET_SELECT('��' || c.nsved || '_1');
    prsg_excel.CELL_VALUE_WRITE('����', to_char(pdOPERDATE, 'dd.mm.yyyy'));
    prsg_excel.CELL_VALUE_WRITE('�����', to_char(pdOPERDATE, 'dd'));
    prsg_excel.CELL_VALUE_WRITE('�����', lower(f_smonth_base(to_char(pdOPERDATE, 'mm'), 1)));
    prsg_excel.CELL_VALUE_WRITE('�����', to_char(pdOPERDATE, 'yy'));
    if psFORM = '0531702' then
      prsg_excel.CELL_VALUE_WRITE('�������������', c.nsved);
    elsif psFORM = '0531706' then
      prsg_excel.CELL_VALUE_WRITE('�����������', sNUMB);
    end if;
    -- ���� ��������� ��������� �� �������:
    if c.sconfbo is null and c.sconfbonumb is null and c.dconfbodate is null then
      c.sconfbo     := '����������� �����';
      c.sconfbonumb := '94-��';
      c.dconfbodate := to_date('21.07.2005', 'dd.mm.yyyy');
    end if;
    prsg_excel.CELL_VALUE_WRITE('����������', c.agnin);
    prsg_excel.CELL_VALUE_WRITE('�1_1', c.docname);
    prsg_excel.CELL_VALUE_WRITE('�1_2', c.ext_number);
    prsg_excel.CELL_VALUE_WRITE('�1_3', to_char(c.doc_date, 'dd.mm.yyyy'));
    prsg_excel.CELL_VALUE_WRITE('�1_4', to_char(c.begin_date, 'dd.mm.yyyy'));
    prsg_excel.CELL_VALUE_WRITE('�1_5', to_char(c.end_date, 'dd.mm.yyyy'));
    prsg_excel.CELL_VALUE_WRITE('�1_6', c.doc_sumtax);
    prsg_excel.CELL_VALUE_WRITE('�1_7', c.curcode);
    prsg_excel.CELL_VALUE_WRITE('�1_8', c.doc_sumtax_base);
    prsg_excel.CELL_VALUE_WRITE('�1_9', c.avans_percent);
    prsg_excel.CELL_VALUE_WRITE('�1_10', c.avans_sum);
    prsg_excel.CELL_VALUE_WRITE('�2_1', c.agnname);
    prsg_excel.CELL_VALUE_WRITE('�2_2', c.agnidnumb);
    prsg_excel.CELL_VALUE_WRITE('�2_3', c.reason_code);
    prsg_excel.CELL_VALUE_WRITE('�2_4', c.scountry);
    prsg_excel.CELL_VALUE_WRITE('�2_5', c.scountrycode);
    prsg_excel.CELL_VALUE_WRITE('�2_6', c.saddress);
    prsg_excel.CELL_VALUE_WRITE('�2_7', c.phone);
    prsg_excel.CELL_VALUE_WRITE('�2_8', '');
    prsg_excel.CELL_VALUE_WRITE('�2_9', c.agnacc);
    prsg_excel.CELL_VALUE_WRITE('�2_10', c.bankname);
    prsg_excel.CELL_VALUE_WRITE('�2_11', c.bankfcodeacc);
    prsg_excel.CELL_VALUE_WRITE('�2_12', c.bankcorracc);
    prsg_excel.CELL_VALUE_WRITE('�4_1', c.szakaztype);
    prsg_excel.CELL_VALUE_WRITE('�4_2', to_char(c.reg_date, 'dd.mm.yyyy'));
    prsg_excel.CELL_VALUE_WRITE('�4_3', c.sconfbo);
    prsg_excel.CELL_VALUE_WRITE('�4_4', c.sconfbonumb);
    prsg_excel.CELL_VALUE_WRITE('�4_5', to_char(c.dconfbodate, 'dd.mm.yyyy'));
    prsg_excel.CELL_VALUE_WRITE('�4_6', c.reg_number);
    -- ������ ����:
    prsg_excel.SHEET_SELECT('��' || c.nsved || '_2');
    prsg_excel.CELL_VALUE_WRITE('�����2', to_char(pdOPERDATE, 'dd'));
    prsg_excel.CELL_VALUE_WRITE('�����2', lower(f_smonth_base(to_char(pdOPERDATE, 'mm'), 1)));
    prsg_excel.CELL_VALUE_WRITE('�����2', to_char(pdOPERDATE, 'yy'));
    if psFORM = '0531702' then
      prsg_excel.CELL_VALUE_WRITE('�������������2', c.nsved);
    elsif psFORM = '0531706' then
      prsg_excel.CELL_VALUE_WRITE('�����������2', sNUMB);
    end if;
    k := 0;
    for cb in b(c.rn, pdOPERDATE) loop
      k := k + 1;
      i := prsg_excel.LINE_APPEND('������');
      prsg_excel.CELL_VALUE_WRITE('�5_1', 0, i, k);
      prsg_excel.CELL_VALUE_WRITE('�5_2', 0, i, '');
      prsg_excel.CELL_VALUE_WRITE('�5_3', 0, i, cb.sexpstruct || ' ' || cb.seconclass);
      prsg_excel.CELL_VALUE_WRITE('�5_4', 0, i, nvl(cb.subject, c.subject));
      prsg_excel.CELL_VALUE_WRITE('�5_5', 0, i, cb.jan);
      prsg_excel.CELL_VALUE_WRITE('�5_6', 0, i, cb.feb);
      prsg_excel.CELL_VALUE_WRITE('�5_7', 0, i, cb.mar);
      prsg_excel.CELL_VALUE_WRITE('�5_8', 0, i, cb.apr);
      prsg_excel.CELL_VALUE_WRITE('�5_9', 0, i, cb.may);
      prsg_excel.CELL_VALUE_WRITE('�5_10', 0, i, cb.jun);
      prsg_excel.CELL_VALUE_WRITE('�5_11', 0, i, cb.jul);
      prsg_excel.CELL_VALUE_WRITE('�5_12', 0, i, cb.aug);
      prsg_excel.CELL_VALUE_WRITE('�5_13', 0, i, cb.sep);
      prsg_excel.CELL_VALUE_WRITE('�5_14', 0, i, cb.oct);
      i := prsg_excel.LINE_APPEND('������2');
      prsg_excel.CELL_VALUE_WRITE('�5_1_2', 0, i, k);
      prsg_excel.CELL_VALUE_WRITE('�5_15', 0, i, cb.nov);
      prsg_excel.CELL_VALUE_WRITE('�5_16', 0, i, cb.dec);
      prsg_excel.CELL_VALUE_WRITE('�5_17', 0, i, cb.all_summ);
      prsg_excel.CELL_VALUE_WRITE('�5_18', 0, i, '0');
      prsg_excel.CELL_VALUE_WRITE('�5_19', 0, i, '0');
      prsg_excel.CELL_VALUE_WRITE('�5_20', 0, i, '0');
      prsg_excel.CELL_VALUE_WRITE('�5_21', 0, i, '0');
      prsg_excel.CELL_VALUE_WRITE('�5_22', 0, i, '0');
      prsg_excel.CELL_VALUE_WRITE('�5_23', 0, i, '0');
    end loop;
    prsg_excel.CELL_VALUE_WRITE('������������', sRUK);
    prsg_excel.CELL_VALUE_WRITE('���������������', sRUKFIO);
    if psFORM = '0531702' then
      prsg_excel.CELL_VALUE_WRITE('��', c.duty_numb);
      prsg_excel.CELL_VALUE_WRITE('�����', to_char(c.duty_date, 'dd'));
      prsg_excel.CELL_VALUE_WRITE('�����', lower(f_smonth_base(to_char(c.duty_date, 'mm'), 1)));
      prsg_excel.CELL_VALUE_WRITE('�����', to_char(c.duty_date, 'yy'));
    end if;
    prsg_excel.LINE_DELETE('������');
    prsg_excel.LINE_DELETE('������2');
    ntemp := 1; -- ���� ������ ������
  end loop;
  if ntemp is not null then
    prsg_excel.SHEET_DELETE('���.1');
    prsg_excel.SHEET_DELETE('���.2');
  end if;
end PP_0531702;
/
