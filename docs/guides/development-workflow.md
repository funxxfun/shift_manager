# 開発ワークフロー

Plan Stackに基づく開発フローのガイド。

## 基本原則

1. **Research → Plan → Implement** — 計画フェーズを飛ばさない
2. **planはアーティファクト** — 実装と同等の成果物として扱う
3. **planは蓄積する** — 削除せず、知識を積み重ねる
4. **planはセーブポイント** — `/clear`しても復帰できる

## ワークフロー

### Step 1: Research（調査）

実装前に、過去の類似実装を検索する。

```
docs/plans/ を検索して、[機能名] に関連する過去の実装を探してください。
```

確認すべきこと:
- 類似の過去plan
- 影響を受けるファイル
- 既存のアーキテクチャパターン

### Step 2: Plan（計画）

Claude CodeでPlan Modeに入る（Shift+Tab を2回）。

**計画ファイルの作成:**

```
docs/plans/YYYYMMDD_機能名.md
```

**命名規則:**
- 日付プレフィックス（YYYYMMDD）で時系列ソート可能に
- snake_caseで機能名
- 簡潔だが具体的に（2-4語）

**良い例:**
- `20260115_user_authentication.md`
- `20260120_csv_export.md`
- `20260201_ai_suggestion_improvement.md`

**避けるべき例:**
- `20260115_fix.md` — 曖昧すぎる
- `20260115_add_user_auth_with_oauth_and_jwt.md` — 長すぎる

**計画に含める内容:**
- タスク概要
- 調査結果（関連する過去plan、影響ファイル）
- 実装方針
- 修正ファイル一覧

テンプレート: [docs/templates/plan-template.md](../templates/plan-template.md)

**人間の承認を待つ** — 承認前にコードを書かない。

### Step 3: Implement（実装）

Plan Modeを終了し、承認された計画に従って実装。

### Step 4: Review（レビュー）

AIが計画と実装を比較:
- 計画通りに完了したこと
- 変更点（ドリフト）とその理由
- 今後のplanへの学び

テンプレート: [docs/templates/review-template.md](../templates/review-template.md)

**アーカイブ:**

```bash
mv docs/plans/20260115_feature.md docs/plans/completed/
```

## コンテキストの復元

`/clear` した後、またはセッション開始時:

```
docs/plans/current/ にあるplanを読んで、続きから実装してください。
```

planがセーブポイントとして機能する。

## 計画の昇格

ほとんどのplanは `completed/` に留まる。昇格は必要な場合のみ。

| 昇格先 | 基準 |
|-------|------|
| `architecture/` | 3つ以上の機能に影響、またはシステム境界を定義 |
| `features/` | 複数の将来のplanから参照される |

過度に整理しない。昇格はオプション。

## Tips

### 効率的なplan作成

- 過去のplanを参照することで、ゼロから書く手間を省く
- 類似機能のplanをテンプレートとして使う

### レビューの活用

- ドリフト（計画からの逸脱）は悪いことではない
- ドリフトの理由を記録することで、将来のplan精度が上がる

### オンボーディング

新メンバーは、planを書くことで学ぶ:
1. 担当領域をClaudeで調査（docs/が既存コンテキストを提供）
2. 小さな修正でもplanを書く
3. シニアが意図をレビュー（コードの前に）
4. 承認後に実装

質問が文書化された回答になる。各planが将来のメンバーの参考になる。
