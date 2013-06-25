create or replace package PKG_WRK
as
  -- ����������� ���������� �����
  procedure GET_HOURS
  (
    nPERFORM     in  number,     -- ����������
    dBGN         in  date,       -- ������ �������
    dEND         in  date,       -- ��������� �������
    sPARAMS      in  varchar2,   -- �������������� ��������� ��� ������ �� ���� �����
    nHOURS       out number      -- ���������� �����
  );

  -- ����������� ���������� ����
  procedure GET_DAYS
  (
    nPERFORM     in  number,     -- ����������
    dBGN         in  date,       -- ������ �������
    dEND         in  date,       -- ��������� �������
    sPARAMS      in  varchar2,   -- �������������� ��������� ��� ������ �� ���� �����
    nDAYS        out number      -- ���������� ����
  );

  -- ����������� ���������� ����/�����
  procedure GET_VALUE
  (
    nTYPE        in  number,     -- ��� ����� ������� (0 - ����, 1 - ���)
    nPERFORM     in  number,     -- ����������
    dBGN         in  date,       -- ������ �������
    dEND         in  date,       -- ��������� �������
    sPARAMS      in  varchar2,   -- �������������� ��������� ��� ������ �� ���� �����
    nVALUE       out number      -- ���������� ����/�����
  );
end PKG_WRK;
/
create or replace package body PKG_WRK
as
  function PARSE_PARAMS
  (
    sPARAMS      in varchar2     -- �������������� ��������� ��� ������ �� ���� ����/�����
  )
  return varchar2
  as
    sRESULT      varchar2( 2000 ) := sPARAMS;
  begin
    sRESULT := replace(sRESULT, 'MH()', 'HT.BASE_SIGN = 1');
    sRESULT := replace(sRESULT, 'TH(', 'HT.SHORT_CODE in (');
    sRESULT := replace(sRESULT, 'TD(', 'DT.SHORT_CODE is not null and DT.SHORT_CODE in (');
    sRESULT := replace(sRESULT, 'DA()', '(DT.ABSENCE_SIGN is not null and DT.ABSENCE_SIGN = 1)');
    sRESULT := replace(sRESULT, 'HD()', 'IS_HOLIDAY(D.COMPANY, D.WORKDATE) = 1');
    sRESULT := trim(sRESULT);
    return sRESULT;
  end PARSE_PARAMS;

  -- ����������� ���������� �����
  procedure GET_HOURS
  (
    nPERFORM     in  number,     -- ����������
    dBGN         in  date,       -- ������ �������
    dEND         in  date,       -- ��������� �������
    sPARAMS      in  varchar2,   -- �������������� ��������� ��� ������ �� ���� �����
    nHOURS       out number      -- ���������� �����
  )
  as
    sSQL         varchar2( 2000 );
    sWHERE       varchar2( 2000 );
  begin
    sWHERE := PARSE_PARAMS(sPARAMS);

    sSQL := '
      select /*+ INDEX(D C_CLNPSPFMWD_WORKDATE_UK) INDEX(H I_CLNPSPFMWH_PRN_FK) */
        nvl(sum(H.WORKEDHOURS), 0)
      from
        CLNPSPFMWD     D,
        CLNPSPFMWH     H,
        SL_HOURS_TYPES HT,
        SLDAYSTYPE     DT
      where D.PRN = :nRN
        and D.WORKDATE between :dBGN and :dEND
        and D.RN = H.PRN
        and D.DAYSTYPE = DT.RN(+)
        and H.HOURSTYPE = HT.RN';

    if sWHERE is not null then
      sSQL := sSQL || ' and (' || sWHERE || ')';
    end if;

    begin
      execute immediate sSQL into nHOURS using nPERFORM, dBGN, dEND;
    exception
      when OTHERS then
        nHOURS := 0;
    end;
  end GET_HOURS;

  -- ����������� ���������� ����
  procedure GET_DAYS
  (
    nPERFORM     in  number,     -- ����������
    dBGN         in  date,       -- ������ �������
    dEND         in  date,       -- ��������� �������
    sPARAMS      in  varchar2,   -- �������������� ��������� ��� ������ �� ���� �����
    nDAYS        out number      -- ���������� ����
  )
  as
    sSUBSQL      varchar2( 2000 );
    sWHERE       varchar2( 2000 );
    sSQL         varchar2( 2000 );
  begin
    sWHERE := PARSE_PARAMS(sPARAMS);

    sSUBSQL := '
      select /*+ INDEX(H I_CLNPSPFMWH_PRN_FK) */
        H.RN
      from
        CLNPSPFMWD     D,
        CLNPSPFMWH     H,
        SL_HOURS_TYPES HT,
        SLDAYSTYPE     DT
      where D.RN = DAYS.RN
        and H.PRN = DAYS.RN
        and D.DAYSTYPE = DT.RN(+)
        and H.HOURSTYPE = HT.RN
        and H.WORKEDHOURS > 0';

    if sWHERE is not null then
      sSUBSQL := sSUBSQL || ' and (' || sWHERE || ')';
    end if;

    sSQL := '
      select
        count(*)
      from
        CLNPSPFMWD DAYS
      where DAYS.PRN = :nRN
        and DAYS.WORKDATE between :dBGN and :dEND
        and exists (' || sSUBSQL || ')';

    begin
      execute immediate sSQL into nDAYS using nPERFORM, dBGN, dEND;
    exception
      when OTHERS then
        nDAYS := 0;
    end;
  end GET_DAYS;

  -- ����������� ���������� ����/�����
  procedure GET_VALUE
  (
    nTYPE        in  number,     -- ��� ����� ������� (0 - ����, 1 - ���)
    nPERFORM     in  number,     -- ����������
    dBGN         in  date,       -- ������ �������
    dEND         in  date,       -- ��������� �������
    sPARAMS      in  varchar2,   -- �������������� ��������� ��� ������ �� ���� �����
    nVALUE       out number      -- ���������� ����/�����
  )
  as
  begin
    if nTYPE = 0 then
      PKG_WRK.GET_HOURS(nPERFORM, dBGN, dEND, sPARAMS, nVALUE);
    else
      PKG_WRK.GET_DAYS(nPERFORM, dBGN, dEND, sPARAMS, nVALUE);
    end if;
  end GET_VALUE;
end PKG_WRK;
/
