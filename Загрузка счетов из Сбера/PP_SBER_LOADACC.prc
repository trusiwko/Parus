create or replace procedure PP_SBER_LOADACC
-- Загрузка открытых счетов Сбербанка
(NLOAD in number,
 SFILE in varchar2,
 SOUT  out varchar2 --
 ) is
  -- Список загруженных сотрудников Excel
  cursor a(nLoad in number, sFileName in varchar2) is
    select t.d7 sagnacc, s.rn, t.d2 || ' ' || t.d3 || ' ' || t.d4 sfio
      from (select t.d2, t.d3, t.d4, t.d5, ltrim(t.d6, '0') d6, t.d7, t.n
              from t_s_excel t
             where t.n > 1
               and t.authid = user
               and (nLoad is null or nLoad = t.n)
               and (sFile is null or sFileName = t.sfile)
               and t.d2 is not null) t,
           (select s.rn,
                   s.agnfamilyname,
                   s.agnfirstname,
                   s.agnlastname,
                   s.docser,
                   ltrim(s.docnumb, '0') docnumb
              from tp_sber_card_xml s) s
     where t.d2 = s.agnfamilyname(+)
       and t.d3 = s.agnfirstname(+)
       and t.d4 = s.agnlastname(+)
       and t.d5 = s.docser(+)
       and t.d6 = s.docnumb(+)
     order by n;
  strcode agnacc.strcode%type;
  agnname agnlist.agnname%type;
  nAGNACC number;
begin
  for c in a(nLoad, sFile) loop
    if c.rn is null then
      sout := sout || 'Не найден сотрудник "' || c.sfio ||
              '" в разделе "Выгрузка заявок в Сбербанк (XML)"' || chr(10);
    end if;
    for c2 in (select cp.company, cp.pers_agent, b.*
                 from clnpersons cp,
                      (select A.AGNNAME,
                              B.BANKFCODEACC,
                              B.BANKACC,
                              B.SWIFT,
                              a.agnabbr
                         from AGNBANKS B, AGNLIST A
                        where B.AGNRN = A.RN
                          and A.AGNABBR = 'СБЕРБАНК') b
                where cp.rn = c.rn) loop
      begin
        select ac.rn
          into nAGNACC
          from agnacc ac
         where ac.agnrn = c2.pers_agent
           and ac.agnacc = c.sagnacc;
      exception
        when no_data_found then
          nAGNACC := null;
      end;
      if nAGNACC is null then
        FIND_AGNACC_LASTCODE(c2.company, c2.pers_agent, strcode, agnname);
        if strcode is null then
          strcode := '0001';
        else
          pkg_document.NEXT_NUMBER(strcode, 10, strcode);
        end if;
        begin
          PKG_PROC_BROKER.PROLOGUE;
          PKG_PROC_BROKER.SET_PARAM_NUM('NCOMPANY', c2.company);
          PKG_PROC_BROKER.SET_PARAM_NUM('NPRN', c2.pers_agent);
          PKG_PROC_BROKER.SET_PARAM_STR('SSTRCODE', strcode);
          PKG_PROC_BROKER.SET_PARAM_STR('SAGNACC', c.sagnacc);
          PKG_PROC_BROKER.SET_PARAM_STR('SAGNNAMEACC', agnname);
          PKG_PROC_BROKER.SET_PARAM_STR('SBANKNAMEACC', c2.agnname);
          PKG_PROC_BROKER.SET_PARAM_STR('SBANKFCODEACC', c2.bankfcodeacc);
          PKG_PROC_BROKER.SET_PARAM_STR('SBANKACC', c2.bankacc);
          PKG_PROC_BROKER.SET_PARAM_STR('SBANKCITYACC', c2.swift);
          PKG_PROC_BROKER.SET_PARAM_STR('SAGNBANKS', c2.agnabbr);
          PKG_PROC_BROKER.SET_PARAM_DAT('DOPEN_DATE', NULL);
          PKG_PROC_BROKER.SET_PARAM_DAT('DCLOSE_DATE', NULL);
          PKG_PROC_BROKER.SET_PARAM_STR('SCOUNTRY_CODE', NULL);
          PKG_PROC_BROKER.SET_PARAM_NUM('NACCESS_FLAG', 1);
          PKG_PROC_BROKER.SET_PARAM_STR('SSWIFT', NULL);
          PKG_PROC_BROKER.SET_PARAM_STR('SREGION', NULL);
          PKG_PROC_BROKER.SET_PARAM_STR('SDISTRICT', NULL);
          PKG_PROC_BROKER.SET_PARAM_STR('SBANKACC_TYPE', NULL);
          PKG_PROC_BROKER.SET_PARAM_STR('SCURRENCY', 'RUB');
          PKG_PROC_BROKER.SET_PARAM_STR('SCORR_AGNACC', '0001');
          PKG_PROC_BROKER.SET_PARAM_STR('SCARDNUMB', NULL);
          PKG_PROC_BROKER.SET_PARAM_STR('SAGNTREAS', NULL);
          PKG_PROC_BROKER.SET_PARAM_STR('STREAS_AGNACC', NULL);
          PKG_PROC_BROKER.SET_PARAM_STR('SINTERMEDIARY', NULL);
          PKG_PROC_BROKER.SET_PARAM_STR('SINTERMED_ACC', NULL);
          PKG_PROC_BROKER.SET_PARAM_NUM('NRN');
          PKG_PROC_BROKER.EXECUTE('P_AGNACC_INSERT', 1);
          PKG_PROC_BROKER.GET_PARAM_NUM(0, 'NRN', nAGNACC);
          PKG_PROC_BROKER.EPILOGUE;
        exception
          when others then
            PKG_PROC_BROKER.EPILOGUE;
            raise;
        end;
        -- Проставим реквизиты: 
        update clnpersons cp
           set cp.trn_agent = cp.pers_agent, cp.trn_agent_acc = nAGNACC
         where cp.rn = c.rn;
        sout := sout || '"' || c.sfio || '" загружен, реквизиты "' ||
                strcode || '" проставлены' || chr(10);
      else
        sout := sout || 'Счет с номером "' || c.sagnacc || '" уже есть.' ||
                chr(10);
      end if;
    end loop;
  end loop;
end PP_SBER_LOADACC;
/*create public synonym PP_SBER_LOADACC for PP_SBER_LOADACC;
  grant execute on PP_SBER_LOADACC to public;*/
/
