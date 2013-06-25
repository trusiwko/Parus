create or replace procedure PP_DOCL_REM
-- Удалить все связи
(nRN in number) is
begin
  for c in (select * from doclinks dl where nRN in (dl.in_document, dl.out_document)) loop
    pkg_doclinks.REMOVE(c.in_unitcode, c.in_document, c.out_unitcode, c.out_document);
  end loop;
end PP_DOCL_REM;
/
