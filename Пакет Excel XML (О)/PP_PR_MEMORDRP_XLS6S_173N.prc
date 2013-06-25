create or replace procedure PP_PR_MEMORDRP_XLS6S_173N
--
(nCOMPANY       in number, -- регистрационный номер организации
 nIDENT         in number, -- идентификатор процесса
 sMEMORDER      in varchar2, -- мнемокод мемориального ордера
 sPERIOD        in varchar2, -- наименование учетного периода
 sBALUNITS      in varchar2, -- ПБЕ
 sJUR_PERS      in varchar2, -- принадлежность
 sCURRENCY      in varchar2, -- валюта
 sECONCLASS     in varchar2, -- КЭКР
 sDIRRECIP      in varchar2, -- главный распорядитель
 sEXECUTOR      in varchar2, -- исполнитель
 sTRUSTOR       in varchar2, -- учредитель
 nANL_LEVEL     in number, -- уровень аналитики
 sEXCL_ACCOUNTS in varchar2, -- исключить из оборотов ГК операции по указанным счетам
 nSHOW_TOTAL    in number, -- показывать обороты по журналу операций
 nEXCL_MOVE     in number, -- исключить операции по внутреннему перемещению
 nSHOW_DEBIT    in number, -- показывать приходные операции
 nUSE_JUR       in number, -- формировать с учетом принадлежности
 nUSE_ANL       in number, -- формировать с учетом аналитики
 nUSE_JUR_TOTAL in number, -- учитывать принадлежность при формировании итоговых  оборотов
 nUSE_ANL_TOTAL in number, -- учитывать аналитику при формировании итоговых оборотов
 nSHOW_ACCS     in number, -- печатать номера счетов в заголовке отчета
 nSHOW_BALUNIT  in number -- печатать только групповые номера счетов в заголовке отчета
 ) as
  /* константы */
  -- заголовок
  --CELL_JURPERS  constant PKG_STD.tSTRING := 'Учреждение';
  --CELL_TRUSTOR constant PKG_STD.tSTRING := 'Учредитель';
  --CELL_BUDGET  constant PKG_STD.tSTRING := 'Бюджет';
  --CELL_ORGCODE  constant PKG_STD.tSTRING := 'ОКПО';
  --CELL_BALUNIT constant PKG_STD.tSTRING := 'Подразделение';
  --CELL_CURCODE constant PKG_STD.tSTRING := 'Валюта';

  -- подвал
  CELL_ACCOUNTANT constant PKG_STD.tSTRING := 'Бухгалтер';
  CELL_EXEC_OCC   constant PKG_STD.tSTRING := 'ИспДолж';
  CELL_EXEC_FIO   constant PKG_STD.tSTRING := 'ИспФИО';

  /* переменные */
  sCELL_MEMORDER    PKG_STD.tLSTRING;
  sCELL_ACCOUNTS    PKG_STD.tLSTRING;
  sCELL_PERIOD      PKG_STD.tSTRING;
  sCELL_DATE_RPT    PKG_STD.tSTRING;
  sCELL_JURPERS     AGNLIST.AGNNAME%type;
  sCELL_ORGCODE     AGNLIST.ORGCODE%type;
  sCELL_CURCODE     CURNAMES.INTCODE%type;
  sCELL_GH1_CONTENT PKG_STD.tSTRING;
  nGF1_TURN_SUM     PKG_STD.tSUMM;
  nGF2_TURN_SUM     PKG_STD.tSUMM;
  nGF5_TURN_SUM     PKG_STD.tSUMM;

  sCELL_GH2_DATE PKG_STD.tSTRING;

  nLN2_RMSUM_DB PKG_STD.tSUMM;
  nLN2_RMSUM_CR PKG_STD.tSUMM;
  nLN2_RSSUM_DB PKG_STD.tSUMM;
  nLN2_RSSUM_CR PKG_STD.tSUMM;

  nLN3_RMSUM_DB PKG_STD.tSUMM;
  nLN3_RMSUM_CR PKG_STD.tSUMM;
  nLN3_RSSUM_DB PKG_STD.tSUMM;
  nLN3_RSSUM_CR PKG_STD.tSUMM;

  -- значения групп
  VALUE_GH1  PKG_STD.tLNUMBER; -- NDATA_TYPE
  VALUE_GH2  PKG_STD.tSTRING; -- SACCOUNT
  VALUE_GH21 PKG_STD.tSTRING; -- SAGENT
  VALUE_GH3  PKG_STD.tNUMBER; -- NRECORD_TYPE
  VALUE_GH4  PKG_STD.tSTRING; -- SACCOUNT_DEBIT
  VALUE_GH5  PKG_STD.tSTRING; -- SACCOUNT_CREDIT

  bGH1_CHANGED  boolean;
  bGH2_CHANGED  boolean;
  bGH21_CHANGED boolean;
  bGH3_CHANGED  boolean;
  bGH4_CHANGED  boolean;
  bGH5_CHANGED  boolean;

  iGH1_IDX   integer;
  iGH2_IDX   integer;
  iLINE1_IDX integer;
  iLINE2_IDX integer;
  iLINE3_IDX integer;
  iGF5_IDX   integer;
  iGF1a_IDX  integer;
  iGF1b_IDX  integer;

  bGH1_IDX   integer;
  bGH2_IDX   integer;
  bLINE1_IDX integer;
  bLINE2_IDX integer;
  bLINE3_IDX integer;
  bFOOT5     integer;
  bFOOT1     integer;
  bGF5_IDX   integer;
  bGF1a_IDX  integer;
  bGF1b_IDX  integer;

  nIDENT1       PKG_STD.tREF;
  nRESULT       number(1);
  nPERIOD       PKG_STD.tREF;
  dDATE_END     PKG_STD.tLDATE;
  nJUR_PERS     PKG_STD.tREF;
  nAGENT        PKG_STD.tREF;
  sACCOUNTANT   AGNMANAGE.NOTE%type;
  nVERSION      PKG_STD.tREF;
  nNUMB         MEMORDER.NUMB%type;
  nREPORT_TYPE  PKG_STD.tNUMBER;
  sBALUNIT_NAME DICBUNTS.BUNIT_NAME%type;
  sACCOUNTS     PKG_STD.tLSTRING;
  sEXEC_OCC     PKG_STD.tSTRING;
  sEXEC_FIO     PKG_STD.tSTRING;
  sTRUSTOR_NAME AGNLIST.AGNNAME%type;
  sBUDGET_NAME  BUDGETS.NAME%type;
  sJUR_PERS_EX  JURPERSONS.CODE%type;

  sFileName varchar2(40);

  type tREC is record(
    nIDENT          PKG_STD.tREF,
    nDATA_TYPE      PKG_STD.tLNUMBER,
    nRECORD_TYPE    PKG_STD.tNUMBER,
    nAGENT_TYPE     PKG_STD.tNUMBER,
    nNUMB           PKG_STD.tNUMBER,
    sAGENT          PKG_STD.tSTRING,
    dOPER_DATE      PKG_STD.tLDATE,
    dFACT_DOCDATE   PKG_STD.tLDATE,
    sFACT_DOCTYPE   PKG_STD.tSTRING,
    sFACT_DOCNUMB   PKG_STD.tSTRING,
    sOPER_CONTENT   PKG_STD.tSTRING,
    sACCOUNT_DEBIT  PKG_STD.tSTRING,
    sACCOUNT_CREDIT PKG_STD.tSTRING,
    nTURN_SUM       PKG_STD.tSUMM,
    sACCOUNT        PKG_STD.tSTRING,
    nREMN_SUM       PKG_STD.tSUMM,
    nDEBIT_SUM      PKG_STD.tSUMM,
    nCREDIT_SUM     PKG_STD.tSUMM,
    sCOMMENT        PKG_STD.tSTRING,
    nIS_DEBIT       PKG_STD.tNUMBER);

  CUR_REC tREC;

  /* курсор */
  cursor C06 is
    select *
      from ( -- операции
            select nIDENT,
                    nDATA_TYPE,
                    nRECORD_TYPE,
                    0 nAGENT_TYPE,
                    nNUMB,
                    sAGENT,
                    dOPER_DATE,
                    dFACT_DOCDATE,
                    sFACT_DOCTYPE,
                    sFACT_DOCNUMB,
                    sOPER_CONTENT,
                    -- sACCOUNT_DEBIT
                    case
                      when sANALYTIC_DEBIT is not null and sJUR_PERS_CODE is not null then
                       sACCOUNT_DEBIT || '.' || sANALYTIC_DEBIT || ', ' || sJUR_PERS_CODE
                      when sANALYTIC_DEBIT is not null and sJUR_PERS_CODE is null then
                       sACCOUNT_DEBIT || '.' || sANALYTIC_DEBIT
                      when sANALYTIC_DEBIT is null and sJUR_PERS_CODE is not null then
                       sACCOUNT_DEBIT || ', ' || sJUR_PERS_CODE
                      else
                       sACCOUNT_DEBIT
                    end sACCOUNT_DEBIT,
                    --sACCOUNT_CREDIT
                    case
                      when sANALYTIC_CREDIT is not null and sJUR_PERS_CODE is not null then
                       sACCOUNT_CREDIT || '.' || sANALYTIC_CREDIT || ', ' || sJUR_PERS_CODE
                      when sANALYTIC_CREDIT is not null and sJUR_PERS_CODE is null then
                       sACCOUNT_CREDIT || '.' || sANALYTIC_CREDIT
                      when sANALYTIC_CREDIT is null and sJUR_PERS_CODE is not null then
                       sACCOUNT_CREDIT || ', ' || sJUR_PERS_CODE
                      else
                       sACCOUNT_CREDIT
                    end sACCOUNT_CREDIT,
                    nTURN_SUM,
                    sACCOUNT,
                    0 nREMN_SUM,
                    0 nDEBIT_SUM,
                    0 nCREDIT_SUM,
                    case
                      when nNUMB = 6 then
                       sAGENT
                      else
                       case
                      when nCURRENCY is not null then
                       'отражается в рублевом эквиваленте'
                    end end sCOMMENT,
                    nIS_DEBIT
              from ( -- V_MEMORDRP_REPORT2
                     select T.RN nRN,
                             T.IDENT nIDENT,
                             T.GROUP_IDENT nGROUP_IDENT,
                             T.DATA_TYPE nDATA_TYPE,
                             T.RECORD_TYPE nRECORD_TYPE,
                             T.NUMB nNUMB,
                             T.OPER_DATE dOPER_DATE,
                             T.FACT_DOCDATE dFACT_DOCDATE,
                             T.FACT_DOCTYPE nFACT_DOCTYPE,
                             DTF.DOCNAME sFACT_DOCTYPE,
                             T.FACT_DOCNUMB sFACT_DOCNUMB,
                             T.AGENT nAGENT,
                             AG.AGNABBR sAGENT,
                             T.OPER_CONTENT sOPER_CONTENT,
                             T.CURRENCY nCURRENCY,
                             C.INTCODE sCURRENCY,
                             case
                               when length(T.ACCOUNT_DEBIT) >= 26 then
                                substr(T.ACCOUNT_DEBIT, 1, 17) || ' ' || substr(T.ACCOUNT_DEBIT, 18, length(T.ACCOUNT_DEBIT) - 20) || ' ' || substr(T.ACCOUNT_DEBIT, -3)
                               else
                                T.ACCOUNT_DEBIT
                             end sACCOUNT_DEBIT,
                             case
                               when length(T.ACCOUNT_CREDIT) >= 26 then
                                substr(T.ACCOUNT_CREDIT, 1, 17) || ' ' || substr(T.ACCOUNT_CREDIT, 18, length(T.ACCOUNT_CREDIT) - 20) || ' ' || substr(T.ACCOUNT_CREDIT, -3)
                               else
                                T.ACCOUNT_CREDIT
                             end sACCOUNT_CREDIT,
                             case
                               when nUSE_ANL = 1 then
                                T.ANALYTIC_DEBIT
                               else
                                null
                             end sANALYTIC_DEBIT,
                             case
                               when nUSE_ANL = 1 then
                                T.ANALYTIC_CREDIT
                               else
                                null
                             end sANALYTIC_CREDIT,
                             T.TURN_SUM nTURN_SUM,
                             T.TURN_BASE_SUM nTURN_BASE_SUM,
                             case
                               when length(T.ACCOUNT) >= 26 then
                                substr(T.ACCOUNT, 1, 17) || ' ' || substr(T.ACCOUNT, 18, length(T.ACCOUNT) - 20) || ' ' || substr(T.ACCOUNT, -3)
                               else
                                T.ACCOUNT
                             end sACCOUNT,
                             case
                               when nUSE_JUR = 1 then
                                T.JUR_PERS
                               else
                                null
                             end sJUR_PERS_CODE,
                             T.REMN_SUM nREMN_SUM,
                             T.DEBIT_SUM nDEBIT_SUM,
                             T.CREDIT_SUM nCREDIT_SUM,
                             T.IS_DEBIT nIS_DEBIT
                       from MEMORDRP_REPORT2 T, DOCTYPES DTF, AGNLIST AG, CURNAMES C
                      where T.FACT_DOCTYPE = DTF.RN(+)
                        and T.AGENT = AG.RN(+)
                        and T.CURRENCY = C.RN(+)
                        and T.AUTHID = UTILIZER)
             where nDATA_TYPE = 0
               and nRECORD_TYPE = 0
               and nIDENT = nIDENT1
            --
            union all
            -- итоги по контрагентам
            select *
              from (select nIDENT,
                           nDATA_TYPE,
                           1 nRECORD_TYPE,
                           case
                             when sum(nDEBIT_SUM) = 0 and sum(nCREDIT_SUM) = 0 then
                              1
                             else
                              0
                           end nAGENT_TYPE,
                           nNUMB,
                           sAGENT,
                           null dOPER_DATE,
                           null dFACT_DOCDATE,
                           null sFACT_DOCTYPE,
                           null sFACT_DOCNUMB,
                           null sOPER_CONTENT,
                           null sACCOUNT_DEBIT,
                           null sACCOUNT_CREDIT,
                           0 nTURN_SUM,
                           sACCOUNT,
                           sum(nREMN_SUM) nREMN_SUM,
                           sum(nDEBIT_SUM) nDEBIT_SUM,
                           sum(nCREDIT_SUM) nCREDIT_SUM,
                           'Итого по ' || sAGENT sCOMMENT,
                           0
                      from ( -- V_MEMORDRP_REPORT2
                            select T.RN nRN,
                                    T.IDENT nIDENT,
                                    T.GROUP_IDENT nGROUP_IDENT,
                                    T.DATA_TYPE nDATA_TYPE,
                                    T.RECORD_TYPE nRECORD_TYPE,
                                    T.NUMB nNUMB,
                                    T.OPER_DATE dOPER_DATE,
                                    T.FACT_DOCDATE dFACT_DOCDATE,
                                    T.FACT_DOCTYPE nFACT_DOCTYPE,
                                    DTF.DOCNAME sFACT_DOCTYPE,
                                    T.FACT_DOCNUMB sFACT_DOCNUMB,
                                    T.AGENT nAGENT,
                                    AG.AGNABBR sAGENT,
                                    T.OPER_CONTENT sOPER_CONTENT,
                                    T.CURRENCY nCURRENCY,
                                    C.INTCODE sCURRENCY,
                                    T.ACCOUNT_DEBIT sACCOUNT_DEBIT,
                                    T.ACCOUNT_CREDIT sACCOUNT_CREDIT,
                                    T.TURN_SUM nTURN_SUM,
                                    T.TURN_BASE_SUM nTURN_BASE_SUM,
                                    case
                                      when length(T.ACCOUNT) >= 26 then
                                       substr(T.ACCOUNT, 1, 17) || ' ' || substr(T.ACCOUNT, 18, length(T.ACCOUNT) - 20) || ' ' || substr(T.ACCOUNT, -3)
                                      else
                                       T.ACCOUNT
                                    end sACCOUNT,
                                    T.REMN_SUM nREMN_SUM,
                                    T.DEBIT_SUM nDEBIT_SUM,
                                    T.CREDIT_SUM nCREDIT_SUM,
                                    T.IS_DEBIT nIS_DEBIT
                              from MEMORDRP_REPORT2 T, DOCTYPES DTF, AGNLIST AG, CURNAMES C
                             where T.FACT_DOCTYPE = DTF.RN(+)
                               and T.AGENT = AG.RN(+)
                               and T.CURRENCY = C.RN(+)
                               and T.AUTHID = UTILIZER)
                     where nDATA_TYPE = 0
                       and nRECORD_TYPE in (1, 2)
                       and nIS_DEBIT = 0
                       and nIDENT = nIDENT1
                       and sAGENT is not null
                     group by nIDENT, nNUMB, nDATA_TYPE, sACCOUNT, sAGENT)
             where nRECORD_TYPE = 1
            --
            union all
            -- итоги по счетам
            select *
              from (select nIDENT,
                           nDATA_TYPE,
                           3 nRECORD_TYPE,
                           1 nAGENT_TYPE,
                           nNUMB,
                           null sAGENT,
                           null dOPER_DATE,
                           null dFACT_DOCDATE,
                           null sFACT_DOCTYPE,
                           null sFACT_DOCNUMB,
                           null sOPER_CONTENT,
                           null sACCOUNT_DEBIT,
                           null sACCOUNT_CREDIT,
                           0 nTURN_SUM,
                           sACCOUNT,
                           nvl(sum(sum(nREMN_SUM)) over(PARTITION BY nIDENT, nDATA_TYPE, sACCOUNT), 0) nREMN_SUM,
                           sum(nDEBIT_SUM) nDEBIT_SUM,
                           sum(nCREDIT_SUM) nCREDIT_SUM,
                           'Всего по счету' sCOMMENT,
                           0
                      from ( -- V_MEMORDRP_REPORT2
                            select T.RN nRN,
                                    T.IDENT nIDENT,
                                    T.GROUP_IDENT nGROUP_IDENT,
                                    T.DATA_TYPE nDATA_TYPE,
                                    T.RECORD_TYPE nRECORD_TYPE,
                                    T.NUMB nNUMB,
                                    T.OPER_DATE dOPER_DATE,
                                    T.FACT_DOCDATE dFACT_DOCDATE,
                                    T.FACT_DOCTYPE nFACT_DOCTYPE,
                                    DTF.DOCNAME sFACT_DOCTYPE,
                                    T.FACT_DOCNUMB sFACT_DOCNUMB,
                                    T.AGENT nAGENT,
                                    AG.AGNABBR sAGENT,
                                    T.OPER_CONTENT sOPER_CONTENT,
                                    T.CURRENCY nCURRENCY,
                                    C.INTCODE sCURRENCY,
                                    T.ACCOUNT_DEBIT sACCOUNT_DEBIT,
                                    T.ACCOUNT_CREDIT sACCOUNT_CREDIT,
                                    T.TURN_SUM nTURN_SUM,
                                    T.TURN_BASE_SUM nTURN_BASE_SUM,
                                    case
                                      when length(T.ACCOUNT) >= 26 then
                                       substr(T.ACCOUNT, 1, 17) || ' ' || substr(T.ACCOUNT, 18, length(T.ACCOUNT) - 20) || ' ' || substr(T.ACCOUNT, -3)
                                      else
                                       T.ACCOUNT
                                    end sACCOUNT,
                                    T.REMN_SUM nREMN_SUM,
                                    T.DEBIT_SUM nDEBIT_SUM,
                                    T.CREDIT_SUM nCREDIT_SUM,
                                    T.IS_DEBIT nIS_DEBIT
                              from MEMORDRP_REPORT2 T, DOCTYPES DTF, AGNLIST AG, CURNAMES C
                             where T.FACT_DOCTYPE = DTF.RN(+)
                               and T.AGENT = AG.RN(+)
                               and T.CURRENCY = C.RN(+)
                               and T.AUTHID = UTILIZER)
                     where nDATA_TYPE = 0
                       and nRECORD_TYPE in (1, 2)
                       and nIS_DEBIT = 0
                       and nIDENT = nIDENT1
                     group by nIDENT, nNUMB, nDATA_TYPE, sACCOUNT)
             where nRECORD_TYPE = 3
            --
            union all
            -- Обороты по журналу операций
            select nIDENT,
                   0.5 nDATA_TYPE,
                   nRECORD_TYPE,
                   0 nAGENT_TYPE,
                   nNUMB,
                   null sAGENT,
                   null dOPER_DATE,
                   null dFACT_DOCDATE,
                   null sFACT_DOCTYPE,
                   null sFACT_DOCNUMB,
                   null sOPER_CONTENT,
                   -- sACCOUNT_DEBIT
                   case
                     when sANALYTIC_DEBIT is not null and sJUR_PERS_CODE is not null then
                      sACCOUNT_DEBIT || '.' || sANALYTIC_DEBIT || ', ' || sJUR_PERS_CODE
                     when sANALYTIC_DEBIT is not null and sJUR_PERS_CODE is null then
                      sACCOUNT_DEBIT || '.' || sANALYTIC_DEBIT
                     when sANALYTIC_DEBIT is null and sJUR_PERS_CODE is not null then
                      sACCOUNT_DEBIT || ', ' || sJUR_PERS_CODE
                     else
                      sACCOUNT_DEBIT
                   end sACCOUNT_DEBIT,
                   --sACCOUNT_CREDIT
                   case
                     when sANALYTIC_CREDIT is not null and sJUR_PERS_CODE is not null then
                      sACCOUNT_CREDIT || '.' || sANALYTIC_CREDIT || ', ' || sJUR_PERS_CODE
                     when sANALYTIC_CREDIT is not null and sJUR_PERS_CODE is null then
                      sACCOUNT_CREDIT || '.' || sANALYTIC_CREDIT
                     when sANALYTIC_CREDIT is null and sJUR_PERS_CODE is not null then
                      sACCOUNT_CREDIT || ', ' || sJUR_PERS_CODE
                     else
                      sACCOUNT_CREDIT
                   end sACCOUNT_CREDIT,
                   nTURN_SUM,
                   sACCOUNT,
                   0 nREMN_SUM,
                   0 nDEBIT_SUM,
                   0 nCREDIT_SUM,
                   null sCOMMENT,
                   0
              from ( -- V_MEMORDRP_REPORT2
                    select T.RN nRN,
                            T.IDENT nIDENT,
                            T.GROUP_IDENT nGROUP_IDENT,
                            T.DATA_TYPE nDATA_TYPE,
                            T.RECORD_TYPE nRECORD_TYPE,
                            T.NUMB nNUMB,
                            T.OPER_DATE dOPER_DATE,
                            T.FACT_DOCDATE dFACT_DOCDATE,
                            T.FACT_DOCTYPE nFACT_DOCTYPE,
                            DTF.DOCNAME sFACT_DOCTYPE,
                            T.FACT_DOCNUMB sFACT_DOCNUMB,
                            T.AGENT nAGENT,
                            AG.AGNABBR sAGENT,
                            T.OPER_CONTENT sOPER_CONTENT,
                            T.CURRENCY nCURRENCY,
                            C.INTCODE sCURRENCY,
                            case
                              when length(T.ACCOUNT_DEBIT) >= 26 then
                               substr(T.ACCOUNT_DEBIT, 1, 17) || ' ' || substr(T.ACCOUNT_DEBIT, 18, length(T.ACCOUNT_DEBIT) - 20) || ' ' || substr(T.ACCOUNT_DEBIT, -3)
                              else
                               T.ACCOUNT_DEBIT
                            end sACCOUNT_DEBIT,
                            case
                              when length(T.ACCOUNT_CREDIT) >= 26 then
                               substr(T.ACCOUNT_CREDIT, 1, 17) || ' ' || substr(T.ACCOUNT_CREDIT, 18, length(T.ACCOUNT_CREDIT) - 20) || ' ' || substr(T.ACCOUNT_CREDIT, -3)
                              else
                               T.ACCOUNT_CREDIT
                            end sACCOUNT_CREDIT,
                            case
                              when nUSE_ANL_TOTAL = 1 then
                               T.ANALYTIC_DEBIT
                              else
                               null
                            end sANALYTIC_DEBIT,
                            case
                              when nUSE_ANL_TOTAL = 1 then
                               T.ANALYTIC_CREDIT
                              else
                               null
                            end sANALYTIC_CREDIT,
                            T.TURN_SUM nTURN_SUM,
                            T.TURN_BASE_SUM nTURN_BASE_SUM,
                            case
                              when length(T.ACCOUNT) >= 26 then
                               substr(T.ACCOUNT, 1, 17) || ' ' || substr(T.ACCOUNT, 18, length(T.ACCOUNT) - 20) || ' ' || substr(T.ACCOUNT, -3)
                              else
                               T.ACCOUNT
                            end sACCOUNT,
                            case
                              when nUSE_JUR_TOTAL = 1 then
                               T.JUR_PERS
                              else
                               null
                            end sJUR_PERS_CODE,
                            T.REMN_SUM nREMN_SUM,
                            T.DEBIT_SUM nDEBIT_SUM,
                            T.CREDIT_SUM nCREDIT_SUM,
                            T.IS_DEBIT nIS_DEBIT
                      from MEMORDRP_REPORT2 T, DOCTYPES DTF, AGNLIST AG, CURNAMES C
                     where T.FACT_DOCTYPE = DTF.RN(+)
                       and T.AGENT = AG.RN(+)
                       and T.CURRENCY = C.RN(+)
                       and T.AUTHID = UTILIZER)
             where nDATA_TYPE = 2
               and nRECORD_TYPE = 0
               and nIDENT = nIDENT1
            --
            union all
            -- Обороты в главную книгу
            select nIDENT,
                   nDATA_TYPE,
                   nRECORD_TYPE,
                   0 nAGENT_TYPE,
                   nNUMB,
                   null sAGENT,
                   null dOPER_DATE,
                   null dFACT_DOCDATE,
                   null sFACT_DOCTYPE,
                   null sFACT_DOCNUMB,
                   null sOPER_CONTENT,
                   -- sACCOUNT_DEBIT
                   case
                     when sANALYTIC_DEBIT is not null and sJUR_PERS_CODE is not null then
                      sACCOUNT_DEBIT || '.' || sANALYTIC_DEBIT || ', ' || sJUR_PERS_CODE
                     when sANALYTIC_DEBIT is not null and sJUR_PERS_CODE is null then
                      sACCOUNT_DEBIT || '.' || sANALYTIC_DEBIT
                     when sANALYTIC_DEBIT is null and sJUR_PERS_CODE is not null then
                      sACCOUNT_DEBIT || ', ' || sJUR_PERS_CODE
                     else
                      sACCOUNT_DEBIT
                   end sACCOUNT_DEBIT,
                   --sACCOUNT_CREDIT
                   case
                     when sANALYTIC_CREDIT is not null and sJUR_PERS_CODE is not null then
                      sACCOUNT_CREDIT || '.' || sANALYTIC_CREDIT || ', ' || sJUR_PERS_CODE
                     when sANALYTIC_CREDIT is not null and sJUR_PERS_CODE is null then
                      sACCOUNT_CREDIT || '.' || sANALYTIC_CREDIT
                     when sANALYTIC_CREDIT is null and sJUR_PERS_CODE is not null then
                      sACCOUNT_CREDIT || ', ' || sJUR_PERS_CODE
                     else
                      sACCOUNT_CREDIT
                   end sACCOUNT_CREDIT,
                   nTURN_SUM,
                   sACCOUNT,
                   0 nREMN_SUM,
                   0 nDEBIT_SUM,
                   0 nCREDIT_SUM,
                   null sCOMMENT,
                   0
              from ( -- V_MEMORDRP_REPORT2
                    select T.RN nRN,
                            T.IDENT nIDENT,
                            T.GROUP_IDENT nGROUP_IDENT,
                            T.DATA_TYPE nDATA_TYPE,
                            T.RECORD_TYPE nRECORD_TYPE,
                            T.NUMB nNUMB,
                            T.OPER_DATE dOPER_DATE,
                            T.FACT_DOCDATE dFACT_DOCDATE,
                            T.FACT_DOCTYPE nFACT_DOCTYPE,
                            DTF.DOCNAME sFACT_DOCTYPE,
                            T.FACT_DOCNUMB sFACT_DOCNUMB,
                            T.AGENT nAGENT,
                            AG.AGNABBR sAGENT,
                            T.OPER_CONTENT sOPER_CONTENT,
                            T.CURRENCY nCURRENCY,
                            C.INTCODE sCURRENCY,
                            case
                              when length(T.ACCOUNT_DEBIT) >= 26 then
                               substr(T.ACCOUNT_DEBIT, 1, 17) || ' ' || substr(T.ACCOUNT_DEBIT, 18, length(T.ACCOUNT_DEBIT) - 20) || ' ' || substr(T.ACCOUNT_DEBIT, -3)
                              else
                               T.ACCOUNT_DEBIT
                            end sACCOUNT_DEBIT,
                            case
                              when length(T.ACCOUNT_CREDIT) >= 26 then
                               substr(T.ACCOUNT_CREDIT, 1, 17) || ' ' || substr(T.ACCOUNT_CREDIT, 18, length(T.ACCOUNT_CREDIT) - 20) || ' ' || substr(T.ACCOUNT_CREDIT, -3)
                              else
                               T.ACCOUNT_CREDIT
                            end sACCOUNT_CREDIT,
                            case
                              when nUSE_ANL_TOTAL = 1 then
                               T.ANALYTIC_DEBIT
                              else
                               null
                            end sANALYTIC_DEBIT,
                            case
                              when nUSE_ANL_TOTAL = 1 then
                               T.ANALYTIC_CREDIT
                              else
                               null
                            end sANALYTIC_CREDIT,
                            T.TURN_SUM nTURN_SUM,
                            T.TURN_BASE_SUM nTURN_BASE_SUM,
                            case
                              when length(T.ACCOUNT) >= 26 then
                               substr(T.ACCOUNT, 1, 17) || ' ' || substr(T.ACCOUNT, 18, length(T.ACCOUNT) - 20) || ' ' || substr(T.ACCOUNT, -3)
                              else
                               T.ACCOUNT
                            end sACCOUNT,
                            case
                              when nUSE_JUR_TOTAL = 1 then
                               T.JUR_PERS
                              else
                               null
                            end sJUR_PERS_CODE,
                            T.REMN_SUM nREMN_SUM,
                            T.DEBIT_SUM nDEBIT_SUM,
                            T.CREDIT_SUM nCREDIT_SUM,
                            T.IS_DEBIT nIS_DEBIT
                      from MEMORDRP_REPORT2 T, DOCTYPES DTF, AGNLIST AG, CURNAMES C
                     where T.FACT_DOCTYPE = DTF.RN(+)
                       and T.AGENT = AG.RN(+)
                       and T.CURRENCY = C.RN(+)
                       and T.AUTHID = UTILIZER)
             where nDATA_TYPE = 1
               and nRECORD_TYPE = 0
               and nIDENT = nIDENT1) C
     order by C.nIDENT, C.nDATA_TYPE, C.sACCOUNT, C.nAGENT_TYPE, C.sAGENT, C.nRECORD_TYPE, C.dFACT_DOCDATE, C.sACCOUNT_DEBIT, C.sACCOUNT_CREDIT;

  /* Итоги 6 */
  procedure MAKE_GR5_FOOTER(nOLD_DATA_TYPE in number, nOLD_RECORD_TYPE in number, sOLD_ACCOUNT_DEBIT in varchar2, sOLD_ACCOUNT_CREDIT in varchar2) as
  begin
    if ((CMP_NUM(nOLD_DATA_TYPE, 1) = 1 or (CMP_NUM(nOLD_DATA_TYPE, 0.5) = 1 and nSHOW_TOTAL = 1)) and CMP_NUM(nOLD_RECORD_TYPE, 0) = 1) then
    
      bGH1_IDX   := 0;
      bGH2_IDX   := 0;
      bLINE1_IDX := 0;
      bLINE2_IDX := 0;
      bLINE3_IDX := 0;
      bGF5_IDX   := 1;
      bGF1a_IDX  := 0;
      bGF1b_IDX  := 0;
    
      PKGP_EXCEL_XML.AddLine;
      PKGP_EXCEL_XML.AddCell('', 'GF5', 'ss:MergeAcross="4"');
      PKGP_EXCEL_XML.AddCell('', 'GF5', 'ss:MergeAcross="2"');
      PKGP_EXCEL_XML.AddCell(sOLD_ACCOUNT_DEBIT, 'GF5');
      PKGP_EXCEL_XML.AddCell(sOLD_ACCOUNT_CREDIT, 'GF5');
      PKGP_EXCEL_XML.AddCell(nGF5_TURN_SUM, 'GF5');
      PKGP_EXCEL_XML.AddCell('', 'GF5', 'ss:MergeAcross="1"');
      PKGP_EXCEL_XML.CloseLine;
    
      nGF5_TURN_SUM := 0;
    end if;
    bFOOT5 := 0;
  end; -- MAKE_GR5_FOOTER

  procedure MAKE_GR1_FOOTER(nOLD_DATA_TYPE in number) as
  begin
    /* Итоги 1 */
    if (CMP_NUM(nOLD_DATA_TYPE, 0) = 1) then
    
      bGH1_IDX   := 0;
      bGH2_IDX   := 0;
      bLINE1_IDX := 0;
      bLINE2_IDX := 0;
      bLINE3_IDX := 0;
      bGF5_IDX   := 0;
      bGF1a_IDX  := 1;
      bGF1b_IDX  := 0;
    
      PKGP_EXCEL_XML.AddLine;
      PKGP_EXCEL_XML.AddCell('', 'GF1a', 'ss:MergeAcross="4"');
      PKGP_EXCEL_XML.AddCell('Итого:', 'GF1a', 'ss:MergeAcross="2"');
      PKGP_EXCEL_XML.AddCell('x', 'GF1a');
      PKGP_EXCEL_XML.AddCell('x', 'GF1a');
      PKGP_EXCEL_XML.AddCell(nGF1_TURN_SUM, 'GF1a');
      PKGP_EXCEL_XML.AddCell('', 'GF1a');
      PKGP_EXCEL_XML.AddCell('', 'GF1a');
      PKGP_EXCEL_XML.CloseLine;
    
      nGF1_TURN_SUM := 0;
    end if; -- Итоги1
  
    /* Итоги 2 */
    if (CMP_NUM(nOLD_DATA_TYPE, 1) = 1 or (CMP_NUM(nOLD_DATA_TYPE, 0.5) = 1 and nSHOW_TOTAL = 1)) then
    
      bGH1_IDX   := 0;
      bGH2_IDX   := 0;
      bLINE1_IDX := 0;
      bLINE2_IDX := 0;
      bLINE3_IDX := 0;
      bGF5_IDX   := 0;
      bGF1a_IDX  := 0;
      bGF1b_IDX  := 1;
    
      PKGP_EXCEL_XML.AddLine;
      PKGP_EXCEL_XML.AddCell('', 'GF1b', 'ss:MergeAcross="4"');
      PKGP_EXCEL_XML.AddCell('Итого:', 'GF1b', 'ss:MergeAcross="2"');
      PKGP_EXCEL_XML.AddCell('x', 'GF1b');
      PKGP_EXCEL_XML.AddCell('x', 'GF1b');
      PKGP_EXCEL_XML.AddCell(nGF2_TURN_SUM, 'GF1b');
      PKGP_EXCEL_XML.AddCell('', 'GF1b');
      PKGP_EXCEL_XML.AddCell('', 'GF1b');
      PKGP_EXCEL_XML.CloseLine;
    
      nGF2_TURN_SUM := 0;
    end if; -- Итоги2
    bFOOT1 := 0;
  end; -- MAKE_GR1_FOOTER

  /* должность и ФИО */
  procedure GET_AGENT(sCODE in varchar2, sOCCUP out varchar2, sFIO out varchar2) as
    nAGENT         PKG_STD.tREF;
    sAGNFAMILYNAME AGNLIST.AGNFAMILYNAME%type;
    sAGNFIRSTNAME  AGNLIST.AGNFIRSTNAME%type;
    sAGNLASTNAME   AGNLIST.AGNLASTNAME%type;
  begin
    FIND_AGNLIST_CODE(0, 1, nCOMPANY, sCODE, nAGENT);
  
    if (nAGENT is not null) then
      select EMPPOST, trim(AGNFAMILYNAME), trim(AGNFIRSTNAME), trim(AGNLASTNAME) into sOCCUP, sAGNFAMILYNAME, sAGNFIRSTNAME, sAGNLASTNAME from AGNLIST where RN = nAGENT;
    
      /* ФИО */
      sFIO := sAGNFAMILYNAME || ' ';
      if (sAGNFIRSTNAME is not null) then
        sFIO := sFIO || substr(sAGNFIRSTNAME, 1, 1) || '.';
      end if;
      if (sAGNLASTNAME is not null) then
        sFIO := sFIO || substr(sAGNLASTNAME, 1, 1) || '.';
      end if;
      sFIO := trim(sFIO);
    end if;
  end GET_AGENT;

  procedure XML_INIT
  --
  (sFileName in varchar2) is
  begin
    PKGP_EXCEL_XML.Init(sFileName);
    PKGP_EXCEL_XML.AddStyles;
    -- Спецификация:
    PKGP_EXCEL_XML.AddStyleBorder('LINE1');
    PKGP_EXCEL_XML.AddStyle_Font_Size('LINE1', '6');
    PKGP_EXCEL_XML.AddStyle_Alignment_Wrap('LINE1');
    -- Спецификация:
    PKGP_EXCEL_XML.AddStyleBorder('LINE2');
    PKGP_EXCEL_XML.AddStyle_Font_Size('LINE2', '6');
    PKGP_EXCEL_XML.AddStyle_Alignment_Wrap('LINE2');
    -- Спецификация:
    PKGP_EXCEL_XML.AddStyleBorder('LINE3');
    PKGP_EXCEL_XML.AddStyle_Font_Size('LINE3', '6');
    PKGP_EXCEL_XML.AddStyle_Alignment_Wrap('LINE3');
    -- Ячейка заголовка:
    PKGP_EXCEL_XML.AddStyle_Font_Size('zagd', '12');
    PKGP_EXCEL_XML.AddStyle_Font_Bold('zagd');
    PKGP_EXCEL_XML.AddStyle_Alignment_Horizontal('zagd', 'Center');
    -- GH1
    PKGP_EXCEL_XML.AddStyle_Font_Size('GH1', '6');
    PKGP_EXCEL_XML.AddStyle_Font_Bold('GH1');
    PKGP_EXCEL_XML.AddStyleBorder('GH1');
    -- GH2
    PKGP_EXCEL_XML.AddStyle_Font_Size('GH2', '6');
    PKGP_EXCEL_XML.AddStyleBorder('GH2');
    -- GF1a
    PKGP_EXCEL_XML.AddStyle_Font_Size('GF1a', '6');
    PKGP_EXCEL_XML.AddStyleBorder('GF1a');
    PKGP_EXCEL_XML.AddStyle_Alignment_Wrap('GF1a');
    -- GF1b
    PKGP_EXCEL_XML.AddStyle_Font_Size('GF1b', '6');
    PKGP_EXCEL_XML.AddStyleBorder('GF1b');
    PKGP_EXCEL_XML.AddStyle_Alignment_Wrap('GF1b');
    -- GF5
    PKGP_EXCEL_XML.AddStyle_Font_Size('GF5', '6');
    PKGP_EXCEL_XML.AddStyleBorder('GF5');
    -- Правая часть шапки:
    PKGP_EXCEL_XML.AddStyleBorder('HEADR');
    PKGP_EXCEL_XML.AddStyle_Font_Size('HEADR', '10');
    PKGP_EXCEL_XML.AddStyle_Alignment_Horizontal('HEADR', 'Center');
    -- Правая часть шапки, текст:
    PKGP_EXCEL_XML.AddStyle_Font_Size('HEADRT', '10');
    PKGP_EXCEL_XML.AddStyle_Alignment_Horizontal('HEADRT', 'Right');
    -- Заголовок, текст:
    PKGP_EXCEL_XML.AddStyle_Font_Size('HEADT', '10');
    -- Заголовок, текст - даннве:
    PKGP_EXCEL_XML.AddStyle_Font_Size('HEADTL', '10');
    PKGP_EXCEL_XML.AddStyleBor('HEADTL', 'Bottom');
    -- Колонки шапки:
    PKGP_EXCEL_XML.AddStyleBorder('HEADC');
    PKGP_EXCEL_XML.AddStyle_Font_Size('HEADC', '6');
    PKGP_EXCEL_XML.AddStyle_Alignment_Horizontal('HEADC', 'Center');
    -- Подвал, подписи
    PKGP_EXCEL_XML.AddStyle_Font_Size('FOOT', '6');
    PKGP_EXCEL_XML.AddStyle_Alignment_Horizontal('FOOT', 'Center');
    -- Подвал, надписи
    PKGP_EXCEL_XML.AddStyle_Font_Size('FOOTL', '10');
    PKGP_EXCEL_XML.AddStyle_Alignment_Horizontal('FOOTL', 'Center');
    PKGP_EXCEL_XML.AddStyleBor('FOOTL', 'Bottom');
  
    PKGP_EXCEL_XML.CloseStyles;
    PKGP_EXCEL_XML.AddWorkSheet('ЖО');
    PKGP_EXCEL_XML.AddNamedRange('Print_Titles', '=ЖО!R12:R14');
    PKGP_EXCEL_XML.AddTable;
  
  end;

  procedure XML_FINI is
  begin
    PKGP_EXCEL_XML.CloseTable;
    PKGP_EXCEL_XML.AddWorksheetOptions;
    PKGP_EXCEL_XML.AddPageSetup;
    PKGP_EXCEL_XML.AddLayout('Landscape');
    PKGP_EXCEL_XML.PageHeader(0.5, 'Форма 0504071' || PKGP_EXCEL_XML.sCOLONTITULNEWLINE || 'стр. ' || PKGP_EXCEL_XML.sCOLONTITULPAGENUM);
    PKGP_EXCEL_XML.PageFooter(0.5);
    PKGP_EXCEL_XML.PageMargins(0.5, 0.8, 0.5, 1.5);
    PKGP_EXCEL_XML.ClosePageSetup;
    PKGP_EXCEL_XML.SetFitToPage;
    PKGP_EXCEL_XML.AddPrint;
    PKGP_EXCEL_XML.AddPrintFitHeight(12000);
    PKGP_EXCEL_XML.ClosePrint;
    PKGP_EXCEL_XML.CloseWorksheetOptions;
    PKGP_EXCEL_XML.CloseWorkSheet;
    PKGP_EXCEL_XML.Fini;
  
    prsg_excel.PREPARE;
    prsg_excel.SHEET_SELECT('Лист1');
    prsg_excel.CELL_DESCRIBE('Отчет');
    prsg_excel.CELL_VALUE_WRITE('Отчет', '\\server-parus\userdata\' || sFileName || '.xml');
  
  end;

begin
  nRESULT := 0;
  nIDENT1 := nIDENT;

  /* проверка уровня аналитики */
  if (nANL_LEVEL < 0) or (nANL_LEVEL > 5) then
    P_EXCEPTION(0, 'Недопустимое значение признака "Уровень аналитики".');
  end if;

  /* проверка признака оборотов */
  if (nSHOW_TOTAL < 0) or (nSHOW_TOTAL > 1) then
    P_EXCEPTION(0, 'Недопустимое значение признака "Показывать обороты по журналу операций".');
  end if;

  /* юридическое лицо */
  if (rtrim(sJUR_PERS) is not null) then
    FIND_JURPERSONS_CODE(0, 0, nCOMPANY, sJUR_PERS, nJUR_PERS);
  
    /* учреждение */
    begin
      select A.RN, AGNNAME, A.ORGCODE
        into nAGENT, sCELL_JURPERS, sCELL_ORGCODE
        from JURPERSONS J, AGNLIST A
       where J.AGENT = A.RN
         and J.RN = nJUR_PERS;
    exception
      when NO_DATA_FOUND then
        PKG_MSG.RECORD_NOT_FOUND(nJUR_PERS, 'JuridicalPersons');
    end;
  
    /* поиск уч.периода */
    FIND_APERIODS_BY_NAME(nCOMPANY, sPERIOD, nPERIOD);
  
    /* определение границ периода */
    select PERIOD_END into dDATE_END from APERIODS where RN = nPERIOD;
  
    /* гл. бухгалтер */
    begin
      select NOTE
        into sACCOUNTANT
        from AGNMANAGE
       where PRN = nAGENT
         and REG_DATE = (select max(REG_DATE)
                           from AGNMANAGE
                          where PRN = nAGENT
                            and REG_DATE <= dDATE_END
                            and POSITION = 0)
         and POSITION = 0;
    exception
      when NO_DATA_FOUND then
        sACCOUNTANT := null;
    end;
  else
    FIND_JURPERSONS_MAIN(1, nCOMPANY, sJUR_PERS_EX, nJUR_PERS);
  end if;

  if nJUR_PERS is not null then
    /* бюджет */
    /* определение версии */
    FIND_VERSION_BY_COMPANY(nCOMPANY, 'BudgetRecipients', nVERSION);
  
    begin
      select BG.NAME
        into sBUDGET_NAME
        from JURPERSONS JP, BUDGRECIP BR, BUDGETS BG
       where JP.RN = nJUR_PERS
         and BR.AGENT = JP.AGENT
         and BR.VERSION = nVERSION
         and BR.BUDGET = BG.RN;
    exception
      when NO_DATA_FOUND then
        sBUDGET_NAME := null;
    end;
  end if;

  /* исполнитель */
  GET_AGENT(sEXECUTOR, sEXEC_OCC, sEXEC_FIO);

  /* валюта */
  sCELL_CURCODE := F_CURRENCY_GET_ISO(F_CURBASE_GET_RN(0, nCOMPANY));

  if (rtrim(sMEMORDER) is null) then
    P_EXCEPTION(0, 'Журнал операций не задан.');
  end if;

  /* определение версии мемориальных ордеров */
  FIND_VERSION_BY_COMPANY(nCOMPANY, 'MemorialOrders', nVERSION);

  /* считывание ордера */
  begin
    select NUMB
      into nNUMB
      from MEMORDER
     where CODE = sMEMORDER
       and VERSION = nVERSION;
  exception
    when NO_DATA_FOUND then
      P_EXCEPTION(0, 'Мемориальный ордер "' || nvl(sMEMORDER, '<null>') || '" не определен.');
  end;

  /* вычисление типа отчета */
  if (nNUMB = 6) then
    nREPORT_TYPE := 68;
  else
    P_EXCEPTION(0, 'Для формирования отчета выбран неподходящий мемориальный ордер.');
  end if;

  dbms_application_info.set_action('Формирую');

  /* заполнение временной таблицы */
  P_MEMORDRP_BASE_CREATE_173N(nCOMPANY,
                              nIDENT,
                              nIDENT,
                              nREPORT_TYPE,
                              sMEMORDER,
                              sPERIOD,
                              sDIRRECIP,
                              sJUR_PERS,
                              sBALUNITS,
                              sCURRENCY,
                              sECONCLASS,
                              sEXCL_ACCOUNTS,
                              nANL_LEVEL,
                              nEXCL_MOVE,
                              nSHOW_DEBIT,
                              nUSE_JUR,
                              nUSE_ANL,
                              nUSE_JUR_TOTAL,
                              nUSE_ANL_TOTAL,
                              nSHOW_ACCS,
                              nSHOW_BALUNIT,
                              sTRUSTOR,
                              nRESULT,
                              sBALUNIT_NAME,
                              sACCOUNTS,
                              sTRUSTOR_NAME);

  if (nRESULT = 1) then
  
    sFileName := 'ЖО_' || to_char(sysdate, 'hhiiss') || '_' || substr(dbms_random.value, 3, 3);
    XML_INIT(sFileName);
  
    sCELL_MEMORDER := 'Журнал операций № ' || sMEMORDER;
    if sACCOUNTS is not null then
      sCELL_ACCOUNTS := 'по счету ' || sACCOUNTS;
    end if;
    sCELL_PERIOD   := 'за ' || sPERIOD || ' года';
    sCELL_DATE_RPT := to_char(SYSDATE, 'DD.MM.YYYY');
  
    PKGP_EXCEL_XML.AddColumn('38');
    PKGP_EXCEL_XML.AddColumn('38');
    PKGP_EXCEL_XML.AddColumn('38');
    PKGP_EXCEL_XML.AddColumn('67');
    PKGP_EXCEL_XML.AddColumn('75');
    PKGP_EXCEL_XML.AddColumn('102');
    PKGP_EXCEL_XML.AddColumn('60');
    PKGP_EXCEL_XML.AddColumn('60');
    PKGP_EXCEL_XML.AddColumn('75');
    PKGP_EXCEL_XML.AddColumn('75');
    PKGP_EXCEL_XML.AddColumn('67');
    PKGP_EXCEL_XML.AddColumn('60');
    PKGP_EXCEL_XML.AddColumn('60');
  
    PKGP_EXCEL_XML.AddLine; -- Строка 1
    PKGP_EXCEL_XML.AddCell(sCELL_MEMORDER, 'zagd', 'ss:MergeAcross="12"');
    PKGP_EXCEL_XML.CloseLine;
    PKGP_EXCEL_XML.AddLine; -- Строка 2
    PKGP_EXCEL_XML.AddCell(sCELL_ACCOUNTS, 'zagd', 'ss:MergeAcross="12"');
    PKGP_EXCEL_XML.CloseLine;
    PKGP_EXCEL_XML.AddLine; -- Строка 3
    PKGP_EXCEL_XML.AddCell('', 'HEADRT', 'ss:MergeAcross="11"');
    PKGP_EXCEL_XML.AddCell('КОДЫ', 'HEADR');
    PKGP_EXCEL_XML.CloseLine;
    PKGP_EXCEL_XML.AddLine; -- Строка 4
    PKGP_EXCEL_XML.AddCell(sCELL_PERIOD, 'zagd', 'ss:MergeAcross="9"');
    PKGP_EXCEL_XML.AddCell('Форма по ОКУД', 'HEADRT', 'ss:MergeAcross="1"');
    PKGP_EXCEL_XML.AddCell('0504071', 'HEADR');
    PKGP_EXCEL_XML.CloseLine;
    PKGP_EXCEL_XML.AddLine; -- Строка 5
    PKGP_EXCEL_XML.AddCell('Дата', 'HEADRT', 'ss:MergeAcross="11"');
    PKGP_EXCEL_XML.AddCell(sCELL_DATE_RPT, 'HEADR');
    PKGP_EXCEL_XML.CloseLine;
    PKGP_EXCEL_XML.AddLine; -- Строка 6
    PKGP_EXCEL_XML.AddCell('Учреждение:', 'HEADT', 'ss:MergeAcross="1"');
    PKGP_EXCEL_XML.AddCell(sCELL_JURPERS, 'HEADTL', 'ss:MergeAcross="7"');
    PKGP_EXCEL_XML.AddCell('по ОКПО', 'HEADRT', 'ss:MergeAcross="1"');
    PKGP_EXCEL_XML.AddCell(sCELL_ORGCODE, 'HEADR');
    PKGP_EXCEL_XML.CloseLine;
    PKGP_EXCEL_XML.AddLine; -- Строка 7
    PKGP_EXCEL_XML.AddCell('Структурное подразделение:', 'HEADT', 'ss:MergeAcross="3"');
    PKGP_EXCEL_XML.AddCell(sBALUNIT_NAME, 'HEADTL', 'ss:MergeAcross="5"');
    PKGP_EXCEL_XML.AddCell('', 'HEADRT', 'ss:MergeAcross="1"');
    PKGP_EXCEL_XML.AddCell('', 'HEADR');
    PKGP_EXCEL_XML.CloseLine;
    PKGP_EXCEL_XML.AddLine; -- Строка 8
    PKGP_EXCEL_XML.AddCell('Наименование учредителя:', 'HEADT', 'ss:MergeAcross="3"');
    PKGP_EXCEL_XML.AddCell(sTRUSTOR_NAME, 'HEADTL', 'ss:MergeAcross="5"');
    PKGP_EXCEL_XML.AddCell('', 'HEADRT', 'ss:MergeAcross="1"');
    PKGP_EXCEL_XML.AddCell('', 'HEADR');
    PKGP_EXCEL_XML.CloseLine;
    PKGP_EXCEL_XML.AddLine; -- Строка 9
    PKGP_EXCEL_XML.AddCell('Наименование бюджета:', 'HEADT', 'ss:MergeAcross="3"');
    PKGP_EXCEL_XML.AddCell(sBUDGET_NAME, 'HEADTL', 'ss:MergeAcross="5"');
    PKGP_EXCEL_XML.AddCell('', 'HEADRT', 'ss:MergeAcross="1"');
    PKGP_EXCEL_XML.AddCell('', 'HEADR');
    PKGP_EXCEL_XML.CloseLine;
    PKGP_EXCEL_XML.AddLine; -- Строка 10
    PKGP_EXCEL_XML.AddCell('Единица измерения:', 'HEADT', 'ss:MergeAcross="2"');
    PKGP_EXCEL_XML.AddCell(sCELL_CURCODE, 'HEADT', 'ss:MergeAcross="6"');
    PKGP_EXCEL_XML.AddCell('по ОКЕИ', 'HEADRT', 'ss:MergeAcross="1"');
    PKGP_EXCEL_XML.AddCell('383', 'HEADR');
    PKGP_EXCEL_XML.CloseLine;
    PKGP_EXCEL_XML.AddLine; -- Строка 11
    PKGP_EXCEL_XML.CloseLine;
    PKGP_EXCEL_XML.AddLine; -- Строка 12
    PKGP_EXCEL_XML.AddNamedCell('Дата операции', 'Print_Titles', 'HEADC', 'ss:MergeDown="1"');
    PKGP_EXCEL_XML.AddNamedCell('Документ', 'Print_Titles', 'HEADC', 'ss:MergeAcross="2"');
    PKGP_EXCEL_XML.AddNamedCell('Наименование показателя', 'Print_Titles', 'HEADC' , 'ss:MergeDown="1"');
    PKGP_EXCEL_XML.AddNamedCell('Содержание операции', 'Print_Titles', 'HEADC' , 'ss:MergeDown="1"');
    PKGP_EXCEL_XML.AddNamedCell('Остаток на начало периода', 'Print_Titles', 'HEADC', 'ss:MergeAcross="1"');
    PKGP_EXCEL_XML.AddNamedCell('Номер счета', 'Print_Titles', 'HEADC', 'ss:MergeAcross="1"');
    PKGP_EXCEL_XML.AddNamedCell('Сумма', 'Print_Titles', 'HEADC' , 'ss:MergeDown="1"');
    PKGP_EXCEL_XML.AddNamedCell('Остаток на конец периода', 'Print_Titles', 'HEADC', 'ss:MergeAcross="1"');
    PKGP_EXCEL_XML.CloseLine;
    PKGP_EXCEL_XML.AddLine;
    PKGP_EXCEL_XML.AddNamedCell('Дата', 'Print_Titles', 'HEADC', 'ss:Index="2"');
    PKGP_EXCEL_XML.AddNamedCell('Номер', 'Print_Titles', 'HEADC');
    PKGP_EXCEL_XML.AddNamedCell('Наименование', 'Print_Titles', 'HEADC');
    PKGP_EXCEL_XML.AddNamedCell('по дебету', 'Print_Titles', 'HEADC', 'ss:Index="7"');
    PKGP_EXCEL_XML.AddNamedCell('по кредиту', 'Print_Titles', 'HEADC');
    PKGP_EXCEL_XML.AddNamedCell('дебет', 'Print_Titles', 'HEADC');
    PKGP_EXCEL_XML.AddNamedCell('кредит', 'Print_Titles', 'HEADC');
    PKGP_EXCEL_XML.AddNamedCell('по дебету', 'Print_Titles', 'HEADC', 'ss:Index="12"');
    PKGP_EXCEL_XML.AddNamedCell('по кредиту', 'Print_Titles', 'HEADC');
    PKGP_EXCEL_XML.CloseLine;
    PKGP_EXCEL_XML.AddLine;
    PKGP_EXCEL_XML.AddNamedCell('1', 'Print_Titles', 'HEADC');
    PKGP_EXCEL_XML.AddNamedCell('2', 'Print_Titles', 'HEADC');
    PKGP_EXCEL_XML.AddNamedCell('3', 'Print_Titles', 'HEADC');
    PKGP_EXCEL_XML.AddNamedCell('4', 'Print_Titles', 'HEADC');
    PKGP_EXCEL_XML.AddNamedCell('5', 'Print_Titles', 'HEADC');
    PKGP_EXCEL_XML.AddNamedCell('6', 'Print_Titles', 'HEADC');
    PKGP_EXCEL_XML.AddNamedCell('7', 'Print_Titles', 'HEADC');
    PKGP_EXCEL_XML.AddNamedCell('8', 'Print_Titles', 'HEADC');
    PKGP_EXCEL_XML.AddNamedCell('9', 'Print_Titles', 'HEADC');
    PKGP_EXCEL_XML.AddNamedCell('10', 'Print_Titles', 'HEADC');
    PKGP_EXCEL_XML.AddNamedCell('11', 'Print_Titles', 'HEADC');
    PKGP_EXCEL_XML.AddNamedCell('12', 'Print_Titles', 'HEADC');
    PKGP_EXCEL_XML.AddNamedCell('13', 'Print_Titles', 'HEADC');
  
    PKGP_EXCEL_XML.CloseLine;
  
    /*     
    PRSG!_EXCEL.CELL_VALUE_WRITE(CELL_JURPERS, );
    PRSG!_EXCEL.CELL_VALUE_WRITE(CELL_TRUSTOR, );
    PRSG!_EXCEL.CELL_VALUE_WRITE(CELL_BUDGET, );
    PRSG!_EXCEL.CELL_VALUE_WRITE(CELL_ORGCODE, );
    PRSG!_EXCEL.CELL_VALUE_WRITE(CELL_BALUNIT, );
    PRSG!_EXCEL.CELL_VALUE_WRITE(CELL_CURCODE, );
    -- подвал
    PRSG!_EXCEL.CELL_VALUE_WRITE(CELL_ACCOUNTANT, );
    PRSG!_EXCEL.CELL_VALUE_WRITE(CELL_EXEC_OCC, );
    PRSG!_EXCEL.CELL_VALUE_WRITE(CELL_EXEC_FIO, );*/
  
    nGF5_TURN_SUM := 0;
    nGF1_TURN_SUM := 0;
    nGF2_TURN_SUM := 0;
  
    bGH1_CHANGED  := true;
    bGH2_CHANGED  := true;
    bGH21_CHANGED := true;
    bGH3_CHANGED  := true;
    bGH4_CHANGED  := true;
    bGH5_CHANGED  := true;
  
    bGH1_IDX   := 0;
    bGH2_IDX   := 0;
    bLINE1_IDX := 0;
    bLINE2_IDX := 0;
    bLINE3_IDX := 0;
    bGF5_IDX   := 0;
    bGF1a_IDX  := 0;
    bGF1b_IDX  := 0;
  
    bFOOT5 := 0;
    bFOOT1 := 0;
  
    dbms_application_info.set_action('Выбираю...');
  
    /* открываем курсор */
    open C06;
    begin
      loop
        fetch C06
          into CUR_REC;
        exit when C06%NOTFOUND;
      
        /* Группа 1 */
        begin
          -- смена группы
          bGH1_CHANGED := bGH1_CHANGED or (CMP_NUM(VALUE_GH1, CUR_REC.nDATA_TYPE) = 0);
        
          if bGH1_CHANGED then
            if (bFOOT1 = 1) then
              /* итоги предыдущей группы */
              if (bFOOT5 = 1) then
                MAKE_GR5_FOOTER(VALUE_GH1, VALUE_GH3, VALUE_GH4, VALUE_GH5);
              end if;
              MAKE_GR1_FOOTER(VALUE_GH1);
            end if;
          
            -- отображение группы
            if (CUR_REC.nDATA_TYPE = 1 or (CUR_REC.nDATA_TYPE = 0.5 and nSHOW_TOTAL = 1)) then
            
              bGH1_IDX   := 1;
              bGH2_IDX   := 0;
              bLINE1_IDX := 0;
              bLINE2_IDX := 0;
              bLINE3_IDX := 0;
              bGF5_IDX   := 0;
              bGF1a_IDX  := 0;
              bGF1b_IDX  := 0;
            
              if (CUR_REC.nDATA_TYPE = 1) then
                sCELL_GH1_CONTENT := 'Обороты в главную книгу';
              else
                sCELL_GH1_CONTENT := 'Обороты по журналу операций';
              end if;
            
              PKGP_EXCEL_XML.AddLine; -- GH1
              PKGP_EXCEL_XML.AddCell('', 'GH1', 'ss:MergeAcross="4"');
              PKGP_EXCEL_XML.AddCell(sCELL_GH1_CONTENT, 'GH1', 'ss:MergeAcross="7"');
              PKGP_EXCEL_XML.CloseLine;
            end if;
            bGH1_CHANGED := false;
            bGH2_CHANGED := true;
          else
            bFOOT1 := 1;
          end if; -- bGH1_CHANGED
        end; -- Группа 1
      
        /* Группа 2 */
        begin
          -- смена группы
          bGH2_CHANGED := bGH2_CHANGED or (CMP_VC2(VALUE_GH2, CUR_REC.sACCOUNT) = 0);
        
          if bGH2_CHANGED then
            -- отображение группы
            if (CUR_REC.NDATA_TYPE = 0) then
            
              bGH1_IDX   := 0;
              bGH2_IDX   := 1;
              bLINE1_IDX := 0;
              bLINE2_IDX := 0;
              bLINE3_IDX := 0;
              bGF5_IDX   := 0;
              bGF1a_IDX  := 0;
              bGF1b_IDX  := 0;
            
              if (CUR_REC.sACCOUNT is not null) then
                sCELL_GH2_DATE := 'Операции по счету ' || CUR_REC.sACCOUNT;
              else
                sCELL_GH2_DATE := null;
              end if;
            
              /* запись значения ячеек строки */
            
              PKGP_EXCEL_XML.AddLine; -- GH1
              PKGP_EXCEL_XML.AddCell(sCELL_GH2_DATE, 'GH2', 'ss:MergeAcross="12"');
              PKGP_EXCEL_XML.CloseLine;
            
            end if;
            bFOOT1        := 1;
            bGH2_CHANGED  := false;
            bGH21_CHANGED := true;
          end if; -- bGH2_CHANGED
        end; -- Группа 2
      
        /* Группа 21 */
        begin
          -- смена группы
          bGH21_CHANGED := bGH21_CHANGED or (CMP_VC2(VALUE_GH21, CUR_REC.sAGENT) = 0);
        
          if bGH21_CHANGED then
            bGH21_CHANGED := false;
            bGH3_CHANGED  := true;
          end if; -- bGH21_CHANGED
        end; -- Группа 21
      
        /* Группа 3 */
        begin
          -- смена группы
          bGH3_CHANGED := bGH3_CHANGED or (CMP_NUM(VALUE_GH3, CUR_REC.nRECORD_TYPE) = 0);
          if bGH3_CHANGED then
            bFOOT1       := 1;
            bGH3_CHANGED := false;
            bGH4_CHANGED := true;
          end if;
        end; -- Группа 3
      
        /* Группа 4 */
        begin
          -- смена группы
          bGH4_CHANGED := bGH4_CHANGED or (CMP_VC2(VALUE_GH4, CUR_REC.sACCOUNT_DEBIT) = 0);
          if bGH4_CHANGED then
            bFOOT1       := 1;
            bGH4_CHANGED := false;
            bGH5_CHANGED := true;
          end if;
        end; -- Группа 4
      
        /* Группа 5 */
        begin
          -- смена группы
          bGH5_CHANGED := bGH5_CHANGED or (CMP_VC2(VALUE_GH5, CUR_REC.sACCOUNT_CREDIT) = 0);
          if bGH5_CHANGED then
            if (bFOOT5 = 1) then
              -- итоги предыдущей группы
              MAKE_GR5_FOOTER(VALUE_GH1, VALUE_GH3, VALUE_GH4, VALUE_GH5);
            end if;
            bGH5_CHANGED  := false;
            nGF5_TURN_SUM := 0;
            bFOOT5        := 1;
          end if;
        end; -- Группа 5
      
        /* Детали 1 */
        if (CUR_REC.nDATA_TYPE = 0 and CUR_REC.nRECORD_TYPE = 0) then
        
          bFOOT5 := 1;
        
          bGH1_IDX   := 0;
          bGH2_IDX   := 0;
          bLINE1_IDX := 1;
          bLINE2_IDX := 0;
          bLINE3_IDX := 0;
          bGF5_IDX   := 0;
          bGF1a_IDX  := 0;
          bGF1b_IDX  := 0;
        
          PKGP_EXCEL_XML.AddLine;
          PKGP_EXCEL_XML.AddCell(to_char(CUR_REC.dOPER_DATE, 'DD.MM.YYYY'), 'LINE1');
          PKGP_EXCEL_XML.AddCell(to_char(CUR_REC.dFACT_DOCDATE, 'DD.MM.YYYY'), 'LINE1');
          PKGP_EXCEL_XML.AddCell(CUR_REC.sFACT_DOCNUMB, 'LINE1');
          PKGP_EXCEL_XML.AddCell(CUR_REC.sFACT_DOCTYPE, 'LINE1');
          PKGP_EXCEL_XML.AddCell(CUR_REC.SCOMMENT, 'LINE1');
          PKGP_EXCEL_XML.AddCell(CUR_REC.sOPER_CONTENT, 'LINE1');
          PKGP_EXCEL_XML.AddCell('', 'LINE1');
          PKGP_EXCEL_XML.AddCell('', 'LINE1');
          PKGP_EXCEL_XML.AddCell(CUR_REC.sACCOUNT_DEBIT, 'LINE1');
          PKGP_EXCEL_XML.AddCell(CUR_REC.sACCOUNT_CREDIT, 'LINE1');
          PKGP_EXCEL_XML.AddCell(CUR_REC.nTURN_SUM, 'LINE1');
          PKGP_EXCEL_XML.AddCell('', 'LINE1');
          PKGP_EXCEL_XML.AddCell('', 'LINE1');
          PKGP_EXCEL_XML.CloseLine;
        
        end if; -- Детали 1
      
        /* Детали 2 */
        if (CUR_REC.nDATA_TYPE = 0) and (CUR_REC.nRECORD_TYPE = 1) then
        
          bFOOT5 := 1;
        
          bGH1_IDX   := 0;
          bGH2_IDX   := 0;
          bLINE1_IDX := 0;
          bLINE2_IDX := 1;
          bLINE3_IDX := 0;
          bGF5_IDX   := 0;
          bGF1a_IDX  := 0;
          bGF1b_IDX  := 0;
        
          nLN2_RMSUM_DB := CUR_REC.nREMN_SUM;
          nLN2_RMSUM_CR := CUR_REC.nREMN_SUM;
          nLN2_RSSUM_DB := CUR_REC.nREMN_SUM + CUR_REC.nDEBIT_SUM - CUR_REC.nCREDIT_SUM;
          nLN2_RSSUM_CR := CUR_REC.nREMN_SUM + CUR_REC.nDEBIT_SUM - CUR_REC.nCREDIT_SUM;
        
          if (nLN2_RMSUM_DB <= 0) then
            nLN2_RMSUM_DB := null;
          end if;
          if (nLN2_RMSUM_CR >= 0) then
            nLN2_RMSUM_CR := null;
          end if;
          if (nLN2_RSSUM_DB <= 0) then
            nLN2_RSSUM_DB := null;
          end if;
          if (nLN2_RSSUM_CR >= 0) then
            nLN2_RSSUM_CR := null;
          end if;
        
          PKGP_EXCEL_XML.AddLine;
          PKGP_EXCEL_XML.AddCell('', 'LINE2', 'ss:MergeAcross="3"');
          PKGP_EXCEL_XML.AddCell(CUR_REC.sCOMMENT, 'LINE2');
          PKGP_EXCEL_XML.AddCell(CUR_REC.sACCOUNT, 'LINE2');
          PKGP_EXCEL_XML.AddCell(nLN2_RMSUM_DB, 'LINE2');
          PKGP_EXCEL_XML.AddCell(-nLN2_RMSUM_CR, 'LINE2');
          PKGP_EXCEL_XML.AddCell(CUR_REC.nDEBIT_SUM, 'LINE2');
          PKGP_EXCEL_XML.AddCell(CUR_REC.nCREDIT_SUM, 'LINE2');
          PKGP_EXCEL_XML.AddCell('x', 'LINE2');
          PKGP_EXCEL_XML.AddCell(nLN2_RSSUM_DB, 'LINE2');
          PKGP_EXCEL_XML.AddCell(-nLN2_RSSUM_CR, 'LINE2');
          PKGP_EXCEL_XML.CloseLine;
        
        end if; -- Детали 2
      
        /* Детали 3 */
        if (CUR_REC.nDATA_TYPE = 0) and (CUR_REC.nRECORD_TYPE = 3) then
        
          bFOOT5 := 1;
        
          bGH1_IDX   := 0;
          bGH2_IDX   := 0;
          bLINE1_IDX := 0;
          bLINE2_IDX := 0;
          bLINE3_IDX := 1;
          bGF5_IDX   := 0;
          bGF1a_IDX  := 0;
          bGF1b_IDX  := 0;
        
          nLN3_RMSUM_DB := CUR_REC.nREMN_SUM;
          nLN3_RMSUM_CR := CUR_REC.nREMN_SUM;
          nLN3_RSSUM_DB := CUR_REC.nREMN_SUM + CUR_REC.nDEBIT_SUM - CUR_REC.nCREDIT_SUM;
          nLN3_RSSUM_CR := CUR_REC.nREMN_SUM + CUR_REC.nDEBIT_SUM - CUR_REC.nCREDIT_SUM;
        
          if (nLN3_RMSUM_DB <= 0) then
            nLN3_RMSUM_DB := null;
          end if;
          if (nLN3_RMSUM_CR >= 0) then
            nLN3_RMSUM_CR := null;
          end if;
          if (nLN3_RSSUM_DB <= 0) then
            nLN3_RSSUM_DB := null;
          end if;
          if (nLN3_RSSUM_CR >= 0) then
            nLN3_RSSUM_CR := null;
          end if;
        
          PKGP_EXCEL_XML.AddLine;
          PKGP_EXCEL_XML.AddCell('', 'LINE3', 'ss:MergeAcross="3"');
          PKGP_EXCEL_XML.AddCell(CUR_REC.sCOMMENT, 'LINE3');
          PKGP_EXCEL_XML.AddCell(CUR_REC.sACCOUNT, 'LINE3');
          PKGP_EXCEL_XML.AddCell(nLN3_RMSUM_DB, 'LINE3');
          PKGP_EXCEL_XML.AddCell(-nLN3_RMSUM_CR, 'LINE3');
          PKGP_EXCEL_XML.AddCell(CUR_REC.nDEBIT_SUM, 'LINE3');
          PKGP_EXCEL_XML.AddCell(CUR_REC.nCREDIT_SUM, 'LINE3');
          PKGP_EXCEL_XML.AddCell('x', 'LINE3');
          PKGP_EXCEL_XML.AddCell(nLN3_RSSUM_DB, 'LINE3');
          PKGP_EXCEL_XML.AddCell(-nLN3_RSSUM_CR, 'LINE3');
          PKGP_EXCEL_XML.CloseLine;
        
        end if; -- Детали 3
      
        /* сохраняем значения групп */
        VALUE_GH1  := CUR_REC.nDATA_TYPE;
        VALUE_GH2  := CUR_REC.sACCOUNT;
        VALUE_GH21 := CUR_REC.sAGENT;
        VALUE_GH3  := CUR_REC.nRECORD_TYPE;
        VALUE_GH4  := CUR_REC.sACCOUNT_DEBIT;
        VALUE_GH5  := CUR_REC.sACCOUNT_CREDIT;
      
        /* итоги */
        if (CUR_REC.NDATA_TYPE = 1 or (CUR_REC.NDATA_TYPE = 0.5 and nSHOW_TOTAL = 1)) and (CUR_REC.NRECORD_TYPE = 0) then
          nGF5_TURN_SUM := nGF5_TURN_SUM + CUR_REC.nTURN_SUM;
        end if;
      
        if (CUR_REC.NIS_DEBIT = 0) and (CUR_REC.NDATA_TYPE = 0) then
          nGF1_TURN_SUM := nGF1_TURN_SUM + CUR_REC.nTURN_SUM;
        end if;
      
        if (CUR_REC.NIS_DEBIT = 0) and (CUR_REC.NDATA_TYPE = 1 or (CUR_REC.NDATA_TYPE = 0.5 and nSHOW_TOTAL = 1)) then
          nGF2_TURN_SUM := nGF2_TURN_SUM + CUR_REC.nTURN_SUM;
        end if;
      
      end loop; -- CUR_REC
    
      if (bFOOT5 = 1) then
        /* Итоги 5 */
        MAKE_GR5_FOOTER(VALUE_GH1, VALUE_GH3, VALUE_GH4, VALUE_GH5);
      end if;
    
      if (bFOOT1 = 1) then
        /* Итоги 1 */
        MAKE_GR1_FOOTER(VALUE_GH1);
      end if;
    
      close C06;
    exception
      when OTHERS then
        close C06;
    end;
  
    /* очистка временной таблицы */
    P_PACK_BY_IDENT('MEMORDRP_REPORT2', nIDENT, null);
  
    dbms_application_info.set_action('Готово');
  
    PKGP_EXCEL_XML.AddLine; -- Строка 
    PKGP_EXCEL_XML.CloseLine;
    PKGP_EXCEL_XML.AddLine; -- Строка 
    PKGP_EXCEL_XML.AddCell('Количество листов приложений', 'HEADT', 'ss:MergeAcross="3"');
    PKGP_EXCEL_XML.AddCell('', 'HEADR');
    PKGP_EXCEL_XML.CloseLine;
    PKGP_EXCEL_XML.AddLine; -- Строка 
    PKGP_EXCEL_XML.CloseLine;
    PKGP_EXCEL_XML.AddLine; -- Строка 
    PKGP_EXCEL_XML.AddCell('Главный бухгалтер:', 'HEADT', 'ss:MergeAcross="2"');
    PKGP_EXCEL_XML.AddCell('', 'FOOTL');
    PKGP_EXCEL_XML.AddCell(sACCOUNTANT, 'FOOTL', 'ss:MergeAcross="1"');
    PKGP_EXCEL_XML.AddCell('Исполнитель:', 'HEADRT', 'ss:MergeAcross="1"');
    PKGP_EXCEL_XML.AddCell(sEXEC_OCC, 'FOOTL', 'ss:MergeAcross="1"');
    PKGP_EXCEL_XML.AddCell('', 'FOOTL');
    PKGP_EXCEL_XML.AddCell(sEXEC_FIO, 'FOOTL', 'ss:MergeAcross="1"');
    PKGP_EXCEL_XML.CloseLine;
    PKGP_EXCEL_XML.AddLine; -- Строка 
    PKGP_EXCEL_XML.AddCell('', 'FOOT', 'ss:MergeAcross="2"');
    PKGP_EXCEL_XML.AddCell('(подпись)', 'FOOT');
    PKGP_EXCEL_XML.AddCell('(расшифровка подписи)', 'FOOT', 'ss:MergeAcross="1"');
    PKGP_EXCEL_XML.AddCell('', 'FOOT', 'ss:MergeAcross="1"');
    PKGP_EXCEL_XML.AddCell('(должность)', 'FOOT', 'ss:MergeAcross="1"');
    PKGP_EXCEL_XML.AddCell('(подпись)', 'FOOT');
    PKGP_EXCEL_XML.AddCell('(расшифровка подписи)', 'FOOT', 'ss:MergeAcross="1"');
    PKGP_EXCEL_XML.CloseLine;
  
    PKGP_EXCEL_XML.AddLine; -- Строка 
    PKGP_EXCEL_XML.CloseLine;
    PKGP_EXCEL_XML.AddLine; -- Строка 
    PKGP_EXCEL_XML.AddCell('"____"______________20___г.', 'HEADT');
    PKGP_EXCEL_XML.CloseLine;
  
    XML_FINI;
  
  else
    P_EXCEPTION(0, 'Данные для формирования отчета не найдены.');
  end if;

exception
  when OTHERS then
    if (nRESULT = 1) then
      /* очистка временной таблицы */
      P_PACK_BY_IDENT('MEMORDRP_REPORT2', nIDENT, null);
    end if;
    raise;
end PP_PR_MEMORDRP_XLS6S_173N;
/
