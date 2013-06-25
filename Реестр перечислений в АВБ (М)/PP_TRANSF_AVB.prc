create or replace procedure PP_TRANSF_AVB
/*
   * Выгрузка перечислений в "АвтоВазБанк" для Мэрии г.о. Тольятти
   * Гончаренко Павел, 17.09.2012 г.
  **/
(nCOMPANY   in number,
 nIDENT     in number,
 nTYPE      in number, -- 1 - АВБ, 2 - ГБ
 sBANK      in varchar2,
 sEXECUTIVE in varchar2,
 nMODE      in number, -- Режим печати
 nOUTIDENT  out number -- Идентификатор файлов выгрузки
 ) is
  i           number;
  sSUMM       VARCHAR2(250);
  cCLOB       CLOB;
  sFILENAME   VARCHAR2(100);
  sREESTR_NUM number;
  sTYPE       varchar2(3);
  sDM         varchar2(2) := chr(9);
  /**
   * Курсор основного запроса:
  **/
  cursor a(nIDEnT in number) is
    select a.*, --
           rownum,
           sum(a.transfsumm) over() nallsumm
      from (select aa.agnacc, --
                   ar.agnfamilyname,
                   ar.agnfirstname,
                   ar.agnlastname,
                   ar.agnfamilyname || ' ' || ar.agnfirstname || ' ' || ar.agnlastname sFIO,
                   st.transfsumm
              from sltransfers st, --
                   agnacc      aa,
                   agnlist     ar
             where aa.rn = st.bankattrs
               and ar.rn = st.recipient
               and st.rn in (select document from selectlist where ident = nIDENT)
             order by 2, 3, 4) a;

  /**
   * Инициализация Excel
  **/
  procedure init is
    i number;
  begin
    if nTYPE = 1 then
      prsg_excel.PREPARE;
      prsg_excel.SHEET_SELECT('Лист1');
      prsg_excel.LINE_DESCRIBE('Строка');
      for i in 1 .. 6 loop
        prsg_excel.LINE_CELL_DESCRIBE('Строка', 'Д' || i);
      end loop;
      prsg_excel.CELL_DESCRIBE('Реестр');
      prsg_excel.CELL_DESCRIBE('КВыдаче');
      prsg_excel.CELL_DESCRIBE('Исполнитель');
    end if;
    if nType = 2 then
      prsg_excel.SHEET_SELECT('Лист2');
      prsg_excel.LINE_DESCRIBE('Строка2');
      for i in 1 .. 4 loop
        prsg_excel.LINE_CELL_DESCRIBE('Строка2', 'Е' || i);
      end loop;
      prsg_excel.CELL_DESCRIBE('Реестр2');
      prsg_excel.CELL_DESCRIBE('РеестрДата');
      prsg_excel.CELL_DESCRIBE('Сумма2');
      prsg_excel.CELL_DESCRIBE('Исполнитель2');
    end if;
  end;

  /**
   * Деинициализация Excel
  **/
  procedure fini is
  begin
    if nTYPE = 1 then
      prsg_excel.LINE_DELETE('Строка');
      prsg_excel.SHEET_DELETE('Лист2');
    end if;
    if nTYPE = 2 then
      prsg_excel.LINE_DELETE('Строка2');
      prsg_excel.SHEET_DELETE('Лист1');
    end if;
  end;

  /**
   * Порядковый номер реестра
  **/
  function reestr_number
  --
  (nTYPE in number) return number is
    Result number;
  begin
    update TP_TRANSF_NUM t
       set t.reestr_number = t.reestr_number + 1
     where t.reestr_type = nTYPE
       and t.reestr_year = to_char(sysdate, 'yyyy')
    returning reestr_number into Result;
    if sql%notfound then
      Result := 1;
      insert into TP_TRANSF_NUM (reestr_number, reestr_type, reestr_year) values (1, nTYPE, to_char(sysdate, 'yyyy'));
    end if;
    return Result;
  end;

  function tocp866
  --
  (sSTRING in varchar2) return varchar2 is
  begin
    --return convert(sSTRING, 'RU8PC866', 'CL8MSWIN1251');
    return sSTRING;
  end;

begin
  sREESTR_NUM := reestr_number(nTYPE);
  /**
   * Формирование отчета EXCEL:
  **/
  if nMODE <> 1 then
    init;
    i := null;
    for c in a(nIDENT) loop
      if nTYPE = 1 then
        if i is null then
          i := prsg_excel.LINE_APPEND('Строка');
          prsg_excel.CELL_VALUE_WRITE('Реестр', 'РЕЕСТР № ' || sREESTR_NUM || ' от ' || to_char(sysdate, 'dd.mm.yyyy') || ' г.');
          p_money_sum_str(nCOMPANY, c.nallsumm, null, sSUMM);
          prsg_excel.CELL_VALUE_WRITE('КВыдаче', sSUMM);
          prsg_excel.CELL_VALUE_WRITE('Исполнитель', sEXECUTIVE);
        else
          i := prsg_excel.LINE_CONTINUE('Строка');
        end if;
        prsg_excel.CELL_VALUE_WRITE('Д1', 0, i, c.rownum);
        prsg_excel.CELL_VALUE_WRITE('Д2', 0, i, c.agnacc);
        prsg_excel.CELL_VALUE_WRITE('Д3', 0, i, c.agnfamilyname);
        prsg_excel.CELL_VALUE_WRITE('Д4', 0, i, c.agnfirstname);
        prsg_excel.CELL_VALUE_WRITE('Д5', 0, i, c.agnlastname);
        prsg_excel.CELL_VALUE_WRITE('Д6', 0, i, c.transfsumm * 100);
      end if;
      if nTYPE = 2 then
        if i is null then
          i := prsg_excel.LINE_APPEND('Строка2');
          prsg_excel.CELL_VALUE_WRITE('Реестр2', 'Реестр № ' || sREESTR_NUM);
          prsg_excel.CELL_VALUE_WRITE('РеестрДата', 'от ' || to_char(sysdate, 'dd.mm.yyyy') || ' г.');
          p_money_sum_str(nCOMPANY, c.nallsumm, null, sSUMM);
          prsg_excel.CELL_VALUE_WRITE('Сумма2', c.nallsumm || ' (' || sSUMM || ')');
          prsg_excel.CELL_VALUE_WRITE('Исполнитель2', sEXECUTIVE);
        else
          i := prsg_excel.LINE_CONTINUE('Строка2');
        end if;
        prsg_excel.CELL_VALUE_WRITE('Е1', 0, i, c.rownum);
        prsg_excel.CELL_VALUE_WRITE('Е2', 0, i, c.agnacc);
        prsg_excel.CELL_VALUE_WRITE('Е3', 0, i, c.sFIO);
        prsg_excel.CELL_VALUE_WRITE('Е4', 0, i, c.transfsumm);
      end if;
    end loop;
    fini;
  end if;

  /**
   * Формирование выгрузки в файл:
  **/
  if nMODE <> 0 then
    if nTYPE = 1 then
      sTYPE := 'АВБ';
    end if;
    if nTYPE = 2 then
      sTYPE := 'ГЭБ';
    end if;
    nOUTIDENT := GEN_IDENT;
    dbms_lob.createtemporary(cCLOB, True, dbms_lob.CALL);
    sFILENAME := 'Реестр ' || sTYPE || ' ' || sREESTR_NUM || '.txt';
    for c in a(nIDENT) loop
      if nTYPE = 1 then
        dbms_lob.append(cCLOB,
                        rpad(trim(c.rownum), 6, ' ') || --
                        rpad(c.agnacc, 21, ' ') || --
                        rpad(tocp866(upper(c.agnfamilyname)), 31, ' ') || --
                        rpad(tocp866(upper(c.agnfirstname)), 17, ' ') || --
                        rpad(tocp866(upper(c.agnlastname)), 22, ' ') || --
                        lpad(trim(to_char(c.transfsumm * 100)), 11, ' ') || --
                        chr(13) || chr(10));
      end if;
      if nTYPE = 2 then
        dbms_lob.append(cCLOB,
                        rpad(c.agnacc, 25, ' ') || -- 
                        lpad(replace(trim(to_char(c.transfsumm)), ',', '.'), 13, ' ') || --
                        ' ' || tocp866(c.sfio) || --
                        chr(13) || chr(10));
      end if;
    end loop;
    insert into FILE_BUFFER
      (IDENT, FILENAME, DATA) --
    values
      (nOUTIDENT, sFILENAME, cCLOB);
    dbms_lob.trim(cCLOB, 0);
  end if;
end PP_TRANSF_AVB;
/
