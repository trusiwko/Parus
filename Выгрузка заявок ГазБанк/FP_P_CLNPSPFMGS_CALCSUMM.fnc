create or replace function FP_P_CLNPSPFMGS_CALCSUMM
--
(nCompany in number,
 nPRN     in number,
 dDate    in date --
 ) return number is
  Result number;
begin
  P_CLNPSPFMGS_CALCSUMM(nCompany, nPRN, dDate, Result);
  return(Result);
end;
/*
  create public synonym FP_P_CLNPSPFMGS_CALCSUMM for FP_P_CLNPSPFMGS_CALCSUMM;
  grant execute on FP_P_CLNPSPFMGS_CALCSUMM to public;
  */
/
