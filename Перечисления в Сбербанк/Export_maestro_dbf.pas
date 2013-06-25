procedure Export_maestro_dbf;
var i, j, cnt, nrn: Integer;
    ex,wb,ws,pach: Variant;
    summa: Real;
begin
  { ���������� �� �������� ������������ � ������� ��������� (dbf).
    �����������: ���������� �� ��������� ��
                 ��� �� "�����-�����"
                 ��������� ������� �.
           ����: 03.04.2011 ���� }

  // ���������� ������������� �������
  summa:=0;
  cnt:=GetDocumentCount;

  // ������� ������������� �������
  Query.Sql.Text:='delete from parus.s_salary_maestro where authid=user';
  Query.Execute;
  Query.Close;

  // ���������� ������������� �������
  for j:=0 to cnt-1 do
  begin
    nrn:=GetDocument(j);
    Query.Sql.Text:='insert into parus.s_salary_maestro(select upper(k.agnfamilyname)||'' ''||substr(upper(k.agnfirstname),1,1)||''. ''||substr(upper(k.agnlastname),1,1), r.agnacc, t.ntransfsumm, k.rn, user, k.agnfamilyname, k.agnfirstname, k.agnlastname from v_sltransfers t, v_agnlist k, v_agnacc r where t.nrn = :n and k.rn = t.nrecipient and r.rn = t.nbankattrs)';
    Query.ParamByName('n').asInteger:=nrn;
    Query.Execute;
  end;

  // ������ Excel
  ex:=CreateOleObject('Excel.Application');
  ex.Visible:=false; // ��������� �����

  // �������� ����� � ������
  wb:=ex.Workbooks.Add;

  // ����� � ��� �������� �����
  ws:=wb.Worksheets(1);
  ws.name := 'T6991'+GetParamValue('sORG')+FloatToStr(GetParamValue('nREESTR'));

  // �������������� ����� Excel
  ws.Range('A:G').NumberFormat := '@';
  ws.Range('A:G').ColumnWidth := 30;

  // ���������� ������ 1 (��������� �������)
  ws.cells(1,1).Value:='A';
  ws.cells(1,2).Value:='B';
  ws.cells(1,3).Value:='C';
  ws.cells(1,4).Value:='D';
  ws.cells(1,5).Value:='E';
  ws.cells(1,6).Value:='F';
  ws.cells(1,7).Value:='G';

  // ���������� ������ 2 (��������� ��)
  ws.cells(2,1).Value:='6991';

  // ���������� ������ 3 (��������)
  ws.cells(3,1).Value:='� ���������� ��������� �';
  ws.cells(3,2).Value:=GetParamValue('sNUMB');
  ws.cells(3,3).Value:='��';
  DateSeparator := '.';
  ws.cells(3,4).Value:=DateToStr(GetParamValue('dDATE'));

  // ���������� ������ 4 (����������)
  ws.cells(4,1).Value:='����������';
  ws.cells(4,2).Value:='01';
  ws.cells(4,3).Value:='810';

  // ���������� ������ 5 (�����������)
  ws.cells(5,1).Value:='������������ (����) �����������';
  ws.cells(5,2).Value:=GetParamValue('sNAME');
  ws.cells(5,3).Value:=GetParamValue('sACC');

  // ���������� ������ 6 (�������)
  ws.cells(6,1).Value:='�� ��������';
  ws.cells(6,2).Value:=GetParamValue('sDOG');
  ws.cells(6,3).Value:='��';
  ws.cells(6,4).Value:=GetParamValue('dDOG');

  // ���������� ������ 7 (���������)
  ws.cells(7,1).Value:='� �/�';
  ws.cells(7,2).Value:='����� �����';
  ws.cells(7,3).Value:='�������';
  ws.cells(7,4).Value:='���';
  ws.cells(7,5).Value:='��������';
  ws.cells(7,6).Value:='�����';
  ws.cells(7,7).Value:='����������';

  // ������������� ������ ������ ������ �� �������� ����������
  i: = 8;

  // ����� ������ ������������
  Query.Sql.Text:='select t.fio, t.ls, sum(t.summa) as summa, convert(t.fio,''RU8PC866'') as sfio, trim(to_char(nvl(sum(t.summa),0),''9999999.99'')) as ssumma, t.fam, t.ima, t.oth  from parus.s_salary_maestro t where t.authid=user group by t.rn, t.fio, t.ls, t.fam, t.ima, t.oth order by t.fio';
  Query.Open;
  Query.First;
  While Not Query.EOF do
  begin

    // ��������� �����
    ws.cells(i,1).insert(-4121);
    ws.cells(i,2).insert(-4121);
    ws.cells(i,3).insert(-4121);
    ws.cells(i,4).insert(-4121);
    ws.cells(i,5).insert(-4121);
    ws.cells(i,6).insert(-4121);
    ws.cells(i,7).insert(-4121);

    // ���������� ������ ������� ������
    ws.cells(i,1).Value:=i-7;
    ws.cells(i,2).value:=Query.FieldByName('ls').asString;
    ws.cells(i,3).value:=Query.FieldByName('fam').asString;
    ws.cells(i,4).value:=Query.FieldByName('ima').asString;
    ws.cells(i,5).value:=Query.FieldByName('oth').asString;
    ws.cells(i,6).value:=Query.FieldByName('ssumma').asString;

    // ��������� �������� ����� � �������������� ������
    summa:=summa+Query.FieldByName('summa').AsFloat;
    i: = i + 1;

    Query.Next;
  end;

  // ���������� �������������� ������
  ws.cells(i,2).value:='�����:';
  DecimalSeparator := '.';
  ws.cells(i,6).value:=FloatToStrF(summa,ffFixed,10,2);

  // �������� "������" ������
  wb.Worksheets(2).delete;
  wb.Worksheets(2).delete;

  // �������� ����� Excel
  wb.SaveAs(GetParamValue('sPACH')+ws.name,11);

  // ��������� ��������� � ����������
  ShowMessage('�������� ���������.');

  // ������������ Excel
  ex.Visible:=true;

end;

end;