create or replace procedure P_IMPORT7_DICTOPER
-- Импорт видов операций
 is
  nNEWRN PKG_STD.tREF;
  nCRN   PKG_STD.tREF;
begin
  FIND_ROOT_CATALOG(PKG_IMPORT7.nCOMPANY, 'TypeOpersPay', nCRN);
  for rREC in (select * --
                 from P7_OPERATE t
                where not exists (select null --
                         from dictoper a
                        where a.typoper_mnemo = t.mnemo_oper)) loop
    begin
      nNEWRN := null;
      p_dictoper_base_insert(ncompany        => PKG_IMPORT7.nCOMPANY,
                             ncrn            => nCRN,
                             ntypoper_mnemo  => rREC.Mnemo_Oper,
                             ntypoper_name   => rREC.Name_Oper,
                             ntypoper_direct => rREC.Type_Oper - 1,
                             nfactret_sign   => 0, -- признак возврата (прямая)
                             nrn             => nNEWRN);
    exception
      when OTHERS then
        PKG_IMPORT7.LOG_ERROR('OPERATE', rREC.Rn, sqlerrm);
    end;
    PKG_IMPORT7.SET_REF('OPERATE', rREC.Rn, nNEWRN);
  end loop;
end P_IMPORT7_DICTOPER;
/
