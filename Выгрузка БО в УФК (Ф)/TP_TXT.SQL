-- Create table
create table TP_TXT
(
  IDENT       NUMBER not null,
  GROUPNUMBER NUMBER not null,
  FIELDNUMBER NUMBER not null,
  VALUE       VARCHAR2(2000),
  AUTHID      VARCHAR2(20) not null,
  FIELDNAME   VARCHAR2(40),
  GROUPNAME   VARCHAR2(40)
)
tablespace PARUS
  pctfree 10
  pctused 40
  initrans 1
  maxtrans 255
  storage
  (
    initial 64K
    next 1M
    minextents 1
    maxextents unlimited
  );
-- Create/Recreate primary, unique and foreign key constraints 
alter table TP_TXT
  add constraint I_TP_TXT_1 unique (IDENT, GROUPNUMBER, FIELDNUMBER)
  using index 
  tablespace PARUS
  pctfree 10
  initrans 2
  maxtrans 255
  storage
  (
    initial 64K
    next 1M
    minextents 1
    maxextents unlimited
  );
