#!/usr/bin/env python3
from __future__ import annotations

import csv
import json
import re
import sys
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = ROOT / "data" / "source"
GENERATED_DIR = ROOT / "data" / "generated"

CARDS_TSV = SOURCE_DIR / "cards.tsv"
STATUSES_TSV = SOURCE_DIR / "statuses.tsv"

RARITY_PREFIX_RE = re.compile(r"^\[(SSR|SR|R|N)\]\s*")

REQUIRED_CARD_FIELDS = [
    "id",
    "name",
    "cost",
    "type",
    "element",
    "faction",
    "pool",
    "npc_only",
    "description",
    "effect_logic",
]

TRUE_VALUES = {"true", "1", "yes", "y", "是"}
FALSE_VALUES = {"false", "0", "no", "n", "否"}

LEGACY_EFFECT_SPECS = {
    "deal_damage": ("target", "amount"),
    "deal_true_damage": ("target", "amount"),
    "deal_damage_all": ("target", "amount"),
    "gain_block": ("target", "amount"),
    "draw_cards": ("target", "amount"),
    "gain_energy": ("target", "amount"),
    "apply_status": ("target", "status", "amount"),
    "apply_power": ("target", "power", "amount"),
    "exhaust": ("target",),
    "discard_cards": ("target", "amount"),
    "shuffle_card_into_draw_pile": ("card_id", "amount"),
    "add_card_to_hand": ("card_id", "amount"),
    "play_card_by_id": ("card_id",),
    "summon": ("summon_id", "amount"),
    "change_intent": ("target", "intent"),
    "increase_max_hp_on_kill": ("target", "amount"),
}

WORKBOOK_OP_ALIASES = {
    "add_block": "gain_block",
    "draw_card": "draw_cards",
    "apply_status_all": "apply_status",
    "add_status": "apply_status",
    "add_power": "apply_power",
    "shuffle_into_draw": "shuffle_card_into_draw_pile",
    "add_to_hand": "add_card_to_hand",
    "discard": "discard_cards",
    "deal_aoe_damage": "deal_damage_all",
    "gain_max_hp_on_kill": "increase_max_hp_on_kill",
}


class DataError(Exception):
    pass


def main() -> int:
    try:
        GENERATED_DIR.mkdir(parents=True, exist_ok=True)
        cards = parse_cards(read_tsv(CARDS_TSV), CARDS_TSV)
        statuses = parse_statuses(read_tsv(STATUSES_TSV), STATUSES_TSV)
        factions = build_factions()
        elements = build_elements()
        drop_pools = build_drop_pools(cards, factions)

        write_json(GENERATED_DIR / "cards.json", cards)
        write_json(GENERATED_DIR / "statuses.json", statuses)
        write_json(GENERATED_DIR / "factions.json", factions)
        write_json(GENERATED_DIR / "elements.json", elements)
        write_json(GENERATED_DIR / "drop_pools.json", drop_pools)
    except DataError as error:
        print(f"Data error: {error}", file=sys.stderr)
        return 1

    print("Export complete:")
    for name in [
        "cards.json",
        "statuses.json",
        "factions.json",
        "elements.json",
        "drop_pools.json",
    ]:
        print(f"  data/generated/{name}")
    return 0


def read_tsv(path: Path) -> list[dict[str, str]]:
    if not path.exists():
        raise DataError(f"Missing source TSV: {path.relative_to(ROOT)}")

    with path.open("r", encoding="utf-8-sig", newline="") as file:
        reader = csv.DictReader(file, delimiter="\t")
        if reader.fieldnames is None:
            raise DataError(f"{path.relative_to(ROOT)} has no header row.")
        return [{key: value or "" for key, value in row.items()} for row in reader]


def parse_cards(rows: list[dict[str, str]], path: Path) -> list[dict[str, Any]]:
    cards: list[dict[str, Any]] = []
    seen_ids: set[str] = set()

    for row_number, row in enumerate(rows, start=2):
        missing = [field for field in REQUIRED_CARD_FIELDS if field not in row]
        if missing:
            raise DataError(
                f"{path.relative_to(ROOT)} row {row_number} missing fields: {', '.join(missing)}"
            )

        card_id = require_text(row["id"], path, row_number, "id")
        if card_id in seen_ids:
            raise DataError(f"{path.relative_to(ROOT)} row {row_number} duplicates card id: {card_id}")
        seen_ids.add(card_id)

        raw_name = require_text(row["name"], path, row_number, "name")
        name, inferred_rarity = extract_rarity(raw_name)
        rarity = row.get("rarity", "").strip() or inferred_rarity or "N"

        effects = parse_effect_logic(row["effect_logic"], path, row_number, card_id)
        card = {
            "id": card_id,
            "name": name,
            "cost": parse_cost(row["cost"], path, row_number, card_id),
            "type": require_text(row["type"], path, row_number, "type"),
            "element": require_text(row["element"], path, row_number, "element"),
            "faction": require_text(row["faction"], path, row_number, "faction"),
            "pool": require_text(row["pool"], path, row_number, "pool"),
            "npc_only": parse_bool(row["npc_only"], path, row_number, card_id),
            "description": require_text(row["description"], path, row_number, "description"),
            "rarity": rarity,
            "effects": effects,
        }
        cards.append(card)

    return cards


def parse_statuses(rows: list[dict[str, str]], path: Path) -> list[dict[str, Any]]:
    required = ["id", "name", "type", "description", "stacking"]
    statuses: list[dict[str, Any]] = []
    seen_ids: set[str] = set()

    for row_number, row in enumerate(rows, start=2):
        missing = [field for field in required if field not in row]
        if missing:
            raise DataError(
                f"{path.relative_to(ROOT)} row {row_number} missing fields: {', '.join(missing)}"
            )

        status_id = require_text(row["id"], path, row_number, "id")
        if status_id in seen_ids:
            raise DataError(f"{path.relative_to(ROOT)} row {row_number} duplicates status id: {status_id}")
        seen_ids.add(status_id)

        statuses.append(
            {
                "id": status_id,
                "name": require_text(row["name"], path, row_number, "name"),
                "type": require_text(row["type"], path, row_number, "type"),
                "description": require_text(row["description"], path, row_number, "description"),
                "stacking": parse_bool(row["stacking"], path, row_number, status_id),
            }
        )

    return statuses


def extract_rarity(raw_name: str) -> tuple[str, str | None]:
    match = RARITY_PREFIX_RE.match(raw_name)
    if not match:
        return raw_name, None
    return RARITY_PREFIX_RE.sub("", raw_name).strip(), match.group(1)


def parse_cost(value: str, path: Path, row_number: int, card_id: str) -> int | str:
    cost = value.strip()
    if cost.upper() == "X":
        return "X"
    if cost.isdigit():
        return int(cost)
    raise DataError(
        f"{path.relative_to(ROOT)} row {row_number} card {card_id} has invalid cost: {value!r}"
    )


def parse_bool(value: str, path: Path, row_number: int, item_id: str) -> bool:
    normalized = value.strip().lower()
    if normalized in TRUE_VALUES:
        return True
    if normalized in FALSE_VALUES:
        return False
    raise DataError(
        f"{path.relative_to(ROOT)} row {row_number} item {item_id} has invalid boolean: {value!r}"
    )


def parse_effect_logic(raw_logic: str, path: Path, row_number: int, card_id: str) -> list[dict[str, Any]]:
    if "op:" in raw_logic:
        return parse_workbook_effect_logic(raw_logic, path, row_number, card_id)

    effects: list[dict[str, Any]] = []
    logic = raw_logic.replace("\\n", "\n")
    for line_number, raw_line in enumerate(logic.splitlines(), start=1):
        line = raw_line.strip()
        if not line:
            continue

        parts = line.split()
        op = parts[0]
        if op not in LEGACY_EFFECT_SPECS:
            raise DataError(
                f"{path.relative_to(ROOT)} row {row_number} card {card_id} line {line_number} "
                f"uses unknown op: {op}"
            )

        params = LEGACY_EFFECT_SPECS[op]
        values = parts[1:]
        if len(values) != len(params):
            raise DataError(
                f"{path.relative_to(ROOT)} row {row_number} card {card_id} line {line_number} "
                f"expects {len(params)} args for {op}, got {len(values)}."
            )

        effect: dict[str, Any] = {"op": op, "condition": None}
        for param, raw_value in zip(params, values):
            effect[param] = parse_amount(raw_value) if param == "amount" else raw_value
        effects.append(effect)

    if not effects:
        raise DataError(f"{path.relative_to(ROOT)} row {row_number} card {card_id} has no effects.")
    return effects


def parse_workbook_effect_logic(raw_logic: str, path: Path, row_number: int, card_id: str) -> list[dict[str, Any]]:
    effects: list[dict[str, Any]] = []
    for index, segment in enumerate(raw_logic.split(";"), start=1):
        segment = segment.strip()
        if not segment:
            continue

        fields = parse_workbook_segment(segment)
        op = fields.pop("op", "")
        if not op:
            raise DataError(
                f"{path.relative_to(ROOT)} row {row_number} card {card_id} effect {index} is missing op."
            )

        effect = normalize_workbook_effect(op, fields)
        effects.append(effect)

    if not effects:
        raise DataError(f"{path.relative_to(ROOT)} row {row_number} card {card_id} has no effects.")
    return effects


def parse_workbook_segment(segment: str) -> dict[str, Any]:
    result: dict[str, Any] = {}
    parts = [part.strip() for part in segment.split(",") if part.strip()]
    for part in parts:
        if ":" not in part:
            continue
        key, value = part.split(":", 1)
        key = key.strip()
        result[key] = parse_workbook_value(value.strip())
    return result


def parse_workbook_value(value: str) -> Any:
    if len(value) >= 2 and value[0] == '"' and value[-1] == '"':
        return value[1:-1]
    if re.fullmatch(r"-?\d+", value):
        return int(value)
    if re.fullmatch(r"-?\d+\.\d+", value):
        return float(value)
    return value


def normalize_workbook_effect(source_op: str, fields: dict[str, Any]) -> dict[str, Any]:
    op = WORKBOOK_OP_ALIASES.get(source_op, source_op)
    effect: dict[str, Any] = {"op": op, "condition": fields.pop("condition", None)}
    if source_op != op:
        effect["source_op"] = source_op

    if "status_key" in fields:
        status_key = str(fields.pop("status_key"))
        if op == "apply_power":
            fields["power"] = normalize_key(status_key)
        else:
            fields["status"] = normalize_key(status_key)
    if "card_id" in fields:
        fields["card_id"] = fields["card_id"]
    if "type" in fields and op == "change_intent":
        fields["intent"] = normalize_key(str(fields.pop("type")))

    if op in {"deal_damage", "deal_true_damage"}:
        effect["target"] = str(fields.pop("target", "enemy"))
    elif op == "deal_damage_all":
        effect["target"] = str(fields.pop("target", "enemies"))
    elif op in {"gain_block", "draw_cards", "gain_energy", "apply_power"}:
        effect["target"] = str(fields.pop("target", "self"))
    elif op == "apply_status":
        default_target = "enemies" if source_op == "apply_status_all" else "enemy"
        target = fields.pop("to", fields.pop("target", default_target))
        effect["target"] = "self" if str(target).lower() == "self" else str(target)
    elif op in {"exhaust", "discard_cards", "increase_max_hp_on_kill"}:
        effect["target"] = str(fields.pop("target", "self"))
    elif op == "change_intent":
        effect["target"] = str(fields.pop("target", "enemy"))

    effect.update(fields)
    return effect


def normalize_key(value: str) -> str:
    text = re.sub(r"(?<!^)(?<!_)(?=[A-Z])", "_", value).replace(" ", "_").replace("-", "_")
    return text.lower()


def parse_amount(value: str) -> int:
    if re.fullmatch(r"-?\d+", value):
        return int(value)
    raise DataError(f"Effect amount must be an integer, got: {value!r}")


def require_text(value: str, path: Path, row_number: int, field: str) -> str:
    text = value.strip()
    if not text:
        raise DataError(f"{path.relative_to(ROOT)} row {row_number} has empty required field: {field}")
    return text


def build_factions() -> list[dict[str, Any]]:
    return [
        {"id": "cangfenggu", "name": "藏鋒谷", "element": "metal", "playable": True, "npc_only": False},
        {"id": "kumuzhai", "name": "枯木齋", "element": "wood", "playable": True, "npc_only": False},
        {"id": "xuanbinggong", "name": "玄冰宮", "element": "water", "playable": True, "npc_only": False},
        {"id": "fentiangu", "name": "焚天谷", "element": "fire", "playable": True, "npc_only": False},
        {"id": "zhenyuezong", "name": "鎮嶽宗", "element": "earth", "playable": True, "npc_only": False},
        {"id": "taixuguan", "name": "太虛觀", "element": "soul", "playable": True, "npc_only": False},
        {"id": "rogue_cultivator", "name": "散修", "element": "mixed", "playable": True, "npc_only": False},
        {"id": "qianjimen", "name": "千機門", "element": "neutral", "playable": False, "npc_only": False},
        {"id": "qixuezong", "name": "泣血宗", "element": "blood", "playable": False, "npc_only": True},
        {"id": "qiansige", "name": "牽絲閣", "element": "puppet", "playable": False, "npc_only": True},
        {"id": "wangqinggong", "name": "忘情宮", "element": "mind", "playable": False, "npc_only": True},
    ]


def build_elements() -> dict[str, Any]:
    return {
        "counter_multiplier": 1.5,
        "synergy_multiplier": 1.2,
        "synergy_hook": "trigger_synergy_effect",
        "counter_cycle": {
            "metal": "wood",
            "wood": "earth",
            "earth": "water",
            "water": "fire",
            "fire": "metal",
        },
        "synergy_cycle": ["wood", "fire", "earth", "metal", "water"],
        "elements": [
            {"id": "metal", "name": "金"},
            {"id": "wood", "name": "木"},
            {"id": "water", "name": "水"},
            {"id": "fire", "name": "火"},
            {"id": "earth", "name": "土"},
        ],
    }


def build_drop_pools(cards: list[dict[str, Any]], factions: list[dict[str, Any]]) -> dict[str, Any]:
    npc_only_factions = {faction["id"] for faction in factions if faction.get("npc_only")}
    player_cards = [
        card for card in cards if not card["npc_only"] and card["faction"] not in npc_only_factions
    ]

    pools: dict[str, Any] = {
        "base": sorted(card["id"] for card in player_cards if card["pool"] == "base"),
        "rogue_cultivator": sorted(card["id"] for card in player_cards),
        "npc_only": sorted(card["id"] for card in cards if card["npc_only"]),
    }

    faction_to_pool = {
        "cangfenggu": "metal",
        "kumuzhai": "wood",
        "xuanbinggong": "water",
        "fentiangu": "fire",
        "zhenyuezong": "earth",
        "taixuguan": "soul",
        "qianjimen": "weapon",
    }

    for faction_id, pool_id in faction_to_pool.items():
        pools[faction_id] = sorted(
            card["id"] for card in player_cards if card["pool"] in {"base", pool_id}
        )

    return pools


def write_json(path: Path, data: Any) -> None:
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    raise SystemExit(main())
