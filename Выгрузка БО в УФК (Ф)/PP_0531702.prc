create or replace procedure PP_0531702
-- Сведения о принятом бюджетном обязательстве
(nCOMPANY  in number,
 nIDENT    in number,
 dOPERDATE in date,
 sRUK      in varchar2,
 sRUKFIO   in varchar2,
 sFORM     in varchar2 default null,
 sNUMB     in varchar2 default null -- Номер заявки на перерегистрацию
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
  -- Первая страница:
  prsg_excel.SHEET_SELECT('стр.1');
  prsg_excel.CELL_DESCRIBE('Дата');
  if psFORM = '0531702' then
    prsg_excel.CELL_DESCRIBE('СведенияНомер');
  elsif psFORM = '0531706' then
    prsg_excel.CELL_DESCRIBE('НомерЗаявки');
  else
    p_exception(0, 'Не найдена форма ' || psFORM);
  end if;
  prsg_excel.CELL_DESCRIBE('ДатаД');
  prsg_excel.CELL_DESCRIBE('ДатаМ');
  prsg_excel.CELL_DESCRIBE('ДатаГ');
  prsg_excel.CELL_DESCRIBE('Получатель');
  prsg_excel.CELL_DESCRIBE('Реестр');
  prsg_excel.CELL_DESCRIBE('ЛС');
  prsg_excel.CELL_DESCRIBE('ГРБС');
  prsg_excel.CELL_DESCRIBE('ГлаваБК');
  prsg_excel.CELL_DESCRIBE('Бюджет');
  prsg_excel.CELL_DESCRIBE('ФО');
  prsg_excel.CELL_DESCRIBE('ФК');
  prsg_excel.CELL_DESCRIBE('КОФК');
  for i in 1 .. 10 loop
    prsg_excel.CELL_DESCRIBE('Д1_' || i);
  end loop;
  for i in 1 .. 12 loop
    prsg_excel.CELL_DESCRIBE('Д2_' || i);
  end loop;
  for i in 1 .. 6 loop
    prsg_excel.CELL_DESCRIBE('Д3_' || i);
    prsg_excel.CELL_DESCRIBE('Д4_' || i);
  end loop;
  -- Вторая страница:
  prsg_excel.SHEET_SELECT('стр.2');
  if psFORM = '0531702' then
    prsg_excel.CELL_DESCRIBE('БО');
    prsg_excel.CELL_DESCRIBE('СведенияНомер2');
  elsif psFORM = '0531706' then
    prsg_excel.CELL_DESCRIBE('НомерЗаявки2');
  end if;
  prsg_excel.CELL_DESCRIBE('ДатаД2');
  prsg_excel.CELL_DESCRIBE('ДатаМ2');
  prsg_excel.CELL_DESCRIBE('ДатаГ2');
  prsg_excel.LINE_DESCRIBE('Строка');
  prsg_excel.LINE_DESCRIBE('Строка2');
  for i in 1 .. 23 loop
    if i <= 14 then
      prsg_excel.LINE_CELL_DESCRIBE('Строка', 'Д5_' || i);
    else
      prsg_excel.LINE_CELL_DESCRIBE('Строка2', 'Д5_' || i);
    end if;
  end loop;
  prsg_excel.LINE_CELL_DESCRIBE('Строка2', 'Д5_1_2');
  prsg_excel.CELL_DESCRIBE('Руководитель');
  prsg_excel.CELL_DESCRIBE('РуководительФИО');
  prsg_excel.CELL_DESCRIBE('ПримечаниеФК');
  prsg_excel.CELL_DESCRIBE('УчетД');
  prsg_excel.CELL_DESCRIBE('УчетМ');
  prsg_excel.CELL_DESCRIBE('УчетГ');
  -- Выводим данные:
  for c in a(nIDENT) loop
    -- Заполняем поле "Номер сведения":
    if c.nsved is null then
      c.nsved := FP_0531702_NUM(c.rn, dOPERDATE);
    end if;
    if psFORM = '0531702' then
      pdOPERDATE := nvl(c.dsved, dOPERDATE);
    else
      pdOPERDATE := dOPERDATE;
    end if;
    -- Копируем листы:
    prsg_excel.SHEET_COPY('стр.1', 'БО' || c.nsved || '_1');
    prsg_excel.SHEET_COPY('стр.2', 'БО' || c.nsved || '_2');
    -- Первый лист:
    prsg_excel.SHEET_SELECT('БО' || c.nsved || '_1');
    prsg_excel.CELL_VALUE_WRITE('Дата', to_char(pdOPERDATE, 'dd.mm.yyyy'));
    prsg_excel.CELL_VALUE_WRITE('ДатаД', to_char(pdOPERDATE, 'dd'));
    prsg_excel.CELL_VALUE_WRITE('ДатаМ', lower(f_smonth_base(to_char(pdOPERDATE, 'mm'), 1)));
    prsg_excel.CELL_VALUE_WRITE('ДатаГ', to_char(pdOPERDATE, 'yy'));
    if psFORM = '0531702' then
      prsg_excel.CELL_VALUE_WRITE('СведенияНомер', c.nsved);
    elsif psFORM = '0531706' then
      prsg_excel.CELL_VALUE_WRITE('НомерЗаявки', sNUMB);
    end if;
    -- Если реквизиты документа не указаны:
    if c.sconfbo is null and c.sconfbonumb is null and c.dconfbodate is null then
      c.sconfbo     := 'Федеральный закон';
      c.sconfbonumb := '94-ФЗ';
      c.dconfbodate := to_date('21.07.2005', 'dd.mm.yyyy');
    end if;
    prsg_excel.CELL_VALUE_WRITE('Получатель', c.agnin);
    prsg_excel.CELL_VALUE_WRITE('Д1_1', c.docname);
    prsg_excel.CELL_VALUE_WRITE('Д1_2', c.ext_number);
    prsg_excel.CELL_VALUE_WRITE('Д1_3', to_char(c.doc_date, 'dd.mm.yyyy'));
    prsg_excel.CELL_VALUE_WRITE('Д1_4', to_char(c.begin_date, 'dd.mm.yyyy'));
    prsg_excel.CELL_VALUE_WRITE('Д1_5', to_char(c.end_date, 'dd.mm.yyyy'));
    prsg_excel.CELL_VALUE_WRITE('Д1_6', c.doc_sumtax);
    prsg_excel.CELL_VALUE_WRITE('Д1_7', c.curcode);
    prsg_excel.CELL_VALUE_WRITE('Д1_8', c.doc_sumtax_base);
    prsg_excel.CELL_VALUE_WRITE('Д1_9', c.avans_percent);
    prsg_excel.CELL_VALUE_WRITE('Д1_10', c.avans_sum);
    prsg_excel.CELL_VALUE_WRITE('Д2_1', c.agnname);
    prsg_excel.CELL_VALUE_WRITE('Д2_2', c.agnidnumb);
    prsg_excel.CELL_VALUE_WRITE('Д2_3', c.reason_code);
    prsg_excel.CELL_VALUE_WRITE('Д2_4', c.scountry);
    prsg_excel.CELL_VALUE_WRITE('Д2_5', c.scountrycode);
    prsg_excel.CELL_VALUE_WRITE('Д2_6', c.saddress);
    prsg_excel.CELL_VALUE_WRITE('Д2_7', c.phone);
    prsg_excel.CELL_VALUE_WRITE('Д2_8', '');
    prsg_excel.CELL_VALUE_WRITE('Д2_9', c.agnacc);
    prsg_excel.CELL_VALUE_WRITE('Д2_10', c.bankname);
    prsg_excel.CELL_VALUE_WRITE('Д2_11', c.bankfcodeacc);
    prsg_excel.CELL_VALUE_WRITE('Д2_12', c.bankcorracc);
    prsg_excel.CELL_VALUE_WRITE('Д4_1', c.szakaztype);
    prsg_excel.CELL_VALUE_WRITE('Д4_2', to_char(c.reg_date, 'dd.mm.yyyy'));
    prsg_excel.CELL_VALUE_WRITE('Д4_3', c.sconfbo);
    prsg_excel.CELL_VALUE_WRITE('Д4_4', c.sconfbonumb);
    prsg_excel.CELL_VALUE_WRITE('Д4_5', to_char(c.dconfbodate, 'dd.mm.yyyy'));
    prsg_excel.CELL_VALUE_WRITE('Д4_6', c.reg_number);
    -- Второй лист:
    prsg_excel.SHEET_SELECT('БО' || c.nsved || '_2');
    prsg_excel.CELL_VALUE_WRITE('ДатаД2', to_char(pdOPERDATE, 'dd'));
    prsg_excel.CELL_VALUE_WRITE('ДатаМ2', lower(f_smonth_base(to_char(pdOPERDATE, 'mm'), 1)));
    prsg_excel.CELL_VALUE_WRITE('ДатаГ2', to_char(pdOPERDATE, 'yy'));
    if psFORM = '0531702' then
      prsg_excel.CELL_VALUE_WRITE('СведенияНомер2', c.nsved);
    elsif psFORM = '0531706' then
      prsg_excel.CELL_VALUE_WRITE('НомерЗаявки2', sNUMB);
    end if;
    k := 0;
    for cb in b(c.rn, pdOPERDATE) loop
      k := k + 1;
      i := prsg_excel.LINE_APPEND('Строка');
      prsg_excel.CELL_VALUE_WRITE('Д5_1', 0, i, k);
      prsg_excel.CELL_VALUE_WRITE('Д5_2', 0, i, '');
      prsg_excel.CELL_VALUE_WRITE('Д5_3', 0, i, cb.sexpstruct || ' ' || cb.seconclass);
      prsg_excel.CELL_VALUE_WRITE('Д5_4', 0, i, nvl(cb.subject, c.subject));
      prsg_excel.CELL_VALUE_WRITE('Д5_5', 0, i, cb.jan);
      prsg_excel.CELL_VALUE_WRITE('Д5_6', 0, i, cb.feb);
      prsg_excel.CELL_VALUE_WRITE('Д5_7', 0, i, cb.mar);
      prsg_excel.CELL_VALUE_WRITE('Д5_8', 0, i, cb.apr);
      prsg_excel.CELL_VALUE_WRITE('Д5_9', 0, i, cb.may);
      prsg_excel.CELL_VALUE_WRITE('Д5_10', 0, i, cb.jun);
      prsg_excel.CELL_VALUE_WRITE('Д5_11', 0, i, cb.jul);
      prsg_excel.CELL_VALUE_WRITE('Д5_12', 0, i, cb.aug);
      prsg_excel.CELL_VALUE_WRITE('Д5_13', 0, i, cb.sep);
      prsg_excel.CELL_VALUE_WRITE('Д5_14', 0, i, cb.oct);
      i := prsg_excel.LINE_APPEND('Строка2');
      prsg_excel.CELL_VALUE_WRITE('Д5_1_2', 0, i, k);
      prsg_excel.CELL_VALUE_WRITE('Д5_15', 0, i, cb.nov);
      prsg_excel.CELL_VALUE_WRITE('Д5_16', 0, i, cb.dec);
      prsg_excel.CELL_VALUE_WRITE('Д5_17', 0, i, cb.all_summ);
      prsg_excel.CELL_VALUE_WRITE('Д5_18', 0, i, '0');
      prsg_excel.CELL_VALUE_WRITE('Д5_19', 0, i, '0');
      prsg_excel.CELL_VALUE_WRITE('Д5_20', 0, i, '0');
      prsg_excel.CELL_VALUE_WRITE('Д5_21', 0, i, '0');
      prsg_excel.CELL_VALUE_WRITE('Д5_22', 0, i, '0');
      prsg_excel.CELL_VALUE_WRITE('Д5_23', 0, i, '0');
    end loop;
    prsg_excel.CELL_VALUE_WRITE('Руководитель', sRUK);
    prsg_excel.CELL_VALUE_WRITE('РуководительФИО', sRUKFIO);
    if psFORM = '0531702' then
      prsg_excel.CELL_VALUE_WRITE('БО', c.duty_numb);
      prsg_excel.CELL_VALUE_WRITE('УчетД', to_char(c.duty_date, 'dd'));
      prsg_excel.CELL_VALUE_WRITE('УчетМ', lower(f_smonth_base(to_char(c.duty_date, 'mm'), 1)));
      prsg_excel.CELL_VALUE_WRITE('УчетГ', to_char(c.duty_date, 'yy'));
    end if;
    prsg_excel.LINE_DELETE('Строка');
    prsg_excel.LINE_DELETE('Строка2');
    ntemp := 1; -- Флаг вывода данных
  end loop;
  if ntemp is not null then
    prsg_excel.SHEET_DELETE('стр.1');
    prsg_excel.SHEET_DELETE('стр.2');
  end if;
end PP_0531702;
/
