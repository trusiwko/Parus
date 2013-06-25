create or replace procedure PP_SBER_CARD_XML
-- Выгрузка заявок на открытие карт Сбербанк (XML)
-- Вызов: Обмен - Экспорт в файл
(nIDENT    in number, -- Идентификатор процесса
 sFILENAME in varchar2, -- Имя файла (sber.xml)
 dFORMDATE in date, -- ДатаФормирования
 sDOG_NUM  in varchar2, -- НомерДоговора
 sORGNAME  in varchar2, -- НаименованиеОрганизации
 sINN      in varchar2, -- ИНН
 sACCOUNT  in varchar2, -- РасчетныйСчетОрганизации
 sID       in varchar2, -- ИдПервичногоДокумента
 sOTDEL    in varchar2, -- Отделение банка
 sFILIAL   in varchar2, -- ФилиалОтделенияБанка
 nVIDVKL   in number, -- Доп.словарь "Тип карты Сбербанк"
 -- КодВидаВклада (50, 51, 52, 53, 54)
 -- КодПодвидаВклада (1, 2, 3, 4, 5):
 -- 50  2 Visa Classic (руб)
 -- 50  4 Visa Gold (руб)
 -- 51  3 Standard MasterCard (руб)
 -- 51  5 Gold MasterCard (руб)
 -- 53  1 Visa Electron (руб)
 -- 54  2 Maestro (руб)
 sCTG in varchar2 -- Категория населения
 -- 0 - индивидуальная;
 -- 207 - зарплатная;
 -- 217 - зарплатная с разрешенным овердрафтом для сотрудников предприятия.
 ) is
  sXML       CLOB;
  nCOUNT     number;
  psFILENAME varchar2(40) := sFILENAME;
  CR         varchar2(2) := chr(10);
  sVIDVKL    varchar2(2);
  sPODVID    varchar2(1);
  sLoadState varchar2(100);
begin
  if (psFILENAME is null) then
    psFILENAME := 'sber';
  end if;
  -- Добавим .xml
  if nvl(lower(pkg_txt_load.EXTRACT_FILE_EXT(psFILENAME)), '-1') <> 'xml' then
    psFILENAME := psFILENAME || '.xml';
  end if;
  sLoadState := psFILENAME || ' от ' || to_char(sysdate, 'dd.mm hh24:mi:ss');
  -- Формируем файл:
  sXML := '<?xml version="1.0" encoding="windows-1251"?>
<СчетаПК ДатаФормирования="' || to_char(dFORMDATE, 'yyyy-mm-dd') || '" НомерДоговора="' || sDOG_NUM || '" НаименованиеОрганизации="' || sORGNAME || '" ИНН="' || sINN || '" РасчетныйСчетОрганизации="' || sACCOUNT || '" ИдПервичногоДокумента="' || sID || '">' || CR;
  for c in (select *
              from (select a.*, --
                           count(1) over() ncount,
                           row_number() over(order by agnfamilyname, agnfirstname, agnlastname) nrow
                      from tp_sber_card_xml a, selectlist s
                     where a.rn = s.document
                       and s.ident = NIDENT
                     order by agnfamilyname, agnfirstname, agnlastname) a
             order by nrow) loop

      case nvl(c.card_type, nVIDVKL)
        when 1 then
          sVIDVKL := '50';
          sPODVID := '2';
        when 2 then
          sVIDVKL := '50';
          sPODVID := '4';
        when 3 then
          sVIDVKL := '51';
          sPODVID := '3';
        when 4 then
          sVIDVKL := '51';
          sPODVID := '5';
        when 5 then
          sVIDVKL := '53';
          sPODVID := '1';
        when 6 then
          sVIDVKL := '54';
          sPODVID := '2';
      end case;

    update tp_sber_card_xml t set t.loadstate = sLoadState || ' ('||c.nrow||')' where t.rn = c.rn;

    if length(c.emb_1 || c.emb_2) > 19 then
      p_exception(0, 'Сократите до 19 символов: ' || c.emb_1 || ' ' || c.emb_2);
    end if;
    if c.nrow = 1 then
      sXML := sXML || '  <ОткрытиеСчетов>' || CR;
    end if;

    sXML := sXML || '    <Сотрудник Нпп="' || trim(to_char(c.nrow)) || '">
      <Фамилия>' || c.agnfamilyname || '</Фамилия>
      <Имя>' || c.agnfirstname || '</Имя>
      <Отчество>' || c.agnlastname || '</Отчество>
      <ОтделениеБанка>' || sOTDEL || '</ОтделениеБанка>
      <ФилиалОтделенияБанка>' || to_char(sFILIAL) || '</ФилиалОтделенияБанка>
      <ВидВклада КодВидаВклада="' || sVIDVKL || '" КодПодвидаВклада="' || sPODVID || '" КодВалюты="810"></ВидВклада>
      <УдостоверениеЛичности>
        <ВидДокумента>Паспорт гражданина РФ</ВидДокумента>
        <Серия>' || c.docser || '</Серия>
        <Номер>' || c.docnumb || '</Номер>
        <ДатаВыдачи>' || c.docwhen || '</ДатаВыдачи>
        <КемВыдан>' || c.docwho || '</КемВыдан>
        <КодПодразделения>' || c.depart_code || '</КодПодразделения>
      </УдостоверениеЛичности>
      <ДатаРождения>' || c.agnburn || '</ДатаРождения>
      <Пол>' || c.ssex || '</Пол>' || CR;
    sXML := sXML || '      <АдресМестаРаботы>
        <Индекс>' || c.o1 || '</Индекс>
        <Регион>
          <РегионНазвание>' || c.o2 || '</РегионНазвание>
          <РегионСокращение>' || c.o3 || '</РегионСокращение>
        </Регион>
        <Район>
          <РайонНазвание>' || c.o4 || '</РайонНазвание>
          <РайонСокращение>' || c.o5 || '</РайонСокращение>
        </Район>
        <НаселенныйПункт>
          <НаселенныйПунктНазвание>' || c.o6 || '</НаселенныйПунктНазвание>
          <НаселенныйПунктСокращение>' || c.o7 || '</НаселенныйПунктСокращение>
        </НаселенныйПункт>
        <Улица>
          <УлицаНазвание>' || c.o8 || '</УлицаНазвание>
          <УлицаСокращение>' || c.o9 || '</УлицаСокращение>
        </Улица>
        <Дом>' || c.o10 || '</Дом>
        <Корпус>' || c.o11 || '</Корпус>
        <Квартира>' || c.o12 || '</Квартира>
      </АдресМестаРаботы>' || CR;
    sXML := sXML || '      <МестоРождения>' || c.addr_burn || '</МестоРождения>
      <АдресПрописки>
        <Индекс>' || c.a1 || '</Индекс>
        <Регион>
          <РегионНазвание>' || c.a2 || '</РегионНазвание>
          <РегионСокращение>' || c.a3 || '</РегионСокращение>
        </Регион>
        <Район>
          <РайонНазвание>' || c.a4 || '</РайонНазвание>
          <РайонСокращение>' || c.a5 || '</РайонСокращение>
        </Район>
        <НаселенныйПункт>
          <НаселенныйПунктНазвание>' || c.a6 || '</НаселенныйПунктНазвание>
          <НаселенныйПунктСокращение>' || c.a7 || '</НаселенныйПунктСокращение>
        </НаселенныйПункт>
        <Улица>
          <УлицаНазвание>' || c.a8 || '</УлицаНазвание>
          <УлицаСокращение>' || c.a9 || '</УлицаСокращение>
        </Улица>
        <Дом>' || c.a10 || '</Дом>
        <Корпус>' || c.a11 || '</Корпус>
        <Квартира>' || c.a12 || '</Квартира>
      </АдресПрописки>
      <ДомашнийТелефон>' || c.phone || '</ДомашнийТелефон>
      <ЭмбоссированныйТекст Поле1="' || c.emb_1 || '" Поле2="' || c.emb_2 || '" Поле3="' || c.emb_3 || '" />
      <КатегорияНаселения>' || sCTG || '</КатегорияНаселения>
      <КонтрольнаяИнформация>' || c.control || '</КонтрольнаяИнформация>
    </Сотрудник>' || CR;
    if c.nrow = c.ncount then
      sXML := sXML || '  </ОткрытиеСчетов>' || CR;
      sXML := sXML || '  <КонтрольныеСуммы>
    <КоличествоЗаписей>' || trim(to_char(c.ncount)) || '</КоличествоЗаписей>
  </КонтрольныеСуммы>
</СчетаПК>';
    end if;
  end loop;
  insert into FILE_BUFFER (IDENT, AUTHID, FILENAME, DATA) values (nIDENT, user, psFILENAME, sXML);
end PP_SBER_CARD_XML;
/
