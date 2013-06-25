create or replace procedure P_UA_JORNAL_XO9207
(
  sSQL_IN               in varchar2
)
is
  sSQL                  PKG_STD.tLSTRING; --�������� ��� ������� ��� order by
  sORDER                PKG_STD.tLSTRING := '';
  LEN_KOD_SPEC          integer;         --����� ������� � ����������, �� ����������� ������
  START_POS_SPEC        integer;         --������ ������� � ����������
  STEK_SKOB             number;          --���� ������
  i                     integer;         --��� ����� (�� ���� ��� ��� ��)
  S                     varchar2(1);     --����������� ������
  KOD_SPEC              PKG_STD.tLSTRING; --����� ������� � ����������
  KOD_BEFORE_SPEC       PKG_STD.tLSTRING; --����� �� ������� � ����������
  KOD_QUERY             PKG_STD.tLSTRING; --����� ��������������� �������
  
  QUERY_CUR             PKG_CURSORS.CurType;
  QUERY_FETCH           V_UA_OPRSPECS%rowtype;
  
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
  
  nPP                   number; --����� �� �� ������
  OLD_PRN               number; --������� ������ ���������
  iGROUP                number; --����������� ������ �����
  nITOG1                number; --����� �������� ��
  nITOG2                number; --����� ��
  
  iLINE_ZAG             integer;
  iLINE_SPEC            integer;
  iLINE_ITOG            integer;

  SHEET_FORM            constant PKG_STD.tSTRING := '������ �����������';
  LINE_ZAG              constant PKG_STD.tSTRING := 'Line_Zag';
  CELL_NPP              constant PKG_STD.tSTRING := '�������';
  CELL_CONTENT          constant PKG_STD.tSTRING := '������������������';
  CELL_DOCUMENT         constant PKG_STD.tSTRING := '��������';
  CELL_ZAG_DT           constant PKG_STD.tSTRING := '���_�����';
  CELL_ZAG_KT           constant PKG_STD.tSTRING := '���_������';
  CELL_ZAG_SUM          constant PKG_STD.tSTRING := '���_������������';

  LINE_SPEC             constant PKG_STD.tSTRING := 'Line_Spec';
  CELL_TMC              constant PKG_STD.tSTRING := '���';
  CELL_DT               constant PKG_STD.tSTRING := '�����';
  CELL_KT               constant PKG_STD.tSTRING := '������';
  CELL_SUM              constant PKG_STD.tSTRING := '������������';
  
  LINE_ITOG             constant PKG_STD.tSTRING := 'Line_Itog';
  CELL_ITOG_XO          constant PKG_STD.tSTRING := '������';
  CELL_ITOG_XO_SUM      constant PKG_STD.tSTRING := '������_�����';
  
  CELL_ITOG_ALL         constant PKG_STD.tSTRING := '���������������';
  
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
  
  if sSQL_IN is not null then
    
    --����������� order by ����� ������, ����������� �� ����
    i:=InStr(sSQL_IN, 'order by');
    sORDER := SubStr(sSQL_IN, i-2);
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
          KOD_SPEC:=replace(KOD_SPEC,'COMPANY','OP.RN = SH.RN and SH.COMPANY');
          KOD_BEFORE_SPEC:=KOD_BEFORE_SPEC||SubStr(sSQL, i+START_POS_SPEC);
  
          exit;
        end if;  
      end loop;
    end if;
    --p_exception(0, KOD_SPEC);
    --������� �� �������� �����������
    if KOD_SPEC is null then
      KOD_SPEC := 'select OP.* from V_OPRSPECS OP, V_OPRSPECS_SHADOW SH where OP.RN = SH.RN';
    end if;

    --������������� ����� �� �����, ��� � oprspec ��� ����, � �� prn
    KOD_QUERY:='select SH.rn, SH.prn, SH.company, SH.operation_date, SH.currency,
                       SH.balunit_debit, SH.account_debit, SH.account_debit_currency, 
                       SH.nbalunit_debit, SH.sbalunit_debit, 
                       SH.analytic_debit1, SH.analytic_debit2, SH.analytic_debit3, SH.analytic_debit4, SH.analytic_debit5, 
                       SH.balunit_credit, SH.account_credit, SH.account_credit_currency, 
                       SH.analytic_credit1, SH.analytic_credit2, SH.analytic_credit3, SH.analytic_credit4, SH.analytic_credit5, 
                       SH.nbalunit_credit, SH.sbalunit_credit, 
                       SH.acnt_sum, SH.acnt_base_sum, SH.acnt_quant, SH.acnt_alt_quant, SH.acnt_equal, 
                       SH.ctrl_sum, SH.ctrl_base_sum, SH.ctrl_quant, SH.ctrl_alt_quant, SH.ctrl_equal, 
                       SH.nomen_code, SH.nomen_name, SH.nomen_meas, SH.nomen_ameas, SH.nomen_partno, SH.nomen_indate, SH.nomen_crn, 
                       SH.alt_sign1, SH.alt_sign2, SH.alt_sign3, SH.alt_sign4, SH.alt_sign5, SH.alt_sign6, SH.alt_sign7, SH.alt_sign8, SH.alt_sign9, SH.alt_sign10, 
                       SH.order_rn, SH.order_numb, SH.record_type, SH.dopercards_charge, 
                       SH.nacctypes, SH.sacctypes_code, SH.nacctypes_type, SH.sacctypes_currency, SH.nacnt_acctypes_sum, SH.nctrl_acctypes_sum, 
                       M.crn, M.njur_pers, M.sjur_pers, M.operation_pref, M.operation_numb, 
                       M.operation_contents, M.special_mark, M.valid_doctype, M.valid_docnumb, M.valid_docdate, 
                       M.fact_doctype, M.fact_docnumb, M.fact_docdate, M.agent_from, M.agent_to, 
                       M.crn_from, M.crn_to, M.acnt_opersum, M.ctrl_opersum, M.special_mark_rn, 
                       M.valid_doctype_rn, M.fact_doctype_rn, M.agent_from_rn, M.agent_to_rn, M.eo_in, M.eo_out, 
                       M.nescort_doctype, M.sescort_doctype, M.sescort_docnumb, M.descort_docdate from ('||KOD_SPEC||') SH, ('||KOD_BEFORE_SPEC||') M where SH.PRN = M.RN '||sORDER; --order by operation_date, prn';

    --������� excel
    
    PRSG_EXCEL.PREPARE;
    PRSG_EXCEL.SHEET_SELECT(SHEET_FORM);
    
    PRSG_EXCEL.LINE_DESCRIBE(LINE_ZAG);
    PRSG_EXCEL.LINE_CELL_DESCRIBE(LINE_ZAG, CELL_NPP);
    PRSG_EXCEL.LINE_CELL_DESCRIBE(LINE_ZAG, CELL_CONTENT);
    PRSG_EXCEL.LINE_CELL_DESCRIBE(LINE_ZAG, CELL_DOCUMENT);
    PRSG_EXCEL.LINE_CELL_DESCRIBE(LINE_ZAG, CELL_ZAG_DT);
    PRSG_EXCEL.LINE_CELL_DESCRIBE(LINE_ZAG, CELL_ZAG_KT);
    PRSG_EXCEL.LINE_CELL_DESCRIBE(LINE_ZAG, CELL_ZAG_SUM);
  
    PRSG_EXCEL.LINE_DESCRIBE(LINE_SPEC);
    PRSG_EXCEL.LINE_CELL_DESCRIBE(LINE_SPEC, CELL_TMC);
    PRSG_EXCEL.LINE_CELL_DESCRIBE(LINE_SPEC, CELL_DT);
    PRSG_EXCEL.LINE_CELL_DESCRIBE(LINE_SPEC, CELL_KT);
    PRSG_EXCEL.LINE_CELL_DESCRIBE(LINE_SPEC, CELL_SUM);
    
    PRSG_EXCEL.LINE_DESCRIBE(LINE_ITOG);
    PRSG_EXCEL.LINE_CELL_DESCRIBE(LINE_ITOG, CELL_ITOG_XO);
    PRSG_EXCEL.LINE_CELL_DESCRIBE(LINE_ITOG, CELL_ITOG_XO_SUM);
    
    PRSG_EXCEL.CELL_DESCRIBE(CELL_ITOG_ALL);
    
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



  --������ ������ � ����� ������� � excel
    nPP:=0;
    OLD_PRN:=0;
    i:=0;
    nITOG1:=0;
    nITOG2:=0;
    iGROUP:=1; --1 - ��������� ZAG, 2 - ��������� SPEC, 3 - ��������� ITOG

    open QUERY_CUR for KOD_QUERY;
    loop
      fetch QUERY_CUR into QUERY_FETCH;
      exit when QUERY_CUR%notfound;
      
      
--      p_exception(0, QUERY_FETCH.analytic_debit5);
      
      --��������� �����������
      --��������� � ���������� (����� ���� �������)
      if QUERY_FETCH.PRN!=OLD_PRN then

        --����� ����� ���������� ������
        if i>1 then
          iLINE_ITOG := PRSG_EXCEL.LINE_APPEND(LINE_ITOG, LINE_SPEC);
          iGROUP:=3;
          PRSG_EXCEL.CELL_VALUE_WRITE(CELL_ITOG_XO, 0, iLINE_ITOG, '�����');
          PRSG_EXCEL.CELL_VALUE_WRITE(CELL_ITOG_XO_SUM, 0, iLINE_ITOG, nITOG1);
        end if;

      
        for m in (select * from V_ECONOPRS where RN=QUERY_FETCH.PRN)
        loop
          nPP:=nPP+1;
          i:=0;
          nITOG2:=nITOG2+nITOG1;
          nITOG1:=0;
          
          case iGROUP
          when 1 then iLINE_ZAG := PRSG_EXCEL.LINE_APPEND(LINE_ZAG);
          when 2 then iLINE_ZAG := PRSG_EXCEL.LINE_APPEND(LINE_ZAG, LINE_SPEC);
          else iLINE_ZAG := PRSG_EXCEL.LINE_APPEND(LINE_ZAG, LINE_ITOG);
          end case;
          iGROUP:=1;
          
          OLD_PRN:=QUERY_FETCH.PRN;
          PRSG_EXCEL.CELL_VALUE_WRITE(CELL_NPP, 0, iLINE_ZAG, nPP);
          
          PRSG_EXCEL.CELL_VALUE_WRITE(CELL_CONTENT, 0, iLINE_ZAG, 
          trim(m.agent_from)||' / '||trim(m.agent_to)||' / '||trim(m.operation_contents));
          
          --�������� �������: ���� ���� ���� ���� �������� �� ���������, �� ������� ��������
          PRSG_EXCEL.CELL_VALUE_WRITE(CELL_DOCUMENT, 0, iLINE_ZAG, 
          PKG_EXT.IIF(m.valid_doctype is null and m.valid_docnumb is null and m.valid_docdate is null, '', trim(m.valid_doctype)||', '||trim(m.valid_docnumb)||', '||trim(to_char(m.valid_docdate, 'dd.mm.yyyy'))||';'||Chr(13))||
          PKG_EXT.IIF(m.fact_doctype is null and m.fact_docnumb is null and m.fact_docdate is null, '', trim(m.fact_doctype)||', '||trim(m.fact_docnumb)||', '||trim(to_char(m.fact_docdate, 'dd.mm.yyyy'))||';'||Chr(13))||
          PKG_EXT.IIF(m.sescort_doctype is null and m.sescort_docnumb is null and m.descort_docdate is null, '', trim(m.sescort_doctype)||', '||trim(m.sescort_docnumb)||', '||trim(to_char(m.descort_docdate, 'dd.mm.yyyy'))||';'||Chr(13))||
          '���� �� '||trim(to_char(m.operation_date, 'dd.mm.yyyy')));
          
          if QUERY_FETCH.nomen_code is null then --���� �������� �� ����� ������������, ������� � ������ � ����������
            
            sSTR:=QUERY_FETCH.account_debit;
            if sSTR is not null then
              sSTR:=SubStr(sSTR,1,17)||' '||SubStr(sSTR,18,1)||' '||SubStr(sSTR,19,3)||' '||SubStr(sSTR,22,2)||' '||SubStr(sSTR,24,16);
              if QUERY_FETCH.analytic_debit1||QUERY_FETCH.analytic_debit2||QUERY_FETCH.analytic_debit3||QUERY_FETCH.analytic_debit4||QUERY_FETCH.analytic_debit5 is not null then
                sSTR:=sSTR||', '||QUERY_FETCH.analytic_debit1||'.'||QUERY_FETCH.analytic_debit2||'.'||QUERY_FETCH.analytic_debit3||'.'||QUERY_FETCH.analytic_debit4||'.'||QUERY_FETCH.analytic_debit5;
              end if;
              PRSG_EXCEL.CELL_VALUE_WRITE(CELL_ZAG_DT, 0, iLINE_ZAG, sSTR);
            end if;

            sSTR:=QUERY_FETCH.account_credit;
            if sSTR is not null then
              sSTR:=SubStr(sSTR,1,17)||' '||SubStr(sSTR,18,1)||' '||SubStr(sSTR,19,3)||' '||SubStr(sSTR,22,2)||' '||SubStr(sSTR,24,16);
              if QUERY_FETCH.analytic_credit1||QUERY_FETCH.analytic_credit2||QUERY_FETCH.analytic_credit3||QUERY_FETCH.analytic_credit4||QUERY_FETCH.analytic_credit5 is not null then
                sSTR:=sSTR||', '||QUERY_FETCH.analytic_credit1||'.'||QUERY_FETCH.analytic_credit2||'.'||QUERY_FETCH.analytic_credit3||'.'||QUERY_FETCH.analytic_credit4||'.'||QUERY_FETCH.analytic_credit5;
              end if;
              PRSG_EXCEL.CELL_VALUE_WRITE(CELL_ZAG_KT, 0, iLINE_ZAG, sSTR);
            end if;
            
            PRSG_EXCEL.CELL_VALUE_WRITE(CELL_ZAG_SUM, 0, iLINE_ZAG, QUERY_FETCH.acnt_base_sum);
            nITOG1:=nITOG1+QUERY_FETCH.acnt_base_sum;
          end if;
          
        end loop;
      end if;

      --��������� ��������� ����� �������� ���������
      if not (QUERY_FETCH.nomen_code is null and i=0) then
        if iGROUP=1 then 
          iLINE_SPEC := PRSG_EXCEL.LINE_APPEND(LINE_SPEC, LINE_ZAG);
        else 
          iLINE_SPEC := PRSG_EXCEL.LINE_APPEND(LINE_SPEC);
        end if;
        iGROUP:=2;
        
        if QUERY_FETCH.nomen_code is not null then
          PRSG_EXCEL.CELL_VALUE_WRITE(CELL_TMC, 0, iLINE_SPEC, trim(QUERY_FETCH.nomen_name)||', '||trim(to_char(QUERY_FETCH.acnt_quant, '99999999999,999'))||trim(QUERY_FETCH.nomen_meas));
        end if;
        
        sSTR:=QUERY_FETCH.account_debit;
        if sSTR is not null then
          sSTR:=SubStr(sSTR,1,17)||' '||SubStr(sSTR,18,1)||' '||SubStr(sSTR,19,3)||' '||SubStr(sSTR,22,2)||' '||SubStr(sSTR,24,16);
          if QUERY_FETCH.analytic_debit1||QUERY_FETCH.analytic_debit2||QUERY_FETCH.analytic_debit3||QUERY_FETCH.analytic_debit4||QUERY_FETCH.analytic_debit5 is not null then
            sSTR:=sSTR||', '||QUERY_FETCH.analytic_debit1||'.'||QUERY_FETCH.analytic_debit2||'.'||QUERY_FETCH.analytic_debit3||'.'||QUERY_FETCH.analytic_debit4||'.'||QUERY_FETCH.analytic_debit5;
          end if;
          PRSG_EXCEL.CELL_VALUE_WRITE(CELL_DT, 0, iLINE_SPEC, sSTR);
        end if;

        sSTR:=QUERY_FETCH.account_credit;
        if sSTR is not null then
          sSTR:=SubStr(sSTR,1,17)||' '||SubStr(sSTR,18,1)||' '||SubStr(sSTR,19,3)||' '||SubStr(sSTR,22,2)||' '||SubStr(sSTR,24,16);
          if QUERY_FETCH.analytic_credit1||QUERY_FETCH.analytic_credit2||QUERY_FETCH.analytic_credit3||QUERY_FETCH.analytic_credit4||QUERY_FETCH.analytic_credit5 is not null then
            sSTR:=sSTR||', '||QUERY_FETCH.analytic_credit1||'.'||QUERY_FETCH.analytic_credit2||'.'||QUERY_FETCH.analytic_credit3||'.'||QUERY_FETCH.analytic_credit4||'.'||QUERY_FETCH.analytic_credit5;
          end if;
          PRSG_EXCEL.CELL_VALUE_WRITE(CELL_KT, 0, iLINE_SPEC, sSTR);
        end if;
              
        PRSG_EXCEL.CELL_VALUE_WRITE(CELL_SUM, 0, iLINE_SPEC, QUERY_FETCH.acnt_base_sum);
        nITOG1:=nITOG1+QUERY_FETCH.acnt_base_sum;
      end if;
      i:=i+1; -- ����������� ���������� �������� � ��
      
    end loop;
    
    --������� ��������� �����, ���� ��� �����
    if i>1 then
      iLINE_ITOG := PRSG_EXCEL.LINE_APPEND(LINE_ITOG, LINE_SPEC);
      iGROUP:=3;
      PRSG_EXCEL.CELL_VALUE_WRITE(CELL_ITOG_XO, 0, iLINE_ITOG, '�����');
      PRSG_EXCEL.CELL_VALUE_WRITE(CELL_ITOG_XO_SUM, 0, iLINE_ITOG, nITOG1);
    end if;
    
    --������� �����
    PRSG_EXCEL.CELL_VALUE_WRITE(CELL_ITOG_ALL, nITOG1+nITOG2);
    PRSG_EXCEL.LINE_DELETE(LINE_ZAG);
    PRSG_EXCEL.LINE_DELETE(LINE_SPEC);
    PRSG_EXCEL.LINE_DELETE(LINE_ITOG);
    PRSG_EXCEL.LINE_DELETE(LINE_USL_OTBOR);
    close QUERY_CUR;


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
       DECODE(p4, 1, null, DECODE(count(*) over (partition by acc,a1,a3,a3,a4), p4,                      sum(acnt_sum) over (partition by acc,a1,a3,a3,a4), null)) as s4
from 
(
  select acc, a1, a2, a3, a4, acnt_sum,
         analytic_debit1, 
         analytic_debit2, 
         analytic_debit3, 
         analytic_debit4, 
         analytic_debit5, 
    row_number() over (partition by acc             order by acc) as p0, 
    row_number() over (partition by acc,a1          order by acc,a1) as p1, 
    row_number() over (partition by acc,a1,a2       order by acc,a1,a2) as p2, 
    row_number() over (partition by acc,a1,a2,a3    order by acc,a1,a2,a3) as p3,
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

--  p_exception(0, length(KOD_QUERY));
  
    iGROUP:=1;       
    open QUERY_CUR for KOD_QUERY;
    loop
      fetch QUERY_CUR into sSTR, sA1, sA2, sA3, sA4, sA5, nS5, nS0, nS1, nS2, nS3, nS4;
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
       DECODE(p4, 1, null, DECODE(count(*) over (partition by acc,a1,a3,a3,a4), p4,                      sum(acnt_sum) over (partition by acc,a1,a3,a3,a4), null)) as s4
from 
(
  select acc, a1, a2, a3, a4, acnt_sum,
         analytic_credit1, 
         analytic_credit2, 
         analytic_credit3, 
         analytic_credit4, 
         analytic_credit5, 
    row_number() over (partition by acc             order by acc) as p0, 
    row_number() over (partition by acc,a1          order by acc,a1) as p1, 
    row_number() over (partition by acc,a1,a2       order by acc,a1,a2) as p2, 
    row_number() over (partition by acc,a1,a2,a3    order by acc,a1,a2,a3) as p3,
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
      fetch QUERY_CUR into sSTR, sA1, sA2, sA3, sA4, sA5, nS5, nS0, nS1, nS2, nS3, nS4;
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

    end loop;
    
    PRSG_EXCEL.LINE_DELETE(LINE_IT_3);
    PRSG_EXCEL.LINE_DELETE(LINE_IT_4);

  else
    p_exception(0,'����� ������� �� ������');
  end if;  
end P_UA_JORNAL_XO9207;
/
