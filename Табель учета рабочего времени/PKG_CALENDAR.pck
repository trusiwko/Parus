create or replace package PKG_CALENDAR
as
  -- ����������� ���������� ����� �� ��������� �� �������� ���������
  procedure GET_HOURS
  (
    nCOMPANY     in  number,
    nSCHEDULE    in  number,     -- ������ ������
    dBGN         in  date,       -- ������ �������
    dEND         in  date,       -- ��������� �������
    sPARAMS      in  varchar2,   -- �������������� ��������� ��� ������ �� ���� �����
    nHOURS       out number      -- ���������� �����
  );

  -- ����������� ���������� ���� �� ��������� �� �������� ���������
  procedure GET_DAYS
  (
    nCOMPANY     in  number,
    nSCHEDULE    in  number,     -- ������ ������
    dBGN         in  date,       -- ������ �������
    dEND         in  date,       -- ��������� �������
    sPARAMS      in  varchar2,   -- �������������� ��������� ��� ������ �� ���� �����
    nDAYS        out number      -- ���������� ����
  );

  -- ����������� ���������� ����/�����
  procedure GET_VALUE
  (
    nCOMPANY     in  number,
    nTYPE        in  number,     -- ��� ����� ������� (0 - ����, 1 - ���)
    nSCHEDULE    in  number,     -- ������ ������
    dBGN         in  date,       -- ������ �������
    dEND         in  date,       -- ��������� �������
    sPARAMS      in  varchar2,   -- �������������� ��������� ��� ������ �� ���� �����
    nVALUE       out number      -- ���������� ����/�����
  );

  -- ����������� ���� ��������� ��������� ��������� �� ���������
  procedure GET_DATE
  (
    nCOMPANY     in  number,
    sSCHEDULE    in  varchar2,   -- �������� ������� ������ (�������� ���� ��������, ���� RN)
    nSCHEDULE    in  number,     -- RN ������� ������
    nTIMESORT    in  number,     -- ������� ����� ��� (0 - � �����, 1 - � ����)
    dBGN         in  date,       -- ������ �������
    nDAYS        in  number,     -- ���������� ����/�����
    dEND         out date        -- ��������� �������
  );
end PKG_CALENDAR;
/
create or replace package body PKG_CALENDAR
as
  function PARSE_PARAMS
  (
    sPARAMS      in varchar2     -- �������������� ��������� ��� ������ �� ���� �����
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

  -- ����������� ���������� ����� �� ��������� �� �������� ���������
  procedure GET_HOURS
  (
    nCOMPANY     in  number,
    nSCHEDULE    in  number,     -- ������ ������
    dBGN         in  date,       -- ������ �������
    dEND         in  date,       -- ��������� �������
    sPARAMS      in  varchar2,   -- �������������� ��������� ��� ������ �� ���� �����
    nHOURS       out number      -- ���������� �����
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

  -- ����������� ���������� ���� �� ��������� �� �������� ���������
  procedure GET_DAYS
  (
    nCOMPANY     in  number,
    nSCHEDULE    in  number,     -- ������ ������
    dBGN         in  date,       -- ������ �������
    dEND         in  date,       -- ��������� �������
    sPARAMS      in  varchar2,   -- �������������� ��������� ��� ������ �� ���� �����
    nDAYS        out number      -- ���������� ����
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

  -- ����������� ���������� ����/�����
  procedure GET_VALUE
  (
    nCOMPANY     in  number,
     nTYPE        in  number,     -- ��� ����� ������� (0 - ����, 1 - ���)
    nSCHEDULE    in  number,     -- ������ ������
    dBGN         in  date,       -- ������ �������
    dEND         in  date,       -- ��������� �������
    sPARAMS      in  varchar2,   -- �������������� ��������� ��� ������ �� ���� �����
    nVALUE       out number      -- ���������� ����/�����
  )
  as
  begin
    if nTYPE = 0 then
      GET_HOURS(nCOMPANY, nSCHEDULE, dBGN, dEND, sPARAMS, nVALUE);
    else
      GET_DAYS(nCOMPANY, nSCHEDULE, dBGN, dEND, sPARAMS, nVALUE);
    end if;
  end GET_VALUE;

  -- ����������� ���� ��������� ��������� ��������� �� ���������
  procedure GET_DATE
  (
    nCOMPANY     in  number,
    sSCHEDULE    in  varchar2,   -- �������� ������� ������ (�������� ���� ��������, ���� RN)
    nSCHEDULE    in  number,     -- RN ������� ������
    nTIMESORT    in  number,     -- ������� ����� ��� (0 - � �����, 1 - � ����)
    dBGN         in  date,       -- ������ �������
    nDAYS        in  number,     -- ���������� ����/�����
    dEND         out date        -- ��������� �������
  )
  as
    nSCHED_RN    PKG_STD.tREF;
    nCUR_LEN     PKG_STD.tLNUMBER;
    dCUR_SDATE   PKG_STD.tLDATE;
    dSDATE       PKG_STD.tLDATE;
    nCALENDAR    PKG_STD.tNUMBER;
    nTMPDAYS     WORKDAYS.DAYS%TYPE;
  begin
    /* ��������� ������������� */
    dEND     := dBGN;
    nCUR_LEN := 0;
    /* ���� ������ ����� */
    if rtrim(sSCHEDULE) is not null then
      FIND_SLSCHEDULE_CODE( 0, 0, nCOMPANY, sSCHEDULE, nSCHED_RN );
    else
      nSCHED_RN := nSCHEDULE;
    end if;
    /* ��������� ���� ������ ������� */
    if dBGN is not null then
      dCUR_SDATE := INT2DATE(1, D_MONTH(dBGN), D_YEAR(dBGN));
      /* ���� �� ��������� ������� ����� */
      loop
        /* �������� ������� ������ �� ����� */
        if (nCUR_LEN >= nDAYS) then exit; end if;
        /* ����������� ���� ������ */
        dSDATE := Greatest(dCUR_SDATE,dBGN);
        /* ��������� ������� ��������� �� ������� ����� (������ ���� ������ ����) */
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
        /* ���� ����� ��������� - ����� ����������� ������� �� ���� */
        if nCALENDAR is not null then
          /* ��������� ������� */
          for CDH in ( select D.DAYS, DS.HOURSNORM
                         from WORKDAYS        D,
                              WORKDAYSTR      DS,
                              SL_HOURS_TYPES  HT
                        where D.PRN         =  nCALENDAR
                          and D.DAYS        >= D_DAY(dSDATE)
                          and D.RN          =  DS.PRN
                          and DS.HOURSNORM  > 0              -- �������������� ���� �� ���������
                          and DS.HOURSTYPES =  HT.RN
                          and HT.BASE_SIGN  =  1             -- �������� �������� ����
                        order by D.DAYS )
            loop
            /* ��������� �������� ���� ��� */
            if (NVL(nTIMESORT,1) = 1) then   -- ���� ��� � ����
              if CDH.DAYS <> nTMPDAYS then   -- ���� ���� ��������� ���� ���
                 nCUR_LEN := nCUR_LEN + 1;
                 nTMPDAYS := CDH.DAYS;
              end if;
            else -- ���� ��� � �����
              nCUR_LEN := nCUR_LEN + CDH.HOURSNORM;
            end if;
            /* ��������� ������������ �������� */
            if (nCUR_LEN >= nDAYS) then
              dEND := dCUR_SDATE + CDH.DAYS - 1;
              exit; -- ������� �� ����� �����
            end if;
          end loop;
          /* ��������� � ���������� ������, ���� � ���� �� ��������� ���������� ������� */
          dCUR_SDATE := add_months(dCUR_SDATE,1);
        else -- ��������� ���, ����� ���������� ���� ������ � �������
          dEND     := dSDATE;
          nCUR_LEN := nDAYS;
        end if;
      end loop;
    end if;
  end GET_DATE;
end PKG_CALENDAR;
/
