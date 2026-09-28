#!/usr/bin/env python3
"""i18n check for this repo (run from the project root).

  python3 tool/i18n_check.py untranslated .   Cyrillic string literals that are not
                                              the 2nd argument of tr('<en>', '<ru>')
                                              (a line containing `i18n-ignore` is allowed)
  python3 tool/i18n_check.py cyrillic .       comments that contain Cyrillic
                                              (comments are English-only)
  snapshot / verify <root> <file.json>        hash of the code with comments stripped —
                                              proves a comment-only edit changed no code

Both checks print file:line for every hit and exit with code 1 if there are any.

A small hand-written lexer: understands '..', "..", '''..''', \"\"\"..\"\"\", raw r'..',
${...} interpolation nesting, // and /* */ (nested) comments.
"""
import hashlib
import json
import os
import re
import sys

CYR = re.compile(r'[Ѐ-ӿ]')


def lex(src):
    """Yields (kind, text, line) where kind is 'code' or 'comment'."""
    i, n, line = 0, len(src), 1
    out = []
    buf = []

    def flush_code():
        if buf:
            out.append(('code', ''.join(buf), None))
            buf.clear()

    def read_string(i, raw):
        # returns index after string, handles triple quotes and interpolation
        q = src[i]
        triple = src.startswith(q * 3, i)
        end = q * 3 if triple else q
        j = i + (3 if triple else 1)
        while j < n:
            if not raw and src[j] == '\\':
                j += 2
                continue
            if src.startswith(end, j):
                return j + len(end)
            if not raw and src.startswith('${', j):
                j = read_interp(j + 2)
                continue
            if not triple and src[j] == '\n':
                return j  # unterminated; be lenient
            j += 1
        return j

    def read_interp(j):
        depth = 1
        while j < n and depth:
            c = src[j]
            if c in '\'"':
                raw = j > 0 and src[j - 1] == 'r' and not (src[j - 2].isalnum() if j > 1 else False)
                j = read_string(j, raw)
                continue
            if c == '{':
                depth += 1
            elif c == '}':
                depth -= 1
            j += 1
        return j

    while i < n:
        c = src[i]
        if src.startswith('//', i):
            flush_code()
            j = src.find('\n', i)
            j = n if j == -1 else j
            out.append(('comment', src[i:j], line))
            i = j
            continue
        if src.startswith('/*', i):
            flush_code()
            depth, j = 1, i + 2
            while j < n and depth:
                if src.startswith('/*', j):
                    depth += 1
                    j += 2
                elif src.startswith('*/', j):
                    depth -= 1
                    j += 2
                else:
                    j += 1
            out.append(('comment', src[i:j], line))
            line += src[i:j].count('\n')
            i = j
            continue
        if c in '\'"':
            raw = i > 0 and src[i - 1] == 'r' and not (src[i - 2].isalnum() or src[i - 2] == '_' if i > 1 else False)
            j = read_string(i, raw)
            flush_code()
            out.append(('string', src[i:j], line))
            line += src[i:j].count('\n')
            i = j
            continue
        if c == '\n':
            line += 1
        buf.append(c)
        i += 1
    flush_code()
    return out


def stripped(src):
    code = ''.join(t for k, t, _ in lex(src) if k in ('code', 'string'))
    return re.sub(r'\s+', ' ', code).strip()


def dart_files(root):
    for base in ('lib', 'test'):
        for d, _, files in os.walk(os.path.join(root, base)):
            for f in files:
                if f.endswith('.dart'):
                    yield os.path.join(d, f)


def main():
    cmd, root = sys.argv[1], sys.argv[2]
    if cmd == 'snapshot':
        data = {os.path.relpath(p, root): hashlib.sha1(stripped(open(p).read()).encode()).hexdigest()
                for p in dart_files(root)}
        json.dump(data, open(sys.argv[3], 'w'), indent=1)
        print(f'{len(data)} files snapshotted')
    elif cmd == 'verify':
        data = json.load(open(sys.argv[3]))
        bad = []
        for rel, h in data.items():
            p = os.path.join(root, rel)
            if not os.path.exists(p):
                bad.append(f'{rel}: missing')
                continue
            if hashlib.sha1(stripped(open(p).read()).encode()).hexdigest() != h:
                bad.append(f'{rel}: CODE CHANGED')
        print('\n'.join(bad) if bad else f'OK: code identical in {len(data)} files')
        sys.exit(1 if bad else 0)
    elif cmd == 'untranslated':
        # Every Cyrillic string must be the 2nd argument of tr('<English>', '<Русский>').
        files = sys.argv[3:] or list(dart_files(root))
        total = 0
        for p in files:
            src_text = open(p).read()
            src_lines = src_text.split('\n')
            toks = [t for t in lex(src_text) if t[0] != 'comment']
            # merge adjacent string literals (implicit concatenation) into groups
            groups = []  # (kind, text, line)
            for k, t, line in toks:
                if k == 'string' and len(groups) >= 2 and groups[-1][0] == 'code' and not groups[-1][1].strip() and groups[-2][0] == 'string':
                    groups.pop()
                    gk, gt, gl = groups.pop()
                    groups.append(('string', gt + t, gl))
                elif k == 'string' and groups and groups[-1][0] == 'string':
                    gk, gt, gl = groups.pop()
                    groups.append(('string', gt + t, gl))
                else:
                    groups.append((k, t, line))
            for idx, (k, t, line) in enumerate(groups):
                if k != 'string' or not CYR.search(t):
                    continue
                ok = (idx >= 3 and groups[idx - 1][0] == 'code' and re.fullmatch(r'\s*,\s*', groups[idx - 1][1])
                      and groups[idx - 2][0] == 'string' and not CYR.search(groups[idx - 2][1])
                      and groups[idx - 3][0] == 'code' and re.search(r'\btr\(\s*$', groups[idx - 3][1]))
                if not ok and 'i18n-ignore' in src_lines[line - 1]:
                    ok = True  # explicitly allowed, e.g. a language's own name
                if not ok:
                    total += 1
                    print(f'{os.path.relpath(p, root)}:{line}: {t.strip()[:90]}')
        print(f'-- {total} untranslated Cyrillic strings', file=sys.stderr)
        sys.exit(1 if total else 0)
    elif cmd == 'cyrillic':
        files = sys.argv[3:] or list(dart_files(root))
        total = 0
        for p in files:
            for k, t, line in lex(open(p).read()):
                if k == 'comment' and CYR.search(t):
                    total += 1
                    print(f'{os.path.relpath(p, root)}:{line}: {t.strip()[:100]}')
        print(f'-- {total} Cyrillic comments', file=sys.stderr)
        sys.exit(1 if total else 0)


if __name__ == '__main__':
    main()
