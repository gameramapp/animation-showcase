# Flutter Animation Showcase

A live catalog of Flutter animations for designers: open any example, tweak
duration, curves and effect strength, and copy the spec for the developers.

**Open it:** https://gameramapp.github.io/animation-showcase/
(add `?lang=ru`, `de`, `fr` or `es` to switch the language)

## What's inside

Implicit and explicit animations, choreography, screen transitions,
micro-interactions, scroll effects, Canvas drawing, animation packages
(flutter_animate, animations, …), Lottie and Rive, and a "from designer to
code" section: curves as `cubic-bezier` / spring, keyframes and matrices from
config.

Every screen has knobs, a **Spec** button with the current values, and a
"What we need from the designer" block.

## Development

```sh
flutter run -d chrome   # local run
flutter analyze
flutter test            # opens every screen in every language
```

Every push to `main` builds the web app and deploys it to GitHub Pages
(`.github/workflows/deploy.yml`).

Adding a showcase, i18n rules and project conventions: see [CLAUDE.md](CLAUDE.md).
