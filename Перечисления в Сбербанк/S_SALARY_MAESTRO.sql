-- Create table
create table S_SALARY_MAESTRO
(
  fio    VARCHAR2(100),
  ls     VARCHAR2(30),
  summa  NUMBER(17,2),
  rn     NUMBER(17),
  authid VARCHAR2(40),
  fam    VARCHAR2(100),
  ima    VARCHAR2(100),
  oth    VARCHAR2(100)
)
tablespace PARUS
  pctfree 10
  pctused 40
  initrans 1
  maxtrans 255
  storage
  (
    initial 64K
    minextents 1
    maxextents unlimited
  );
-- Grant/Revoke object privileges 
grant select, insert, delete on S_SALARY_MAESTRO to PUBLIC;
-- Create the synonym 
create or replace public synonym S_SALARY_MAESTRO for PARUS.S_SALARY_MAESTRO;