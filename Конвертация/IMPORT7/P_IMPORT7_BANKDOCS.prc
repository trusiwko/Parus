create or replace procedure P_IMPORT7_BANKDOCS
-- Импорт банковских документов
 as
  nNEWRN            PKG_STD.tREF;
  nJUR_PERS         PKG_STD.tREF;
  nMAIN_JUR_PERS    PKG_STD.tREF;
  sTMP              PKG_STD.tSTRING;
  nDEFAULT_TYPEOPER PKG_STD.tREF;
  nDEFAULT_CURRENCY PKG_STD.tREF;
  nTOACC            PKG_STD.tREF;
  nTO               PKG_STD.tREF;
  nFROMACC          PKG_STD.tREF;
  nFROM             PKG_STD.tREF;
begin
  PKG_IMPORT7.IMPORT_TABLE('DOCTYPES');
  PKG_IMPORT7.IMPORT_TABLE('AGNLIST');
  PKG_IMPORT7.IMPORT_TABLE('DICTOPER');
  PKG_IMPORT7.IMPORT_TABLE('TRANSREASON');
  PKG_IMPORT7.IMPORT_TABLE('TRANSTYPE');

  select min(rn) into nDEFAULT_TYPEOPER from DICTOPER t where t.typoper_direct = 1;
  find_currency_base(PKG_IMPORT7.nCOMPANY, nDEFAULT_CURRENCY);

  FIND_JURPERSONS_MAIN(0, PKG_IMPORT7.nCOMPANY, sTMP, nMAIN_JUR_PERS);
  for rREC in (select t.*, --
                      decode(t.APP_PAY, 1, 'почтой', 2, 'телеграфом', 3, 'электронно', 4, 'клиринг', 5, 'срочным телеграфом', 6, 'срочно') spaytype,
                      s.rn ntaxstate
                 from P7_BANK t, TAXPAYERSTATUS s
                where t.taxstate = s.code(+)
                order by t.RN) loop
    begin
      -- Юр.лицо:
      nJUR_PERS := F_IMPORT7_JURPERS(0, 1, rREC.RN_ORGPU, nMAIN_JUR_PERS);
      if nJUR_PERS is null then
        nJUR_PERS := nMAIN_JUR_PERS;
      end if;
      -- Случай, когда не указаны реквизиты:
      nTO := PKG_IMPORT7.GET_RN8(0, 1, 'ORGBASE', rREC.Rn_Org_To);
      if rREC.Rn_Rek_To is not null then
        nTOACC := PKG_IMPORT7.GET_RN8(0, 1, 'BANKACC', rREC.Rn_Org_To || rREC.Rn_Rek_To);
      else
        nTOACC := null;
      end if;
      nFROM := PKG_IMPORT7.GET_RN8(0, 1, 'ORGBASE', rREC.Rn_Org_Fr);
      if rREC.Rn_Rek_Fr is not null then
        nFROMACC := PKG_IMPORT7.GET_RN8(0, 1, 'BANKACC', rREC.Rn_Org_Fr || rREC.Rn_Rek_Fr);
      else
        nFROMACC := null;
      end if;
      if (nTOACC is null) and (nTO is not null) then
        select min(rn) into nTOACC from AGNACC t where t.agnrn = nTO;
        if nTOACC is null then
          p_agnacc_base_insert(ncompany      => PKG_IMPORT7.nCOMPANY,
                               nprn          => nTO,
                               sstrcode      => '0001',
                               sagnacc       => null,
                               sagnnameacc   => '0001',
                               sbanknameacc  => null,
                               sbankfcodeacc => null,
                               sbankacc      => null,
                               sbankcityacc  => null,
                               nagnbanks     => null,
                               dopen_date    => null,
                               dclose_date   => null,
                               scountry_code => null,
                               naccess_flag  => 1,
                               sswift        => null,
                               sregion       => null,
                               sdistrict     => null,
                               nbankacc_type => null,
                               ncurrency     => null,
                               ncorr_agnacc  => null,
                               scardnumb     => null,
                               nagntreas     => null,
                               ntreas_agnacc => null,
                               nintermediary => null,
                               nintermed_acc => null,
                               nrn           => nTOACC);
        end if;
      end if;
    
      if (nFROMACC is null) and (nFROM is not null) then
        select min(rn) into nFROMACC from AGNACC t where t.agnrn = nFROM;
        if nFROMACC is null then
          p_agnacc_base_insert(ncompany      => PKG_IMPORT7.nCOMPANY,
                               nprn          => nFROM,
                               sstrcode      => '0001',
                               sagnacc       => null,
                               sagnnameacc   => '0001',
                               sbanknameacc  => null,
                               sbankfcodeacc => null,
                               sbankacc      => null,
                               sbankcityacc  => null,
                               nagnbanks     => null,
                               dopen_date    => null,
                               dclose_date   => null,
                               scountry_code => null,
                               naccess_flag  => 1,
                               sswift        => null,
                               sregion       => null,
                               sdistrict     => null,
                               nbankacc_type => null,
                               ncurrency     => null,
                               ncorr_agnacc  => null,
                               scardnumb     => null,
                               nagntreas     => null,
                               ntreas_agnacc => null,
                               nintermediary => null,
                               nintermed_acc => null,
                               nrn           => nFROMACC);
        end if;
      end if;
    
      p_bankdocs_base_insert(ncompany         => PKG_IMPORT7.nCOMPANY,
                             ncrn             => PKG_IMPORT7.GET_CATALOG8('BankDocuments', rREC.PARENT_RN),
                             nbank_typedoc    => PKG_IMPORT7.GET_RN8(0, 1, 'DOCBASE', rREC.Rn_Doc),
                             sbank_prefdoc    => rREC.RN,
                             sbank_numbdoc    => rREC.Num_Doc,
                             dbank_datedoc    => rREC.Date_Doc,
                             nvalid_typedoc   => PKG_IMPORT7.GET_RN8(0, 1, 'DOCBASE', rREC.Rn_Base),
                             svalid_numbdoc   => rREC.Num_Base,
                             dvalid_datedoc   => rREC.Date_Base,
                             sfrom_numb       => null, -- документ плательщика
                             dfrom_date       => null,
                             nagent_from      => nFROM,
                             nagentf_acc      => nFROMACC,
                             nagent_to        => nTO,
                             nagentt_acc      => nTOACC,
                             nbunit_mnemo     => null, -- ПБЕ
                             ntype_oper       => nvl(PKG_IMPORT7.GET_RN8(0, 1, 'OPERATE', rREC.Rn_Operate), nDEFAULT_TYPEOPER), -- вид операции
                             spay_seq         => rREC.Turn_Pay,
                             dpay_data        => nvl(rREC.Date_r_Pay, rREC.Date_Pay), -- дата оплаты
                             spay_info        => rREC.Note,
                             spay_note        => rREC.Note_2,
                             npay_sum         => rREC.Summa_Doc,
                             ntax_sum         => rREC.Summa_Nds,
                             npercent_tax_sum => rREC.St_Nds,
                             ncurrency        => nvl(PKG_IMPORT7.GET_RN8(0, 1, 'CURRBASE', rREC.Rn_Curr), nDEFAULT_CURRENCY),
                             spay_type        => rREC.spaytype, -- вид платежа
                             spay_kind        => null, -- вид оплаты
                             njur_pers        => nJUR_PERS,
                             nincomeclass     => PKG_IMPORT7.GET_RN8(0, 1, 'BKLSDOH', rREC.kbk_rn),
                             nfin_source      => null,
                             ntransreason     => PKG_IMPORT7.GET_RN8(0, 1, 'COMDICBS', rREC.Rn_Pay),
                             stransperiod     => rREC.Date_Trans,
                             stransnumber     => rREC.Num_Pay,
                             dtransdate       => rREC.Date_b_Pay,
                             ntranstype       => PKG_IMPORT7.GET_RN8(0, 1, 'COMDICBS', rREC.Rn_Trans),
                             nunallotted_sum  => 0, -- нераспределенная сумма
                             ntaxpstatus      => rREC.ntaxstate,
                             nspecial_mark    => PKG_IMPORT7.GET_RN8(0, 1, 'MARKBASE', rREC.Rn_mark),
                             nis_advance      => rREC.l_Avans,
                             nokato           => null,
                             sreason_code     => null,
                             nrn              => nNEWRN);
    exception
      when OTHERS then
        PKG_IMPORT7.LOG_ERROR('BANK', rREC.Rn, nvl(ERROR_CONSTR_TEXT, ERROR_TEXT));
    end;
    PKG_IMPORT7.SET_REF('BANK', rREC.RN, nNEWRN);
  end loop; -- rREC
end;
/
