create or replace function FP_CLNPERSEXP_GET_LEN
/**
 * ћодифицированна€ функци€ F_CLNPERSEXP_GET_LEN
 * ¬ыводит только количество полных лет стажа
**/
(
  nEXPERIENCES      in number,          -- рег. номер типа стажа
  nCLNPERSONS       in number,          -- рег. номер сотрудника
  dCALCDATE         in date             -- дата на которую расчитываетс€ стаж
)
return number
as
  nYEARS            PKG_STD.tNUMBER;
  nTEMP             PKG_STD.tNUMBER;
begin
  /* определение количества лет, дней, мес€цев указанного стажа у сотрудника */
  PKG_CLNPERSEXP.GETEXP(nEXPERIENCES, nCLNPERSONS, dCALCDATE, nTEMP, nTEMP, nYEARS);

  return nYEARS;
end;
/
