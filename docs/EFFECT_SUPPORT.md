# Effect 支援清單

這份文件記錄 `data/generated/cards.json` 目前使用到的 effect op，以及 `BattleEffectResolver` 是否已支援。更新卡牌或新增 effect op 時，請同步更新 resolver 與本文件。

更新指令：

```powershell
C:\Users\rickl\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe tools\validate_effect_support.py --markdown
```

目前統計：

- 卡牌數：81
- 使用中的 effect op：47
- 已支援 effect op：14
- 待支援 effect op：33

| Status | Effect op | Uses | First example |
| --- | --- | ---: | --- |
| Supported | `deal_damage` | 20 | BAS_002 基礎劍訣 |
| Supported | `apply_status` | 19 | BAS_005 破綻百出 |
| Supported | `gain_block` | 15 | BAS_001 基礎吐納 |
| Supported | `exhaust` | 12 | BAS_004 聚氣散 |
| Supported | `draw_cards` | 8 | BAS_003 閃避步法 |
| Supported | `gain_energy` | 5 | BAS_004 聚氣散 |
| Supported | `deal_true_damage` | 3 | SOU_001 神念刺 |
| Supported | `discard_cards` | 3 | BAS_007 飛身托跡 |
| Supported | `deal_damage_all` | 2 | FIR_005 星火燎原 |
| Supported | `lose_hp` | 2 | FIR_006 焚血訣 |
| Supported | `remove_status` | 2 | WOD_008 碧落黃泉 |
| Supported | `heal` | 1 | BAS_009 便捷小還丹 |
| Supported | `remove_self_status` | 1 | FIR_009 轉焰歸元 |
| Supported | `trigger_burn_all` | 1 | FIR_005 星火燎原 |
| Pending | `apply_power` | 9 | BAS_016 斂氣術 |
| Pending | `add_buff` | 3 | BAS_010 強攻訣 |
| Pending | `shuffle_card_into_draw_pile` | 3 | BAS_017 大力金剛丸 |
| Pending | `consume_all_energy` | 2 | WAT_008 九歌落水 |
| Pending | `add_block_per_debuff` | 1 | BAS_015 借力打力 |
| Pending | `add_block_per_status` | 1 | GLD_005 劍影步 |
| Pending | `add_card_to_hand` | 1 | WOD_003 青蔓術 |
| Pending | `add_random_rare_to_hand` | 1 | BAS_019 仙人指路 |
| Pending | `add_temporary_buff` | 1 | WPN_004 淬毒機關 |
| Pending | `apply_status_per_status_threshold` | 1 | WOD_006 催化劑 |
| Pending | `buff_soul_damage` | 1 | SOU_007 神念化盾 |
| Pending | `change_intent` | 1 | SOU_004 驚魂咒 |
| Pending | `deal_damage_boost_by_status_cards` | 1 | WPN_003 飛刀突襲 |
| Pending | `deal_damage_equal_block` | 1 | ERT_005 泰山壓頂 |
| Pending | `deal_damage_vampire` | 1 | WOD_005 嗜血藤蔓 |
| Pending | `deal_true_aoe_damage` | 1 | SOU_008 神識風暴 |
| Pending | `deal_true_damage_per_status` | 1 | WOD_008 碧落黃泉 |
| Pending | `discard_all_type` | 1 | WPN_006 袖裡乾坤 |
| Pending | `discover_from_discard` | 1 | BAS_018 搜刮戰場 |
| Pending | `double_current_block` | 1 | ERT_007 岩石重構 |
| Pending | `end_turn` | 1 | BAS_014 奪路而逃 |
| Pending | `exhaust_type_in_hand` | 1 | GLD_006 熔劍鑄鐵 |
| Pending | `get_self_status` | 1 | FIR_007 紅蓮業火 |
| Pending | `increase_max_hp_on_kill` | 1 | SOU_005 搜魂奪魄 |
| Pending | `play_all_from_decks` | 1 | GLD_008 天外飛仙 |
| Pending | `redirect_intent_to_self` | 1 | SOU_006 奪舍魔音 |
| Pending | `reduce_gold` | 1 | BAS_008 靈石利誘 |
| Pending | `reduce_intent_damage` | 1 | SOU_003 神識干擾 |
| Pending | `retain_hand` | 1 | BAS_012 蓄勢待發 |
| Pending | `return_to_hand_on_discard` | 1 | WPN_005 回旋扇 |
| Pending | `strip_block` | 1 | BAS_013 破甲針 |
| Pending | `trigger_on_turn_end_in_hand` | 1 | STS_001 丹毒 |
| Pending | `unplayable` | 1 | STS_001 丹毒 |
