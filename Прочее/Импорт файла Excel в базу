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

procedure LoadFromExcel();
Const
  xlCellTypeLastCell = 11;
Var
  xl : Variant;
  od : TOpenDialog;
  maxRow, maxCol : Integer;
  frmWait : TForm;
  i,j : Integer;
  sSQL : String;
begin
  od := TOpenDialog.Create(nil);
  od.filter := 'Файлы MS Office Excel 2003 (xls)|*.xls';
  if od.Execute then begin
    xl := CreateOleObject('Excel.Application');
    xl.WorkBooks.Add(od.FileName);
    xl.Selection.SpecialCells(xlCellTypeLastCell).Select;
    maxRow := xl.ActiveCell.Row;
    maxCol := xl.ActiveCell.Column;
    CreateFrmWait(frmWait);
    UpdateFrmWaitStatus(frmWait, 'Найдено ' + IntToStr(maxCol) + ' столбцов и ' + IntToStr(maxRow) + ' строк');
    Query.SQL.Clear;
    Query.SQL.Text := 'delete from s_excel t where t.authid = user';
    Query.Execute;
    for i := 1 to maxRow do begin
      sSQL := 'insert into s_excel(authid, loaddate, loadfile, n1';
      for j := 1 to maxCol do begin
        sSQL := sSQL + ', f' + IntToStr(j);
      end;
      if xl.Cells(i, 1).Font.Bold then
        sSQL := sSQL + ', b';
      sSQL := sSQL + ') values (user, sysdate, :f, :n1';
      for j := 1 to maxCol do begin
        sSQL := sSQL + ', :f' + IntToStr(j);
      end;
      if xl.Cells(i, 1).Font.Bold then
        sSQL := sSQL + ', :b';
      sSQL := sSQL + ')';
      Query.SQL.Clear;
      Query.SQL.Text := sSQL;
      Query.Params.ParamByName('n1').Value := i;
      Query.Params.ParamByName('f').Value := od.FileName;
      for j := 1 to maxCol do begin
         try
           Query.Params.ParamByName('f' + IntToStr(j)).Value := VarToStr(xl.Cells(i,j).Value);
         except
           Query.Params.ParamByName('f' + IntToStr(j)).Value := '';
         end;
      end;
      if xl.Cells(i, 1).Font.Bold then
         Query.Params.ParamByName('b').Value := 1;
      try
         Query.Execute;
      except
         showmessage(sSQL);
         raise;
      end;
      if (i mod 10 = 0) then begin
        UpdateFrmWaitStatus(frmWait, 'Загружено: ' + IntToStr(i) + ' строк из ' + IntToStr(maxRow) + ' (' + IntToStr(Round(i/maxRow * 100)) + '%)');
        Application.ProcessMessages;
      end;
    end;
    showmessage('Загрузка завершена.');
    FreeFrmWait(frmWait);
    xl.quit;
  end;
  od.Free;
end;
