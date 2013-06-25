create or replace procedure P_UDO_IMPORT_SAUMI_XML
(
  nIDENT            in number,          -- сотрудники
  nCOMPANY          in number,          -- организация
  dDATE             in date,            -- Дата отчета
  nREGIM            in number           -- Режим (1 - трансорт, 2 - ОС < 100 000, 3 - ОС > 100 000
)
as
   /* данные о работодателе */
   
   cCLOB                  clob default null;
   cTEMP                  varchar2(4000) default null;
   cTEMP1                 varchar2(4000) default null;
   cTEMP3                 varchar2(4000) default null; 
   sFileName              varchar2(35);
   sDef                   VARCHAR2 (1);
   v_act_date             DATE;
   v_min_date             DATE;
   v_new_a_cost_begin     NUMBER;
   v_new_a_amort_during   NUMBER;
   v_new_a_amort_begin    NUMBER; 
   v_act_type             NUMBER;
   v_fdoc_numb            VARCHAR2(20);
   v_fdoc_date            DATE;
   nKOl                   integer := 1;

 PROCEDURE report_to_buff
   IS
   BEGIN
      INSERT INTO FILE_BUFFER (IDENT, AUTHID,FILENAME, DATA)
        VALUES   (nIDENT, user, sFileNAME, cCLOB);
   END;


begin

sFileNAME := 'test.xml';

/* создаем новый буфер */
dbms_lob.createtemporary(cCLOB, true);

 cTEMP := '<?xml version="1.0" encoding="utf-8"?>'|| CHR (13)||
 '<objects xmlns="http://mio.samregion.ru/datacollector"'||CHR (13)||
          'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">';
 dbms_lob.writeappend(cCLOB, length(cTEMP), cTEMP);

   for rec IN (SELECT * FROM (
      SELECT --+ordered
                replace(t3.code, ' ', '') AS sokof,
                LTRIM (t2.OBJECT_GROUP) scard_pref_trim,
                LTRIM (t2.OBJECT_NUMBER) scard_numb_trim,
                LTRIM (t2.inv_number) invno,
                T5.NOMEN_NAME snom_name,
                t2.item_count,
                1 as count_real,
                t2.income_date,
                t2.rn,
                DECODE (SUBSTR (T4.ACC_NUMBER, 18, 1), '1', '1', '0') is_budget
         FROM   selectlist t1,
                INVENTORY t2,
                okof t3,
                DICACCS t4,
                DICNOMNS t5
        WHERE       t1.ident = NIDENT
                AND T1.DOCUMENT = t2.RN
                AND t2.okof = t3.rn
                AND T2.ACCOUNT = t4.rn(+)
                AND T2.NOMENCLATURE = T5.RN
                AND t2.item_count = 1
               union all
        SELECT --+ordered
                replace(t3.code, ' ', '') AS sokof,
                LTRIM (t2.OBJECT_GROUP) scard_pref_trim,
                LTRIM (t2.OBJECT_NUMBER)||'-'||LTRIM(t6.group_number) scard_numb_trim,
                LTRIM (t2.inv_number) invno,
                T5.NOMEN_NAME snom_name,
                count (1) over (partition by t6.prn) as item_count,
                t6.item_count count_real,
                t6.in_date as income_date,
                t2.rn,
                DECODE (SUBSTR (T4.ACC_NUMBER, 18, 1), '1', '1', '0') is_budget
         FROM   selectlist t1,
                INVENTORY t2,
                okof t3,
                DICACCS t4,
                DICNOMNS t5,
                INVPACK t6
        WHERE       t1.ident = NIDENT
                AND T1.DOCUMENT = t2.RN
                AND t2.okof = t3.rn
                AND T2.ACCOUNT = t4.rn(+)
                AND T2.NOMENCLATURE = T5.RN
                AND t2.item_count > 1
                AND (T6.OUT_DATE IS NULL OR T6.OUT_DATE > dDATE) 
                AND t6.prn = t2.rn)
     ORDER BY   invno)    
   LOOP


   --Пошли по истории карточки
    BEGIN
         SELECT   MAX (ACTION_DATE) ACT_DATE,
                  MIN (ACTION_DATE) MIN_DATE,                 
                  MAX (NEW_A_COST_BEGIN)
                     KEEP (DENSE_RANK LAST ORDER BY ACTION_DATE)
                     NEW_A_COST_BEGIN,
                  MAX (NEW_A_AMORT_DURING)
                     KEEP (DENSE_RANK LAST ORDER BY ACTION_DATE)
                     NEW_A_AMORT_DURINGN,
                 MAX (NEW_A_AMORT_BEGIN)
                     KEEP (DENSE_RANK LAST ORDER BY ACTION_DATE)
                     NEW_A_AMORT_BEGIN,                                              
                  MAX (ACTION_TYPE)
                     KEEP (DENSE_RANK LAST ORDER BY ACTION_DATE)
                     ACTION_TYPE
           INTO   v_act_date,
                  v_min_date,
                  v_new_a_cost_begin,
                  v_new_a_amort_during,
                  v_new_a_amort_begin,
                  v_act_type
           FROM   INVHIST
          WHERE   PRN =rec.RN AND ACTION_DATE <= dDate;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            p_exception (
               0,
                  'Нет операций по карточке до даты '
               || TO_CHAR (ddate, 'dd.mm.yyyy')
               || '! Инвентарный номер :'
               || NVL (rec.scard_pref_trim, '')
               || sDef
               || NVL (rec.scard_numb_trim, '')
            );
      END;

     -- А теперь прробуем отловить операция Према к учету и вытащить оттуда документ-основание
     BEGIN
       SELECT  VDOC_NUMB, VDOC_DATE
         INTO  v_fdoc_numb, v_fdoc_date  
         FROM  INVHIST     
        WHERE  PRN =rec.RN AND ACTION_DATE <= dDate AND ACTION_TYPE = 0; 
       EXCEPTION WHEN NO_DATA_FOUND THEN v_fdoc_numb := null;  v_fdoc_date := null;
     END;

       if nREGIM = 2 then  -- До 100 000 р
       cTEMP1 := cTEMP1 ||CHR (13)||
                '<object xsi:type="MovablesLess1000">'|| CHR (13)||
                 '<OKOF>'||to_char(rec.sokof)||'</OKOF>'||CHR (13)|| --Код ОКОФ. Обязательный элемент. 9-ти значное число
                 '<invno>'||rec.scard_pref_trim||rec.scard_numb_trim||'</invno>'||CHR (13)||
                 '<description>'||convert(rec.snom_name,'utf8')||'</description>'||CHR (13)||
                 '<is_budget>'||rec.is_budget||'</is_budget>'||CHR (13)||   --Источник финансирования. 0 - внебюджетный, 1 - бюджетный. Обязательный элемент. По умолчанию значение = 0
                 '<propsections_id>4</propsections_id>'||CHR (13)||
                 '<propgroups_id>7</propgroups_id>'||CHR (13)||
                 '<propnames_id>1</propnames_id>'||CHR (13)||
                 '<amount>'||replace(to_char(rec.count_real),',','.')||'</amount>'||CHR (13)||
                 '<costs>'||CHR (13)||
                 '<startpay>'||replace(to_char(v_new_a_cost_begin/rec.item_count),',','.')||'</startpay>'||CHR (13)||   --меняем разделитель дробной части
                 '<startpay_calcdate>'||to_char(v_min_date,'dd.mm.yyyy')||'</startpay_calcdate>'||CHR (13)||
                 '<pay>'||replace(((v_NEW_A_COST_BEGIN - v_NEW_A_AMORT_DURING-v_NEW_A_AMORT_BEGIN)/rec.item_count),',','.')||'</pay>'||CHR (13)||
                 '<pay_calcdate>'||to_char(ddate,'dd.mm.yyyy')||'</pay_calcdate>'||CHR (13)||
                 '</costs>'||CHR (13)||
                 '<documents>'||CHR (13)||
                 '<document>'||CHR (13)||
                 '<doctypes_id>'||758||'</doctypes_id>'||CHR (13)||
                 '<docno>'||nvl(convert(v_fdoc_numb,'utf8'),' ')||'</docno>'||CHR (13)||
                 '<docdate>'||to_char(nvl(v_fdoc_date,v_min_date),'dd.mm.yyyy')||'</docdate>'||CHR (13)||
                 '<explanation></explanation>'||CHR (13)||
                 '<docrole>'||convert('Иное_вещное_право','utf8')||'</docrole>'||CHR (13)||
                  '</document>'||CHR (13)||
                  '</documents>'||CHR (13)||
                 '</object>';
      nKOl := nKOl + 1;
     dbms_lob.writeappend(cCLOB, length(cTEMP1), cTEMP1);
     cTEMP1 := null; 
     end if;
     
       if nREGIM = 3 then  -- Больше 100 000
       cTEMP1 := cTEMP1 ||CHR (13)||
                '<object xsi:type="MovablesMore1000">'|| CHR (13)||
                 '<OKOF>'||to_char(rec.sokof)||'</OKOF>'||CHR (13)|| --Код ОКОФ. Обязательный элемент. 9-ти значное число
                 '<invno>'||rec.scard_pref_trim||rec.scard_numb_trim||'</invno>'||CHR (13)||
                 '<description>'||convert(rec.snom_name,'utf8')||'</description>'||CHR (13)||
                 '<is_budget>'||rec.is_budget||'</is_budget>'||CHR (13)||   --Источник финансирования. 0 - внебюджетный, 1 - бюджетный. Обязательный элемент. По умолчанию значение = 0
                 '<propsections_id>4</propsections_id>'||CHR (13)||
                 '<propgroups_id>7</propgroups_id>'||CHR (13)||
                 '<propnames_id>1</propnames_id>'||CHR (13)||
                -- '<amount>'||to_char(rec.item_count)||'</amount>'||CHR (13)||
                 '<costs>'||CHR (13)||
                 '<startpay>'||replace(to_char(v_new_a_cost_begin),',','.')||'</startpay>'||CHR (13)||   --меняем разделитель дробной части
                 '<startpay_calcdate>'||to_char(v_min_date,'dd.mm.yyyy')||'</startpay_calcdate>'||CHR (13)||
                 '<pay>'||replace((v_NEW_A_COST_BEGIN - v_NEW_A_AMORT_DURING-v_NEW_A_AMORT_BEGIN),',','.')||'</pay>'||CHR (13)||
                 '<pay_calcdate>'||to_char(ddate,'dd.mm.yyyy')||'</pay_calcdate>'||CHR (13)||
                 '</costs>'||CHR (13)||
                 '<documents>'||CHR (13)||
                 '<document>'||CHR (13)||
                 '<doctypes_id>'||758||'</doctypes_id>'||CHR (13)||
                 '<docno>'||nvl(convert(v_fdoc_numb,'utf8'),' ')||'</docno>'||CHR (13)||
                 '<docdate>'||to_char(nvl(v_fdoc_date,v_min_date),'dd.mm.yyyy')||'</docdate>'||CHR (13)||
                 '<explanation></explanation>'||CHR (13)||
                 '<docrole>'||convert('Иное_вещное_право','utf8')||'</docrole>'||CHR (13)||
                  '</document>'||CHR (13)||
                  '</documents>'||CHR (13)||
                 '</object>';
      nKOl := nKOl + 1;
     dbms_lob.writeappend(cCLOB, length(cTEMP1), cTEMP1);
     cTEMP1 := null; 
     end if;
     
       if nREGIM = 1 then      -- Бибики
       cTEMP1 := cTEMP1 ||CHR (13)||
                '<object xsi:type="Transport">'|| CHR (13)||
                 '<OKOF>'||to_char(rec.sokof)||'</OKOF>'||CHR (13)|| --Код ОКОФ. Обязательный элемент. 9-ти значное число
                 '<invno>'||rec.scard_pref_trim||rec.scard_numb_trim||'</invno>'||CHR (13)||
                 '<description>'||convert(rec.snom_name,'utf8')||'</description>'||CHR (13)||
                 '<is_budget>'||rec.is_budget||'</is_budget>'||CHR (13)||   --Источник финансирования. 0 - внебюджетный, 1 - бюджетный. Обязательный элемент. По умолчанию значение = 0
                 '<transptype_id>1</transptype_id>'||CHR (13)||
                 '<brandnames_id>738</brandnames_id>'||CHR (13)||           --Марка тр. средства. Значение брать из поля id таблицы "brandnames". Обязательный элемент
                 '<model></model>'||CHR (13)||
                 '<relyear>2010</relyear>'||CHR (13)||
                 '<motorno></motorno>'||CHR (13)|| 
                 '<fedno>'||' '||'</fedno>' ||CHR (13)||                    -- Гос. номер. Обязательный элемент.
                 '<chassisno></chassisno>'||CHR (13)||
                 '<fedno_date>'||to_char(v_min_date,'dd.mm.yyyy')||'</fedno_date>'||CHR (13)||                    -- Когда выдан гос. номер. Обязательный элемент
                 '<bodyno></bodyno>'||CHR (13)||
                 '<info />'||CHR (13)|| 
                 '<costs>'||CHR (13)||
                 '<startpay>'||replace(to_char(v_new_a_cost_begin),',','.')||'</startpay>'||CHR (13)||   --меняем разделитель дробной части
                 '<startpay_calcdate>'||'01.01.2012'/*to_char(v_min_date,'dd.mm.yyyy')*/||'</startpay_calcdate>'||CHR (13)||
                 '<pay>'||replace((v_NEW_A_COST_BEGIN - v_NEW_A_AMORT_DURING-v_NEW_A_AMORT_BEGIN),',','.')||'</pay>'||CHR (13)||
                 '<pay_calcdate>'||to_char(ddate,'dd.mm.yyyy')||'</pay_calcdate>'||CHR (13)||
                 '</costs>'||CHR (13)||
                 '<documents>'||CHR (13)||
                 '<document>'||CHR (13)||
                 '<doctypes_id>'||758||'</doctypes_id>'||CHR (13)||
                 '<docno>'||nvl(convert(v_fdoc_numb,'utf8'),' ')||'</docno>'||CHR (13)||
                 '<docdate>'||to_char(nvl(v_fdoc_date,v_min_date),'dd.mm.yyyy')||'</docdate>'||CHR (13)||
                 '<explanation></explanation>'||CHR (13)||
                 '<docrole>'||convert('Иное_вещное_право','utf8')||'</docrole>'||CHR (13)||
                  '</document>'||CHR (13)||
                  '</documents>'||CHR (13)||
                 '</object>';
      nKOl := nKOl + 1;
     dbms_lob.writeappend(cCLOB, length(cTEMP1), cTEMP1);
     cTEMP1 := null; 
     end if;
     
     end loop;

        cTEMP3 := cTEMP3 ||CHR (13)||
                  '</objects>';

 dbms_lob.writeappend(cCLOB, length(cTEMP3), cTEMP3);

report_to_buff;

    /* освобождаем буфер */
    dbms_lob.freetemporary(cCLOB);
    
--exception
  --when others then p_exception(0,'Ошибка загрузки. '||nKOl);
end;