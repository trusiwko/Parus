create or replace procedure PP_TXT_N
--
(nIDENT        in number, --
 nGROUPNUMBER  in number,
 nFIELDNUMBER  in number,
 sVALUE        in number,
 bNeed         in boolean,
 sFIELDNAME    in varchar2 default null,
 sFIELDNAMERUS in varchar2 default null) is
  sNUM_FMT constant varchar2(18) := '999999999999990.99';
begin
  PP_TXT(nIDENT, nGROUPNUMBER, nFIELDNUMBER, to_char(sVALUE, sNUM_FMT), bNeed, sFIELDNAME, sFIELDNAMERUS);
end;
/
