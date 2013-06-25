create or replace function FP_EO_DATE_RN
-- Доп.колонка "Дата ХО" (по связям)
(RN in number) return date is
begin
  return(FP_EO_DATE(RN));
end FP_EO_DATE_RN;
/*create public synonym FP_EO_DATE_RN for FP_EO_DATE_RN;
  grant execute on FP_EO_DATE_RN to public;*/
/
