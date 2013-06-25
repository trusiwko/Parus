create or replace function FP_BD_GK
-- Âåğíåì ÃÊ èç íàçíà÷åíèÿ ïëàòåæà
( --
 sPAYINFO in varchar2, --
 nAGENT   in number) return number is
  Result number;
  type ar_integer is table of varchar(20) index by binary_integer;
  a        ar_integer;
  i        number;
  n        number;
  p        number;
  sdocnum  varchar2(20);
  sdocdate varchar2(20);

begin
  a(0) := 'ñîã-íî ÃÊ';
  a(1) := 'ñîã-íî äîã';
  a(2) := 'ñîã ÃÊ';
  a(3) := 'ñîã äîã';
  p := -1;
  for i in 0 .. 3 loop
    n := instr(sPAYINFO, a(i));
    if n > 0 then
      p := n + length(a(i));
      exit;
    end if;
  end loop;
  if p > 0 then
    n := instr(sPAYINFO, ' îò ', p);
    if n > 0 and n - p < 20 then
      sdocnum  := substr(sPAYINFO, p, n - p);
      p        := n + 4;
      sdocdate := substr(sPAYINFO, p, 8);
    end if;
  end if;
  begin
    select g.rn
      into Result
      from govcntr g
     where g.agent_supp = nAGENT
       and FP_BD_GK_RemoveNonLit(upper(trim(nvl(g.ext_numb, g.doc_numb)))) = FP_BD_GK_RemoveNonLit(upper(trim(sdocnum)))
       and (to_char(g.doc_date, 'dd.mm.yy') = sdocdate or to_char(g.doc_date, 'dd.mm.yyyy') = sdocdate);
  exception
    when others then
      null;
  end;
  return(Result);
exception
  when others then
    return null;
end FP_BD_GK;
/
