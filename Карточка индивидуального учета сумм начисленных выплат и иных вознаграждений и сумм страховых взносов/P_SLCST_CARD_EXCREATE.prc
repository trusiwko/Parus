create or replace procedure P_SLCST_CARD_EXCREATE
(
  nCOMPANY           in number,
  nIDENT             in number,              -- Список сотрудников
  dPERIODBEGIN       in date,                -- Период С
  dPERIODEND         in date,                -- Период По
  nTARIF             in number,              -- Код тарифа
  nTARIF1            in number,              -- Код льготного тарифа
  nINVAL3            in number,              -- Формировать данные по инвалидам раздел 3
  nENVD3             in number,              -- Формировать данные по ЕНВД раздел 3
  sINDEXFACT         in varchar2,            -- Максимальная облагаемая сумма
  sSALSCALE_SPFR     in varchar2,            -- Правило определения шкалы СПФР
  sSALSCALE_NPFR     in varchar2,            -- Правило определения шкалы НПФР
  sSALSCALE_FFOMS    in varchar2,            -- Правило определения шкалы ФФОМС
  sSALSCALE_TFOMS    in varchar2,            -- Правило определения шкалы ТФОМС
  sSALSCALE_FSS      in varchar2,            -- Правило определения шкалы ФСС
  sSALSCALE_SPFR1    in varchar2,            -- Правило определения льготной шкалы СПФР
  sSALSCALE_NPFR1    in varchar2,            -- Правило определения льготной шкалы НПФР
  sSALSCALE_FFOMS1   in varchar2,            -- Правило определения льготной шкалы ФФОМС
  sSALSCALE_TFOMS1   in varchar2,            -- Правило определения льготной шкалы ТФОМС
  sSALSCALE_FSS1     in varchar2,            -- Правило определения льготной шкалы ФСС
  sKPP               in varchar2             -- КПП
)
as
 /* константы */
  -- рабочий лист
 SHEET1_FORM           constant PKG_STD.tSTRING := 'Лист1';
 DETAIL                constant PKG_STD.tSTRING := 'Детали';
 CELL_YEAR             constant PKG_STD.tSTRING := 'Календарный_год';
 CELL_PAGE             constant PKG_STD.tSTRING := 'Страница';
 CELL_NAME             constant PKG_STD.tSTRING := 'Организация';
 CELL_INN              constant PKG_STD.tSTRING := 'ИНН';
 CELL_KPP              constant PKG_STD.tSTRING := 'КПП';
 CELL_TARIF            constant PKG_STD.tSTRING := 'Код_тарифа';
 CELL_FIO1             constant PKG_STD.tSTRING := 'Фамилия';
 CELL_FIO2             constant PKG_STD.tSTRING := 'Имя';
 CELL_FIO3             constant PKG_STD.tSTRING := 'Отчество';
 CELL_PFR              constant PKG_STD.tSTRING := 'Номер_ПФР';
 CELL_INN1             constant PKG_STD.tSTRING := 'ИНН_сотрудника';
 CELL_CTZN             constant PKG_STD.tSTRING := 'Гражданство';
 CELL_BIRTH            constant PKG_STD.tSTRING := 'Дата_рождения';
 CELL_INV              constant PKG_STD.tSTRING := 'Инвалид';
 CELL_NOTINV           constant PKG_STD.tSTRING := 'Не_инвалид';
 CELL_BEGINV           constant PKG_STD.tSTRING := 'Дата_выдачи';
 CELL_ENDINV           constant PKG_STD.tSTRING := 'Дата_окончания';
 CELL_SPRF             constant PKG_STD.tSTRING := 'СЧ';
 CELL_NPRF             constant PKG_STD.tSTRING := 'НЧ';
 CELL_FFOMS            constant PKG_STD.tSTRING := 'ФФОМС';
 CELL_TFOMS            constant PKG_STD.tSTRING := 'ТФОМС';
 CELL_FSS              constant PKG_STD.tSTRING := 'ФСС';
 iDETAIL_IDX           integer;

  nSALSCALE_SPFR           PKG_STD.tREF;
  nSALSCALE_NPFR           PKG_STD.tREF;
  nSALSCALE_FFOMS          PKG_STD.tREF;
  nSALSCALE_TFOMS          PKG_STD.tREF;
  nSALSCALE_FSS            PKG_STD.tREF;
  nSALSCALE_SPFR1          PKG_STD.tREF;
  nSALSCALE_NPFR1          PKG_STD.tREF;
  nSALSCALE_FFOMS1         PKG_STD.tREF;
  nSALSCALE_TFOMS1         PKG_STD.tREF;
  nSALSCALE_FSS1           PKG_STD.tREF;
  nPRC_SPFR66              SALTAXSTRUC.PERCENT%TYPE;
  nPRC_NPFR66              SALTAXSTRUC.PERCENT%TYPE;
  nPRC_SPFR67              SALTAXSTRUC.PERCENT%TYPE;
  nPRC_NPFR67              SALTAXSTRUC.PERCENT%TYPE;
  nPRC_FFOMS               SALTAXSTRUC.PERCENT%TYPE;
  nPRC_TFOMS               SALTAXSTRUC.PERCENT%TYPE;
  nPRC_FSS                 SALTAXSTRUC.PERCENT%TYPE;
  nPRC_SPFR166             SALTAXSTRUC.PERCENT%TYPE;
  nPRC_NPFR166             SALTAXSTRUC.PERCENT%TYPE;
  nPRC_SPFR167             SALTAXSTRUC.PERCENT%TYPE;
  nPRC_NPFR167             SALTAXSTRUC.PERCENT%TYPE;
  nPRC_FFOMS1              SALTAXSTRUC.PERCENT%TYPE;
  nPRC_TFOMS1              SALTAXSTRUC.PERCENT%TYPE;
  nPRC_FSS1                SALTAXSTRUC.PERCENT%TYPE;
  nINDEXFACT               PKG_STD.tREF;
  nMAXINCOME               SLPAYS.SUM%TYPE;
  dPERIODBEGIN_            date := dPERIODBEGIN;
  nMONTHBEGIN              number(2);
  nMONTHEND                number(2);
  nYEAR                    number(4);
  sSQL                     varchar2(100) := 'begin PKG_SLCST.CELL_NUMBVALUE_WRITE(:nCELL, :nNUM, 2, :nIDX); end;';
  sTMP                     PKG_STD.tSTRING;
  sREASON_CODE             AGNLIST.REASON_CODE%type;
  rYEAR                    SLCST_RSV1%rowtype;
  rYEAR_FSS                SLCST_RSV1%rowtype;

  procedure INIT_RSV
  (
   rCALC        in out nocopy SLCST_RSV1%rowtype
  )
  as
  begin
    rCALC.COMP         := 0;
    rCALC.COMP_INV     := 0;
    rCALC.COMP_ENVD    := 0;
    rCALC.DEDUCT       := 0;
    rCALC.DEDUCT_INV   := 0;
    rCALC.DEDUCT_ENVD  := 0;
    rCALC.SUD          := 0;
    rCALC.SUD_INV      := 0;
    rCALC.MAXIMUM      := 0;
    rCALC.MAXIMUM_INV  := 0;
    rCALC.MAXIMUM_ENVD := 0;
    rCALC.NPFR         := 0;
    rCALC.NPFR_INV     := 0;
    rCALC.NPFR_ENVD    := 0;
    rCALC.SPFR         := 0;
    rCALC.SPFR_INV     := 0;
    rCALC.SPFR_ENVD    := 0;
    rCALC.FFOMS        := 0;
    rCALC.FFOMS_INV    := 0;
    rCALC.FFOMS_ENVD   := 0;
    rCALC.TFOMS        := 0;
    rCALC.TFOMS_INV    := 0;
    rCALC.TFOMS_ENVD   := 0;
    rCALC.AUTHOR       := 0;
    rCALC.AUTHOR_INV   := 0;
    rCALC.AUTHOR_ENVD  := 0;
  end INIT_RSV;

  procedure FIND_SALTAXSCALE_PRC
  (
   nRULE      in number,
   nYEAR      in number,
   nPRC       out number
  )
  as
   nRN        PKG_STD.tREF;
  begin
    PKG_SLCST.FIND_SALTAXSCALE(nCOMPANY, nRULE, nYEAR, dPERIODEND, nRN);
    -- Ищем процент
    if nRN is not null then
      for CUR in
      (
        select M.PERCENT
          from SALTAXSTRUC M,
               SALTAXEDITS E
         where M.PRN = E.RN
           and E.PRN = nRN
           and E.EDTAX_BEGIN =
            (
              select max( E1.EDTAX_BEGIN )
                from SALTAXEDITS E1
                where E1.PRN = nRN
                  and E1.EDTAX_BEGIN <= dPERIODEND
            )
        order by M.INCOME
      )
      loop
        nPRC := CUR.PERCENT;
        exit;
      end loop;
    end if;
  end FIND_SALTAXSCALE_PRC;

  procedure PRINT_HEAD
  (
   nPAGE          in number,
   nPERS_AGENT    in number,
   sCODE          in varchar2,
   sAGNIDNUMB     in varchar2,
   sAGNFAMILYNAME in varchar2,
   sAGNFIRSTNAME  in varchar2,
   sAGNLASTNAME   in varchar2,
   sPENSION_NBR   in varchar2,
   sINN           in varchar2,
   sCTZN          in varchar2,
   dAGNBURN       in date
  )
  as
    nINV          integer :=0;
  begin
    PRSG_EXCEL.CELL_VALUE_WRITE( CELL_YEAR, 0, iDETAIL_IDX, nYEAR );
    PRSG_EXCEL.CELL_VALUE_WRITE( CELL_PAGE, 0, iDETAIL_IDX, nPAGE );
    PRSG_EXCEL.CELL_VALUE_WRITE( CELL_NAME, 0, iDETAIL_IDX, sCODE );
    PRSG_EXCEL.CELL_VALUE_WRITE( CELL_INN, 0, iDETAIL_IDX, lpad(trim(sAGNIDNUMB),10,'0') );
    PRSG_EXCEL.CELL_VALUE_WRITE( CELL_KPP, 0, iDETAIL_IDX, nvl(sKPP, sREASON_CODE) );
    PRSG_EXCEL.CELL_VALUE_WRITE( CELL_FIO1, 0, iDETAIL_IDX, sAGNFAMILYNAME );
    PRSG_EXCEL.CELL_VALUE_WRITE( CELL_FIO2, 0, iDETAIL_IDX, sAGNFIRSTNAME );
    PRSG_EXCEL.CELL_VALUE_WRITE( CELL_FIO3, 0, iDETAIL_IDX, sAGNLASTNAME );
    PRSG_EXCEL.CELL_VALUE_WRITE( CELL_PFR, 0, iDETAIL_IDX, sPENSION_NBR );
    PRSG_EXCEL.CELL_VALUE_WRITE( CELL_INN1, 0, iDETAIL_IDX, lpad(trim(sINN),12,'0') );
    PRSG_EXCEL.CELL_VALUE_WRITE( CELL_CTZN, 0, iDETAIL_IDX, sCTZN );
    PRSG_EXCEL.CELL_VALUE_WRITE( CELL_BIRTH, 0, iDETAIL_IDX, to_char(dAGNBURN, 'DD.MM.YYYY') );
    if nPAGE = 1 then
      PRSG_EXCEL.CELL_VALUE_WRITE( CELL_TARIF, 0, iDETAIL_IDX, lpad(nTARIF,2,'0') );
      if D_YEAR(dAGNBURN) > 1966 then
        PRSG_EXCEL.CELL_VALUE_WRITE( CELL_SPRF, 0, iDETAIL_IDX, nPRC_SPFR67 );
        PRSG_EXCEL.CELL_VALUE_WRITE( CELL_NPRF, 0, iDETAIL_IDX, nPRC_NPFR67 );
           else
        PRSG_EXCEL.CELL_VALUE_WRITE( CELL_SPRF, 0, iDETAIL_IDX, nPRC_SPFR66 );
        PRSG_EXCEL.CELL_VALUE_WRITE( CELL_NPRF, 0, iDETAIL_IDX, nPRC_NPFR66 );
      end if;
      PRSG_EXCEL.CELL_VALUE_WRITE( CELL_FFOMS, 0, iDETAIL_IDX, nPRC_FFOMS );
      PRSG_EXCEL.CELL_VALUE_WRITE( CELL_TFOMS, 0, iDETAIL_IDX, nPRC_TFOMS );
      PRSG_EXCEL.CELL_VALUE_WRITE( CELL_FSS, 0, iDETAIL_IDX, nPRC_FSS );
    else
      PRSG_EXCEL.CELL_VALUE_WRITE( CELL_TARIF, 0, iDETAIL_IDX, lpad(nTARIF1,2,'0') );
      if D_YEAR(dAGNBURN) > 1966 then
        PRSG_EXCEL.CELL_VALUE_WRITE( CELL_SPRF, 0, iDETAIL_IDX, nPRC_SPFR167 );
        PRSG_EXCEL.CELL_VALUE_WRITE( CELL_NPRF, 0, iDETAIL_IDX, nPRC_NPFR167 );
      else
        PRSG_EXCEL.CELL_VALUE_WRITE( CELL_SPRF, 0, iDETAIL_IDX, nPRC_SPFR166 );
        PRSG_EXCEL.CELL_VALUE_WRITE( CELL_NPRF, 0, iDETAIL_IDX, nPRC_NPFR166 );
      end if;
      PRSG_EXCEL.CELL_VALUE_WRITE( CELL_FFOMS, 0, iDETAIL_IDX, nPRC_FFOMS1 );
      PRSG_EXCEL.CELL_VALUE_WRITE( CELL_TFOMS, 0, iDETAIL_IDX, nPRC_TFOMS1 );
      PRSG_EXCEL.CELL_VALUE_WRITE( CELL_FSS, 0, iDETAIL_IDX, nPRC_FSS1 );
    end if;
    for reci in
    (
      select REF_BEG,
             REF_END
        from SLCST_INVALID
       where AUTHID = user
         and AGENT = nPERS_AGENT
    )
    loop
      nINV:= 1;
      PRSG_EXCEL.CELL_ATTRIBUTE_SET(CELL_INV, 0, iDETAIL_IDX, 'Font.Underline', 'xlUnderlineStyleSingle');
      PRSG_EXCEL.CELL_VALUE_WRITE( CELL_BEGINV, 0, iDETAIL_IDX, to_char(reci.REF_BEG, 'DD.MM.YYYY') );
      PRSG_EXCEL.CELL_VALUE_WRITE( CELL_ENDINV, 0, iDETAIL_IDX, to_char(reci.REF_END, 'DD.MM.YYYY') );
    end loop;
    if nINV = 0 then
      PRSG_EXCEL.CELL_ATTRIBUTE_SET(CELL_NOTINV, 0, iDETAIL_IDX, 'Font.Underline', 'xlUnderlineStyleSingle');
    end if;
  end PRINT_HEAD;

begin
  /* Правило определения шкалы СПФР */
  if sSALSCALE_SPFR is not null then
    FIND_SALSCALE_CODE(0, 0, nCOMPANY, sSALSCALE_SPFR, nSALSCALE_SPFR);
    FIND_SALTAXSCALE_PRC(nSALSCALE_SPFR, 1966, nPRC_SPFR66);
    FIND_SALTAXSCALE_PRC(nSALSCALE_SPFR, 1967, nPRC_SPFR67);
  end if;
  /* Правило определения шкалы НПФР */
  if sSALSCALE_NPFR is not null then
    FIND_SALSCALE_CODE(0, 0, nCOMPANY, sSALSCALE_NPFR, nSALSCALE_NPFR);
    FIND_SALTAXSCALE_PRC(nSALSCALE_NPFR, 1966, nPRC_NPFR66);
    FIND_SALTAXSCALE_PRC(nSALSCALE_NPFR, 1967, nPRC_NPFR67);
  end if;
  /* Правило определения шкалы ФФОМС */
  if sSALSCALE_FFOMS is not null then
    FIND_SALSCALE_CODE(0, 0, nCOMPANY, sSALSCALE_FFOMS, nSALSCALE_FFOMS);
    FIND_SALTAXSCALE_PRC(nSALSCALE_FFOMS, 0, nPRC_FFOMS);
  end if;
  /* Правило определения шкалы ТФОМС */
  if sSALSCALE_TFOMS is not null then
    FIND_SALSCALE_CODE(0, 0, nCOMPANY, sSALSCALE_TFOMS, nSALSCALE_TFOMS);
    FIND_SALTAXSCALE_PRC(nSALSCALE_TFOMS, 0, nPRC_TFOMS);
  end if;
  /* Правило определения шкалы ФСC */
  if sSALSCALE_FSS is not null then
    FIND_SALSCALE_CODE(0, 0, nCOMPANY, sSALSCALE_FSS, nSALSCALE_FSS);
    FIND_SALTAXSCALE_PRC(nSALSCALE_FSS, 0, nPRC_FSS);
  end if;
  if nINVAL3 + nENVD3 > 0 then
    /* Правило определения льготной шкалы СПФР */
    if sSALSCALE_SPFR1 is not null then
      FIND_SALSCALE_CODE(0, 0, nCOMPANY, sSALSCALE_SPFR1, nSALSCALE_SPFR1);
      FIND_SALTAXSCALE_PRC(nSALSCALE_SPFR1, 1966, nPRC_SPFR166);
      FIND_SALTAXSCALE_PRC(nSALSCALE_SPFR1, 1967, nPRC_SPFR167);
    end if;
    /* Правило определения льготной шкалы НПФР */
    if sSALSCALE_NPFR1 is not null then
      FIND_SALSCALE_CODE(0, 0, nCOMPANY, sSALSCALE_NPFR1, nSALSCALE_NPFR1);
      FIND_SALTAXSCALE_PRC(nSALSCALE_NPFR1, 1966, nPRC_NPFR166);
      FIND_SALTAXSCALE_PRC(nSALSCALE_NPFR1, 1967, nPRC_NPFR167);
    end if;
    /* Правило определения льготной шкалы ФФОМС */
    if sSALSCALE_FFOMS1 is not null then
      FIND_SALSCALE_CODE(0, 0, nCOMPANY, sSALSCALE_FFOMS1, nSALSCALE_FFOMS1);
      FIND_SALTAXSCALE_PRC(nSALSCALE_FFOMS1, 0, nPRC_FFOMS1);
    end if;
    /* Правило определения льготной шкалы ТФОМС */
    if sSALSCALE_TFOMS1 is not null then
      FIND_SALSCALE_CODE(0, 0, nCOMPANY, sSALSCALE_TFOMS1, nSALSCALE_TFOMS1);
      FIND_SALTAXSCALE_PRC(nSALSCALE_TFOMS1, 0, nPRC_TFOMS1);
    end if;
    /* Правило определения льготной шкалы ФСC */
    if sSALSCALE_FSS1 is not null then
      FIND_SALSCALE_CODE(0, 0, nCOMPANY, sSALSCALE_FSS1, nSALSCALE_FSS1);
      FIND_SALTAXSCALE_PRC(nSALSCALE_FSS1, 0, nPRC_FSS1);
    end if;
  end if;
  /* Максимальная облагаемая сумма */
  if sINDEXFACT is not null then
    FIND_INDEXFACT_CODE(0, 0, nCOMPANY, sINDEXFACT, nINDEXFACT);
    -- Получаем заданное в словаре ограничение
    P_INDEXFACT_BASE_GETVAL( nINDEXFACT, dPERIODEND, nMAXINCOME );
  else
    nMAXINCOME := null;
  end if;

  /* установка текущего рабочего листа */
  PRSG_EXCEL.SHEET_SELECT( SHEET1_FORM );
  /* описание */
  -- строки и ячейки
  PRSG_EXCEL.LINE_DESCRIBE( DETAIL );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, CELL_YEAR );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, CELL_PAGE );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, CELL_NAME );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, CELL_INN );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, CELL_KPP );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, CELL_TARIF );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, CELL_FIO1 );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, CELL_FIO2 );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, CELL_FIO3 );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, CELL_PFR );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, CELL_INN1 );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, CELL_CTZN );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, CELL_BIRTH );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, CELL_INV );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, CELL_NOTINV );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, CELL_BEGINV );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, CELL_ENDINV );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, CELL_SPRF );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, CELL_NPRF );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, CELL_FFOMS );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, CELL_TFOMS );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, CELL_FSS );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Выплаты_1' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Выплаты_2' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Выплаты_3' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Выплаты_4' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Выплаты_5' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Выплаты_6' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Выплаты_7' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Выплаты_8' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Выплаты_9' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Выплаты_10' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Выплаты_11' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Выплаты_12' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Выплаты_год_1' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Выплаты_год_2' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Выплаты_год_3' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Выплаты_год_4' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Выплаты_год_5' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Выплаты_год_6' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Выплаты_год_7' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Выплаты_год_8' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Выплаты_год_9' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Выплаты_год_10' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Выплаты_год_11' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Выплаты_год_12' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Ч7СТ8_1' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Ч7СТ8_2' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Ч7СТ8_3' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Ч7СТ8_4' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Ч7СТ8_5' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Ч7СТ8_6' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Ч7СТ8_7' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Ч7СТ8_8' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Ч7СТ8_9' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Ч7СТ8_10' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Ч7СТ8_11' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Ч7СТ8_12' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Ч7СТ8_год_1' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Ч7СТ8_год_2' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Ч7СТ8_год_3' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Ч7СТ8_год_4' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Ч7СТ8_год_5' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Ч7СТ8_год_6' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Ч7СТ8_год_7' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Ч7СТ8_год_8' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Ч7СТ8_год_9' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Ч7СТ8_год_10' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Ч7СТ8_год_11' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Ч7СТ8_год_12' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Ч1СТ9_1' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Ч1СТ9_2' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Ч1СТ9_3' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Ч1СТ9_4' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Ч1СТ9_5' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Ч1СТ9_6' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Ч1СТ9_7' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Ч1СТ9_8' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Ч1СТ9_9' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Ч1СТ9_10' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Ч1СТ9_11' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Ч1СТ9_12' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Ч1СТ9_год_1' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Ч1СТ9_год_2' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Ч1СТ9_год_3' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Ч1СТ9_год_4' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Ч1СТ9_год_5' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Ч1СТ9_год_6' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Ч1СТ9_год_7' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Ч1СТ9_год_8' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Ч1СТ9_год_9' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Ч1СТ9_год_10' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Ч1СТ9_год_11' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Ч1СТ9_год_12' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'П1Ч3СТ9_1' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'П1Ч3СТ9_2' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'П1Ч3СТ9_3' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'П1Ч3СТ9_4' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'П1Ч3СТ9_5' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'П1Ч3СТ9_6' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'П1Ч3СТ9_7' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'П1Ч3СТ9_8' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'П1Ч3СТ9_9' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'П1Ч3СТ9_10' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'П1Ч3СТ9_11' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'П1Ч3СТ9_12' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'П1Ч3СТ9_год_1' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'П1Ч3СТ9_год_2' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'П1Ч3СТ9_год_3' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'П1Ч3СТ9_год_4' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'П1Ч3СТ9_год_5' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'П1Ч3СТ9_год_6' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'П1Ч3СТ9_год_7' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'П1Ч3СТ9_год_8' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'П1Ч3СТ9_год_9' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'П1Ч3СТ9_год_10' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'П1Ч3СТ9_год_11' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'П1Ч3СТ9_год_12' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'П2Ч3СТ9_1' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'П2Ч3СТ9_2' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'П2Ч3СТ9_3' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'П2Ч3СТ9_4' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'П2Ч3СТ9_5' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'П2Ч3СТ9_6' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'П2Ч3СТ9_7' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'П2Ч3СТ9_8' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'П2Ч3СТ9_9' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'П2Ч3СТ9_10' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'П2Ч3СТ9_11' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'П2Ч3СТ9_12' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'П2Ч3СТ9_год_1' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'П2Ч3СТ9_год_2' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'П2Ч3СТ9_год_3' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'П2Ч3СТ9_год_4' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'П2Ч3СТ9_год_5' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'П2Ч3СТ9_год_6' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'П2Ч3СТ9_год_7' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'П2Ч3СТ9_год_8' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'П2Ч3СТ9_год_9' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'П2Ч3СТ9_год_10' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'П2Ч3СТ9_год_11' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'П2Ч3СТ9_год_12' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Ч4СТ8_1' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Ч4СТ8_2' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Ч4СТ8_3' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Ч4СТ8_4' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Ч4СТ8_5' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Ч4СТ8_6' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Ч4СТ8_7' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Ч4СТ8_8' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Ч4СТ8_9' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Ч4СТ8_10' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Ч4СТ8_11' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Ч4СТ8_12' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Ч4СТ8_год_1' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Ч4СТ8_год_2' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Ч4СТ8_год_3' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Ч4СТ8_год_4' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Ч4СТ8_год_5' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Ч4СТ8_год_6' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Ч4СТ8_год_7' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Ч4СТ8_год_8' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Ч4СТ8_год_9' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Ч4СТ8_год_10' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Ч4СТ8_год_11' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Ч4СТ8_год_12' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'База_ОПС_1' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'База_ОПС_2' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'База_ОПС_3' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'База_ОПС_4' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'База_ОПС_5' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'База_ОПС_6' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'База_ОПС_7' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'База_ОПС_8' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'База_ОПС_9' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'База_ОПС_10' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'База_ОПС_11' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'База_ОПС_12' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'База_ОПС_год_1' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'База_ОПС_год_2' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'База_ОПС_год_3' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'База_ОПС_год_4' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'База_ОПС_год_5' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'База_ОПС_год_6' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'База_ОПС_год_7' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'База_ОПС_год_8' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'База_ОПС_год_9' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'База_ОПС_год_10' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'База_ОПС_год_11' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'База_ОПС_год_12' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'База_ОМС_1' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'База_ОМС_2' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'База_ОМС_3' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'База_ОМС_4' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'База_ОМС_5' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'База_ОМС_6' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'База_ОМС_7' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'База_ОМС_8' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'База_ОМС_9' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'База_ОМС_10' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'База_ОМС_11' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'База_ОМС_12' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'База_ОМС_год_1' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'База_ОМС_год_2' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'База_ОМС_год_3' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'База_ОМС_год_4' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'База_ОМС_год_5' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'База_ОМС_год_6' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'База_ОМС_год_7' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'База_ОМС_год_8' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'База_ОМС_год_9' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'База_ОМС_год_10' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'База_ОМС_год_11' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'База_ОМС_год_12' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'База_ФСС_1' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'База_ФСС_2' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'База_ФСС_3' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'База_ФСС_4' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'База_ФСС_5' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'База_ФСС_6' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'База_ФСС_7' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'База_ФСС_8' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'База_ФСС_9' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'База_ФСС_10' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'База_ФСС_11' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'База_ФСС_12' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'База_ФСС_год_1' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'База_ФСС_год_2' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'База_ФСС_год_3' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'База_ФСС_год_4' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'База_ФСС_год_5' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'База_ФСС_год_6' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'База_ФСС_год_7' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'База_ФСС_год_8' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'База_ФСС_год_9' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'База_ФСС_год_10' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'База_ФСС_год_11' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'База_ФСС_год_12' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_СПФР_1' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_СПФР_2' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_СПФР_3' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_СПФР_4' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_СПФР_5' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_СПФР_6' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_СПФР_7' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_СПФР_8' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_СПФР_9' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_СПФР_10' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_СПФР_11' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_СПФР_12' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_СПФР_год_1' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_СПФР_год_2' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_СПФР_год_3' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_СПФР_год_4' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_СПФР_год_5' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_СПФР_год_6' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_СПФР_год_7' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_СПФР_год_8' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_СПФР_год_9' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_СПФР_год_10' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_СПФР_год_11' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_СПФР_год_12' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_НПФР_1' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_НПФР_2' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_НПФР_3' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_НПФР_4' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_НПФР_5' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_НПФР_6' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_НПФР_7' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_НПФР_8' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_НПФР_9' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_НПФР_10' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_НПФР_11' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_НПФР_12' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_НПФР_год_1' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_НПФР_год_2' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_НПФР_год_3' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_НПФР_год_4' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_НПФР_год_5' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_НПФР_год_6' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_НПФР_год_7' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_НПФР_год_8' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_НПФР_год_9' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_НПФР_год_10' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_НПФР_год_11' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_НПФР_год_12' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_ФФОМС_1' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_ФФОМС_2' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_ФФОМС_3' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_ФФОМС_4' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_ФФОМС_5' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_ФФОМС_6' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_ФФОМС_7' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_ФФОМС_8' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_ФФОМС_9' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_ФФОМС_10' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_ФФОМС_11' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_ФФОМС_12' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_ФФОМС_год_1' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_ФФОМС_год_2' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_ФФОМС_год_3' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_ФФОМС_год_4' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_ФФОМС_год_5' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_ФФОМС_год_6' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_ФФОМС_год_7' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_ФФОМС_год_8' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_ФФОМС_год_9' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_ФФОМС_год_10' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_ФФОМС_год_11' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_ФФОМС_год_12' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_ТФОМС_1' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_ТФОМС_2' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_ТФОМС_3' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_ТФОМС_4' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_ТФОМС_5' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_ТФОМС_6' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_ТФОМС_7' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_ТФОМС_8' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_ТФОМС_9' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_ТФОМС_10' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_ТФОМС_11' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_ТФОМС_12' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_ТФОМС_год_1' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_ТФОМС_год_2' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_ТФОМС_год_3' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_ТФОМС_год_4' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_ТФОМС_год_5' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_ТФОМС_год_6' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_ТФОМС_год_7' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_ТФОМС_год_8' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_ТФОМС_год_9' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_ТФОМС_год_10' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_ТФОМС_год_11' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_ТФОМС_год_12' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_ФСС_1' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_ФСС_2' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_ФСС_3' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_ФСС_4' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_ФСС_5' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_ФСС_6' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_ФСС_7' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_ФСС_8' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_ФСС_9' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_ФСС_10' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_ФСС_11' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_ФСС_12' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_ФСС_год_1' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_ФСС_год_2' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_ФСС_год_3' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_ФСС_год_4' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_ФСС_год_5' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_ФСС_год_6' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_ФСС_год_7' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_ФСС_год_8' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_ФСС_год_9' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_ФСС_год_10' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_ФСС_год_11' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Начислено_ФСС_год_12' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Пособия_ФСС_1' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Пособия_ФСС_2' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Пособия_ФСС_3' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Пособия_ФСС_4' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Пособия_ФСС_5' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Пособия_ФСС_6' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Пособия_ФСС_7' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Пособия_ФСС_8' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Пособия_ФСС_9' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Пособия_ФСС_10' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Пособия_ФСС_11' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Пособия_ФСС_12' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Пособия_ФСС_год_1' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Пособия_ФСС_год_2' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Пособия_ФСС_год_3' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Пособия_ФСС_год_4' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Пособия_ФСС_год_5' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Пособия_ФСС_год_6' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Пособия_ФСС_год_7' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Пособия_ФСС_год_8' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Пособия_ФСС_год_9' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Пособия_ФСС_год_10' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Пособия_ФСС_год_11' );
  PRSG_EXCEL.LINE_CELL_DESCRIBE( DETAIL, 'Пособия_ФСС_год_12' );

  nYEAR := D_YEAR(dPERIODEND);
  if dPERIODBEGIN is null or D_YEAR(dPERIODBEGIN) <> nYEAR then
    dPERIODBEGIN_ := INT2DATE(1, 1, nYEAR);
  end if;
  nMONTHBEGIN := D_MONTH(dPERIODBEGIN_);
  nMONTHEND   := D_MONTH(dPERIODEND);

  for recs in
  (
    select SL.DOCUMENT,
           C.PERS_AGENT,
           C.OWNER_AGENT,
           TC.RN,
           A1.AGNFAMILYNAME,
           A1.AGNFIRSTNAME,
           A1.AGNLASTNAME,
           A1.AGNIDNUMB as INN,
           FORMAT_HIER_NAME( null, A1.VERSION, CS.FULLNAME ) as CTZN,
           A1.AGNBURN,
           A1.PENSION_NBR,
           A2.AGNABBR,
           A2.AGNIDNUMB
      from SELECTLIST    SL,
           CLNPERSONS     C,
           CLNPERSTAXACC TC,
           AGNLIST       A1,
           AGNLIST       A2,
           GEOGRAFY      CS
     where SL.IDENT = nIDENT
       and SL.DOCUMENT   = C.RN
       and C.RN          = TC.PRN
       and C.PERS_AGENT  = A1.RN
       and C.OWNER_AGENT = A2.RN
       and A1.CITIZENSHIP= CS.RN(+)
       and TC.TYPE = 0
       and TC.YEAR = nYEAR
  )
  loop
    /* расчет */
    delete from SLCST_RSV1;
    /* инвалиды */
    delete from SLCST_INVALID
     where AUTHID = user;

    /* Расчет по сотруднику */
    PKG_SLCST.CALC_PFR(recs.PERS_AGENT, recs.DOCUMENT, recs.RN, nYEAR, nMONTHBEGIN, nMONTHEND, nINVAL3, nENVD3, nMAXINCOME, 2);

    /* Печать основного листа */
    PKG_SLCST.GET_AGENT_PARAM(nCOMPANY, recs.OWNER_AGENT, dPERIODEND, sTMP, sTMP, sTMP, sREASON_CODE);
    iDETAIL_IDX := PRSG_EXCEL.LINE_APPEND( DETAIL );
    /* Заголовок */
    PRINT_HEAD(1, recs.PERS_AGENT, recs.AGNABBR, recs.AGNIDNUMB, recs.AGNFAMILYNAME,
      recs.AGNFIRSTNAME, recs.AGNLASTNAME, recs.PENSION_NBR, recs.INN, recs.CTZN, recs.AGNBURN);

    INIT_RSV(rYEAR);
    INIT_RSV(rYEAR_FSS);

    for rec in
    (
      select MONTHNUMB,
             COMP,
             COMP_INV,
             COMP_ENVD,
             DEDUCT,
             SUD,
             MAXIMUM,
             SPFR,
             NPFR,
             FFOMS,
             TFOMS,
             AUTHOR
        from SLCST_RSV1
       where FSS = 0
       order by MONTHNUMB
    )
    loop
      /* Накопители с начала года */
      rYEAR.COMP         := rYEAR.COMP + rec.COMP;
      rYEAR.COMP_INV     := rYEAR.COMP_INV + rec.COMP_INV;
      rYEAR.COMP_ENVD    := rYEAR.COMP_ENVD + rec.COMP_ENVD;
      rYEAR.DEDUCT       := rYEAR.DEDUCT + rec.DEDUCT;
      rYEAR.SUD          := rYEAR.SUD + rec.SUD;
      rYEAR.MAXIMUM      := rYEAR.MAXIMUM + rec.MAXIMUM;
      rYEAR.SPFR         := rYEAR.SPFR + rec.SPFR;
      rYEAR.NPFR         := rYEAR.NPFR + rec.NPFR;
      rYEAR.FFOMS        := rYEAR.FFOMS + rec.FFOMS;
      rYEAR.TFOMS        := rYEAR.TFOMS + rec.TFOMS;
      rYEAR.AUTHOR       := rYEAR.AUTHOR + rec.AUTHOR;

      execute immediate sSQL using 'Выплаты_'||trim(rec.MONTHNUMB), rec.COMP, iDETAIL_IDX;
      execute immediate sSQL using 'Выплаты_год_'||trim(rec.MONTHNUMB), rYEAR.COMP, iDETAIL_IDX;
      execute immediate sSQL using 'Ч7СТ8_'||trim(rec.MONTHNUMB), rec.AUTHOR, iDETAIL_IDX;
      execute immediate sSQL using 'Ч7СТ8_год_'||trim(rec.MONTHNUMB), rYEAR.AUTHOR, iDETAIL_IDX;
      execute immediate sSQL using 'Ч1СТ9_'||trim(rec.MONTHNUMB), rec.DEDUCT, iDETAIL_IDX;
      execute immediate sSQL using 'Ч1СТ9_год_'||trim(rec.MONTHNUMB), rYEAR.DEDUCT, iDETAIL_IDX;
      execute immediate sSQL using 'П1Ч3СТ9_'||trim(rec.MONTHNUMB), rec.SUD, iDETAIL_IDX;
      execute immediate sSQL using 'П1Ч3СТ9_год_'||trim(rec.MONTHNUMB), rYEAR.SUD, iDETAIL_IDX;
      execute immediate sSQL using 'Ч4СТ8_'||trim(rec.MONTHNUMB), rec.MAXIMUM, iDETAIL_IDX;
      execute immediate sSQL using 'Ч4СТ8_год_'||trim(rec.MONTHNUMB), rYEAR.MAXIMUM, iDETAIL_IDX;
      execute immediate sSQL using 'База_ОПС_'||trim(rec.MONTHNUMB),
        rec.COMP - rec.AUTHOR - rec.DEDUCT - rec.SUD, iDETAIL_IDX;
      execute immediate sSQL using 'База_ОПС_год_'||trim(rec.MONTHNUMB),
        rYEAR.COMP - rYEAR.AUTHOR - rYEAR.DEDUCT - rYEAR.SUD, iDETAIL_IDX;
      execute immediate sSQL using 'База_ОМС_'||trim(rec.MONTHNUMB),
        rec.COMP - rec.AUTHOR - rec.DEDUCT, iDETAIL_IDX;
      execute immediate sSQL using 'База_ОМС_год_'||trim(rec.MONTHNUMB),
        rYEAR.COMP - rYEAR.AUTHOR - rYEAR.DEDUCT, iDETAIL_IDX;
      execute immediate sSQL using 'Начислено_СПФР_'||trim(rec.MONTHNUMB), rec.SPFR, iDETAIL_IDX;
      execute immediate sSQL using 'Начислено_СПФР_год_'||trim(rec.MONTHNUMB), rYEAR.SPFR, iDETAIL_IDX;
      execute immediate sSQL using 'Начислено_НПФР_'||trim(rec.MONTHNUMB), rec.NPFR, iDETAIL_IDX;
      execute immediate sSQL using 'Начислено_НПФР_год_'||trim(rec.MONTHNUMB), rYEAR.NPFR, iDETAIL_IDX;
      execute immediate sSQL using 'Начислено_ФФОМС_'||trim(rec.MONTHNUMB), rec.FFOMS, iDETAIL_IDX;
      execute immediate sSQL using 'Начислено_ФФОМС_год_'||trim(rec.MONTHNUMB), rYEAR.FFOMS, iDETAIL_IDX;
      execute immediate sSQL using 'Начислено_ТФОМС_'||trim(rec.MONTHNUMB), rec.TFOMS, iDETAIL_IDX;
      execute immediate sSQL using 'Начислено_ТФОМС_год_'||trim(rec.MONTHNUMB), rYEAR.TFOMS, iDETAIL_IDX;

      /* Данные по ФСС */
      for rec1 in
      (
        select SPFR,
               NPFR,
               AUTHOR
          from SLCST_RSV1
         where FSS = 1
           and MONTHNUMB = rec.MONTHNUMB
      )
      loop
        /* Накопители с начала года */
        rYEAR_FSS.AUTHOR := rYEAR_FSS.AUTHOR + rec1.AUTHOR;
        rYEAR_FSS.SPFR   := rYEAR_FSS.SPFR + rec1.SPFR;
        rYEAR_FSS.NPFR   := rYEAR_FSS.NPFR + rec1.NPFR;

        execute immediate sSQL using 'П2Ч3СТ9_'||trim(rec.MONTHNUMB), rec1.AUTHOR, iDETAIL_IDX;
        execute immediate sSQL using 'П2Ч3СТ9_год_'||trim(rec.MONTHNUMB), rYEAR_FSS.AUTHOR, iDETAIL_IDX;
        execute immediate sSQL using 'База_ФСС_'||trim(rec.MONTHNUMB),
          rec.COMP - rec.DEDUCT - rec1.AUTHOR, iDETAIL_IDX;
        execute immediate sSQL using 'База_ФСС_год_'||trim(rec.MONTHNUMB),
          rYEAR.COMP - rYEAR.DEDUCT - rYEAR_FSS.AUTHOR, iDETAIL_IDX;
        execute immediate sSQL using 'Начислено_ФСС_'||trim(rec.MONTHNUMB), rec1.SPFR, iDETAIL_IDX;
        execute immediate sSQL using 'Начислено_ФСС_год_'||trim(rec.MONTHNUMB), rYEAR_FSS.SPFR, iDETAIL_IDX;
        execute immediate sSQL using 'Пособия_ФСС_'||trim(rec.MONTHNUMB), rec1.NPFR, iDETAIL_IDX;
        execute immediate sSQL using 'Пособия_ФСС_год_'||trim(rec.MONTHNUMB), rYEAR_FSS.NPFR, iDETAIL_IDX;
      end loop;
    end loop;

    /* Печать льготников */
    if nINVAL3 + nENVD3 > 0 and rYEAR.COMP_INV + rYEAR.COMP_ENVD > 0 then
      iDETAIL_IDX := PRSG_EXCEL.LINE_APPEND( DETAIL );
      /* Заголовок */
      PRINT_HEAD(2, recs.PERS_AGENT, recs.AGNABBR, recs.AGNIDNUMB, recs.AGNFAMILYNAME,
        recs.AGNFIRSTNAME, recs.AGNLASTNAME, recs.PENSION_NBR, recs.INN, recs.CTZN, recs.AGNBURN);
      INIT_RSV(rYEAR);
      INIT_RSV(rYEAR_FSS);

      for rec in
      (
        select MONTHNUMB,
               COMP_INV,
               COMP_ENVD,
               DEDUCT_INV,
               DEDUCT_ENVD,
               SUD_INV,
               MAXIMUM_INV,
               MAXIMUM_ENVD,
               SPFR_INV,
               SPFR_ENVD,
               NPFR_INV,
               NPFR_ENVD,
               FFOMS_INV,
               FFOMS_ENVD,
               TFOMS_INV,
               TFOMS_ENVD,
               AUTHOR_INV,
               AUTHOR_ENVD
          from SLCST_RSV1
         where FSS = 0
         order by MONTHNUMB
      )
      loop
        /* Накопители с начала года */
        rYEAR.COMP_INV     := rYEAR.COMP_INV + rec.COMP_INV;
        rYEAR.COMP_ENVD    := rYEAR.COMP_ENVD + rec.COMP_ENVD;
        rYEAR.DEDUCT_INV   := rYEAR.DEDUCT_INV + rec.DEDUCT_INV;
        rYEAR.DEDUCT_ENVD  := rYEAR.DEDUCT_ENVD + rec.DEDUCT_ENVD;
        rYEAR.SUD_INV      := rYEAR.SUD_INV + rec.SUD_INV;
        rYEAR.MAXIMUM_INV  := rYEAR.MAXIMUM_INV + rec.MAXIMUM_INV;
        rYEAR.MAXIMUM_ENVD := rYEAR.MAXIMUM_ENVD + rec.MAXIMUM_ENVD;
        rYEAR.SPFR_INV     := rYEAR.SPFR_INV + rec.SPFR_INV;
        rYEAR.SPFR_ENVD    := rYEAR.SPFR_ENVD + rec.SPFR_ENVD;
        rYEAR.NPFR_INV     := rYEAR.NPFR_INV + rec.NPFR_INV;
        rYEAR.NPFR_ENVD    := rYEAR.NPFR_ENVD + rec.NPFR_ENVD;
        rYEAR.FFOMS_INV    := rYEAR.FFOMS_INV + rec.FFOMS_INV;
        rYEAR.FFOMS_ENVD   := rYEAR.FFOMS_ENVD + rec.FFOMS_ENVD;
        rYEAR.TFOMS_INV    := rYEAR.TFOMS_INV + rec.TFOMS_INV;
        rYEAR.TFOMS_ENVD   := rYEAR.TFOMS_ENVD + rec.TFOMS_ENVD;
        rYEAR.AUTHOR_INV   := rYEAR.AUTHOR_INV + rec.AUTHOR_INV;
        rYEAR.AUTHOR_ENVD  := rYEAR.AUTHOR_ENVD + rec.AUTHOR_ENVD;

        execute immediate sSQL using 'Выплаты_'||trim(rec.MONTHNUMB),
          rec.COMP_INV + rec.COMP_ENVD, iDETAIL_IDX;
        execute immediate sSQL using 'Выплаты_год_'||trim(rec.MONTHNUMB),
          rYEAR.COMP_INV + rYEAR.COMP_ENVD, iDETAIL_IDX;
        execute immediate sSQL using 'Ч7СТ8_'||trim(rec.MONTHNUMB),
          rec.AUTHOR_INV + rec.AUTHOR_ENVD, iDETAIL_IDX;
        execute immediate sSQL using 'Ч7СТ8_год_'||trim(rec.MONTHNUMB),
          rYEAR.AUTHOR_INV + rYEAR.AUTHOR_ENVD, iDETAIL_IDX;
        execute immediate sSQL using 'Ч1СТ9_'||trim(rec.MONTHNUMB),
          rec.DEDUCT_INV + rec.DEDUCT_ENVD, iDETAIL_IDX;
        execute immediate sSQL using 'Ч1СТ9_год_'||trim(rec.MONTHNUMB),
          rYEAR.DEDUCT_INV + rYEAR.DEDUCT_ENVD, iDETAIL_IDX;
        execute immediate sSQL using 'П1Ч3СТ9_'||trim(rec.MONTHNUMB),
          rec.SUD_INV, iDETAIL_IDX;
        execute immediate sSQL using 'П1Ч3СТ9_год_'||trim(rec.MONTHNUMB),
          rYEAR.SUD_INV, iDETAIL_IDX;
        execute immediate sSQL using 'Ч4СТ8_'||trim(rec.MONTHNUMB),
          rec.MAXIMUM_INV + rec.MAXIMUM_ENVD, iDETAIL_IDX;
        execute immediate sSQL using 'Ч4СТ8_год_'||trim(rec.MONTHNUMB),
          rYEAR.MAXIMUM_INV + rYEAR.MAXIMUM_ENVD, iDETAIL_IDX;
        execute immediate sSQL using 'База_ОПС_'||trim(rec.MONTHNUMB),
          rec.COMP_INV - rec.AUTHOR_INV - rec.DEDUCT_INV - rec.SUD_INV +
          rec.COMP_ENVD - rec.AUTHOR_ENVD - rec.DEDUCT_ENVD, iDETAIL_IDX;
        execute immediate sSQL using 'База_ОПС_год_'||trim(rec.MONTHNUMB),
          rYEAR.COMP_INV - rYEAR.AUTHOR_INV - rYEAR.DEDUCT_INV - rYEAR.SUD_INV +
          rYEAR.COMP_ENVD - rYEAR.AUTHOR_ENVD - rYEAR.DEDUCT_ENVD, iDETAIL_IDX;
        execute immediate sSQL using 'База_ОМС_'||trim(rec.MONTHNUMB),
          rec.COMP_INV - rec.AUTHOR_INV - rec.DEDUCT_INV +
          rec.COMP_ENVD - rec.AUTHOR_ENVD - rec.DEDUCT_ENVD, iDETAIL_IDX;
        execute immediate sSQL using 'База_ОМС_год_'||trim(rec.MONTHNUMB),
          rYEAR.COMP_INV - rYEAR.AUTHOR_INV - rYEAR.DEDUCT_INV +
          rYEAR.COMP_ENVD - rYEAR.AUTHOR_ENVD - rYEAR.DEDUCT_ENVD, iDETAIL_IDX;
        execute immediate sSQL using 'Начислено_СПФР_'||trim(rec.MONTHNUMB),
          rec.SPFR_INV + rec.SPFR_ENVD, iDETAIL_IDX;
        execute immediate sSQL using 'Начислено_СПФР_год_'||trim(rec.MONTHNUMB),
          rYEAR.SPFR_INV + rYEAR.SPFR_ENVD, iDETAIL_IDX;
        execute immediate sSQL using 'Начислено_НПФР_'||trim(rec.MONTHNUMB),
          rec.NPFR_INV + rec.NPFR_ENVD, iDETAIL_IDX;
        execute immediate sSQL using 'Начислено_НПФР_год_'||trim(rec.MONTHNUMB),
          rYEAR.NPFR_INV + rYEAR.NPFR_ENVD, iDETAIL_IDX;
        execute immediate sSQL using 'Начислено_ФФОМС_'||trim(rec.MONTHNUMB),
          rec.FFOMS_INV + rec.FFOMS_ENVD, iDETAIL_IDX;
        execute immediate sSQL using 'Начислено_ФФОМС_год_'||trim(rec.MONTHNUMB),
          rYEAR.FFOMS_INV + rYEAR.FFOMS_ENVD, iDETAIL_IDX;
        execute immediate sSQL using 'Начислено_ТФОМС_'||trim(rec.MONTHNUMB),
          rec.TFOMS_INV + rec.TFOMS_ENVD, iDETAIL_IDX;
        execute immediate sSQL using 'Начислено_ТФОМС_год_'||trim(rec.MONTHNUMB),
          rYEAR.TFOMS_INV + rYEAR.TFOMS_ENVD, iDETAIL_IDX;

        /* Данные по ФСС */
        for rec1 in
        (
          select SPFR_INV,
                 SPFR_ENVD,
                 NPFR_INV,
                 NPFR_ENVD,
                 AUTHOR_INV,
                 AUTHOR_ENVD
            from SLCST_RSV1
           where FSS = 1
             and MONTHNUMB = rec.MONTHNUMB
        )
        loop
          /* Накопители с начала года */
          rYEAR_FSS.AUTHOR_INV   := rYEAR_FSS.AUTHOR_INV + rec1.AUTHOR_INV;
          rYEAR_FSS.AUTHOR_ENVD  := rYEAR_FSS.AUTHOR_ENVD + rec1.AUTHOR_ENVD;
          rYEAR_FSS.SPFR_INV     := rYEAR_FSS.SPFR_INV + rec1.SPFR_INV;
          rYEAR_FSS.SPFR_ENVD    := rYEAR_FSS.SPFR_ENVD + rec1.SPFR_ENVD;
          rYEAR_FSS.NPFR_INV     := rYEAR_FSS.NPFR_INV + rec1.NPFR_INV;
          rYEAR_FSS.NPFR_ENVD    := rYEAR_FSS.NPFR_ENVD + rec1.NPFR_ENVD;

          execute immediate sSQL using 'П2Ч3СТ9_'||trim(rec.MONTHNUMB),
            rec1.AUTHOR_INV + rec1.AUTHOR_ENVD, iDETAIL_IDX;
          execute immediate sSQL using 'П2Ч3СТ9_год_'||trim(rec.MONTHNUMB),
            rYEAR_FSS.AUTHOR_INV + rYEAR_FSS.AUTHOR_ENVD, iDETAIL_IDX;
          execute immediate sSQL using 'База_ФСС_'||trim(rec.MONTHNUMB),
            rec.COMP_INV - rec.DEDUCT_INV - rec1.AUTHOR_INV +
            rec.COMP_ENVD - rec.DEDUCT_ENVD - rec1.AUTHOR_ENVD, iDETAIL_IDX;
          execute immediate sSQL using 'База_ФСС_год_'||trim(rec.MONTHNUMB),
            rYEAR.COMP_INV - rYEAR.DEDUCT_INV - rYEAR_FSS.AUTHOR_INV +
            rYEAR.COMP_ENVD - rYEAR.DEDUCT_ENVD - rYEAR_FSS.AUTHOR_ENVD, iDETAIL_IDX;
          execute immediate sSQL using 'Начислено_ФСС_'||trim(rec.MONTHNUMB),
            rec1.SPFR_INV + rec1.SPFR_ENVD, iDETAIL_IDX;
          execute immediate sSQL using 'Начислено_ФСС_год_'||trim(rec.MONTHNUMB),
            rYEAR_FSS.SPFR_INV + rYEAR_FSS.SPFR_ENVD, iDETAIL_IDX;
          execute immediate sSQL using 'Пособия_ФСС_'||trim(rec.MONTHNUMB),
            rec1.NPFR_INV + rec1.NPFR_ENVD, iDETAIL_IDX;
          execute immediate sSQL using 'Пособия_ФСС_год_'||trim(rec.MONTHNUMB),
            rYEAR_FSS.NPFR_INV+ rYEAR_FSS.NPFR_ENVD, iDETAIL_IDX;
        end loop;
      end loop;
    end if;
  end loop;
  PRSG_EXCEL.LINE_DELETE( DETAIL );
end;
/
