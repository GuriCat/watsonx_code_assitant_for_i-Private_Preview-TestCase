      *
      * May not work for IBM i 7.1.
      * Specify SQLPKG(any_obj_name) to avoid connection error.
      *
      * > CRTSQLRPGI OBJ(DSPSVRSTSR) SRCFILE(IBMISVCSS) SQLPKG(QTEMP/XX)
      *   DBGVIEW(*SOURCE)
      *
     H DFTACTGRP(*NO) ACTGRP(*NEW) OPTION(*SRCSTMT : *NOUNREF : *NODEBUGIO)
     H ALWNULL(*INPUTONLY)
      *
     FDSPSVRSTSDCF   E             WORKSTN
     F                                     SFILE(SFL : SFLRRN)
     F                                     INFDS(SFLDS)
      *
     D SFLRRN          S              4P 0
     D SFLDS           DS
     D   sflRcdNo            378    379I 0
      *
     D svrSts          DS
     D   NUM_PART                    10I 0
     D   PART_ID                     10I 0
     D   HOST_NAME                  255    VARYING
     D   CPU_CAP                      5P 2
     D   CPU_SHARE                    8    VARYING
     D   CPU_MAX                      5P 2
     D   TOTAL_JOBS                  10I 0
     D   ACT_JOBS                    10I 0
     D   MAX_JOBS                    10I 0
     D   SYS_STG                     20I 0
     D   SYS_RATE                     5P 2
     D nulIndArr       S              5I 0 DIM(11)
     D stmt            S            500
     D SQLerror        S               N
      * Procedures
     D cmdLine         PR                  EXTPGM('QUSCMDLN')
     D sndStsMsg       PR            10I 0
     D   msgTxt                     200A   CONST VARYING
     D usleep          PR                  EXTPROC('usleep')
     D   milSec                      10U 0 VALUE
      * Depends on lpar configuration
     D lpar            S             10    DIM(4) VARYING
     D lparNumber      C                   CONST(3)
      * Misc
     D i               S              3P 0
     D rc              S             10I 0
      *
        EXSR #init;

        // Main loop
        DOW (1 = 1);

          IF *IN03; // Exit
            LEAVE;
          ENDIF;

          IF *IN21; // Show command window
            CALLP cmdLine();
            *IN21 = *OFF;
            ITER;
          ENDIF;

          IF *IN05; // Refresh

            // Run sql and get info
            *IN32 = *OFF; // SFLDSP SFLDSPCTL
            *IN30 = *ON;  // SFLCLR
            WRITE SFLCTL;

            SETCORE = 0; //割当コア数
            TOTCPU  = 0; //コア使用合計
            FOR i = 1 TO lparNumber;
              EXSR #getLparStatus;
            ENDFOR;
            IF SETCORE > 0;
              COREUSE = (TOTCPU / SETCORE) * 100;
            ELSE;
              COREUSE = -1;
            ENDIF;

          ENDIF;

          // Display status
          WRITE HEADER;
          WRITE FOOTER;
          *IN32 = *ON;  // SFLDSP SFLDSPCTL
          *IN30 = *OFF; // SFLCLR
          EXFMT SFLCTL;

        ENDDO;

        *INLR = *ON;
        RETURN;

        // Subroutines //////////////////////////////////

        // Set DRDA host name defined at RDBDIR
        BEGSR #init;

          NUMPART = 0;
          lpar(1) = 'L7007920';
          lpar(2) = 'B7007920';
          lpar(3) = 'C7007920';
          *IN05 = *ON; // For first time

          // Avoid CPI8350
          EXEC SQL SET OPTION COMMIT = *NONE;

        ENDSR;

        // Check SQL error
        BEGSR #checkSQLError;

          IF %SUBST(SQLSTATE : 1 : 2) <> '00';
            sndStsMsg('SQLエラー: SQLCODE ' + %CHAR(SQLCODE) +
                      ', SQLSTATE ' + SQLSTATE);
            SQLerror = *ON;
            usleep(500000); // Wait 0.5 sec
          ENDIF;

        ENDSR;

        // Get system status of respective lpar
        BEGSR #getLparStatus;

          SQLerror = *OFF;

          stmt = 'SELECT NUM_PART, ' +    // integer
                        'PART_ID, '    +  // integer
                        'HOST_NAME, '  +  // varchar(255)
                        'CPU_CAP, '    +  // dec(5,2)
                        'CPU_SHARE, '  +  // varchar(8) Null capable
                        'CPU_MAX, '    +  // dec(5,2)
                        'TOTAL_JOBS, ' +  // integer
                        'ACT_JOBS, '   +  // integer
                        'MAX_JOBS, '   +  // integer
                        'SYS_STG, '    +  // bigint (MB)
                        'SYS_RATE '    +  // dec(5,2)
                 'FROM ' + lpar(i) +
                 '/QSYS2/SYSTEM_STATUS_INFO FOR FETCH ONLY';
          sndStsMsg(stmt);
          EXEC SQL PREPARE s1 FROM :stmt;
          EXSR #checkSQLError;

          IF NOT SQLerror;
            EXEC SQL DECLARE c1 CURSOR for s1; // DECLAREはSQLSTATEに影響無
            EXEC SQL OPEN c1;
            IF NOT SQLerror;
              EXSR #checkSQLError;
              IF NOT SQLerror;
                EXEC SQL FETCH c1 INTO :svrSts :nulIndArr;
                EXSR #checkSQLError;
                IF NOT SQLerror;
                  EXEC SQL CLOSE c1;
                  EXSR #checkSQLError;
                ENDIF;
              ENDIF;
            ENDIF;
          ENDIF;
          // Convert result
          IF NOT SQLerror;
            sndStsMsg(HOST_NAME + 'から正常にデータが取得された。');
            // server level
            NUMPART = NUM_PART;     // integer
            // partition level
            PARTID     = PART_ID;    // integer
            PARTNAME   = HOST_NAME;  // varchar(255)
            CAPCPU     = CPU_CAP;    // dec(5,2)
            SHAREMODE  = CPU_SHARE;  // varchar(8) Null capable
            MAXCPU     = CPU_MAX;    // dec(5,2)
            ESTCORE    = CAPCPU * (MAXCPU / 100);
            TOTALJOBS  = TOTAL_JOBS; // integer
            ACTIVEJOBS = ACT_JOBS;   // integer
            MAXJOBS    = MAX_JOBS;   // integer
            SIZEASP1   = SYS_STG / 1024;    // bigint (MB)
            RATEASP1   = SYS_RATE;   // dec(5,2)
            SETCORE += CAPCPU;
            TOTCPU += ESTCORE;
          ELSE;
            sndStsMsg(lpar(i) + 'のデータ取得でエラー。SQLSTATE = ' +
                      SQLSTATE);
            // server level
            IF NUMPART <> 0;
              NUMPART = 99;         // integer
            ENDIF;
            // partition level
            CLEAR SFL;
          ENDIF;
          usleep(500000); // Wait 0.5 sec

          SFLRRN = i;
          WRITE SFL;
          sndStsMsg(' ');

       ENDSR;

      *
     P sndStsMsg       B
     D sndStsMsg       PI            10I 0
     D   msgTxt                     200A   CONST VARYING
      *
      /INCLUDE QSYSINC/QRPGLESRC,QUSEC
      *
     D QMHSNDPM        PR                  EXTPGM('QMHSNDPM')
     D   msgID                        7A   CONST
     D   msgFile                     20A   CONST
     D   msgData                    200A   CONST OPTIONS(*VARSIZE)
     D   msgLen                      10I 0 CONST
     D   msgType                     10A   CONST
     D   msgStkEnt                   10A   CONST
     D   msgRStkEnt                  10I 0 CONST
     D   msgRtnKey                    4A
     D   msgErrDS                          LIKEDS(QUSEC) OPTIONS(*VARSIZE)
      *
     D messageKey      S              4A
      *
       QUSBPRV = 16;

       QMHSNDPM('CPF9897' : 'QCPFMSG   *LIBL     ' :
                msgTxt : %LEN(msgTxt) : '*STATUS   ' :
                '*EXT      ' : 0 : messageKey : QUSEC);

       RETURN QUSBAVL;
      *
     P                 E