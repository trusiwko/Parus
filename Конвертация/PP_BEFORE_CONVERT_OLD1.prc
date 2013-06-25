create or replace procedure PP_BEFORE_CONVERT is
begin
  -- Индексы:
  execute immediate 'alter table P7_GDMD add constraint I_P7_GDMD_1 primary key (NOB_RN)';
  execute immediate 'alter table P7_UNITS add constraint I_P7_UNITS_1 primary key (RN)';
  execute immediate 'alter table P7_INSPEC add constraint I_P7_INSPEC_1 primary key (RN)';
  execute immediate 'alter table P7_INBASE add constraint I_P7_INBASE_1 primary key (RN)';
  --execute immediate 'create index I_P7_EOPSPEC_1 on P7_EOPSPEC (master_rn)';
  --execute immediate 'create index I_P7_INSPEC_2 on P7_INSPEC (master_rn);';
  --execute immediate 'create index I_P7_ACANREST_1 on P7_ACANREST (master_rn)';
  execute immediate 'create index I_P7_UNIT_REF_1 on P7_UNIT_REF (PARENT_UNT, PARENT_RN)';
  execute immediate 'create index I_P7_UNITS_2 on P7_UNITS (NAME)';

  -- Базовая валюта у нас не Руб, а RUB:
  update P7_CURRBASE t set t.ISO = 'Руб' where t.RN = '0002';
  update P7_CURRBASE t set t.ISO = 'RUB' where t.RN = '0001';
  -- Типовые формы учета:
  update P7_ACCBASE t
     set t.s_analityc = 3
   where t.account like '%1106%'
     and t.s_analityc = '0';
  -- С инвентаркой беда: нет дат:
  update P7_INSPEC
     set p7_date = nvl(date_old, date_doc)
   where p7_date is null;
  -- 1. Попробуем взять минимальную дату истории ИК
  for c in (select t.RN, ACTION_DATE
              from (select min(DATE_OLD) over(partition by MASTER_RN) ACTION_DATE,
                           t.*
                      from P7_INSPEC t) t
             where P7_DATE is null
               and ACTION_DATE is not null) loop
    update P7_INSPEC t set t.P7_DATE = c.action_date where t.RN = c.RN;
  end loop;
  -- 2. Далее:
  for c in (select DATE_IN, t.RN
              from P7_INBASE a, P7_INSPEC t
             where a.RN = t.Master_Rn
               and t.P7_DATE is null) loop
    update P7_INSPEC t set t.p7_date = c.date_in where t.RN = c.RN;
  end loop;
  -- 3. Вынужденная мера:
  update P7_INSPEC t
     set t.p7_date = to_date('01.01.2000', 'dd.mm.yyyy')
   where p7_date is null;
  -- 4. С датой начисления амортизации:
  for c in (select t.RN, s.ddate
              from P7_INBASE t,
                   (select max(s.p7_date) ddate, s.master_rn
                      from P7_INSPEC s
                     where s.code = '3'
                     group by s.master_rn) s
             where t.rn = s.master_rn
               and nvl(t.summa_amor, 0) <> 0
               and t.date_rst is null) loop
    update P7_INBASE t set t.date_rst = c.ddate where t.RN = c.RN;
  end loop;
  update P7_INBASE t
     set t.date_rst = t.date_in
   where t.date_rst is null
     and nvl(t.summa_amor, 0) <> 0;
  -- 5. СПИ:
  update P7_INBASE t
     set t.SROK = 1
   where t.SROK = 0
     and t.meth_amort = 1;
  -- 6. Стоимость:
  update P7_INBASE t
     set t.In_Sum =
         (t.In_Wear + t.Summa_Amor)
   where t.IN_WEAR + t.SUMMA_AMOR > t.In_Sum;
  -- AMORT_TYPE in (3,4) and CARD_TYPE in (3,4) or CARD_TYPE not in (3,4) 
  begin
    for c in (select t.RN, t.Typik, t.Meth_Amort
                from P7_INBASE t
               where not ((METH_AMORT <> 1 and TYPIK in (4, 5)) or
                      TYPIK not in (4, 5))) loop
      update P7_INBASE t set t.Meth_Amort = 0 where t.RN = c.rn;
    end loop;
  end;
  -- ИНН и КПП
  update p7_orgbase t
     set t.inn = replace(t.inn, '+', '/')
   where t.inn like '%+%';
  update p7_orgbase t
     set t.inn = replace(t.inn, '-', '/')
   where t.inn like '%-%';
  update p7_orgbase t
     set t.inn = replace(t.inn, '\', '/')
   where t.inn like '%\%';
  update p7_orgbase t
     set t.inn = replace(t.inn, '*', '/')
   where t.inn like '%*%';
  update p7_orgbase t
     set t.inn = replace(t.inn, '.', '/')
   where t.inn like '%.%';
  update p7_orgbase t
     set t.inn = replace(t.inn, 'a', '/')
   where t.inn like '%a%';
  -- И такое бывает:
  update P7_INBASE t set t.Rst_Sum = 0 where t.Rst_Sum < 0;
  update P7_INSPEC t set t.INSUM_NEW = 0 where t.INSUM_NEW < 0;
  update P7_INSPEC t set t.Insum_Old = 0 where t.Insum_Old < 0;
  -- Типы документов:
  update p7_docbase t set t.mnemo_doc = trim(t.mnemo_doc);
  
  -- Если загружаем через ODBC, то:
  /*for c in (select t.COLUMN_NAME, t.TABLE_NAME
              from user_tab_columns t
             where t.TABLE_NAME in ('P7_EOPBASE',
                                    'P7_EOPSPEC',
                                    'P7_NOMREST',
                                    'P7_INBASE',
                                    'P7_INSPEC')
               and t.DATA_TYPE = 'VARCHAR2') loop
    execute immediate 'update ' || c.table_name || ' set ' || c.column_name ||
                      ' = trim(' || c.column_name || ')';
  end loop;*/
end PP_BEFORE_CONVERT;
/
