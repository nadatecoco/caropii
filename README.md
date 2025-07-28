# 🍽️ caropii

## 📌 このアプリについて

**caropii**は、食事・睡眠・運動の総合的な健康管理とAIによる分析アドバイスを受けられるヘルスケアアプリです。

## 🌟 現在の主な機能

- ✅ **食事記録**: 食材選択による簡単な食事記録
- ✅ **PFC可視化**: タンパク質・脂質・炭水化物とカロリーの可視化
- ✅ **AI栄養分析**: Gemini APIによる栄養バランス分析とアドバイス
- ✅ **睡眠データ分析**: Apple Watch/ヘルスケア連携による睡眠質分析
- ✅ **統合健康分析**: 食事・睡眠データの統合分析（実装済み）
- ✅ **本番環境対応**: Render環境での安定動作

---

## 🧩 技術スタック

| 機能 | 使用技術 |
|------|---------|
| **iOSアプリ** | SwiftUI + HealthKit |
| **グラフ描画** | Swift Charts |
| **健康データ** | Apple Watch / ヘルスケア |
| **バックエンド** | Ruby on Rails 8.0.2 |
| **サービスクラス** | HealthAnalyzer（統合システム） |
| **データベース** | SQLite（開発）/ PostgreSQL（本番） |
| **AI分析** | Google Gemini API |
| **デプロイ** | Render |

---

## 🏗️ アーキテクチャ

### データフロー設計
```
ヘルスケアアプリ（永続保存）
    ↓
iOS caropii（表示のみ）
    ↓
Rails API（一時保存）
    ↓
HealthAnalyzer（統合分析）
    ↓
Gemini API（AI分析）
    ↓
結果返却 → データ自動削除
```

### コスト最適化戦略
- **詳細データ**: ヘルスケアが無料で永続保存
- **分析データ**: Rails一時コピー → 分析完了後自動削除
- **DB容量**: 固定（爆発的増加なし）

---

## 📱 実装済み機能詳細

### ✅ 食事管理システム
- **8種類の基本食材**: 栄養価データベース
- **PFC横棒グラフ**: リアルタイム可視化
- **今日の合計値**: カロリー・栄養素サマリー
- **記録削除**: タップで簡単削除

### ✅ AI分析システム（HealthAnalyzer）
```ruby
class HealthAnalyzer
  def analyze(type, data = nil)
    case type
    when "nutrition" then analyze_nutrition
    when "sleep" then analyze_sleep(data)
    end
  end
end
```

### ✅ 睡眠データ分析
- **Apple Watch連携**: HealthKit経由でデータ取得
- **睡眠質分析**: 睡眠時間・効率・段階の分析
- **改善アドバイス**: Gemini APIによる個別アドバイス

### ✅ 本番環境インフラ
- **自動デプロイ**: GitHubプッシュ → Render自動更新
- **自動マイグレーション**: Build Command統合
- **環境変数管理**: GEMINI_API_KEYなど

---

## 🗂️ データベース構造

### 食事データ
```sql
CREATE TABLE food_entries (
  food_name VARCHAR,
  protein DECIMAL,
  fat DECIMAL,
  carbs DECIMAL,
  calories DECIMAL,
  consumed_at DATETIME
);
```

### 睡眠データ（一時保存用）
```sql
CREATE TABLE sleep_records (
  start_time DATETIME,
  end_time DATETIME,
  sleep_value INTEGER,
  duration_hours DECIMAL
);
```

---

## 🚀 次期実装予定機能（5項目）

### 1. 💪 筋トレ記録機能（最優先）
**概要**:
- インターバル中の素早い記録
- 種目サジェスト機能
- 前回記録の自動入力

**技術方針**:
- 既存パターンの応用（シンプル）
- 外部依存なし
- 早期成功体験重視

### 2. 📸 読み取り最適化
**OCR栄養成分読み取り**:
- iOS標準Vision Framework使用
- 商品パッケージの栄養表示を自動読取
- コスト無料（外部API不使用）

**バーコードスキャン**:
- AVFoundation使用
- JANコード → 商品データベース連携

### 3. 🎤 食事記録完璧化
**音声入力対応**:
- 自然言語での食事記録
- 「鮭おにぎり2個食べました」→ 構造化データ変換
- 既存タップ選択との併用

### 4. 😴 睡眠データ分析強化
**HealthKit完全統合**:
- 長期データ取得（1年分など）
- より詳細な睡眠段階分析
- 食事・運動との相関分析

### 5. 🎨 最終UI改善
**デザイン統一**:
- 全画面の統一感向上
- ユーザビリティ改善
- 視覚的完成度向上

---

## 📋 基本食材リスト

1. **鶏胸肉**(100g) - 108kcal, P:22.3g, F:1.5g, C:0g
2. **白米**(150g) - 252kcal, P:3.8g, F:0.5g, C:55.7g
3. **卵**(1個) - 76kcal, P:6.2g, F:5.2g, C:0.2g
4. **アボカド**(1/2個) - 160kcal, P:2g, F:14.7g, C:6.2g
5. **バナナ**(1本) - 86kcal, P:1.1g, F:0.2g, C:22.5g
6. **サーモン**(100g) - 208kcal, P:22.1g, F:12.4g, C:0.1g
7. **ブロッコリー**(100g) - 25kcal, P:2.6g, F:0.4g, C:4.3g
8. **オートミール**(30g) - 114kcal, P:4.1g, F:2.0g, C:20.7g

---

## 🛠 開発環境セットアップ

### Rails バックエンド
```bash
cd backend
bundle install
bundle exec rails db:migrate
bundle exec rails server  # http://localhost:3000
```

### iOS アプリ
```bash
cd ios
open pfcz.xcodeproj  # Xcodeで開く
```

### 環境変数設定
```bash
# 開発環境
export GEMINI_API_KEY="your_api_key_here"

# 本番環境（Render）
# ダッシュボードのEnvironment Variablesで設定
```

---

## 📊 使い方

### 基本操作
1. **食事記録**: ホーム画面で食材タップ → 自動記録
2. **グラフ確認**: PFC摂取バランスをリアルタイム表示
3. **AI分析**: 「AI分析する」ボタン → Gemini分析結果表示
4. **記録削除**: 記録をタップして削除

### 睡眠データ分析
1. **データ取得**: Apple Watch着用で睡眠データ自動収集
2. **分析実行**: 「睡眠データ分析」ボタン
3. **結果確認**: 睡眠質と改善アドバイス表示

---

## 📚 プロジェクト文書

- [機能拡張計画会議_2025年7月28日](./議事録/機能拡張計画会議_2025年7月28日.md)
- [システム統合・睡眠分析実装記録](./議事録/システム統合・睡眠分析実装記録_2025年7月28日.md)
- [将来の拡張計画メモ](./議事録/将来の拡張計画メモ.md)
- [データ同期設計の検討記録](./議事録/データ同期設計の検討記録.md)

---

## 🎯 開発フェーズ

### ✅ フェーズ1: 基盤システム（完了）
- Rails API基盤構築
- iOS基本機能実装
- AI分析システム統合
- 本番環境デプロイ

### 🔄 フェーズ2: 機能拡張（進行中）
- 筋トレ記録機能 ← **現在ここ**
- OCR読み取り機能
- 音声入力対応

### 🔮 フェーズ3: 完成版（予定）
- 睡眠データ完全統合
- UI最終調整
- 総合ヘルスケアアプリ完成

---

**開発者**: natatekoko  
**技術サポート**: Claude Code  
**最終更新**: 2025年7月28日