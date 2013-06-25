create or replace procedure PP_TXT
--
(nIDENT        in number, --
 nGROUPNUMBER  in number,
 nFIELDNUMBER  in number,
 sVALUE        in varchar2,
 bNeed         in boolean,
 sFIELDNAME    in varchar2 default null,
 sFIELDNAMERUS in varchar2 default null,
 nSIZEMAX      in number default null,
 nSIZEMIN      in number default null) is
  s varchar2(250);
begin
  if sFIELDNAMERUS is not null then
    s := ' (' || sFIELDNAMERUS || ')';
  end if;
  if (bNeed) and (sVALUE is null) then
    p_exception(0, 'Поле "' || sFIELDNAME || s || '" должно быть обязательно заполнено.');
  end if;
  if (nSIZEMAX is not null) and (length(sVALUE) > nSIZEMAX) then
    p_exception(0, 'Поле "' || sFIELDNAME || s || '" превышает допустимую длину ' || nSIZEMAX || ' символов: ' || sVALUE);
  end if;
  if (nSIZEMIN is not null) and (length(sVALUE) < nSIZEMIN) then
    p_exception(0, 'Поле "' || sFIELDNAME || s || '" меньше необходимой длины ' || nSIZEMIN || ' символов: ' || sVALUE);
  end if;
  insert into TP_TXT
    (ident, groupnumber, fieldnumber, value, authid, fieldname) --
  values
    (nIDENT, nGROUPNUMBER, nFIELDNUMBER, replace(trim(sVALUE), '|', '/'), user, sFIELDNAME);
end;
/
