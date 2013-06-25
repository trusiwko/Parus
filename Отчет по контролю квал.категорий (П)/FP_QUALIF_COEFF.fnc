create or replace function FP_QUALIF_COEFF
--
(nCOMPANY in number, nGRCATSAL in number, nCLNPERSONS in number, dDATE in date) return number is
  nVALUE  number;
  nRESULT number;
begin
  for c in (select f.func_params
              from GRSALCFUNC f
             where f.prn = nGRCATSAL
               and f.Func_Kind = 0 -- Исполнения должностей
            ) loop
    PKG_GSCF_QUALIF.GETVALUE(nCOMPANY, nCLNPERSONS, NULL, 1, c.FUNC_PARAMS, dDATE, nVALUE, nRESULT);
  end loop;
  return(nVALUE);
end FP_QUALIF_COEFF;
/
