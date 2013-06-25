create or replace procedure PP_BEFORE_CONVERT is
  f            boolean;
  p7_gdmd_code p7_gdmd.code%type;
  shrtype_rn   p7_zhrtype.hrtype_rn%type;
  sISO_7       p7_currbase.iso%type;
  sISO_8       curnames.intcode%type;
  sVIDISP      P7_ZVIDISP.VIDISP_RN%type;
  sRN7         VARCHAR2(4);
  nTEMP        number;
  nVERSION     PKG_STD.tREF;
  sNUMB        P7_COMDICBS.NUM%type;
begin
  -- Исправить базовые процедуры:
  /*
   1. Отключить проверки P_OPRSPECS_CHECK: 
   1.1 "В проводке ХО не задана номенклатура." (101)
   1.2 "В проводке ХО задание номенклатуры недопустимо." (106)
   2. Отключить проверку P_IMPORT7_INVENTORY
   2.1 "Счет инвентарного учета должен иметь типовую форму "Основные средства"." (297)
   3. Исправить процедуру P_IMPORT7_CLNPERSONS
   3.1 Вместо добавления контрагента на 154 строке:
          if CHECK_DUPLICATE(nPERS_AGENT, nOWNER_AGENT, rREC.JobBegin, rREC.JobEnd) > 0 then
            nOWNER_AGENT := nPERS_AGENT;
            update P7_ZANK t set t.organ_rn = t.orgbase_rn where t.ank_rn = rREC.Ank_Rn;
          end if;
   4. T_DICACCS_BUPDATE
   4.1 Допустимо изменение типовой формы учета "материалы, товары (учетные цены)" на "материалы, товары (средние цены)" и наоборот.
   Исправление косяков:
   1. P_IMPORT7_PRRWRD
   60: nREWTYPE nNEWRN
   Сократить "Государственная награда" и прочие до 20 символов!
  */
  begin
    execute immediate 'create index I_P7_NOMREST_1 on P7_NOMREST (RN_ACCOUNT)';
    execute immediate 'alter table P7_ACCBASE add constraint I_P7_ACCBASE_1 primary key (RN)';
  exception
    when others then
      null;
  end;
  -- Удаляем индексы, потом восстановим:
  --execute immediate 'drop index I_OPRSPECS_TURNS_CR_NOM';
  --execute immediate 'drop index I_OPRSPECS_TURNS_DB_NOM';
  --
  update P7_AMORT t set t.name_nor = t.shifr where t.name_nor is null;
  --
  update P7_BANKACC t
     set t.code = trim(t.code)
   where t.code <> trim(t.code);
  --
  update P7_PERSON t
     set t.bh_country = null
   where not exists
   (select null from P7_COUNTRY a where a.country_rn = t.bh_country)
     and t.bh_country is not null;
  update P7_PERSON t
     set t.bh_region_ = null
   where not exists (select null
            from P7_REGION a
           where a.region_rn = t.bh_region_
             and a.country_rn = t.bh_country)
     and t.bh_region_ is not null;
  -- Родственники:
  update P7_ZANKFAM t
     set t.degrel_rn =
         (select min(t.degrel_rn)
            from P7_ZDEGREL t
           where t.code in ('----', 'Прочее'))
   where t.degrel_rn is null;
  update P7_ZANKFAM t
     set t.dedu_end = null
   where t.dedu_end = to_date('31.12.8888', 'dd.mm.yyyy');
  update P7_ZANKFAM t
     set t.dedu_start = t.dedu_end
   where t.dedu_start is null
     and t.dedu_end is not null
     and t.taxrep_rn is not null;
  update P7_ZANKFAM t
     set t.dedu_start = null
   where t.taxrep_rn is null
     and t.dedu_start is not null;
  update P7_ZANKFAM t
     set t.dedu_start = t.dedu_end
   where t.dedu_end < t.dedu_start;
  -- Дублирование налоговых вычетов у родственников:
  for c in (select distinct a.ankfam_rn, a.nrow
              from (select t.ankfam_rn,
                           t.orgbase_rn,
                           t.degrel_rn,
                           t.surname,
                           t.firstname,
                           t.secondname,
                           t.birthday,
                           t.isfirstchl,
                           t.isinval,
                           t.isvich,
                           t.dedu_start,
                           t.dedu_end,
                           row_number() over(partition by t.orgbase_rn, t.degrel_rn, t.surname, t.firstname, t.secondname, t.birthday, t.isfirstchl, t.isinval, t.isvich order by t.ankfam_rn) nrow
                      from P7_ZANKFAM t
                     where t.dedu_start is not null) a,
                   (select t.ankfam_rn,
                           t.orgbase_rn,
                           t.degrel_rn,
                           t.surname,
                           t.firstname,
                           t.secondname,
                           t.birthday,
                           t.isfirstchl,
                           t.isinval,
                           t.isvich,
                           t.dedu_start,
                           t.dedu_end
                      from P7_ZANKFAM t
                     where t.dedu_start is not null) b
             where a.orgbase_rn = b.orgbase_rn
               and a.degrel_rn = b.degrel_rn
               and cmp_vc2(a.surname, b.surname) = 1
               and cmp_vc2(a.firstname, b.firstname) = 1
               and cmp_vc2(a.secondname, b.secondname) = 1
               and cmp_dat(a.birthday, b.birthday) = 1
               and a.isfirstchl = b.isfirstchl
               and a.isinval = b.isinval
               and a.isvich = b.isvich
               and b.dedu_end > a.dedu_start
               and b.dedu_start <= a.dedu_end
               and a.ankfam_rn <> b.ankfam_rn) loop
    update P7_ZANKFAM t
       set t.surname = t.surname || c.nrow
     where t.ankfam_rn = c.ankfam_rn;
  end loop;
  --
  update P7_zank t
     set t.jobend = null
   where t.jobend = to_date('31.12.8888', 'dd.mm.yyyy');
  -- Дата увольнения меньше даты приема: дату приема возьмем из исполнения должностей.
  for c in (select least(f.startdate, t.jobend) ddate, t.ank_rn
              from p7_zank t,
                   (select f.ank_rn, min(f.startdate) startdate
                      from p7_zfcac f
                     group by f.ank_rn) f
             where t.jobend < t.jobbegin
               and f.ank_rn = t.ank_rn) loop
    update p7_zank t set t.jobbegin = c.ddate where t.ank_rn = c.ank_rn;
  end loop;
  -- Отсутствующие единицы измерения:
  insert into p7_measure
    (rn, mnemo_mes, name_mes, is_integer, category, is_sample, kf)
    select distinct t.rn_mes, '[' || t.rn_mes || ']', t.rn_mes, 0, 3, 1, 1
      from p7_nobase t
     where not exists (select null from p7_measure a where a.rn = t.rn_mes);
  -- Пробелы в мнемокоде номенклатуры:
  update p7_gdmd t set t.code = trim(t.code) where t.code <> trim(t.code);
  f := true;
  while f loop
    f := false;
    for c in (select t.nob_rn, max(t.gdmd_rn) gdmd_rn, t.code, count(1) n
                from p7_gdmd t
               group by t.nob_rn, t.code
              having count(1) > 1) loop
      f            := true;
      p7_gdmd_code := PKG_EXECUTE.FIND_UNIQUE_COLUMN_VALUE('P7_GDMD',
                                                           '',
                                                           '',
                                                           'CODE',
                                                           c.code);
      update p7_gdmd t
         set t.code = p7_gdmd_code
       where t.gdmd_rn = c.gdmd_rn;
    end loop;
  end loop;
  --
  insert into p7_passport
    (passport_r, name, identity)
    select distinct t.passport_r, t.passport_r, 1
      from P7_PERSON t
     where not exists
     (select null from p7_passport p where t.passport_r = p.passport_r)
       and t.passport_r is not null;
  -- Отсутствующие группы ТМЦ:
  insert into P7_GDGR
    (rn, code, name, batchuse, batchbefor, batchsel)
    select distinct t.gdgr_rn, '[' || t.gdgr_rn || ']', t.gdgr_rn, 1, 0, 1
      from P7_NOBASE t
     where not exists (select null from P7_GDGR a where a.rn = t.gdgr_rn)
       and t.gdgr_rn is not null;
  -- Раздел ЭК назначен разным уровням аналитики:
  update P7_ACCBASE t
     set t.org_an = null
   where t.smeta_an like '%8%'
     and trim(t.org_an) = '4';
  -- 
  update P7_ACCBASE t
     set t.rn_acb = null
   where not exists (select null from P7_ACBBASE a where a.rn = t.rn_acb)
     and t.rn_acb is not null;
  update P7_ACCBASE t
     set t.rn_tfin = null
   where not exists (select null from P7_FSBFBASE a where a.rn = t.rn_tfin)
     and t.rn_tfin is not null;
  update P7_ACCBASE t
     set t.rn_mo = null
   where not exists (select null from P7_ORDBASE a where a.rn = t.rn_mo)
     and t.rn_mo is not null;
  update p7_accbase t set t.name_acc = t.account where t.name_acc is null;
  -- Нет родителя:
  delete from P7_NOSPEC t
   where not exists (select * from P7_NOBASE a where a.rn = t.master_rn);
  -- Обмен валют (проблема с базовыми валютами)
  select t.iso into sISO_7 from P7_CURRBASE t where t.lbase = 1;
  find_version_by_company(PKG_IMPORT7.nCOMPANY, 'CURNAMES', nVERSION);
  select t.intcode
    into sISO_8
    from CURNAMES t, CURBASE c
   where c.currency = t.rn
     and t.version = nVERSION;
  if sISO_7 <> sISO_8 then
    update P7_CURRBASE t set t.iso = 'ру1' where t.iso = sISO_7;
    update P7_CURRBASE t set t.iso = sISO_7 where t.iso = sISO_8;
    update P7_CURRBASE t set t.iso = sISO_8 where t.iso = 'ру1';
  end if;
  -- Удаляем остатки по ТМЦ по неправильным счетам:
  -- Данное нужно делать после загрузки счетов в программу! Хорошо в P_IMPORT7_DICACCS
  find_version_by_company(PKG_IMPORT7.nCOMPANY, 'AccountsPlan', nVERSION);
  delete from P7_NOMREST t
   where t.rn in (select t.rn
                    from P7_NOMREST t, IMPORT7 b, ACCTFORM a, DICACCS c
                   where t.rn_account = b.rn7
                     and b.table7 = 'ACCBASE'
                     and a.numb = c.acc_form
                     and c.rn = b.rn8
                     and a.is_values = 0
                     and c.version = nVERSION);
  update DICACCS d
     set d.acc_form = 300
   where d.rn in (select distinct c.rn
                    from P7_NOMREST t, IMPORT7 b, DICACCS c
                   where t.rn_account = b.rn7
                     and b.table7 = 'ACCBASE'
                     and c.acc_form is null
                     and c.rn = b.rn8)
     and d.version = nVERSION;
  --
  delete from P7_ACANREST t
   where (not exists (select * from P7_ACCSPEC s where s.rn = t.rn_ac_a4) and
          t.rn_ac_a4 is not null);
  -- Не существующая аналитика:
  update P7_EOPSPEC t
     set t.rn_db_a1 = null
   where not exists (select null from P7_ACCSPEC a where a.rn = t.rn_db_a1)
     and t.rn_db_a1 is not null;
  update P7_EOPSPEC t
     set t.rn_db_a2 = null
   where not exists (select null from P7_ACCSPEC a where a.rn = t.rn_db_a2)
     and t.rn_db_a2 is not null;
  update P7_EOPSPEC t
     set t.rn_db_a3 = null
   where not exists (select null from P7_ACCSPEC a where a.rn = t.rn_db_a3)
     and t.rn_db_a3 is not null;
  update P7_EOPSPEC t
     set t.rn_db_a4 = null
   where not exists (select null from P7_ACCSPEC a where a.rn = t.rn_db_a4)
     and t.rn_db_a4 is not null;
  update P7_EOPSPEC t
     set t.rn_db_a5 = null
   where not exists (select null from P7_ACCSPEC a where a.rn = t.rn_db_a5)
     and t.rn_db_a5 is not null;
  update P7_EOPSPEC t
     set t.rn_kr_a1 = null
   where not exists (select null from P7_ACCSPEC a where a.rn = t.rn_kr_a1)
     and t.rn_kr_a1 is not null;
  update P7_EOPSPEC t
     set t.rn_kr_a2 = null
   where not exists (select null from P7_ACCSPEC a where a.rn = t.rn_kr_a2)
     and t.rn_kr_a2 is not null;
  update P7_EOPSPEC t
     set t.rn_kr_a3 = null
   where not exists (select null from P7_ACCSPEC a where a.rn = t.rn_kr_a3)
     and t.rn_kr_a3 is not null;
  update P7_EOPSPEC t
     set t.rn_kr_a4 = null
   where not exists (select null from P7_ACCSPEC a where a.rn = t.rn_kr_a4)
     and t.rn_kr_a4 is not null;
  update P7_EOPSPEC t
     set t.rn_kr_a5 = null
   where not exists (select null from P7_ACCSPEC a where a.rn = t.rn_kr_a5)
     and t.rn_kr_a5 is not null;
  --
  update P7_EOPBASE t
     set t.rn_doc = null
   where not exists (select null from P7_DOCBASE a where t.rn_doc = a.rn)
     and t.rn_doc is not null;
  update P7_EOPBASE t
     set t.num_doc = trim(t.num_doc)
   where t.num_doc <> trim(t.num_doc);
  --
  delete from p7_inspec t where t.code = '0';
  update P7_INSPEC t
     set t.rn_doc = null
   where not exists (select null from P7_DOCBASE a where a.rn = t.rn_doc)
     and t.rn_doc is not null;
  -- Недопустимое значение срока полезного использования:
  update P7_INBASE t
     set t.srok = 1
   where t.meth_amort = 1
     and t.srok = 0;
  --  ORA-02290: check constraint (PARUS.C_INVENTORY_AMORTCARD) violated
  update P7_INBASE t
     set t.meth_amort = 2
   where not
          (t.meth_amort <> 1 and t.typik in (4, 5) or t.typik not in (4, 5));
  --
  update p7_inbase t
     set t.in_wear = t.IN_SUM - t.SUMMA_AMOR
   where not (t.in_wear + t.SUMMA_AMOR <= t.IN_SUM);
  update p7_inbase t
     set t.in_sum = t.in_sum - t.in_wear, t.in_wear = 0
   where t.in_wear < 0;
  update p7_inbase t
     set t.srok = t.srok_ost
   where not (t.srok >= t.srok_ost);
  update p7_inbase t
     set t.date_rst = t.date_in
   where t.date_rst is null
     and t.SUMMA_AMOR <> 0;
  delete from P7_INBASE t
   where not exists
   (select null from P7_ACCBASE a where a.rn = t.RN_ACCOUNT);
  --
  insert into P7_AMORT
    (rn, shifr, name_nor, nor_amort, scope, srok_y, srok_m, rn_mea, scopex)
    select distinct t.rn_amort,
                    t.rn_amort,
                    t.rn_amort,
                    null,
                    null,
                    0,
                    0,
                    null,
                    0
      from p7_inbase t
     where not exists (select null from P7_AMORT a where a.rn = t.rn_amort)
       and t.rn_amort is not null;
  -- ЗАРАБОТНАЯ ПЛАТА:
  select count(1) into ntemp from P7_ZHRTYPE;
  if ntemp = 0 then
    insert into P7_ZHRTYPE
      (hrtype_rn, num, code, nick, name, main)
    values
      ('0001', 1, 'Д', 'Д', 'Д', 1);
  end if;
  begin
    select t.hrtype_rn
      into shrtype_rn
      from P7_ZHRTYPE t
     where t.nick = 'Д';
  exception
    when no_data_found then
      shrtype_rn := null;
  end;
  update P7_ZGRRBSP t
     set t.hrtype_rn = shrtype_rn
   where not exists
   (select null from p7_zhrtype a where t.hrtype_rn = a.hrtype_rn);
  execute immediate 'alter table P7_ZTAXREP modify taxbase VARCHAR2(2)';
  update P7_ZTAXREP t set t.taxbase = '13' where t.taxbase = 'C';
  --
  for i in 1 .. 3 loop
    update P7_ZFZPFUNC t set t.params = replace(t.params, ' ;', ';');
    update P7_ZFZPFUNC t set t.params = replace(t.params, '; ', ';');
    update P7_ZFZPFUNC t set t.params = replace(t.params, ' :', ':');
    update P7_ZFZPFUNC t set t.params = replace(t.params, ': ', ':');
    update P7_ZFZPFUNC t set t.params = replace(t.params, ' = ', '=');
    update P7_ZFZPFUNC t
       set t.params = replace(t.params, '/Ал=', '/АЛ=');
    update P7_ZFZPFUNC t
       set t.params = '/CM=# /АЛ=СрСтавка'
     where dbms_lob.substr(t.params) = '/АЛ=СрСтавка';
  end loop;
  --
  delete from P7_ZSNUSP t where t.snu_rn is null;
  -- Даты начала/окончания штатных должностей и подразделений
  for c in (select a.subdiv_rn, min(t.startdate) mdate
              from p7_zsubdiv a, p7_zpost t
             where t.subdiv_rn = a.subdiv_rn
               and t.startdate < a.startdate
             group by a.subdiv_rn) loop
    update p7_zsubdiv a
       set a.startdate = c.mdate
     where a.subdiv_rn = c.subdiv_rn;
  end loop;
  for c in (select t.post_rn, a.enddate
              from p7_zsubdiv a, p7_zpost t
             where t.subdiv_rn = a.subdiv_rn
               and t.enddate > a.enddate) loop
    update p7_zpost a
       set a.enddate = c.enddate
     where a.post_rn = c.post_rn;
  end loop;
  --
  update P7_ZPOST t
     set t.tipdol_rn =
         (select min(tt.tipdol_rn) from P7_ZTIPDOL tt)
   where t.tipdol_rn is null;
  --
  for c in (select t.postch_rn, a.enddate
              from p7_zpostch t, p7_zpost a
             where nvl(t.chenddate, a.enddate + 1) > a.enddate
               and t.PostBs_RN = a.post_rn) loop
    update p7_zpostch t
       set t.chenddate = c.enddate
     where t.postch_rn = c.postch_rn;
  end loop;
  --
  for c in (select a.startdate, t.postfzp_rn
              from p7_zpostfzp t, p7_zpost a
             where t.post_rn = a.post_rn
               and t.startdate < a.startdate) loop
    update p7_zpostfzp t
       set t.startdate = c.startdate
     where t.postfzp_rn = c.postfzp_rn;
  end loop;
  for c in (select a.enddate, t.postfzp_rn
              from p7_zpostfzp t, p7_zpost a
             where t.post_rn = a.post_rn
               and t.enddate > a.enddate) loop
    update p7_zpostfzp t
       set t.enddate = c.enddate
     where t.postfzp_rn = c.postfzp_rn;
  end loop;
  -- Но проблема до конца не решена:
  select min(t.vidisp_rn) into sVIDISP from P7_ZVIDISP t where t.main = 1;
  update p7_zfcac t
     set t.vidisp_rn = sVIDISP
   where t.vidisp_rn in
         (select a.vidisp_rn from p7_zvidisp a where a.main = 0)
     and t.ismainisp = 1;
  --
  for c in (select max(t.hissp_rn) hissp_rn, t.his_rn, t.code, count(1)
              from p7_zhissp t
             group by t.his_rn, t.code
            having count(1) > 1) loop
    delete from p7_zhissp t
     where t.code = c.code
       and t.his_rn = c.his_rn
       and t.hissp_rn <> c.hissp_rn;
  end loop;
  -- Нарушена иерархия. Корневой раздел доп.словаря имеет LEVEL = 2, а не один:
  select t.rn into sRN7 from p7_units t where t.name = 'CommonDic';
  for c in (select rn, nlevel
              from (select A.*, level - 1 nlevel
                      from P7_ACATALOG A
                     where A.UNIT_RN = sRN7
                    connect by prior a.rn = a.parent_rn
                     start with a.rn = sRN7) a
             where a.p7_level <> nlevel) loop
    update P7_ACATALOG t set t.p7_level = c.nlevel where t.rn = c.rn;
  end loop;
  --
  delete from P7_ZANKSTBS t where t.startdate > t.enddate;
  -- Не указана квалификационная категория.
  select count(1) into nTEMP from P7_ZEMPSKL t where t.skillrate_ is null;
  if nTEMP > 0 then
    begin
      select a.comdicbs_r
        into sRN7
        from p7_COMDICBS a, p7_comdictp b
       where b.comdictp_r = a.comdictp_r
         and b.num = 23
         and a.code = 'нет категории';
    exception
      when no_data_found then
        p_exception(0,
                    'Необходимо добавить квалификационную категорию "нет категории"');
    end;
    update P7_ZEMPSKL t set t.skillrate_ = sRN7 where t.skillrate_ is null;
  end if;
  -- Удалим старые данные:
  -- Начисления за прошлые года:
  delete from p7_zhis t where t.year <= to_char(sysdate, 'yyyy') - 3;
  delete from p7_ZPVHEAD t where t.year <= to_char(sysdate, 'yyyy') - 3;
  delete from P7_ZSVTREE t
   where not exists
   (select null from p7_ZPVHEAD a where a.pvhead_rn = t.pvhead_rn);
  -- Если базы доливаются:
  for c in (select a.code, t.daytype_rn
              from p7_zdaytype t, SLDAYSTYPE a
             where a.short_code = t.nick) loop
    update p7_zdaytype t
       set t.code = c.code
     where t.daytype_rn = c.daytype_rn
       and t.code <> c.code;
  end loop;
  for c in (select a.code, t.hrtype_rn
              from p7_zhrtype t, SL_HOURS_TYPES a
             where a.short_code = t.nick) loop
    update p7_zhrtype t
       set t.code = c.code
     where t.hrtype_rn = c.hrtype_rn
       and t.code <> c.code;
  end loop;
  -- Дублирование номера образовательного учреждения.
  for c in (select A.COMDICBS_R, E.CODE
              from P7_COMDICBS A, P7_COMDICTP B, edinstitut E
             where A.COMDICTP_R = B.COMDICTP_R
               and B.NUM = 11
               and E.NAME = A.NAME
               and E.CODE <> A.CODE) loop
    update P7_COMDICBS A
       set A.CODE = c.CODE
     where A.COMDICBS_R = C.COMDICBS_R;
  end loop;
  select max(numb) into sNUMB from edinstitut;
  for c in (select A.COMDICBS_R
              from P7_COMDICBS A, P7_COMDICTP B
             where A.COMDICTP_R = B.COMDICTP_R
               and B.NUM = 11
               and not exists
             (select null from edinstitut i where a.code = i.code)
               and exists
             (select null from edinstitut i where a.num = i.numb)) loop
    PKG_DOCUMENT.NEXT_NUMBER(sNUMB, 4, 1, sNUMB);
    update P7_COMDICBS A
       set A.NUM = sNUMB
     where A.COMDICBS_R = C.COMDICBS_R;
  end loop;
  --
  for c in (select t.spec_rn, p.code
              from P7_ZSPEC t, PRPROF p
             where t.name = p.name
               and t.code <> p.code) loop
    update P7_ZSPEC t set t.code = c.code where t.spec_rn = c.spec_rn;
  end loop;

  select trim(max(numb)) into sNUMB from PRPROF;
  for c in (select t.spec_rn
              from P7_ZSPEC t
             where not exists
             (select null from PRPROF i where t.code = i.code)
               and exists
             (select null from PRPROF i where t.num = i.numb)) loop
    PKG_DOCUMENT.NEXT_NUMBER(sNUMB, 4, 1, sNUMB);
    update P7_ZSPEC A set A.NUM = sNUMB where A.Spec_Rn = c.Spec_Rn;
  end loop;
  --
  select trim(max(numb)) into sNUMB from PREDSPEC;
  for c in (select t.okso_rn
              from P7_ZOKSO t
             where not exists
             (select null from PREDSPEC i where t.code = i.code)
               and exists
             (select null from PREDSPEC i where t.num = i.numb)) loop
    PKG_DOCUMENT.NEXT_NUMBER(sNUMB, 4, 1, sNUMB);
    update P7_ZOKSO A set A.NUM = sNUMB where A.okso_rn = c.okso_rn;
  end loop;
  -- Дублирование номера учёной степени.
  for c in (select A.COMDICBS_R, E.CODE
              from P7_COMDICBS A, P7_COMDICTP B, PRACDDGR E
             where A.COMDICTP_R = B.COMDICTP_R
               and B.NUM = 13
               and E.NAME = A.NAME
               and E.CODE <> A.CODE) loop
    update P7_COMDICBS A
       set A.CODE = c.CODE
     where A.COMDICBS_R = C.COMDICBS_R;
  end loop;
  select trim(max(numb))
    into sNUMB
    from (select to_number(numb) numb
            from PRACDDGR
          union all
          select t.num
            from p7_comdicbs t, p7_comdictp a
           where a.num = '13'
             and t.comdictp_r = a.comdictp_r);
  for c in (select t.comdicbs_r
              from p7_comdicbs t, p7_comdictp a
             where a.num = '13'
               and t.comdictp_r = a.comdictp_r
               and not exists
             (select null from PRACDDGR i where t.code = i.code)
               and exists
             (select null from PRACDDGR i where t.num = i.numb)) loop
    PKG_DOCUMENT.NEXT_NUMBER(sNUMB, 4, 1, sNUMB);
    update p7_comdicbs A
       set A.NUM = sNUMB
     where A.comdicbs_r = c.comdicbs_r;
  end loop;

  -- Дублирование номера учёного звания.
  for c in (select A.COMDICBS_R, E.CODE
              from P7_COMDICBS A, P7_COMDICTP B, PRACDSTS E
             where A.COMDICTP_R = B.COMDICTP_R
               and B.NUM = 12
               and E.NAME = A.NAME
               and E.CODE <> A.CODE) loop
    update P7_COMDICBS A
       set A.CODE = c.CODE
     where A.COMDICBS_R = C.COMDICBS_R;
  end loop;
  select trim(max(numb))
    into sNUMB
    from (select to_number(numb) numb
            from PRACDSTS
          union all
          select t.num
            from p7_comdicbs t, p7_comdictp a
           where a.num = '12'
             and t.comdictp_r = a.comdictp_r);
  for c in (select t.comdicbs_r
              from p7_comdicbs t, p7_comdictp a
             where a.num = '12'
               and t.comdictp_r = a.comdictp_r
               and not exists
             (select null from PRACDSTS i where t.code = i.code)
               and exists
             (select null from PRACDSTS i where t.num = i.numb)) loop
    PKG_DOCUMENT.NEXT_NUMBER(sNUMB, 4, 1, sNUMB);
    update p7_comdicbs A
       set A.NUM = sNUMB
     where A.comdicbs_r = c.comdicbs_r;
  end loop;

  -- Тип записи не может быть заполнен при незаполненном номере ордера.
  update P7_EOPSPEC t
     set t.nza_mo = null
   where t.nza_mo in (1, 2)
     and t.rn_mo is null;
  -- В проводке ХО задание количества недопустимо.
  update P7_EOPSPEC t
     set t.count = 0
   where t.rn_numcl is null
     and t.count <> 0;
  update P7_EOPBASE t
     set t.num_base = trim(t.num_base)
   where t.num_base <> trim(t.num_base);
  --
  update p7_zfzpsp t
     set t.katfzp_rn = null
   where not exists
   (select null from p7_zkatfzp a where a.katfzp_rn = t.katfzp_rn);
--
delete from p7_zfzpfunc t 
 where not exists
 (select * from p7_zkatfzp a where t.katfzp_rn = a.katfzp_rn)
;

-- update p7_zempeduc ed set ed.okso_rn = null where not exists(select null from p7_zokso z where z.okso_rn = ed.okso_rn)

  -- P_IMPORT7_CLNPERSTAXACC, P_IMPORT7_SLPAYGRND, P_IMPORT7_SLPAYS

  -- P_IMPORT7_VALREMNS, P_IMPORT7_ACCREMNS, P_IMPORT7_ECONOPRS, P_IMPORT7_AGNLIST,
  -- P_IMPORT7_DICNOMNS

end PP_BEFORE_CONVERT;
/
