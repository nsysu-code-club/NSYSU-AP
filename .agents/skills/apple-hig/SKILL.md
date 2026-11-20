---
name: apple-hig
description: Apple's Human Interface Guidelines, distilled into decision rules for agents. Use when designing, building, or reviewing an app, game, or UI for iOS, iPadOS, macOS, tvOS, visionOS, or watchOS — picking a component (sheet vs. alert vs. popover, tab bar vs. sidebar), sizing hit targets and type, choosing colors and materials (Liquid Glass), writing UI copy and button labels, laying out for adaptivity and Dynamic Type, handling permissions and privacy prompts, or checking whether something feels native to the platform. Also use for web or cross-platform UI that should feel Apple-native.
---

# Apple Human Interface Guidelines

Everything below is derived from Apple's Human Interface Guidelines (developer.apple.com/design/human-interface-guidelines), read in full. This file is the decision layer: the rules you need for most work, plus routing to the reference files when you need exact numbers or component detail.

**The through-line:** an interface feels at home on an Apple platform when it defers to content, behaves the way the system behaves, adapts to whatever the person has chosen (size, appearance, language, input), and never makes the person guess. Familiarity is not a constraint on originality — it's what buys you the attention to spend on the parts that are actually yours.

## How to use this skill

1. Read the **Non-negotiables** below. They apply to every task.
2. Identify what you're doing and load the matching reference:

| Task | Load |
|---|---|
| Targeting a specific device / "does this feel like a Mac app?" | [PLATFORMS.md](PLATFORMS.md) |
| Color, typography, layout, icons, materials, motion, accessibility, writing | [FOUNDATIONS.md](FOUNDATIONS.md) |
| Launching, onboarding, modality, search, settings, feedback, drag & drop, media | [PATTERNS.md](PATTERNS.md) |
| Choosing or configuring a specific control or view | [COMPONENTS.md](COMPONENTS.md) |
| Gestures, keyboard, pointer, eyes, Digital Crown, Apple Pencil, game controls | [INPUTS.md](INPUTS.md) |
| Siri, App Intents, generative AI, Apple Pay, Sign in with Apple, Wallet, HealthKit, widgets… | [TECHNOLOGIES.md](TECHNOLOGIES.md) |
| Reviewing existing UI | [CHECKLIST.md](CHECKLIST.md) |

3. When a rule below and a platform rule conflict, the platform wins. When Apple gives a number, use Apple's number — don't round it to something that "looks close."

## The eight design principles

Apple frames all of its guidance under eight principles. Use them to break ties, not to decorate a rationale.

- **Purpose** — make something meaningful. Every element earns its place by serving the product's reason to exist.
- **Agency** — let people do things their own way. Stay out of the way, don't lock people into flows, make mistakes recoverable.
- **Responsibility** — act in people's best interest. Collect the minimum, be transparent, anticipate misuse.
- **Familiarity** — build on what people know. Established patterns, applied consistently, with clear feedback.
- **Flexibility** — adapt to diverse contexts and needs. Accessibility from the start, multiple input methods, preserved context.
- **Simplicity** — be clear and direct. Simplicity isn't minimalism; it's a focused, hierarchical, well-labeled experience.
- **Craft** — care about every detail. Quality sets the tone; ship, then keep the bar high.
- **Delight** — make it human. Know the emotion you want, deliver it — but never at the cost of the task. *Delight is not decoration.*

## Non-negotiables

These are the rules that get violated most often and that most reliably make software feel non-native.

### Touch targets and spacing

| Platform | Default control size | Minimum control size |
|---|---|---|
| iOS, iPadOS | 44×44 pt | 28×28 pt |
| macOS | 28×28 pt | 20×20 pt |
| tvOS | 66×66 pt | 56×56 pt |
| visionOS | 60×60 pt | 28×28 pt |
| watchOS | 44×44 pt | 28×28 pt |

- Spacing matters as much as size. ~12 pt of padding around bezeled elements, ~24 pt around unbezeled ones.
- visionOS: place button *centers* at least 60 pt apart, ≥16 pt margin around each interactive item — the eye-hover effect needs room.
- Every custom button needs a press state. A button without one reads as broken.
- Respond on pointer-down for feedback, not on release.

### Type sizes

| Platform | Default | Minimum |
|---|---|---|
| iOS, iPadOS | 17 pt | 11 pt |
| macOS | 13 pt | 10 pt |
| tvOS | 29 pt | 23 pt |
| visionOS | 17 pt | 12 pt |
| watchOS | 16 pt | 12 pt |

- Avoid Ultralight, Thin, and Light weights. Prefer Regular, Medium, Semibold, Bold.
- If you use a thin custom font, go *larger* than the minimum.
- Minimize the number of typefaces. A custom face for headlines + system font for body/captions is the safe pattern.
- Support Dynamic Type (iOS, iPadOS, tvOS, visionOS, watchOS). Test at the largest accessibility size. Prioritize: raising body text size does not mean raising tab titles.

### Contrast

- Text up to 17 pt: **4.5:1** minimum. 18 pt or bold: **3:1** minimum.
- Dark Mode custom colors: aim for **7:1**, especially at small sizes.
- If you can't hit the minimum by default, you must at least respond to Increase Contrast.
- Never rely on color alone. Pair it with shape, icon, text, or position.

### Color

- Use system colors. They already have light, dark, and increased-contrast variants and adapt to vibrancy.
- Never hard-code system color values — Apple changes them between releases.
- Never redefine a semantic color's meaning (don't use `separator` as a text color).
- Supply light *and* dark variants for every custom color, even in a single-appearance app — Liquid Glass needs both.
- Colors read differently by culture (red = danger in some places, luck in others). Verify per locale.

### Appearance

- Don't offer an app-specific light/dark setting. Respect the systemwide choice, including Auto switching mid-session.
- A permanently dark appearance is legitimate only for immersive media (Stocks, media viewers).
- Test with Increase Contrast and Reduce Transparency on, separately and together.

### Motion

- Add motion purposefully. Don't animate frequent, routine interactions — the system already does the subtle work.
- Motion must never be the only channel. Pair with haptics, audio, text.
- Never make people wait for an animation before they can act.
- Honor Reduce Motion: tighten springs, track gestures directly, avoid z-axis depth animation, replace positional transitions with fades, avoid animating into and out of blurs.
- Dim Flashing Lights: respond to it if you play video.
- visionOS: no motion in the periphery, give a stationary frame of reference, never rotate the world, avoid ~0.2 Hz oscillation.

### Content-first layout

- Extend backgrounds and scrollable content to the screen edges. Controls float *above* content, not in the same plane.
- Respect safe areas and layout margins — Dynamic Island, camera housing, corner radii, tvOS overscan (inset 60 pt top/bottom, 80 pt sides).
- Reading order carries importance: most important content at the top and leading side. Account for RTL.
- Group related items; give essential information room.
- Progressive disclosure over cramming.
- Avoid full-width buttons in iOS; if you must, harmonize with the hardware corner radius.
- Never put critical controls at the bottom edge of a macOS window — people drag windows off-screen there.

### Liquid Glass

- Liquid Glass is the **functional layer**: controls and navigation floating above content. Don't use it *in* the content layer.
- Use it sparingly on custom controls. System components adopt it automatically.
- Two variants: **regular** (blurs and adjusts luminosity — the default, use for text-heavy elements: alerts, sidebars, popovers) and **clear** (highly translucent — only over rich media). With clear over bright content, add a ~35% dark dimming layer.
- Liquid Glass has no inherent color; it takes color from what's behind. Add color only for genuine emphasis (a primary action's background), and to at most one control in a view.
- If your content layer is colorful, prefer monochrome toolbars and tab bars.
- Use a **scroll edge effect** — not a background — to separate a bar from scrolling content. Prefer the automatic style. One per view.

### Writing

- Be clear, then be brief. Read it aloud.
- Buttons and links start with a verb: "Send", not "Let's do it!"; "Learn more about X", not "Click here."
- Use *you*/*your*. Avoid *we* (especially in errors — "Unable to load content" beats "We're having trouble…").
- Drop unnecessary possessives: "Favorites" ≥ "Your Favorites."
- Pick title case or sentence case per element type, then be consistent. Title case for button labels and menu items; sentence case for descriptions and tooltips.
- Errors: say what to do, not what went wrong. "Choose a password with at least 8 characters" beats "That password is too short" beats "Invalid password." No "Oops."
- Match the verb to the device: *tap* on touch, *click* on Mac, *choose* when it could be either.
- Avoid jargon, colloquialisms, and humor — all three translate badly and exclude people.
- Avoid unnecessary gendered language. "Subscribers can post recipes" beats "a subscriber can post his or her recipes."
- Don't localize Apple trademarks. Never make them plural or possessive.

### Privacy and permissions

- Request access only to data you actually need, at the moment the feature needs it — not at launch, unless the app can't function without it.
- Purpose strings: one complete sentence, active voice, sentence case, ending period, stating *how and why*. "The app records during the night to detect snoring sounds." Not "Microphone access is needed for a better experience."
- A pre-alert screen may have exactly **one** button, labeled Continue or Next — never Allow, never a Cancel/close option, never an incentive, never an imitation of the system alert. These get apps rejected.
- Process on device when you can. Store secrets in the keychain, never in plain text.
- Prefer passkeys and Sign in with Apple over inventing an auth scheme.
- If you let people create an account in-app, you must let them *delete* it in-app (or link directly to the page that does).

### Accessibility (not optional, not a phase)

- **Perceivable**: never a single channel. Captions/subtitles/transcripts/audio descriptions for media. Haptics alongside audio cues. Visual cues alongside audio cues.
- **Adaptable**: Dynamic Type, Increase Contrast, Reduce Motion, Reduce Transparency, Bold Text, Full Keyboard Access, Switch Control, Voice Control, VoiceOver, Assistive Access.
- **Operable**: simplest gesture that works; always offer a non-gesture alternative (a swipe-to-delete needs a button too); avoid time-boxed, auto-dismissing UI.
- **Labeled**: alternative text for every meaningful image, icon, and custom symbol; exclude decorative images; group related elements so VoiceOver reads them together; announce layout and content changes.
- Charts need per-element accessibility labels (or per-group), plus Audio Graphs where possible.
- Audit with Accessibility Inspector. Declare support with Accessibility Nutrition Labels.

## Fast decision tables

### Which container?

| You need to… | Use |
|---|---|
| Deliver critical, actionable information that must interrupt | **Alert** |
| Offer choices related to an action the person just took | **Action sheet** / confirmation dialog |
| Have them complete one scoped task and come back | **Sheet** |
| Show a small amount of related info/functionality, transiently | **Popover** |
| Provide supplementary controls alongside the main window (macOS) | **Panel** / inspector |
| Support a self-contained task in parallel | **New window** (iPadOS, macOS, visionOS) |
| Provide an immersive, distraction-free view | **Full-screen mode** (iOS/iPadOS/macOS) or a **Full Space** (visionOS) |

- Never show two modal views at once. Never cascade popovers. An alert may sit above anything — but only one alert.
- Always provide an obvious dismissal, following platform convention (top toolbar button or swipe-down on iOS/iPadOS/watchOS; in-content button on macOS/tvOS).
- Confirm before dismissing anything that would lose user-generated content.

### Navigation vs. action

| Bar | Purpose |
|---|---|
| **Tab bar** | Navigate between top-level sections. Never actions. Always visible. Never disable a tab. |
| **Sidebar** | Navigate between areas or top-level collections when there's room. ≤2 levels of hierarchy. |
| **Toolbar** | Act on the current view, plus title, navigation, and search. |

- iPadOS: don't choose — use a tab bar that converts to a sidebar (`sidebarAdaptable`).
- Toolbar item groups: leading (back, sidebar, title, document menu), center (customizable, overflows), trailing (search, inspector, More, one prominent primary action). Max ~3 groups.
- Every macOS toolbar item must also exist as a menu bar command. Not vice versa.

### Menu-bearing controls

| Control | For |
|---|---|
| **Pop-up button** | Flat list of mutually exclusive options; shows current selection |
| **Pull-down button** | Actions related to the button's own purpose; supports submenus and multi-select |
| **Context menu** | Frequently used actions for a specific item; hidden, so must be duplicated elsewhere |
| **Edit menu** | Selection-scoped commands (Copy, Look Up, Translate). Prefer the system one. |

- Menu labels: verb or verb phrase, title case, no articles, ellipsis when more input is required.
- Group logically with separators; ≤~3 groups in a context menu; ≤1 level of submenu; ≤5 items in a submenu.
- Dim unavailable items in a regular menu; *hide* them in a context menu.
- Icons in menus: use them for the most common actions, and either give every item in a group an icon or none.

### Progress and status

- Determinate whenever you can know the duration. Even out the pace — 90% in five seconds then 10% in five minutes reads as deceptive.
- Never switch a spinner into a bar or vice versa.
- Keep indicators moving; a stationary one reads as a hang.
- Offer Cancel when interruption is safe; add Pause when it isn't.
- watchOS: avoid indeterminate indicators entirely — promise a notification instead.

## Common failure modes

- Building the iPhone layout and scaling it. Each platform's ergonomics, viewing distance, and input model are different; see PLATFORMS.md.
- Using an alert for something informational. Use inline status.
- Hiding a primary action inside a "More" menu.
- Two prominent buttons in one view (keep it to one, at most two).
- A destructive action assigned the primary role so Return triggers it.
- Building a custom control that behaves *almost* like the system one.
- Custom effects on an app icon — the system draws highlights, shadows, blurs, and refraction; yours will fight them.
- Text baked into an icon, an App Clip card image, a pass image, or a launch screen — none of it localizes or scales.
- Requesting permissions at launch "to get it out of the way."
- Treating Dynamic Type, RTL, and VoiceOver as a post-ship pass.

## Source

Distilled from the complete Human Interface Guidelines: <https://developer.apple.com/design/human-interface-guidelines>. Apple revises the HIG continuously; when a detail matters, verify against the live page.
