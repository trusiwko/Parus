-- Create table
create table CLNPSPFM_CS
(
  dummy      VARCHAR2(1),
  rn         NUMBER not null,
  authid     VARCHAR2(30) not null,
  clnpspfm   NUMBER(17) not null,
  typ        NUMBER,
  pay_lnk    NUMBER(17),
  pay_sum    NUMBER(20,5),
  pay_aux    NUMBER(1),
  slp_lnk    NUMBER(17),
  rem4       NUMBER,
  rem5       NUMBER(20,5),
  rem6       NUMBER(20,5),
  rem7       NUMBER(20,5),
  c_typ      NUMBER,
  c_pay_lnk  NUMBER(17),
  c_pay_sum  NUMBER(20,5),
  c_pay_aux  NUMBER(1),
  c_rem5     NUMBER(20,5),
  c_rem6     NUMBER(20,5),
  mnths      NUMBER,
  yearfor    NUMBER(4),
  monthfor   NUMBER(2),
  bgnfor     NUMBER(2),
  endfor     NUMBER(2),
  c_yearfor  NUMBER(4),
  c_monthfor NUMBER(2),
  c_bgnfor   NUMBER(2),
  c_endfor   NUMBER(2),
  topay      NUMBER(1),
  c_topay    NUMBER(1),
  param      VARCHAR2(40),
  c_param    VARCHAR2(40),
  slcalc_lnk NUMBER
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
-- Create/Recreate indexes 
create index I_CLNPSPFM_CS_TYP on CLNPSPFM_CS (AUTHID, TYP)
  tablespace INDX
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
create unique index I_CLNPSPFM_CS_UNIQUE on CLNPSPFM_CS (AUTHID, RN)
  tablespace INDX
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
