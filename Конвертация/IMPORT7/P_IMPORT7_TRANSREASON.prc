create or replace procedure P_IMPORT7_TRANSREASON
-- ��������� ������������
 as
  nNEWRN    PKG_STD.tREF;
begin
  /* �� ���. �������
    101 - ��������� ����������
  */
  for rREC in (select A.*
                 from P7_COMDICBS A, P7_COMDICTP B
                where A.COMDICTP_R = B.COMDICTP_R
                  and B.NUM = 101) loop
  
    find_transreason_code(1, 1, PKG_IMPORT7.nCOMPANY, rREC.Code, nNEWRN);
  
    if nNEWRN is null then
      begin
        p_transreason_base_insert(ncompany => PKG_IMPORT7.nCOMPANY, --
                                  scode    => rREC.Code,
                                  sname    => rREC.Name,
                                  nrn      => nNEWRN);
      exception
        when OTHERS then
          PKG_IMPORT7.LOG_ERROR('COMDICBS', rREC.COMDICBS_R, nvl(ERROR_CONSTR_TEXT, ERROR_TEXT));
      end;
    end if;
    PKG_IMPORT7.SET_REF('COMDICBS', rREC.COMDICBS_R, nNEWRN);
  end loop;
end;
/
