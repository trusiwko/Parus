create or replace procedure PP_ODC_CREATE
-- Переформирование ДК задолженности
(nIDENT in number) is
begin

  for c in (select e.*
              from oprspecs e, selectlist s
             where e.prn = s.document
               and s.ident = nIDENT) loop
    delete from ODCTURNSSPECS t where t.spec = c.rn;
    P_ODCTURNS_INSERT(c.COMPANY,
                      c.PRN,
                      c.RN,
                      c.ACCOUNT_DEBIT,
                      c.BALUNIT_DEBIT,
                      c.ANALYTIC_DEBIT1,
                      c.ANALYTIC_DEBIT2,
                      c.ANALYTIC_DEBIT3,
                      c.ANALYTIC_DEBIT4,
                      c.ANALYTIC_DEBIT5,
                      c.ACCOUNT_CREDIT,
                      c.BALUNIT_CREDIT,
                      c.ANALYTIC_CREDIT1,
                      c.ANALYTIC_CREDIT2,
                      c.ANALYTIC_CREDIT3,
                      c.ANALYTIC_CREDIT4,
                      c.ANALYTIC_CREDIT5,
                      c.CURRENCY,
                      c.ACNT_SUM,
                      c.ACNT_BASE_SUM,
                      c.CTRL_SUM,
                      c.CTRL_BASE_SUM,
                      c.ACNT_ACCTYPES_SUM,
                      c.CTRL_ACCTYPES_SUM);
    P_ODCTURNS_TURN2SHEET(c.rn);
  end loop;

end PP_ODC_CREATE;
/
