procedure WriteQueryValue(MsWord : Variant; sLabel : String; sValue : String);
begin
  try
    MsWord.Selection.GoTo(-1, unAssigned, unAssigned, sLabel);
  except
    showmessage('Не могу найти закладку "' + sLabel + '"');
    raise;
  end;
  if sValue = ''
     then MsWord.Selection.Text := ''
     else MsWord.Selection.typetext(Query.FieldByName(sValue).AsString);
end;

procedure PrintDogovor;
var
  MsWord : Variant;
  sFileName : String;
begin
  try
    MsWord := CreateOleObject('Word.Application');
  except
    raise;
  end;
  // Загружаем документ MS Word:
  sFileName := '\\server-parus\parusdata\DOGOVOR.doc';
  // Сохраняем дату:
  MsWord.Documents.Open(sFileName, false, true);
  StoredProc.StoredProcName := 'PP_DOGOVOR';
  StoredProc.ParamByName('NRN').Value := GetDocument(0);
  StoredProc.ParamByName('DOPERDATE').Value := null;
  StoredProc.ExecProc;
  //
  MsWord.Documents.Open(sFileName, false, true);
  // Открываем запрос с данными:
  Query.SQL.Text := 'select rn, agncntr, sfio, sfio_to, sFIO_abl, agnfamilyname, agnfirstname, agnlastname, sdepartment, ''должности '' || spost spost, ctname, '+
                    'dstart, mstart, ystart, clnpspfmhsrn, sPASSPORT, saddress, ssumm, sruk, sagnburn, sFamIO, ' +
                    'cntrnumb, dcntr, mcntr, ycntr, schedule, leave_len, ssexend, srok, sispsrok, sslave, schedulees, ' +
                    'p42, p43, p44, p55, p56, p57, p58, p59, p510, p510a, p511, p512, p513, p514, p515, ' +
                    'p631, p632, p633, s631, s632, s633, ' +
                    'p635a, p635b, p635c, p635, s635a, s635b, s635c, ' +
                    'nokl, nopas, nvysl, nstep, sokl, soklkoeff, nklass, noth, soth, ndoplotp, npoosch, spoosch, nplat ' +
                    ' from VP_DOGOVOR t where rn = :rn';
  Query.ParamByName('rn').asInteger:=GetDocument(0);
  Query.Open;
  WriteQueryValue(MsWord, 'Номер', 'cntrnumb');
  WriteQueryValue(MsWord, 'ФИОР', 'sFIO_abl');
  WriteQueryValue(MsWord, 'ДатаД', 'dcntr');
  WriteQueryValue(MsWord, 'ДатаМ', 'mcntr');
  WriteQueryValue(MsWord, 'ДатаГ', 'ycntr');
  WriteQueryValue(MsWord, 'ФИОИ', 'sfio');
  WriteQueryValue(MsWord, 'Окончание', 'ssexend');
  WriteQueryValue(MsWord, 'Должность', 'spost');
  WriteQueryValue(MsWord, 'Подразделение', 'sdepartment');
  WriteQueryValue(MsWord, 'НаСрок', 'srok');
  WriteQueryValue(MsWord, 'ПричинаСрочного', '');
  WriteQueryValue(MsWord, 'КонкретнаяРабота', '');
  WriteQueryValue(MsWord, 'СрокДоговора', '');
  WriteQueryValue(MsWord, 'ТипРаботы', 'ctname');
  WriteQueryValue(MsWord, 'ИспытательныйСрокДней', 'sispsrok');
  if (Query.FieldByName('sispsrok').AsString = '') then WriteQueryValue(MsWord, 'ИспытательныйСрок', '');
  WriteQueryValue(MsWord, 'Подчинение', 'sslave');
  WriteQueryValue(MsWord, 'ПриступилД', 'dstart');
  WriteQueryValue(MsWord, 'ПриступилМ', 'mstart');
  WriteQueryValue(MsWord, 'ПриступилГ', 'ystart');
  if (Query.FieldByName('p42').AsInteger = 0) then WriteQueryValue(MsWord, 'П42', '');
  if (Query.FieldByName('p43').AsInteger = 0) then WriteQueryValue(MsWord, 'П43', '');
  if (Query.FieldByName('p44').AsInteger = 0) then WriteQueryValue(MsWord, 'П44', '');
  if (Query.FieldByName('p55').AsInteger = 0) then WriteQueryValue(MsWord, 'П55', '');
  if (Query.FieldByName('p56').AsInteger = 0) then WriteQueryValue(MsWord, 'П56', '');
  if (Query.FieldByName('p57').AsInteger = 0) then WriteQueryValue(MsWord, 'П57', '');
  if (Query.FieldByName('p58').AsInteger = 0) then WriteQueryValue(MsWord, 'П58', '');
  if (Query.FieldByName('p59').AsInteger = 0) then WriteQueryValue(MsWord, 'П59', '');
  if (Query.FieldByName('p510').AsInteger = 0) then WriteQueryValue(MsWord, 'П510', '');
  if (Query.FieldByName('p510a').AsInteger = 0) then WriteQueryValue(MsWord, 'П510а', '');
  if (Query.FieldByName('p511').AsInteger = 0) then WriteQueryValue(MsWord, 'П511', '');
  if (Query.FieldByName('p512').AsInteger = 0) then WriteQueryValue(MsWord, 'П512', '');
  if (Query.FieldByName('p513').AsInteger = 0) then WriteQueryValue(MsWord, 'П513', '');
  if (Query.FieldByName('p514').AsInteger = 0) then WriteQueryValue(MsWord, 'П514', '');
  if (Query.FieldByName('p515').AsInteger = 0) then WriteQueryValue(MsWord, 'П515', '');
  WriteQueryValue(MsWord, 'Продолжительность', 'schedule');
  WriteQueryValue(MsWord, 'ОсобенностиРежима', 'schedulees');
  // 6.3
  if (Query.FieldByName('p631').AsInteger = 0) then WriteQueryValue(MsWord, 'П631', '') else WriteQueryValue(MsWord, 'П631П', 's631');
  if (Query.FieldByName('p632').AsInteger = 0) then WriteQueryValue(MsWord, 'П632', '') else WriteQueryValue(MsWord, 'П632П', 's632');
  if (Query.FieldByName('p633').AsInteger = 0) then WriteQueryValue(MsWord, 'П633', '') else WriteQueryValue(MsWord, 'П633П', 's633');
  // 6.3.5
  if (Query.FieldByName('p635a').AsInteger = 0) then WriteQueryValue(MsWord, 'П635а', '') else WriteQueryValue(MsWord, 'П635аП', 's635a');
  if (Query.FieldByName('p635b').AsInteger = 0) then WriteQueryValue(MsWord, 'П635б', '') else WriteQueryValue(MsWord, 'П635бП', 's635b');
  if (Query.FieldByName('p635c').AsInteger = 0) then WriteQueryValue(MsWord, 'П635в', '') else WriteQueryValue(MsWord, 'П635вП', 's635c');
  if (Query.FieldByName('p635').AsInteger = 0) then WriteQueryValue(MsWord, 'П635', '');

  WriteQueryValue(MsWord, 'Оклад', 'sokl');
  WriteQueryValue(MsWord, 'ОкладД', 'nokl');
  if (Query.FieldByName('soklkoeff').AsString = '') then WriteQueryValue(MsWord, 'ОкладКатегория', '') else WriteQueryValue(MsWord, 'ОкладКатегорияД', 'soklkoeff');
  if (Query.FieldByName('nopas').AsString = '') then WriteQueryValue(MsWord, 'НадбавкаОпасность', '') else WriteQueryValue(MsWord, 'НадбавкаОпасностьД', 'nopas');
  if (Query.FieldByName('nvysl').AsString = '') then WriteQueryValue(MsWord, 'Надбавка', '') else WriteQueryValue(MsWord, 'НадбавкаД', 'nvysl');
  if (Query.FieldByName('nklass').AsString = '') then WriteQueryValue(MsWord, 'НадбавкаКлассность', '') else WriteQueryValue(MsWord, 'НадбавкаКлассностьД', 'nklass');
  if (Query.FieldByName('noth').AsString = '') then WriteQueryValue(MsWord, 'Доплаты', '') else begin
    WriteQueryValue(MsWord, 'ДоплатыД', 'noth');
    WriteQueryValue(MsWord, 'ДоплатыПричина', 'soth');
  end;
  if (Query.FieldByName('ndoplotp').AsInteger = 0) then WriteQueryValue(MsWord, 'ДоплатыОтпуск', '');
  if (Query.FieldByName('noth').AsString = '') then WriteQueryValue(MsWord, 'ДоплатыПоощрительные', '') else begin
    WriteQueryValue(MsWord, 'ДоплатыПоощрительныеД', 'npoosch');
    WriteQueryValue(MsWord, 'ДоплатыПоощрительныеП', 'snpoosch');
  end;
  if (Query.FieldByName('nplat').AsInteger = 0) then WriteQueryValue(MsWord, 'ДоплатыЕжемесячно', '') else WriteQueryValue(MsWord, 'ДоплатыЕжемесячноП', 'nplat');
  WriteQueryValue(MsWord, 'ФИОГР', 'sagnburn');
  WriteQueryValue(MsWord, 'Паспорт', 'sPASSPORT');
  WriteQueryValue(MsWord, 'Адрес', 'saddress');
  WriteQueryValue(MsWord, 'ФамИО1', 'sFamIO');
  WriteQueryValue(MsWord, 'ФамИО', 'sFamIO');

  MsWord.Visible := True;
end;
