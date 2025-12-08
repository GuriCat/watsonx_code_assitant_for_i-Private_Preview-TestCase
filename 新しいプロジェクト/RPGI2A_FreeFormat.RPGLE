**free
// プログラムのヘッダー
ctl-opt dftactgrp(*no) actgrp('RPGI2A') option(*srcstmt:*nodebugio);

// ファイル定義
dcl-f PERSONL1IF keyed;
dcl-f PERSON keyed;
dcl-f DSPF2A workstn infds(DSPDS);

// データ構造定義
dcl-ds DSPDS;
  DSPROW int(5);
end-ds;

dcl-ds GRID;
  GSLIN int(5);
  GSCOL int(5);
  GLEN int(5);
end-ds;

// メイン処理
begsr Main;
  exsr Init;
  dow not *inlr;
    exfmt DSPF2A;
    if *in03;
      leave;
    endif;

    // F4キー処理
    if *in04;
      exsr List;
      iter;
    endif;

    // 検索キー未入力チェック
    if Key = *blanks;
      dsply '検索キーが未入力です。';
      iter;
    endif;

    // サブファイルセット
    exsr SetSubfile;

    // レコードがない場合
    if RcdNum = 0;
      dsply '一致するレコードがありません。';
      iter;
    endif;

    // サブファイル表示
    exsr DisplaySubfile;
  enddo;
endsr;

// 初期化処理
begsr Init;
  dspRow = 24;
endsr;

// リスト表示処理
begsr List;
  dsply 'リストを表示します。';
endsr;

// サブファイルセット処理
begsr SetSubfile;
  dsply 'サブファイルをセットします。';
endsr;

// サブファイル表示処理
begsr DisplaySubfile;
  dsply 'サブファイルを表示します。';
endsr;

*inlr = *on;
return;