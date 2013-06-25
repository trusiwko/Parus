create or replace package PKG_CALENDAR
as
  -- Определение количества часов по календарю на заданном интервале
  procedure GET_HOURS
  (
    nCOMPANY     in  number,
    nSCHEDULE    in  number,     -- график работы
    dBGN         in  date,       -- начало периода
    dEND         in  date,       -- окончание периода
    sPARAMS      in  varchar2,   -- дополнительные параметры для отбора по типу часов
    nHOURS       out number      -- количество часов
  );

  -- Определение количества дней по календарю на заданном интервале
  procedure GET_DAYS
  (
    nCOMPANY     in  number,
    nSCHEDULE    in  number,     -- график работы
    dBGN         in  date,       -- начало периода
    dEND         in  date,       -- окончание периода
    sPARAMS      in  varchar2,   -- дополнительные параметры для отбора по типу часов
    nDAYS        out number      -- количество дней
  );

  -- Определение количества дней/часов
  procedure GET_VALUE
  (
    nCOMPANY     in  number,
    nTYPE        in  number,     -- вид учета времени (0 - часы, 1 - дни)
    nSCHEDULE    in  number,     -- график работы
    dBGN         in  date,       -- начало периода
    dEND         in  date,       -- окончание периода
    sPARAMS      in  varchar2,   -- дополнительные параметры для отбора по типу часов
    nVALUE       out number      -- количество дней/часов
  );

  -- Определение даты окончания заданного интервала по календарю
  procedure GET_DATE
  (
    nCOMPANY     in  number,
    sSCHEDULE    in  varchar2,   -- мнемокод графика работы (задается либо мнемокод, либо RN)
    nSCHEDULE    in  number,     -- RN графика работы
    nTIMESORT    in  number,     -- единица учета ФОВ (0 - в часах, 1 - в днях)
    dBGN         in  date,       -- начало периода
    nDAYS        in  number,     -- количество дней/часов
    dEND         out date        -- окончание периода
  );
end PKG_CALENDAR;
/
create or replace package body PKG_CALENDAR
as
  function PARSE_PARAMS
  (
    sPARAMS      in varchar2     -- дополнительные параметры для отбора по типу часов
  )
  return varchar2
  as
    sRESULT      varchar2( 2000 ) := sPARAMS;
  begin
    sRESULT := replace(sRESULT, 'MH()', 'HT.BASE_SIGN = 1');
    sRESULT := replace(sRESULT, 'TH(', 'HT.SHORT_CODE in (');
    sRESULT := trim(sRESULT);
    return sRESULT;
  end PARSE_PARAMS;

  -- Определение количества часов по календарю на заданном интервале
  procedure GET_HOURS
  (
    nCOMPANY     in  number,
    nSCHEDULE    in  number,     -- график работы
    dBGN         in  date,       -- начало периода
    dEND         in  date,       -- окончание периода
    sPARAMS      in  varchar2,   -- дополнительные параметры для отбора по типу часов
    nHOURS       out number      -- количество часов
  )
  as
    nBGN         number( 2 );
    nEND         number( 2 );
    sSQL         varchar2( 2000 );
    sWHERE       varchar2( 2000 );
    nSUM         PKG_STD.tSUMM;
  begin
    nHOURS := 0;

    if nSCHEDULE is null then
      return;
    end if;

    sWHERE := PARSE_PARAMS(sPARAMS);
    for CUR in
    (
      select
        RN, STARTDATE, ENDDATE
      from
        ENPERIOD
      where COMPANY = nCOMPANY
        and SCHEDULE = nSCHEDULE
        and STARTDATE <= dEND
        and ENDDATE >= dBGN
    )
    loop
      nBGN := D_DAY(greatest(CUR.STARTDATE, dBGN));
      nEND := D_DAY(least(CUR.ENDDATE, dEND));

      sSQL := '
        select nvl(sum(H.HOURSNORM), 0)
          from
            WORKDAYS D,
            WORKDAYSTR H,
            SL_HOURS_TYPES HT
          where D.PRN = :nRN
            and D.DAYS between :nBGN and :nEND
            and D.RN = H.PRN
            and H.HOURSTYPES = HT.RN';

      if sWHERE is not null then
        sSQL := sSQL || ' and (' || sWHERE || ')';
      end if;

      begin
        execute immediate sSQL into nSUM using CUR.RN, nBGN, nEND;
      exception
        when OTHERS then
          nSUM := 0;
      end;

      nHOURS := nHOURS + nSUM;
    end loop;
  end GET_HOURS;

  -- Определение количества дней по календарю на заданном интервале
  procedure GET_DAYS
  (
    nCOMPANY     in  number,
    nSCHEDULE    in  number,     -- график работы
    dBGN         in  date,       -- начало периода
    dEND         in  date,       -- окончание периода
    sPARAMS      in  varchar2,   -- дополнительные параметры для отбора по типу часов
    nDAYS        out number      -- количество дней
  )
  as
    nBGN         number( 2 );
    nEND         number( 2 );
    sSUBSQL      varchar2( 2000 );
    sWHERE       varchar2( 2000 );
    sSQL         varchar2( 2000 );
    nCNT         PKG_STD.tNUMBER;
  begin
    nDAYS := 0;

    if nSCHEDULE is null then
      return;
    end if;

    sWHERE := PARSE_PARAMS(sPARAMS);
    for CUR in
    (
      select
        RN, STARTDATE, ENDDATE
      from
        ENPERIOD
      where COMPANY = nCOMPANY
        and SCHEDULE = nSCHEDULE
        and STARTDATE <= dEND
        and ENDDATE >= dBGN
    )
    loop
      nBGN := D_DAY(greatest(CUR.STARTDATE, dBGN));
      nEND := D_DAY(least(CUR.ENDDATE, dEND));

      sSUBSQL := '
        select H.RN
          from
            WORKDAYSTR H,
            SL_HOURS_TYPES HT
          where H.PRN = D.RN
            and H.HOURSNORM > 0
            and H.HOURSTYPES = HT.RN';

      if sWHERE is not null then
        sSUBSQL := sSUBSQL || ' and (' || sWHERE || ')';
      end if;

      sSQL := '
        select
          count(*)
        from
          WORKDAYS D
        where D.PRN = :nRN
          and D.DAYS between :nBGN and :nEND
          and exists (' || sSUBSQL || ')';

      begin
        execute immediate sSQL into nCNT using CUR.RN, nBGN, nEND;
      exception
        when OTHERS then
          nCNT := 0;
      end;

      nDAYS := nDAYS + nCNT;
    end loop;
  end GET_DAYS;

  -- Определение количества дней/часов
  procedure GET_VALUE
  (
    nCOMPANY     in  number,
     nTYPE        in  number,     -- вид учета времени (0 - часы, 1 - дни)
    nSCHEDULE    in  number,     -- график работы
    dBGN         in  date,       -- начало периода
    dEND         in  date,       -- окончание периода
    sPARAMS      in  varchar2,   -- дополнительные параметры для отбора по типу часов
    nVALUE       out number      -- количество дней/часов
  )
  as
  begin
    if nTYPE = 0 then
      GET_HOURS(nCOMPANY, nSCHEDULE, dBGN, dEND, sPARAMS, nVALUE);
    else
      GET_DAYS(nCOMPANY, nSCHEDULE, dBGN, dEND, sPARAMS, nVALUE);
    end if;
  end GET_VALUE;

  -- Определение даты окончания заданного интервала по календарю
  procedure GET_DATE
  (
    nCOMPANY     in  number,
    sSCHEDULE    in  varchar2,   -- мнемокод графика работы (задается либо мнемокод, либо RN)
    nSCHEDULE    in  number,     -- RN графика работы
    nTIMESORT    in  number,     -- единица учета ФОВ (0 - в часах, 1 - в днях)
    dBGN         in  date,       -- начало периода
    nDAYS        in  number,     -- количество дней/часов
    dEND         out date        -- окончание периода
  )
  as
    nSCHED_RN    PKG_STD.tREF;
    nCUR_LEN     PKG_STD.tLNUMBER;
    dCUR_SDATE   PKG_STD.tLDATE;
    dSDATE       PKG_STD.tLDATE;
    nCALENDAR    PKG_STD.tNUMBER;
    nTMPDAYS     WORKDAYS.DAYS%TYPE;
  begin
    /* начальная инициализация */
    dEND     := dBGN;
    nCUR_LEN := 0;
    /* ищем график работ */
    if rtrim(sSCHEDULE) is not null then
      FIND_SLSCHEDULE_CODE( 0, 0, nCOMPANY, sSCHEDULE, nSCHED_RN );
    else
      nSCHED_RN := nSCHEDULE;
    end if;
    /* проверяем дату начала периода */
    if dBGN is not null then
      dCUR_SDATE := INT2DATE(1, D_MONTH(dBGN), D_YEAR(dBGN));
      /* цикл по календарю графика работ */
      loop
        /* проверка условия выхода из цикла */
        if (nCUR_LEN >= nDAYS) then exit; end if;
        /* расчитываем дату начала */
        dSDATE := Greatest(dCUR_SDATE,dBGN);
        /* проверяем наличие календаря по графику работ (должен быть только один) */
        begin
          select RN into nCALENDAR
            from ENPERIOD
           where COMPANY   =  nCOMPANY
             and SCHEDULE  =  nSCHED_RN
             and STARTDATE <= dCUR_SDATE
             and ENDDATE   >= dCUR_SDATE
             and rownum = 1;
        exception
          when NO_DATA_FOUND then
            nCALENDAR := null;
        end;
        nTMPDAYS := 0;
        /* если нашли календарь - будем формировать выборку по нему */
        if nCALENDAR is not null then
          /* формируем выборку */
          for CDH in ( select D.DAYS, DS.HOURSNORM
                         from WORKDAYS        D,
                              WORKDAYSTR      DS,
                              SL_HOURS_TYPES  HT
                        where D.PRN         =  nCALENDAR
                          and D.DAYS        >= D_DAY(dSDATE)
                          and D.RN          =  DS.PRN
                          and DS.HOURSNORM  > 0              -- отритцательные часы не учитываем
                          and DS.HOURSTYPES =  HT.RN
                          and HT.BASE_SIGN  =  1             -- отбираем основные часы
                        order by D.DAYS )
            loop
            /* учитываем основные часы дня */
            if (NVL(nTIMESORT,1) = 1) then   -- учет ФОВ в днях
              if CDH.DAYS <> nTMPDAYS then   -- один день учитываем один раз
                 nCUR_LEN := nCUR_LEN + 1;
                 nTMPDAYS := CDH.DAYS;
              end if;
            else -- учет ФОВ в часах
              nCUR_LEN := nCUR_LEN + CDH.HOURSNORM;
            end if;
            /* проверяем накопившийся интервал */
            if (nCUR_LEN >= nDAYS) then
              dEND := dCUR_SDATE + CDH.DAYS - 1;
              exit; -- выходим из этого цикла
            end if;
          end loop;
          /* переходим к следующему месяцу, если в этом не набралось требуемого времени */
          dCUR_SDATE := add_months(dCUR_SDATE,1);
        else -- календаря нет, берем расчитаную дату начала и выходим
          dEND     := dSDATE;
          nCUR_LEN := nDAYS;
        end if;
      end loop;
    end if;
  end GET_DATE;
end PKG_CALENDAR;
/
