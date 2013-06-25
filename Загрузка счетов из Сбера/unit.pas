procedure CreateFrmWait(var frmWait : TForm);
Var
  lblWait : Tlabel;
begin
  frmWait := TForm.Create(nil);
  frmWait.Width := 300;
  frmWait.Height := 200;
  frmWait.Position := poDesktopCenter;
  frmWait.Caption := 'Загрузка данных';
  lblWait := TLabel.Create(frmWait);
  lblWait.Parent := frmWait;
  lblWait.Name := 'lblWait';
  lblWait.WordWrap := true;
  lblWait.Autosize := false;
  lblWait.top := 15; lblWait.Left := 15;
  lblWait.Width := frmWait.Width - 30;
  lblWait.Height := frmWait.Height - 100;
  lblWait.Visible := true;
  frmWait.Show;
end;

procedure FreeFrmWait(frmWait : TForm);
begin
  frmWait.lblWait.Free;
  frmWait.Free;
end;

procedure UpdateFrmWaitStatus(frmWait : TForm; sStatus : String);
begin
  frmWait.lblWait.Caption := sStatus;
  Application.ProcessMessages;
end;

function ParusLoad(nLoad : Integer, sFile : String);
begin
  StoredProc.StoredProcName := 'PP_SBER_LOADACC';
  StoredProc.Prepare;
  StoredProc.ParamByName('NLOAD').Value := nLoad;
  StoredProc.ParamByName('SFILE').Value := sFile;
  StoredProc.ExecProc;
  Result := StoredProc.ParamByName('SOUT').AsString;
end;

procedure LoadFromExcel;
Const
  xlCellTypeLastCell = 11;
  ofAllowMultiSelect = 64;
  ofFileMustExist = 512;
Var
  OD : TOpenDialog;
  xl, xlsheet : Variant;
  iRows, iCols, i, j, iFile : Integer;
  sSQL : String;
  si : String;
  frmWait : TForm;
  v : String;
begin
  OD := TOpenDialog.Create(nil);
  OD.Filter := 'Файлы Excel (*.xls)|*.xls';
  OD.Options := ofAllowMultiSelect + ofFileMustExist;
  if (not(OD.Execute)) then begin
    OD.Free;
    exit;
  end;
  CreateFrmWait(frmWait);
  xl := CreateOleObject('Excel.Application');
  Query.SQL.Text := 'delete from t_s_excel where authid = user';
  Query.Execute;
  Query.SQL.Clear;
  for iFile := 0 to OD.Files.Count - 1 do begin
  UpdateFrmWaitStatus(frmWait, 'Открываю файл: ' + OD.Files.Strings[iFile]);
  xl.Workbooks.Add(OD.Files.Strings[iFile]);
  iRows := xl.Selection.SpecialCells(xlCellTypeLastCell).Row;
  iCols := xl.Selection.SpecialCells(xlCellTypeLastCell).Column;
  UpdateFrmWaitStatus(frmWait, 'Открываю файл: ' + OD.Files.Strings[iFile] + #13#10 + 'Найдено: ' + IntToStr(iRows) + ' строк и ' + IntToStr(iCols) + ' столбцов');
  for j := 1 to iRows do begin
      sSQL := 'insert into t_s_excel(authid, n, sfile';
      for i := 1 to iCols do begin
        sSQL := sSQL + ', d' + trim(IntToStr(i));
      end;
      sSQL := sSQL + ') values(user, ' + IntToStr(j) + ', ''' + OD.Files.Strings[iFile] + '''';
      for i := 1 to iCols do begin
        v := VarToStr(xl.Cells(j,i).Value);
        if v <> ''
           then sSQL := sSQL + ', ''' + v + ''''
           else sSQL := sSQL + ', null';
      end;
      sSQL := sSQL + ')';
      Query.SQL.Text := sSQL;
      try
        Query.Execute;
      except
        ShowMessage('ОШИБКА: ' + #13#10 + sSQL);
        raise;
        exit;
      end;
      if j mod 25 = 0 then begin
        UpdateFrmWaitStatus(frmWait, 'Загружаю: ' + OD.Files.Strings[iFile] + #13#10 + 'Загружено: ' + IntToStr(j / iRows * 100) + '%');
      end;
      xl.Cells(j,8).Value := ParusLoad(j, OD.Files.Strings[iFile]);
      if j = 1 then
         xl.Columns('H:H').ColumnWidth := 50;
  end;
  end; // iFile
  OD.Free;
  xl.Visible := true;
  FreeFrmWait(frmWait);
  ShowMessage('Результаты загрузки в Excel - файле');
end;
