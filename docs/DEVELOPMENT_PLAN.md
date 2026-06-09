# 《覓仙劫》製作說明與開發路線

本文件是《覓仙劫》後續製作的共同參照。之後新增功能、調整架構、製作卡牌或 UI 時，優先依照這份方向走；完成的項目用勾選標記，淘汰或不再採用的想法用刪除線標記。

## 核心定位

《覓仙劫》採用「殺戮尖塔式戰鬥骨架」，但題材與策略核心要做成修仙味：

- 回合制卡牌戰鬥。
- 每回合抽牌、獲得靈力、施展法訣、收功。
- 敵人顯示意圖，玩家根據意圖選擇攻擊、防禦、解狀態或準備 combo。
- 卡牌、狀態、敵人與日後法寶盡量資料驅動。
- 核心特色是「五行流派 + 禁術代價 + 法寶組合」。

開發比例原則：

- 70% 採用成熟的卡牌 Roguelike 戰鬥架構。
- 30% 做出《覓仙劫》自己的修仙系統。

## 已完成

- [x] 建立 Godot 專案與直式手機解析度。
- [x] 建立主戰鬥場景 `BattleScene`。
- [x] 建立卡牌視圖 `CardView`。
- [x] 建立敵人視圖 `EnemyView`。
- [x] 建立卡牌資料 `cards.json` 與 TSV/XLSX 匯入流程。
- [x] 建立狀態資料 `statuses.json`。
- [x] 建立卡圖資源與 placeholder 流程。
- [x] 實作抽牌堆、手牌、棄牌堆、消耗區。
- [x] 實作靈力消耗與每回合恢復。
- [x] 實作點選/拖曳卡牌到敵人。
- [x] 實作敵人意圖顯示。
- [x] 實作基本敵人回合。
- [x] 拆出 `BattleEffectResolver`，讓效果解析不再全部塞在 `BattleScene`。
- [x] 支援第一批核心卡牌效果：
  - [x] `deal_damage`
  - [x] `deal_true_damage`
  - [x] `deal_damage_all`
  - [x] `gain_block`
  - [x] `draw_cards`
  - [x] `gain_energy`
  - [x] `apply_status`
  - [x] `remove_status`
  - [x] `remove_self_status`
  - [x] `lose_hp`
  - [x] `heal`
  - [x] `discard_cards`
  - [x] `exhaust`
  - [x] `trigger_burn_all`
- [x] 支援第一批條件：
  - [x] `self_has_flame_body`
  - [x] `target_has_poison`
  - [x] `hand_has_attack`
  - [x] `first_card_this_turn`
  - [x] `played_water_this_turn`
  - [x] `target_intent_is_attack`
- [x] 實作資料驅動敵人意圖序列 `intent_sequence`。
- [x] Godot headless 載入檢查通過。
- [x] 測試牌組目前使用的 effect 都已有支援。

## 目前第一目標：可玩戰鬥閉環

目標是先讓玩家可以完整打一場小型戰鬥，確認核心戰鬥有趣，再擴充地圖、商店、事件與法寶。

- [ ] 實際開啟 Godot 主場景，人工測試完整打一場到勝利或敗北。
- [ ] 修正戰鬥 UI 中任何擠壓、看不清楚、操作不順的地方。
- [ ] 確認敵人死亡後不再被選取、不再行動。
- [ ] 確認抽牌堆空時棄牌堆會洗回抽牌堆。
- [ ] 確認消耗牌進消耗區，且不會洗回抽牌堆。
- [ ] 補一個簡單的戰鬥測試/除錯入口，方便快速重開戰鬥。
- [x] 檢查 81 張卡中哪些效果尚未支援，產出支援清單。
- [ ] 測試牌組先保持只放已支援效果的卡，避免戰鬥體驗被未完成效果打斷。

## 下一階段：效果與狀態補齊

優先補齊資料中已存在、且對五行流派很關鍵的效果。

- [ ] `deal_true_aoe_damage`
- [ ] `deal_true_damage_per_status`
- [ ] `deal_damage_equal_block`
- [ ] `deal_damage_vampire`
- [ ] `deal_damage_boost_by_status_cards`
- [ ] `add_block_per_status`
- [ ] `add_block_per_debuff`
- [ ] `apply_power`
- [ ] `add_buff`
- [ ] `add_temporary_buff`
- [ ] `discard_all_type`
- [ ] `exhaust_type_in_hand`
- [ ] `shuffle_card_into_draw_pile`
- [ ] `add_card_to_hand`
- [ ] `change_intent`
- [ ] `consume_all_energy`
- [ ] `double_current_block`
- [ ] `strip_block`
- [ ] `retain_hand`
- [ ] `return_to_hand_on_discard`
- [ ] `unplayable`

狀態系統目標：

- [x] 燃燒可以造成傷害並遞減。
- [x] 中毒可以造成傷害並遞減。
- [x] 虛弱會降低攻擊。
- [x] 易傷會增加受到傷害。
- [x] 化焰可作為火系條件。
- [ ] 劍意要能強化金系/劍訣。
- [ ] 冰寒要能影響敵人行動或意圖。
- [ ] 神魂標記要能支援神魂流派真傷。
- [ ] 幻影/無形類狀態要限制受到傷害。
- [ ] 護盾保留類狀態要支援回合間保留護盾。

## 五行與流派方向

五行不是只當顏色，而要變成戰鬥邏輯。

- [ ] 火修：高爆發、燃燒、自燃、化焰、反噬。
- [ ] 木修：中毒、恢復、持續成長、毒層轉傷害。
- [ ] 水修：抽牌、棄牌、冰寒、靈力流動、延遲收益。
- [ ] 金修：飛劍、劍意、多段、破甲。
- [ ] 土修：護盾、反擊、護盾轉傷、厚重代價。
- [ ] 神魂修：真傷、控心、神魂標記、傷神代價。
- [ ] 暗器/武器流：棄牌、多段、消耗手牌換爆發。

## 資料架構原則

卡牌、狀態、敵人、法寶都要優先資料驅動。

- [x] 卡牌資料已從 TSV/XLSX 匯出 JSON。
- [x] 卡牌效果使用 effects 陣列。
- [x] 狀態使用 `statuses.json`。
- [x] 敵人資料改成正式 JSON，不再只寫在 `_sample_enemies()`。
- [ ] 法寶資料建立 `relics.json` 或 `artifacts.json`。
- [x] 每個 effect op 都要有支援狀態清單。
- [x] 增加 effect 支援檢查工具。
- [ ] 匯出工具要能檢查缺少必要欄位的卡牌。

建議卡牌資料契約：

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

## 系統拆分方向

目前已開始把規則從 UI 場景拆出。後續目標是：

- [x] `BattleEffectResolver`：解析卡牌 effects。
- [x] `DeckManager`：管理抽牌、棄牌、消耗、洗牌。
- [ ] `StatusManager`：管理狀態疊層、回合結算、顯示名稱。
- [ ] `EnemyManager`：管理敵人生成、死亡、意圖輪轉。
- [ ] `TurnManager`：管理玩家回合、敵人回合、回合開始/結束。
- [ ] `ArtifactManager`：管理法寶觸發。
- [ ] `BattleScene` 最終只保留 UI 協調與畫面互動。

## 第二階段：Roguelike 骨架

戰鬥穩定後再做。

- [ ] 戰後選卡。
- [ ] 基礎路線地圖。
- [ ] 普通戰鬥、精英戰鬥、Boss 節點。
- [ ] 事件節點。
- [ ] 商店。
- [ ] 休息/修煉節點。
- [ ] 初始主修流派選擇。
- [ ] 每局隨機卡池與獎勵。

## 法寶系統

法寶是每局差異化核心，但不要早於戰鬥閉環。

- [ ] 建立法寶資料格式。
- [ ] 戰鬥開始觸發。
- [ ] 回合開始/結束觸發。
- [ ] 打出特定元素卡時觸發。
- [ ] 上狀態或引爆狀態時觸發。
- [ ] 消耗牌、棄牌、抽牌時觸發。
- [ ] Boss/精英專屬法寶。

## UI 與體驗規範

- [x] 採用直式手機 UI。
- [x] 卡牌可點選與拖曳。
- [x] 敵人意圖直接顯示在敵人卡片上。
- [ ] 戰鬥資訊要更清楚區分：玩家、敵人、提示、手牌。
- [ ] 狀態要逐步改成 icon + 數字，少用長文字。
- [ ] 靈力、抽牌堆、棄牌堆、消耗區要容易掃讀。
- [ ] 卡牌大圖預覽要更適合手機操作。
- [ ] 戰鬥 log 保留，但不能搶走主要操作區。

## 暫不做或不照搬

- [ ] ~~整套照搬殺戮尖塔角色職業。~~ 改成主修流派 + 五行混搭 + 法寶。
- [ ] ~~只做 Attack / Skill / Power 的英文表層。~~ 底層可保留 type，顯示要修仙化。
- [ ] ~~一開始就做完整地圖、商店、事件。~~ 先確保戰鬥本身好玩。
- [ ] ~~每張卡都寫獨立腳本。~~ 大部分卡牌使用資料 effects 組合，少數特殊牌才寫 custom script。

## 每次開發前檢查

- [ ] 先確認要做的是戰鬥閉環、效果補齊、資料整理、UI 改善，還是 Roguelike 外層。
- [ ] 不新增大型系統，除非目前階段已完成。
- [ ] 新卡牌優先使用既有 effect op。
- [ ] 如果需要新 effect op，要同時更新 resolver 與這份說明。
- [ ] 每次實作後至少跑：

```powershell
C:\tools\Godot.exe --headless --path . --quit
C:\tools\Godot.exe --headless --path . --quit-after 1
```

## 近期建議順序

1. 人工遊玩目前戰鬥，修操作與顯示問題。
2. 拆出 `StatusManager`。
3. 補齊五行核心狀態與 combo。
4. 做戰後選卡。
5. 開始做路線地圖。
