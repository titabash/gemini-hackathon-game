-- =============================================================================
-- Demo Scenario Seed Data: 倉庫街の失踪事件
-- =============================================================================
-- Fixed UUIDs for idempotent execution.
-- This file is executed automatically by `supabase db reset` via config.toml.
-- =============================================================================

-- Fixed UUIDs
-- Scenario: 11111111-1111-1111-1111-111111111111
-- Scene Backgrounds:
--   Bar:              22222222-2222-2222-2222-222222222201
--   Warehouse Back:   22222222-2222-2222-2222-222222222202
--   Warehouse Inside: 22222222-2222-2222-2222-222222222203
--   Alley:            22222222-2222-2222-2222-222222222204
-- NPCs:
--   情報屋リオ:       33333333-3333-3333-3333-333333333301
--   見張りの男:       33333333-3333-3333-3333-333333333302
--   佐藤健一:         33333333-3333-3333-3333-333333333303

-- ===== Scenario =====
INSERT INTO scenarios (
  id,
  title,
  description,
  initial_state,
  win_conditions,
  fail_conditions,
  max_turns,
  thumbnail_path,
  created_by,
  is_public
) VALUES (
  '11111111-1111-1111-1111-111111111111',
  '倉庫街の失踪事件',
  '雨の倉庫街で失踪した男を追う、現代ミステリ風TRPGシナリオ。情報屋との交渉、倉庫への潜入、そして失踪者の救出——すべての判断があなたの手に委ねられる。',
  '{
    "pc": {
      "name": "探索者",
      "stats": {
        "hp": 100,
        "maxHp": 100,
        "san": 70,
        "maxSan": 70,
        "str": 60,
        "dex": 65,
        "int": 75,
        "cha": 55
      },
      "statusEffects": [],
      "location": { "x": 5, "y": 8 },
      "imagePath": "scenarios/11111111-1111-1111-1111-111111111111/pc.png"
    },
    "npcs": [
      {
        "name": "情報屋リオ",
        "profile": {
          "speechStyle": "ぶっきらぼうだが根は悪くない。敬語は使わない",
          "values": "金と信頼を重視。嘘を嫌う",
          "taboo": "過去の失敗について触れられること"
        },
        "goals": {
          "shortTerm": "探索者から報酬を得る",
          "midTerm": "倉庫街の利権を守る",
          "longTerm": "裏社会から足を洗う"
        },
        "state": { "hp": 80, "mood": "cautious", "flags": [] },
        "location": { "x": 3, "y": 4 },
        "isActive": true,
        "imagePath": "scenarios/11111111-1111-1111-1111-111111111111/npcs/rio.png",
        "relationship": {
          "affinity": -10,
          "trust": 15,
          "fear": 0,
          "debt": 0,
          "flags": {}
        }
      },
      {
        "name": "見張りの男",
        "profile": {
          "speechStyle": "無口。必要最低限しか話さない",
          "values": "命令に忠実。仲間を裏切らない",
          "taboo": "組織の情報を漏らすこと"
        },
        "goals": {
          "shortTerm": "倉庫の入口を守る",
          "midTerm": "ボスからの評価を上げる",
          "longTerm": "組織内で昇格する"
        },
        "state": { "hp": 90, "mood": "alert", "flags": ["armed"] },
        "location": { "x": 12, "y": 3 },
        "isActive": true,
        "imagePath": "scenarios/11111111-1111-1111-1111-111111111111/npcs/guard.png",
        "relationship": {
          "affinity": -30,
          "trust": 0,
          "fear": 0,
          "debt": 0,
          "flags": {}
        }
      },
      {
        "name": "佐藤健一",
        "profile": {
          "speechStyle": "丁寧で穏やか。恐怖で声が震えている",
          "values": "家族を大切にする一般人。正直者",
          "taboo": "なし（一般人のため特別な禁則はない）"
        },
        "goals": {
          "shortTerm": "この場所から逃げ出したい",
          "midTerm": "家族のもとに帰る",
          "longTerm": "平穏な日常に戻る"
        },
        "state": { "hp": 40, "mood": "terrified", "flags": ["restrained", "weakened"] },
        "location": { "x": 14, "y": 6 },
        "isActive": false,
        "imagePath": "scenarios/11111111-1111-1111-1111-111111111111/npcs/sato.png",
        "relationship": {
          "affinity": 50,
          "trust": 30,
          "fear": 10,
          "debt": 0,
          "flags": {}
        }
      }
    ],
    "objectives": [
      {
        "title": "失踪者の行方を突き止めろ",
        "description": "倉庫街で最後に目撃された失踪者の手がかりを追え",
        "status": "active",
        "sortOrder": 0
      },
      {
        "title": "情報屋リオから情報を得ろ",
        "description": "酒場にいる情報屋リオに接触し、失踪者に関する情報を引き出せ",
        "status": "active",
        "sortOrder": 1
      }
    ],
    "items": [
      {
        "name": "探偵手帳",
        "description": "これまでの調査メモが書かれた手帳",
        "type": "key_item",
        "quantity": 1,
        "isEquipped": false,
        "imagePath": "scenarios/11111111-1111-1111-1111-111111111111/items/notebook.png"
      },
      {
        "name": "懐中電灯",
        "description": "暗所の探索に使える小型の懐中電灯",
        "type": "tool",
        "quantity": 1,
        "isEquipped": true,
        "imagePath": "scenarios/11111111-1111-1111-1111-111111111111/items/flashlight.png"
      },
      {
        "name": "現金",
        "description": "情報料や買い物に使える現金。あまり多くはない",
        "type": "currency",
        "quantity": 3,
        "isEquipped": false,
        "imagePath": null
      }
    ],
    "context": {
      "plotEssentials": {
        "mainObjective": "倉庫街で失踪した人物の行方を調査する",
        "currentCrisis": "失踪から48時間。証拠が消される前に真相にたどり着く必要がある",
        "importantNpcs": ["情報屋リオ", "見張りの男", "佐藤健一（失踪者・未発見）"],
        "unresolvedMysteries": ["失踪者は自発的に消えたのか、連れ去られたのか", "倉庫に何が保管されているのか"]
      },
      "shortTermSummary": "",
      "confirmedFacts": []
    },
    "openingNarration": "雨の倉庫街。じめじめとした空気が肌にまとわりつく。\n失踪者——佐藤健一の最後の目撃地点はこの界隈だ。\n薄暗い路地の先に、かすかな灯りを漏らす酒場が見える。情報屋リオがいるはずの店だ。\n時計を見る。午後11時。あまり悠長にしている暇はない。"
  }'::jsonb,
  '[
    {
      "id": "find_victim",
      "description": "失踪者の居場所を特定する",
      "requiredFlags": ["found_warehouse_secret", "identified_victim_location"]
    },
    {
      "id": "rescue_victim",
      "description": "失踪者を救出する",
      "requiredFlags": ["found_warehouse_secret", "identified_victim_location", "rescued_victim"]
    }
  ]'::jsonb,
  '[
    {
      "id": "hp_zero",
      "description": "HPが0になった",
      "condition": "pc.stats.hp <= 0"
    },
    {
      "id": "san_zero",
      "description": "SAN値が0になった",
      "condition": "pc.stats.san <= 0"
    },
    {
      "id": "time_up",
      "description": "時間切れ（ターン制限超過）",
      "condition": "session.currentTurnNumber >= 30"
    }
  ]'::jsonb,
  30,
  'scenarios/11111111-1111-1111-1111-111111111111/thumbnail.png',
  NULL,
  true
)
ON CONFLICT (id) DO NOTHING;

-- ===== Scene Backgrounds =====

-- 1. 酒場
INSERT INTO scene_backgrounds (
  id,
  scenario_id,
  session_id,
  location_name,
  image_path,
  description
) VALUES (
  '22222222-2222-2222-2222-222222222201',
  '11111111-1111-1111-1111-111111111111',
  NULL,
  '酒場',
  'scenarios/11111111-1111-1111-1111-111111111111/backgrounds/bar.png',
  '薄暗い照明に煙草の煙が漂う、倉庫街の裏通りにある小さな酒場。カウンターの隅に情報屋リオの姿がある。'
)
ON CONFLICT (id) DO NOTHING;

-- 2. 倉庫裏口
INSERT INTO scene_backgrounds (
  id,
  scenario_id,
  session_id,
  location_name,
  image_path,
  description
) VALUES (
  '22222222-2222-2222-2222-222222222202',
  '11111111-1111-1111-1111-111111111111',
  NULL,
  '倉庫裏口',
  'scenarios/11111111-1111-1111-1111-111111111111/backgrounds/warehouse_back.png',
  '錆びたシャッターと積み上げられたドラム缶。監視カメラの赤いランプが点滅している。見張りの男が立っている。'
)
ON CONFLICT (id) DO NOTHING;

-- 3. 倉庫内部
INSERT INTO scene_backgrounds (
  id,
  scenario_id,
  session_id,
  location_name,
  image_path,
  description
) VALUES (
  '22222222-2222-2222-2222-222222222203',
  '11111111-1111-1111-1111-111111111111',
  NULL,
  '倉庫内部',
  'scenarios/11111111-1111-1111-1111-111111111111/backgrounds/warehouse_inside.png',
  '埃っぽい広い空間に木箱が並ぶ。奥の小部屋から微かなうめき声が聞こえる。失踪者が拘束されている。'
)
ON CONFLICT (id) DO NOTHING;

-- 4. 路地裏
INSERT INTO scene_backgrounds (
  id,
  scenario_id,
  session_id,
  location_name,
  image_path,
  description
) VALUES (
  '22222222-2222-2222-2222-222222222204',
  '11111111-1111-1111-1111-111111111111',
  NULL,
  '路地裏',
  'scenarios/11111111-1111-1111-1111-111111111111/backgrounds/alley.png',
  '雨に濡れた狭い路地。壁にはスプレーアートが描かれ、割れた街灯が不規則に明滅している。'
)
ON CONFLICT (id) DO NOTHING;

-- ===== NPCs (Scenario Templates) =====

-- 1. 情報屋リオ
INSERT INTO npcs (
  id,
  scenario_id,
  session_id,
  name,
  image_path,
  profile,
  goals,
  state,
  location_x,
  location_y
) VALUES (
  '33333333-3333-3333-3333-333333333301',
  '11111111-1111-1111-1111-111111111111',
  NULL,
  '情報屋リオ',
  'scenarios/11111111-1111-1111-1111-111111111111/npcs/rio.png',
  '{"speechStyle": "ぶっきらぼうだが根は悪くない。敬語は使わない", "values": "金と信頼を重視。嘘を嫌う", "taboo": "過去の失敗について触れられること"}'::jsonb,
  '{"shortTerm": "探索者から報酬を得る", "midTerm": "倉庫街の利権を守る", "longTerm": "裏社会から足を洗う"}'::jsonb,
  '{"hp": 80, "mood": "cautious", "flags": []}'::jsonb,
  3, 4
)
ON CONFLICT (id) DO NOTHING;

-- 2. 見張りの男
INSERT INTO npcs (
  id,
  scenario_id,
  session_id,
  name,
  image_path,
  profile,
  goals,
  state,
  location_x,
  location_y
) VALUES (
  '33333333-3333-3333-3333-333333333302',
  '11111111-1111-1111-1111-111111111111',
  NULL,
  '見張りの男',
  'scenarios/11111111-1111-1111-1111-111111111111/npcs/guard.png',
  '{"speechStyle": "無口。必要最低限しか話さない", "values": "命令に忠実。仲間を裏切らない", "taboo": "組織の情報を漏らすこと"}'::jsonb,
  '{"shortTerm": "倉庫の入口を守る", "midTerm": "ボスからの評価を上げる", "longTerm": "組織内で昇格する"}'::jsonb,
  '{"hp": 90, "mood": "alert", "flags": ["armed"]}'::jsonb,
  12, 3
)
ON CONFLICT (id) DO NOTHING;

-- 3. 佐藤健一（失踪者）
INSERT INTO npcs (
  id,
  scenario_id,
  session_id,
  name,
  image_path,
  profile,
  goals,
  state,
  location_x,
  location_y
) VALUES (
  '33333333-3333-3333-3333-333333333303',
  '11111111-1111-1111-1111-111111111111',
  NULL,
  '佐藤健一',
  'scenarios/11111111-1111-1111-1111-111111111111/npcs/sato.png',
  '{"speechStyle": "丁寧で穏やか。恐怖で声が震えている", "values": "家族を大切にする一般人。正直者", "taboo": "なし（一般人のため特別な禁則はない）"}'::jsonb,
  '{"shortTerm": "この場所から逃げ出したい", "midTerm": "家族のもとに帰る", "longTerm": "平穏な日常に戻る"}'::jsonb,
  '{"hp": 40, "mood": "terrified", "flags": ["restrained", "weakened"]}'::jsonb,
  14, 6
)
ON CONFLICT (id) DO NOTHING;
