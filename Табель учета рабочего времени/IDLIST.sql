-- Create table
create global temporary table IDLIST
(
  DUMMY VARCHAR2(1),
  ID    NUMBER(17),
  HID   NUMBER(17)
)
on commit preserve rows;
