create or replace procedure PP_OB_IK
-- Инвентарная карточка по оборотке
(nIDENT in number) is
  cursor a(nIDENT in number) is
    select AG.AGNFAMILYNAME || ' ' || AG.AGNFIRSTNAME || ' ' || AG.AGNLASTNAME sAGNNAME, --
           DN.NOMEN_NAME,
           DN.NOMEN_CODE,
           DA.ACC_NUMBER,
           V.DATE_TO,
           V.ACNT_RES_QUANT,
           V.ACNT_RES_SUM,
           V.ACNT_RES_SUM / V.ACNT_RES_QUANT ACNT_RES_PRICE
      from VALTURNS   V, --
           AGNLIST    AG,
           DICNOMNS   DN,
           DICACCS    DA,
           SELECTLIST S
     where V.RN = S.DOCUMENT
       and S.IDENT = nIDENT
       and AG.RN = V.AGENT
       and DN.RN = V.NOMENCLATURE
       and DA.RN = V.ACCOUNT
       and V.ACNT_RES_QUANT <> 0
     order by NOMEN_NAME;

  r1 number;
  r2 number;
  n number;

  --
  procedure excel_init is
  begin
    prsg_excel.PREPARE;
    prsg_excel.SHEET_SELECT('ИК группового учета ОС');
    prsg_excel.CELL_DESCRIBE('День');
    prsg_excel.CELL_DESCRIBE('Месяц');
    prsg_excel.CELL_DESCRIBE('Год');
    prsg_excel.CELL_DESCRIBE('Дата');
    prsg_excel.CELL_DESCRIBE('Наименование');
    prsg_excel.CELL_DESCRIBE('МОЛ');
    prsg_excel.CELL_DESCRIBE('Счет');
    prsg_excel.LINE_DESCRIBE('Строка1');
    prsg_excel.LINE_DESCRIBE('Строка2');
    prsg_excel.LINE_CELL_DESCRIBE('Строка1', 'НачальнаяСтоимостьЕд');
    prsg_excel.LINE_CELL_DESCRIBE('Строка2', 'ИнвНомер');
    prsg_excel.LINE_CELL_DESCRIBE('Строка2', 'ПоступилоКолич');
    prsg_excel.LINE_CELL_DESCRIBE('Строка2', 'ПоступилоСумма');
  end;
  --
  procedure excel_fini is
  begin
    prsg_excel.LINE_DELETE('Строка1');
    prsg_excel.LINE_DELETE('Строка2');
  end;
begin
  excel_init;
  for c in a(nIDENT) loop
    r1 := prsg_excel.LINE_APPEND('Строка1');
    r2 := prsg_excel.LINE_APPEND('Строка2');
    if n is null then
      prsg_excel.CELL_VALUE_WRITE('Наименование', c.nomen_name);
      prsg_excel.CELL_VALUE_WRITE('МОЛ', c.sagnname);
      prsg_excel.CELL_VALUE_WRITE('Счет', c.acc_number);
      prsg_excel.CELL_VALUE_WRITE('Дата', to_char(c.date_to, 'dd.mm.yyyy'));
      prsg_excel.CELL_VALUE_WRITE('День', to_char(c.date_to, 'dd'));
      prsg_excel.CELL_VALUE_WRITE('Месяц', lower(f_smonth_base(to_char(c.date_to, 'mm'), 1)));
      prsg_excel.CELL_VALUE_WRITE('Год', to_char(c.date_to, 'yyyy'));
      n := 1;
    end if;
    prsg_excel.CELL_VALUE_WRITE('НачальнаяСтоимостьЕд', 0, r1, c.acnt_res_price);
    prsg_excel.CELL_VALUE_WRITE('ИнвНомер', 0, r2, c.nomen_code);
    prsg_excel.CELL_VALUE_WRITE('ПоступилоКолич', 0, r2, c.acnt_res_quant);
    prsg_excel.CELL_VALUE_WRITE('ПоступилоСумма', 0, r2, c.acnt_res_sum);
  end loop;
  excel_fini;
end PP_OB_IK;
/
