     H DFTACTGRP(*NO) ACTGRP(*NEW) OPTION(*SRCSTMT : *NOUNREF : *NODEBUGIO)
      *
     Dstmt             S            500    INZ('SELECT * FROM SYOHIN -
     D                                     WHERE PRPRCD = ''120'' -
     D                                     FOR UPDATE WITH NC')
      *
      /FREE

        EXEC SQL PREPARE s1 FROM :stmt;
        EXEC SQL DECLARE c1 CURSOR FOR s1;
        EXEC SQL OPEN c1;

        DOW (1 = 1);
          EXEC SQL FETCH c1;
          IF %SUBST(SQLSTATE : 1 : 2) <> '00';
            LEAVE;
          ENDIF;
          EXEC SQL UPDATE SYOHIN
            SET PRTXR = 0.08,           --消費税率
                PRUPDT = CAST(VARCHAR_FORMAT(CURRENT_TIMESTAMP, 'YYYYMMDD')
                         AS DEC(8, 0)), --最終更新日
                PRUPTM = CAST(VARCHAR_FORMAT(CURRENT_TIMESTAMP, 'HH24MISS')
                         AS DEC(6, 0))  --最終更新時刻
            WHERE CURRENT OF c1;
        ENDDO;

        EXEC SQL CLOSE c1;

        *INLR = *ON;
        RETURN;
      /END-FREE