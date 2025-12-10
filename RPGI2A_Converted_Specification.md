# RPGI2A 完全フリーフォーマットILE RPG変換仕様書

## 1. 概要
RPGI2Aプログラムは、IBM iシステム上で動作するILE RPGプログラムであり、登録者（PERSON）データをカナ（読み）で検索し、一覧表示および詳細表示を行う対話型アプリケーションです。本仕様書は、固定形式RPGコードを完全フリーフォーマットILE RPGに変換した詳細な仕様を定義します。

## 2. 変換概要
### 2.1 変換元情報
- **ソースファイル**: RPGI2A.RPG（固定形式RPG）
- **プログラムタイプ**: 対話型RPG（IDDU対応）
- **画面処理**: サブファイルを利用した一覧表示

### 2.2 変換後情報
- **ソースファイル**: RPGI2A_FreeFormat.RPGLE（完全フリーフォーマットILE RPG）
- **プログラムタイプ**: ILE RPGモジュール
- **コンパイルオプション**: 
  - Dftactgrp(*no)
  - Actgrp(*caller)
  - Bnddir('QC2LE')
  - Dat(*ISO)
  - DatFmt(*ISO)
  - Timfmt(*HMS)

### 2.3 変換による変更点

#### 2.3.1 言語構造の変換
| 固定形式 | フリーフォーマット | 変換内容 |
|---------|------------------|---------|
| C 操作コード | 操作コード | すべての操作コードをフリーフォーマットに変換 |
| IF 条件 | IF 条件 | 条件分岐をIF/ENDIF構造に変換 |
| DO ループ | DO/ENDDO | ループ処理をDO/ENDDO構造に変換 |
| BEGSR/ENDSR | BEGSR/ENDSR | サブルーチン構造は維持 |
| EXSR | EXSR | サブルーチン呼び出しは維持 |
| SETOFF/SETON | SETOFF/SETON | フラグ操作は維持 |

#### 2.3.2 宣言部の変換
- **固定形式**: ファイル定義のみ、変数は暗黙的宣言
- **フリーフォーマット**: 
  - DCL-Sによる変数の明示的宣言
  - DCL-Cによる定数の宣言
  - DCL-DSによるデータ構造体の宣言
  - 初期値の設定（INZ句）

## 3. ER図（Entity Relationship Diagram）

### 3.1 データベース構造

```mermaid
erDiagram
    PERSON {
        string REGNO PK "登録番号"
        string KJNAME "姓名"
        string KNNAME "姓名（読み）"
        char GENDER "性別"
        string TEL "電話番号（主）"
        string MOBILE "電話番号（副）"
        string POST "郵便番号"
        string PREF "都道府県"
        string ADDR1 "住所1"
        string ADDR2 "住所2"
        string ADDR3 "住所3"
        date BIRTHD "生年月日"
    }
    
    PERSON ||--o{ PERSONR : "レコード形式"
    
    PERSONR {
        string REGNO PK "登録番号"
        string KJNAME "姓名"
        string KNNAME "姓名（読み）"
        char GENDER "性別"
        string TEL "電話番号（主）"
        string MOBILE "電話番号（副）"
        string POST "郵便番号"
        string PREF "都道府県"
        string ADDR1 "住所1"
        string ADDR2 "住所2"
        string ADDR3 "住所3"
        date BIRTHD "生年月日"
    }
```

### 3.2 データ項目詳細

```mermaid
classDiagram
    class PERSON {
        <<Physical File>>
        +登録番号(REGNO): String[5]
        +姓名(KJNAME): String[22]
        +姓名(読み)(KNNAME): String[20]
        +性別(GENDER): Char[1]
        +電話番号(主)(TEL): String[12]
        +電話番号(副)(MOBILE): String[12]
        +郵便番号(POST): String[8]
        +都道府県(PREF): String[10]
        +住所1(ADDR1): String[32]
        +住所2(ADDR2): String[32]
        +住所3(ADDR3): String[32]
        +生年月日(BIRTHD): Date[8]
    }
    
    class PERSONR {
        <<Record Format>>
        +登録番号(REGNO): String[5]
        +姓名(KJNAME): String[22]
        +姓名(読み)(KNNAME): String[20]
        +性別(GENDER): Char[1]
        +電話番号(主)(TEL): String[12]
        +電話番号(副)(MOBILE): String[12]
        +郵便番号(POST): String[8]
        +都道府県(PREF): String[10]
        +住所1(ADDR1): String[32]
        +住所2(ADDR2): String[32]
        +住所3(ADDR3): String[32]
        +生年月日(BIRTHD): Date[8]
    }
    
    class PERSONL1 {
        <<Logical File>>
        +登録番号(REGNO): String[5]
        +姓名(読み)(KNNAME): String[20]
    }
    
    class RPGI2A {
        <<Program>>
        +検索処理()
        +一覧表示()
        +詳細表示()
        +カナリスト表示()
    }
    
    PERSON "1" --> "1..*" PERSONR : contains
    PERSON "1" --> "1..*" PERSONL1 : indexed by
    RPGI2A ..> PERSON : searches
    RPGI2A ..> PERSONL1 : uses for search
```

## 4. フローチャート

### 4.1 メイン処理フロー

```mermaid
flowchart TD
    Start([プログラム開始]) --> Init[変数初期化]
    Init --> ScreenSize[画面サイズ取得]
    ScreenSize --> SearchInput[検索条件入力画面表示]
    
    SearchInput --> F3{F3キー?}
    F3 -->|Yes| End([プログラム終了])
    F3 -->|No| F4{F4キー?}
    
    F4 -->|Yes| KanjiList[カナリスト表示]
    F4 -->|No| KeyInput{キー入力?}
    
    KanjiList --> KeyInput
    KeyInput -->|No| Error1[エラー: 未入力]
    KeyInput -->|Yes| Search[検索実行]
    
    Error1 --> SearchInput
    Search --> RecordFound{レコード found?}
    
    RecordFound -->|No| Error2[エラー: 該当なし]
    RecordFound -->|Yes| DisplayList[一覧表示画面]
    
    Error2 --> SearchInput
    DisplayList --> DetailReq{詳細表示要求?}
    
    DetailReq -->|Yes| Detail[詳細表示]
    DetailReq -->|No| ExitReq{F3/F12?}
    
    Detail --> F3Detail{F3キー?}
    F3Detail -->|Yes| BackToList[戻る]
    F3Detail -->|No| Detail
    
    BackToList --> DisplayList
    ExitReq -->|Yes| End
    ExitReq -->|No| DisplayList
    
    style Start fill:#90EE90
    style End fill:#FFB6C1
    style Error1 fill:#FFA07A
    style Error2 fill:#FFA07A
    style Detail fill:#87CEEB
```

### 4.2 検索処理フロー

```mermaid
flowchart TD
    SearchStart[検索開始] --> ClearSFL[サブファイルクリア]
    ClearSFL --> InitVars[変数初期化]
    InitVars --> SetLL[SETLL実行]
    
    SetLL --> ReadLoop{READ実行}
    ReadLoop -->|EOF| SearchEnd[検索終了]
    ReadLoop -->|レコードあり| CheckKey{キー一致?}
    
    CheckKey -->|Yes| AddToSFL[サブファイル追加]
    CheckKey -->|No| SearchEnd
    
    AddToSFL --> CheckCount{100件未満?}
    CheckCount -->|Yes| ReadLoop
    CheckCount -->|No| SearchEnd
    
    style SearchStart fill:#90EE90
    style SearchEnd fill:#FFB6C1
    style AddToSFL fill:#98FB98
```

### 4.3 詳細表示フロー

```mermaid
flowchart TD
    DetailStart[詳細表示開始] --> GetAttr[表示属性取得]
    GetAttr --> ReadDetail[詳細データ読込]
    
    ReadDetail --> ChainSuccess{CHAIN成功?}
    ChainSuccess -->|Yes| CreateURI[URI生成]
    ChainSuccess -->|No| Error[エラー表示]
    
    CreateURI --> CreateImg[画像URI生成]
    CreateImg --> CreateMap[地図URL生成]
    CreateMap --> Display[詳細画面表示]
    
    Display --> F3Check{F3キー?}
    F3Check -->|Yes| Return[戻る]
    F3Check -->|No| Display
    
    style DetailStart fill:#90EE90
    style Return fill:#FFB6C1
    style Error fill:#FFA07A
    style CreateURI fill:#87CEEB
```

## 5. 処理シーケンス図

### 5.1 メイン処理シーケンス

```mermaid
sequenceDiagram
    participant User as ユーザー
    participant PRG as RPGI2Aプログラム
    participant SCREEN as 画面
    participant FILE as PERSONファイル
    participant SYS as システム
    
    User->>PRG: プログラム起動
    PRG->>SCREEN: 検索条件入力画面表示
    
    alt F3押下
        User->>PRG: F3キー押下
        PRG->>PRG: プログラム終了
    else F4押下
        User->>PRG: F4キー押下
        PRG->>SCREEN: カナリスト表示
        User->>PRG: カナ選択
        PRG->>SCREEN: 検索条件入力画面表示
    else キー入力
        User->>SCREEN: 検索キー入力
        SCREEN->>PRG: キー値送信
        PRG->>FILE: SETLL実行
        FILE-->>PRG: レコード位置
        
        loop 検索処理
            PRG->>FILE: READ実行
            FILE-->>PRG: レコードデータ
            
            alt レコード存在
                PRG->>PRG: キー一致チェック
                PRG->>SCREEN: サブファイル書き込み
            else EOF
                PRG->>PRG: 検索終了
            end
        end
        
        PRG->>SCREEN: 一覧表示画面表示
        
        alt 詳細表示要求
            User->>PRG: 5入力 or ENTER
            PRG->>FILE: CHAIN実行
            FILE-->>PRG: 詳細データ
            
            PRG->>PRG: 画像URI生成
            PRG->>PRG: 地図URL生成
            PRG->>SCREEN: 詳細画面表示
        else F3/F12
            User->>PRG: F3/F12押下
            PRG->>SCREEN: 検索条件入力画面表示
        end
    end
```

### 5.2 サブファイル処理シーケンス

```mermaid
sequenceDiagram
    participant PRG as RPGI2Aプログラム
    participant SFL as サブファイル
    participant USER as ユーザー
    
    PRG->>SFL: サブファイル初期化
    loop レコード追加
        PRG->>SFL: レコード追加
        SFL-->>PRG: 追加完了
    end
    
    PRG->>USER: サブファイル表示
    USER->>SFL: 操作入力
    
    alt オプション5入力
        USER->>PRG: 5入力
        PRG->>SFL: レコード更新
        SFL-->>PRG: 更新完了
        PRG->>PRG: 詳細表示処理呼び出し
    else ENTER入力
        USER->>PRG: ENTER入力
        PRG->>SFL: カーソル行取得
        SFL-->>PRG: 行データ
        PRG->>PRG: 詳細表示処理呼び出し
    else その他入力
        USER->>PRG: 無効入力
        PRG->>SFL: エラー表示
        SFL-->>PRG: 表示完了
    end
```

## 6. 状態遷移図

```mermaid
stateDiagram-v2
    [*] --> 初期化状態: プログラム起動
    
    初期化状態 --> 画面サイズ取得: 変数初期化完了
    画面サイズ取得 --> 検索入力待機: サブファイル初期化
    
    検索入力待機 --> カナリスト表示: F4押下
    検索入力待機 --> 検索処理: キー入力
    検索入力待機 --> 終了状態: F3押下
    
    カナリスト表示 --> 検索入力待機: 選択完了
    
    検索処理 --> 検索中: SETLL実行
    検索中 --> 検索中: READ実行
    検索中 --> 一覧表示: レコード found or EOF
    
    一覧表示 --> 詳細表示: 5入力 or ENTER
    一覧表示 --> 検索入力待機: F3/F12押下
    
    詳細表示 --> 詳細表示中: 詳細データ取得
    詳細表示中 --> 一覧表示: F3押下
    詳細表示中 --> 詳細表示中: 画面更新
    
    終了状態 --> [*]: *INLR=ON
```

## 7. データフロー図

```mermaid
flowchart LR
    subgraph "入力データ"
        A1[(キーボード入力)]
        A2[(F3/F4キー)]
        A3[(マウス操作)]
    end
    
    subgraph "RPGI2Aプログラム"
        B1[検索処理モジュール]
        B2[一覧表示モジュール]
        B3[詳細表示モジュール]
        B4[カナリストモジュール]
        B5[画面制御モジュール]
    end
    
    subgraph "データファイル"
        C1[(PERSONファイル)]
        C2[(サブファイル)]
    end
    
    subgraph "出力データ"
        D1[(検索結果画面)]
        D2[(詳細情報画面)]
        D3[(カナ選択リスト)]
        D4[(エラーメッセージ)]
    end
    
    subgraph "システムリソース"
        E1[(システム日付)]
        E2[(システム時刻)]
        E3[(画面サイズ)]
    end
    
    A1 --> B1
    A2 --> B5
    A3 --> B5
    
    B1 --> C1
    C1 --> B1
    
    B1 --> B2
    B2 --> C2
    C2 --> B2
    
    B2 --> B3
    B3 --> C1
    B3 --> D2
    
    B5 --> B4
    B4 --> D3
    
    B1 --> D4
    B2 --> D4
    
    E1 --> B3
    E2 --> B3
    E3 --> B5
    
    D1 --> A1
    D2 --> A1
    D3 --> A1
    
    style B1 fill:#87CEEB
    style B2 fill:#87CEEB
    style B3 fill:#87CEEB
    style C1 fill:#FFE4B5
    style D1 fill:#98FB98
    style D2 fill:#98FB98
```

## 8. コンポーネント図

```mermaid
graph TB
    subgraph "IBM i システム"
        subgraph "RPGI2Aプログラム"
            A[メイン処理]
            B[初期化モジュール]
            C[検索モジュール]
            D[表示モジュール]
            E[サブファイルモジュール]
            F[エラーハンドリング]
        end
        
        subgraph "データベース層"
            G[(PERSON.PF<br/>物理ファイル)]
            H[(PERSONL1.LF<br/>論理ファイル)]
            I[(サブファイル)]
        end
        
        subgraph "表示層"
            J[(DSPF2A.DSPF<br/>表示ファイル)]
            K[検索入力画面]
            L[一覧表示画面]
            M[詳細表示画面]
            N[カナリスト画面]
        end
        
        subgraph "システムサービス"
            O[システム日時]
            P[画面管理]
            Q[キーボード入力]
        end
    end
    
    A --> B
    A --> C
    A --> D
    A --> E
    A --> F
    
    B --> I
    C --> G
    C --> H
    C --> I
    D --> K
    D --> L
    D --> M
    D --> N
    E --> I
    F --> J
    
    G --> O
    H --> O
    I --> P
    J --> Q
    
    style A fill:#87CEEB
    style G fill:#FFE4B5
    style J fill:#E6E6FA
```

## 9. 機能仕様

### 9.1 機能概要
- **検索機能**: 姓名の読み（カナ）で始まる登録者を検索
- **一覧表示**: 検索結果をサブファイルで表示（最大100件）
- **詳細表示**: 選択した登録者の詳細情報をウインドウで表示
- **リスト選択**: F4でカナ文字リストから選択
- **画面対応**: 80桁および132桁画面に対応
- **罫線描画**: 画面サイズに応じた罫線を動的に描画
- **性別による色分け**: 男性（青）、女性（白）、その他（緑）で表示

### 9.2 使用ファイル
#### 物理ファイル
- **PERSON.PF**: 登録者マスターファイル
  - REGNO (5S0): 登録番号（キー）
  - KJNAME (22O): 姓名
  - KNNAME (20): 姓名（読み）
  - GENDER (1): 性別 (M/F)
  - TEL (12): 電話番号（主）
  - MOBILE (12): 電話番号（副）
  - POST (8): 郵便番号
  - PREF (10J): 都道府県
  - ADDR1 (32O): 住所1
  - ADDR2 (32O): 住所2
  - ADDR3 (32O): 住所3
  - BIRTHD (8S): 生年月日

#### 論理ファイル
- **PERSONL1.LF**: 登録者検索用論理ファイル
  - REGNOをキーとしたアクセス

#### 表示ファイル
- **DSPF2A.DSPF**: 対話型表示ファイル
  - MIDASI: 検索条件入力画面
  - MEISFL: 一覧表示サブファイル
  - SYOSAI: 詳細表示ウインドウ
  - LISTSFL: カナ選択リストサブファイル
  - FOOTER: 機能キーガイド

## 10. 変換による改善点
1. **可読性向上**: コメントとインデントによるコードの可読性向上
2. **保守性向上**: 構造化されたコードによる保守性の向上
3. **デバッグ容易性**: フリーフォーマットによるデバッグの容易化
4. **現代的な構文**: 最新のRPG構文による開発効率向上
5. **エラーハンドリング**: 元のロジックを維持した堅牢なエラーハンドリング

## 11. 依存関係と環境要件
### 11.1 ハードウェア要件
- IBM i システム
- 必要なメモリ容量

### 11.2 ソフトウェア要件
- IBM i OS 7.1以上
- RPGLEコンパイラー
- 以下のライブラリ：
  - QC2LE（C言語ランタイム）

### 11.3 ファイル依存関係
- **PERSON.PF**: 登録者マスターファイル
- **PERSONL1.LF**: 登録者検索用論理ファイル
- **DSPF2A.DSPF**: 表示ファイル定義

## 12. 作成情報
- **作成日**: 2025年12月9日
- **変換元**: RPGI2A.RPG（固定形式RPG）
- **変換先**: RPGI2A_FreeFormat.RPGLE（完全フリーフォーマットILE RPG）
- **変換者**: AIアシスタント
- **検証済み**: はい（元コードとのロジック比較完了）

## 13. テスト推奨事項
1. **コンパイルテスト**: ソースファイルの正常コンパイル確認
2. **機能テスト**: 各機能の正常動作確認
3. **画面サイズテスト**: 80桁/132桁画面の両方での動作確認
4. **エラーテスト**: 各エラー条件での動作確認
5. **パフォーマンステスト**: 大量データ時のパフォーマンス確認
