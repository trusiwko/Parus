create or replace procedure PP_GOVCNTR_HO_CANCEL
-- Снятие отработки ГК в ХО
( --
 nCOMPANY in number,
 nIDENT   in number --
 ) is
begin
  for a in (select dl.in_document, dl.out_document
              from selectlist s, doclinks dl
             where s.ident = nident
               and s.document = dl.in_document
               and dl.in_unitcode = 'GovernmentContracts'
               and dl.out_unitcode = 'EconomicOperations') loop
    pkg_doclinks.REMOVE('GovernmentContracts', a.in_document, 'EconomicOperations', a.out_document);
    begin
      PKG_PROC_BROKER.PROLOGUE;
      PKG_PROC_BROKER.SET_PARAM_NUM('NCOMPANY', nCOMPANY);
      PKG_PROC_BROKER.SET_PARAM_NUM('RN', a.out_document);
      PKG_PROC_BROKER.EXECUTE('DELETE_ECONOPRS', 1);
      PKG_PROC_BROKER.EPILOGUE;
    exception
      when others then
        PKG_PROC_BROKER.EPILOGUE;
        raise;
    end;
  end loop;
end PP_GOVCNTR_HO_CANCEL;
/*create public synonym PP_GOVCNTR_HO_CANCEL for PP_GOVCNTR_HO_CANCEL;
  grant execute on PP_GOVCNTR_HO_CANCEL to public;*/
/
