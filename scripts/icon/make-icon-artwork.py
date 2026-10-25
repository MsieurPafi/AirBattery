"""App icon artwork (D-018).

Writes three SVG files to the given folder:
- bolt.svg, plus.svg: white layers for AirBattery/AppIcon.icon/Assets (Icon Composer adds glass and light)
- flat.svg: flat icon for macOS 12-25, exported to AppIcon.appiconset with export-pngs.swift

Usage: python3 scripts/icon/make-icon-artwork.py <out-dir>
"""
import sys, os
out = sys.argv[1]
TOP, BOTTOM = "#8DEFB2", "#13A6A0"
# Geometry on the full-bleed 1024 canvas (Icon Composer: the canvas is the icon shape)
BOLT = "M590 120 L268 566 L478 566 L398 870 L714 405 L503 405 Z"
BOLT_W = 54                     # rounded corners: stroke drawn with the fill
PLUS = (790, 238, 214, 70)      # cx, cy, size, thickness
def plus_rects(fill):
    cx, cy, s, t = PLUS
    return (f'<rect x="{cx-s/2}" y="{cy-t/2}" width="{s}" height="{t}" rx="{t/2}" fill="{fill}"/>'
            f'<rect x="{cx-t/2}" y="{cy-s/2}" width="{t}" height="{s}" rx="{t/2}" fill="{fill}"/>')
def bolt_path(fill):
    return f'<path d="{BOLT}" fill="{fill}" stroke="{fill}" stroke-width="{BOLT_W}" stroke-linejoin="round"/>'
def layer(body):
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">{body}</svg>'
# Icon Composer layers: plain white shapes, the system adds glass, light and shadow
open(os.path.join(out, "bolt.svg"), "w").write(layer(bolt_path("#FFFFFF")))
open(os.path.join(out, "plus.svg"), "w").write(layer(plus_rects("#FFFFFF")))
# Flat icon for macOS 12-25: same artwork scaled into the classic 824 pt squircle
glass = ('<linearGradient id="glass" x1="0" y1="0" x2="1" y2="1">'
         '<stop offset="0.25" stop-color="#fff" stop-opacity="0.97"/><stop offset="0.8" stop-color="#fff" stop-opacity="0.70"/></linearGradient>')
flat = f'''<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">
<defs>
<linearGradient id="bg" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{TOP}"/><stop offset="1" stop-color="{BOTTOM}"/></linearGradient>
<linearGradient id="sheen" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff" stop-opacity="0.20"/><stop offset="0.5" stop-color="#fff" stop-opacity="0"/></linearGradient>
{glass}
<filter id="drop" x="-10%" y="-10%" width="120%" height="125%"><feDropShadow dx="0" dy="10" stdDeviation="12" flood-color="#000" flood-opacity="0.28"/></filter>
<mask id="art"><g transform="translate(100 100) scale(0.8047)">{bolt_path("#fff")}{plus_rects("#fff")}</g></mask>
</defs>
<g filter="url(#drop)"><rect x="100" y="100" width="824" height="824" rx="185" fill="url(#bg)"/></g>
<rect width="1024" height="1024" fill="url(#glass)" mask="url(#art)"/>
<rect x="100" y="100" width="824" height="824" rx="185" fill="url(#sheen)"/>
</svg>'''
open(os.path.join(out, "flat.svg"), "w").write(flat)
