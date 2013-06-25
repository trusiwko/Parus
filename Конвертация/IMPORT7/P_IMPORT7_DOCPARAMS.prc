create or replace procedure P_IMPORT7_DOCPARAMS
-- Типы документов. Связи с разделами.
 is
  nNEWRN PKG_STD.TREF;
begin
  for rREC in (select s.*, --
                      a.P8 sunit
                 from p7_docspec s, p7_units u, VP_P7_UNITS a
                where s.unit_rn = u.rn
                  and a.P7 = u.name) loop
    begin
      p_docparams_base_insert(ncompany  => PKG_IMPORT7.nCOMPANY, --
                              nprn      => PKG_IMPORT7.GET_RN8(0, 1, 'DOCBASE', rREC.Master_Rn),
                              sunitcode => rREC.sunit,
                              nsbase    => rREC.Is_Yes,
                              nsconf    => rREC.Is_Conf,
                              nsdoc     => rREC.Is_First,
                              nrn       => nNEWRN);
    exception
      when OTHERS then
        PKG_IMPORT7.LOG_ERROR('DOCSPEC', rREC.RN, nvl(ERROR_CONSTR_TEXT, ERROR_TEXT));
    end;
    PKG_IMPORT7.SET_REF('DOCSPEC', rREC.RN, nNEWRN);
  end loop;
end P_IMPORT7_DOCPARAMS;
/
