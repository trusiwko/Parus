create or replace view vp_p7_units as
select 'Bank' P7, 'BankDocuments' P8
  from dual
union all
select 'EconOp', 'EconomicOperations'
  from dual
union all
select 'InternalDocs', 'InternalDocuments'
  from dual
union all
select 'Cash', 'CashDocuments'
  from dual
union all
select 'Inventory', 'Inventory'
  from dual
union all
select 'Bill', ''
  from dual
union all
select 'PayLst', 'PayNotes'
  from dual
union all
select 'AdvanceReturns', 'AdvanceReport'
  from dual
union all
select 'Deposit', 'SalaryDeposits' from dual;
