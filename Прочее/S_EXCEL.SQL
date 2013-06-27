create table S_EXCEL
(
  authid   VARCHAR2(20),
  n1       NUMBER,
  f1       VARCHAR2(2000),
  f2       VARCHAR2(2000),
  f3       VARCHAR2(2000),
  f4       VARCHAR2(2000),
  f5       VARCHAR2(2000),
  f6       VARCHAR2(2000),
  f7       VARCHAR2(2000),
  f8       VARCHAR2(2000),
  f9       VARCHAR2(2000),
  f10      VARCHAR2(2000),
  f11      VARCHAR2(2000),
  f12      VARCHAR2(2000),
  f13      VARCHAR2(2000),
  f14      VARCHAR2(2000),
  f15      VARCHAR2(2000),
  f16      VARCHAR2(2000),
  f17      VARCHAR2(2000),
  f18      VARCHAR2(2000),
  f19      VARCHAR2(2000),
  f20      VARCHAR2(2000),
  f21      VARCHAR2(2000),
  f22      VARCHAR2(2000),
  f23      VARCHAR2(2000),
  f24      VARCHAR2(2000),
  f25      VARCHAR2(2000),
  f26      VARCHAR2(2000),
  f27      VARCHAR2(2000),
  f28      VARCHAR2(2000),
  f29      VARCHAR2(2000),
  f30      VARCHAR2(2000),
  f31      VARCHAR2(2000),
  f32      VARCHAR2(2000),
  f33      VARCHAR2(2000),
  f34      VARCHAR2(2000),
  f35      VARCHAR2(2000),
  f36      VARCHAR2(2000),
  f37      VARCHAR2(2000),
  f38      VARCHAR2(2000),
  f39      VARCHAR2(2000),
  f40      VARCHAR2(2000),
  b        NUMBER(1),
  loaddate DATE,
  loadfile VARCHAR2(400)
)
tablespace PARUS
  pctfree 10
  initrans 1
  maxtrans 255
  storage
  (
    initial 1M
    next 1M
    minextents 1
    maxextents unlimited
  );
-- Grant/Revoke object privileges 
grant select, insert, update, delete on S_EXCEL to PUBLIC;
