create or replace function fp_nextrn7 --
(sRN in varchar2) return varchar2 is
  Result varchar2(4);
  n4     number;
  n3     number;
  n2     number;
  n1     number;

  function check_numb(a in out number, b in out number) return boolean is
    Result boolean;
  begin
    Result := false;
    if a > 57 and a < 65 then
      a := 65;
    elsif a > 90 and a < 97 then
      a := 97;
    elsif a > 122 and a < 192 then
      a := 192;
    elsif a > 255 then
      a      := 48;
      b      := b + 1;
      Result := true;
    end if;
    return Result;
  end;
begin
  n4 := ascii(substr(sRN, 4, 1));
  n3 := ascii(substr(sRN, 3, 1));
  n2 := ascii(substr(sRN, 2, 1));
  n1 := ascii(substr(sRN, 1, 1));
  n4 := n4 + 1;

  if check_numb(n4, n3) then
    if check_numb(n3, n2) then
      if check_numb(n2, n1) then
        null;
      end if;
    end if;
  end if;

  --  48 .. 57, 65 .. 90, 97 .. 122, 192 .. 255
  Result := chr(n1) || chr(n2) || chr(n3) || chr(n4);
  return(Result);
end fp_nextrn7;
/
