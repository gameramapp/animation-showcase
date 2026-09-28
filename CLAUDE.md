# CLAUDE.md — what this project is and what's expected of you

> Any Claude agent entering this project reads this file. Read it in full
> before changing anything.

## The gist of the project

This is a **Flutter animation showcase** for designers. The goal is to bring
together, in one app, the whole range of animations the team knows how to
build, and **host** it as a web app so designers can open a link, browse the
catalog and watch every animation live.

Think of it as a **living catalog of capabilities**: not a learning codelab,
but a demo stand — "here's what we can do." Over time this will keep growing:

- **more animation packages get added** (flutter_animate, rive, lottie,
  animations, etc.) — on request;
- **more showcases get added** — separate screens, each demonstrating one
  technique / effect / package capability.

Origin: a fork of the official Flutter codelab `animation_samples`, but the
classic examples from it have been removed — everything in the catalog is
built for our own needs.

## Audience — designers, not developers

The main thing to keep in mind for any UI change:

- **The catalog must be easy to browse**: clear grouping, meaningful names, a
  tidy home screen. A designer should find the effect they need in seconds.
- **Every showcase should "play" right away** or have an obvious button to
  start it — a designer shouldn't have to guess how to turn it on.
- A short **description in words** for each showcase (what the effect is,
  which package it's built with) is a big plus.

## Architecture (how it's all put together right now)

- Entry point and navigation: [lib/main.dart](lib/main.dart). Uses `go_router`.
- The catalog is the `categories` list (`DemoCategory { title, subtitle, icon,
  demos }`). Each category holds its own `Demo { name, route, builder,
  description, effort }` list (`basicDemos`, `explicitDemos`, `routingDemos`,
  `microDemos`, `scrollDemos`, `paintingDemos`, `packageDemos`, `mediaDemos`,
  `experimentalDemos`, `configDemos`).
  `HomePage` and the `GoRouter` routes are built from `categories`
  automatically.
- `description` — one line for the designer (what the effect is, where it's
  useful); `effort` (`Effort.easy / medium / hard`) — how much effort that
  animation costs in the product. Shown as a badge on the home screen.
- `preview` — a live 72×72 mini-animation to the left of the item on the home
  screen. All previews live in
  [lib/src/home/demo_previews.dart](lib/src/home/demo_previews.dart):
  `LoopPreview(builder: (context, t) => …)` supplies a looping time `t`.
  A preview must stay lightweight: heavy packages (Rive etc.) are faked.
- Showcases live under [lib/src/](lib/src/) in themed folders (`basics/`,
  `explicit/`, `routing/`, `hero/`, `micro/`, `scroll/`, `painting/`,
  `packages/`, `config/`, `home/`), each with a barrel file (except
  `packages/`, where screens are grouped into `packages_*.dart`).
  The classic examples from the Flutter codelab have been removed — the
  catalog is ours only.
- Shared building blocks in [lib/src/common/](lib/src/common/):
  - `IntroCard` — a screen's intro card (what this is + a hint on how to play
    it);
  - `AnimBlock` — a "preview on the left, description and knobs on the right"
    block;
  - `ResponsiveWrap` + `ShowcaseTile` — a grid of example tiles;
  - `LabeledSlider`, `CurveDropdown`, `animationCurves` — standard knobs;
  - `motion_spec.dart` — curves as STRINGS: a Flutter preset,
    `cubic-bezier(…)` (Figma/CSS) or `spring(stiffness, damping, mass)` (Figma
    Smart Animate). Turn one into a `Curve` only via `resolveCurve(...)`.
    `CurveDropdown` opens its own curve editor. `SpecButton` /
    `AnimBlock(spec: …)` — the "Spec" button: the block's current settings as
    JSON (`timingSpec(...)` for duration and curve with its CSS equivalent);
  - `designer_brief.dart` — `DesignerBrief`: the "What we need from the
    designer" block at the very bottom of the screen;
  - `keyframe_spec.dart` — the "animation from config" runtime (a JSON of
    keyframes: properties, a CSS transform, matrices). Moves into the product
    as is;
  - `matrix_sequence.dart` — the "matrix sequence" runtime: the designer's
    text (one matrix per line + `| ms | curve`) → `MatrixSequence.parse(...)`
    → `MatrixSequenceAnimator`. A TweenSequence of Matrix4Tween under the
    hood.
  Build new screens out of these — that's what keeps the catalog looking
  consistent.
- Every showcase is a self-contained widget with a `static const String
  routeName`. Good examples:
  [lib/src/micro/micro_interactions.dart](lib/src/micro/micro_interactions.dart),
  [lib/src/basics/implicit_animations.dart](lib/src/basics/implicit_animations.dart).

## i18n: English by default + Russian, Spanish, French, German

The UI speaks five languages. Read
[lib/src/common/i18n.dart](lib/src/common/i18n.dart) — it has the full
picture in its header comment; the short version:

- Every user-visible string is written as a pair right where it's used:
  `Text(tr('Duration', 'Длительность'))`. `tr(en, ru)` reads the current
  language (`AppLang.en` is the default) and picks the matching argument.
- `tr()` calls must run inside `build()` (or a getter/function called from
  it). No UI text may live in a `const` value, a top-level or static `final`,
  an enum constant's constructor, a `late final` field, or a default
  parameter value — any of those would freeze the string in whatever
  language was active when it was first evaluated.
- English and Russian are written inline. Spanish, French and German are
  looked up **by the English text** in
  [lib/src/l10n/translations.g.dart](lib/src/l10n/translations.g.dart),
  generated from `tool/i18n/{es,fr,de}.json`. A missing translation falls back
  to English. Interpolated strings are matched by template — the key for
  `tr('Speed (${ms} ms)', …)` is `Speed (⟪0⟫ ms)`, and a translation may
  reorder the `⟪n⟫` placeholders.
- After adding or changing any `tr()` English text:
  1. `python3 tool/i18n_extract.py extract` → `tool/i18n/keys.json`
     (every English key with its Russian twin and where it's used);
  2. add the missing keys to `tool/i18n/{es,fr,de}.json`
     (`python3 tool/i18n_extract.py coverage` lists what's missing or stale);
  3. `python3 tool/i18n_extract.py generate` → rewrites translations.g.dart
     (never edit it by hand);
  4. `coverage` must report 0 missing and 0 placeholder mismatches.
- Every screen's `AppBar` ends its `actions` with `const LangButton()` — the
  language menu. Add it to any new screen's `AppBar`.
- The language can be forced with a link parameter: `https://…/?lang=de`. The
  choice is otherwise remembered in the browser (`shared_preferences` →
  `localStorage`); English is the default when neither is set.
- Switching the language re-runs every `build()` in the app (see
  `AnimationSamples` in main.dart, which listens to `appLang` and calls
  `WidgetsBinding.instance.reassembleApplication()`) while keeping all state
  and the current page — that's what makes `tr()` calls inside otherwise
  `const` subtrees pick up the new language.
- State must not hold translated text as identity: remember choices by
  index or by an English id and translate only for display (see the choice
  fields in `brief_playground.dart`, palettes in
  `generative_avatars_demo.dart`, presets in `matrix4_transform_demo.dart`).
  If a `State` keeps translated text (e.g. a sample value in a
  `TextEditingController`), refresh it in `reassemble()` — it is called on
  every language switch.
- Comments are English-only; UI text is English + Russian via `tr()`.
  Both rules are enforced by `python3 tool/i18n_check.py untranslated .`
  (Cyrillic string literals outside the second argument of `tr()`) and
  `python3 tool/i18n_check.py cyrillic .` (Cyrillic in comments). Both must
  print 0 — they exit with code 1 otherwise.
- [test/all_demos_test.dart](test/all_demos_test.dart) opens every screen in
  English, checks there is no Cyrillic on screen, switches through Russian,
  German, French and Spanish at runtime and back, fails on any crash, on a
  layout overflow in EN or RU, and if a shown string has no es/fr/de
  translation. es/fr/de are best-effort: their overflows are tolerated
  (German runs long; don't spend time fitting it).

## How to add a new showcase (the standard procedure)

When asked to "build showcase X" / "show off package Y's capability":

1. **Package**: if a new package is needed — `flutter pub add <pkg>`. Check
   that it's web-compatible and installs on the current Flutter (see "Known
   limitations").
2. **Widget**: create a file in the right folder under [lib/src/](lib/src/)
   (packages go in `lib/src/packages/`). The widget must:
   - have `static const String routeName = 'category/name';`
   - be a `Scaffold` with `AppBar(title: ...)` and an `IntroCard` at the top;
   - **play right away** (auto-play / loop) or have an explicit button;
   - offer **knobs** for everything the designer might want to set for us
     (duration, curve via `CurveDropdown`, delays, effect strength…) — this
     is a sandbox where the designer dials in an animation for their case;
   - give every block a "Spec" (`AnimBlock(spec: …)` or `SpecButton`) with
     ALL current values in the designer's units;
   - end with a `DesignerBrief` at the very bottom: exactly what to send us
     so we can reproduce it (timings, curves, values, files and their
     requirements);
   - text — through `tr()`, short: what the effect is and where it's useful.
3. **Export**: add the file to its folder's barrel.
4. **Preview**: add a preview function in `demo_previews.dart`.
5. **Registration**: add a `Demo(...)` with `description`, `effort` and
   `preview` to the right list in [lib/main.dart](lib/main.dart) (or start a
   new `DemoCategory`).
6. **Check it**: `flutter analyze` and `flutter test` — the test
   [test/all_demos_test.dart](test/all_demos_test.dart) opens EVERY screen in
   the catalog itself, at phone and desktop width, and fails on any exception
   or layout overflow. Then run it in the browser and eyeball it.

Keep new showcases consistent with the existing ones in style and structure.

## Hosting (web)

The app must build and run as Flutter Web.

- Local run: `flutter run -d chrome`
- Build for deployment: `flutter build web` → artifacts in `build/web/`
- Any new packages must be **web-compatible** (or have a web fallback). If a
  package doesn't work on web, that needs to be called out explicitly.

## Known limitations

- `boring_avatars` requires Dart ≥ 3.11 (a Flutter newer than 3.35) — it
  doesn't install. There's a custom CustomPainter-based implementation
  instead (the "Generative avatars" screen).
- Rive doesn't run its native engine under `flutter test` (it crashes with
  SIGABRT if rive_native is built locally) — in tests, the screen shows a
  stand-in.
- In tests, the stand-in font is wider than the real one: wrap `Row`s with
  text in `Flexible` + `TextOverflow.ellipsis`.

## Conventions

- Base stack: Flutter 3.35 (Dart SDK `^3.9.0-0`), `go_router`, the animation
  packages from [pubspec.yaml](pubspec.yaml).
- Showcase names and `routeName` — meaningful, reflecting the effect/package.
- Assets go in [assets/](assets/), fonts in [fonts/](fonts/), register them in
  [pubspec.yaml](pubspec.yaml).
- Before handing off work: `flutter analyze` and `flutter test` with no
  errors, and a check in the browser.

## Checklist for a new agent

- [ ] Read this file — understood this is an animation showcase for
      designers, meant to be hosted.
- [ ] Understood the showcase pattern (widget → barrel → `Demo` with
      description and effort in main.dart).
- [ ] Understood the i18n pattern (`tr()` in `build()`, `LangButton` in every
      `AppBar`, no UI text in `const`/`final`/state fields, es/fr/de tables
      regenerated via `tool/i18n_extract.py` after text changes).
- [ ] Any changes keep the catalog easy for a designer to browse and
      web-compatible.
