create or replace procedure PP_TXT_S
--
(nIDENT       in number, --
 nGROUPNUMBER in number,
 nFIELDNUMBER in number,
 sVALUE       in varchar2,
 bNeed        in boolean,
 sFIELDNAME   in varchar2 default null,
 sFIELDNAMERUS in varchar2 default null,
 nSIZEMAX         in number default null,
 nSIZEMIN         in number default null) is
begin
  PP_TXT(nIDENT, nGROUPNUMBER, nFIELDNUMBER, sVALUE, bNeed, sFIELDNAME, sFIELDNAMERUS, nSIZEMAX, nSIZEMIN);
end;
/
