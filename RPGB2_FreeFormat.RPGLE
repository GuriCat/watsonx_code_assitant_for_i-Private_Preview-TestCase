**FREE

// ============================================================================
// プログラム名: RPGB2_FreeFormat
// 説明: 商品ファイルの消費税率と最終更新日時を更新
//       元のRPGサイクル処理を完全フリーフォーマットで再現
// ============================================================================

// ファイル定義 - 更新モード（UP）、外部記述
DCL-F SYOHIN USAGE(*UPDATE: *EXT) KEYED;

// 変数定義
DCL-S PRTXR PACKED(3:2);      // 消費税率
DCL-S PRUPDT DATE;            // 最終更新日
DCL-S PRUPTM TIME;            // 最終更新時刻

// メイン処理 - RPGサイクルの動作を再現
// 元のプログラムはRPGサイクルによりファイルから自動的にレコードを読み込む

// ファイルの全レコードを処理
DOW NOT %EOF(SYOHIN);
    // レコードの読み込み（RPGサイクルの代わり）
    READ SYOHIN;
    
    // EOF確認
    IF NOT %EOF(SYOHIN);
        // 元のC仕様の処理を実行
        
        // 消費税率の設定（8%）- 元: Z-ADD 0.08 PRTXR
        PRTXR = 0.08;
        
        // 最終更新日の設定 - 元: MOVE *DATE PRUPDT
        PRUPDT = %DATE();
        
        // 最終更新時刻の設定 - 元: TIME PRUPTM
        PRUPTM = %TIME();
        
        // レコードの更新 - 元: C 10 UPDAT SYOHINR
        // 元のプログラムでは標識10がオンの場合に更新
        // ISYOHINR 10により、SYOHINRレコード形式の場合は常に標識10がオン
        UPDATE SYOHINR;
    ENDIF;
ENDDO;

// プログラム終了
*INLR = *ON;
RETURN;
