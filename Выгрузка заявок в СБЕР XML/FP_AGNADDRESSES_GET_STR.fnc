create or replace function FP_AGNADDRESSES_GET_STR
--
(nAGNLISTRN in number, -- регистрационный номер контрагента
 nTYPEADDR  in number, -- Тип адреса:
 --   0 - основной,
 --   1 - юридический,
 --   2 - реального проживания,
 --   3 - почтового перевода,
 --   4 - временной регистрации,
 --   5 - рождени
 sFORMAT in varchar2 -- Флаги форматирования. Флаги состоят из букв, кажда
 -- определяет наличие в строке определенного
 -- геогр. понятия.
 --   P - индекс, H - дом,
 --   B - корпус, L - строение,
 --   F - квартира, C - страна,
 --   R - регион, D - район,
 --   Y - город, T - населенный пункт,
 --   S - улица, O - код страны,
 --   A - код ОКАТО страны
 ) return varchar2 as
  sADDRESS    varchar2(1000);
  rADDR       AGNADDRESSES%rowtype;
  sREG        GEOGRAFY.GEOGRNAME%type;
  sREG_T      LOCALITYTYPE.NAME%type;
  sDISTRICT   GEOGRAFY.GEOGRNAME%type;
  sDISTRICT_T LOCALITYTYPE.NAME%type;
  sCITY       GEOGRAFY.GEOGRNAME%type;
  sCITY_T     LOCALITYTYPE.NAME%type;
  sTOWN       GEOGRAFY.GEOGRNAME%type;
  sTOWN_T     LOCALITYTYPE.NAME%type;
  sSTREET     GEOGRAFY.GEOGRNAME%type;
  sSTREET_T   LOCALITYTYPE.NAME%type;
  sCOUNTRY    GEOGRAFY.GEOGRNAME%type;
  sCOUNTRY_C  GEOGRAFY.CODE%type;
  sCOUNTRY_O  GEOGRAFY.OKATO%type;

begin
  sADDRESS := sFORMAT;

  -- выборка записи в зависимости от типа адреса
  begin
    if nTYPEADDR = 0 then
      -- основной
      select *
        into rADDR
        from AGNADDRESSES
       where PRN = nAGNLISTRN
         and PRIMARY_SIGN = 1
         and rownum < 2;
    elsif nTYPEADDR = 1 then
      -- юридический
      select *
        into rADDR
        from AGNADDRESSES
       where PRN = nAGNLISTRN
         and LEGAL_SIGN = 1
         and rownum < 2;
    elsif nTYPEADDR = 2 then
      -- реального проживания
      select *
        into rADDR
        from AGNADDRESSES
       where PRN = nAGNLISTRN
         and REAL_SIGN = 1
         and rownum < 2;
    elsif nTYPEADDR = 3 then
      -- почтового перевода
      select *
        into rADDR
        from AGNADDRESSES
       where PRN = nAGNLISTRN
         and MAIL_SIGN = 1
         and rownum < 2;
    elsif nTYPEADDR = 4 then
      -- временной регистрации
      select *
        into rADDR
        from AGNADDRESSES
       where PRN = nAGNLISTRN
         and REGISTRATION_SIGN = 1
         and rownum < 2;
    elsif nTYPEADDR = 5 then
      -- рождения
      select *
        into rADDR
        from AGNADDRESSES
       where PRN = nAGNLISTRN
         and BIRTH_SIGN = 1
         and rownum < 2;
    else
      return null;
    end if;
  exception
    when NO_DATA_FOUND then
      return null;
  end;

  -- раскручиваем геогр. понятия в обратную сторону (из подчиненного - вверх)
  for rREC in (select A.GEOGRNAME, --
                      A.GTYPE,
                      A.CODE,
                      A.OKATO,
                      nvl(B.NAME, ' ') NAME
                 from (select GEOGRNAME, --
                              to_number(GEOGRTYPE) GTYPE,
                              CODE,
                              OKATO,
                              LOCALITYKIND
                         from GEOGRAFY
                        start with RN = rADDR.GEOGRAFY_RN
                       connect by prior PRN = RN) A,
                      LOCALITYTYPE B
                where A.LOCALITYKIND = B.RN(+)) loop
    if rREC.GTYPE = 1 then
      -- Страна
      sCOUNTRY   := rREC.GEOGRNAME;
      sCOUNTRY_C := rREC.CODE;
      sCOUNTRY_O := rREC.OKATO;
    elsif rREC.GTYPE = 2 then
      -- Регион
      sREG   := rREC.GEOGRNAME;
      sREG_T := rREC.NAME;
    elsif rREC.GTYPE = 3 then
      -- Район
      sDISTRICT   := rREC.GEOGRNAME;
      sDISTRICT_T := rREC.NAME;
    elsif rREC.GTYPE = 4 then
      -- Населенный пункт
      sTOWN   := rREC.GEOGRNAME;
      sTOWN_T := rREC.NAME;
    elsif rREC.GTYPE = 5 then
      -- Улица
      sSTREET   := rREC.GEOGRNAME;
      sSTREET_T := rREC.NAME;
    elsif rREC.GTYPE = 8 then
      -- город
      sCITY   := rREC.GEOGRNAME;
      sCITY_T := lower(rREC.NAME);
    end if;
  end loop;

  /* Формирование строки */
  -- Страна
  sADDRESS := replace(sADDRESS, 'C', sCOUNTRY);
  -- Код страны
  sADDRESS := replace(sADDRESS, 'O', sCOUNTRY_C);
  -- Код ОКАТО страны
  sADDRESS := replace(sADDRESS, 'A', sCOUNTRY_O);
  -- Почтовый индекс
  sADDRESS := replace(sADDRESS, 'P', rADDR.ADDR_POST);
  -- регион
  sADDRESS := replace(sADDRESS, 'R', sREG);
  sADDRESS := replace(sADDRESS, 'r', sREG_T);
  -- район
  sADDRESS := replace(sADDRESS, 'D', sDISTRICT);
  sADDRESS := replace(sADDRESS, 'd', sDISTRICT_T);
  -- город
  sADDRESS := replace(sADDRESS, 'Y', sCITY);
  sADDRESS := replace(sADDRESS, 'y', sCITY_T);
  -- нас. пункт
  sADDRESS := replace(sADDRESS, 'T', sTOWN);
  sADDRESS := replace(sADDRESS, 't', sTOWN_T);
  -- улица
  sADDRESS := replace(sADDRESS, 'S', sSTREET);
  sADDRESS := replace(sADDRESS, 's', sSTREET_T);
  -- дом
  sADDRESS := replace(sADDRESS, 'H', rADDR.ADDR_HOUSE);
  -- корпус
  sADDRESS := replace(sADDRESS, 'B', rADDR.ADDR_BLOCK);
  -- строение
  sADDRESS := replace(sADDRESS, 'L', rADDR.ADDR_BUILDING);
  -- квартира
  sADDRESS := replace(sADDRESS, 'F', rADDR.ADDR_FLAT);
  return sADDRESS;
end;
/
