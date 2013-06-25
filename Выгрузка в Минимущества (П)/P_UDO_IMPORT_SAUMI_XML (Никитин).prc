create or replace procedure P_UDO_IMPORT_SAUMI_XML
(
  nIDENT            in number,          -- сотрудники
  nCOMPANY          in number,          -- организация
  dDATE             in date,            -- Дата отчета
  nREGIM            in number           -- Режим (1 - трансорт, 2 - ОС < 100 000, 3 - ОС > 100 000
)
as
   /* данные о работодателе */

  cCLOB             CLOB;
  sFileName         varchar2(35);
   sDef                   VARCHAR2 (1);
   v_act_date             DATE;
   v_new_a_cost_begin     NUMBER;
   v_new_a_amort_during   NUMBER;
   v_act_type             NUMBER;

 PROCEDURE report_to_buff
   IS
   BEGIN
      INSERT INTO FILE_BUFFER (IDENT, FILENAME, DATA)
        VALUES   (nIDENT, sFileNAME, cCLOB);
   END;


begin

sFileNAME := 'test.xml';

 cCLOB := '<?xml version="1.0" encoding="utf-8"?>'|| CHR (13)||
 '<objects xmlns="http://mio.samregion.ru/datacollector"'||CHR (13)||
          'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">';

   for rec IN (SELECT --+ordered
                replace(t3.code, ' ', '') AS sokof,
                LTRIM (t2.OBJECT_GROUP) scard_pref_trim,
                LTRIM (t2.OBJECT_NUMBER) scard_numb_trim,
                LTRIM (t2.inv_number) invno,
                T5.NOMEN_NAME snom_name,
                t2.item_count,
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
                AND T2.NOMENCLATURE = T5.RN)
   LOOP
 
 
   --Пошли по истории карточки
    BEGIN
         SELECT   MAX (ACTION_DATE) ACT_DATE,
                  MAX (NEW_A_COST_BEGIN)
                     KEEP (DENSE_RANK LAST ORDER BY ACTION_DATE)
                     NEW_A_COST_BEGIN,
                  MAX (NEW_A_AMORT_DURING)
                     KEEP (DENSE_RANK LAST ORDER BY ACTION_DATE)
                     NEW_A_AMORT_DURINGN,
                  MAX (ACTION_TYPE)
                     KEEP (DENSE_RANK LAST ORDER BY ACTION_DATE)
                     ACTION_TYPE
           INTO   v_act_date,
                  v_new_a_cost_begin,
                  v_new_a_amort_during,
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

       cCLOB := cCLOB ||CHR (13)|| 
                '<object xsi:type="MovablesLess1000">'|| CHR (13)||
                 '<OKOF>'||to_char(rec.sokof)||'</OKOF>'||CHR (13)|| --Код ОКОФ. Обязательный элемент. 9-ти значное число
                 '<invno>'||rec.scard_pref_trim||rec.scard_numb_trim||'</invno>'||CHR (13)|| 
                 '<description>'||convert(rec.snom_name,'utf8')||'</description>'||CHR (13)||
                 '<is_budget>'||rec.is_budget||'</is_budget>'||CHR (13)||   --Источник финансирования. 0 - внебюджетный, 1 - бюджетный. Обязательный элемент. По умолчанию значение = 0
                 '<propsections_id>4</propsections_id>'||CHR (13)||
                 '<propgroups_id>7</propgroups_id>'||CHR (13)||
                 '<propnames_id>1</propnames_id>'||CHR (13)||
                 '<amount>'||to_char(rec.item_count)||'</amount>'||CHR (13)||
                 '<costs>'||CHR (13)||
                 '<startpay>'||v_new_a_cost_begin||'</startpay>'||CHR (13)||
                 '<startpay_calcdate>'||to_char(rec.INCOME_DATE,'dd.mm.yyyy')||'</startpay_calcdate>'||CHR (13)||
                 '<pay>'||(v_NEW_A_COST_BEGIN - v_NEW_A_AMORT_DURING)||'</pay>'||CHR (13)||
                 '<pay_calcdate>'||to_char(ddate,'dd.mm.yyyy')||'</pay_calcdate>'||CHR (13)||
                 '</costs>'||CHR (13)||
                 '<documents>'||CHR (13)||
                 '<document>'||CHR (13)||
                 '<doctypes_id>'||758||'</doctypes_id>'||CHR (13)|| 
                 '<docno>'||432||'</docno>'||CHR (13)|| 
                 '<docdate>'||to_char(ddate,'dd.mm.yyyy')||'</docdate>'||CHR (13)|| 
                 '<explanation></explanation>'||CHR (13)|| 
                 '<docrole>'||convert('Иное_вещное_право','utf8')||'</docrole>'||CHR (13)|| 
                  '</document>'||CHR (13)||
                  '</documents>'||CHR (13)||
                 '</object>';
     end loop;    
           
        cCLOB := cCLOB ||CHR (13)||
                  '</objects>';
                  
      
            
report_to_buff;

end;
/
