// RPGI2A - 完全フリーフォーマットILE RPG変換
// 概要: 登録者データをカナで検索・表示する対話型アプリケーション

ctl-opt Dftactgrp(*no) Actgrp(*caller) Bnddir('QC2LE') Dat(*ISO) 
        DatFmt(*ISO) Timfmt(*HMS) Usrgrp(*SYSVAL) Debug(*None) Option(*SrcStmt:*NoDebugIO);

// ファイル定義
/personl1 if e k disk;
/person   if e k disk;
dspf2a   cf e workstn infds(dspds) @srrn ksfile meisfl @irrn ksfile listsfl;

// 宣言部
dcl-s pgmnam(10a) inz(*blanks);           // プログラム名
dcl-s dsprow(5s 0) inz(0);                // 表示装置の画面サイズ(行)
dcl-s sflpag(5s 0) inz(0);                // サブファイルページサイズ
dcl-s sflsiz(5s 0) inz(0);                // サブファイルサイズ

// メッセージ格納用コンパイル時配列
dcl-c MSGDTA '検索条件（カナ）が未入力。';
dcl-c MSG(4) '検索条件（カナ）が未入力。' '一致するキーが見つからない。' '詳細表示は5を指定。' 'レコードの読取でエラー。';

// 検索リスト項目格納用コンパイル時配列
dcl-c KANJ(15) 'アイウエオ' 'カキクケコ' 'サシスセソ' 'タチツテト' 'ナニヌネノ'
              'ハヒフヘホ' 'マミムメモ' 'ヤユヨ' 'ラリルレロ' 'ワヲン' 'ガギグゲゴ' 'ザジズゼゾ' 'ダヂデド' 'バビブベボ' 'パピプペポ';
dcl-c KANA(45) 'ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾖﾗﾘﾙﾚﾛﾜｦ';

// 画像ディレクトリーURI用コンパイル時配列
dcl-c DIR 'FILE://GURI/IMG/';

// 地図リンクURL用コンパイル時配列
dcl-c URL 'https://www.google.co.jp/maps/place/';

// 画面罫線座標用コンパイル時配列
dcl-c GDATA(22) '006004073' '007004073' '023004073' '006004017' '006010017'
               '006032017' '006054017' '006055017' '006067017' '006077017'
               '006004122' '007004122' '025004122' '006004019' '006010019'
               '006032019' '006054019' '006055019' '006067019' '006080019'
               '006094019' '006126019';

// ファイル情報データ構造
dcl-ds dspds qualified;
  dsprow(5s 0);           // 画面の行数
end-ds;

// プログラム名取得
dcl-ds psds qualified;
  pgmnam(10a);            // プログラム名
end-ds;

// 罫線用データ構造
dcl-ds grid qualified;
  gslin(30a) inz('');     // 開始行
  gscol(60a) inz('');     // 開始桁
  glen(90a) inz('');      // 長さ
end-ds;

// ゾーン→文字変換
dcl-ds regz qualified;
  regc(60a) inz('');      // 文字フィールド
end-ds;

// 検索キー
dcl-s key(50a) inz(*blanks);              // 検索キー
dcl-s len(5s 0) inz(0);                   // 検索キーの長さ
dcl-s rcdnum(5s 0) inz(0);               // レコード数
dcl-s option(1a) inz(' ');               // オプション

// 画面位置
dcl-s @crow(5s 0) inz(0);                // カーソル行
dcl-s @ccol(5s 0) inz(0);                // カーソル列
dcl-s @ssize(5s 0) inz(0);               // 画面サイズ
dcl-s @srrn(5s 0) inz(0);               // サブファイル相対レコード番号
dcl-s @irrn(5s 0) inz(0);               // リストサブファイル相対レコード番号
dcl-s @sploc(5s 0) inz(0);              // サブファイル位置

// 罫線描画用
dcl-s @hgsl(5s 0) inz(0);               // 水平罫線開始行
dcl-s @hgsc(5s 0) inz(0);               // 水平罫線開始桁
dcl-s @hglen(5s 0) inz(0);              // 水平罫線長さ
dcl-s @vgsl(5s 0) inz(0);               // 垂直罫線開始行
dcl-s @vgsc(5s 0) inz(0);               // 垂直罫線開始桁
dcl-s @vglen(5s 0) inz(0);              // 垂直罫線長さ

// 表示属性
dcl-s @satr1(1a) inz(' ');              // 属性1
dcl-s @satr2(1a) inz(' ');              // 属性2

// 各種フラグ
dcl-s optcnt(5s 0) inz(0);               // オプションカウンタ
dcl-s wrrn(5s 0) inz(0);                // ワークサブファイルレコード番号
dcl-s inu8(1a) inz('N');                // 80桁画面フラグ

// 画像URI
dcl-s uriimg(50a) inz('');              // 画像URI
dcl-s pos(5s 0) inz(0);                 // 検索位置
dcl-s regno(5a) inz(' ');               // 登録番号
dcl-s regc(10a) inz('');                // 登録番号(文字)
dcl-s uriweb(80a) inz('');              // 地図URL
dcl-s post(8a) inz('');                 // 郵便番号

// 比較用変数
dcl-s cmpkey(20a) inz('');              // 比較キー

// 画面定義
c-control midasi enter(*in03) (*in04) (*in12);
c-control meisfl enter(*in03) (*in04) (*in12) (*in50) (*in60);
c-control listsfl enter(*in03) (*in04) (*in97);
c-control syosai enter(*in03);

// メイン処理
exsr #init;

dow *hival;
  // フッター書き込み
  writefooter();
  exfmt midasi;
  
  // F3=終了
  if *in03;
    leave;
  endif;
  
  // F4=リスト
  if *in04;
    exsr #list;
    iterate;
  endif;
  
  // 検索キー未入力
  if key = *blanks;
    seton *in50;
    movel msg(1) msgdta;
    iterate;
  endif;
  
  // サブファイル・レコードのセット
  exsr #setsf;
  
  // キーが合致するレコードが無い
  if rcdnum = 0;
    seton *in50;
    movel msg(2) msgdta;
    iterate;
  endif;
  
  // サブファイル表示
  movea '10' *in(31);
  z-add 1 @sploc;
  seton *in60;
  setoff *in0312;
  
  dow *hival;
    writefooter();
    writemeiasi();
    writeheadds3();
    writeheadds4();
    exsr #dgrid;
    exfmt meictl;
    writeclrgrd();
    
    // F3/12=戻る
    if *in03 or *in12;
      leave;
    endif;
    
    setoff *in50;
    
    // サブファイル対話処理
    exsr #sflp;
    
    // F3/12=戻る
    if *in03 or *in12;
      leave;
    endif;
  enddo;
  
  setoff *in60;
enddo;

seton *lr;
return;

// サブルーチン

// ###初期設定
begsr #init;
  // 表示装置の画面サイズの取得
  dsprow = %size(dspds);
  
  // 画面サイズに合わせてSFLSIZ設定
  if dsprow <= 24;
    inu8 = 'Y';
    z-add 9 @ssize;
  else;
    inu8 = 'N';
    z-add 19 @ssize;
  endif;
  
  sflpag = @ssize / 2;
  
  // 検索リストサブファイルの作成
  seton *in90;
  writelistctl();
  setoff *in90;
  
  do 45 @irrn;
    movel kanj(@irrn) @irrnitem;
    writelistsfl();
  enddo;
endsr;

// ###検索リストの表示（サブファイル・ウインドゥ）
begsr #list;
  // カーソル位置の設定
  z-add 1 @crow;
  z-add 1 @ccol;
  
  // リストウインドゥの表示
  writelistctl();
  writelistf();
  read listctl(97);
  
  // サブファイル内でF3（取消）の場合は何もしない
  if *in03;
    // F3以外(ENTER)の場合、サブファイル行に対応した文字をセット
    else;
      if @irrn >= 1 and @irrn <= 45;
        movel kana(@irrn) key;
      else;
        // サブファイルレコード外でENTERを押した場合は取消扱い
        seton *in03;
      endif;
    endif;
  endif;
endsr;

// ###サブファイルのセット
begsr #setsf;
  // サブファイルのクリア(SFLCLR)
  movea '01' *in(31);
  writemeictl();
  movea '10' *in(31);
  
  // 変数の初期化
  z-add 0 @srrn;
  z-add 0 rcdnum;
  len = %len(%trim(key));
  move *blanks option;
  
  // レコードの検索とサブファイルへの書出し
  setll personr key;
  
  dow *hival;
    read personr(71);
    
    // ファイルの終わり
    if %eof;
      leave;
    endif;
    
    // キー値と一致しない場合は終了
    if %trim(subst(knname:1:len)) <> %trim(key);
      leave;
    endif;
    
    add 1 rcdnum;
    add 1 @srrn;
    exsr #atr;
    writemeisfl();
    
    // 最大100件まで表示
    if rcdnum >= 100;
      leave;
    endif;
  enddo;
endsr;

// ###サブファイル対話処理
begsr #sflp;
  // 変数の初期化
  setoff *in50;
  z-add 0 optcnt;
  z-add @srrn wrrn;
  
  // サブファイルでの操作チェック
  do rcdnum i;
    if chain meisfl(wrrn:80);
      leave;
    endif;
    
    // オプションに5が指定→詳細表示（色を変更）
    select;
      when option = '5';
        add 1 optcnt;
        move *blanks option;
        updatemeisfl();
        z-add @srrn wrrn;
        exsr #dspdt;
        
        // F3で詳細を抜けても最初の画面に戻さない
        if *in03;
          leave;
        endif;
        
      // オプションがブランク→そのまま更新
      when option = ' ';
        updatemeisfl();
        
      // オプションに5とブランク以外→エラー
      other;
        add 1 optcnt;
        seton *in50;
        movel msg(3) msgdta;
        move *blanks option;
        updatemeisfl();
        z-add @srrn wrrn;
        leave;
    endsl;
  enddo;
  
  // オプション未指定＆サブファイル上でENTER→詳細表示
  // 外でENTER→前画面
  if optcnt = 0;
    // カーソル行のデータを表示
    if wrrn > 0 and wrrn <= rcdnum;
      if chain meisfl(wrrn:81);
        exsr #dspdt;
        z-add @srrn @sploc;
      else;
        seton *in12;
      endif;
    else;
      // カーソルがサブファイル外
      seton *in12;
    endif;
  else;
    // オプションがブランク以外
    z-add wrrn @sploc;
  endif;
  
  // F3で詳細を抜けても最初の画面に戻さない
  if *in03;
    setoff *in03;
  endif;
endsr;

// ###詳細表示（ウインドゥ）
begsr #dspdt;
  exsr #atr;
  
  // 再度データを読み込んで全詳細情報を取得
  chain personr2 regno(72);
  
  if *in72 = *off;
    // 画像URIの設定
    // (A) REGNO(ZONE) -> REGZ(DS-ZONE) = REGC(DS-CHAR)
    // (B) POS = "0"以外の文字位置-> 3
    // (C) "00123"の3文字目以降を取出し、後続ブランク埋"00123" -> "123  "
    // (D) URIIMGに挿入ブランク0で連結URIIMG -> URIIMG |< "123  "
    // (E)拡張子を挿入ブランク0で連結URIIMG -> URIIMG |< ".JPG"
    movel dir(1) uriimg;
    z-add 0 regz;
    move regno regz;
    '0' check regc(pos:10);
    if pos > 0;
      substr regc:pos regc;
    endif;
    cat regc:0 uriimg;
    cat '.JPG':0 uriimg;
    
    // 地図URLの設定
    movel url(1) uriweb;
    cat post:0 uriweb;
    
    // 詳細画面の表示
    exfmt syosai;
  else;
    // REGNOでのCHAINでエラー
    if chain meisfl(80);
      seton *in50;
      movel msg(4) msgdta;
      move ' ' option;
      updatemeisfl();
      seton *in03;
      z-add @srrn wrrn;
    endif;
  endif;
endsr;

// ###表示属性（プログラム−システム間フィールド）のセット
begsr #atr;
  select;
    when gender = 'M';
      move x'3A' @satr1;  // 青
      move x'3E' @satr2;  // 青下線
    when gender = 'F';
      move x'22' @satr1;  // 白
      move x'26' @satr2;  // 白下線
    other;
      move x'20' @satr1;  // 緑
      move x'24' @satr2;  // 緑下線
  endsl;
endsr;

// ###画面罫線描画
begsr #dgrid;
  // 80桁画面
  if inu8 = 'Y';
    do 3 j;
      move gdata(j) grid;
      @hgsl = %int(grid.gslin);
      @hgsc = %int(grid.gscol);
      @hglen = %int(grid.glen);
      writehgrdr();
    enddo;
    
    do 10 j;
      move gdata(j+3) grid;
      @vgsl = %int(grid.gslin);
      @vgsc = %int(grid.gscol);
      @vglen = %int(grid.glen);
      writevgrdr();
    enddo;
  else;
    // 132桁画面
    do 13 j;
      move gdata(j+10) grid;
      @hgsl = %int(grid.gslin);
      @hgsc = %int(grid.gscol);
      @hglen = %int(grid.glen);
      writehgrdr();
    enddo;
    
    do 22 j;
      move gdata(j+23) grid;
      @vgsl = %int(grid.gslin);
      @vgsc = %int(grid.gscol);
      @vglen = %int(grid.glen);
      writevgrdr();
    enddo;
  endif;
endsr;
