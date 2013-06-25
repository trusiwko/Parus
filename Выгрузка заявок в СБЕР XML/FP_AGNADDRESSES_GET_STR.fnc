create or replace function FP_AGNADDRESSES_GET_STR
--
(nAGNLISTRN in number, -- ��������������� ����� �����������
 nTYPEADDR  in number, -- ��� ������:
 --   0 - ��������,
 --   1 - �����������,
 --   2 - ��������� ����������,
 --   3 - ��������� ��������,
 --   4 - ��������� �����������,
 --   5 - �������
 sFORMAT in varchar2 -- ����� ��������������. ����� ������� �� ����, �����
 -- ���������� ������� � ������ �������������
 -- �����. �������.
 --   P - ������, H - ���,
 --   B - ������, L - ��������,
 --   F - ��������, C - ������,
 --   R - ������, D - �����,
 --   Y - �����, T - ���������� �����,
 --   S - �����, O - ��� ������,
 --   A - ��� ����� ������
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

  -- ������� ������ � ����������� �� ���� ������
  begin
    if nTYPEADDR = 0 then
      -- ��������
      select *
        into rADDR
        from AGNADDRESSES
       where PRN = nAGNLISTRN
         and PRIMARY_SIGN = 1
         and rownum < 2;
    elsif nTYPEADDR = 1 then
      -- �����������
      select *
        into rADDR
        from AGNADDRESSES
       where PRN = nAGNLISTRN
         and LEGAL_SIGN = 1
         and rownum < 2;
    elsif nTYPEADDR = 2 then
      -- ��������� ����������
      select *
        into rADDR
        from AGNADDRESSES
       where PRN = nAGNLISTRN
         and REAL_SIGN = 1
         and rownum < 2;
    elsif nTYPEADDR = 3 then
      -- ��������� ��������
      select *
        into rADDR
        from AGNADDRESSES
       where PRN = nAGNLISTRN
         and MAIL_SIGN = 1
         and rownum < 2;
    elsif nTYPEADDR = 4 then
      -- ��������� �����������
      select *
        into rADDR
        from AGNADDRESSES
       where PRN = nAGNLISTRN
         and REGISTRATION_SIGN = 1
         and rownum < 2;
    elsif nTYPEADDR = 5 then
      -- ��������
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

  -- ������������ �����. ������� � �������� ������� (�� ������������ - �����)
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
      -- ������
      sCOUNTRY   := rREC.GEOGRNAME;
      sCOUNTRY_C := rREC.CODE;
      sCOUNTRY_O := rREC.OKATO;
    elsif rREC.GTYPE = 2 then
      -- ������
      sREG   := rREC.GEOGRNAME;
      sREG_T := rREC.NAME;
    elsif rREC.GTYPE = 3 then
      -- �����
      sDISTRICT   := rREC.GEOGRNAME;
      sDISTRICT_T := rREC.NAME;
    elsif rREC.GTYPE = 4 then
      -- ���������� �����
      sTOWN   := rREC.GEOGRNAME;
      sTOWN_T := rREC.NAME;
    elsif rREC.GTYPE = 5 then
      -- �����
      sSTREET   := rREC.GEOGRNAME;
      sSTREET_T := rREC.NAME;
    elsif rREC.GTYPE = 8 then
      -- �����
      sCITY   := rREC.GEOGRNAME;
      sCITY_T := lower(rREC.NAME);
    end if;
  end loop;

  /* ������������ ������ */
  -- ������
  sADDRESS := replace(sADDRESS, 'C', sCOUNTRY);
  -- ��� ������
  sADDRESS := replace(sADDRESS, 'O', sCOUNTRY_C);
  -- ��� ����� ������
  sADDRESS := replace(sADDRESS, 'A', sCOUNTRY_O);
  -- �������� ������
  sADDRESS := replace(sADDRESS, 'P', rADDR.ADDR_POST);
  -- ������
  sADDRESS := replace(sADDRESS, 'R', sREG);
  sADDRESS := replace(sADDRESS, 'r', sREG_T);
  -- �����
  sADDRESS := replace(sADDRESS, 'D', sDISTRICT);
  sADDRESS := replace(sADDRESS, 'd', sDISTRICT_T);
  -- �����
  sADDRESS := replace(sADDRESS, 'Y', sCITY);
  sADDRESS := replace(sADDRESS, 'y', sCITY_T);
  -- ���. �����
  sADDRESS := replace(sADDRESS, 'T', sTOWN);
  sADDRESS := replace(sADDRESS, 't', sTOWN_T);
  -- �����
  sADDRESS := replace(sADDRESS, 'S', sSTREET);
  sADDRESS := replace(sADDRESS, 's', sSTREET_T);
  -- ���
  sADDRESS := replace(sADDRESS, 'H', rADDR.ADDR_HOUSE);
  -- ������
  sADDRESS := replace(sADDRESS, 'B', rADDR.ADDR_BLOCK);
  -- ��������
  sADDRESS := replace(sADDRESS, 'L', rADDR.ADDR_BUILDING);
  -- ��������
  sADDRESS := replace(sADDRESS, 'F', rADDR.ADDR_FLAT);
  return sADDRESS;
end;
/
