create or replace procedure PP_RLIST
-- Расчетный лист
(nCOMPANY in number,
 nIDENT   in number,
 udSCALC  in date --
 ) is

  iROW    number;
  fROW    number;
  iROWA   number;
  bFIRST  boolean;
  dSCALC  date;
  nMSCALC number(2);
  nYSCALC number(4);
  dPFM    date;

  cursor cPF(nIDENT in number) is
    select ag.agnfamilyname || ' ' || ag.agnfirstname || ' ' || ag.agnlastname sFIO, --
           nvl(cd.psdep_name, po.name) spsdepname,
           de.name sdepartment,
           ofc.name sofficerclsname,
           pf.persrn
      from clnpspfm       pf, --
           clnpersons     cp,
           agnlist        ag,
           clnpsdep       cd,
           ins_department de,
           clnposts       po,
           officercls     ofc
     where pf.persrn = cp.rn
       and cp.pers_agent = ag.rn
       and pf.psdeprn = cd.rn(+)
       and pf.postrn = po.rn(+)
       and pf.deptrn = de.rn
       and pf.officercls = ofc.rn(+)
       and pf.rn in (select document from selectlist where ident = nIDENT);

  cursor cGS(nCLN in number, dDATE in date) is
    select rownum, --
           a.*,
           sum(summ) over() nallsumm,
           count(1) over() ncount
      from (select gr.code, --
                   sum(gs.summ) summ,
                   decode(gs.dimcoeff, 1, 100, 1) * gs.coeffic / 100 coeffic,
                   gr.grsal_numb grsal_numb
              from clnpspfmgs gs, grsalary gr, clnpspfm pf
             where dDATE between gs.do_act_from and nvl(gs.do_act_to, dDATE)
               and gr.rn = gs.grsalary
               and gs.prn = pf.rn
               and pf.persrn = nCLN
             group by gr.code, gs.dimcoeff, gs.coeffic, gr.grsal_numb
            union all
            select null, --
                   null,
                   null,
                   '9999999999'
              from dual
            union all
            select null, --
                   null,
                   null,
                   '9999999999'
              from dual
             order by 4) a;

  cursor cSLP(nPERS in number, nYEAR in number, nMONTH in number) is
    select sc.code, --
           trim(to_char(s.monthfor, '00')) || '-' || trim(to_char(s.yearfor)) speriod,
           f_slpays_paramstr(s.company, s.rn) sparams,
           sum(s.sum) nsum,
           sc.compch_type,
           sc.numb,
           row_number() over(partition by sc.compch_type order by numb) nrow,
           count(1) over(partition by sc.compch_type) ncount,
           sum(sum(s.sum)) over(partition by sc.compch_type) nallsum,
           sum(decode(sc.compch_type, 10, 1, 30, -1) * sum(s.sum)) over() nitogsum
      from slpays s, slcompcharges sc
     where s.clnpersons = nPERS
       and s.year = nYEAR
       and s.month = nMONTH
       and s.slcompcharges = sc.rn
       and sc.confpay_sign = 0
       and sc.auxilpay_sign = 0
       and sc.compch_type in (10, 30)
     group by sc.code, --
              trim(to_char(s.monthfor, '00')) || '-' || trim(to_char(s.yearfor)),
              f_slpays_paramstr(s.company, s.rn),
              sc.compch_type,
              sc.numb
    having sum(s.sum) <> 0
     order by ncount desc, numb;

  procedure init is
  begin
    prsg_excel.PREPARE;
    prsg_excel.SHEET_SELECT('Лист1');
    prsg_excel.LINE_DESCRIBE('Строка1'); -- ФИО
    prsg_excel.LINE_CELL_DESCRIBE('Строка1', 'ФИО');
    prsg_excel.LINE_DESCRIBE('Строка2'); -- Подразделение и ФОТ
    prsg_excel.LINE_CELL_DESCRIBE('Строка2', 'Подразделение');
    prsg_excel.LINE_DESCRIBE('Строка3'); -- Подразделение и ФОТ
    prsg_excel.LINE_CELL_DESCRIBE('Строка3', 'Должность');
    prsg_excel.LINE_CELL_DESCRIBE('Строка3', 'ФОТ');
    prsg_excel.LINE_CELL_DESCRIBE('Строка3', 'Процент');
    prsg_excel.LINE_CELL_DESCRIBE('Строка3', 'Сумма');
    prsg_excel.LINE_DESCRIBE('Строка4');
    prsg_excel.LINE_CELL_DESCRIBE('Строка4', 'Итого');
    prsg_excel.LINE_DESCRIBE('Строка5'); -- Начисления и удержания
    prsg_excel.LINE_CELL_DESCRIBE('Строка5', 'Начислено');
    prsg_excel.LINE_CELL_DESCRIBE('Строка5', 'НачисленоПериод');
    prsg_excel.LINE_CELL_DESCRIBE('Строка5', 'НачисленоПараметры');
    prsg_excel.LINE_CELL_DESCRIBE('Строка5', 'НачисленоСумма');
    prsg_excel.LINE_CELL_DESCRIBE('Строка5', 'Удержано');
    prsg_excel.LINE_CELL_DESCRIBE('Строка5', 'УдержаноПериод');
    prsg_excel.LINE_CELL_DESCRIBE('Строка5', 'УдержаноСумма');
    prsg_excel.LINE_DESCRIBE('Строка6');
    prsg_excel.LINE_CELL_DESCRIBE('Строка6', 'НачисленоВсего');
    prsg_excel.LINE_CELL_DESCRIBE('Строка6', 'УдержаноВсего');
    prsg_excel.LINE_CELL_DESCRIBE('Строка6', 'КВыдаче');
  end;

  procedure fini is
  begin
    prsg_excel.LINE_DELETE('Строка1');
    prsg_excel.LINE_DELETE('Строка2');
    prsg_excel.LINE_DELETE('Строка3');
    prsg_excel.LINE_DELETE('Строка4');
    prsg_excel.LINE_DELETE('Строка5');
    prsg_excel.LINE_DELETE('Строка6');
  end;

begin
  init;

  /* дата */
  dSCALC := trunc(nvl(udSCALC, GET_OPTIONS_DATE('SalaryCalcPeriod', nCOMPANY)), 'MONTH');
  if not dSCALC is null then
    nMSCALC := D_MONTH(dSCALC);
    nYSCALC := D_YEAR(dSCALC);
  else
    p_exception(0, 'Не задана дата.');
  end if;

  for rPF in cPF(nIDENT) loop
    -- Дата расчета ФОТ:
    select max(nvl(pf.endeng, last_day(dSCALC))) --
      into dPFM
      from clnpspfm pf
     where pf.persrn = rPF.Persrn;
  
    if iROW is null then
      iROW := prsg_excel.LINE_APPEND('Строка1');
    else
      iROW := prsg_excel.LINE_CONTINUE('Строка1');
    end if;
    prsg_excel.CELL_VALUE_WRITE('ФИО', 0, iROW, rPF.sFIO);
    iROW := prsg_excel.LINE_CONTINUE('Строка2');
    prsg_excel.CELL_VALUE_WRITE('Подразделение', 0, iROW, 'Подразделение: ' || rPF.Sdepartment);
  
    -- ФОТ
    for rGS in cGS(rPF.Persrn, least(dPFM, last_day(dSCALC))) loop
      if (rGS.ROWNUM < 3) or (rGS.CODE is not null) then
        iROW := prsg_excel.LINE_CONTINUE('Строка3');
        if rGS.Rownum = 1 then
          prsg_excel.CELL_VALUE_WRITE('Должность', 0, iROW, 'Должность: ' || rPF.Spsdepname);
        elsif rGS.Rownum = 2 then
          prsg_excel.CELL_VALUE_WRITE('Должность', 0, iROW, 'Категория персонала: ' || rPF.Sofficerclsname);
        end if;
        if rGS.CODE is not null then
          prsg_excel.CELL_VALUE_WRITE('ФОТ', 0, iROW, rGS.Code);
          prsg_excel.CELL_VALUE_WRITE('Процент', 0, iROW, rGS.Coeffic);
          prsg_excel.CELL_VALUE_WRITE('Сумма', 0, iROW, rGS.Summ);
        end if;
      end if;
      if (rGS.Rownum = rGS.Ncount) then
        iROW := prsg_excel.LINE_CONTINUE('Строка4');
        prsg_excel.CELL_VALUE_WRITE('Итого', 0, iROW, rGS.Nallsumm);
      end if;
    end loop;
    fROW   := null; -- Номер первой строки
    bFIRST := true;
    -- Начисления:
    for rSLP in cSLP(rPF.Persrn, nYSCALC, nMSCALC) loop
      if (bFIRST) then
        iROW := prsg_excel.LINE_CONTINUE('Строка5');
        fROW := nvl(fROW, iROW);
      else
        iROW := fROW + rSLP.Nrow - 1;
      end if;
      if rSLP.Compch_Type = 10 then
        prsg_excel.CELL_VALUE_WRITE('Начислено', 0, iROW, rSLP.Code);
        prsg_excel.CELL_VALUE_WRITE('НачисленоПериод', 0, iROW, rSLP.Speriod);
        prsg_excel.CELL_VALUE_WRITE('НачисленоПараметры', 0, iROW, rSLP.Sparams);
        prsg_excel.CELL_VALUE_WRITE('НачисленоСумма', 0, iROW, rSLP.Nsum);
      elsif rSLP.Compch_Type = 30 then
        prsg_excel.CELL_VALUE_WRITE('Удержано', 0, iROW, rSLP.Code);
        prsg_excel.CELL_VALUE_WRITE('УдержаноПериод', 0, iROW, rSLP.Speriod);
        prsg_excel.CELL_VALUE_WRITE('УдержаноСумма', 0, iROW, rSLP.Nsum);
      end if;
      -- Итого:
      if (rSLP.Nrow = rSLP.Ncount) then
        if (bFIRST) then
          iROWA := prsg_excel.LINE_CONTINUE('Строка6');
          prsg_excel.CELL_VALUE_WRITE('КВыдаче', 0, iROWA, rSLP.Nitogsum);
          bFIRST := false;
        end if;
        if rSLP.Compch_Type = 10 then
          prsg_excel.CELL_VALUE_WRITE('НачисленоВсего', 0, iROWA, rSLP.Nallsum);
        elsif rSLP.Compch_Type = 30 then
          prsg_excel.CELL_VALUE_WRITE('УдержаноВсего', 0, iROWA, rSLP.Nallsum);
        end if;
      end if;
    end loop;
  end loop;

  fini;
end PP_RLIST;
/
