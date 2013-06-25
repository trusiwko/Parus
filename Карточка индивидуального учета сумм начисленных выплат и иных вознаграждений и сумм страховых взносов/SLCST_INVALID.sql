-- Create table
create table SLCST_INVALID
(
  DUMMY       VARCHAR2(1),
  RN          NUMBER(17),
  AUTHID      VARCHAR2(30),
  AGENT       NUMBER(17),
  AGNDISABLED NUMBER(17),
  DOC_SER     NUMBER(17) default 0,
  DOC_NUMB    NUMBER(17) default 0,
  DOC_DATE    NUMBER(17) default 0,
  INVGROUP    NUMBER(17) default 0,
  DATE_END    NUMBER(17) default 0,
  INC_PFR     NUMBER(17,2) default 0,
  INC_PFR1    NUMBER(17,2) default 0,
  INC_PFR2    NUMBER(17,2) default 0,
  INC_PFR3    NUMBER(17,2) default 0,
  TYPE        NUMBER(1) default 0,
  REF_BEG     DATE,
  REF_END     DATE
)
tablespace PARUS
  pctfree 10
  initrans 1
  maxtrans 255
  storage
  (
    initial 64K
    minextents 1
    maxextents unlimited
  );
