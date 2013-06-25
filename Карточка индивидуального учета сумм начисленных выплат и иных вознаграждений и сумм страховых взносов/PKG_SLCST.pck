create or replace package PKG_SLCST
as
 type T_SCALE is record(
          INCOME   number(17,2),
          SUMM     number(17,2),
          PERCENT  number(17,2));
  type t_ASCALE is varray(4) of T_SCALE;
  type T_TAXSUM is record(
          BASESUMM  number(17,2),
          TAXSUMM   number(17,2),
          NUMB      number(17),
          SCALESUMM number(17,2),
          PERCENT   number(17,2),
          DELTA     number(17,2));
  type t_ATAXSUM is varray(4) of T_TAXSUM;
  /* проверка введенных значений */
  procedure GET_ADDRESS
  (
   nAGNRN              in number,
   nLEGAL              in number,                 -- юридический
   nPRIMARY            in number,                 -- основной
   sADR_COUNTRY_CODE   out varchar2,
   sADDR_POST          out varchar2,
   sADDR_REGCODE       out varchar2,
   sADDR_REG_NAME      out varchar2,
   sADDR_DISTRICT_NAME out varchar2,
   sADDR_DISTRICT_TYPE out varchar2,
   sADDR_CITY_NAME     out varchar2,
   sADDR_CITY_TYPE     out varchar2,
   sADDR_TOWNE_NAME    out varchar2,
   sADDR_TOWNE_TYPE    out varchar2,
   sADDR_STREET_NAME   out varchar2,
   sADDR_STREET_TYPE   out varchar2,
   sADDR_HOUSE         out varchar2,
   sADDR_BLOCK         out varchar2,
   sADDR_FLAT          out varchar2
  );

  /* процедура расчета ЕСН */
  procedure  CALC_CREATE
  (
   nCOMPANY      in number,
   nDEPARTMENT   in varchar2,                  -- подразделение
   nYEAR         in number,
   dPERIODBEGIN  in date,
   dPERIODEND    in date,
   nCHILDDEP     in number,                    -- признак учитывать все подчиненные подразделения
   nNEGOTIVE     in number,                    -- отриц налог. база
   nDEVIDE       in number,                    -- делить сумму налога по льготе на 2
   nPAY_FSS1     in number,                    -- возмещено ФСС за 1 месяц последнего квартала
   nPAY_FSS2     in number,                    -- взмещено ФСС за 1 месяц последнего квартала
   nPAY_FSS3     in number,                    -- возмещено ФСС за 1 месяц последнего квартала
   nPAY_FSS      in number,                    -- возмещено ФСС за налоговый период
   n2005         in number default 0,          -- признак печати отчетности за 2005г
   nCLNPSPFMFGRP in number default null,       -- группа исполнений
   nDIFENVD      in number default 0           -- Сбор отчислений в части облагаемых по ЕНВД
  );

  /* Расчет по шкалам налогообложения */
  procedure SCALE_CREATE
  (
   nCOMPANY        in number,
   nDEPARTMENT     in varchar2,                  -- подразделение
   nYEAR           in number,
   dPERIODBEGIN    in date,
   dPERIODEND      in date,
   nCHILDDEP       in number,                    -- признак учитывать все подчиненные подразделения
   nNEGOTIVE       in number,                    -- отриц налог. база
   nTAXSCALE_PFR   in number,                    -- налоговая шкала для ПФР
   nTAXSCALE_FSS   in number,
   nTAXSCALE_FFOMS in number,
   nTAXSCALE_TFOMS in number,
   n2005           in number default 0,          -- признак печати отчетности за 2005г
   nCLNPSPFMFGRP   in number default null        -- группа исполнений
  );
  /* Формирование таблицы инвалидов */
   procedure INVALID_CREATE
  (
   nCOMPANY        in number,
   nDEPARTMENT     in varchar2,                -- подразделение
   nYEAR           in number,
   dPERIODBEGIN    in date,
   dPERIODEND      in date,
   nCHILDDEP       in number,                  -- подчиненные подразделения
   nNEGOTIVE       in number,
   nCLNPSPFMFGRP   in number default null      -- группа исполнений
  );

  /* Расчет права на применение регрессивной шкалы */
  procedure REGRESS_CREATE
  (
   nCOMPANY       in number,
   nDEPARTMENT    in varchar2,                  -- подразделение
   nYEAR          in number,
   dPERIODBEGIN   in date,
   dPERIODEND     in date,
   nCHILDDEP      in number,                    -- признак учитывать все подчиненные подразделения
   nNEGOTIVE      in number,                    -- отриц налог. база
   nSTATESNOTFULL in number,                    -- состояние ИД, указывающее на работу неполный рабочий день
   sSTATESVAK     in varchar2,
   nMAXPROP       in varchar2,                  -- свойство сотрудника, определяющее, что он относится к категории наиболее высокооплачиваемых
   sMAXVALUE      in varchar2,                  -- значение свойства
   nUSEENVD       in number default 0,          -- признак применения ЕНВД
   nAVG1          in number default 0,          -- средняя численность за 1 месяц последнего квартала
   nAVG2          in number default 0,          -- средняя численность за 2 месяц последнего квартала
   nAVG3          in number default 0           -- средняя численность за 3 месяц последнего квартала
  );

  /* Формирование данных расчета налоговой декларации (авансовых платежей) по обязательному пенсионному страхованию */
  procedure CALCDUTYPFR_CREATE
  (
   nCOMPANY      in number,
   nDEPARTMENT   in varchar2,                  -- подразделение
   nYEAR         in number,
   dPERIODBEGIN  in date,
   dPERIODEND    in date,
   nCHILDDEP     in number,                    -- признак учитывать все подчиненные подразделения
   nNEGOTIVE     in number,                    -- отриц налог. база
   nUSEENVD      in number,                    -- признак применения ЕНВД
   nPER_DUTY     in number,
   nPER_DUTY1    in number,
   nPER_DUTY2    in number,
   nPER_DUTY3    in number,
   nPER_CUMUL    in number,
   nPER_CUMUL1   in number,
   nPER_CUMUL2   in number,
   nPER_CUMUL3   in number,
   nPER_NOTENVD  in number,
   nPER_NOTENVD1 in number,
   nPER_NOTENVD2 in number,
   nPER_NOTENVD3 in number,
   n2005         in number default 0,           -- признак печати отчетности за 2005г
   nCLNPSPFMFGRP in number default null,        -- группа исполнений
   nDIFENVD      in number default 0            -- Сбор отчислений в части облагаемых по ЕНВД
  );

  /* Расчет по шкалам налогообложения */
  procedure SCALEDUTYPFR_CREATE
  (
   nCOMPANY        in number,
   nDEPARTMENT     in varchar2,                  -- подразделение
   nYEAR           in number,
   dPERIODBEGIN    in date,
   dPERIODEND      in date,
   nCHILDDEP       in number,                    -- признак учитывать все подчиненные подразделения
   nNEGOTIVE       in number,                    -- отриц налог. база
   nSCALE_DUTY     in number,                    -- правило выбора налоговой шкалы для страховой части ПФР
   nSCALE_CUMUL    in number,                    -- правило выбора налоговой шкалы для накопительной части ПФР
   nUSEENVD        in number,                    -- применяется ЕНВД
   n2005           in number default 0,          -- признак печати отчетности за 2005г
   nCLNPSPFMFGRP   in number default null        -- группа исполнений
  );
  /* Корректировка округленных данных */
  procedure DELTA
  (
   nVALUE         in number,
   nVALUE1        in out number,
   nVALUE2        in out number,
   nVALUE3        in out number
  );
  /* Получение данных из доп свойств сотрудников */
  procedure GET_PARM
  (
   sWORD1     in varchar2,
   sWORD2     in varchar2,
   nCLNPER    in number,
   nPARSM_RN  out number
  );
  procedure GET_SCALE
  (
   aSCALE          in out t_ASCALE,
   dDATE           in date,
   nTAXSCALE       in number                    -- налоговая шкала для ПФР
  );
  procedure GET_TAXSUMM
  (
   aSCALE     in out t_ASCALE,
   aTAX       in out t_ATAXSUM,
   aTAXITO    in out t_ATAXSUM,
   nTAXBASE   in number,
   nTAX       in number,
   nDELTA     in number,
   nSCALE     in number default 0
  );

  /* процедура расчета ПФР */
  procedure CALC_PFR
  (
   nAGENT               in number,             -- КАФЛ
   nPERSRN              in number,             -- Сотрудник
   nCLNPERSTAXACC       in number,             -- Налоговая карточка
   nYEAR                in number,
   nMONTHBEGIN          in number,
   nMONTHEND            in number,
   nINVAL3              in number,             -- Формировать данные по инвалидам раздел 3
   nENVD3               in number,             -- Формировать данные по ЕНВД раздел 3
   nMAXINCOME           in number,             -- Максимальная облагаемая база
   n4FSS                   in number default 0    -- Расчет для 4-ФСС
  );

  /* Параметры КАЮЛ */
  procedure GET_AGENT_PARAM
  (
   nCOMPANY             in number,
   nAGENT               in number,             -- КАЮЛ
   dPERIODEND           in date,               -- На дату
   sREGNUMB             out varchar2,          -- Регистрационный номер в ПФР
   sOKVED               out varchar2,          -- ОКВЭД (ОКОНХ)
   sOKATO               out varchar2,          -- ОКАТО
   sREASON_CODE         out varchar2           -- КПП
  );

  /* Печать цифровой ячейки для ПФР */
  procedure CELL_NUMBVALUE_WRITE
  (
   sCELL      in varchar2,                     -- ячейка
   nNUMB      in number,                       -- сумма
   nDIG       in number default 2,             -- десятичных знаков
   nIDX       in number default null           -- строка
  );

  /* Поиск шкалы налогооблажения */
  procedure FIND_SALTAXSCALE
  (
   nCOMPANY   in number,
   nRULE      in number,                       -- шкала
   nYEAR      in number,                       -- год рождения
   dPERIODEND in date,                         -- Период По
   nRN        out number                       -- шкала налогооблажения
  );
end PKG_SLCST;
/
create or replace package body PKG_SLCST
as
  /* Корректировка округленных данных по шкалам */
  procedure DELTA_SCALE
  (
   aTAX         in out t_ATAXSUM
  )
  as
   nDELTA       number(17);
  begin
   nDELTA := round(aTAX(1).BASESUMM + aTAX(2).BASESUMM + aTAX(3).BASESUMM, 0) -
            (round(aTAX(1).BASESUMM,0) + round(aTAX(2).BASESUMM,0) + round(aTAX(3).BASESUMM,0));
   /* Для распределения можно использовать только шкалу №3 (свыше 600000) или шкалу №1 (до 280000) */
   if nDELTA <> 0 then
      if aTAX(3).BASESUMM <> 0 then
         aTAX(3).BASESUMM := aTAX(3).BASESUMM + nDELTA;
      elsif aTAX(1).BASESUMM <> 0 then
         aTAX(1).BASESUMM := aTAX(1).BASESUMM + nDELTA;
      end if;
   end if;

   nDELTA := round(aTAX(1).TAXSUMM + aTAX(2).TAXSUMM + aTAX(3).TAXSUMM, 0) -
            (round(aTAX(1).TAXSUMM,0) + round(aTAX(2).TAXSUMM,0) + round(aTAX(3).TAXSUMM,0));
   /* Для распределения можно использовать только шкалу №3 (свыше 600000) или шкалу №1 (до 280000) */
   if nDELTA <> 0 then
      if aTAX(3).TAXSUMM <> 0 then
         aTAX(3).TAXSUMM := aTAX(3).TAXSUMM + nDELTA;
      elsif aTAX(1).BASESUMM <> 0 then
         aTAX(1).TAXSUMM := aTAX(1).TAXSUMM + nDELTA;
      end if;
   end if;
  end DELTA_SCALE;

  procedure GET_ADDRESS
  (
   nAGNRN              in number,
   nLEGAL              in number,                 -- юридический
   nPRIMARY            in number,                 -- основной
   sADR_COUNTRY_CODE   out varchar2,
   sADDR_POST          out varchar2,
   sADDR_REGCODE       out varchar2,
   sADDR_REG_NAME      out varchar2,
   sADDR_DISTRICT_NAME out varchar2,
   sADDR_DISTRICT_TYPE out varchar2,
   sADDR_CITY_NAME     out varchar2,
   sADDR_CITY_TYPE     out varchar2,
   sADDR_TOWNE_NAME    out varchar2,
   sADDR_TOWNE_TYPE    out varchar2,
   sADDR_STREET_NAME   out varchar2,
   sADDR_STREET_TYPE   out varchar2,
   sADDR_HOUSE         out varchar2,
   sADDR_BLOCK         out varchar2,
   sADDR_FLAT          out varchar2
  )
  as
   nGEOGR                AGNADDRESSES.RN%TYPE;
   nCOUNTRY              AGNADDRESSES.GEOGRAFY_RN%TYPE;
   nREGION               AGNADDRESSES.GEOGRAFY_RN%TYPE;
   nDISTRICT             AGNADDRESSES.GEOGRAFY_RN%TYPE;
   nTOWNE                AGNADDRESSES.GEOGRAFY_RN%TYPE;
   nSTREET               AGNADDRESSES.GEOGRAFY_RN%TYPE;
   nCITY                 AGNADDRESSES.GEOGRAFY_RN%TYPE;
  begin
   sADR_COUNTRY_CODE   :='';
   sADDR_POST          :='';
   sADDR_REGCODE       :='';
   sADDR_REG_NAME      :='';
   sADDR_DISTRICT_NAME :='';
   sADDR_DISTRICT_TYPE :='';
   sADDR_CITY_NAME     :='';
   sADDR_CITY_TYPE     :='';
   sADDR_TOWNE_NAME    :='';
   sADDR_TOWNE_TYPE    :='';
   sADDR_STREET_NAME   :='';
   sADDR_STREET_TYPE   :='';
   sADDR_HOUSE         :='';
   sADDR_BLOCK         :='';
   sADDR_FLAT          :='';
   for rec1 in
   (
    select A.GEOGRAFY_RN,
           A.ADDR_POST,
           A.ADDR_HOUSE,
           A.ADDR_BLOCK,
           A.ADDR_FLAT
      from AGNADDRESSES A
      where PRN = nAGNRN
      and ((nLEGAL is not null and LEGAL_SIGN = nLEGAL) or (nPRIMARY is not null and PRIMARY_SIGN = nPRIMARY))
      and rownum<2
    )
    loop
      nGEOGR       := rec1.GEOGRAFY_RN;
      sADDR_POST   := rec1.ADDR_POST;
      sADDR_HOUSE  := rec1.ADDR_HOUSE;
      sADDR_BLOCK  := rec1.ADDR_BLOCK;
      sADDR_FLAT   := rec1.ADDR_FLAT;
      for rec2 in
      (
        select
         RN,
         to_number(GEOGRTYPE) GTYPE
        from GEOGRAFY
         start with RN = nGEOGR
         connect by prior PRN = RN
      )
      loop
        if rec2.GTYPE = 2 then
          -- регион
          nREGION := rec2.RN;
        elsif rec2.GTYPE = 1 then
          -- страна
          nCOUNTRY := rec2.RN;
        elsif rec2.GTYPE = 3 then
          -- район
          nDISTRICT := rec2.RN;
        elsif rec2.GTYPE = 4 then
          -- населенный пункт
          nTOWNE := rec2.RN;
        elsif rec2.GTYPE = 5 then
          -- улица
          nSTREET := rec2.RN;
               elsif rec2.GTYPE = 8 then
          -- город
          nCITY := rec2.RN;
        end if;
      end loop;
      if nCOUNTRY is not null then
         select GF.CODE into sADR_COUNTRY_CODE
           from GEOGRAFY GF
           where GF.RN = nCOUNTRY;
      end if;
      if nREGION is not null then
         select GF.CODE into sADDR_REGCODE
           from GEOGRAFY GF
           where GF.RN = nREGION;
         select GF.GEOGRNAME into sADDR_REG_NAME
           from GEOGRAFY GF
           where GF.RN = nREGION;
      end if;
      if nDISTRICT is not null then
         select GF.GEOGRNAME into sADDR_DISTRICT_NAME
           from GEOGRAFY GF
           where GF.RN = nDISTRICT;
         select LT.NAME into sADDR_DISTRICT_TYPE
           from GEOGRAFY GF,
                LOCALITYTYPE LT
           where GF.LOCALITYKIND = LT.RN (+)
             and GF.RN = nDISTRICT;
      end if;
      if nTOWNE is not null then
         select GF.GEOGRNAME into sADDR_TOWNE_NAME
           from GEOGRAFY GF
           where GF.RN = nTOWNE;
         select LT.NAME into sADDR_TOWNE_TYPE
           from GEOGRAFY GF,
               LOCALITYTYPE LT
           where GF.LOCALITYKIND = LT.RN (+)
             and GF.RN = nTOWNE;
      end if;
      if nSTREET is not null then
         select GF.GEOGRNAME into sADDR_STREET_NAME
           from GEOGRAFY GF
           where GF.RN = nSTREET;
         select LT.NAME into sADDR_STREET_TYPE
           from GEOGRAFY GF,
                LOCALITYTYPE LT
           where GF.LOCALITYKIND = LT.RN (+)
             and GF.RN = nSTREET;
       end if;
       if nCITY is not null then
         select GF.GEOGRNAME into sADDR_CITY_NAME
           from GEOGRAFY GF
           where GF.RN = nCITY;
         select LT.NAME into sADDR_CITY_TYPE
           from GEOGRAFY GF,
                LOCALITYTYPE LT
           where GF.LOCALITYKIND = LT.RN (+)
             and GF.RN = nCITY;
       end if;
    end loop;
   end GET_ADDRESS;

   procedure  CALC_CREATE
   (
    nCOMPANY      in number,
    nDEPARTMENT   in varchar2,                  -- подразделение
    nYEAR         in number,
    dPERIODBEGIN  in date,
    dPERIODEND    in date,
    nCHILDDEP     in number,                    -- признак учитывать все подчиненные подразделения
    nNEGOTIVE     in number,                    -- отриц налог. база
    nDEVIDE       in number,                    -- делить сумму налога по льготе на 2
    nPAY_FSS1     in number,                    -- возмещено ФСС за 1 месяц последнего квартала
    nPAY_FSS2     in number,                    -- взмещено ФСС за 1 месяц последнего квартала
    nPAY_FSS3     in number,                    -- возмещено ФСС за 1 месяц последнего квартала
    nPAY_FSS      in number,                    -- возмещено ФСС за налоговый период
    n2005         in number default 0,          -- признак печати отчетности за 2005г
    nCLNPSPFMFGRP in number default null,       -- группа исполнений
    nDIFENVD      in number default 0           -- Сбор отчислений в части облагаемых по ЕНВД
   )
   as
    nBASE_PFR            SLCST_CALC.BASE_PFR%TYPE;                      -- налоговая база ПФР всего, и за три последних месяца
    nBASE_PFR1           SLCST_CALC.BASE_PFR1%TYPE;
    nBASE_PFR2           SLCST_CALC.BASE_PFR2%TYPE;
    nBASE_PFR3           SLCST_CALC.BASE_PFR3%TYPE;
    nBASE_FSS            SLCST_CALC.BASE_FSS%TYPE;                      -- налоговая база ФСС всего, и за три последних месяца
    nBASE_FSS1           SLCST_CALC.BASE_FSS1%TYPE;
    nBASE_FSS2           SLCST_CALC.BASE_FSS2%TYPE;
    nBASE_FSS3           SLCST_CALC.BASE_FSS3%TYPE;
    nBASE_FFOMS          SLCST_CALC.BASE_FFOMS%TYPE;                    -- налоговая база ФФОМСС всего, и за три последних месяца
    nBASE_FFOMS1         SLCST_CALC.BASE_FFOMS1%TYPE;
    nBASE_FFOMS2         SLCST_CALC.BASE_FFOMS2%TYPE;
    nBASE_FFOMS3         SLCST_CALC.BASE_FFOMS3%TYPE;
    nBASE_TFOMS          SLCST_CALC.BASE_TFOMS%TYPE;                    -- налоговая база TФОМСС всего, и за три последних месяца
    nBASE_TFOMS1         SLCST_CALC.BASE_TFOMS1%TYPE;
    nBASE_TFOMS2         SLCST_CALC.BASE_TFOMS2%TYPE;
    nBASE_TFOMS3         SLCST_CALC.BASE_TFOMS3%TYPE;
    nDEDUCT_PFR          SLCST_CALC.DEDUCT_PFR%TYPE;                    -- умма налоговых льгот по ПФР всего, и за три последних месяца
    nDEDUCT_PFR1         SLCST_CALC.DEDUCT_PFR1%TYPE;
    nDEDUCT_PFR2         SLCST_CALC.DEDUCT_PFR2%TYPE;
    nDEDUCT_PFR3         SLCST_CALC.DEDUCT_PFR3%TYPE;
    nDEDUCT_FSS          SLCST_CALC.DEDUCT_FSS%TYPE;                    -- сумма налоговых льгот по ФСС всего, и за три последних месяца
    nDEDUCT_FSS1         SLCST_CALC.DEDUCT_FSS1%TYPE;
    nDEDUCT_FSS2         SLCST_CALC.DEDUCT_FSS2%TYPE;
    nDEDUCT_FSS3         SLCST_CALC.DEDUCT_FSS3%TYPE;
    nDEDUCT_FFOMS        SLCST_CALC.DEDUCT_FFOMS%TYPE;                  -- сумма налоговых льгот по ФФОМС всего, и за три последних месяца
    nDEDUCT_FFOMS1       SLCST_CALC.DEDUCT_FFOMS1%TYPE;
    nDEDUCT_FFOMS2       SLCST_CALC.DEDUCT_FFOMS2%TYPE;
    nDEDUCT_FFOMS3       SLCST_CALC.DEDUCT_FFOMS3%TYPE;
    nDEDUCT_TFOMS        SLCST_CALC.DEDUCT_TFOMS%TYPE;                  -- сумма налоговых льгот по TФОМС всего, и за три последних месяца
    nDEDUCT_TFOMS1       SLCST_CALC.DEDUCT_TFOMS1%TYPE;
    nDEDUCT_TFOMS2       SLCST_CALC.DEDUCT_TFOMS2%TYPE;
    nDEDUCT_TFOMS3       SLCST_CALC.DEDUCT_TFOMS3%TYPE;
    nTAX_PFR             SLCST_CALC.TAX_PFR%TYPE;                       -- налог в ПФР
    nTAX_PFR1            SLCST_CALC.TAX_PFR1%TYPE;
    nTAX_PFR2            SLCST_CALC.TAX_PFR2%TYPE;
    nTAX_PFR3            SLCST_CALC.TAX_PFR3%TYPE;
    nTAX_FSS             SLCST_CALC.TAX_FSS%TYPE;                       -- налог в ФСС
    nTAX_FSS1            SLCST_CALC.TAX_FSS1%TYPE;
    nTAX_FSS2            SLCST_CALC.TAX_FSS2%TYPE;
    nTAX_FSS3            SLCST_CALC.TAX_FSS3%TYPE;
    nTAX_FFOMS           SLCST_CALC.TAX_FFOMS%TYPE;                     -- налог в ФФОМС
    nTAX_FFOMS1          SLCST_CALC.TAX_FFOMS1%TYPE;
    nTAX_FFOMS2          SLCST_CALC.TAX_FFOMS2%TYPE;
    nTAX_FFOMS3          SLCST_CALC.TAX_FFOMS3%TYPE;
    nTAX_TFOMS           SLCST_CALC.TAX_TFOMS%TYPE;                     -- налог в ТФОМС
    nTAX_TFOMS1          SLCST_CALC.TAX_TFOMS1%TYPE;
    nTAX_TFOMS2          SLCST_CALC.TAX_TFOMS2%TYPE;
    nTAX_TFOMS3          SLCST_CALC.TAX_TFOMS3%TYPE;
    nTAX_PFRDUTY         SLCST_CALC.TAX_PFRDUTY%TYPE;                   -- налог в ПФР на обязательное страхование
    nTAX_PFRDUTY1        SLCST_CALC.TAX_PFRDUTY1%TYPE;
    nTAX_PFRDUTY2        SLCST_CALC.TAX_PFRDUTY2%TYPE;
    nTAX_PFRDUTY3        SLCST_CALC.TAX_PFRDUTY3%TYPE;
    nTAX_DEDUCT_PFR      SLCST_CALC.TAX_DEDUCT_PFR%TYPE;                -- налог по льготе в ПФР
    nTAX_DEDUCT_PFR1     SLCST_CALC.TAX_DEDUCT_PFR1%TYPE;
    nTAX_DEDUCT_PFR2     SLCST_CALC.TAX_DEDUCT_PFR2%TYPE;
    nTAX_DEDUCT_PFR3     SLCST_CALC.TAX_DEDUCT_PFR3%TYPE;
    nTAX_DEDUCT_FSS      SLCST_CALC.TAX_DEDUCT_FSS%TYPE;                -- налог по льготе в ФСС
    nTAX_DEDUCT_FSS1     SLCST_CALC.TAX_DEDUCT_FSS1%TYPE;
    nTAX_DEDUCT_FSS2     SLCST_CALC.TAX_DEDUCT_FSS2%TYPE;
    nTAX_DEDUCT_FSS3     SLCST_CALC.TAX_DEDUCT_FSS3%TYPE;
    nTAX_DEDUCT_FFOMS    SLCST_CALC.TAX_DEDUCT_FFOMS%TYPE;              -- налог по льготе в ФФОМС
    nTAX_DEDUCT_FFOMS1   SLCST_CALC.TAX_DEDUCT_FFOMS1%TYPE;
    nTAX_DEDUCT_FFOMS2   SLCST_CALC.TAX_DEDUCT_FFOMS2%TYPE;
    nTAX_DEDUCT_FFOMS3   SLCST_CALC.TAX_DEDUCT_FFOMS3%TYPE;
    nTAX_DEDUCT_TFOMS    SLCST_CALC.TAX_DEDUCT_TFOMS%TYPE;              --  налог по льготе в ТФОМС
    nTAX_DEDUCT_TFOMS1   SLCST_CALC.TAX_DEDUCT_TFOMS1%TYPE;
    nTAX_DEDUCT_TFOMS2   SLCST_CALC.TAX_DEDUCT_TFOMS2%TYPE;
    nTAX_DEDUCT_TFOMS3   SLCST_CALC.TAX_DEDUCT_TFOMS3%TYPE;
    nRAS_FSS             SLCST_CALC.RAS_FSS%TYPE;                       -- расходы  ФСС
    nRAS_FSS1            SLCST_CALC.RAS_FSS2%TYPE;
    nRAS_FSS2            SLCST_CALC.RAS_FSS3%TYPE;
    nRAS_FSS3            SLCST_CALC.RAS_FSS3%TYPE;
    nPER_FSS             SLCST_CALC.RAS_FSS%TYPE;                       -- возмещено  ФСС
    nPER_FSS1            SLCST_CALC.RAS_FSS2%TYPE;
    nPER_FSS2            SLCST_CALC.RAS_FSS3%TYPE;
    nPER_FSS3            SLCST_CALC.RAS_FSS3%TYPE;
    nINF1000_PFR         SLCST_CALC.INF1000_PFR%TYPE;                   -- справочно строка 1000
    nINF1000_FSS         SLCST_CALC.INF1000_FSS%TYPE;
    nINF1000_FFOMS       SLCST_CALC.INF1000_FFOMS%TYPE;
    nINF1000_TFOMS       SLCST_CALC.INF1000_TFOMS%TYPE;
    nINF1100_PFR         SLCST_CALC.INF1100_PFR%TYPE;                   -- справочно строка 1100
    nINF1100_FSS         SLCST_CALC.INF1100_FSS%TYPE;
    nINF1100_FFOMS       SLCST_CALC.INF1100_FFOMS%TYPE;
    nINF1100_TFOMS       SLCST_CALC.INF1100_TFOMS%TYPE;
    nINF1200_PFR         SLCST_CALC.INF1200_PFR%TYPE;                   -- справочно строка 1200
    nINF1200_FSS         SLCST_CALC.INF1200_FSS%TYPE;
    nINF1200_FFOMS       SLCST_CALC.INF1200_FFOMS%TYPE;
    nINF1200_TFOMS       SLCST_CALC.INF1200_TFOMS%TYPE;
    nINF1300_PFR         SLCST_CALC.INF1300_PFR%TYPE;
    nTAX_PFRDUTYNOTENDV  SLCST_CALC.TAX_PFRDUTY%TYPE;                   -- налог в ПФР на обязательное страхование по не ЕНВД
    nTAX_PFRDUTYNOTENDV1 SLCST_CALC.TAX_PFRDUTY1%TYPE;
    nTAX_PFRDUTYNOTENDV2 SLCST_CALC.TAX_PFRDUTY2%TYPE;
    nTAX_PFRDUTYNOTENDV3 SLCST_CALC.TAX_PFRDUTY3%TYPE;
    nTMPVALUE            number (17,2);
    nMONTH1  number;
    nMONTH2  number;
    nMONTH3  number;
    nMAXVAL  number;
    nMONTHBEGIN          number;
    nMONTHEND            number;
    nDEVISOR             number;
    /* получение сумм */
    procedure GET_SUMM
    (
     nPERSRN              in number,
     nCLNPERSTAXACC       in number,
     nYEAR                in number,
     nMONTHBEGIN          in number,
     nMONTHEND            in number,
     nNEGOTIVE            in number
    )
   as
    nBASE_PFR_            SLCST_CALC.BASE_PFR%TYPE;
    nBASE_PFR1_           SLCST_CALC.BASE_PFR1%TYPE;
    nBASE_PFR2_           SLCST_CALC.BASE_PFR2%TYPE;
    nBASE_PFR3_           SLCST_CALC.BASE_PFR3%TYPE;
    nBASE_FSS_            SLCST_CALC.BASE_FSS%TYPE;                      -- налоговая база ФСС всего, и за три последних месяца
    nBASE_FSS1_           SLCST_CALC.BASE_FSS1%TYPE;
    nBASE_FSS2_           SLCST_CALC.BASE_FSS2%TYPE;
    nBASE_FSS3_           SLCST_CALC.BASE_FSS3%TYPE;
    nBASE_FFOMS_          SLCST_CALC.BASE_FFOMS%TYPE;                    -- налоговая база ФФОМСС всего, и за три последних месяца
    nBASE_FFOMS1_         SLCST_CALC.BASE_FFOMS1%TYPE;
    nBASE_FFOMS2_         SLCST_CALC.BASE_FFOMS2%TYPE;
    nBASE_FFOMS3_         SLCST_CALC.BASE_FFOMS3%TYPE;
    nBASE_TFOMS_          SLCST_CALC.BASE_TFOMS%TYPE;                    -- налоговая база TФОМСС всего, и за три последних месяца
    nBASE_TFOMS1_         SLCST_CALC.BASE_TFOMS1%TYPE;
    nBASE_TFOMS2_         SLCST_CALC.BASE_TFOMS2%TYPE;
    nBASE_TFOMS3_         SLCST_CALC.BASE_TFOMS3%TYPE;

    nDEDUCT_PFR_          SLCST_CALC.DEDUCT_PFR%TYPE;
    nDEDUCT_PFR1_         SLCST_CALC.DEDUCT_PFR1%TYPE;
    nDEDUCT_PFR2_         SLCST_CALC.DEDUCT_PFR2%TYPE;
    nDEDUCT_PFR3_         SLCST_CALC.DEDUCT_PFR3%TYPE;

    nDEDUCT_FSS_          SLCST_CALC.DEDUCT_FSS%TYPE;
    nDEDUCT_FSS1_         SLCST_CALC.DEDUCT_FSS1%TYPE;
    nDEDUCT_FSS2_         SLCST_CALC.DEDUCT_FSS2%TYPE;
    nDEDUCT_FSS3_         SLCST_CALC.DEDUCT_FSS3%TYPE;

    nDEDUCT_FFOMS_        SLCST_CALC.DEDUCT_FFOMS%TYPE;
    nDEDUCT_FFOMS1_       SLCST_CALC.DEDUCT_FFOMS1%TYPE;
    nDEDUCT_FFOMS2_       SLCST_CALC.DEDUCT_FFOMS2%TYPE;
    nDEDUCT_FFOMS3_       SLCST_CALC.DEDUCT_FFOMS3%TYPE;

    nDEDUCT_TFOMS_        SLCST_CALC.DEDUCT_TFOMS%TYPE;
    nDEDUCT_TFOMS1_       SLCST_CALC.DEDUCT_TFOMS1%TYPE;
    nDEDUCT_TFOMS2_       SLCST_CALC.DEDUCT_TFOMS2%TYPE;
    nDEDUCT_TFOMS3_       SLCST_CALC.DEDUCT_TFOMS3%TYPE;
    nCOUNT                number;
    dEND                  date;
   begin
    nTMPVALUE       :=0;
    nBASE_PFR_      :=0;
    nBASE_PFR1_     :=0;
    nBASE_PFR2_     :=0;
    nBASE_PFR3_     :=0;
    nBASE_FSS_      :=0;
    nBASE_FSS1_     :=0;
    nBASE_FSS2_     :=0;
    nBASE_FSS3_     :=0;
    nBASE_FFOMS_    :=0;
    nBASE_FFOMS1_   :=0;
    nBASE_FFOMS2_   :=0;
    nBASE_FFOMS3_   :=0;
    nBASE_TFOMS_    :=0;
    nBASE_TFOMS1_   :=0;
    nBASE_TFOMS2_   :=0;
    nBASE_TFOMS3_   :=0;
    nDEDUCT_PFR_    :=0;
    nDEDUCT_PFR1_   :=0;
    nDEDUCT_PFR2_   :=0;
    nDEDUCT_PFR3_   :=0;
    nDEDUCT_FSS_    :=0;
    nDEDUCT_FSS1_   :=0;
    nDEDUCT_FSS2_   :=0;
    nDEDUCT_FSS3_   :=0;
    nDEDUCT_FFOMS_  :=0;
    nDEDUCT_FFOMS1_ :=0;
    nDEDUCT_FFOMS2_ :=0;
    nDEDUCT_FFOMS3_ :=0;
    nDEDUCT_TFOMS_  :=0;
    nDEDUCT_TFOMS1_ :=0;
    nDEDUCT_TFOMS2_ :=0;
    nDEDUCT_TFOMS3_ :=0;
    dEND := add_months(INT2DATE(1,nMONTHEND,nYEAR),1)-1;
    select count(*)
    into nCOUNT
    from DUAL
    where exists
      (
      select A.CODE
      from
        CLNPERSADDINF I,
        SLANLSIGNS    A
      where I.PRN         = nPERSRN
        and I.BEGIN_DATE <= dEND
        and (I.END_DATE is null or I.END_DATE >= dEND)
        and I.SLANLSIGNS  = A.RN
        and trim(A.CODE) = 'ИНОСТРАНЕЦ'
      );
    for cTAXPAYS in
    (
    select TC.PRN,
           TP.SLTAXACCS,
           TP.SUMME,
           TP.DISCOUNTSUMM,
           TP.MONTHNUMB,
           TR.TAXBASE,
           TR.STATE,
           TR.POS_CODE,
           TR.PRIVIL,
           TR1.DDCODE,
           TR.TA_TYPE
     from CLNPERSTAXACCSP TP,
          CLNPERSTAXACC   TC,
          SLTAXACCS TR,
          SALINDEDUCT TR1
     where TC.RN = TP.PRN
       and TP.SLTAXACCS = TR.RN
       and TR.DEDCODE = TR1.RN (+)
       and TC.RN = nCLNPERSTAXACC
       and TP.MONTHNUMB>=nMONTHBEGIN
       and TP.MONTHNUMB<=nMONTHEND
    )
    loop
       nTMPVALUE :=0;
       if cTAXPAYS.TAXBASE = 4 and cTAXPAYS.STATE =0 then            -- доход ПФР
          if trim(cTAXPAYS.POS_CODE) = '7' then
             nTMPVALUE := cTAXPAYS.SUMME;
             nINF1000_PFR := nINF1000_PFR + cTAXPAYS.SUMME;
          end if;
          if trim(cTAXPAYS.DDCODE) = '1' then
             nTMPVALUE := cTAXPAYS.DISCOUNTSUMM;
             nINF1100_PFR := nINF1100_PFR + cTAXPAYS.DISCOUNTSUMM;
          end if;
          if trim(cTAXPAYS.DDCODE) = '2' then
             nTMPVALUE := cTAXPAYS.DISCOUNTSUMM;
             nINF1100_PFR := nINF1100_PFR + cTAXPAYS.DISCOUNTSUMM;
          end if;
          if trim(cTAXPAYS.DDCODE) = '3' then
             nTMPVALUE := cTAXPAYS.DISCOUNTSUMM;
             nINF1100_PFR := nINF1100_PFR + cTAXPAYS.DISCOUNTSUMM;
          end if;
          if trim(cTAXPAYS.POS_CODE) = '1' and trim(cTAXPAYS.DDCODE) = '4' then
             nTMPVALUE := cTAXPAYS.DISCOUNTSUMM;
             nINF1100_PFR := nINF1100_PFR + cTAXPAYS.DISCOUNTSUMM;
          end if;
          if trim(cTAXPAYS.POS_CODE) = '2' then
             nTMPVALUE := cTAXPAYS.SUMME;
             nINF1300_PFR := nINF1300_PFR + cTAXPAYS.SUMME;
          end if;
          if trim(cTAXPAYS.POS_CODE) = '6' then
             nTMPVALUE := cTAXPAYS.SUMME;
             nINF1200_PFR := nINF1200_PFR + cTAXPAYS.SUMME;
          end if;
          nBASE_PFR_:= nBASE_PFR_ + cTAXPAYS.SUMME - nTMPVALUE;                 -- налоговая база для ПФР (строка 100)
          if cTAXPAYS.MONTHNUMB <nMONTH1 then                                   -- первый месяц последнего кавартала
             nBASE_PFR1_ := nBASE_PFR1_ + cTAXPAYS.SUMME - nTMPVALUE;
          end if;
          if cTAXPAYS.MONTHNUMB <nMONTH2 then                                   -- второй месяц последнего кавартала
             nBASE_PFR2_ := nBASE_PFR2_ + cTAXPAYS.SUMME - nTMPVALUE;
          end if;
          if cTAXPAYS.MONTHNUMB < nMONTH3 then                                  -- третий месяц последнего кавартала
             nBASE_PFR3_ := nBASE_PFR3_ + cTAXPAYS.SUMME - nTMPVALUE;
          end if;
       elsif cTAXPAYS.TAXBASE = 4 and cTAXPAYS.STATE =1 then                    -- вычет ПФР
             nDEDUCT_PFR_ := nDEDUCT_PFR_ + cTAXPAYS.SUMME;                     -- льгота для ПФР
             if cTAXPAYS.MONTHNUMB <nMONTH1 then
                nDEDUCT_PFR1_ := nDEDUCT_PFR1_ + cTAXPAYS.SUMME;
             end if;
             if cTAXPAYS.MONTHNUMB< nMONTH2 then
                nDEDUCT_PFR2_ := nDEDUCT_PFR2_ + cTAXPAYS.SUMME;
             end if;
             if cTAXPAYS.MONTHNUMB < nMONTH3 then
                nDEDUCT_PFR3_ := nDEDUCT_PFR3_ + cTAXPAYS.SUMME;
             end if;
       elsif cTAXPAYS.TAXBASE = 4 and cTAXPAYS.STATE =2 then                 -- налог ПФР
             if not (n2005 = 1 and cTAXPAYS.TA_TYPE = 10 and trim(cTAXPAYS.POS_CODE) = '2') then
                nTAX_PFR := nTAX_PFR + cTAXPAYS.SUMME;
                if cTAXPAYS.MONTHNUMB =nMONTH1 then
                   nTAX_PFR1  := nTAX_PFR1 + cTAXPAYS.SUMME;
                end if;
                if cTAXPAYS.MONTHNUMB = nMONTH2 then
                   nTAX_PFR2  := nTAX_PFR2 + cTAXPAYS.SUMME;
                end if;
                if cTAXPAYS.MONTHNUMB = nMONTH3 then
                   nTAX_PFR3  := nTAX_PFR3 + cTAXPAYS.SUMME;
                end if;
             end if;
             if cTAXPAYS.TA_TYPE = 10 then
                nTAX_DEDUCT_PFR := nTAX_DEDUCT_PFR + cTAXPAYS.SUMME;
                if cTAXPAYS.MONTHNUMB = nMONTH1 then
                   nTAX_DEDUCT_PFR1  := nTAX_DEDUCT_PFR1 + cTAXPAYS.SUMME;
                end if;
                if cTAXPAYS.MONTHNUMB = nMONTH2 then
                   nTAX_DEDUCT_PFR2  := nTAX_DEDUCT_PFR2 + cTAXPAYS.SUMME;
                end if;
                if cTAXPAYS.MONTHNUMB = nMONTH3 then
                   nTAX_DEDUCT_PFR3  := nTAX_DEDUCT_PFR3 + cTAXPAYS.SUMME;
                end if;
             end if;

--      elsif cTAXPAYS.TAXBASE = 4 and cTAXPAYS.STATE =3 then                 -- расход ПФР
       elsif cTAXPAYS.TAXBASE = 5 and cTAXPAYS.STATE =0 then                 -- доход ФФОМС
          if trim(cTAXPAYS.POS_CODE) = '7' then
             nTMPVALUE := cTAXPAYS.SUMME;
             nINF1000_FFOMS := nINF1000_FFOMS + cTAXPAYS.SUMME;
          end if;
          if trim(cTAXPAYS.DDCODE) = '1' then
             nTMPVALUE := cTAXPAYS.DISCOUNTSUMM;
             nINF1100_FFOMS := nINF1100_FFOMS + cTAXPAYS.DISCOUNTSUMM;
          end if;
          if trim(cTAXPAYS.DDCODE) = '2' then
             nTMPVALUE := cTAXPAYS.DISCOUNTSUMM;
             nINF1100_FFOMS := nINF1100_FFOMS + cTAXPAYS.DISCOUNTSUMM;
          end if;
          if trim(cTAXPAYS.DDCODE) = '3' then
             nTMPVALUE := cTAXPAYS.DISCOUNTSUMM;
             nINF1100_FFOMS := nINF1100_FFOMS + cTAXPAYS.DISCOUNTSUMM;
          end if;
          if trim(cTAXPAYS.POS_CODE) = '1' and trim(cTAXPAYS.DDCODE) = '4' then
             nTMPVALUE := cTAXPAYS.DISCOUNTSUMM;
             nINF1100_FFOMS := nINF1100_FFOMS + cTAXPAYS.DISCOUNTSUMM;
          end if;
          if trim(cTAXPAYS.POS_CODE) = '6' then
             nTMPVALUE := cTAXPAYS.SUMME;
             nINF1200_FFOMS := nINF1200_FFOMS + cTAXPAYS.SUMME;
          end if;
          if cTAXPAYS.MONTHNUMB <nMONTH1 then                                  -- первый месяц последнего кавартала
             nBASE_FFOMS1_ := nBASE_FFOMS1_ + cTAXPAYS.SUMME - nTMPVALUE;
          end if;
          nBASE_FFOMS_:= nBASE_FFOMS_ + cTAXPAYS.SUMME - nTMPVALUE;          -- налоговая база для ФФОМС (строка 100)
          if cTAXPAYS.MONTHNUMB < nMONTH2 then                             -- второй месяц последнего кавартала
             nBASE_FFOMS2_ := nBASE_FFOMS2_ + cTAXPAYS.SUMME - nTMPVALUE;
          end if;
          if cTAXPAYS.MONTHNUMB < nMONTH3 then                             -- третий месяц последнего кавартала
             nBASE_FFOMS3_ := nBASE_FFOMS3_ + cTAXPAYS.SUMME - nTMPVALUE;
          end if;
       elsif cTAXPAYS.TAXBASE = 5 and cTAXPAYS.STATE =1 then                 -- вычет ФФОМС
             nDEDUCT_FFOMS_ := nDEDUCT_FFOMS_ + cTAXPAYS.SUMME;              -- льгота для ФФОМС
             if cTAXPAYS.MONTHNUMB <nMONTH1 then
                nDEDUCT_FFOMS1_ := nDEDUCT_FFOMS1_ + cTAXPAYS.SUMME;
             end if;
             if cTAXPAYS.MONTHNUMB < nMONTH2 then
                nDEDUCT_FFOMS2_ := nDEDUCT_FFOMS2_ + cTAXPAYS.SUMME;
             end if;
             if cTAXPAYS.MONTHNUMB < nMONTH3 then
                nDEDUCT_FFOMS3_ := nDEDUCT_FFOMS3_ + cTAXPAYS.SUMME;
             end if;
       elsif cTAXPAYS.TAXBASE = 5 and cTAXPAYS.STATE =2 then                 -- налог ФФОМС
             nTAX_FFOMS := nTAX_FFOMS + cTAXPAYS.SUMME;
             if cTAXPAYS.MONTHNUMB =nMONTH1 then
                nTAX_FFOMS1 := nTAX_FFOMS1 + cTAXPAYS.SUMME;
             end if;
             if cTAXPAYS.MONTHNUMB = nMONTH2 then
                nTAX_FFOMS2 := nTAX_FFOMS2 + cTAXPAYS.SUMME;
             end if;
             if cTAXPAYS.MONTHNUMB = nMONTH3 then
                nTAX_FFOMS3 := nTAX_FFOMS3 + cTAXPAYS.SUMME;
             end if;
             if cTAXPAYS.TA_TYPE = 10 then
                nTAX_DEDUCT_FFOMS := nTAX_DEDUCT_FFOMS + cTAXPAYS.SUMME;
                if cTAXPAYS.MONTHNUMB = nMONTH1 then
                   nTAX_DEDUCT_FFOMS1  := nTAX_DEDUCT_FFOMS1 + cTAXPAYS.SUMME;
                end if;
                if cTAXPAYS.MONTHNUMB = nMONTH2 then
                   nTAX_DEDUCT_FFOMS2  := nTAX_DEDUCT_FFOMS2 + cTAXPAYS.SUMME;
                end if;
                if cTAXPAYS.MONTHNUMB = nMONTH3 then
                   nTAX_DEDUCT_FFOMS3  := nTAX_DEDUCT_FFOMS3 + cTAXPAYS.SUMME;
                end if;
             end if;
--       elsif cTAXPAYS.TAXBASE = 5 and cTAXPAYS.STATE =3 then                 -- расход ФФОМС
       elsif cTAXPAYS.TAXBASE = 6 and cTAXPAYS.STATE =0 then                 -- доход ТФОМС
          if trim(cTAXPAYS.POS_CODE) = '7' then
             nTMPVALUE := cTAXPAYS.SUMME;
             nINF1000_TFOMS := nINF1000_TFOMS + cTAXPAYS.SUMME;
          end if;
          if trim(cTAXPAYS.DDCODE) = '1' then
             nTMPVALUE := cTAXPAYS.DISCOUNTSUMM;
             nINF1100_TFOMS := nINF1100_TFOMS + cTAXPAYS.DISCOUNTSUMM;
          end if;
          if trim(cTAXPAYS.DDCODE) = '2' then
             nTMPVALUE := cTAXPAYS.DISCOUNTSUMM;
             nINF1100_TFOMS := nINF1100_TFOMS + cTAXPAYS.DISCOUNTSUMM;
          end if;
          if trim(cTAXPAYS.DDCODE) = '3' then
             nTMPVALUE := cTAXPAYS.DISCOUNTSUMM;
             nINF1100_TFOMS := nINF1100_TFOMS + cTAXPAYS.DISCOUNTSUMM;
          end if;
          if trim(cTAXPAYS.POS_CODE) = '1' and trim(cTAXPAYS.DDCODE) = '4' then
             nTMPVALUE := cTAXPAYS.DISCOUNTSUMM;
             nINF1100_TFOMS := nINF1100_TFOMS + cTAXPAYS.DISCOUNTSUMM;
          end if;
          if trim(cTAXPAYS.POS_CODE) = '6' then
             nTMPVALUE  := cTAXPAYS.SUMME;             -- льгота для ТФОМС
             nINF1200_TFOMS := nINF1200_TFOMS + cTAXPAYS.SUMME;
          end if;
          nBASE_TFOMS_:= nBASE_TFOMS_ + cTAXPAYS.SUMME - nTMPVALUE;         -- налоговая база для ТФОМС (строка 100)
          if cTAXPAYS.MONTHNUMB <nMONTH1 then                                 -- первый месяц последнего кавартала
             nBASE_TFOMS1_ := nBASE_TFOMS1_ + cTAXPAYS.SUMME - nTMPVALUE;
          end if;
          if cTAXPAYS.MONTHNUMB < nMONTH2 then                             -- второй месяц последнего кавартала
             nBASE_TFOMS2_ := nBASE_TFOMS2_ + cTAXPAYS.SUMME - nTMPVALUE;
          end if;
          if cTAXPAYS.MONTHNUMB < nMONTH3 then                             -- третий месяц последнего кавартала
             nBASE_TFOMS3_ := nBASE_TFOMS3_ + cTAXPAYS.SUMME - nTMPVALUE;
          end if;
       elsif cTAXPAYS.TAXBASE = 6 and cTAXPAYS.STATE =1 then                 -- вычет ТФОМС
             nDEDUCT_TFOMS_ := nDEDUCT_TFOMS_ + cTAXPAYS.SUMME;              -- льгота для ТФОМС
             if cTAXPAYS.MONTHNUMB <nMONTH1 then
                nDEDUCT_TFOMS1_ := nDEDUCT_TFOMS1_ + cTAXPAYS.SUMME;
             end if;
             if cTAXPAYS.MONTHNUMB < nMONTH2 then
                nDEDUCT_TFOMS2_ := nDEDUCT_TFOMS2_ + cTAXPAYS.SUMME;
             end if;
             if cTAXPAYS.MONTHNUMB < nMONTH3 then
                nDEDUCT_TFOMS3_ := nDEDUCT_TFOMS3_ + cTAXPAYS.SUMME;
             end if;
       elsif cTAXPAYS.TAXBASE = 6 and cTAXPAYS.STATE =2 then                 -- налог ТФОМС
             nTAX_TFOMS := nTAX_TFOMS + cTAXPAYS.SUMME;
             if cTAXPAYS.MONTHNUMB =nMONTH1 then
                nTAX_TFOMS1 := nTAX_TFOMS1 + cTAXPAYS.SUMME;
             end if;
             if cTAXPAYS.MONTHNUMB = nMONTH2 then
                nTAX_TFOMS2 := nTAX_TFOMS2 + cTAXPAYS.SUMME;
             end if;
             if cTAXPAYS.MONTHNUMB = nMONTH3 then
                nTAX_TFOMS3 := nTAX_TFOMS3 + cTAXPAYS.SUMME;
             end if;
             if cTAXPAYS.TA_TYPE = 10 then
                nTAX_DEDUCT_TFOMS := nTAX_DEDUCT_TFOMS + cTAXPAYS.SUMME;
                if cTAXPAYS.MONTHNUMB = nMONTH1 then
                   nTAX_DEDUCT_TFOMS1  := nTAX_DEDUCT_TFOMS1 + cTAXPAYS.SUMME;
                end if;
                if cTAXPAYS.MONTHNUMB = nMONTH2 then
                   nTAX_DEDUCT_TFOMS2  := nTAX_DEDUCT_TFOMS2 + cTAXPAYS.SUMME;
                end if;
                if cTAXPAYS.MONTHNUMB = nMONTH3 then
                   nTAX_DEDUCT_TFOMS3  := nTAX_DEDUCT_TFOMS3 + cTAXPAYS.SUMME;
                end if;
             end if;
 --      elsif cTAXPAYS.TAXBASE = 6 and cTAXPAYS.STATE =3 then                 -- расход ТФОМС

       elsif cTAXPAYS.TAXBASE = 7 and cTAXPAYS.STATE =0 then                 -- доход ФСС
          if trim(cTAXPAYS.POS_CODE) = '3' then
             nTMPVALUE := cTAXPAYS.SUMME;
             nINF1100_FSS := nINF1100_FSS + cTAXPAYS.SUMME;
          end if;
          if trim(cTAXPAYS.POS_CODE) = '7' then
             nTMPVALUE := cTAXPAYS.SUMME;
             nINF1000_FSS := nINF1000_FSS + cTAXPAYS.SUMME;
          end if;
          if trim(cTAXPAYS.DDCODE) = '1' then
             nTMPVALUE := cTAXPAYS.DISCOUNTSUMM;
             nINF1100_FSS := nINF1100_FSS + cTAXPAYS.DISCOUNTSUMM;
          end if;
          if trim(cTAXPAYS.DDCODE) = '2' then
             nTMPVALUE := cTAXPAYS.DISCOUNTSUMM;
             nINF1100_FSS := nINF1100_FSS + cTAXPAYS.DISCOUNTSUMM;
          end if;
          if trim(cTAXPAYS.DDCODE) = '3' then
             nTMPVALUE := cTAXPAYS.DISCOUNTSUMM;
             nINF1100_FSS := nINF1100_FSS + cTAXPAYS.DISCOUNTSUMM;
          end if;
          if trim(cTAXPAYS.POS_CODE) = '1' and trim(cTAXPAYS.DDCODE) = '4' then
             nTMPVALUE := cTAXPAYS.DISCOUNTSUMM;
             nINF1100_FSS := nINF1100_FSS + cTAXPAYS.DISCOUNTSUMM;
          end if;
          if trim(cTAXPAYS.POS_CODE) = '6' then
             nTMPVALUE := cTAXPAYS.SUMME;
             nINF1200_FSS := nINF1200_FSS + cTAXPAYS.SUMME;
          end if;
          nBASE_FSS_:= nBASE_FSS_ + cTAXPAYS.SUMME - nTMPVALUE;             -- налоговая база для ФСС (строка 100)
          if cTAXPAYS.MONTHNUMB <nMONTH1 then                                 -- первый месяц последнего кавартала
             nBASE_FSS1_ := nBASE_FSS1_ + cTAXPAYS.SUMME - nTMPVALUE;
          end if;
          if cTAXPAYS.MONTHNUMB < nMONTH2 then                             -- второй месяц последнего кавартала
             nBASE_FSS2_ := nBASE_FSS2_ + cTAXPAYS.SUMME - nTMPVALUE;
          end if;
          if cTAXPAYS.MONTHNUMB < nMONTH3 then                             -- третий месяц последнего кавартала
             nBASE_FSS3_ := nBASE_FSS3_ + cTAXPAYS.SUMME - nTMPVALUE;
          end if;
       elsif cTAXPAYS.TAXBASE = 7 and cTAXPAYS.STATE =1 then                 -- вычет ФСС
             nDEDUCT_FSS_ := nDEDUCT_FSS_ + cTAXPAYS.SUMME;                  -- льгота для ФСС
             if cTAXPAYS.MONTHNUMB <nMONTH1 then
                nDEDUCT_FSS1_ := nDEDUCT_FSS1_ + cTAXPAYS.SUMME;
             end if;
             if cTAXPAYS.MONTHNUMB < nMONTH2 then
                nDEDUCT_FSS2_ := nDEDUCT_FSS2_ + cTAXPAYS.SUMME;
             end if;
             if cTAXPAYS.MONTHNUMB < nMONTH3 then
                nDEDUCT_FSS3_ := nDEDUCT_FSS3_ + cTAXPAYS.SUMME;
             end if;
       elsif cTAXPAYS.TAXBASE = 7 and cTAXPAYS.STATE =2 then                 -- налог ФСС
             nTAX_FSS := nTAX_FSS + cTAXPAYS.SUMME;
             if cTAXPAYS.MONTHNUMB =nMONTH1 then
                nTAX_FSS1 := nTAX_FSS1 + cTAXPAYS.SUMME;
             end if;
             if cTAXPAYS.MONTHNUMB = nMONTH2 then
                nTAX_FSS2 := nTAX_FSS2 + cTAXPAYS.SUMME;
             end if;
             if cTAXPAYS.MONTHNUMB = nMONTH3 then
                nTAX_FSS3 := nTAX_FSS3 + cTAXPAYS.SUMME;
             end if;
             if cTAXPAYS.TA_TYPE = 10 then
                nTAX_DEDUCT_FSS := nTAX_DEDUCT_FSS + cTAXPAYS.SUMME;
                if cTAXPAYS.MONTHNUMB = nMONTH1 then
                   nTAX_DEDUCT_FSS1  := nTAX_DEDUCT_FSS1 + cTAXPAYS.SUMME;
                end if;
                if cTAXPAYS.MONTHNUMB = nMONTH2 then
                   nTAX_DEDUCT_FSS2  := nTAX_DEDUCT_FSS2 + cTAXPAYS.SUMME;
                end if;
                if cTAXPAYS.MONTHNUMB = nMONTH3 then
                   nTAX_DEDUCT_FSS3  := nTAX_DEDUCT_FSS3 + cTAXPAYS.SUMME;
                end if;
             end if;
       elsif cTAXPAYS.TAXBASE = 7 and cTAXPAYS.STATE =3 then                 -- расход ФСС
             nRAS_FSS := nRAS_FSS + cTAXPAYS.SUMME;
             if cTAXPAYS.MONTHNUMB =nMONTH1 then
                nRAS_FSS1 := nRAS_FSS1 + cTAXPAYS.SUMME;
             end if;
             if cTAXPAYS.MONTHNUMB = nMONTH2 then
                nRAS_FSS2 := nRAS_FSS2 + cTAXPAYS.SUMME;
             end if;
             if cTAXPAYS.MONTHNUMB = nMONTH3 then
                nRAS_FSS3 := nRAS_FSS3 + cTAXPAYS.SUMME;
             end if;
 --      elsif cTAXPAYS.TAXBASE = 8 and cTAXPAYS.STATE =0 then                 -- доход ПФР страх
 --      elsif cTAXPAYS.TAXBASE = 8 and cTAXPAYS.STATE =1 then                 -- вычет ПФР страх
       elsif nCOUNT = 0 and (cTAXPAYS.TAXBASE = 8 or cTAXPAYS.TAXBASE = 9) and cTAXPAYS.STATE =2 then                 -- налог ПФР страх
             nTAX_PFRDUTY := nTAX_PFRDUTY + cTAXPAYS.SUMME;
             if cTAXPAYS.MONTHNUMB =nMONTH1 then
                nTAX_PFRDUTY1 := nTAX_PFRDUTY1 + cTAXPAYS.SUMME;
             end if;
             if cTAXPAYS.MONTHNUMB = nMONTH2 then
                nTAX_PFRDUTY2 := nTAX_PFRDUTY2 + cTAXPAYS.SUMME;
             end if;
             if cTAXPAYS.MONTHNUMB = nMONTH3 then
                nTAX_PFRDUTY3 := nTAX_PFRDUTY3 + cTAXPAYS.SUMME;
             end if;
       elsif nCOUNT = 0 and (cTAXPAYS.TAXBASE = 10 or cTAXPAYS.TAXBASE = 11) and cTAXPAYS.STATE =2 then                 -- налог на страховую часть ПФР по не ЕНВД
             nTAX_PFRDUTYNOTENDV := nTAX_PFRDUTYNOTENDV + cTAXPAYS.SUMME;
             if cTAXPAYS.MONTHNUMB =nMONTH1 then
                nTAX_PFRDUTYNOTENDV1 := nTAX_PFRDUTYNOTENDV1 + cTAXPAYS.SUMME;
             end if;
             if cTAXPAYS.MONTHNUMB = nMONTH2 then
                nTAX_PFRDUTYNOTENDV2 := nTAX_PFRDUTYNOTENDV2 + cTAXPAYS.SUMME;
             end if;
             if cTAXPAYS.MONTHNUMB = nMONTH3 then
                nTAX_PFRDUTYNOTENDV3 := nTAX_PFRDUTYNOTENDV3 + cTAXPAYS.SUMME;
             end if;
       end if;
    end loop;
    /* Налоговая база ПФР */
    nBASE_PFR_  := greatest(nBASE_PFR_ ,nMAXVAL);
    nBASE_PFR1_ := greatest(nBASE_PFR1_,nMAXVAL);
    nBASE_PFR2_ := greatest(nBASE_PFR2_,nMAXVAL);
    nBASE_PFR3_ := greatest(nBASE_PFR3_,nMAXVAL);

    nBASE_PFR  := nBASE_PFR  + nBASE_PFR_;
    nBASE_PFR1 := nBASE_PFR1 + nBASE_PFR2_ - nBASE_PFR1_;
    nBASE_PFR2 := nBASE_PFR2 + nBASE_PFR3_ - nBASE_PFR2_;
    nBASE_PFR3 := nBASE_PFR3 + nBASE_PFR_  - nBASE_PFR3_;
    /* Налоговая база ФСС */
    nBASE_FSS_  := greatest(nBASE_FSS_ ,nMAXVAL);
    nBASE_FSS1_ := greatest(nBASE_FSS1_,nMAXVAL);
    nBASE_FSS2_ := greatest(nBASE_FSS2_,nMAXVAL);
    nBASE_FSS3_ := greatest(nBASE_FSS3_,nMAXVAL);

    nBASE_FSS  := nBASE_FSS  + nBASE_FSS_;
    nBASE_FSS1 := nBASE_FSS1 + nBASE_FSS2_ - nBASE_FSS1_;
    nBASE_FSS2 := nBASE_FSS2 + nBASE_FSS3_ - nBASE_FSS2_;
    nBASE_FSS3 := nBASE_FSS3 + nBASE_FSS_  - nBASE_FSS3_;
    /* Налоговая база ФФОМС */
    nBASE_FFOMS_  := greatest(nBASE_FFOMS_ ,nMAXVAL);
    nBASE_FFOMS1_ := greatest(nBASE_FFOMS1_,nMAXVAL);
    nBASE_FFOMS2_ := greatest(nBASE_FFOMS2_,nMAXVAL);
    nBASE_FFOMS3_ := greatest(nBASE_FFOMS3_,nMAXVAL);

    nBASE_FFOMS  := nBASE_FFOMS  + nBASE_FFOMS_;
    nBASE_FFOMS1 := nBASE_FFOMS1 + nBASE_FFOMS2_ - nBASE_FFOMS1_;
    nBASE_FFOMS2 := nBASE_FFOMS2 + nBASE_FFOMS3_ - nBASE_FFOMS2_;
    nBASE_FFOMS3 := nBASE_FFOMS3 + nBASE_FFOMS_  - nBASE_FFOMS3_;
    /* Налоговая база ТФОМС */
    nBASE_TFOMS_  := greatest(nBASE_TFOMS_ ,nMAXVAL);
    nBASE_TFOMS1_ := greatest(nBASE_TFOMS1_,nMAXVAL);
    nBASE_TFOMS2_ := greatest(nBASE_TFOMS2_,nMAXVAL);
    nBASE_TFOMS3_ := greatest(nBASE_TFOMS3_,nMAXVAL);

    nBASE_TFOMS  := nBASE_TFOMS  + nBASE_TFOMS_;
    nBASE_TFOMS1 := nBASE_TFOMS1 + nBASE_TFOMS2_ - nBASE_TFOMS1_;
    nBASE_TFOMS2 := nBASE_TFOMS2 + nBASE_TFOMS3_ - nBASE_TFOMS2_;
    nBASE_TFOMS3 := nBASE_TFOMS3 + nBASE_TFOMS_  - nBASE_TFOMS3_;

    /* льгота ПФР */
    nDEDUCT_PFR_   := greatest(least(nDEDUCT_PFR_,nBASE_PFR_),0);
    nDEDUCT_PFR1_  := greatest(least(nDEDUCT_PFR1_,nBASE_PFR1_),0);
    nDEDUCT_PFR2_  := greatest(least(nDEDUCT_PFR2_,nBASE_PFR2_),0);
    nDEDUCT_PFR3_  := greatest(least(nDEDUCT_PFR3_,nBASE_PFR3_),0);

    nDEDUCT_PFR    := nDEDUCT_PFR + nDEDUCT_PFR_;
    nDEDUCT_PFR1   := nDEDUCT_PFR1 + nDEDUCT_PFR2_ - nDEDUCT_PFR1_;
    nDEDUCT_PFR2   := nDEDUCT_PFR2 + nDEDUCT_PFR3_ - nDEDUCT_PFR2_;
    nDEDUCT_PFR3   := nDEDUCT_PFR3 + nDEDUCT_PFR_  - nDEDUCT_PFR3_;
    /* льгота ФСС */
    nDEDUCT_FSS_   := greatest(least(nDEDUCT_FSS_,nBASE_FSS_),0);
    nDEDUCT_FSS1_  := greatest(least(nDEDUCT_FSS1_,nBASE_FSS1_),0);
    nDEDUCT_FSS2_  := greatest(least(nDEDUCT_FSS2_,nBASE_FSS2_),0);
    nDEDUCT_FSS3_  := greatest(least(nDEDUCT_FSS3_,nBASE_FSS3_),0);

    nDEDUCT_FSS    := nDEDUCT_FSS + nDEDUCT_FSS_;
    nDEDUCT_FSS1   := nDEDUCT_FSS1 + nDEDUCT_FSS2_ - nDEDUCT_FSS1_;
    nDEDUCT_FSS2   := nDEDUCT_FSS2 + nDEDUCT_FSS3_ - nDEDUCT_FSS2_;
    nDEDUCT_FSS3   := nDEDUCT_FSS3 + nDEDUCT_FSS_  - nDEDUCT_FSS3_;
    /* льгота ФФОМС */
    nDEDUCT_FFOMS_ := greatest(least(nDEDUCT_FFOMS_,nBASE_FFOMS_),0);
    nDEDUCT_FFOMS1_ := greatest(least(nDEDUCT_FFOMS1_,nBASE_FFOMS1_),0);
    nDEDUCT_FFOMS2_ := greatest(least(nDEDUCT_FFOMS2_,nBASE_FFOMS2_),0);
    nDEDUCT_FFOMS3_ := greatest(least(nDEDUCT_FFOMS3_,nBASE_FFOMS3_),0);

    nDEDUCT_FFOMS    := nDEDUCT_FFOMS + nDEDUCT_FFOMS_;
    nDEDUCT_FFOMS1   := nDEDUCT_FFOMS1 + nDEDUCT_FFOMS2_ - nDEDUCT_FFOMS1_;
    nDEDUCT_FFOMS2   := nDEDUCT_FFOMS2 + nDEDUCT_FFOMS3_ - nDEDUCT_FFOMS2_;
    nDEDUCT_FFOMS3   := nDEDUCT_FFOMS3 + nDEDUCT_FFOMS_  - nDEDUCT_FFOMS3_;
    /* льгота ТФОМС */
    nDEDUCT_TFOMS_ := greatest(least(nDEDUCT_TFOMS_,nBASE_TFOMS_),0);
    nDEDUCT_TFOMS1_ := greatest(least(nDEDUCT_TFOMS1_,nBASE_TFOMS1_),0);
    nDEDUCT_TFOMS2_ := greatest(least(nDEDUCT_TFOMS2_,nBASE_TFOMS2_),0);
    nDEDUCT_TFOMS3_ := greatest(least(nDEDUCT_TFOMS3_,nBASE_TFOMS3_),0);

    nDEDUCT_TFOMS    := nDEDUCT_TFOMS + nDEDUCT_TFOMS_;
    nDEDUCT_TFOMS1   := nDEDUCT_TFOMS1 + nDEDUCT_TFOMS2_ - nDEDUCT_TFOMS1_;
    nDEDUCT_TFOMS2   := nDEDUCT_TFOMS2 + nDEDUCT_TFOMS3_ - nDEDUCT_TFOMS2_;
    nDEDUCT_TFOMS3   := nDEDUCT_TFOMS3 + nDEDUCT_TFOMS_  - nDEDUCT_TFOMS3_;
   end GET_SUMM;

   begin
    nBASE_PFR      :=0;
    nBASE_PFR1     :=0;
    nBASE_PFR2     :=0;
    nBASE_PFR3     :=0;
    nBASE_FSS      :=0;
    nBASE_FSS1     :=0;
    nBASE_FSS2     :=0;
    nBASE_FSS3     :=0;
    nBASE_FFOMS    :=0;
    nBASE_FFOMS1   :=0;
    nBASE_FFOMS2   :=0;
    nBASE_FFOMS3   :=0;
    nBASE_TFOMS    :=0;
    nBASE_TFOMS1   :=0;
    nBASE_TFOMS2   :=0;
    nBASE_TFOMS3   :=0;
    nDEDUCT_PFR    :=0;
    nDEDUCT_PFR1   :=0;
    nDEDUCT_PFR2   :=0;
    nDEDUCT_PFR3   :=0;
    nDEDUCT_FSS    :=0;
    nDEDUCT_FSS1   :=0;
    nDEDUCT_FSS2   :=0;
    nDEDUCT_FSS3   :=0;
    nDEDUCT_FFOMS  :=0;
    nDEDUCT_FFOMS1 :=0;
    nDEDUCT_FFOMS2 :=0;
    nDEDUCT_FFOMS3 :=0;
    nDEDUCT_TFOMS  :=0;
    nDEDUCT_TFOMS1 :=0;
    nDEDUCT_TFOMS2 :=0;
    nDEDUCT_TFOMS3 :=0;
    nTAX_PFR       :=0;
    nTAX_PFR1      :=0;
    nTAX_PFR2      :=0;
    nTAX_PFR3      :=0;
    nTAX_FSS       :=0;
    nTAX_FSS1      :=0;
    nTAX_FSS2      :=0;
    nTAX_FSS3      :=0;
    nTAX_FFOMS     :=0;
    nTAX_FFOMS1    :=0;
    nTAX_FFOMS2    :=0;
    nTAX_FFOMS3    :=0;
    nTAX_TFOMS     :=0;
    nTAX_TFOMS1    :=0;
    nTAX_TFOMS2    :=0;
    nTAX_TFOMS3    :=0;
    nTAX_DEDUCT_PFR    :=0;
    nTAX_DEDUCT_PFR1   :=0;
     nTAX_DEDUCT_PFR2   :=0;
    nTAX_DEDUCT_PFR3   :=0;
    nTAX_DEDUCT_FSS    :=0;
    nTAX_DEDUCT_FSS1   :=0;
    nTAX_DEDUCT_FSS2   :=0;
    nTAX_DEDUCT_FSS3   :=0;
    nTAX_DEDUCT_FFOMS  :=0;
    nTAX_DEDUCT_FFOMS1 :=0;
    nTAX_DEDUCT_FFOMS2 :=0;
    nTAX_DEDUCT_FFOMS3 :=0;
    nTAX_DEDUCT_TFOMS  :=0;
    nTAX_DEDUCT_TFOMS1 :=0;
    nTAX_DEDUCT_TFOMS2 :=0;
    nTAX_DEDUCT_TFOMS3 :=0;
    nTAX_PFRDUTY   :=0;
    nTAX_PFRDUTY1  :=0;
    nTAX_PFRDUTY2  :=0;
    nTAX_PFRDUTY3  :=0;
    nRAS_FSS       :=0;
    nRAS_FSS1      :=0;
    nRAS_FSS2      :=0;
    nRAS_FSS3      :=0;
    nPER_FSS       :=0;
    nPER_FSS1      :=0;
    nPER_FSS2      :=0;
    nPER_FSS3      :=0;
    nINF1000_PFR   :=0;
    nINF1000_FSS   :=0;
    nINF1000_FFOMS :=0;
    nINF1000_TFOMS :=0;
    nINF1100_PFR   :=0;
    nINF1100_FSS   :=0;
    nINF1100_FFOMS :=0;
    nINF1100_TFOMS :=0;
    nINF1200_PFR   :=0;
    nINF1200_FSS   :=0;
    nINF1200_FFOMS :=0;
    nINF1200_TFOMS :=0;
    nINF1300_PFR   :=0;
    nTAX_PFRDUTYNOTENDV   :=0;                   -- налог в ПФР на обязательное страхование по не ЕНВД
    nTAX_PFRDUTYNOTENDV1  :=0;
    nTAX_PFRDUTYNOTENDV2  :=0;
    nTAX_PFRDUTYNOTENDV3  :=0;
    nMONTHBEGIN := D_MONTH(dPERIODBEGIN);
    nMONTHEND   := D_MONTH(dPERIODEND);
    nMONTH3 := nMONTHEND;
    nMONTH2 := nMONTH3-1;
    nMONTH1 := nMONTH3-2;
    if nNEGOTIVE = 1 then
       nMAXVAL:= -9999999999;
    else
       nMAXVAL:= 0;
    end if;
    -- список сотрудников выбранного подразделения
    if nDEPARTMENT is null and nCLNPSPFMFGRP is null then  -- организация
       for cTAX in
       (
        select CP.PERSRN,
               TC.RN as CLNPERSTAXACC
          from CLNPSPFM CP,
              CLNPERSTAXACC TC
          where CP.PERSRN = TC.PRN
            and CP.COMPANY = nCOMPANY
            and TC.TYPE = 0
            and TC.YEAR = nYEAR
          group by CP.PERSRN,TC.RN
         )
         loop
           GET_SUMM(cTAX.PERSRN,cTAX.CLNPERSTAXACC,nYEAR,nMONTHBEGIN,nMONTHEND,nNEGOTIVE);
         end loop;
    elsif nDEPARTMENT is not null and nCHILDDEP=1 then  -- Подразделение и подчиненные
         for cTAX in
         (
          Select CP.PERSRN,
                 TC.RN as CLNPERSTAXACC
            from CLNPSPFM CP,
                 CLNPERSTAXACC TC
            where CP.PERSRN = TC.PRN
              and CP.DEPTRN in (Select RN from INS_DEPARTMENT start with rn = nDEPARTMENT  connect by prior RN=PRN)
              and TC.TYPE = 0
              and TC.YEAR = nYEAR
            group by CP.PERSRN,TC.RN
         )
         loop
           GET_SUMM(cTAX.PERSRN,cTAX.CLNPERSTAXACC,nYEAR,nMONTHBEGIN,nMONTHEND,nNEGOTIVE);
         end loop;
    elsif nDEPARTMENT is not null and nCHILDDEP=0 then  -- Подразделение без подчиненных
         for cTAX in
         (
          Select CP.PERSRN,
                 TC.RN as CLNPERSTAXACC
            from CLNPSPFM CP,
                 CLNPERSTAXACC TC
            where CP.PERSRN = TC.PRN
              and CP.DEPTRN = nDEPARTMENT
              and TC.TYPE = 0
              and TC.YEAR = nYEAR
            group by CP.PERSRN,TC.RN
         )
         loop
           GET_SUMM(cTAX.PERSRN,cTAX.CLNPERSTAXACC,nYEAR,nMONTHBEGIN,nMONTHEND,nNEGOTIVE);
         end loop;
    elsif nDEPARTMENT is null and nCLNPSPFMFGRP is not null then  -- Группа исполнений
      for cTAX in
      (
       Select CP.PERSRN,
              TC.RN as CLNPERSTAXACC
         from CLNPSPFMFGRPSP CPS,
              CLNPSPFM CP,
              CLNPERSTAXACC TC,
              CLNPERSONS CN
         where CPS.CLNPSPFM = CP.RN
           and CP.PERSRN = TC.PRN
           and CP.PERSRN = CN.RN
           and CPS.PRN = nCLNPSPFMFGRP
           and TC.TYPE = 0
           and TC.YEAR = nYEAR
         group by CP.PERSRN,TC.RN
      )
      loop
        GET_SUMM(cTAX.PERSRN,cTAX.CLNPERSTAXACC,nYEAR,nMONTHBEGIN,nMONTHEND,nNEGOTIVE);
      end loop;
    end if;
    if nTAX_PFRDUTYNOTENDV<> 0 then      -- налог в ПФР на обязательное страхование по не ЕНВД
      /* если Сбор отчислений в части облагаемых по ЕНВД, вычисляем разницу между ВСЕГО и ЕНВД */
      if nDIFENVD = 1 then
        nTAX_PFRDUTY  := nTAX_PFRDUTY - nTAX_PFRDUTYNOTENDV;
        nTAX_PFRDUTY1 := nTAX_PFRDUTY1 - nTAX_PFRDUTYNOTENDV1;
        nTAX_PFRDUTY2 := nTAX_PFRDUTY2 - nTAX_PFRDUTYNOTENDV2;
        nTAX_PFRDUTY3 := nTAX_PFRDUTY3 - nTAX_PFRDUTYNOTENDV3;
      else
        nTAX_PFRDUTY  := nTAX_PFRDUTYNOTENDV;
        nTAX_PFRDUTY1 := nTAX_PFRDUTYNOTENDV1;
        nTAX_PFRDUTY2 := nTAX_PFRDUTYNOTENDV2;
        nTAX_PFRDUTY3 := nTAX_PFRDUTYNOTENDV3;
      end if;
    end if;
    if nDEVIDE = 1 then
       nDEVISOR := 2;
    else
       nDEVISOR := 1;
    end if;
    nTAX_DEDUCT_PFR   := nTAX_DEDUCT_PFR/nDEVISOR;
    nTAX_DEDUCT_PFR1  := nTAX_DEDUCT_PFR1/nDEVISOR;
    nTAX_DEDUCT_PFR2  := nTAX_DEDUCT_PFR2/nDEVISOR;
    nTAX_DEDUCT_PFR3  := nTAX_DEDUCT_PFR3/nDEVISOR;
    nPER_FSS := nvl(nPAY_FSS,nRAS_FSS);
    nPER_FSS1 := nvl(nPAY_FSS1,nRAS_FSS1);
    nPER_FSS2 := nvl(nPAY_FSS2,nRAS_FSS2);
    nPER_FSS3 := nvl(nPAY_FSS3,nRAS_FSS3);

    /* округление и ликвидация погрешности */
    nBASE_PFR   := round(nBASE_PFR,0);
    nBASE_PFR1  := round(nBASE_PFR1,0);
    nBASE_PFR2  := round(nBASE_PFR2,0);
    nBASE_PFR3  := round(nBASE_PFR3,0);
    nBASE_FSS   := round(nBASE_FSS,0);
    nBASE_FSS1  := round(nBASE_FSS1,0);
    nBASE_FSS2  := round(nBASE_FSS2,0);
    nBASE_FSS3  := round(nBASE_FSS3,0);
    nBASE_FFOMS := round(nBASE_FFOMS,0);
    nBASE_FFOMS1:= round(nBASE_FFOMS1,0);
    nBASE_FFOMS2:= round(nBASE_FFOMS2,0);
    nBASE_FFOMS3:= round(nBASE_FFOMS3,0);
    nBASE_TFOMS := round(nBASE_TFOMS,0);
    nBASE_TFOMS1:= round(nBASE_TFOMS1,0);
    nBASE_TFOMS2:= round(nBASE_TFOMS2,0);
    nBASE_TFOMS3:= round(nBASE_TFOMS3,0);
    nDEDUCT_PFR := round(nDEDUCT_PFR,0);
    nDEDUCT_PFR1:= round(nDEDUCT_PFR1,0);
    nDEDUCT_PFR2:= round(nDEDUCT_PFR2,0);
    nDEDUCT_PFR3:= round(nDEDUCT_PFR3,0);
    nDEDUCT_FSS := round(nDEDUCT_FSS,0);
    nDEDUCT_FSS1:= round(nDEDUCT_FSS1,0);
    nDEDUCT_FSS2:= round(nDEDUCT_FSS2,0);
    nDEDUCT_FSS3:= round(nDEDUCT_FSS3,0);
    nDEDUCT_FFOMS:= round(nDEDUCT_FFOMS,0);
    nDEDUCT_FFOMS1:= round(nDEDUCT_FFOMS1,0);
    nDEDUCT_FFOMS2:= round(nDEDUCT_FFOMS2,0);
    nDEDUCT_FFOMS3:= round(nDEDUCT_FFOMS3,0);
    nDEDUCT_TFOMS := round(nDEDUCT_TFOMS,0);
    nDEDUCT_TFOMS1:= round(nDEDUCT_TFOMS1,0);
    nDEDUCT_TFOMS2:= round(nDEDUCT_TFOMS2,0);
    nDEDUCT_TFOMS3:= round(nDEDUCT_TFOMS3,0);
    nTAX_PFR      := round(nTAX_PFR,0);
    nTAX_PFR1     := round(nTAX_PFR1,0);
    nTAX_PFR2     := round(nTAX_PFR2,0);
    nTAX_PFR3     := round(nTAX_PFR3,0);
    nTAX_FSS      := round(nTAX_FSS,0);
    nTAX_FSS1     := round(nTAX_FSS1,0);
    nTAX_FSS2     := round(nTAX_FSS2,0);
    nTAX_FSS3     := round(nTAX_FSS3,0);
    nTAX_FFOMS    := round(nTAX_FFOMS,0);
    nTAX_FFOMS1   := round(nTAX_FFOMS1,0);
    nTAX_FFOMS2   := round(nTAX_FFOMS2,0);
    nTAX_FFOMS3   := round(nTAX_FFOMS3,0);
    nTAX_TFOMS    := round(nTAX_TFOMS,0);
    nTAX_TFOMS1   := round(nTAX_TFOMS1,0);
    nTAX_TFOMS2   := round(nTAX_TFOMS2,0);
    nTAX_TFOMS3   := round(nTAX_TFOMS3,0);
    nTAX_PFRDUTY  := round(nTAX_PFRDUTY,0);
    nTAX_PFRDUTY1 := round(nTAX_PFRDUTY1,0);
    nTAX_PFRDUTY2 := round(nTAX_PFRDUTY2,0);
    nTAX_PFRDUTY3 := round(nTAX_PFRDUTY3,0);
    nTAX_DEDUCT_PFR := round(nTAX_DEDUCT_PFR,0);
    nTAX_DEDUCT_PFR1:= round(nTAX_DEDUCT_PFR1,0);
    nTAX_DEDUCT_PFR2:= round(nTAX_DEDUCT_PFR2,0);
    nTAX_DEDUCT_PFR3:= round(nTAX_DEDUCT_PFR3,0);
    nTAX_DEDUCT_FSS := round(nTAX_DEDUCT_FSS,0);
    nTAX_DEDUCT_FSS1:= round(nTAX_DEDUCT_FSS1,0);
    nTAX_DEDUCT_FSS2:= round(nTAX_DEDUCT_FSS2,0);
    nTAX_DEDUCT_FSS3:= round(nTAX_DEDUCT_FSS3,0);
    nTAX_DEDUCT_FFOMS:= round(nTAX_DEDUCT_FFOMS,0);
    nTAX_DEDUCT_FFOMS1:= round(nTAX_DEDUCT_FFOMS1,0);
    nTAX_DEDUCT_FFOMS2:= round(nTAX_DEDUCT_FFOMS2,0);
    nTAX_DEDUCT_FFOMS3:= round(nTAX_DEDUCT_FFOMS3,0);
    nTAX_DEDUCT_TFOMS := round(nTAX_DEDUCT_TFOMS,0);
    nTAX_DEDUCT_TFOMS1:= round(nTAX_DEDUCT_TFOMS1,0);
    nTAX_DEDUCT_TFOMS2:= round(nTAX_DEDUCT_TFOMS2,0);
    nTAX_DEDUCT_TFOMS3:= round(nTAX_DEDUCT_TFOMS3,0);

       nRAS_FSS          := round(nRAS_FSS,0);
    nRAS_FSS1         := round(nRAS_FSS1,0);
    nRAS_FSS2         := round(nRAS_FSS2,0);
    nRAS_FSS3         := round(nRAS_FSS3,0);

    nPER_FSS          := round(nPER_FSS,0);
    nPER_FSS1         := round(nPER_FSS1,0);
    nPER_FSS2         := round(nPER_FSS2,0);
    nPER_FSS3         := round(nPER_FSS3,0);

    nINF1000_PFR      := round(nINF1000_PFR,0);
    nINF1000_FSS      := round(nINF1000_FSS,0);
    nINF1000_FFOMS    := round(nINF1000_FFOMS,0);
    nINF1000_TFOMS    := round(nINF1000_TFOMS,0);
    nINF1100_PFR      := round(nINF1100_PFR,0);
    nINF1100_FSS      := round(nINF1100_FSS,0);
    nINF1100_FFOMS    := round(nINF1100_FFOMS,0);
    nINF1100_TFOMS    := round(nINF1100_TFOMS,0);
    nINF1200_PFR      := round(nINF1200_PFR,0);
    nINF1200_FSS      := round(nINF1200_FSS ,0);
    nINF1200_FFOMS    := round(nINF1200_FFOMS,0);
    nINF1200_TFOMS    := round(nINF1200_TFOMS,0);
    nINF1300_PFR      := round(nINF1300_PFR,0);

    /* для первого квартала делаем коррекцию погрешности округления */
    if nMONTHBEGIN = 1 and nMONTHEND = 3 then
       DELTA(nBASE_PFR,nBASE_PFR1,nBASE_PFR2,nBASE_PFR3);
       DELTA(nBASE_FSS,nBASE_FSS1,nBASE_FSS2,nBASE_FSS3);
       DELTA(nBASE_FFOMS,nBASE_FFOMS1,nBASE_FFOMS2,nBASE_FFOMS3);
       DELTA(nBASE_TFOMS,nBASE_TFOMS1,nBASE_TFOMS2,nBASE_TFOMS3);
       DELTA(nDEDUCT_PFR,nDEDUCT_PFR1,nDEDUCT_PFR2,nDEDUCT_PFR3);
       DELTA(nDEDUCT_FSS,nDEDUCT_FSS1,nDEDUCT_FSS2,nDEDUCT_FSS3);
       DELTA(nDEDUCT_FFOMS,nDEDUCT_FFOMS1,nDEDUCT_FFOMS2,nDEDUCT_FFOMS3);
       DELTA(nDEDUCT_TFOMS,nDEDUCT_TFOMS1,nDEDUCT_TFOMS2,nDEDUCT_TFOMS3);
       DELTA(nTAX_PFR,nTAX_PFR1,nTAX_PFR2,nTAX_PFR3);
       DELTA(nTAX_FSS,nTAX_FSS1,nTAX_FSS2,nTAX_FSS3);
       DELTA(nTAX_FFOMS,nTAX_FFOMS1,nTAX_FFOMS2,nTAX_FFOMS3);
       DELTA(nTAX_TFOMS,nTAX_TFOMS1,nTAX_TFOMS2,nTAX_TFOMS3);
       DELTA(nTAX_PFRDUTY,nTAX_PFRDUTY1,nTAX_PFRDUTY2,nTAX_PFRDUTY3);
       DELTA(nTAX_DEDUCT_PFR,nTAX_DEDUCT_PFR1,nTAX_DEDUCT_PFR2,nTAX_DEDUCT_PFR3);
       DELTA(nTAX_DEDUCT_FSS,nTAX_DEDUCT_FSS1,nTAX_DEDUCT_FSS2,nTAX_DEDUCT_FSS3);
       DELTA(nTAX_DEDUCT_FFOMS,nTAX_DEDUCT_FFOMS1,nTAX_DEDUCT_FFOMS2,nTAX_DEDUCT_FFOMS3);
       DELTA(nTAX_DEDUCT_TFOMS,nTAX_DEDUCT_TFOMS1,nTAX_DEDUCT_TFOMS2,nTAX_DEDUCT_TFOMS3);
       DELTA(nRAS_FSS,nRAS_FSS1,nRAS_FSS2,nRAS_FSS3);
    end if;
    insert
    into SLCST_CALC
    (
     RN,
     AUTHID,
     BASE_PFR,
     BASE_PFR1,
     BASE_PFR2,
     BASE_PFR3,
     BASE_FSS,
     BASE_FSS1,
     BASE_FSS2,
     BASE_FSS3,
     BASE_FFOMS,
     BASE_FFOMS1,
     BASE_FFOMS2,
     BASE_FFOMS3,
     BASE_TFOMS,
     BASE_TFOMS1,
     BASE_TFOMS2,
     BASE_TFOMS3,
     DEDUCT_PFR,
     DEDUCT_PFR1,
     DEDUCT_PFR2,
     DEDUCT_PFR3,
     DEDUCT_FSS,
     DEDUCT_FSS1,
     DEDUCT_FSS2,
     DEDUCT_FSS3,
     DEDUCT_FFOMS,
     DEDUCT_FFOMS1,
     DEDUCT_FFOMS2,
     DEDUCT_FFOMS3,
     DEDUCT_TFOMS,
     DEDUCT_TFOMS1,
     DEDUCT_TFOMS2,
     DEDUCT_TFOMS3,
     TAX_PFR,
     TAX_PFR1,
     TAX_PFR2,
     TAX_PFR3,
     TAX_FSS,
     TAX_FSS1,
     TAX_FSS2,
     TAX_FSS3,
     TAX_FFOMS,
     TAX_FFOMS1,
     TAX_FFOMS2,
     TAX_FFOMS3,
     TAX_TFOMS,
     TAX_TFOMS1,
     TAX_TFOMS2,
     TAX_TFOMS3,
     TAX_PFRDUTY,
     TAX_PFRDUTY1,
     TAX_PFRDUTY2,
     TAX_PFRDUTY3,
     TAX_DEDUCT_PFR,
     TAX_DEDUCT_PFR1,
     TAX_DEDUCT_PFR2,
     TAX_DEDUCT_PFR3,
     TAX_DEDUCT_FSS,
     TAX_DEDUCT_FSS1,
     TAX_DEDUCT_FSS2,
     TAX_DEDUCT_FSS3,
     TAX_DEDUCT_FFOMS,
     TAX_DEDUCT_FFOMS1,
     TAX_DEDUCT_FFOMS2,
     TAX_DEDUCT_FFOMS3,
     TAX_DEDUCT_TFOMS,
     TAX_DEDUCT_TFOMS1,
     TAX_DEDUCT_TFOMS2,
     TAX_DEDUCT_TFOMS3,
     RAS_FSS,
     RAS_FSS1,
     RAS_FSS2,
     RAS_FSS3,
     PER_FSS,
     PER_FSS1,
     PER_FSS2,
     PER_FSS3,
     INF1000_PFR,
     INF1000_FSS,
     INF1000_FFOMS,
     INF1000_TFOMS,
     INF1100_PFR,
     INF1100_FSS,
     INF1100_FFOMS,
     INF1100_TFOMS,
     INF1200_PFR,
     INF1200_FSS,
     INF1200_FFOMS,
     INF1200_TFOMS,
     INF1300_PFR
    )
    values
    (
     1,
     user,
     nBASE_PFR,
     nBASE_PFR1,
     nBASE_PFR2,
     nBASE_PFR3,
     nBASE_FSS,
     nBASE_FSS1,
     nBASE_FSS2,
     nBASE_FSS3,
     nBASE_FFOMS,
     nBASE_FFOMS1,
     nBASE_FFOMS2,
     nBASE_FFOMS3,
     nBASE_TFOMS,
     nBASE_TFOMS1,
     nBASE_TFOMS2,
     nBASE_TFOMS3,
     nDEDUCT_PFR,
     nDEDUCT_PFR1,
     nDEDUCT_PFR2,
     nDEDUCT_PFR3,
     nDEDUCT_FSS,
     nDEDUCT_FSS1,
     nDEDUCT_FSS2,
     nDEDUCT_FSS3,
     nDEDUCT_FFOMS,
     nDEDUCT_FFOMS1,
     nDEDUCT_FFOMS2,
     nDEDUCT_FFOMS3,
     nDEDUCT_TFOMS,
     nDEDUCT_TFOMS1,
     nDEDUCT_TFOMS2,
     nDEDUCT_TFOMS3,
     nTAX_PFR,
     nTAX_PFR1,
     nTAX_PFR2,
     nTAX_PFR3,
     nTAX_FSS,
     nTAX_FSS1,
     nTAX_FSS2,
     nTAX_FSS3,
     nTAX_FFOMS,
     nTAX_FFOMS1,
     nTAX_FFOMS2,
     nTAX_FFOMS3,
     nTAX_TFOMS,
     nTAX_TFOMS1,
     nTAX_TFOMS2,
     nTAX_TFOMS3,
     nTAX_PFRDUTY,
     nTAX_PFRDUTY1,
     nTAX_PFRDUTY2,
     nTAX_PFRDUTY3,
     nTAX_DEDUCT_PFR,
     nTAX_DEDUCT_PFR1,
     nTAX_DEDUCT_PFR2,
     nTAX_DEDUCT_PFR3,
     nTAX_DEDUCT_FSS,
     nTAX_DEDUCT_FSS1,
     nTAX_DEDUCT_FSS2,
     nTAX_DEDUCT_FSS3,
     nTAX_DEDUCT_FFOMS,
     nTAX_DEDUCT_FFOMS1,
     nTAX_DEDUCT_FFOMS2,
     nTAX_DEDUCT_FFOMS3,
     nTAX_DEDUCT_TFOMS,
     nTAX_DEDUCT_TFOMS1,
     nTAX_DEDUCT_TFOMS2,
     nTAX_DEDUCT_TFOMS3,
     nRAS_FSS,
     nRAS_FSS1,
     nRAS_FSS2,
     nRAS_FSS3,
     nPER_FSS,
     nPER_FSS1,
     nPER_FSS2,
     nPER_FSS3,
     nINF1000_PFR,
     nINF1000_FSS,
     nINF1000_FFOMS,
     nINF1000_TFOMS,
     nINF1100_PFR,
     nINF1100_FSS,
     nINF1100_FFOMS,
     nINF1100_TFOMS,
     nINF1200_PFR,
     nINF1200_FSS,
     nINF1200_FFOMS,
     nINF1200_TFOMS,
     nINF1300_PFR
   );
   begin
     update SLCST_EMPLOYER
        set TAX_PFR  = greatest(nTAX_PFR  - nTAX_PFRDUTY  - nTAX_DEDUCT_PFR,0),
            TAX_PFR1 = greatest(nTAX_PFR1 - nTAX_PFRDUTY1 - nTAX_DEDUCT_PFR1,0),
            TAX_PFR2 = greatest(nTAX_PFR2 - nTAX_PFRDUTY2 - nTAX_DEDUCT_PFR2,0),
            TAX_PFR3 = greatest(nTAX_PFR3 - nTAX_PFRDUTY3 - nTAX_DEDUCT_PFR3,0),
            TAX_FSS  = greatest(nTAX_FSS  - nTAX_DEDUCT_FSS  - nRAS_FSS + nPER_FSS,0),
            TAX_FSS1 = greatest(nTAX_FSS1 - nTAX_DEDUCT_FSS1 - nRAS_FSS1 + nPER_FSS1,0),
            TAX_FSS2 = greatest(nTAX_FSS2 - nTAX_DEDUCT_FSS2 - nRAS_FSS2 + nPER_FSS2,0),
            TAX_FSS3 = greatest(nTAX_FSS3 - nTAX_DEDUCT_FSS3 - nRAS_FSS3 + nPER_FSS3,0),
            TAX_FFOMS  = greatest(nTAX_FFOMS  - nTAX_DEDUCT_FFOMS,0),
            TAX_FFOMS1 = greatest(nTAX_FFOMS1 - nTAX_DEDUCT_FFOMS1,0),
            TAX_FFOMS2 = greatest(nTAX_FFOMS2 - nTAX_DEDUCT_FFOMS2,0),
            TAX_FFOMS3 = greatest(nTAX_FFOMS3 - nTAX_DEDUCT_FFOMS3,0),
            TAX_TFOMS  = greatest(nTAX_TFOMS  - nTAX_DEDUCT_TFOMS,0),
            TAX_TFOMS1 = greatest(nTAX_TFOMS1 - nTAX_DEDUCT_TFOMS1,0),
            TAX_TFOMS2 = greatest(nTAX_TFOMS2 - nTAX_DEDUCT_TFOMS2,0),
            TAX_TFOMS3 = greatest(nTAX_TFOMS3 - nTAX_DEDUCT_TFOMS3,0)
      where AUTHID = user;
     if ( SQL%NOTFOUND ) then
        P_EXCEPTION( 0,'Запись плательщика налога не найдена.' );
     end if;
   end;
end  CALC_CREATE;


/* Расчет по шкалам налогообложения */
procedure SCALE_CREATE
(
 nCOMPANY        in number,
 nDEPARTMENT     in varchar2,                  -- подразделение
 nYEAR           in number,
 dPERIODBEGIN    in date,
 dPERIODEND      in date,
 nCHILDDEP       in number,                    -- признак учитывать все подчиненные подразделения
 nNEGOTIVE       in number,                    -- отриц налог. база
 nTAXSCALE_PFR   in number,                    -- налоговая шкала для ПФР
 nTAXSCALE_FSS   in number,
 nTAXSCALE_FFOMS in number,
 nTAXSCALE_TFOMS in number,
 n2005           in number default 0,          -- признак печати отчетности за 2005г
 nCLNPSPFMFGRP   in number default null        -- группа исполнений
)
as
 nTAXBASE_PFR     number;
 nTAXBASE_FSS     number;
 nTAXBASE_FFOMS   number;
 nTAXBASE_TFOMS   number;
 nTAX_PFR         number;
 nTAX_FSS         number;
 nTAX_FFOMS       number;
 nTAX_TFOMS       number;
 nDEDUCT_PFR      number;
 nDEDUCT_FSS      number;
 nDEDUCT_FFOMS    number;
 nDEDUCT_TFOMS    number;
 aSCALE_PFR       t_ASCALE := t_ASCALE();
 aSCALE_FSS       t_ASCALE := t_ASCALE();
 aSCALE_FFOMS     t_ASCALE := t_ASCALE();
 aSCALE_TFOMS     t_ASCALE := t_ASCALE();
 aTAX_PFR         t_ATAXSUM := t_ATAXSUM();
 aTAX_FSS         t_ATAXSUM := t_ATAXSUM();
 aTAX_FFOMS       t_ATAXSUM := t_ATAXSUM();
 aTAX_TFOMS       t_ATAXSUM := t_ATAXSUM();
 aTAX_PFRITO      t_ATAXSUM := t_ATAXSUM();
 aTAX_FSSITO      t_ATAXSUM := t_ATAXSUM();
 aTAX_FFOMSITO    t_ATAXSUM := t_ATAXSUM();
 aTAX_TFOMSITO    t_ATAXSUM := t_ATAXSUM();
 i                number;
 j                number;
 nMONTHBEGIN      number;
 nMONTHEND        number;
procedure SET_VALUES
as
begin
 nTAXBASE_PFR   :=0;
 nTAXBASE_FSS   :=0;
 nTAXBASE_FFOMS :=0;
 nTAXBASE_TFOMS :=0;
 nTAX_PFR       :=0;
 nTAX_FSS       :=0;
 nTAX_FFOMS     :=0;
 nTAX_TFOMS     :=0;
 nDEDUCT_PFR    :=0;
 nDEDUCT_FSS    :=0;
 nDEDUCT_FFOMS  :=0;
 nDEDUCT_TFOMS  :=0;
end SET_VALUES;

procedure GET_SUMM
(
 nCLNPERSTAXACC       in number
)
as
 nMAXVAL  number;
begin

  if nNEGOTIVE = 1 then
     nMAXVAL:= -9999999999;
  else
     nMAXVAL:= 0;
  end if;
  for cTAXPAYS in
 (
   select TP.SLTAXACCS,
          sum(TP.SUMME) as SUMME,
          sum(TP.DISCOUNTSUMM) as DISCOUNTSUMM,
          TR.TAXBASE,
          TR.STATE
    from CLNPERSTAXACCSP TP,
         CLNPERSTAXACC   TC,
         SLTAXACCS TR
    where TC.RN = TP.PRN
      and TP.SLTAXACCS = TR.RN
      and TC.RN = nCLNPERSTAXACC
      and TP.MONTHNUMB>=nMONTHBEGIN
      and TP.MONTHNUMB<=nMONTHEND
      and trim(TR.POS_CODE) <> '7'
    group by TP.SLTAXACCS, TR.TAXBASE, TR.STATE
  )
  loop
     if cTAXPAYS.TAXBASE = 4 and cTAXPAYS.STATE =0 then       -- доход ПФР
        nTAXBASE_PFR := nTAXBASE_PFR + cTAXPAYS.SUMME - cTAXPAYS.DISCOUNTSUMM;
     elsif cTAXPAYS.TAXBASE = 4 and cTAXPAYS.STATE =2 then    -- налог по ПФР
        nTAX_PFR := nTAX_PFR + cTAXPAYS.SUMME;
     elsif cTAXPAYS.TAXBASE = 5 and cTAXPAYS.STATE =0 then    -- доход ФФОМС
        nTAXBASE_FFOMS := nTAXBASE_FFOMS + cTAXPAYS.SUMME - cTAXPAYS.DISCOUNTSUMM;
     elsif cTAXPAYS.TAXBASE = 5 and cTAXPAYS.STATE =2 then    -- налог ФФОМС
         nTAX_FFOMS := nTAX_FFOMS + cTAXPAYS.SUMME;
     elsif cTAXPAYS.TAXBASE = 6 and cTAXPAYS.STATE =0 then    -- доход ТФОМС
        nTAXBASE_TFOMS := nTAXBASE_TFOMS + cTAXPAYS.SUMME - cTAXPAYS.DISCOUNTSUMM;
     elsif cTAXPAYS.TAXBASE = 6 and cTAXPAYS.STATE =2 then    -- налог ТФОМС
        nTAX_TFOMS := nTAX_TFOMS + cTAXPAYS.SUMME;
     elsif cTAXPAYS.TAXBASE = 7 and cTAXPAYS.STATE =0 then    -- доход ФСС
       nTAXBASE_FSS := nTAXBASE_FSS + cTAXPAYS.SUMME - cTAXPAYS.DISCOUNTSUMM;
     elsif cTAXPAYS.TAXBASE = 7 and cTAXPAYS.STATE =2 then    -- налог ФСС
        nTAX_FSS := nTAX_FSS + cTAXPAYS.SUMME;
     end if;
  end loop;
  nTAXBASE_PFR   := greatest(nTAXBASE_PFR ,nMAXVAL);
  nTAXBASE_FSS   := greatest(nTAXBASE_FSS ,nMAXVAL);
  nTAXBASE_FFOMS := greatest(nTAXBASE_FFOMS ,nMAXVAL);
  nTAXBASE_TFOMS := greatest(nTAXBASE_TFOMS ,nMAXVAL);
end;

procedure INSERT_SCALE
(
 aSCALE     in t_ASCALE,
 aTAX       in t_ATAXSUM,
 aTAXITO    in t_ATAXSUM,
 n2005      in number default 0       -- признак отчета за 2005 год
)
as
begin
insert into SLCST_SCALE
(
 RN,
 AUTHID,
 NAME,
 CODE,
 BASE_PFR,
 BASE_FSS,
 BASE_FFOMS,
 PERSENT_PFR,
 PERSENT_FSS,
 PERSENT_FFOMS,
 PERSENT_TFOMS,
 TAX_PFR,
 TAX_FSS,
 TAX_FFOMS,
 TAX_TFOMS,
 QUANTITY_PFR,
 QUANTITY_FSS,
 QUANTITY_FFOMS
)
values
(
 1,
 user,
 decode(n2005,0,'До 100 000 руб.',1,'До 280 000 руб.'),
 '010',
 round(aTAX_PFRITO(1).BASESUMM,0),
 round(aTAX_FSSITO(1).BASESUMM,0),
 round(aTAX_FFOMSITO(1).BASESUMM,0),
 aTAX_PFRITO(1).PERCENT,
 aTAX_FSSITO(1).PERCENT,
 aTAX_FFOMSITO(1).PERCENT,
 aTAX_TFOMSITO(1).PERCENT,
 round(aTAX_PFRITO(1).TAXSUMM,0),
 round(aTAX_FSSITO(1).TAXSUMM,0),
 round(aTAX_FFOMSITO(1).TAXSUMM,0),
 round(aTAX_TFOMSITO(1).TAXSUMM,0),
 aTAX_PFRITO(1).NUMB,
 aTAX_FSSITO(1).NUMB,
 aTAX_FFOMSITO(1).NUMB
);
insert into SLCST_SCALE
(
 RN,
 AUTHID,
 NAME,
 CODE,
 BASE_PFR,
 BASE_FSS,
 BASE_FFOMS,
 PERSENT_PFR,
 PERSENT_FSS,
 PERSENT_FFOMS,
 PERSENT_TFOMS,
 TAX_PFR,
 TAX_FSS,
 TAX_FFOMS,
 TAX_TFOMS,
 QUANTITY_PFR,
 QUANTITY_FSS,
 QUANTITY_FFOMS
)
values
(
 1,
 user,
 decode(n2005,0,'От 100 001 руб. до 300 000 руб.,   в том числе:',1,'От 280 001 руб. до 600 000 руб.,   в том числе:'),
 '020',
 round(aTAX_PFRITO(2).BASESUMM,0),
 round(aTAX_FSSITO(2).BASESUMM,0),
 round(aTAX_FFOMSITO(2).BASESUMM,0),
 -100,                   -- ставка - X
 -100,
 -100,
 -100,
 round(aTAX_PFRITO(2).TAXSUMM,0),
 round(aTAX_FSSITO(2).TAXSUMM,0),
 round(aTAX_FFOMSITO(2).TAXSUMM,0),
 round(aTAX_TFOMSITO(2).TAXSUMM,0),
 aTAX_PFRITO(2).NUMB,
 aTAX_FSSITO(2).NUMB,
 aTAX_FFOMSITO(2).NUMB
);
insert into SLCST_SCALE
(
 RN,
 AUTHID,
 NAME,
 CODE,
 BASE_PFR,
 BASE_FSS,
 BASE_FFOMS,
 PERSENT_PFR,
 PERSENT_FSS,
 PERSENT_FFOMS,
 PERSENT_TFOMS,
 TAX_PFR,
 TAX_FSS,
 TAX_FFOMS,
 TAX_TFOMS,
 QUANTITY_PFR,
 QUANTITY_FSS,
 QUANTITY_FFOMS
)
values
(
 1,
 user,
 decode(n2005,0,'100 000 руб.',1,'280 000 руб.'),
 '021',
 round(aTAX_PFRITO(2).BASESUMM-aTAX_PFR(2).BASESUMM,0),
 round(aTAX_FSSITO(2).BASESUMM-aTAX_FSS(2).BASESUMM,0),
 round(aTAX_FFOMSITO(2).BASESUMM-aTAX_FFOMS(2).BASESUMM,0),
 aTAX_PFRITO(2).SCALESUMM,
 aTAX_FSSITO(2).SCALESUMM,
 aTAX_FFOMSITO(2).SCALESUMM,
 aTAX_TFOMSITO(2).SCALESUMM,
 round(aTAX_PFRITO(2).TAXSUMM - aTAX_PFR(2).TAXSUMM,0),
 round(aTAX_FSSITO(2).TAXSUMM - aTAX_FSS(2).TAXSUMM,0),
 round(aTAX_FFOMSITO(2).TAXSUMM - aTAX_FFOMS(2).TAXSUMM,0),
 round(aTAX_TFOMSITO(2).TAXSUMM - aTAX_TFOMS(2).TAXSUMM,0),
 aTAX_PFRITO(2).NUMB,
 aTAX_FSSITO(2).NUMB,
 aTAX_FFOMSITO(2).NUMB
);
insert into SLCST_SCALE
(
 RN,
 AUTHID,
 NAME,
 CODE,
 BASE_PFR,
 BASE_FSS,
 BASE_FFOMS,
 PERSENT_PFR,
 PERSENT_FSS,
 PERSENT_FFOMS,
 PERSENT_TFOMS,
 TAX_PFR,
 TAX_FSS,
 TAX_FFOMS,
 TAX_TFOMS,
 QUANTITY_PFR,
 QUANTITY_FSS,
 QUANTITY_FFOMS
)
values
(
 1,
 user,
 decode(n2005,0,'сумма, превышающая 100 000 руб.',1,'сумма, превышающая 280 000 руб.'),
 '022',
 round(aTAX_PFR(2).BASESUMM,0),
 round(aTAX_FSS(2).BASESUMM,0),
 round(aTAX_FFOMS(2).BASESUMM,0),
 aTAX_PFRITO(2).PERCENT,
 aTAX_FSSITO(2).PERCENT,
 aTAX_FFOMSITO(2).PERCENT,
 aTAX_TFOMSITO(2).PERCENT,
 round(aTAX_PFR(2).TAXSUMM,0),
 round(aTAX_FSS(2).TAXSUMM,0),
 round(aTAX_FFOMS(2).TAXSUMM,0),
 round(aTAX_TFOMS(2).TAXSUMM,0),
 -100,
 -100,
 -100
);
insert into SLCST_SCALE
(
 RN,
 AUTHID,
 NAME,
 CODE,
 BASE_PFR,
 BASE_FSS,
 BASE_FFOMS,
 PERSENT_PFR,
 PERSENT_FSS,
 PERSENT_FFOMS,
 PERSENT_TFOMS,
 TAX_PFR,
 TAX_FSS,
 TAX_FFOMS,
 TAX_TFOMS,
 QUANTITY_PFR,
 QUANTITY_FSS,
 QUANTITY_FFOMS
)
values
(
 1,
 user,
 decode(n2005,0,'От 300 001 руб. до 600 000 руб.,   в том числе:',1,'Cвыше 600 000 руб.,   в том числе:'),
 '030',
  round(aTAX_PFRITO(3).BASESUMM,0),
  round(aTAX_FSSITO(3).BASESUMM,0),
  round(aTAX_FFOMSITO(3).BASESUMM,0),
  -100,
  -100,
  -100,
  -100,
 round(aTAX_PFRITO(3).TAXSUMM,0),
 round(aTAX_FSSITO(3).TAXSUMM,0),
 round(aTAX_FFOMSITO(3).TAXSUMM,0),
 round(aTAX_TFOMSITO(3).TAXSUMM,0),
 aTAX_PFRITO(3).NUMB,
 aTAX_FSSITO(3).NUMB,
 aTAX_FFOMSITO(3).NUMB
);
insert into SLCST_SCALE
(
 RN,
 AUTHID,
 NAME,
 CODE,
 BASE_PFR,
 BASE_FSS,
 BASE_FFOMS,
 PERSENT_PFR,
 PERSENT_FSS,
 PERSENT_FFOMS,
 PERSENT_TFOMS,
 TAX_PFR,
 TAX_FSS,
 TAX_FFOMS,
 TAX_TFOMS,
 QUANTITY_PFR,
 QUANTITY_FSS,
 QUANTITY_FFOMS
)
values
(
 1,
 user,
 decode(n2005,0,'300 000 руб.',1,'600 000 руб.'),
 '031',
  round(aTAX_PFRITO(3).BASESUMM - aTAX_PFR(3).BASESUMM,0),
  round(aTAX_FSSITO(3).BASESUMM - aTAX_FSS(3).BASESUMM,0),
  round(aTAX_FFOMSITO(3).BASESUMM - aTAX_FFOMS(3).BASESUMM,0),
  aTAX_PFRITO(3).SCALESUMM,
  aTAX_FSSITO(3).SCALESUMM,
  aTAX_FFOMSITO(3).SCALESUMM,
  aTAX_TFOMSITO(3).SCALESUMM,
  round(aTAX_PFRITO(3).TAXSUMM - aTAX_PFR(3).TAXSUMM,0),
  round(aTAX_FSSITO(3).TAXSUMM - aTAX_FSS(3).TAXSUMM,0),
  round(aTAX_FFOMSITO(3).TAXSUMM - aTAX_FFOMS(3).TAXSUMM,0),
  round(aTAX_TFOMSITO(3).TAXSUMM - aTAX_TFOMS(3).TAXSUMM,0),
  aTAX_PFRITO(3).NUMB,
  aTAX_FSSITO(3).NUMB,
  aTAX_FFOMSITO(3).NUMB
);
insert into SLCST_SCALE
(
 RN,
 AUTHID,
 NAME,
 CODE,
 BASE_PFR,
 BASE_FSS,
 BASE_FFOMS,
 PERSENT_PFR,
 PERSENT_FSS,
 PERSENT_FFOMS,
 PERSENT_TFOMS,
 TAX_PFR,
 TAX_FSS,
 TAX_FFOMS,
 TAX_TFOMS,
 QUANTITY_PFR,
 QUANTITY_FSS,
 QUANTITY_FFOMS
)
values
(
 1,
 user,
 decode(n2005,0,'сумма, превышающая 300 000 руб.',1,'сумма, превышающая 600 000 руб.'),
 '032',
 round(aTAX_PFR(3).BASESUMM,0),
 round(aTAX_FSS(3).BASESUMM,0),
 round(aTAX_FFOMS(3).BASESUMM,0),
 aTAX_PFRITO(3).PERCENT,
 aTAX_FSSITO(3).PERCENT,
 aTAX_FFOMSITO(3).PERCENT,
 aTAX_TFOMSITO(3).PERCENT,
 round(aTAX_PFR(3).TAXSUMM,0),
 round(aTAX_FSS(3).TAXSUMM,0),
 round(aTAX_FFOMS(3).TAXSUMM,0),
 round(aTAX_TFOMS(3).TAXSUMM,0),
 -100,
 -100,
 -100
);
if n2005 = 0 then
   insert into SLCST_SCALE
   (
    RN,
    AUTHID,
    NAME,
    CODE,
    BASE_PFR,
    BASE_FSS,
    BASE_FFOMS,
    PERSENT_PFR,
    PERSENT_FSS,
    PERSENT_FFOMS,
    PERSENT_TFOMS,
    TAX_PFR,
    TAX_FSS,
    TAX_FFOMS,
    TAX_TFOMS,
    QUANTITY_PFR,
    QUANTITY_FSS,
    QUANTITY_FFOMS
   )
   values
   (
    1,
    user,
    'Cвыше 600 000 руб.,   в том числе:',
    '040',
    round(aTAX_PFRITO(4).BASESUMM,0),
    round(aTAX_FSSITO(4).BASESUMM,0),
    round(aTAX_FFOMSITO(4).BASESUMM,0),
    0,
    0,
    0,
    0,
    round(aTAX_PFRITO(4).TAXSUMM,0),
    round(aTAX_FSSITO(4).TAXSUMM,0),
    round(aTAX_FFOMSITO(4).TAXSUMM,0),
    round(aTAX_TFOMSITO(4).TAXSUMM,0),
    aTAX_PFRITO(4).NUMB,
    aTAX_FSSITO(4).NUMB,
    aTAX_FFOMSITO(4).NUMB
   );
   insert into SLCST_SCALE
   (
    RN,
    AUTHID,
    NAME,
    CODE,
    BASE_PFR,
    BASE_FSS,
    BASE_FFOMS,
    PERSENT_PFR,
    PERSENT_FSS,
    PERSENT_FFOMS,
    PERSENT_TFOMS,
    TAX_PFR,
    TAX_FSS,
    TAX_FFOMS,
    TAX_TFOMS,
    QUANTITY_PFR,
    QUANTITY_FSS,
    QUANTITY_FFOMS
   )
   values
   (
    1,
    user,
    '600 000 руб.',
    '041',
    round(aTAX_PFRITO(4).BASESUMM - aTAX_PFR(4).BASESUMM,0),
    round(aTAX_FSSITO(4).BASESUMM - aTAX_FSS(4).BASESUMM,0),
    round(aTAX_FFOMSITO(4).BASESUMM - aTAX_FFOMS(4).BASESUMM,0),
    aTAX_PFRITO(4).SCALESUMM,
    -100,
    -100,
    -100,
    round(aTAX_PFRITO(4).TAXSUMM - aTAX_PFR(4).TAXSUMM,0),
    round(aTAX_FSSITO(4).TAXSUMM - aTAX_FSS(4).TAXSUMM,0),
    round(aTAX_FFOMSITO(4).TAXSUMM - aTAX_FFOMS(4).TAXSUMM,0),
    round(aTAX_TFOMSITO(4).TAXSUMM - aTAX_TFOMS(4).TAXSUMM,0),
    aTAX_PFRITO(4).NUMB,
    aTAX_FSSITO(4).NUMB,
    aTAX_FFOMSITO(4).NUMB
   );
   insert into SLCST_SCALE
   (
    RN,
    AUTHID,
    NAME,
    CODE,
    BASE_PFR,
    BASE_FSS,
    BASE_FFOMS,
    PERSENT_PFR,
    PERSENT_FSS,
    PERSENT_FFOMS,
    PERSENT_TFOMS,
    TAX_PFR,
    TAX_FSS,
    TAX_FFOMS,
    TAX_TFOMS,
    QUANTITY_PFR,
    QUANTITY_FSS,
    QUANTITY_FFOMS
   )
   values
   (
    1,
    user,
    'сумма, превышающая 600 000 руб.',
    '042',
    round(aTAX_PFR(4).BASESUMM,0),
    round(aTAX_FSS(4).BASESUMM,0),
    round(aTAX_FFOMS(4).BASESUMM,0),
    aTAX_PFRITO(4).PERCENT,
    -100,
    -100,
    -100,
    round(aTAX_PFR(4).TAXSUMM,0),
    round(aTAX_FSS(4).TAXSUMM,0),
    round(aTAX_FFOMS(4).TAXSUMM,0),
    round(aTAX_TFOMS(4).TAXSUMM,0),
    -100,
    -100,
    -100
   );
end if;
insert into SLCST_SCALE
(
 RN,
 AUTHID,
 NAME,
 CODE,
 BASE_PFR,
 BASE_FSS,
 BASE_FFOMS,
 PERSENT_PFR,
 PERSENT_FSS,
 PERSENT_FFOMS,
 PERSENT_TFOMS,
 TAX_PFR,
 TAX_FSS,
 TAX_FFOMS,
 TAX_TFOMS,
 QUANTITY_PFR,
 QUANTITY_FSS,
 QUANTITY_FFOMS
)
values
(
 1,
 user,
 decode(n2005,0,'ИТОГО:',1,'ИТОГО: (стр.010 + стр. 020 + стр. 030)'),
 decode(n2005,0,'050',1,'040'),
 round(aTAX_PFRITO(1).BASESUMM,0)   + round(aTAX_PFRITO(2).BASESUMM,0)   + round(aTAX_PFRITO(3).BASESUMM,0)   + round(aTAX_PFRITO(4).BASESUMM,0),
 round(aTAX_FSSITO(1).BASESUMM,0)   + round(aTAX_FSSITO(2).BASESUMM,0)   + round(aTAX_FSSITO(3).BASESUMM,0)   + round(aTAX_FSSITO(4).BASESUMM,0),
 round(aTAX_FFOMSITO(1).BASESUMM,0) + round(aTAX_FFOMSITO(2).BASESUMM,0) + round(aTAX_FFOMSITO(3).BASESUMM,0) + round(aTAX_FFOMSITO(4).BASESUMM,0),
 -100,
 -100,
 -100,
 -100,
 round(aTAX_PFRITO(1).TAXSUMM,0)   + round(aTAX_PFRITO(2).TAXSUMM,0)   + round(aTAX_PFRITO(3).TAXSUMM,0)   + round(aTAX_PFRITO(4).TAXSUMM,0),
 round(aTAX_FSSITO(1).TAXSUMM,0)   + round(aTAX_FSSITO(2).TAXSUMM,0)   + round(aTAX_FSSITO(3).TAXSUMM,0)   + round(aTAX_FSSITO(4).TAXSUMM,0),
 round(aTAX_FFOMSITO(1).TAXSUMM,0) + round(aTAX_FFOMSITO(2).TAXSUMM,0) + round(aTAX_FFOMSITO(3).TAXSUMM,0) + round(aTAX_FFOMSITO(4).TAXSUMM,0),
 round(aTAX_TFOMSITO(1).TAXSUMM,0) + round(aTAX_TFOMSITO(2).TAXSUMM,0) + round(aTAX_TFOMSITO(3).TAXSUMM,0) + round(aTAX_TFOMSITO(4).TAXSUMM,0),
 aTAX_PFRITO(1).NUMB + aTAX_PFRITO(2).NUMB + aTAX_PFRITO(3).NUMB + aTAX_PFRITO(4).NUMB,
 aTAX_FSSITO(1).NUMB + aTAX_FSSITO(2).NUMB + aTAX_FSSITO(3).NUMB + aTAX_FSSITO(4).NUMB,
 aTAX_FFOMSITO(1).NUMB + aTAX_FFOMSITO(2).NUMB + aTAX_FFOMSITO(3).NUMB + aTAX_FFOMSITO(4).NUMB
);
end;
begin
 nMONTHBEGIN := D_MONTH(dPERIODBEGIN);
 nMONTHEND   := D_MONTH(dPERIODEND);
 SET_VALUES;
  /* инициализация массивов */
  /* налоговые шкалы */
  for i in 1..4
  loop
      aSCALE_PFR.EXTEND;
      aSCALE_PFR(i).INCOME:=0;
      aSCALE_PFR(i).SUMM:=0;
      aSCALE_PFR(i).PERCENT:=0;

      aSCALE_FSS.EXTEND;
      aSCALE_FSS(i).INCOME:=0;
      aSCALE_FSS(i).SUMM:=0;
      aSCALE_FSS(i).PERCENT:=0;

      aSCALE_FFOMS.EXTEND;
      aSCALE_FFOMS(i).INCOME:=0;
      aSCALE_FFOMS(i).SUMM:=0;
      aSCALE_FFOMS(i).PERCENT:=0;

      aSCALE_TFOMS.EXTEND;
      aSCALE_TFOMS(i).INCOME:=0;
      aSCALE_TFOMS(i).SUMM:=0;
      aSCALE_TFOMS(i).PERCENT:=0;

      aTAX_PFR.EXTEND;
      aTAX_PFR(i).BASESUMM   :=0;
      aTAX_PFR(i).TAXSUMM    :=0;
      aTAX_PFR(i).NUMB       :=0;
      aTAX_PFR(i).SCALESUMM  :=0;
      aTAX_PFR(i).PERCENT    :=0;

      aTAX_FSS.EXTEND;
      aTAX_FSS(i).BASESUMM   :=0;
      aTAX_FSS(i).TAXSUMM    :=0;
      aTAX_FSS(i).NUMB       :=0;
      aTAX_FSS(i).SCALESUMM  :=0;
      aTAX_FSS(i).PERCENT    :=0;

      aTAX_FFOMS.EXTEND;
      aTAX_FFOMS(i).BASESUMM   :=0;
      aTAX_FFOMS(i).TAXSUMM    :=0;
      aTAX_FFOMS(i).NUMB       :=0;
      aTAX_FFOMS(i).SCALESUMM  :=0;
      aTAX_FFOMS(i).PERCENT    :=0;

      aTAX_TFOMS.EXTEND;
      aTAX_TFOMS(i).BASESUMM   :=0;
      aTAX_TFOMS(i).TAXSUMM    :=0;
      aTAX_TFOMS(i).NUMB       :=0;
      aTAX_TFOMS(i).SCALESUMM  :=0;
      aTAX_TFOMS(i).PERCENT    :=0;

      aTAX_PFRITO.EXTEND;
      aTAX_PFRITO(i).BASESUMM   :=0;
      aTAX_PFRITO(i).TAXSUMM    :=0;
      aTAX_PFRITO(i).NUMB       :=0;
      aTAX_PFRITO(i).SCALESUMM  :=0;
      aTAX_PFRITO(i).PERCENT    :=0;

      aTAX_FSSITO.EXTEND;
      aTAX_FSSITO(i).BASESUMM   :=0;
      aTAX_FSSITO(i).TAXSUMM    :=0;
      aTAX_FSSITO(i).NUMB       :=0;
      aTAX_FSSITO(i).SCALESUMM  :=0;
      aTAX_FSSITO(i).PERCENT    :=0;

      aTAX_FFOMSITO.EXTEND;
      aTAX_FFOMSITO(i).BASESUMM   :=0;
      aTAX_FFOMSITO(i).TAXSUMM    :=0;
      aTAX_FFOMSITO(i).NUMB       :=0;
      aTAX_FFOMSITO(i).SCALESUMM  :=0;
      aTAX_FFOMSITO(i).PERCENT    :=0;

      aTAX_TFOMSITO.EXTEND;
      aTAX_TFOMSITO(i).BASESUMM   :=0;
      aTAX_TFOMSITO(i).TAXSUMM    :=0;
      aTAX_TFOMSITO(i).NUMB       :=0;
      aTAX_TFOMSITO(i).SCALESUMM  :=0;
      aTAX_TFOMSITO(i).PERCENT    :=0;

   end loop;
 /* заполнение шкал */
  PKG_SLCST.GET_SCALE(aSCALE_PFR,dPERIODEND,nTAXSCALE_PFR);
  PKG_SLCST.GET_SCALE(aSCALE_FSS,dPERIODEND,nTAXSCALE_FSS);
  PKG_SLCST.GET_SCALE(aSCALE_FFOMS,dPERIODEND,nTAXSCALE_FFOMS);
  PKG_SLCST.GET_SCALE(aSCALE_TFOMS,dPERIODEND,nTAXSCALE_TFOMS);
 /* список сотрудников выбранного подразделения */
 if nDEPARTMENT is null and nCLNPSPFMFGRP is null then               -- вся организация
    for cTAX in
    (
     Select CP.PERSRN,
            TC.RN as CLNPERSTAXACC
       from CLNPSPFM CP,
           CLNPERSTAXACC TC
       where CP.PERSRN = TC.PRN
         and CP.COMPANY = nCOMPANY
         and TC.TYPE = 0
         and TC.YEAR = nYEAR
       group by CP.PERSRN,TC.RN
      )
      loop
        SET_VALUES;
        GET_SUMM(cTAX.CLNPERSTAXACC);
        PKG_SLCST.GET_TAXSUMM(aSCALE_PFR,aTAX_PFR,aTAX_PFRITO,nTAXBASE_PFR,nTAX_PFR,nDEDUCT_PFR);
        PKG_SLCST.GET_TAXSUMM(aSCALE_FSS,aTAX_FSS,aTAX_FSSITO,nTAXBASE_FSS,nTAX_FSS,nDEDUCT_FSS);
        PKG_SLCST.GET_TAXSUMM(aSCALE_FFOMS,aTAX_FFOMS,aTAX_FFOMSITO,nTAXBASE_FFOMS,nTAX_FFOMS,nDEDUCT_FFOMS);
        PKG_SLCST.GET_TAXSUMM(aSCALE_TFOMS,aTAX_TFOMS,aTAX_TFOMSITO,nTAXBASE_TFOMS,nTAX_TFOMS,nDEDUCT_TFOMS);
      end loop;
  elsif nDEPARTMENT is not null and nCHILDDEP=1 then      -- включать все подчиненные подразделения
      for cTAX in
      (
       Select CP.PERSRN,
              TC.RN as CLNPERSTAXACC
         from CLNPSPFM CP,
              CLNPERSTAXACC TC
         where CP.PERSRN = TC.PRN
           and CP.DEPTRN in (Select RN from INS_DEPARTMENT start with rn = nDEPARTMENT  connect by prior RN=PRN)
           and TC.TYPE = 0
           and TC.YEAR = nYEAR
         group by CP.PERSRN,TC.RN
      )
      loop
        SET_VALUES;
        GET_SUMM(cTAX.CLNPERSTAXACC);
        PKG_SLCST.GET_TAXSUMM(aSCALE_PFR,aTAX_PFR,aTAX_PFRITO,nTAXBASE_PFR,nTAX_PFR,nDEDUCT_PFR);
        PKG_SLCST.GET_TAXSUMM(aSCALE_FSS,aTAX_FSS,aTAX_FSSITO,nTAXBASE_FSS,nTAX_FSS,nDEDUCT_FSS);
        PKG_SLCST.GET_TAXSUMM(aSCALE_FFOMS,aTAX_FFOMS,aTAX_FFOMSITO,nTAXBASE_FFOMS,nTAX_FFOMS,nDEDUCT_FFOMS);
        PKG_SLCST.GET_TAXSUMM(aSCALE_TFOMS,aTAX_TFOMS,aTAX_TFOMSITO,nTAXBASE_TFOMS,nTAX_TFOMS,nDEDUCT_TFOMS);
      end loop;
  elsif nDEPARTMENT is not null and nCHILDDEP=0 then
      for cTAX in
      (
       Select CP.PERSRN,
              TC.RN as CLNPERSTAXACC
         from CLNPSPFM CP,
              CLNPERSTAXACC TC
         where CP.PERSRN = TC.PRN
           and CP.DEPTRN = nDEPARTMENT
           and TC.TYPE = 0
           and TC.YEAR = nYEAR
         group by CP.PERSRN,TC.RN
      )
      loop
        SET_VALUES;
        GET_SUMM(cTAX.CLNPERSTAXACC);
        PKG_SLCST.GET_TAXSUMM(aSCALE_PFR,aTAX_PFR,aTAX_PFRITO,nTAXBASE_PFR,nTAX_PFR,nDEDUCT_PFR);
        PKG_SLCST.GET_TAXSUMM(aSCALE_FSS,aTAX_FSS,aTAX_FSSITO,nTAXBASE_FSS,nTAX_FSS,nDEDUCT_FSS);
        PKG_SLCST.GET_TAXSUMM(aSCALE_FFOMS,aTAX_FFOMS,aTAX_FFOMSITO,nTAXBASE_FFOMS,nTAX_FFOMS,nDEDUCT_FFOMS);
        PKG_SLCST.GET_TAXSUMM(aSCALE_TFOMS,aTAX_TFOMS,aTAX_TFOMSITO,nTAXBASE_TFOMS,nTAX_TFOMS,nDEDUCT_TFOMS);
      end loop;
 elsif nDEPARTMENT is null and nCLNPSPFMFGRP is not null then
      for cTAX in
      (
       Select CP.PERSRN,
              TC.RN as CLNPERSTAXACC
         from CLNPSPFMFGRPSP CPS,
              CLNPSPFM CP,
              CLNPERSTAXACC TC,
              CLNPERSONS CN
         where CPS.CLNPSPFM = CP.RN
           and CP.PERSRN = TC.PRN
           and CP.PERSRN = CN.RN
           and CPS.PRN = nCLNPSPFMFGRP
           and TC.TYPE = 0
           and TC.YEAR = nYEAR
         group by CP.PERSRN, TC.RN
      )
      loop
        SET_VALUES;
        GET_SUMM(cTAX.CLNPERSTAXACC);
        PKG_SLCST.GET_TAXSUMM(aSCALE_PFR,aTAX_PFR,aTAX_PFRITO,nTAXBASE_PFR,nTAX_PFR,nDEDUCT_PFR);
        PKG_SLCST.GET_TAXSUMM(aSCALE_FSS,aTAX_FSS,aTAX_FSSITO,nTAXBASE_FSS,nTAX_FSS,nDEDUCT_FSS);
        PKG_SLCST.GET_TAXSUMM(aSCALE_FFOMS,aTAX_FFOMS,aTAX_FFOMSITO,nTAXBASE_FFOMS,nTAX_FFOMS,nDEDUCT_FFOMS);
        PKG_SLCST.GET_TAXSUMM(aSCALE_TFOMS,aTAX_TFOMS,aTAX_TFOMSITO,nTAXBASE_TFOMS,nTAX_TFOMS,nDEDUCT_TFOMS);
      end loop;
 end if;
 INSERT_SCALE(aSCALE_PFR,aTAX_PFR,aTAX_PFRITO,n2005);

end SCALE_CREATE;

/* Расчет права на применение регрессивной шкалы */
procedure REGRESS_CREATE
(
 nCOMPANY       in number,
 nDEPARTMENT    in varchar2,                  -- подразделение
 nYEAR          in number,
 dPERIODBEGIN   in date,
 dPERIODEND     in date,
 nCHILDDEP      in number,                    -- признак учитывать все подчиненные подразделения
 nNEGOTIVE      in number,                    -- отриц налог. база
 nSTATESNOTFULL in number,                    -- состояние ИД, указывающее на работу неполный рабочий день
 sSTATESVAK     in varchar2,
 nMAXPROP       in varchar2,                  -- свойство сотрудника, определяющее, что он относится к категории наиболее высокооплачиваемых
 sMAXVALUE      in varchar2,                  -- значение свойства
 nUSEENVD       in number default 0,          -- применяется ЕНВД
 nAVG1          in number default 0,          -- средняя численность за 1 месяц последнего квартала
 nAVG2          in number default 0,          -- средняя численность за 2 месяц последнего квартала
 nAVG3          in number default 0           -- средняя численность за 3 месяц последнего квартала
)
as
 nAVG_QUANTITY1        PKG_STD.tLCOEFF;
 nAVG_QUANTITY2        PKG_STD.tLCOEFF;
 nAVG_QUANTITY3        PKG_STD.tLCOEFF;
 nSUM_CHARGES1         SLCST_REGRESS.SUM_CHARGES1%TYPE;
 nSUM_CHARGES2         SLCST_REGRESS.SUM_CHARGES2%TYPE;
 nSUM_CHARGES3         SLCST_REGRESS.SUM_CHARGES3%TYPE;
 nMAX_QUANTITY1        SLCST_REGRESS.MAX_QUANTITY1%TYPE;
 nMAX_QUANTITY2        SLCST_REGRESS.MAX_QUANTITY2%TYPE;
 nMAX_QUANTITY3        SLCST_REGRESS.MAX_QUANTITY3%TYPE;
 nMAX_SUMCHARGES1      SLCST_REGRESS.MAX_SUMCHARGES1%TYPE;
 nMAX_SUMCHARGES2      SLCST_REGRESS.MAX_SUMCHARGES2%TYPE;
 nMAX_SUMCHARGES3      SLCST_REGRESS.MAX_SUMCHARGES3%TYPE;
 nSUM_BASE1            SLCST_REGRESS.SUM_BASE1%TYPE;
 nSUM_BASE2            SLCST_REGRESS.SUM_BASE2%TYPE;
 nSUM_BASE3            SLCST_REGRESS.SUM_BASE3%TYPE;
 nAVG_BASE1            SLCST_REGRESS.AVG_BASE1%TYPE;
 nAVG_BASE2            SLCST_REGRESS.AVG_BASE2%TYPE;
 nAVG_BASE3            SLCST_REGRESS.AVG_BASE3%TYPE;
 nMONTH_QUANTITY1      SLCST_REGRESS.MONTH_QUANTITY1%TYPE;
 nMONTH_QUANTITY2      SLCST_REGRESS.MONTH_QUANTITY2%TYPE;
 nMONTH_QUANTITY3      SLCST_REGRESS.MONTH_QUANTITY3%TYPE;
 nAVG_MONTH_BASE1      SLCST_REGRESS.AVG_MONTH_BASE1%TYPE;
 nAVG_MONTH_BASE2      SLCST_REGRESS.AVG_MONTH_BASE2%TYPE;
 nAVG_MONTH_BASE3      SLCST_REGRESS.AVG_MONTH_BASE3%TYPE;
 nMONTHBEGIN          number;
 nMONTHEND            number;
 nMONTH1  number;
 nMONTH2  number;
 nMONTH3  number;
 nRECORD  number;
procedure GET_AVERAGE
/* Расчет средне-списочной численности */
(
 nCOMPANY        in number,
 nCLNPSPFM       in number,
 dPERIODBEGIN    in date,
 dPERIODEND      in date,
 nSTATESNOTFULL  in number,
 sSTATESVAK_     in varchar2
)
as
 nAVG_QUANTITY1_        PKG_STD.tLCOEFF;
 nAVG_QUANTITY2_        PKG_STD.tLCOEFF;
 nAVG_QUANTITY3_        PKG_STD.tLCOEFF;
 dPERIODEND1_           date;
 dPERIODEND2_           date;
 dPERIODEND3_           date;
 nSTATERN               CLNPSPFMST.RN%TYPE;
begin
 nAVG_QUANTITY1_ :=0;
 nAVG_QUANTITY2_ :=0;
 nAVG_QUANTITY3_ :=0;
 dPERIODEND3_ := last_day(dPERIODEND);
 dPERIODEND2_ := add_months(dPERIODEND3_,-1);
 dPERIODEND1_ := add_months(dPERIODEND2_,-1);
 if nSTATESNOTFULL is not null then
   if dPERIODEND1_> dPERIODBEGIN then
      begin
       select CS.RN  into nSTATERN
         from CLNPSPFMST CS
         where CS.PRN = nCLNPSPFM
           and CS.PERFSTATE = nSTATESNOTFULL
           and CS.BEGIN_DATE <= dPERIODEND1_
           and (CS.END_DATE is null or CS.END_DATE>=dPERIODBEGIN);
         exception
          when NO_DATA_FOUND then
           nSTATERN := null;
      end;
      if nSTATERN is not null then                   -- неполный рабочий день по графикам работ
         PKG_CLNPSPFM_AVERAGE.GET_AVERAGE_WORKEDDAYS(nCOMPANY,nCLNPSPFM,dPERIODBEGIN,dPERIODEND1_,1,sSTATESVAK_,1,1,nAVG_QUANTITY1_);
      else                                       -- полный рабочий день по календарным дням
         PKG_CLNPSPFM_AVERAGE.GET_AVERAGE_CALENDAR(nCOMPANY,nCLNPSPFM,dPERIODBEGIN,dPERIODEND1_,1,sSTATESVAK_,1,nAVG_QUANTITY1_);
      end if;
   end if;
   if dPERIODEND2_> dPERIODBEGIN then
      begin
       select CS.RN  into nSTATERN
         from CLNPSPFMST CS
         where CS.PRN = nCLNPSPFM
           and CS.PERFSTATE = nSTATESNOTFULL
           and CS.BEGIN_DATE <= dPERIODEND2_
           and (CS.END_DATE is null or CS.END_DATE>=dPERIODBEGIN);
         exception
          when NO_DATA_FOUND then
           nSTATERN := null;
      end;
      if nSTATERN is not null then                   -- неполный рабочий день по графикам работ
         PKG_CLNPSPFM_AVERAGE.GET_AVERAGE_WORKEDDAYS(nCOMPANY,nCLNPSPFM,dPERIODBEGIN,dPERIODEND2_,1,sSTATESVAK_,1,1,nAVG_QUANTITY2_);
      else                                           -- полный рабочий день по календарным дням
         PKG_CLNPSPFM_AVERAGE.GET_AVERAGE_CALENDAR(nCOMPANY,nCLNPSPFM,dPERIODBEGIN,dPERIODEND2_,1,sSTATESVAK_,1,nAVG_QUANTITY2_);
      end if;
   end if;
   if dPERIODEND3_> dPERIODBEGIN then
      begin
       select CS.RN  into nSTATERN
         from CLNPSPFMST CS
         where CS.PRN = nCLNPSPFM
           and CS.PERFSTATE = nSTATESNOTFULL
           and CS.BEGIN_DATE <= dPERIODEND3_
           and (CS.END_DATE is null or CS.END_DATE>=dPERIODBEGIN);
         exception
          when NO_DATA_FOUND then
           nSTATERN := null;
      end;
      if nSTATERN is not null then                   -- неполный рабочий день по графикам работ
         PKG_CLNPSPFM_AVERAGE.GET_AVERAGE_WORKEDDAYS(nCOMPANY,nCLNPSPFM,dPERIODBEGIN,dPERIODEND3_,1,sSTATESVAK_,1,1,nAVG_QUANTITY3_);
      else                                       -- полный рабочий день по календарным дням
         PKG_CLNPSPFM_AVERAGE.GET_AVERAGE_CALENDAR(nCOMPANY,nCLNPSPFM,dPERIODBEGIN,dPERIODEND3_,1,sSTATESVAK_,1,nAVG_QUANTITY3_);
      end if;
   end if;
 else
    if dPERIODEND1_> dPERIODBEGIN then
       PKG_CLNPSPFM_AVERAGE.GET_AVERAGE_CALENDAR(nCOMPANY,nCLNPSPFM,dPERIODBEGIN,dPERIODEND1_,1,sSTATESVAK_,1,nAVG_QUANTITY1_);
    end if;
    if dPERIODEND2_> dPERIODBEGIN then
       PKG_CLNPSPFM_AVERAGE.GET_AVERAGE_CALENDAR(nCOMPANY,nCLNPSPFM,dPERIODBEGIN,dPERIODEND2_,1,sSTATESVAK_,1,nAVG_QUANTITY2_);
    end if;
    if dPERIODEND3_> dPERIODBEGIN then
       PKG_CLNPSPFM_AVERAGE.GET_AVERAGE_CALENDAR(nCOMPANY,nCLNPSPFM,dPERIODBEGIN,dPERIODEND3_,1,sSTATESVAK_,1,nAVG_QUANTITY3_);
    end if;
 end if;
 nAVG_QUANTITY1 := nAVG_QUANTITY1 + nAVG_QUANTITY1_;
 nAVG_QUANTITY2 := nAVG_QUANTITY2 + nAVG_QUANTITY2_;
 nAVG_QUANTITY3 := nAVG_QUANTITY3 + nAVG_QUANTITY3_;
end;
procedure GET_SUMM
(
 nCLNPERSTAXACC       in number,
 nYEAR                in number,
 nMONTHBEGIN          in number,
 nMONTHEND            in number
)
as
  nTMPVALUE              SLCST_CALC.BASE_PFR%TYPE;
  nSUM_CHARGES1_         SLCST_REGRESS.SUM_CHARGES1%TYPE;
  nSUM_CHARGES2_         SLCST_REGRESS.SUM_CHARGES2%TYPE;
  nSUM_CHARGES3_         SLCST_REGRESS.SUM_CHARGES3%TYPE;
  nBASE                  number;
begin
  nTMPVALUE      := 0;
  nSUM_CHARGES1_ := 0;
  nSUM_CHARGES2_ := 0;
  nSUM_CHARGES3_ := 0;
  if nUSEENVD = 0 then
     nBASE := 4;
  else
     nBASE := 8;
  end if;
  for cTAXPAYS in
 (
   select TC.PRN,
          TP.SLTAXACCS,
          TP.SUMME,
          TP.DISCOUNTSUMM,
          TP.MONTHNUMB,
          TR.TAXBASE,
          TR.STATE,
          TR.POS_CODE,
          TR.PRIVIL,
          TR1.DDCODE
    from CLNPERSTAXACCSP TP,
         CLNPERSTAXACC   TC,
         SLTAXACCS TR,
         SALINDEDUCT TR1
    where TC.RN = TP.PRN
      and TP.SLTAXACCS = TR.RN
      and TR.DEDCODE = TR1.RN (+)
      and TC.RN = nCLNPERSTAXACC
      and TP.MONTHNUMB>=nMONTHBEGIN
      and TP.MONTHNUMB<=nMONTHEND
      and TR.TAXBASE = nBASE
      and TR.STATE = 0
  )
  loop
     nTMPVALUE      := 0;
     if trim(cTAXPAYS.DDCODE) = '1' then
        nTMPVALUE := cTAXPAYS.DISCOUNTSUMM;
     end if;
     if trim(cTAXPAYS.DDCODE) = '2' then
        nTMPVALUE := cTAXPAYS.DISCOUNTSUMM;
     end if;
     if trim(cTAXPAYS.DDCODE) = '3' then
        nTMPVALUE := cTAXPAYS.DISCOUNTSUMM;
     end if;
     if trim(cTAXPAYS.POS_CODE) = '1' and trim(cTAXPAYS.DDCODE) = '4' then
        nTMPVALUE := cTAXPAYS.DISCOUNTSUMM;
     end if;
     if trim(cTAXPAYS.POS_CODE) = '7' then
        nTMPVALUE := cTAXPAYS.SUMME;
     end if;
     if cTAXPAYS.MONTHNUMB <=nMONTH1 then
        nSUM_CHARGES1  := nSUM_CHARGES1+ cTAXPAYS.SUMME - nTMPVALUE;
        nSUM_CHARGES1_ := nSUM_CHARGES1_ + cTAXPAYS.SUMME - nTMPVALUE;
     end if;
     if cTAXPAYS.MONTHNUMB <= nMONTH2 then
        nSUM_CHARGES2  := nSUM_CHARGES2 + cTAXPAYS.SUMME - nTMPVALUE;
        nSUM_CHARGES2_ := nSUM_CHARGES2_ + cTAXPAYS.SUMME - nTMPVALUE;
     end if;
     if cTAXPAYS.MONTHNUMB <= nMONTH3 then
        nSUM_CHARGES3  := nSUM_CHARGES3 + cTAXPAYS.SUMME - nTMPVALUE;
        nSUM_CHARGES3_ := nSUM_CHARGES3_ + cTAXPAYS.SUMME - nTMPVALUE;
     end if;
  end loop;
  /* запись сумм по каждому человеку отдельно */
  insert
    into SLCST_REGRESS
    (
     RN,
     AUTHID,
     SUM_CHARGES1,
     SUM_CHARGES2,
     SUM_CHARGES3
    )
    values
    (
      1,
      user,
      nSUM_CHARGES1_,
      nSUM_CHARGES2_,
      nSUM_CHARGES3_
     );
end;
begin
 nAVG_QUANTITY1 :=0;
 nAVG_QUANTITY2 :=0;
 nAVG_QUANTITY3 :=0;
 nSUM_CHARGES1  :=0;
 nSUM_CHARGES2  :=0;
 nSUM_CHARGES3  :=0;
 nMAX_QUANTITY1 :=0;
 nMAX_QUANTITY2 :=0;
 nMAX_QUANTITY3 :=0;
 nMAX_SUMCHARGES1:=0;
 nMAX_SUMCHARGES2:=0;
 nMAX_SUMCHARGES3:=0;
 nSUM_BASE1:=0;
 nSUM_BASE2:=0;
 nSUM_BASE3:=0;
 nAVG_BASE1:=0;
 nAVG_BASE2:=0;
 nAVG_BASE3:=0;
 nMONTH_QUANTITY1:=0;
 nMONTH_QUANTITY2:=0;
 nMONTH_QUANTITY3:=0;
 nAVG_MONTH_BASE1:=0;
 nAVG_MONTH_BASE2:=0;
 nAVG_MONTH_BASE3:=0;
 nMONTHBEGIN := D_MONTH(dPERIODBEGIN);
 nMONTHEND   := D_MONTH(dPERIODEND);
 nAVG_QUANTITY1 :=0;
 nAVG_QUANTITY2 :=0;
 nAVG_QUANTITY3 :=0;
 nMONTH3 := nMONTHEND;
 nMONTH2 := nMONTH3-1;
 nMONTH1 := nMONTH3-2;
 delete
  from SLCST_REGRESS
  where AUTHID = user;
 /* исполнения для определения среднесписочной численности */
 if nDEPARTMENT is null then                         -- вся организация
    if nAVG1 is null or nAVG2 is null or nAVG3 is null then
       for cTAX in
       (
        select CP.RN,
               TC.RN as CLNPERSTAXACC
          from CLNPSPFM CP,
               CLNPERSTAXACC TC,
               DOCS_PROPS_VALS A,
               DOCS_PROPS B
         where CP.PERSRN = TC.PRN
           and CP.PERSRN = A.UNIT_RN(+)
           and A.DOCS_PROP_RN = B.RN(+)
           and ((nMAXPROP is not null and A.UNITCODE='ClientPersons') or (nMAXPROP is null ))
           and ((nMAXPROP is not null and upper(A.STR_VALUE) = upper(sMAXVALUE) and B.RN = nMAXPROP) or (nMAXPROP is null ))
           and CP.COMPANY = nCOMPANY
           and TC.TYPE = 0
           and TC.YEAR = nYEAR
         group by CP.RN,TC.RN
         )
         loop
           GET_AVERAGE(nCOMPANY,cTAX.RN,dPERIODBEGIN,dPERIODEND,nSTATESNOTFULL,sSTATESVAK);
         end loop;
    end if;
    for cTAX in
    (
     Select CP.PERSRN,
            TC.RN as CLNPERSTAXACC
       from CLNPSPFM CP,
           CLNPERSTAXACC TC,
           DOCS_PROPS_VALS A,
           DOCS_PROPS B
       where CP.PERSRN = TC.PRN
         and CP.PERSRN = A.UNIT_RN(+)
         and A.DOCS_PROP_RN = B.RN(+)
         and ((nMAXPROP is not null and A.UNITCODE='ClientPersons') or (nMAXPROP is null ))
         and ((nMAXPROP is not null and upper(A.STR_VALUE) = upper(sMAXVALUE) and B.RN = nMAXPROP) or (nMAXPROP is null ))
         and CP.COMPANY = nCOMPANY
         and TC.TYPE = 0
         and TC.YEAR = nYEAR
       group by CP.PERSRN,TC.RN
      )
      loop
        GET_SUMM(cTAX.CLNPERSTAXACC,nYEAR,nMONTHBEGIN,nMONTHEND);
      end loop;
  else
   if nCHILDDEP=1 then                              -- включать все подчиненные подразделения
      if nAVG1 is null or nAVG2 is null or nAVG3 is null then
         for cTAX in
         (
         Select CP.RN,
                TC.RN as CLNPERSTAXACC
           from CLNPSPFM CP,
                CLNPERSTAXACC TC,
                DOCS_PROPS_VALS A,
                DOCS_PROPS B
          where CP.PERSRN = TC.PRN
            and CP.PERSRN = A.UNIT_RN(+)
            and A.DOCS_PROP_RN = B.RN(+)
            and ((nMAXPROP is not null and A.UNITCODE='ClientPersons') or (nMAXPROP is null ))
            and ((nMAXPROP is not null and upper(A.STR_VALUE) = upper(sMAXVALUE) and B.RN = nMAXPROP) or (nMAXPROP is null ))
            and CP.DEPTRN in (Select RN from INS_DEPARTMENT start with rn = nDEPARTMENT  connect by prior RN=PRN)
            and TC.TYPE = 0
            and TC.YEAR = nYEAR
          group by CP.RN,TC.RN
          )
          loop
             GET_AVERAGE(nCOMPANY,cTAX.RN,dPERIODBEGIN,dPERIODEND,nSTATESNOTFULL,sSTATESVAK);
          end loop;
       end if;
       for cTAX in
       (
       Select CP.PERSRN,
              TC.RN as CLNPERSTAXACC
         from CLNPSPFM CP,
              CLNPERSTAXACC TC,
              DOCS_PROPS_VALS A,
              DOCS_PROPS B
         where CP.PERSRN = TC.PRN
           and CP.PERSRN = A.UNIT_RN(+)
           and A.DOCS_PROP_RN = B.RN(+)
           and ((nMAXPROP is not null and A.UNITCODE='ClientPersons') or (nMAXPROP is null ))
           and ((nMAXPROP is not null and upper(A.STR_VALUE) = upper(sMAXVALUE) and B.RN = nMAXPROP) or (nMAXPROP is null ))
           and CP.DEPTRN in (Select RN from INS_DEPARTMENT start with rn = nDEPARTMENT  connect by prior RN=PRN)
           and TC.TYPE = 0
           and TC.YEAR = nYEAR
         group by CP.PERSRN,TC.RN
       )
       loop
         GET_SUMM(cTAX.CLNPERSTAXACC,nYEAR,nMONTHBEGIN,nMONTHEND);
       end loop;
   else
      if nAVG1 is null or nAVG2 is null or nAVG3 is null then
         for cTAX in
         (
          select CP.RN,
                 TC.RN as CLNPERSTAXACC
            from CLNPSPFM CP,
                 CLNPERSTAXACC TC,
                 DOCS_PROPS_VALS A,
                 DOCS_PROPS B
           where CP.PERSRN = TC.PRN
             and CP.PERSRN = A.UNIT_RN(+)
             and A.DOCS_PROP_RN = B.RN(+)
             and ((nMAXPROP is not null and A.UNITCODE='ClientPersons') or (nMAXPROP is null ))
             and ((nMAXPROP is not null and upper(A.STR_VALUE) = upper(sMAXVALUE) and B.RN = nMAXPROP) or (nMAXPROP is null ))
             and CP.DEPTRN = nDEPARTMENT
             and TC.TYPE = 0
             and TC.YEAR = nYEAR
           group by CP.RN,TC.RN
          )
          loop
             GET_AVERAGE(nCOMPANY,cTAX.RN,dPERIODBEGIN,dPERIODEND,nSTATESNOTFULL,sSTATESVAK);
          end loop;
       end if;
       for cTAX in
       (
       Select CP.PERSRN,
              TC.RN as CLNPERSTAXACC
         from CLNPSPFM CP,
              CLNPERSTAXACC TC,
              DOCS_PROPS_VALS A,
              DOCS_PROPS B
         where CP.PERSRN = TC.PRN
           and CP.PERSRN = A.UNIT_RN(+)
           and A.DOCS_PROP_RN = B.RN(+)
           and ((nMAXPROP is not null and A.UNITCODE='ClientPersons') or (nMAXPROP is null ))
           and ((nMAXPROP is not null and upper(A.STR_VALUE) = upper(sMAXVALUE) and B.RN = nMAXPROP) or (nMAXPROP is null ))
           and  CP.DEPTRN = nDEPARTMENT
           and TC.TYPE = 0
           and TC.YEAR = nYEAR
         group by CP.PERSRN,TC.RN
       )
       loop
         GET_SUMM(cTAX.CLNPERSTAXACC,nYEAR,nMONTHBEGIN,nMONTHEND);
       end loop;
    end if;
 end if;
 nAVG_QUANTITY1 := nvl(nAVG1,nAVG_QUANTITY1);
 nAVG_QUANTITY2 := nvl(nAVG2,nAVG_QUANTITY2);
 nAVG_QUANTITY3 := nvl(nAVG3,nAVG_QUANTITY3);

 /* 10% (30%) работников, имеющих наибольшие по размеру доходы */
 if nAVG_QUANTITY1 > 30 then
    nMAX_QUANTITY1 := round(nAVG_QUANTITY1 * 0.10,0);
 else
    nMAX_QUANTITY1 := round(nAVG_QUANTITY1 * 0.30,0);
 end if;
 if nAVG_QUANTITY2 > 30 then
    nMAX_QUANTITY2 := round(nAVG_QUANTITY2 * 0.10,0);
 else
    nMAX_QUANTITY2 := round(nAVG_QUANTITY2 * 0.30,0);
 end if;
 if nAVG_QUANTITY3 > 30 then
    nMAX_QUANTITY3 := round(nAVG_QUANTITY3 * 0.10,0);
 else
    nMAX_QUANTITY3 := round(nAVG_QUANTITY3 * 0.30,0);
 end if;
 nAVG_QUANTITY1 := round(nAVG_QUANTITY1,0);
 nAVG_QUANTITY2 := round(nAVG_QUANTITY2,0);
 nAVG_QUANTITY3 := round(nAVG_QUANTITY3,0);
 /* Суммы выплат 10% (30%) работников, имеющих наибольшие по размеру доходы */
 nMAX_SUMCHARGES1 := 0;
 nRECORD := 0;
 for cSUM in
 (
  select SR.SUM_CHARGES1
    from SLCST_REGRESS SR
    where AUTHID = user
    order by SR.SUM_CHARGES1 desc
 )
 loop
   nRECORD := nRECORD + 1;
   if nRECORD <= nMAX_QUANTITY1 then
      nMAX_SUMCHARGES1 := nMAX_SUMCHARGES1 + cSUM.SUM_CHARGES1;
   end if;
 end loop;
 nMAX_SUMCHARGES2 := 0;
 nRECORD := 0;
 for cSUM in
 (
  select SR.SUM_CHARGES2
    from SLCST_REGRESS SR
    where AUTHID = user
    order by SR.SUM_CHARGES2 desc
 )
 loop
   nRECORD := nRECORD + 1;
   if nRECORD <= nMAX_QUANTITY2 then
      nMAX_SUMCHARGES2 := nMAX_SUMCHARGES2 + cSUM.SUM_CHARGES2;
   end if;
 end loop;
 nMAX_SUMCHARGES3 := 0;
 nRECORD := 0;
 for cSUM in
 (
  select SR.SUM_CHARGES3
    from SLCST_REGRESS SR
    where AUTHID = user
    order by SR.SUM_CHARGES3 desc
 )
 loop
   nRECORD := nRECORD + 1;
   if nRECORD <= nMAX_QUANTITY3 then
      nMAX_SUMCHARGES3 := nMAX_SUMCHARGES3 + cSUM.SUM_CHARGES3;
   end if;
 end loop;
 /* налоговая база без учета выплат работникам, имеющим наибольшие по размеру доходы */
 nSUM_BASE1 := nSUM_CHARGES1 - nMAX_SUMCHARGES1;
 nSUM_BASE2 := nSUM_CHARGES2 - nMAX_SUMCHARGES2;
 nSUM_BASE3 := nSUM_CHARGES3 - nMAX_SUMCHARGES3;
 /* налоговая база в среднем на 1 работника (стр. 050 : (стр. 010 – стр. 030)) */
 if (nAVG_QUANTITY1-nMAX_QUANTITY1)>0 then
    nAVG_BASE1 := nSUM_BASE1/(nAVG_QUANTITY1-nMAX_QUANTITY1);
 else
   nAVG_BASE1 := 0;
 end if;
 if (nAVG_QUANTITY2-nMAX_QUANTITY2)>0 then
    nAVG_BASE2 := nSUM_BASE2/(nAVG_QUANTITY2-nMAX_QUANTITY2);
 else
   nAVG_BASE2 := 0;
 end if;
 if (nAVG_QUANTITY3-nMAX_QUANTITY3)>0 then
    nAVG_BASE3 := nSUM_BASE3/(nAVG_QUANTITY3-nMAX_QUANTITY3);
 else
   nAVG_BASE3 := 0;
 end if;
 /* количество месяцев, истекших с начала налогового периода */
 nMONTH_QUANTITY1 := nMONTH1;
 nMONTH_QUANTITY2 := nMONTH2;
 nMONTH_QUANTITY3 := nMONTH3;
 /* налоговая база в среднем на 1 работника, приходящаяся на один месяц в истекшем налоговом периоде */
 if nMONTH1>0 then
   nAVG_MONTH_BASE1 := nAVG_BASE1/nMONTH1;
 end if;
 if nMONTH2>0 then
   nAVG_MONTH_BASE2 := nAVG_BASE2/nMONTH2;
 end if;
 if nMONTH3>0 then
   nAVG_MONTH_BASE3 := nAVG_BASE3/nMONTH3;
 end if;
 /* коррекция */
 if nAVG_MONTH_BASE1<2500 and nMONTH1>0 then
   nAVG_QUANTITY2   := -100;          -- Z
   nSUM_CHARGES2    := -100;
   nMAX_QUANTITY2   := -100;
   nMAX_SUMCHARGES2 := -100;
   nSUM_BASE2       := -100;
   nAVG_BASE2       := -100;
   nMONTH_QUANTITY2 := -100;
   nAVG_QUANTITY3   := -100;        -- Z
   nSUM_CHARGES3    := -100;
   nMAX_QUANTITY3   := -100;
   nMAX_SUMCHARGES3 := -100;
   nSUM_BASE3       := -100;
   nAVG_BASE3       := -100;
   nMONTH_QUANTITY3 := -100;
   nAVG_MONTH_BASE3 := -100;
 end if;
 if nAVG_MONTH_BASE2<2500 and nMONTH2>0 then
   nAVG_QUANTITY3   := -100;        -- Z
   nSUM_CHARGES3    := -100;
   nMAX_QUANTITY3   := -100;
   nMAX_SUMCHARGES3 := -100;
   nSUM_BASE3       := -100;
   nAVG_BASE3       := -100;
   nMONTH_QUANTITY3 := -100;
   nAVG_MONTH_BASE3 := -100;
 end if;
 if nAVG_MONTH_BASE1<2500 and nMONTH1>0 then
    nAVG_MONTH_BASE2 := -100;
 end if;
 delete
  from SLCST_REGRESS
  where AUTHID = user;
 insert
  into SLCST_REGRESS
  (
  RN,
  AUTHID,
  AVG_QUANTITY1,
  AVG_QUANTITY2,
  AVG_QUANTITY3,
  SUM_CHARGES1,
  SUM_CHARGES2,
  SUM_CHARGES3,
  MAX_QUANTITY1,
  MAX_QUANTITY2,
  MAX_QUANTITY3,
  MAX_SUMCHARGES1,
  MAX_SUMCHARGES2,
  MAX_SUMCHARGES3,
  SUM_BASE1,
  SUM_BASE2,
  SUM_BASE3,
  AVG_BASE1,
  AVG_BASE2,
  AVG_BASE3,
  MONTH_QUANTITY1,
  MONTH_QUANTITY2,
  MONTH_QUANTITY3,
  AVG_MONTH_BASE1,
  AVG_MONTH_BASE2,
  AVG_MONTH_BASE3
  )
  values
  (
  1,
  user,
  nAVG_QUANTITY1,
  nAVG_QUANTITY2,
  nAVG_QUANTITY3,
  nSUM_CHARGES1,
  nSUM_CHARGES2,
  nSUM_CHARGES3,
  nMAX_QUANTITY1,
  nMAX_QUANTITY2,
  nMAX_QUANTITY3,
  nMAX_SUMCHARGES1,
  nMAX_SUMCHARGES2,
  nMAX_SUMCHARGES3,
  nSUM_BASE1,
  nSUM_BASE2,
  nSUM_BASE3,
  nAVG_BASE1,
  nAVG_BASE2,
  nAVG_BASE3,
  nMONTH_QUANTITY1,
  nMONTH_QUANTITY2,
  nMONTH_QUANTITY3,
  nAVG_MONTH_BASE1,
  nAVG_MONTH_BASE2,
  nAVG_MONTH_BASE3
  );
end REGRESS_CREATE;


/* Формирование таблицы инвалидов */
   procedure INVALID_CREATE
   (
    nCOMPANY        in number,
    nDEPARTMENT     in varchar2,                       -- подразделение
    nYEAR           in number,
    dPERIODBEGIN    in date,
    dPERIODEND      in date,
    nCHILDDEP       in number,                         -- признак учитывать все подчиненные подразделения
    nNEGOTIVE       in number,
    nCLNPSPFMFGRP   in number default null             -- группа исполнений
   )
  as
    nAGENT            SLCST_INVALID.AGENT%TYPE;        -- инвалид - контрагент ссылка на AGNLIST(rn)
    nDOC_SER          SLCST_INVALID.DOC_SER%TYPE;      -- серия сидетельства по инвалидности
    nDOC_NUMB         SLCST_INVALID.DOC_NUMB%TYPE;     -- номер сидетельства по инвалидности
    nDOC_DATE         SLCST_INVALID.DOC_DATE%TYPE;     -- дата свидетельства
    nINVGROUP          SLCST_INVALID.INVGROUP%TYPE;     -- группа инвалидности
    nDATE_END         SLCST_INVALID.DATE_END%TYPE;     -- дата окончания срока инвалидности
    nINC_PFR          SLCST_INVALID.INC_PFR%TYPE;      -- выплаты инвалидам всего и за три последних месяца
    nINC_PFR1         SLCST_INVALID.INC_PFR1%TYPE;
    nINC_PFR2         SLCST_INVALID.INC_PFR2%TYPE;
    nINC_PFR3         SLCST_INVALID.INC_PFR3%TYPE;
    nINCITO_PFR       SLCST_INVALID.INC_PFR%TYPE;      -- выплаты инвалидам всего и за три последних месяца
    nINCITO_PFR1      SLCST_INVALID.INC_PFR1%TYPE;
    nINCITO_PFR2      SLCST_INVALID.INC_PFR2%TYPE;
    nINCITO_PFR3      SLCST_INVALID.INC_PFR3%TYPE;
    nTYPE             SLCST_INVALID.TYPE%TYPE;
    nMONTHBEGIN number;
    nMONTHEND   number;
    nAGNDISABLED      PKG_STD.tREF;

    procedure GET_SUMM
   (
    nCLNPERSTAXACC       in number,
    nYEAR                in number,
    nMONTHBEGIN          in number,
    nMONTHEND            in number,
    nNEGOTIVE            in number
   )
   as
    nMONTH1     number;
    nMONTH2     number;
    nMONTH3     number;
    nMAXVAL     number;
    nSUM_PFR_   number;
    nSUM_PFR1_  number;
    nSUM_PFR2_  number;
    nSUM_PFR3_  number;
    nDED_PFR_   number;
    nDED_PFR1_  number;
    nDED_PFR2_  number;
    nDED_PFR3_  number;
    begin
     nMONTH3 := nMONTHEND;
     nMONTH2 := nMONTH3-1;
     nMONTH1 := nMONTH3-2;
     if nNEGOTIVE = 1 then
        nMAXVAL:= -9999999999;
     else
        nMAXVAL:= 0;
     end if;
     nSUM_PFR_  :=0;
     nSUM_PFR1_ :=0;
     nSUM_PFR2_ :=0;
     nSUM_PFR3_ :=0;
     nDED_PFR_  :=0;
     nDED_PFR1_ :=0;
     nDED_PFR2_ :=0;
     nDED_PFR3_ :=0;

     for cTAXPAYS in
    (
      select sum(TP.SUMME) as SUMME,
             sum(TP.DISCOUNTSUMM) as DISCOUNTSUMM,
             TR.STATE,
             TP.MONTHNUMB
       from CLNPERSTAXACCSP TP,
            CLNPERSTAXACC   TC,
            SLTAXACCS TR
       where TC.RN = TP.PRN
         and TP.SLTAXACCS = TR.RN
         and TC.RN = nCLNPERSTAXACC
         and TP.MONTHNUMB>=nMONTHBEGIN
         and TP.MONTHNUMB<=nMONTHEND
         and TR.TAXBASE = 4
         and (TR.STATE = 0 or TR.STATE = 1)
         and trim(TR.POS_CODE) <> '7'
        group by TP.MONTHNUMB, TR.STATE
     )
     loop
       if cTAXPAYS.STATE =0 then                    -- доход ПФР
          nSUM_PFR_:= nSUM_PFR_+ cTAXPAYS.SUMME - cTAXPAYS.DISCOUNTSUMM;
          if cTAXPAYS.MONTHNUMB <nMONTH1 then                               -- первый месяц последнего кавартала
             nSUM_PFR1_:= nSUM_PFR1_+ cTAXPAYS.SUMME - cTAXPAYS.DISCOUNTSUMM;
          end if;
          if cTAXPAYS.MONTHNUMB < nMONTH2 then                           -- второй месяц последнего кавартала
             nSUM_PFR2_:= nSUM_PFR2_+ cTAXPAYS.SUMME - cTAXPAYS.DISCOUNTSUMM;
          end if;
          if cTAXPAYS.MONTHNUMB < nMONTH3 then                           -- третий месяц последнего кавартала
             nSUM_PFR3_:= nSUM_PFR3_+ cTAXPAYS.SUMME - cTAXPAYS.DISCOUNTSUMM;
          end if;
       else                                         -- вычет ПФР
          nDED_PFR_:= nDED_PFR_+ cTAXPAYS.SUMME;
          if cTAXPAYS.MONTHNUMB <nMONTH1 then                               -- первый месяц последнего кавартала
             nDED_PFR1_:= nDED_PFR1_+ cTAXPAYS.SUMME;
          end if;
          if cTAXPAYS.MONTHNUMB < nMONTH2 then                           -- второй месяц последнего кавартала
             nDED_PFR2_:= nDED_PFR2_+ cTAXPAYS.SUMME;
          end if;
          if cTAXPAYS.MONTHNUMB < nMONTH3 then                           -- третий месяц последнего кавартала
             nDED_PFR3_:= nDED_PFR3_+ cTAXPAYS.SUMME;
          end if;
       end if;
     end loop;
     /* доход */
     nSUM_PFR_  := greatest(nSUM_PFR_ ,nMAXVAL);
     nSUM_PFR1_ := greatest(nSUM_PFR1_ ,nMAXVAL);
     nSUM_PFR2_ := greatest(nSUM_PFR2_ ,nMAXVAL);
     nSUM_PFR3_ := greatest(nSUM_PFR3_ ,nMAXVAL);

      /* вычет */
     nDED_PFR_   := greatest(least(nDED_PFR_,nSUM_PFR_),0);
     nDED_PFR1_  := greatest(least(nDED_PFR1_,nSUM_PFR1_),0);
     nDED_PFR2_  := greatest(least(nDED_PFR2_,nSUM_PFR2_),0);
     nDED_PFR3_  := greatest(least(nDED_PFR3_,nSUM_PFR3_),0);

     nINC_PFR   := nINC_PFR  +  nDED_PFR_;
     nINC_PFR1  := nINC_PFR1 + (nDED_PFR2_ - nDED_PFR1_);
     nINC_PFR2  := nINC_PFR2 + (nDED_PFR3_ - nDED_PFR2_);
     nINC_PFR3  := nINC_PFR3 + (nDED_PFR_  - nDED_PFR3_);
     /* Итог */
     nINCITO_PFR  := nINCITO_PFR  + nINC_PFR;
     nINCITO_PFR1 := nINCITO_PFR1 + nINC_PFR1;
     nINCITO_PFR2 := nINCITO_PFR2 + nINC_PFR2;
     nINCITO_PFR3 := nINCITO_PFR3 + nINC_PFR3;
     /* округление */
     nINC_PFR   := round(nINC_PFR,0);
     nINC_PFR1  := round(nINC_PFR1,0);
     nINC_PFR2  := round(nINC_PFR2,0);
     nINC_PFR3  := round(nINC_PFR3,0);

     /* Коррекци округления */
     if nMONTHBEGIN=1 and nMONTHEND = 3 then
        delta(nINC_PFR,nINC_PFR1,nINC_PFR2,nINC_PFR3);
     end if;
   end;
   procedure INSERT_REC
   (
     nINC_PFR   in number,
     nINC_PFR1  in number,
     nINC_PFR2  in number,
     nINC_PFR3  in number,
     nTYPE      in number
   )
   as
   begin
    insert
       into SLCST_INVALID
       (
        RN,
        AUTHID,
        AGENT,
        DOC_SER,
        DOC_NUMB,
        DOC_DATE,
        INVGROUP,
        DATE_END,
        INC_PFR,
        INC_PFR1,
        INC_PFR2,
        INC_PFR3,
        TYPE,
        AGNDISABLED
       )
       values
       (
        1,
        user,
        nAGENT,
        nDOC_SER,
        nDOC_NUMB,
        nDOC_DATE,
        nINVGROUP,
        nDATE_END,
        nvl(nINC_PFR,0),
        nvl(nINC_PFR1,0),
        nvl(nINC_PFR2,0),
        nvl(nINC_PFR3,0),
        nvl(nTYPE,0),
        nAGNDISABLED
       );
   end;
   procedure INV_INFO
   (
    nPERSRN     in number,
    nPERS_AGENT in number
   )
   as
   begin
      nAGNDISABLED := null;
      nINVGROUP    := null;
      nDOC_SER     := null;
      nDOC_NUMB    := null;
      nDOC_DATE    := null;
      nDATE_END    := null;
      for rec in
      (
       select RN
         from AGNDISABLED
        where PRN = nPERS_AGENT
         and ( DATEEND  is null or DATEEND >= dPERIODBEGIN)
         and ( DATEBEG <= dPERIODEND)
       order by DATEBEG desc
       )
       loop
         if nAGNDISABLED is null then
            nAGNDISABLED := rec.RN;
         end if;
       end loop;
       /* группа инвалидности */
       PKG_SLCST.GET_PARM('%ИНВАЛИД%', '%ГРУП%',  nPERSRN, nINVGROUP);
       if  nINVGROUP is not null or nAGNDISABLED is not null then
           /* серия */
           PKG_SLCST.GET_PARM('%ИНВАЛИД%', '%СЕР%',   nPERSRN, nDOC_SER);
           /* номер */
           PKG_SLCST.GET_PARM('%ИНВАЛИД%', '%НОМЕР%', nPERSRN, nDOC_NUMB);
           /* дата */
           PKG_SLCST.GET_PARM('%ИНВАЛИД%', '%ДАТАС%',  nPERSRN, nDOC_DATE);
 --          if nDOC_DATE is null then
 --            PKG_SLCST.GET_PARM('%ИНВАЛИД%', '%ДАТА%',  nPERSRN, nDOC_DATE);
 --          end if;
           /* дата окончания инвалидности */
           PKG_SLCST.GET_PARM('%ИНВАЛИД%', '%ДАТАОК%',  nPERSRN, nDATE_END);
       end if;
   end;

   begin
    nINCITO_PFR  := 0;
    nINCITO_PFR1 := 0;
    nINCITO_PFR2 := 0;
    nINCITO_PFR3 := 0;
    nMONTHBEGIN := D_MONTH(dPERIODBEGIN);
    nMONTHEND   := D_MONTH(dPERIODEND);
    if nDEPARTMENT is null and nCLNPSPFMFGRP is null then                        -- вся организация
       for cTAX in
       (
        Select CP.PERSRN,
               TC.RN  CLNPERSTAXACC
          from CLNPSPFM CP,
               CLNPERSTAXACC TC
          where CP.PERSRN = TC.PRN
            and CP.COMPANY = nCOMPANY
            and TC.TYPE = 0
            and TC.YEAR = nYEAR
          group by CP.PERSRN,TC.RN
         )
         loop
          nINC_PFR  :=0;
          nINC_PFR1 :=0;
          nINC_PFR2 :=0;
          nINC_PFR3 :=0;
          begin
            select PERS_AGENT into nAGENT from CLNPERSONS CP where CP.RN = cTAX.PERSRN;
            exception
            when NO_DATA_FOUND then
             null;
          end;
          INV_INFO(cTAX.PERSRN,nAGENT);
          if nAGNDISABLED is not null or nINVGROUP is not null then
             GET_SUMM(cTAX.CLNPERSTAXACC,nYEAR,nMONTHBEGIN,nMONTHEND,nNEGOTIVE);
             INSERT_REC(nINC_PFR,nINC_PFR1,nINC_PFR2,nINC_PFR3,0);
          end if;
         end loop;
     elsif nDEPARTMENT is not null and nCHILDDEP=1 then -- включать все подчиненные подразделения
         for cTAX in
         (
          Select CP.PERSRN,
                 TC.RN as CLNPERSTAXACC
            from CLNPSPFM CP,
                 CLNPERSTAXACC TC
            where CP.PERSRN = TC.PRN
              and CP.DEPTRN in (Select RN from INS_DEPARTMENT start with rn = nDEPARTMENT  connect by prior RN=PRN)
              and TC.TYPE = 0
              and TC.YEAR = nYEAR
            group by CP.PERSRN,TC.RN
         )
         loop
          nINC_PFR  :=0;
          nINC_PFR1 :=0;
          nINC_PFR2 :=0;
          nINC_PFR3 :=0;
          begin
            select PERS_AGENT into nAGENT from CLNPERSONS CP where CP.RN = cTAX.PERSRN;
            exception
            when NO_DATA_FOUND then
             null;
          end;
          INV_INFO(cTAX.PERSRN,nAGENT);
          if nAGNDISABLED is not null or nINVGROUP is not null then
             GET_SUMM(cTAX.CLNPERSTAXACC,nYEAR,nMONTHBEGIN,nMONTHEND,nNEGOTIVE);
             INSERT_REC(nINC_PFR,nINC_PFR1,nINC_PFR2,nINC_PFR3,0);
          end if;
         end loop;
     elsif nDEPARTMENT is not null and nCHILDDEP=0 then    -- без подчиненных подразделений
         for cTAX in
         (
          Select CP.PERSRN,
                 TC.RN as CLNPERSTAXACC
            from CLNPSPFM CP,
                 CLNPERSTAXACC TC
            where CP.PERSRN = TC.PRN
              and CP.DEPTRN = nDEPARTMENT
              and TC.TYPE = 0
              and TC.YEAR = nYEAR
            group by CP.PERSRN,TC.RN
         )
         loop
          nINC_PFR  :=0;
          nINC_PFR1 :=0;
          nINC_PFR2 :=0;
          nINC_PFR3 :=0;
          begin
            select PERS_AGENT into nAGENT from CLNPERSONS CP where CP.RN = cTAX.PERSRN;
            exception
            when NO_DATA_FOUND then
             null;
          end;
          INV_INFO(cTAX.PERSRN,nAGENT);
          if nAGNDISABLED is not null or nINVGROUP is not null then
             GET_SUMM(cTAX.CLNPERSTAXACC,nYEAR,nMONTHBEGIN,nMONTHEND,nNEGOTIVE);
             INSERT_REC(nINC_PFR,nINC_PFR1,nINC_PFR2,nINC_PFR3,0);
          end if;
         end loop;
     elsif nDEPARTMENT is null and nCLNPSPFMFGRP is not null then       -- группа подразделений
      for cTAX in
      (
       Select CP.PERSRN,
              TC.RN as CLNPERSTAXACC
         from CLNPSPFMFGRPSP CPS,
              CLNPSPFM CP,
              CLNPERSTAXACC TC,
              CLNPERSONS CN
         where CPS.CLNPSPFM = CP.RN
           and CP.PERSRN = TC.PRN
           and CP.PERSRN = CN.RN
           and CPS.PRN = nCLNPSPFMFGRP
           and TC.TYPE = 0
           and TC.YEAR = nYEAR
         group by CP.PERSRN,TC.RN
      )
      loop
          nINC_PFR  :=0;
          nINC_PFR1 :=0;
          nINC_PFR2 :=0;
          nINC_PFR3 :=0;
          begin
            select PERS_AGENT into nAGENT from CLNPERSONS CP where CP.RN = cTAX.PERSRN;
            exception
            when NO_DATA_FOUND then
             null;
          end;
          INV_INFO(cTAX.PERSRN,nAGENT);
          if nAGNDISABLED is not null or nINVGROUP is not null then
             GET_SUMM(cTAX.CLNPERSTAXACC,nYEAR,nMONTHBEGIN,nMONTHEND,nNEGOTIVE);
             INSERT_REC(nINC_PFR,nINC_PFR1,nINC_PFR2,nINC_PFR3,0);
          end if;
      end loop;

    end if;
    /* округление */
    nINCITO_PFR   := round(nINCITO_PFR,0);
    nINCITO_PFR1  := round(nINCITO_PFR1,0);
    nINCITO_PFR2  := round(nINCITO_PFR2,0);
    nINCITO_PFR3  := round(nINCITO_PFR3,0);
    if nMONTHBEGIN=1 and nMONTHEND = 3 then
       /* коррекция округления */
       delta(nINCITO_PFR,nINCITO_PFR1,nINCITO_PFR2,nINCITO_PFR3);
    end if;
    INSERT_REC(nINCITO_PFR,nINCITO_PFR1,nINCITO_PFR2,nINCITO_PFR3,1);
  end INVALID_CREATE;


  /* Формирование данных расчета налоговой декларации (авансовых платежей) по обязательному пенсионному страхованию */
  procedure CALCDUTYPFR_CREATE
  (
  nCOMPANY      in number,
  nDEPARTMENT   in varchar2,                  -- подразделение
  nYEAR         in number,
  dPERIODBEGIN  in date,
  dPERIODEND    in date,
  nCHILDDEP     in number,                    -- признак учитывать все подчиненные подразделения
  nNEGOTIVE     in number,                    -- отриц налог. база
  nUSEENVD      in number,                    -- признак применения ЕНВД
  nPER_DUTY     in number,
  nPER_DUTY1    in number,
  nPER_DUTY2    in number,
  nPER_DUTY3    in number,
  nPER_CUMUL    in number,
  nPER_CUMUL1   in number,
  nPER_CUMUL2   in number,
  nPER_CUMUL3   in number,
  nPER_NOTENVD  in number,
  nPER_NOTENVD1 in number,
  nPER_NOTENVD2 in number,
  nPER_NOTENVD3 in number,
  n2005         in number default 0,           -- признак печати отчетности за 2005г
  nCLNPSPFMFGRP in number default null,        -- группа исполнений
  nDIFENVD      in number default 0            -- Сбор отчислений в части облагаемых по ЕНВД
  )
  as
   nBASE_1             SLCST_CALCDUTYPFR.BASE_1 %TYPE;      -- налоговая база 1 возрастной категории всего, и за три последних месяца
   nBASE_1_1           SLCST_CALCDUTYPFR.BASE_1_1%TYPE;
   nBASE_1_2           SLCST_CALCDUTYPFR.BASE_1_2%TYPE;
   nBASE_1_3           SLCST_CALCDUTYPFR.BASE_1_3%TYPE;
   nBASE_2             SLCST_CALCDUTYPFR.BASE_2%TYPE;       -- налоговая база 2 возрастной категории всего, и за три последних месяца
   nBASE_2_1           SLCST_CALCDUTYPFR.BASE_2_1%TYPE;
   nBASE_2_2           SLCST_CALCDUTYPFR.BASE_2_2%TYPE;
   nBASE_2_3           SLCST_CALCDUTYPFR.BASE_2_3%TYPE;
   nBASE_3             SLCST_CALCDUTYPFR.BASE_3%TYPE;       -- налоговая база 3 возрастной категории всего, и за три последних месяца
   nBASE_3_1           SLCST_CALCDUTYPFR.BASE_3_1%TYPE;
   nBASE_3_2           SLCST_CALCDUTYPFR.BASE_3_2%TYPE;
   nBASE_3_3           SLCST_CALCDUTYPFR.BASE_3_3%TYPE;
   nBASENOTENDV        SLCST_CALCDUTYPFR.BASENOTENDV%TYPE;
   nBASENOTENDV1       SLCST_CALCDUTYPFR.BASENOTENDV1%TYPE;
   nBASENOTENDV2       SLCST_CALCDUTYPFR.BASENOTENDV2%TYPE;
   nBASENOTENDV3       SLCST_CALCDUTYPFR.BASENOTENDV3%TYPE;
   nTAX_DUTY_1         SLCST_CALCDUTYPFR.TAX_DUTY_1%TYPE;   -- налог на обязательное пенсионное страхование 1 возрастной категории всего и за три последних месяца
   nTAX_DUTY_1_1       SLCST_CALCDUTYPFR.TAX_DUTY_1_1%TYPE;
   nTAX_DUTY_1_2       SLCST_CALCDUTYPFR.TAX_DUTY_1_2%TYPE;
   nTAX_DUTY_1_3       SLCST_CALCDUTYPFR.TAX_DUTY_1_3%TYPE;
   nTAX_DUTY_2         SLCST_CALCDUTYPFR.TAX_DUTY_2%TYPE;   -- налог на обязательное пенсионное страхование 2 возрастной категории всего и за три последних месяца
   nTAX_DUTY_2_1       SLCST_CALCDUTYPFR.TAX_DUTY_2_1%TYPE;
   nTAX_DUTY_2_2       SLCST_CALCDUTYPFR.TAX_DUTY_2_2%TYPE;
   nTAX_DUTY_2_3       SLCST_CALCDUTYPFR.TAX_DUTY_2_3%TYPE;
   nTAX_DUTY_3         SLCST_CALCDUTYPFR.TAX_DUTY_3%TYPE;   -- налог на обязательное пенсионное страхование 3 возрастной категории всего и за три последних месяца
   nTAX_DUTY_3_1       SLCST_CALCDUTYPFR.TAX_DUTY_3_1%TYPE;
   nTAX_DUTY_3_2       SLCST_CALCDUTYPFR.TAX_DUTY_3_2%TYPE;
   nTAX_DUTY_3_3       SLCST_CALCDUTYPFR.TAX_DUTY_3_3%TYPE;
   nTAX_DUTYNOTENDV    SLCST_CALCDUTYPFR.TAX_DUTYNOTENDV%TYPE;
   nTAX_DUTYNOTENDV1   SLCST_CALCDUTYPFR.TAX_DUTYNOTENDV1%TYPE;
   nTAX_DUTYNOTENDV2   SLCST_CALCDUTYPFR.TAX_DUTYNOTENDV2%TYPE;
   nTAX_DUTYNOTENDV3   SLCST_CALCDUTYPFR.TAX_DUTYNOTENDV3%TYPE;
   nTAX_CUMUL_2        SLCST_CALCDUTYPFR.TAX_CUMUL_2%TYPE;  -- налог на накопительное пенсионное страхование 2 возрастной категории всего и за три последних месяца
   nTAX_CUMUL_2_1      SLCST_CALCDUTYPFR.TAX_CUMUL_2_1%TYPE;
   nTAX_CUMUL_2_2      SLCST_CALCDUTYPFR.TAX_CUMUL_2_2%TYPE;
   nTAX_CUMUL_2_3      SLCST_CALCDUTYPFR.TAX_CUMUL_2_3%TYPE;
   nTAX_CUMUL_3        SLCST_CALCDUTYPFR.TAX_CUMUL_3%TYPE;  -- налог на накопительное пенсионное страхование 3 возрастной категории всего и за три последних месяца
   nTAX_CUMUL_3_1      SLCST_CALCDUTYPFR.TAX_CUMUL_3_1%TYPE;
     nTAX_CUMUL_3_2      SLCST_CALCDUTYPFR.TAX_CUMUL_3_2%TYPE;
   nTAX_CUMUL_3_3      SLCST_CALCDUTYPFR.TAX_CUMUL_3_3%TYPE;
   nTAX_CUMULNOTENDV   SLCST_CALCDUTYPFR.TAX_CUMULNOTENDV%TYPE;
   nTAX_CUMULNOTENDV1  SLCST_CALCDUTYPFR.TAX_CUMULNOTENDV1%TYPE;
   nTAX_CUMULNOTENDV2  SLCST_CALCDUTYPFR.TAX_CUMULNOTENDV2%TYPE;
   nTAX_CUMULNOTENDV3  SLCST_CALCDUTYPFR.TAX_CUMULNOTENDV3%TYPE;
   nPAY_DUTY           SLCST_CALCDUTYPFR.PAY_DUTY%TYPE;           -- уплачено страховых взносов на страховую часть
   nPAY_DUTY1          SLCST_CALCDUTYPFR.PAY_DUTY1%TYPE;
   nPAY_DUTY2          SLCST_CALCDUTYPFR.PAY_DUTY2%TYPE;
   nPAY_DUTY3          SLCST_CALCDUTYPFR.PAY_DUTY3%TYPE;
   nPAY_CUMUL          SLCST_CALCDUTYPFR.PAY_CUMUL%TYPE;           -- уплачено страховых взносов на накопительную часть
   nPAY_CUMUL1         SLCST_CALCDUTYPFR.PAY_CUMUL1%TYPE;
   nPAY_CUMUL2         SLCST_CALCDUTYPFR.PAY_CUMUL2%TYPE;
   nPAY_CUMUL3         SLCST_CALCDUTYPFR.PAY_CUMUL3%TYPE;
   nPAY_NOTENVD        SLCST_CALCDUTYPFR.PAY_NOTENVD%TYPE;         -- уплачено страховых взносов не ЕНВД
   nPAY_NOTENVD1       SLCST_CALCDUTYPFR.PAY_NOTENVD1%TYPE;
   nPAY_NOTENVD2       SLCST_CALCDUTYPFR.PAY_NOTENVD2%TYPE;
   nPAY_NOTENVD3       SLCST_CALCDUTYPFR.PAY_NOTENVD3%TYPE;
   nTAX_PFRDUTY        number(17,2);
   nTAX_PFRDUTY1       number(17,2);
   nTAX_PFRDUTY2       number(17,2);
   nTAX_PFRDUTY3       number(17,2);
   nMONTHBEGIN         number;
   nMONTHEND           number;
  procedure GET_SUMM
  (
   nPERSRN              in number,
   nCLNPERSTAXACC       in number,
   nAGNRN               in number,
   nYEAR                in number,
   nMONTHBEGIN          in number,
   nMONTHEND            in number,
   nNEGOTIVE            in number
  )
  as
    nMONTH1  number;
    nMONTH2  number;
    nMONTH3  number;
    nMAXVAL  number;
    nTMPVALUE             SLCST_CALC.BASE_PFR%TYPE;
    nBASE_PFR_            SLCST_CALC.BASE_PFR%TYPE;
    nBASE_PFR1_           SLCST_CALC.BASE_PFR1%TYPE;
    nBASE_PFR2_           SLCST_CALC.BASE_PFR2%TYPE;
    nBASE_PFR3_           SLCST_CALC.BASE_PFR3%TYPE;
    nBASE_PFR             SLCST_CALC.BASE_PFR%TYPE;
    nBASE_PFR1            SLCST_CALC.BASE_PFR1%TYPE;
    nBASE_PFR2            SLCST_CALC.BASE_PFR2%TYPE;
    nBASE_PFR3            SLCST_CALC.BASE_PFR3%TYPE;
    nBASE_DUTY_           SLCST_CALC.BASE_PFR%TYPE;
    nBASE_DUTY1_          SLCST_CALC.BASE_PFR1%TYPE;
    nBASE_DUTY2_          SLCST_CALC.BASE_PFR2%TYPE;
    nBASE_DUTY3_          SLCST_CALC.BASE_PFR3%TYPE;
    nBASE_DUTY            SLCST_CALC.BASE_PFR%TYPE;
    nBASE_DUTY1           SLCST_CALC.BASE_PFR1%TYPE;
    nBASE_DUTY2           SLCST_CALC.BASE_PFR2%TYPE;
    nBASE_DUTY3           SLCST_CALC.BASE_PFR3%TYPE;
    nTAX_DUTY_            SLCST_CALCDUTYPFR.TAX_DUTY_1%TYPE;
    nTAX_DUTY1_           SLCST_CALCDUTYPFR.TAX_DUTY_1%TYPE;
    nTAX_DUTY2_           SLCST_CALCDUTYPFR.TAX_DUTY_1%TYPE;
    nTAX_DUTY3_           SLCST_CALCDUTYPFR.TAX_DUTY_1%TYPE;
    nTAX_CUMUL_           SLCST_CALCDUTYPFR.TAX_DUTY_1%TYPE;
    nTAX_CUMUL1_          SLCST_CALCDUTYPFR.TAX_DUTY_1%TYPE;
    nTAX_CUMUL2_          SLCST_CALCDUTYPFR.TAX_DUTY_1%TYPE;
    nTAX_CUMUL3_          SLCST_CALCDUTYPFR.TAX_DUTY_1%TYPE;
    nSEX                  number(1);
    dDATEBIRTH            date;
    nYEARBIRTH            number(4);
    nGROUP1               number(1);
    nGROUP2               number(1);
    nGROUP3               number(1);
    nCOUNT                number;
    dEND                  date;
  begin
    dEND := add_months(INT2DATE(1,nMONTHEND,nYEAR),1)-1;
    select count(*)
    into nCOUNT
    from DUAL
    where exists
      (
      select A.CODE
      from
        CLNPERSADDINF I,
        SLANLSIGNS    A
      where I.PRN         = nPERSRN
        and I.BEGIN_DATE <= dEND
        and (I.END_DATE is null or I.END_DATE >= dEND)
        and I.SLANLSIGNS  = A.RN
        and trim(A.CODE) = 'ИНОСТРАНЕЦ'
      );
    if nCOUNT > 0 then
       return;
    end if;
    nMONTH3 := nMONTHEND;
    nMONTH2 := nMONTH3-1;
    nMONTH1 := nMONTH3-2;
    if nNEGOTIVE = 1 then
       nMAXVAL:= -9999999999;
    else
       nMAXVAL:= 0;
    end if;
    nGROUP1:=0;
    nGROUP2:=0;
    nGROUP3:=0;
    select A.SEX into nSEX from AGNLIST A where A.RN = nAGNRN;
    select A.AGNBURN into dDATEBIRTH from AGNLIST A where A.RN = nAGNRN;
    nYEARBIRTH := D_YEAR(dDATEBIRTH);
    /* определение возрастных групп */
    if n2005 = 0 then
       if (nSEX<=1 and nYEARBIRTH<=1952) or (nSEX=2 and nYEARBIRTH<=1956) then
          nGROUP1 :=1;
       elsif (nSEX<=1 and nYEARBIRTH >=1953 and nYEARBIRTH <=1966) or (nSEX=2 and nYEARBIRTH>=1957 and nYEARBIRTH <=1966) then
          nGROUP2 :=1;
       elsif nYEARBIRTH>=1967 then
          nGROUP3 :=1;
       end if;
    else
       if nYEARBIRTH<=1966  then
          nGROUP1 :=1;
       elsif nYEARBIRTH>=1967 then
          nGROUP2 :=1;
       end if;
    end if;
    nTMPVALUE       :=0;
    nBASE_PFR_      :=0;
    nBASE_PFR1_     :=0;
    nBASE_PFR2_     :=0;
    nBASE_PFR3_     :=0;
    nBASE_PFR       :=0;
    nBASE_PFR1      :=0;
    nBASE_PFR2      :=0;
    nBASE_PFR3      :=0;
    nBASE_DUTY_     :=0;
    nBASE_DUTY1_    :=0;
    nBASE_DUTY2_    :=0;
    nBASE_DUTY3_    :=0;
    nBASE_DUTY      :=0;
    nBASE_DUTY1     :=0;
    nBASE_DUTY2     :=0;
    nBASE_DUTY3     :=0;
    nTAX_DUTY_      :=0;
    nTAX_DUTY1_     :=0;
    nTAX_DUTY2_     :=0;
    nTAX_DUTY3_     :=0;
    nTAX_CUMUL_     :=0;
    nTAX_CUMUL1_    :=0;
    nTAX_CUMUL2_    :=0;
    nTAX_CUMUL3_    :=0;
    nTAX_PFRDUTY    :=0;
    nTAX_PFRDUTY1   :=0;
    nTAX_PFRDUTY2   :=0;
    nTAX_PFRDUTY3   :=0;

    for cTAXPAYS in
    (
     select TC.PRN,
            TP.SLTAXACCS,
            TP.SUMME,
            TP.DISCOUNTSUMM,
            TP.MONTHNUMB,
            TR.TAXBASE,
            TR.STATE,
            TR.POS_CODE,
            TR.PRIVIL,
            TR1.DDCODE
      from CLNPERSTAXACCSP TP,
           CLNPERSTAXACC   TC,
           SLTAXACCS TR,
           SALINDEDUCT TR1
      where TC.RN = TP.PRN
        and TP.SLTAXACCS = TR.RN
        and TR.DEDCODE = TR1.RN (+)
        and TC.RN = nCLNPERSTAXACC
        and TP.MONTHNUMB>=nMONTHBEGIN
        and TP.MONTHNUMB<=nMONTHEND
        and (TR.TAXBASE = 4 or TR.TAXBASE = 8 or TR.TAXBASE = 9 or TR.TAXBASE = 10 or TR.TAXBASE = 11)
    )
    loop
        nTMPVALUE :=0;
        if cTAXPAYS.TAXBASE = 4 and cTAXPAYS.STATE =0 then            -- доход ПФР
              if trim(cTAXPAYS.POS_CODE) = '7' then
                 nTMPVALUE := cTAXPAYS.SUMME;
              end if;
              if trim(cTAXPAYS.DDCODE) = '1' then
                 nTMPVALUE := cTAXPAYS.DISCOUNTSUMM;
              end if;
              if trim(cTAXPAYS.DDCODE) = '2' then
                 nTMPVALUE := cTAXPAYS.DISCOUNTSUMM;
              end if;
              if trim(cTAXPAYS.DDCODE) = '3' then
                 nTMPVALUE := cTAXPAYS.DISCOUNTSUMM;
              end if;
              if trim(cTAXPAYS.POS_CODE) = '1' and trim(cTAXPAYS.DDCODE) = '4' then
                 nTMPVALUE := cTAXPAYS.DISCOUNTSUMM;
              end if;
              if trim(cTAXPAYS.POS_CODE) = '6' then
                 nTMPVALUE := cTAXPAYS.DISCOUNTSUMM;
              end if;
              if trim(cTAXPAYS.POS_CODE) = '2' then
                 nTMPVALUE := cTAXPAYS.SUMME;
              end if;
              nBASE_PFR_:= nBASE_PFR_ + cTAXPAYS.SUMME - nTMPVALUE;               -- налоговая база для ПФР (строка 100)
              if cTAXPAYS.MONTHNUMB < nMONTH1 then                                 -- первый месяц последнего кавартала
                 nBASE_PFR1_ := nBASE_PFR1_ + cTAXPAYS.SUMME - nTMPVALUE;
              end if;
              if cTAXPAYS.MONTHNUMB < nMONTH2 then                                 -- второй месяц последнего кавартала
                 nBASE_PFR2_ := nBASE_PFR2_ + cTAXPAYS.SUMME - nTMPVALUE;
              end if;
              if cTAXPAYS.MONTHNUMB < nMONTH3 then                                -- третий месяц последнего кавартала
                 nBASE_PFR3_ := nBASE_PFR3_ + cTAXPAYS.SUMME - nTMPVALUE;
              end if;
        elsif nCOUNT = 0 and cTAXPAYS.TAXBASE = 8 and cTAXPAYS.STATE =0 then                     -- доход страховой части ПФР
              if trim(cTAXPAYS.POS_CODE) = '7' then
                 nTMPVALUE := cTAXPAYS.SUMME;
              end if;
              if trim(cTAXPAYS.DDCODE) = '1' then
                 nTMPVALUE := cTAXPAYS.DISCOUNTSUMM;
              end if;
              if trim(cTAXPAYS.DDCODE) = '2' then
                 nTMPVALUE := cTAXPAYS.DISCOUNTSUMM;
              end if;
              if trim(cTAXPAYS.DDCODE) = '3' then
                 nTMPVALUE := cTAXPAYS.DISCOUNTSUMM;
              end if;
              if trim(cTAXPAYS.POS_CODE) = '1' and trim(cTAXPAYS.DDCODE) = '4' then
                 nTMPVALUE := cTAXPAYS.DISCOUNTSUMM;
              end if;
              if trim(cTAXPAYS.POS_CODE) = '6' then
                 nTMPVALUE := cTAXPAYS.DISCOUNTSUMM;
              end if;
              if trim(cTAXPAYS.POS_CODE) = '2' then
                 nTMPVALUE := cTAXPAYS.SUMME;
              end if;
              nBASE_DUTY_ := nBASE_DUTY_ + cTAXPAYS.SUMME - nTMPVALUE;
              if cTAXPAYS.MONTHNUMB <nMONTH1 then
                 nBASE_DUTY1_ := nBASE_DUTY1_ + cTAXPAYS.SUMME - nTMPVALUE;
              end if;
              if cTAXPAYS.MONTHNUMB <nMONTH2 then
                 nBASE_DUTY2_ := nBASE_DUTY2_ + cTAXPAYS.SUMME - nTMPVALUE;
              end if;
              if cTAXPAYS.MONTHNUMB <nMONTH3 then
                 nBASE_DUTY3_ := nBASE_DUTY3_ + cTAXPAYS.SUMME - nTMPVALUE;
              end if;
        elsif cTAXPAYS.TAXBASE = 8 and cTAXPAYS.STATE =2 then                  -- налог на страховую часть ПФР
              nTAX_DUTY_ := nTAX_DUTY_ + cTAXPAYS.SUMME;
              if cTAXPAYS.MONTHNUMB =nMONTH1 then
                 nTAX_DUTY1_ := nTAX_DUTY1_ + cTAXPAYS.SUMME;
              end if;
              if cTAXPAYS.MONTHNUMB = nMONTH2 then
                 nTAX_DUTY2_ := nTAX_DUTY2_ + cTAXPAYS.SUMME;
              end if;
              if cTAXPAYS.MONTHNUMB = nMONTH3 then
                 nTAX_DUTY3_ := nTAX_DUTY3_ + cTAXPAYS.SUMME;
              end if;
        elsif cTAXPAYS.TAXBASE = 10 and cTAXPAYS.STATE =2 and nUSEENVD = 1 then                 -- налог на страховую часть ПФР по не ЕНВД
              nTAX_DUTYNOTENDV := nTAX_DUTYNOTENDV + cTAXPAYS.SUMME;
              if cTAXPAYS.MONTHNUMB =nMONTH1 then
                 nTAX_DUTYNOTENDV1 := nTAX_DUTYNOTENDV1 + cTAXPAYS.SUMME;
              end if;
              if cTAXPAYS.MONTHNUMB = nMONTH2 then
                 nTAX_DUTYNOTENDV2 := nTAX_DUTYNOTENDV2 + cTAXPAYS.SUMME;
              end if;
              if cTAXPAYS.MONTHNUMB = nMONTH3 then
                 nTAX_DUTYNOTENDV3 := nTAX_DUTYNOTENDV3 + cTAXPAYS.SUMME;
              end if;
        elsif cTAXPAYS.TAXBASE = 9 and cTAXPAYS.STATE =2 then                  -- налог на накопительную часть ПФР
              nTAX_CUMUL_ := nTAX_CUMUL_ + cTAXPAYS.SUMME;
              if cTAXPAYS.MONTHNUMB = nMONTH1 then
                 nTAX_CUMUL1_ := nTAX_CUMUL1_ + cTAXPAYS.SUMME;
              end if;
              if cTAXPAYS.MONTHNUMB = nMONTH2 then
                 nTAX_CUMUL2_ := nTAX_CUMUL2_ + cTAXPAYS.SUMME;
              end if;
              if cTAXPAYS.MONTHNUMB = nMONTH3 then
                 nTAX_CUMUL3_ := nTAX_CUMUL3_ + cTAXPAYS.SUMME;
              end if;
        elsif cTAXPAYS.TAXBASE = 11 and cTAXPAYS.STATE =2 and nUSEENVD = 1 then                 -- налог на страховую часть ПФР по не ЕНВД
              nTAX_CUMULNOTENDV := nTAX_CUMULNOTENDV + cTAXPAYS.SUMME;
              if cTAXPAYS.MONTHNUMB =nMONTH1 then
                 nTAX_CUMULNOTENDV1 := nTAX_CUMULNOTENDV1 + cTAXPAYS.SUMME;
              end if;
              if cTAXPAYS.MONTHNUMB = nMONTH2 then
                 nTAX_CUMULNOTENDV2 := nTAX_CUMULNOTENDV2 + cTAXPAYS.SUMME;
              end if;
              if cTAXPAYS.MONTHNUMB = nMONTH3 then
                 nTAX_CUMULNOTENDV3 := nTAX_CUMULNOTENDV3 + cTAXPAYS.SUMME;
              end if;
        end if;
    end loop;
    /* Налоговая база ПФР */
    nBASE_PFR_  := greatest(nBASE_PFR_ ,nMAXVAL);
    nBASE_PFR1_ := greatest(nBASE_PFR1_,nMAXVAL);
    nBASE_PFR2_ := greatest(nBASE_PFR2_,nMAXVAL);
    nBASE_PFR3_ := greatest(nBASE_PFR3_,nMAXVAL);

    nBASE_PFR  := nBASE_PFR  + nBASE_PFR_;
    nBASE_PFR1 := nBASE_PFR1 + nBASE_PFR2_ - nBASE_PFR1_;
    nBASE_PFR2 := nBASE_PFR2 + nBASE_PFR3_ - nBASE_PFR2_;
    nBASE_PFR3 := nBASE_PFR3 + nBASE_PFR_  - nBASE_PFR3_;

    /* Налоговая база страх ПФР */

    nBASE_DUTY_  := greatest(nBASE_DUTY_ ,nMAXVAL);
    nBASE_DUTY1_ := greatest(nBASE_DUTY1_,nMAXVAL);
    nBASE_DUTY2_ := greatest(nBASE_DUTY2_,nMAXVAL);
    nBASE_DUTY3_ := greatest(nBASE_DUTY3_,nMAXVAL);

    nBASE_DUTY  := nBASE_DUTY  + nBASE_DUTY_;
    nBASE_DUTY1 := nBASE_DUTY1 + nBASE_DUTY2_ - nBASE_DUTY1_;
    nBASE_DUTY2 := nBASE_DUTY2 + nBASE_DUTY3_ - nBASE_DUTY2_;
    nBASE_DUTY3 := nBASE_DUTY3 + nBASE_DUTY_  - nBASE_DUTY3_;

    if nUSEENVD = 1 then    -- если есть налоговая база по ЕНДВ
       /* Налоговая база ПФР не енвд*/
       nBASENOTENDV  := nBASENOTENDV  + nBASE_PFR;
       nBASENOTENDV1 := nBASENOTENDV1 + nBASE_PFR1;
       nBASENOTENDV2 := nBASENOTENDV2 + nBASE_PFR2;
       nBASENOTENDV3 := nBASENOTENDV3 + nBASE_PFR3;

       nBASE_PFR  := nBASE_DUTY;
       nBASE_PFR1 := nBASE_DUTY1;
       nBASE_PFR2 := nBASE_DUTY2;
       nBASE_PFR3 := nBASE_DUTY3;
    end if;

    if nGROUP1 = 1 then
       nBASE_1   := nBASE_1  + nBASE_PFR;
       nBASE_1_1 := nBASE_1_1 + nBASE_PFR1;
       nBASE_1_2 := nBASE_1_2 + nBASE_PFR2;
       nBASE_1_3 := nBASE_1_3 + nBASE_PFR3;

       nTAX_DUTY_1 := nTAX_DUTY_1 +  nTAX_DUTY_;
       nTAX_DUTY_1_1 := nTAX_DUTY_1_1  + nTAX_DUTY1_;
       nTAX_DUTY_1_2 := nTAX_DUTY_1_2  + nTAX_DUTY2_;
       nTAX_DUTY_1_3 := nTAX_DUTY_1_3  + nTAX_DUTY3_;

    elsif nGROUP2 = 1 then
       nBASE_2   := nBASE_2   + nBASE_PFR;
       nBASE_2_1 := nBASE_2_1 + nBASE_PFR1;
       nBASE_2_2 := nBASE_2_2 + nBASE_PFR2;
       nBASE_2_3 := nBASE_2_3 + nBASE_PFR3;

       nTAX_DUTY_2 := nTAX_DUTY_2 +  nTAX_DUTY_;
       nTAX_DUTY_2_1 := nTAX_DUTY_2_1  + nTAX_DUTY1_;
       nTAX_DUTY_2_2 := nTAX_DUTY_2_2  + nTAX_DUTY2_;
       nTAX_DUTY_2_3 := nTAX_DUTY_2_3  + nTAX_DUTY3_;

       nTAX_CUMUL_2 := nTAX_CUMUL_2 +  nTAX_CUMUL_;
       nTAX_CUMUL_2_1 := nTAX_CUMUL_2_1  + nTAX_CUMUL1_;
       nTAX_CUMUL_2_2 := nTAX_CUMUL_2_2  + nTAX_CUMUL2_;
       nTAX_CUMUL_2_3 := nTAX_CUMUL_2_3  + nTAX_CUMUL3_;

    elsif nGROUP3 = 1 then
       nBASE_3   := nBASE_3   + nBASE_PFR;
       nBASE_3_1 := nBASE_3_1 + nBASE_PFR1;
       nBASE_3_2 := nBASE_3_2 + nBASE_PFR2;
       nBASE_3_3 := nBASE_3_3 + nBASE_PFR3;

       nTAX_DUTY_3   := nTAX_DUTY_3 +  nTAX_DUTY_;
       nTAX_DUTY_3_1 := nTAX_DUTY_3_1  + nTAX_DUTY1_;
       nTAX_DUTY_3_2 := nTAX_DUTY_3_2  + nTAX_DUTY2_;
       nTAX_DUTY_3_3 := nTAX_DUTY_3_3  + nTAX_DUTY3_;

       nTAX_CUMUL_3   := nTAX_CUMUL_3 +  nTAX_CUMUL_;
       nTAX_CUMUL_3_1 := nTAX_CUMUL_3_1 + nTAX_CUMUL1_;
       nTAX_CUMUL_3_2 := nTAX_CUMUL_3_2 + nTAX_CUMUL2_;
       nTAX_CUMUL_3_3 := nTAX_CUMUL_3_3 + nTAX_CUMUL3_;

    end if;

    nTAX_PFRDUTY    := nTAX_PFRDUTY + nTAX_DUTY_ + nTAX_CUMUL_;
    nTAX_PFRDUTY1   := nTAX_PFRDUTY1 + nTAX_CUMUL1_ + nTAX_DUTY1_;
    nTAX_PFRDUTY2   := nTAX_PFRDUTY2 + nTAX_CUMUL2_ + nTAX_DUTY2_;
    nTAX_PFRDUTY3   := nTAX_PFRDUTY3 + nTAX_CUMUL3_ + nTAX_DUTY3_;
  end;

  begin
   nBASE_1        :=0;
   nBASE_1_1      :=0;
   nBASE_1_2      :=0;
   nBASE_1_3      :=0;
   nBASE_2        :=0;
   nBASE_2_1      :=0;
   nBASE_2_2      :=0;
   nBASE_2_3      :=0;
   nBASE_3        :=0;
   nBASE_3_1      :=0;
   nBASE_3_2      :=0;
   nBASE_3_3      :=0;
   nBASENOTENDV   :=0;
   nBASENOTENDV1  :=0;
   nBASENOTENDV2  :=0;
   nBASENOTENDV3  :=0;
   nTAX_DUTY_1    :=0;
   nTAX_DUTY_1_1  :=0;
   nTAX_DUTY_1_2  :=0;
   nTAX_DUTY_1_3  :=0;
   nTAX_DUTY_2    :=0;
   nTAX_DUTY_2_1  :=0;
   nTAX_DUTY_2_2  :=0;
   nTAX_DUTY_2_3  :=0;
   nTAX_DUTY_3    :=0;
   nTAX_DUTY_3_1  :=0;
   nTAX_DUTY_3_2  :=0;
   nTAX_DUTY_3_3  :=0;
   nTAX_DUTYNOTENDV  :=0;
   nTAX_DUTYNOTENDV1 :=0;
   nTAX_DUTYNOTENDV2 :=0;
   nTAX_DUTYNOTENDV3 :=0;
   nTAX_CUMUL_2    :=0;
   nTAX_CUMUL_2_1 :=0;
   nTAX_CUMUL_2_2 :=0;
   nTAX_CUMUL_2_3 :=0;
   nTAX_CUMUL_3   :=0;
   nTAX_CUMUL_3_1 :=0;
   nTAX_CUMUL_3_2 :=0;
   nTAX_CUMUL_3_3 :=0;
   nTAX_CUMULNOTENDV :=0;
   nTAX_CUMULNOTENDV1:=0;
   nTAX_CUMULNOTENDV2:=0;
   nTAX_CUMULNOTENDV3:=0;
   nMONTHBEGIN := D_MONTH(dPERIODBEGIN);
   nMONTHEND   := D_MONTH(dPERIODEND);
   nTAX_PFRDUTY  := 0;
   nTAX_PFRDUTY1 := 0;
   nTAX_PFRDUTY2 := 0;
   nTAX_PFRDUTY3 := 0;
   nPAY_DUTY     := 0;
   nPAY_DUTY1    := 0;
   nPAY_DUTY2    := 0;
   nPAY_DUTY3    := 0;
   nPAY_CUMUL    := 0;
   nPAY_CUMUL1   := 0;
   nPAY_CUMUL2   := 0;
   nPAY_CUMUL3   := 0;
   nPAY_NOTENVD  := 0;
   nPAY_NOTENVD1 := 0;
   nPAY_NOTENVD2 := 0;
   nPAY_NOTENVD3 := 0;
   -- список сотрудников выбранного подразделения
   if nDEPARTMENT is null and nCLNPSPFMFGRP is null then               -- вся организация
      for cTAX in
      (
       Select CP.PERSRN,
              TC.RN as CLNPERSTAXACC,
              CN.PERS_AGENT
         from CLNPSPFM CP,
              CLNPERSTAXACC TC,
              CLNPERSONS CN
         where CP.PERSRN = TC.PRN
           and CP.PERSRN = CN.RN
           and CP.COMPANY = nCOMPANY
           and TC.TYPE = 0
           and TC.YEAR = nYEAR
         group by CP.PERSRN, TC.RN, CN.PERS_AGENT
        )
        loop
          GET_SUMM(cTAX.PERSRN,cTAX.CLNPERSTAXACC,cTAX.PERS_AGENT,nYEAR,nMONTHBEGIN,nMONTHEND,nNEGOTIVE);
        end loop;
   elsif nDEPARTMENT is not null and nCHILDDEP=1 then -- Подразделение + подчиненные подразделения

      for cTAX in
      (
       Select CP.PERSRN,
              TC.RN as CLNPERSTAXACC,
              CN.PERS_AGENT
         from CLNPSPFM CP,
              CLNPERSTAXACC TC,
              CLNPERSONS CN
         where CP.PERSRN = TC.PRN
           and CP.PERSRN = CN.RN
           and CP.DEPTRN in (Select RN from INS_DEPARTMENT start with rn = nDEPARTMENT  connect by prior RN=PRN)
           and TC.TYPE = 0
           and TC.YEAR = nYEAR
         group by CP.PERSRN,TC.RN, CN.PERS_AGENT
      )
      loop
       GET_SUMM(cTAX.PERSRN,cTAX.CLNPERSTAXACC,cTAX.PERS_AGENT,nYEAR,nMONTHBEGIN,nMONTHEND,nNEGOTIVE);
      end loop;
   elsif nDEPARTMENT is not null and nCHILDDEP=0 then  -- Подразделение без подчиненных подразделений
      for cTAX in
      (
       Select CP.PERSRN,
              TC.RN as CLNPERSTAXACC,
              CN.PERS_AGENT
         from CLNPSPFM CP,
              CLNPERSTAXACC TC,
              CLNPERSONS CN
         where CP.PERSRN = TC.PRN
           and CP.PERSRN = CN.RN
           and CP.DEPTRN = nDEPARTMENT
           and TC.TYPE = 0
           and TC.YEAR = nYEAR
         group by CP.PERSRN,TC.RN,CN.PERS_AGENT
      )
      loop
        GET_SUMM(cTAX.PERSRN,cTAX.CLNPERSTAXACC,cTAX.PERS_AGENT,nYEAR,nMONTHBEGIN,nMONTHEND,nNEGOTIVE);
      end loop;
   elsif nDEPARTMENT is null and nCLNPSPFMFGRP is not null then  -- Группа исполнений
      for cTAX in
      (
       Select CP.PERSRN,
              TC.RN as CLNPERSTAXACC,
              CN.PERS_AGENT
         from CLNPSPFMFGRPSP CPS,
              CLNPSPFM CP,
              CLNPERSTAXACC TC,
              CLNPERSONS CN
         where CPS.CLNPSPFM = CP.RN
           and CP.PERSRN = TC.PRN
           and CP.PERSRN = CN.RN
           and CPS.PRN = nCLNPSPFMFGRP
           and TC.TYPE = 0
           and TC.YEAR = nYEAR
         group by CP.PERSRN,TC.RN,CN.PERS_AGENT
      )
      loop
        GET_SUMM(cTAX.PERSRN,cTAX.CLNPERSTAXACC,cTAX.PERS_AGENT,nYEAR,nMONTHBEGIN,nMONTHEND,nNEGOTIVE);
      end loop;
   end if;
   nBASE_1            := round(nBASE_1,0);
   nBASE_1_1          := round(nBASE_1_1,0);
   nBASE_1_2          := round(nBASE_1_2,0);
   nBASE_1_3          := round(nBASE_1_3,0);
   nBASE_2            := round(nBASE_2,0);
   nBASE_2_1          := round(nBASE_2_1,0);
   nBASE_2_2          := round(nBASE_2_2,0);
   nBASE_2_3          := round(nBASE_2_3,0);
   nBASE_3            := round(nBASE_3,0);
   nBASE_3_1          := round(nBASE_3_1,0);
   nBASE_3_2          := round(nBASE_3_2,0);
   nBASE_3_3          := round(nBASE_3_3,0);
   nBASENOTENDV       := round(nBASENOTENDV,0);
   nBASENOTENDV1      := round(nBASENOTENDV1,0);
   nBASENOTENDV2      := round(nBASENOTENDV2,0);
   nBASENOTENDV3      := round(nBASENOTENDV3,0);
   nTAX_DUTY_1        := round(nTAX_DUTY_1,0);
   nTAX_DUTY_1_1      := round(nTAX_DUTY_1_1,0);
   nTAX_DUTY_1_2      := round(nTAX_DUTY_1_2,0);
   nTAX_DUTY_1_3      := round(nTAX_DUTY_1_3,0);
   nTAX_DUTY_2        := round(nTAX_DUTY_2,0);
   nTAX_DUTY_2_1      := round(nTAX_DUTY_2_1,0);
   nTAX_DUTY_2_2      := round(nTAX_DUTY_2_2,0);
   nTAX_DUTY_2_3      := round(nTAX_DUTY_2_3,0);
   nTAX_DUTY_3        := round(nTAX_DUTY_3,0);
   nTAX_DUTY_3_1      := round(nTAX_DUTY_3_1,0);
   nTAX_DUTY_3_2      := round(nTAX_DUTY_3_2,0);
   nTAX_DUTY_3_3      := round(nTAX_DUTY_3_3,0);
   nTAX_DUTYNOTENDV   := round(nTAX_DUTYNOTENDV,0);
   nTAX_DUTYNOTENDV1  := round(nTAX_DUTYNOTENDV1,0);
   nTAX_DUTYNOTENDV2  := round(nTAX_DUTYNOTENDV2,0);
   nTAX_DUTYNOTENDV3  := round(nTAX_DUTYNOTENDV3,0);
   nTAX_CUMUL_2       := round(nTAX_CUMUL_2,0);
   nTAX_CUMUL_2_1     := round(nTAX_CUMUL_2_1,0);
   nTAX_CUMUL_2_2     := round(nTAX_CUMUL_2_2,0);
   nTAX_CUMUL_2_3     := round(nTAX_CUMUL_2_3,0);
   nTAX_CUMUL_3       := round(nTAX_CUMUL_3,0);
   nTAX_CUMUL_3_1     := round(nTAX_CUMUL_3_1,0);
   nTAX_CUMUL_3_2     := round(nTAX_CUMUL_3_2,0);
   nTAX_CUMUL_3_3     := round(nTAX_CUMUL_3_3,0);
   nTAX_CUMULNOTENDV  := round(nTAX_CUMULNOTENDV,0);
   nTAX_CUMULNOTENDV1 := round(nTAX_CUMULNOTENDV1,0);
   nTAX_CUMULNOTENDV2 := round(nTAX_CUMULNOTENDV2,0);
   nTAX_CUMULNOTENDV3 := round(nTAX_CUMULNOTENDV3,0);
   nTAX_PFRDUTY  := round(nTAX_PFRDUTY,0);
   nTAX_PFRDUTY1 := round(nTAX_PFRDUTY1,0);
   nTAX_PFRDUTY2 := round(nTAX_PFRDUTY2,0);
   nTAX_PFRDUTY3 := round(nTAX_PFRDUTY3,0);

   /* коррекция с формой по ЕСН */
--   DELTA(nTAX_PFRDUTY,NTAX_DUTY_1, NTAX_DUTY_2, NTAX_DUTY_3);
--   DELTA(nTAX_PFRDUTY1,NTAX_DUTY_1_1, NTAX_DUTY_2_1, NTAX_DUTY_3_1);
--   DELTA(nTAX_PFRDUTY1,NTAX_DUTY_1_2, NTAX_DUTY_2_2, NTAX_DUTY_3_2);
--   DELTA(nTAX_PFRDUTY1,NTAX_DUTY_1_3, NTAX_DUTY_2_3, NTAX_DUTY_3_3);

   /* для первого квартала делаем коррекцию погрешности округления */
   if nMONTHBEGIN = 1 and nMONTHEND = 3 then
      DELTA(nBASE_1,nBASE_1_1,nBASE_1_2,nBASE_1_3);
      DELTA(nBASE_2,nBASE_2_1,nBASE_2_2,nBASE_2_3);
      DELTA(nBASE_3,nBASE_3_1,nBASE_3_2,nBASE_3_3);
      DELTA(nBASENOTENDV,nBASENOTENDV1,nBASENOTENDV2,nBASENOTENDV3);
      DELTA(nTAX_DUTY_1,nTAX_DUTY_1_1,nTAX_DUTY_1_2,nTAX_DUTY_1_3);
      DELTA(nTAX_DUTY_2,nTAX_DUTY_2_1,nTAX_DUTY_2_2,nTAX_DUTY_2_3);
      DELTA(nTAX_DUTY_3,nTAX_DUTY_3_1,nTAX_DUTY_3_2,nTAX_DUTY_3_3);
      DELTA(nTAX_DUTYNOTENDV,nTAX_DUTYNOTENDV1,nTAX_DUTYNOTENDV2,nTAX_DUTYNOTENDV3);
      DELTA(nTAX_CUMUL_2,nTAX_CUMUL_2_1,nTAX_CUMUL_2_2,nTAX_CUMUL_2_3);
      DELTA(nTAX_CUMUL_3,nTAX_CUMUL_3_1,nTAX_CUMUL_3_2,nTAX_CUMUL_3_3);
      DELTA(nTAX_CUMULNOTENDV, nTAX_CUMULNOTENDV1, nTAX_CUMULNOTENDV2, nTAX_CUMULNOTENDV3);
   end if;
   /* оплачено */
   /* если параметр не задан, то считаем, что оплачено столько сколько расчитано */
   nPAY_DUTY     := nvl(nPER_DUTY,nTAX_DUTY_1+nTAX_DUTY_2+nTAX_DUTY_3);
   nPAY_DUTY1    := nvl(nPER_DUTY1,nTAX_DUTY_1_1+nTAX_DUTY_2_1+nTAX_DUTY_3_1);
   nPAY_DUTY2    := nvl(nPER_DUTY2,nTAX_DUTY_1_2+nTAX_DUTY_2_2+nTAX_DUTY_3_2);
   nPAY_DUTY3    := nvl(nPER_DUTY3,nTAX_DUTY_1_3+nTAX_DUTY_2_3+nTAX_DUTY_3_3);
   nPAY_CUMUL    := nvl(nPER_CUMUL,nTAX_CUMUL_2+nTAX_CUMUL_3);
   nPAY_CUMUL1   := nvl(nPER_CUMUL1,nTAX_CUMUL_2_1+nTAX_CUMUL_3_1);
   nPAY_CUMUL2   := nvl(nPER_CUMUL2,nTAX_CUMUL_2_2+nTAX_CUMUL_3_2);
   nPAY_CUMUL3   := nvl(nPER_CUMUL3,nTAX_CUMUL_2_3+nTAX_CUMUL_3_3);
   if nUSEENVD = 1 then
      /* если Сбор отчислений в части облагаемых по ЕНВД, вычисляем разницу между ВСЕГО и ЕНВД */
      if nDIFENVD = 1 then
        nTAX_DUTYNOTENDV  := nTAX_DUTY_1 + nTAX_DUTY_2 + nTAX_DUTY_3 - nTAX_DUTYNOTENDV;
        nTAX_DUTYNOTENDV1 := nTAX_DUTY_1_1 + nTAX_DUTY_2_1 + nTAX_DUTY_3_1 - nTAX_DUTYNOTENDV1;
        nTAX_DUTYNOTENDV2 := nTAX_DUTY_1_2 + nTAX_DUTY_2_2 + nTAX_DUTY_3_2 - nTAX_DUTYNOTENDV2;
        nTAX_DUTYNOTENDV3 := nTAX_DUTY_1_3 + nTAX_DUTY_2_3 + nTAX_DUTY_3_3 - nTAX_DUTYNOTENDV3;
        nTAX_CUMULNOTENDV := nTAX_CUMUL_2  + nTAX_CUMUL_3 - nTAX_CUMULNOTENDV;
        nTAX_CUMULNOTENDV1:= nTAX_CUMUL_2_1+ nTAX_CUMUL_3_1 - nTAX_CUMULNOTENDV1;
        nTAX_CUMULNOTENDV2:= nTAX_CUMUL_2_2+ nTAX_CUMUL_3_2 - nTAX_CUMULNOTENDV2;
        nTAX_CUMULNOTENDV3:= nTAX_CUMUL_2_3+ nTAX_CUMUL_3_3 - nTAX_CUMULNOTENDV3;
      end if;
      nPAY_NOTENVD  := nvl(nPER_NOTENVD,nTAX_DUTYNOTENDV+nTAX_CUMULNOTENDV);
      nPAY_NOTENVD1 := nvl(nPER_NOTENVD1,nTAX_DUTYNOTENDV1+nTAX_CUMULNOTENDV1);
      nPAY_NOTENVD2 := nvl(nPER_NOTENVD2,nTAX_DUTYNOTENDV2+nTAX_CUMULNOTENDV2);
      nPAY_NOTENVD3 := nvl(nPER_NOTENVD3,nTAX_DUTYNOTENDV3+nTAX_CUMULNOTENDV3);
   else
      nBASENOTENDV  :=  nBASE_1   + nBASE_2   + nBASE_3;
      nBASENOTENDV1 :=  nBASE_1_1 + nBASE_2_1 + nBASE_3_1;
      nBASENOTENDV2 :=  nBASE_1_2 + nBASE_2_2 + nBASE_3_2;
      nBASENOTENDV3 :=  nBASE_1_3 + nBASE_2_3 + nBASE_3_3;
      nTAX_DUTYNOTENDV  := nTAX_DUTY_1 + nTAX_DUTY_2 + nTAX_DUTY_3;
      nTAX_DUTYNOTENDV1 := nTAX_DUTY_1_1 + nTAX_DUTY_2_1 + nTAX_DUTY_3_1;
      nTAX_DUTYNOTENDV2 := nTAX_DUTY_1_2 + nTAX_DUTY_2_2 + nTAX_DUTY_3_2;
      nTAX_DUTYNOTENDV3 := nTAX_DUTY_1_3 + nTAX_DUTY_2_3 + nTAX_DUTY_3_3;
      nTAX_CUMULNOTENDV := nTAX_CUMUL_2  + nTAX_CUMUL_3;
      nTAX_CUMULNOTENDV1:= nTAX_CUMUL_2_1+ nTAX_CUMUL_3_1;
      nTAX_CUMULNOTENDV2:= nTAX_CUMUL_2_2+ nTAX_CUMUL_3_2;
      nTAX_CUMULNOTENDV3:= nTAX_CUMUL_2_3+ nTAX_CUMUL_3_3;

      nPAY_NOTENVD  := nPAY_DUTY+nPAY_CUMUL;
      nPAY_NOTENVD1 := nPAY_DUTY1+nPAY_CUMUL1;
      nPAY_NOTENVD2 := nPAY_DUTY2+nPAY_CUMUL2;
      nPAY_NOTENVD3 := nPAY_DUTY3+nPAY_CUMUL3;

   end if;

   insert
      into SLCST_CALCDUTYPFR
      (
       RN,
       AUTHID,
       BASE_1,
       BASE_1_1,
       BASE_1_2,
       BASE_1_3,
       BASE_2,
       BASE_2_1,
       BASE_2_2,
       BASE_2_3,
       BASE_3,
       BASE_3_1,
       BASE_3_2,
       BASE_3_3,
       BASENOTENDV,
       BASENOTENDV1,
       BASENOTENDV2,
       BASENOTENDV3,
       TAX_DUTY_1,
       TAX_DUTY_1_1,
       TAX_DUTY_1_2,
       TAX_DUTY_1_3,
       TAX_DUTY_2,
       TAX_DUTY_2_1,
       TAX_DUTY_2_2,
       TAX_DUTY_2_3,
       TAX_DUTY_3,
       TAX_DUTY_3_1,
       TAX_DUTY_3_2,
       TAX_DUTY_3_3,
       TAX_DUTYNOTENDV,
       TAX_DUTYNOTENDV1,
       TAX_DUTYNOTENDV2,
       TAX_DUTYNOTENDV3,
       TAX_CUMUL_2,
       TAX_CUMUL_2_1,
       TAX_CUMUL_2_2,
       TAX_CUMUL_2_3,
       TAX_CUMUL_3,
       TAX_CUMUL_3_1,
       TAX_CUMUL_3_2,
       TAX_CUMUL_3_3,
       TAX_CUMULNOTENDV,
       TAX_CUMULNOTENDV1,
       TAX_CUMULNOTENDV2,
       TAX_CUMULNOTENDV3,
       PAY_DUTY,
       PAY_DUTY1,
       PAY_DUTY2,
       PAY_DUTY3,
       PAY_CUMUL,
       PAY_CUMUL1,
       PAY_CUMUL2,
       PAY_CUMUL3,
       PAY_NOTENVD,
       PAY_NOTENVD1,
       PAY_NOTENVD2,
       PAY_NOTENVD3
      )
      values
      (
       1,
       user,
       nBASE_1,
       nBASE_1_1,
       nBASE_1_2,
       nBASE_1_3,
       nBASE_2,
       nBASE_2_1,
       nBASE_2_2,
       nBASE_2_3,
       nBASE_3,
       nBASE_3_1,
       nBASE_3_2,
       nBASE_3_3,
       nBASENOTENDV,
       nBASENOTENDV1,
       nBASENOTENDV2,
       nBASENOTENDV3,
       nTAX_DUTY_1,
       nTAX_DUTY_1_1,
       nTAX_DUTY_1_2,
       nTAX_DUTY_1_3,
       nTAX_DUTY_2,
       nTAX_DUTY_2_1,
       nTAX_DUTY_2_2,
       nTAX_DUTY_2_3,
       nTAX_DUTY_3,
       nTAX_DUTY_3_1,
       nTAX_DUTY_3_2,
       nTAX_DUTY_3_3,
       nTAX_DUTYNOTENDV,
       nTAX_DUTYNOTENDV1,
       nTAX_DUTYNOTENDV2,
       nTAX_DUTYNOTENDV3,
       nTAX_CUMUL_2,
       nTAX_CUMUL_2_1,
       nTAX_CUMUL_2_2,
       nTAX_CUMUL_2_3,
       nTAX_CUMUL_3,
       nTAX_CUMUL_3_1,
       nTAX_CUMUL_3_2,
       nTAX_CUMUL_3_3,
       nTAX_CUMULNOTENDV,
       nTAX_CUMULNOTENDV1,
       nTAX_CUMULNOTENDV2,
       nTAX_CUMULNOTENDV3,
       nPAY_DUTY,
       nPAY_DUTY1,
       nPAY_DUTY2,
       nPAY_DUTY3,
       nPAY_CUMUL,
       nPAY_CUMUL1,
       nPAY_CUMUL2,
       nPAY_CUMUL3,
       nPAY_NOTENVD,
       nPAY_NOTENVD1,
       nPAY_NOTENVD2,
       nPAY_NOTENVD3
       );

   begin
     update SLCST_EMPLOYER
        set TAX_PFR  = nTAX_DUTY_1+nTAX_DUTY_2+nTAX_DUTY_3,
            TAX_PFR1 = nTAX_DUTY_1_1+nTAX_DUTY_2_1+nTAX_DUTY_3_1,
            TAX_PFR2 = nTAX_DUTY_1_2+nTAX_DUTY_2_2+nTAX_DUTY_3_2,
            TAX_PFR3 = nTAX_DUTY_1_3+nTAX_DUTY_2_3+nTAX_DUTY_3_3,
            TAX_FSS  = nTAX_CUMUL_2+nTAX_CUMUL_3,
            TAX_FSS1 = nTAX_CUMUL_2_1+nTAX_CUMUL_3_1,
            TAX_FSS2 = nTAX_CUMUL_2_2+nTAX_CUMUL_3_2,
            TAX_FSS3 = nTAX_CUMUL_2_3+nTAX_CUMUL_3_3
      where AUTHID = user;
     if ( SQL%NOTFOUND ) then
        P_EXCEPTION( 0,'Запись плательщика налога не найдена.' );
     end if;
   end;
  end CALCDUTYPFR_CREATE;

/* Расчет по шкалам налогообложения обязательного страхования*/
procedure SCALEDUTYPFR_CREATE
(
 nCOMPANY        in number,
 nDEPARTMENT     in varchar2,                  -- подразделение
 nYEAR           in number,
 dPERIODBEGIN    in date,
 dPERIODEND      in date,
 nCHILDDEP       in number,                    -- признак учитывать все подчиненные подразделения
 nNEGOTIVE       in number,                    -- отриц налог. база
 nSCALE_DUTY     in number,                    -- правило выбора налоговой шкалы для страховой части ПФР
 nSCALE_CUMUL    in number,                    -- правило выбора налоговой шкалы для накопительной части ПФР
 nUSEENVD        in number,                    -- применяется ЕНВД
 n2005           in number default 0,          -- признак печати отчетности за 2005г
 nCLNPSPFMFGRP   in number default null        -- группа исполнений
)
as
 nTAXBASE_1          number;
 nTAXBASE_2          number;
 nTAXBASE_3          number;
 nTAXBASENOTENDV_1   number;
 nTAXBASENOTENDV_2   number;
 nTAXBASENOTENDV_3   number;
 nTAX_DUTY_1         number;
 nTAX_DUTY_2         number;
 nTAX_DUTY_3         number;
 nTAX_CUMUL_2        number;
 nTAX_CUMUL_3        number;
 aSCALE_DUTY_1       t_ASCALE := t_ASCALE();
 aSCALE_DUTY_2       t_ASCALE := t_ASCALE();
 aSCALE_DUTY_3       t_ASCALE := t_ASCALE();
 aSCALE_CUMUL_2      t_ASCALE := t_ASCALE();
 aSCALE_CUMUL_3      t_ASCALE := t_ASCALE();
 aTAX_DUTY_1         t_ATAXSUM := t_ATAXSUM();
 aTAX_DUTY_2         t_ATAXSUM := t_ATAXSUM();
 aTAX_DUTY_3         t_ATAXSUM := t_ATAXSUM();
 aTAX_DUTY_4         t_ATAXSUM := t_ATAXSUM();
 aTAX_DUTY_5         t_ATAXSUM := t_ATAXSUM();
 aTAX_DUTY_6         t_ATAXSUM := t_ATAXSUM();
 aTAX_CUMUL_2        t_ATAXSUM := t_ATAXSUM();
 aTAX_CUMUL_3        t_ATAXSUM := t_ATAXSUM();
 aTAX_DUTYITO_1      t_ATAXSUM := t_ATAXSUM();
 aTAX_DUTYITO_2      t_ATAXSUM := t_ATAXSUM();
 aTAX_DUTYITO_3      t_ATAXSUM := t_ATAXSUM();
 aTAX_DUTYITO_4      t_ATAXSUM := t_ATAXSUM();
 aTAX_DUTYITO_5      t_ATAXSUM := t_ATAXSUM();
 aTAX_DUTYITO_6      t_ATAXSUM := t_ATAXSUM();
 aTAX_CUMULITO_2     t_ATAXSUM := t_ATAXSUM();
 aTAX_CUMULITO_3     t_ATAXSUM := t_ATAXSUM();
 i                   number;
 j                   number;
 nMONTHBEGIN         number;
 nMONTHEND           number;
 nGROUP1             number(1);
 nGROUP2             number(1);
 nGROUP3             number(1);
 nTAXSCALEDUTY       number;
 nTAXSCALECUMUL      number;
procedure GET_SUMM
(
 nPERSRN              in number,
 nCLNPERSTAXACC       in number,
 nYEAR                in number,
 nMONTHBEGIN          in number,
 nMONTHEND            in number,
 nNEGOTIVE            in number
)
as
 nMAXVAL    number;
 nBASE_PFR  number;
 nBASE_DUTY number;
 nTAXBASE   number;
 nTAXBASENOTENDV number;
 nTAX_DUTY  number;
 nTAX_CUMUL number;
 nTMPVALUE  number;
 nCOUNT                number;
 dEND                  date;

begin
 nBASE_PFR       :=0;
 nBASE_DUTY      :=0;

 nTAXBASE        :=0;
 nTAXBASENOTENDV :=0;
 nTAX_DUTY       :=0;
 nTAX_CUMUL      :=0;

  if nNEGOTIVE = 1 then
     nMAXVAL:= -9999999999;
  else
     nMAXVAL:= 0;
  end if;
  dEND := add_months(INT2DATE(1,nMONTHEND,nYEAR),1)-1;
  select count(*)
   into nCOUNT
   from DUAL
   where exists
   (
    select A.CODE
    from
      CLNPERSADDINF I,
      SLANLSIGNS    A
    where I.PRN         = nPERSRN
      and I.BEGIN_DATE <= dEND
      and (I.END_DATE is null or I.END_DATE >= dEND)
      and I.SLANLSIGNS  = A.RN
      and trim(A.CODE) = 'ИНОСТРАНЕЦ'
    );
  if nCOUNT > 0 then
     return;
  end if;
  for cTAXPAYS in
  (
   select TC.PRN,
          TP.SLTAXACCS,
          TP.SUMME,
          TP.DISCOUNTSUMM,
          TP.MONTHNUMB,
          TR.TAXBASE,
          TR.STATE,
          TR.POS_CODE,
          TR.PRIVIL,
          TR1.DDCODE
    from CLNPERSTAXACCSP TP,
         CLNPERSTAXACC   TC,
         SLTAXACCS TR,
         SALINDEDUCT TR1
    where TC.RN = TP.PRN
      and TP.SLTAXACCS = TR.RN
      and TR.DEDCODE = TR1.RN (+)
      and TC.RN = nCLNPERSTAXACC
      and TP.MONTHNUMB>=nMONTHBEGIN
      and TP.MONTHNUMB<=nMONTHEND
      and (TR.TAXBASE = 4 or TR.TAXBASE = 8 or TR.TAXBASE = 9 or TR.TAXBASE = 10)
  )
  loop
     nTMPVALUE :=0;
     if cTAXPAYS.TAXBASE = 4 and cTAXPAYS.STATE =0 then                      -- доход ПФР
         if trim(cTAXPAYS.POS_CODE) = '7' then
            nTMPVALUE := cTAXPAYS.SUMME;
         end if;
         if trim(cTAXPAYS.DDCODE) = '1' then
            nTMPVALUE := cTAXPAYS.DISCOUNTSUMM;
         end if;
         if trim(cTAXPAYS.DDCODE) = '2' then
            nTMPVALUE := cTAXPAYS.DISCOUNTSUMM;
         end if;
         if trim(cTAXPAYS.DDCODE) = '3' then
            nTMPVALUE := cTAXPAYS.DISCOUNTSUMM;
         end if;
         if trim(cTAXPAYS.POS_CODE) = '1' and trim(cTAXPAYS.DDCODE) = '4' then
            nTMPVALUE := cTAXPAYS.DISCOUNTSUMM;
         end if;
         if trim(cTAXPAYS.POS_CODE) = '6' then
            nTMPVALUE := cTAXPAYS.DISCOUNTSUMM;
         end if;
         if trim(cTAXPAYS.POS_CODE) = '2' then
            nTMPVALUE := cTAXPAYS.SUMME;
          end if;
         nBASE_PFR:= nBASE_PFR + cTAXPAYS.SUMME - nTMPVALUE;                 -- налоговая база для ПФР
      elsif cTAXPAYS.TAXBASE = 8 and cTAXPAYS.STATE =0 then                  -- доход страховой части ПФР
          if trim(cTAXPAYS.POS_CODE) = '7' then
             nTMPVALUE := cTAXPAYS.SUMME;
          end if;
          if trim(cTAXPAYS.DDCODE) = '1' then
             nTMPVALUE := cTAXPAYS.DISCOUNTSUMM;
          end if;
          if trim(cTAXPAYS.DDCODE) = '2' then
             nTMPVALUE := cTAXPAYS.DISCOUNTSUMM;
          end if;
          if trim(cTAXPAYS.DDCODE) = '3' then
            nTMPVALUE := cTAXPAYS.DISCOUNTSUMM;
          end if;
          if trim(cTAXPAYS.POS_CODE) = '1' and trim(cTAXPAYS.DDCODE) = '4' then
             nTMPVALUE := cTAXPAYS.DISCOUNTSUMM;
          end if;
          if trim(cTAXPAYS.POS_CODE) = '6' then
             nTMPVALUE := cTAXPAYS.DISCOUNTSUMM;
          end if;
         if trim(cTAXPAYS.POS_CODE) = '2' then
            nTMPVALUE := cTAXPAYS.SUMME;
         end if;
          nBASE_DUTY := nBASE_DUTY + cTAXPAYS.SUMME - nTMPVALUE;
      elsif cTAXPAYS.TAXBASE = 8 and cTAXPAYS.STATE =2 then                  -- налог на страховую часть ПФР
            nTAX_DUTY := nTAX_DUTY + cTAXPAYS.SUMME;
      elsif cTAXPAYS.TAXBASE = 9 and cTAXPAYS.STATE =2 then                  -- налог на накопительную часть ПФР
            nTAX_CUMUL := nTAX_CUMUL + cTAXPAYS.SUMME;
      end if;
  end loop;
  nBASE_PFR       := greatest(nBASE_PFR ,nMAXVAL);
  nBASE_DUTY      := greatest(nBASE_DUTY ,nMAXVAL);
  if nUSEENVD = 0 then                      -- ЕНВД не применяется
     nTAXBASE        := nBASE_PFR;
     nTAXBASENOTENDV := 0;
  else
     nTAXBASE        := nBASE_DUTY;
     nTAXBASENOTENDV := nBASE_PFR;
  end if;
  if nGROUP1 = 1 then
     nTAXBASE_1  := nTAXBASE;
     nTAXBASENOTENDV_1 := nTAXBASENOTENDV;
     nTAX_DUTY_1 := nTAX_DUTY;
  elsif nGROUP2 = 1 then
     nTAXBASE_2 := nTAXBASE;
     nTAXBASENOTENDV_2 := nTAXBASENOTENDV;
     nTAX_DUTY_2 := nTAX_DUTY;
     nTAX_CUMUL_2 := nTAX_CUMUL;
  elsif nGROUP3 = 1 then
     nTAXBASE_3 := nTAXBASE;
     nTAXBASENOTENDV_3 := nTAXBASENOTENDV;
     nTAX_DUTY_3 := nTAX_DUTY;
     nTAX_CUMUL_3 := nTAX_CUMUL;
  end if;
end;
procedure GET_AGN
/* обработка сотрудника */
(
 nPERSRN         number,
 nAGENT          number,
 nCLNPERSTAXACC  number
)
as
 nSEX       number(1);
 dDATEBIRTH date;
 nYEARBIRH  number(4);
 nJUR_PERS  PKG_STD.tREF;
begin
 nTAXBASE_1   :=0;
 nTAXBASE_2   :=0;
 nTAXBASE_3   :=0;
 nTAXBASENOTENDV_1:=0;
 nTAXBASENOTENDV_2:=0;
 nTAXBASENOTENDV_3:=0;
 nTAX_DUTY_1  :=0;
 nTAX_DUTY_2  :=0;
 nTAX_DUTY_3  :=0;
 nTAX_CUMUL_2 :=0;
 nTAX_CUMUL_3 :=0;
 nGROUP1:=0;
 nGROUP2:=0;
 nGROUP3:=0;
 -- Предварительно нужно найти юрлицо, к которому относится контрагент
 begin
  select
    J.RN
  into
    nJUR_PERS
  from
    CLNPERSONS C,
    JURPERSONS J
  where C.RN = nPERSRN
    and C.OWNER_AGENT = J.AGENT
    and J.COMPANY = nCOMPANY;
  exception
     when NO_DATA_FOUND then
       nJUR_PERS := null;
 end;
 /* налоговая шкала для страховой части */
 FIND_SALTAXSCALE_RULE(nCOMPANY,nSCALE_DUTY,dPERIODEND,nAGENT,nJUR_PERS,nTAXSCALEDUTY);
 /* налоговая шкала для накопительной части */
 FIND_SALTAXSCALE_RULE(nCOMPANY,nSCALE_CUMUL,dPERIODEND,nAGENT,nJUR_PERS,nTAXSCALECUMUL);
 /* определение возрастных групп */
 select A.SEX into nSEX from AGNLIST A where A.RN = nAGENT;
 select A.AGNBURN into dDATEBIRTH from AGNLIST A where A.RN = nAGENT;
 nYEARBIRH := D_YEAR(dDATEBIRTH);
 if n2005 = 0 then
    if (nSEX<=1 and nYEARBIRH<=1952) or (nSEX=2 and nYEARBIRH<=1956) then
       nGROUP1 :=1;
      /* заполнение шкал */
      if nTAXSCALEDUTY is not null and aSCALE_DUTY_1(1).SUMM+aSCALE_DUTY_1(2).SUMM+aSCALE_DUTY_1(3).SUMM+aSCALE_DUTY_1(4).SUMM=0 then
         PKG_SLCST.GET_SCALE(aSCALE_DUTY_1,dPERIODEND,nTAXSCALEDUTY);
      end if;
    elsif (nSEX<=1 and nYEARBIRH >=1953 and nYEARBIRH <=1966) or (nSEX=2 and nYEARBIRH>=1957 and nYEARBIRH <=1966) then
       nGROUP2 :=1;
      if nTAXSCALEDUTY is not null and aSCALE_DUTY_2(1).SUMM+aSCALE_DUTY_2(2).SUMM+aSCALE_DUTY_2(3).SUMM+aSCALE_DUTY_2(4).SUMM=0 then
         PKG_SLCST.GET_SCALE(aSCALE_DUTY_2,dPERIODEND,nTAXSCALEDUTY);
      end if;
      if nTAXSCALECUMUL is not null and aSCALE_CUMUL_2(1).SUMM+aSCALE_CUMUL_2(2).SUMM+aSCALE_CUMUL_2(3).SUMM+aSCALE_CUMUL_2(4).SUMM=0 then
         PKG_SLCST.GET_SCALE(aSCALE_CUMUL_2,dPERIODEND,nTAXSCALECUMUL);
      end if;
    elsif nYEARBIRH >=1967 then
      nGROUP3 :=1;
      if nTAXSCALEDUTY is not null and aSCALE_DUTY_3(1).SUMM+aSCALE_DUTY_3(2).SUMM+aSCALE_DUTY_3(3).SUMM+aSCALE_DUTY_3(4).SUMM=0 then
         PKG_SLCST.GET_SCALE(aSCALE_DUTY_3,dPERIODEND,nTAXSCALEDUTY);
      end if;
      if nTAXSCALECUMUL is not null and aSCALE_CUMUL_3(1).SUMM+aSCALE_CUMUL_3(2).SUMM+aSCALE_CUMUL_3(3).SUMM+aSCALE_CUMUL_3(4).SUMM=0 then
         PKG_SLCST.GET_SCALE(aSCALE_CUMUL_3,dPERIODEND,nTAXSCALECUMUL);
      end if;
    end if;
 else
    if nYEARBIRH<=1966 then
       nGROUP1 :=1;
      /* заполнение шкал */
      if nTAXSCALEDUTY is not null and aSCALE_DUTY_1(1).SUMM+aSCALE_DUTY_1(2).SUMM+aSCALE_DUTY_1(3).SUMM+aSCALE_DUTY_1(4).SUMM=0 then
         PKG_SLCST.GET_SCALE(aSCALE_DUTY_1,dPERIODEND,nTAXSCALEDUTY);
      end if;
    elsif nYEARBIRH >=1967 then
       nGROUP2 :=1;
      if nTAXSCALEDUTY is not null and aSCALE_DUTY_2(1).SUMM+aSCALE_DUTY_2(2).SUMM+aSCALE_DUTY_2(3).SUMM+aSCALE_DUTY_2(4).SUMM=0 then
         PKG_SLCST.GET_SCALE(aSCALE_DUTY_2,dPERIODEND,nTAXSCALEDUTY);
      end if;
      if nTAXSCALECUMUL is not null and aSCALE_CUMUL_2(1).SUMM+aSCALE_CUMUL_2(2).SUMM+aSCALE_CUMUL_2(3).SUMM+aSCALE_CUMUL_2(4).SUMM=0 then
         PKG_SLCST.GET_SCALE(aSCALE_CUMUL_2,dPERIODEND,nTAXSCALECUMUL);
      end if;
    end if;
 end if;
 GET_SUMM(nPERSRN,nCLNPERSTAXACC,nYEAR,nMONTHBEGIN,nMONTHEND,nNEGOTIVE);
 PKG_SLCST.GET_TAXSUMM(aSCALE_DUTY_1,aTAX_DUTY_1,aTAX_DUTYITO_1,nTAXBASE_1,nTAX_DUTY_1,0);
 PKG_SLCST.GET_TAXSUMM(aSCALE_DUTY_2,aTAX_DUTY_2,aTAX_DUTYITO_2,nTAXBASE_2,nTAX_DUTY_2,0);
 PKG_SLCST.GET_TAXSUMM(aSCALE_DUTY_3,aTAX_DUTY_3,aTAX_DUTYITO_3,nTAXBASE_3,nTAX_DUTY_3,0);
 PKG_SLCST.GET_TAXSUMM(aSCALE_DUTY_1,aTAX_DUTY_4,aTAX_DUTYITO_4,nTAXBASENOTENDV_1,0,0,nTAXBASE_1);
 PKG_SLCST.GET_TAXSUMM(aSCALE_DUTY_2,aTAX_DUTY_5,aTAX_DUTYITO_5,nTAXBASENOTENDV_2,0,0,nTAXBASE_2);
 PKG_SLCST.GET_TAXSUMM(aSCALE_DUTY_3,aTAX_DUTY_6,aTAX_DUTYITO_6,nTAXBASENOTENDV_3,0,0,nTAXBASE_3);
 PKG_SLCST.GET_TAXSUMM(aSCALE_CUMUL_2,aTAX_CUMUL_2,aTAX_CUMULITO_2,nTAXBASE_2,nTAX_CUMUL_2,0);
 PKG_SLCST.GET_TAXSUMM(aSCALE_CUMUL_3,aTAX_CUMUL_3,aTAX_CUMULITO_3,nTAXBASE_3,nTAX_CUMUL_3,0);
 if nUSEENVD <> 1 then
    for i in 1..4
    loop
       aTAX_DUTYITO_4(i).BASESUMM := aTAX_DUTYITO_1(i).BASESUMM;
       aTAX_DUTYITO_5(i).BASESUMM := aTAX_DUTYITO_2(i).BASESUMM;
       aTAX_DUTYITO_6(i).BASESUMM := aTAX_DUTYITO_3(i).BASESUMM;
       aTAX_DUTYITO_4(i).NUMB := aTAX_DUTYITO_1(i).NUMB;
       aTAX_DUTYITO_5(i).NUMB := aTAX_DUTYITO_2(i).NUMB;
       aTAX_DUTYITO_6(i).NUMB := aTAX_DUTYITO_3(i).NUMB;
       aTAX_DUTYITO_4(i).DELTA := 0;
       aTAX_DUTYITO_5(i).DELTA := 0;
       aTAX_DUTYITO_6(i).DELTA := 0;
       aTAX_DUTY_4(i).BASESUMM := aTAX_DUTY_1(i).BASESUMM;
       aTAX_DUTY_5(i).BASESUMM := aTAX_DUTY_2(i).BASESUMM;
       aTAX_DUTY_6(i).BASESUMM := aTAX_DUTY_3(i).BASESUMM;
       aTAX_DUTY_4(i).NUMB := aTAX_DUTYITO_1(i).NUMB;
       aTAX_DUTY_5(i).NUMB := aTAX_DUTYITO_2(i).NUMB;
       aTAX_DUTY_6(i).NUMB := aTAX_DUTYITO_3(i).NUMB;
    end loop;
 end if;
end;
procedure INSERT_SCALE
as
begin
insert into SLCST_SCALEDUTYPFR
(
 RN,
 AUTHID,
 NAME,
 CODE,
 BASE_PFR_1,
 BASE_PFR_2,
 BASE_PFR_3,
 BASENOTENDV_PFR_1,
 BASENOTENDV_PFR_2,
 BASENOTENDV_PFR_3,
 PERSENT_DUTY_1,
 PERSENT_DUTY_2,
 PERSENT_DUTY_3,
 PERSENT_CUMUL_2,
 PERSENT_CUMUL_3,
 TAX_DUTY_1,
 TAX_DUTY_2,
 TAX_DUTY_3,
 TAX_CUMUL_2,
 TAX_CUMUL_3,
 QUANTITY_1,
 QUANTITY_2,
 QUANTITY_3,
 QUANTITYNOTENDV_1,
 QUANTITYNOTENDV_2,
 QUANTITYNOTENDV_3
)
values
(
 1,
 user,
 decode(n2005,0,'До 100 000 руб.',1,'До 280 000 руб.'),
 '100',
 round(aTAX_DUTYITO_1(1).BASESUMM,0),
 round(aTAX_DUTYITO_2(1).BASESUMM,0),
 round(aTAX_DUTYITO_3(1).BASESUMM,0),
 round(aTAX_DUTYITO_4(1).BASESUMM,0),
 round(aTAX_DUTYITO_5(1).BASESUMM,0),
 round(aTAX_DUTYITO_6(1).BASESUMM,0),
 aTAX_DUTYITO_1(1).PERCENT,
 aTAX_DUTYITO_2(1).PERCENT,
 aTAX_DUTYITO_3(1).PERCENT,
 aTAX_CUMULITO_2(1).PERCENT,
 aTAX_CUMULITO_3(1).PERCENT,
 round(aTAX_DUTYITO_1(1).TAXSUMM,0),
 round(aTAX_DUTYITO_2(1).TAXSUMM,0),
 round(aTAX_DUTYITO_3(1).TAXSUMM,0),
 round(aTAX_CUMULITO_2(1).TAXSUMM,0),
 round(aTAX_CUMULITO_3(1).TAXSUMM,0),
 aTAX_DUTYITO_1(1).NUMB,
 aTAX_DUTYITO_2(1).NUMB,
 aTAX_DUTYITO_3(1).NUMB,
 aTAX_DUTYITO_4(1).NUMB,
 aTAX_DUTYITO_5(1).NUMB,
 aTAX_DUTYITO_6(1).NUMB
);
insert into SLCST_SCALEDUTYPFR
(
 RN,
 AUTHID,
 NAME,
 CODE,
 BASE_PFR_1,
 BASE_PFR_2,
 BASE_PFR_3,
 BASENOTENDV_PFR_1,
 BASENOTENDV_PFR_2,
 BASENOTENDV_PFR_3,
 PERSENT_DUTY_1,
 PERSENT_DUTY_2,
 PERSENT_DUTY_3,
 PERSENT_CUMUL_2,
 PERSENT_CUMUL_3,
 TAX_DUTY_1,
 TAX_DUTY_2,
 TAX_DUTY_3,
 TAX_CUMUL_2,
 TAX_CUMUL_3,
 QUANTITY_1,
 QUANTITY_2,
 QUANTITY_3,
 QUANTITYNOTENDV_1,
 QUANTITYNOTENDV_2,
 QUANTITYNOTENDV_3
)
values
(
 1,
 user,
 decode(n2005,0,'От 100 001 руб. до 300 000 руб.',1,'От 280 001 до 600 000 руб.'),
 '200',
 round(aTAX_DUTYITO_1(2).BASESUMM,0),
 round(aTAX_DUTYITO_2(2).BASESUMM,0),
 round(aTAX_DUTYITO_3(2).BASESUMM,0),
 round(aTAX_DUTYITO_4(2).BASESUMM,0),
 round(aTAX_DUTYITO_5(2).BASESUMM,0),
 round(aTAX_DUTYITO_6(2).BASESUMM,0),
 -100,                   -- ставка - X
 -100,
 -100,
 -100,
 -100,
 round(aTAX_DUTYITO_1(2).TAXSUMM,0),
 round(aTAX_DUTYITO_2(2).TAXSUMM,0),
 round(aTAX_DUTYITO_3(2).TAXSUMM,0),
 round(aTAX_CUMULITO_2(2).TAXSUMM,0),
 round(aTAX_CUMULITO_3(2).TAXSUMM,0),
 aTAX_DUTYITO_1(2).NUMB,
 aTAX_DUTYITO_2(2).NUMB,
 aTAX_DUTYITO_3(2).NUMB,
 aTAX_DUTYITO_4(2).NUMB,
 aTAX_DUTYITO_5(2).NUMB,
 aTAX_DUTYITO_6(2).NUMB
);
insert into SLCST_SCALEDUTYPFR
(
 RN,
 AUTHID,
 NAME,
 CODE,
 BASE_PFR_1,
 BASE_PFR_2,
 BASE_PFR_3,
 BASENOTENDV_PFR_1,
 BASENOTENDV_PFR_2,
 BASENOTENDV_PFR_3,
 PERSENT_DUTY_1,
 PERSENT_DUTY_2,
 PERSENT_DUTY_3,
 PERSENT_CUMUL_2,
 PERSENT_CUMUL_3,
 TAX_DUTY_1,
 TAX_DUTY_2,
 TAX_DUTY_3,
 TAX_CUMUL_2,
 TAX_CUMUL_3,
 QUANTITY_1,
 QUANTITY_2,
 QUANTITY_3,
 QUANTITYNOTENDV_1,
 QUANTITYNOTENDV_2,
 QUANTITYNOTENDV_3
)
values
(
 1,
 user,
 decode(n2005,0,'100 000 руб.',1,'280 000 руб.'),
 '210',
 round(aTAX_DUTYITO_1(2).BASESUMM-aTAX_DUTY_1(2).BASESUMM,0),
 round(aTAX_DUTYITO_2(2).BASESUMM-aTAX_DUTY_2(2).BASESUMM,0),
 round(aTAX_DUTYITO_3(2).BASESUMM-aTAX_DUTY_3(2).BASESUMM,0),
 round(aTAX_DUTYITO_4(2).BASESUMM-aTAX_DUTY_4(2).BASESUMM-aTAX_DUTYITO_4(2).DELTA,0),
 round(aTAX_DUTYITO_5(2).BASESUMM-aTAX_DUTY_5(2).BASESUMM-aTAX_DUTYITO_5(2).DELTA,0),
 round(aTAX_DUTYITO_6(2).BASESUMM-aTAX_DUTY_6(2).BASESUMM-aTAX_DUTYITO_6(2).DELTA,0),
 aTAX_DUTYITO_1(2).SCALESUMM,
 aTAX_DUTYITO_2(2).SCALESUMM,
 aTAX_DUTYITO_3(2).SCALESUMM,
 aTAX_CUMULITO_2(2).SCALESUMM,
 aTAX_CUMULITO_3(2).SCALESUMM,
 round(aTAX_DUTYITO_1(2).TAXSUMM - aTAX_DUTY_1(2).TAXSUMM,0),
 round(aTAX_DUTYITO_2(2).TAXSUMM - aTAX_DUTY_2(2).TAXSUMM,0),
 round(aTAX_DUTYITO_3(2).TAXSUMM - aTAX_DUTY_3(2).TAXSUMM,0),
 round(aTAX_CUMULITO_2(2).TAXSUMM - aTAX_CUMUL_2(2).TAXSUMM,0),
 round(aTAX_CUMULITO_3(2).TAXSUMM - aTAX_CUMUL_3(2).TAXSUMM,0),
 aTAX_DUTYITO_1(2).NUMB,
 aTAX_DUTYITO_2(2).NUMB,
 aTAX_DUTYITO_3(2).NUMB,
 aTAX_DUTY_4(2).NUMB,
 aTAX_DUTY_5(2).NUMB,
 aTAX_DUTY_6(2).NUMB
);
insert into SLCST_SCALEDUTYPFR
(
 RN,
 AUTHID,
 NAME,
 CODE,
 BASE_PFR_1,
 BASE_PFR_2,
 BASE_PFR_3,
 BASENOTENDV_PFR_1,
 BASENOTENDV_PFR_2,
 BASENOTENDV_PFR_3,
 PERSENT_DUTY_1,
 PERSENT_DUTY_2,
 PERSENT_DUTY_3,
 PERSENT_CUMUL_2,
 PERSENT_CUMUL_3,
 TAX_DUTY_1,
 TAX_DUTY_2,
 TAX_DUTY_3,
 TAX_CUMUL_2,
 TAX_CUMUL_3,
 QUANTITY_1,
 QUANTITY_2,
 QUANTITY_3,
 QUANTITYNOTENDV_1,
 QUANTITYNOTENDV_2,
 QUANTITYNOTENDV_3
)
values
(
 1,
 user,
 decode(n2005,0,'свыше 100 000 руб.',1,'свыше 280 000 руб.'),
 '220',
 round(aTAX_DUTY_1(2).BASESUMM,0),
 round(aTAX_DUTY_2(2).BASESUMM,0),
 round(aTAX_DUTY_3(2).BASESUMM,0),
 round(aTAX_DUTY_4(2).BASESUMM,0),
 round(aTAX_DUTY_5(2).BASESUMM,0),
 round(aTAX_DUTY_6(2).BASESUMM,0),
 aTAX_DUTYITO_1(2).PERCENT,
 aTAX_DUTYITO_2(2).PERCENT,
 aTAX_DUTYITO_3(2).PERCENT,
 aTAX_CUMULITO_2(2).PERCENT,
 aTAX_CUMULITO_3(2).PERCENT,
 round(aTAX_DUTY_1(2).TAXSUMM,0),
 round(aTAX_DUTY_2(2).TAXSUMM,0),
 round(aTAX_DUTY_3(2).TAXSUMM,0),
 round(aTAX_CUMUL_2(2).TAXSUMM,0),
 round(aTAX_CUMUL_3(2).TAXSUMM,0),
 -100,
 -100,
 -100,
 -100,
 -100,
 -100
);
if n2005 = 0 then
   insert into SLCST_SCALEDUTYPFR
   (
    RN,
    AUTHID,
    NAME,
    CODE,
    BASE_PFR_1,
    BASE_PFR_2,
    BASE_PFR_3,
    BASENOTENDV_PFR_1,
    BASENOTENDV_PFR_2,
    BASENOTENDV_PFR_3,
    PERSENT_DUTY_1,
    PERSENT_DUTY_2,
    PERSENT_DUTY_3,
    PERSENT_CUMUL_2,
    PERSENT_CUMUL_3,
    TAX_DUTY_1,
    TAX_DUTY_2,
    TAX_DUTY_3,
    TAX_CUMUL_2,
    TAX_CUMUL_3,
    QUANTITY_1,
    QUANTITY_2,
    QUANTITY_3,
    QUANTITYNOTENDV_1,
    QUANTITYNOTENDV_2,
    QUANTITYNOTENDV_3
   )
   values
   (
    1,
    user,
    'От 300 001 руб. до 600 000 руб.',
    '300',
     round(aTAX_DUTYITO_1(3).BASESUMM,0),
     round(aTAX_DUTYITO_2(3).BASESUMM,0),
     round(aTAX_DUTYITO_3(3).BASESUMM,0),
     round(aTAX_DUTYITO_4(3).BASESUMM,0),
     round(aTAX_DUTYITO_5(3).BASESUMM,0),
     round(aTAX_DUTYITO_6(3).BASESUMM,0),
     -100,
     -100,
     -100,
     -100,
     -100,
    round(aTAX_DUTYITO_1(3).TAXSUMM,0),
    round(aTAX_DUTYITO_2(3).TAXSUMM,0),
    round(aTAX_DUTYITO_3(3).TAXSUMM,0),
    round(aTAX_CUMULITO_2(3).TAXSUMM,0),
    round(aTAX_CUMULITO_3(3).TAXSUMM,0),
    aTAX_DUTYITO_1(3).NUMB,
    aTAX_DUTYITO_2(3).NUMB,
    aTAX_DUTYITO_3(3).NUMB,
    aTAX_DUTYITO_4(3).NUMB,
    aTAX_DUTYITO_5(3).NUMB,
    aTAX_DUTYITO_6(3).NUMB
   );
end if;

insert into SLCST_SCALEDUTYPFR
(
 RN,
 AUTHID,
 NAME,
 CODE,
 BASE_PFR_1,
 BASE_PFR_2,
 BASE_PFR_3,
 BASENOTENDV_PFR_1,
 BASENOTENDV_PFR_2,
 BASENOTENDV_PFR_3,
 PERSENT_DUTY_1,
 PERSENT_DUTY_2,
 PERSENT_DUTY_3,
 PERSENT_CUMUL_2,
 PERSENT_CUMUL_3,
 TAX_DUTY_1,
 TAX_DUTY_2,
 TAX_DUTY_3,
 TAX_CUMUL_2,
 TAX_CUMUL_3,
 QUANTITY_1,
 QUANTITY_2,
 QUANTITY_3,
 QUANTITYNOTENDV_1,
 QUANTITYNOTENDV_2,
 QUANTITYNOTENDV_3
)
values
(
 1,
 user,
 decode(n2005,0,'300 000 руб.',1,'Свыше 600 000 руб.'),
 decode(n2005,0,'310',1,'300'),
 decode(n2005,0,round(aTAX_DUTYITO_1(3).BASESUMM - aTAX_DUTY_1(3).BASESUMM,0),1,round(aTAX_DUTYITO_1(3).BASESUMM,0)),
 decode(n2005,0,round(aTAX_DUTYITO_2(3).BASESUMM - aTAX_DUTY_2(3).BASESUMM,0),1,round(aTAX_DUTYITO_2(3).BASESUMM,0)),
 decode(n2005,0,round(aTAX_DUTYITO_3(3).BASESUMM - aTAX_DUTY_3(3).BASESUMM,0),1,round(aTAX_DUTYITO_3(3).BASESUMM,0)),
 decode(n2005,0,round(aTAX_DUTYITO_4(3).BASESUMM - aTAX_DUTY_4(3).BASESUMM,0),1,round(aTAX_DUTYITO_4(3).BASESUMM,0)),
 decode(n2005,0,round(aTAX_DUTYITO_5(3).BASESUMM - aTAX_DUTY_5(3).BASESUMM,0),1,round(aTAX_DUTYITO_5(3).BASESUMM,0)),
 decode(n2005,0,round(aTAX_DUTYITO_6(3).BASESUMM - aTAX_DUTY_6(3).BASESUMM,0),1,round(aTAX_DUTYITO_6(3).BASESUMM,0)),
 aTAX_DUTYITO_1(3).SCALESUMM,
 aTAX_DUTYITO_2(3).SCALESUMM,
 aTAX_DUTYITO_3(3).SCALESUMM,
 aTAX_CUMULITO_2(3).SCALESUMM,
 aTAX_CUMULITO_3(3).SCALESUMM,
 round(aTAX_DUTYITO_1(3).TAXSUMM - aTAX_DUTY_1(3).TAXSUMM,0),
 round(aTAX_DUTYITO_2(3).TAXSUMM - aTAX_DUTY_2(3).TAXSUMM,0),
 round(aTAX_DUTYITO_3(3).TAXSUMM - aTAX_DUTY_3(3).TAXSUMM,0),
 round(aTAX_CUMULITO_2(3).TAXSUMM - aTAX_CUMUL_2(3).TAXSUMM,0),
 round(aTAX_CUMULITO_3(3).TAXSUMM - aTAX_CUMUL_3(3).TAXSUMM,0),
 aTAX_DUTYITO_1(3).NUMB,
 aTAX_DUTYITO_2(3).NUMB,
 aTAX_DUTYITO_3(3).NUMB,
 aTAX_DUTYITO_4(3).NUMB,
 aTAX_DUTYITO_5(3).NUMB,
 aTAX_DUTYITO_6(3).NUMB
);
if n2005 = 0 then
   insert into SLCST_SCALEDUTYPFR
   (
    RN,
    AUTHID,
    NAME,
    CODE,
    BASE_PFR_1,
    BASE_PFR_2,
    BASE_PFR_3,
    BASENOTENDV_PFR_1,
    BASENOTENDV_PFR_2,
    BASENOTENDV_PFR_3,
    PERSENT_DUTY_1,
    PERSENT_DUTY_2,
    PERSENT_DUTY_3,
    PERSENT_CUMUL_2,
    PERSENT_CUMUL_3,
    TAX_DUTY_1,
    TAX_DUTY_2,
    TAX_DUTY_3,
    TAX_CUMUL_2,
    TAX_CUMUL_3,
    QUANTITY_1,
    QUANTITY_2,
    QUANTITY_3,
    QUANTITYNOTENDV_1,
    QUANTITYNOTENDV_2,
    QUANTITYNOTENDV_3
   )
   values
   (
    1,
    user,
    'свыше 300 000 руб.',
    '320',
    round(aTAX_DUTY_1(3).BASESUMM,0),
    round(aTAX_DUTY_2(3).BASESUMM,0),
    round(aTAX_DUTY_3(3).BASESUMM,0),
    round(aTAX_DUTY_4(3).BASESUMM,0),
    round(aTAX_DUTY_5(3).BASESUMM,0),
    round(aTAX_DUTY_6(3).BASESUMM,0),
    aTAX_DUTYITO_1(3).PERCENT,
    aTAX_DUTYITO_2(3).PERCENT,
    aTAX_DUTYITO_3(3).PERCENT,
    aTAX_CUMULITO_2(3).PERCENT,
    aTAX_CUMULITO_3(3).PERCENT,
    round(aTAX_DUTY_1(3).TAXSUMM,0),
    round(aTAX_DUTY_2(3).TAXSUMM,0),
    round(aTAX_DUTY_3(3).TAXSUMM,0),
    round(aTAX_CUMUL_2(3).TAXSUMM,0),
    round(aTAX_CUMUL_3(3).TAXSUMM,0),
    -100,
    -100,
    -100,
    -100,
    -100,
    -100
   );
   insert into SLCST_SCALEDUTYPFR
   (
    RN,
    AUTHID,
    NAME,
    CODE,
    BASE_PFR_1,
    BASE_PFR_2,
    BASE_PFR_3,
    BASENOTENDV_PFR_1,
    BASENOTENDV_PFR_2,
    BASENOTENDV_PFR_3,
    PERSENT_DUTY_1,
    PERSENT_DUTY_2,
    PERSENT_DUTY_3,
    PERSENT_CUMUL_2,
    PERSENT_CUMUL_3,
    TAX_DUTY_1,
    TAX_DUTY_2,
    TAX_DUTY_3,
    TAX_CUMUL_2,
    TAX_CUMUL_3,
    QUANTITY_1,
    QUANTITY_2,
    QUANTITY_3,
    QUANTITYNOTENDV_1,
    QUANTITYNOTENDV_2,
    QUANTITYNOTENDV_3
   )
   values
   (
    1,
    user,
    'Cвыше 600 000 руб.',
    '400',
    round(aTAX_DUTYITO_1(4).BASESUMM,0),
    round(aTAX_DUTYITO_2(4).BASESUMM,0),
    round(aTAX_DUTYITO_3(4).BASESUMM,0),
    round(aTAX_DUTYITO_4(4).BASESUMM,0),
    round(aTAX_DUTYITO_5(4).BASESUMM,0),
    round(aTAX_DUTYITO_6(4).BASESUMM,0),
    0,
    0,
    0,
    0,
    0,
    round(aTAX_DUTYITO_1(4).TAXSUMM,0),
    round(aTAX_DUTYITO_2(4).TAXSUMM,0),
    round(aTAX_DUTYITO_3(4).TAXSUMM,0),
    round(aTAX_CUMULITO_2(4).TAXSUMM,0),
    round(aTAX_CUMULITO_3(4).TAXSUMM,0),
    aTAX_DUTYITO_1(4).NUMB,
    aTAX_DUTYITO_2(4).NUMB,
    aTAX_DUTYITO_3(4).NUMB,
    aTAX_DUTYITO_4(4).NUMB,
    aTAX_DUTYITO_5(4).NUMB,
    aTAX_DUTYITO_6(4).NUMB
   );
end if;
insert into SLCST_SCALEDUTYPFR
(
 RN,
 AUTHID,
 NAME,
 CODE,
 BASE_PFR_1,
 BASE_PFR_2,
 BASE_PFR_3,
 BASENOTENDV_PFR_1,
 BASENOTENDV_PFR_2,
 BASENOTENDV_PFR_3,
 PERSENT_DUTY_1,
 PERSENT_DUTY_2,
 PERSENT_DUTY_3,
 PERSENT_CUMUL_2,
 PERSENT_CUMUL_3,
 TAX_DUTY_1,
 TAX_DUTY_2,
 TAX_DUTY_3,
 TAX_CUMUL_2,
 TAX_CUMUL_3,
 QUANTITY_1,
 QUANTITY_2,
 QUANTITY_3,
 QUANTITYNOTENDV_1,
 QUANTITYNOTENDV_2,
 QUANTITYNOTENDV_3
)
values
(
 1,
 user,
 'ИТОГО:',
 decode(n2005,0,'500',1,'400'),
 round(aTAX_DUTYITO_1(1).BASESUMM,0) + round(aTAX_DUTYITO_1(2).BASESUMM,0) + round(aTAX_DUTYITO_1(3).BASESUMM,0) + round(aTAX_DUTYITO_1(4).BASESUMM,0),
 round(aTAX_DUTYITO_2(1).BASESUMM,0) + round(aTAX_DUTYITO_2(2).BASESUMM,0) + round(aTAX_DUTYITO_2(3).BASESUMM,0) + round(aTAX_DUTYITO_2(4).BASESUMM,0),
 round(aTAX_DUTYITO_3(1).BASESUMM,0) + round(aTAX_DUTYITO_3(2).BASESUMM,0) + round(aTAX_DUTYITO_3(3).BASESUMM,0) + round(aTAX_DUTYITO_3(4).BASESUMM,0),
 round(aTAX_DUTYITO_4(1).BASESUMM,0) + round(aTAX_DUTYITO_4(2).BASESUMM,0) + round(aTAX_DUTYITO_4(3).BASESUMM,0) + round(aTAX_DUTYITO_4(4).BASESUMM,0),
 round(aTAX_DUTYITO_5(1).BASESUMM,0) + round(aTAX_DUTYITO_5(2).BASESUMM,0) + round(aTAX_DUTYITO_5(3).BASESUMM,0) + round(aTAX_DUTYITO_5(4).BASESUMM,0),
 round(aTAX_DUTYITO_6(1).BASESUMM,0) + round(aTAX_DUTYITO_6(2).BASESUMM,0) + round(aTAX_DUTYITO_6(3).BASESUMM,0) + round(aTAX_DUTYITO_6(4).BASESUMM,0),
 -100,
 -100,
 -100,
 -100,
 -100,
 round(aTAX_DUTYITO_1(1).TAXSUMM,0)  + round(aTAX_DUTYITO_1(2).TAXSUMM,0)  + round(aTAX_DUTYITO_1(3).TAXSUMM,0)  + round(aTAX_DUTYITO_1(4).TAXSUMM,0),
 round(aTAX_DUTYITO_2(1).TAXSUMM,0)  + round(aTAX_DUTYITO_2(2).TAXSUMM,0)  + round(aTAX_DUTYITO_2(3).TAXSUMM,0)  + round(aTAX_DUTYITO_2(4).TAXSUMM,0),
 round(aTAX_DUTYITO_3(1).TAXSUMM,0)  + round(aTAX_DUTYITO_3(2).TAXSUMM,0)  + round(aTAX_DUTYITO_3(3).TAXSUMM,0)  + round(aTAX_DUTYITO_3(4).TAXSUMM,0),
 round(aTAX_CUMULITO_2(1).TAXSUMM,0) + round(aTAX_CUMULITO_2(2).TAXSUMM,0) + round(aTAX_CUMULITO_2(3).TAXSUMM,0) + round(aTAX_CUMULITO_2(4).TAXSUMM,0),
 round(aTAX_CUMULITO_3(1).TAXSUMM,0) + round(aTAX_CUMULITO_3(2).TAXSUMM,0) + round(aTAX_CUMULITO_3(3).TAXSUMM,0) + round(aTAX_CUMULITO_3(4).TAXSUMM,0),
 aTAX_DUTYITO_1(1).NUMB + aTAX_DUTYITO_1(2).NUMB + aTAX_DUTYITO_1(3).NUMB + aTAX_DUTYITO_1(4).NUMB,
 aTAX_DUTYITO_2(1).NUMB + aTAX_DUTYITO_2(2).NUMB + aTAX_DUTYITO_2(3).NUMB + aTAX_DUTYITO_2(4).NUMB,
 aTAX_DUTYITO_3(1).NUMB + aTAX_DUTYITO_3(2).NUMB + aTAX_DUTYITO_3(3).NUMB + aTAX_DUTYITO_3(4).NUMB,
 aTAX_DUTYITO_4(1).NUMB + aTAX_DUTYITO_4(2).NUMB + aTAX_DUTYITO_4(3).NUMB + aTAX_DUTYITO_4(4).NUMB,
 aTAX_DUTYITO_5(1).NUMB + aTAX_DUTYITO_5(2).NUMB + aTAX_DUTYITO_5(3).NUMB + aTAX_DUTYITO_5(4).NUMB,
 aTAX_DUTYITO_6(1).NUMB + aTAX_DUTYITO_6(2).NUMB + aTAX_DUTYITO_6(3).NUMB + aTAX_DUTYITO_6(4).NUMB
);
end;
begin
 nMONTHBEGIN := D_MONTH(dPERIODBEGIN);
 nMONTHEND   := D_MONTH(dPERIODEND);
  /* инициализация массивов */
  /* налоговые шкалы */
  for i in 1..4
  loop
      aSCALE_DUTY_1.EXTEND;
      aSCALE_DUTY_1(i).INCOME:=0;
      aSCALE_DUTY_1(i).SUMM:=0;
      aSCALE_DUTY_1(i).PERCENT:=0;

      aSCALE_DUTY_2.EXTEND;
      aSCALE_DUTY_2(i).INCOME:=0;
      aSCALE_DUTY_2(i).SUMM:=0;
      aSCALE_DUTY_2(i).PERCENT:=0;

      aSCALE_DUTY_3.EXTEND;
      aSCALE_DUTY_3(i).INCOME:=0;
      aSCALE_DUTY_3(i).SUMM:=0;
      aSCALE_DUTY_3(i).PERCENT:=0;


      aSCALE_CUMUL_2.EXTEND;
      aSCALE_CUMUL_2(i).INCOME:=0;
      aSCALE_CUMUL_2(i).SUMM:=0;
      aSCALE_CUMUL_2(i).PERCENT:=0;

      aSCALE_CUMUL_3.EXTEND;
      aSCALE_CUMUL_3(i).INCOME:=0;
      aSCALE_CUMUL_3(i).SUMM:=0;
      aSCALE_CUMUL_3(i).PERCENT:=0;

      aTAX_DUTY_1.EXTEND;
      aTAX_DUTY_1(i).BASESUMM   :=0;
      aTAX_DUTY_1(i).TAXSUMM    :=0;
      aTAX_DUTY_1(i).NUMB       :=0;
      aTAX_DUTY_1(i).SCALESUMM  :=0;
      aTAX_DUTY_1(i).PERCENT    :=0;

      aTAX_DUTY_2.EXTEND;
      aTAX_DUTY_2(i).BASESUMM   :=0;
      aTAX_DUTY_2(i).TAXSUMM    :=0;
      aTAX_DUTY_2(i).NUMB       :=0;
      aTAX_DUTY_2(i).SCALESUMM  :=0;
      aTAX_DUTY_2(i).PERCENT    :=0;

      aTAX_DUTY_3.EXTEND;
      aTAX_DUTY_3(i).BASESUMM   :=0;
      aTAX_DUTY_3(i).TAXSUMM    :=0;
      aTAX_DUTY_3(i).NUMB       :=0;
      aTAX_DUTY_3(i).SCALESUMM  :=0;
      aTAX_DUTY_3(i).PERCENT    :=0;

      aTAX_DUTY_4.EXTEND;
      aTAX_DUTY_4(i).BASESUMM   :=0;
      aTAX_DUTY_4(i).TAXSUMM    :=0;
      aTAX_DUTY_4(i).NUMB       :=0;
      aTAX_DUTY_4(i).SCALESUMM  :=0;
      aTAX_DUTY_4(i).PERCENT    :=0;

      aTAX_DUTY_5.EXTEND;
      aTAX_DUTY_5(i).BASESUMM   :=0;
      aTAX_DUTY_5(i).TAXSUMM    :=0;
      aTAX_DUTY_5(i).NUMB       :=0;
      aTAX_DUTY_5(i).SCALESUMM  :=0;
      aTAX_DUTY_5(i).PERCENT    :=0;

      aTAX_DUTY_6.EXTEND;
      aTAX_DUTY_6(i).BASESUMM   :=0;
      aTAX_DUTY_6(i).TAXSUMM    :=0;
      aTAX_DUTY_6(i).NUMB       :=0;
      aTAX_DUTY_6(i).SCALESUMM  :=0;
      aTAX_DUTY_6(i).PERCENT    :=0;

      aTAX_CUMUL_2.EXTEND;
      aTAX_CUMUL_2(i).BASESUMM   :=0;
      aTAX_CUMUL_2(i).TAXSUMM    :=0;
      aTAX_CUMUL_2(i).NUMB       :=0;
      aTAX_CUMUL_2(i).SCALESUMM  :=0;
      aTAX_CUMUL_2(i).PERCENT    :=0;

      aTAX_CUMUL_3.EXTEND;
      aTAX_CUMUL_3(i).BASESUMM   :=0;
      aTAX_CUMUL_3(i).TAXSUMM    :=0;
      aTAX_CUMUL_3(i).NUMB       :=0;
      aTAX_CUMUL_3(i).SCALESUMM  :=0;
      aTAX_CUMUL_3(i).PERCENT    :=0;

      aTAX_DUTYITO_1.EXTEND;
      aTAX_DUTYITO_1(i).BASESUMM   :=0;
      aTAX_DUTYITO_1(i).TAXSUMM    :=0;
      aTAX_DUTYITO_1(i).NUMB       :=0;
      aTAX_DUTYITO_1(i).SCALESUMM  :=0;
      aTAX_DUTYITO_1(i).PERCENT    :=0;

      aTAX_DUTYITO_2.EXTEND;
      aTAX_DUTYITO_2(i).BASESUMM   :=0;
      aTAX_DUTYITO_2(i).TAXSUMM    :=0;
      aTAX_DUTYITO_2(i).NUMB       :=0;
      aTAX_DUTYITO_2(i).SCALESUMM  :=0;
      aTAX_DUTYITO_2(i).PERCENT    :=0;

      aTAX_DUTYITO_3.EXTEND;
      aTAX_DUTYITO_3(i).BASESUMM   :=0;
      aTAX_DUTYITO_3(i).TAXSUMM    :=0;
      aTAX_DUTYITO_3(i).NUMB       :=0;
      aTAX_DUTYITO_3(i).SCALESUMM  :=0;
      aTAX_DUTYITO_3(i).PERCENT    :=0;

      aTAX_DUTYITO_4.EXTEND;
      aTAX_DUTYITO_4(i).BASESUMM   :=0;
      aTAX_DUTYITO_4(i).TAXSUMM    :=0;
      aTAX_DUTYITO_4(i).NUMB       :=0;
      aTAX_DUTYITO_4(i).SCALESUMM  :=0;
      aTAX_DUTYITO_4(i).PERCENT    :=0;
      aTAX_DUTYITO_4(i).DELTA      :=0;

      aTAX_DUTYITO_5.EXTEND;
      aTAX_DUTYITO_5(i).BASESUMM   :=0;
      aTAX_DUTYITO_5(i).TAXSUMM    :=0;
      aTAX_DUTYITO_5(i).NUMB       :=0;
      aTAX_DUTYITO_5(i).SCALESUMM  :=0;
      aTAX_DUTYITO_5(i).PERCENT    :=0;
      aTAX_DUTYITO_5(i).DELTA      :=0;

      aTAX_DUTYITO_6.EXTEND;
      aTAX_DUTYITO_6(i).BASESUMM   :=0;
      aTAX_DUTYITO_6(i).TAXSUMM    :=0;
      aTAX_DUTYITO_6(i).NUMB       :=0;
      aTAX_DUTYITO_6(i).SCALESUMM  :=0;
      aTAX_DUTYITO_6(i).PERCENT    :=0;
      aTAX_DUTYITO_6(i).DELTA      :=0;

      aTAX_CUMULITO_2.EXTEND;
      aTAX_CUMULITO_2(i).BASESUMM   :=0;
      aTAX_CUMULITO_2(i).TAXSUMM    :=0;
      aTAX_CUMULITO_2(i).NUMB       :=0;
      aTAX_CUMULITO_2(i).SCALESUMM  :=0;
      aTAX_CUMULITO_2(i).PERCENT    :=0;

      aTAX_CUMULITO_3.EXTEND;
      aTAX_CUMULITO_3(i).BASESUMM   :=0;
      aTAX_CUMULITO_3(i).TAXSUMM    :=0;
      aTAX_CUMULITO_3(i).NUMB       :=0;
      aTAX_CUMULITO_3(i).SCALESUMM  :=0;
      aTAX_CUMULITO_3(i).PERCENT    :=0;

   end loop;
 /* список сотрудников выбранного подразделения */
 if nDEPARTMENT is null and nCLNPSPFMFGRP is null then               -- вся организация
    for cTAX in
    (
      Select CP.PERSRN,
            TC.RN as CLNPERSTAXACC,
            CN.PERS_AGENT
       from CLNPSPFM CP,
            CLNPERSTAXACC TC,
            CLNPERSONS CN
       where CP.PERSRN = TC.PRN
         and CP.PERSRN = CN.RN
         and CP.COMPANY = nCOMPANY
         and TC.TYPE = 0
         and TC.YEAR = nYEAR
       group by CP.PERSRN, TC.RN, CN.PERS_AGENT
      )
      loop
         GET_AGN(cTAX.PERSRN,cTAX.PERS_AGENT,cTAX.CLNPERSTAXACC);
      end loop;
  elsif nDEPARTMENT is not null and nCHILDDEP=1 then   -- включать все подчиненные подразделения
      for cTAX in
      (
       Select CP.PERSRN,
              TC.RN as CLNPERSTAXACC,
              CN.PERS_AGENT
         from CLNPSPFM CP,
              CLNPERSTAXACC TC,
              CLNPERSONS CN
         where CP.PERSRN = TC.PRN
           and CP.PERSRN = CN.RN
           and CP.DEPTRN in (Select RN from INS_DEPARTMENT start with rn = nDEPARTMENT  connect by prior RN=PRN)
           and TC.TYPE = 0
           and TC.YEAR = nYEAR
         group by CP.PERSRN,TC.RN, CN.PERS_AGENT
      )
      loop
        GET_AGN(cTAX.PERSRN,cTAX.PERS_AGENT,cTAX.CLNPERSTAXACC);
      end loop;
  elsif nDEPARTMENT is not null and nCHILDDEP=0 then  -- без подчиненных подразделений
      for cTAX in
      (
       Select CP.PERSRN,
              TC.RN as CLNPERSTAXACC,
              CN.PERS_AGENT
         from CLNPSPFM CP,
              CLNPERSTAXACC TC,
              CLNPERSONS CN
         where CP.PERSRN = TC.PRN
           and CP.PERSRN = CN.RN
           and CP.DEPTRN = nDEPARTMENT
           and TC.TYPE = 0
           and TC.YEAR = nYEAR
         group by CP.PERSRN,TC.RN,CN.PERS_AGENT
      )
      loop
         GET_AGN(cTAX.PERSRN,cTAX.PERS_AGENT,cTAX.CLNPERSTAXACC);
      end loop;
  elsif nDEPARTMENT is null and nCLNPSPFMFGRP is not null then -- группы исполнений
      for cTAX in
      (
       Select CP.PERSRN,
              TC.RN as CLNPERSTAXACC,
              CN.PERS_AGENT
         from CLNPSPFMFGRPSP CPS,
              CLNPSPFM CP,
              CLNPERSTAXACC TC,
              CLNPERSONS CN
         where CPS.CLNPSPFM = CP.RN
           and CP.PERSRN = TC.PRN
           and CP.PERSRN = CN.RN
           and CPS.PRN = nCLNPSPFMFGRP
           and TC.TYPE = 0
           and TC.YEAR = nYEAR
         group by CP.PERSRN,TC.RN,CN.PERS_AGENT
      )
      loop
         GET_AGN(cTAX.PERSRN,cTAX.PERS_AGENT,cTAX.CLNPERSTAXACC);
      end loop;
 end if;
 DELTA_SCALE(aTAX_DUTYITO_1);
 DELTA_SCALE(aTAX_DUTYITO_2);
 DELTA_SCALE(aTAX_DUTYITO_3);
 DELTA_SCALE(aTAX_DUTYITO_4);
 DELTA_SCALE(aTAX_DUTYITO_5);
 DELTA_SCALE(aTAX_DUTYITO_6);
 DELTA_SCALE(aTAX_CUMULITO_2);
 DELTA_SCALE(aTAX_CUMULITO_3);
 INSERT_SCALE;
end SCALEDUTYPFR_CREATE;

  /* Корректировка округленных данных */
  procedure DELTA
  (
   nVALUE         in number,
   nVALUE1        in out number,
   nVALUE2        in out number,
   nVALUE3        in out number
  )
  as
   nDELTA       number(17);
  begin
    /* nVALUE = nVALUE1+nVALUE2+nVALUE3 */
   nDELTA := nVALUE - (nVALUE1+nVALUE2+nVALUE3);
   if nDELTA <> 0 then
      if nVALUE1 <> 0 then
         nVALUE1:=nVALUE1+nDELTA;
      else
         if nVALUE2 <> 0 then
            nVALUE2:=nVALUE2+nDELTA;
         else
            if nVALUE3 <> 0 then
               nVALUE3:=nVALUE3+nDELTA;
            end if;
         end if;
      end if;
   end if;
  end DELTA;


procedure GET_PARM
(
 sWORD1     in varchar2,
 sWORD2     in varchar2,
 nCLNPER    in number,
 nPARSM_RN  out number
)
 as
  begin
   select
     A.RN
    into
     nPARSM_RN
    from
     DOCS_PROPS_VALS A,
     DOCS_PROPS_LINKS B
    where A.UNIT_RN = nCLNPER
      and A.UNITCODE='ClientPersons'
      and A.DOCS_PROP_RN = B.PRN
      and A.UNITCODE = B.UNITCODE
      and upper(B.NAME) like sWORD1
      and upper(B.NAME) like sWORD2
      and rownum<2;
   exception
      when NO_DATA_FOUND then nPARSM_RN := null;
end;

procedure GET_SCALE
(
 aSCALE          in out t_ASCALE,
 dDATE           in date,
 nTAXSCALE       in number                    -- налоговая шкала для ПФР
)
as
 ii         integer;
 i          integer;
begin
  ii := 0;
  for i in 1..4
  loop
     aSCALE(i).INCOME  := 0;
     aSCALE(i).SUMM    := 0;
     aSCALE(i).PERCENT := 0;
  end loop;
  for cTAXSCALE in
  (
   select SS.INCOME,
          SS.SUMM,
          SS.PERCENT
     from SALTAXSTRUC SS,
          SALTAXEDITS SE,
          SALTAXSCALE SC
    where SS.PRN = SE.RN
       and SE.PRN = SC.RN
       and SC.RN = nTAXSCALE
       and SE.EDTAX_BEGIN =
        (
          select max(SE.EDTAX_BEGIN )
            from SALTAXEDITS SE
            where SE.PRN = nTAXSCALE
              and SE.EDTAX_BEGIN <= dDATE
        )
     order by SS.INCOME
  )
  loop
    ii := ii + 1;
    if ii <= 4 then
       aSCALE(ii).INCOME  := cTAXSCALE.INCOME;
       aSCALE(ii).SUMM    := cTAXSCALE.SUMM;
       aSCALE(ii).PERCENT := cTAXSCALE.PERCENT;
    end if;
  end loop;
end;

procedure GET_TAXSUMM
(
 aSCALE     in out t_ASCALE,
 aTAX       in out t_ATAXSUM,
 aTAXITO    in out t_ATAXSUM,
 nTAXBASE   in number,
 nTAX       in number,
 nDELTA     in number,
 nSCALE     in number default 0
)
as
 i          integer;
 nTAXSCALE  number(17);
 nSCALEDELTA number(17);
begin
  -- Сумма для определения нужной шкалы может быть передана отдельно
  if nSCALE = 0 then
    nTAXSCALE := nTAXBASE;
  else
    nTAXSCALE := nSCALE;
  end if;
  for i in 1..4
  loop
    if i>1 then
       if nTAXSCALE+nDELTA>aSCALE(i-1).INCOME and nTAXSCALE+nDELTA<=aSCALE(i).INCOME then
          aTAXITO(i).BASESUMM := aTAXITO(i).BASESUMM + nTAXBASE;
          aTAXITO(i).TAXSUMM  := aTAXITO(i).TAXSUMM + nTAX;
          if nTAXBASE>0 then
             aTAXITO(i).NUMB  := aTAXITO(i).NUMB + 1;
          end if;
          nSCALEDELTA := nTAXBASE+nDELTA-aSCALE(i-1).INCOME;
          if nSCALEDELTA < 0 then
            aTAXITO(i).DELTA := aTAXITO(i).DELTA + nTAXBASE + nDELTA;
          else
            aTAX(i).BASESUMM := aTAX(i).BASESUMM + nSCALEDELTA;
            aTAX(i).TAXSUMM  := aTAX(i).TAXSUMM + nSCALEDELTA * aSCALE(i).PERCENT/100;
          end if;
          --aTAX(i).TAXSUMM  := aTAX(i).TAXSUMM  + nTAX-aSCALE(i).SUMM;

          if nTAXBASE-aSCALE(i-1).INCOME>=0 then
             aTAX(i).NUMB  := aTAX(i).NUMB + 1;
          end if;
       end if;
    else
       if nTAXSCALE+nDELTA<=aSCALE(i).INCOME then
          aTAXITO(i).BASESUMM := aTAXITO(i).BASESUMM + nTAXBASE;
          aTAXITO(i).TAXSUMM  := aTAXITO(i).TAXSUMM + nTAX;
          if nTAXBASE>0 then
             aTAXITO(i).NUMB  := aTAXITO(i).NUMB + 1;
             aTAX(i).NUMB  := aTAX(i).NUMB + 1;
          end if;

          aTAX(i).BASESUMM := aTAX(i).BASESUMM + nTAXBASE;
          aTAX(i).TAXSUMM  := aTAX(i).TAXSUMM  + nTAX;
       end if;
    end if;
    aTAXITO(i).SCALESUMM := aSCALE(i).SUMM;
    aTAXITO(i).PERCENT   := aSCALE(i).PERCENT;
    aTAX(i).SCALESUMM := aSCALE(i).SUMM;
    aTAX(i).PERCENT   := aSCALE(i).PERCENT;
  end loop;
end;

/* процедура расчета ПФР */
procedure CALC_PFR
(
 nAGENT               in number,             -- КАФЛ
 nPERSRN              in number,             -- Сотрудник
 nCLNPERSTAXACC       in number,             -- Налоговая карточка
 nYEAR                in number,
 nMONTHBEGIN          in number,
 nMONTHEND            in number,
 nINVAL3              in number,             -- Формировать данные по инвалидам раздел 3
 nENVD3               in number,             -- Формировать данные по ЕНВД раздел 3
 nMAXINCOME           in number,             -- Максимальная облагаемая база
 n4FSS                in number default 0    -- Расчет для (0 - РСВ-1, 1 - 4-ФСС, 2 - Инд.карточка)
)
as
 rCALC                SLCST_RSV1%rowtype;
 nINV                 integer := 0;
 nENVD                integer;
 nRESIDENT            integer;
 nBIRTH               number(4);
 nBIRTH_MORE66        SLCST_RSV1.BIRTH_MORE66%TYPE := 0;
 dBGN                 date;
 dEND                 date;
 dINVBGN              date;
 dINVEND              date;
 nALLINCOME           SLPAYS.SUM%TYPE := 0;
 nALLINCOME1          SLPAYS.SUM%TYPE := 0;
 nALLINCOMENOT        SLPAYS.SUM%TYPE := 0;
 nALLINCOMENOT1       SLPAYS.SUM%TYPE := 0;
 nD                   SLPAYS.SUM%TYPE;
 nDI                  SLPAYS.SUM%TYPE;
 nDE                  SLPAYS.SUM%TYPE;
 nDELTA               SLPAYS.SUM%TYPE;

  procedure INIT_RECORD
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
  end INIT_RECORD;

  procedure INS_RECORD
  (
    nMONTH            in number,
    nFSS              in number
  )
  as
  begin
    update SLCST_RSV1
       set COMP         = COMP + rCALC.COMP,
           COMP_INV     = COMP_INV + rCALC.COMP_INV,
           COMP_ENVD    = COMP_ENVD + rCALC.COMP_ENVD,
           DEDUCT       = DEDUCT + rCALC.DEDUCT,
           DEDUCT_INV   = DEDUCT_INV + rCALC.DEDUCT_INV,
           DEDUCT_ENVD  = DEDUCT_ENVD + rCALC.DEDUCT_ENVD,
           SUD          = SUD + rCALC.SUD,
           SUD_INV      = SUD_INV + rCALC.SUD_INV,
           MAXIMUM      = MAXIMUM + rCALC.MAXIMUM,
           MAXIMUM_INV  = MAXIMUM_INV + rCALC.MAXIMUM_INV,
           MAXIMUM_ENVD = MAXIMUM_ENVD + rCALC.MAXIMUM_ENVD,
           NPFR         = NPFR + rCALC.NPFR,
           NPFR_INV     = NPFR_INV + rCALC.NPFR_INV,
           NPFR_ENVD    = NPFR_ENVD + rCALC.NPFR_ENVD,
           SPFR         = SPFR + rCALC.SPFR,
           SPFR_INV     = SPFR_INV + rCALC.SPFR_INV,
           SPFR_ENVD    = SPFR_ENVD + rCALC.SPFR_ENVD,
           FFOMS        = FFOMS + rCALC.FFOMS,
           FFOMS_INV    = FFOMS_INV + rCALC.FFOMS_INV,
           FFOMS_ENVD   = FFOMS_ENVD + rCALC.FFOMS_ENVD,
           TFOMS        = TFOMS + rCALC.TFOMS,
           TFOMS_INV    = TFOMS_INV + rCALC.TFOMS_INV,
           TFOMS_ENVD   = TFOMS_ENVD + rCALC.TFOMS_ENVD,
           AUTHOR       = AUTHOR + rCALC.AUTHOR,
           AUTHOR_INV   = AUTHOR_INV + rCALC.AUTHOR_INV,
           AUTHOR_ENVD  = AUTHOR_ENVD + rCALC.AUTHOR_ENVD
     where MONTHNUMB = nMONTH
       and BIRTH_MORE66 = nBIRTH_MORE66
       and FSS = nFSS;
    if ( SQL%NOTFOUND ) then
      insert into SLCST_RSV1
      (
        MONTHNUMB,
        BIRTH_MORE66,
        FSS,
        COMP,
        COMP_INV,
        COMP_ENVD,
        DEDUCT,
        DEDUCT_INV,
        DEDUCT_ENVD,
        SUD,
        SUD_INV,
        MAXIMUM,
        MAXIMUM_INV,
        MAXIMUM_ENVD,
        NPFR,
        NPFR_INV,
        NPFR_ENVD,
        SPFR,
        SPFR_INV,
        SPFR_ENVD,
        FFOMS,
        FFOMS_INV,
        FFOMS_ENVD,
        TFOMS,
        TFOMS_INV,
        TFOMS_ENVD,
        AUTHOR,
        AUTHOR_INV,
        AUTHOR_ENVD
      )
      values
      (
        nMONTH,
        nBIRTH_MORE66,
        nFSS,
        rCALC.COMP,
        rCALC.COMP_INV,
        rCALC.COMP_ENVD,
        rCALC.DEDUCT,
        rCALC.DEDUCT_INV,
        rCALC.DEDUCT_ENVD,
        rCALC.SUD,
        rCALC.SUD_INV,
        rCALC.MAXIMUM,
        rCALC.MAXIMUM_INV,
        rCALC.MAXIMUM_ENVD,
        rCALC.NPFR,
        rCALC.NPFR_INV,
        rCALC.NPFR_ENVD,
        rCALC.SPFR,
        rCALC.SPFR_INV,
        rCALC.SPFR_ENVD,
        rCALC.FFOMS,
        rCALC.FFOMS_INV,
        rCALC.FFOMS_ENVD,
        rCALC.TFOMS,
        rCALC.TFOMS_INV,
        rCALC.TFOMS_ENVD,
        rCALC.AUTHOR,
        rCALC.AUTHOR_INV,
        rCALC.AUTHOR_ENVD
      );
    end if;
 end INS_RECORD;

begin
  /* Год рождения */
  begin
    select D_YEAR(AGNBURN)
      into nBIRTH
      from AGNLIST
     where RN = nAGENT;
  exception
    when NO_DATA_FOUND then
      nBIRTH := 0;
  end;
  if nBIRTH > 1966 then
    nBIRTH_MORE66 := 1;
  end if;

  /* Резидент / Нерезидент */
  begin
    select RESIDENT_SIGN
      into nRESIDENT
      from CLNPERSTAXACC
     where RN = nCLNPERSTAXACC;
  exception
    when NO_DATA_FOUND then
      nRESIDENT := 0;
  end;

  /* определяем ЕНВД */
  select count(*)
    into nENVD
    from DUAL
    where exists
          (
            select null
              from CLNPERSTAXACCSP TP,
                   CLNPERSTAXACC   TC,
                   SLTAXACCS       TR
             where TC.RN        = TP.PRN
               and TP.SLTAXACCS = TR.RN
               and TC.RN        = nCLNPERSTAXACC
               and TP.MONTHNUMB >= nMONTHBEGIN
               and TP.MONTHNUMB <= nMONTHEND
               and TR.TAXBASE = 10);

  /* Помесячный расчет */
  for i in nMONTHBEGIN..nMONTHEND
  loop
    INIT_RECORD;

    if nINVAL3 = 1 then
      /* определяем инвалидность */
      dBGN := INT2DATE(1, i, nYEAR);
      dEND := last_day(dBGN);
      dINVBGN := null;
      dINVEND := null;
      for rec in
      (
        select DATEBEG,
               DATEEND
          from AGNDISABLED
         where PRN = nAGENT
           and DATEBEG <= dEND
           and (DATEEND >= dBGN or DATEEND is null)
         order by DATEBEG
      )
      loop
        if dINVBGN is null then
          if rec.DATEBEG <= dBGN then
            dINVBGN := dBGN;
          else
            exit;
          end if;
        end if;
        if dINVEND is null or (dINVEND + 1 >= rec.DATEBEG) then
          dINVEND := greatest(nvl(dINVEND,dBGN),least(dEND,nvl(rec.DATEEND,dEND)));
        else
          exit;
        end if;
      end loop;
      nINV := CMP_DAT(dBGN,dINVBGN) * CMP_DAT(dEND,dINVEND);
    end if;

    for cTAXPAYS in
    (
     select TC.PRN,
            TP.SLTAXACCS,
            TP.SUMME,
            TP.DISCOUNTSUMM,
            TP.MONTHNUMB,
            TR.TAXBASE,
            TR.STATE,
            TR.POS_CODE,
            TR.PRIVIL,
            TR1.DDCODE,
            TR.TA_TYPE
       from CLNPERSTAXACCSP TP,
            CLNPERSTAXACC   TC,
            SLTAXACCS       TR,
            SALINDEDUCT     TR1
      where TC.RN        = TP.PRN
        and TP.SLTAXACCS = TR.RN
        and TR.DEDCODE   = TR1.RN(+)
        and TC.RN        = nCLNPERSTAXACC
        and TP.MONTHNUMB = i
        and ((n4FSS in (0,2) and ((TR.STATE = 2 and TR.TAXBASE in (5,6,8,9)) or (TR.STATE = 0 and TR.TAXBASE in (8,10)))) or
             (n4FSS = 1 and TR.STATE in (0,2) and TR.TAXBASE in (7,10))
            )
    )
    loop
      /* Доход */
      if cTAXPAYS.STATE = 0 then
        /* Инвалиды */
        if nINV = 1 and nINVAL3 = 1 then
          /* Включается в облагаемый доход полностью */
          if cTAXPAYS.TA_TYPE = 1 and nRESIDENT = 0 then
            rCALC.COMP_INV := rCALC.COMP_INV + cTAXPAYS.SUMME;
          /* Включается в облагаемый доход с учетом вычета */
          elsif cTAXPAYS.TA_TYPE = 2 and nRESIDENT = 0 then
            rCALC.COMP_INV := rCALC.COMP_INV + cTAXPAYS.SUMME;
            /* Авторские */
            if cTAXPAYS.POS_CODE = '10' and n4FSS = 2 then
              rCALC.AUTHOR_INV := rCALC.AUTHOR_INV + cTAXPAYS.DISCOUNTSUMM;
            else
              rCALC.DEDUCT_INV := rCALC.DEDUCT_INV + cTAXPAYS.DISCOUNTSUMM;
            end if;
            /* Cудьи */
            if cTAXPAYS.POS_CODE = '6' and n4FSS in (0,2) then
              rCALC.SUD_INV := rCALC.SUD_INV + cTAXPAYS.SUMME - cTAXPAYS.DISCOUNTSUMM;
            end if;
          /* Не включается в облагаемый доход */
          elsif cTAXPAYS.TA_TYPE = 0 or nRESIDENT = 1 then
            rCALC.COMP_INV := rCALC.COMP_INV + cTAXPAYS.SUMME;
            /* Авторские */
            if cTAXPAYS.POS_CODE = '10' and n4FSS = 2 then
              rCALC.AUTHOR_INV := rCALC.AUTHOR_INV + cTAXPAYS.SUMME;
            /* Cудьи */
            elsif cTAXPAYS.POS_CODE = '6' and n4FSS in (0,2) then
              rCALC.SUD_INV := rCALC.SUD_INV + cTAXPAYS.SUMME;
            else
              rCALC.DEDUCT_INV := rCALC.DEDUCT_INV + cTAXPAYS.SUMME;
            end if;
          end if;
        /* ЕНВД */
        elsif cTAXPAYS.TAXBASE = 10 and nENVD3 = 1 then
          /* Включается в облагаемый доход полностью */
          if cTAXPAYS.TA_TYPE = 1 and nRESIDENT = 0 then
            rCALC.COMP_ENVD := rCALC.COMP_ENVD + cTAXPAYS.SUMME;
          /* Включается в облагаемый доход с учетом вычета */
          elsif cTAXPAYS.TA_TYPE = 2 and nRESIDENT = 0 then
            rCALC.COMP_ENVD := rCALC.COMP_ENVD + cTAXPAYS.SUMME;
            /* Авторские */
            if cTAXPAYS.POS_CODE = '10' and n4FSS = 2 then
              rCALC.AUTHOR_ENVD := rCALC.AUTHOR_ENVD + cTAXPAYS.DISCOUNTSUMM;
            else
              rCALC.DEDUCT_ENVD := rCALC.DEDUCT_ENVD + cTAXPAYS.DISCOUNTSUMM;
            end if;
          /* Не включается в облагаемый доход */
          elsif cTAXPAYS.TA_TYPE = 0 or nRESIDENT = 1 then
            rCALC.COMP_ENVD := rCALC.COMP_ENVD + cTAXPAYS.SUMME;
            /* Авторские */
            if cTAXPAYS.POS_CODE = '10' and n4FSS = 2 then
              rCALC.AUTHOR_ENVD := rCALC.AUTHOR_ENVD + cTAXPAYS.SUMME;
            else
              rCALC.DEDUCT_ENVD := rCALC.DEDUCT_ENVD + cTAXPAYS.SUMME;
            end if;
          end if;
        /* Обложение по общим ставкам */
        else
          /* Включается в облагаемый доход полностью */
          if cTAXPAYS.TA_TYPE = 1 and nRESIDENT = 0 then
            rCALC.COMP := rCALC.COMP + cTAXPAYS.SUMME;
          /* Включается в облагаемый доход с учетом вычета */
          elsif cTAXPAYS.TA_TYPE = 2 and nRESIDENT = 0 then
            rCALC.COMP := rCALC.COMP + cTAXPAYS.SUMME;
            /* Авторские */
            if cTAXPAYS.POS_CODE = '10' and n4FSS = 2 then
              rCALC.AUTHOR := rCALC.AUTHOR + cTAXPAYS.DISCOUNTSUMM;
            else
              rCALC.DEDUCT := rCALC.DEDUCT + cTAXPAYS.DISCOUNTSUMM;
            end if;
            /* Cудьи */
            if cTAXPAYS.POS_CODE = '6' and n4FSS in (0,2) then
              rCALC.SUD := rCALC.SUD + cTAXPAYS.SUMME - cTAXPAYS.DISCOUNTSUMM;
            end if;
          /* Не включается в облагаемый доход */
          elsif cTAXPAYS.TA_TYPE = 0 or nRESIDENT = 1 then
            rCALC.COMP := rCALC.COMP + cTAXPAYS.SUMME;
            /* Авторские */
            if cTAXPAYS.POS_CODE = '10' and n4FSS = 2 then
              rCALC.AUTHOR := rCALC.AUTHOR + cTAXPAYS.SUMME;
            /* Cудьи */
            elsif cTAXPAYS.POS_CODE = '6' and n4FSS in (0,2) then
              rCALC.SUD := rCALC.SUD + cTAXPAYS.SUMME;
            else
              rCALC.DEDUCT := rCALC.DEDUCT + cTAXPAYS.SUMME;
            end if;
          end if;
        end if;
      end if;

      /* Налог */
      if cTAXPAYS.STATE = 2 then
        /* Налог */
        if cTAXPAYS.TA_TYPE = 8 then
          /* Учет по ставкам страховой части ПФР */
          if cTAXPAYS.TAXBASE = 8 then
            rCALC.SPFR := rCALC.SPFR + cTAXPAYS.SUMME;
          /* Учет по ставкам накопительной части ПФР */
          elsif cTAXPAYS.TAXBASE = 9 then
            rCALC.NPFR := rCALC.NPFR + cTAXPAYS.SUMME;
          /* Учет по ставкам ФФОМС */
          elsif cTAXPAYS.TAXBASE = 5 then
            rCALC.FFOMS := rCALC.FFOMS + cTAXPAYS.SUMME;
          /* Учет по ставкам ТФОМС */
          elsif cTAXPAYS.TAXBASE in (6,7) then
            rCALC.TFOMS := rCALC.TFOMS + cTAXPAYS.SUMME;
          end if;
        /* Налог по льготе */
        elsif cTAXPAYS.TA_TYPE = 10 then
          /* Инвалиды */
          if (nINV = 1 or nENVD = 0) and nINVAL3 = 1 then
            /* Учет по ставкам страховой части ПФР */
            if cTAXPAYS.TAXBASE = 8 then
              rCALC.SPFR_INV := rCALC.SPFR_INV + cTAXPAYS.SUMME;
            /* Учет по ставкам накопительной части ПФР */
            elsif cTAXPAYS.TAXBASE = 9 then
              rCALC.NPFR_INV := rCALC.NPFR_INV + cTAXPAYS.SUMME;
            /* Учет по ставкам ФФОМС */
            elsif cTAXPAYS.TAXBASE = 5 then
              rCALC.FFOMS_INV := rCALC.FFOMS_INV + cTAXPAYS.SUMME;
            /* Учет по ставкам ТФОМС */
            elsif cTAXPAYS.TAXBASE in (6,7) then
              rCALC.TFOMS_INV := rCALC.TFOMS_INV + cTAXPAYS.SUMME;
            end if;
          /* ЕНВД */
          elsif nENVD3 = 1 then
            /* Учет по ставкам страховой части ПФР */
            if cTAXPAYS.TAXBASE = 8 then
              rCALC.SPFR_ENVD := rCALC.SPFR_ENVD + cTAXPAYS.SUMME;
            /* Учет по ставкам накопительной части ПФР */
            elsif cTAXPAYS.TAXBASE = 9 then
              rCALC.NPFR_ENVD := rCALC.NPFR_ENVD + cTAXPAYS.SUMME;
            /* Учет по ставкам ФФОМС */
            elsif cTAXPAYS.TAXBASE = 5 then
              rCALC.FFOMS_ENVD := rCALC.FFOMS_ENVD + cTAXPAYS.SUMME;
            /* Учет по ставкам ТФОМС */
            elsif cTAXPAYS.TAXBASE in (6,7) then
              rCALC.TFOMS_ENVD := rCALC.TFOMS_ENVD + cTAXPAYS.SUMME;
            end if;
          else
            /* Учет по ставкам страховой части ПФР */
            if cTAXPAYS.TAXBASE = 8 then
              rCALC.SPFR := rCALC.SPFR + cTAXPAYS.SUMME;
            /* Учет по ставкам накопительной части ПФР */
            elsif cTAXPAYS.TAXBASE = 9 then
              rCALC.NPFR := rCALC.NPFR + cTAXPAYS.SUMME;
            /* Учет по ставкам ФФОМС */
            elsif cTAXPAYS.TAXBASE = 5 then
              rCALC.FFOMS := rCALC.FFOMS + cTAXPAYS.SUMME;
            /* Учет по ставкам ТФОМС */
            elsif cTAXPAYS.TAXBASE in (6,7) then
              rCALC.TFOMS := rCALC.TFOMS + cTAXPAYS.SUMME;
            end if;
          end if;
        end if;
      end if;
    end loop;
    /* запомним дельты приращения базы в разрезе ставок */
    nD  := rCALC.COMP - rCALC.DEDUCT - rCALC.AUTHOR;
    nDI := rCALC.COMP_INV - rCALC.DEDUCT_INV - rCALC.AUTHOR_INV;
    nDE := rCALC.COMP_ENVD - rCALC.DEDUCT_ENVD - rCALC.AUTHOR_ENVD;
    /* Проверяем: ранее максимум был превышен, а теперь в результате сторно опять доход упал ниже максимума */
    if nALLINCOME = nMAXINCOME and nALLINCOMENOT + nD + nDI + nDE < nMAXINCOME then
      /* Надо так же распределить дельту, но только ту часть, которая упала ниже максимума  */
      nALLINCOME := nALLINCOMENOT + nD + nDI + nDE;
      nDELTA :=  nALLINCOME - nMAXINCOME;
      nALLINCOMENOT := nALLINCOMENOT + nD + nDI + nDE;
      if nD <> 0 and nDE <> 0 then
        nDE := nDELTA * abs(nDE / (nD + nDE));
        nD  := nDELTA - nDE;
        rCALC.MAXIMUM      := rCALC.COMP - rCALC.DEDUCT - rCALC.AUTHOR - nD;
        rCALC.MAXIMUM_ENVD := rCALC.COMP_ENVD - rCALC.DEDUCT_ENVD - rCALC.AUTHOR_ENVD - nDE;
        if abs(nD) <= abs(rCALC.COMP - rCALC.DEDUCT - rCALC.SUD - rCALC.AUTHOR) then
          rCALC.SUD := 0;
        else
          rCALC.SUD := nD - (rCALC.COMP - rCALC.DEDUCT - rCALC.SUD - rCALC.AUTHOR);
        end if;
      elsif nD <> 0 then
        nD := nDELTA;
        rCALC.MAXIMUM := rCALC.COMP - rCALC.DEDUCT - rCALC.AUTHOR - nD;
        if abs(nD) <= abs(rCALC.COMP - rCALC.DEDUCT - rCALC.SUD - rCALC.AUTHOR) then
          rCALC.SUD := 0;
        else
          rCALC.SUD := nD - (rCALC.COMP - rCALC.DEDUCT - rCALC.SUD - rCALC.AUTHOR);
        end if;
      elsif nDI <> 0 then
        nDI := nDELTA;
        rCALC.MAXIMUM_INV := rCALC.COMP_INV - rCALC.DEDUCT_INV - rCALC.AUTHOR_INV - nDI;
        if abs(nDI) <= abs(rCALC.COMP_INV - rCALC.DEDUCT_INV - rCALC.SUD_INV - rCALC.AUTHOR_INV) then
          rCALC.SUD_INV := 0;
        else
          rCALC.SUD_INV := nDI - (rCALC.COMP_INV - rCALC.DEDUCT_INV - rCALC.SUD_INV - rCALC.AUTHOR_INV);
        end if;
      elsif nDE <> 0 then
        nDE := nDELTA;
        rCALC.MAXIMUM_ENVD := rCALC.COMP_ENVD - rCALC.DEDUCT_ENVD - rCALC.AUTHOR_ENVD - nDE;
      end if;
    end if;
    /* Проверяем: не превысила ли облагаемая база максимум */
    if (nMAXINCOME is not null) and (nALLINCOME + nD + nDI + nDE > nMAXINCOME or
       (nALLINCOME = nMAXINCOME and nALLINCOMENOT + nD + nDI + nDE >= nMAXINCOME)) then
      nALLINCOMENOT := nALLINCOMENOT + nD + nDI + nDE;
      if nALLINCOME = nMAXINCOME then
        /* максимума достигли в предыдущих месяцах, теперь всю дельту пишем на превышение */
        rCALC.MAXIMUM      := nD;
        rCALC.MAXIMUM_INV  := nDI;
        rCALC.MAXIMUM_ENVD := nDE;
        rCALC.SUD          := 0;
        rCALC.SUD_INV      := 0;
      else
        /* в этом месяце достигли максимума */
        nDELTA := nMAXINCOME - nALLINCOME;
        nALLINCOME := nMAXINCOME;
        if nD <> 0 and nDE <> 0 then
          /* ситуация при которой в месяце превышения есть несколько доходов разного типа
             возможна только в случае наличия доходов по общей системе и ЕНВД, т.к. если
             в месяце инвалидность то все доходы ушли на нее */
          nDE := nDELTA * nDE / (nD + nDE);
          nD  := nDELTA - nDE;
          rCALC.MAXIMUM      := rCALC.COMP - rCALC.DEDUCT - rCALC.AUTHOR - nD;
          rCALC.MAXIMUM_ENVD := rCALC.COMP_ENVD - rCALC.DEDUCT_ENVD - rCALC.AUTHOR_ENVD - nDE;
          if nD <= rCALC.COMP - rCALC.DEDUCT - rCALC.SUD - rCALC.AUTHOR then
            rCALC.SUD := 0;
          else
            rCALC.SUD := nD - (rCALC.COMP - rCALC.DEDUCT - rCALC.SUD - rCALC.AUTHOR);
          end if;
        elsif nD <> 0 then
          nD := nDELTA;
          rCALC.MAXIMUM := rCALC.COMP - rCALC.DEDUCT - rCALC.AUTHOR - nD;
          if nD <= rCALC.COMP - rCALC.DEDUCT - rCALC.SUD - rCALC.AUTHOR then
            rCALC.SUD := 0;
          else
            rCALC.SUD := nD - (rCALC.COMP - rCALC.DEDUCT - rCALC.SUD - rCALC.AUTHOR);
          end if;
        elsif nDI <> 0 then
          nDI := nDELTA;
          rCALC.MAXIMUM_INV := rCALC.COMP_INV - rCALC.DEDUCT_INV - rCALC.AUTHOR_INV - nDI;
          if nDI <= rCALC.COMP_INV - rCALC.DEDUCT_INV - rCALC.SUD_INV - rCALC.AUTHOR_INV then
            rCALC.SUD_INV := 0;
          else
            rCALC.SUD_INV := nDI - (rCALC.COMP_INV - rCALC.DEDUCT_INV - rCALC.SUD_INV - rCALC.AUTHOR_INV);
          end if;
        elsif nDE <> 0 then
          nDE := nDELTA;
          rCALC.MAXIMUM_ENVD := rCALC.COMP_ENVD - rCALC.DEDUCT_ENVD - rCALC.AUTHOR_ENVD - nDE;
        end if;
      end if;
    else
      nALLINCOMENOT := nALLINCOMENOT + nD + nDI + nDE;
      nALLINCOME := nALLINCOME + nD + nDI + nDE;
    end if;

    INS_RECORD(i,0);

    /* Инвалиды */
    if nINV = 1 and nINVAL3 = 1 and n4FSS in (0,2) then
      rCALC.COMP_INV := round(rCALC.COMP_INV, 0);
      for rec in
      (
        select REF_BEG,
               REF_END
          from AGNDISABLED
         where PRN = nAGENT
           and DATEBEG <= dEND
           and (DATEEND is null or DATEEND >= dBGN)
         order by DATEBEG desc
      )
      loop
        update SLCST_INVALID
           set REF_END  = nvl(rec.REF_END, REF_END),
               INC_PFR  = INC_PFR + rCALC.COMP_INV,
               INC_PFR1 = INC_PFR1 + decode(i, nMONTHEND-2, rCALC.COMP_INV, 0),
               INC_PFR2 = INC_PFR2 + decode(i, nMONTHEND-1, rCALC.COMP_INV, 0),
               INC_PFR3 = INC_PFR3 + decode(i, nMONTHEND, rCALC.COMP_INV, 0)
         where AUTHID = user
           and AGENT = nAGENT;
        if ( SQL%NOTFOUND ) then
          insert into SLCST_INVALID
          (
            RN,
            AUTHID,
            AGENT,
            REF_BEG,
            REF_END,
            INC_PFR,
            INC_PFR1,
            INC_PFR2,
            INC_PFR3
          )
          values
          (
            1,
            user,
            nAGENT,
            rec.REF_BEG,
            rec.REF_END,
            rCALC.COMP_INV,
            decode(i, nMONTHEND-2, rCALC.COMP_INV, 0),
            decode(i, nMONTHEND-1, rCALC.COMP_INV, 0),
            decode(i, nMONTHEND, rCALC.COMP_INV, 0)
          );
        end if;
        exit;
      end loop;
    end if;

    /* Учет по ФСС для индивидуальной карточки */
    if n4FSS = 2 then
      INIT_RECORD;
      for cTAXPAYS in
      (
       select TC.PRN,
              TP.SLTAXACCS,
              TP.SUMME,
              TP.DISCOUNTSUMM,
              TP.MONTHNUMB,
              TR.TAXBASE,
              TR.STATE,
              TR.POS_CODE,
              TR.PRIVIL,
              TR1.DDCODE,
              TR.TA_TYPE
         from CLNPERSTAXACCSP TP,
              CLNPERSTAXACC   TC,
              SLTAXACCS       TR,
              SALINDEDUCT     TR1
        where TC.RN        = TP.PRN
          and TP.SLTAXACCS = TR.RN
          and TR.DEDCODE   = TR1.RN(+)
          and TC.RN        = nCLNPERSTAXACC
          and TP.MONTHNUMB = i
          and ((TR.STATE = 0 and TR.TAXBASE in (7,10)) or
               (TR.STATE in (2,3) and TR.TAXBASE = 7)
              )
      )
      loop
        /* Доход */
        if cTAXPAYS.STATE = 0 then
          /* Инвалиды */
          if nINV = 1 and nINVAL3 = 1 then
            /* Включается в облагаемый доход полностью */
            if cTAXPAYS.TA_TYPE = 1 and nRESIDENT = 0 then
              rCALC.COMP_INV := rCALC.COMP_INV + cTAXPAYS.SUMME;
            /* Включается в облагаемый доход с учетом вычета */
            elsif cTAXPAYS.TA_TYPE = 2 and nRESIDENT = 0 then
              rCALC.COMP_INV := rCALC.COMP_INV + cTAXPAYS.SUMME;
              rCALC.DEDUCT_INV := rCALC.DEDUCT_INV + cTAXPAYS.DISCOUNTSUMM;
            /* Не включается в облагаемый доход */
            elsif cTAXPAYS.TA_TYPE = 0 or nRESIDENT = 1 then
              rCALC.COMP_INV := rCALC.COMP_INV + cTAXPAYS.SUMME;
              /* Авторские */
              if cTAXPAYS.POS_CODE = '10' then
                rCALC.AUTHOR_INV := rCALC.AUTHOR_INV + cTAXPAYS.SUMME;
              else
                rCALC.DEDUCT_INV := rCALC.DEDUCT_INV + cTAXPAYS.SUMME;
              end if;
            end if;
          /* ЕНВД */
          elsif cTAXPAYS.TAXBASE = 10 and nENVD3 = 1 then
            /* Включается в облагаемый доход полностью */
            if cTAXPAYS.TA_TYPE = 1 and nRESIDENT = 0 then
              rCALC.COMP_ENVD := rCALC.COMP_ENVD + cTAXPAYS.SUMME;
            /* Включается в облагаемый доход с учетом вычета */
            elsif cTAXPAYS.TA_TYPE = 2 and nRESIDENT = 0 then
              rCALC.COMP_ENVD := rCALC.COMP_ENVD + cTAXPAYS.SUMME;
              rCALC.DEDUCT_ENVD := rCALC.DEDUCT_ENVD + cTAXPAYS.DISCOUNTSUMM;
            /* Не включается в облагаемый доход */
            elsif cTAXPAYS.TA_TYPE = 0 or nRESIDENT = 1 then
              rCALC.COMP_ENVD := rCALC.COMP_ENVD + cTAXPAYS.SUMME;
              /* Авторские */
              if cTAXPAYS.POS_CODE = '10' then
                rCALC.AUTHOR_ENVD := rCALC.AUTHOR_ENVD + cTAXPAYS.SUMME;
              else
                rCALC.DEDUCT_ENVD := rCALC.DEDUCT_ENVD + cTAXPAYS.SUMME;
              end if;
            end if;
          /* Обложение по общим ставкам */
          else
            /* Включается в облагаемый доход полностью */
            if cTAXPAYS.TA_TYPE = 1 and nRESIDENT = 0 then
              rCALC.COMP := rCALC.COMP + cTAXPAYS.SUMME;
            /* Включается в облагаемый доход с учетом вычета */
            elsif cTAXPAYS.TA_TYPE = 2 and nRESIDENT = 0 then
              rCALC.COMP := rCALC.COMP + cTAXPAYS.SUMME;
              rCALC.DEDUCT := rCALC.DEDUCT + cTAXPAYS.DISCOUNTSUMM;
            /* Не включается в облагаемый доход */
            elsif cTAXPAYS.TA_TYPE = 0 or nRESIDENT = 1 then
              rCALC.COMP := rCALC.COMP + cTAXPAYS.SUMME;
              /* Авторские */
              if cTAXPAYS.POS_CODE = '10' then
                rCALC.AUTHOR := rCALC.AUTHOR + cTAXPAYS.SUMME;
              else
                rCALC.DEDUCT := rCALC.DEDUCT + cTAXPAYS.SUMME;
              end if;
            end if;
          end if;
        end if;

        /* Учет по ставкам ФСС РФ */
        if cTAXPAYS.TAXBASE = 7 then
          /* Налог */
          if cTAXPAYS.STATE = 2 then
            /* Налог */
            if cTAXPAYS.TA_TYPE = 8 then
              rCALC.SPFR := rCALC.SPFR + cTAXPAYS.SUMME;
            /* Налог по льготе */
            elsif cTAXPAYS.TA_TYPE = 10 then
              /* Инвалиды */
              if (nINV = 1 or nENVD = 0) and nINVAL3 = 1 then
                rCALC.SPFR_INV := rCALC.SPFR_INV + cTAXPAYS.SUMME;
              /* ЕНВД */
              elsif nENVD3 = 1 then
                rCALC.SPFR_ENVD := rCALC.SPFR_ENVD + cTAXPAYS.SUMME;
              else
                rCALC.SPFR := rCALC.SPFR + cTAXPAYS.SUMME;
              end if;
            end if;
          end if;
          /* Расход */
          if cTAXPAYS.STATE = 3 then
            rCALC.NPFR := rCALC.NPFR + cTAXPAYS.SUMME;
          end if;
        end if;
      end loop;

      /* запомним дельты приращения базы в разрезе ставок */
      nD  := rCALC.COMP - rCALC.DEDUCT - rCALC.AUTHOR;
      nDI := rCALC.COMP_INV - rCALC.DEDUCT_INV - rCALC.AUTHOR_INV;
      nDE := rCALC.COMP_ENVD - rCALC.DEDUCT_ENVD - rCALC.AUTHOR_ENVD;
      /* Проверяем: ранее максимум был превышен, а теперь в результате сторно опять доход упал ниже максимума */
      if nALLINCOME1 = nMAXINCOME and nALLINCOMENOT1 + nD + nDI + nDE < nMAXINCOME then
        /* Надо так же распределить дельту, но только ту часть, которая упала ниже максимума  */
        nALLINCOME1 := nALLINCOMENOT1 + nD + nDI + nDE;
        nDELTA :=  nALLINCOME1 - nMAXINCOME;
        nALLINCOMENOT1 := nALLINCOMENOT1 + nD + nDI + nDE;
        if nD <> 0 and nDE <> 0 then
          nDE := nDELTA * abs(nDE / (nD + nDE));
          nD  := nDELTA - nDE;
          rCALC.MAXIMUM      := rCALC.COMP - rCALC.DEDUCT - rCALC.AUTHOR - nD;
          rCALC.MAXIMUM_ENVD := rCALC.COMP_ENVD - rCALC.DEDUCT_ENVD - rCALC.AUTHOR_ENVD - nDE;
        elsif nD <> 0 then
          nD := nDELTA;
          rCALC.MAXIMUM := rCALC.COMP - rCALC.DEDUCT - rCALC.AUTHOR - nD;
        elsif nDI <> 0 then
          nDI := nDELTA;
          rCALC.MAXIMUM_INV := rCALC.COMP_INV - rCALC.DEDUCT_INV - rCALC.AUTHOR_INV - nDI;
        elsif nDE <> 0 then
          nDE := nDELTA;
          rCALC.MAXIMUM_ENVD := rCALC.COMP_ENVD - rCALC.DEDUCT_ENVD - rCALC.AUTHOR_ENVD - nDE;
        end if;
      end if;
      /* Проверяем: не превысила ли облагаемая база максимум */
      if (nMAXINCOME is not null) and (nALLINCOME1 + nD + nDI + nDE > nMAXINCOME or
         (nALLINCOME1 = nMAXINCOME and nALLINCOMENOT1 + nD + nDI + nDE >= nMAXINCOME)) then
        nALLINCOMENOT1 := nALLINCOMENOT1 + nD + nDI + nDE;
        if nALLINCOME1 = nMAXINCOME then
          /* максимума достигли в предыдущих месяцах, теперь всю дельту пишем на превышение */
          rCALC.MAXIMUM      := nD;
          rCALC.MAXIMUM_INV  := nDI;
          rCALC.MAXIMUM_ENVD := nDE;
        else
          /* в этом месяце достигли максимума */
          nDELTA := nMAXINCOME - nALLINCOME1;
          nALLINCOME1 := nMAXINCOME;
          if nD <> 0 and nDE <> 0 then
            /* ситуация при которой в месяце превышения есть несколько доходов разного типа
               возможна только в случае наличия доходов по общей системе и ЕНВД, т.к. если
               в месяце инвалидность то все доходы ушли на нее */
            nDE := nDELTA * nDE / (nD + nDE);
            nD  := nDELTA - nDE;
            rCALC.MAXIMUM      := rCALC.COMP - rCALC.DEDUCT - rCALC.AUTHOR - nD;
            rCALC.MAXIMUM_ENVD := rCALC.COMP_ENVD - rCALC.DEDUCT_ENVD - rCALC.AUTHOR_ENVD - nDE;
          elsif nD <> 0 then
            nD := nDELTA;
            rCALC.MAXIMUM := rCALC.COMP - rCALC.DEDUCT - rCALC.AUTHOR - nD;
          elsif nDI <> 0 then
            nDI := nDELTA;
            rCALC.MAXIMUM_INV := rCALC.COMP_INV - rCALC.DEDUCT_INV - rCALC.AUTHOR_INV - nDI;
          elsif nDE <> 0 then
            nDE := nDELTA;
            rCALC.MAXIMUM_ENVD := rCALC.COMP_ENVD - rCALC.DEDUCT_ENVD - rCALC.AUTHOR_ENVD - nDE;
          end if;
        end if;
      else
        nALLINCOME1 := nALLINCOME1 + nD + nDI + nDE;
        nALLINCOMENOT1 := nALLINCOMENOT1 + nD + nDI + nDE;
      end if;
      INS_RECORD(i,1);
    end if;
  end loop;
end CALC_PFR;

/* Параметры КАЮЛ */
procedure GET_AGENT_PARAM
(
 nCOMPANY             in number,
 nAGENT               in number,             -- КАЮЛ
 dPERIODEND           in date,               -- На дату
 sREGNUMB             out varchar2,          -- Регистрационный номер в ПФР
 sOKVED               out varchar2,          -- ОКВЭД (ОКОНХ)
 sOKATO               out varchar2,          -- ОКАТО
 sREASON_CODE         out varchar2           -- КПП
)
as
 nVERSION             PKG_STD.tREF;
begin
  /* версия вида деятельности */
  FIND_VERSION_BY_COMPANY( nCOMPANY,'SalaryActivityTypes',nVERSION );
  for rec in
  (
    select B.REGNUMB,
           C.CODE
      from SLACTYPE A,
           SLACTYPEORG B,
           NATECONSECT C
     where A.RN           = B.PRN
       and B.AGENT        = nAGENT
       and A.VERSION      = nVERSION
       and A.NATECONSECT  = C.RN
     order by B.PRIMARY_SIGN desc
  )
  loop
    sREGNUMB := rec.REGNUMB;
    sOKVED   := rec.CODE;
    exit;
  end loop;

  /* КПП, ОКАТО */
  begin
    select O.CODE,
           A.REASON_CODE
      into sOKATO,
           sREASON_CODE
      from AGNTAXBR A,
           OKATO    O
     where A.PRN = nAGENT
       and A.OKATO = O.RN(+)
       and A.DATEBEG <= dPERIODEND
       and (A.DATEEND >= dPERIODEND or A.DATEEND is null);
  exception
    when NO_DATA_FOUND then
      null;
  end;

  /* КАЮЛ */
  for rec in
  (
    select A.REASON_CODE,
           O.CODE OKATO,
           C.CODE OKVED
      from AGNLIST     A,
           OKATO       O,
           NATECONLIST L,
           NATECONSECT C
     where A.RN = nAGENT
       and A.OKATO = O.RN(+)
       and A.NATECONSECT = L.RN(+)
       and L.OKONH = C.RN(+)
  )
  loop
    sOKATO       := nvl(sOKATO, rec.OKATO);
    sREASON_CODE := nvl(sREASON_CODE, rec.REASON_CODE);
    sOKVED       := nvl(rec.OKVED,sOKVED);
    exit;
  end loop;
end GET_AGENT_PARAM;

/* Печать цифровой ячейки для ПФР */
procedure CELL_NUMBVALUE_WRITE
(
 sCELL      in varchar2,                     -- ячейка
 nNUMB      in number,                       -- сумма
 nDIG       in number default 2,             -- десятичных знаков
 nIDX       in number default null           -- строка
)
as
sNUMB       varchar2(50);
begin
  if nNUMB <> 0 then
    if nDIG = 0 then
      sNUMB := trim(to_char(nNUMB,'99999999999999999'));
    elsif nDIG = 2 then
      sNUMB := trim(to_char(nNUMB,'999999999999999.99'));
    end if;
    if nIDX is null then
      PRSG_EXCEL.CELL_VALUE_WRITE(sCELL, sNUMB);
    else
      PRSG_EXCEL.CELL_VALUE_WRITE(sCELL, 0, nIDX, sNUMB);
    end if;
  else
    if nIDX is null then
      PRSG_EXCEL.CELL_VALUE_WRITE(sCELL, chr(39)||'-------');
      PRSG_EXCEL.CELL_ATTRIBUTE_SET(sCELL,'HorizontalAlignment','xlHAlignCenter');
    else
      PRSG_EXCEL.CELL_VALUE_WRITE(sCELL, 0, nIDX, chr(39)||'-------');
      PRSG_EXCEL.CELL_ATTRIBUTE_SET(sCELL,0,nIDX,'HorizontalAlignment','xlHAlignCenter');
    end if;
  end if;
end CELL_NUMBVALUE_WRITE;

/* Поиск шкалы налогооблажения */
procedure FIND_SALTAXSCALE
(
 nCOMPANY   in number,
 nRULE      in number,                   -- шкала
 nYEAR      in number,                   -- год рождения
 dPERIODEND in date,                     -- Период По
 nRN        out number                   -- шкала налогооблажения
)
as
  sTAXSCALE         SALTAXSCALE.CODE%TYPE;
  sSQL              varchar2( 2000 );
  sWHERE            varchar2( 2000 );
  nCOUNT            PKG_STD.tNUMBER;
begin
  -- Перебираем редакцию шкалы
  for CUR in
  (
    select M.STRT_COND,
           M.STRT_VALUE
      from SALSTRUC M,
           SALEDITS E
     where M.PRN = E.RN
       and E.PRN = nRULE
       and E.EDITION_BEGIN =
        (
          select max( E1.EDITION_BEGIN )
            from SALEDITS E1
           where E1.PRN = nRULE
             and E1.EDITION_BEGIN <= dPERIODEND
        )
    order by M.STRT_NUMBER
  )
  loop
    if nYEAR > 0 then
      sSQL := 'select count(*) from dual';
      sWHERE := replace(CUR.STRT_COND, 'BY()', to_char(nYEAR,'9999'));
      if sWHERE is not null then
        sSQL := sSQL || ' where ' || sWHERE;
      end if;

      begin
        execute immediate sSQL into nCOUNT;
      exception
        when OTHERS then
          nCOUNT := 0;
      end;

      if nCOUNT > 0 then
        sTAXSCALE := CUR.STRT_VALUE;
        exit;
      end if;
    else
      sTAXSCALE := CUR.STRT_VALUE;
      exit;
    end if;
  end loop;
  -- В результате перебора состава шкалы мы должны были найти
  -- мнемокод шкалы налогообложения
  -- Теперь превращаем его в RN
  FIND_SALTAXSCALE_CODE(1, 1, nCOMPANY, sTAXSCALE, nRN);
end FIND_SALTAXSCALE;

end PKG_SLCST;
/
