create or replace procedure PP_QUALIFCTG_VIEW
/**
  * ���������������� ����� �� �������� ���������������� ���������
  * ��� ������ ������ ���������� ������� �������� ��� ��� ���������� � ����� "���������������� ���������", 
  * ������ ��: /CM=# /SC=������:20;������:15;������:10
  */
(nCOMPANY  in number,
 nIDENT    in number,
 sUNIT     in varchar2,
 dDATE     in date,
 sGRSALARY in varchar2, -- ������ ��� � ����������� ��
 sGRCATSAL in varchar2, -- ������ ��������� ��� ��� ������ (�� ������������)
 nDIFFONLY in number -- �������� ������ ������� (���� != ����)
 ) is
  nGRSALARY PKG_STD.tREF;
  nGRCATSAL PKG_STD.tREF;
  i         PKG_STD.tNUMBER;
  nTYPE     PKG_STD.tNUMBER;
  /**
   * ������� ������:
  **/
  cursor a(dDATE     in date, --
           nGRSALARY in number,
           nGRCATSAL in number,
           nIDENT    in number,
           nTYPE     in number) is
    select trim(cp.tab_numb) sTABNUMB, --
           ag.agnfamilyname || ' ' || ag.agnfirstname || ' ' || ag.agnlastname sFIO,
           po.name spostname,
           gs2.summ,
           hs.rateacc,
           ct.code clnpspfmtypescode,
           cx.dfrom,
           cx.code sqctg,
           nvl(gs.coeffic, 0) coeffic,
           case
             when (add_months(cx.dfrom, 5 * 12) < dDATE) then
              0
             else
              FP_QUALIF_COEFF(cp.company, nGRSALARY, cp.rn, dDATE)
           end nRate,
           de.name sdepartment,
           row_number() over(partition by de.name order by de.name, ag.agnfamilyname || ' ' || ag.agnfirstname || ' ' || ag.agnlastname, ct.is_primary desc, pf.rn) row_dep,
           count(1) over(partition by de.name) cnt_dep
      from clnpersons cp,
           agnlist ag,
           clnpspfm pf,
           clnpspfmhs hs,
           clnpsdep cd,
           clnposts po,
           ins_department de,
           clnpspfmtypes ct,
           (select GS.COEFFIC, GS.PRN
              from CLNPSPFMGS GS
             where dDATE between GS.DO_ACT_FROM and nvl(GS.DO_ACT_TO, dDATE)
               and GS.GRSALARY = nGRSALARY) GS,
           (select sum(GS.SUMM) SUMM, GS.PRN
              from CLNPSPFMGS GS, GRCATSALSP SP
             where dDATE between GS.DO_ACT_FROM and nvl(GS.DO_ACT_TO, dDATE)
               and GS.GRSALARY = SP.GRSALARYRN
               and SP.PRN = nGRCATSAL
             group by GS.PRN) GS2,
           (select code, dfrom, prn
              from (select pq.code, --
                           ct.prn,
                           ct.ctgdate dfrom,
                           lead(ct.ctgdate) over(partition by ct.prn order by ct.ctgdate) - 1 dtill
                      from CLNPRQUALIFCTG ct, PRQUALIFCTG pq
                     where pq.rn = ct.prqualifctg) cx
             where dDATE between cx.dfrom and nvl(dtill, dDATE)) cx
     where ag.rn = cp.pers_agent
       and cp.rn = pf.persrn
       and cd.rn(+) = pf.psdeprn
       and po.rn = nvl(cd.postrn, pf.postrn)
       and ct.rn = pf.clnpspfmtypes
       and de.rn = pf.deptrn
       and pf.rn = hs.prn
       and gs.prn(+) = pf.rn
       and gs2.prn(+) = pf.rn
       and dDATE between hs.do_act_from and nvl(hs.do_act_to, dDATE)
       and (((nTYPE = 1) and pf.rn in (select document from selectlist where ident = nIDENT)) --
           or ((nTYPE = 2) and cp.rn in (select document from selectlist where ident = nIDENT)))
       and ((nDIFFONLY = 0) --
           or (nvl(gs.coeffic, 0) <> FP_QUALIF_COEFF(cp.company, nGRSALARY, cp.rn, dDATE)) --
           or (add_months(cx.dfrom, 5 * 12) < dDATE and nvl(gs.coeffic, 0) <> 0) -- ���� ������ ��� 5 ���, � ����������� ��� ����
           )
       and cx.prn(+) = cp.rn
     order by de.name, ag.agnfamilyname || ' ' || ag.agnfirstname || ' ' || ag.agnlastname, ct.is_primary desc, pf.rn;

  /**
   * ������������� excel
  **/
  procedure init
  
   is
    i number;
  begin
    prsg_excel.PREPARE;
    prsg_excel.SHEET_SELECT('����1');
    prsg_excel.LINE_DESCRIBE('������');
    for i in 1 .. 10 loop
      prsg_excel.LINE_CELL_DESCRIBE('������', '�' || i);
    end loop;
    prsg_excel.LINE_DESCRIBE('�����');
    prsg_excel.LINE_CELL_DESCRIBE('�����', '������');
    prsg_excel.COLUMN_DESCRIBE('�����');
    prsg_excel.CELL_DESCRIBE('���������');
  end;

  /**
   * ��������������� excel
  **/
  procedure fini is
  begin
    prsg_excel.LINE_DELETE('������');
    prsg_excel.LINE_DELETE('�����');
    if sGRCATSAL is null then
      prsg_excel.COLUMN_DELETE('�����');
    end if;
  end;

begin

  if sUNIT = 'ClientPostPerform' then
    nTYPE := 1;
  elsif sUNIT = 'ClientPersons' then
    nTYPE := 2;
  else
    p_exception(0, '����� �� ����� ���� ������ �� ������� ' || sUNIT);
  end if;

  /**
   * �������������:
  **/
  init;
  find_grsalary_code(0, 0, nCOMPANY, sGRSALARY, nGRSALARY);
  find_grcatsal_code(0, 1, nCOMPANY, sGRCATSAL, nGRCATSAL);
  i := null;
  /**
   * ������� ����:
  **/
  for c in a(dDATE, nGRSALARY, nGRCATSAL, nIDENT, nTYPE) loop
    if c.row_dep = 1 then
      if i is null then
        i := prsg_excel.LINE_APPEND('�����');
        prsg_excel.CELL_VALUE_WRITE('���������', '����� �� �������� ���������������� ��������� ����������� �� ���� ' || to_char(dDATE, 'dd.mm.yyyy') || ' �.');
      else
        i := prsg_excel.LINE_CONTINUE('�����');
      end if;
      prsg_excel.CELL_VALUE_WRITE('������', 0, i, c.sdepartment);
    end if;
    i := prsg_excel.LINE_CONTINUE('������');
    prsg_excel.CELL_VALUE_WRITE('�1', 0, i, c.stabnumb);
    prsg_excel.CELL_VALUE_WRITE('�2', 0, i, c.sfio);
    prsg_excel.CELL_VALUE_WRITE('�3', 0, i, c.spostname);
    prsg_excel.CELL_VALUE_WRITE('�4', 0, i, c.summ);
    prsg_excel.CELL_VALUE_WRITE('�5', 0, i, c.rateacc);
    prsg_excel.CELL_VALUE_WRITE('�6', 0, i, to_char(c.dfrom, 'dd.mm.yyyy'));
    prsg_excel.CELL_VALUE_WRITE('�7', 0, i, c.sqctg);
    prsg_excel.CELL_VALUE_WRITE('�8', 0, i, c.coeffic);
    prsg_excel.CELL_VALUE_WRITE('�9', 0, i, c.nrate);
    prsg_excel.CELL_VALUE_WRITE('�10', 0, i, c.clnpspfmtypescode);
  end loop;
  fini;
end PP_QUALIFCTG_VIEW;
/
