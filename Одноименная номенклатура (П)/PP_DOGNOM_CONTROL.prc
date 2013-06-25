create or replace procedure PP_DOGNOM_CONTROL
-- Снятие контроля ежеквартального лимита по номенклатуре одноименных товаров, работ, услуг
(nCOMPANY in number,
 nRN      in number,
 sMSG     out varchar2 --
 ) is
  soldcontrol varchar2(3);
  snewcontrol varchar2(3);
  ntemp       number;
begin
  soldcontrol := nvl(prsf_prop_sget(nCOMPANY, 'GovernmentContracts', nRN, 'НоменклатураКонтроль'), 'Нет');
  if soldcontrol = 'Нет' then
    snewcontrol := 'Да';
    sMSG        := 'Контроль снят';
  else
    snewcontrol := '';
    sMSG        := 'Контроль установлен';
  end if;
  pkg_docs_props_vals.MODIFY('НоменклатураКонтроль', 'GovernmentContracts', nRN, snewcontrol, null, null, ntemp);
end PP_DOGNOM_CONTROL;
/*create public synonym PP_DOGNOM_CONTROL for PP_DOGNOM_CONTROL;
  grant execute on PP_DOGNOM_CONTROL to public;*/
/
