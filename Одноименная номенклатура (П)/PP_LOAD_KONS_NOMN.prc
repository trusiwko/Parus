create or replace procedure PP_LOAD_KONS_NOMN
/*
  Процедура загрузки номенклатуры товаров, работ, услуг для нужд заказчика 
  из программы КонсультантПлюс.
  Файл в текстовом формате txt необходимо загрузить в базу в раздел 
  "Присоединенные документы" (двоичный)
  */

  /*create table TP_LOAD_KONS
  (
    RN   NUMBER,
    DATA VARCHAR2(77),
    NUM  VARCHAR2(3),
    TEXT VARCHAR2(57),
    CODE VARCHAR2(11)
  )*/
( --
 nCompany  in number,
 sDictCode in varchar2, -- Код доп.словаря для загрузки
 sFileCode in varchar2 -- Код присоединенного документа
 ) is
  d         varchar2(77);
  i         number;
  sName     varchar2(500);
  sCode     varchar2(500);
  sNPP      varchar2(3);
  ntemp     number;
  stemp     varchar2(240);
  dtemp     date;
  nDictCode number;
  nFileCode number;

  procedure InsertLine is
    ntemp number;
    aCode varchar2(240);
    aName varchar2(500);
  begin
  
    -- Необходимо указать свой способ заполнения справочника:
    -- Используя: sNPP, sName, sCode:
    aCode := lpad(sNPP, 3, '0'); 
    aName := substr(sName || ' (' || sCode || ')', 1, 500);
  
    begin
      PKG_PROC_BROKER.PROLOGUE;
      PKG_PROC_BROKER.SET_PARAM_NUM('NCOMPANY', nCompany);
      PKG_PROC_BROKER.SET_PARAM_NUM('NPRN', nDictCode);
      PKG_PROC_BROKER.SET_PARAM_STR('SSTR_VALUE', aCode);
      PKG_PROC_BROKER.SET_PARAM_NUM('NNUM_VALUE', NULL);
      PKG_PROC_BROKER.SET_PARAM_DAT('DDATE_VALUE', NULL);
      PKG_PROC_BROKER.SET_PARAM_STR('SNOTE', aName);
      PKG_PROC_BROKER.SET_PARAM_NUM('NRN');
      PKG_PROC_BROKER.EXECUTE('P_EXTRA_DICTS_VALUES_INSERT', 1);
      PKG_PROC_BROKER.GET_PARAM_NUM(0, 'NRN', ntemp);
      PKG_PROC_BROKER.EPILOGUE;
    exception
      when others then
        PKG_PROC_BROKER.EPILOGUE;
        raise;
    end;
  end;
begin

  find_extra_dict_by_code(0, nCOMPANY, sDictCode, nDictCode, ntemp, ntemp, ntemp, ntemp, stemp);
  find_filelinks_code(0, nCompany, sFileCode, nFileCode, ntemp, stemp, stemp, dtemp, ntemp);
  delete from TP_LOAD_KONS;
  i := 1; -- Позиция с которой вырезаем
  for c in (select dbms_lob.getlength(t.bdata) a, --
                   t.bdata
              from filelinks t
             where rn = nFileCode) loop
    while (i < c.a) loop
      d := utl_raw.cast_to_varchar2(dbms_lob.substr(c.bdata, 77, i)); -- Берем строку (77 символов)
      if (substr(d, 1, 1) = '¦') then
        insert into TP_LOAD_KONS
          (rn, data, num, text, code) --
        values
          (gen_id, d, trim(substr(d, 2, 3)), trim(substr(d, 6, 57)), trim(substr(d, 64, 11)));
      end if;
      i := i + 77;
    end loop;
  end loop;
  delete from TP_LOAD_KONS t where t.num in ('N', 'п/п'); -- Удаляем заголовок
  -- Объединяем строки одного блока в одну строку:
  for c in (select rownum, a.* from (select * from TP_LOAD_KONS a order by rn) a) loop
    if c.num is not null then
      if (c.rownum <> 1) then
        InsertLine(); -- Добавляем в доп.словарь
      end if;
      sName := c.text;
      sCode := c.code;
      sNPP  := c.num;
    else
      sName := sName || ' ' || c.text;
      sCode := sCode || ' ' || c.code;
    end if;
  end loop;
  commit;
end PP_LOAD_KONS_NOMN;
/*create public synonym PP_LOAD_KONS_NOMN for PP_LOAD_KONS_NOMN;
  grant execute on PP_LOAD_KONS_NOMN to public;*/
/
