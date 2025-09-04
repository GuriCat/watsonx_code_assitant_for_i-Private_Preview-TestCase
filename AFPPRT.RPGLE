     H DFTACTGRP(*NO) ACTGRP(*NEW)
     H OPTION(*SHOWCPY : *SRCSTMT : *NOUNREF : *NODEBUGIO)
     H DATEDIT(*YMD/)
      *
     FPERSON    IF   E             DISK
     FAFPPRTF   O    E             PRINTER
     FQPRINT    O    F  198        PRINTER USROPN OFLIND(*INOF)
      *
     D RCDCNT          S              5  0 INZ(0)
     D PAGECNT         S                   LIKE(RCDCNT)
     D LINECNT         S                   LIKE(RCDCNT)
      *１インチ当り文字数
     D CPI             C                   10
      *１インチ当り行数
     D LPI             C                   6
      *行開始位置調整
     D YD              C                   4
      *１ページ当たり印刷レコード数
     D ITEMS           C                   5
      *１レコード当り印刷行数
     D EL              C                   10
      *現在の基準行
     D YP              S              3  0
      *累積読取件数を１ページ当たり印刷レコード数で割った余り
     D REM             S                    LIKE(RCDCNT)
      *
     D FN              S             30A    CCSID(37) INZ('WT Sans J')
     D PM              S            198
      *
        //ジョブスイッチ1がオンの場合はデバッグ印刷出力
     C   U1              OPEN      QPRINT

        DOW (1 = 1);
          READ PERSONR;
          IF %EOF OR RCDCNT > 50;
       //   EXSR #WSHUKEI;
            LEAVE;
          ENDIF;
          RCDCNT += 1;
          REM = %REM(RCDCNT:ITEMS);
          IF REM = 1;
            PAGECNT += 1;
            EXSR #WMIDASI;
          ENDIF;
          EXSR #PMEISAI;
          IF REM = 0;
            EXSR #WFOOT;
          ENDIF;
        ENDDO;

        IF (REM <> 0) AND (RCDCNT > 0);
          EXSR #WSHUKEI;
        ENDIF;

        *INLR = *ON;

     C   U1              CLOSE     QPRINT

        BEGSR #PMEISAI;
      //  IF LINECNT = 0;
      //    EXSR #WMIDASI;
      //    LINECNT = 5;
      //  ENDIF;
      //  LINECNT += 10;
      //  IF LINECNT > 58;
      //    LINECNT = 0;
      //  ENDIF;
          //明細の印刷開始行の算出
          IF REM = 0;
            YP = YD+(ITEMS-1)*EL;
          ELSE;
            YP = YD+(REM-1)*EL;
          ENDIF;
          EXSR #WMEISAI;
        ENDSR;

        BEGSR #WMIDASI;
          WSTR(3:33:FN:18:18:'登録者リスト');
          WSTR(2:65:FN:10:10:'ページ：');
          WSTR(2:74:FN:10:10:%EDITC(PAGECNT:'3'));
          WSTR(3:65:FN:10:10:'出力日：');
          WSTR(3:71:FN:10:10:%EDITC(*DATE:'Y'));
        ENDSR;

        BEGSR #WMEISAI;
          WBOX(1+YP:2:11+YP:79:0.025);
          WHLINE(5+YP:24:79:0.01);
          WHLINE(3+YP:61:79:0.01);
          WHLINE(7+YP:61:79:0.01);
          WHLINE(9+YP:61:79:0.01);
          WHLINE(10+YP:65:79:0.005);
          WVLINE(1+YP:11:11+YP:0.01);
          WVLINE(1+YP:24:11+YP:0.01);
          WVLINE(1+YP:27:11+YP:0.01);
          WVLINE(1+YP:61:11+YP:0.01);
          WVLINE(1+YP:65:11+YP:0.01);
          WSTR(2+YP: 4:FN:16:16:%EDITC(REGNO:'X'));
          WSTR(2+YP:25.5:FN: 8: 8:'姓');
          WSTR(3+YP:25.5:FN: 8: 8:'名');
          WSTR(2+YP:28:FN:10:10:KNNAME);
          WSTR(4+YP:28:FN:18:18:KJNAME);
          WSTR(2+YP-0.2:62:FN: 8: 8:'性別');
          WSTR(2+YP:66:FN:12:12:GENDER);
          WSTR(3+YP+0.2:62:FN: 8: 8:'生年');
          WSTR(4+YP:62:FN: 8: 8:'月日');
          WSTR(4+YP:66:FN:12:12:%EDITC(BIRTHD:'Y'));
          WSTR(7+YP:25.5:FN: 8: 8:'住');
          WSTR(8+YP:25.5:FN: 8: 8:'所');
          WSTR(6+YP+0.4:28:FN:12:12:ADDR1);
          WSTR(8+YP:28:FN:12:12:ADDR2);
          WSTR(10+YP-0.4:28:FN:12:12:ADDR3);
          WSTR(5+YP+0.2:62:FN: 8: 8:'郵便');
          WSTR(6+YP:62:FN: 8: 8:'番号');
          WSTR(6+YP:66:FN:12:12:POST);
          WSTR(7+YP+0.2:62:FN: 8: 8:'都道');
          WSTR(8+YP:62:FN: 8: 8:'府県');
          WSTR(8+YP:66:FN:12:12:PREF);
          WSTR(9+YP+0.3:66:FN:10:10:TEL);
          WSTR(10+YP-0.2:62:FN:12:12:'TEL');
          WSTR(10+YP+0.3:66:FN:10:10:MOBILE);
          WBAR1(4+YP:3:%EDITC(REGNO:'X'));
          WBAR2(6+YP:52:%TRIMR(ADDR1)+%TRIMR(ADDR2)+%TRIMR(ADDR3));
          WIMG(1+YP:11:11+YP:24:%CHAR(REGNO) + '.JPG':'/IMG');
        ENDSR;

        BEGSR #WFOOT;
          WSTR(60:72:FN:8:8:'※社外秘※');
          WRITE EOP;
          DP('EOP');
        ENDSR;

        BEGSR #WSHUKEI;
          WSTR(14+YP:62:FN:14:14:'件数：');
          WSTR(14+YP:68:FN:14:14:%EDITC(RCDCNT:'3'));
          WHLINE(15+YP:61:73:0.03);
          EXSR #WFOOT;
        ENDSR;

      *
     OQPRINT    E            PRTOUT         1
     O                       PM                 198
      **************************
      *サブプロシージャー
      **************************
      *桁／行を指定し、CPIまたはLPIからインチで位置（左上）を返す
     PIPOS             B
     DIPOS             PI             5S 3
     D  POS                           5  2 CONST
     D  CLPI                          3  1 CONST
      *
        RETURN (POS-1)*(1/CLPI);
      *
     PIPOS             E
      **************************
      *バーコードの出力１
     PWBAR1            B
     DWBAR1            PI
     D  ROW                           5  2 CONST
     D  COL                           5  2 CONST
     D  STR                          50    CONST
      *
     D  ZONE           S              5S 0
      *
        B1Y = IPOS(ROW:LPI);
        B1X = IPOS(COL:CPI);
     C                   MOVEL     STR           ZONE
        EANDAT = ZONE;
        WRITE BAR1;
        DP('WBAR:B1Y=' + N2C(B1Y) + ',B1X=' + N2C(B1X));
      *
     PWBAR1            E
      **************************
      *バーコードの出力２
     PWBAR2            B
     DWBAR2            PI
     D  ROW                           5  2 CONST
     D  COL                           5  2 CONST
     D  STR                         106    CONST
      *
        B2Y = IPOS(ROW:LPI);
        B2X = IPOS(COL:CPI);
        QRDATA = STR;
        WRITE BAR2;
        DP('WBAR:B2Y=' + N2C(B2Y) + ',B2X=' + N2C(B2X));
      *
     PWBAR2            E
      **************************
      *イメージファイル
     PWIMG             B
     DWIMG             PI
     D  ROW1                          5  2 CONST
     D  COL1                          5  2 CONST
     D  ROW2                          5  2 CONST
     D  COL2                          5  2 CONST
     D  FILE                        128    CONST
     D  PATH                        128    CONST
      *
        IMGF = %TRIMR(FILE);
        IY = IPOSL(ROW1:LPI);
        IX = IPOSL(COL1:CPI);
        IMGH = (COL2-COL1)*(1/CPI);
        IMGW = (ROW2-ROW1)*(1/LPI);
        IMGP = %TRIMR(PATH);
        WRITE IMG;
        DP('WIMG:ROW1=' + N2C(ROW1) + ',COL1=' + N2C(COL1) +
           ',ROW2=' + N2C(ROW2) + ',COL2=' + N2C(COL2) +
           ',FILE="' + %TRIMR(FILE) + '",PATH="' + %TRIMR(PATH) + '"');
      *
     PWIMG             E
      **************************
      *文字出力
     PWSTR             B
     DWSTR             PI
     D  ROW                           5  2 CONST
     D  COL                           5  2 CONST
     D  FONTNAME                     30    CONST
     D  FONTH                         4  0 CONST
     D  FONTW                         4  0 CONST
     D  STR                         100    CONST
      *
        SY = IPOS(ROW+1:LPI);
        SX = IPOS(COL:CPI);
        FON = FONTNAME;
        FOH = FONTH;
        FOW = FONTW;
        UNISTR = %UCS2(%TRIMR(STR));
        WRITE STR01;
        DP('WSTR:SY=' + N2C(SY) + ',SX=' + N2C(SX) +
           ',FON="' + %TRIMR(FON) + '",FOH=' + N2C(FOH) + ',FOW=' + N2C(FOW) +
           ',STR="' + %TRIMR(STR) + '"');
      *
     PWSTR             E
      **************************
      *桁／行を指定し、CPIまたはLPIからインチで罫線位置
      *（桁と次の桁、または、行と次の行の中間点）を返す
     PIPOSL            B
     DIPOSL            PI             5S 3
     D  POS                           5  2 CONST
     D  CLPI                          3  1 CONST
      *
        RETURN (POS-1)*(1/CLPI) + (1/(CLPI*2));
      *
     PIPOSL            E
      **************************
      *ボックス罫線出力
     PWBOX             B
     DWBOX             PI
     D  ROW1                          5  2 CONST
     D  COL1                          5  2 CONST
     D  ROW2                          5  2 CONST
     D  COL2                          5  2 CONST
     D  WIDTH                         5S 3 CONST
      *
        BY1 = IPOSL(ROW1:LPI)-WIDTH/2; //罫線幅を考慮し、罫線位置を中間に設定
        BX1 = IPOSL(COL1:CPI)-WIDTH/2;
        BY2 = IPOSL(ROW2:LPI)+WIDTH/2;
        BX2 = IPOSL(COL2:CPI)+WIDTH/2;
        BLW = WIDTH;
        WRITE BOX;
        DP('WBOX:BY1=' + N2C(BY1) + ',BX1=' + N2C(BX1) +
           'BY2=' + N2C(BY2) + ',BX2=' + N2C(BX2) + ',BLW=' + N2C(BLW));
      *
     PWBOX             E
      **************************
      *横線出力
     PWHLINE           B
     DWHLINE           PI
     D  ROW1                          5  2 CONST
     D  COL1                          5  2 CONST
     D  COL2                          5  2 CONST
     D  WIDTH                         5S 3 CONST
      *
        HLY = IPOSL(ROW1:LPI)-WIDTH/2;
        HLX = IPOSL(COL1:CPI);
        HLL = (COL2-COL1)*(1/CPI);
        HLW = WIDTH;
        WRITE HLINE;
        DP('WHLINE:HLY=' + N2C(HLY) + ',HLX=' + N2C(HLX) +
           'HLL=' + N2C(HLL) + ',HLW=' + N2C(HLW));
      *
     PWHLINE           E
      **************************
      *縦線出力
     PWVLINE           B
     DWVLINE           PI
     D  ROW1                          5  2 CONST
     D  COL1                          5  2 CONST
     D  ROW2                          5  2 CONST
     D  WIDTH                         5S 3 CONST
      *
        VLY = IPOSL(ROW1:LPI);
        VLX = IPOSL(COL1:CPI)-WIDTH/2;
        VLL = (ROW2-ROW1)*(1/LPI);
        VLW = WIDTH;
        WRITE VLINE;
        DP('WVLINE:VLY=' + N2C(VLY) + ',VLX=' + N2C(VLX) +
           'VLL=' + N2C(VLL) + ',VLW=' + N2C(VLW));
      *
     PWVLINE           E
      **************************
      *数値→文字変換
     PN2C              B
     DN2C              PI            20    VARYING
     D NUMERIC                        9P 3 CONST
      *
        RETURN %TRIML(%EDITC(NUMERIC : 'P'));
      *
     PN2C              E
      **************************
      *デバッグ印刷（ジョブスイッチ１がオンの場合に有効）
     PDP               B
     DDP               PI
     D INSTR                        198    CONST
      *
     DCURTIME          S               Z
     DCURTIMEHMS       S               T
      *
     C                   IF        *INU1 = *ON
     C                   MOVEL     INSTR         PM
      * GET CURRENT TIME
     C                   TIME                    CURTIME
     C                   MOVE      CURTIME       CURTIMEHMS
     C                   MOVE      CURTIMEHMS    HMS               6 0
     C                   EXTRCT    CURTIME:*MS   MS                6 0
     C                   EVAL      PM = %EDITW(HMS : '  :  :  ') + '.' +
     C                                  %SUBST(%EDITW(MS : '0      ') : 2 : 3) +
     C                                  '|' + %TRIMR(PM)
     C
     C                   EXCEPT    PRTOUT
     C                   ENDIF
      *
     C                   RETURN
      *
     PDP               E