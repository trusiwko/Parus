-- Create table
create table TP_EXCEL_XML_STYLE
(
  STYLENAME           VARCHAR2(20),
  STYLEPARAMETER      VARCHAR2(240),
  IDENT               NUMBER,
  STYLEPARAMETERVALUE VARCHAR2(240)
)
tablespace PARUS
  pctfree 10
  initrans 1
  maxtrans 255
  storage
  (
    initial 64K
    next 1M
    minextents 1
    maxextents unlimited
  );
