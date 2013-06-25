create or replace procedure PP_REPORT_SOVM
-- �������� � ���������� �������������
( --
 dDATE    in date, --
 sExclude in varchar2 -- ��������� ���� ����������
 ) is
  i number;
begin
  prsg_excel.PREPARE;
  prsg_excel.SHEET_SELECT('����1');
  prsg_excel.CELL_DESCRIBE('����');
  prsg_excel.LINE_DESCRIBE('������');
  prsg_excel.LINE_CELL_DESCRIBE('������', '�������');
  prsg_excel.LINE_DESCRIBE('������');
  for i in 1 .. 4 loop
    prsg_excel.LINE_CELL_DESCRIBE('������', '�' || i);
  end loop;
  prsg_excel.CELL_VALUE_WRITE('����', '�� ��������� �� ' || to_char(dDATE, 'dd.mm.yyyy') || ' �.');
  for c in (select rownum, --
                   a.*,
                   row_number() over(partition by a.sdepartment order by a.sdepartment, a.sfio, a.spost) rn,
                   count(1) over(partition by a.sdepartment order by a.sdepartment) cn,
                   a.spost || ' (' || a.srateacc || ') - � ' || to_char(a.do_act_from, 'dd.mm.yyyy') || decode(a.do_act_to, null, null, ' �� ' || to_char(a.do_act_to, 'dd.mm.yyyy')) s3
              from (select upper(a.agnfamilyname) || ' ' || chr(10) || a.agnfirstname || ' ' || a.agnlastname sfio, --
                           trim(cp.tab_numb) tab_numb,
                           clp.name spost,
                           trim(rtrim(to_char(hs.rateacc, '990.999'), '0.')) srateacc,
                           hs.do_act_from,
                           hs.do_act_to,
                           ind.name sdepartment,
                           tpr.*
                      from clnpspfm pf, --
                           clnpspfmhs hs,
                           clnpspfmtypes ct,
                           clnpersons cp,
                           agnlist a,
                           clnpsdep cd,
                           clnposts clp,
                           (select pf.persrn, clp.name sprimarypost, ind.code sprimarydepartment
                              from clnpspfm pf, clnpspfmtypes ct, clnpsdep cd, clnposts clp, ins_department ind
                             where pf.clnpspfmtypes = ct.rn
                               and ct.is_primary = 1
                               and dDATE between pf.begeng and nvl(pf.endeng, dDATE)
                               and pf.psdeprn = cd.rn
                               and cd.postrn = clp.rn
                               and cd.deptrn = ind.rn) tpr,
                           ins_department ind
                     where pf.clnpspfmtypes = ct.rn
                       and ct.is_primary = 0
                       and (sExclude is null or ';' || sExclude || ';' not like '%;' || ct.code || ';%')
                       and pf.persrn = cp.rn
                       and cp.pers_agent = a.rn
                       and pf.psdeprn = cd.rn
                       and cd.postrn = clp.rn
                       and hs.prn = pf.rn
                       and dDATE between hs.do_act_from and nvl(hs.do_act_to, dDATE)
                       and tpr.persrn(+) = pf.persrn
                       and cd.deptrn = ind.rn
                     order by sdepartment, sfio, spost) a) loop
    if c.rn = 1 then
      if c.rownum = 1 then
        i := prsg_excel.LINE_APPEND('������');
      else
        i := prsg_excel.LINE_CONTINUE('������');
      end if;
      prsg_excel.CELL_VALUE_WRITE('�������', 0, i, c.sdepartment);
    end if;
    i := prsg_excel.LINE_CONTINUE('������');
    prsg_excel.CELL_VALUE_WRITE('�1', 0, i, c.rownum);
    prsg_excel.CELL_VALUE_WRITE('�2', 0, i, c.sfio || ' (' || c.tab_numb || ')');
    prsg_excel.CELL_VALUE_WRITE('�3', 0, i, c.s3);
    prsg_excel.CELL_VALUE_WRITE('�4', 0, i, c.sprimarypost || chr(10) || c.sprimarydepartment);
  end loop;
  prsg_excel.LINE_DELETE('������');
  prsg_excel.LINE_DELETE('������');
end PP_REPORT_SOVM;
/*create public synonym PP_REPORT_SOVM for PP_REPORT_SOVM;
  grant execute on PP_REPORT_SOVM to public;*/
/
