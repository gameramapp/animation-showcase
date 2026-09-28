#!/usr/bin/env python3
"""Extra UI languages (es / fr / de) on top of the inline tr('English', 'Russian') pairs.

The English text is the key. This tool keeps the translation tables in sync
with the code (run from the project root):

  python3 tool/i18n_extract.py extract     scan lib/ → tool/i18n/keys.json
                                           (every English template + its Russian
                                           twin and where it is used)
  python3 tool/i18n_extract.py coverage    which keys are missing / stale in
                                           tool/i18n/<lang>.json (exit 1 if any)
  python3 tool/i18n_extract.py generate    tool/i18n/<lang>.json → lib/src/l10n/translations.g.dart

Interpolations become numbered placeholders ⟪0⟫, ⟪1⟫… in both the key and the
translation, e.g. '${ms} ms' → '⟪0⟫ ms'. A translation may reorder them.
"""
import importlib.util
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
_spec = importlib.util.spec_from_file_location('i18n_check', os.path.join(HERE, 'i18n_check.py'))
_check = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_check)

LANGS = ('es', 'fr', 'de')
I18N_DIR = os.path.join('tool', 'i18n')
OUT = os.path.join('lib', 'src', 'l10n', 'translations.g.dart')
PH = '⟪{}⟫'
PH_RE = re.compile(r'⟪(\d+)⟫')

_SIMPLE_ESC = {'n': '\n', 'r': '\r', 't': '\t', 'b': '\b', 'f': '\f', 'v': '\v'}


def literal_value(lit, counter):
    """Runtime value of one Dart string literal, interpolations → placeholders."""
    raw = lit.startswith('r')
    body = lit[1:] if raw else lit
    q = body[0]
    triple = body.startswith(q * 3)
    body = body[3:-3] if triple else body[1:-1]
    if triple:
        # Dart drops the first line of a multi-line string if it's blank.
        body = re.sub(r'\A[ \t]*\r?\n', '', body)
    if raw:
        return body
    out, i, n = [], 0, len(body)
    while i < n:
        c = body[i]
        if c == '\\' and i + 1 < n:
            e = body[i + 1]
            if e in _SIMPLE_ESC:
                out.append(_SIMPLE_ESC[e]); i += 2
            elif e == 'x':
                out.append(chr(int(body[i + 2:i + 4], 16))); i += 4
            elif e == 'u':
                if body[i + 2] == '{':
                    j = body.index('}', i)
                    out.append(chr(int(body[i + 3:j], 16))); i = j + 1
                else:
                    out.append(chr(int(body[i + 2:i + 6], 16))); i += 6
            else:
                out.append(e); i += 2  # \' \" \\ \$ and any other char
            continue
        if c == '$' and i + 1 < n:
            if body[i + 1] == '{':
                depth, j = 1, i + 2
                while j < n and depth:
                    if body[j] == '{':
                        depth += 1
                    elif body[j] == '}':
                        depth -= 1
                    j += 1
                out.append(PH.format(counter[0])); counter[0] += 1; i = j
                continue
            m = re.match(r'[A-Za-z_][A-Za-z0-9_]*', body[i + 1:])
            if m:
                out.append(PH.format(counter[0])); counter[0] += 1; i += 1 + m.end()
                continue
        out.append(c); i += 1
    return ''.join(out)


def group_value(group_src):
    """Value of adjacent literals ('a' 'b' "c") joined, with placeholders."""
    counter = [0]
    toks = [t for t in _check.lex(group_src) if t[0] == 'string']
    return ''.join(literal_value(t[1], counter) for t in toks)


def scan():
    """All tr('<en>', '<ru>') pairs in lib/: {en: {'ru': ru, 'files': [...]}}."""
    keys = {}
    for d, _, files in os.walk('lib'):
        for f in sorted(files):
            if not f.endswith('.dart') or f.endswith('.g.dart'):
                continue
            path = os.path.join(d, f)
            toks = [t for t in _check.lex(open(path).read()) if t[0] != 'comment']
            groups = []
            for k, t, line in toks:
                if k == 'string' and groups and groups[-1][0] == 'string':
                    groups[-1] = ('string', groups[-1][1] + ' ' + t, groups[-1][2])
                elif (k == 'string' and len(groups) >= 2 and groups[-1][0] == 'code'
                      and not groups[-1][1].strip() and groups[-2][0] == 'string'):
                    groups.pop()
                    groups[-1] = ('string', groups[-1][1] + ' ' + t, groups[-1][2])
                else:
                    groups.append((k, t, line))
            for i in range(3, len(groups)):
                if (groups[i][0] == 'string' and groups[i - 2][0] == 'string'
                        and groups[i - 1][0] == 'code' and re.fullmatch(r'\s*,\s*', groups[i - 1][1])
                        and re.search(r'\btr\(\s*$', groups[i - 3][1])):
                    en = group_value(groups[i - 2][1])
                    ru = group_value(groups[i][1])
                    entry = keys.setdefault(en, {'ru': ru, 'files': []})
                    where = f'{os.path.relpath(path)}:{groups[i - 2][2]}'
                    if where not in entry['files']:
                        entry['files'].append(where)
    return keys


def dart_str(s):
    s = (s.replace('\\', '\\\\').replace("'", "\\'").replace('$', '\\$')
         .replace('\n', '\\n').replace('\r', '\\r').replace('\t', '\\t'))
    return f"'{s}'"


def main():
    cmd = sys.argv[1] if len(sys.argv) > 1 else 'extract'
    os.makedirs(I18N_DIR, exist_ok=True)
    keys = scan()
    if cmd == 'extract':
        json.dump(keys, open(os.path.join(I18N_DIR, 'keys.json'), 'w'), ensure_ascii=False, indent=1)
        print(f'{len(keys)} keys → {I18N_DIR}/keys.json')
    elif cmd == 'coverage':
        bad = 0
        for lang in LANGS:
            path = os.path.join(I18N_DIR, f'{lang}.json')
            table = json.load(open(path)) if os.path.exists(path) else {}
            missing = [k for k in keys if not table.get(k)]
            stale = [k for k in table if k not in keys]
            wrong_ph = [k for k, v in table.items() if k in keys and v and
                        sorted(PH_RE.findall(k)) != sorted(PH_RE.findall(v))]
            print(f'{lang}: {len(keys) - len(missing)}/{len(keys)} translated, '
                  f'{len(missing)} missing, {len(stale)} stale, {len(wrong_ph)} placeholder mismatches')
            for k in wrong_ph[:10]:
                print(f'   placeholders differ: {k[:70]!r}')
            bad += len(missing) + len(wrong_ph)
        sys.exit(1 if bad else 0)
    elif cmd == 'generate':
        lines = [
            '// GENERATED by tool/i18n_extract.py generate — do not edit by hand.',
            '// Source: tool/i18n/<lang>.json (English text → translation).',
            '',
            '// ignore_for_file: prefer_single_quotes, lines_longer_than_80_chars',
            '',
            'const Map<String, Map<String, String>> kTranslations = {',
        ]
        for lang in LANGS:
            path = os.path.join(I18N_DIR, f'{lang}.json')
            table = json.load(open(path)) if os.path.exists(path) else {}
            lines.append(f"  '{lang}': {{")
            for k in sorted(keys):
                v = table.get(k)
                if v:
                    lines.append(f'    {dart_str(k)}: {dart_str(v)},')
            lines.append('  },')
        lines.append('};')
        os.makedirs(os.path.dirname(OUT), exist_ok=True)
        open(OUT, 'w').write('\n'.join(lines) + '\n')
        print(f'wrote {OUT}')
    else:
        sys.exit(__doc__)


if __name__ == '__main__':
    main()
