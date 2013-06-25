create or replace procedure P_UA_JORNAL_XO_ITOG9207
(
  sSQL_IN               in varchar2
)
is
  sSQL                  PKG_STD.tLSTRING; --�������� ��� ������� ��� order by
  LEN_KOD_SPEC          integer;         --����� ������� � ����������, �� ����������� ������
  START_POS_SPEC        integer;         --������ ������� � ����������
  STEK_SKOB             number;          --���� ������
  i                     integer;         --��� ����� (�� ���� ��� ��� ��)
  S                     varchar2(1);     --����������� ������
  KOD_SPEC              PKG_STD.tLSTRING; --����� ������� � ����������
  KOD_BEFORE_SPEC       PKG_STD.tLSTRING; --����� �� ������� � ����������
  KOD_QUERY             PKG_STD.tLSTRING; --����� ��������������� �������
  
  iGROUP                number; --����������� ������ �����
  QUERY_CUR             PKG_CURSORS.CurType;
  
  sSTR                  PKG_STD.tLSTRING;
  sA1                   PKG_STD.tLSTRING;
  sA2                   PKG_STD.tLSTRING;
  sA3                   PKG_STD.tLSTRING;
  sA4                   PKG_STD.tLSTRING;
  sA5                   PKG_STD.tLSTRING;
  nS0                   number;
  nS1                   number;
  nS2                   number;
  nS3                   number;
  nS4                   number;
  nS5                   number;
  
  nROW number; nCOUNT number; nALLSUMM number;
  
  SHEET_FORM            constant PKG_STD.tSTRING := '������ �����������';
  
  iLINE_IT_1            integer;
  LINE_IT_1             constant PKG_STD.tSTRING := 'LINE_IT_A';
  CELL_IT_ACC1          constant PKG_STD.tSTRING := '����_A';
  CELL_IT_SUM1          constant PKG_STD.tSTRING := '�����_A';

  iLINE_IT_2            integer;
  LINE_IT_2             constant PKG_STD.tSTRING := 'LINE_IT_B';
  CELL_IT_ACC2          constant PKG_STD.tSTRING := '����_B';
  CELL_IT_SUM2          constant PKG_STD.tSTRING := '�����_B';

  iLINE_IT_3            integer;
  LINE_IT_3             constant PKG_STD.tSTRING := 'LINE_IT_C';
  CELL_IT_ACC3          constant PKG_STD.tSTRING := '����_C';
  CELL_IT_SUM3          constant PKG_STD.tSTRING := '�����_C';

  iLINE_IT_4            integer;
  LINE_IT_4             constant PKG_STD.tSTRING := 'LINE_IT_D';
  CELL_IT_ACC4          constant PKG_STD.tSTRING := '����_D';
  CELL_IT_SUM4          constant PKG_STD.tSTRING := '�����_D';

  iLINE_USL             integer;
  LINE_USL_OTBOR        constant PKG_STD.tSTRING := 'USLOWIE';
  CELL_USL_OTBOR1       constant PKG_STD.tSTRING := '��';
  CELL_USL_OTBOR2       constant PKG_STD.tSTRING := '��������';

begin
      --����������� order by ����� ������, ����������� �� ����
  if sSQL_IN is not null then
    
    i:=InStr(sSQL_IN, 'order by');
    sSQL:=PKG_EXT.IIF(i!=0, SubStr(sSQL_IN, 1, i-2), sSQL_IN);
    --�������� ������ ������� �� ������� ����� where
    sSQL:='select * '||SubStr(sSQL, InStr(sSQL, 'from'));
    
    KOD_SPEC:='';
    KOD_BEFORE_SPEC:=sSQL;
    START_POS_SPEC:=InStr(sSQL, 'V_OPRSPECS_SHADOW');
    if not START_POS_SPEC=0 then --����� ����� V_OPRSPECS_SHADOW
      --KOD_BEFORE_SPEC ��������� �������� �� ������ ������� ������, ������� �������� �� ����� ����, �.�. ������ ����� ���� ������� chr(13)
      --"and" ���� ������, �������� �� ��� ������
      KOD_BEFORE_SPEC:=SubStr(KOD_BEFORE_SPEC, 1, InStr(SubStr(KOD_BEFORE_SPEC, 1, START_POS_SPEC), 'and', -1)-1);
      
      --START_POS_SPEC ���������� ������ ���� 
      --���� select, ��� ��������� �������
      START_POS_SPEC:=InStr(SubStr(sSQL, 1, START_POS_SPEC), 'select', -1);
      KOD_SPEC:=SubStr(sSQL, START_POS_SPEC);
      STEK_SKOB:=0;
      LEN_KOD_SPEC:=Length(KOD_SPEC);
      --������ ����� ������ ���������� � ������ ���������� union all
      i:=InStr(KOD_SPEC, 'union all', -1);
      loop --���� ����� ������
        i:=i+1;
        S:=SubStr(KOD_SPEC, i, 1);
        if S='(' then STEK_SKOB:=STEK_SKOB+1; end if;
        if S=')' then STEK_SKOB:=STEK_SKOB-1; end if;
        if STEK_SKOB<0 or i=LEN_KOD_SPEC then
          
          KOD_SPEC:=replace(SubStr(KOD_SPEC, 1, i-1),'SH.PRN','OP.*');
          KOD_SPEC:=replace(KOD_SPEC,'V_OPRSPECS_SHADOW','V_OPRSPECS OP, V_OPRSPECS_SHADOW');
          KOD_SPEC:=replace(KOD_SPEC,'COMPANY','SH.COMPANY')||' and OP.RN = SH.RN';
          KOD_BEFORE_SPEC:=KOD_BEFORE_SPEC||SubStr(sSQL, i+START_POS_SPEC);
  
          exit;
        end if;  
      end loop;
    end if;

    --������� �� �������� �����������
    if KOD_SPEC is null then
      KOD_SPEC := 'select OP.* from V_OPRSPECS OP, V_OPRSPECS_SHADOW SH where OP.RN = SH.RN';
    end if;    

    --������������� ����� �� �����, ��� � oprspec ��� ����, � �� prn
    KOD_QUERY:='select SH.* from ('||KOD_SPEC||') SH, ('||KOD_BEFORE_SPEC||') M where SH.PRN = M.RN '||' order by operation_date, prn';
    
    --������� excel
    PRSG_EXCEL.PREPARE;
    PRSG_EXCEL.SHEET_SELECT(SHEET_FORM);
    
    PRSG_EXCEL.LINE_DESCRIBE(LINE_IT_1);
    PRSG_EXCEL.LINE_CELL_DESCRIBE(LINE_IT_1, CELL_IT_ACC1);
    PRSG_EXCEL.LINE_CELL_DESCRIBE(LINE_IT_1, CELL_IT_SUM1);
    
    PRSG_EXCEL.LINE_DESCRIBE(LINE_IT_2);
    PRSG_EXCEL.LINE_CELL_DESCRIBE(LINE_IT_2, CELL_IT_ACC2);
    PRSG_EXCEL.LINE_CELL_DESCRIBE(LINE_IT_2, CELL_IT_SUM2);
    
    PRSG_EXCEL.LINE_DESCRIBE(LINE_IT_3);
    PRSG_EXCEL.LINE_CELL_DESCRIBE(LINE_IT_3, CELL_IT_ACC3);
    PRSG_EXCEL.LINE_CELL_DESCRIBE(LINE_IT_3, CELL_IT_SUM3);
    
    PRSG_EXCEL.LINE_DESCRIBE(LINE_IT_4);
    PRSG_EXCEL.LINE_CELL_DESCRIBE(LINE_IT_4, CELL_IT_ACC4);
    PRSG_EXCEL.LINE_CELL_DESCRIBE(LINE_IT_4, CELL_IT_SUM4);
    
    PRSG_EXCEL.LINE_DESCRIBE(LINE_USL_OTBOR);
    PRSG_EXCEL.LINE_CELL_DESCRIBE(LINE_USL_OTBOR, CELL_USL_OTBOR1);
    PRSG_EXCEL.LINE_CELL_DESCRIBE(LINE_USL_OTBOR, CELL_USL_OTBOR2);
    
    --������� ������� ������
    for j in
    (
      select 'D' as A0,
             1 as A1, 
             'OPERATION_DATE>=TO_DATE(' as A2, 
             '���� �������� c:' as A3 
        from dual 
      union all
      select 'D' as A0, 1, 'OPERATION_DATE<=TO_DATE(', '���� �������� ��:' from dual union all
      select 'S' as A0, 1, 'OPERATION_PREF>=', '������� �������� �:' from dual union all
      select 'S' as A0, 1, 'OPERATION_PREF<=', '������� �������� ��:' from dual union all
      select 'S' as A0, 1, 'OPERATION_NUMB>=', '����� �������� �:' from dual union all
      select 'S' as A0, 1, 'OPERATION_NUMB<=', '����� �������� ��:' from dual union all
      select 'S' as A0, 1, 'OPERATION_NUMB=', '����� ��������:' from dual union all
      select 'S' as A0, 1, 'OPERATION_NUMB like ', '����� ��������:' from dual union all
      select 'S' as A0, 1, 'OPERATION_PREF like ', '������� ��������:' from dual union all
      select 'S' as A0, 1, 'SPECIAL_MARK_RN in (select RN from DICSMRKS where SMARK_MNEMO=', '������ �������:' from dual union all
      select 'S' as A0, 1, 'SPECIAL_MARK_RN in (select RN from DICSMRKS where SMARK_MNEMO like ', '������ �������:' from dual union all
      select 'S' as A0, 1, 'VALID_DOCTYPE_RN in (select RN from DOCTYPES where DOCCODE=', '��������-���������:' from dual union all
      select 'S' as A0, 1, 'VALID_DOCTYPE_RN in (select RN from DOCTYPES where DOCCODE like ', '��������-���������:' from dual union all
      select 'D' as A0, 1, 'VALID_DOCDATE>=TO_DATE(', '���� ���������-��������� �:' from dual union all
      select 'D' as A0, 1, 'VALID_DOCDATE<=TO_DATE(', '���� ���������-��������� ��:' from dual union all
      select 'S' as A0, 1, 'VALID_DOCNUMB=', '����� ���������-���������:' from dual union all
      select 'S' as A0, 1, 'VALID_DOCNUMB like ', '����� ���������-���������:' from dual union all
      select 'S' as A0, 1, 'FACT_DOCTYPE_RN in (select RN from DOCTYPES where DOCCODE=', '��������-�������������:' from dual union all
      select 'S' as A0, 1, 'FACT_DOCTYPE_RN in (select RN from DOCTYPES where DOCCODE like ', '��������-�������������:' from dual union all
      select 'S' as A0, 1, 'FACT_DOCNUMB=', '����� ���������-�������������:'  from dual union all
      select 'S' as A0, 1, 'FACT_DOCNUMB like ', '����� ���������-�������������:'  from dual union all
      select 'D' as A0, 1, 'FACT_DOCDATE<=TO_DATE(', '���� ���������-������������� ��:' from dual union all
      select 'D' as A0, 1, 'FACT_DOCDATE>=TO_DATE(', '���� ���������-������������� �:' from dual union all
      select 'S' as A0, 0, 'ACNT_OPERSUM>=', '����� ������������� ������ �:' from dual union all
      select 'S' as A0, 0, 'ACNT_OPERSUM<=', '����� ������������� ������ ��:' from dual union all
      select 'S' as A0, 1, 'CRN_FROM in (select RN from ACATALOG where NAME=', '�� ���� (�������):' from dual union all
      select 'S' as A0, 1, 'CRN_FROM in (select RN from ACATALOG where NAME like ', '�� ���� (�������):' from dual union all
      select 'S' as A0, 1, 'CRN_TO in (select RN from ACATALOG where NAME=', '���� (�������):' from dual union all
      select 'S' as A0, 1, 'CRN_TO in (select RN from ACATALOG where NAME like ', '���� (�������):' from dual union all
      select 'S' as A0, 1, 'OPERATION_CONTENTS=', '����������:' from dual union all
      select 'S' as A0, 1, 'OPERATION_CONTENTS like ', '����������:' from dual union all
      select 'S' as A0, 1, 'NJUR_PERS in (select RN from JURPERSONS where CODE=', '��������������:' from dual union all
      select 'S' as A0, 1, 'NJUR_PERS in (select RN from JURPERSONS where CODE like ', '��������������:' from dual union all
      select 'S' as A0, 1, 'sESCORT_DOCNUMB=', '����� ���������-�������������:' from dual union all
      select 'S' as A0, 1, 'sESCORT_DOCNUMB like ', '����� ���������-�������������:' from dual union all
      select 'D' as A0, 1, 'dESCORT_DOCDATE<=TO_DATE(', '���� ���������-������������� �:' from dual union all
      select 'D' as A0, 1, 'dESCORT_DOCDATE>=TO_DATE(', '���� ���������-������������� ��:' from dual union all
      select 'S' as A0, 1, 'nESCORT_DOCTYPE in (select RN from DOCTYPES where DOCCODE=', '��������-�������������:' from dual union all
      select 'S' as A0, 1, 'nESCORT_DOCTYPE in (select RN from DOCTYPES where DOCCODE like ', '��������-�������������:' from dual union all
      select 'S' as A0, 1, 'AGENT_FROM_RN in (select RN from AGNLIST where AGNABBR=', '�� ���� (����������):' from dual union all
      select 'S' as A0, 1, 'AGENT_FROM_RN in (select RN from AGNLIST where AGNABBR like ', '�� ���� (����������):' from dual union all
      select 'S' as A0, 1, 'AGENT_TO_RN in (select RN from AGNLIST where AGNABBR=', '���� (����������):' from dual union all
      select 'S' as A0, 1, 'AGENT_TO_RN in (select RN from AGNLIST where AGNABBR like ', '���� (����������):' from dual union all
      select 'S' as A0, 0, 'ACNT_SUM>=', '����� �������� � ������ �:' from dual union all
      select 'S' as A0, 0, 'ACNT_SUM<=', '����� �������� � ������ ��:' from dual union all
      select 'S' as A0, 0, 'ACNT_BASE_SUM>=', '����� �������� � ����������� �:' from dual union all
      select 'S' as A0, 0, 'ACNT_BASE_SUM<=', '����� �������� � ����������� ��:' from dual union all
      select 'S' as A0, 0, 'ACNT_QUANT>=', '���������� �:' from dual union all
      select 'S' as A0, 0, 'ACNT_QUANT<=', '���������� ��:' from dual union all
      select 'S' as A0, 1, 'NOMENCLATURE in (select RN from DICNOMNS where NOMEN_CODE=', '�������� ������������:' from dual union all
      select 'S' as A0, 1, 'NOMENCLATURE in (select RN from DICNOMNS where NOMEN_CODE like ', '�������� ������������:' from dual union all
      select 'S' as A0, 1, 'NOMENCLATURE in (select RN from DICNOMNS where NOMEN_NAME=', '������������ ������������:' from dual union all
      select 'S' as A0, 1, 'NOMENCLATURE in (select RN from DICNOMNS where NOMEN_NAME like ', '������������ ������������:' from dual union all
      select 'S' as A0, 1, 'CURRENCY in (select RN from CURNAMES where INTCODE=', '������:' from dual union all
      select 'S' as A0, 1, 'CURRENCY in (select RN from CURNAMES where INTCODE like ', '������:' from dual union all
      select 'S' as A0, 1, 'NOMEN_CRN in (select RN from ACATALOG where NAME=', '������� ������������:' from dual union all
      select 'S' as A0, 1, 'NOMEN_CRN in (select RN from ACATALOG where NAME like ', '������� ������������:' from dual union all
      select 'S' as A0, 1, 'BALUNIT_DEBIT in (select RN from DICBUNTS where BUNIT_MNEMO=', '������������� ���������� ������� �� ������:' from dual union all
      select 'S' as A0, 1, 'BALUNIT_DEBIT in (select RN from DICBUNTS where BUNIT_MNEMO like ', '������������� ���������� ������� �� ������:' from dual union all
      select 'S' as A0, 1, 'ANALYTIC_DEBIT1 in (select RN from DICANLS where ANL_NUMBER=', '��������� 1 ������ �� ������:' from dual union all
      select 'S' as A0, 1, 'ANALYTIC_DEBIT1 in (select RN from DICANLS where ANL_NUMBER like ', '��������� 1 ������ �� ������:' from dual union all
      select 'S' as A0, 1, 'ANALYTIC_DEBIT2 in (select RN from DICANLS where ANL_NUMBER=', '��������� 2 ������ �� ������:' from dual union all
      select 'S' as A0, 1, 'ANALYTIC_DEBIT2 in (select RN from DICANLS where ANL_NUMBER like ', '��������� 2 ������ �� ������:' from dual union all
      select 'S' as A0, 1, 'ANALYTIC_DEBIT3 in (select RN from DICANLS where ANL_NUMBER=', '��������� 3 ������ �� ������:' from dual union all
      select 'S' as A0, 1, 'ANALYTIC_DEBIT3 in (select RN from DICANLS where ANL_NUMBER like ', '��������� 3 ������ �� ������:' from dual union all
      select 'S' as A0, 1, 'ANALYTIC_DEBIT4 in (select RN from DICANLS where ANL_NUMBER=', '��������� 4 ������ �� ������:' from dual union all
      select 'S' as A0, 1, 'ANALYTIC_DEBIT4 in (select RN from DICANLS where ANL_NUMBER like ', '��������� 4 ������ �� ������:' from dual union all
      select 'S' as A0, 1, 'ANALYTIC_DEBIT5 in (select RN from DICANLS where ANL_NUMBER=', '��������� 5 ������ �� ������:' from dual union all
      select 'S' as A0, 1, 'ANALYTIC_DEBIT5 in (select RN from DICANLS where ANL_NUMBER like ', '��������� 5 ������ �� ������:' from dual union all
      select 'S' as A0, 1, 'ACCOUNT_DEBIT in (select D.RN from DICACCS D where D.ACC_NUMBER=', '���� �� ������:' from dual union all
      select 'S' as A0, 1, 'ACCOUNT_DEBIT in (select D.RN from DICACCS D where D.ACC_NUMBER like ', '���� �� ������:' from dual union all
      select 'S' as A0, 1, 'exists (select RN from BALELEMENT where (RN=D.BALUNIT) and (CODE=', '��������� ���� �� ������:' from dual union all
      select 'S' as A0, 1, 'exists (select RN from BALELEMENT where (RN=D.BALUNIT) and (CODE like ', '��������� ���� �� ������:' from dual union all
      select 'S' as A0, 1, 'BALUNIT_CREDIT in (select RN from DICBUNTS where BUNIT_MNEMO=', '������������� ���������� ������� �� �������:' from dual union all
      select 'S' as A0, 1, 'BALUNIT_CREDIT in (select RN from DICBUNTS where BUNIT_MNEMO like ', '������������� ���������� ������� �� �������:' from dual union all
      select 'S' as A0, 1, 'ANALYTIC_CREDIT1 in (select RN from DICANLS where ANL_NUMBER=', '��������� 1 ������ �� �������:' from dual union all
      select 'S' as A0, 1, 'ANALYTIC_CREDIT1 in (select RN from DICANLS where ANL_NUMBER like ', '��������� 1 ������ �� �������:' from dual union all
      select 'S' as A0, 1, 'ANALYTIC_CREDIT2 in (select RN from DICANLS where ANL_NUMBER=', '��������� 2 ������ �� �������:' from dual union all
      select 'S' as A0, 1, 'ANALYTIC_CREDIT2 in (select RN from DICANLS where ANL_NUMBER like ', '��������� 2 ������ �� �������:' from dual union all
      select 'S' as A0, 1, 'ANALYTIC_CREDIT3 in (select RN from DICANLS where ANL_NUMBER=', '��������� 3 ������ �� �������:' from dual union all
      select 'S' as A0, 1, 'ANALYTIC_CREDIT3 in (select RN from DICANLS where ANL_NUMBER like ', '��������� 3 ������ �� �������:' from dual union all
      select 'S' as A0, 1, 'ANALYTIC_CREDIT4 in (select RN from DICANLS where ANL_NUMBER=', '��������� 4 ������ �� �������:' from dual union all
      select 'S' as A0, 1, 'ANALYTIC_CREDIT4 in (select RN from DICANLS where ANL_NUMBER like ', '��������� 4 ������ �� �������:' from dual union all
      select 'S' as A0, 1, 'ANALYTIC_CREDIT5 in (select RN from DICANLS where ANL_NUMBER=', '��������� 5 ������ �� �������:' from dual union all
      select 'S' as A0, 1, 'ANALYTIC_CREDIT5 in (select RN from DICANLS where ANL_NUMBER like ', '��������� 5 ������ �� �������:' from dual union all
      select 'S' as A0, 1, 'ACCOUNT_CREDIT in (select D.RN from DICACCS D where D.ACC_NUMBER=', '���� �� �������:' from dual union all
      select 'S' as A0, 1, 'ACCOUNT_CREDIT in (select D.RN from DICACCS D where D.ACC_NUMBER like ', '���� �� �������:' from dual union all
      select 'S' as A0, 1, 'exists (select RN from BALELEMENT where (RN=D.BALUNIT) and (CODE=', '��������� ���� �� �������:' from dual union all
      select 'S' as A0, 1, 'exists (select RN from BALELEMENT where (RN=D.BALUNIT) and (CODE like ', '��������� ���� �� �������:' from dual union all
      select 'S' as A0, 1, 'ACCTYPES in (select RN from ACCTYPES where CODE=', '��� �����:' from dual union all
      select 'S' as A0, 1, 'ACCTYPES in (select RN from ACCTYPES where CODE like ', '��� �����:' from dual union all
      select 'S' as A0, 1, 'ORDER_RN in (select NRN from V_MEMORDER where SCODE=', '����� ������:' from dual
    )loop
      i:=InStr(KOD_QUERY, j.A2, 1);
      if i!=0 then
        iLINE_USL := PRSG_EXCEL.LINE_APPEND(LINE_USL_OTBOR);
        PRSG_EXCEL.CELL_VALUE_WRITE(CELL_USL_OTBOR1, 0, iLINE_USL, j.A3);
        i:=i+Length(j.A2)+j.a1;
        if j.a1=1 then
          sSTR:=Replace(SubStr(KOD_QUERY, i, InStr(KOD_QUERY, chr(39), i)-i), '%', '*');
        else
          sSTR:=Replace(SubStr(KOD_QUERY, i, InStr(KOD_QUERY, chr(32), i)-i), '%', '*');
        end if;
        if j.a0='D' then
          sSTR:=to_char(to_date(sSTR, 'dd/mm/yyyy'), 'dd.mm.yyyy');
        end if;
        if sSTR is not null then
          PRSG_EXCEL.CELL_VALUE_WRITE(CELL_USL_OTBOR2, 0, iLINE_USL, sSTR);
        end if;  
      end if;
    end loop;

    KOD_QUERY:=
'select acc,
       analytic_debit1, 
       analytic_debit2, 
       analytic_debit3, 
       analytic_debit4, 
       analytic_debit5, 
       acnt_sum,
       DECODE(p0, 1, null, DECODE(count(*) over (partition by acc),             p0, DECODE(p0, p1, null, sum(acnt_sum) over (partition by acc)           ), null)) as s0,
       DECODE(p1, 1, null, DECODE(count(*) over (partition by acc,a1),          p1, DECODE(p1, p2, null, sum(acnt_sum) over (partition by acc,a1)        ), null)) as s1,
       DECODE(p2, 1, null, DECODE(count(*) over (partition by acc,a1,a2),       p2, DECODE(p2, p3, null, sum(acnt_sum) over (partition by acc,a1,a2)     ), null)) as s2,
       DECODE(p3, 1, null, DECODE(count(*) over (partition by acc,a1,a2,a3),    p3, DECODE(p3, p4, null, sum(acnt_sum) over (partition by acc,a1,a2,a3)  ), null)) as s3,
       DECODE(p4, 1, null, DECODE(count(*) over (partition by acc,a1,a3,a3,a4), p4,                      sum(acnt_sum) over (partition by acc,a1,a3,a3,a4), null)) as s4,
       nrow,
       COUNT(1) over() ncount,
       sum(acnt_sum) over() acnt_sum_all
from 
(
  select acc, a1, a2, a3, a4, acnt_sum,
         analytic_debit1, 
         analytic_debit2, 
         analytic_debit3, 
         analytic_debit4, 
         analytic_debit5, 
    row_number() over (order by acc,a1,a2,a3,a4) nrow,
    row_number() over (partition by acc             order by acc,a1,a2,a3,a4) as p0, 
    row_number() over (partition by acc,a1          order by acc,a1,a2,a3,a4) as p1, 
    row_number() over (partition by acc,a1,a2       order by acc,a1,a2,a3,a4) as p2, 
    row_number() over (partition by acc,a1,a2,a3    order by acc,a1,a2,a3,a4) as p3,
    row_number() over (partition by acc,a1,a2,a3,a4 order by acc,a1,a2,a3,a4) as p4
  from 
  (
    select SH.account_debit as acc,
           SH.analytic_debit1,
           DECODE(SH.analytic_debit1, null, DECODE(SH.analytic_debit2, null, DECODE(SH.analytic_debit3, null, DECODE(SH.analytic_debit4, null, SH.analytic_debit5, SH.analytic_debit4), SH.analytic_debit3), SH.analytic_debit2), SH.analytic_debit1) as a1, 
           SH.analytic_debit2,
           DECODE(SH.analytic_debit2, null, DECODE(SH.analytic_debit3, null, DECODE(SH.analytic_debit4, null, SH.analytic_debit5, SH.analytic_debit4), SH.analytic_debit3), SH.analytic_debit2) as a2, 
           SH.analytic_debit3,
           DECODE(SH.analytic_debit3, null, DECODE(SH.analytic_debit4, null, SH.analytic_debit5, SH.analytic_debit4), SH.analytic_debit3) as a3,
           SH.analytic_debit4,
           DECODE(SH.analytic_debit4, null, SH.analytic_debit5, SH.analytic_debit4) as a4, 
           SH.analytic_debit5,
           sum(SH.acnt_sum) as acnt_sum
      from ('||KOD_SPEC||') SH, ('||KOD_BEFORE_SPEC||') M where SH.PRN = M.RN and SH.account_debit is not null
       group by SH.account_debit,
           SH.analytic_debit1, 
           SH.analytic_debit2, 
           SH.analytic_debit3,
           SH.analytic_debit4, 
           SH.analytic_debit5
  )
)';

    iGROUP:=1;       
    open QUERY_CUR for KOD_QUERY;
    loop
      fetch QUERY_CUR into sSTR, sA1, sA2, sA3, sA4, sA5, nS5, nS0, nS1, nS2, nS3, nS4, nROW, nCOUNT, nALLSUMM;
      exit when QUERY_CUR%notfound;

      if iGROUP=1 then
        iLINE_IT_1 := PRSG_EXCEL.LINE_APPEND(LINE_IT_1);
      else
        iLINE_IT_1 := PRSG_EXCEL.LINE_APPEND(LINE_IT_1, LINE_IT_2);
      end if;

      sSTR:=SubStr(sSTR,1,17)||' '||SubStr(sSTR,18,1)||' '||SubStr(sSTR,19,3)||' '||SubStr(sSTR,22,2)||' '||SubStr(sSTR,24,50);
      if sA1||sA2||sA3||sA4||sA5 is not null then
        sA5:=', '||sA1||'.'||sA2||'.'||sA3||'.'||sA4||'.'||sA5;
      end if;  
      PRSG_EXCEL.CELL_VALUE_WRITE(CELL_IT_ACC1, 0, iLINE_IT_1, sSTR||sA5);
      PRSG_EXCEL.CELL_VALUE_WRITE(CELL_IT_SUM1, 0, iLINE_IT_1, nS5);
      iGROUP:=1;
      
      if nS4 is not null then
        iLINE_IT_2 := PRSG_EXCEL.LINE_APPEND(LINE_IT_2, LINE_IT_1);
        if sA1||sA2||sA3||sA4 is not null then
          sA4:=', '||sA1||'.'||sA2||'.'||sA3||'.'||sA4;
        end if;  
        PRSG_EXCEL.CELL_VALUE_WRITE(CELL_IT_ACC2, 0, iLINE_IT_2, '����� '||sSTR||sA4);
        PRSG_EXCEL.CELL_VALUE_WRITE(CELL_IT_SUM2, 0, iLINE_IT_2, nS4);
        iGROUP:=2;
      end if;
      if nS3 is not null then
        if iGROUP=2 then
          iLINE_IT_2 := PRSG_EXCEL.LINE_APPEND(LINE_IT_2);
        else
          iLINE_IT_2 := PRSG_EXCEL.LINE_APPEND(LINE_IT_2, LINE_IT_1);
        end if;
        if sA1||sA2||sA3 is not null then
          sA3:=', '||sA1||'.'||sA2||'.'||sA3;
        end if;  
        PRSG_EXCEL.CELL_VALUE_WRITE(CELL_IT_ACC2, 0, iLINE_IT_2, '����� '||sSTR||sA3);
        PRSG_EXCEL.CELL_VALUE_WRITE(CELL_IT_SUM2, 0, iLINE_IT_2, nS3);
        iGROUP:=2;
      end if;
      if nS2 is not null then
        if iGROUP=2 then
          iLINE_IT_2 := PRSG_EXCEL.LINE_APPEND(LINE_IT_2);
        else
          iLINE_IT_2 := PRSG_EXCEL.LINE_APPEND(LINE_IT_2, LINE_IT_1);
        end if;
        if sA1||sA2 is not null then
          sA2:=', '||sA1||'.'||sA2;
        end if;  
        PRSG_EXCEL.CELL_VALUE_WRITE(CELL_IT_ACC2, 0, iLINE_IT_2, '����� '||sSTR||sA2);
        PRSG_EXCEL.CELL_VALUE_WRITE(CELL_IT_SUM2, 0, iLINE_IT_2, nS2);
        iGROUP:=2;
      end if;
      if nS1 is not null then
        if iGROUP=2 then
          iLINE_IT_2 := PRSG_EXCEL.LINE_APPEND(LINE_IT_2);
        else
          iLINE_IT_2 := PRSG_EXCEL.LINE_APPEND(LINE_IT_2, LINE_IT_1);
        end if;
        if sA1 is not null then
          sA1:=', '||sA1;
        end if;
        PRSG_EXCEL.CELL_VALUE_WRITE(CELL_IT_ACC2, 0, iLINE_IT_2, '����� '||sSTR||sA1);
        PRSG_EXCEL.CELL_VALUE_WRITE(CELL_IT_SUM2, 0, iLINE_IT_2, nS1);
        iGROUP:=2;
      end if;
      if nS0 is not null then
        if iGROUP=2 then
          iLINE_IT_2 := PRSG_EXCEL.LINE_APPEND(LINE_IT_2);
        else
          iLINE_IT_2 := PRSG_EXCEL.LINE_APPEND(LINE_IT_2, LINE_IT_1);
        end if;
        PRSG_EXCEL.CELL_VALUE_WRITE(CELL_IT_ACC2, 0, iLINE_IT_2, '����� '||sSTR);
        PRSG_EXCEL.CELL_VALUE_WRITE(CELL_IT_SUM2, 0, iLINE_IT_2, nS0);
        iGROUP:=2;
      end if;
      if nROW = nCOUNT then
        if iGROUP=2 then
          iLINE_IT_2 := PRSG_EXCEL.LINE_APPEND(LINE_IT_2);
        else
          iLINE_IT_2 := PRSG_EXCEL.LINE_APPEND(LINE_IT_2, LINE_IT_1);
        end if;
        PRSG_EXCEL.CELL_VALUE_WRITE(CELL_IT_ACC2, 0, iLINE_IT_2, '����� ');
        PRSG_EXCEL.CELL_VALUE_WRITE(CELL_IT_SUM2, 0, iLINE_IT_2, nALLSUMM);
        iGROUP:=2;
      end if;
    end loop;

    PRSG_EXCEL.LINE_DELETE(LINE_IT_1);
    PRSG_EXCEL.LINE_DELETE(LINE_IT_2);

    KOD_QUERY:=
'select acc,
       analytic_credit1, 
       analytic_credit2, 
       analytic_credit3, 
       analytic_credit4, 
       analytic_credit5, 
       acnt_sum,
       DECODE(p0, 1, null, DECODE(count(*) over (partition by acc),             p0, DECODE(p0, p1, null, sum(acnt_sum) over (partition by acc)           ), null)) as s0,
       DECODE(p1, 1, null, DECODE(count(*) over (partition by acc,a1),          p1, DECODE(p1, p2, null, sum(acnt_sum) over (partition by acc,a1)        ), null)) as s1,
       DECODE(p2, 1, null, DECODE(count(*) over (partition by acc,a1,a2),       p2, DECODE(p2, p3, null, sum(acnt_sum) over (partition by acc,a1,a2)     ), null)) as s2,
       DECODE(p3, 1, null, DECODE(count(*) over (partition by acc,a1,a2,a3),    p3, DECODE(p3, p4, null, sum(acnt_sum) over (partition by acc,a1,a2,a3)  ), null)) as s3,
       DECODE(p4, 1, null, DECODE(count(*) over (partition by acc,a1,a3,a3,a4), p4,                      sum(acnt_sum) over (partition by acc,a1,a3,a3,a4), null)) as s4,
       nrow,
       count(1) over() ncount,
       sum(acnt_sum) over() acnt_sum_all
from 
(
  select acc, a1, a2, a3, a4, acnt_sum,
         analytic_credit1, 
         analytic_credit2, 
         analytic_credit3, 
         analytic_credit4, 
         analytic_credit5, 
    row_number() over (order by acc,a1,a2,a3,a4) nrow,
    row_number() over (partition by acc             order by acc,a1,a2,a3,a4) as p0, 
    row_number() over (partition by acc,a1          order by acc,a1,a2,a3,a4) as p1, 
    row_number() over (partition by acc,a1,a2       order by acc,a1,a2,a3,a4) as p2, 
    row_number() over (partition by acc,a1,a2,a3    order by acc,a1,a2,a3,a4) as p3,
    row_number() over (partition by acc,a1,a2,a3,a4 order by acc,a1,a2,a3,a4) as p4
  from 
  (
    select SH.account_credit as acc,
           SH.analytic_credit1,
           DECODE(SH.analytic_credit1, null, DECODE(SH.analytic_credit2, null, DECODE(SH.analytic_credit3, null, DECODE(SH.analytic_credit4, null, SH.analytic_credit5, SH.analytic_credit4), SH.analytic_credit3), SH.analytic_credit2), SH.analytic_credit1) as a1, 
           SH.analytic_credit2,
           DECODE(SH.analytic_credit2, null, DECODE(SH.analytic_credit3, null, DECODE(SH.analytic_credit4, null, SH.analytic_credit5, SH.analytic_credit4), SH.analytic_credit3), SH.analytic_credit2) as a2, 
           SH.analytic_credit3,
           DECODE(SH.analytic_credit3, null, DECODE(SH.analytic_credit4, null, SH.analytic_credit5, SH.analytic_credit4), SH.analytic_credit3) as a3,
           SH.analytic_credit4,
           DECODE(SH.analytic_credit4, null, SH.analytic_credit5, SH.analytic_credit4) as a4, 
           SH.analytic_credit5,
           sum(SH.acnt_sum) as acnt_sum
      from ('||KOD_SPEC||') SH, ('||KOD_BEFORE_SPEC||') M where SH.PRN = M.RN and SH.account_credit is not null
       group by SH.account_credit,
           SH.analytic_credit1, 
           SH.analytic_credit2, 
           SH.analytic_credit3,
           SH.analytic_credit4, 
           SH.analytic_credit5
  )
)';

    iGROUP:=1;       
    open QUERY_CUR for KOD_QUERY;
    loop
      fetch QUERY_CUR into sSTR, sA1, sA2, sA3, sA4, sA5, nS5, nS0, nS1, nS2, nS3, nS4, nROW, nCOUNT, nALLSUMM;
      exit when QUERY_CUR%notfound;

      if iGROUP=1 then
        iLINE_IT_3 := PRSG_EXCEL.LINE_APPEND(LINE_IT_3);
      else
        iLINE_IT_3 := PRSG_EXCEL.LINE_APPEND(LINE_IT_3, LINE_IT_4);
      end if;

      sSTR:=SubStr(sSTR,1,17)||' '||SubStr(sSTR,18,1)||' '||SubStr(sSTR,19,3)||' '||SubStr(sSTR,22,2)||' '||SubStr(sSTR,24,50);
      if sA1||sA2||sA3||sA4||sA5 is not null then
        sA5:=', '||sA1||'.'||sA2||'.'||sA3||'.'||sA4||'.'||sA5;
      end if;  
      PRSG_EXCEL.CELL_VALUE_WRITE(CELL_IT_ACC3, 0, iLINE_IT_3, sSTR||sA5);
      PRSG_EXCEL.CELL_VALUE_WRITE(CELL_IT_SUM3, 0, iLINE_IT_3, nS5);
      iGROUP:=1;
      
      if nS4 is not null then
        iLINE_IT_4 := PRSG_EXCEL.LINE_APPEND(LINE_IT_4, LINE_IT_3);
        if sA1||sA2||sA3||sA4 is not null then
          sA4:=', '||sA1||'.'||sA2||'.'||sA3||'.'||sA4;
        end if;  
        PRSG_EXCEL.CELL_VALUE_WRITE(CELL_IT_ACC4, 0, iLINE_IT_4, '����� '||sSTR||sA4);
        PRSG_EXCEL.CELL_VALUE_WRITE(CELL_IT_SUM4, 0, iLINE_IT_4, nS4);
        iGROUP:=2;
      end if;
      if nS3 is not null then
        if iGROUP=2 then
          iLINE_IT_4 := PRSG_EXCEL.LINE_APPEND(LINE_IT_4);
        else
          iLINE_IT_4 := PRSG_EXCEL.LINE_APPEND(LINE_IT_4, LINE_IT_3);
        end if;
        if sA1||sA2||sA3 is not null then
          sA3:=', '||sA1||'.'||sA2||'.'||sA3;
        end if;  
        PRSG_EXCEL.CELL_VALUE_WRITE(CELL_IT_ACC4, 0, iLINE_IT_4, '����� '||sSTR||sA3);
        PRSG_EXCEL.CELL_VALUE_WRITE(CELL_IT_SUM4, 0, iLINE_IT_4, nS3);
        iGROUP:=2;
      end if;
      if nS2 is not null then
        if iGROUP=2 then
          iLINE_IT_4 := PRSG_EXCEL.LINE_APPEND(LINE_IT_4);
        else
          iLINE_IT_4 := PRSG_EXCEL.LINE_APPEND(LINE_IT_4, LINE_IT_3);
        end if;
        if sA1||sA2 is not null then
          sA2:=', '||sA1||'.'||sA2;
        end if;  
        PRSG_EXCEL.CELL_VALUE_WRITE(CELL_IT_ACC4, 0, iLINE_IT_4, '����� '||sSTR||sA2);
        PRSG_EXCEL.CELL_VALUE_WRITE(CELL_IT_SUM4, 0, iLINE_IT_4, nS2);
        iGROUP:=2;
      end if;
      if nS1 is not null then
        if iGROUP=2 then
          iLINE_IT_4 := PRSG_EXCEL.LINE_APPEND(LINE_IT_4);
        else
          iLINE_IT_4 := PRSG_EXCEL.LINE_APPEND(LINE_IT_4, LINE_IT_3);
        end if;
        if sA1 is not null then
          sA1:=', '||sA1;
        end if;  
        PRSG_EXCEL.CELL_VALUE_WRITE(CELL_IT_ACC4, 0, iLINE_IT_4, '����� '||sSTR||sA1);
        PRSG_EXCEL.CELL_VALUE_WRITE(CELL_IT_SUM4, 0, iLINE_IT_4, nS1);
        iGROUP:=2;
      end if;
      if nS0 is not null then
        if iGROUP=2 then
          iLINE_IT_4 := PRSG_EXCEL.LINE_APPEND(LINE_IT_4);
        else
          iLINE_IT_4 := PRSG_EXCEL.LINE_APPEND(LINE_IT_4, LINE_IT_3);
        end if;
        PRSG_EXCEL.CELL_VALUE_WRITE(CELL_IT_ACC4, 0, iLINE_IT_4, '����� '||sSTR);
        PRSG_EXCEL.CELL_VALUE_WRITE(CELL_IT_SUM4, 0, iLINE_IT_4, nS0);
        iGROUP:=2;
      end if;

      if nROW = nCOUNT then
        if iGROUP=2 then
          iLINE_IT_4 := PRSG_EXCEL.LINE_APPEND(LINE_IT_4);
        else
          iLINE_IT_4 := PRSG_EXCEL.LINE_APPEND(LINE_IT_4, LINE_IT_3);
        end if;
        PRSG_EXCEL.CELL_VALUE_WRITE(CELL_IT_ACC4, 0, iLINE_IT_4, '����� ');
        PRSG_EXCEL.CELL_VALUE_WRITE(CELL_IT_SUM4, 0, iLINE_IT_4, nALLSUMM);
        iGROUP:=2;
      end if;


    end loop;
    
    PRSG_EXCEL.LINE_DELETE(LINE_IT_3);
    PRSG_EXCEL.LINE_DELETE(LINE_IT_4);

  else
    p_exception(0,'����� ������� �� ������');
  end if;  
end P_UA_JORNAL_XO_ITOG9207;
/
