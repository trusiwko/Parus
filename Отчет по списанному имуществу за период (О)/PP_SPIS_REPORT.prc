create or replace procedure PARUS.PP_SPIS_REPORT
-- ����� �� ���������� ��������� �� ������
(dFROM  in date, -- ������ �
 dTILL  in date, -- ������ ��
 bMODEL in number, -- �������� ������ � ������������ (����������)
 bNOTE  in number -- �������� �������������� � ������������ (����������)
 ) is

  iROW number;

  cursor cREC is
    select trim(i.inv_number) inv_number, --
           h.action_date,
           dtv.doccode vdoc_type,
           h.vdoc_numb,
           h.vdoc_date,
           dtf.doccode fdoc_type,
           h.fdoc_numb,
           h.fdoc_date,
           dn.nomen_name || --
           decode(bMODEL, 0, null, ' ' || i.object_model) || --
           decode(bNOTE, 0, null, ' ' || i.object_note) snomen
      from inventory i, invhist h, doctypes dtv, doctypes dtf, dicnomns dn
     where h.prn = i.rn
       and h.action_type = 4
       and dtv.rn(+) = h.vdoc_type
       and dtf.rn(+) = h.fdoc_type
       and dn.rn = i.nomenclature
       and h.action_date between nvl(dFROM, h.action_date) and nvl(dTILL, h.action_date)
     order by inv_number;

  procedure init is
  begin
    PRSG_EXCEL.PREPARE;
    PRSG_EXCEL.SHEET_SELECT('����1');
    PRSG_EXCEL.CELL_DESCRIBE('������');
    PRSG_EXCEL.LINE_DESCRIBE('������');
    for i in 1 .. 9 loop
      PRSG_EXCEL.LINE_CELL_DESCRIBE('������', '�' || i);
    end loop;
    PRSG_EXCEL.CELL_VALUE_WRITE('������', '�� ������ � ' || to_char(dFROM, 'dd.mm.yyyy') || ' �� ' || to_char(dTILL, 'dd.mm.yyyy') || ' �.');
  end;

  procedure fini is
  begin
    PRSG_EXCEL.LINE_DELETE('������');
  end;

begin

  init;

  for rREC in cREC loop
    if iROW is null then
      iROW := PRSG_EXCEL.LINE_APPEND('������');
    else
      iROW := PRSG_EXCEL.LINE_CONTINUE('������');
    end if;
    PRSG_EXCEL.CELL_VALUE_WRITE('�1', 0, iROW, rREC.Inv_Number);
    PRSG_EXCEL.CELL_VALUE_WRITE('�2', 0, iROW, to_char(rREC.action_date, 'dd.mm.yyyy'));
    PRSG_EXCEL.CELL_VALUE_WRITE('�3', 0, iROW, rREC.Snomen);
    PRSG_EXCEL.CELL_VALUE_WRITE('�4', 0, iROW, rREC.vdoc_type);
    PRSG_EXCEL.CELL_VALUE_WRITE('�5', 0, iROW, rREC.vdoc_numb);
    PRSG_EXCEL.CELL_VALUE_WRITE('�6', 0, iROW, to_char(rREC.vdoc_date, 'dd.mm.yyyy'));
    PRSG_EXCEL.CELL_VALUE_WRITE('�7', 0, iROW, rREC.fdoc_type);
    PRSG_EXCEL.CELL_VALUE_WRITE('�8', 0, iROW, rREC.fdoc_numb);
    PRSG_EXCEL.CELL_VALUE_WRITE('�9', 0, iROW, to_char(rREC.fdoc_date, 'dd.mm.yyyy'));
  end loop;

  fini;

end PP_SPIS_REPORT;
/
