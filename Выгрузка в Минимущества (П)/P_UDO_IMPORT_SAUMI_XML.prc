create or replace procedure P_UDO_IMPORT_SAUMI_XML
--
(nIDENT       in number, -- ����������
 nCOMPANY     in number, -- �����������
 dDATE        in date, -- ���� ������
 nREGIM       in number, -- ����� (1 - ���������, 2 - �� < 100 000, 3 - �� > 100 000, 4 - ���������)
 sFile        in varchar2,
 nStartNumber in number,
 sOUT         out varchar2) as
  /* ������ � ������������ */

  cCLOB                clob default null;
  cTEMP                varchar2(4000) default null;
  cTEMP1               varchar2(4000) default null;
  cTEMP3               varchar2(4000) default null;
  sFileName            varchar2(35);
  sDef                 VARCHAR2(1);
  v_min_date           DATE;
  v_spis_date          DATE;
  v_new_a_cost_begin   NUMBER;
  v_new_a_amort_during NUMBER;
  v_new_a_amort_begin  NUMBER;
  v_fdoc_numb          VARCHAR2(20);
  v_fdoc_date          DATE;
  v_spis_fdoc_numb     VARCHAR2(20);
  v_spis_fdoc_date     DATE;
  v_spis_fdoc_name     DOCTYPES.DOCNAME%type;
  nKOl                 integer := 0;
  nKol2                number := 0;
  ntransptype_id       number := 1;
  nbrandnames_id       number := 841;
  ndoctypes_id         number := 758;
  ndoctypes4_id        number;
  npropsections_id     number := 4;
  npropgroups_id       number := 21;
  npropnames_id        number := 1;
  nmovetype4_id        number := 18;
  ndocrole             number := 8;
  nXMLVersion          number := 2;
  /* 
    1 - ������� ������ 
    2 - �������� ���� regno
  */

  PROCEDURE report_to_buff IS
  BEGIN
    INSERT INTO FILE_BUFFER (IDENT, AUTHID, FILENAME, DATA) VALUES (nIDENT, user, sFileNAME, cCLOB);
  END;

begin
  sFileNAME := sFile;
  if nvl(lower(substr(sFileNAME, length(sFileNAME) - 3)), '-1') <> '.xml' then
    sFileNAME := sFileNAME || '.xml';
  end if;

  /* ������� ����� ����� */
  dbms_lob.createtemporary(cCLOB, true);

  cTEMP := '<?xml version="1.0" encoding="windows-1251"?>' || CHR(13) --
           || '<objects xmlns="http://mio.samregion.ru/datacollector"' || CHR(13) --
           || '         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">';
  dbms_lob.writeappend(cCLOB, length(cTEMP), cTEMP);

  if table_exists('DC_TRANSPTYPE') > 0 then
    begin
      execute immediate 'select ID from DC_TRANSPTYPE where NAME = :a'
        into ntransptype_id
        using '�� �������';
    exception
      when no_data_found then
        null;
    end;
  end if;

  if table_exists('DC_BRANDNAMES') > 0 then
    begin
      execute immediate 'select ID from DC_BRANDNAMES where NAME = :a'
        into nbrandnames_id
        using '�� �������';
    exception
      when no_data_found then
        null;
    end;
  end if;

  if table_exists('DC_DOCTYPES') > 0 then
    begin
      execute immediate 'select ID from DC_DOCTYPES where NAME = :a'
        into ndoctypes_id
        using '�� �������';
    exception
      when no_data_found then
        null;
    end;
  end if;

  if table_exists('DC_PROPSECTIONS') > 0 then
    begin
      execute immediate 'select ID from DC_PROPSECTIONS where NAME = :a'
        into npropsections_id
        using '������ �������� ��-��';
    exception
      when no_data_found then
        null;
    end;
  end if;

  if table_exists('DC_PROPGROUPS') > 0 then
    begin
      execute immediate 'select ID from DC_PROPGROUPS where NAME = :a'
        into npropgroups_id
        using '������';
    exception
      when no_data_found then
        null;
    end;
  end if;

  if table_exists('DC_MOVETYPE') > 0 then
    begin
      execute immediate 'select ID from DC_MOVETYPE where trim(NAME) = :a'
        into nmovetype4_id
        using '��������';
    exception
      when no_data_found then
        null;
    end;
  end if;

  if table_exists('DC_DOCROLES') > 0 then
    begin
      execute immediate 'select ID from DC_DOCROLES where trim(NAME) = :a'
        into ndocrole
        using '���� ������ �����';
    exception
      when no_data_found then
        null;
    end;
  end if;

  for rec IN (SELECT *
                FROM (SELECT replace(t3.code, ' ', '') AS sokof,
                             TRIM(decode(t2.OBJECT_NUMBER, null, np.inv_group, t2.OBJECT_GROUP)) scard_pref_trim,
                             TRIM(decode(t2.OBJECT_NUMBER, null, np.inv_numb, t2.OBJECT_NUMBER)) scard_numb_trim,
                             T5.NOMEN_NAME snom_name,
                             t2.item_count,
                             1 as count_real,
                             t2.income_date,
                             t2.rn,
                             DECODE(SUBSTR(T4.ACC_NUMBER, 18, 1), '1', '1', '4', '1', '0') is_budget,
                             prsf_prop_sget(t2.company, 'Inventory', t2.rn, '���������� �����') reestr,
                             np.ncount groups_count,
                             t2.item_count items_count
                        FROM selectlist t1, --
                             INVENTORY t2,
                             okof t3,
                             DICACCS t4,
                             DICNOMNS t5,
                             (select t.prn, --
                                     max(t.inv_group) inv_group,
                                     max(t.inv_numb) inv_numb,
                                     count(1) ncount
                                from INVPACK t
                               WHERE (T.OUT_DATE IS NULL OR T.OUT_DATE > dDATE)
                               group by t.prn) np
                       WHERE t1.ident = NIDENT
                         AND T1.DOCUMENT = t2.RN
                         AND t2.okof = t3.rn
                         AND T2.ACCOUNT = t4.rn(+)
                         AND T2.NOMENCLATURE = T5.RN
                         AND t2.item_count = 1
                         AND np.prn(+) = t2.rn
                      union all
                      SELECT replace(t3.code, ' ', '') AS sokof,
                             TRIM(decode(t6.inv_numb, null, t2.object_group, t6.inv_group)) scard_pref_trim,
                             TRIM(decode(t6.inv_numb, null, t2.object_number || '.' || trim(t6.group_number), t6.inv_numb)) scard_numb_trim,
                             T5.NOMEN_NAME snom_name,
                             count(1) over(partition by t6.prn) as item_count,
                             t6.item_count count_real,
                             t6.in_date as income_date,
                             t2.rn,
                             DECODE(SUBSTR(T4.ACC_NUMBER, 18, 1), '1', '1', '0') is_budget,
                             nvl(prsf_prop_sget(t2.company, 'InventoryGroupCardSheet', t6.rn, '���������� �����'), prsf_prop_sget(t2.company, 'Inventory', t2.rn, '���������� �����')) reestr,
                             sum(t6.item_count) over(partition by t6.prn) as groups_count,
                             t2.item_count items_count
                        FROM selectlist t1, --
                             INVENTORY  t2,
                             okof       t3,
                             DICACCS    t4,
                             DICNOMNS   t5,
                             INVPACK    t6
                       WHERE t1.ident = NIDENT
                         AND T1.DOCUMENT = t2.RN
                         AND t2.okof = t3.rn
                         AND T2.ACCOUNT = t4.rn(+)
                         AND T2.NOMENCLATURE = T5.RN
                         AND t2.item_count > 1
                         AND (T6.OUT_DATE IS NULL OR T6.OUT_DATE > dDATE)
                         AND t6.prn = t2.rn)
               ORDER BY rn) LOOP
    if (nStartNumber is null) or (nKOl + 1 >= nStartNumber) then
      if rec.groups_count <> rec.items_count then
        p_exception(0, '�� �������� ����������: ' || rec.scard_pref_trim || '-' || rec.scard_numb_trim);
      end if;
      --����� �� ������� ��������
      BEGIN
        SELECT MIN(ACTION_DATE) MIN_DATE, --
               MAX(NEW_A_COST_BEGIN) KEEP(DENSE_RANK LAST ORDER BY ACTION_DATE) NEW_A_COST_BEGIN,
               MAX(NEW_A_AMORT_DURING) KEEP(DENSE_RANK LAST ORDER BY ACTION_DATE) NEW_A_AMORT_DURINGN,
               MAX(NEW_A_AMORT_BEGIN) KEEP(DENSE_RANK LAST ORDER BY ACTION_DATE) NEW_A_AMORT_BEGIN,
               min(decode(H.Action_Type, 0, H.VDOC_NUMB, null)),
               min(decode(H.ACTION_TYPE, 0, H.VDOC_DATE, null)),
               MAX(decode(H.Action_Type, 4, ACTION_DATE, null)), -- ���� ��������
               min(decode(H.Action_Type, 4, H.VDOC_NUMB, null)),
               min(decode(H.ACTION_TYPE, 4, H.VDOC_DATE, null)),
               min(decode(H.ACTION_TYPE, 4, DT.DOCNAME, null))
          INTO v_min_date, --
               v_new_a_cost_begin,
               v_new_a_amort_during,
               v_new_a_amort_begin,
               v_fdoc_numb,
               v_fdoc_date,
               v_spis_date,
               v_spis_fdoc_numb,
               v_spis_fdoc_date,
               v_spis_fdoc_name
          FROM INVHIST H, DOCTYPES DT
         WHERE PRN = rec.RN
           AND ACTION_DATE <= dDate
           AND DT.RN(+) = H.VDOC_TYPE;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          p_exception(0, '��� �������� �� �������� �� ���� ' || TO_CHAR(ddate, 'dd.mm.yyyy') || '! ����������� ����� :' || NVL(rec.scard_pref_trim, '') || sDef || NVL(rec.scard_numb_trim, ''));
      END;
    
      if rec.scard_numb_trim is null then
        p_exception(0, '�� ������ ����������� ����� (���.���������:  ' || v_new_a_cost_begin || ', ' || rec.snom_name || ')');
      end if;
    
      cTEMP1 := CHR(13) || '<!-- ����� �������: ' || (nKOl + 1) || ' -->';
      dbms_lob.writeappend(cCLOB, length(cTEMP1), cTEMP1);
      cTEMP1 := null;
    
      if nREGIM = 2 then
        -- �� 100 000 �
        cTEMP1 := cTEMP1 || CHR(13) || '<object xsi:type="MovablesLess1000">' || CHR(13) --
                  || '<OKOF>' || to_char(rec.sokof) || '</OKOF>' || CHR(13); --��� ����. ������������ �������. 9-�� ������� �����
        if nXMLVersion > 1 then
          cTEMP1 := cTEMP1 || '<regno>' || rec.reestr || '</regno>' || CHR(13); -- ���������� �����
        end if;
        cTEMP1 := cTEMP1 || '<invno>' || rec.scard_pref_trim || rec.scard_numb_trim || '</invno>' || CHR(13) --
                  || '<description>' || rec.snom_name || '</description>' || CHR(13) --
                  || '<is_budget>' || rec.is_budget || '</is_budget>' || CHR(13) --�������� ��������������. 0 - ������������, 1 - ���������. ������������ �������. �� ��������� �������� = 0
                  || '<propsections_id>' || trim(to_char(npropsections_id)) || '</propsections_id>' || CHR(13) --
                  || '<propgroups_id>' || trim(to_char(npropgroups_id)) || '</propgroups_id>' || CHR(13) --
                  || '<propnames_id>' || trim(to_char(npropnames_id)) || '</propnames_id>' || CHR(13) --
                  || '<amount>' || replace(to_char(rec.count_real), ',', '.') || '</amount>' || CHR(13) --
                  || '<costs>' || CHR(13) --
                  || '<startpay>' || replace(to_char(v_new_a_cost_begin / rec.item_count), ',', '.') || '</startpay>' || CHR(13) --������ ����������� ������� �����
                  || '<startpay_calcdate>' || to_char(dDate, 'dd.mm.yyyy') || '</startpay_calcdate>' || CHR(13) --
                  || '<pay>' || replace(((v_NEW_A_COST_BEGIN - v_NEW_A_AMORT_DURING - v_NEW_A_AMORT_BEGIN) / rec.item_count), ',', '.') || '</pay>' || CHR(13) --
                  || '<pay_calcdate>' || to_char(ddate, 'dd.mm.yyyy') || '</pay_calcdate>' || CHR(13) --
                  || '</costs>' || CHR(13) --
                  || '<documents>' || CHR(13) || '<document>' || CHR(13) --
                  || '<doctypes_id>' || trim(to_char(ndoctypes_id)) || '</doctypes_id>' || CHR(13) --
                  || '<docno>' || nvl(v_fdoc_numb, ' ') || '</docno>' || CHR(13) --
                  || '<docdate>' || to_char(nvl(v_fdoc_date, v_min_date), 'dd.mm.yyyy') || '</docdate>' || CHR(13) --
                  || '<explanation></explanation>' || CHR(13) --
                  || '<docrole>' || '����_������_�����' || '</docrole>' || CHR(13) --
                  || '</document>' || CHR(13) --
                  || '</documents>' || CHR(13) --
                  || '</object>';
        nKOl   := nKOl + 1;
        dbms_lob.writeappend(cCLOB, length(cTEMP1), cTEMP1);
        cTEMP1 := null;
      end if;
    
      if nREGIM = 3 then
        -- ������ 100 000
        cTEMP1 := cTEMP1 || CHR(13) --
                  || '<object xsi:type="MovablesMore1000">' || CHR(13) --
                  || '<OKOF>' || to_char(rec.sokof) || '</OKOF>' || CHR(13); --��� ����. ������������ �������. 9-�� ������� �����
        if nXMLVersion > 1 then
          cTEMP1 := cTEMP1 || '<regno>' || rec.reestr || '</regno>' || CHR(13); -- ���������� �����
        end if;
        cTEMP1 := cTEMP1 || '<invno>' || rec.scard_pref_trim || rec.scard_numb_trim || '</invno>' || CHR(13) --
                  || '<description>' || rec.snom_name || '</description>' || CHR(13) --
                  || '<is_budget>' || rec.is_budget || '</is_budget>' || CHR(13) --�������� ��������������. 0 - ������������, 1 - ���������. ������������ �������. �� ��������� �������� = 0
                  || '<propsections_id>' || trim(to_char(npropsections_id)) || '</propsections_id>' || CHR(13) --
                  || '<propgroups_id>' || trim(to_char(npropgroups_id)) || '</propgroups_id>' || CHR(13) --
                  || '<propnames_id>' || trim(to_char(npropnames_id)) || '</propnames_id>' || CHR(13) --
                  || '<costs>' || CHR(13) --
                  || '<startpay>' || replace(to_char(v_new_a_cost_begin), ',', '.') || '</startpay>' || CHR(13) --������ ����������� ������� �����
                  || '<startpay_calcdate>' || to_char(dDate, 'dd.mm.yyyy') || '</startpay_calcdate>' || CHR(13) --
                  || '<pay>' || replace((v_NEW_A_COST_BEGIN - v_NEW_A_AMORT_DURING - v_NEW_A_AMORT_BEGIN), ',', '.') || '</pay>' || CHR(13) || '<pay_calcdate>' || to_char(ddate, 'dd.mm.yyyy') || '</pay_calcdate>' || CHR(13) --
                  || '</costs>' || CHR(13) --
                  || '<documents>' || CHR(13) --
                  || '<document>' || CHR(13) --
                  || '<doctypes_id>' || trim(to_char(ndoctypes_id)) || '</doctypes_id>' || CHR(13) --
                  || '<docno>' || nvl(convert(v_fdoc_numb, 'utf8'), ' ') || '</docno>' || CHR(13) --
                  || '<docdate>' || to_char(nvl(v_fdoc_date, v_min_date), 'dd.mm.yyyy') || '</docdate>' || CHR(13) --
                  || '<explanation></explanation>' || CHR(13) --
                  || '<docrole>' || '����_������_�����' || '</docrole>' || CHR(13) --
                  || '</document>' || CHR(13) --
                  || '</documents>' || CHR(13) --
                  || '</object>';
        nKOl   := nKOl + 1;
        dbms_lob.writeappend(cCLOB, length(cTEMP1), cTEMP1);
        cTEMP1 := null;
      end if;
    
      if nREGIM = 1 then
        -- ����
        cTEMP1 := cTEMP1 || CHR(13) --
                  || '<object xsi:type="Transport">' || CHR(13) --
                  || '<OKOF>' || to_char(rec.sokof) || '</OKOF>' || CHR(13); --��� ����. ������������ �������. 9-�� ������� �����
        if nXMLVersion > 1 then
          cTEMP1 := cTEMP1 || '<regno>' || rec.reestr || '</regno>' || CHR(13); -- ���������� �����
        end if;
        cTEMP1 := cTEMP1 || '<invno>' || rec.scard_pref_trim || rec.scard_numb_trim || '</invno>' || CHR(13) --
                  || '<description>' || rec.snom_name || '</description>' || CHR(13) --
                  || '<is_budget>' || rec.is_budget || '</is_budget>' || CHR(13) --�������� ��������������. 0 - ������������, 1 - ���������. ������������ �������. �� ��������� �������� = 0
                  || '<transptype_id>' || trim(to_char(ntransptype_id)) || '</transptype_id>' || CHR(13) --
                  || '<brandnames_id>' || trim(to_char(nbrandnames_id)) || '</brandnames_id>' || CHR(13) --����� ��. ��������. �������� ����� �� ���� id ������� "brandnames". ������������ �������
                  || '<model></model>' || CHR(13) --
                  || '<relyear>' || to_char(v_min_date, 'yyyy') || '</relyear>' || CHR(13) -- ��� �������
                  || '<motorno></motorno>' || CHR(13) --
                  || '<fedno>' || ' ' || '</fedno>' || CHR(13) -- ���. �����. ������������ �������.
                  || '<chassisno></chassisno>' || CHR(13) --
                  || '<fedno_date>' || to_char(v_min_date, 'dd.mm.yyyy') || '</fedno_date>' || CHR(13) -- ����� ����� ���. �����. ������������ �������
                  || '<bodyno></bodyno>' || CHR(13) --
                  || '<info />' || CHR(13) --
                  || '<costs>' || CHR(13) --
                  || '<startpay>' || replace(to_char(v_new_a_cost_begin), ',', '.') || '</startpay>' || CHR(13) --������ ����������� ������� �����
                  || '<startpay_calcdate>' || trim(to_char(dDATE, 'dd.mm.yyyy')) || '</startpay_calcdate>' || CHR(13) --
                  || '<pay>' || replace((v_NEW_A_COST_BEGIN - v_NEW_A_AMORT_DURING - v_NEW_A_AMORT_BEGIN), ',', '.') || '</pay>' || CHR(13) --
                  || '<pay_calcdate>' || to_char(ddate, 'dd.mm.yyyy') || '</pay_calcdate>' || CHR(13) --
                  || '</costs>' || CHR(13) --
                  || '<documents>' || CHR(13) --
                  || '<document>' || CHR(13) --
                  || '<doctypes_id>' || trim(to_char(ndoctypes_id)) || '</doctypes_id>' || CHR(13) --
                  || '<docno>' || nvl(v_fdoc_numb, ' ') || '</docno>' || CHR(13) --
                  || '<docdate>' || to_char(nvl(v_fdoc_date, v_min_date), 'dd.mm.yyyy') || '</docdate>' || CHR(13) --
                  || '<explanation></explanation>' || CHR(13) --
                  || '<docrole>' || '����_������_�����' || '</docrole>' || CHR(13) --
                  || '</document>' || CHR(13) --
                  || '</documents>' || CHR(13) --
                  || '</object>';
        nKOl   := nKOl + 1;
        dbms_lob.writeappend(cCLOB, length(cTEMP1), cTEMP1);
        cTEMP1 := null;
      end if;
    
      if (nREGIM = 4) and (v_spis_date is not null) and (rec.reestr is not null) then
        -- ���� ��� ���������:
        if table_exists('DC_DOCTYPES') > 0 then
          begin
            execute immediate 'select ID from DC_DOCTYPES where NAME = :a'
              into ndoctypes4_id
              using v_spis_fdoc_name;
          exception
            when no_data_found then
              ndoctypes4_id := ndoctypes_id;
          end;
        end if;
        -- ��������
        cTEMP1 := cTEMP1 || CHR(13) --
                  || '  <object xsi:type="MoveItems">
    <regno>' || rec.reestr || '</regno> 
    <moves> 
       <movetype_id>' || nmovetype4_id || '</movetype_id> 
       <sincedate>' || to_char(v_spis_date, 'dd.mm.yyyy') || '</sincedate> 
       <enddate></enddate> 
       <documents> 
         <document>
           <doctypes_id>' || trim(to_char(ndoctypes_id)) || '</doctypes_id> 
           <docno>' || nvl(v_spis_fdoc_numb, ' ') || '</docno>
           <docdate>' || to_char(nvl(v_spis_fdoc_date, v_spis_date), 'dd.mm.yyyy') || '</docdate>
           <explanation></explanation> 
           <docrole>' || ndocrole || '</docrole>' || '
         </document>
       </documents>
    </moves>
  </object>';
        /*           <clients_id>
         <client_id>
           <cl_id>5100</cl_id>
         </client_id>  
        </clients_id>*/
        nKOl := nKOl + 1;
        dbms_lob.writeappend(cCLOB, length(cTEMP1), cTEMP1);
        cTEMP1 := null;
      end if;
    else
      nKOl  := nKOl + 1;
      nKol2 := nKol2 + 1;
    end if;
  end loop;

  cTEMP3 := cTEMP3 || CHR(13) || '</objects>';

  dbms_lob.writeappend(cCLOB, length(cTEMP3), cTEMP3);

  report_to_buff;

  /* ����������� ����� */
  dbms_lob.freetemporary(cCLOB);

  sOUT := '����� ��������� ��������: ' || (nKOl - nKol2);
end;
/
