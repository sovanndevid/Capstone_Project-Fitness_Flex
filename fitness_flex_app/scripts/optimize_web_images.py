#!/usr/bin/env python3
"""Shrink source photos only inside temporary Flutter Web build checkouts.

Keep the original mobile repository images and image paths unchanged.
"""
from pathlib import Path
from PIL import Image, ImageOps

IMAGE_DIR = Path("assets/images")
if not IMAGE_DIR.is_dir():
    raise SystemExit("Missing asset images directory; refusing to continue.")

original = 0
optimized = 0
for file in sorted(IMAGE_DIR.glob("*.jpg")):
    original += file.stat().st_size
    with Image.open(file) as source:
        img = ImageOps.exif_transpose(source).convert("RGB")
        img.thumbnail((1400, 1050), Image.Resampling.LANCZOS)
        img.save(file, "JPEG", quality=76, optimize=True, progressive=True, subsampling=2)
    optimized += file.stat().st_size
    print(f"Optimized {file.name}: {file.stat().st_size // 1024} KiB")

if original <= 0 or optimized >= original * .45:
    raise SystemExit("Web image optimization did not achieve expected savings.")
print(f"Web image assets: {original / 1048576:.2f} MiB -> {optimized / 1048576:.2f} MiB "
      f"({100 * (1 - optimized/original):.1f}% smaller)")
