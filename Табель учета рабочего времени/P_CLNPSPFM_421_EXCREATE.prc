create or replace procedure P_CLNPSPFM_421_EXCREATE
(
  nCOMPANY          in number,          -- �����������
  nIDENT            in number,          -- ���������� ����������
  dMONTH            in date,            -- ���� ���������� ������
  sNIGHT            in varchar2,        -- ��� ������ �����
  sORG              in varchar2,        -- ����������� ��� ������
  sACC              in varchar2,        -- ����� �����
  dFORM             in date,            -- ���� �����������
  sRUK              in varchar2,        -- ������������ ����������
  sISP              in varchar2,        -- ����������� (���������)
  sISPR             in varchar2,        -- ����������� (����������� �������)
  nPAGE3            in number,          -- ����������� ������������ �������� 3
  sGRCATSAL         in varchar2         -- ��������� 1-�� ���
)
as
  /* ��������� */
  -- ������� ����
  SHEET1_FORM       constant PKG_STD.tSTRING := '����1';
  CELL_RUK          constant PKG_STD.tSTRING := '������������';
  CELL_MONTH        constant PKG_STD.tSTRING := '�����';
  CELL_YEAR         constant PKG_STD.tSTRING := '���';
  CELL_DATE         constant PKG_STD.tSTRING := '����';
  CELL_ORG          constant PKG_STD.tSTRING := '����������';
  CELL_OKPO         constant PKG_STD.tSTRING := '����';
  CELL_DEPT         constant PKG_STD.tSTRING := '�������������';
  CELL_DAYS         constant PKG_STD.tSTRING := '���';
  CELL_ACC          constant PKG_STD.tSTRING := '����';
  SHEET2_FORM       constant PKG_STD.tSTRING := '����2';
  DETAIL1           constant PKG_STD.tSTRING := '������1';
  CELL_NUM          constant PKG_STD.tSTRING := '�����';
  CELL_FIO          constant PKG_STD.tSTRING := '���';
  CELL_DOL          constant PKG_STD.tSTRING := '���������';
  CELL_ISP          constant PKG_STD.tSTRING := '���������_�����������';
  CELL_ISPR         constant PKG_STD.tSTRING := '���_�����������';
  SHEET3_FORM       constant PKG_STD.tSTRING := '����3';
  DETAIL2           constant PKG_STD.tSTRING := '������2';
  CELL_DAYSABS      constant PKG_STD.tSTRING := '���_������';
  CELL_KATN         constant PKG_STD.tSTRING := '���������_�����������';
  CELL_KATP         constant PKG_STD.tSTRING := '���������_���������';
  CELL_TABNUM       constant PKG_STD.tSTRING := '���������_�����';
  CELL_COST         constant PKG_STD.tSTRING := '���������';
  -- �������
  ADD_COLUMN        constant PKG_STD.tSTRING := '�������';
  CELL_ADD_NAME     constant PKG_STD.tSTRING := '��������_�������';
  CELL_ADD_HOUR     constant PKG_STD.tSTRING := '����_�������';
  CELL_ADD_SUMM     constant PKG_STD.tSTRING := '�����_�������';
  iCOLUMN_IDX       integer;
  iDETAIL_1IDX      integer;
  iDETAIL_2IDX      integer;
  nCOL              integer := 0;
  nSRT              integer := 1;
  nORGRN            PKG_STD.tREF;
  nGRCATSAL         PKG_STD.tREF;
  nSCHEDULE         PKG_STD.tREF;
  nTIMESORT         CLNPSPFMHS.TIMESORT%type;
  nCLNRATE          CLNPSPFMGS.CLNRATE%type := 0;
  sDEPT             INS_DEPARTMENT.NAME%type;
  nNORMH            number(17,2);
  nWORKH            number(17,2);
  nWORKN            number(17,2) := 0;
  nOTKL             number(17,2);
  nWORKDAYS         number(2) := 0;
  nDAYSABS          number(2);
  nHOURSABS         number(17,2);
  sDAY              varchar2(20);
  dDAT              date;
  dLDAT             date;
  nYEAR             number(4) := D_YEAR(dMONTH);
  nMONTH            number(2) := D_MONTH(dMONTH);
begin
  /* ������ ��������� ��� */
  FIND_GRCATSAL_CODE(1, 1, nCOMPANY, sGRCATSAL, nGRCATSAL);
  /* ������������ ��������� ���� (1-� �����) */
  dDAT := trunc(dMONTH,'MONTH');
  /* ���������� ��������� ���� ������ */
  dLDAT := last_day(dDAT);

  /* ������ */
  PRSG_EXCEL.PREPARE;

  /* ��������� �������� �������� ����� */
  PRSG_EXCEL.SHEET_SELECT( SHEET1_FORM );
  /* �������� */
  -- ���������
  PRSG_EXCEL.CELL_DESCRIBE( CELL_RUK );
  PRSG_EXCEL.CELL_DESCRIBE( CELL_MONTH );
  PRSG_EXCEL.CELL_DESCRIBE( CELL_YEAR );
  PRSG_EXCEL.CELL_DESCRIBE( CELL_DATE );
  PRSG_EXCEL.CELL_DESCRIBE( CELL_ORG );
  PRSG_EXCEL.CELL_DESCRIBE( CELL_OKPO );
  PRSG_EXCEL.CELL_DESCRIBE( CELL_DEPT );
  PRSG_EXCEL.CELL_DESCRIBE( CELL_DAYS );
  PRSG_EXCEL.CELL_DESCRIBE( CELL_ACC );
  PRSG_EXCEL.SHEET_SELECT( SHEET2_FORM );
  PRSG_EXCEL.LINE_DESCRIBE( DETAIL1 );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL1, CELL_NUM );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL1, CELL_FIO );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL1, CELL_DOL );
  for i in 1..31 loop
    PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL1, '����'||i );
  end loop;
  PRSG_EXCEL.CELL_DESCRIBE( CELL_ISP );
  PRSG_EXCEL.CELL_DESCRIBE( CELL_ISPR );
  PRSG_EXCEL.SHEET_SELECT( SHEET3_FORM );
  PRSG_EXCEL.LINE_DESCRIBE( DETAIL2 );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL2, CELL_DAYSABS );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL2, CELL_KATN );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL2, CELL_KATP );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL2, CELL_TABNUM );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL2, CELL_COST );
  -- �������
  PRSG_EXCEL.COLUMN_DESCRIBE( ADD_COLUMN );
  PRSG_EXCEL.COLUMN_CELL_DESCRIBE(ADD_COLUMN, CELL_ADD_NAME);
  PRSG_EXCEL.COLUMN_CELL_DESCRIBE(ADD_COLUMN, CELL_ADD_HOUR);
  PRSG_EXCEL.COLUMN_CELL_DESCRIBE(ADD_COLUMN, CELL_ADD_SUMM);

  if nPAGE3 = 1 then
    /* ��� ������� ��������� ���������� */
    delete from IDLIST;
    for rec in
    (
     select C.RN,
            C.CODE,
            C.NUMB
       from CLNPSPFM      A,
            SELECTLIST   SL,
            SLPAYS        S,
            SLCOMPCHARGES C
       where SL.IDENT        = nIDENT
         and SL.DOCUMENT     = A.RN
         and SL.DOCUMENT     = S.CLNPSPFM
         and S.SLCOMPCHARGES = C.RN
         and S.YEAR          = nYEAR
         and S.MONTH         = nMONTH
         and C.COMPCH_TYPE in (10,20)
       group by C.NUMB, C.CODE, C.RN
       order by C.NUMB
    )
    loop
      insert into IDLIST( ID, HID ) values (rec.RN, 1);
      nCOL := nCOL + 1;
      iCOLUMN_IDX := PRSG_EXCEL.COLUMN_APPEND(ADD_COLUMN);
      PRSG_EXCEL.CELL_VALUE_WRITE( CELL_ADD_NAME, iCOLUMN_IDX, 0, rec.CODE );
    end loop;
  else
    for i in 1..4 loop
      iCOLUMN_IDX := PRSG_EXCEL.COLUMN_APPEND(ADD_COLUMN);
      PRSG_EXCEL.CELL_VALUE_WRITE( CELL_ADD_NAME, iCOLUMN_IDX, 0, ' ' );
    end loop;
  end if;

  /* ������ �� ��������� ����������� */
  for rec in
  (
    select A.RN,
           least(dLDAT,nvl(A.ENDENG,dLDAT)) ENDENG,
           B.TAB_PREF,
           B.TAB_NUMB,
           C.AGNFAMILYNAME,
           C.AGNFIRSTNAME,
           C.AGNLASTNAME,
           nvl(J.PSDEP_NAME, D.NAME) POSTNAME,
           E.NAME,
           I.NAME PRPAYCAT,
           H.NAME OFFICERCLS,
           A.DEPTRN
      from CLNPSPFM A,
           CLNPERSONS B,
           AGNLIST C,
           SELECTLIST SL,
           INS_DEPARTMENT E,
           OFFICERCLS H,
           PRPAYCAT I,
           CLNPOSTS D,
           CLNPSDEP J
     where SL.IDENT = nIDENT
       and A.RN = SL.DOCUMENT
       and B.PERS_AGENT = C.RN
       and A.PERSRN = B.RN
       and A.POSTRN = D.RN(+)
       and A.PSDEPRN = J.RN(+)
       and A.DEPTRN = E.RN (+)
       and A.OFFICERCLS = H.RN (+)
       and B.PRPAYCAT = I.RN (+)
     order by C.AGNFAMILYNAME,
              C.AGNFIRSTNAME,
              C.AGNLASTNAME,
              B.TAB_PREF,
              B.TAB_NUMB
  )
  loop
    if nORGRN is null then
      if sORG is not null then
        FIND_AGENT_BY_MNEMO(nCOMPANY, sORG, nORGRN);
      else
        select OWNER_AGENT into nORGRN from INS_DEPARTMENT where RN = rec.DEPTRN;
      end if;
    end if;
    if sDEPT is null then
      sDEPT := rec.NAME;
    end if;

    /* ������ ������ */
    begin
      select A.SCHEDULE,
             A.TIMESORT
        into nSCHEDULE,
             nTIMESORT
        from CLNPSPFMHS A
       where A.PRN = rec.RN
         and A.DO_ACT_FROM =
             (
              select max(B.DO_ACT_FROM)
                from CLNPSPFMHS B
               where B.PRN = rec.RN
                 and B.DO_ACT_FROM <= dLDAT
             );
    exception
      when NO_DATA_FOUND then
        nSCHEDULE := null;
        nTIMESORT := 1;
    end;
    if nWORKDAYS = 0 then
      /* ���������� �������  ���� � ������ */
      PKG_CALENDAR.GET_DAYS(nCOMPANY, nSCHEDULE, dDAT, dLDAT, 'MH()', nWORKDAYS);
    end if;

    PRSG_EXCEL.SHEET_SELECT( SHEET2_FORM );
    iDETAIL_1IDX := PRSG_EXCEL.LINE_APPEND(DETAIL1);
    PRSG_EXCEL.CELL_VALUE_WRITE( CELL_NUM, 0, iDETAIL_1IDX, nSRT);
    PRSG_EXCEL.CELL_VALUE_WRITE( CELL_FIO, 0, iDETAIL_1IDX, trim(rec.AGNFAMILYNAME)||' '||trim(rec.AGNFIRSTNAME)||' '||trim(rec.AGNLASTNAME));
    PRSG_EXCEL.CELL_VALUE_WRITE( CELL_DOL, 0, iDETAIL_1IDX, trim(rec.POSTNAME));

    nHOURSABS := 0;
    /* ���� �� ���� */
    for recd in
    (
      select A.RN,
             A.WORKDATE,
             B.SHORT_CODE,
             B.ABSENCE_SIGN
        from CLNPSPFMWD A,
             SLDAYSTYPE B
       where A.PRN = rec.RN
         and A.DAYSTYPE = B.RN (+)
         and A.WORKDATE >= dDAT
         and A.WORKDATE <= dLDAT
    )
    loop
      /* ���������� ����� �� ����� */
      PKG_CALENDAR.GET_HOURS(nCOMPANY, nSCHEDULE, recd.WORKDATE, recd.WORKDATE, 'MH()', nNORMH);
      /* ���������� ����� � ������ �� ���� */
      PKG_WRK.GET_HOURS(rec.RN, recd.WORKDATE, recd.WORKDATE, null, nWORKH);
      if sNIGHT is not null then
        /* ���������� ������ ����� � ������ �� ���� */
        PKG_WRK.GET_HOURS(rec.RN, recd.WORKDATE, recd.WORKDATE, 'trim(HT.CODE) in ('''||trim(sNIGHT)||''')', nWORKN);
      end if;
      if recd.ABSENCE_SIGN = 1 then
        sDAY := trim(recd.SHORT_CODE);
      elsif nNORMH = 0 then
        sDAY := '�';
      else
        sDAY := '';
      end if;
      /* ���� ���������� */
      nOTKL := nNORMH - nWORKH;
      if nOTKL <> 0 then
        sDAY := sDAY||' '||abs(nOTKL);
      end if;
      sDAY := sDAY||CR;
      /* ������������ */
      if nOTKL < 0 then
        sDAY := sDAY||'�';
        if nWORKN > 0 then
          sDAY := sDAY||'/'||nWORKN;
        end if;
      elsif nWORKN > 0 then
        sDAY := sDAY||nWORKN;
      end if;
      if nOTKL > 0 then
        nHOURSABS := nHOURSABS + nOTKL;
      elsif nOTKL = 0 and recd.ABSENCE_SIGN = 1 then
        nHOURSABS := nHOURSABS + nNORMH;
      end if;

      execute immediate 'begin PRSG_EXCEL.CELL_VALUE_WRITE(:sCELL, 0, :nDETAIL, :nSTR); end;'
        using '����'||trim(D_DAY(recd.WORKDATE)), iDETAIL_1IDX, sDAY;
    end loop;
    /* ���������� ���� ������ */
    PKG_WRK.GET_DAYS(rec.RN, dDAT, dLDAT, 'DA()', nDAYSABS);

    PRSG_EXCEL.SHEET_SELECT( SHEET3_FORM );
    if nPAGE3 = 1 then
      if nGRCATSAL is not null then
        select sum(CLNRATE)
          into nCLNRATE
          from CLNPSPFMGS C
         where C.PRN = rec.RN
           and C.GRSALARY in (select G.GRSALARYRN from GRCATSALSP G where G.PRN = nGRCATSAL)
           and C.DO_ACT_FROM <= rec.ENDENG
           and (C.DO_ACT_TO is null or C.DO_ACT_TO >= rec.ENDENG);
      end if;
      /* ����� ������� ����/����� */
--      PKG_CALENDAR.GET_VALUE(nCOMPANY, nTIMESORT, nSCHEDULE, dDAT, dLDAT, 'MH()', nNORMH);
      PKG_CALENDAR.GET_HOURS(nCOMPANY, nSCHEDULE, dDAT, dLDAT, 'MH()', nNORMH);
      nHOURSABS := nNORMH - nHOURSABS;
      /* ������� �� ����� */
      iCOLUMN_IDX := 0;
      for rec1 in
      (
       select C.RN
         from IDLIST I,
              SLCOMPCHARGES C
        where I.ID = C.RN
        order by C.NUMB
      )
      loop
        iCOLUMN_IDX := iCOLUMN_IDX + 1;
        PRSG_EXCEL.CELL_VALUE_WRITE( CELL_ADD_HOUR, iCOLUMN_IDX, 0, 0);
        PRSG_EXCEL.CELL_VALUE_WRITE( CELL_ADD_SUMM, iCOLUMN_IDX, 0, 0);
        for rec2 in
        (
         select sum(S.SUM) SUM
           from SLPAYS S
          where S.CLNPSPFM      = rec.RN
            and S.SLCOMPCHARGES = rec1.RN
            and S.YEAR          = nYEAR
            and S.MONTH         = nMONTH
        )
        loop
          if nHOURSABS > 0 then
            PRSG_EXCEL.CELL_VALUE_WRITE( CELL_ADD_HOUR, iCOLUMN_IDX, 0, nHOURSABS);
          end if;
          PRSG_EXCEL.CELL_VALUE_WRITE( CELL_ADD_SUMM, iCOLUMN_IDX, 0, rec2.SUM );
        end loop;
      end loop;
    end if;
    iDETAIL_2IDX := PRSG_EXCEL.LINE_APPEND(DETAIL2);
    PRSG_EXCEL.CELL_VALUE_WRITE( CELL_DAYSABS, 0, iDETAIL_2IDX, nDAYSABS);
    PRSG_EXCEL.CELL_VALUE_WRITE( CELL_KATN, 0, iDETAIL_2IDX, trim(rec.PRPAYCAT));
    PRSG_EXCEL.CELL_VALUE_WRITE( CELL_KATP, 0, iDETAIL_2IDX, trim(rec.OFFICERCLS));
    PRSG_EXCEL.CELL_VALUE_WRITE( CELL_TABNUM, 0, iDETAIL_2IDX, trim(rec.TAB_PREF)||'-'||trim(rec.TAB_NUMB));
    if nPAGE3 = 1 and nNORMH <> 0 then
      PRSG_EXCEL.CELL_VALUE_WRITE( CELL_COST, 0, iDETAIL_2IDX, nCLNRATE / nNORMH);
    end if;
    nSRT := nSRT + 1;
  end loop;
  /* �������� */
  PRSG_EXCEL.LINE_DELETE( DETAIL2 );
  if nCOL > 0 then
    PRSG_EXCEL.COLUMN_DELETE(ADD_COLUMN);
  end if;
  PRSG_EXCEL.SHEET_SELECT( SHEET2_FORM );
  PRSG_EXCEL.LINE_DELETE( DETAIL1 );
  PRSG_EXCEL.CELL_VALUE_WRITE( CELL_ISP, trim(sISP));
  PRSG_EXCEL.CELL_VALUE_WRITE( CELL_ISPR, trim(sISPR));
  PRSG_EXCEL.SHEET_SELECT( SHEET1_FORM );
  PRSG_EXCEL.CELL_VALUE_WRITE( CELL_RUK, trim(sRUK));
  PRSG_EXCEL.CELL_VALUE_WRITE( CELL_MONTH, F_GET_MONTH(nMONTH));
  PRSG_EXCEL.CELL_VALUE_WRITE( CELL_YEAR, nYEAR);
  PRSG_EXCEL.CELL_VALUE_WRITE( CELL_DATE, to_char(dFORM,'dd.mm.yyyy'));
  PRSG_EXCEL.CELL_VALUE_WRITE( CELL_DEPT, trim(sDEPT));
  PRSG_EXCEL.CELL_VALUE_WRITE( CELL_DAYS, nWORKDAYS);
  PRSG_EXCEL.CELL_VALUE_WRITE( CELL_ACC, trim(sACC));
  for rec in
  (
    select ORGCODE,
           AGNNAME
      from AGNLIST
     where RN = nORGRN
  )
  loop
    PRSG_EXCEL.CELL_VALUE_WRITE( CELL_ORG, trim(rec.AGNNAME));
    PRSG_EXCEL.CELL_VALUE_WRITE( CELL_OKPO, trim(rec.ORGCODE));
  end loop;
end;
/
