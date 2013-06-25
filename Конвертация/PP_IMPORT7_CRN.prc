create or replace procedure PP_IMPORT7_CRN
--
(sCAPT in varchar2, sUNIT in varchar2) is
  sURN varchar2(4);
  sCRN varchar2(4);
begin

    select u.rn into sURN from p7_units u where u.name = sUNIT;
    select fp_nextrn7(max(rn)
                      keep(dense_rank last order by ascii(substr(rn, 1, 1)), --
                           ascii(substr(rn, 2, 1)),
                           ascii(substr(rn, 3, 1)),
                           ascii(substr(rn, 4, 1))))
      into sCRN
      from P7_ACATALOG t;
    for c in (select * from P7_ACATALOG t where t.rn = sCRN) loop
      p_exception(0, 'Такого не должно быть!');
    end loop;
    update p7_acatalog t
       set t.listname = t.listname || ' [' || sCAPT || ']',
           t.p7_level = t.p7_level + 1
     where t.unit_rn = sURN;
    update p7_acatalog t
       set t.parent_rn = sCRN
     where t.parent_rn is null
       and t.unit_rn = sURN;
    insert into p7_acatalog
      (rn, listname, p7_level, unit_rn)
    values
      (sCRN, sCAPT, 0, sURN);
    if sUNIT = 'zSubDivision' then
      for cc in (select rn
                   from p7_acatalog a
                  where a.parent_rn = sCRN
                    and a.unit_rn = sURN) loop
        insert into P7_ZSUBDIV
          (subdiv_rn,
           catalog_rn,
           code,
           name,
           num_ord,
           startdate,
           enddate,
           isstaff,
           isorg,
           directvip,
           ordernum,
           orderdate)
          select fp_nextrn7(max(t.subdiv_rn)
                            keep(dense_rank last order by
                                 ascii(substr(t.subdiv_rn, 1, 1)), --
                                 ascii(substr(t.subdiv_rn, 2, 1)),
                                 ascii(substr(t.subdiv_rn, 3, 1)),
                                 ascii(substr(t.subdiv_rn, 4, 1)))),
                 cc.rn,
                 SCAPT,
                 sCAPT,
                 0,
                 min(t.startdate),
                 max(t.enddate),
                 1,
                 0,
                 0,
                 '-',
                 min(t.orderdate)
            from P7_ZSUBDIV t;
      end loop;
    end if;
end PP_IMPORT7_CRN;
/
