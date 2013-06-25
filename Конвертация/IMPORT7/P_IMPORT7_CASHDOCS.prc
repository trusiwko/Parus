create or replace procedure P_IMPORT7_CASHDOCS
-- »мпорт кассовых документов
 as
  nNEWRN         PKG_STD.tREF;
  nJUR_PERS      PKG_STD.tREF;
  nMAIN_JUR_PERS PKG_STD.tREF;
  sTMP           PKG_STD.tSTRING;
  nSPECRN        PKG_STD.tREF;
begin
  PKG_IMPORT7.IMPORT_TABLE('DOCTYPES');
  PKG_IMPORT7.IMPORT_TABLE('AGNLIST');
  PKG_IMPORT7.IMPORT_TABLE('DICTOPER');
  PKG_IMPORT7.IMPORT_TABLE('CURNAMES');
  PKG_IMPORT7.IMPORT_TABLE('MEMORDER');
  PKG_IMPORT7.IMPORT_TABLE('ACCBASE');
  PKG_IMPORT7.IMPORT_TABLE('ACCSPEC');

  FIND_JURPERSONS_MAIN(0, PKG_IMPORT7.nCOMPANY, sTMP, nMAIN_JUR_PERS);
  for rREC in (select t.* from P7_CASH t order by t.RN) loop
    begin
      -- ёр.лицо:
      nJUR_PERS := F_IMPORT7_JURPERS(0, 1, rREC.RN_ORGPU, nMAIN_JUR_PERS);
      if nJUR_PERS is null then
        nJUR_PERS := nMAIN_JUR_PERS;
      end if;
    
      p_cashdocs_base_insert(ncompany         => PKG_IMPORT7.nCOMPANY,
                             ncrn             => PKG_IMPORT7.GET_CATALOG8('CashDocuments', rREC.PARENT_RN),
                             njur_pers        => nJUR_PERS,
                             ncash_typedoc    => PKG_IMPORT7.GET_RN8(0, 1, 'DOCBASE', rREC.Rn_Doc),
                             scash_prefdoc    => rREC.RN,
                             scash_numbdoc    => rREC.Num_Doc,
                             dcash_datedoc    => rREC.Date_Doc,
                             nvalid_typedoc   => PKG_IMPORT7.GET_RN8(0, 1, 'DOCBASE', rREC.Rn_Base),
                             svalid_numbdoc   => rREC.Num_Base,
                             dvalid_datedoc   => rREC.Date_Base,
                             nagent_from      => PKG_IMPORT7.GET_RN8(0, 1, 'ORGBASE', rREC.Rn_Org_Fr),
                             nagent_to        => PKG_IMPORT7.GET_RN8(0, 1, 'ORGBASE', rREC.Rn_Org_To),
                             nbunit_mnemo     => null,
                             ntype_oper       => PKG_IMPORT7.GET_RN8(0, 1, 'OPERATE', rREC.Rn_Operate),
                             spay_info        => rREC.Note,
                             spay_note        => null,
                             npay_sum         => rREC.Summa_Itog,
                             ntax_sum         => rREC.Summa_Nds,
                             npercent_tax_sum => rREC.Nds_St,
                             ntax_sal_sum     => rREC.Summa_Nsp,
                             ncurrency        => PKG_IMPORT7.GET_RN8(0, 1, 'CURRBASE', rREC.Rn_Curr),
                             nunallotted_sum  => rREC.Summa_Itog,
                             nfin_source      => null,
                             nspecial_mark    => PKG_IMPORT7.GET_RN8(0, 1, 'MARKBASE', rREC.Rn_mark),
                             nrn              => nNEWRN);
    exception
      when OTHERS then
        PKG_IMPORT7.LOG_ERROR('CASH', rREC.Rn, nvl(ERROR_CONSTR_TEXT, ERROR_TEXT));
    end;
    PKG_IMPORT7.SET_REF('CASH', rREC.RN, nNEWRN);
    for rSPEC in (select * from P7_CASHSPEC t where t.master_rn = rREC.RN) loop
      begin
        p_cashdocspec_base_insert(ncompany          => PKG_IMPORT7.nCOMPANY,
                                  nprn              => nNEWRN,
                                  neconclass        => null,
                                  nexpstruct        => null,
                                  nbalunit          => null,
                                  npay_sum          => rSPEC.Sum_Base,
                                  nrecalculate      => 0,
                                  naccount_debit    => PKG_IMPORT7.GET_RN8(0, 1, 'ACCBASE', rSPEC.Rn_Db),
                                  nanalytic_debit1  => PKG_IMPORT7.GET_RN8(0, 1, 'ACCSPEC', rSPEC.Rn_Db_A1),
                                  nanalytic_debit2  => PKG_IMPORT7.GET_RN8(0, 1, 'ACCSPEC', rSPEC.Rn_Db_A2),
                                  nanalytic_debit3  => PKG_IMPORT7.GET_RN8(0, 1, 'ACCSPEC', rSPEC.Rn_Db_A3),
                                  nanalytic_debit4  => PKG_IMPORT7.GET_RN8(0, 1, 'ACCSPEC', rSPEC.Rn_Db_A4),
                                  nanalytic_debit5  => PKG_IMPORT7.GET_RN8(0, 1, 'ACCSPEC', rSPEC.Rn_Db_A5),
                                  naccount_credit   => PKG_IMPORT7.GET_RN8(0, 1, 'ACCBASE', rSPEC.Rn_Kr),
                                  nanalytic_credit1 => PKG_IMPORT7.GET_RN8(0, 1, 'ACCSPEC', rSPEC.Rn_Kr_A1),
                                  nanalytic_credit2 => PKG_IMPORT7.GET_RN8(0, 1, 'ACCSPEC', rSPEC.Rn_Kr_A2),
                                  nanalytic_credit3 => PKG_IMPORT7.GET_RN8(0, 1, 'ACCSPEC', rSPEC.Rn_Kr_A3),
                                  nanalytic_credit4 => PKG_IMPORT7.GET_RN8(0, 1, 'ACCSPEC', rSPEC.Rn_Kr_A4),
                                  nanalytic_credit5 => PKG_IMPORT7.GET_RN8(0, 1, 'ACCSPEC', rSPEC.Rn_Kr_A5),
                                  nfinsources       => null,
                                  nincomeclass      => PKG_IMPORT7.GET_RN8(0, 1, 'BKLSDOH', rSPEC.Kbk_Rn),
                                  nbudgcpsymb       => null,
                                  snote             => null,
                                  nrn               => nSPECRN);
      exception
        when OTHERS then
          PKG_IMPORT7.LOG_ERROR('CASHSPEC', rREC.Rn || rSPEC.RN, nvl(ERROR_CONSTR_TEXT, ERROR_TEXT));
      end;
    end loop; -- rSPEC
  end loop; -- rREC
end;
/
