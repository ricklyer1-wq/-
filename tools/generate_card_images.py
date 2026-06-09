#!/usr/bin/env python3
from __future__ import annotations

import json
import math
import sys
from pathlib import Path
from textwrap import wrap
from typing import Any

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
CARDS_JSON = ROOT / "data" / "generated" / "cards.json"
OUTPUT_DIR = ROOT / "assets" / "cards"
WIDTH = 512
HEIGHT = 768

ELEMENT_THEMES = {
    "metal": ((210, 188, 116), (69, 72, 78), "金"),
    "wood": ((81, 148, 95), (29, 76, 56), "木"),
    "water": ((76, 145, 196), (26, 62, 102), "水"),
    "fire": ((218, 94, 58), (120, 35, 33), "火"),
    "earth": ((161, 129, 78), (78, 61, 39), "土"),
    "soul": ((138, 112, 190), (48, 42, 82), "魂"),
    "neutral": ((139, 146, 153), (51, 57, 65), "凡"),
    "blood": ((173, 50, 62), (83, 18, 28), "血"),
    "puppet": ((132, 112, 86), (61, 49, 38), "傀"),
    "mind": ((108, 107, 125), (42, 43, 57), "念"),
    "evil": ((138, 37, 55), (48, 18, 28), "魔"),
}

TYPE_LABELS = {
    "attack": "攻擊",
    "skill": "技能",
    "power": "能力",
    "status": "狀態",
}

RARITY_COLORS = {
    "BASIC": (198, 203, 210),
    "N": (226, 226, 218),
    "R": (113, 176, 236),
    "SR": (190, 128, 231),
    "SSR": (246, 195, 83),
    "TOKEN": (139, 220, 172),
    "STATUS": (217, 96, 96),
}


def main() -> int:
    if not CARDS_JSON.exists():
        print("Missing data/generated/cards.json. Run tools/export_sheets_to_json.py first.", file=sys.stderr)
        return 1

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    cards = json.loads(CARDS_JSON.read_text(encoding="utf-8"))
    for card in cards:
        image = draw_card(card)
        image.save(OUTPUT_DIR / f"{card['id']}.png")

    print(f"Generated {len(cards)} card images in assets/cards")
    return 0


def draw_card(card: dict[str, Any]) -> Image.Image:
    element = str(card.get("element", "neutral"))
    primary, secondary, glyph = ELEMENT_THEMES.get(element, ELEMENT_THEMES["neutral"])
    rarity = str(card.get("rarity", "N"))
    rarity_color = RARITY_COLORS.get(rarity, RARITY_COLORS["N"])

    image = Image.new("RGB", (WIDTH, HEIGHT), secondary)
    draw = ImageDraw.Draw(image)
    draw_gradient(draw, primary, secondary)
    draw_abstract_art(draw, primary, secondary, glyph)

    margin = 28
    draw.rounded_rectangle((margin, margin, WIDTH - margin, HEIGHT - margin), radius=32, outline=rarity_color, width=8)
    draw.rounded_rectangle((44, 46, WIDTH - 44, 166), radius=22, fill=(21, 24, 30), outline=(238, 232, 210), width=2)
    draw.rounded_rectangle((44, 548, WIDTH - 44, 710), radius=22, fill=(238, 232, 210), outline=(52, 45, 39), width=2)

    title_font = font(42)
    body_font = font(25)
    small_font = font(22)
    cost_font = font(44)
    glyph_font = font(120)

    draw.ellipse((54, 58, 128, 132), fill=(245, 241, 223), outline=rarity_color, width=4)
    draw.text((91, 94), str(card.get("cost", "?")), font=cost_font, fill=(32, 35, 40), anchor="mm")

    draw.text((150, 82), str(card.get("name", "")), font=title_font, fill=(248, 244, 225), anchor="la")
    type_text = TYPE_LABELS.get(str(card.get("type", "")), str(card.get("type", "")))
    draw.text((154, 128), f"{type_text} · {rarity}", font=small_font, fill=(204, 213, 222), anchor="la")

    draw.text((WIDTH / 2, 348), glyph, font=glyph_font, fill=(255, 255, 255), anchor="mm")
    draw.ellipse((176, 262, 336, 422), outline=(255, 255, 255), width=4)

    description = str(card.get("description", ""))
    y = 574
    for line in wrap_cjk(description, 17)[:4]:
        draw.text((70, y), line, font=body_font, fill=(34, 32, 29))
        y += 34

    draw.text((WIDTH / 2, 724), str(card.get("id", "")), font=small_font, fill=(238, 232, 210), anchor="mm")
    return image


def draw_gradient(draw: ImageDraw.ImageDraw, primary: tuple[int, int, int], secondary: tuple[int, int, int]) -> None:
    for y in range(HEIGHT):
        t = y / HEIGHT
        color = tuple(int(primary[i] * (1 - t) + secondary[i] * t) for i in range(3))
        draw.line((0, y, WIDTH, y), fill=color)


def draw_abstract_art(
    draw: ImageDraw.ImageDraw,
    primary: tuple[int, int, int],
    secondary: tuple[int, int, int],
    glyph: str,
) -> None:
    cx, cy = WIDTH / 2, 348
    for index in range(18):
        angle = index * math.pi / 9
        radius = 58 + index * 7
        x = cx + math.cos(angle) * radius
        y = cy + math.sin(angle) * radius
        color = blend(primary, secondary, index / 18)
        draw.line((cx, cy, x, y), fill=color, width=8)
    for radius in (92, 132, 176):
        draw.ellipse((cx - radius, cy - radius, cx + radius, cy + radius), outline=blend(primary, (255, 255, 255), 0.35), width=3)


def blend(a: tuple[int, int, int], b: tuple[int, int, int], t: float) -> tuple[int, int, int]:
    return tuple(int(a[i] * (1 - t) + b[i] * t) for i in range(3))


def font(size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    candidates = [
        Path("C:/Windows/Fonts/msjh.ttc"),
        Path("C:/Windows/Fonts/msyh.ttc"),
        Path("C:/Windows/Fonts/simhei.ttf"),
    ]
    for candidate in candidates:
        if candidate.exists():
            return ImageFont.truetype(str(candidate), size)
    return ImageFont.load_default()


def wrap_cjk(text: str, width: int) -> list[str]:
    lines: list[str] = []
    for paragraph in text.splitlines():
        if not paragraph:
            continue
        lines.extend(wrap(paragraph, width=width, break_long_words=True, replace_whitespace=False))
    return lines or [""]


if __name__ == "__main__":
    raise SystemExit(main())
