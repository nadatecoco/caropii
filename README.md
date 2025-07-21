# 🍽️ PFCZ（仮）

## 📌 このアプリについて

本アプリは、日々の**食事記録**を効率的に行い、その情報を活用して**AIからの助言**を受けられる健康管理サポートアプリです。  
具体的には、ユーザーが登録した食材や食事の内容を元に、ChatGPTと連携し、「摂取バランスはどうか」「追加で何を食べるべきか」「今の食生活に偏りはあるか」といったアドバイスをもらえる設計を目指しています。  
現時点では食事記録とアドバイスの連携を主な機能とし、今後は睡眠などの他の健康データも統合していく予定です。

---

## ✍️ 作った背景

人間は日々、筋トレ・食事・睡眠など、健康に関わるデータを記録していることも多いですが、それらは「記録するだけ」で終わってしまい、十分に活用されていないことが多いと感じていました。  
せっかく手間をかけて記録しているのであれば、**AIにそのデータを活かしてもらい、日々の生活の質向上につなげることができるのではないか**と考えました。

実際、ChatGPTのようなAIを活用すれば、「昨日の睡眠に応じたトレーニング強度」や「最近の食生活から見た栄養バランス」など、体調に応じたアドバイスを受け取ることが可能です。  
ただし、そのたびに毎回データを入力し直すのは**非常に面倒**です。これが、AIの活用を日常に取り入れるうえでの大きな障壁になっていると感じました。

そこで注目したのが、**過去の情報をもとに生成結果を補強できる「RAG」**という技術です。  
この仕組みを取り入れれば、**一度記録しておいたデータをAIが自動的に参照してくれるため、毎回情報を渡す手間が省け、より自然な形でアドバイスを受け取ることが可能になります。**

このアプリでは、まずは「日々の食事記録」と「AIによる助言の自動化」を軸に、そうした体験を実現する第一歩として開発を進めています。

---

## 🧩 使用技術

| 目的           | 使用技術                  |
|----------------|---------------------------|
| フロントエンド | SwiftUI（iOS）            |
| グラフ描画     | Swift Charts              |
| バックエンド   | Ruby on Rails（予定）     |
| DB管理         | PostgreSQL + pgvector（予定） |
| AI連携         | OpenAI API（予定）        |

---

## 🔮 将来的な機能構想

- ✅ 音声入力で食材追加  
- ✅ カレンダーで日付ごとの記録表示  
- ✅ 栄養バランスに基づいたGPTの助言  
- ✅ 食事傾向の分析とグラフ化  
- ✅ Apple Watchなどとの連携（睡眠・活動データ）  
- ✅ 継続日数の表示やリマインダー通知    
- ✅ オフライン保存やスマホ内データ処理の最適化
---
## 📱 画面遷移図（テキスト形式）
[ホーム画面]
├─▶ [保存画面]
│       ├─▶ 入力内容をLLMに送信（音声・テキスト）
│       ├─▶ 推定された食材の確認（チェック方式）
│       ├─▶ チェックOK：記録 → DB保存前確認 → 保存
│       └─▶ チェックNG：ユーザーが手動で成分入力 → DB保存前確認 → 保存
└─▶ [食材データベース画面]
├─▶ 保存された食材一覧
└─▶ 栄養情報を詳細表示（栄養成分は詳細ボタンで展開）

## 🏗️ アーキテクチャ構成（予定）

```text
iOSアプリ（SwiftUI）
        ↓
バックエンドAPI（Rails）
        ↓
PostgreSQL + pgvector
        ↓
OpenAI GPT-4 API（RAG構成）
        ↓
iOSアプリにレスポンス
---

## 📁 実装済み機能一覧

- FlowLayout によるチップ複数行表示（3〜4行まで）  
- ScrollViewで縦スクロール対応  
- Chartに `.easeInOut` アニメーション追加  
- `chartXScale(domain:)` によるグラフバーの左寄せ修正  

---

## 🗒️ 補足

- READMEは他の個人開発者のリポジトリも参考にしつつ改善中  
- GPTの活用方針は今後も検討・調整予定  

---
 テーブル設計

  users

  | Column             | Type   | Options                   |
  |--------------------|--------|---------------------------|
  | uuid               | uuid   | unique: true, null: false |
  | app_user_id        | string | unique: true              |
  | name               | string | null: false               |
  | email              | string | null: false, unique: true |
  | encrypted_password | string | null: false               |
  | last_name          | string | null: false               |
  | first_name         | string | null: false               |
  | kana_last_name     | string | null: false               |
  | kana_first_name    | string | null: false               |
  | birthday           | date   | null: false               |

  Association: has_many :analysis_sessions

  ---
  analysis_sessions

  | Column          | Type       | Options                              |
  |-----------------|------------|--------------------------------------|
  | uuid            | uuid       | unique: true, null: false            |
  | user            | references | null: false, foreign_key: true       |
  | session_type    | string     | null: false (e.g. 'daily', 'weekly') |
  | start_date      | date       | null: false                          |
  | end_date        | date       | null: false                          |
  | status          | string     | default: 'pending'                   |
  | expires_at      | datetime   | null: false                          |
  | analysis_result | json       |                                      |

  Association:
  - belongs_to :user
  - has_many :food_entries, dependent: :destroy
  - has_many :sleep_records, dependent: :destroy
  - has_many :exercise_records, dependent: :destroy
  - has_many :health_metrics, dependent: :destroy

  ---
  food_entries

  | Column           | Type       | Options                              |
  |------------------|------------|--------------------------------------|
  | uuid             | uuid       | unique: true, null: false            |
  | analysis_session | references | null: false, foreign_key: true       |
  | food_name        | string     | null: false                          |
  | protein          | decimal    | precision: 6, scale: 2, null: false  |
  | fat              | decimal    | precision: 6, scale: 2, null: false  |
  | carbs            | decimal    | precision: 6, scale: 2, null: false  |
  | calories         | decimal    | precision: 7, scale: 2, null: false  |
  | quantity         | decimal    | precision: 5, scale: 2, default: 1.0 |
  | consumed_at      | datetime   | null: false                          |
  | meal_type        | string     | (e.g. 'breakfast', 'lunch', etc.)    |

  Association: belongs_to :analysis_session

  ---
  sleep_records

  | Column           | Type       | Options                        |
  |------------------|------------|--------------------------------|
  | uuid             | uuid       | unique: true, null: false      |
  | analysis_session | references | null: false, foreign_key: true |
  | sleep_start      | datetime   | null: false                    |
  | sleep_end        | datetime   | null: false                    |
  | duration_minutes | integer    | null: false                    |
  | quality_score    | integer    | (1〜10スケール)                     |
  | sleep_stages     | json       | (deep/light/REMなどの構造化データ)      |
  | recorded_date    | date       | null: false                    |

  Association: belongs_to :analysis_session

  ---
  exercise_records

  | Column           | Type       | Options                        |
  |------------------|------------|--------------------------------|
  | uuid             | uuid       | unique: true, null: false      |
  | analysis_session | references | null: false, foreign_key: true |
  | exercise_type    | string     | null: false                    |
  | duration_minutes | integer    | null: false                    |
  | intensity        | string     |                                |
  | calories_burned  | decimal    | precision: 6, scale: 2         |
  | distance_km      | decimal    | precision: 6, scale: 2         |
  | exercise_data    | json       | （心拍数やペースなど）                    |
  | started_at       | datetime   | null: false                    |
  | ended_at         | datetime   | null: false                    |

  Association: belongs_to :analysis_session

  ---
  health_metrics

  | Column           | Type       | Options                             |
  |------------------|------------|-------------------------------------|
  | uuid             | uuid       | unique: true, null: false           |
  | analysis_session | references | null: false, foreign_key: true      |
  | metric_type      | string     | null: false （例: 'weight'）           |
  | value            | decimal    | precision: 8, scale: 2, null: false |
  | unit             | string     | null: false （例: 'kg', '%'）          |
  | measured_at      | datetime   | null: false                         |
  | notes            | text       |                                     |

  Association: belongs_to :analysis_session

