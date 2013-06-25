create or replace procedure PP_TRANSF_AVB
/*
   * �������� ������������ � "�����������" ��� ����� �.�. ��������
   * ���������� �����, 17.09.2012 �.
  **/
(nCOMPANY   in number,
 nIDENT     in number,
 nTYPE      in number, -- 1 - ���, 2 - ��
 sBANK      in varchar2,
 sEXECUTIVE in varchar2,
 nMODE      in number, -- ����� ������
 nOUTIDENT  out number -- ������������� ������ ��������
 ) is
  i           number;
  sSUMM       VARCHAR2(250);
  cCLOB       CLOB;
  sFILENAME   VARCHAR2(100);
  sREESTR_NUM number;
  sTYPE       varchar2(3);
  sDM         varchar2(2) := chr(9);
  /**
   * ������ ��������� �������:
  **/
  cursor a(nIDEnT in number) is
    select a.*, --
           rownum,
           sum(a.transfsumm) over() nallsumm
      from (select aa.agnacc, --
                   ar.agnfamilyname,
                   ar.agnfirstname,
                   ar.agnlastname,
                   ar.agnfamilyname || ' ' || ar.agnfirstname || ' ' || ar.agnlastname sFIO,
                   st.transfsumm
              from sltransfers st, --
                   agnacc      aa,
                   agnlist     ar
             where aa.rn = st.bankattrs
               and ar.rn = st.recipient
               and st.rn in (select document from selectlist where ident = nIDENT)
             order by 2, 3, 4) a;

  /**
   * ������������� Excel
  **/
  procedure init is
    i number;
  begin
    if nTYPE = 1 then
      prsg_excel.PREPARE;
      prsg_excel.SHEET_SELECT('����1');
      prsg_excel.LINE_DESCRIBE('������');
      for i in 1 .. 6 loop
        prsg_excel.LINE_CELL_DESCRIBE('������', '�' || i);
      end loop;
      prsg_excel.CELL_DESCRIBE('������');
      prsg_excel.CELL_DESCRIBE('�������');
      prsg_excel.CELL_DESCRIBE('�����������');
    end if;
    if nType = 2 then
      prsg_excel.SHEET_SELECT('����2');
      prsg_excel.LINE_DESCRIBE('������2');
      for i in 1 .. 4 loop
        prsg_excel.LINE_CELL_DESCRIBE('������2', '�' || i);
      end loop;
      prsg_excel.CELL_DESCRIBE('������2');
      prsg_excel.CELL_DESCRIBE('����������');
      prsg_excel.CELL_DESCRIBE('�����2');
      prsg_excel.CELL_DESCRIBE('�����������2');
    end if;
  end;

  /**
   * ��������������� Excel
  **/
  procedure fini is
  begin
    if nTYPE = 1 then
      prsg_excel.LINE_DELETE('������');
      prsg_excel.SHEET_DELETE('����2');
    end if;
    if nTYPE = 2 then
      prsg_excel.LINE_DELETE('������2');
      prsg_excel.SHEET_DELETE('����1');
    end if;
  end;

  /**
   * ���������� ����� �������
  **/
  function reestr_number
  --
  (nTYPE in number) return number is
    Result number;
  begin
    update TP_TRANSF_NUM t
       set t.reestr_number = t.reestr_number + 1
     where t.reestr_type = nTYPE
       and t.reestr_year = to_char(sysdate, 'yyyy')
    returning reestr_number into Result;
    if sql%notfound then
      Result := 1;
      insert into TP_TRANSF_NUM (reestr_number, reestr_type, reestr_year) values (1, nTYPE, to_char(sysdate, 'yyyy'));
    end if;
    return Result;
  end;

  function tocp866
  --
  (sSTRING in varchar2) return varchar2 is
  begin
    --return convert(sSTRING, 'RU8PC866', 'CL8MSWIN1251');
    return sSTRING;
  end;

begin
  sREESTR_NUM := reestr_number(nTYPE);
  /**
   * ������������ ������ EXCEL:
  **/
  if nMODE <> 1 then
    init;
    i := null;
    for c in a(nIDENT) loop
      if nTYPE = 1 then
        if i is null then
          i := prsg_excel.LINE_APPEND('������');
          prsg_excel.CELL_VALUE_WRITE('������', '������ � ' || sREESTR_NUM || ' �� ' || to_char(sysdate, 'dd.mm.yyyy') || ' �.');
          p_money_sum_str(nCOMPANY, c.nallsumm, null, sSUMM);
          prsg_excel.CELL_VALUE_WRITE('�������', sSUMM);
          prsg_excel.CELL_VALUE_WRITE('�����������', sEXECUTIVE);
        else
          i := prsg_excel.LINE_CONTINUE('������');
        end if;
        prsg_excel.CELL_VALUE_WRITE('�1', 0, i, c.rownum);
        prsg_excel.CELL_VALUE_WRITE('�2', 0, i, c.agnacc);
        prsg_excel.CELL_VALUE_WRITE('�3', 0, i, c.agnfamilyname);
        prsg_excel.CELL_VALUE_WRITE('�4', 0, i, c.agnfirstname);
        prsg_excel.CELL_VALUE_WRITE('�5', 0, i, c.agnlastname);
        prsg_excel.CELL_VALUE_WRITE('�6', 0, i, c.transfsumm * 100);
      end if;
      if nTYPE = 2 then
        if i is null then
          i := prsg_excel.LINE_APPEND('������2');
          prsg_excel.CELL_VALUE_WRITE('������2', '������ � ' || sREESTR_NUM);
          prsg_excel.CELL_VALUE_WRITE('����������', '�� ' || to_char(sysdate, 'dd.mm.yyyy') || ' �.');
          p_money_sum_str(nCOMPANY, c.nallsumm, null, sSUMM);
          prsg_excel.CELL_VALUE_WRITE('�����2', c.nallsumm || ' (' || sSUMM || ')');
          prsg_excel.CELL_VALUE_WRITE('�����������2', sEXECUTIVE);
        else
          i := prsg_excel.LINE_CONTINUE('������2');
        end if;
        prsg_excel.CELL_VALUE_WRITE('�1', 0, i, c.rownum);
        prsg_excel.CELL_VALUE_WRITE('�2', 0, i, c.agnacc);
        prsg_excel.CELL_VALUE_WRITE('�3', 0, i, c.sFIO);
        prsg_excel.CELL_VALUE_WRITE('�4', 0, i, c.transfsumm);
      end if;
    end loop;
    fini;
  end if;

  /**
   * ������������ �������� � ����:
  **/
  if nMODE <> 0 then
    if nTYPE = 1 then
      sTYPE := '���';
    end if;
    if nTYPE = 2 then
      sTYPE := '���';
    end if;
    nOUTIDENT := GEN_IDENT;
    dbms_lob.createtemporary(cCLOB, True, dbms_lob.CALL);
    sFILENAME := '������ ' || sTYPE || ' ' || sREESTR_NUM || '.txt';
    for c in a(nIDENT) loop
      if nTYPE = 1 then
        dbms_lob.append(cCLOB,
                        rpad(trim(c.rownum), 6, ' ') || --
                        rpad(c.agnacc, 21, ' ') || --
                        rpad(tocp866(upper(c.agnfamilyname)), 31, ' ') || --
                        rpad(tocp866(upper(c.agnfirstname)), 17, ' ') || --
                        rpad(tocp866(upper(c.agnlastname)), 22, ' ') || --
                        lpad(trim(to_char(c.transfsumm * 100)), 11, ' ') || --
                        chr(13) || chr(10));
      end if;
      if nTYPE = 2 then
        dbms_lob.append(cCLOB,
                        rpad(c.agnacc, 25, ' ') || -- 
                        lpad(replace(trim(to_char(c.transfsumm)), ',', '.'), 13, ' ') || --
                        ' ' || tocp866(c.sfio) || --
                        chr(13) || chr(10));
      end if;
    end loop;
    insert into FILE_BUFFER
      (IDENT, FILENAME, DATA) --
    values
      (nOUTIDENT, sFILENAME, cCLOB);
    dbms_lob.trim(cCLOB, 0);
  end if;
end PP_TRANSF_AVB;
/
