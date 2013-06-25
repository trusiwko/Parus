create or replace procedure PARUS.PP_SPIS_REPORT
-- Отчет по списанному имуществу за период
(dFROM  in date, -- Период с
 dTILL  in date, -- Период по
 bMODEL in number, -- Выводить модель в наименование (логический)
 bNOTE  in number -- Выводить характеристику в наименование (логический)
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
    PRSG_EXCEL.SHEET_SELECT('Лист1');
    PRSG_EXCEL.CELL_DESCRIBE('Период');
    PRSG_EXCEL.LINE_DESCRIBE('Строка');
    for i in 1 .. 9 loop
      PRSG_EXCEL.LINE_CELL_DESCRIBE('Строка', 'Д' || i);
    end loop;
    PRSG_EXCEL.CELL_VALUE_WRITE('Период', 'за период с ' || to_char(dFROM, 'dd.mm.yyyy') || ' по ' || to_char(dTILL, 'dd.mm.yyyy') || ' г.');
  end;

  procedure fini is
  begin
    PRSG_EXCEL.LINE_DELETE('Строка');
  end;

begin

  init;

  for rREC in cREC loop
    if iROW is null then
      iROW := PRSG_EXCEL.LINE_APPEND('Строка');
    else
      iROW := PRSG_EXCEL.LINE_CONTINUE('Строка');
    end if;
    PRSG_EXCEL.CELL_VALUE_WRITE('Д1', 0, iROW, rREC.Inv_Number);
    PRSG_EXCEL.CELL_VALUE_WRITE('Д2', 0, iROW, to_char(rREC.action_date, 'dd.mm.yyyy'));
    PRSG_EXCEL.CELL_VALUE_WRITE('Д3', 0, iROW, rREC.Snomen);
    PRSG_EXCEL.CELL_VALUE_WRITE('Д4', 0, iROW, rREC.vdoc_type);
    PRSG_EXCEL.CELL_VALUE_WRITE('Д5', 0, iROW, rREC.vdoc_numb);
    PRSG_EXCEL.CELL_VALUE_WRITE('Д6', 0, iROW, to_char(rREC.vdoc_date, 'dd.mm.yyyy'));
    PRSG_EXCEL.CELL_VALUE_WRITE('Д7', 0, iROW, rREC.fdoc_type);
    PRSG_EXCEL.CELL_VALUE_WRITE('Д8', 0, iROW, rREC.fdoc_numb);
    PRSG_EXCEL.CELL_VALUE_WRITE('Д9', 0, iROW, to_char(rREC.fdoc_date, 'dd.mm.yyyy'));
  end loop;

  fini;

end PP_SPIS_REPORT;
/
