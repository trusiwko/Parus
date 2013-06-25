-- Create table
create table TRS_SLTRANSFERS_SBER
(
  P_A_NUMBER VARCHAR2(32),
  SUMMA      NUMBER(16,2),
  FIO        VARCHAR2(40),
  PASSPORT   VARCHAR2(20),
  KOD        VARCHAR2(20),
  C_E_DATE   DATE,
  SSESSION   VARCHAR2(30)
)
tablespace USERS
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
-- Grant/Revoke object privileges 
grant select, insert, update, delete on TRS_SLTRANSFERS_SBER to PUBLIC;
