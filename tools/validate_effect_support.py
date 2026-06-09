#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import re
from collections import Counter
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CARDS_PATH = ROOT / "data" / "generated" / "cards.json"
RESOLVER_PATH = ROOT / "scripts" / "battle" / "BattleEffectResolver.gd"


def main() -> int:
    parser = argparse.ArgumentParser(description="Report card effect ops supported by BattleEffectResolver.")
    parser.add_argument("--markdown", action="store_true", help="Print a Markdown table.")
    args = parser.parse_args()

    cards = json.loads(CARDS_PATH.read_text(encoding="utf-8"))
    supported_ops = read_supported_ops()
    counts: Counter[str] = Counter()
    examples: dict[str, str] = {}

    for card in cards:
        for effect in card.get("effects", []):
            op = str(effect.get("op", "")).strip()
            if not op:
                continue
            counts[op] += 1
            examples.setdefault(op, f"{card.get('id', '')} {card.get('name', '')}".strip())

    rows = sorted(
        counts.items(),
        key=lambda item: (
            item[0] not in supported_ops,
            -item[1],
            item[0],
        ),
    )

    if args.markdown:
        print("| Status | Effect op | Uses | First example |")
        print("| --- | --- | ---: | --- |")
        for op, count in rows:
            status = "Supported" if op in supported_ops else "Pending"
            print(f"| {status} | `{op}` | {count} | {examples[op]} |")
    else:
        for op, count in rows:
            status = "OK" if op in supported_ops else "TODO"
            print(f"{status:4} {op:36} {count:3}  {examples[op]}")

    unsupported = [op for op in counts if op not in supported_ops]
    print()
    print(f"Cards: {len(cards)}")
    print(f"Effect ops: {len(counts)}")
    print(f"Supported ops: {len(counts) - len(unsupported)}")
    print(f"Pending ops: {len(unsupported)}")
    return 1 if unsupported else 0


def read_supported_ops() -> set[str]:
    text = RESOLVER_PATH.read_text(encoding="utf-8")
    match = re.search(r"const\s+SUPPORTED_OPS\s*:=\s*\{(?P<body>.*?)\}", text, re.S)
    if match is None:
        raise SystemExit(f"Could not find SUPPORTED_OPS in {RESOLVER_PATH.relative_to(ROOT)}")
    return set(re.findall(r'"([^"]+)"', match.group("body")))


if __name__ == "__main__":
    raise SystemExit(main())
