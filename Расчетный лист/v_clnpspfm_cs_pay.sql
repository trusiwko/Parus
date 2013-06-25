create or replace view v_clnpspfm_cs_pay
(nrn, nclnpspfm, ntyp, spay_name, spay_code, npay_aux, npay_sum, sslp_pref, sslp_numb, nyearfor, nmonthfor, nbgnfor, nendfor, ncnt, nprc, nded, ntax, nc_typ, sc_pay_name, sc_pay_code, nc_pay_aux, nc_pay_sum, nc_yearfor, nc_monthfor, nc_bgnfor, nc_endfor, nc_prc, nc_ded, nmnths, ntopay, nc_topay, ncash, nvisa)
as
select A.RN, -- nRN
       A.CLNPSPFM, -- nCLNPSPFM
       A.TYP, -- nTYP
       B.NAME, -- sPAY_NAME
       B.CODE, -- sPAY_CODE
       A.PAY_AUX, -- nPAY_AUX
       A.PAY_SUM, -- nPAY_SUM
       C.PREF, -- sSLP_PREF
       C.NUMB, -- sSLP_NUMB
       A.YEARFOR, -- nYEARFOR
       A.MONTHFOR, -- nMONTHFOR
       A.BGNFOR, -- nBGNFOR
       A.ENDFOR, -- nENDFOR
       A.REM4, -- nCNT
       A.REM5, -- nPRC
       A.REM6, -- nDED
       A.REM7, -- nTAX
       A.C_TYP, -- nC_TYP
       BC.NAME, -- sC_PAY_NAME
       BC.CODE, -- sC_PAY_CODE
       A.C_PAY_AUX, -- nC_PAY_AUX
       A.C_PAY_SUM, -- nC_PAY_SUM
       A.C_YEARFOR, -- nC_YEARFOR
       A.C_MONTHFOR, -- nC_MONTHFOR
       A.C_BGNFOR, -- nC_BGNFOR
       A.C_ENDFOR, -- nC_ENDFOR
       A.C_REM5, -- nC_PRC
       A.C_REM6, -- nC_DED
       A.MNTHS, -- nMNTHS
       A.TOPAY, -- nTOPAY
       A.C_TOPAY, -- C_TOPAY
       case
         when A.TYP in (1, 3, 7) then
          A.PAY_SUM
         when A.TYP in (5, 111) then
          -A.PAY_SUM
         else
          0
       end nCASH,
       case
         when A.TYP in (111) then
          A.PAY_SUM
         else
          0
       end nVISA
  from CLNPSPFM_CS A, SLCOMPCHARGES B, SLCOMPCHARGES BC, SLPSHEETS C
 where A.AUTHID = UTILIZER
   and (A.TYP is null or (A.TYP between 1 and 10))
   and A.PAY_LNK = B.RN(+)
   and A.C_PAY_LNK = BC.RN(+)
   and A.SLP_LNK = C.RN(+);
