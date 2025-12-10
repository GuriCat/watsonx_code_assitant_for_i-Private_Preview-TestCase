# RPGB2 ER図とフローチャート

## 1. ER図（Entity Relationship Diagram）

### データベース構造

```mermaid
erDiagram
    SYOHIN {
        string SYOHIN_CODE PK "商品コード"
        string SYOHIN_NAME "商品名"
        decimal PRTXR "消費税率"
        date PRUPDT "最終更新日"
        time PRUPTM "最終更新時刻"
    }
    
    SYOHIN ||--o{ SYOHINR : "レコード形式"
    
    SYOHINR {
        string SYOHIN_CODE PK "商品コード"
        string SYOHIN_NAME "商品名"
        decimal PRTXR "消費税率(0.08)"
        date PRUPDT "最終更新日"
        time PRUPTM "最終更新時刻"
    }
```

### データ項目詳細

```mermaid
classDiagram
    class SYOHIN {
        <<Physical File>>
        +商品コード: String
        +商品名: String
        +消費税率(PRTXR): Decimal(3,2)
        +最終更新日(PRUPDT): Date
        +最終更新時刻(PRUPTM): Time
    }
    
    class SYOHINR {
        <<Record Format>>
        +商品コード: String
        +商品名: String
        +消費税率(PRTXR): Decimal(3,2)
        +最終更新日(PRUPDT): Date
        +最終更新時刻(PRUPTM): Time
    }
    
    class RPGB2 {
        <<Program>>
        +消費税率設定()
        +最終更新日時設定()
        +レコード更新()
    }
    
    SYOHIN "1" --> "1..*" SYOHINR : contains
    RPGB2 ..> SYOHIN : updates
```

## 2. フローチャート

### 2.1 メイン処理フロー

```mermaid
flowchart TD
    Start([プログラム開始]) --> Init[変数初期化]
    Init --> OpenFile[SYOHINファイルオープン]
    OpenFile --> ReadLoop{レコード読み込み}
    
    ReadLoop -->|EOF| End([プログラム終了])
    ReadLoop -->|レコードあり| CheckIndicator{指示子10<br/>オン?}
    
    CheckIndicator -->|Yes| SetTax[消費税率=0.08設定]
    CheckIndicator -->|No| ReadLoop
    
    SetTax --> SetDate[最終更新日=現在日付]
    SetDate --> SetTime[最終更新時刻=現在時刻]
    SetTime --> UpdateRec[レコード更新<br/>UPDATE SYOHINR]
    UpdateRec --> ReadLoop
    
    style Start fill:#90EE90
    style End fill:#FFB6C1
    style SetTax fill:#87CEEB
    style SetDate fill:#87CEEB
    style SetTime fill:#87CEEB
    style UpdateRec fill:#FFA500
```

### 2.2 詳細処理フロー（RPGサイクル含む）

```mermaid
flowchart TD
    A([プログラム開始<br/>*INLR=OFF]) --> B[ファイル定義<br/>SYOHIN UP E DISK]
    B --> C[入力仕様<br/>ISYOHINR 10]
    C --> D{RPGサイクル開始<br/>ファイルから<br/>レコード読み込み}
    
    D -->|EOF| Z([*INLR=ON<br/>プログラム終了])
    D -->|レコードあり| E[レコード識別<br/>SYOHINR形式?]
    
    E -->|Yes| F[指示子10=ON]
    E -->|No| D
    
    F --> G[Z-ADD 0.08 → PRTXR<br/>消費税率8%設定]
    G --> H[MOVE *DATE → PRUPDT<br/>システム日付取得]
    H --> I[TIME → PRUPTM<br/>現在時刻取得]
    I --> J{指示子10<br/>オン?}
    
    J -->|Yes| K[UPDAT SYOHINR<br/>レコード更新]
    J -->|No| D
    K --> D
    
    style A fill:#90EE90
    style Z fill:#FFB6C1
    style G fill:#87CEEB
    style H fill:#87CEEB
    style I fill:#87CEEB
    style K fill:#FFA500
    style F fill:#FFFF99
```

### 2.3 フリーフォーマット版フローチャート

```mermaid
flowchart TD
    Start([プログラム開始]) --> DeclFile[ファイル定義<br/>DCL-F SYOHIN]
    DeclFile --> DeclVars[変数定義<br/>PRTXR, PRUPDT, PRUPTM]
    DeclVars --> LoopStart{DOW NOT %EOF}
    
    LoopStart -->|True| Read[READ SYOHIN]
    LoopStart -->|False| SetLR[*INLR = *ON]
    
    Read --> CheckEOF{%EOF?}
    CheckEOF -->|True| LoopStart
    CheckEOF -->|False| SetTax[PRTXR = 0.08]
    
    SetTax --> SetDate[PRUPDT = %DATE]
    SetDate --> SetTime[PRUPTM = %TIME]
    SetTime --> Update[UPDATE SYOHINR]
    Update --> LoopStart
    
    SetLR --> Return([RETURN])
    
    style Start fill:#90EE90
    style Return fill:#FFB6C1
    style SetTax fill:#87CEEB
    style SetDate fill:#87CEEB
    style SetTime fill:#87CEEB
    style Update fill:#FFA500
```

## 3. 処理シーケンス図

```mermaid
sequenceDiagram
    participant PRG as RPGB2プログラム
    participant FILE as SYOHINファイル
    participant SYS as システム
    
    PRG->>FILE: ファイルオープン(更新モード)
    activate FILE
    
    loop 全レコード処理
        PRG->>FILE: レコード読み込み(READ)
        FILE-->>PRG: レコードデータ
        
        alt レコードが存在
            PRG->>PRG: 消費税率=0.08設定
            PRG->>SYS: 現在日付取得(*DATE)
            SYS-->>PRG: システム日付
            PRG->>PRG: PRUPDT設定
            
            PRG->>SYS: 現在時刻取得(TIME)
            SYS-->>PRG: システム時刻
            PRG->>PRG: PRUPTM設定
            
            PRG->>FILE: レコード更新(UPDATE)
            FILE-->>PRG: 更新完了
        else EOF
            PRG->>PRG: ループ終了
        end
    end
    
    PRG->>FILE: ファイルクローズ
    deactivate FILE
    PRG->>PRG: *INLR=ON
```

## 4. 状態遷移図

```mermaid
stateDiagram-v2
    [*] --> 初期化: プログラム開始
    初期化 --> ファイルオープン: SYOHIN定義
    ファイルオープン --> レコード読み込み待機
    
    レコード読み込み待機 --> レコード読み込み中: READ実行
    レコード読み込み中 --> データ処理: レコード存在
    レコード読み込み中 --> 終了処理: EOF検出
    
    データ処理 --> 消費税率設定: 指示子10オン
    消費税率設定 --> 日付設定: PRTXR=0.08
    日付設定 --> 時刻設定: PRUPDT設定
    時刻設定 --> レコード更新: PRUPTM設定
    レコード更新 --> レコード読み込み待機: UPDATE完了
    
    終了処理 --> [*]: *INLR=ON
```

## 5. データフロー図

```mermaid
flowchart LR
    A[(SYOHINファイル)] -->|レコード読み込み| B[RPGB2プログラム]
    C[システム日付] -->|*DATE| B
    D[システム時刻] -->|TIME| B
    E[定数: 0.08] -->|消費税率| B
    
    B -->|PRTXR更新| F[消費税率フィールド]
    B -->|PRUPDT更新| G[最終更新日フィールド]
    B -->|PRUPTM更新| H[最終更新時刻フィールド]
    
    F --> I[(更新済みレコード)]
    G --> I
    H --> I
    
    I -->|UPDATE| A
    
    style A fill:#FFE4B5
    style B fill:#87CEEB
    style I fill:#98FB98
```

## 6. コンポーネント図

```mermaid
graph TB
    subgraph "IBM i システム"
        subgraph "RPGB2プログラム"
            A[メイン処理ロジック]
            B[消費税率設定モジュール]
            C[日時取得モジュール]
            D[レコード更新モジュール]
        end
        
        subgraph "データベース層"
            E[(SYOHIN<br/>物理ファイル)]
            F[SYOHINR<br/>レコード形式]
        end
        
        subgraph "システムサービス"
            G[システム日付]
            H[システム時刻]
        end
    end
    
    A --> B
    A --> C
    A --> D
    B --> D
    C --> D
    C --> G
    C --> H
    D --> F
    F --> E
    
    style A fill:#87CEEB
    style E fill:#FFE4B5
```

---

## 注記

- **ER図**: SYOHINファイルとSYOHINRレコード形式の関係を示しています
- **フローチャート**: 元のRPGサイクル版とフリーフォーマット版の両方を含みます
- **シーケンス図**: プログラムとファイル、システムとの相互作用を時系列で表現
- **状態遷移図**: プログラムの各状態とその遷移を示します
- **データフロー図**: データの流れと変換処理を視覚化
- **コンポーネント図**: システムの構成要素と依存関係を表現
