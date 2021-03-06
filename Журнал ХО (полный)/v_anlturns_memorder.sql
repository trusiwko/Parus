create or replace view v_anlturns_memorder
(nrn, sauthid, nident, ncompany, ddate_from, ddate_to, njur_pers, sjur_pers, nbalunit, sbalunit, nbalelem, sbalelem, nacctype, sacctype, nat_currency, sat_currency, naccount, saccount, saccount_name, nacc_currency, ncurrency, scurrency, nanalytic1, sanalytic1, sanalytic1_name, nanalytic2, sanalytic2, sanalytic2_name, nanalytic3, sanalytic3, sanalytic3_name, nanalytic4, sanalytic4, sanalytic4_name, nanalytic5, sanalytic5, sanalytic5_name, ndiff_sign, nacnt_remn_sum, nacnt_remn_base_sum, nacnt_remn_at_sum, nctrl_remn_sum, nctrl_remn_base_sum, nctrl_remn_at_sum, nacnt_debit_remn_sum, nacnt_debit_remn_base_sum, nacnt_debit_remn_at_sum, nctrl_debit_remn_sum, nctrl_debit_remn_base_sum, nctrl_debit_remn_at_sum, nacnt_credit_remn_sum, nacnt_credit_remn_base_sum, nacnt_credit_remn_at_sum, nctrl_credit_remn_sum, nctrl_credit_remn_base_sum, nctrl_credit_remn_at_sum, nacnt_debit_turn_sum, nacnt_debit_turn_base_sum, nacnt_debit_turn_at_sum, nctrl_debit_turn_sum, nctrl_debit_turn_base_sum, nctrl_debit_turn_at_sum, nacnt_credit_turn_sum, nacnt_credit_turn_base_sum, nacnt_credit_turn_at_sum, nctrl_credit_turn_sum, nctrl_credit_turn_base_sum, nctrl_credit_turn_at_sum, nacnt_res_sum, nacnt_res_base_sum, nacnt_res_at_sum, nctrl_res_sum, nctrl_res_base_sum, nctrl_res_at_sum, nacnt_debit_res_sum, nacnt_debit_res_base_sum, nacnt_debit_res_at_sum, nctrl_debit_res_sum, nctrl_debit_res_base_sum, nctrl_debit_res_at_sum, nacnt_credit_res_sum, nacnt_credit_res_base_sum, nacnt_credit_res_at_sum, nctrl_credit_res_sum, nctrl_credit_res_base_sum, nctrl_credit_res_at_sum, smemorder)
as
select
  TR.RN,
  TR.AUTHID,
  TR.IDENT,
  TR.COMPANY,
  TR.DATE_FROM,
  TR.DATE_TO,
  TR.JUR_PERS,
    JP.CODE,
  TR.BALUNIT,
    BU.BUNIT_MNEMO,
  TR.BALELEM,
    BE.CODE,
  TR.ACCTYPE,
    T.CODE,
    T.CURRENCY,
      TC.INTCODE,
  TR.ACCOUNT,
    AC.ACC_NUMBER,
    AC.ACC_NAME,
    AC.ACC_CURRENCY,
  TR.CURRENCY,
    C.INTCODE,
  TR.ANALYTIC1,
    AN1.ANL_NUMBER,
    AN1.ANL_NAME,
  TR.ANALYTIC2,
    AN2.ANL_NUMBER,
    AN2.ANL_NAME,
  TR.ANALYTIC3,
    AN3.ANL_NUMBER,
    AN3.ANL_NAME,
  TR.ANALYTIC4,
    AN4.ANL_NUMBER,
    AN4.ANL_NAME,
  TR.ANALYTIC5,
    AN5.ANL_NUMBER,
    AN5.ANL_NAME,
  TR.DIFF_SIGN,
  TR.ACNT_REMN_SUM,
  TR.ACNT_REMN_BASE_SUM,
  TR.ACNT_REMN_AT_SUM,
  TR.CTRL_REMN_SUM,
  TR.CTRL_REMN_BASE_SUM,
  TR.CTRL_REMN_AT_SUM,
  TR.ACNT_DEBIT_REMN_SUM,
  TR.ACNT_DEBIT_REMN_BASE_SUM,
  TR.ACNT_DEBIT_REMN_AT_SUM,
  TR.CTRL_DEBIT_REMN_SUM,
  TR.CTRL_DEBIT_REMN_BASE_SUM,
  TR.CTRL_DEBIT_REMN_AT_SUM,
  TR.ACNT_CREDIT_REMN_SUM,
  TR.ACNT_CREDIT_REMN_BASE_SUM,
  TR.ACNT_CREDIT_REMN_AT_SUM,
  TR.CTRL_CREDIT_REMN_SUM,
  TR.CTRL_CREDIT_REMN_BASE_SUM,
  TR.CTRL_CREDIT_REMN_AT_SUM,
  TR.ACNT_DEBIT_TURN_SUM,
  TR.ACNT_DEBIT_TURN_BASE_SUM,
  TR.ACNT_DEBIT_TURN_AT_SUM,
  TR.CTRL_DEBIT_TURN_SUM,
  TR.CTRL_DEBIT_TURN_BASE_SUM,
  TR.CTRL_DEBIT_TURN_AT_SUM,
  TR.ACNT_CREDIT_TURN_SUM,
  TR.ACNT_CREDIT_TURN_BASE_SUM,
  TR.ACNT_CREDIT_TURN_AT_SUM,
  TR.CTRL_CREDIT_TURN_SUM,
  TR.CTRL_CREDIT_TURN_BASE_SUM,
  TR.CTRL_CREDIT_TURN_AT_SUM,
  TR.ACNT_RES_SUM,
  TR.ACNT_RES_BASE_SUM,
  TR.ACNT_RES_AT_SUM,
  TR.CTRL_RES_SUM,
  TR.CTRL_RES_BASE_SUM,
  TR.CTRL_RES_AT_SUM,
  TR.ACNT_DEBIT_RES_SUM,
  TR.ACNT_DEBIT_RES_BASE_SUM,
  TR.ACNT_DEBIT_RES_AT_SUM,
  TR.CTRL_DEBIT_RES_SUM,
  TR.CTRL_DEBIT_RES_BASE_SUM,
  TR.CTRL_DEBIT_RES_AT_SUM,
  TR.ACNT_CREDIT_RES_SUM,
  TR.ACNT_CREDIT_RES_BASE_SUM,
  TR.ACNT_CREDIT_RES_AT_SUM,
  TR.CTRL_CREDIT_RES_SUM,
  TR.CTRL_CREDIT_RES_BASE_SUM,
  TR.CTRL_CREDIT_RES_AT_SUM,
  MO.CODE
from
  ANLTURNS   TR,
  DICACCS    AC,
  DICANLS    AN1,
  DICANLS    AN2,
  DICANLS    AN3,
  DICANLS    AN4,
  DICANLS    AN5,
  ACCTYPES   T,
  DICBUNTS   BU,
  CURNAMES   C,
  CURNAMES   TC,
  BALELEMENT BE,
  JURPERSONS JP,
  MEMORDER   MO
where AUTHID       = user
  and TR.CURRENCY  = C.RN
  and TR.JUR_PERS  = JP.RN  (+)
  and TR.BALELEM   = BE.RN  (+)
  and TR.ACCOUNT   = AC.RN   (+)
  and TR.ANALYTIC1 = AN1.RN  (+)
  and TR.ANALYTIC2 = AN2.RN  (+)
  and TR.ANALYTIC3 = AN3.RN  (+)
  and TR.ANALYTIC4 = AN4.RN  (+)
  and TR.ANALYTIC5 = AN5.RN  (+)
  and TR.BALUNIT   = BU.RN  (+)
  and TR.ACCTYPE   = T.RN   (+)
  and T.CURRENCY   = TC.RN  (+)
  and AC.MEMORDER  = MO.RN  

