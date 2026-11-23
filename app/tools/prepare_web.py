"""Prépare web/ (généré par `flutter create --platforms=web`) pour un usage iPhone (PWA).
Usage : python3 tools/prepare_web.py <titre> <couleur_theme>
Idempotent : repart toujours de la copie d'origine de index.html / manifest.json."""
import json, shutil, sys
from pathlib import Path
from PIL import Image

title, color = sys.argv[1], (sys.argv[2] if len(sys.argv) > 2 else '#0B0805')
web = Path('web')
for name in ('index.html', 'manifest.json'):
    orig = web / (name + '.orig')
    if not orig.exists():
        shutil.copy(web / name, orig)

# Icônes depuis le logo
logo = Image.open('assets/images/logo.png').convert('RGBA')
def icon(size, path):
    bg = Image.new('RGBA', (size, size), color)
    l = logo.copy(); l.thumbnail((int(size * .8), int(size * .8)))
    bg.paste(l, ((size - l.width) // 2, (size - l.height) // 2), l)
    bg.convert('RGB').save(path)
(web / 'icons').mkdir(exist_ok=True)
icon(180, web / 'icons' / 'apple-touch-icon.png')
icon(192, web / 'icons' / 'Icon-192.png')
icon(512, web / 'icons' / 'Icon-512.png')
icon(192, web / 'icons' / 'Icon-maskable-192.png')
icon(512, web / 'icons' / 'Icon-maskable-512.png')
icon(32, web / 'favicon.png')

html = (web / 'index.html.orig').read_text(encoding='utf-8')
head = f'''<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover">
  <meta name="apple-mobile-web-app-capable" content="yes">
  <meta name="mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
  <meta name="apple-mobile-web-app-title" content="{title}">
  <meta name="theme-color" content="{color}">
  <link rel="apple-touch-icon" href="icons/apple-touch-icon.png">
  <style>html,body{{background:{color};margin:0}}</style>
'''
import re
html = re.sub(r'<meta name="apple-mobile-web-app-[^>]*>\s*', '', html)
html = re.sub(r'<link rel="apple-touch-icon"[^>]*>\s*', '', html)
html = re.sub(r'<title>.*?</title>', f'<title>{title}</title>', html, flags=re.S)
html = html.replace('<head>', '<head>\n  ' + head, 1)
(web / 'index.html').write_text(html, encoding='utf-8')

m = json.loads((web / 'manifest.json.orig').read_text(encoding='utf-8'))
m.update(name=title, short_name=title, background_color=color, theme_color=color, display='standalone', orientation='portrait-primary')
(web / 'manifest.json').write_text(json.dumps(m, indent=2, ensure_ascii=False), encoding='utf-8')
print('web prêt :', title)
