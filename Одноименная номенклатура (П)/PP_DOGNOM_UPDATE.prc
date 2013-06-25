create or replace procedure PP_DOGNOM_UPDATE
-- Обновление доп.свойства "Номенклатура для нужд заказчика"
( --
 nIDENT in number,
 sCODE  in varchar2 --
 ) is
begin
  for c in (select s.document from selectlist s where s.ident = nIDENT) loop
    begin
      PKG_PROC_BROKER.PROLOGUE;
      PKG_PROC_BROKER.SET_PARAM_STR('SUNITCODE', 'GovernmentContracts');
      PKG_PROC_BROKER.SET_PARAM_NUM('NDOCUMENT', c.document);
      PKG_PROC_BROKER.SET_PROP_STR('Номенклатура для зак',
                                   sCODE);
      PKG_PROC_BROKER.EXECUTE('P_DOCUMENT_UPDATE', 1);
      PKG_PROC_BROKER.EPILOGUE;
    exception
      when others then
        PKG_PROC_BROKER.EPILOGUE;
        raise;
    end;
  end loop;
end PP_DOGNOM_UPDATE;
/*create public synonym PP_DOGNOM_UPDATE for PP_DOGNOM_UPDATE;
grant execute on PP_DOGNOM_UPDATE to public;*/
/
