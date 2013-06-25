uses ComObj, DBTables;

procedure TO_GB;
var
  sTableName: string;
  sSQL: string;
  i, rowsCount: integer;
  cnn: Variant;
  sAGNBURN, sDOCWHEN: string;
begin
  // Создаем соединение
  cnn:= CreateOLEObject('ADODB.Connection');
  cnn.Provider:= 'Microsoft.Jet.OLEDB.4.0';
  cnn.Properties('Extended Properties'):= 'DBASE 5.0';
  cnn.Properties('Data Source'):= 'C:\';
  cnn.Open;
  // Генерим имя таблицы
  with Query do begin
    Sql.Text:= 'select ''GB_'' || to_char(sysdate,''HHMISS'') a from dual';
    Open;
    sTableName := FieldByName('a').AsString;
    Close;
  end;
  // Создаем таблицу
  sSQL := 'create table ' + sTableName +
    ' (' +
    '   COMPANY      Character(30), ' +
    '   TAB_NO       Character(20), ' +
    '   SURNAME      Character(30), ' +
    '   FIRSTNAME    Character(16), ' +
    '   SECONDNAME   Character(16), ' +
    '   BORN_DATE    Date, ' +
    '   BORN_PLACE   Character(200), ' +
    '   "POSITION"   Character(30), ' +
    '   ZIP_CODE     Character(6), ' +
    '   ADDRESS_1    Character(40), ' +
    '   ADDRESS_2    Character(40), ' +
    '   ADDRESS_3    Character(40), ' +
    '   ADDRESS_4    Character(40), ' +
    '   ADDRESS_5    Character(40), ' +
    '   ADDRESS_6    Character(40), ' +
    '   ADDRESS_7    Character(40), ' +
    '   ADDRESS_8    Character(40), ' +
    '   PASS_SER     Character(10), ' +
    '   PASPORT      Character(12), ' +
    '   PASS_DATE    Date, ' +
    '   PASS_GR      Character(200), ' +
    '   PHONE_CODE   Character(9), ' +
    '   ACCOUNT      Character(27), ' +
    '   CONST_NO     Character(9), ' +
    '   COMP_PHONE   Character(10), ' +
    '   PHONE_AMOU   Character(16), ' +
    '   HOME_PHONE   Character(10), ' +
    '   AMOUNT       Character(25), ' +
    '   TRADE_DATE   Date ' +
    ' )';
  cnn.Execute(sSQL);
  rowsCount := GetDocumentCount;
  for i := 0 to rowsCount - 1 do begin
    SQL.Text := 'select * from vp_to_gb t where nCLNPSPFM = ' + GetDocument(i);
    Open;
    First;
    while not EOF do begin
      if FieldByName('AGNBURN').AsString = ''
         then sAGNBURN := 'null'
         else sAGNBURN := '''' + FieldByName('AGNBURN').AsString + '''';
      if FieldByName('DOCWHEN').AsString = ''
         then sDOCWHEN := 'null'
         else sDOCWHEN := '''' + FieldByName('DOCWHEN').AsString + '''';

      sSQL :=
        ' insert into ' + sTableName +
        ' (' +
        '  COMPANY, TAB_NO, SURNAME, FIRSTNAME, SECONDNAME, BORN_DATE, BORN_PLACE, "POSITION", ZIP_CODE, ' +
        '  ADDRESS_1, ADDRESS_2, ADDRESS_3, ADDRESS_4, ADDRESS_5, ADDRESS_6, ADDRESS_7, ADDRESS_8, ' +
        '  PASS_SER, PASPORT, PASS_DATE, PASS_GR, AMOUNT' +
        ' )' +
        ' values (' +
        '''' + FieldByName('COMPNAME').AsString + ''', ' +
        '''' + FieldByName('TAB_NUMB').AsString + ''', ' +
        '''' + FieldByName('AGNFAMILYNAME').AsString + ''', ' +
        '''' + FieldByName('AGNFIRSTNAME').AsString + ''', ' +
        '''' + FieldByName('AGNLASTNAME').AsString + ''', ' +
        '  ' + sAGNBURN + '  , ' +
        '''' + FieldByName('ADDR_BURN').AsString + ''', ' +
        '''' + FieldByName('SCLNPOSTS').AsString + ''', ' +
        '''' + FieldByName('ZIPCODE').AsString + ''', ' +
        '''' + FieldByName('SCOUNTRY').AsString + ''', ' +
        '''' + FieldByName('SREGIONCODE').AsString + ''', ' +
        '''' + FieldByName('SRAION').AsString + ''', ' +
        '''' + FieldByName('STOWN').AsString + ''', ' +
        '''' + FieldByName('SSTREET').AsString + ''', ' +
        '''' + FieldByName('ADDR_HOUSE').AsString + ''', ' +
        '''' + FieldByName('ADDR_BUILDING').AsString + ''', ' +
        '''' + FieldByName('ADDR_FLAT').AsString + ''', ' +
        '''' + FieldByName('DOCSER').AsString + ''', ' +
        '''' + FieldByName('DOCNUMB').AsString + ''', ' +
        '  ' + sDOCWHEN + '  , ' +
        '''' + FieldByName('DOCWHO').AsString + ''', ' +
        '''' + FieldByName('AMOUNT').AsString + '''' +
        ' );';
      cnn.Execute(sSQL);
      Next;
    end;
  end;
  cnn.Close;
  ShowMessage('Выгрузка завершена (с:\'+sTableName+'.dbf)');
end;
