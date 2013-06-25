create or replace procedure PP_GOVCNTR_HO
-- Отработка ГК в ХО
( --
 nIDENT in number --
 ) is
  sNUMB varchar2(20);
  NCRN  number; -- Каталог ХО
  oprrn number;
  ntemp number;
begin
  for a in (select t.rn, --
                   t.company,
                   a.agnabbr,
                   dt.doccode,
                   trim(t.doc_pref) || '-' || trim(t.doc_numb) snumb,
                   t.doc_date,
                   t.state,
                   t.quan_modif
              from govcntr t, selectlist s, agnlist a, doctypes dt
             where s.ident = nident
               and s.document = t.rn
               and a.rn = t.agent_supp
               and dt.rn = t.doc_types) loop
    -- Проверка на отработку
    for c in (select null
                from doclinks dl
               where dl.in_unitcode = 'GovernmentContracts'
                 and dl.in_document = a.rn
                 and dl.out_unitcode = 'EconomicOperations') loop
      p_exception(0, 'Контракт уже отработан в журнале ХО');
    end loop;
    -- Проверка на состояние
    if a.state = 0 then
      p_exception(0, 'Контракт необходимо сначала утвердить.');
    end if;
    -- Контракт создан на основании другого
    if a.quan_modif <> 0 then
      begin
        SELECT DL.IN_DOCUMENT
          INTO ntemp
          FROM DOCLINKS DL
         WHERE DL.IN_UNITCODE = 'GovernmentContracts'
           AND DL.Out_Unitcode = 'GovernmentContracts'
           AND DL.OUT_DOCUMENT = a.rn;
      exception
        when no_data_found then
          ntemp := null;
      end;
    
      if ntemp is not null then
        select count(1)
          into ntemp
          from DOCLINKS DL2
         WHERE DL2.IN_UNITCODE = 'GovernmentContracts'
           AND DL2.IN_DOCUMENT = ntemp
           AND DL2.OUT_UNITCODE = 'EconomicOperations';
        if ntemp = 0 then
          p_exception(0, 'Входящий контракт должен быть отработан в учете!');
        end if;
      end if;
    end if;
  
    for c in (select M.RN,
                     M.OPERATION_PREF, --
                     M.OPERATION_CONTENTS,
                     AGF.AGNABBR          AGENTF,
                     AC.NAME              SCATALOG,
                     JP.CODE              SJURPERS
                from MDLEOPRS M, AGNLIST AGF, ACATALOG AC, JURPERSONS JP
               where M.CODE = 'Обязательства'
                 and AGF.RN(+) = M.AGENT_FROM
                 and AC.RN = M.CRN
                 and JP.RN = M.JUR_PERS) loop
      find_acatalog_name(1, a.company, null, 'EconomicOperations', c.scatalog, ncrn);
      if ncrn is null then
        find_acatalog_name(0, a.company, null, 'EconomicOperations', 'Хозяйственные операции', ncrn);
      end if;
      P_ECONOPRS_GETNEXTNUMB(a.company, c.OPERATION_PREF, sNUMB);
      begin
        PKG_PROC_BROKER.PROLOGUE;
        PKG_PROC_BROKER.SET_PARAM_NUM('RN', NULL);
        PKG_PROC_BROKER.SET_PARAM_NUM('COMPANY', a.company);
        PKG_PROC_BROKER.SET_PARAM_NUM('CRN', ncrn);
        PKG_PROC_BROKER.SET_PARAM_STR('SJUR_PERS', c.SJURPERS);
        PKG_PROC_BROKER.SET_PARAM_STR('OPER_PREF', c.Operation_Pref);
        PKG_PROC_BROKER.SET_PARAM_STR('OPER_NUMB', sNUMB);
        PKG_PROC_BROKER.SET_PARAM_STR('OPER_CONTENTS', c.operation_contents);
        PKG_PROC_BROKER.SET_PARAM_DAT('OPER_DATE', a.doc_date);
        PKG_PROC_BROKER.SET_PARAM_STR('SPECIAL_MARK', NULL);
        PKG_PROC_BROKER.SET_PARAM_STR('VDOC_TYPE', a.doccode);
        PKG_PROC_BROKER.SET_PARAM_STR('VDOC_NUMB', a.snumb);
        PKG_PROC_BROKER.SET_PARAM_DAT('VDOC_DATE', a.doc_date);
        PKG_PROC_BROKER.SET_PARAM_STR('FDOC_TYPE', NULL);
        PKG_PROC_BROKER.SET_PARAM_STR('FDOC_NUMB', NULL);
        PKG_PROC_BROKER.SET_PARAM_DAT('FDOC_DATE', NULL);
        PKG_PROC_BROKER.SET_PARAM_STR('AGENT_FROM', c.agentf);
        PKG_PROC_BROKER.SET_PARAM_STR('AGENT_TO', a.agnabbr);
        PKG_PROC_BROKER.SET_PARAM_STR('SESCORT_DOCTYPE', NULL);
        PKG_PROC_BROKER.SET_PARAM_STR('SESCORT_DOCNUMB', NULL);
        PKG_PROC_BROKER.SET_PARAM_DAT('DESCORT_DOCDATE', NULL);
        PKG_PROC_BROKER.SET_PARAM_NUM('NEWRN');
        PKG_PROC_BROKER.EXECUTE('MODIFY_ECONOPRS', 1);
        PKG_PROC_BROKER.GET_PARAM_NUM(0, 'NEWRN', oprrn);
        PKG_PROC_BROKER.EPILOGUE;
      exception
        when others then
          PKG_PROC_BROKER.EPILOGUE;
          raise;
      end;
      ntemp := null;
      for b in (select dc.acc_number dcnumber, --
                       dd.acc_number ddnumber,
                       ec.code eccode,
                       sum(f.summ) summ
                  from MDLEOSPS   s, --
                       dicaccs    dc,
                       dicaccs    dd,
                       govcntrfin f,
                       econclass  ec
                 where s.prn = c.rn
                   and s.account_debit = dd.rn(+)
                   and s.account_credit = dc.rn(+)
                   and f.prn = a.rn
                   and f.expstruct = dc.expstruct
                   and ec.rn(+) = f.econclass
                 group by dc.acc_number, --
                          dd.acc_number,
                          ec.code
                having sum(f.summ) > 0) loop
        begin
          PKG_PROC_BROKER.PROLOGUE;
          PKG_PROC_BROKER.SET_PARAM_NUM('RN', NULL);
          PKG_PROC_BROKER.SET_PARAM_NUM('COMPANY', a.company);
          PKG_PROC_BROKER.SET_PARAM_NUM('PRN', oprrn);
          PKG_PROC_BROKER.SET_PARAM_STR('BALU_DEBIT', NULL);
          PKG_PROC_BROKER.SET_PARAM_STR('ACC_DEBIT', b.ddnumber);
          PKG_PROC_BROKER.SET_PARAM_STR('ANL1_DEBIT', NULL);
          PKG_PROC_BROKER.SET_PARAM_STR('ANL2_DEBIT', NULL);
          PKG_PROC_BROKER.SET_PARAM_STR('ANL3_DEBIT', NULL);
          PKG_PROC_BROKER.SET_PARAM_STR('ANL4_DEBIT', NULL);
          PKG_PROC_BROKER.SET_PARAM_STR('ANL5_DEBIT', b.eccode);
          PKG_PROC_BROKER.SET_PARAM_STR('BALU_CREDIT', NULL);
          PKG_PROC_BROKER.SET_PARAM_STR('ACC_CREDIT', b.dcnumber);
          PKG_PROC_BROKER.SET_PARAM_STR('ANL1_CREDIT', NULL);
          PKG_PROC_BROKER.SET_PARAM_STR('ANL2_CREDIT', NULL);
          PKG_PROC_BROKER.SET_PARAM_STR('ANL3_CREDIT', NULL);
          PKG_PROC_BROKER.SET_PARAM_STR('ANL4_CREDIT', NULL);
          PKG_PROC_BROKER.SET_PARAM_STR('ANL5_CREDIT', b.eccode);
          PKG_PROC_BROKER.SET_PARAM_STR('CURRENCY', 'RUB');
          PKG_PROC_BROKER.SET_PARAM_STR('NOMEN_CODE', NULL);
          PKG_PROC_BROKER.SET_PARAM_STR('NOMEN_PARTNO', NULL);
          PKG_PROC_BROKER.SET_PARAM_DAT('NOMEN_INDATE', NULL);
          PKG_PROC_BROKER.SET_PARAM_NUM('ACNT_SUM', b.summ);
          PKG_PROC_BROKER.SET_PARAM_NUM('ACNT_BASE_SUM', b.summ);
          PKG_PROC_BROKER.SET_PARAM_NUM('ACNT_QUANT', 0);
          PKG_PROC_BROKER.SET_PARAM_NUM('ACNT_ALT_QUANT', 0);
          PKG_PROC_BROKER.SET_PARAM_NUM('ACNT_EQUAL', NULL);
          PKG_PROC_BROKER.SET_PARAM_NUM('CTRL_SUM', b.summ);
          PKG_PROC_BROKER.SET_PARAM_NUM('CTRL_BASE_SUM', b.summ);
          PKG_PROC_BROKER.SET_PARAM_NUM('CTRL_QUANT', 0);
          PKG_PROC_BROKER.SET_PARAM_NUM('CTRL_ALT_QUANT', 0);
          PKG_PROC_BROKER.SET_PARAM_NUM('CTRL_EQUAL', NULL);
          PKG_PROC_BROKER.SET_PARAM_STR('A_SIGN1', NULL);
          PKG_PROC_BROKER.SET_PARAM_STR('A_SIGN2', NULL);
          PKG_PROC_BROKER.SET_PARAM_STR('A_SIGN3', NULL);
          PKG_PROC_BROKER.SET_PARAM_STR('A_SIGN4', NULL);
          PKG_PROC_BROKER.SET_PARAM_STR('A_SIGN5', NULL);
          PKG_PROC_BROKER.SET_PARAM_STR('A_SIGN6', NULL);
          PKG_PROC_BROKER.SET_PARAM_STR('A_SIGN7', NULL);
          PKG_PROC_BROKER.SET_PARAM_STR('A_SIGN8', NULL);
          PKG_PROC_BROKER.SET_PARAM_STR('A_SIGN9', NULL);
          PKG_PROC_BROKER.SET_PARAM_STR('A_SIGN10', NULL);
          PKG_PROC_BROKER.SET_PARAM_STR('ORDER_NUMB', NULL);
          PKG_PROC_BROKER.SET_PARAM_NUM('RECORD_TYPE', NULL);
          PKG_PROC_BROKER.SET_PARAM_NUM('NACNT_ACCTYPES_SUM', 0);
          PKG_PROC_BROKER.SET_PARAM_NUM('NCTRL_ACCTYPES_SUM', 0);
          PKG_PROC_BROKER.SET_PARAM_NUM('NINC_TO_DC', 1);
          PKG_PROC_BROKER.SET_PARAM_NUM('NEWRN');
          PKG_PROC_BROKER.EXECUTE('MODIFY_OPRSPECS', 1);
          PKG_PROC_BROKER.GET_PARAM_NUM(0, 'NEWRN', ntemp);
          PKG_PROC_BROKER.EPILOGUE;
        exception
          when others then
            PKG_PROC_BROKER.EPILOGUE;
            raise;
        end;
      end loop;
      if (ntemp is null) then
        p_exception(0, 'Не найдено подходящей по структуре расходов проводки в образце ХО "Обязательства"');
      end if;
      pkg_doclinks.LINK(0, a.company, 'GovernmentContracts', a.rn, null, a.doc_date, 0, 'EconomicOperations', oprrn, null, a.doc_date, 0, 0, 0, null);
    end loop;
  end loop;
end PP_GOVCNTR_HO;
/*create public synonym PP_GOVCNTR_HO for PP_GOVCNTR_HO;
  grant execute on PP_GOVCNTR_HO to public;*/
/
