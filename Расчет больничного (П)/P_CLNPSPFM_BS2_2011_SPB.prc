create or replace procedure P_CLNPSPFM_BS2_2011_SPB
--
(nCOMPANY  in number, -- �����������
 nIDENT    in number, -- ���������� ��
 sSLCOMPGR in varchar2, -- ������ ������
 dBEGIN    in date, -- ����� �� ������� "�" �
 dEND      in date, -- ����� �� ������� "�" ��
 dFORBEGIN in date, -- ����� �� ������� "��" �
 dFOREND   in date, -- ����� �� ������� "��" ��
 nCOMMON   in number, -- ������� ������ ����� �������
 nDEKRET   in number, -- ����� ��� ���������
 sPOST     in varchar2,
 sFIO      in varchar2) as
  /* ��������� */
  -- ������� ����
  SHEET_FORM constant PKG_STD.tSTRING := '������';
  CELL_SLP   constant PKG_STD.tSTRING := '���_������';
  CELL_FIO   constant PKG_STD.tSTRING := '���';
  CELL_PER   constant PKG_STD.tSTRING := '������';
  DETAIL2    constant PKG_STD.tSTRING := '������2';
  CELL_PER1  constant PKG_STD.tSTRING := '������1';
  CELL_SUMZ  constant PKG_STD.tSTRING := 'C�����������';
  CELL_SRZR  constant PKG_STD.tSTRING := '�������_���������';
  CELL_NBOL  constant PKG_STD.tSTRING := '��_�����';
  CELL_NMEN  constant PKG_STD.tSTRING := '��_�����_�������';
  CELL_ITOG  constant PKG_STD.tSTRING := '����������';
  iDETAIL_1IDX integer := null;
  --  iDETAIL_1IDX         integer;
  --  iDETAIL_3IDX         integer;
  --  nLINE                integer := 0;

  nPROCESS        PKG_STD.tREF;
  nSLCOMPGR       PKG_STD.tREF;
  nYBGN           number(4);
  nMBGN           number(2);
  nYEND           number(4);
  nMEND           number(2);
  nYFORBGN        number(4);
  nMFORBGN        number(2);
  nYFOREND        number(4);
  nMFOREND        number(2);
  dCALCPRDBGN     date;
  dCALCPRDBGN2    date;
  odCALCPRDBGN    date;
  odCALCPRDBGN2   date;
  nTMP            SLPAYSPRM.NUM_VALUE%type;
  nYEARSUMLIM1    PKG_STD.tSUMM;
  nYEARSUMLIM2    PKG_STD.tSUMM;
  nDAYS           SLPAYSPRM.NUM_VALUE%type;
  nSUM            PKG_STD.tSUMM;
  nYEARSUM1       PKG_STD.tSUMM;
  nYEARSUM2       PKG_STD.tSUMM;
  dBEGIN_DATE     date;
  dEND_DATE       date;
  nABSDAYS        number;
  dFIRSTDATE      date;
  nCOUNT          number;
  nWRK            number;
  nPRC            number;
  nCALDAYS        number;
  nLIMITMIN       number;
  nLIMITMINRULE   number;
  sRELATIVE       varchar2(20);
  nCALCPRDDAYSQNT number;

begin

  /* ������������� �������� */
  nPROCESS := GEN_IDENT;

  /* ��������� ������������ ��������� ������ */
  PKG_TEMP.SET_TEMP_USED('CLNPSPFM_SLPAYSGRPPRMREP', nPROCESS);

  FIND_SLCOMPGR_CODE(0, 0, nCOMPANY, sSLCOMPGR, nSLCOMPGR);

  /* �������� ������ �� ������� */
  delete from CLNPSPFM_SLPAYSGRPPRMREP where AUTHID = UTILIZER;

  /* ������ */
  PRSG_EXCEL.PREPARE;
  /* ��������� �������� �������� ����� */
  PRSG_EXCEL.SHEET_SELECT(SHEET_FORM);
  /* �������� */
  PRSG_EXCEL.LINE_DESCRIBE('������0');
  PRSG_EXCEL.LINE_CELL_DESCRIBE('������0', CELL_SLP);
  PRSG_EXCEL.LINE_CELL_DESCRIBE('������0', CELL_FIO);
  PRSG_EXCEL.LINE_CELL_DESCRIBE('������0', CELL_PER);
  PRSG_EXCEL.LINE_DESCRIBE('������1�');
  PRSG_EXCEL.LINE_CELL_DESCRIBE('������1�', '�����1�');
  PRSG_EXCEL.LINE_CELL_DESCRIBE('������1�', '�����2�');
  PRSG_EXCEL.LINE_CELL_DESCRIBE('������1�', '�����1�');
  PRSG_EXCEL.LINE_CELL_DESCRIBE('������1�', '�����2�');
  PRSG_EXCEL.LINE_CELL_DESCRIBE('������1�', '���������1');
  PRSG_EXCEL.LINE_CELL_DESCRIBE('������1�', '���������2');
  PRSG_EXCEL.LINE_DESCRIBE('������1�');
  PRSG_EXCEL.LINE_CELL_DESCRIBE('������1�', '��_������_������');
  PRSG_EXCEL.LINE_DESCRIBE(DETAIL2);
  PRSG_EXCEL.LINE_CELL_DESCRIBE(DETAIL2, CELL_PER1);
  PRSG_EXCEL.LINE_CELL_DESCRIBE(DETAIL2, CELL_SUMZ);
  PRSG_EXCEL.LINE_CELL_DESCRIBE(DETAIL2, '������������');
  PRSG_EXCEL.LINE_CELL_DESCRIBE(DETAIL2, '��_������_�����');
  PRSG_EXCEL.LINE_CELL_DESCRIBE(DETAIL2, CELL_SRZR);
  PRSG_EXCEL.LINE_CELL_DESCRIBE(DETAIL2, '���_�����������');
  PRSG_EXCEL.LINE_CELL_DESCRIBE(DETAIL2, '����');
  PRSG_EXCEL.LINE_CELL_DESCRIBE(DETAIL2, CELL_NBOL);
  PRSG_EXCEL.LINE_CELL_DESCRIBE(DETAIL2, CELL_NMEN);
  PRSG_EXCEL.LINE_CELL_DESCRIBE(DETAIL2, CELL_ITOG);
  PRSG_EXCEL.LINE_DESCRIBE('������2�');
  PRSG_EXCEL.LINE_DESCRIBE('������2�');
  PRSG_EXCEL.LINE_CELL_DESCRIBE('������2�', '���1');
  PRSG_EXCEL.LINE_CELL_DESCRIBE('������2�', '���2');
  PRSG_EXCEL.LINE_CELL_DESCRIBE('������2�', '���3');
  PRSG_EXCEL.LINE_DESCRIBE('������2�');
  PRSG_EXCEL.LINE_DESCRIBE('������4');
  PRSG_EXCEL.LINE_CELL_DESCRIBE('������4', '���������');
  PRSG_EXCEL.LINE_CELL_DESCRIBE('������4', '���2');
  PRSG_EXCEL.COLUMN_DESCRIBE('����1');
  PRSG_EXCEL.COLUMN_DESCRIBE('��1');

  -- �������������� ���������� ��� ������ ���������� �� ��������������� �������
  nYBGN    := D_YEAR(dBEGIN);
  nMBGN    := D_MONTH(dBEGIN);
  nYEND    := D_YEAR(dEND);
  nMEND    := D_MONTH(dEND);
  nYFORBGN := D_YEAR(dFORBEGIN);
  nMFORBGN := D_MONTH(dFORBEGIN);
  nYFOREND := D_YEAR(dFOREND);
  nMFOREND := D_MONTH(dFOREND);
  -- ����
  for cGRP in (select SP.CLNPSPFM, --
                      SP.CLNPERSONS,
                      SP.RN,
                      SP.SLPAYGRND,
                      CL.PERS_AGENT,
                      A.AGNFAMILYNAME,
                      A.AGNFIRSTNAME,
                      A.AGNLASTNAME,
                      GP.dBGN,
                      GP.dEND
                 from SELECTLIST SL, --
                      SLPAYSGRP SP,
                      SLCOMPGRSTRUCT ST,
                      CLNPERSONS CL,
                      AGNLIST A,
                      (select PR.PRN, --
                              max(decode(PR.CODE, 'BGN', PR.DATE_VALUE)) dBGN,
                              max(decode(PR.CODE, 'END', PR.DATE_VALUE)) dEND
                         from SLPAYGRNDPRM PR
                        where PR.CODE in ('BGN', 'END')
                        group by PR.PRN) GP
                where SL.DOCUMENT = SP.CLNPSPFM
                  and SP.SLCOMPCHARGES = ST.SLCOMPCHARGES
                  and SP.CLNPERSONS = CL.RN
                  and CL.PERS_AGENT = A.RN
                  and ST.PRN = nSLCOMPGR
                  and SL.IDENT = nIDENT
                  and GP.PRN(+) = SP.SLPAYGRND
                  and ((dBEGIN is not null and (SP.YEAR > nYBGN or (SP.YEAR = nYBGN and SP.MONTH >= nMBGN))) or dBEGIN is null)
                  and ((dEND is not null and (SP.YEAR < nYEND or (SP.YEAR = nYEND and SP.MONTH <= nMEND))) or dEND is null)
                order by A.AGNFAMILYNAME, A.AGNFIRSTNAME, A.AGNLASTNAME, dBGN) loop
    /* ������ ���������� ������� */
    PKG_SLPAYSGRPPRM.GET(cGRP.RN, 'CALCPRDBGN', dCALCPRDBGN);
    PKG_SLPAYSGRPPRM.GET(cGRP.RN, 'CALCPRDBGN2', dCALCPRDBGN2);
    if dCALCPRDBGN2 is null then
      dCALCPRDBGN2 := add_months(dCALCPRDBGN, 12);
    else
      dCALCPRDBGN2 := trunc(dCALCPRDBGN2, 'Y');
    end if;
    odCALCPRDBGN  := dCALCPRDBGN;
    odCALCPRDBGN2 := dCALCPRDBGN2;
    /* ������� ��������� � ������ ����������� */
    PKG_SLPAYSGRPPRM.GET(cGRP.RN, 'YEARSUMLIM1', nYEARSUMLIM1);
    PKG_SLPAYSGRPPRM.GET(cGRP.RN, 'YEARSUMLIM2', nYEARSUMLIM2);
    nYEARSUM1 := 0;
    nYEARSUM2 := 0;
    /* ��������� �� �������*/
    for i in 1 .. 24 loop
      /* ��������� ��������������� */
      PKG_SLPAYSGRPPRM.GET(cGRP.RN, 'AVGSUM' || trim(to_char(i)), nTMP, 0);
      insert into CLNPSPFM_SLPAYSGRPPRMREP
        (RN, IDENT, CONNECT_EXT, AUTHID, MONTH, YEARFOR, MONTHFOR, AVGSUM) --
      values
        (cGRP.RN, nPROCESS, PKG_SESSION.GET_CONNECT_EXT, UTILIZER, i, D_YEAR(dCALCPRDBGN), D_MONTH(dCALCPRDBGN), nTMP);
      if i < 12 then
        dCALCPRDBGN := add_months(dCALCPRDBGN, 1);
      else
        if i > 12 then
          dCALCPRDBGN2 := add_months(dCALCPRDBGN2, 1);
        end if;
        dCALCPRDBGN := dCALCPRDBGN2;
      end if;
      if i < 13 then
        nYEARSUM1 := nYEARSUM1 + nTMP;
      else
        nYEARSUM2 := nYEARSUM2 + nTMP;
      end if;
    end loop;
  
    nABSDAYS := 0;
    -- �������
    for cPAYS in (select SP.SUM, --
                         SP.RN,
                         SP.SLPAYGRND,
                         SP.MONTHFOR,
                         SP.YEARFOR,
                         SC.NAME,
                         row_number() over(order by SC.NAME, SP.YEARFOR, SP.MONTHFOR) nrow,
                         count(1) over() ncount
                    from SLPAYS SP, SLCOMPCHARGES SC
                   where SP.SLPAYSGRP = cGRP.RN
                     and SP.SLCOMPCHARGES = SC.RN
                     and ((dFORBEGIN is not null and (SP.YEARFOR > nYFORBGN or (SP.YEARFOR = nYFORBGN and SP.MONTHFOR >= nMFORBGN))) or dFORBEGIN is null)
                     and ((dFOREND is not null and (SP.YEARFOR < nYFOREND or (SP.YEARFOR = nYFOREND and SP.MONTHFOR <= nMFOREND))) or dFOREND is null)
                   order by SC.NAME, SP.YEARFOR, SP.MONTHFOR) loop
      /* ������ ����������� (�� ��������� ����������) */
      dBEGIN_DATE := cGRP.dBGN;
      dEND_DATE   := cGRP.dEND;
    
      if nCOMMON = 0 then
        if cPAYS.MONTHFOR <> D_MONTH(dBEGIN_DATE) then
          dBEGIN_DATE := INT2DATE(1, cPAYS.MONTHFOR, cPAYS.YEARFOR);
        end if;
        if cPAYS.MONTHFOR <> D_MONTH(dEND_DATE) then
          dEND_DATE := last_day(dBEGIN_DATE);
        end if;
      end if;
    
      if (nCOMMON = 0) or (cPAYS.NROW = 1) then
      
        if iDETAIL_1IDX is not null /*nLINE = 3*/
         then
          iDETAIL_1IDX := PRSG_EXCEL.LINE_CONTINUE('������0');
          PRSG_EXCEL.LINE_PAGE_BREAK;
        else
          iDETAIL_1IDX := PRSG_EXCEL.LINE_APPEND('������0');
        end if;
        PRSG_EXCEL.CELL_VALUE_WRITE(CELL_SLP, 0, iDETAIL_1IDX, cPAYS.NAME);
        PRSG_EXCEL.CELL_VALUE_WRITE(CELL_FIO, 0, iDETAIL_1IDX, trim(cGRP.AGNFAMILYNAME) || ' ' || trim(cGRP.AGNFIRSTNAME) || ' ' || trim(cGRP.AGNLASTNAME));
        PRSG_EXCEL.CELL_VALUE_WRITE(CELL_PER, 0, iDETAIL_1IDX, '� ' || to_char(dBEGIN_DATE, 'dd') || '.' || to_char(dBEGIN_DATE, 'mm') || '.' || D_YEAR(dBEGIN_DATE) || ' �� ' || to_char(dEND_DATE, 'dd') || '.' || to_char(dEND_DATE, 'mm') || '.' || D_YEAR(dEND_DATE));
        iDETAIL_1IDX := PRSG_EXCEL.LINE_CONTINUE('������1�');
        PRSG_EXCEL.CELL_VALUE_WRITE('���������1', 0, iDETAIL_1IDX, '��������� �� ' || to_char(odCALCPRDBGN, 'yyyy') || ' ���');
        PRSG_EXCEL.CELL_VALUE_WRITE('���������2', 0, iDETAIL_1IDX, '��������� �� ' || to_char(odCALCPRDBGN2, 'yyyy') || ' ���');
        PRSG_EXCEL.CELL_VALUE_WRITE('�����1�', 0, iDETAIL_1IDX, nYEARSUM1);
        PRSG_EXCEL.CELL_VALUE_WRITE('�����1�', 0, iDETAIL_1IDX, nYEARSUM1);
        PRSG_EXCEL.CELL_VALUE_WRITE('�����1�', 0, iDETAIL_1IDX, nYEARSUMLIM1);
        PRSG_EXCEL.CELL_VALUE_WRITE('�����2�', 0, iDETAIL_1IDX, nYEARSUM2);
        PRSG_EXCEL.CELL_VALUE_WRITE('�����2�', 0, iDETAIL_1IDX, nYEARSUMLIM2);
        iDETAIL_1IDX := PRSG_EXCEL.LINE_CONTINUE('������1�');
        if nDEKRET = 1 then
          PRSG_EXCEL.CELL_VALUE_WRITE('��_������_������', 0, iDETAIL_1IDX, '����� �� ������ �����');
        else
          PRSG_EXCEL.CELL_VALUE_WRITE('��_������_������', 0, iDETAIL_1IDX, '�������');
        end if;
        nDAYS := 0;
        nSUM  := 0;
      end if;
      iDETAIL_1IDX := PRSG_EXCEL.LINE_CONTINUE(DETAIL2);
      PRSG_EXCEL.CELL_VALUE_WRITE(CELL_PER1, 0, iDETAIL_1IDX, to_char(cPAYS.MONTHFOR, '00') || '/' || cPAYS.YEARFOR);
      PRSG_EXCEL.CELL_VALUE_WRITE(CELL_SUMZ, 0, iDETAIL_1IDX, nYEARSUMLIM1 + nYEARSUMLIM2);
      /* ���������� ���� */
      PKG_SLPAYSPRM.GET(cPAYS.RN, 'WRK', nWRK, 0);
      PRSG_EXCEL.CELL_VALUE_WRITE('����', 0, iDETAIL_1IDX, nWRK);
      nDAYS := nDAYS + nWRK;
      /* ������� */
      PKG_SLPAYSPRM.GET(cPAYS.RN, 'PRC', nPRC, 0);
      /* ������� ��������� ��������� */
      PKG_SLPAYSPRM.GET(cPAYS.RN, 'CALCAVGPAY', nTMP, 0);
      PRSG_EXCEL.CELL_VALUE_WRITE(CELL_SRZR, 0, iDETAIL_1IDX, nTMP);
      if nDEKRET = 1 then
        PRSG_EXCEL.CELL_VALUE_WRITE('��_������_�����', 0, iDETAIL_1IDX, nTMP * 30.4 * 0.4);
      else
        --PRSG_EXCEL.CELL_VALUE_WRITE('��_������_�����', 0, iDETAIL_1IDX, nTMP * nWRK);
        PRSG_EXCEL.CELL_VALUE_WRITE('��_������_�����', 0, iDETAIL_1IDX, nPRC);
      end if;
    
      /* ������ ����������� �����: */
      if nDEKRET = 1 then
        PKG_SLPAYGRNDPRM.GET(cPAYS.SLPAYGRND, 'RELATIVE', sRELATIVE, '');
        find_salscale_code(0, 0, nCOMPANY, '����������� �������', nLIMITMINRULE);
        if (sRELATIVE is not null) and (nLIMITMINRULE is not null) then
          P_SALSCALE_BASE_GETVAL(nLIMITMINRULE, dBEGIN_DATE, F_AGNRELATIVE_CHILD_NUMB(nCOMPANY, cGRP.PERS_AGENT, sRELATIVE), nLIMITMIN);
        else
          nLIMITMIN := 0;
        end if;
      else
        PKG_SLPAYSPRM.GET(cPAYS.RN, 'LIMITAVG', nLIMITMIN, 0);
      end if;
      PRSG_EXCEL.CELL_VALUE_WRITE('���_�����������', 0, iDETAIL_1IDX, nLIMITMIN);
      /* ���������� */
      PKG_SLPAYSPRM.GET(cPAYS.RN, 'CALCSUM', nTMP, 0);
      /* �� ����� */
      PKG_SLPAYSPRM.GET(cPAYS.RN, 'LIMITMAX', nTMP, 0);
      PRSG_EXCEL.CELL_VALUE_WRITE(CELL_NBOL, 0, iDETAIL_1IDX, nTMP);
      /* �� ����� */
      PKG_SLPAYSPRM.GET(cPAYS.RN, 'LIMITMIN', nTMP, 0);
      PRSG_EXCEL.CELL_VALUE_WRITE(CELL_NMEN, 0, iDETAIL_1IDX, nTMP);
      /* ��� �������� */
      PKG_SLPAYSGRPPRM.GET(cGRP.Rn, 'ABSDAYS', nABSDAYS, 0);
      /* ����� �� ����� ����� */
      if nWRK = 0 then
        nWRK := null;
      end if;
      nCALDAYS := last_day(to_date('01.' || to_char(cPAYS.Monthfor, '00') || '.' || to_char(cPAYS.Yearfor), 'dd.mm.yyyy')) - to_date('01.' || to_char(cPAYS.Monthfor, '00') || '.' || to_char(cPAYS.Yearfor), 'dd.mm.yyyy') + 1;
      --PRSG_EXCEL.CELL_VALUE_WRITE('��_������_�����', 0, iDETAIL_1IDX, ROUND(cPAYS.SUM * nCALDAYS / nWRK, 2));
      /* ����� */
      PRSG_EXCEL.CELL_VALUE_WRITE(CELL_ITOG, 0, iDETAIL_1IDX, cPAYS.SUM);
      nSUM := nSUM + cPAYS.SUM;
    
      nCALCPRDDAYSQNT := (add_months(odCALCPRDBGN, 12) - odCALCPRDBGN) + (add_months(odCALCPRDBGN2, 12) - odCALCPRDBGN2);
      PRSG_EXCEL.CELL_VALUE_WRITE('������������', 0, iDETAIL_1IDX, PKG_EXT.IIF(nCALCPRDDAYSQNT - nABSDAYS < 0, 0, nCALCPRDDAYSQNT - nABSDAYS));
    
      if nABSDAYS <> 0 then
        iDETAIL_1IDX := PRSG_EXCEL.LINE_CONTINUE('������2�');
        nCOUNT       := 0;
        for cDNV in (select WD.WORKDATE, --
                            lag(WD.WORKDATE) over(partition by DT.NAME order by WD.WORKDATE, DT.NAME) PREVDATE,
                            DT.NAME,
                            WD.WORKDATE - lag(WD.WORKDATE) over(partition by DT.NAME order by WD.WORKDATE, DT.NAME) nDAYS,
                            row_number() over(order by WD.WORKDATE, DT.NAME) nROW,
                            count(1) over() nCOUNT
                       from CLNPSPFMWD WD, SLDAYSTYPE DT, CLNPSPFM PF, CLNPSPFMTYPES CT
                      where WD.DAYSTYPE = DT.RN
                        and DT.SHORT_CODE in ('�', '�')
                        and to_char(WD.WORKDATE, 'yyyy') in (to_char(odCALCPRDBGN, 'yyyy'), to_char(odCALCPRDBGN2, 'yyyy'))
                        and WD.PRN = PF.RN
                        and PF.CLNPSPFMTYPES = CT.RN
                        and CT.IS_PRIMARY = 1
                        and PF.PERSRN = cGRP.CLNPERSONS
                      order by WD.WORKDATE, DT.NAME) loop
          if (cDNV.nDAYS is null) then
            dFIRSTDATE := cDNV.WORKDATE;
          end if;
          if (cDNV.nDAYS <> 1) or (cDNV.nROW = cDNV.nCOUNT) then
            iDETAIL_1IDX := PRSG_EXCEL.LINE_CONTINUE('������2�');
            if (cDNV.nROW = cDNV.nCOUNT) then
              nCOUNT := nCOUNT + 1;
              PRSG_EXCEL.CELL_VALUE_WRITE('���1', 0, iDETAIL_1IDX, '� ' || to_char(dFIRSTDATE, 'dd.mm.yyyy') || ' �� ' || to_char(cDNV.Workdate, 'dd.mm.yyyy'));
            else
              PRSG_EXCEL.CELL_VALUE_WRITE('���1', 0, iDETAIL_1IDX, '� ' || to_char(dFIRSTDATE, 'dd.mm.yyyy') || ' �� ' || to_char(cDNV.PREVDATE, 'dd.mm.yyyy'));
            end if;
            PRSG_EXCEL.CELL_VALUE_WRITE('���2', 0, iDETAIL_1IDX, cDNV.Name);
            PRSG_EXCEL.CELL_VALUE_WRITE('���3', 0, iDETAIL_1IDX, nCOUNT);
            dFIRSTDATE := cDNV.WORKDATE;
            nCOUNT     := 0;
            if (cDNV.nROW = cDNV.nCOUNT) then
              iDETAIL_1IDX := PRSG_EXCEL.LINE_CONTINUE('������2�');
              PRSG_EXCEL.CELL_VALUE_WRITE('���2', 0, iDETAIL_1IDX, '�����');
              PRSG_EXCEL.CELL_VALUE_WRITE('���3', 0, iDETAIL_1IDX, cDNV.nCOUNT);
            end if;
          end if;
          nCOUNT := nCOUNT + 1;
        end loop;
        iDETAIL_1IDX := PRSG_EXCEL.LINE_CONTINUE('������2�');
      end if;
    
      if (cPAYS.Nrow = cPAYS.Ncount) and (cPAYS.Ncount > 1) and (nCOMMON <> 0) then
        iDETAIL_1IDX := PRSG_EXCEL.LINE_CONTINUE(DETAIL2);
        PRSG_EXCEL.CELL_VALUE_WRITE(CELL_PER1, 0, iDETAIL_1IDX, '�����');
        PRSG_EXCEL.CELL_VALUE_WRITE('����', 0, iDETAIL_1IDX, nDAYS);
        PRSG_EXCEL.CELL_VALUE_WRITE(CELL_ITOG, 0, iDETAIL_1IDX, nSUM);
      end if;
    
      -- ������� ���������� ���� � ���� ����� �������, ���� � ����� ������ �������
      if (cPAYS.NROW = cPAYS.NCOUNT) or (nCOMMON = 0) then
        iDETAIL_1IDX := PRSG_EXCEL.LINE_CONTINUE('������4');
        PRSG_EXCEL.CELL_VALUE_WRITE('���������', 0, iDETAIL_1IDX, sPOST);
        PRSG_EXCEL.CELL_VALUE_WRITE('���2', 0, iDETAIL_1IDX, sFIO);
      end if;
    
    end loop;
  
  end loop;
  /* �������� */
  PRSG_EXCEL.LINE_DELETE('������0');
  PRSG_EXCEL.LINE_DELETE(DETAIL2);
  PRSG_EXCEL.LINE_DELETE('������4');
  PRSG_EXCEL.LINE_DELETE('������1�');
  PRSG_EXCEL.LINE_DELETE('������1�');
  PRSG_EXCEL.LINE_DELETE('������2�');
  PRSG_EXCEL.LINE_DELETE('������2�');
  PRSG_EXCEL.LINE_DELETE('������2�');
  if nDEKRET = 1 then
    PRSG_EXCEL.COLUMN_DELETE('��1');
  else
    PRSG_EXCEL.COLUMN_DELETE('����1');
  end if;

  /* ������������� ��������������� �������������� �������� */
  PKG_TEMP.CONFIRM_USED_IDENT(nPROCESS);
end P_CLNPSPFM_BS2_2011_SPB;
/
