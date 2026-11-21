#!/usr/bin/env python3
"""Discord announcement (news / stable / beta). Env: WEBHOOK KIND TITLE BODY URL NEWS_TYPE EMOJI ROLE_ID PING_TEXT DRY_RUN"""
import json, os, re, sys, urllib.request, urllib.error
from datetime import datetime, timezone
E = os.environ.get
LIMIT = 3900
COLORS = {'feature':0x2ECC71,'fix':0xE67E22,'update':0x3498DB,'alert':0xE74C3C,'info':0x95A5A6,'stable':0x3498DB,'beta':0x9B59B6}
ICONS = {'feature':'✨','fix':'🛠️','update':'⬆️','alert':'⚠️','info':'ℹ️','stable':'🚀','beta':'🧪'}
LABELS = {'feature':'Nouveauté','fix':'Correctif','update':'Mise à jour','alert':'Alerte','info':'Info','stable':'Release','beta':'Pré-release (bêta)'}

def split_row(l):
    l = l.strip().strip('|')
    return [c.strip() for c in l.split('|')]

def table_to_code(rows):
    cells = [[re.sub(r'[*_`~=]+', '', c) for c in r] for r in rows]
    n = max(len(r) for r in cells)
    cells = [r + [''] * (n - len(r)) for r in cells]
    w = [max(len(r[i]) for r in cells) for i in range(n)]
    f = lambda r: ' | '.join(r[i].ljust(w[i]) for i in range(n)).rstrip()
    return '```\n' + '\n'.join([f(cells[0]), '-+-'.join('-'*x for x in w)] + [f(r) for r in cells[1:]]) + '\n```'

def to_discord(md):
    md = (md or '').replace('\r\n', '\n').replace('\r', '\n')
    if '\n' not in md: md = md.replace('\\n', '\n')
    md = re.sub(r'<!--.*?-->', '', md, flags=re.S)
    lines, out, image, i = md.split('\n'), [], None, 0
    sep = lambda l: bool(re.match(r'^\s*\|?[\s:\-|]+\|?\s*$', l)) and '-' in l
    while i < len(lines):
        l = lines[i].rstrip()
        m = re.match(r'^!\[[^\]]*\]\((https?://\S+)\)$', l.strip())
        if m: image = image or m.group(1); i += 1; continue
        if '|' in l and i+1 < len(lines) and sep(lines[i+1]):
            rows, j = [split_row(l)], i+2
            while j < len(lines) and '|' in lines[j] and lines[j].strip():
                rows.append(split_row(lines[j])); j += 1
            out.append(table_to_code(rows)); i = j; continue
        l = re.sub(r'^#{4,}\s+', '### ', l)
        l = re.sub(r'^\*\s+', '- ', l)
        l = re.sub(r'==(.+?)==', r'**\1**', l)
        out.append(l); i += 1
    return re.sub(r'\n{3,}', '\n\n', '\n'.join(out)).strip(), image

def clip(t, link):
    if len(t) <= LIMIT: return t
    c = t[:LIMIT].rsplit('\n', 1)[0]
    if c.count('```') % 2: c += '\n```'
    return c + ('\n\n… [lire la suite](%s)' % link if link else '\n\n…')

def main():
    hook = (E('WEBHOOK') or '').strip()
    if not hook: print('No webhook: skipped.'); return 0
    kind = E('KIND', 'news')
    nt = E('NEWS_TYPE', 'info') if kind == 'news' else kind
    if nt not in COLORS: nt = 'info'
    title, url = (E('TITLE') or '').strip(), (E('URL') or '').strip()
    text, image = to_discord(E('BODY'))
    emoji = (E('EMOJI') or '').strip() or ICONS[nt]
    emb = {'title': f'{emoji} {title}'[:256], 'color': COLORS[nt],
           'footer': {'text': 'LastStats · ' + LABELS[nt]},
           'timestamp': datetime.now(timezone.utc).isoformat()}
    if text: emb['description'] = clip(text, url)
    if url: emb['url'] = url
    if image: emb['image'] = {'url': image}
    p = {'username': 'LastStats', 'embeds': [emb]}
    role, ping = (E('ROLE_ID') or '').strip(), (E('PING_TEXT') or '').strip()
    if role or ping: p['content'] = ((f'Hey <@&{role}>! ' if role else '') + ping).strip()
    p['allowed_mentions'] = {'parse': [], 'roles': [role] if role else []}
    if E('DRY_RUN') == '1': print(json.dumps(p, ensure_ascii=False, indent=2)); return 0
    req = urllib.request.Request(hook + ('&' if '?' in hook else '?') + 'wait=true',
        data=json.dumps(p).encode(), method='POST',
        headers={'Content-Type':'application/json','User-Agent':'LastStats-CI (https://github.com/SanoBld/LastStats)'})
    try:
        with urllib.request.urlopen(req, timeout=20) as r: print('Discord:', r.status)
    except urllib.error.HTTPError as e:
        print('Discord error', e.code, e.read().decode('utf-8','replace')[:300]); return 1
    return 0
if __name__ == '__main__': sys.exit(main())
