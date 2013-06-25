create or replace procedure PP_REGRESSIA
-- ����� "�������� ������ (���������)"
(nIDENT in number, BDATE in date, EDATE in DATE, sSLCOMPGR in varchar2, nERRONLY in number) is

  nMPSUMM          number := 4000;
  sSCALES_FSS      varchar2(500) := '���;�����';
  sSCALES_PFS      varchar2(500) := '���1;���2;����������;���1;���2;���.����� 58.3 �.1;���.����� 58.3 �.2';
  sSCALES_BEFORE67 varchar2(500) := '���1;���1';
  sSCALES_AFTER66  varchar2(500) := '���2;���2';
  sSCALE           SALTAXSCALE.CODE%type;
  psSCALE          SALTAXSCALE.CODE%type;
  nBASE            number;
  nBASE_CALC       number;
  nNALOG           number;
  sGROUP           varchar2(200);
  nFACT_SUM        number;
  nDISC            number;
  nNEOBL           number;

  iROW number;
  iCOL number;
  nROW number;

  cursor cSCALE(sCODE in varchar2, EDATE in date) is
    select s.percent percent, --
           lag(s.income) over(order by income) income_from,
           s.income income_to,
           row_number() over(order by income) nrow,
           sum(s.percent * s.income / 100) over(order by income) - s.percent * s.income / 100 nPREVSUM,
           count(1) over() ncount
      from SALTAXSCALE sa, SALTAXEDITS MS, SALTAXSTRUC S
     where sa.code = sCODE
       and ms.PRN = sa.rn
       and s.prn = ms.rn
       and ms.edtax_begin = (select max(ms.edtax_begin)
                               from SALTAXEDITS MS
                              where PRN = sa.rn
                                and ms.edtax_begin <= EDATE)
     order by income;

  cursor cPERS(nIDENT in number, sSLCOMPGR in varchar2, nMPSUM in number, BDATE in date, EDATE in date) is
    select a.clnpersons, --
           a.agnburn,
           a.summ_doh,
           a.summ_vmen,
           a.summ_neobl,
           a.summ_mp,
           a.MPSUM,
           a.summ_fss,
           a.summ_ffoms,
           a.summ_pfs,
           a.summ_solid,
           a.summ_dt,
           a.summ_pfn,
           a.summ_doh + a.MPSUM baza_fss, -- tfoms, ffoms
           a.summ_doh + a.MPSUM + a.summ_vmen baza_pfs, -- solid, pfn
           a.summ_neobl + a.summ_mp - a.MPSUM summ_neobl_all,
           a.summ_mp - a.MPSUM summ_disc_all,
           a.ndeptrn,
           a.summ_doh_sol1,
           a.summ_doh_sol2,
           (1 - a.contract_sign) * (a.summ_doh + a.MPSUM) baza_fss_dog
      from (select t.clnpersons as clnpersons, --
                   max(cp.contract_sign) contract_sign,
                   max(ag.agnburn) as agnburn,
                   max(decode(ct.is_primary, 1, pf.deptrn)) keep(dense_rank last order by pf.begeng) ndeptrn,
                   sum(decode(y.formula, '+', t.sum, 0)) as summ_doh, -- ���������� �����
                   sum(decode(y.formula, 'V', t.sum, 0)) as summ_vmen, -- ��������� �����
                   sum(decode(y.formula, 'N', t.sum, 0)) as summ_neobl, -- ������������ �����
                   sum(decode(y.formula, 'E', t.sum, 0)) as summ_mp, -- ���.������
                   case
                     when (sum(decode(y.formula, 'E', t.sum, 0)) > nMPSUM) then
                      sum(decode(y.formula, 'E', t.sum, 0)) - nMPSUM
                     else
                      0
                   end MPSUM,
                   -- �����:
                   sum(decode(y.formula, 'S', t.sum, 0)) as summ_fss, -- ���
                   sum(decode(y.formula, 'F', t.sum, 0)) as summ_ffoms, -- �����
                   sum(decode(y.formula, 'C', t.sum, 0)) as summ_pfs, -- ��� 
                   sum(decode(y.formula, 'C2', t.sum, 0)) as summ_solid, -- ����������
                   sum(decode(y.formula, 'DT', t.sum, 0)) as summ_dt, -- ���.�����
                   sum(decode(y.formula, 'H', t.sum, 0)) as summ_pfn, -- ���      
                   sum(decode(y.formula, '+', t.sum, 0) * pkg_clnpspfm.check_tar_sol_pfr(pf.rn, INT2DATE(1, t.MONTH, t.YEAR), 1)) summ_doh_sol1, -- ���������� ����� � ������ ���.������ 1
                   sum(decode(y.formula, '+', t.sum, 0) * pkg_clnpspfm.check_tar_sol_pfr(pf.rn, INT2DATE(1, t.MONTH, t.YEAR), 2)) summ_doh_sol2 -- ���������� ����� � ������ ���.������ 2
              from SLPAYS         t, --
                   SLCOMPGR       r,
                   SLCOMPGRSTRUCT y,
                   agnlist        ag,
                   clnpersons     cp,
                   clnpspfm       pf,
                   clnpspfmtypes  ct,
                   selectlist     sl
             where SL.IDENT = nIDENT
               and t.clnpersons = SL.DOCUMENT
               and t.agent = ag.rn
               and r.code = sSLCOMPGR
               and y.prn = r.rn
               and t.year >= to_number(to_char(BDATE, 'YYYY'))
               and t.year <= to_number(to_char(EDATE, 'YYYY'))
               and t.month >= to_number(to_char(BDATE, 'MM'))
               and t.month <= to_number(to_char(EDATE, 'MM'))
               and t.slcompcharges = y.slcompcharges
               and t.clnpspfm = pf.rn
               and pf.clnpspfmtypes = ct.rn
               and t.clnpersons = cp.rn
             GROUP by t.clnpersons) a;

  cursor cREC is
    select a.*, --
           dense_rank() over(order by GROUP_NAME, AGNFAMILYNAME, AGNFIRSTNAME, AGNLASTNAME) nROW, -- ����� ��
           row_number() over(partition by CLNPERSONS order by GROUP_NAME, AGNFAMILYNAME, AGNFIRSTNAME, AGNLASTNAME, SCALE_CODE) nROW2, -- ���� 1 - �������� ����� �������
           row_number() over(partition by GROUP_NAME order by GROUP_NAME, AGNFAMILYNAME, AGNFIRSTNAME, AGNLASTNAME, SCALE_CODE) nROW_GROUP, -- ���� 1 - �������� ����� ������
           dense_rank() over(order by SCALE_CODE) nCOL
      from (select AG.AGNFAMILYNAME, --
                   AG.AGNFIRSTNAME,
                   AG.AGNLASTNAME,
                   DE.NAME SDEPARTMENT,
                   trim(CP.TAB_NUMB) TAB_NUMB,
                   to_char(AG.AGNBURN, 'dd.mm.yyyy') sAGNBURN,
                   decode(AG.SEX, 1, '���', '���') sSEX,
                   max(sERR) over(partition by TT.CLNPERSONS) sERRMAX,
                   TT.*
              from (select T.CLNPERSONS, --
                           T.DEPTRN,
                           max(decode(T.SCALE_CODE, '���', max(T.GROUP_NAME))) over(partition by T.CLNPERSONS) GROUP_NAME, -- ��������� ����� �� ���
                           T.SCALE_CODE,
                           (T.BASE_SUM) BASE_SUM,
                           (T.FACT_SUM_DISC) FACT_SUM_DISC,
                           (T.FACT_SUM_NEOBL) FACT_SUM_NEOBL,
                           sum(T.NALOG_SUM) NALOG_SUM,
                           (T.FACT_SUM) FACT_SUM,
                           decode(sum(T.NALOG_SUM) - T.FACT_SUM, 0, null, '!') sERR
                      from TP_REGRESSIA T
                     where t.authid = user
                     group by T.CLNPERSONS, --
                              T.DEPTRN,
                              T.SCALE_CODE,
                              T.BASE_SUM,
                              T.FACT_SUM_DISC,
                              T.FACT_SUM_NEOBL,
                              T.FACT_SUM) TT,
                   CLNPERSONS CP,
                   AGNLIST AG,
                   INS_DEPARTMENT DE
             where TT.CLNPERSONS = CP.RN
               and CP.PERS_AGENT = AG.RN
               and DE.RN = TT.DEPTRN
             order by GROUP_NAME, AGNFAMILYNAME, AGNFIRSTNAME, AGNLASTNAME, SCALE_CODE) a
     where (nERRONLY = 0 or a.sERRMAX is not null)
     order by GROUP_NAME, AGNFAMILYNAME, AGNFIRSTNAME, AGNLASTNAME, SCALE_CODE;

  procedure init is
  begin
    prsg_excel.PREPARE;
    prsg_excel.SHEET_SELECT('����1');
    prsg_excel.CELL_DESCRIBE('������');
    prsg_excel.LINE_DESCRIBE('������');
    prsg_excel.LINE_DESCRIBE('������');
    prsg_excel.LINE_DESCRIBE('������2');
    prsg_excel.COLUMN_DESCRIBE('�������');
    prsg_excel.LINE_CELL_DESCRIBE('������', '�������');
    prsg_excel.LINE_CELL_DESCRIBE('������', '�����');
    prsg_excel.LINE_CELL_DESCRIBE('������', '���������');
    prsg_excel.LINE_CELL_DESCRIBE('������', '��������');
    prsg_excel.LINE_CELL_DESCRIBE('������', '������');
    prsg_excel.LINE_CELL_DESCRIBE('������', '������');
    prsg_excel.COLUMN_CELL_DESCRIBE('�������', '������');
    prsg_excel.COLUMN_CELL_DESCRIBE('�������', '��������');
  end;

  procedure fini is
  begin
    prsg_excel.LINE_DELETE('������');
    prsg_excel.LINE_DELETE('������');
    prsg_excel.LINE_DELETE('������2');
    prsg_excel.COLUMN_DELETE('�������');
  end;

begin
  delete from TP_REGRESSIA t where t.authid = user;
  -- ���� �� �����������:
  for rPERS in cPERS(nIDENT, sSLCOMPGR, nMPSUMM, BDATE, EDATE) loop
    -- ���� �� ���� ������:
    for k in 1 .. stroccurs(sSCALES_FSS || ';' || sSCALES_PFS, ';') + 1 loop
      sSCALE := strtok(sSCALES_FSS || ';' || sSCALES_PFS, ';', k);
      -- ����������� ����:
      if instr(sSCALES_FSS, sSCALE) > 0 then
        nBASE := rPERS.Baza_Fss;
      elsif instr(sSCALES_PFS, sSCALE) > 0 then
        nBASE := rPERS.Baza_Pfs;
      else
        nBASE := 0;
      end if;
      nBASE_CALC := nBASE;
      -- ����������� �����:
      psSCALE := sSCALE;
      if sSCALE = '���' then
        nFACT_SUM  := rPERS.Summ_Fss;
        nBASE_CALC := rPERS.BAZA_FSS_DOG;
      elsif sSCALE = '�����' then
        nFACT_SUM := rPERS.Summ_Ffoms;
      elsif sSCALE in ('���1', '���2') then
        psSCALE   := '���';
        nFACT_SUM := rPERS.Summ_Pfs;
      elsif sSCALE = '����������' then
        nFACT_SUM := rPERS.Summ_Solid;
      elsif sSCALE in ('���1', '���2') then
        psSCALE   := '���';
        nFACT_SUM := rPERS.Summ_Pfn;
      elsif sSCALE in ('���.����� 58.3 �.1', '���.����� 58.3 �.2') then
        psSCALE    := '���.����� 58.3';
        nFACT_SUM  := rPERS.Summ_DT;
        nBASE_CALC := 0;
        if sSCALE = '���.����� 58.3 �.1' then
          nBASE_CALC := rPERS.Summ_Doh_Sol1;
        elsif sSCALE = '���.����� 58.3 �.2' then
          nBASE_CALC := rPERS.Summ_Doh_Sol2;
        end if;
        if (nBASE_CALC <> 0) then
          nBASE_CALC := nBASE_CALC + rPERS.MPSUM + rPERS.summ_vmen;
        end if;
      else
        psSCALE   := '?';
        nFACT_SUM := 0;
      end if;
    
      -- ���� �� ��������� �����:
      sGROUP := '';
      nNALOG := 0;
      for rSCALE in cSCALE(sSCALE, EDATE) loop
        if (nBASE > nvl(rSCALE.Income_From, nBASE - 1)) and (nBASE <= rSCALE.Income_To) then
          if rSCALE.Income_From is not null then
            sGROUP := '�� ' || rSCALE.Income_From || ' ���.';
          end if;
          if rSCALE.Nrow <> rSCALE.Ncount then
            sGROUP := sGROUP || ' �� ' || rSCALE.Income_To || ' ���.';
          end if;
          nNALOG := Round((nBASE_CALC - nvl(rSCALE.Income_From, 0)) * rSCALE.Percent / 100 + rSCALE.nPREVSUM, 2);
        end if;
      end loop;
    
      nDISC  := rPERS.summ_disc_all;
      nNEOBL := rPERS.summ_neobl_all;
    
      -- ����������� �� ����� ��������:
      if (D_YEAR(rPERS.Agnburn) <= 1966) and (instr(sSCALES_AFTER66, sSCALE) > 0) then
        nNALOG := 0;
      end if;
      if (D_YEAR(rPERS.Agnburn) >= 1967) and (instr(sSCALES_BEFORE67, sSCALE) > 0) then
        nNALOG := 0;
      end if;
    
      insert into TP_REGRESSIA
        (authid, ident, clnpersons, group_name, scale_code, base_sum, nalog_sum, fact_sum, fact_sum_disc, fact_sum_neobl, deptrn) --
      values
        (user, nIDENT, rPERS.Clnpersons, sGROUP, psSCALE, nBASE, nNALOG, nFACT_SUM, nDISC, nNEOBL, rPERS.ndeptrn);
    
    end loop;
  end loop;

  init;

  prsg_excel.CELL_VALUE_WRITE('������', '�� ������ � ' || to_char(BDATE, 'dd.mm.yyyy') || ' �. �� ' || to_char(EDATE, 'dd.mm.yyyy') || ' �.');

  for rREC in cREC loop
    if rREC.Nrow2 = 1 then
      -- ����� ���������:
      -- ������� 6 �����:
      for i in 1 .. 6 loop
        -- ���� ����� ����� ��������:
        if (i = 1) and (rREC.Nrow_Group = 1) then
          if iROW is null then
            iROW := prsg_excel.LINE_APPEND('������');
          else
            iROW := prsg_excel.LINE_CONTINUE('������');
          end if;
          prsg_excel.CELL_VALUE_WRITE('�������', 0, iROW, rREC.Group_Name);
        end if;
        -- ��������� ������:
        iROW := prsg_excel.LINE_CONTINUE('������');
        if i = 1 then
          prsg_excel.CELL_VALUE_WRITE('�����', 0, iROW, rREC.Nrow);
          prsg_excel.CELL_VALUE_WRITE('���������', 0, iROW, rREC.Agnfamilyname);
          prsg_excel.CELL_VALUE_WRITE('��������', 0, iROW, '����� ������');
        elsif i = 2 then
          prsg_excel.CELL_VALUE_WRITE('���������', 0, iROW, rREC.Agnfirstname);
          prsg_excel.CELL_VALUE_WRITE('��������', 0, iROW, '������������ �����');
        elsif i = 3 then
          prsg_excel.CELL_VALUE_WRITE('���������', 0, iROW, rREC.Agnlastname);
          prsg_excel.CELL_VALUE_WRITE('��������', 0, iROW, '������ �� ���.���');
        elsif i = 4 then
          prsg_excel.CELL_VALUE_WRITE('���������', 0, iROW, rREC.Tab_Numb);
          prsg_excel.CELL_VALUE_WRITE('��������', 0, iROW, '���������� �����');
        elsif i = 5 then
          prsg_excel.CELL_VALUE_WRITE('���������', 0, iROW, rREC.Sdepartment);
          prsg_excel.CELL_VALUE_WRITE('��������', 0, iROW, '��������� ������');
        elsif i = 6 then
          prsg_excel.CELL_VALUE_WRITE('���������', 0, iROW, rREC.Sagnburn || ' ' || rREC.Ssex);
          prsg_excel.CELL_VALUE_WRITE('��������', 0, iROW, '������ ���� ���������');
        end if;
        prsg_excel.CELL_VALUE_WRITE('������', 0, iROW, rREC.Serrmax);
      end loop;
      -- iROW = 6� ������, iROW - 5 = 1� ������
      nROW := prsg_excel.LINE_CONTINUE('������2');
    end if;
    -- ������� �������:
    while nvl(iCOL, 0) < rREC.Ncol loop
      if iCOL is null then
        iCOL := prsg_excel.COLUMN_APPEND('�������');
      else
        iCOL := prsg_excel.COLUMN_CONTINUE('�������');
      end if;
    end loop;
    -- ������� ������:
    prsg_excel.CELL_VALUE_WRITE('��������', rREC.Ncol, 0, rREC.Scale_Code);
    prsg_excel.CELL_VALUE_WRITE('������', rREC.Ncol, iROW - 5, rREC.Base_Sum + rREC.Fact_Sum_Neobl);
    prsg_excel.CELL_VALUE_WRITE('������', rREC.Ncol, iROW - 4, rREC.Fact_Sum_Neobl);
    prsg_excel.CELL_VALUE_WRITE('������', rREC.Ncol, iROW - 3, rREC.Fact_Sum_Disc);
    prsg_excel.CELL_VALUE_WRITE('������', rREC.Ncol, iROW - 2, rREC.Base_Sum);
    prsg_excel.CELL_VALUE_WRITE('������', rREC.Ncol, iROW - 1, rREC.Fact_Sum);
    prsg_excel.CELL_VALUE_WRITE('������', rREC.Ncol, iROW, rREC.Nalog_Sum);
    if rREC.Serr is not null then
      prsg_excel.CELL_ATTRIBUTE_SET('������', rREC.Ncol, iROW - 1, 'Font.ColorIndex', 3);
      prsg_excel.CELL_ATTRIBUTE_SET('������', rREC.Ncol, iROW, 'Font.ColorIndex', 3);
    end if;
  end loop;

  fini;

end PP_REGRESSIA;
/
