create or replace procedure PP_INVENT_REP
-- Список ОС в Росимущество
(nCOMPANY  in number,
 dDATE     in date,
 sMOL      in varchar2,
 sACCOUNTS in varchar2 --
 ) is

  iROW number;
  MYID PKG_STD.tREF;

  cursor cREC(dDATE in date, MYID in number, sMOL in varchar2) is
    select rownum, a.*
      from (select dn.nomen_name || decode(i.object_model, null, null, ' ' || i.object_model) sname, --
                   trim(i.inv_number) inv_number,
                   i.item_count,
                   h.new_a_cost_begin,
                   h.new_a_amort_during + h.new_a_amort_begin new_a_amort,
                   h.new_a_cost_end
              from inventory i, --
                   dicnomns dn,
                   agnlist ag,
                   (select h.prn, --
                           max(h.new_account) keep(dense_rank last order by numb) account,
                           max(h.new_a_amort_during) keep(dense_rank last order by numb) new_a_amort_during,
                           max(h.new_a_cost_end) keep(dense_rank last order by numb) new_a_cost_end,
                           max(h.new_a_cost_begin) keep(dense_rank last order by numb) new_a_cost_begin,
                           max(h.new_a_amort_begin) keep(dense_rank last order by numb) new_a_amort_begin,
                           max(h.action_type) keep(dense_rank last order by numb) action_type,
                           max(h.agent_to) keep(dense_rank last order by numb) agent_to
                      from invhist h
                     where h.action_date <= dDATE
                     group by h.prn) h
             where i.rn = h.prn
               and (MYID is null or h.account in (select hid from IDLIST where ID = MYID))
               and dn.rn = i.nomenclature
               and h.action_type <> 4
               and ag.rn = h.agent_to
               and (sMOL is null or ';' || sMOL || ';' like '%;' || ag.agnabbr || ';%')
             order by sname, inv_number) a;

  -- Составляем список счетов, переданных в параметрах:
  procedure accList(sACCOUNTS in varchar2, MYID out number) is
    sACCOUNT DICACCS.Acc_Number%type;
  begin
    if sACCOUNTS is not null then
      MYID := gen_id;
      for i in 1 .. STRCNT(sACCOUNTS, ';') loop
        sACCOUNT := STRTOK(sACCOUNTS, ';', i);
        insert into IDLIST
          (ID, HID)
          select MYID, DA.RN from DICACCS DA where DA.ACC_NUMBER like sACCOUNT;
      end loop;
    else
      MYID := null;
    end if;
  end;

  procedure init is
  begin
    prsg_excel.PREPARE;
    prsg_excel.SHEET_SELECT('Лист1');
    prsg_excel.LINE_DESCRIBE('Строка');
    for i in 1 .. 7 loop
      prsg_excel.LINE_CELL_DESCRIBE('Строка', 'Д' || i);
    end loop;
    prsg_excel.CELL_DESCRIBE('Дата');
  end;

  procedure fini is
  begin
    prsg_excel.LINE_DELETE('Строка');
  end;

begin
  accList(replace(replace(sACCOUNTS, '*', '%'), '?', '_'), MYID);
  init;
  for rREC in cREC(dDATE, MYID, sMOL) loop
    if iROW is null then
      iROW := prsg_excel.LINE_APPEND('Строка');
      prsg_excel.CELL_VALUE_WRITE('Дата', 'на ' || to_char(dDATE, 'dd.mm.yyyy') || ' г.');
    else
      iROW := prsg_excel.LINE_CONTINUE('Строка');
    end if;
    prsg_excel.CELL_VALUE_WRITE('Д1', 0, iRow, rREC.rownum);
    prsg_excel.CELL_VALUE_WRITE('Д2', 0, iRow, rREC.Sname);
    prsg_excel.CELL_VALUE_WRITE('Д3', 0, iRow, rREC.Inv_Number);
    prsg_excel.CELL_VALUE_WRITE('Д4', 0, iRow, rREC.Item_Count);
    prsg_excel.CELL_VALUE_WRITE('Д5', 0, iRow, rREC.New_a_Cost_Begin);
    prsg_excel.CELL_VALUE_WRITE('Д6', 0, iRow, rREC.New_a_Amort);
    prsg_excel.CELL_VALUE_WRITE('Д7', 0, iRow, rREC.New_a_Cost_End);
  end loop;
  fini;
  delete from IDLIST t where t.id = MYID;
end PP_INVENT_REP;
/
