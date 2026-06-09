#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
CARDS_JSON = ROOT / "data" / "generated" / "cards.json"
OUTPUT_DIR = ROOT / "assets" / "cards"
DEFAULT_SOURCE_DIR = Path("C:/覓仙劫圖片")
MAX_WIDTH = 512


def main() -> int:
    parser = argparse.ArgumentParser(description="Import skill art by matching image filenames to card names.")
    parser.add_argument("source_dir", nargs="?", type=Path, default=DEFAULT_SOURCE_DIR)
    parser.add_argument("--max-width", type=int, default=MAX_WIDTH)
    args = parser.parse_args()

    if not CARDS_JSON.exists():
        raise FileNotFoundError(f"Missing card data: {CARDS_JSON}")
    if not args.source_dir.exists():
        raise FileNotFoundError(f"Missing source image directory: {args.source_dir}")

    cards = json.loads(CARDS_JSON.read_text(encoding="utf-8"))
    cards_by_name = {str(card["name"]): card for card in cards if "name" in card and "id" in card}
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    imported = 0
    skipped: list[str] = []
    total_before = 0
    total_after = 0

    for card_name, card in sorted(cards_by_name.items(), key=lambda item: str(item[1]["id"])):
        source_path = args.source_dir / f"{card_name}.png"
        if not source_path.exists():
            skipped.append(card_name)
            continue

        output_path = OUTPUT_DIR / f"{card['id']}.png"
        before = source_path.stat().st_size
        total_before += before

        with Image.open(source_path) as source:
            image = source.convert("RGB")
            if image.width > args.max_width:
                height = round(image.height * args.max_width / image.width)
                image = image.resize((args.max_width, height), Image.Resampling.LANCZOS)
            image.save(output_path, format="PNG", optimize=True, compress_level=9)

        after = output_path.stat().st_size
        total_after += after
        imported += 1
        print(f"{card['id']} {card_name}: {before:,} -> {after:,} bytes")

    print(f"Imported {imported} images into {OUTPUT_DIR}")
    print(f"Matched source size: {total_before:,} bytes")
    print(f"Output size: {total_after:,} bytes")
    if skipped:
        print("Missing source images:")
        for name in skipped:
            print(f"- {name}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
