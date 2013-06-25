create or replace function FP_CLNPERSEXP_GET_LEN
/**
 * ���������������� ������� F_CLNPERSEXP_GET_LEN
 * ������� ������ ���������� ������ ��� �����
**/
(
  nEXPERIENCES      in number,          -- ���. ����� ���� �����
  nCLNPERSONS       in number,          -- ���. ����� ����������
  dCALCDATE         in date             -- ���� �� ������� ������������� ����
)
return number
as
  nYEARS            PKG_STD.tNUMBER;
  nTEMP             PKG_STD.tNUMBER;
begin
  /* ����������� ���������� ���, ����, ������� ���������� ����� � ���������� */
  PKG_CLNPERSEXP.GETEXP(nEXPERIENCES, nCLNPERSONS, dCALCDATE, nTEMP, nTEMP, nYEARS);

  return nYEARS;
end;
/
