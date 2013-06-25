create or replace procedure P_CLNPSPFM_CS
(
  nCOMPANY          in number,          -- организация
  nICLNPSPFM        in number,          -- исполнение
  nISCOMPACT        in number,          -- компактная форма
  nISPERS           in number,          -- формировать по сотруднику
  nISALLPFM         in number,          -- формировать по всем исполнениям сотрудника
  sTAX              in varchar2,        -- налог
  nGRPADDPAY        in number,          -- Группировать по видам начислений
  nGRPSUBPAY        in number,          -- Группировать по видам удержаний
  nECXLVED          in number,          -- Не учитывать ведомость при группировке
  nDEDUCT           in number,          -- Признак печати отчислений
  sCALCIN           in varchar2,        -- список видов расчетов, которых учитывать
  sCALCTOPAY        in varchar2         -- список расчетов, по которым считать сумму на руки
)
as
  type rCLNPSPFM is record(
    RN              PKG_STD.tREF,
    PERSRN          PKG_STD.tREF
  );

  type tCLNPSPFM is table of rCLNPSPFM index by binary_integer;

  nRN               CLNPSPFM_CS.RN%type;
  nCLNPSPFM         CLNPSPFM_CS.CLNPSPFM%type;
  nTYP              CLNPSPFM_CS.TYP%type;
  nPAY_LNK          CLNPSPFM_CS.PAY_LNK%type;
  nPAY_SUM          CLNPSPFM_CS.PAY_SUM%type;
  nPAY_AUX          CLNPSPFM_CS.PAY_AUX%type;
  nSLP_LNK          CLNPSPFM_CS.SLP_LNK%type;
  nREM4             CLNPSPFM_CS.REM4%type;
  nREM5             CLNPSPFM_CS.REM5%type;
  nREM6             CLNPSPFM_CS.REM6%type;
  nREM7             CLNPSPFM_CS.REM7%type;
  nC_TYP            CLNPSPFM_CS.C_TYP%type;
  nC_PAY_LNK        CLNPSPFM_CS.C_PAY_LNK%type;
  nC_PAY_SUM        CLNPSPFM_CS.C_PAY_SUM%type;
  nC_PAY_AUX        CLNPSPFM_CS.C_PAY_AUX%type;
  nC_REM5           CLNPSPFM_CS.C_REM5%type;
  nC_REM6           CLNPSPFM_CS.C_REM6%type;
  nYEARFOR          CLNPSPFM_CS.YEARFOR%type;
  nMONTHFOR         CLNPSPFM_CS.MONTHFOR%type;
  nBGNFOR           CLNPSPFM_CS.BGNFOR%type;
  nENDFOR           CLNPSPFM_CS.ENDFOR%type;
  nC_YEARFOR        CLNPSPFM_CS.C_YEARFOR%type;
  nC_MONTHFOR       CLNPSPFM_CS.C_MONTHFOR%type;
  nC_BGNFOR         CLNPSPFM_CS.C_BGNFOR%type;
  nC_ENDFOR         CLNPSPFM_CS.C_ENDFOR%type;
  nTOPAY            CLNPSPFM_CS.TOPAY%type;
  nC_TOPAY          CLNPSPFM_CS.C_TOPAY%type;
  nTAX              SLCOMPCHARGES.RN%type;
  tbCLNPSPFM        tCLNPSPFM;
  dSCALC            date;
  nMSCALC           number;
  nYSCALC           number;
  nTMPDEDUCT        number;
  sSEQSYMB          varchar2(1);
  nOCURSIN          integer;
  nOCURSTOPAY       integer;
  nLOOP             integer;
  j                 integer;
  i                 binary_integer;
procedure ins_clnpspfm_cs
as
begin
  insert into CLNPSPFM_CS
  (
    RN,
    AUTHID,
    CLNPSPFM,
    TYP,
    PAY_LNK,
    PAY_SUM,
    PAY_AUX,
    SLP_LNK,
    REM4,
    REM5,
    REM6,
    REM7,
    C_TYP,
    C_PAY_LNK,
    C_PAY_SUM,
    C_PAY_AUX,
    C_REM5,
    C_REM6,
    YEARFOR,
    MONTHFOR,
    BGNFOR,
    ENDFOR,
    C_YEARFOR,
    C_MONTHFOR,
    C_BGNFOR,
    C_ENDFOR,
    TOPAY,
    C_TOPAY
  )
  values
  (
    nRN,
    UTILIZER,
    nCLNPSPFM,
    nTYP,
    nPAY_LNK,
    nPAY_SUM,
    nPAY_AUX,
    nSLP_LNK,
    nREM4,
    nREM5,
    nREM6,
    nREM7,
    nC_TYP,
    nC_PAY_LNK,
    nC_PAY_SUM,
    nC_PAY_AUX,
    nC_REM5,
    nC_REM6,
    nYEARFOR,
    nMONTHFOR,
    nBGNFOR,
    nENDFOR,
    nC_YEARFOR,
    nC_MONTHFOR,
    nC_BGNFOR,
    nC_ENDFOR,
    nTOPAY,
    nC_TOPAY
  );
  nRN := nRN + 1;
end;

function find_slp_lnk(
  tmp_nSLPAYS       in number
) return number
as
  tmp_nSLPRN        number;
begin
  begin
    select /*+ FIRST_ROWS */
      A.RN
    into
      tmp_nSLPRN
    from
      SLPSHEETS A,
      DOCLINKS DL
    where A.CALCBETWN = 0
      and A.RN           = DL.OUT_DOCUMENT
      and DL.IN_DOCUMENT = tmp_nSLPAYS
      and rownum < 2;
    return tmp_nSLPRN;
  exception
    when NO_DATA_FOUND then return NULL;
  end;
end;

procedure calc_pays(
  tmp_nATYP         in number,
  tmp_nNTYP         in number,
  tmp_nGRP          in number
)
as
  tmp_nTMP1         number;
  tmp_nTMP2         number;
begin
  nTYP      := tmp_nNTYP;
  tmp_nTMP1 := nRN;
  /* если группировка - скрыть доп. сведения */
  if tmp_nGRP = 1 then
    nREM4     := NULL;
    nREM5     := NULL;
    nREM6     := NULL;
    nREM7     := NULL;
    nYEARFOR  := NULL;
    nMONTHFOR := NULL;
    nBGNFOR   := NULL;
    nENDFOR   := NULL;
  end if;

  /* выборка типов выплат/удержаний */
  for tmp_rec1 in (
    select /*+ ORDERED */
      A.PAY_LNK,
      A.PAY_SUM,
      A.PAY_AUX,
      B.RN SLPAYS,
      B.SLCOMPCHARGES,
      B.YEARFOR,
      B.MONTHFOR,
      B.BGNFOR,
      B.ENDFOR,
      B.YEAR,
      B.MONTH,
      lower(D.CODE) CODE,
      A.TOPAY
    from
      CLNPSPFM_CS A,
      SLPAYS B,
      SLCOMPCHARGES C,
      SLCALCALG D
    where A.AUTHID = UTILIZER
      and A.TYP = tmp_nATYP
      and B.RN = A.PAY_LNK
      and C.RN = B.SLCOMPCHARGES
      and C.SLCALCALG = D.RN
    order by
      C.NUMB)
  loop


    /* определение ведомости */
    nSLP_LNK := find_slp_lnk(tmp_rec1.PAY_LNK);
    /* если не группировать */
    if tmp_nGRP = 0 then
       nTOPAY := tmp_rec1.TOPAY;
       nPAY_LNK := tmp_rec1.SLCOMPCHARGES;
       nPAY_AUX := tmp_rec1.PAY_AUX;
       nPAY_SUM := tmp_rec1.PAY_SUM;
       /* если годЗа<>годВ или месяцЗа<>месяцВ */
       if (tmp_rec1.YEAR <> tmp_rec1.YEARFOR) or (tmp_rec1.MONTH <> tmp_rec1.MONTHFOR) then
          nYEARFOR  := tmp_rec1.YEARFOR;
          nMONTHFOR := tmp_rec1.MONTHFOR;
       else
         nYEARFOR  := NULL;
         nMONTHFOR := NULL;
       end if;
       if tmp_rec1.CODE in ('окл', 'над', 'час', 'отп', 'бос', 'бом', 'отр', 'огс', 'бс2') then
         nBGNFOR := tmp_rec1.BGNFOR;
         nENDFOR := tmp_rec1.ENDFOR;
       else
         nBGNFOR := NULL;
         nENDFOR := NULL;
       end if;
       PKG_SLPAYSPRM.GET(tmp_rec1.SLPAYS,'WRK',nREM4);
       /* проценты - для всех кроме ПОМОЩИ */
       if tmp_rec1.CODE <> 'пом' then
         PKG_SLPAYSPRM.GET(tmp_rec1.SLPAYS,'PRC',nREM5);
       else
         nREM5 := NULL;
       end if;
       /* вычет - для всех */
       PKG_SLPAYSPRM.GET(tmp_rec1.SLPAYS,'DEDUCTSUM',nREM6);
       /* Облагаемая сумма - только для ПОМОЩИ и ССУДЫ*/
       if tmp_rec1.CODE in ('ссд', 'пом') then
          PKG_SLPAYSPRM.GET(tmp_rec1.SLPAYS,'SUMFORTAX',nREM7);
       else
          nREM7 := NULL;
       end if;
       /* Облагаемая сумма - только для Материальная помощь 2 скидки */
       if tmp_rec1.CODE in ('мп2') then
          PKG_SLPAYSPRM.GET(tmp_rec1.SLPAYS,'SUMFORTAXNAL',nREM7);
       else
          nREM7 := NULL;
       end if;
       ins_clnpspfm_cs;
     else /* если группировать */
       if nECXLVED = 1 then        -- Не учитывать ведомость при группировке
         nSLP_LNK := null;
       end if;
       /* поиск записи такого-же типа */
       nTOPAY := 0;
       begin
         select RN
           into tmp_nTMP2
           from CLNPSPFM_CS
          where AUTHID = UTILIZER
            and TYP = nTYP
            and CLNPSPFM = nCLNPSPFM
            and PAY_LNK = tmp_rec1.SLCOMPCHARGES
            and (nECXLVED = 1 or CMP_NUM(SLP_LNK, nSLP_LNK) = 1);
       exception
         when NO_DATA_FOUND then
           tmp_nTMP2 := 0;
       end;
       if tmp_nTMP2 = 0 then
         /* если запись не найдена - просто добавление */
         nPAY_LNK := tmp_rec1.SLCOMPCHARGES;
         nPAY_AUX := tmp_rec1.PAY_AUX;
         nPAY_SUM := tmp_rec1.PAY_SUM;
         ins_clnpspfm_cs;
       else
         /* если записи одинаковые - изменение */
         update CLNPSPFM_CS
            set PAY_SUM = PAY_SUM + tmp_rec1.PAY_SUM
          where AUTHID = UTILIZER
            and RN = tmp_nTMP2;
       end if;
     end if;
  end loop;
  /* подсчет итогов */
  if tmp_nTMP1 <> nRN then
    select nvl(sum(PAY_SUM), 0)
    into nPAY_SUM
    from CLNPSPFM_CS
    where AUTHID = UTILIZER
      and TYP = tmp_nNTYP
      and CLNPSPFM = nCLNPSPFM
      and PAY_AUX = 0;
--    and TOPAY = 0;    По аналогии с 7-кой учитываем все записи, несмотря на вхождение в список расчетов
    nTYP      := tmp_nNTYP + 1;
    nPAY_LNK  := NULL;
    nPAY_AUX  := NULL;
    nSLP_LNK  := NULL;
    nYEARFOR  := NULL;
    nMONTHFOR := NULL;
    nBGNFOR   := NULL;
    nENDFOR   := NULL;
    nREM4     := NULL;
    nREM5     := NULL;
    nREM6     := NULL;
    nREM7     := NULL;
    nTOPAY    := 0;
    ins_clnpspfm_cs;
  end if;
end;

procedure prepare_compact
as
  tmp_nRN           number;
  tmp_nTMP1         number;
  tmp_nTMP2         number;
begin
  nTYP      := NULL;
  nPAY_LNK  := NULL;
  nPAY_AUX  := NULL;
  nPAY_SUM  := NULL;
  nSLP_LNK  := NULL;
  nREM4     := NULL;
  nREM5     := NULL;
  nREM6     := NULL;
  nREM7     := NULL;
  nYEARFOR  := NULL;
  nMONTHFOR := NULL;
  nBGNFOR   := NULL;
  nENDFOR   := NULL;
  nTOPAY    := 0;
  /* определяем первый RN для начислений, авансов, и количество */
  tmp_nTMP1 := 0;
  tmp_nRN   := NULL;
  for tmp_rec1 in (
    select RN
    from CLNPSPFM_CS
    where AUTHID = UTILIZER
      and TYP in (1,2,3,4)
      and CLNPSPFM = nCLNPSPFM
    order by RN)
  loop
    if tmp_nRN is null then
      tmp_nRN := tmp_rec1.RN;
    end if;
    tmp_nTMP1 := tmp_nTMP1 + 1;
  end loop;
  /* переносим данные в правую часть или добавляем записи */
  tmp_nTMP2 := 0;
  for tmp_rec1 in (
    select
      RN,
      TYP,
      PAY_LNK,
      PAY_SUM,
      PAY_AUX,
      YEARFOR,
      MONTHFOR,
      BGNFOR,
      ENDFOR,
      REM5,
      REM6,
      TOPAY
    from CLNPSPFM_CS
    where AUTHID = UTILIZER
      and CLNPSPFM = nCLNPSPFM
      and TYP in (5,6,7,8,9,10)
    order by RN)
  loop
    if tmp_nTMP2 < tmp_nTMP1 then
      update CLNPSPFM_CS
      set
        C_TYP      = tmp_rec1.TYP,
        C_PAY_LNK  = tmp_rec1.PAY_LNK,
        C_PAY_SUM  = tmp_rec1.PAY_SUM,
        C_PAY_AUX  = tmp_rec1.PAY_AUX,
        C_YEARFOR  = tmp_rec1.YEARFOR,
        C_MONTHFOR = tmp_rec1.MONTHFOR,
        C_BGNFOR   = tmp_rec1.BGNFOR,
        C_ENDFOR   = tmp_rec1.ENDFOR,
        C_REM5     = tmp_rec1.REM5,
        C_REM6     = tmp_rec1.REM6,
        C_TOPAY    = tmp_rec1.TOPAY
      where AUTHID = UTILIZER
        and RN     = tmp_nRN + tmp_nTMP2;
    else
      nC_TYP      := tmp_rec1.TYP;
      nC_PAY_LNK  := tmp_rec1.PAY_LNK;
      nC_PAY_SUM  := tmp_rec1.PAY_SUM;
      nC_PAY_AUX  := tmp_rec1.PAY_AUX;
      nC_YEARFOR  := tmp_rec1.YEARFOR;
      nC_MONTHFOR := tmp_rec1.MONTHFOR;
      nC_BGNFOR   := tmp_rec1.BGNFOR;
      nC_ENDFOR   := tmp_rec1.ENDFOR;
      nC_REM5     := tmp_rec1.REM5;
      nC_REM6     := tmp_rec1.REM6;
      nC_TOPAY    := tmp_rec1.TOPAY;
      ins_clnpspfm_cs;
    end if;
    tmp_nTMP2 := tmp_nTMP2 + 1;
  end loop;
  delete CLNPSPFM_CS
  where AUTHID = UTILIZER
    and TYP in (5,6,7,8,9,10)
    and CLNPSPFM = nCLNPSPFM;
  nC_TYP     := NULL;
  nC_PAY_LNK := NULL;
  nC_PAY_SUM := NULL;
  nC_PAY_AUX := NULL;
  nC_YEARFOR  := NULL;
  nC_MONTHFOR := NULL;
  nC_BGNFOR   := NULL;
  nC_ENDFOR   := NULL;
  nC_REM5    := NULL;
  nC_REM6    := NULL;
  nC_TOPAY   := NULL;
end;

procedure calc_footer
(
  tmp_nPERSRN       in number
)
as
  tmp_nTMP          number;
  tmp_nAGENT        number;
begin
  /* определение рег. номера контрагента */
  select /*+ FIRST_ROWS */
    PERS_AGENT
  into tmp_nAGENT
  from CLNPERSONS
  where RN = tmp_nPERSRN;
  /* если формирование по сотруднику, то выход если данные уже были сформированы */
  if nISPERS = 1 then
    select count(*)
    into tmp_nTMP
    from CLNPSPFM_CS
    where AUTHID = UTILIZER
      and TYP in (11, 12)
      and PAY_LNK = tmp_nAGENT;
    if tmp_nTMP > 0 then
      return;
    end if;
  end if;
  nPAY_LNK  := tmp_nAGENT;
  nPAY_AUX  := NULL;
  nSLP_LNK  := NULL;
  nYEARFOR  := NULL;
  nMONTHFOR := NULL;
  nBGNFOR   := NULL;
  nENDFOR   := NULL;
  nREM4     := NULL;
  nREM5     := 0;
  nREM6     := 0;
  nREM7     := 0;
  /* расчет за месяц */
  for rec2 in (
    select /*+ ORDERED */
      B.RN,
      B.SUM
    from
      CLNPSPFM A,
      SLPAYS B
    where A.PERSRN = tmp_nPERSRN
      and trunc(A.BEGENG,'MONTH') <= dSCALC
      and (A.ENDENG >= dSCALC or A.ENDENG is null)
      and B.CLNPSPFM = A.RN
      and B.YEARFOR = nYSCALC
      and B.MONTHFOR = nMSCALC
      and B.SLCOMPCHARGES in (
        select SLCOMPCHARGES
        from SLCOMPGRSTRUCT
        where PRN = nTAX))
  loop
    nPAY_SUM := 0;
    PKG_SLPAYSPRM.GET(rec2.RN,'DEDUCTSUM', nPAY_SUM);
    if not (nPAY_SUM is null) then
      nREM5 := nREM5 + nPAY_SUM;
    end if;
    nPAY_SUM := 0;
    PKG_SLPAYSPRM.GET(rec2.RN,'TAXRATE', nPAY_SUM);
    if not (nPAY_SUM is null) then
      nREM6 := nREM6 + nPAY_SUM;
    end if;
    if not (rec2.SUM is null) then
      nREM7 := nREM7 + rec2.SUM;
    end if;
  end loop;
  nTYP     := 11;
  nREM6    := nREM6 - nREM5;
  nPAY_SUM := NULL;
  ins_clnpspfm_cs;
  /* расчет за год (все месяцы) */
  nREM5     := 0;
  nREM6     := 0;
  nREM7     := 0;
  for rec2 in (
    select /*+ ORDERED */
      B.RN,
      B.SUM
    from
      CLNPSPFM A,
      SLPAYS B
    where A.PERSRN = tmp_nPERSRN
--      and trunc(A.BEGENG,'MONTH') <= dSCALC
--      and (A.ENDENG >= dSCALC or A.ENDENG is null)
      and B.CLNPSPFM = A.RN
      and B.YEARFOR = nYSCALC
      and B.MONTHFOR <= nMSCALC
      and B.SLCOMPCHARGES in (
        select SLCOMPCHARGES
        from SLCOMPGRSTRUCT
        where PRN = nTAX))
  loop
    nPAY_SUM := 0;
    PKG_SLPAYSPRM.GET(rec2.RN,'DEDUCTSUM', nPAY_SUM);
    if not (nPAY_SUM is null) then
      nREM5 := nREM5 + nPAY_SUM;
    end if;
    nPAY_SUM := 0;
    PKG_SLPAYSPRM.GET(rec2.RN,'TAXRATE', nPAY_SUM);
    if not (nPAY_SUM is null) then
      nREM6 := nREM6 + nPAY_SUM;
    end if;
    if not (rec2.SUM is null) then
      nREM7 := nREM7 + rec2.SUM;
    end if;
  end loop;
  nREM6    := nREM6 - nREM5;
  nTYP     := 12;
  nPAY_SUM := NULL;
  ins_clnpspfm_cs;
end;

function is_exists
(
  nPERSRN         in number
)
return boolean
is
  bFOUND          boolean;
  i               binary_integer;
begin
  bFOUND := false;
  i := tbCLNPSPFM.first;
  while i is not null loop
    if ( tbCLNPSPFM(i).PERSRN = nPERSRN ) then
      bFOUND := true;
      exit;
    end if;
    i := tbCLNPSPFM.next(i);
  end loop;
  return bFOUND;
end;

begin
  nRN      := 1;
  nTAX     := NULL;
  dSCALC   := NULL;
  /* очистка временной таблицы */
  delete CLNPSPFM_CS
  where AUTHID = UTILIZER;
  nC_TYP      := NULL;
  nC_PAY_LNK  := NULL;
  nC_PAY_SUM  := NULL;
  nC_PAY_AUX  := NULL;
  nC_YEARFOR  := NULL;
  nC_MONTHFOR := NULL;
  nC_BGNFOR   := NULL;
  nC_ENDFOR   := NULL;
  nC_REM5     := NULL;
  nC_REM6     := NULL;
  nC_TOPAY    := 0;
  sSEQSYMB    := GET_OPTIONS_STR('SeqSymb',nCOMPANY);
  nOCURSIN    := STROCCURS(sCALCIN,sSEQSYMB);
  nOCURSTOPAY := STROCCURS(sCALCTOPAY,sSEQSYMB);

  /* рег. номер группы */
  FIND_SLCOMPGR_CODE(1, 1, nCOMPANY, sTAX, nTAX);
  /* дата */
  dSCALC := trunc(GET_OPTIONS_DATE('SalaryCalcPeriod', nCOMPANY),'MONTH');
  if not dSCALC is null then
    nMSCALC := D_MONTH(dSCALC);
    nYSCALC := D_YEAR(dSCALC);
  end if;

  /* заполнение таблицы исполнений */
  for rec1 in (
    select /*+ ORDERED */
      A.RN,
      A.PERSRN
    from
      SELECTLIST    SL,
      CLNPSPFM      A,
      CLNPSPFMTYPES B
    where SL.IDENT        = nICLNPSPFM
      and A.RN            = SL.DOCUMENT
      and A.CLNPSPFMTYPES = B.RN
    order by
      B.IS_PRIMARY desc,
      A.BEGENG,
      A.PREF,
      A.NUMB )
  loop
    /* если формировать по всем исполнениям и исполнений сотрудника ещё нет в таблице */
    if nISALLPFM = 1 and ( not is_exists( rec1.PERSRN ) ) then
      for rec2 in (
        select
          A.RN
        from
          CLNPSPFM      A,
          CLNPSPFMTYPES B
        where A.PERSRN        = rec1.PERSRN
          and A.CLNPSPFMTYPES = B.RN
          and ( exists ( select null from SLPAYS P where P.CLNPSPFM = A.RN and P.YEAR = nYSCALC and P.MONTH = nMSCALC )
              or A.RN in ( select DOCUMENT from SELECTLIST where IDENT = nICLNPSPFM ) )
        order by
          B.IS_PRIMARY desc,
          A.BEGENG,
          A.PREF,
          A.NUMB
      )
      loop
        /* заносим данные в таблицу */
        tbCLNPSPFM(tbCLNPSPFM.COUNT + 1).RN := rec2.RN;
        tbCLNPSPFM(tbCLNPSPFM.COUNT).PERSRN := rec1.PERSRN;
      end loop;
    elsif nISALLPFM <> 1 then
      /* заносим данные в таблицу */
      tbCLNPSPFM(tbCLNPSPFM.COUNT + 1).RN := rec1.RN;
      tbCLNPSPFM(tbCLNPSPFM.COUNT).PERSRN := rec1.PERSRN;
    end if;

  end loop;

  i := tbCLNPSPFM.FIRST;
  while i is not null loop
    nCLNPSPFM := tbCLNPSPFM(i).RN;
    nPAY_LNK := NULL;
    nPAY_SUM := NULL;
    /* расчет количества нормы дней */
    for rec2 in (
      select /*+ FIRST_ROWS */
        SCHEDULE,
        TIMESORT
      from CLNPSPFMHS
      where PRN = tbCLNPSPFM(i).RN
        and DO_ACT_FROM <= dSCALC
        and (DO_ACT_TO >= dSCALC or DO_ACT_TO is null)
      order by
        DO_ACT_FROM desc)
    loop
      if nPAY_LNK is null then
        nPAY_LNK := rec2.TIMESORT;
        if nPAY_LNK = 1 then               -- в днях
           PKG_CALENDAR.GET_DAYS(nCOMPANY, rec2.SCHEDULE, trunc(dSCALC,'MONTH'), last_day(dSCALC), 'MH()', nPAY_SUM);
        else
           PKG_CALENDAR.GET_HOURS(nCOMPANY, rec2.SCHEDULE, trunc(dSCALC,'MONTH'), last_day(dSCALC), 'MH()', nPAY_SUM);
        end if;
        exit;
      end if;
    end loop;
    nTYP := 0;
    nPAY_AUX  := NULL;
    nSLP_LNK  := NULL;
    nYEARFOR  := NULL;
    nMONTHFOR := NULL;
    nBGNFOR   := NULL;
    nENDFOR   := NULL;
    nREM4     := NULL;
    nREM5     := NULL;
    nREM6     := NULL;
    nREM7     := NULL;

    ins_clnpspfm_cs;
    nTMPDEDUCT := 0;
    /* не печатать отчисления */
    if nDEDUCT = 0 then
       nTMPDEDUCT := 50;
    end if;
    /* предварительные данные: начислено/удержано/отчислено */
    for rec2 in (
      select /*+ ORDERED */
        A.RN,
        A.SUM,
        B.COMPCH_TYPE,
        B.AUXILPAY_SIGN,
        C.CODE as CALCCODE
      from
        SLPAYS A,
        SLCOMPCHARGES B,
        SLCALCTYPE C
      where A.CLNPSPFM = tbCLNPSPFM(i).RN
        and A.SLCALCTYPE = C.RN
        and A.YEAR = nYSCALC
        and A.MONTH = nMSCALC
        and A.SLCOMPCHARGES = B.RN
        and not (B.CONFPAY_SIGN = 1 and B.AUXILPAY_SIGN = 0)
        and not (B.COMPCH_TYPE - nTMPDEDUCT = 0)
        )
    loop
      nLOOP := 1;
      if sCALCIN is not null then
          for j in 1..nOCURSIN+1
          loop
             if rec2.CALCCODE = strtok(sCALCIN ,sSEQSYMB,j) then
                nLOOP := 0;
             end if;
          end loop;
      else
         nLOOP := 0;
      end if;
      if nLOOP = 0 then
         nTOPAY := 1;
         if sCALCTOPAY is not null then
             for j in 1..nOCURSTOPAY+1
             loop
                if rec2.CALCCODE = strtok(sCALCTOPAY ,sSEQSYMB,j) then
                   nTOPAY := 0;
                end if;
             end loop;
         else
            nTOPAY := 0;
         end if;
         nTYP := 0 - rec2.COMPCH_TYPE;
         nPAY_LNK := rec2.RN;
         nPAY_SUM := rec2.SUM;
         nPAY_AUX := rec2.AUXILPAY_SIGN;
         ins_clnpspfm_cs;
      end if;
    end loop;
    /* обработка начислений */
    calc_pays(-10, 1, nGRPADDPAY);
    /* обработка авансов */
    calc_pays(-20, 3, nGRPADDPAY);
    /* обработка удержаний */
    calc_pays(-30, 5, nGRPSUBPAY);
    /* обработка переплат */
    calc_pays(-40, 7, nGRPSUBPAY);
    /* обработка отчислений */
    calc_pays(-50, 9, nGRPSUBPAY);
    /* удаление вспомогательных данных */
    delete CLNPSPFM_CS
    where AUTHID = UTILIZER
      and TYP < 0;
    if nISCOMPACT = 1 then
      prepare_compact;
    end if;
    /* обработка футера по налогу */
    calc_footer(tbCLNPSPFM(i).PERSRN);

    i := tbCLNPSPFM.NEXT(i);
  end loop;
end P_CLNPSPFM_CS;
/
