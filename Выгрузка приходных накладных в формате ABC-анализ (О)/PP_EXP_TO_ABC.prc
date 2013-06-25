create or replace procedure PP_EXP_TO_ABC
--
(nIDENT out number,
 dFROM  in date,
 dTILL  in date,
 nMODE  in number
 --
 ) is
  xDOC       dbms_xmldom.DOMDocument;
  xTMPNODE   dbms_xmldom.DOMNode;
  xIMPORTDOC dbms_xmldom.DOMNode;
  xSOSTAV    dbms_xmldom.DOMNode;
  xSTR       dbms_xmldom.DOMNode;
  xROOT      dbms_xmldom.DOMNode;
  cDATA      clob;
  sFILENAME  varchar2(20);
  iROW       number;

  cursor a(dFROM in date, dTILL in date, nXML in number) is
    select prsf_prop_nget(dn.version, 'Nomenclator', dn.rn, 'Код ИМЦ') ncode, --
           prsf_prop_sget(dn.version, 'Nomenclator', dn.rn, 'Признак ЖНВЛС') sven,
           row_number() over(partition by a.gtd order by a.rn) nrow,
           dn.nomen_code,
           a.quant,
           a.summtax,
           a.price,
           a.gtd,
           decode(prsf_prop_nget(dn.version, 'Nomenclator', dn.rn, 'Код ИМЦ'), null, 'Нет', decode(prsf_prop_sget(dn.version, 'Nomenclator', dn.rn, 'Признак ЖНВЛС'), null, 'Нет', 'Да')) sXML
      from (select max(ivs.rn) rn, --
                   sum(ivs.quant) quant,
                   sum(ivs.summtax) summtax,
                   ivs.price,
                   ivs.gtd,
                   ivs.nomen
              from ininvoices      iv, --
                   ininvoicesspecs ivs
             where ivs.prn = iv.rn
               and iv.doc_date between dFROM and dTILL
             group by ivs.price, --
                      ivs.gtd,
                      ivs.nomen) a,
           dicnomns dn
     where dn.rn = a.nomen
       and (nXML = 0 or prsf_prop_nget(dn.version, 'Nomenclator', dn.rn, 'Код ИМЦ') is not null)
     order by a.gtd, a.rn;

  procedure AddIMPORTDOC(dFROM in date, dTILL in date, sTF in varchar2) is
  begin
    xIMPORTDOC := dbms_xmldom.makeNode(dbms_xmldom.createElement(xDOC, 'importdoc'));
    xTMPNODE   := dbms_xmldom.appendChild(xROOT, xIMPORTDOC);
    xTMPNODE   := PKG_XML_UNL.ADD_XML_NODE(xDOC, xIMPORTDOC, 'datebegin', to_char(dFROM, 'yyyy-mm-dd') || 'T12:00:00');
    xTMPNODE   := PKG_XML_UNL.ADD_XML_NODE(xDOC, xIMPORTDOC, 'dateend', to_char(dTILL, 'yyyy-mm-dd') || 'T12:00:00');
    xTMPNODE   := PKG_XML_UNL.ADD_XML_NODE(xDOC, xIMPORTDOC, 'typefinans', sTF);
    xTMPNODE   := PKG_XML_UNL.ADD_XML_NODE(xDOC, xIMPORTDOC, 'regnum', sTF);
    xTMPNODE   := PKG_XML_UNL.ADD_XML_NODE(xDOC, xIMPORTDOC, 'otdelenie', null);
    xTMPNODE   := PKG_XML_UNL.ADD_XML_NODE(xDOC, xIMPORTDOC, 'prochee', null);
    xSOSTAV    := dbms_xmldom.makeNode(dbms_xmldom.createElement(xDOC, 'sostav'));
    xTMPNODE   := dbms_xmldom.appendChild(xIMPORTDOC, xSOSTAV);
  end;

  procedure AddSTR(nPREP in number, nCOUNT in number, nPRICE in number, nSUMMA in number, sVEN in varchar2) is
  begin
    xSTR     := dbms_xmldom.makeNode(dbms_xmldom.createElement(xDOC, 'str'));
    xTMPNODE := dbms_xmldom.appendChild(xSOSTAV, xSTR);
    xTMPNODE := PKG_XML_UNL.ADD_XML_NODE(xDOC, xSTR, 'prep', nPREP);
    xTMPNODE := PKG_XML_UNL.ADD_XML_NODE(xDOC, xSTR, 'count', nCOUNT);
    xTMPNODE := PKG_XML_UNL.ADD_XML_NODE(xDOC, xSTR, 'price', nPRICE);
    xTMPNODE := PKG_XML_UNL.ADD_XML_NODE(xDOC, xSTR, 'summa', nSUMMA);
    xTMPNODE := PKG_XML_UNL.ADD_XML_NODE(xDOC, xSTR, 'ven', sVEN);
  end;

  procedure init is
  begin
    prsg_excel.PREPARE;
    prsg_excel.SHEET_SELECT('Лист1');
    prsg_excel.LINE_DESCRIBE('Строка');
    prsg_excel.LINE_DESCRIBE('Группа');
    for i in 1 .. 7 loop
      prsg_excel.LINE_CELL_DESCRIBE('Строка', 'Д' || i);
    end loop;
    prsg_excel.LINE_CELL_DESCRIBE('Группа', 'Г1');
    prsg_excel.CELL_DESCRIBE('Период');
  end;

  procedure fini is
  begin
    prsg_excel.LINE_DELETE('Строка');
    prsg_excel.LINE_DELETE('Группа');
  end;

begin

  if nMODE <> 1 then
    init;
    prsg_excel.CELL_VALUE_WRITE('Период', 'за период с ' || to_char(dFROM, 'dd.mm.yyyy') || ' г. по ' || to_char(dTILL, 'dd.mm.yyyy') || ' г.');
    for rREC in a(dFROM, dTILL, 0) loop
      if rREC.Nrow = 1 then
        if iROW is null then
          iROW := prsg_excel.LINE_APPEND('Группа');
        else
          iROW := prsg_excel.LINE_CONTINUE('Группа');
        end if;
        prsg_excel.CELL_VALUE_WRITE('Г1', 0, iRow, rREC.Gtd);
      end if;
      iROW := prsg_excel.LINE_CONTINUE('Строка');
      prsg_excel.CELL_VALUE_WRITE('Д1', 0, iRow, rREC.Nomen_Code);
      prsg_excel.CELL_VALUE_WRITE('Д2', 0, iRow, rREC.ncode);
      prsg_excel.CELL_VALUE_WRITE('Д3', 0, iRow, rREC.Sven);
      prsg_excel.CELL_VALUE_WRITE('Д4', 0, iRow, rREC.Quant);
      prsg_excel.CELL_VALUE_WRITE('Д5', 0, iRow, rREC.Price);
      prsg_excel.CELL_VALUE_WRITE('Д6', 0, iRow, rREC.Summtax);
      prsg_excel.CELL_VALUE_WRITE('Д7', 0, iRow, rREC.sXML);
    end loop;
    fini;
  end if;

  if nMODE > 0 then
  
    nIDENT := gen_id;
  
    dbms_lob.createtemporary(cDATA, True, dbms_lob.CALL);
    xDOC  := dbms_xmldom.newDOMDocument;
    xROOT := dbms_xmldom.appendChild( --
                                     dbms_xmldom.makeNode(xDOC),
                                     dbms_xmldom.makeNode(dbms_xmldom.createElement(xDOC, 'newdocs')));
    for rREC in a(dFROM, dTILL, 1) loop
      if rREC.Nrow = 1 then
        AddIMPORTDOC(dFROM, dTILL, rREC.Gtd);
      end if;
      if (rREC.Sven is null) then
        p_exception(0, 'У номенклатуры "' || rREC.Nomen_Code || '" не указан "Признак ЖНВЛС".');
      end if;
      AddStr(rREC.Ncode, rREC.Quant, rREC.Price, rREC.Summtax, rREC.Sven);
    end loop;
    -- Вывод:
    dbms_xmldom.writeToClob(xDOC, cDATA);
    cDATA     := '<?xml version="1.0" encoding="windows-1251"?>' || Chr(13) || Chr(10) || cDATA;
    sFILENAME := 'ABC.xml';
  
    insert into FILE_BUFFER (IDENT, AUTHID, FILENAME, DATA) values (nIDENT, UTILIZER, sFILENAME, cDATA);
  
    -- Очистка:
    dbms_xmldom.freeDocument(xDOC);
    dbms_lob.trim(cDATA, 0);
  
  end if;

end PP_EXP_TO_ABC;
/
