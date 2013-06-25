create or replace procedure PP_SBER_CARD_XML_T
-- Добавление сотрудников в раздел "Выгрузка заявок на открытие карт в Сбербанк"
-- Вызывается из раздела "Сотрудники"
(nIDENT   in number,
 nCOMPANY in number,
 sCONTROL in varchar2,
 sCATALOG in varchar2,
 nCardType in number --
 ) is
  psCONTROL varchar2(4000) := sCONTROL;
  nCRN      number;
  nPCRN     number;
begin
  psCONTROL := replace(psCONTROL, chr(13) || chr(10), ';');
  psCONTROL := replace(psCONTROL, chr(13), ';');
  psCONTROL := replace(psCONTROL, chr(10), ';');
  psCONTROL := upper(psCONTROL);
  find_acatalog_name(1, null, null, 'SberXML', sCATALOG, nCRN);
  if nCRN is null then
    find_acatalog_name(1, null, null, 'SberXML', 'Выгрузка заявок в Сбербанк (XML)', nPCRN);
    P_ACATALOG_INSERT(nCOMPANY, nPCRN, sCATALOG, nCRN);
  end if;
  insert into TP_SBER_CARD_XML
    (rn,
     crn,
     agnfamilyname, --
     agnfirstname,
     agnlastname,
     docser,
     docnumb,
     docwhen,
     docwho,
     depart_code,
     agnburn,
     ssex,
     addr_burn,
     a1,
     a2,
     a3,
     a4,
     a5,
     a6,
     a7,
     a8,
     a9,
     a10,
     a11,
     a12,
     o1,
     o2,
     o3,
     o4,
     o5,
     o6,
     o7,
     o8,
     o9,
     o10,
     o11,
     o12,
     phone,
     emb_1,
     emb_2,
     emb_3,
     control,
     card_type)
    select a.rn,
           nCRN,
           substr(upper(a.agnfamilyname), 1, 60) agnfamilyname, --
           substr(upper(a.agnfirstname), 1, 30) agnfirstname,
           substr(upper(a.agnlastname), 1, 30) agnlastname,
           substr(upper(trim(a.docser)), 1, 14) docser,
           substr(upper(trim(a.docnumb)), 1, 14) docnumb,
           to_char(a.docwhen, 'yyyy-mm-dd') docwhen,
           substr(upper(trim(a.docwho)), 1, 250) docwho,
           substr(trim(a.depart_code), 1, 10) depart_code,
           to_char(a.agnburn, 'yyyy-mm-dd') agnburn,
           decode(a.sex, 1, 'М', 'Ж') ssex,
           substr(upper(trim(a.addr_burn)), 1, 200) addr_burn,
           a.a1,
           a.a2,
           a.a3,
           a.a4,
           a.a5,
           a.a6,
           a.a7,
           a.a8,
           a.a9,
           a.a10,
           substr(a.a11, 1, 5) a11,
           a.a12,
           a.o1,
           a.o2,
           a.o3,
           a.o4,
           a.o5,
           a.o6,
           a.o7,
           a.o8,
           a.o9,
           a.o10,
           substr(a.o11, 1, 5) o11,
           a.o12,
           null phone,
           FP_LATIN(a.agnfirstname) emb_1,
           FP_LATIN(a.agnfamilyname) emb_2,
           null emb_3,
           trim(strtok(psCONTROL, ';', a.nrow)) control,
           nCardType
      from (select cp.rn,
                   ag.agnfamilyname, --
                   ag.agnfirstname,
                   ag.agnlastname,
                   ag.agnburn,
                   ag.sex,
                   ad.docser,
                   ad.docnumb,
                   ad.docwhen,
                   ad.docwho,
                   ag.phone,
                   -- Адрес сотрудника:
                   FP_AGNADDRESSES_GET_STR(cp.pers_agent, 0, 'P') a1,
                   FP_AGNADDRESSES_GET_STR(cp.pers_agent, 0, 'R') a2,
                   FP_AGNADDRESSES_GET_STR(cp.pers_agent, 0, 'r') a3,
                   FP_AGNADDRESSES_GET_STR(cp.pers_agent, 0, 'D') a4,
                   FP_AGNADDRESSES_GET_STR(cp.pers_agent, 0, 'd') a5,
                   nvl(FP_AGNADDRESSES_GET_STR(cp.pers_agent, 0, 'Y'), FP_AGNADDRESSES_GET_STR(cp.pers_agent, 0, 'T')) a6,
                   nvl(FP_AGNADDRESSES_GET_STR(cp.pers_agent, 0, 'y'), FP_AGNADDRESSES_GET_STR(cp.pers_agent, 0, 't')) a7,
                   FP_AGNADDRESSES_GET_STR(cp.pers_agent, 0, 'S') a8,
                   FP_AGNADDRESSES_GET_STR(cp.pers_agent, 0, 's') a9,
                   FP_AGNADDRESSES_GET_STR(cp.pers_agent, 0, 'H') a10,
                   FP_AGNADDRESSES_GET_STR(cp.pers_agent, 0, 'B') a11,
                   FP_AGNADDRESSES_GET_STR(cp.pers_agent, 0, 'F') a12,
                   -- Адрес работодателя:
                   FP_AGNADDRESSES_GET_STR(cp.owner_agent, 0, 'P') o1,
                   FP_AGNADDRESSES_GET_STR(cp.owner_agent, 0, 'R') o2,
                   FP_AGNADDRESSES_GET_STR(cp.owner_agent, 0, 'r') o3,
                   FP_AGNADDRESSES_GET_STR(cp.owner_agent, 0, 'D') o4,
                   FP_AGNADDRESSES_GET_STR(cp.owner_agent, 0, 'd') o5,
                   nvl(FP_AGNADDRESSES_GET_STR(cp.owner_agent, 0, 'Y'), FP_AGNADDRESSES_GET_STR(cp.owner_agent, 0, 'T')) o6,
                   nvl(FP_AGNADDRESSES_GET_STR(cp.owner_agent, 0, 'y'), FP_AGNADDRESSES_GET_STR(cp.owner_agent, 0, 't')) o7,
                   FP_AGNADDRESSES_GET_STR(cp.owner_agent, 0, 'S') o8,
                   FP_AGNADDRESSES_GET_STR(cp.owner_agent, 0, 's') o9,
                   FP_AGNADDRESSES_GET_STR(cp.owner_agent, 0, 'H') o10,
                   FP_AGNADDRESSES_GET_STR(cp.owner_agent, 0, 'B') o11,
                   FP_AGNADDRESSES_GET_STR(cp.owner_agent, 0, 'F') o12,
                   ag.addr_burn,
                   ag.mail,
                   ad.depart_code,
                   count(1) over() ncount,
                   row_number() over(order by ag.agnfamilyname, ag.agnfirstname, ag.agnlastname) nrow
              from clnpersons cp,
                   agnlist ag,
                   (select t.prn, --
                           t.docser,
                           t.docnumb,
                           t.docwhen,
                           t.docwho,
                           t.depart_code
                      from agndocums t
                     where t.default_sign = 1) ad,
                   selectlist sel
             where ag.rn = cp.pers_agent
               and ad.prn(+) = cp.pers_agent
               and sel.document = cp.rn
               and sel.ident = nIDENT
               and not exists (select null from TP_SBER_CARD_XML a where a.rn = cp.rn)
             order by ag.agnfamilyname, ag.agnfirstname, ag.agnlastname) a
     order by nrow;
end PP_SBER_CARD_XML_T;
/*create public synonym PP_SBER_CARD_XML_T for PP_SBER_CARD_XML_T;
  grant execute on PP_SBER_CARD_XML_T to public;*/
/
