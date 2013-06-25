create or replace package PKGP_EXCEL_XML is

  -- Author  : GONCHARENKOPL
  -- Created : 08.02.2012 12:17:06

  f              utl_file.file_type;
  bWorkSheetOpen boolean := false;
  styleID        number;

  sCOLONTITULNEWLINE varchar2(10) := '&#10;';
  sCOLONTITULPAGENUM varchar2(10) := '&amp;С';

  procedure Init(sFileName in varchar2);
  procedure AddWorkSheet(sSheet in varchar2);
  procedure CloseWorkSheet;
  procedure AddTable;
  procedure AddColumn(sWidth in varchar2);
  procedure CloseTable;
  procedure AddNamedRange(sName in varchar2, sValue in varchar2);
  procedure AddLine(sParams in varchar2 default null);
  procedure CloseLine;
  procedure AddStyles;
  procedure CloseStyles;
  procedure AddStyleBorder(sName in varchar2);
  procedure AddStyleBor(sName in varchar2, sBORDER in varchar2);
  procedure AddStyle_Font_Bold(sName in varchar2);
  procedure AddStyle_Font_Size(sName in varchar2, sValue in varchar2);
  procedure AddStyle_Alignment_Horizontal(sName in varchar, sValue in varchar2);
  procedure AddStyle_Alignment_Vertical(sName in varchar, sValue in varchar2);
  procedure AddStyle_Alignment_Wrap(sName in varchar);
  procedure AddEmptyCell(nCount in number default 1);
  procedure AddCell(sData in varchar2, sStyle in varchar2 default null, sParams in varchar2 default null);
  procedure AddCell(nData in number, sStyle in varchar2 default null, sParams in varchar2 default null);
  procedure AddNamedCell(sData in varchar2, sNamed in varchar2, sStyle in varchar2 default null, sParams in varchar2 default null);
  procedure AddWorksheetOptions;
  procedure AddPageSetup;
  procedure AddLayout(sOrienantion in varchar2);
  procedure PageHeader(nMargin in number, sText in varchar2 default null);
  procedure PageFooter(nFooter in number);
  procedure PageMargins(nBottom in number, nLeft in number, nRight in number, nTop in number);
  procedure ClosePageSetup;
  procedure SetFitToPage;
  procedure AddPrint;
  procedure AddPrintFitHeight(nHeight in number);
  procedure ClosePrint;
  procedure CloseWorksheetOptions;
  procedure Fini;
  -----------------------------------------------
  procedure test;

end PKGP_EXCEL_XML;
/
create or replace package body PKGP_EXCEL_XML is

  procedure Init(sFileName in varchar2) is
  begin
    f := utl_file.fopen_nchar('USERDATA', sFileName || '.xml', 'w');
    utl_file.put_line_nchar(f,
                            '<?xml version="1.0"?>
<?mso-application progid="Excel.Sheet"?>
<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet"
 xmlns:o="urn:schemas-microsoft-com:office:office"
 xmlns:x="urn:schemas-microsoft-com:office:excel"
 xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet"
 xmlns:html="http://www.w3.org/TR/REC-html40">
 <DocumentProperties xmlns="urn:schemas-microsoft-com:office:office">
  <Author>GoncharenkoPL</Author>
  <LastAuthor>GoncharenkoPL</LastAuthor>
 </DocumentProperties>
 <ExcelWorkbook xmlns="urn:schemas-microsoft-com:office:excel">
 </ExcelWorkbook>');
  end;

  procedure AddStyles is
  begin
    utl_file.put_line_nchar(f,
                            ' <Styles>
  <Style ss:ID="Default" ss:Name="Normal">
   <Alignment ss:Vertical="Bottom"/>
   <Borders/>
   <Font ss:FontName="Arial Cyr" x:CharSet="204"/>
   <Interior/>
   <NumberFormat/>
   <Protection/>
  </Style>');
    styleId := gen_ident;
  end;

  procedure CloseStyles is
    sStyleLine varchar2(2000);
  begin
    for c in (select t.stylename, --
                     t.styleparameter,
                     t.styleparametervalue,
                     row_number() over(partition by t.stylename order by t.stylename, t.styleparameter, t.styleparametervalue) nrow,
                     count(1) over(partition by t.stylename) ncount,
                     row_number() over(partition by t.stylename, t.styleparameter order by t.stylename, t.styleparameter, t.styleparametervalue) nrow_par,
                     count(1) over(partition by t.stylename, t.styleparameter) ncount_par,
                     row_number() over(order by t.stylename, t.styleparameter, t.styleparametervalue) nrowall
                from TP_EXCEL_XML_STYLE t
               where t.Ident = styleId
               order by nrowall) loop
      if c.nrow = 1 then
        sStyleLine := '  <Style ss:ID="' || c.stylename || '">' || chr(10);
      end if;
      if c.styleparameter = 'border' then
        sStyleLine := sStyleLine || '   <Borders>
    <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>
    <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>
    <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>
    <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>
   </Borders>' || chr(10);
      end if;
      if c.styleparameter = 'bord' then
        if c.nrow_par = 1 then
          sStyleLine := sStyleLine || '<Borders>';
        end if;
        sStyleLine := sStyleLine || ' ' || '<Border ss:Position="' || c.styleparametervalue || '" ss:LineStyle="Continuous" ss:Weight="1"/>';
        if c.nrow_par = c.ncount_par then
          sStyleLine := sStyleLine || '</Borders>' || chr(10);
        end if;
      end if;
      if c.styleparameter = 'font' then
        if c.nrow_par = 1 then
          sStyleLine := sStyleLine || '<Font';
        end if;
        sStyleLine := sStyleLine || ' ' || c.styleparametervalue;
        if c.nrow_par = c.ncount_par then
          sStyleLine := sStyleLine || '/>' || chr(10);
        end if;
      end if;
      if c.styleparameter = 'alignment' then
        if c.nrow_par = 1 then
          sStyleLine := sStyleLine || '<Alignment';
        end if;
        sStyleLine := sStyleLine || ' ' || c.styleparametervalue;
        if c.nrow_par = c.ncount_par then
          sStyleLine := sStyleLine || '/>' || chr(10);
        end if;
      end if;
      if c.nrow = c.ncount then
        sStyleLine := sStyleLine || '  </Style>' || chr(10);
        utl_file.put_line_nchar(f, sStyleLine);
      end if;
    end loop;
    utl_file.put_line_nchar(f, ' </Styles>');
    delete from TP_EXCEL_XML_STYLE t where t.ident = styleId;
  end;

  procedure AddStyle_Font_Bold(sName in varchar2) is
  begin
    insert into TP_EXCEL_XML_STYLE
      (STYLENAME, STYLEPARAMETER, STYLEPARAMETERVALUE, IDENT) --
    values
      (sName, 'font', 'ss:Bold="1"', styleId);
  end;

  procedure AddStyle_Font_Size(sName in varchar2, sValue in varchar2) is
  begin
    insert into TP_EXCEL_XML_STYLE
      (STYLENAME, STYLEPARAMETER, STYLEPARAMETERVALUE, IDENT) --
    values
      (sName, 'font', 'ss:Size="' || sValue || '"', styleId);
  end;

  procedure AddStyleBorder(sName in varchar2) is
  begin
    insert into TP_EXCEL_XML_STYLE (STYLENAME, STYLEPARAMETER, IDENT) values (sName, 'border', styleId);
  end;

  /**
   * Добавить рамку
   * Bottom, Left, Right, Top
  **/
  procedure AddStyleBor(sName in varchar2, sBORDER in varchar2) is
  begin
    insert into TP_EXCEL_XML_STYLE (STYLENAME, STYLEPARAMETER, STYLEPARAMETERVALUE, IDENT) values (sName, 'bord', sBORDER, styleId);
  end;

  procedure AddStyle_Alignment_Wrap(sName in varchar) is
  begin
    insert into TP_EXCEL_XML_STYLE
      (STYLENAME, STYLEPARAMETER, STYLEPARAMETERVALUE, IDENT) --
    values
      (sName, 'alignment', 'ss:WrapText="1"', styleId);
  end;

  procedure AddStyle_Alignment_Horizontal
  -- sValue : Left, Center
  (sName in varchar, sValue in varchar2) is
  begin
    insert into TP_EXCEL_XML_STYLE
      (STYLENAME, STYLEPARAMETER, STYLEPARAMETERVALUE, IDENT) --
    values
      (sName, 'alignment', 'ss:Horizontal="' || sValue || '"', styleId);
  end;

  procedure AddStyle_Alignment_Vertical
  -- sValue : Center, Bottom
  (sName in varchar, sValue in varchar2) is
  begin
    insert into TP_EXCEL_XML_STYLE
      (STYLENAME, STYLEPARAMETER, STYLEPARAMETERVALUE, IDENT) --
    values
      (sName, 'alignment', 'ss:Vertical="' || sValue || '"', styleId);
  end;

  procedure AddWorkSheet(sSheet in varchar2) is
  begin
    utl_file.put_line_nchar(f, ' <Worksheet ss:Name="' || sSheet || '">');
  end;

  procedure AddNamedRange(sName in varchar2, sValue in varchar2) is
  begin
    utl_file.put_line_nchar(f,
                            '  <Names>
   <NamedRange ss:Name="' || sName || '" ss:RefersTo="' || sValue || '"/>
  </Names>');
  end;

  procedure AddTable is
  begin
    utl_file.put_line_nchar(f, '  <Table>');
  end;

  procedure AddColumn(sWidth in varchar2) is
  begin
    utl_file.put_line_nchar(f, '  <Column ss:AutoFitWidth="0" ss:Width="' || sWidth || '"/>');
  end;

  procedure AddLine(sParams in varchar2 default null) is
  begin
    utl_file.put_line_nchar(f, '   <Row ' || sParams || '>');
  end;

  procedure CloseLine is
  begin
    utl_file.put_line_nchar(f, '   </Row>');
  end;

  procedure AddEmptyCell(nCount in number default 1) is
    i number;
  begin
    for i in 1 .. nCount loop
      utl_file.put_line_nchar(f, '<Cell />');
    end loop;
  end;

  procedure AddCell_
  --
  (sData   in varchar2,
   sType   in varchar2,
   sStyle  in varchar2,
   sParams in varchar2,
   sNamed  in varchar2 --
   ) is
    psStyle   varchar2(40);
    sNamedStr varchar2(80);
  begin
    if sStyle is not null then
      psStyle := ' ss:StyleID="' || sStyle || '"';
    end if;
    if sParams is not null then
      psStyle := psStyle || ' ' || sParams;
    end if;
    if sNamed is not null then
      sNamedStr := '<NamedCell ss:Name="' || sNamed || '"/>';
    end if;
    utl_file.put_line_nchar(f, '      <Cell' || psStyle || '><Data ss:Type="' || sType || '">' || sData || '</Data>' || sNamedStr || '</Cell>');
  end;

  procedure AddCell
  --
  (sData   in varchar2,
   sStyle  in varchar2 default null,
   sParams in varchar2 default null --
   ) is
  begin
    AddCell_(sData, 'String', sStyle, sParams, null);
  end;

  procedure AddCell
  --
  (nData   in number,
   sStyle  in varchar2 default null,
   sParams in varchar2 default null --
   ) is
  begin
    AddCell_(replace(to_char(Round(nData, 3)), ',', '.'), 'Number', sStyle, sParams, null);
  end;

  procedure AddNamedCell
  --
  (sData   in varchar2,
   sNamed  in varchar2,
   sStyle  in varchar2 default null,
   sParams in varchar2 default null --
   ) is
  begin
    AddCell_(sData, 'String', sStyle, sParams, sNamed);
  end;

  procedure CloseTable is
  begin
    utl_file.put_line_nchar(f, '  </Table>');
  end;

  procedure AddWorksheetOptions is
  begin
    utl_file.put_line_nchar(f, '  <WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel">');
  end;

  procedure AddPageSetup is
  begin
    utl_file.put_line_nchar(f, '   <PageSetup>');
  end;

  /**
   * Ориентация книги
   * sOrienantion: Landscape
  **/
  procedure AddLayout(sOrienantion in varchar2) is
  begin
    utl_file.put_line_nchar(f, '<Layout x:Orientation="' || sOrienantion || '"/>');
  end;

  /**
   * Колонтитул:
  **/
  procedure PageHeader(nMargin in number, sText in varchar2 default null) is
    sHEADER varchar2(500);
  begin
    sHEADER := '<Header x:Margin="' || replace(to_char(round(nMargin / 2.54, 10)), ',', '.') || '"';
    if sText is not null then
      sHEADER := sHEADER || ' x:Data="&amp;П' || sText || '"';
    end if;
    sHEADER := sHEADER || '/>';
    utl_file.put_line_nchar(f, sHEADER);
  end;

  procedure PageMargins(nBottom in number, nLeft in number, nRight in number, nTop in number) is
  begin
    utl_file.put_line_nchar(f,
                            '<PageMargins x:Bottom="' || replace(to_char(round(nBottom / 2.54, 10)), ',', '.') || '" x:Left="' || replace(to_char(round(nLeft / 2.54, 10)), ',', '.') || '" x:Right="' || replace(to_char(round(nRight / 2.54, 10)), ',', '.') || '" x:Top="' ||
                            replace(to_char(round(nTop / 2.54, 10)), ',', '.') || '"/>');
  end;

  procedure PageFooter(nFooter in number) is
  begin
    utl_file.put_line_nchar(f, '<Footer x:Margin="' || replace(to_char(round(nFooter / 2.54, 10)), ',', '.') || '"/>');
  end;

  procedure ClosePageSetup is
  begin
    utl_file.put_line_nchar(f, '   </PageSetup>');
  end;

  procedure SetFitToPage is
  begin
    utl_file.put_line_nchar(f, '   <FitToPage/>');
  end;

  procedure AddPrint is
  begin
    utl_file.put_line_nchar(f, '<Print>');
  end;

  procedure AddPrintFitHeight(nHeight in number) is
  begin
    utl_file.put_line_nchar(f, '<FitHeight>' || nHeight || '</FitHeight>');
  end;

  procedure ClosePrint is
  begin
    utl_file.put_line_nchar(f, '</Print>');
  end;

  procedure CloseWorksheetOptions is
  begin
    utl_file.put_line_nchar(f, '  </WorksheetOptions>');
  end;

  procedure CloseWorkSheet is
  begin
    utl_file.put_line_nchar(f, ' </Worksheet>');
  end;

  procedure Fini is
  begin
    utl_file.put_line_nchar(f, '</Workbook>');
    utl_file.fclose(f);
  end;

  -------------------------------------------------------------------------------------

  procedure test is
  begin
    null;
  end;

end PKGP_EXCEL_XML;
/*create public synonym PKGP_EXCEL_XML for PKGP_EXCEL_XML;
grant execute on PKGP_EXCEL_XML to public;*/
/
