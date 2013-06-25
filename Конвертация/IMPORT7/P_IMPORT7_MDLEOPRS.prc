create or replace procedure P_IMPORT7_MDLEOPRS
-- Импорт образцов ХО
 is
  nNEWRN         PKG_STD.tREF;
  nJUR_PERS      PKG_STD.tREF;
  nMAIN_JUR_PERS PKG_STD.tREF;
  nSPECRN        PKG_STD.tREF;
  sTMP           varchar2(20);
  nREC           number(1);
  sNUMB          MDLEOSPS.NUMB_SORT%type;
  nORDER_TYPE    MEMORDER.NUMB%TYPE;
begin
  PKG_IMPORT7.IMPORT_TABLE('DOCTYPES');
  PKG_IMPORT7.IMPORT_TABLE('AGNLIST');
  PKG_IMPORT7.IMPORT_TABLE('DICACCS');
  PKG_IMPORT7.IMPORT_TABLE('CURNAMES');
  PKG_IMPORT7.IMPORT_TABLE('DICNOMNS');
  PKG_IMPORT7.IMPORT_TABLE('MEMORDER');

  FIND_JURPERSONS_MAIN(0, PKG_IMPORT7.nCOMPANY, sTMP, nMAIN_JUR_PERS);

  for rREC in (select * from p7_m_eobase t order by rn) loop
    -- Юр.лицо:
    nJUR_PERS := F_IMPORT7_JURPERS(0, 1, rREC.RN_ORGPU, nMAIN_JUR_PERS);
    if nJUR_PERS is null then
      nJUR_PERS := nMAIN_JUR_PERS;
    end if;
    begin
      nNEWRN := null;
      p_mdleoprs_base_modify(rn                    => null,
                             company               => PKG_IMPORT7.nCOMPANY,
                             crn                   => PKG_IMPORT7.GET_CATALOG8('EconomicOperationsModels', rREC.Parent_Rn),
                             oper_pref             => rREC.Pref_Eop,
                             code                  => rREC.Rn,
                             oper_contents         => PKG_EXECUTE.FIND_UNIQUE_COLUMN_VALUE('MDLEOPRS', 'COMPANY', PKG_IMPORT7.nCOMPANY, 'OPERATION_CONTENTS', rREC.Note),
                             oper_date             => null, -- Дата учета
                             special_mark          => PKG_IMPORT7.GET_RN8(0, 1, 'MARKBASE', rREC.Rn_Mark),
                             vdoc_type             => PKG_IMPORT7.GET_RN8(0, 1, 'DOCBASE', rREC.Rn_Base),
                             vdoc_numb             => rREC.Num_Base,
                             vdoc_date             => rREC.Date_Base,
                             fdoc_type             => PKG_IMPORT7.GET_RN8(0, 1, 'DOCBASE', rREC.Rn_Doc),
                             fdoc_numb             => rREC.Num_Doc,
                             fdoc_date             => rREC.Date_Doc,
                             nescort_doctype       => PKG_IMPORT7.GET_RN8(0, 1, 'DOCBASE', rREC.Rn_Sopr),
                             sescort_docnumb       => rREC.Num_Sopr,
                             descort_docdate       => rREC.Date_Sopr,
                             agent_from            => PKG_IMPORT7.GET_RN8(0, 1, 'ORGBASE', rREC.Rn_Orgfr),
                             agent_to              => PKG_IMPORT7.GET_RN8(0, 1, 'ORGBASE', rREC.Rn_Orgto),
                             nac_sum_dropzero_sign => 0,
                             nab_sum_dropzero_sign => 0,
                             ncc_sum_dropzero_sign => 0,
                             ncb_sum_dropzero_sign => 0,
                             nam_qnt_dropzero_sign => 0,
                             naa_qnt_dropzero_sign => 0,
                             ncm_qnt_dropzero_sign => 0,
                             nca_qnt_dropzero_sign => 0,
                             njur_pers             => nJUR_PERS,
                             newrn                 => nNEWRN);
      PKG_IMPORT7.SET_REF('MDLEOPRS', rREC.RN, nNEWRN);
    exception
      when OTHERS then
        PKG_IMPORT7.LOG_ERROR('MDLEOPRS', rREC.RN);
    end;
    for rSPEC in (select *
                    from P7_m_Eospec t
                   where t.master_rn = rREC.Rn
                     and nNEWRN is not null
                   order by RN) loop
      P_MDLEOSPS_GETNEXTNUMB(PKG_IMPORT7.nCOMPANY, nNEWRN, sNUMB);
      -- Определяю номер записи:
      begin
        select NUMB into nORDER_TYPE from MEMORDER where RN = PKG_IMPORT7.GET_RN8(0, 1, 'ORDBASE', rSPEC.RN_MO);
      exception
        when no_data_found then
          nORDER_TYPE := null;
      end;
      if rSPEC.rn_mo is null then
        nREC := null;
      else
        if (nORDER_TYPE in (1, 2, 3, 5, 6, 7, 8, 15)) then
          nREC := 2;
        else
          nREC := 1;
        end if;
      end if;
      -- Добавляю:
      begin
        p_mdleosps_base_insert(ncompany          => PKG_IMPORT7.nCOMPANY,
                               nprn              => nNEWRN,
                               nbalunit_debit    => null,
                               naccount_debit    => PKG_IMPORT7.GET_RN8(0, 1, 'ACCBASE', rSPEC.Rn_Db),
                               nanalytic_debit1  => PKG_IMPORT7.GET_RN8(0, 1, 'ACCSPEC', rSPEC.Rn_Db_A1),
                               nanalytic_debit2  => PKG_IMPORT7.GET_RN8(0, 1, 'ACCSPEC', rSPEC.Rn_Db_A2),
                               nanalytic_debit3  => PKG_IMPORT7.GET_RN8(0, 1, 'ACCSPEC', rSPEC.Rn_Db_A3),
                               nanalytic_debit4  => PKG_IMPORT7.GET_RN8(0, 1, 'ACCSPEC', rSPEC.Rn_Db_A4),
                               nanalytic_debit5  => PKG_IMPORT7.GET_RN8(0, 1, 'ACCSPEC', rSPEC.Rn_Db_A5),
                               nbalunit_credit   => null,
                               naccount_credit   => PKG_IMPORT7.GET_RN8(0, 1, 'ACCBASE', rSPEC.Rn_Kr),
                               nanalytic_credit1 => PKG_IMPORT7.GET_RN8(0, 1, 'ACCSPEC', rSPEC.Rn_Kr_A1),
                               nanalytic_credit2 => PKG_IMPORT7.GET_RN8(0, 1, 'ACCSPEC', rSPEC.Rn_Kr_A2),
                               nanalytic_credit3 => PKG_IMPORT7.GET_RN8(0, 1, 'ACCSPEC', rSPEC.Rn_Kr_A3),
                               nanalytic_credit4 => PKG_IMPORT7.GET_RN8(0, 1, 'ACCSPEC', rSPEC.Rn_Kr_A4),
                               nanalytic_credit5 => PKG_IMPORT7.GET_RN8(0, 1, 'ACCSPEC', rSPEC.Rn_Kr_A5),
                               ncurrency         => PKG_IMPORT7.GET_RN8(0, 1, 'CURRBASE', rSPEC.Rn_Curr),
                               nnomenclature     => PKG_IMPORT7.GET_RN8(0, 1, 'NOBASE', rSPEC.Rn_Numcl),
                               sformula_sum      => rSPEC.Formula,
                               sformula_quant    => rSPEC.Form_Count,
                               salt_sign1        => null,
                               salt_sign2        => null,
                               salt_sign3        => null,
                               salt_sign4        => null,
                               salt_sign5        => null,
                               salt_sign6        => null,
                               salt_sign7        => null,
                               salt_sign8        => null,
                               salt_sign9        => null,
                               salt_sign10       => null,
                               nmemorder         => PKG_IMPORT7.GET_RN8(0, 1, 'ORDBASE', rSPEC.RN_MO),
                               nrec_number       => nREC,
                               ntotal_eo         => 0,
                               snumb_sort        => sNUMB,
                               nrn               => nSPECRN);
        PKG_IMPORT7.SET_REF('MDLEOSPS', rSPEC.RN, nSPECRN);
      exception
        when OTHERS then
          PKG_IMPORT7.LOG_ERROR('MDLEOSPS', rSPEC.RN);
      end;
    end loop; -- rSPEC
  end loop; -- rREC
end P_IMPORT7_MDLEOPRS;
/
