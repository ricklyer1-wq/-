# 《覓仙劫》目前開發內容總覽

本文件整理《覓仙劫》目前已開發的內容，供交接、回顧與後續開發使用。它是現況總覽，不取代既有開發路線、效果支援清單或測試清單。

## 專案定位與核心玩法

《覓仙劫》是 Godot 4.6 製作的直式手機卡牌 Roguelike 專案。核心採用「殺戮尖塔式」回合制卡牌戰鬥骨架，題材與策略特色則朝修仙方向延伸。

目前核心方向：

- 回合制卡牌戰鬥。
- 每回合抽牌、獲得靈力、施展法訣、收功。
- 敵人顯示意圖，玩家根據意圖決定攻擊、防禦、解狀態或準備 combo。
- 卡牌、狀態、敵人、章節、事件、商店與獎勵盡量資料驅動。
- 特色系統方向是「五行流派 + 禁術代價 + 法寶組合」。

目前專案入口與基礎設定：

- Godot 專案設定檔：`project.godot`
- 主場景：`res://scenes/title/TitleScene.tscn`
- 顯示方向：直式手機解析度，viewport 為 1080 x 1920。
- Autoload：`GameData`、`EffectRegistry`、`RunManager`、`DebugProfile`。

## 目前可玩流程

目前已具備第一章 demo 流程雛形，可以從標題進入地圖，依節點進入戰鬥、事件、商店、獎勵與章節結局。

主要流程：

1. 進入 `TitleScene`。
2. 建立或使用 debug run。
3. 進入 `MapScene`，顯示第一章節點。
4. 點擊可用節點進入對應場景。
5. 戰鬥勝利後進入卡牌獎勵。
6. 事件節點套用選項結果。
7. 商店節點可買牌、療傷、移除卡牌與切換卡牌包。
8. Boss 或章節終點後進入章節結局選擇。
9. 結局選項可解鎖修士、卡牌包或更新 debug profile。

第一章目前資料：

- 章節 ID：`chapter_01`
- 章節名稱：`第一章：靈霧染血`
- 節點數：13
- 起始節點：`node_001`
- 節點類型包含：普通戰鬥、事件、商店、精英/劇情精英、休息 placeholder、Boss。

## 已完成系統總覽

目前已完成或已有可用雛形的系統：

- 專案基礎：Godot 專案、直式手機解析度、主場景、autoload 設定。
- 資料載入：集中由 `GameData` 載入卡牌、敵人、狀態、陣營、元素與掉落池。
- 戰鬥核心：抽牌、手牌、棄牌堆、消耗區、靈力、護盾、血量、敵人意圖、敵人回合。
- 卡牌操作：卡牌可點選、可觸控拖曳、可丟到敵人目標。
- 效果解析：`BattleEffectResolver` 已拆出，負責解析大部分資料驅動卡牌效果。
- 地圖流程：`RunManager` 與 `RunState` 管理目前章節、節點、完成節點與場景流轉。
- 戰後獎勵：`CardRewardScene` 與 `RewardManager` 可產生三選一卡牌獎勵，也可跳過拿金錢。
- 事件：`EventScene` 與 `EventManager` 可載入事件、顯示選項並套用結果。
- 商店：`ShopScene` 與 `ShopManager` 可買卡、療傷、移除卡牌、切換本局卡牌包。
- 章節結局：`ChapterEndingScene` 與 `ChapterEndingManager` 可套用結局選擇與解鎖內容。
- Debug profile：`DebugProfile` 可記錄已解鎖修士、卡牌包、章節通關與最後選項。
- 工具鏈：已有卡牌匯入、卡圖生成、技能圖匯入、資料匯出與效果支援檢查工具。

## 戰鬥系統

戰鬥主要由 `BattleScene` 協調 UI 與互動，規則逐步拆出到獨立腳本。

主要組件：

- `BattleScene`：戰鬥場景、玩家/敵人 UI、回合流程、卡牌打出入口。
- `CardView`：卡牌顯示、點擊、拖曳、選取、combo 提示與手機版布局。
- `EnemyView`：敵人顯示、意圖與拖曳 drop target。
- `DeckManager`：抽牌堆、手牌、棄牌堆、消耗區與洗牌管理。
- `BattleEffectResolver`：解析卡牌 effects 陣列。
- `CardData`、`EnemyData`：卡牌與敵人 runtime 資料物件。

目前已支援的主要 effect op：

- `deal_damage`
- `deal_true_damage`
- `deal_damage_all`
- `gain_block`
- `draw_cards`
- `gain_energy`
- `apply_status`
- `remove_status`
- `remove_self_status`
- `lose_hp`
- `heal`
- `discard_cards`
- `exhaust`
- `trigger_burn_all`

目前已支援的主要條件：

- `self_has_flame_body`
- `target_has_poison`
- `hand_has_attack`
- `first_card_this_turn`
- `played_water_this_turn`
- `target_intent_is_attack`

已實作或已有基礎行為的狀態方向：

- 燃燒：造成傷害並遞減。
- 中毒：造成傷害並遞減。
- 虛弱：降低攻擊。
- 易傷：增加受到傷害。
- 化焰：可作為火系條件。

## Roguelike 外層流程

Roguelike 外層目前以第一章 demo 為主，使用資料驅動章節與節點。

主要組件：

- `RunManager`：讀取 run flow、章節、起始修士、卡牌包設定，管理節點流轉。
- `RunState`：保存本局狀態，包括修士、章節、節點、牌組、血量、金錢、卡牌包、事件與獎勵狀態。
- `ChapterDatabase`：讀取章節資料與節點查詢。
- `MapScene`、`MapNodeView`：顯示章節地圖與節點狀態。
- `StartingCultivatorDatabase`：載入起始修士與起始牌組。

目前起始修士共有 8 種：

- `metal_cultivator`
- `wood_cultivator`
- `water_cultivator`
- `fire_cultivator`
- `earth_cultivator`
- `soul_cultivator`
- `weapon_cultivator`
- `wanderer_cultivator`

卡牌包雛形已存在，可用於限制或切換本局獎勵卡池。預設最大啟用卡牌包數為 2，部分解鎖或角色設定可調整。

## 資料驅動內容

目前專案資料分成 source、generated 與 config 三類。

資料量現況：

- 卡牌：81 張，位於 `data/generated/cards.json`。
- 敵人：11 個，位於 `data/generated/enemies.json`。
- 狀態：15 個，位於 `data/generated/statuses.json`。
- 第一章節點：13 個，位於 `data/config/chapter_01.json`。

主要資料檔：

- `data/source/cards.xlsx`、`data/source/cards.tsv`：卡牌來源資料。
- `data/source/statuses.tsv`：狀態來源資料。
- `data/generated/cards.json`：遊戲使用的卡牌資料。
- `data/generated/enemies.json`：敵人資料與意圖序列。
- `data/generated/statuses.json`：狀態資料。
- `data/generated/elements.json`、`data/generated/factions.json`、`data/generated/drop_pools.json`：元素、陣營與掉落池。
- `data/config/run_flow_v1.json`：節點類型與場景流轉設定。
- `data/config/chapter_01.json`：第一章劇情與節點。
- `data/config/events_chapter_01.json`：第一章事件。
- `data/config/shop_v1.json`：商店設定。
- `data/config/card_reward_weights_toggleable.json`：卡牌獎勵與卡牌包權重。
- `data/config/starting_cultivators.json`：起始修士、血量、金錢、起始牌組與推薦卡牌包。
- `data/config/chapter_01_ending_choices.json`：章節結局選項與解鎖內容。

建議卡牌資料契約目前沿用：

```json
{
  "id": "FIR_003",
  "name": "炎爆術",
  "element": "fire",
  "type": "attack",
  "cost": 2,
  "target_type": "enemy",
  "description": "造成傷害。若有化焰，追加效果。",
  "rarity": "R",
  "effects": [],
  "tags": [],
  "exhaust": false
}
```

## UI 與美術資源

目前 UI 採直式手機優先，主要畫面已具備可玩的基礎排版。

已存在的主要 UI 與美術資源：

- 標題背景：`assets/ui/title_login_bg.png`
- 戰鬥玩家、敵人、面板、按鈕與血量/靈力條素材：`assets/ui/battle/`
- 卡牌圖：`assets/cards/`
- 狀態 icon：`assets/ui/status/`
- 敵人與角色 placeholder：`assets/ui/`
- 第一章地圖背景：`assets/maps/chapter_01_map_bg.png`
- 第一章戰鬥背景：`assets/backgrounds/`

目前 UI 已有：

- 卡牌手牌顯示。
- 卡牌大圖與戰鬥手牌模式。
- 敵人圖、血量、護盾、意圖顯示。
- 玩家血量、靈力、牌堆數量、戰鬥 log。
- 地圖節點按鈕與可用/完成狀態。
- 獎勵、事件、商店、結局選項 UI。

## 工具與資料匯入流程

`tools/` 目前包含資料與資源處理工具。

主要工具：

- `tools/export_sheets_to_json.py`：將來源表格匯出為遊戲使用 JSON。
- `tools/import_cards_xlsx.py`：匯入卡牌 Excel 資料。
- `tools/generate_card_images.py`：產生卡牌圖片。
- `tools/import_skill_images.py`：匯入技能或卡牌相關圖片。
- `tools/validate_effect_support.py`：檢查卡牌資料使用的 effect op 是否已被支援。

效果支援檢查可使用：

```powershell
python tools\validate_effect_support.py --markdown
```

專案中也有 Android 匯出相關檔案與 build 產物，但這份總覽不逐一列出 Godot import 檔、`.uid`、build artifact 或 Android JDK 內部檔案。

## 測試與除錯方式

目前可用的測試與檢查方式：

- Godot headless 載入檢查。
- Chapter 01 demo regression checklist。
- Run flow smoke log。
- Effect support validation tool。
- 手動從地圖推進節點，測試戰鬥、獎勵、事件、商店與結局。

建議每次功能實作後至少執行：

```powershell
C:\tools\Godot.exe --headless --path . --quit
C:\tools\Godot.exe --headless --path . --quit-after 1
```

第一章 demo 手動測試可參考：

- `docs/chapter_01_demo_test_checklist.md`

## 已知未完成項目與下一步

目前明確待完成或待加強的項目：

- 完整人工遊玩目前主場景，確認戰鬥能穩定打到勝利或敗北。
- 修正戰鬥 UI 中擠壓、看不清楚或操作不順的地方。
- 確認敵人死亡後不再被選取，也不再行動。
- 確認抽牌堆空時棄牌堆會洗回抽牌堆。
- 確認消耗牌進消耗區，且不會洗回抽牌堆。
- 補上更方便的戰鬥測試或重開戰鬥入口。
- 拆出 `StatusManager`，集中處理狀態疊層、回合結算與顯示名稱。
- 拆出 `EnemyManager`，集中處理敵人生成、死亡與意圖輪轉。
- 拆出 `TurnManager`，集中處理玩家回合、敵人回合、回合開始與結束。
- 建立 `ArtifactManager` 與法寶資料。
- 補齊更多資料中已存在但尚未支援的 effect op。
- 建立 `relics.json` 或 `artifacts.json`。
- 匯出工具補上必要欄位檢查。

優先建議順序仍沿用現有開發路線：

1. 人工遊玩目前戰鬥，修操作與顯示問題。
2. 拆出 `StatusManager`。
3. 補齊五行核心狀態與 combo。
4. 完善戰後選卡與卡池控制。
5. 繼續擴充路線地圖、事件、商店與法寶。

## 相關文件

- `docs/DEVELOPMENT_PLAN.md`：製作說明與後續開發路線。
- `docs/EFFECT_SUPPORT.md`：卡牌 effect op 支援狀態。
- `docs/chapter_01_demo_test_checklist.md`：第一章 demo regression checklist。
