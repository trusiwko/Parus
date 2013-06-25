create or replace procedure PP_SBER_CARD_XML
-- �������� ������ �� �������� ���� �������� (XML)
-- �����: ����� - ������� � ����
(nIDENT    in number, -- ������������� ��������
 sFILENAME in varchar2, -- ��� ����� (sber.xml)
 dFORMDATE in date, -- ����������������
 sDOG_NUM  in varchar2, -- �������������
 sORGNAME  in varchar2, -- �����������������������
 sINN      in varchar2, -- ���
 sACCOUNT  in varchar2, -- ������������������������
 sID       in varchar2, -- ���������������������
 sOTDEL    in varchar2, -- ��������� �����
 sFILIAL   in varchar2, -- ��������������������
 nVIDVKL   in number, -- ���.������� "��� ����� ��������"
 -- ������������� (50, 51, 52, 53, 54)
 -- ���������������� (1, 2, 3, 4, 5):
 -- 50  2 Visa Classic (���)
 -- 50  4 Visa Gold (���)
 -- 51  3 Standard MasterCard (���)
 -- 51  5 Gold MasterCard (���)
 -- 53  1 Visa Electron (���)
 -- 54  2 Maestro (���)
 sCTG in varchar2 -- ��������� ���������
 -- 0 - ��������������;
 -- 207 - ����������;
 -- 217 - ���������� � ����������� ����������� ��� ����������� �����������.
 ) is
  sXML       CLOB;
  nCOUNT     number;
  psFILENAME varchar2(40) := sFILENAME;
  CR         varchar2(2) := chr(10);
  sVIDVKL    varchar2(2);
  sPODVID    varchar2(1);
  sLoadState varchar2(100);
begin
  if (psFILENAME is null) then
    psFILENAME := 'sber';
  end if;
  -- ������� .xml
  if nvl(lower(pkg_txt_load.EXTRACT_FILE_EXT(psFILENAME)), '-1') <> 'xml' then
    psFILENAME := psFILENAME || '.xml';
  end if;
  sLoadState := psFILENAME || ' �� ' || to_char(sysdate, 'dd.mm hh24:mi:ss');
  -- ��������� ����:
  sXML := '<?xml version="1.0" encoding="windows-1251"?>
<������� ����������������="' || to_char(dFORMDATE, 'yyyy-mm-dd') || '" �������������="' || sDOG_NUM || '" �����������������������="' || sORGNAME || '" ���="' || sINN || '" ������������������������="' || sACCOUNT || '" ���������������������="' || sID || '">' || CR;
  for c in (select *
              from (select a.*, --
                           count(1) over() ncount,
                           row_number() over(order by agnfamilyname, agnfirstname, agnlastname) nrow
                      from tp_sber_card_xml a, selectlist s
                     where a.rn = s.document
                       and s.ident = NIDENT
                     order by agnfamilyname, agnfirstname, agnlastname) a
             order by nrow) loop

      case nvl(c.card_type, nVIDVKL)
        when 1 then
          sVIDVKL := '50';
          sPODVID := '2';
        when 2 then
          sVIDVKL := '50';
          sPODVID := '4';
        when 3 then
          sVIDVKL := '51';
          sPODVID := '3';
        when 4 then
          sVIDVKL := '51';
          sPODVID := '5';
        when 5 then
          sVIDVKL := '53';
          sPODVID := '1';
        when 6 then
          sVIDVKL := '54';
          sPODVID := '2';
      end case;

    update tp_sber_card_xml t set t.loadstate = sLoadState || ' ('||c.nrow||')' where t.rn = c.rn;

    if length(c.emb_1 || c.emb_2) > 19 then
      p_exception(0, '��������� �� 19 ��������: ' || c.emb_1 || ' ' || c.emb_2);
    end if;
    if c.nrow = 1 then
      sXML := sXML || '  <��������������>' || CR;
    end if;

    sXML := sXML || '    <��������� ���="' || trim(to_char(c.nrow)) || '">
      <�������>' || c.agnfamilyname || '</�������>
      <���>' || c.agnfirstname || '</���>
      <��������>' || c.agnlastname || '</��������>
      <��������������>' || sOTDEL || '</��������������>
      <��������������������>' || to_char(sFILIAL) || '</��������������������>
      <��������� �������������="' || sVIDVKL || '" ����������������="' || sPODVID || '" ���������="810"></���������>
      <���������������������>
        <������������>������� ���������� ��</������������>
        <�����>' || c.docser || '</�����>
        <�����>' || c.docnumb || '</�����>
        <����������>' || c.docwhen || '</����������>
        <��������>' || c.docwho || '</��������>
        <����������������>' || c.depart_code || '</����������������>
      </���������������������>
      <������������>' || c.agnburn || '</������������>
      <���>' || c.ssex || '</���>' || CR;
    sXML := sXML || '      <����������������>
        <������>' || c.o1 || '</������>
        <������>
          <��������������>' || c.o2 || '</��������������>
          <����������������>' || c.o3 || '</����������������>
        </������>
        <�����>
          <�������������>' || c.o4 || '</�������������>
          <���������������>' || c.o5 || '</���������������>
        </�����>
        <���������������>
          <�����������������������>' || c.o6 || '</�����������������������>
          <�������������������������>' || c.o7 || '</�������������������������>
        </���������������>
        <�����>
          <�������������>' || c.o8 || '</�������������>
          <���������������>' || c.o9 || '</���������������>
        </�����>
        <���>' || c.o10 || '</���>
        <������>' || c.o11 || '</������>
        <��������>' || c.o12 || '</��������>
      </����������������>' || CR;
    sXML := sXML || '      <�������������>' || c.addr_burn || '</�������������>
      <�������������>
        <������>' || c.a1 || '</������>
        <������>
          <��������������>' || c.a2 || '</��������������>
          <����������������>' || c.a3 || '</����������������>
        </������>
        <�����>
          <�������������>' || c.a4 || '</�������������>
          <���������������>' || c.a5 || '</���������������>
        </�����>
        <���������������>
          <�����������������������>' || c.a6 || '</�����������������������>
          <�������������������������>' || c.a7 || '</�������������������������>
        </���������������>
        <�����>
          <�������������>' || c.a8 || '</�������������>
          <���������������>' || c.a9 || '</���������������>
        </�����>
        <���>' || c.a10 || '</���>
        <������>' || c.a11 || '</������>
        <��������>' || c.a12 || '</��������>
      </�������������>
      <���������������>' || c.phone || '</���������������>
      <�������������������� ����1="' || c.emb_1 || '" ����2="' || c.emb_2 || '" ����3="' || c.emb_3 || '" />
      <������������������>' || sCTG || '</������������������>
      <���������������������>' || c.control || '</���������������������>
    </���������>' || CR;
    if c.nrow = c.ncount then
      sXML := sXML || '  </��������������>' || CR;
      sXML := sXML || '  <����������������>
    <�����������������>' || trim(to_char(c.ncount)) || '</�����������������>
  </����������������>
</�������>';
    end if;
  end loop;
  insert into FILE_BUFFER (IDENT, AUTHID, FILENAME, DATA) values (nIDENT, user, psFILENAME, sXML);
end PP_SBER_CARD_XML;
/
