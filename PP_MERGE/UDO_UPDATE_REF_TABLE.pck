CREATE OR REPLACE PACKAGE UDO_UPDATE_REF_TABLE
AS

  /*=======================================================================
  Глобальная замена ссылок на одну сущность, ссылками на другую.

  Например для глобальной замены номенклатуры Н1 на номенклатуру Н2,
  находим значения RN в таблице DICNOMNS для этих номенклатур
  (допустим для Н1 - 44444444,а для Н2 - 77777  )

  тогда для замены всех ссылок на намеклатуру Н1 ссылками на намеклатуру Н2
  вызываем
  begin
     UDO_UPDATE_REF_TABLE.UPDAT('DICNOMNS',44444444,77777);
  end;

  при удачном выполнении не забываем про commit;
  если все прошло удачно - номенклатура Н2 может быть безболезненно удалена.

 неудачи могут быть связаны с нарушением уникальных ключей, например
 у номенклатуры Н1 есть модификация с мнемокодом МОД1, и у номенклатуры Н2
 тоже есть модификация с мнемокодом МОД1. в этом случае после возникновении
 ошибки необходимо самостоятельно принять меры для устранения дублирования
 переименовать одну из модификаций, или удалить одну из них...

 =========================================================================*/


  PROCEDURE UPDAT(
  STABLENAME in VARCHAR2, -- имя таблицы
  NOLD_RN in NUMBER,      -- значение первичного ключя (которое меняем)
  NNEW_RN in NUMBER       -- -- значение первичного ключя (на которое меняем)
);
PROCEDURE ENABLETRIGGERS (STABLENAME IN VARCHAR2);
PROCEDURE DISABLETRIGGERS (STABLENAME IN VARCHAR2);

END UDO_UPDATE_REF_TABLE;
/
CREATE OR REPLACE PACKAGE BODY UDO_UPDATE_REF_TABLE
AS
  PROCEDURE GET_TABLE_PK(STABLENAME IN VARCHAR2,SPKNAME OUT VARCHAR2)IS
  BEGIN
    SELECT AC.CONSTRAINT_NAME
    INTO SPKNAME
    FROM SYS.ALL_CONSTRAINTS AC
    WHERE AC.TABLE_NAME = STABLENAME
    AND AC.CONSTRAINT_TYPE = 'P';
  EXCEPTION
    WHEN OTHERS THEN
      NULL;   -- PL/SQL;
  END;

  PROCEDURE ENABLETRIGGERS (STABLENAME IN VARCHAR2) as
    PRAGMA autonomous_transaction;
  BEGIN
    FOR I IN (SELECT ALT.TRIGGER_NAME
                FROM SYS.ALL_TRIGGERS ALT
               WHERE ALT.TABLE_NAME = STABLENAME
                 AND ALT.TRIGGERING_EVENT = 'UPDATE') LOOP
       EXECUTE IMMEDIATE 'ALTER TRIGGER ' || I.TRIGGER_NAME || ' ENABLE';
    END LOOP;
    EXECUTE IMMEDIATE 'drop trigger UDO_TEMP_TRIGG';
  END;

  PROCEDURE DISABLETRIGGERS (STABLENAME IN VARCHAR2) as
    PRAGMA autonomous_transaction;
  BEGIN
    EXECUTE IMMEDIATE 'create or replace trigger UDO_TEMP_TRIGG
                       before insert on '|| STABLENAME ||' for each row
                        begin
                        P_EXCEPTION( 0,''Таблица временно заблокирована'');
                       end;';
    FOR I IN (SELECT ALT.TRIGGER_NAME
                FROM SYS.ALL_TRIGGERS ALT
               WHERE ALT.TABLE_NAME = STABLENAME
                 AND ALT.TRIGGERING_EVENT = 'UPDATE') LOOP
       EXECUTE IMMEDIATE 'ALTER TRIGGER ' || I.TRIGGER_NAME || ' DISABLE';
    END LOOP;
  END;


  PROCEDURE UPDATETABLE(STABLENAME IN VARCHAR2,SCOLUMNNAME IN VARCHAR2,NOLDVALUE IN NUMBER,NNEWVALUE IN NUMBER) IS
    --SLOCKSQL   VARCHAR2(1000);
    SUPDATESQL VARCHAR2(1000);
  BEGIN
    --SLOCKSQL := 'SELECT * FROM ' || STABLENAME || ' FOR UPDATE NOWAIT';
    --EXECUTE IMMEDIATE SLOCKSQL;
   BEGIN
    DISABLETRIGGERS(STABLENAME);
    SUPDATESQL := 'UPDATE ' ||  STABLENAME;
    SUPDATESQL := SUPDATESQL || ' SET ' || SCOLUMNNAME || '=' || NNEWVALUE;
    SUPDATESQL := SUPDATESQL || ' WHERE ' || SCOLUMNNAME || '=' || NOLDVALUE;
      EXECUTE IMMEDIATE SUPDATESQL;
   EXCEPTION
    WHEN OTHERS THEN
      ENABLETRIGGERS(STABLENAME);
      RAISE;
   END;
    ENABLETRIGGERS(STABLENAME);
  END;

  PROCEDURE UPDAT(STABLENAME IN VARCHAR2,NOLD_RN IN NUMBER,NNEW_RN IN NUMBER) IS
    SPKNAME VARCHAR2(30);
    NRECCOUNT NUMBER;
    SSQLCOUNT VARCHAR2(1000);
  BEGIN
    GET_TABLE_PK(STABLENAME,SPKNAME);
    FOR I IN (SELECT AC.TABLE_NAME,ACC.COLUMN_NAME
                FROM SYS.ALL_CONSTRAINTS AC,
                     SYS.ALL_CONS_COLUMNS ACC
                WHERE AC.CONSTRAINT_TYPE = 'R'
                  AND AC.R_CONSTRAINT_NAME = SPKNAME
                  AND ACC.CONSTRAINT_NAME = AC.CONSTRAINT_NAME) LOOP
       SSQLCOUNT := 'SELECT COUNT (*) FROM ' || I.TABLE_NAME;
       SSQLCOUNT := SSQLCOUNT || ' WHERE ' || I.COLUMN_NAME;
       SSQLCOUNT := SSQLCOUNT || '=' || NOLD_RN;
       EXECUTE IMMEDIATE SSQLCOUNT INTO NRECCOUNT;
       IF  NRECCOUNT>0 THEN
         UPDATETABLE(I.TABLE_NAME,I.COLUMN_NAME,NOLD_RN,NNEW_RN);
       END IF;
     END LOOP;
  END UPDAT;

END UDO_UPDATE_REF_TABLE;
/
