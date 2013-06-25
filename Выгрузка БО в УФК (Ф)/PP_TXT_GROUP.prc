create or replace procedure PP_TXT_GROUP
--
(nIDENT in number,
 nGROUP in number,
 sGROUP in varchar2 --
 ) is
begin
  update TP_TXT t
     set t.groupname = sGROUP
   where t.ident = nIDENT
     and t.groupnumber = nGROUP;
end PP_TXT_GROUP;
/
