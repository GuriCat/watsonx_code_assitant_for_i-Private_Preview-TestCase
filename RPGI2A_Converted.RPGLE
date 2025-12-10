**free
Ctl-opt Dftactgrp(*no) Actgrp(*caller) Bnddir('QC2LE');

//******************************************************************************
// ファイル定義
//******************************************************************************
Dcl-f PERSONL1 Disk(*ext) Keyed Usage(*input) Rename(PERSONR2 : PERSONR);
Dcl-f PERSON Disk(*ext) Keyed Usage(*input);
Dcl-f DSPF2A Workstn(*ext) Sfile(Meisfl : @Srrn)
                    Sfile(Listsfl : @Irrn) Infds(Dspds);

//******************************************************************************
// メッセージ格納用コンパイル時配列
//******************************************************************************
Dcl-ds Msg Qualified;
  Msg1 Char(78) Inz('検索条件（カナ）が未入力。');
  Msg2 Char(78) Inz('一致するキーが見つからない。');
  Msg3 Char(78) Inz('詳細表示は5を指定。');
  Msg4 Char(78) Inz('レコードの読取でエラー。');
End-ds;

//******************************************************************************
// 検索リスト項目格納用コンパイル時配列
//******************************************************************************
Dcl-ds Kanj Qualified;
  Item1 Char(45) Inz('アイウエオカキクケコサシスセソ');
  Item2 Char(45) Inz('タチツテトナニヌネノハヒフヘホ');
  Item3 Char(45) Inz('マミムメモヤユヨラリルレロワヲ');
End-ds;

Dcl-ds Kana Qualified;
  Kana1 Char(45) Inz('ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾖﾗﾘﾙﾚﾛﾜｦ');
End-ds;

//******************************************************************************
// 画像ディレクトリーURI用コンパイル時配列
//******************************************************************************
Dcl-ds Dir Qualified;
  Dir1 Char(50) Inz('FILE://GURI/IMG/');
End-ds;

//******************************************************************************
// 地図リンクURL用コンパイル時配列
//******************************************************************************
Dcl-ds Url Qualified;
  Url1 Char(80) Inz('https://www.google.co.jp/maps/place/');
End-ds;

//******************************************************************************
// 画面罫線座標用コンパイル時配列
//******************************************************************************
Dcl-ds Gdata Qualified;
  // 80桁画面水平線
  Gd1 Char(9) Inz('006004073');
  Gd2 Char(9) Inz('007004073');
  Gd3 Char(9) Inz('023004073');
  // 80桁画面縦線
  Gd4 Char(9) Inz('006004017');
  Gd5 Char(9) Inz('006010017');
  Gd6 Char(9) Inz('006032017');
  Gd7 Char(9) Inz('006054017');
  Gd8 Char(9) Inz('006055017');
  Gd9 Char(9) Inz('006067017');
  Gd10 Char(9) Inz('006077017');
  // 132桁画面水平線
  Gd11 Char(9) Inz('006004122');
  Gd12 Char(9) Inz('007004122');
  Gd13 Char(9) Inz('025004122');
  // 132桁画面縦線
  Gd14 Char(9) Inz('006004019');
  Gd15 Char(9) Inz('006010019');
  Gd16 Char(9) Inz('006032019');
  Gd17 Char(9) Inz('006054019');
  Gd18 Char(9) Inz('006055019');
  Gd19 Char(9) Inz('006067019');
  Gd20 Char(9) Inz('006080019');
  Gd21 Char(9) Inz('006094019');
  Gd22 Char(9) Inz('006126019');
End-ds;

//******************************************************************************
// ファイル情報データ構造
//******************************************************************************
Dcl-ds Dspds;
  Dsprow Int(5) Pos(152);
End-ds;

//******************************************************************************
// プログラム名取得
//******************************************************************************
Dcl-ds Psds Psds;
  Pgmnam Char(10) Pos(1);
End-ds;

//******************************************************************************
// 罫線用データ構造（開始行：開始桁：長さ）
//******************************************************************************
Dcl-ds Grid;
  Gslin Char(3) Pos(1);
  Gscol Char(3) Pos(4);
  Glen Char(3) Pos(7);
End-ds;

//******************************************************************************
// ゾーン→文字変換
//******************************************************************************
Dcl-ds Regds;
  Regz Zoned(6:0) Pos(1);
  Regc Char(6) Pos(1);
End-ds;

//******************************************************************************
// 変数定義
//******************************************************************************
Dcl-s @Srrn Int(5);
Dcl-s @Irrn Int(5);
Dcl-s @Ssize Int(5);
Dcl-s @Sploc Int(5);
Dcl-s @Crow Int(5);
Dcl-s @Ccol Int(5);
Dcl-s Rcdnum Int(5);
Dcl-s Key Char(50);
Dcl-s Msgdta Char(78);
Dcl-s Chekrkey Char(50);
Dcl-s Len Int(5);
Dcl-s Cmpkey Char(20);
Dcl-s Option Char(1);
Dcl-s Optcnt Int(5);
Dcl-s Wrrn Int(5);
Dcl-s I Int(5);
Dcl-s Regno Int(5);
Dcl-s Uriimg Char(50);
Dcl-s Uriweb Char(80);
Dcl-s Pos Int(5);
Dcl-s J Int(5);
Dcl-s @Hgsl Int(5);
Dcl-s @Hgsc Int(5);
Dcl-s @HgLen Int(5);
Dcl-s @Vgsl Int(5);
Dcl-s @Vgsc Int(5);
Dcl-s @VgLen Int(5);

//******************************************************************************
// メインルーチン
//******************************************************************************
@Srrn = 0;
@Irrn = 0;

Exsr #Init;

Dou *On;
  Write Footer;
  Exfmt Midasi;
  // F3=終了
  If *In03;
    Leave;
  Endif;
  *In50 = *Off;
  // F4=リスト
  If *In04;
    Exsr #List;
    If *In03;
      Iter;
    Endif;
  Endif;
  // 検索キー未入力
  If Key = *Blanks;
    *In50 = *On;
    Msgdta = Msg.Msg1;
    Iter;
  Endif;
  // サブファイル・レコードのセット
  Exsr #Setsf;
  // キーが合致するレコードが無い
  If Rcdnum = 0;
    *In50 = *On;
    Msgdta = Msg.Msg2;
    Iter;
  Endif;
  // サブファイル表示
  *In(31) = '1';
  @Sploc = 1;
  *In60 = *On;
  *In03 = *Off;
  *In12 = *Off;
  Dou *On;
    Write Footer;
    Write Midasi;
    If *In40;
      Write Headds3;
    Else;
      Write Headds4;
    Endif;
    Exsr #Dgrid;
    Exfmt Meictl;
    Write Clrgrd;
    // F3/12=戻る
    If *In03 Or *In12;
      Leave;
    Endif;
    *In50 = *Off;
    // サブファイル対話処理
    Exsr #Sflp;
    // F3/12=戻る
    If *In03 Or *In12;
      Leave;
    Endif;
  Enddo;
  *In60 = *Off;
Enddo;

*Inlr = *On;
Return;

//******************************************************************************
// サブルーチン
//******************************************************************************

//******************************************************************************
//###初期設定
//******************************************************************************
Dcl-proc #Init;
  // 表示装置の画面サイズの取得
  If Dsprow = 24;
    *In40 = *On;
  Else;
    *In40 = *Off;
  Endif;
  // 画面サイズに合わせてSFLSIZ設定
  If *In40;
    @Ssize = 9;
  Else;
    @Ssize = 19;
  Endif;
  // 検索リストサブファイルの作成
  *In90 = *On;
  Write Listctl;
  *In90 = *Off;
  For @Irrn = 1 To 45;
    If @Irrn <= 15;
      Item = %Subst(Kanj.Item1 : (@Irrn-1)*4 +1 : 4);
    Elseif @Irrn <= 30;
      Item = %Subst(Kanj.Item2 : (@Irrn-16)*4 +1 : 4);
    Else;
      Item = %Subst(Kanj.Item3 : (@Irrn-31)*4 +1 : 4);
    Endif;
    Write Listsfl;
  Endfor;
End-proc;

//******************************************************************************
//###検索リストの表示（サブファイル・ウインドゥ）
//******************************************************************************
Dcl-proc #List;
  // カーソル位置の設定
  @Crow = 1;
  @Ccol = 1;
  // リストウインドゥの表示
  Write Listctl;
  Write Listf;
  Read Listctl;
  // サブファイル内でF3（取消）の場合は何もしない
  If Not *In03;
    // F3以外(ENTER)の場合、サブファイル行に対応した文字をセット
    If @Irrn >= 1 And @Irrn <= 45;
      Key = %Subst(Kana.Kana1 : (@Irrn-1) +1 : 1);
    Else;
      // サブファイルレコード外でENTERを押した場合は取消扱い
      *In03 = *On;
    Endif;
  Endif;
End-proc;

//******************************************************************************
//###サブファイルのセット
//******************************************************************************
Dcl-proc #Setsf;
  // サブファイルのクリア(SFLCLR)
  *In(31) = '0';
  Write Meictl;
  *In(31) = '1';
  // 変数の初期化
  @Srrn = 0;
  Rcdnum = 0;
  Chekrkey = Key;
  Len = %Len(%Trim(Key));
  Option = *Blanks;
  // レコードの検索とサブファイルへの書出し
  Setll Key Personr;
  Dou *On;
    Read Personr;
    // ファイルの終わり
    If %Eof;
      Leave;
    Endif;
    // キー値と一致しない場合は終了
    %Subst(Cmpkey : 1 : Len) = %Subst(Kname : 1 : Len);
    If Key <> Cmpkey;
      Leave;
    Endif;
    Rcdnum += 1;
    @Srrn += 1;
    Exsr #Atr;
    Write Meisfl;
    // 最大100件まで表示
    If Rcdnum >= 100;
      Leave;
    Endif;
  Enddo;
End-proc;

//******************************************************************************
//###サブファイル対話処理
//******************************************************************************
Dcl-proc #Sflp;
  // 変数の初期化
  *In50 = *Off;
  Optcnt = 0;
  Wrrn = @Srrn;
  // サブファイルでの操作チェック
  For I = 1 To Rcdnum;
    Chain I Meisfl;
    If %Found;
      Select;
        When Option = '5';
          // オプションに5が指定→詳細表示（色を変更）
          Optcnt += 1;
          Option = *Blanks;
          Update Meisfl;
          Wrrn = @Srrn;
          Exsr #Dspdt;
          // F3で詳細を抜けても最初の画面に戻さない
          If *In03;
            Leave;
          Endif;
        When Option = ' ';
          // オプションがブランク→そのまま更新
          Update Meisfl;
        Other;
          // オプションに5とブランク以外→エラー
          Optcnt += 1;
          *In50 = *On;
          Msgdta = Msg.Msg3;
          Option = *Blanks;
          Update Meisfl;
          Wrrn = @Srrn;
          Leave;
      Endsl;
    Else;
      Leave;
    Endif;
  Endfor;
  // オプション未指定＆サブファイル上でENTER→詳細表示
  // 外でENTER→前画面
  If Optcnt = 0;
    // カーソル行のデータを表示
    If Wrrn > 0 And Wrrn <= Rcdnum;
      Chain Wrrn Meisfl;
      If Not %Error;
        Exsr #Dspdt;
        @Sploc = @Srrn;
      Endif;
    Else;
      // カーソルがサブファイル外
      *In12 = *On;
    Endif;
  Else;
    // オプションがブランク以外
    @Sploc = Wrrn;
  Endif;
  // F3で詳細を抜けても最初の画面に戻さない
  If *In03;
    *In03 = *Off;
  Endif;
End-proc;

//******************************************************************************
//###詳細表示（ウインドゥ）
//******************************************************************************
Dcl-proc #Dspdt;
  Exsr #Atr;
  // 再度データを読み込んで全詳細情報を取得
  Chain Regno Personr;
  If %Found;
    // 画像URIの設定
    //   (A) REGNO(ZONE) -> REGZ(DS-ZONE) = REGC(DS-CHAR)
    //          00123          00123          "00123"
    //   (B) POS = "0"以外の文字位置-> 3
    //   (C) "00123"の3文字目以降を取出し、後続ブランク埋"00123" -> "123  "
    //   (D) URIIMGに挿入ブランク0で連結URIIMG -> URIIMG |< "123  "
    //   (E)拡張子を挿入ブランク0で連結URIIMG -> URIIMG |< ".JPG"
    Uriimg = Dir.Dir1;
    Regz = Regno;
    Pos = %Check('0' : Regc);
    If Pos > 0;
      %Subst(Regc : 1) = %Subst(Regc : Pos);
    Endif;
    Uriimg = %Trim(Uriimg) + %Trim(Regc);
    Uriimg = %Trim(Uriimg) + '.JPG';
    // 地図URLの設定
    Uriweb = Url.Url1 + %Char(Post);
    // 詳細画面の表示
    Exfmt Syosai;
  Else;
    // REGNOでのCHAINでエラー
    Chain Wrrn Meisfl;
    *In50 = *On;
    Msgdta = Msg.Msg4;
    Option = ' ';
    Update Meisfl;
    *In03 = *On;
    Wrrn = @Srrn;
  Endif;
End-proc;

//******************************************************************************
//###表示属性（プログラム−システム間フィールド）のセット
//******************************************************************************
Dcl-proc #Atr;
  Select;
    When Gender = 'M';
      // 青
      @Satr1 = X'3A';
      // 青下線
      @Satr2 = X'3E';
    When Gender = 'F';
      // 白
      @Satr1 = X'22';
      // 白下線
      @Satr2 = X'26';
    Other;
      // 緑
      @Satr1 = X'20';
      // 緑下線
      @Satr2 = X'24';
  Endsl;
End-proc;

//******************************************************************************
//###画面罫線描画
//******************************************************************************
Dcl-proc #Dgrid;
  // 80桁画面
  If *In40;
    For J = 1 To 3;
      Grid = Gdata.Gd(J);
      @Hgsl = %Int(Gslin);
      @Hgsc = %Int(Gscol);
      @HgLen = %Int(Glen);
      Write Hgrdr;
    Endfor;
    For J = 4 To 10;
      Grid = Gdata.Gd(J);
      @Vgsl = %Int(Gslin);
      @Vgsc = %Int(Gscol);
      @VgLen = %Int(Glen);
      Write Vgrdr;
    Endfor;
  Else;
    // 132桁画面
    For J = 11 To 13;
      Grid = Gdata.Gd(J);
      @Hgsl = %Int(Gslin);
      @Hgsc = %Int(Gscol);
      @HgLen = %Int(Glen);
      Write Hgrdr;
    Endfor;
    For J = 14 To 22;
      Grid = Gdata.Gd(J);
      @Vgsl = %Int(Gslin);
      @Vgsc = %Int(Gscol);
      @VgLen = %Int(Glen);
      Write Vgrdr;
    Endfor;
  Endif;
End-proc;