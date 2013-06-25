create or replace procedure PP_0531702_BN
-- Сведения о принятом бюджетном обязательстве
( --
 nCOMPANY  in number, --
 nIDENT    in number,
 dOPERDATE in date,
 sRUK      in varchar2,
 sRUKFIO   in varchar2,
 nTYPE     in number, -- 0 - Сведения о БО, 1 - Заявка на изменение, 2 - Заявка на перерегистрацию
 sOUT      out varchar2 --
 ) is
  sFILEVER   varchar2(6) := '130101';
  sFILE_EXT  varchar2(2);
  nTEMP      number;
  nROW       number := 0;
  sFILENAME  varchar2(20);
  nNOM_LINE  number;
  pdOPERDATE date;
  bNEED      boolean;

  cursor a(nIDENT in number) is
    select a.*, --
           row_number() over(partition by a.ubp_code, a.agnin order by a.ubp_code, a.agnin, a.rn) nrow,
           count(1) over(partition by a.ubp_code, a.agnin) ncount,
           row_number() over(order by a.ubp_code, a.agnin, a.rn) nrow_all,
           count(1) over() ncount_all
      from (select a.rn,
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
                   dsved,
                   sdoc_stat_gk,
                   sdoc_stat_gk_full
              from VP_0531702_M A, SELECTLIST S
             where a.rn = s.document
               and s.ident = nIDENT
             order by a.ubp_code, a.agnin, A.RN) a;

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
      from VP_0531702_S
     where prn = nPRN
       and sYEAR = to_char(dYEAR, 'yyyy');

  -- Номер заявки на изменение (уникальный в пределах одного дня):
  function GetNomZI(nTYPE in number) return number is
    Result number;
  begin
    update TP_0531702_NOMZI t
       set t.nom_zi = t.nom_zi + 1 --
     where t.operdate = trunc(sysdate)
       and t.zitype = nTYPE returning nom_zi into Result;
    if sql%notfound then
      insert into TP_0531702_NOMZI (NOM_ZI, OPERDATE, ZITYPE) values (1, trunc(sysdate), nTYPE);
      Result := 1;
    end if;
    return Result;
  end;

  -- Номер файла:
  function GetNomFile return number is
    Result number;
  begin
    select SP_BONUM.NEXTVAL into Result from dual;
    return Result;
  end;

  procedure INCROW is
  begin
    nROW := nROW + 1;
  end;

begin
  if nTYPE = 0 then
    sFILE_EXT := 'BN';
  elsif nTYPE = 1 then
    sFILE_EXT := 'BC';
  elsif nTYPE = 2 then
    sFILE_EXT := 'BC';
  else
    p_exception(0, 'Не верный вид');
  end if;
  -- Выводим данные:
  for c in a(nIDENT) loop
    -- Заполняем поле "Номер сведения"
    if c.nsved is null then
      c.nsved := FP_0531702_NUM(c.rn, dOPERDATE);
    end if;
    pdOPERDATE := nvl(c.dsved, dOPERDATE);
    if nTYPE = 2 then
      -- Если заявка на перерегистрацию, то дату будем брать не сведения, а указанную в параметрах
      pdOPERDATE := dOPERDATE;
    end if;
    -- Если реквизиты документа не указаны:
    if c.sconfbo is null and c.sconfbonumb is null and c.dconfbodate is null then
      c.sconfbo     := 'Федеральный закон';
      c.sconfbonumb := '94-ФЗ';
      c.dconfbodate := to_date('21.07.2005', 'dd.mm.yyyy');
    end if;
    -- Запись в первый файл:
    if c.nrow = 1 then
      delete from TP_TXT t where t.authid = user;
      sFILENAME := c.ubp_code || --
                   DEC_TO_36S(to_number(to_char(sysdate, 'dd')), 0) || --
                   lpad(DEC_TO_36S(GetNomFile(), 0), 2, '0') || --
                   '.' || --
                   sFILE_EXT || --
                   DEC_TO_36S(to_number(to_char(sysdate, 'mm')), 0);
      /* FK */
      INCROW;
      PP_TXT_S(nIDENT, nROW, 1, 'TX' || sFILE_EXT || sFILEVER, true, 'NUM_VER');
      PP_TXT_S(nIDENT, nROW, 2, 'Парус', true, 'FORMER');
      PP_TXT_S(nIDENT, nROW, 3, '8.5.5', true, 'FORM_VER');
      PP_TXT_S(nIDENT, nROW, 4, null, false, 'NORM_DOC');
      PP_TXT_GROUP(nIDENT, nROW, 'FK');
      /* FROM */
      INCROW;
      PP_TXT_S(nIDENT, nROW, 1, '1', true, 'BUDG_LEVEL', 'Уровень бюджета', 1);
      PP_TXT_S(nIDENT, nROW, 2, c.ubp_code, true, 'KOD_UBP', 'Код УБП', 5);
      PP_TXT_S(nIDENT, nROW, 3, c.agnin, true, 'NAME_UBP', 'Наименование УБП', 2000);
      PP_TXT_GROUP(nIDENT, nROW, 'FROM');
      /* TO */
      INCROW;
      PP_TXT_S(nIDENT, nROW, 1, c.ft_code, true, 'KOD_TOFK', 'Код ОрФК', 4);
      PP_TXT_S(nIDENT, nROW, 2, c.ft_name, true, 'NAME_TOFK', 'Наименование ОрФК', 2000);
      PP_TXT_GROUP(nIDENT, nROW, 'TO');
    end if;
    /* BN или BC (: sFILE_EXT) */
    INCROW;
    PP_TXT_S(nIDENT, nROW, 1, '', false, 'GUID_FK', 'Глобальный уникальный идентификатор');
    if nTYPE = 0 then
      PP_TXT_S(nIDENT, nROW, 2, c.nsved, true, 'NOM_SV', 'Номер документа', 16);
    elsif nTYPE in (1, 2) then
      PP_TXT_S(nIDENT, nROW, 2, trim(to_char(nTYPE - 1)), true, 'DOC_TYPE', 'Тип заявки', 1);
      if nTYPE = 1 then
        -- Обязательно заполняется  для типа заявки "0" - "Заявка на внесение изменений в бюджетное обязательство".
        PP_TXT_S(nIDENT, nROW, 3, GetNomZI(nTYPE), true, 'NOM_ZI', 'Номер заявки на изменение БО', 15);
      else
        -- Не заполняется для типа заявки "1" - "Заявка на перерегистрацию бюджетного обязательства".
        PP_TXT_S(nIDENT, nROW, 3, '', false, 'NOM_ZI', 'Номер заявки на изменение БО', 15);
      end if;
      PP_TXT_S(nIDENT, nROW, 4, c.duty_numb, true, 'NOM_BO', 'Учетный номер БО', 16);
    end if;
    PP_TXT_D(nIDENT, nROW, 5, pdOPERDATE, true, 'DATE_OTCH', 'Дата составления');
    PP_TXT_S(nIDENT, nROW, 6, c.ubp_code, false, 'KOD_UBP_PBS', 'Код ПБС по Сводному реестру', 5, 5);
    PP_TXT_S(nIDENT, nROW, 7, c.agnin, true, 'NAME_UBP_PBS', 'Получатель бюджетных средств', 2000);
    PP_TXT_S(nIDENT, nROW, 8, c.ls_num, true, 'LS_NUM', 'Номер лицевого счета получателя', 11);
    PP_TXT_S(nIDENT, nROW, 9, c.dr_code, false, 'GLAVA_GRBS', 'Глава по БК', 3);
    PP_TXT_S(nIDENT, nROW, 10, c.dr_name, false, 'NAME_GRBS', 'Главный распорядитель бюджетных средств', 2000);
    PP_TXT_S(nIDENT, nROW, 11, 'Федеральный бюджет', true, 'NAME_BUD', 'Наименование бюджета', 512);
    PP_TXT_S(nIDENT, nROW, 12, c.fin_name, true, 'NAME_FO', 'Финансовый орган', 2000);
    PP_TXT_S(nIDENT, nROW, 13, c.ft_code, true, 'KOD_TOFK', 'Код ТОФК', 4);
    PP_TXT_S(nIDENT, nROW, 14, c.ft_name, true, 'NAME_TOFK', 'Наименование территориального органа Федерального казначейства', 2000);
    PP_TXT_S(nIDENT, nROW, 15, sRUK, false, 'DOL_RUK', 'Должность руководителя', 100);
    PP_TXT_S(nIDENT, nROW, 16, sRUKFIO, true, 'NAME_RUK', 'ФИО руководителя', 50);
    PP_TXT_D(nIDENT, nROW, 17, pdOPERDATE, true, 'DATE_POD', 'Дата подписания документа');
    if nTYPE = 0 then
      PP_TXT_S(nIDENT, nROW, 18, '', false, 'NOM_BO', 'Номер БО');
      PP_TXT_S(nIDENT, nROW, 19, '', false, 'DATE_FK', 'Дата постановки на учет');
    end if;
    PP_TXT_S(nIDENT, nROW, 20, '', false, 'NOTE_FK', 'Примечание');
    PP_TXT_S(nIDENT, nROW, 21, '', false, 'DOL_ISP', 'Должность исполнителя');
    PP_TXT_S(nIDENT, nROW, 22, '', false, 'NAME_ISP', 'ФИО исполнителя');
    PP_TXT_S(nIDENT, nROW, 23, '', false, 'TEL_ISP', 'Телефон исполнителя');
    PP_TXT_GROUP(nIDENT, nROW, sFILE_EXT);
    /* BNOSN или BCOSN (: sFILE_EXT || 'OSN')*/
    INCROW;
    -- Поле обязательно, если заполнено одно из полей BCOSN.SUM_S, BCOSN.SUM_R или BCOSN.SUM_PREPAY.
    bNEED := (nvl(c.doc_sumtax, 0) <> 0) or (nvl(c.doc_sumtax_base, 0) <> 0) or (nvl(c.avans_percent, 0) <> 0);
    PP_TXT_S(nIDENT, nROW, 1, c.ndoctype, bNEED, 'DOC_VID_OSN', 'Вид документа основания', 1);
    PP_TXT_S(nIDENT, nROW, 2, c.ext_number, bNEED, 'NOM_DOC', 'Номер документа основания', 45);
    PP_TXT_D(nIDENT, nROW, 3, c.doc_date, bNEED, 'DATE_DOC', 'Дата документа основания');
    PP_TXT_D(nIDENT, nROW, 4, c.begin_date, false, 'DATE_DOC_BEG', 'Дата начала действия  документа основания');
    PP_TXT_D(nIDENT, nROW, 5, c.end_date, bNEED, 'DATE_DOC_END', 'Дата окончания действия документа основания');
    PP_TXT_N(nIDENT, nROW, 6, c.doc_sumtax, bNEED, 'SUM_S', 'Сумма в валюте обязательства');
    PP_TXT_S(nIDENT, nROW, 7, c.curcode, bNEED, 'KOD_CUR', 'Код валюты по ОКВ', 3);
    PP_TXT_N(nIDENT, nROW, 8, c.doc_sumtax_base, false, 'SUM_R', 'Сумма в валюте Российской Федерации');
    PP_TXT_N(nIDENT, nROW, 9, c.avans_percent, false, 'PROC_PRERPAY', 'Авансовый платёж - процент от общей суммы обязательства');
    PP_TXT_N(nIDENT, nROW, 10, c.avans_sum, bNEED, 'SUM_PREPAY', 'Сумма авансового платежа');
    PP_TXT_GROUP(nIDENT, nROW, sFILE_EXT || 'OSN');
    /* BNCONTR или BCCONTR */
    INCROW;
    PP_TXT_S(nIDENT, nROW, 1, c.agnname, true, 'NAME_CONTR', 'Наименование/фамилия, имя, отчество', 2000);
    PP_TXT_S(nIDENT, nROW, 2, c.agnidnumb, false, 'INN', 'ИНН', 12);
    PP_TXT_S(nIDENT, nROW, 3, c.reason_code, false, 'KPP', 'КПП', 9, 9);
    PP_TXT_S(nIDENT, nROW, 4, c.scountry, true, 'COUNTRY', 'Юридический адрес (место регистрации) - наименование страны', 80);
    PP_TXT_S(nIDENT, nROW, 5, c.scountrycode, true, 'OKSM', 'Юридический адрес (место регистрации) - код страны по ОКСМ', 3);
    PP_TXT_S(nIDENT, nROW, 6, c.saddress, true, 'ADDRESS', 'Юридический адрес (место регистрации) - адрес', 360);
    PP_TXT_S(nIDENT, nROW, 7, c.phone, false, 'TEL', 'Телефон (факс)', 50);
    PP_TXT_S(nIDENT, nROW, 8, '', false, 'STATUS', 'Код статуса', 1);
    PP_TXT_S(nIDENT, nROW, 9, c.agnacc, true, 'BS_R_SCH', 'Номер банковского счета', 20);
    PP_TXT_S(nIDENT, nROW, 10, c.bankname, true, 'NAME_BIC', 'Наименование банка', 160);
    PP_TXT_S(nIDENT, nROW, 11, c.bankfcodeacc, true, 'BIC', 'БИК банка', 9);
    PP_TXT_S(nIDENT, nROW, 12, c.bankcorracc, false, 'BS_K_SCH', 'Корреспондентский счет банка', 20);
    PP_TXT_GROUP(nIDENT, nROW, sFILE_EXT || 'CONTR');
    /* BNIDOC или BCIDOC */
    -- Пропущу пока
    /* BNEXREQ или BCEXREQ */
    if c.ndoctype = 1 then
      INCROW;
      PP_TXT_S(nIDENT, nROW, 1, c.nzakaztype, true, 'ORDER_VID', 'Способ размещения заказа', 2);
      PP_TXT_D(nIDENT, nROW, 2, c.reg_date, false, 'DATE_ITOG', 'Дата подведения итогов конкурса, аукциона, запроса котировок');
      PP_TXT_S(nIDENT, nROW, 3, c.sconfbo, true, 'DOC_VID_GK', 'Вид документа, подтверждающего основание заключения контракта', 160);
      PP_TXT_S(nIDENT, nROW, 4, c.sconfbonumb, true, 'NOM_DOC_GK', 'Номер документа, подтверждающего основание заключения контракта', 254);
      PP_TXT_D(nIDENT, nROW, 5, c.dconfbodate, true, 'DATE_DOC_GK', 'Дата документа, подтверждающего основание заключения контракта');
      if nTYPE = 1 then
        -- Может заполняться  для типа заявки "0" - "Заявка на внесение изменений в бюджетное обязательство".
        PP_TXT_S(nIDENT, nROW, 6, c.sdoc_stat_gk, false, 'DOC_STAT_GK', 'Статус исполнения контракта');
      elsif nTYPE = 2 then
        --Не заполняется для типа заявки "1" - "Заявка на перерегистрацию бюджетного обязательства".
        PP_TXT_S(nIDENT, nROW, 6, '', false, 'DOC_STAT_GK', 'Статус исполнения контракта');
      end if;
      if c.nzakaztype <= 6 then
        PP_TXT_S(nIDENT, nROW, 7, c.reg_number, true, 'NOM_REGISTER', 'Номер реестровой записи в реестре госконтрактов', 19);
      else
        PP_TXT_S(nIDENT, nROW, 7, c.reg_number, true, 'NOM_REGISTER', 'Номер реестровой записи в реестре госконтрактов', 13);
      end if;
      PP_TXT_GROUP(nIDENT, nROW, sFILE_EXT || 'EXREQ');
    end if;
    /* BNDESCR или BCDESCR */
    -- Раздел 5. Расшифровка обязательства
    nNOM_LINE := 0;
    for cb in b(c.rn, pdOPERDATE) loop
      INCROW;
      nNOM_LINE := nNOM_LINE + 1;
      PP_TXT_S(nIDENT, nROW, 1, nNOM_LINE, true, 'NOM_LINE', 'Номер п/п');
      PP_TXT_S(nIDENT, nROW, 2, 1, true, 'SR_FIN', 'Вид средств для исполнения обязательства', 1);
      if nTYPE = 0 then
        PP_TXT_S(nIDENT, nROW, 3, cb.sexpstruct || cb.seconclass, true, 'KBK', 'Код по БК', 20, 20);
        PP_TXT_S(nIDENT, nROW, 4, '10', true, 'TYPE_KBK', 'Тип КБК', 2);
      elsif nTYPE in (1, 2) then
        PP_TXT_S(nIDENT, nROW, 4, cb.sexpstruct || cb.seconclass, true, 'KBK', 'Код по БК', 20, 20);
        PP_TXT_S(nIDENT, nROW, 3, '10', true, 'TYPE_KBK', 'Тип КБК', 2);
      end if;
      PP_TXT_S(nIDENT, nROW, 6, nvl(cb.subject, c.subject), false, 'SUBJ', 'Предмет по документу-основанию', 1000);
      PP_TXT_N(nIDENT, nROW, 7, cb.jan, false, 'SUM_JAN', 'Сумма на январь');
      PP_TXT_N(nIDENT, nROW, 8, cb.feb, false, 'SUM_FEB', 'Сумма на февраль');
      PP_TXT_N(nIDENT, nROW, 9, cb.mar, false, 'SUM_MAR');
      PP_TXT_N(nIDENT, nROW, 10, cb.apr, false, 'SUM_APR');
      PP_TXT_N(nIDENT, nROW, 11, cb.may, false, 'SUM_MAY');
      PP_TXT_N(nIDENT, nROW, 12, cb.jun, false, 'SUM_JUN');
      PP_TXT_N(nIDENT, nROW, 13, cb.jul, false, 'SUM_JUL');
      PP_TXT_N(nIDENT, nROW, 14, cb.aug, false, 'SUM_AUG');
      PP_TXT_N(nIDENT, nROW, 15, cb.sep, false, 'SUM_SEP');
      PP_TXT_N(nIDENT, nROW, 16, cb.oct, false, 'SUM_OCT');
      PP_TXT_N(nIDENT, nROW, 17, cb.nov, false, 'SUM_NOV');
      PP_TXT_N(nIDENT, nROW, 18, cb.dec, false, 'SUM_DEC', 'Сумма на декабрь');
      PP_TXT_N(nIDENT, nROW, 19, cb.all_summ, true, 'SUM_YEAR', 'Сумма на текущий финансовый год');
      PP_TXT_N(nIDENT, nROW, 20, null, false, 'SUM_1_YEAR', 'Сумма на первый год');
      PP_TXT_N(nIDENT, nROW, 21, null, false, 'SUM_2_YEAR', 'Сумма на второй год');
      PP_TXT_N(nIDENT, nROW, 22, null, false, 'SUM_3_YEAR', 'Сумма на третий год после текущего');
      PP_TXT_N(nIDENT, nROW, 23, null, false, 'SUM_4_YEAR', 'Сумма на четвертый год после текущего');
      PP_TXT_N(nIDENT, nROW, 24, null, false, 'SUM_5_YEAR', 'Сумма на пятый год после текущего');
      PP_TXT_S(nIDENT, nROW, 25, null, false, 'NOTE', 'Примечание', 254);
      if nTYPE = 0 then
        PP_TXT_S(nIDENT, nROW, 26, null /*c.seconclass*/, false, 'ADD_KLASS', 'Код цели субсидии/субвенции', 20);
      elsif nTYPE in (1, 2) then
        PP_TXT_S(nIDENT, nROW, 5, null /*c.seconclass*/, false, 'ADD_KLASS', 'Код цели субсидии/субвенции', 20);
      end if;
      PP_TXT_GROUP(nIDENT, nROW, sFILE_EXT || 'DESCR');
    end loop;
    -- Вывод в этот файл завершен:
    if c.nrow = c.ncount then
      PP_TXT_FILE(nIDENT, sFILENAME);
      if sOUT is null then
        sOUT := sFILENAME;
      else
        sOUT := sOUT || ', ' || sFILENAME;
      end if;
      pkg_docs_props_vals.MODIFY('БО выгружено в файл', 'Contracts', c.rn, sFILENAME, null, null, ntemp);
    end if;
  end loop;
  sOUT := 'Выгрузка завершена: ' || sOUT;
end PP_0531702_BN;
/
