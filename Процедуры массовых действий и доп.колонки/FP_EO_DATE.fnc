create or replace function FP_EO_DATE
-- Доп.колонка "Дата ХО" (по связям)
(nRN in number) return date is
  Result date;
begin
  select /*+ INDEX(L I_DOCLINKS_IN_DOCUMENT) */
   max(eo.operation_date)
    into Result
    from doclinks dl, econoprs eo
   where dl.out_unitcode = 'EconomicOperations'
     and dl.in_document = nRN
     and dl.out_document = eo.rn;
  return(Result);
end FP_EO_DATE;
/*create public synonym FP_EO_DATE for FP_EO_DATE;
  grant execute on FP_EO_DATE to public;*/
/
