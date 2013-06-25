create or replace procedure PP_BEFORE_LOAD is
begin
  execute immediate 'alter table P7_NOBASE modify name_nom VARCHAR2(240)';
  -- PKG_DBASE.DO_OEM_CONVERT:
  -- sRESULT := convert(sRESULT, 'CL8ISO8859P5', 'CL8MSWIN1251');
end PP_BEFORE_LOAD;
/
