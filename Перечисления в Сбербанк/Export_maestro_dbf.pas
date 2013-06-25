procedure Export_maestro_dbf;
var i, j, cnt, nrn: Integer;
    ex,wb,ws,pach: Variant;
    summa: Real;
begin
  { Приложение по выгрузке перечислений в формате Сбербанка (dbf).
    Разработчик: специалист по внедрению ПП
                 ООО ИТ "Парус-Волга"
                 Белозеров Дмитрий А.
           Дата: 03.04.2011 года }

  // Заполнение промежуточной таблицы
  summa:=0;
  cnt:=GetDocumentCount;

  // Очистка промежуточной таблицы
  Query.Sql.Text:='delete from parus.s_salary_maestro where authid=user';
  Query.Execute;
  Query.Close;

  // Заполнение промежуточной таблицы
  for j:=0 to cnt-1 do
  begin
    nrn:=GetDocument(j);
    Query.Sql.Text:='insert into parus.s_salary_maestro(select upper(k.agnfamilyname)||'' ''||substr(upper(k.agnfirstname),1,1)||''. ''||substr(upper(k.agnlastname),1,1), r.agnacc, t.ntransfsumm, k.rn, user, k.agnfamilyname, k.agnfirstname, k.agnlastname from v_sltransfers t, v_agnlist k, v_agnacc r where t.nrn = :n and k.rn = t.nrecipient and r.rn = t.nbankattrs)';
    Query.ParamByName('n').asInteger:=nrn;
    Query.Execute;
  end;

  // Запуск Excel
  ex:=CreateOleObject('Excel.Application');
  ex.Visible:=false; // невидимый режим

  // Создание книги и листов
  wb:=ex.Workbooks.Add;

  // Выбор и имя текущего листа
  ws:=wb.Worksheets(1);
  ws.name := 'T6991'+GetParamValue('sORG')+FloatToStr(GetParamValue('nREESTR'));

  // Форматирование листа Excel
  ws.Range('A:G').NumberFormat := '@';
  ws.Range('A:G').ColumnWidth := 30;

  // Заполнение строки 1 (заголовок таблицы)
  ws.cells(1,1).Value:='A';
  ws.cells(1,2).Value:='B';
  ws.cells(1,3).Value:='C';
  ws.cells(1,4).Value:='D';
  ws.cells(1,5).Value:='E';
  ws.cells(1,6).Value:='F';
  ws.cells(1,7).Value:='G';

  // Заполнение строки 2 (Отделение СБ)
  ws.cells(2,1).Value:='6991';

  // Заполнение строки 3 (платежка)
  ws.cells(3,1).Value:='К платежному поручению №';
  ws.cells(3,2).Value:=GetParamValue('sNUMB');
  ws.cells(3,3).Value:='от';
  DateSeparator := '.';
  ws.cells(3,4).Value:=DateToStr(GetParamValue('dDATE'));

  // Заполнение строки 4 (зачисление)
  ws.cells(4,1).Value:='Зачисление';
  ws.cells(4,2).Value:='01';
  ws.cells(4,3).Value:='810';

  // Заполнение строки 5 (организация)
  ws.cells(5,1).Value:='Наименование (ОГРН) предприятия';
  ws.cells(5,2).Value:=GetParamValue('sNAME');
  ws.cells(5,3).Value:=GetParamValue('sACC');

  // Заполнение строки 6 (договор)
  ws.cells(6,1).Value:='По договору';
  ws.cells(6,2).Value:=GetParamValue('sDOG');
  ws.cells(6,3).Value:='от';
  ws.cells(6,4).Value:=GetParamValue('dDOG');

  // Заполнение строки 7 (заголовок)
  ws.cells(7,1).Value:='№ п/п';
  ws.cells(7,2).Value:='Номер счета';
  ws.cells(7,3).Value:='Фамилия';
  ws.cells(7,4).Value:='Имя';
  ws.cells(7,5).Value:='Отчество';
  ws.cells(7,6).Value:='Сумма';
  ws.cells(7,7).Value:='Примечание';

  // Идентификатор первой строки данных по зарплате сотрудника
  i: = 8;

  // Выбор данных перечислений
  Query.Sql.Text:='select t.fio, t.ls, sum(t.summa) as summa, convert(t.fio,''RU8PC866'') as sfio, trim(to_char(nvl(sum(t.summa),0),''9999999.99'')) as ssumma, t.fam, t.ima, t.oth  from parus.s_salary_maestro t where t.authid=user group by t.rn, t.fio, t.ls, t.fam, t.ima, t.oth order by t.fio';
  Query.Open;
  Query.First;
  While Not Query.EOF do
  begin

    // Добаление строк
    ws.cells(i,1).insert(-4121);
    ws.cells(i,2).insert(-4121);
    ws.cells(i,3).insert(-4121);
    ws.cells(i,4).insert(-4121);
    ws.cells(i,5).insert(-4121);
    ws.cells(i,6).insert(-4121);
    ws.cells(i,7).insert(-4121);

    // Заполнение данных текущей строки
    ws.cells(i,1).Value:=i-7;
    ws.cells(i,2).value:=Query.FieldByName('ls').asString;
    ws.cells(i,3).value:=Query.FieldByName('fam').asString;
    ws.cells(i,4).value:=Query.FieldByName('ima').asString;
    ws.cells(i,5).value:=Query.FieldByName('oth').asString;
    ws.cells(i,6).value:=Query.FieldByName('ssumma').asString;

    // Инкремент итоговой суммы и идентификатора строки
    summa:=summa+Query.FieldByName('summa').AsFloat;
    i: = i + 1;

    Query.Next;
  end;

  // Заполнение заключительной строки
  ws.cells(i,2).value:='ИТОГО:';
  DecimalSeparator := '.';
  ws.cells(i,6).value:=FloatToStrF(summa,ffFixed,10,2);

  // Удаление "лишних" листов
  wb.Worksheets(2).delete;
  wb.Worksheets(2).delete;

  // Сохрание книги Excel
  wb.SaveAs(GetParamValue('sPACH')+ws.name,11);

  // Генерация сообщения о завершении
  ShowMessage('Выгрузка завершена.');

  // Визуализация Excel
  ex.Visible:=true;

end;

end;