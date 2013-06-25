CREATE OR REPLACE procedure PARUS.PP_TXT_FILE
--
(nIDENT    in number,
 sFILENAME in varchar2 --
 ) is
  sDATA     PKG_STD.tLSTRING;
  sDELIM    varchar2(1) := '|';
  sEXP_CLOB clob;
begin
  dbms_lob.createtemporary(sEXP_CLOB, true);
  for a in (select distinct t.groupnumber, --
                            t.groupname
              from TP_TXT t
             where t.ident = nIDENT
             order by groupnumber) loop
    sDATA := a.groupname;
    for c in (select t.value --
                from TP_TXT t
               where t.ident = nIDENT
                 and t.groupnumber = a.groupnumber
               order by t.fieldnumber) loop
      sDATA := sDATA || sDELIM || c.value;
    end loop;
    sDATA := sDATA || sDELIM || CR;
    dbms_lob.writeappend(sEXP_CLOB, length(sDATA), sDATA);
  end loop;

  insert into FILE_BUFFER
    (IDENT, AUTHID, FILENAME, DATA) --
  values
    (nIDENT, user, sFILENAME, sEXP_CLOB);
  dbms_lob.freetemporary(sEXP_CLOB);

end PP_TXT_FILE;
/
