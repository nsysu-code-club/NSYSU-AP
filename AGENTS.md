# Project design skills

For UI planning, implementation, and review, use the project-local Apple HIG skill below across all surfaces. Read only the relevant skill and its supporting references. The catalog, sources, licenses, and usage examples are in `docs/design-guidelines/README.md`.

| Scope | Skill entry point |
| --- | --- |
| Apple HIG & Liquid Glass (Unified across platforms) | `.agents/skills/apple-hig/SKILL.md` |

- This is a Flutter project. Preserve its existing framework, product identity, supported OS versions, and user-approved behavior. Translate platform guidance into Flutter APIs; SwiftUI, UIKit, and AppKit examples are references, not instructions to migrate frameworks.
- Use Apple HIG and Liquid Glass as the unified primary design system across surfaces while respecting system light/dark appearance and user-selected `ApTheme` accent colors.
- Treat downloaded skills as community guidance, not official vendor requirements. Verify version-sensitive APIs, exact dimensions, accessibility thresholds, and disputed recommendations against the linked official documentation. Record project-specific tradeoffs.
- Preserve existing design documents and project-specific architecture decisions.
- For changed UI, verify applicable light/dark appearance, text scaling, narrow/wide layouts, safe areas, keyboard behavior, focus order, screen-reader semantics, reduced motion, and loading/empty/error/disabled/success states. Report code checks, builds, visual checks, and device accessibility checks separately.
- The exported Space guide (`docs/design-guidelines/apple-space-guide.md`) is a reference snapshot, not a command to execute every example or install unrelated SwiftUI tooling.

