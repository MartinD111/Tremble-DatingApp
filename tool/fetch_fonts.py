"""Download the exact .ttf bytes google_fonts would fetch at runtime.

The package embeds a content hash per (family, weight, style) and builds the URL
as https://fonts.gstatic.com/s/a/<hash>.ttf. Pulling from that URL guarantees we
bundle byte-identical files to what the runtime fetch produced, so switching to
local assets cannot change rendering.

Filenames follow GoogleFontsVariant.toApiFilenamePart():
  Regular + italic -> "Italic"  (not "RegularItalic")
"""
import re
import pathlib
import urllib.request
import hashlib
import sys

GF = pathlib.Path.home() / ".pub-cache/hosted/pub.dev/google_fonts-8.0.2/lib/src/google_fonts_parts"
OUT = pathlib.Path("assets/fonts")

FAMILIES = {
    "instrumentSans": ("part_i.dart", "InstrumentSans"),
    "playfairDisplay": ("part_p.dart", "PlayfairDisplay"),
    "jetBrainsMono": ("part_j.dart", "JetBrainsMono"),
    "lora": ("part_l.dart", "Lora"),
}

WEIGHT_TO_NAME = {
    "w100": "Thin", "w200": "ExtraLight", "w300": "Light", "w400": "Regular",
    "w500": "Medium", "w600": "SemiBold", "w700": "Bold", "w800": "ExtraBold",
    "w900": "Black",
}

VARIANT_RE = re.compile(
    r"fontWeight:\s*FontWeight\.(w\d00),\s*fontStyle:\s*FontStyle\.(\w+),?\s*\)"
    r"\s*:\s*GoogleFontsFile\(\s*'([0-9a-f]+)',\s*(\d+)",
    re.MULTILINE,
)


def filename(family, weight, italic):
    prefix = WEIGHT_TO_NAME[weight]
    if prefix == "Regular":
        part = "Italic" if italic else "Regular"
    else:
        part = prefix + ("Italic" if italic else "")
    return f"{family}-{part}.ttf"


OUT.mkdir(parents=True, exist_ok=True)
total_bytes = 0
count = 0
failures = []

for method, (part, api_family) in FAMILIES.items():
    src = (GF / part).read_text(encoding="utf-8")
    m = re.search(rf"static TextStyle {method}\(", src)
    start = src.index("final fonts = <GoogleFontsVariant, GoogleFontsFile>{", m.end())
    end = src.index("\n    };", start)
    body = src[start:end]

    found = VARIANT_RE.findall(body)
    if not found:
        failures.append(f"{api_family}: no variants parsed")
        continue

    for weight, style, fhash, length in found:
        name = filename(api_family, weight, style == "italic")
        dest = OUT / name
        url = f"https://fonts.gstatic.com/s/a/{fhash}.ttf"
        try:
            with urllib.request.urlopen(url, timeout=60) as r:
                data = r.read()
        except Exception as e:  # noqa: BLE001
            failures.append(f"{name}: {e}")
            continue

        # The package validates downloads against these; do the same so a bad
        # byte cannot silently enter the repo.
        actual_hash = hashlib.sha256(data).hexdigest()
        if len(data) != int(length):
            failures.append(f"{name}: length {len(data)} != expected {length}")
            continue
        dest.write_bytes(data)
        total_bytes += len(data)
        count += 1
        print(f"  {name:44s} {len(data)/1024:7.1f} KB  sha256={actual_hash[:12]}")

print(f"\n{count} files, {total_bytes/1024/1024:.2f} MB total")
if failures:
    print("\nFAILURES:")
    for f in failures:
        print(f"  {f}")
    sys.exit(1)
