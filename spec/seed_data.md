# シードデータ仕様：デモ用シナリオ「倉庫街の失踪事件」

## 0. このドキュメントの目的

デモ用シードデータの構成、実行方法、および手動で準備が必要な画像アセットについて定義する。

---

## 1. 概要

Gemini Hackathon のデモ用に、サービスの WOW ポイントを全て体験できるシナリオを1つシードデータとして登録する。Design Docs のミニセッション例「倉庫街の失踪事件」をベースに、以下を網羅する。

| WOW ポイント | デモでの体験 |
|-------------|------------|
| 自由入力（Do/Say） | 酒場やリオへのアプローチを自由に記述 |
| Choice（3〜6択） | リオへの切り出し方 / 倉庫への侵入方法を選択 |
| Roll（判定） | 交渉・隠密・観察などのスキルチェック |
| Clarify（確認質問） | 曖昧入力時に意図を絞り込み |
| Repair（修正） | 矛盾発生時の自動修復 |
| NPC 関係値 | リオ(affinity/trust)、見張り(fear/affinity)が変動 |
| アイテム | 探偵手帳・懐中電灯・現金の使用 |
| クエスト目標 | メイン+サブ目標の進捗表示 |
| Flame 盤面 | NPC立ち絵＋背景画像によるシーン演出 |
| 勝利/敗北条件 | 救出成功 vs HP0/SAN0/時間切れ |

---

## 2. シードデータの構成

### 2.1 投入対象テーブル

| テーブル | レコード数 | 内容 |
|---------|-----------|------|
| `scenarios` | 1 | デモシナリオ本体 |
| `scene_backgrounds` | 4 | 酒場、倉庫裏口、倉庫内部、路地裏 |

### 2.2 投入しないテーブル

以下はセッション開始時に `scenarios.initial_state` から動的に展開されるため、シードでは投入しない。

- `sessions`
- `player_characters`
- `npcs` / `npc_relationships`
- `turns`
- `items`
- `objectives`
- `context_summaries`

### 2.3 固定 UUID

冪等性確保のため固定UUIDを使用。

| エンティティ | UUID |
|-------------|------|
| シナリオ | `11111111-1111-1111-1111-111111111111` |
| 背景: 酒場 | `22222222-2222-2222-2222-222222222201` |
| 背景: 倉庫裏口 | `22222222-2222-2222-2222-222222222202` |
| 背景: 倉庫内部 | `22222222-2222-2222-2222-222222222203` |
| 背景: 路地裏 | `22222222-2222-2222-2222-222222222204` |

---

## 3. シナリオ設定

### 3.1 基本情報

- **タイトル**: 倉庫街の失踪事件
- **ジャンル**: 現代ミステリ風 TRPG
- **プレイ時間**: 5〜10分のデモ
- **公開**: `is_public = true`（全ユーザー閲覧可）
- **作成者**: `created_by = NULL`（システムシード）

### 3.2 PC（プレイヤーキャラクター）

| パラメータ | 値 |
|-----------|---|
| 名前 | 探索者 |
| HP / maxHP | 100 / 100 |
| SAN / maxSAN | 70 / 70 |
| STR / DEX / INT / CHA | 60 / 65 / 75 / 55 |
| 初期位置 | (5, 8) |
| 立ち絵 | `scenarios/{id}/pc.png` |

### 3.3 NPC

| NPC | mood | 初期位置 | isActive | affinity | trust | fear | 特記 |
|-----|------|---------|----------|----------|-------|------|------|
| 情報屋リオ | cautious | (3, 4) | true | -10 | 15 | 0 | 金と信頼を重視 |
| 見張りの男 | alert | (12, 3) | true | -30 | 0 | 0 | armed フラグ |
| 佐藤健一 | terrified | (14, 6) | **false** | 50 | 30 | 10 | restrained, weakened |

- 佐藤健一は `isActive: false`（失踪者。発見イベントまで盤面非表示）

### 3.4 初期アイテム

| アイテム | type | quantity | isEquipped | 画像 |
|---------|------|----------|-----------|------|
| 探偵手帳 | key_item | 1 | false | あり |
| 懐中電灯 | tool | 1 | true | あり |
| 現金 | currency | 3 | false | なし |

### 3.5 初期クエスト目標

| 目標 | status | sortOrder |
|------|--------|-----------|
| 失踪者の行方を突き止めろ | active | 0 |
| 情報屋リオから情報を得ろ | active | 1 |

### 3.6 勝利条件

| ID | 説明 | 必要フラグ |
|----|------|-----------|
| `find_victim` | 失踪者の居場所を特定する | `found_warehouse_secret`, `identified_victim_location` |
| `rescue_victim` | 失踪者を救出する | 上記 + `rescued_victim` |

### 3.7 敗北条件

| ID | 説明 | 条件 |
|----|------|------|
| `hp_zero` | HPが0になった | `pc.stats.hp <= 0` |
| `san_zero` | SAN値が0になった | `pc.stats.san <= 0` |
| `time_up` | 時間切れ | `session.currentTurnNumber >= 30` |

### 3.8 オープニングナレーション

> 雨の倉庫街。じめじめとした空気が肌にまとわりつく。
> 失踪者——佐藤健一の最後の目撃地点はこの界隈だ。
> 薄暗い路地の先に、かすかな灯りを漏らす酒場が見える。情報屋リオがいるはずの店だ。
> 時計を見る。午後11時。あまり悠長にしている暇はない。

### 3.9 背景画像（scene_backgrounds）

| ロケーション | 説明 |
|-------------|------|
| 酒場 | 薄暗い照明に煙草の煙が漂う、倉庫街の裏通りにある小さな酒場 |
| 倉庫裏口 | 錆びたシャッターと積み上げられたドラム缶。監視カメラの赤いランプが点滅 |
| 倉庫内部 | 埃っぽい広い空間に木箱が並ぶ。奥の小部屋から微かなうめき声 |
| 路地裏 | 雨に濡れた狭い路地。壁にスプレーアート、割れた街灯が不規則に明滅 |

---

## 4. 画像アセットの準備（手動）

シードデータのDB投入は自動で行われるが、**画像ファイルは手動でSupabase Storageにアップロードする必要がある**。

### 4.1 ストレージバケット

- **バケット名**: `scenario-assets`
- **公開設定**: Public（`getPublicUrl` でアクセス可能）
- **ファイルサイズ上限**: 10MiB
- **対応形式**: PNG, JPEG, WebP

### 4.2 必要な画像ファイル一覧

以下の画像を用意し、Supabase Storage にアップロードする。

#### シナリオサムネイル

| パス | 推奨サイズ | 用途 |
|------|-----------|------|
| `scenarios/11111111-1111-1111-1111-111111111111/thumbnail.png` | 400×300 | シナリオ一覧のサムネイル |

#### 立ち絵（PC/NPC）

| パス | 推奨サイズ | 用途 |
|------|-----------|------|
| `scenarios/11111111-1111-1111-1111-111111111111/pc.png` | 512×1024, 透過 | PC立ち絵 |
| `scenarios/11111111-1111-1111-1111-111111111111/npcs/rio.png` | 512×1024, 透過 | 情報屋リオ立ち絵 |
| `scenarios/11111111-1111-1111-1111-111111111111/npcs/guard.png` | 512×1024, 透過 | 見張りの男 立ち絵 |
| `scenarios/11111111-1111-1111-1111-111111111111/npcs/sato.png` | 512×1024, 透過 | 佐藤健一（失踪者）立ち絵 |

#### 背景画像

| パス | 推奨サイズ | 用途 |
|------|-----------|------|
| `scenarios/11111111-1111-1111-1111-111111111111/backgrounds/bar.png` | 1920×1080 | 酒場 |
| `scenarios/11111111-1111-1111-1111-111111111111/backgrounds/warehouse_back.png` | 1920×1080 | 倉庫裏口 |
| `scenarios/11111111-1111-1111-1111-111111111111/backgrounds/warehouse_inside.png` | 1920×1080 | 倉庫内部 |
| `scenarios/11111111-1111-1111-1111-111111111111/backgrounds/alley.png` | 1920×1080 | 路地裏 |

#### アイテム画像

| パス | 推奨サイズ | 用途 |
|------|-----------|------|
| `scenarios/11111111-1111-1111-1111-111111111111/items/notebook.png` | 128×128 | 探偵手帳 |
| `scenarios/11111111-1111-1111-1111-111111111111/items/flashlight.png` | 128×128 | 懐中電灯 |

> **注**: 「現金」アイテムは `imagePath: null` のため画像不要。

### 4.3 アップロード手順

1. ローカルSupabaseを起動

   ```bash
   make run
   ```

2. Supabase Studio にアクセス

   ```
   http://localhost:54323
   ```

3. Storage → `scenario-assets` を開く

4. 以下のディレクトリ構造に従って画像をアップロード

   ```
   scenario-assets/
   └── scenarios/
       └── 11111111-1111-1111-1111-111111111111/
           ├── thumbnail.png
           ├── pc.png
           ├── npcs/
           │   ├── rio.png
           │   ├── guard.png
           │   └── sato.png
           ├── items/
           │   ├── notebook.png
           │   └── flashlight.png
           └── backgrounds/
               ├── bar.png
               ├── warehouse_back.png
               ├── warehouse_inside.png
               └── alley.png
   ```

### 4.4 画像がない場合の動作

画像は**任意（nullable）**。アップロードしなくてもシードデータの投入やセッション開始は可能。

- `image_path` が指定されているが画像が存在しない → フロントエンドでプレースホルダーを表示
- `image_path` が `null` → 画像なしとして扱う

デモ時は画像を用意することを推奨するが、開発中は画像なしでも機能の動作確認は可能。

### 4.5 画像の生成方法（参考）

デモ用の画像は以下の方法で準備できる：

- **AI画像生成**: Midjourney, DALL-E, Stable Diffusion 等で生成
- **フリー素材**: いらすとや、Unsplash 等の背景素材
- **手動作成**: Figma, Canva 等でプレースホルダーを作成

立ち絵は**透過PNG/WebP**が必須（Flame盤面上で背景と合成するため）。

---

## 5. シードの実行方法

### 5.1 実行ファイル

- **ファイル**: `supabase/seed.sql`
- **設定**: `supabase/config.toml` の `[db.seed]` で登録済み

```toml
[db.seed]
enabled = true
sql_paths = ["./seed.sql"]
```

### 5.2 実行コマンド

```bash
# シードデータを既存DBに追加投入（DBリセットなし、安全）
make seed
```

- `ON CONFLICT DO NOTHING` により、既存データがあってもエラーにならない
- 何度実行しても安全（冪等）
- 既存のセッションデータ等は保持される

> **注**: `make db-reset` はDBを完全にリセットする別コマンド。リセット時は `supabase/config.toml` の `[db.seed]` 設定により `seed.sql` も自動実行される。

### 5.3 冪等性

- すべての INSERT に `ON CONFLICT (id) DO NOTHING` を使用
- 固定UUIDにより、何度実行しても同じ結果になる
- 既にデータが存在する場合はスキップされる

### 5.4 検証方法

1. シード実行後、Drizzle Studio で確認

   ```bash
   make drizzle-studio
   ```

2. 確認項目
   - `scenarios` テーブルに1レコード（UUID: `11111111-...`）
   - `scene_backgrounds` テーブルに4レコード（UUID: `22222222-...-01` 〜 `04`）
   - `initial_state` JSONB に PC, NPC×3, objectives×2, items×3, context, openingNarration が含まれる
   - 全画像パスが `scenarios/11111111-1111-1111-1111-111111111111/` 配下を指している

---

## 6. フロントエンドでの画像URL変換

DBには**パスのみ**保存されている。フロントエンドで表示する際に Supabase Storage の Public URL に変換する。

```dart
final supabase = Supabase.instance.client;

// パスからURLに変換
final imageUrl = supabase.storage
    .from('scenario-assets')
    .getPublicUrl(imagePath);
```

例:
- パス: `scenarios/11111111-1111-1111-1111-111111111111/npcs/rio.png`
- URL: `http://localhost:54321/storage/v1/object/public/scenario-assets/scenarios/11111111-1111-1111-1111-111111111111/npcs/rio.png`

---

## 7. シナリオ追加時のガイドライン

将来シナリオを追加する場合は以下に従う。

### 7.1 seed.sql への追加

1. 新しい固定UUIDを採番
2. `scenarios` に INSERT 文を追加
3. 必要な `scene_backgrounds` に INSERT 文を追加
4. すべて `ON CONFLICT (id) DO NOTHING` を付与

### 7.2 initial_state の構造

```jsonc
{
  "pc": { /* PCデータ */ },
  "npcs": [ /* NPC配列 */ ],
  "objectives": [ /* 初期目標配列 */ ],
  "items": [ /* 初期アイテム配列 */ ],
  "context": {
    "plotEssentials": { /* AI GMの常時コンテキスト */ },
    "shortTermSummary": "",
    "confirmedFacts": []
  },
  "openingNarration": "..."
}
```

### 7.3 画像パスの命名規則

```
scenarios/{SCENARIO_UUID}/thumbnail.png
scenarios/{SCENARIO_UUID}/pc.png
scenarios/{SCENARIO_UUID}/npcs/{npc_name}.png
scenarios/{SCENARIO_UUID}/items/{item_name}.png
scenarios/{SCENARIO_UUID}/backgrounds/{location_name}.png
```

- `{npc_name}` / `{item_name}` / `{location_name}` は英数字スネークケース
- 拡張子は `.png` 推奨（PNG/JPEGも可）
