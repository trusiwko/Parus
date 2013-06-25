-- Create table
create table TP_SBER_CARD_XML
(
  AGNFAMILYNAME VARCHAR2(60),
  AGNFIRSTNAME  VARCHAR2(30),
  AGNLASTNAME   VARCHAR2(30),
  DOCSER        VARCHAR2(14),
  DOCNUMB       VARCHAR2(14),
  DOCWHEN       VARCHAR2(10),
  DOCWHO        VARCHAR2(250),
  DEPART_CODE   VARCHAR2(10),
  AGNBURN       VARCHAR2(10),
  SSEX          VARCHAR2(1),
  ADDR_BURN     VARCHAR2(200),
  A1            VARCHAR2(6),
  A2            VARCHAR2(160),
  A3            VARCHAR2(160),
  A4            VARCHAR2(160),
  A5            VARCHAR2(160),
  A6            VARCHAR2(160),
  A7            VARCHAR2(160),
  A8            VARCHAR2(160),
  A9            VARCHAR2(160),
  A10           VARCHAR2(7),
  A11           VARCHAR2(5),
  A12           VARCHAR2(9),
  O1            VARCHAR2(6),
  O2            VARCHAR2(160),
  O3            VARCHAR2(160),
  O4            VARCHAR2(160),
  O5            VARCHAR2(160),
  O6            VARCHAR2(160),
  O7            VARCHAR2(160),
  O8            VARCHAR2(160),
  O9            VARCHAR2(160),
  O10           VARCHAR2(7),
  O11           VARCHAR2(5),
  O12           VARCHAR2(9),
  PHONE         VARCHAR2(20),
  EMB_1         VARCHAR2(60),
  EMB_2         VARCHAR2(30),
  EMB_3         VARCHAR2(30),
  CONTROL       VARCHAR2(51),
  RN            NUMBER not null,
  CRN           NUMBER not null,
  LOADSTATE     VARCHAR2(100),
  CARD_TYPE     NUMBER not null
) ;
-- Create/Recreate primary, unique and foreign key constraints
alter table TP_SBER_CARD_XML
  add constraint I_TP_SBER_CARD_XML_1 primary key (RN)
   ;
alter table TP_SBER_CARD_XML
  add constraint I_TP_SBER_CARD_XML_2 foreign key (CRN)
  references ACATALOG (RN);
-- Grant/Revoke object privileges
grant select, insert, update, delete on TP_SBER_CARD_XML to PUBLIC;
