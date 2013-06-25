CREATE OR REPLACE PROCEDURE "PRS_SLTRANSFERS_TO_SBER"
--
(nCOMPANY in number,
 nIDENT   in number, -- IDENT отмеченных перечислений
 nRN      in number, -- RN перечисления
 sSESSION out varchar2 -- ID сессии
 ) as
  cCLOB       CLOB;
  sFNAME      varchar2(13) := 'C:\parus.tab';
  nCLOB_IDENT PKG_STD.tREF; -- вывод строки в CLOB

  procedure println(tmp_sVALUE in varchar2) is
    tmp_nTMP1 number;
    tmp_nLEN  number;
    tmp_sTMP1 varchar2(300);
  begin
    tmp_nLEN  := length(tmp_sVALUE);
    tmp_nTMP1 := 1;
    loop
      if tmp_nTMP1 > tmp_nLEN then
        exit;
      end if;
      tmp_sTMP1 := substr(tmp_sVALUE, tmp_nTMP1, 300);
      tmp_sTMP1 := replace(tmp_sTMP1, Chr(10), '');
      tmp_sTMP1 := replace(tmp_sTMP1, Chr(13), '');
      dbms_lob.writeappend(cCLOB, length(tmp_sTMP1), convert(tmp_sTMP1, 'RU8PC866'));
      tmp_nTMP1 := tmp_nTMP1 + 300;
    end loop;
    dbms_lob.writeappend(cCLOB, 2, Chr(13) || Chr(10));
  end;

begin
  -- создание буфера вывода
  DBMS_LOB.CREATETEMPORARY(cCLOB, TRUE, DBMS_LOB.CALL);
  nCLOB_IDENT := gen_ident;
  sSESSION    := PKG_SESSION.GET_USID;
  for i_rec in (select TRIM(upper(substr(nvl(ACC.AGNACC, ''), 1, 20))) AGNACC,
                       SLT.TRANSFSUMM,
                       substr(TRIM(AL.AGNFAMILYNAME) || ' ' || TRIM(AL.AGNFIRSTNAME) || ' ' || TRIM(AL.AGNLASTNAME), 1, 40) AGNFIO,
                       TRIM(AL.PASSPORT_SER) || ' ' || TRIM(AL.PASSPORT_NUMB) PASSPORT_NUMB
                  from SLTRANSFERS SLT
                  join AGNACC ACC on ACC.RN = SLT.BANKATTRS
                  join AGNLIST AL on AL.RN = SLT.RECIPIENT
                  join JURPERSONS JP on JP.RN = SLT.JURPERSONS
                 where SLT.COMPANY = nCOMPANY
                   and ((nIDENT is not null) and (SLT.RN in (select DOCUMENT from SELECTLIST SL where SL.IDENT = nIDENT)))
                    or ((nRN is not null) and (SLT.RN = nRN))
                 order by AL.AGNFAMILYNAME, AL.AGNFIRSTNAME, AL.AGNLASTNAME) loop
    insert into TRS_SLTRANSFERS_SBER
      (P_A_NUMBER, SUMMA, FIO, PASSPORT, KOD, C_E_DATE, SSESSION)
    values
      (i_rec.AGNACC, i_rec.TRANSFSUMM, i_rec.AGNFIO, i_rec.PASSPORT_NUMB, 0, null, sSESSION);
    commit;
    println(i_rec.AGNACC);
  end loop;
  insert into FILE_BUFFER (IDENT, FILENAME, DATA) values (nCLOB_IDENT, sFNAME, cCLOB);
  DBMS_LOB.TRIM(cCLOB, 0);
end PRS_SLTRANSFERS_TO_SBER;
/
