create or replace procedure P_IMPORT7_INVENTORY
as
  nCOMPANY                  PKG_STD.tREF;
  nINV_RN                   PKG_STD.tREF;
  nHST_RN                   PKG_STD.tREF;
  nACCOUNT                  PKG_STD.tREF;
  nACCTYPES                 PKG_STD.tREF;
  sOBJECT_GROUP             INVENTORY.OBJECT_GROUP%type;
  sOBJECT_NUMBER            INVENTORY.OBJECT_NUMBER%type;
  sCARD_PREF                INVENTORY.CARD_PREF%type;
  sCARD_NUMB                INVENTORY.CARD_NUMB%type;
  sINV_NUMBER               INVENTORY.INV_NUMBER%type;
  nMAIN_JUR_PERS            PKG_STD.tREF;
  sTMP                      PKG_STD.tSTRING;
  nCRN                      PKG_STD.tREF;
  nJUR_PERS                 PKG_STD.tREF;
  nOBJ_STATUS               INVENTORY.OBJ_STATUS%type;
  nOKOF                     PKG_STD.tREF;
  sOKOF_CODE                OKOF.CODE%type;
  sOKOF_NAME                OKOF.NAME%type;
  sOKOF_FULLNAME            OKOF.FULLNAME%type;
  nOKOF_HIER_LEVEL          OKOF.HIER_LEVEL%type;
  sTAX_GROUP                INVTAXGR.CODE%type;
  sCLASS_PREF               INVENTORY.CLASS_PREF%type;
  sCLASS_NUMB               INVENTORY.CLASS_NUMB%type;
  nOBJECT_PLACE             PKG_STD.tREF;
  nAMORT_TYPE               INVENTORY.AMORT_TYPE%type;
  nCARD_TYPE                INVENTORY.CARD_TYPE%type;
  nITEM_COUNT               INVENTORY.ITEM_COUNT%type;
  nA_TERM_USE_REST          INVENTORY.A_TERM_USE_REST%type;
  nUSE_COST_END             INVENTORY.USE_COST_END%type;
  nINV_NUMB_SIGN            INVENTORY.INV_NUMB_SIGN%type;

  nACTION_TYPE              INVHIST.ACTION_TYPE%type;
  nOPER_TYPE                INVHIST.OPER_TYPE%type;
  nMOVE_TYPE                INVHIST.MOVE_TYPE%type;
  nCONSERV_TYPE             INVHIST.CONSERV_TYPE%type;
  nAMORT_YEAR               INVHIST.AMORT_YEAR%type;

  nA_COST_BEGIN             PKG_STD.tSUMM;
  nAB_COST_BEGIN            PKG_STD.tSUMM;
  nA_AMORT_BEGIN            PKG_STD.tSUMM;
  nAB_AMORT_BEGIN           PKG_STD.tSUMM;
  nA_AMORT_DURING           PKG_STD.tSUMM;
  nAB_AMORT_DURING          PKG_STD.tSUMM;
  nA_COST_END               PKG_STD.tSUMM;
  nAB_COST_END              PKG_STD.tSUMM;

  nSUBST                    PKG_STD.tREF;
  sSUBST_NOTE               INVSUBST.NOTE%type;
  nPACK                     PKG_STD.tREF;
  nINCOME_SUM_A             PKG_STD.tSUMM;
  nINCOME_SUM_AB            PKG_STD.tSUMM;

  nECONOPRS                 PKG_STD.tREF;
  nOPRSPECS                 PKG_STD.tREF;

  /* ������������ ����������� ������ � ������������ ������ �������� */
  procedure SET_INV_NUMBER
  (
    sGROUP_INV              in varchar2,
    sNUM_INV                in varchar2,
    sOUT_OBJECT_GROUP       out varchar2,
    sOUT_OBJECT_NUMBER      out varchar2,
    sOUT_INV_NUMBER         out varchar2
  )
  as
  begin
    /* ��������������� ������������ */
    -- ����������� ������ (�������)
    sOUT_OBJECT_GROUP  := substr(lpad(strtrim(sGROUP_INV),3,'0')||lpad(strtrim(sNUM_INV),15,'0'),1,8);
    sOUT_OBJECT_GROUP  := strright(strtrim(sOUT_OBJECT_GROUP),10);
    -- ����������� ������ (�����)
    sOUT_OBJECT_NUMBER := substr(lpad(strtrim(sGROUP_INV),3,'0')||lpad(strtrim(sNUM_INV),15,'0'),9);
    sOUT_OBJECT_NUMBER := strright(strtrim(sOUT_OBJECT_NUMBER),10);

    -- ����������� �����
    sOUT_INV_NUMBER := strtrim(sOUT_OBJECT_GROUP)||GET_OPTIONS_STR('PrefSymb')||strtrim(sOUT_OBJECT_NUMBER);
    sOUT_INV_NUMBER := strright(strtrim(sOUT_INV_NUMBER),40);
  end SET_INV_NUMBER;

  /* ������������ �������� �������� */
  function GET_CARD_PREF
  (
    nACCTYPES               in number,
    sCARD_NUMB              in varchar2
  )
  return varchar2
  as
    sRESULT                 PKG_STD.tSTRING;
    sRESULT1                PKG_STD.tSTRING;
    nTMP_RN                 PKG_STD.tREF;
  begin
    sRESULT := nvl(GET_OPTIONS_STR( 'InvCardPref', nCOMPANY ), '1');
    sRESULT := STRRIGHT( sRESULT, 10 );

    /* ����� �������� �� �������� � ������ */
    begin
      select /*+ INDEX(INVENTORY C_INVENTORY_CARD_UK) */ RN
        into nTMP_RN
        from INVENTORY
       where CARD_NUMB = sCARD_NUMB
         and CARD_PREF = sRESULT
         and ACCTYPES  = nACCTYPES
         and COMPANY   = nCOMPANY;
    exception
      when NO_DATA_FOUND then
        nTMP_RN := null;
    end;

    /* ���� ������� - ���������� ���������� ������� */
    if nTMP_RN is not null then

      /* ����� ������������� �������� */
      begin
       select max( CARD_PREF )
         into sRESULT1
         from INVENTORY
        where CARD_NUMB = sCARD_NUMB
          and ACCTYPES  = nACCTYPES
          and COMPANY   = nCOMPANY;
      exception
        when NO_DATA_FOUND then
          sRESULT1 := null;
      end;

      /* ��������� */
      PKG_DOCUMENT.NEXT_NUMBER( sRESULT1, 10, sRESULT );
    end if;

    return sRESULT;
  end GET_CARD_PREF;

  /* �����/�������� ��������������� */
  function GET_DICPLACE
  (
    nAGENT                  in number
  )
  return number
  as
    nRESULT                 PKG_STD.tREF;
    sCODE                   DICPLACE.PLACE_MNEMO%type;
    sNAME                   DICPLACE.PLACE_NAME%type;
    nDICPLACE_CRN           PKG_STD.tREF;
  begin
    nRESULT := null;

    if nAGENT is not null then
      /* ���������� ����������� */
      begin
        select AGNABBR, substr(AGNNAME,1,80)
          into sCODE, sNAME
          from AGNLIST
         where RN = nAGENT;
      exception
        when NO_DATA_FOUND then
          PKG_MSG.RECORD_NOT_FOUND( nAGENT, 'AGNLIST' );
      end;

      /* ����� ��������������� �� ��������� */
      FIND_DICPLACE_SMART_MNEMO( 1, nCOMPANY, sCODE, nRESULT );

      if nRESULT is null then
        /* ������� ��������������� */
        FIND_ROOT_CATALOG( nCOMPANY, 'ObjPlace', nDICPLACE_CRN );

        /* ������������ ��������������� */
        sNAME := PKG_EXECUTE.FIND_UNIQUE_COLUMN_VALUE( 'DICPLACE', 'COMPANY', nCOMPANY, 'PLACE_NAME', sNAME );

        /* ���������� ��������������� */
        P_DICPLACE_BASE_INSERT( nCOMPANY, nDICPLACE_CRN, sCODE, sNAME, null, null, nRESULT );
      end if;
    end if;

    return nRESULT;
  end GET_DICPLACE;

  /* ���������� ����������� �������� */
  procedure INVENTORY_INSERT
  (
    nCOMPANY                in number,
    nCRN                    in number,
    nJUR_PERS               in number,
    nINVOBJECT              in number,
    nINVOBJCL               in number,
    sINVOBJCL_NAME          in varchar2,
    nOBJ_STATUS             in number,
    nACCOUNT                in number,
    nANALYTIC1              in number,
    nANALYTIC2              in number,
    nANALYTIC3              in number,
    nANALYTIC4              in number,
    nANALYTIC5              in number,
    nBALUNIT                in number,
    nCURRENCY               in number,
    nEXECUTIVE              in number,
    sOBJECT_GROUP           in varchar2,
    sOBJECT_NUMBER          in varchar2,
    sINV_NUMBER             in varchar2,
    sCARD_PREF              in varchar2,
    sCARD_NUMB              in varchar2,
    nNOMENCLATURE           in number,
    sCLASS_PREF             in varchar2,
    sCLASS_NUMB             in varchar2,
    nOKOF                   in number,
    sOBJECT_NOTE            in varchar2,
    sOBJECT_MODEL           in varchar2,
    nOBJECT_PLACE           in number,
    sWORS_NUMBER            in varchar2,
    nPRODUCER               in number,
    nA_COST_BEGIN           in number,
    nAB_COST_BEGIN          in number,
    nC_COST_BEGIN           in number,
    nCB_COST_BEGIN          in number,
    nA_SUM_FUND             in number,
    nAB_SUM_FUND            in number,
    nC_SUM_FUND             in number,
    nCB_SUM_FUND            in number,
    nA_AMORT_BEGIN          in number,
    nAB_AMORT_BEGIN         in number,
    nC_AMORT_BEGIN          in number,
    nCB_AMORT_BEGIN         in number,
    dAMORT_DURING_DATE      in date,
    nA_AMORT_DURING         in number,
    nAB_AMORT_DURING        in number,
    nC_AMORT_DURING         in number,
    nCB_AMORT_DURING        in number,
    nA_COST_END             in number,
    nAB_COST_END            in number,
    nC_COST_END             in number,
    nCB_COST_END            in number,
    nAMORT_RN               in number,
    nAMORT_TYPE             in number,
    nACNT_TERM_USE          in number,
    nCTRL_TERM_USE          in number,
    nAMORT_FAST             in number,
    nCAMORT_FAST            in number,
    nCARD_TYPE              in number,
    dRELEASE_DATE           in date,
    dINCOME_DATE            in date,
    nITEM_COUNT             in number,
    nSUBDIV                 in number,
    nACNT_RUN               in number,
    nCTRL_RUN               in number,
    nA_TERM_USE_REST        in number,
    nC_TERM_USE_REST        in number,
    nTAX_GROUP              in number,
    nTAX_SUBGROUP           in number,
    nUSE_COST_END           in number,
    nACCTYPES               in number,
    nAMORT_FROM_BEGIN       in number,
    nAMORT_SUM_CAP          in number,
    nOPER_RULE              in number,
    nSTATE_REGIST           in number,
    nASSETS_LIMIT           in number,
    nTAXOBJTYPES            in number,
    nA_SUM_CAP              in number,
    nAB_SUM_CAP             in number,
    nC_SUM_CAP              in number,
    nCB_SUM_CAP             in number,
    nINV_NUMB_SIGN          in number,
    sBARCODE                in varchar2,
    dLABEL_DATE             in date,
    nA_AMORT_OFF            in number,
    nAB_AMORT_OFF           in number,
    nC_AMORT_OFF            in number,
    nCB_AMORT_OFF           in number,
    nFREE_SIGN              in number,
    --
    nRN                     out number
  )
  as
    sNEW_OBJECT_GROUP       INVENTORY.OBJECT_GROUP%type;
    sNEW_OBJECT_NUMBER      INVENTORY.OBJECT_NUMBER%type;
    sNEW_INV_NUMBER         INVENTORY.INV_NUMBER%type;
    sNEW_CARD_PREF          INVENTORY.CARD_PREF%type;
    sNEW_CARD_NUMB          INVENTORY.CARD_NUMB%type;
    sNEW_CLASS_PREF         INVENTORY.CLASS_PREF%type;
    sNEW_CLASS_NUMB         INVENTORY.CLASS_NUMB%type;
  begin
    /* �������� ( �� P_INVENTORY_BASE_INSERT ) */

    /* �������� ����������� �������� �������� ��� ������������ ������� */
    P_INVENTORY_INVOBJ_CHECK( nCOMPANY, nACCTYPES, nINVOBJECT, null );

    /* �������� ( �� T_INVENTORY_BINSERT ) */

    /* ��� */
    if nAMORT_TYPE in (1, 2, 5) and nACNT_TERM_USE = 0 then
      P_EXCEPTION( 0, '������������ �������� ����� ��������� �������������.' );
    end if;

    /* �������� �������� */
    if PKG_ACCTFORM.IS_TYPFORM( PKG_ACCTFORM.sIS_MainValues, null, nACCOUNT ) = 0 then
      P_EXCEPTION( 0, '���� ������������ ����� ������ ����� ������� ����� "�������� ��������".' );
    end if;

    /* ������������� ����������� ������ (�������) */
    if sOBJECT_GROUP is not null then
      sNEW_OBJECT_GROUP := strright( strtrim( sOBJECT_GROUP ),10 );
    end if;
    /* ������������� ����������� ������ (�����) */
    if sOBJECT_NUMBER is not null then
      sNEW_OBJECT_NUMBER := strright( strtrim( sOBJECT_NUMBER ),10 );
    end if;
    /* ������������� ������������ ������ */
    if sINV_NUMBER is not null then
      sNEW_INV_NUMBER := strright( strtrim( sINV_NUMBER ),40 );
    end if;
    /* ������������� ������ �������� */
    sNEW_CARD_PREF := strright( strtrim( sCARD_PREF ),10 );
    sNEW_CARD_NUMB := strright( strtrim( sCARD_NUMB ),10 );
    /* ������������� ���� �� ���� */
    if sCLASS_PREF is not null then
      sNEW_CLASS_PREF := strright( strtrim( sCLASS_PREF ),10 );
    end if;
    if sCLASS_NUMB is not null then
      sNEW_CLASS_NUMB := strright( strtrim( sCLASS_NUMB ),10 );
    end if;

    if dAMORT_DURING_DATE is null and
       (nA_AMORT_DURING  != 0 or
        nAB_AMORT_DURING != 0 or
        nC_AMORT_DURING  != 0 or
        nCB_AMORT_DURING != 0)
    then
      P_EXCEPTION( 0, '�� ������ ���� ����������� �����������/������.' );
    end if;

    if nA_COST_BEGIN   <> nAB_COST_BEGIN   or
       nC_COST_BEGIN   <> nCB_COST_BEGIN   or
       nA_SUM_FUND     <> nAB_SUM_FUND     or
       nC_SUM_FUND     <> nCB_SUM_FUND     or
       nA_AMORT_BEGIN  <> nAB_AMORT_BEGIN  or
       nC_AMORT_BEGIN  <> nCB_AMORT_BEGIN  or
       nA_AMORT_DURING <> nAB_AMORT_DURING or
       nC_AMORT_DURING <> nCB_AMORT_DURING or
       nA_AMORT_OFF    <> nAB_AMORT_OFF    or
       nC_AMORT_OFF    <> nCB_AMORT_OFF    or
       nA_COST_END     <> nAB_COST_END     or
       nC_COST_END     <> nCB_COST_END
    then
      P_EXCEPTION( 0, '����� � ���������� ������ ���������.' );
    end if;

    if nvl( GET_OPTIONS_NUM('InventoryFundUse', nCOMPANY), 0) = 1 then
      if not (nA_AMORT_BEGIN  + nA_AMORT_DURING  + nA_SUM_FUND  + nA_SUM_CAP  + nA_AMORT_OFF  <= nA_COST_BEGIN  and
              nAB_AMORT_BEGIN + nAB_AMORT_DURING + nAB_SUM_FUND + nAB_SUM_CAP + nAB_AMORT_OFF <= nAB_COST_BEGIN and
              nC_AMORT_BEGIN  + nC_AMORT_DURING  + nC_SUM_FUND  + nC_SUM_CAP  + nC_AMORT_OFF  <= nC_COST_BEGIN  and
              nCB_AMORT_BEGIN + nCB_AMORT_DURING + nCB_SUM_FUND + nCB_SUM_CAP + nCB_AMORT_OFF <= nCB_COST_BEGIN) then
        P_EXCEPTION( 0, '����� ��������� ������������, ���������� ������, ����������� ��������, ����������� � ��������� ��������������� ����������� ������ ���� ������ ���� ����� ��������� ���������.' );
      end if;
    else
      if not (nA_AMORT_BEGIN  + nA_AMORT_DURING  + nA_SUM_CAP  + nA_AMORT_OFF  <= nA_COST_BEGIN  and
              nAB_AMORT_BEGIN + nAB_AMORT_DURING + nAB_SUM_CAP + nAB_AMORT_OFF <= nAB_COST_BEGIN and
              nC_AMORT_BEGIN  + nC_AMORT_DURING  + nC_SUM_CAP  + nC_AMORT_OFF  <= nC_COST_BEGIN  and
              nCB_AMORT_BEGIN + nCB_AMORT_DURING + nCB_SUM_CAP + nCB_AMORT_OFF <= nCB_COST_BEGIN) then
        P_EXCEPTION( 0, '����� ���������� ������, ����������� ��������, �����������  � ��������� ��������������� ����������� ������ ���� ������ ���� ����� ��������� ���������.' );
      end if;
    end if;

    nRN := GEN_ID;

    insert into INVENTORY
    (
      RN,
      COMPANY,
      CRN,
      JUR_PERS,
      INVOBJECT,
      INVOBJCL,
      INVOBJCL_NAME,
      OBJ_STATUS,
      ACCOUNT,
      ANALYTIC1,
      ANALYTIC2,
      ANALYTIC3,
      ANALYTIC4,
      ANALYTIC5,
      BALUNIT,
      CURRENCY,
      EXECUTIVE,
      OBJECT_GROUP,
      OBJECT_NUMBER,
      INV_NUMBER,
      CARD_PREF,
      CARD_NUMB,
      NOMENCLATURE,
      CLASS_PREF,
      CLASS_NUMB,
      OKOF,
      OBJECT_NOTE,
      OBJECT_MODEL,
      OBJECT_PLACE,
      WORS_NUMBER,
      PRODUCER,
      A_COST_BEGIN,
      AB_COST_BEGIN,
      C_COST_BEGIN,
      CB_COST_BEGIN,
      A_SUM_FUND,
      AB_SUM_FUND,
      C_SUM_FUND,
      CB_SUM_FUND,
      A_AMORT_BEGIN,
      AB_AMORT_BEGIN,
      C_AMORT_BEGIN,
      CB_AMORT_BEGIN,
      AMORT_DURING_DATE,
      A_AMORT_DURING,
      AB_AMORT_DURING,
      C_AMORT_DURING,
      CB_AMORT_DURING,
      A_COST_END,
      AB_COST_END,
      C_COST_END,
      CB_COST_END,
      AMORT_RN,
      AMORT_TYPE,
      ACNT_TERM_USE,
      CTRL_TERM_USE,
      AMORT_FAST,
      CAMORT_FAST,
      CARD_TYPE,
      RELEASE_DATE,
      INCOME_DATE,
      ITEM_COUNT,
      SUBDIV,
      ACNT_RUN,
      CTRL_RUN,
      A_TERM_USE_REST,
      C_TERM_USE_REST,
      TAX_GROUP,
      TAX_SUBGROUP,
      USE_COST_END,
      ACCTYPES,
      AMORT_FROM_BEGIN,
      AMORT_SUM_CAP,
      OPER_RULE,
      STATE_REGIST,
      ASSETS_LIMIT,
      TAXOBJTYPES,
      A_SUM_CAP,
      AB_SUM_CAP,
      C_SUM_CAP,
      CB_SUM_CAP,
      INV_NUMB_SIGN,
      BARCODE,
      LABEL_DATE,
      A_AMORT_OFF,
      AB_AMORT_OFF,
      C_AMORT_OFF,
      CB_AMORT_OFF,
      FREE_SIGN
    )
    values
    (
      nRN,
      nCOMPANY,
      nCRN,
      nJUR_PERS,
      nINVOBJECT,
      nINVOBJCL,
      sINVOBJCL_NAME,
      nOBJ_STATUS,
      nACCOUNT,
      nANALYTIC1,
      nANALYTIC2,
      nANALYTIC3,
      nANALYTIC4,
      nANALYTIC5,
      nBALUNIT,
      nCURRENCY,
      nEXECUTIVE,
      sNEW_OBJECT_GROUP,
      sNEW_OBJECT_NUMBER,
      sNEW_INV_NUMBER,
      sNEW_CARD_PREF,
      sNEW_CARD_NUMB,
      nNOMENCLATURE,
      sNEW_CLASS_PREF,
      sNEW_CLASS_NUMB,
      nOKOF,
      sOBJECT_NOTE,
      sOBJECT_MODEL,
      nOBJECT_PLACE,
      sWORS_NUMBER,
      nPRODUCER,
      nA_COST_BEGIN,
      nAB_COST_BEGIN,
      nC_COST_BEGIN,
      nCB_COST_BEGIN,
      nA_SUM_FUND,
      nAB_SUM_FUND,
      nC_SUM_FUND,
      nCB_SUM_FUND,
      nA_AMORT_BEGIN,
      nAB_AMORT_BEGIN,
      nC_AMORT_BEGIN,
      nCB_AMORT_BEGIN,
      dAMORT_DURING_DATE,
      nA_AMORT_DURING,
      nAB_AMORT_DURING,
      nC_AMORT_DURING,
      nCB_AMORT_DURING,
      nA_COST_END,
      nAB_COST_END,
      nC_COST_END,
      nCB_COST_END,
      nAMORT_RN,
      nAMORT_TYPE,
      nACNT_TERM_USE,
      nCTRL_TERM_USE,
      nAMORT_FAST,
      nCAMORT_FAST,
      nCARD_TYPE,
      dRELEASE_DATE,
      dINCOME_DATE,
      nITEM_COUNT,
      nSUBDIV,
      nACNT_RUN,
      nCTRL_RUN,
      nA_TERM_USE_REST,
      nC_TERM_USE_REST,
      nTAX_GROUP,
      nTAX_SUBGROUP,
      nUSE_COST_END,
      nACCTYPES,
      nAMORT_FROM_BEGIN,
      nAMORT_SUM_CAP,
      nOPER_RULE,
      nSTATE_REGIST,
      nASSETS_LIMIT,
      nTAXOBJTYPES,
      nA_SUM_CAP,
      nAB_SUM_CAP,
      nC_SUM_CAP,
      nCB_SUM_CAP,
      nINV_NUMB_SIGN,
      sBARCODE,
      dLABEL_DATE,
      nA_AMORT_OFF,
      nAB_AMORT_OFF,
      nC_AMORT_OFF,
      nCB_AMORT_OFF,
      nFREE_SIGN
    );
  end INVENTORY_INSERT;

  /* ���������� ������� �������� */
  procedure INVSUBST_INSERT
  (
    nCOMPANY                in number,
    nPRN                    in number,
    nNOM                    in number,
    nAMOUNT                 in number,
    nALT_AMOUNT             in number,
    sNOTE                   in varchar2,
    nREVAL_SUM              in number,
    nAB_REVAL_SUM           in number,
    nREVAL_C_SUM            in number,
    nAB_REVAL_C_SUM         in number,
    nRARTICLE               in number,
    nPARTY                  in number,
    sBARCODE                in varchar2,
    dLABEL_DATE             in date,
    nRN                     out number
  )
  as
    nAMOUNT1                PKG_STD.tQUANT;
    nALT_AMOUNT1            PKG_STD.tQUANT;
  begin
    nAMOUNT1     := nvl(nAMOUNT, 0);
    nALT_AMOUNT1 := nvl(nALT_AMOUNT, 0);

    /* ��������� RN */
    nRN := GEN_ID;

    /* ���������� */
    insert into INVSUBST
    (
      RN,
      PRN,
      NOMENCLATURE,
      AMOUNT,
      NOTE,
      REVAL_SUM,
      AB_REVAL_SUM,
      REVAL_C_SUM,
      AB_REVAL_C_SUM,
      RARTICLE,
      PARTY,
      ALT_AMOUNT,
      BARCODE,
      LABEL_DATE
    )
    values
    (
      nRN,
      nPRN,
      nNOM,
      nAMOUNT1,
      sNOTE,
      nvl(nREVAL_SUM,0),
      nvl(nAB_REVAL_SUM,0),
      nvl(nREVAL_C_SUM,0),
      nvl(nAB_REVAL_C_SUM,0),
      nRARTICLE,
      nPARTY,
      nvl(nALT_AMOUNT1,0),
      sBARCODE,
      dLABEL_DATE
    );
  end INVSUBST_INSERT;

  /* ���������� � ������ ��������� �������� */
  procedure INVPACK_INSERT
  (
    nCOMPANY                in number,
    nPRN                    in number,
    dIN_DATE                in date,
    dFACTORY_DATE           in date,
    sFACTORY_NUMBER         in varchar2,
    sGROUP_NUMBER           in varchar2,
    sINV_GROUP              in varchar2,
    sINV_NUMB               in varchar2,
    sINV_NUMBER             in varchar2,
    dOUT_DATE               in date,
    nITEM_COUNT             in number,
    nINCOME_SUM_A           in number,
    nINCOME_SUM_AB          in number,
    nINCOME_SUM_C           in number,
    nINCOME_SUM_CB          in number,
    nOBJECT_PLACE           in number,
    sBARCODE                in varchar2,
    dLABEL_DATE             in date,
    nRN                     out number
  )
  as
  begin
    /* ��������� ���������������� ������ */
    nRN := GEN_ID;

    /* ���������� ������ � ������� */
    insert
      into INVPACK ( RN, PRN, IN_DATE, FACTORY_DATE,FACTORY_NUMBER,
        GROUP_NUMBER,OUT_DATE, ITEM_COUNT, INCOME_SUM_A,
        INCOME_SUM_AB, INCOME_SUM_C, INCOME_SUM_CB, INV_GROUP, INV_NUMB,
        INV_NUMBER, OBJECT_PLACE, BARCODE, LABEL_DATE )
      values( nRN,nPRN,dIN_DATE,dFACTORY_DATE,sFACTORY_NUMBER,
        sGROUP_NUMBER,dOUT_DATE, nITEM_COUNT, nINCOME_SUM_A,
        nINCOME_SUM_AB, nINCOME_SUM_C, nINCOME_SUM_CB, sINV_GROUP, sINV_NUMB,
        sINV_NUMBER, nOBJECT_PLACE, sBARCODE, dLABEL_DATE );
  end INVPACK_INSERT;


  /* ���������� ������� �������� */
  procedure INVHIST_INSERT
  (
    nPRN                    in number,
    nCOMPANY                in number,
    nCRN                    in number,
    nJUR_PERS               in number,
    nNUMB                   in number,
    nACTION_TYPE            in number,
    dACTION_DATE            in date,
    nFDOC_TYPE              in number,
    sFDOC_NUMB              in varchar2,
    dFDOC_DATE              in date,
    nVDOC_TYPE              in number,
    sVDOC_NUMB              in varchar2,
    dVDOC_DATE              in date,
    nOLD_ACCOUNT            in number,
    nNEW_ACCOUNT            in number,
    nOLD_BALUNIT            in number,
    nNEW_BALUNIT            in number,
    nAGENT_FROM             in number,
    nAGENT_TO               in number,
    nAMORT_RN               in number,
    sAMORT_NOTE             in varchar2,
    dAMORT_OLD_DUR_DATE     in date,
    nAMORT_FAST             in number,
    nAMORT_FAST_NEW         in number,
    nCAMORT_FAST            in number,
    nCAMORT_FAST_NEW        in number,
    nAMORT_YEAR             in number,
    nAMORT_YEAR_C           in number,
    nAMORT_RUN              in number,
    nAMORT_RUN_C            in number,
    nACNT_RUN               in number,
    nCTRL_RUN               in number,
    nAMORT_YEAR_SUM         in number,
    nAMORT_YEAR_C_SUM       in number,
    nAMORT_YEAR_BSUM        in number,
    nAMORT_YEAR_C_BSUM      in number,
    nAMORT_RUN_SUM          in number,
    nAMORT_RUN_C_SUM        in number,
    nAMORT_RUN_BSUM         in number,
    nAMORT_RUN_C_BSUM       in number,
    nALT_SUM                in number,
    nALT_C_SUM              in number,
    nALT_BSUM               in number,
    nALT_C_BSUM             in number,
    nREVAL_TYPE             in number,
    nREVAL_EQUAL            in number,
    nREVAL_C_EQUAL          in number,
    nREVAL_SUM              in number,
    nREVAL_C_SUM            in number,
    nOLD_A_COST_BEGIN       in number,
    nOLD_AB_COST_BEGIN      in number,
    nOLD_C_COST_BEGIN       in number,
    nOLD_CB_COST_BEGIN      in number,
    nOLD_A_AMORT_BEGIN      in number,
    nOLD_AB_AMORT_BEGIN     in number,
    nOLD_C_AMORT_BEGIN      in number,
    nOLD_CB_AMORT_BEGIN     in number,
    nOLD_A_AMORT_DURING     in number,
    nOLD_AB_AMORT_DURING    in number,
    nOLD_C_AMORT_DURING     in number,
    nOLD_CB_AMORT_DURING    in number,
    nOLD_A_COST_END         in number,
    nOLD_AB_COST_END        in number,
    nOLD_C_COST_END         in number,
    nOLD_CB_COST_END        in number,
    nOLD_A_SUM_CAP          in number,
    nOLD_AB_SUM_CAP         in number,
    nOLD_C_SUM_CAP          in number,
    nOLD_CB_SUM_CAP         in number,
    nNEW_A_COST_BEGIN       in number,
    nNEW_AB_COST_BEGIN      in number,
    nNEW_C_COST_BEGIN       in number,
    nNEW_CB_COST_BEGIN      in number,
    nNEW_A_AMORT_BEGIN      in number,
    nNEW_AB_AMORT_BEGIN     in number,
    nNEW_C_AMORT_BEGIN      in number,
    nNEW_CB_AMORT_BEGIN     in number,
    nNEW_A_AMORT_DURING     in number,
    nNEW_AB_AMORT_DURING    in number,
    nNEW_C_AMORT_DURING     in number,
    nNEW_CB_AMORT_DURING    in number,
    nNEW_A_COST_END         in number,
    nNEW_AB_COST_END        in number,
    nNEW_C_COST_END         in number,
    nNEW_CB_COST_END        in number,
    nNEW_A_SUM_CAP          in number,
    nNEW_AB_SUM_CAP         in number,
    nNEW_C_SUM_CAP          in number,
    nNEW_CB_SUM_CAP         in number,
    nMAIN_OPER_REF          in number,
    nALT_OPER_REF           in number,
    nOPER_TYPE              in number,
    nCOUNT_OLD              in number,
    nCOUNT_NEW              in number,
    nSUBDIV_OLD             in number,
    nSUBDIV_NEW             in number,
    nANL_OLD1               in number,
    nANL_NEW1               in number,
    nANL_OLD2               in number,
    nANL_NEW2               in number,
    nANL_OLD3               in number,
    nANL_NEW3               in number,
    nANL_OLD4               in number,
    nANL_NEW4               in number,
    nANL_OLD5               in number,
    nANL_NEW5               in number,
    nA_REALIZ_SUM           in number,
    nAB_REALIZ_SUM          in number,
    nC_REALIZ_SUM           in number,
    nCB_REALIZ_SUM          in number,
    nPLACE_OLD              in number,
    nPLACE_NEW              in number,
    nA_TERM_USE_OLD         in number,
    nA_TERM_USE_NEW         in number,
    nC_TERM_USE_OLD         in number,
    nC_TERM_USE_NEW         in number,
    nA_TERM_USE_REST_OLD    in number,
    nA_TERM_USE_REST_NEW    in number,
    nC_TERM_USE_REST_OLD    in number,
    nC_TERM_USE_REST_NEW    in number,
    nINVOBJCL_OLD           in number,
    nINVOBJCL_NEW           in number,
    nMOVE_TYPE              in number,
    nCONSERV_TYPE           in number,
    nSTATE_REGIST           in number,
    nASSETS_LIMIT           in number,
    nTAXOBJTYPES_OLD        in number,
    nTAXOBJTYPES_NEW        in number,
    nAMORT_TYPE_OLD         in number,
    nAMORT_TYPE_NEW         in number,
    nTAX_GROUP_OLD          in number,
    nTAX_GROUP_NEW          in number,
    nTAX_SUBGROUP_OLD       in number,
    nTAX_SUBGROUP_NEW       in number,
    nOLD_A_GR_COST_END      in number,
    nNEW_A_GR_COST_END      in number,
    nOLD_AB_GR_COST_END     in number,
    nNEW_AB_GR_COST_END     in number,
    nOLD_C_GR_COST_END      in number,
    nNEW_C_GR_COST_END      in number,
    nOLD_CB_GR_COST_END     in number,
    nNEW_CB_GR_COST_END     in number,
    nA_GR_AMORT_DURING      in number,
    nAB_GR_AMORT_DURING     in number,
    nC_GR_AMORT_DURING      in number,
    nCB_GR_AMORT_DURING     in number,
    --
    nRN                     out number
  )
  as
  begin

    nRN := GEN_ID;

    insert into INVHIST
    (
      RN,
      PRN,
      COMPANY,
      CRN,
      JUR_PERS,
      NUMB,
      ACTION_TYPE,
      ACTION_DATE,
      FDOC_TYPE,
      FDOC_NUMB,
      FDOC_DATE,
      VDOC_TYPE,
      VDOC_NUMB,
      VDOC_DATE,
      OLD_ACCOUNT,
      NEW_ACCOUNT,
      OLD_BALUNIT,
      NEW_BALUNIT,
      AGENT_FROM,
      AGENT_TO,
      AMORT_RN,
      AMORT_NOTE,
      AMORT_OLD_DUR_DATE,
      AMORT_FAST,
      AMORT_FAST_NEW,
      CAMORT_FAST,
      CAMORT_FAST_NEW,
      AMORT_YEAR,
      AMORT_YEAR_C,
      AMORT_RUN,
      AMORT_RUN_C,
      ACNT_RUN,
      CTRL_RUN,
      AMORT_YEAR_SUM,
      AMORT_YEAR_C_SUM,
      AMORT_YEAR_BSUM,
      AMORT_YEAR_C_BSUM,
      AMORT_RUN_SUM,
      AMORT_RUN_C_SUM,
      AMORT_RUN_BSUM,
      AMORT_RUN_C_BSUM,
      ALT_SUM,
      ALT_C_SUM,
      ALT_BSUM,
      ALT_C_BSUM,
      REVAL_TYPE,
      REVAL_EQUAL,
      REVAL_C_EQUAL,
      REVAL_SUM,
      REVAL_C_SUM,
      OLD_A_COST_BEGIN,
      OLD_AB_COST_BEGIN,
      OLD_C_COST_BEGIN,
      OLD_CB_COST_BEGIN,
      OLD_A_AMORT_BEGIN,
      OLD_AB_AMORT_BEGIN,
      OLD_C_AMORT_BEGIN,
      OLD_CB_AMORT_BEGIN,
      OLD_A_AMORT_DURING,
      OLD_AB_AMORT_DURING,
      OLD_C_AMORT_DURING,
      OLD_CB_AMORT_DURING,
      OLD_A_COST_END,
      OLD_AB_COST_END,
      OLD_C_COST_END,
      OLD_CB_COST_END,
      OLD_A_SUM_CAP,
      OLD_AB_SUM_CAP,
      OLD_C_SUM_CAP,
      OLD_CB_SUM_CAP,
      NEW_A_COST_BEGIN,
      NEW_AB_COST_BEGIN,
      NEW_C_COST_BEGIN,
      NEW_CB_COST_BEGIN,
      NEW_A_AMORT_BEGIN,
      NEW_AB_AMORT_BEGIN,
      NEW_C_AMORT_BEGIN,
      NEW_CB_AMORT_BEGIN,
      NEW_A_AMORT_DURING,
      NEW_AB_AMORT_DURING,
      NEW_C_AMORT_DURING,
      NEW_CB_AMORT_DURING,
      NEW_A_COST_END,
      NEW_AB_COST_END,
      NEW_C_COST_END,
      NEW_CB_COST_END,
      NEW_A_SUM_CAP,
      NEW_AB_SUM_CAP,
      NEW_C_SUM_CAP,
      NEW_CB_SUM_CAP,
      MAIN_OPER_REF,
      ALT_OPER_REF,
      OPER_TYPE,
      COUNT_OLD,
      COUNT_NEW,
      SUBDIV_OLD,
      SUBDIV_NEW,
      ANL_OLD1,
      ANL_NEW1,
      ANL_OLD2,
      ANL_NEW2,
      ANL_OLD3,
      ANL_NEW3,
      ANL_OLD4,
      ANL_NEW4,
      ANL_OLD5,
      ANL_NEW5,
      A_REALIZ_SUM,
      AB_REALIZ_SUM,
      C_REALIZ_SUM,
      CB_REALIZ_SUM,
      PLACE_OLD,
      PLACE_NEW,
      A_TERM_USE_OLD,
      A_TERM_USE_NEW,
      C_TERM_USE_OLD,
      C_TERM_USE_NEW,
      A_TERM_USE_REST_OLD,
      A_TERM_USE_REST_NEW,
      C_TERM_USE_REST_OLD,
      C_TERM_USE_REST_NEW,
      INVOBJCL_OLD,
      INVOBJCL_NEW,
      MOVE_TYPE,
      CONSERV_TYPE,
      STATE_REGIST,
      ASSETS_LIMIT,
      TAXOBJTYPES_OLD,
      TAXOBJTYPES_NEW,
      AMORT_TYPE_OLD,
      AMORT_TYPE_NEW,
      TAX_GROUP_OLD,
      TAX_GROUP_NEW,
      TAX_SUBGROUP_OLD,
      TAX_SUBGROUP_NEW,
      OLD_A_GR_COST_END,
      NEW_A_GR_COST_END,
      OLD_AB_GR_COST_END,
      NEW_AB_GR_COST_END,
      OLD_C_GR_COST_END,
      NEW_C_GR_COST_END,
      OLD_CB_GR_COST_END,
      NEW_CB_GR_COST_END,
      A_GR_AMORT_DURING,
      AB_GR_AMORT_DURING,
      C_GR_AMORT_DURING,
      CB_GR_AMORT_DURING
    )
    values
    (
      nRN,
      nPRN,
      nCOMPANY,
      nCRN,
      nJUR_PERS,
      nNUMB,
      nACTION_TYPE,
      dACTION_DATE,
      nFDOC_TYPE,
      sFDOC_NUMB,
      dFDOC_DATE,
      nVDOC_TYPE,
      sVDOC_NUMB,
      dVDOC_DATE,
      nOLD_ACCOUNT,
      nNEW_ACCOUNT,
      nOLD_BALUNIT,
      nNEW_BALUNIT,
      nAGENT_FROM,
      nAGENT_TO,
      nAMORT_RN,
      sAMORT_NOTE,
      dAMORT_OLD_DUR_DATE,
      nAMORT_FAST,
      nAMORT_FAST_NEW,
      nCAMORT_FAST,
      nCAMORT_FAST_NEW,
      nAMORT_YEAR,
      nAMORT_YEAR_C,
      nAMORT_RUN,
      nAMORT_RUN_C,
      nACNT_RUN,
      nCTRL_RUN,
      nAMORT_YEAR_SUM,
      nAMORT_YEAR_C_SUM,
      nAMORT_YEAR_BSUM,
      nAMORT_YEAR_C_BSUM,
      nAMORT_RUN_SUM,
      nAMORT_RUN_C_SUM,
      nAMORT_RUN_BSUM,
      nAMORT_RUN_C_BSUM,
      nALT_SUM,
      nALT_C_SUM,
      nALT_BSUM,
      nALT_C_BSUM,
      nREVAL_TYPE,
      nREVAL_EQUAL,
      nREVAL_C_EQUAL,
      nREVAL_SUM,
      nREVAL_C_SUM,
      nOLD_A_COST_BEGIN,
      nOLD_AB_COST_BEGIN,
      nOLD_C_COST_BEGIN,
      nOLD_CB_COST_BEGIN,
      nOLD_A_AMORT_BEGIN,
      nOLD_AB_AMORT_BEGIN,
      nOLD_C_AMORT_BEGIN,
      nOLD_CB_AMORT_BEGIN,
      nOLD_A_AMORT_DURING,
      nOLD_AB_AMORT_DURING,
      nOLD_C_AMORT_DURING,
      nOLD_CB_AMORT_DURING,
      nOLD_A_COST_END,
      nOLD_AB_COST_END,
      nOLD_C_COST_END,
      nOLD_CB_COST_END,
      nOLD_A_SUM_CAP,
      nOLD_AB_SUM_CAP,
      nOLD_C_SUM_CAP,
      nOLD_CB_SUM_CAP,
      nNEW_A_COST_BEGIN,
      nNEW_AB_COST_BEGIN,
      nNEW_C_COST_BEGIN,
      nNEW_CB_COST_BEGIN,
      nNEW_A_AMORT_BEGIN,
      nNEW_AB_AMORT_BEGIN,
      nNEW_C_AMORT_BEGIN,
      nNEW_CB_AMORT_BEGIN,
      nNEW_A_AMORT_DURING,
      nNEW_AB_AMORT_DURING,
      nNEW_C_AMORT_DURING,
      nNEW_CB_AMORT_DURING,
      nNEW_A_COST_END,
      nNEW_AB_COST_END,
      nNEW_C_COST_END,
      nNEW_CB_COST_END,
      nNEW_A_SUM_CAP,
      nNEW_AB_SUM_CAP,
      nNEW_C_SUM_CAP,
      nNEW_CB_SUM_CAP,
      nMAIN_OPER_REF,
      nALT_OPER_REF,
      nOPER_TYPE,
      nCOUNT_OLD,
      nCOUNT_NEW,
      nSUBDIV_OLD,
      nSUBDIV_NEW,
      nANL_OLD1,
      nANL_NEW1,
      nANL_OLD2,
      nANL_NEW2,
      nANL_OLD3,
      nANL_NEW3,
      nANL_OLD4,
      nANL_NEW4,
      nANL_OLD5,
      nANL_NEW5,
      nA_REALIZ_SUM,
      nAB_REALIZ_SUM,
      nC_REALIZ_SUM,
      nCB_REALIZ_SUM,
      nPLACE_OLD,
      nPLACE_NEW,
      nA_TERM_USE_OLD,
      nA_TERM_USE_NEW,
      nC_TERM_USE_OLD,
      nC_TERM_USE_NEW,
      nA_TERM_USE_REST_OLD,
      nA_TERM_USE_REST_NEW,
      nC_TERM_USE_REST_OLD,
      nC_TERM_USE_REST_NEW,
      nINVOBJCL_OLD,
      nINVOBJCL_NEW,
      nMOVE_TYPE,
      nCONSERV_TYPE,
      nSTATE_REGIST,
      nASSETS_LIMIT,
      nTAXOBJTYPES_OLD,
      nTAXOBJTYPES_NEW,
      nAMORT_TYPE_OLD,
      nAMORT_TYPE_NEW,
      nTAX_GROUP_OLD,
      nTAX_GROUP_NEW,
      nTAX_SUBGROUP_OLD,
      nTAX_SUBGROUP_NEW,
      nOLD_A_GR_COST_END,
      nNEW_A_GR_COST_END,
      nOLD_AB_GR_COST_END,
      nNEW_AB_GR_COST_END,
      nOLD_C_GR_COST_END,
      nNEW_C_GR_COST_END,
      nOLD_CB_GR_COST_END,
      nNEW_CB_GR_COST_END,
      nA_GR_AMORT_DURING,
      nAB_GR_AMORT_DURING,
      nC_GR_AMORT_DURING,
      nCB_GR_AMORT_DURING
    );
  end INVHIST_INSERT;


begin
  /* �������:
    - nAMORT_TYPE
    - nTAX_GROUP
  */

  PKG_IMPORT7.IMPORT_TABLE('DICACCS');
  PKG_IMPORT7.IMPORT_TABLE('AGNLIST');
  PKG_IMPORT7.IMPORT_TABLE('DICNOMNS');
  PKG_IMPORT7.IMPORT_TABLE('OKOF');
  PKG_IMPORT7.IMPORT_TABLE('DOCTYPES');
  PKG_IMPORT7.IMPORT_TABLE('DICAMORT');
  PKG_IMPORT7.IMPORT_TABLE('ECONOPRS');

  nCOMPANY := PKG_IMPORT7.nCOMPANY;

  /* ����������� �������������� - �������� ����������� ���� */
  FIND_JURPERSONS_MAIN(0, PKG_IMPORT7.nCOMPANY, sTMP, nMAIN_JUR_PERS);

  /* ��������� �������� INVENTORY */
  execute immediate 'alter table INVENTORY disable all triggers';
  execute immediate 'alter table INVHIST   disable all triggers';

  begin
    /* ���� �� ��������� ����� 7 */
    for rINV in
    (
      select t.*, rownum, count(1) over() ncount from (select *
        from P7_INBASE
        where RN_ORG is not null
        order by GROUP_INV, NUM_INV) t
    )
    loop
      dbms_application_info.set_action(ROUND(rINV.Rownum / rINV.Ncount * 1000) / 10);
      /* �������� �������� �� ���������� ������ */
      nINV_RN := PKG_IMPORT7.GET_RN8( 1, 0, 'INBASE', rINV.RN );

      if nINV_RN is null then
        begin
          -- ������ ���������� �����������
          if rINV.METH_AMORT = 6 then
            nAMORT_TYPE := 4;
          elsif rINV.METH_AMORT = 1 then
            nAMORT_TYPE := 1;
          else
            nAMORT_TYPE := 3;
          end if;

          -- ��.����
          nJUR_PERS :=  nvl(F_IMPORT7_JURPERS(0, 1, rINV.RN_ORGPU, nMAIN_JUR_PERS), nMAIN_JUR_PERS);

          -- ��������� ������������ �������
          if rINV.DATE_OUT is not null then
            nOBJ_STATUS := 2;  -- �����
          elsif rINV.DATKONS is not null then
            nOBJ_STATUS := 3;  -- ���������������
          elsif rINV.DATE_IN is not null then
            nOBJ_STATUS := 1;  -- ������ � �����
          else
            nOBJ_STATUS := 0;  -- �� ������
          end if;

          -- ����
          nACCOUNT := PKG_IMPORT7.GET_RN8( 0, 0, 'ACCBASE', rINV.RN_ACCOUNT );

          -- ��� �����
          begin
            select ACCTYPES
              into nACCTYPES
              from DICACCS
              where RN = nACCOUNT;
          exception
            when NO_DATA_FOUND then
              PKG_MSG.RECORD_NOT_FOUND( nACCOUNT, 'AccountsPlan' );
          end;

          -- ����� ��������
          sCARD_NUMB := STRRIGHT( to_char(rINV.NUM_CARD), 10 );
          -- ������� ��������
          sCARD_PREF := GET_CARD_PREF( nACCTYPES, sCARD_NUMB );

          -- ����
          nOKOF := PKG_IMPORT7.GET_RN8( 1, 1, 'OKOF', rINV.RN_OKOF );
          if nOKOF is not null then
            FIND_OKOF_PARAMS( 0, nCOMPANY, nOKOF, sOKOF_CODE, sOKOF_NAME, sOKOF_FULLNAME, nOKOF_HIER_LEVEL, sTAX_GROUP );
            sCLASS_PREF := substr(sOKOF_CODE,1,2);
            sCLASS_NUMB := substr(sOKOF_CODE,4);
          else
            sCLASS_PREF := null;
            sCLASS_NUMB := null;
          end if;

          -- ���������������
          nOBJECT_PLACE := GET_DICPLACE( PKG_IMPORT7.GET_RN8(0, 1, 'ORGBASE', rINV.LOCATION_R) );

          -- ��� ��������
          case rINV.TYPIK
          when 0 then nCARD_TYPE := 0; -- ��-6
          when 1 then nCARD_TYPE := 1; -- ��-8
          when 2 then nCARD_TYPE := 1; -- ��-8
          when 3 then nCARD_TYPE := 2; -- ��-9
          when 4 then nCARD_TYPE := 3; -- ��-�
          when 5 then nCARD_TYPE := 4; -- ��-�
          else
            P_EXCEPTION( 0, '����������� ��� �������� (TYPIK = '||to_char(rINV.TYPIK)||').' );
          end case;

          -- ���������� ���� ��������� �������������
          if rINV.DATE_SROK is not null then
            nA_TERM_USE_REST := rINV.SROK_OST;
          else
            nA_TERM_USE_REST := rINV.SROK;
          end if;

          -- ������������ ���������� ���������
          if rINV.SROK_OST > 0 then
            nUSE_COST_END := 2;
          else
            nUSE_COST_END := 0;
          end if;

          -- ���� �� ����������� �������
          if nCARD_TYPE in (0, 1) then
            nINV_NUMB_SIGN := 0;
          elsif nCARD_TYPE = 2 then
            nINV_NUMB_SIGN := 1;
          else
            nINV_NUMB_SIGN := rINV.LGROUPCARD;
          end if;
          -- ��������� ����������� ������ � ������
          if nINV_NUMB_SIGN = 1 then
            sOBJECT_GROUP  := null;
            sOBJECT_NUMBER := null;
            sINV_NUMBER    := null;
          else
            -- ������������
            SET_INV_NUMBER
            (
              to_char(rINV.GROUP_INV),
              to_char(rINV.NUM_INV),
              sOBJECT_GROUP,
              sOBJECT_NUMBER,
              sINV_NUMBER
            );
          end if;

          -- ����������
          if nCARD_TYPE in (2, 3, 4) then
            nITEM_COUNT := rINV.KOLIO;
          else
            nITEM_COUNT := 1;
          end if;

          -- �����
          nA_COST_BEGIN    := rINV.IN_SUM;     -- ��������� ��������� (������������� ������)
          nAB_COST_BEGIN   := rINV.IN_SUM;     -- ��������� ��������� � ����������� (������������� ������)
          nA_AMORT_BEGIN   := rINV.IN_WEAR;    -- ��������� ����� (������������� ������)
          nAB_AMORT_BEGIN  := rINV.IN_WEAR;    -- ��������� ����� � ����������� (������������� ������)
          nA_AMORT_DURING  := rINV.SUMMA_AMOR; -- ����������� ����������� (������������� ������)
          nAB_AMORT_DURING := rINV.SUMMA_AMOR; -- ����������� ����������� � ����������� (������������� ������)
          nA_COST_END      := rINV.RST_SUM;    -- ���������� ��������� (������������� ������)
          nAB_COST_END     := rINV.RST_SUM;    -- ���������� ��������� � ����������� (������������� ������)
          -- �������
          nCRN             := PKG_IMPORT7.GET_CATALOG8( 'Inventory', rINV.PARENT_RN );

          /* ���������� ����������� �������� */
          INVENTORY_INSERT
          (
            nCOMPANY           => nCOMPANY,                                                 -- �����������
            nCRN               => nCRN,                                                     -- �������
            nJUR_PERS          => nJUR_PERS,                                                -- ��.����
            nINVOBJECT         => null,                                                     -- ����������� ������
            nINVOBJCL          => null,                                                     -- ����� ������������ �������
            sINVOBJCL_NAME     => null,                                                     -- ����� ������������ ������� (������������)
            nOBJ_STATUS        => nOBJ_STATUS,                                              -- ��������� ������������ �������
            nACCOUNT           => PKG_IMPORT7.GET_RN8( 0, 0, 'ACCBASE', rINV.RN_ACCOUNT ),  -- ����
            nANALYTIC1         => PKG_IMPORT7.GET_RN8( 0, 1, 'ACCSPEC', rINV.RN_AC_A1 ),    -- ��������� 1 ������
            nANALYTIC2         => PKG_IMPORT7.GET_RN8( 0, 1, 'ACCSPEC', rINV.RN_AC_A2 ),    -- ��������� 2 ������
            nANALYTIC3         => PKG_IMPORT7.GET_RN8( 0, 1, 'ACCSPEC', rINV.RN_AC_A3 ),    -- ��������� 3 ������
            nANALYTIC4         => PKG_IMPORT7.GET_RN8( 0, 1, 'ACCSPEC', rINV.RN_AC_A4 ),    -- ��������� 4 ������
            nANALYTIC5         => PKG_IMPORT7.GET_RN8( 0, 1, 'ACCSPEC', rINV.RN_AC_A5 ),    -- ��������� 5 ������
            nBALUNIT           => null,                                                     -- ���
            nCURRENCY          => F_CURBASE_GET_RN( 0, nCOMPANY ),                          -- ������ (�������)
            nEXECUTIVE         => PKG_IMPORT7.GET_RN8( 0, 0, 'ORGBASE', rINV.RN_ORG ),      -- ���
            sOBJECT_GROUP      => sOBJECT_GROUP,                                            -- ����������� ������ (�������)
            sOBJECT_NUMBER     => sOBJECT_NUMBER,                                           -- ����������� ������ (�����)
            sINV_NUMBER        => sINV_NUMBER,                                              -- ����������� �����
            sCARD_PREF         => sCARD_PREF,                                               -- ����� �������� (�������)
            sCARD_NUMB         => sCARD_NUMB,                                               -- ����� �������� (�����)
            nNOMENCLATURE      => PKG_IMPORT7.GET_RN8( 0, 0, 'NOBASE', rINV.RN_NOMCL ),     -- ������������
            sCLASS_PREF        => sCLASS_PREF,                                              -- ��� �� ���� (������)
            sCLASS_NUMB        => sCLASS_NUMB,                                              -- ��� �� ���� (�����)
            nOKOF              => nOKOF,                                                    -- ����
            sOBJECT_NOTE       => strtrim(dbms_lob.substr( rINV.NOTE, 2000 )),              -- ������� ��������������
            sOBJECT_MODEL      => rINV.MODEL,                                               -- ������, �����
            nOBJECT_PLACE      => nOBJECT_PLACE,                                            -- ���������������
            sWORS_NUMBER       => rINV.NUM_FACT,                                            -- ��������� �����
            nPRODUCER          => null,                                                     -- ������������
            nA_COST_BEGIN      => nA_COST_BEGIN,                                            -- ��������� ��������� (������������� ������)
            nAB_COST_BEGIN     => nAB_COST_BEGIN,                                           -- ��������� ��������� � ����������� (������������� ������)
            nC_COST_BEGIN      => 0,                                                        -- ��������� ��������� (�������������� ������)
            nCB_COST_BEGIN     => 0,                                                        -- ��������� ��������� � ����������� (�������������� ������)
            nA_SUM_FUND        => 0,                                                        -- ����� ��������� ������������ (������������� ������)
            nAB_SUM_FUND       => 0,                                                        -- ����� ��������� ������������ � ����������� (������������� ������)
            nC_SUM_FUND        => 0,                                                        -- ����� ��������� ������������ (�������������� ������)
            nCB_SUM_FUND       => 0,                                                        -- ����� ��������� ������������ � ����������� (�������������� ������)
            nA_AMORT_BEGIN     => nA_AMORT_BEGIN,                                           -- ��������� ����� (������������� ������)
            nAB_AMORT_BEGIN    => nAB_AMORT_BEGIN,                                          -- ��������� ����� � ����������� (������������� ������)
            nC_AMORT_BEGIN     => 0,                                                        -- ��������� ����� (�������������� ������)
            nCB_AMORT_BEGIN    => 0,                                                        -- ��������� ����� � ����������� (�������������� ������)
            dAMORT_DURING_DATE => rINV.DATE_RST,                                            -- ���� ���������� ���������� �����������
            nA_AMORT_DURING    => nA_AMORT_DURING,                                          -- ����������� ����������� (������������� ������)
            nAB_AMORT_DURING   => nAB_AMORT_DURING,                                         -- ����������� ����������� � ����������� (������������� ������)
            nC_AMORT_DURING    => 0,                                                        -- ����������� ����������� (�������������� ������)
            nCB_AMORT_DURING   => 0,                                                        -- ����������� ����������� � ����������� (�������������� ������)
            nA_COST_END        => nA_COST_END,                                              -- ���������� ��������� (������������� ������)
            nAB_COST_END       => nAB_COST_END,                                             -- ���������� ��������� � ����������� (������������� ������)
            nC_COST_END        => 0,                                                        -- ���������� ��������� (�������������� ������)
            nCB_COST_END       => 0,                                                        -- ���������� ��������� � ����������� (�������������� ������)
            nAMORT_RN          => PKG_IMPORT7.GET_RN8(0, 1, 'AMORT', rINV.RN_AMORT),        -- ���� �����������
            --
            nAMORT_TYPE        => nAMORT_TYPE,                                              -- ������ ���������� �����������
            --
            nACNT_TERM_USE     => rINV.SROK,                                                -- ���� ��������� ������������� (������������� ������)
            nCTRL_TERM_USE     => 0,                                                        -- ���� ��������� ������������� (�������������� ������)
            nAMORT_FAST        => rINV.CORR_KOEFF,                                          -- ����������� ����������� (������������� ������)
            nCAMORT_FAST       => 0,                                                        -- ����������� ����������� (�������������� ������)
            nCARD_TYPE         => nCARD_TYPE,                                               -- ��� ��������
            dRELEASE_DATE      => rINV.DATE_PROD,                                           -- ���� �������    ��� ��-9 - ������. ��� ��������� �������� �������.
            dINCOME_DATE       => rINV.DATE_IN,                                             -- ���� �����������
            nITEM_COUNT        => nITEM_COUNT,                                              -- ����������
            nSUBDIV            => null,                                                     -- �������������
            nACNT_RUN          => 0,                                                        -- ������� ������ (������������� ������)
            nCTRL_RUN          => 0,                                                        -- ������� ������ (�������������� ������)
            nA_TERM_USE_REST   => nA_TERM_USE_REST,                                         -- ���������� ���� ��������� ������������� (������������� ������)
            nC_TERM_USE_REST   => 0,                                                        -- ���������� ���� ��������� ������������� (�������������� ������)
            --
            nTAX_GROUP         => null,                                                     -- ��������������� ������
            nTAX_SUBGROUP      => null,                                                     -- ��������������� ���������
            --
            nUSE_COST_END      => nUSE_COST_END,                                            -- ������������ ���������� ���������
            nACCTYPES          => nACCTYPES,                                                -- ��� �����
            nAMORT_FROM_BEGIN  => 0,                                                        -- ������� ���������� ����������� � ������ �������� � �����
            nAMORT_SUM_CAP     => 0,                                                        -- ���������� ����������� � ������ ����� ����������� ��������
            nOPER_RULE         => null,                                                     -- ������� ��������� ���������� �����������
            nSTATE_REGIST      => 0,                                                        -- ���� ��������������� �����������
            nASSETS_LIMIT      => 0,                                                        -- ����������� ������������� ��������
            nTAXOBJTYPES       => null,                                                     -- ��� ������� ���������������
            nA_SUM_CAP         => 0,                                                        -- ����� ����������� �������� (������������� ������)
            nAB_SUM_CAP        => 0,                                                        -- ����� ����������� �������� ����������� (������������� ������)
            nC_SUM_CAP         => 0,                                                        -- ����� ����������� �������� (�������������� ������)
            nCB_SUM_CAP        => 0,                                                        -- ����� ����������� �������� � ����������� (�������������� ������)
            nINV_NUMB_SIGN     => nINV_NUMB_SIGN,                                           -- ���� �� ����������� �������
            sBARCODE           => null,                                                     -- �����-���
            dLABEL_DATE        => null,                                                     -- ���� ��������
            nA_AMORT_OFF       => 0,                                                        -- ��������� ��������������� ����������� (������������� ������)
            nAB_AMORT_OFF      => 0,                                                        -- ��������� ��������������� ����������� � ����������� (������������� ������)
            nC_AMORT_OFF       => 0,                                                        -- ��������� ��������������� ����������� (�������������� ������)
            nCB_AMORT_OFF      => 0,                                                        -- ��������� ��������������� ����������� � ����������� (�������������� ������)
            nFREE_SIGN         => 0,                                                        -- ������������� �����������: 0 - ���, 1 - ��
            --                                                                              --
            nRN                => nINV_RN                                                   -- ����������� ��������
          );

          /* ������ ����������� �������� */
          for rSUBST in
          (
            select
              RN_PRNOM,
              sum(KOLIO) KOLIO,
              sum(NSUM)  NSUM,
              min(RN)    RN
            from
              P7_INSOST
            where MASTER_RN = rINV.RN
              and RN_PRNOM is not null
            group by RN_PRNOM
          )
          loop
            begin
              /* ��������� ���������� */
              sSUBST_NOTE := null;
              for rec in
              (
                select
                  nvl((select NOMEN_NAME from DICNOMNS where RN = PKG_IMPORT7.GET_RN8(0, 1, 'NOBASE', RN_NOMOSOB)), T.NAM_OSOB)  sNOMOSOB,
                  nvl((select NOMEN_NAME from DICNOMNS where RN = PKG_IMPORT7.GET_RN8(0, 1, 'NOBASE', RN_MATER)),   T.NAM_MATER) sMATER
                from
                  P7_INSOST T
                where T.RN = rSUBST.RN
              )
              loop
                if strtrim(rec.sNOMOSOB) is not null then
                  sSUBST_NOTE := strtrim(rec.sNOMOSOB);
                end if;

                if strtrim(rec.sMATER) is not null then
                  if sSUBST_NOTE is not null then
                    sSUBST_NOTE := sSUBST_NOTE || '; '|| strtrim(rec.sMATER);
                  else
                    sSUBST_NOTE := strtrim(rec.sMATER);
                  end if;
                end if;
              end loop; -- rec

              /* ���������� � ������ ������� */
              INVSUBST_INSERT
              (
                nCOMPANY         => nCOMPANY,                                                 -- �����������
                nPRN             => nINV_RN,                                                  -- ����������� ��������
                nNOM             => PKG_IMPORT7.GET_RN8(0, 0, 'NOBASE', rSUBST.RN_PRNOM),     -- ������������
                nAMOUNT          => rSUBST.KOLIO,                                             -- ����������
                nALT_AMOUNT      => 0,                                                        -- ���������� � ���
                sNOTE            => sSUBST_NOTE,                                              -- ����������
                nREVAL_SUM       => rSUBST.NSUM,                                              -- ����� (������������� ������)
                nAB_REVAL_SUM    => rSUBST.NSUM,                                              -- ����� � ����������� (������������� ������)
                nREVAL_C_SUM     => 0,                                                        -- ����� (�������������� ������)
                nAB_REVAL_C_SUM  => 0,                                                        -- ����� � ����������� (�������������� ������)
                nRARTICLE        => null,                                                     -- �������
                nPARTY           => null,                                                     -- ������
                sBARCODE         => null,                                                     -- �����-���
                dLABEL_DATE      => null,                                                     -- ���� ��������
                nRN              => nSUBST                                                    -- ���.����� � ������� �������
              );
            exception
              when OTHERS then
                PKG_IMPORT7.LOG_ERROR( 'INSOST', rSUBST.RN );
            end;
          end loop; -- rSUBST

          /* ������ ��������� �������� */
          if nCARD_TYPE in (2, 3, 4) then

            /* ��� ����� �� ���.������� */
            if nINV_NUMB_SIGN = 0 and rINV.DATE_IN is not null then
              if rINV.KOLIO > 0 then
                nITEM_COUNT := rINV.KOLIO;
              else
                nITEM_COUNT := 1;
              end if;

              if nCARD_TYPE = 2 then
                nITEM_COUNT    := 1;
                nINCOME_SUM_A  := 0;
                nINCOME_SUM_AB := 0;
              else
                nINCOME_SUM_A  := rINV.IN_SUM;
                nINCOME_SUM_AB := rINV.IN_SUM;
              end if;

              /* ���������� � ������ ��������� �������� */
              INVPACK_INSERT
              (
                nCOMPANY        => nCOMPANY,                                                -- �����������
                nPRN            => nINV_RN,                                                 -- ����������� ��������
                dIN_DATE        => rINV.DATE_IN,                                            -- ���� �����������
                dFACTORY_DATE   => rINV.DATE_PROD,                                          -- ���� �������
                sFACTORY_NUMBER => rINV.NUM_FACT,                                           -- ��������� �����
                sGROUP_NUMBER   => '1',                                                     -- ���������� �����
                sINV_GROUP      => null,                                                    -- ����������� ������ (�������)
                sINV_NUMB       => null,                                                    -- ����������� ������ (�����)
                sINV_NUMBER     => null,                                                    -- ����������� �����
                dOUT_DATE       => rINV.DATE_OUT,                                           -- ���� �������
                nITEM_COUNT     => nITEM_COUNT,                                             -- ����������
                nINCOME_SUM_A   => nINCOME_SUM_A,                                           -- ����� ������� (������������� ������)
                nINCOME_SUM_AB  => nINCOME_SUM_AB,                                          -- ����� ������� � ����������� (������������� ������)
                nINCOME_SUM_C   => 0,                                                       -- ����� ������� (�������������� ������)
                nINCOME_SUM_CB  => 0,                                                       -- ����� ������� � ����������� (�������������� ������)
                nOBJECT_PLACE   => null,                                                    -- ���������������
                sBARCODE        => null,                                                    -- �����-���
                dLABEL_DATE     => null,                                                    -- ���� ��������
                nRN             => nPACK                                                    -- ���.����� � ��������� �������
              );

            /* � ������ �� ���.������� */
            else
              /* ��������� ������ */
              for rPACK in
              (
                select ROWNUM, T.* from
                (
                  select *
                    from P7_INSPIS
                   where MASTER_RN = rINV.RN
                     and P7_DATE is not null
                   order by P7_DATE, INUM, RN
                 ) T
              )
              loop
                begin
                  /* �������� �������� �������� �� ���������� ������ */
                  nPACK := PKG_IMPORT7.GET_RN8( 1, 0, 'INSPIS', rPACK.RN );

                  if nPACK is null then
                    /* ������������ ������������ ������ */
                    SET_INV_NUMBER
                    (
                      to_char(rINV.GROUP_INV),
                      to_char(rPACK.INUM),
                      sOBJECT_GROUP,
                      sOBJECT_NUMBER,
                      sINV_NUMBER
                    );

                    if rINV.KOLIO > 0 then
                      nITEM_COUNT := rINV.KOLIO;
                    else
                      nITEM_COUNT := 1;
                    end if;

                    if nCARD_TYPE = 2 then
                      nITEM_COUNT    := 1;
                      nINCOME_SUM_A  := 0;
                      nINCOME_SUM_AB := 0;
                    else
                      nINCOME_SUM_A  := rINV.IN_SUM/nITEM_COUNT;
                      nINCOME_SUM_AB := rINV.IN_SUM/nITEM_COUNT;
                    end if;

                    /* ���������� � ������ ��������� �������� */
                    INVPACK_INSERT
                    (
                      nCOMPANY        => nCOMPANY,                                                -- �����������
                      nPRN            => nINV_RN,                                                 -- ����������� ��������
                      dIN_DATE        => rPACK.P7_DATE,                                           -- ���� �����������
                      dFACTORY_DATE   => rINV.DATE_PROD,                                          -- ���� �������
                      sFACTORY_NUMBER => rINV.NUM_FACT,                                           -- ��������� �����
                      sGROUP_NUMBER   => to_char(rPACK.ROWNUM),                                   -- ���������� �����
                      sINV_GROUP      => sOBJECT_GROUP,                                           -- ����������� ������ (�������)
                      sINV_NUMB       => sOBJECT_NUMBER,                                          -- ����������� ������ (�����)
                      sINV_NUMBER     => sINV_NUMBER,                                             -- ����������� �����
                      dOUT_DATE       => rPACK.DATEOUT,                                           -- ���� �������
                      nITEM_COUNT     => 1,                                                       -- ����������
                      nINCOME_SUM_A   => nINCOME_SUM_A,                                           -- ����� ������� (������������� ������)
                      nINCOME_SUM_AB  => nINCOME_SUM_AB,                                          -- ����� ������� � ����������� (������������� ������)
                      nINCOME_SUM_C   => 0,                                                       -- ����� ������� (�������������� ������)
                      nINCOME_SUM_CB  => 0,                                                       -- ����� ������� � ����������� (�������������� ������)
                      nOBJECT_PLACE   => null,                                                    -- ���������������
                      sBARCODE        => null,                                                    -- �����-���
                      dLABEL_DATE     => null,                                                    -- ���� ��������
                      nRN             => nPACK                                                    -- ���.����� � ��������� �������
                    );
                  end if;
                exception
                  when OTHERS then
                    PKG_IMPORT7.LOG_ERROR( 'INSPIS', rPACK.RN );
                end;
                PKG_IMPORT7.SET_REF( 'INSPIS', rPACK.RN, nPACK );
              end loop; -- rPACK
            end if;
          end if; -- ������ ��������� ��������

          /* ���� �� �������� ����� 7 */
          for rHST in
          (
            select ROWNUM, T.* from
            (
              select t.*, nvl(P7_DATE, DATE_OLD) ACTION_DATE
                from P7_INSPEC t
               where MASTER_RN = rINV.RN
               order by ACTION_DATE, RN
            ) T
          )
          loop
            /* �������� �������� �������� �� ���������� ������ */
            nHST_RN := PKG_IMPORT7.GET_RN8( 1, 0, 'INSPEC', rHST.RN );

            if nHST_RN is null then
              begin
                -- ��������� ���������
                nOPER_TYPE    := 2;    -- ��� �������� ("������")
                nMOVE_TYPE    := 0;    -- ������ ����������� ("�� �����")
                nCONSERV_TYPE := 0;    -- ������ �����������/��������������

                -- ��� ��������
                case rHST.CODE
                when 1  then nACTION_TYPE := 0;  -- �������� � �����
                when 2  then nACTION_TYPE := 4;  -- ��������
                when 3  then nACTION_TYPE := 1;  -- ���������� �����������
                when 4  then nACTION_TYPE := 2;  -- ����������
                when 5  then nACTION_TYPE := 5;  -- �������������, ��������, �����
                             nOPER_TYPE   := 0;  -- �������������, ������������, ���������
                when 6  then nACTION_TYPE := 3;  -- �����������
                when 7  then nACTION_TYPE := 6;  -- �����������
                when 8  then nACTION_TYPE := 7;  -- ����� �� �����������
                when 9  then nACTION_TYPE := 18; -- �������������� ��������
                when 10 then nACTION_TYPE := 5;  -- ��������
                             nOPER_TYPE   := 1;  -- ��� �������� = ����������� ������
                when 11 then nACTION_TYPE := 5;  -- �������� (���������� ��������� �������)
                when 12 then nACTION_TYPE := 10; -- ������� �� ������� ���������� �������
                when 13 then nACTION_TYPE := 8;  -- �������� �� ������� ���������� �������
                when 14 then nACTION_TYPE := 9;  -- ���������� ����������� �� ������� ���������� �������
                when 15 then nACTION_TYPE := 9;  -- ����������� �� ������� ���������� �������
                when 16 then nACTION_TYPE := 9;  -- ����������� �� ������� ���������� ������� � ����� � ���������� ������������
                             nMOVE_TYPE   := 1;  -- ������ ����������� = ���������� �����������
                when 17 then nACTION_TYPE := 15; -- ������
                when 18 then nACTION_TYPE := 16; -- �������� � ������������
                when 19 then nACTION_TYPE := 9;  -- ��������� �����������
                when 20 then nACTION_TYPE := 8;  -- ��������� ��������
                when 21 then nACTION_TYPE := 9;  -- ����������� � ���������� ����������� �����������
                when 22 then nACTION_TYPE := 16; -- �������� � ������������ �� ������� ���������� �������
                when 23 then nACTION_TYPE := 16; -- ����������� �� ������� ���������� ������� � ����� � ��������� � ������������
                when 24 then nACTION_TYPE := 10; -- ������� �� �������� ��-6, � ����.
                when 25 then nACTION_TYPE := 16; -- �������� � ������������
                else
                  P_EXCEPTION( 0, '����������� ��� �������� (CODE = '||to_char(rHST.CODE)||').' );
                end case;

                if rHST.NORM_AMORT > 100 then
                  nAMORT_YEAR := 100;
                else
                  nAMORT_YEAR := rHST.NORM_AMORT;
                end if;

                /* ���������� ������� �������� */
                INVHIST_INSERT
                (
                  nPRN                 => nINV_RN,                                               -- ��������
                  nCOMPANY             => nCOMPANY,                                              -- �����������
                  nCRN                 => nCRN,                                                  -- �������
                  nJUR_PERS            => nJUR_PERS,                                             -- ������
                  nNUMB                => rHST.ROWNUM,                                           -- ����� ��������
                  nACTION_TYPE         => nACTION_TYPE,                                          -- ��� ��������
                  dACTION_DATE         => rHST.ACTION_DATE,                                          -- ���� ��������
                  nFDOC_TYPE           => null,                                                  -- ��� ���������-�������������
                  sFDOC_NUMB           => null,                                                  -- ����� ���������-�������������
                  dFDOC_DATE           => null,                                                  -- ���� ���������-�������������
                  nVDOC_TYPE           => PKG_IMPORT7.GET_RN8(0, 1, 'DOCBASE', rHST.RN_DOC),     -- ��� ���������-���������
                  sVDOC_NUMB           => rHST.NUM_DOC,                                          -- ����� ���������-���������
                  dVDOC_DATE           => rHST.DATE_DOC,                                         -- ���� ���������-���������
                  nOLD_ACCOUNT         => PKG_IMPORT7.GET_RN8(0, 1, 'ACCBASE', rHST.RN_ACC_OLD), -- ���� ��
                  nNEW_ACCOUNT         => PKG_IMPORT7.GET_RN8(0, 1, 'ACCBASE', rHST.RN_ACC_NEW), -- ���� �����
                  nOLD_BALUNIT         => null,                                                  -- ��� ��
                  nNEW_BALUNIT         => null,                                                  -- ��� �����
                  nAGENT_FROM          => PKG_IMPORT7.GET_RN8(0, 1, 'ORGBASE', rHST.RN_MOL_OLD), -- �� ����
                  nAGENT_TO            => PKG_IMPORT7.GET_RN8(0, 1, 'ORGBASE', rHST.RN_MOL_NEW), -- ����
                  nAMORT_RN            => PKG_IMPORT7.GET_RN8(0, 1, 'AMORT',   rHST.RN_AMORT),   -- ���� �����������
                  sAMORT_NOTE          => rHST.PRIMECH,                                          -- ����������
                  dAMORT_OLD_DUR_DATE  => rHST.DATE_OLD,                                         -- ���� ��������� ����������� �����������
                  nAMORT_FAST          => rHST.CORR_KOEFF,                                       -- ����������� ����������� (������������� ������) ��
                  nAMORT_FAST_NEW      => rHST.CORR_KOEFF,                                       -- ����������� ����������� (������������� ������) �����
                  nCAMORT_FAST         => 1,                                                     -- ����������� ����������� (�������������� ������) ��
                  nCAMORT_FAST_NEW     => 1,                                                     -- ����������� ����������� (�������������� ������) �����
                  nAMORT_YEAR          => nAMORT_YEAR,                                           -- ����� �� �������������� (������������� ������)
                  nAMORT_YEAR_C        => 0,                                                     -- ����� �� �������������� (�������������� ������)
                  nAMORT_RUN           => rHST.RUN,                                              -- ����� �� 1000 �� ������� (������������� ������)
                  nAMORT_RUN_C         => 0,                                                     -- ����� �� 1000 �� ������� (�������������� ������)
                  nACNT_RUN            => 0,                                                     -- ������ (������������� ������)
                  nCTRL_RUN            => 0,                                                     -- ������ (�������������� ������)
                  nAMORT_YEAR_SUM      => 0,                                                     -- ����� �� �������������� (������������� ������)
                  nAMORT_YEAR_C_SUM    => 0,                                                     -- ����� �� �������������� (�������������� ������)
                  nAMORT_YEAR_BSUM     => 0,                                                     -- ����� � ����������� �� �������������� (������������� ������)
                  nAMORT_YEAR_C_BSUM   => 0,                                                     -- ����� � ����������� �� �������������� (�������������� ������)
                  nAMORT_RUN_SUM       => 0,                                                     -- ����� �� 1000 �� ������� (������������� ������)
                  nAMORT_RUN_C_SUM     => 0,                                                     -- ����� �� 1000 �� ������� (�������������� ������)
                  nAMORT_RUN_BSUM      => 0,                                                     -- ����� � ����������� �� 1000 �� ������� (������������� ������)
                  nAMORT_RUN_C_BSUM    => 0,                                                     -- ����� � ����������� �� 1000 �� ������� (�������������� ������)
                  nALT_SUM             => rHST.ADD_SUM,                                          -- �������������� ���������� (������������� ������)
                  nALT_C_SUM           => 0,                                                     -- �������������� ���������� (�������������� ������)
                  nALT_BSUM            => rHST.ADD_SUM,                                          -- �������������� ���������� � ����������� (������������� ������)
                  nALT_C_BSUM          => 0,                                                     -- �������������� ���������� � ����������� (�������������� ������)
                  nREVAL_TYPE          => 0,                                                     -- ��� ���������� (0-�����������, 1-�����)
                  nREVAL_EQUAL         => 0,                                                     -- ����������� ���������� (������������� ������)
                  nREVAL_C_EQUAL       => 0,                                                     -- ����������� ���������� (�������������� ������)
                  nREVAL_SUM           => 0,                                                     -- ����� ���������� (������������� ������)
                  nREVAL_C_SUM         => 0,                                                     -- ����� ���������� (�������������� ������)
                  nOLD_A_COST_BEGIN    => rHST.INSUM_OLD,                                        -- ��������� ��������� (������������� ������)
                  nOLD_AB_COST_BEGIN   => rHST.INSUM_OLD,                                        -- ��������� ��������� � ����������� (������������� ������)
                  nOLD_C_COST_BEGIN    => 0,                                                     -- ��������� ��������� (�������������� ������)
                  nOLD_CB_COST_BEGIN   => 0,                                                     -- ��������� ��������� � ����������� (�������������� ������)
                  nOLD_A_AMORT_BEGIN   => rHST.INWEAR_OLD,                                       -- ��������� ����� (������������� ������)
                  nOLD_AB_AMORT_BEGIN  => rHST.INWEAR_OLD,                                       -- ��������� ����� � ����������� (������������� ������)
                  nOLD_C_AMORT_BEGIN   => 0,                                                     -- ��������� ����� (�������������� ������)
                  nOLD_CB_AMORT_BEGIN  => 0,                                                     -- ��������� ����� � ����������� (�������������� ������)
                  nOLD_A_AMORT_DURING  => rHST.WEAR_OLD,                                         -- ����������� ����������� (������������� ������)
                  nOLD_AB_AMORT_DURING => rHST.WEAR_OLD,                                         -- ����������� ����������� � ����������� (������������� ������)
                  nOLD_C_AMORT_DURING  => 0,                                                     -- ����������� ����������� (�������������� ������)
                  nOLD_CB_AMORT_DURING => 0,                                                     -- ����������� ����������� � ����������� (�������������� ������)
                  nOLD_A_COST_END      => rHST.RST_CSUM_O,                                       -- ���������� ��������� (������������� ������)
                  nOLD_AB_COST_END     => rHST.RST_CSUM_O,                                       -- ���������� ��������� � ����������� (������������� ������)
                  nOLD_C_COST_END      => 0,                                                     -- ���������� ��������� (�������������� ������)
                  nOLD_CB_COST_END     => 0,                                                     -- ���������� ��������� � ����������� (�������������� ������)
                  nOLD_A_SUM_CAP       => 0,                                                     -- ����� ����������� �������� (������������� ������)
                  nOLD_AB_SUM_CAP      => 0,                                                     -- ����� ����������� �������� ����������� (������������� ������)
                  nOLD_C_SUM_CAP       => 0,                                                     -- ����� ����������� �������� (�������������� ������)
                  nOLD_CB_SUM_CAP      => 0,                                                     -- ����� ����������� �������� ����������� (�������������� ������)
                  nNEW_A_COST_BEGIN    => rHST.INSUM_NEW,                                        -- ��������� ��������� (������������� ������)
                  nNEW_AB_COST_BEGIN   => rHST.INSUM_NEW,                                        -- ��������� ��������� � ����������� (������������� ������)
                  nNEW_C_COST_BEGIN    => 0,                                                     -- ��������� ��������� (�������������� ������)
                  nNEW_CB_COST_BEGIN   => 0,                                                     -- ��������� ��������� � ����������� (�������������� ������)
                  nNEW_A_AMORT_BEGIN   => rHST.INWEAR_NEW,                                       -- ��������� ����� (������������� ������)
                  nNEW_AB_AMORT_BEGIN  => rHST.INWEAR_NEW,                                       -- ��������� ����� � ����������� (������������� ������)
                  nNEW_C_AMORT_BEGIN   => 0,                                                     -- ��������� ����� (�������������� ������)
                  nNEW_CB_AMORT_BEGIN  => 0,                                                     -- ��������� ����� � ����������� (�������������� ������)
                  nNEW_A_AMORT_DURING  => rHST.WEAR_NEW,                                         -- ����������� ����������� (������������� ������)
                  nNEW_AB_AMORT_DURING => rHST.WEAR_NEW,                                         -- ����������� ����������� � ����������� (������������� ������)
                  nNEW_C_AMORT_DURING  => 0,                                                     -- ����������� ����������� (�������������� ������)
                  nNEW_CB_AMORT_DURING => 0,                                                     -- ����������� ����������� � ����������� (�������������� ������)
                  nNEW_A_COST_END      => rHST.RST_CSUM_N,                                       -- ���������� ��������� (������������� ������)
                  nNEW_AB_COST_END     => rHST.RST_CSUM_N,                                       -- ���������� ��������� � ����������� (������������� ������)
                  nNEW_C_COST_END      => 0,                                                     -- ���������� ��������� (�������������� ������)
                  nNEW_CB_COST_END     => 0,                                                     -- ���������� ��������� � ����������� (�������������� ������)
                  nNEW_A_SUM_CAP       => 0,                                                     -- ����� ����������� �������� (������������� ������)
                  nNEW_AB_SUM_CAP      => 0,                                                     -- ����� ����������� �������� ����������� (������������� ������)
                  nNEW_C_SUM_CAP       => 0,                                                     -- ����� ����������� �������� (�������������� ������)
                  nNEW_CB_SUM_CAP      => 0,                                                     -- ����� ����������� �������� ����������� (�������������� ������)
                  nMAIN_OPER_REF       => null,                                                  -- ������ �� �������� �������� ��
                  nALT_OPER_REF        => null,                                                  -- ������ �� �������������� �������� ��
                  nOPER_TYPE           => nOPER_TYPE,                                            -- ��� ��������
                  nCOUNT_OLD           => rHST.KOLIO_OLD,                                        -- ���������� ��
                  nCOUNT_NEW           => rHST.KOLIO_NEW,                                        -- ���������� �����
                  nSUBDIV_OLD          => null,                                                  -- ������������� ��
                  nSUBDIV_NEW          => null,                                                  -- ������������� �����
                  nANL_OLD1            => PKG_IMPORT7.GET_RN8(0, 1, 'ACCSPEC', rHST.RN_AC_OLD_), -- ��������� 1 ������ ��
                  nANL_NEW1            => PKG_IMPORT7.GET_RN8(0, 1, 'ACCSPEC', rHST.RN_AC_NEW_), -- ��������� 1 ������ �����
                  nANL_OLD2            => PKG_IMPORT7.GET_RN8(0, 1, 'ACCSPEC', rHST.RN_AC_OLD2), -- ��������� 2 ������ ��
                  nANL_NEW2            => PKG_IMPORT7.GET_RN8(0, 1, 'ACCSPEC', rHST.RN_AC_NEW2), -- ��������� 2 ������ �����
                  nANL_OLD3            => PKG_IMPORT7.GET_RN8(0, 1, 'ACCSPEC', rHST.RN_AC_OLD3), -- ��������� 3 ������ ��
                  nANL_NEW3            => PKG_IMPORT7.GET_RN8(0, 1, 'ACCSPEC', rHST.RN_AC_NEW3), -- ��������� 3 ������ �����
                  nANL_OLD4            => PKG_IMPORT7.GET_RN8(0, 1, 'ACCSPEC', rHST.RN_AC_OLD4), -- ��������� 4 ������ ��
                  nANL_NEW4            => PKG_IMPORT7.GET_RN8(0, 1, 'ACCSPEC', rHST.RN_AC_NEW4), -- ��������� 4 ������ �����
                  nANL_OLD5            => PKG_IMPORT7.GET_RN8(0, 1, 'ACCSPEC', rHST.RN_AC_OLD5), -- ��������� 5 ������ ��
                  nANL_NEW5            => PKG_IMPORT7.GET_RN8(0, 1, 'ACCSPEC', rHST.RN_AC_NEW5), -- ��������� 5 ������ �����
                  nA_REALIZ_SUM        => 0,
                  nAB_REALIZ_SUM       => 0,
                  nC_REALIZ_SUM        => 0,
                  nCB_REALIZ_SUM       => 0,
                  nPLACE_OLD           => null,                                                  -- ��������������� ��
                  nPLACE_NEW           => null,                                                  -- ��������������� �����
                  nA_TERM_USE_OLD      => rHST.SROK_OST_O,                                       -- ���� ��������� ������������� (������������� ������) ��
                  nA_TERM_USE_NEW      => rHST.SROKOST_NE,                                       -- ���� ��������� ������������� (������������� ������) �����
                  nC_TERM_USE_OLD      => 0,                                                     -- ���� ��������� ������������� (�������������� ������) ��
                  nC_TERM_USE_NEW      => 0,                                                     -- ���� ��������� ������������� (�������������� ������) �����
                  nA_TERM_USE_REST_OLD => rHST.SROK_OST_O,                                       -- ���������� ���� ��������� ������������� (������������� ������) ��
                  nA_TERM_USE_REST_NEW => rHST.SROKOST_NE,                                       -- ���������� ���� ��������� ������������� (������������� ������) �����
                  nC_TERM_USE_REST_OLD => 0,                                                     -- ���������� ���� ��������� ������������� (�������������� ������) ��
                  nC_TERM_USE_REST_NEW => 0,                                                     -- ���������� ���� ��������� ������������� (�������������� ������) �����
                  nINVOBJCL_OLD        => null,                                                  -- ����� ������������ ������� ��
                  nINVOBJCL_NEW        => null,                                                  -- ����� ������������ ������� �����
                  nMOVE_TYPE           => nMOVE_TYPE,                                            -- ������ �����������
                  nCONSERV_TYPE        => nCONSERV_TYPE,                                         -- ������ �����������/��������������
                  nSTATE_REGIST        => 0,                                                     -- ���� ��������������� �����������
                  nASSETS_LIMIT        => 0,                                                     -- ����������� ������������� ��������
                  nTAXOBJTYPES_OLD     => null,                                                  -- ��� ������� ��������������� ��
                  nTAXOBJTYPES_NEW     => null,                                                  -- ��� ������� ��������������� �����
                  nAMORT_TYPE_OLD      => nAMORT_TYPE,                                           -- ������ ���������� ����������� ��
                  nAMORT_TYPE_NEW      => nAMORT_TYPE,                                           -- ������ ���������� ����������� �����
                  nTAX_GROUP_OLD       => null,                                                  -- ��������������� ������ ��
                  nTAX_GROUP_NEW       => null,                                                  -- ��������������� ������ �����
                  nTAX_SUBGROUP_OLD    => null,                                                  -- ��������������� ��������� ��
                  nTAX_SUBGROUP_NEW    => null,                                                  -- ��������������� ��������� �����
                  nOLD_A_GR_COST_END   => 0,                                                     -- ���������� ��������� �� ������ � ������ (������������� ������) ��
                  nNEW_A_GR_COST_END   => 0,                                                     -- ���������� ��������� �� ������ � ������ (������������� ������) �����
                  nOLD_AB_GR_COST_END  => 0,                                                     -- ���������� ��������� �� ������ � ����������� (������������� ������) ��
                  nNEW_AB_GR_COST_END  => 0,                                                     -- ���������� ��������� �� ������ � ����������� (������������� ������) �����
                  nOLD_C_GR_COST_END   => 0,                                                     -- ���������� ��������� �� ������ � ������ (�������������� ������) ��
                  nNEW_C_GR_COST_END   => 0,                                                     -- ���������� ��������� �� ������ � ������ (�������������� ������) �����
                  nOLD_CB_GR_COST_END  => 0,                                                     -- ���������� ��������� �� ������ � ����������� (�������������� ������) ��
                  nNEW_CB_GR_COST_END  => 0,                                                     -- ���������� ��������� �� ������ � ����������� (�������������� ������) �����
                  nA_GR_AMORT_DURING   => 0,                                                     -- ��������� �� ������ � ������ (������������� ������)
                  nAB_GR_AMORT_DURING  => 0,                                                     -- ��������� �� ������ � ����������� (������������� ������)
                  nC_GR_AMORT_DURING   => 0,                                                     -- ��������� �� ������ � ������ (�������������� ������)
                  nCB_GR_AMORT_DURING  => 0,                                                     -- ��������� �� ������ � ����������� (�������������� ������)
                  --
                  nRN                  => nHST_RN
                );
                PKG_IMPORT7.SET_REF( 'INSPEC', rHST.RN, nHST_RN );

                /* ���������� � ��*/
                for rREF in
                (
                select R.CHILD_RN, R.CHILD_RN_E
                  from P7_UNIT_REF R,
                       P7_UNITS UI,
                       P7_UNITS UE
                  where R.PARENT_UNT = UI.RN
                    and R.CHILD_UNT = UE.RN
                    and R.PARENT_RN = rHST.RN
                    and UI.NAME = 'Inventory'
                    and UE.NAME = 'EconOp'
                    and R.CHILD_RN is not null
                ) loop
                  begin
                    nECONOPRS := PKG_IMPORT7.GET_RN8(1, 1, 'EOPBASE', rREF.CHILD_RN);
                    if nECONOPRS is not null then
                      nOPRSPECS := PKG_IMPORT7.GET_RN8(1, 1, 'EOPSPEC', rREF.CHILD_RN_E);

                      if rREF.CHILD_RN_E is null or nOPRSPECS is not null then

                        /* ������ - ������ */
                        PKG_DOCLINKS.LINK
                        (
                          nFLAG_SMART       => 1,
                          nCOMPANY          => nCOMPANY,
                          sIN_UNITCODE      => 'Inventory',
                          nIN_DOCUMENT      => nINV_RN,
                          nIN_PRN_DOCUMENT  => null,
                          sOUT_UNITCODE     => 'EconomicOperations',
                          nOUT_DOCUMENT     => nECONOPRS,
                          nOUT_PRN_DOCUMENT => null,
                          nBREAKUP_KIND     => 0,
                          nLINK_TYPE        => null,
                          nIDENT            => null
                        );

                        /* ������ - ������*/
                        PKG_DOCLINKS.LINK
                        (
                          nFLAG_SMART       => 1,
                          nCOMPANY          => nCOMPANY,
                          sIN_UNITCODE      => 'InventoryHistory',
                          nIN_DOCUMENT      => nHST_RN,
                          nIN_PRN_DOCUMENT  => nINV_RN,
                          sOUT_UNITCODE     => 'EconomicOperations',
                          nOUT_DOCUMENT     => nECONOPRS,
                          nOUT_PRN_DOCUMENT => null,
                          nBREAKUP_KIND     => 0,
                          nLINK_TYPE        => null,
                          nIDENT            => null
                        );

                        for rOPSPEC in
                        (
                        select RN
                          from OPRSPECS
                          where PRN = nECONOPRS
                            and (nOPRSPECS is null or RN = nOPRSPECS)
                        ) loop
                            /* ������ - ������ */
                            PKG_DOCLINKS.LINK
                            (
                              nFLAG_SMART       => 1,
                              nCOMPANY          => nCOMPANY,
                              sIN_UNITCODE      => 'Inventory',
                              nIN_DOCUMENT      => nINV_RN,
                              nIN_PRN_DOCUMENT  => null,
                              sOUT_UNITCODE     => 'EconomicOperationsSpecs',
                              nOUT_DOCUMENT     => rOPSPEC.RN,
                              nOUT_PRN_DOCUMENT => nECONOPRS,
                              nBREAKUP_KIND     => 0,
                              nLINK_TYPE        => null,
                              nIDENT            => null
                            );

                            /* ������ - ������*/
                            PKG_DOCLINKS.LINK
                            (
                              nFLAG_SMART       => 1,
                              nCOMPANY          => nCOMPANY,
                              sIN_UNITCODE      => 'InventoryHistory',
                              nIN_DOCUMENT      => nHST_RN,
                              nIN_PRN_DOCUMENT  => nINV_RN,
                              sOUT_UNITCODE     => 'EconomicOperationsSpecs',
                              nOUT_DOCUMENT     => rOPSPEC.RN,
                              nOUT_PRN_DOCUMENT => nECONOPRS,
                              nBREAKUP_KIND     => 0,
                              nLINK_TYPE        => null,
                              nIDENT            => null
                            );
                        end loop;
                      end if;
                    end if;
                  exception
                    when OTHERS then
                      PKG_IMPORT7.LOG_ERROR('INSPEC_EO', rHST.RN);
                  end;
                end loop;
              exception
                when OTHERS then
                  PKG_IMPORT7.LOG_ERROR( 'INSPEC', rHST.RN );
              end;
            end if; -- nHST_RN is null
          end loop; -- rHST
          PKG_IMPORT7.SET_REF( 'INBASE', rINV.RN, nINV_RN );
        exception
          when OTHERS then
            PKG_IMPORT7.LOG_ERROR( 'INBASE', rINV.RN );
        end;
      end if; -- nINV_RN is null
    end loop; -- rINV

    /* �������� �������� INVENTORY */
    execute immediate 'alter table INVENTORY enable all triggers';
    execute immediate 'alter table INVHIST   enable all triggers';
  exception
    when OTHERS then
      rollback;
      /* �������� �������� INVENTORY */
      execute immediate 'alter table INVENTORY enable all triggers';
      execute immediate 'alter table INVHIST   enable all triggers';
      raise;
  end;
end;
/
