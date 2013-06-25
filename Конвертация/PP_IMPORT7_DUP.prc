create or replace procedure PP_IMPORT7_DUP
--
(sCAPT in varchar2) is
  sNEWAGNABBR AGNLIST.AGNABBR%type;
  sNEWDEP     INS_DEPARTMENT.CODE%type;
begin

  PP_IMPORT7_CRN(sCAPT, 'Organizations');
  PP_IMPORT7_CRN(sCAPT, 'zTaxRepCfg');
  PP_IMPORT7_CRN(sCAPT, 'zEmployee');
  pp_IMPORT7_CRN(sCAPT, 'zDolGroup');
  pp_import7_crn(sCAPT, 'zKatPer');
  pp_import7_crn(sCAPT, 'zFaceAcc');
  PP_IMPORT7_CRN(sCAPT, 'zSostZat');
  pp_import7_crn(sCAPT, 'zKatFzp');
  PP_IMPORT7_CRN(sCAPT, 'zSubDivision');
  PP_IMPORT7_CRN(sCAPT, 'EconOp');

  update P7_ZPOST t set t.post_prefi = sCAPT || t.post_prefi;
  update p7_zank t set t.tab_prefix = sCAPT || t.tab_prefix;
  update p7_zfcac t set t.fcac_prefi = sCAPT || t.fcac_prefi;

  -- Исключаем совпадение контрагентов уже существующих в базе и загружаемых:
  for c in (select o.rn, o.rmnemo_org
              from p7_orgbase o, agnlist a
             where o.rmnemo_org = a.agnabbr) loop
    sNEWAGNABBR := PKG_EXECUTE.FIND_UNIQUE_COLUMN_VALUE('AGNLIST',
                                                        '',
                                                        '',
                                                        'AGNABBR',
                                                        c.rmnemo_org);
    for cc in (select null
                 from p7_orgbase t
                where t.rmnemo_org = sNEWAGNABBR) loop
      p_exception(0, 'Уже есть ' || sNEWAGNABBR);
    end loop;
    update p7_orgbase o set o.rmnemo_org = sNEWAGNABBR where o.rn = c.rn;
  end loop;
 
  -- То же самое с подразделениями:
  for c in (select o.subdiv_rn, o.code
              from P7_ZSUBDIV o, ins_department a
             where o.code = a.code) loop
    sNEWDEP := PKG_EXECUTE.FIND_UNIQUE_COLUMN_VALUE('INS_DEPARTMENT',
                                                    '',
                                                    '',
                                                    'CODE',
                                                    c.code);
    for cc in (select null from P7_ZSUBDIV t where t.code = sNEWDEP) loop
      p_exception(0, 'Уже есть ' || sNEWDEP);
    end loop;
    update P7_ZSUBDIV o
       set o.code = sNEWDEP
     where o.subdiv_rn = c.subdiv_rn;
  end loop;

  -- И с составами затрат:
  for c in (select o.sostzat_rn, o.code
              from P7_ZSOSTZAT o, slcosts a
             where o.code = a.code) loop
    sNEWDEP := PKG_EXECUTE.FIND_UNIQUE_COLUMN_VALUE('SLCOSTS',
                                                    '',
                                                    '',
                                                    'CODE',
                                                    c.code);
    for cc in (select null from P7_ZSOSTZAT t where t.code = sNEWDEP) loop
      p_exception(0, 'Уже есть ' || sNEWDEP);
    end loop;
    update P7_ZSOSTZAT o
       set o.code = sNEWDEP
     where o.sostzat_rn = c.sostzat_rn;
  end loop;

  P_IMPORT7_CLNPSPFMGS;
  P_IMPORT7_CLNPSPFMWD;
  p_import7_agndocums;
  p_import7_agnaddresses;
  p_import7_agneduc;
  p_import7_agnlangs;
  p_import7_agnranks;
  p_import7_agnrelative;
  p_import7_slpays;

  PKG_IMPORT7.IMPORT_TABLE('ECONOPRS');

end PP_IMPORT7_DUP;
/
