create or replace procedure PP_COPY_BUDGEXPEND_SP
-- Копируем смету
(nFROM in number, nTO in number) is
begin
  for c in (select t.sum_dist_q1, --
                   t.sum_dist_q2,
                   t.sum_dist_q3,
                   t.sum_dist_q4,
                   t.sum_dist_y,
                   t2.rn,
                   e.code        ssubcode,
                   e.name        ssubcodename,
                   e.hier_level
              from BUDGEXPEND_SP t, EXPSTRUCTITEMS e, BUDGEXPEND_SP t2, EXPSTRUCTITEMS e2
             where t.expstructitems = e.rn
               and t.prn = nFROM
               and t2.prn = nTO
               and t2.expstructitems = e2.rn
               and (e2.code = e.code or e2.econclass = e.econclass)
             order by e.sort_number) loop
    update BUDGEXPEND_SP a
       set a.sum_dist_y  = c.sum_dist_y, --
           a.sum_dist_q1 = c.sum_dist_q1,
           a.sum_dist_q2 = c.sum_dist_q2,
           a.sum_dist_q3 = c.sum_dist_q3,
           a.sum_dist_q4 = c.sum_dist_q4
     where a.rn = c.rn;
  end loop;
  for c in (select * from BUDGEXPEND t where t.rn = nFROM) loop
    update BUDGEXPEND a
       set a.sum_dist_y  = c.sum_dist_y, --
           a.sum_dist_q1 = c.sum_dist_q1,
           a.sum_dist_q2 = c.sum_dist_q2,
           a.sum_dist_q3 = c.sum_dist_q3,
           a.sum_dist_q4 = c.sum_dist_q4
     where a.rn = nTO;
  end loop;
end PP_COPY_BUDGEXPEND_SP;
/
