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

  /* формирование инвентарной группы и инвентарного номера карточки */
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
    /* Предварительное формирование */
    -- инвентарная группа (префикс)
    sOUT_OBJECT_GROUP  := substr(lpad(strtrim(sGROUP_INV),3,'0')||lpad(strtrim(sNUM_INV),15,'0'),1,8);
    sOUT_OBJECT_GROUP  := strright(strtrim(sOUT_OBJECT_GROUP),10);
    -- инвентарная группа (номер)
    sOUT_OBJECT_NUMBER := substr(lpad(strtrim(sGROUP_INV),3,'0')||lpad(strtrim(sNUM_INV),15,'0'),9);
    sOUT_OBJECT_NUMBER := strright(strtrim(sOUT_OBJECT_NUMBER),10);

    -- инвентарный номер
    sOUT_INV_NUMBER := strtrim(sOUT_OBJECT_GROUP)||GET_OPTIONS_STR('PrefSymb')||strtrim(sOUT_OBJECT_NUMBER);
    sOUT_INV_NUMBER := strright(strtrim(sOUT_INV_NUMBER),40);
  end SET_INV_NUMBER;

  /* формирование префикса карточки */
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

    /* поиск карточки по префиксу и номеру */
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

    /* если найдена - генерируем уникальный префикс */
    if nTMP_RN is not null then

      /* поиск максимального префикса */
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

      /* генерация */
      PKG_DOCUMENT.NEXT_NUMBER( sRESULT1, 10, sRESULT );
    end if;

    return sRESULT;
  end GET_CARD_PREF;

  /* поиск/создание местонахождения */
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
      /* считывание контрагента */
      begin
        select AGNABBR, substr(AGNNAME,1,80)
          into sCODE, sNAME
          from AGNLIST
         where RN = nAGENT;
      exception
        when NO_DATA_FOUND then
          PKG_MSG.RECORD_NOT_FOUND( nAGENT, 'AGNLIST' );
      end;

      /* поиск местонахождения по мнемокоду */
      FIND_DICPLACE_SMART_MNEMO( 1, nCOMPANY, sCODE, nRESULT );

      if nRESULT is null then
        /* каталог местонахождения */
        FIND_ROOT_CATALOG( nCOMPANY, 'ObjPlace', nDICPLACE_CRN );

        /* наименование местонахождения */
        sNAME := PKG_EXECUTE.FIND_UNIQUE_COLUMN_VALUE( 'DICPLACE', 'COMPANY', nCOMPANY, 'PLACE_NAME', sNAME );

        /* добавление местонахождения */
        P_DICPLACE_BASE_INSERT( nCOMPANY, nDICPLACE_CRN, sCODE, sNAME, null, null, nRESULT );
      end if;
    end if;

    return nRESULT;
  end GET_DICPLACE;

  /* добавление инвентарной карточки */
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
    /* Проверки ( из P_INVENTORY_BASE_INSERT ) */

    /* Проверка возможности создания карточки для инвентарного объекта */
    P_INVENTORY_INVOBJ_CHECK( nCOMPANY, nACCTYPES, nINVOBJECT, null );

    /* Проверки ( из T_INVENTORY_BINSERT ) */

    /* СПИ */
    if nAMORT_TYPE in (1, 2, 5) and nACNT_TERM_USE = 0 then
      P_EXCEPTION( 0, 'Недопустимое значение срока полезного использования.' );
    end if;

    /* основные средства */
    if PKG_ACCTFORM.IS_TYPFORM( PKG_ACCTFORM.sIS_MainValues, null, nACCOUNT ) = 0 then
      P_EXCEPTION( 0, 'Счет инвентарного учета должен иметь типовую форму "Основные средства".' );
    end if;

    /* корректировка инвентарной группы (префикс) */
    if sOBJECT_GROUP is not null then
      sNEW_OBJECT_GROUP := strright( strtrim( sOBJECT_GROUP ),10 );
    end if;
    /* корректировка инвентарной группы (номер) */
    if sOBJECT_NUMBER is not null then
      sNEW_OBJECT_NUMBER := strright( strtrim( sOBJECT_NUMBER ),10 );
    end if;
    /* корректировка инвентарного номера */
    if sINV_NUMBER is not null then
      sNEW_INV_NUMBER := strright( strtrim( sINV_NUMBER ),40 );
    end if;
    /* корректировка номера карточки */
    sNEW_CARD_PREF := strright( strtrim( sCARD_PREF ),10 );
    sNEW_CARD_NUMB := strright( strtrim( sCARD_NUMB ),10 );
    /* корректировка кода по ОКОФ */
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
      P_EXCEPTION( 0, 'Не задана дата начисленния амортизации/износа.' );
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
      P_EXCEPTION( 0, 'Сумма и эквивалент должны совпадать.' );
    end if;

    if nvl( GET_OPTIONS_NUM('InventoryFundUse', nCOMPANY), 0) = 1 then
      if not (nA_AMORT_BEGIN  + nA_AMORT_DURING  + nA_SUM_FUND  + nA_SUM_CAP  + nA_AMORT_OFF  <= nA_COST_BEGIN  and
              nAB_AMORT_BEGIN + nAB_AMORT_DURING + nAB_SUM_FUND + nAB_SUM_CAP + nAB_AMORT_OFF <= nAB_COST_BEGIN and
              nC_AMORT_BEGIN  + nC_AMORT_DURING  + nC_SUM_FUND  + nC_SUM_CAP  + nC_AMORT_OFF  <= nC_COST_BEGIN  and
              nCB_AMORT_BEGIN + nCB_AMORT_DURING + nCB_SUM_FUND + nCB_SUM_CAP + nCB_AMORT_OFF <= nCB_COST_BEGIN) then
        P_EXCEPTION( 0, 'Сумма бюджетных ассигнований, начального износа, капитальных вложений, начисленной и списанной недоначисленной амортизации должна быть меньше либо равна начальной стоимости.' );
      end if;
    else
      if not (nA_AMORT_BEGIN  + nA_AMORT_DURING  + nA_SUM_CAP  + nA_AMORT_OFF  <= nA_COST_BEGIN  and
              nAB_AMORT_BEGIN + nAB_AMORT_DURING + nAB_SUM_CAP + nAB_AMORT_OFF <= nAB_COST_BEGIN and
              nC_AMORT_BEGIN  + nC_AMORT_DURING  + nC_SUM_CAP  + nC_AMORT_OFF  <= nC_COST_BEGIN  and
              nCB_AMORT_BEGIN + nCB_AMORT_DURING + nCB_SUM_CAP + nCB_AMORT_OFF <= nCB_COST_BEGIN) then
        P_EXCEPTION( 0, 'Сумма начального износа, капитальных вложений, начисленной  и списанной недоначисленной амортизации должна быть меньше либо равна начальной стоимости.' );
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

  /* добавление состава объектов */
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

    /* генерация RN */
    nRN := GEN_ID;

    /* добавление */
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

  /* добавление в состав групповой карточки */
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
    /* генерация регистрационного номера */
    nRN := GEN_ID;

    /* добавление записи в таблицу */
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


  /* добавление истории операций */
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
  /* Сделать:
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

  /* определение принадлежности - основное юридическое лицо */
  FIND_JURPERSONS_MAIN(0, PKG_IMPORT7.nCOMPANY, sTMP, nMAIN_JUR_PERS);

  /* отключаем триггеры INVENTORY */
  execute immediate 'alter table INVENTORY disable all triggers';
  execute immediate 'alter table INVHIST   disable all triggers';

  begin
    /* цикл по карточкам Парус 7 */
    for rINV in
    (
      select t.*, rownum, count(1) over() ncount from (select *
        from P7_INBASE
        where RN_ORG is not null
        order by GROUP_INV, NUM_INV) t
    )
    loop
      dbms_application_info.set_action(ROUND(rINV.Rownum / rINV.Ncount * 1000) / 10);
      /* проверка карточки на предыдущий импорт */
      nINV_RN := PKG_IMPORT7.GET_RN8( 1, 0, 'INBASE', rINV.RN );

      if nINV_RN is null then
        begin
          -- способ начисления амортизации
          if rINV.METH_AMORT = 6 then
            nAMORT_TYPE := 4;
          elsif rINV.METH_AMORT = 1 then
            nAMORT_TYPE := 1;
          else
            nAMORT_TYPE := 3;
          end if;

          -- юр.лицо
          nJUR_PERS :=  nvl(F_IMPORT7_JURPERS(0, 1, rINV.RN_ORGPU, nMAIN_JUR_PERS), nMAIN_JUR_PERS);

          -- состояние инвентарного объекта
          if rINV.DATE_OUT is not null then
            nOBJ_STATUS := 2;  -- выбыл
          elsif rINV.DATKONS is not null then
            nOBJ_STATUS := 3;  -- законсервирован
          elsif rINV.DATE_IN is not null then
            nOBJ_STATUS := 1;  -- принят к учету
          else
            nOBJ_STATUS := 0;  -- не введен
          end if;

          -- счет
          nACCOUNT := PKG_IMPORT7.GET_RN8( 0, 0, 'ACCBASE', rINV.RN_ACCOUNT );

          -- вид учета
          begin
            select ACCTYPES
              into nACCTYPES
              from DICACCS
              where RN = nACCOUNT;
          exception
            when NO_DATA_FOUND then
              PKG_MSG.RECORD_NOT_FOUND( nACCOUNT, 'AccountsPlan' );
          end;

          -- номер карточки
          sCARD_NUMB := STRRIGHT( to_char(rINV.NUM_CARD), 10 );
          -- префикс карточки
          sCARD_PREF := GET_CARD_PREF( nACCTYPES, sCARD_NUMB );

          -- ОКОФ
          nOKOF := PKG_IMPORT7.GET_RN8( 1, 1, 'OKOF', rINV.RN_OKOF );
          if nOKOF is not null then
            FIND_OKOF_PARAMS( 0, nCOMPANY, nOKOF, sOKOF_CODE, sOKOF_NAME, sOKOF_FULLNAME, nOKOF_HIER_LEVEL, sTAX_GROUP );
            sCLASS_PREF := substr(sOKOF_CODE,1,2);
            sCLASS_NUMB := substr(sOKOF_CODE,4);
          else
            sCLASS_PREF := null;
            sCLASS_NUMB := null;
          end if;

          -- местонахождение
          nOBJECT_PLACE := GET_DICPLACE( PKG_IMPORT7.GET_RN8(0, 1, 'ORGBASE', rINV.LOCATION_R) );

          -- тип карточки
          case rINV.TYPIK
          when 0 then nCARD_TYPE := 0; -- ОС-6
          when 1 then nCARD_TYPE := 1; -- ОС-8
          when 2 then nCARD_TYPE := 1; -- ОС-8
          when 3 then nCARD_TYPE := 2; -- ОС-9
          when 4 then nCARD_TYPE := 3; -- ОС-С
          when 5 then nCARD_TYPE := 4; -- ОС-Э
          else
            P_EXCEPTION( 0, 'Неизвестный тип карточки (TYPIK = '||to_char(rINV.TYPIK)||').' );
          end case;

          -- Оставшийся срок полезного использования
          if rINV.DATE_SROK is not null then
            nA_TERM_USE_REST := rINV.SROK_OST;
          else
            nA_TERM_USE_REST := rINV.SROK;
          end if;

          -- Использовать остаточную стоимость
          if rINV.SROK_OST > 0 then
            nUSE_COST_END := 2;
          else
            nUSE_COST_END := 0;
          end if;

          -- Учет по инвентарным номерам
          if nCARD_TYPE in (0, 1) then
            nINV_NUMB_SIGN := 0;
          elsif nCARD_TYPE = 2 then
            nINV_NUMB_SIGN := 1;
          else
            nINV_NUMB_SIGN := rINV.LGROUPCARD;
          end if;
          -- установка инвентарной группы и номера
          if nINV_NUMB_SIGN = 1 then
            sOBJECT_GROUP  := null;
            sOBJECT_NUMBER := null;
            sINV_NUMBER    := null;
          else
            -- формирование
            SET_INV_NUMBER
            (
              to_char(rINV.GROUP_INV),
              to_char(rINV.NUM_INV),
              sOBJECT_GROUP,
              sOBJECT_NUMBER,
              sINV_NUMBER
            );
          end if;

          -- Количество
          if nCARD_TYPE in (2, 3, 4) then
            nITEM_COUNT := rINV.KOLIO;
          else
            nITEM_COUNT := 1;
          end if;

          -- Суммы
          nA_COST_BEGIN    := rINV.IN_SUM;     -- начальная стоимость (бухгалтерская оценка)
          nAB_COST_BEGIN   := rINV.IN_SUM;     -- начальная стоимость в эквиваленте (бухгалтерская оценка)
          nA_AMORT_BEGIN   := rINV.IN_WEAR;    -- начальный износ (бухгалтерская оценка)
          nAB_AMORT_BEGIN  := rINV.IN_WEAR;    -- начальный износ в эквиваленте (бухгалтерская оценка)
          nA_AMORT_DURING  := rINV.SUMMA_AMOR; -- начисленная амортизация (бухгалтерская оценка)
          nAB_AMORT_DURING := rINV.SUMMA_AMOR; -- начисленная амортизация в эквиваленте (бухгалтерская оценка)
          nA_COST_END      := rINV.RST_SUM;    -- остаточная стоимость (бухгалтерская оценка)
          nAB_COST_END     := rINV.RST_SUM;    -- остаточная стоимость в эквиваленте (бухгалтерская оценка)
          -- Каталог
          nCRN             := PKG_IMPORT7.GET_CATALOG8( 'Inventory', rINV.PARENT_RN );

          /* добавление инвентарной карточки */
          INVENTORY_INSERT
          (
            nCOMPANY           => nCOMPANY,                                                 -- организация
            nCRN               => nCRN,                                                     -- каталог
            nJUR_PERS          => nJUR_PERS,                                                -- юр.лицо
            nINVOBJECT         => null,                                                     -- инвентарный объект
            nINVOBJCL          => null,                                                     -- класс инвентарного объекта
            sINVOBJCL_NAME     => null,                                                     -- класс инвентарного объекта (наименование)
            nOBJ_STATUS        => nOBJ_STATUS,                                              -- состояние инвентарного объекта
            nACCOUNT           => PKG_IMPORT7.GET_RN8( 0, 0, 'ACCBASE', rINV.RN_ACCOUNT ),  -- счет
            nANALYTIC1         => PKG_IMPORT7.GET_RN8( 0, 1, 'ACCSPEC', rINV.RN_AC_A1 ),    -- аналитика 1 уровня
            nANALYTIC2         => PKG_IMPORT7.GET_RN8( 0, 1, 'ACCSPEC', rINV.RN_AC_A2 ),    -- аналитика 2 уровня
            nANALYTIC3         => PKG_IMPORT7.GET_RN8( 0, 1, 'ACCSPEC', rINV.RN_AC_A3 ),    -- аналитика 3 уровня
            nANALYTIC4         => PKG_IMPORT7.GET_RN8( 0, 1, 'ACCSPEC', rINV.RN_AC_A4 ),    -- аналитика 4 уровня
            nANALYTIC5         => PKG_IMPORT7.GET_RN8( 0, 1, 'ACCSPEC', rINV.RN_AC_A5 ),    -- аналитика 5 уровня
            nBALUNIT           => null,                                                     -- ПБЕ
            nCURRENCY          => F_CURBASE_GET_RN( 0, nCOMPANY ),                          -- валюта (базовая)
            nEXECUTIVE         => PKG_IMPORT7.GET_RN8( 0, 0, 'ORGBASE', rINV.RN_ORG ),      -- МОЛ
            sOBJECT_GROUP      => sOBJECT_GROUP,                                            -- инвентарная группа (префикс)
            sOBJECT_NUMBER     => sOBJECT_NUMBER,                                           -- инвентарная группа (номер)
            sINV_NUMBER        => sINV_NUMBER,                                              -- инвентарный номер
            sCARD_PREF         => sCARD_PREF,                                               -- номер карточки (префикс)
            sCARD_NUMB         => sCARD_NUMB,                                               -- номер карточки (номер)
            nNOMENCLATURE      => PKG_IMPORT7.GET_RN8( 0, 0, 'NOBASE', rINV.RN_NOMCL ),     -- номенклатура
            sCLASS_PREF        => sCLASS_PREF,                                              -- код по ОКОФ (группа)
            sCLASS_NUMB        => sCLASS_NUMB,                                              -- код по ОКОФ (номер)
            nOKOF              => nOKOF,                                                    -- ОКОФ
            sOBJECT_NOTE       => strtrim(dbms_lob.substr( rINV.NOTE, 2000 )),              -- краткая характеристика
            sOBJECT_MODEL      => rINV.MODEL,                                               -- объект, марка
            nOBJECT_PLACE      => nOBJECT_PLACE,                                            -- местонахождение
            sWORS_NUMBER       => rINV.NUM_FACT,                                            -- заводской номер
            nPRODUCER          => null,                                                     -- изготовитель
            nA_COST_BEGIN      => nA_COST_BEGIN,                                            -- начальная стоимость (бухгалтерская оценка)
            nAB_COST_BEGIN     => nAB_COST_BEGIN,                                           -- начальная стоимость в эквиваленте (бухгалтерская оценка)
            nC_COST_BEGIN      => 0,                                                        -- начальная стоимость (управленческая оценка)
            nCB_COST_BEGIN     => 0,                                                        -- начальная стоимость в эквиваленте (управленческая оценка)
            nA_SUM_FUND        => 0,                                                        -- сумма бюджетных ассигнований (бухгалтерская оценка)
            nAB_SUM_FUND       => 0,                                                        -- сумма бюджетных ассигнований в эквиваленте (бухгалтерская оценка)
            nC_SUM_FUND        => 0,                                                        -- сумма бюджетных ассигнований (управленческая оценка)
            nCB_SUM_FUND       => 0,                                                        -- сумма бюджетных ассигнований в эквиваленте (управленческая оценка)
            nA_AMORT_BEGIN     => nA_AMORT_BEGIN,                                           -- начальный износ (бухгалтерская оценка)
            nAB_AMORT_BEGIN    => nAB_AMORT_BEGIN,                                          -- начальный износ в эквиваленте (бухгалтерская оценка)
            nC_AMORT_BEGIN     => 0,                                                        -- начальный износ (управленческая оценка)
            nCB_AMORT_BEGIN    => 0,                                                        -- начальный износ в эквиваленте (управленческая оценка)
            dAMORT_DURING_DATE => rINV.DATE_RST,                                            -- дата последнего начисления амортизации
            nA_AMORT_DURING    => nA_AMORT_DURING,                                          -- начисленная амортизация (бухгалтерская оценка)
            nAB_AMORT_DURING   => nAB_AMORT_DURING,                                         -- начисленная амортизация в эквиваленте (бухгалтерская оценка)
            nC_AMORT_DURING    => 0,                                                        -- начисленная амортизация (управленческая оценка)
            nCB_AMORT_DURING   => 0,                                                        -- начисленная амортизация в эквиваленте (управленческая оценка)
            nA_COST_END        => nA_COST_END,                                              -- остаточная стоимость (бухгалтерская оценка)
            nAB_COST_END       => nAB_COST_END,                                             -- остаточная стоимость в эквиваленте (бухгалтерская оценка)
            nC_COST_END        => 0,                                                        -- остаточная стоимость (управленческая оценка)
            nCB_COST_END       => 0,                                                        -- остаточная стоимость в эквиваленте (управленческая оценка)
            nAMORT_RN          => PKG_IMPORT7.GET_RN8(0, 1, 'AMORT', rINV.RN_AMORT),        -- шифр амортизации
            --
            nAMORT_TYPE        => nAMORT_TYPE,                                              -- способ начисления амортизации
            --
            nACNT_TERM_USE     => rINV.SROK,                                                -- Срок полезного использования (бухгалтерская оценка)
            nCTRL_TERM_USE     => 0,                                                        -- Срок полезного использования (управленческая оценка)
            nAMORT_FAST        => rINV.CORR_KOEFF,                                          -- поправочный коэффициент (бухгалтерская оценка)
            nCAMORT_FAST       => 0,                                                        -- поправочный коэффициент (управленческая оценка)
            nCARD_TYPE         => nCARD_TYPE,                                               -- Тип карточки
            dRELEASE_DATE      => rINV.DATE_PROD,                                           -- Дата выпуска    Для ОС-9 - пустая. Для остальных задается вручную.
            dINCOME_DATE       => rINV.DATE_IN,                                             -- Дата поступления
            nITEM_COUNT        => nITEM_COUNT,                                              -- Количество
            nSUBDIV            => null,                                                     -- Подразделение
            nACNT_RUN          => 0,                                                        -- Текущий пробег (бухгалтерская оценка)
            nCTRL_RUN          => 0,                                                        -- Текущий пробег (управленческая оценка)
            nA_TERM_USE_REST   => nA_TERM_USE_REST,                                         -- Оставшийся срок полезного использования (бухгалтерская оценка)
            nC_TERM_USE_REST   => 0,                                                        -- Оставшийся срок полезного использования (управленческая оценка)
            --
            nTAX_GROUP         => null,                                                     -- Амортизационная группа
            nTAX_SUBGROUP      => null,                                                     -- Амортизационная подгруппа
            --
            nUSE_COST_END      => nUSE_COST_END,                                            -- Использовать остаточную стоимость
            nACCTYPES          => nACCTYPES,                                                -- вид учета
            nAMORT_FROM_BEGIN  => 0,                                                        -- Признак начисления амортизации с месяца принятия к учету
            nAMORT_SUM_CAP     => 0,                                                        -- Начисление амортизации с учетом суммы капитальных вложений
            nOPER_RULE         => null,                                                     -- правило отработки начисления амортизации
            nSTATE_REGIST      => 0,                                                        -- факт государственной регистрации
            nASSETS_LIMIT      => 0,                                                        -- ограничения распоряжением активами
            nTAXOBJTYPES       => null,                                                     -- вид объекта налогообложения
            nA_SUM_CAP         => 0,                                                        -- сумма капитальных вложений (бухгалтерская оценка)
            nAB_SUM_CAP        => 0,                                                        -- сумма капитальных вложений эквиваленте (бухгалтерская оценка)
            nC_SUM_CAP         => 0,                                                        -- сумма капитальных вложений (управленческая оценка)
            nCB_SUM_CAP        => 0,                                                        -- сумма капитальных вложений в эквиваленте (управленческая оценка)
            nINV_NUMB_SIGN     => nINV_NUMB_SIGN,                                           -- Учет по инвентарным номерам
            sBARCODE           => null,                                                     -- Штрих-код
            dLABEL_DATE        => null,                                                     -- Дата этикетки
            nA_AMORT_OFF       => 0,                                                        -- списанная недоначисленная амортизация (бухгалтерская оценка)
            nAB_AMORT_OFF      => 0,                                                        -- списанная недоначисленная амортизация в эквиваленте (бухгалтерская оценка)
            nC_AMORT_OFF       => 0,                                                        -- списанная недоначисленная амортизация (управленческая оценка)
            nCB_AMORT_OFF      => 0,                                                        -- списанная недоначисленная амортизация в эквиваленте (управленческая оценка)
            nFREE_SIGN         => 0,                                                        -- безвозмездное поступление: 0 - нет, 1 - да
            --                                                                              --
            nRN                => nINV_RN                                                   -- инвентарная карточка
          );

          /* состав инвентарной карточки */
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
              /* формируем примечание */
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

              /* добавление в состав объекта */
              INVSUBST_INSERT
              (
                nCOMPANY         => nCOMPANY,                                                 -- организация
                nPRN             => nINV_RN,                                                  -- инвентарная карточка
                nNOM             => PKG_IMPORT7.GET_RN8(0, 0, 'NOBASE', rSUBST.RN_PRNOM),     -- номенклатура
                nAMOUNT          => rSUBST.KOLIO,                                             -- количество
                nALT_AMOUNT      => 0,                                                        -- количество в ДЕИ
                sNOTE            => sSUBST_NOTE,                                              -- примечание
                nREVAL_SUM       => rSUBST.NSUM,                                              -- сумма (бухгалтерская оценка)
                nAB_REVAL_SUM    => rSUBST.NSUM,                                              -- сумма в эквиваленте (бухгалтерская оценка)
                nREVAL_C_SUM     => 0,                                                        -- сумма (управленческая оценка)
                nAB_REVAL_C_SUM  => 0,                                                        -- сумма в эквиваленте (управленческая оценка)
                nRARTICLE        => null,                                                     -- изделие
                nPARTY           => null,                                                     -- партия
                sBARCODE         => null,                                                     -- штрих-код
                dLABEL_DATE      => null,                                                     -- дата этикетки
                nRN              => nSUBST                                                    -- рег.номер в составе объекта
              );
            exception
              when OTHERS then
                PKG_IMPORT7.LOG_ERROR( 'INSOST', rSUBST.RN );
            end;
          end loop; -- rSUBST

          /* состав групповой карточки */
          if nCARD_TYPE in (2, 3, 4) then

            /* без учета по инв.номерам */
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

              /* добавление в состав групповой карточки */
              INVPACK_INSERT
              (
                nCOMPANY        => nCOMPANY,                                                -- организация
                nPRN            => nINV_RN,                                                 -- инвентарная карточка
                dIN_DATE        => rINV.DATE_IN,                                            -- дата поступления
                dFACTORY_DATE   => rINV.DATE_PROD,                                          -- дата выпуска
                sFACTORY_NUMBER => rINV.NUM_FACT,                                           -- заводской номер
                sGROUP_NUMBER   => '1',                                                     -- порядковый номер
                sINV_GROUP      => null,                                                    -- инвентарная группа (префикс)
                sINV_NUMB       => null,                                                    -- инвентарная группа (номер)
                sINV_NUMBER     => null,                                                    -- инвентарный номер
                dOUT_DATE       => rINV.DATE_OUT,                                           -- дата выбытия
                nITEM_COUNT     => nITEM_COUNT,                                             -- количество
                nINCOME_SUM_A   => nINCOME_SUM_A,                                           -- сумма прихода (бухгалтерская оценка)
                nINCOME_SUM_AB  => nINCOME_SUM_AB,                                          -- сумма прихода в эквиваленте (бухгалтерская оценка)
                nINCOME_SUM_C   => 0,                                                       -- сумма прихода (управленческая оценка)
                nINCOME_SUM_CB  => 0,                                                       -- сумма прихода в эквиваленте (управленческая оценка)
                nOBJECT_PLACE   => null,                                                    -- местонахождение
                sBARCODE        => null,                                                    -- штрих-код
                dLABEL_DATE     => null,                                                    -- дата этикетки
                nRN             => nPACK                                                    -- рег.номер в групповом составе
              );

            /* с учетом по инв.номерам */
            else
              /* переносим состав */
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
                  /* проверка операции карточки на предыдущий импорт */
                  nPACK := PKG_IMPORT7.GET_RN8( 1, 0, 'INSPIS', rPACK.RN );

                  if nPACK is null then
                    /* формирование инвентарного номера */
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

                    /* добавление в состав групповой карточки */
                    INVPACK_INSERT
                    (
                      nCOMPANY        => nCOMPANY,                                                -- организация
                      nPRN            => nINV_RN,                                                 -- инвентарная карточка
                      dIN_DATE        => rPACK.P7_DATE,                                           -- дата поступления
                      dFACTORY_DATE   => rINV.DATE_PROD,                                          -- дата выпуска
                      sFACTORY_NUMBER => rINV.NUM_FACT,                                           -- заводской номер
                      sGROUP_NUMBER   => to_char(rPACK.ROWNUM),                                   -- порядковый номер
                      sINV_GROUP      => sOBJECT_GROUP,                                           -- инвентарная группа (префикс)
                      sINV_NUMB       => sOBJECT_NUMBER,                                          -- инвентарная группа (номер)
                      sINV_NUMBER     => sINV_NUMBER,                                             -- инвентарный номер
                      dOUT_DATE       => rPACK.DATEOUT,                                           -- дата выбытия
                      nITEM_COUNT     => 1,                                                       -- количество
                      nINCOME_SUM_A   => nINCOME_SUM_A,                                           -- сумма прихода (бухгалтерская оценка)
                      nINCOME_SUM_AB  => nINCOME_SUM_AB,                                          -- сумма прихода в эквиваленте (бухгалтерская оценка)
                      nINCOME_SUM_C   => 0,                                                       -- сумма прихода (управленческая оценка)
                      nINCOME_SUM_CB  => 0,                                                       -- сумма прихода в эквиваленте (управленческая оценка)
                      nOBJECT_PLACE   => null,                                                    -- местонахождение
                      sBARCODE        => null,                                                    -- штрих-код
                      dLABEL_DATE     => null,                                                    -- дата этикетки
                      nRN             => nPACK                                                    -- рег.номер в групповом составе
                    );
                  end if;
                exception
                  when OTHERS then
                    PKG_IMPORT7.LOG_ERROR( 'INSPIS', rPACK.RN );
                end;
                PKG_IMPORT7.SET_REF( 'INSPIS', rPACK.RN, nPACK );
              end loop; -- rPACK
            end if;
          end if; -- состав групповой карточки

          /* цикл по оперциям Парус 7 */
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
            /* проверка операции карточки на предыдущий импорт */
            nHST_RN := PKG_IMPORT7.GET_RN8( 1, 0, 'INSPEC', rHST.RN );

            if nHST_RN is null then
              begin
                -- начальная установка
                nOPER_TYPE    := 2;    -- тип дооценки ("Прочее")
                nMOVE_TYPE    := 0;    -- подтип перемещения ("Не задан")
                nCONSERV_TYPE := 0;    -- подтип консервации/восстановления

                -- тип операции
                case rHST.CODE
                when 1  then nACTION_TYPE := 0;  -- принятие к учету
                when 2  then nACTION_TYPE := 4;  -- списание
                when 3  then nACTION_TYPE := 1;  -- начисление амортизации
                when 4  then nACTION_TYPE := 2;  -- переоценка
                when 5  then nACTION_TYPE := 5;  -- Реконструкция, дооценка, порча
                             nOPER_TYPE   := 0;  -- Реконструкция, модернизация, достройка
                when 6  then nACTION_TYPE := 3;  -- перемещение
                when 7  then nACTION_TYPE := 6;  -- консервация
                when 8  then nACTION_TYPE := 7;  -- Вывод из консервации
                when 9  then nACTION_TYPE := 18; -- Исправительная операция
                when 10 then nACTION_TYPE := 5;  -- дооценка
                             nOPER_TYPE   := 1;  -- тип дооценки = капитальный ремонт
                when 11 then nACTION_TYPE := 5;  -- дооценка (уменьшение стоимости объекта)
                when 12 then nACTION_TYPE := 10; -- Выбытие из состава группового объекта
                when 13 then nACTION_TYPE := 8;  -- Списание из состава группового объекта
                when 14 then nACTION_TYPE := 9;  -- Внутреннее перемещение из состава группового объекта
                when 15 then nACTION_TYPE := 9;  -- Поступление из состава группового объекта
                when 16 then nACTION_TYPE := 9;  -- поступление из состава группового объекта в связи с внутренним перемещением
                             nMOVE_TYPE   := 1;  -- подтип перемещения = внутреннее перемещение
                when 17 then nACTION_TYPE := 15; -- приход
                when 18 then nACTION_TYPE := 16; -- передача в эксплуатацию
                when 19 then nACTION_TYPE := 9;  -- Частичное перемещение
                when 20 then nACTION_TYPE := 8;  -- частичное списание
                when 21 then nACTION_TYPE := 9;  -- Поступление в результате внутреннего перемещения
                when 22 then nACTION_TYPE := 16; -- Передача в эксплуатацию из состава группового объекта
                when 23 then nACTION_TYPE := 16; -- Поступление из состава группового объекта в связи с передачей в эксплуатацию
                when 24 then nACTION_TYPE := 10; -- перевод на карточку ОС-6, и проч.
                when 25 then nACTION_TYPE := 16; -- передача в эксплуатацию
                else
                  P_EXCEPTION( 0, 'Неизвестный тип операции (CODE = '||to_char(rHST.CODE)||').' );
                end case;

                if rHST.NORM_AMORT > 100 then
                  nAMORT_YEAR := 100;
                else
                  nAMORT_YEAR := rHST.NORM_AMORT;
                end if;

                /* добавление истории карточки */
                INVHIST_INSERT
                (
                  nPRN                 => nINV_RN,                                               -- карточка
                  nCOMPANY             => nCOMPANY,                                              -- организация
                  nCRN                 => nCRN,                                                  -- каталог
                  nJUR_PERS            => nJUR_PERS,                                             -- юрлицо
                  nNUMB                => rHST.ROWNUM,                                           -- номер операции
                  nACTION_TYPE         => nACTION_TYPE,                                          -- тип операции
                  dACTION_DATE         => rHST.ACTION_DATE,                                          -- дата операции
                  nFDOC_TYPE           => null,                                                  -- тип документа-подтверждения
                  sFDOC_NUMB           => null,                                                  -- номер документа-подтверждения
                  dFDOC_DATE           => null,                                                  -- дата документа-подтверждения
                  nVDOC_TYPE           => PKG_IMPORT7.GET_RN8(0, 1, 'DOCBASE', rHST.RN_DOC),     -- тип документа-основания
                  sVDOC_NUMB           => rHST.NUM_DOC,                                          -- номер документа-основания
                  dVDOC_DATE           => rHST.DATE_DOC,                                         -- дата документа-основания
                  nOLD_ACCOUNT         => PKG_IMPORT7.GET_RN8(0, 1, 'ACCBASE', rHST.RN_ACC_OLD), -- счет до
                  nNEW_ACCOUNT         => PKG_IMPORT7.GET_RN8(0, 1, 'ACCBASE', rHST.RN_ACC_NEW), -- счет после
                  nOLD_BALUNIT         => null,                                                  -- ПБЕ до
                  nNEW_BALUNIT         => null,                                                  -- ПБЕ после
                  nAGENT_FROM          => PKG_IMPORT7.GET_RN8(0, 1, 'ORGBASE', rHST.RN_MOL_OLD), -- от кого
                  nAGENT_TO            => PKG_IMPORT7.GET_RN8(0, 1, 'ORGBASE', rHST.RN_MOL_NEW), -- кому
                  nAMORT_RN            => PKG_IMPORT7.GET_RN8(0, 1, 'AMORT',   rHST.RN_AMORT),   -- шифр амортизации
                  sAMORT_NOTE          => rHST.PRIMECH,                                          -- примечание
                  dAMORT_OLD_DUR_DATE  => rHST.DATE_OLD,                                         -- дата последней начисленной амортизации
                  nAMORT_FAST          => rHST.CORR_KOEFF,                                       -- поправочный коэффициент (бухгалтерская оценка) до
                  nAMORT_FAST_NEW      => rHST.CORR_KOEFF,                                       -- поправочный коэффициент (бухгалтерская оценка) после
                  nCAMORT_FAST         => 1,                                                     -- поправочный коэффициент (управленческая оценка) до
                  nCAMORT_FAST_NEW     => 1,                                                     -- поправочный коэффициент (управленческая оценка) после
                  nAMORT_YEAR          => nAMORT_YEAR,                                           -- норма на восстановление (бухгалтерская оценка)
                  nAMORT_YEAR_C        => 0,                                                     -- норма на восстановление (управленческая оценка)
                  nAMORT_RUN           => rHST.RUN,                                              -- норма на 1000 км пробега (бухгалтерская оценка)
                  nAMORT_RUN_C         => 0,                                                     -- норма на 1000 км пробега (управленческая оценка)
                  nACNT_RUN            => 0,                                                     -- пробег (бухгалтерская оценка)
                  nCTRL_RUN            => 0,                                                     -- пробег (управленческая оценка)
                  nAMORT_YEAR_SUM      => 0,                                                     -- сумма на восстановление (бухгалтерская оценка)
                  nAMORT_YEAR_C_SUM    => 0,                                                     -- сумма на восстановление (управленческая оценка)
                  nAMORT_YEAR_BSUM     => 0,                                                     -- сумма в эквиваленте на восстановление (бухгалтерская оценка)
                  nAMORT_YEAR_C_BSUM   => 0,                                                     -- сумма в эквиваленте на восстановление (управленческая оценка)
                  nAMORT_RUN_SUM       => 0,                                                     -- сумма на 1000 км пробега (бухгалтерская оценка)
                  nAMORT_RUN_C_SUM     => 0,                                                     -- сумма на 1000 км пробега (управленческая оценка)
                  nAMORT_RUN_BSUM      => 0,                                                     -- сумма в эквиваленте на 1000 км пробега (бухгалтерская оценка)
                  nAMORT_RUN_C_BSUM    => 0,                                                     -- сумма в эквиваленте на 1000 км пробега (управленческая оценка)
                  nALT_SUM             => rHST.ADD_SUM,                                          -- дополнительное начисление (бухгалтерская оценка)
                  nALT_C_SUM           => 0,                                                     -- дополнительное начисление (управленческая оценка)
                  nALT_BSUM            => rHST.ADD_SUM,                                          -- дополнительное начисление в эквиваленте (бухгалтерская оценка)
                  nALT_C_BSUM          => 0,                                                     -- дополнительное начисление в эквиваленте (управленческая оценка)
                  nREVAL_TYPE          => 0,                                                     -- тип переоценки (0-коэффициент, 1-сумма)
                  nREVAL_EQUAL         => 0,                                                     -- коэффициент переоценки (бухгалтерская оценка)
                  nREVAL_C_EQUAL       => 0,                                                     -- коэффициент переоценки (управленческая оценка)
                  nREVAL_SUM           => 0,                                                     -- сумма переоценки (бухгалтерская оценка)
                  nREVAL_C_SUM         => 0,                                                     -- сумма переоценки (управленческая оценка)
                  nOLD_A_COST_BEGIN    => rHST.INSUM_OLD,                                        -- начальная стоимость (бухгалтерская оценка)
                  nOLD_AB_COST_BEGIN   => rHST.INSUM_OLD,                                        -- начальная стоимость в эквиваленте (бухгалтерская оценка)
                  nOLD_C_COST_BEGIN    => 0,                                                     -- начальная стоимость (управленческая оценка)
                  nOLD_CB_COST_BEGIN   => 0,                                                     -- начальная стоимость в эквиваленте (управленческая оценка)
                  nOLD_A_AMORT_BEGIN   => rHST.INWEAR_OLD,                                       -- начальный износ (бухгалтерская оценка)
                  nOLD_AB_AMORT_BEGIN  => rHST.INWEAR_OLD,                                       -- начальный износ в эквиваленте (бухгалтерская оценка)
                  nOLD_C_AMORT_BEGIN   => 0,                                                     -- начальный износ (управленческая оценка)
                  nOLD_CB_AMORT_BEGIN  => 0,                                                     -- начальный износ в эквиваленте (управленческая оценка)
                  nOLD_A_AMORT_DURING  => rHST.WEAR_OLD,                                         -- начисленная амортизация (бухгалтерская оценка)
                  nOLD_AB_AMORT_DURING => rHST.WEAR_OLD,                                         -- начисленная амортизация в эквиваленте (бухгалтерская оценка)
                  nOLD_C_AMORT_DURING  => 0,                                                     -- начисленная амортизация (управленческая оценка)
                  nOLD_CB_AMORT_DURING => 0,                                                     -- начисленная амортизация в эквиваленте (управленческая оценка)
                  nOLD_A_COST_END      => rHST.RST_CSUM_O,                                       -- остаточная стоимость (бухгалтерская оценка)
                  nOLD_AB_COST_END     => rHST.RST_CSUM_O,                                       -- остаточная стоимость в эквиваленте (бухгалтерская оценка)
                  nOLD_C_COST_END      => 0,                                                     -- остаточная стоимость (управленческая оценка)
                  nOLD_CB_COST_END     => 0,                                                     -- остаточная стоимость в эквиваленте (управленческая оценка)
                  nOLD_A_SUM_CAP       => 0,                                                     -- сумма капитальных вложений (бухгалтерская оценка)
                  nOLD_AB_SUM_CAP      => 0,                                                     -- сумма капитальных вложений эквиваленте (бухгалтерская оценка)
                  nOLD_C_SUM_CAP       => 0,                                                     -- сумма капитальных вложений (управленческая оценка)
                  nOLD_CB_SUM_CAP      => 0,                                                     -- сумма капитальных вложений эквиваленте (управленческая оценка)
                  nNEW_A_COST_BEGIN    => rHST.INSUM_NEW,                                        -- начальная стоимость (бухгалтерская оценка)
                  nNEW_AB_COST_BEGIN   => rHST.INSUM_NEW,                                        -- начальная стоимость в эквиваленте (бухгалтерская оценка)
                  nNEW_C_COST_BEGIN    => 0,                                                     -- начальная стоимость (управленческая оценка)
                  nNEW_CB_COST_BEGIN   => 0,                                                     -- начальная стоимость в эквиваленте (управленческая оценка)
                  nNEW_A_AMORT_BEGIN   => rHST.INWEAR_NEW,                                       -- начальный износ (бухгалтерская оценка)
                  nNEW_AB_AMORT_BEGIN  => rHST.INWEAR_NEW,                                       -- начальный износ в эквиваленте (бухгалтерская оценка)
                  nNEW_C_AMORT_BEGIN   => 0,                                                     -- начальный износ (управленческая оценка)
                  nNEW_CB_AMORT_BEGIN  => 0,                                                     -- начальный износ в эквиваленте (управленческая оценка)
                  nNEW_A_AMORT_DURING  => rHST.WEAR_NEW,                                         -- начисленная амортизация (бухгалтерская оценка)
                  nNEW_AB_AMORT_DURING => rHST.WEAR_NEW,                                         -- начисленная амортизация в эквиваленте (бухгалтерская оценка)
                  nNEW_C_AMORT_DURING  => 0,                                                     -- начисленная амортизация (управленческая оценка)
                  nNEW_CB_AMORT_DURING => 0,                                                     -- начисленная амортизация в эквиваленте (управленческая оценка)
                  nNEW_A_COST_END      => rHST.RST_CSUM_N,                                       -- остаточная стоимость (бухгалтерская оценка)
                  nNEW_AB_COST_END     => rHST.RST_CSUM_N,                                       -- остаточная стоимость в эквиваленте (бухгалтерская оценка)
                  nNEW_C_COST_END      => 0,                                                     -- остаточная стоимость (управленческая оценка)
                  nNEW_CB_COST_END     => 0,                                                     -- остаточная стоимость в эквиваленте (управленческая оценка)
                  nNEW_A_SUM_CAP       => 0,                                                     -- сумма капитальных вложений (бухгалтерская оценка)
                  nNEW_AB_SUM_CAP      => 0,                                                     -- сумма капитальных вложений эквиваленте (бухгалтерская оценка)
                  nNEW_C_SUM_CAP       => 0,                                                     -- сумма капитальных вложений (управленческая оценка)
                  nNEW_CB_SUM_CAP      => 0,                                                     -- сумма капитальных вложений эквиваленте (управленческая оценка)
                  nMAIN_OPER_REF       => null,                                                  -- ссылка на основную проводку ХО
                  nALT_OPER_REF        => null,                                                  -- ссылка на дополнительную проводку ХО
                  nOPER_TYPE           => nOPER_TYPE,                                            -- тип дооценки
                  nCOUNT_OLD           => rHST.KOLIO_OLD,                                        -- количество до
                  nCOUNT_NEW           => rHST.KOLIO_NEW,                                        -- количество после
                  nSUBDIV_OLD          => null,                                                  -- подразделение до
                  nSUBDIV_NEW          => null,                                                  -- подразделение после
                  nANL_OLD1            => PKG_IMPORT7.GET_RN8(0, 1, 'ACCSPEC', rHST.RN_AC_OLD_), -- аналитика 1 уровня до
                  nANL_NEW1            => PKG_IMPORT7.GET_RN8(0, 1, 'ACCSPEC', rHST.RN_AC_NEW_), -- аналитика 1 уровня после
                  nANL_OLD2            => PKG_IMPORT7.GET_RN8(0, 1, 'ACCSPEC', rHST.RN_AC_OLD2), -- аналитика 2 уровня до
                  nANL_NEW2            => PKG_IMPORT7.GET_RN8(0, 1, 'ACCSPEC', rHST.RN_AC_NEW2), -- аналитика 2 уровня после
                  nANL_OLD3            => PKG_IMPORT7.GET_RN8(0, 1, 'ACCSPEC', rHST.RN_AC_OLD3), -- аналитика 3 уровня до
                  nANL_NEW3            => PKG_IMPORT7.GET_RN8(0, 1, 'ACCSPEC', rHST.RN_AC_NEW3), -- аналитика 3 уровня после
                  nANL_OLD4            => PKG_IMPORT7.GET_RN8(0, 1, 'ACCSPEC', rHST.RN_AC_OLD4), -- аналитика 4 уровня до
                  nANL_NEW4            => PKG_IMPORT7.GET_RN8(0, 1, 'ACCSPEC', rHST.RN_AC_NEW4), -- аналитика 4 уровня после
                  nANL_OLD5            => PKG_IMPORT7.GET_RN8(0, 1, 'ACCSPEC', rHST.RN_AC_OLD5), -- аналитика 5 уровня до
                  nANL_NEW5            => PKG_IMPORT7.GET_RN8(0, 1, 'ACCSPEC', rHST.RN_AC_NEW5), -- аналитика 5 уровня после
                  nA_REALIZ_SUM        => 0,
                  nAB_REALIZ_SUM       => 0,
                  nC_REALIZ_SUM        => 0,
                  nCB_REALIZ_SUM       => 0,
                  nPLACE_OLD           => null,                                                  -- местонахождение до
                  nPLACE_NEW           => null,                                                  -- местонахождение после
                  nA_TERM_USE_OLD      => rHST.SROK_OST_O,                                       -- срок полезного использования (бухгалтерская оценка) до
                  nA_TERM_USE_NEW      => rHST.SROKOST_NE,                                       -- срок полезного использования (бухгалтерская оценка) после
                  nC_TERM_USE_OLD      => 0,                                                     -- срок полезного использования (управленческая оценка) до
                  nC_TERM_USE_NEW      => 0,                                                     -- срок полезного использования (управленческая оценка) после
                  nA_TERM_USE_REST_OLD => rHST.SROK_OST_O,                                       -- оставшийся срок полезного использования (бухгалтерская оценка) до
                  nA_TERM_USE_REST_NEW => rHST.SROKOST_NE,                                       -- оставшийся срок полезного использования (бухгалтерская оценка) после
                  nC_TERM_USE_REST_OLD => 0,                                                     -- оставшийся срок полезного использования (управленческая оценка) до
                  nC_TERM_USE_REST_NEW => 0,                                                     -- оставшийся срок полезного использования (управленческая оценка) после
                  nINVOBJCL_OLD        => null,                                                  -- класс инвентарного объекта до
                  nINVOBJCL_NEW        => null,                                                  -- класс инвентарного объекта после
                  nMOVE_TYPE           => nMOVE_TYPE,                                            -- подтип перемещения
                  nCONSERV_TYPE        => nCONSERV_TYPE,                                         -- подтип консервации/восстановления
                  nSTATE_REGIST        => 0,                                                     -- факт государственной регистрации
                  nASSETS_LIMIT        => 0,                                                     -- ограничения распоряжением активами
                  nTAXOBJTYPES_OLD     => null,                                                  -- вид объекта налогообложения до
                  nTAXOBJTYPES_NEW     => null,                                                  -- вид объекта налогообложения после
                  nAMORT_TYPE_OLD      => nAMORT_TYPE,                                           -- способ начисления амортизации до
                  nAMORT_TYPE_NEW      => nAMORT_TYPE,                                           -- способ начисления амортизации после
                  nTAX_GROUP_OLD       => null,                                                  -- амортизационная группа до
                  nTAX_GROUP_NEW       => null,                                                  -- амортизационная группа после
                  nTAX_SUBGROUP_OLD    => null,                                                  -- амортизационная подгруппа до
                  nTAX_SUBGROUP_NEW    => null,                                                  -- амортизационная подгруппа после
                  nOLD_A_GR_COST_END   => 0,                                                     -- остаточная стоимость по группе в валюте (бухгалтерская оценка) до
                  nNEW_A_GR_COST_END   => 0,                                                     -- остаточная стоимость по группе в валюте (бухгалтерская оценка) после
                  nOLD_AB_GR_COST_END  => 0,                                                     -- остаточная стоимость по группе в эквиваленте (бухгалтерская оценка) до
                  nNEW_AB_GR_COST_END  => 0,                                                     -- остаточная стоимость по группе в эквиваленте (бухгалтерская оценка) после
                  nOLD_C_GR_COST_END   => 0,                                                     -- остаточная стоимость по группе в валюте (управленческая оценка) до
                  nNEW_C_GR_COST_END   => 0,                                                     -- остаточная стоимость по группе в валюте (управленческая оценка) после
                  nOLD_CB_GR_COST_END  => 0,                                                     -- остаточная стоимость по группе в эквиваленте (управленческая оценка) до
                  nNEW_CB_GR_COST_END  => 0,                                                     -- остаточная стоимость по группе в эквиваленте (управленческая оценка) после
                  nA_GR_AMORT_DURING   => 0,                                                     -- начислено по группе в валюте (бухгалтерская оценка)
                  nAB_GR_AMORT_DURING  => 0,                                                     -- начислено по группе в эквиваленте (бухгалтерская оценка)
                  nC_GR_AMORT_DURING   => 0,                                                     -- начислено по группе в валюте (управленческая оценка)
                  nCB_GR_AMORT_DURING  => 0,                                                     -- начислено по группе в эквиваленте (управленческая оценка)
                  --
                  nRN                  => nHST_RN
                );
                PKG_IMPORT7.SET_REF( 'INSPEC', rHST.RN, nHST_RN );

                /* Связывание с ХО*/
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

                        /* Мастер - Мастер */
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

                        /* Детейл - Мастер*/
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
                            /* Мастер - Детейл */
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

                            /* Детейл - Детейл*/
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

    /* включаем триггеры INVENTORY */
    execute immediate 'alter table INVENTORY enable all triggers';
    execute immediate 'alter table INVHIST   enable all triggers';
  exception
    when OTHERS then
      rollback;
      /* включаем триггеры INVENTORY */
      execute immediate 'alter table INVENTORY enable all triggers';
      execute immediate 'alter table INVHIST   enable all triggers';
      raise;
  end;
end;
/
