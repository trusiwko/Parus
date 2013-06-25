create or replace procedure PP_TXT_D
--
(nIDENT        in number, --
 nGROUPNUMBER  in number,
 nFIELDNUMBER  in number,
 sVALUE        in date,
 bNeed         in boolean,
 sFIELDNAME    in varchar2 default null,
 sFIELDNAMERUS in varchar2 default null) is
  sDATE_FMT constant varchar2(10) := 'DD.MM.YYYY';
begin
  PP_TXT(nIDENT, nGROUPNUMBER, nFIELDNUMBER, to_char(sVALUE, sDATE_FMT), bNeed, sFIELDNAME, sFIELDNAMERUS);
end;
/
