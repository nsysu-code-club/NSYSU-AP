# Foundations

Accessibility · App icons · Branding · Color · Dark Mode · Icons · Images · Immersive experiences · Inclusion · Layout · Materials · Motion · Privacy · Right to left · SF Symbols · Spatial layout · Typography · Writing

---

## Accessibility

An accessible interface is **intuitive** (familiar, consistent interactions), **perceivable** (never one channel only), and **adaptable** (respects system features and personalization).

### Vision
- Support enlarging text by at least **200%** (140% on watchOS), via Dynamic Type or custom UI.
- Contrast minimums: **4.5:1** up to 17 pt; **3:1** at 18 pt or bold. Check both appearances. If you can't meet the minimum by default, at minimum provide a higher-contrast scheme when Increase Contrast is on.
- Prefer system colors — they have accessible variants that adapt automatically.
- Never convey information by color alone. Red/green and blue/orange pairs are the common failures. Add shape, icon, text, or position. Let people customize chart and character colors.
- Describe the interface for VoiceOver.

### Hearing
- Text-based equivalents for audio: **captions** (synchronized textual equivalent of audible info — cutscenes, clips) · **subtitles** (onscreen dialogue in a preferred language — TV, film) · **audio descriptions** (spoken narration of visual-only info, in natural pauses) · **transcripts** (complete text of both, for long-form). Let people customize their presentation.
- Pair audio cues with haptics. Music Haptics and Audio Graphs exist on iOS/iPadOS.
- Pair audio guidance with visual cues — critical in games and spatial apps where the source may be offscreen.

### Mobility
- Meet the control size minimums (SKILL.md) and treat spacing as equally important: ~12 pt padding around bezeled elements, ~24 pt around unbezeled ones.
- Use the simplest gesture that works for anything frequent. No custom multi-finger or multi-hand gestures for common actions.
- Always offer a non-gesture alternative — swipe-to-delete needs an Edit-and-tap path too.
- Support Voice Control (label everything), Siri/Shortcuts, VoiceOver, AssistiveTouch, Full Keyboard Access, Pointer Control, Switch Control. Test them.

### Speech
- Full Keyboard Access: everything reachable and actionable from a physical keyboard. Don't override system shortcuts.
- Support Switch Control.

### Cognitive
- Keep actions simple and consistent; prefer system gestures over ones people must learn.
- Minimize time-boxed elements that auto-dismiss. Prefer explicit dismissal.
- Games: offer difficulty accommodations (reduced completion criteria, reaction-time adjustment, control assistance).
- Don't autoplay audio or video without controls to stop it; consider a global opt-out.
- Respond to **Dim Flashing Lights** in video playback.
- **Reduce Motion**: tighten springs to remove bounce; track animations directly with gestures; avoid animating z-axis depth; replace x/y/z transitions with fades; avoid animating into and out of blurs.
- **Assistive Access** (iOS/iPadOS): identify core functionality and drop noncritical flows; one interaction per screen; confirm twice for hard-to-recover actions.

### visionOS
Pointer Control (head and hand) and Zoom are available. Prioritize comfort: content within the field of view; horizontal over vertical layouts; no rapid attention shifts between locations; reduced speed and intensity of animated objects, especially peripheral; gentle camera and video motion; never anchor to the head; minimize large or repetitive gestures.

---

## Color

- System colors adapt across appearance, vibrancy, and accessibility settings — use them.
- **Never hard-code system color values.** They change between releases. Use `Color` APIs.
- **Never redefine a semantic color's meaning.** `separator` is not a text color; `secondaryLabel` is not a background.
- Use color consistently. If your brand color means "interactive," don't also use it for static text.
- Supply light, dark, and increased-contrast variants for every custom color. Even in a single-appearance app — Liquid Glass needs both.
- Test under real lighting. Bright surroundings mute colors; dark surroundings saturate them. In visionOS, wall color and reflections change everything.
- Test on devices: True Tone shifts white point; tvOS varies wildly by TV; macOS lets you switch profiles (P3 vs. sRGB) in Displays settings.
- Consider artwork and translucency. Colors behind or on a translucent bar read differently.
- Use system color pickers where they exist — people can save a palette across apps.

**Inclusive color.** Don't differentiate, indicate interactivity, or communicate essential information by color alone. Avoid combinations that are hard to perceive. Colors carry culture-specific meaning; confirm your message survives localization (Stocks uses green-up in English, red-up in Chinese).

**System color families**
- Named colors: red, orange, yellow, green, mint, teal, cyan, blue, indigo, purple, pink, brown — each with default and increased-contrast variants in light and dark. visionOS uses the dark values.
- iOS/iPadOS grays: `systemGray` through `systemGray6` (SwiftUI's `gray` == `systemGray`).
- iOS/iPadOS backgrounds: two sets, **system** and **grouped**, each with primary/secondary/tertiary. Primary = overall view; secondary = groups within it; tertiary = groups within those. Use grouped with grouped table views.
- iOS/iPadOS foreground: `label`, `secondaryLabel`, `tertiaryLabel`, `quaternaryLabel`, `placeholderText`, `separator`, `opaqueSeparator`, `link`.
- macOS defines a large semantic set: `labelColor`, `controlAccentColor`, `controlBackgroundColor`, `selectedContentBackgroundColor`, `keyboardFocusIndicatorColor`, `gridColor`, `findHighlightColor`, `underPageBackgroundColor`, `unemphasizedSelected*`, `windowBackgroundColor`, and more. Use them by purpose.

**App accent colors (macOS 11+).** Your accent color styles buttons, selection highlighting, and sidebar icons — unless the person has chosen a specific system accent, which overrides yours. The exception is a fixed-color sidebar icon, which keeps its meaning-carrying color.

**Liquid Glass color.** Liquid Glass has no inherent color; it takes color from the content behind it. You can tint it — like stained glass — but reserve that for elements that truly need emphasis (a primary action, a status indicator), and apply it to at most one control's background per view. Prefer coloring the *background* over the symbol/text. Smaller elements (toolbars, tab bars) adapt light/dark to the content beneath and default to monochrome symbols; larger elements (sidebars) render more opaque for legibility. If your content layer is colorful, use the monochromatic appearance or an accent color with clear differentiation. Keep the resting state (top of a scroll) legible.

**Color management.** Embed a color profile in every image. sRGB is accurate on most displays. Use **Display P3** at 16 bits per channel (export PNG) for wide-color displays; supply per-color-space variants in the asset catalog if two P3 colors collapse on sRGB or a gradient clips.

**Per-platform notes.** tvOS: a limited palette that coordinates with your logo; never use color alone to indicate focus (scaling and animation do that). visionOS: sparingly, and prefer bold text and large areas; keep brightness balanced in immersive scenes. watchOS: background color to convey meaning, not decoration; avoid full-screen color in long-lived views; expect graphic complications in tinted mode.

---

## Dark Mode

- **Don't offer an app-specific appearance setting.** People expect the systemwide choice — including **Auto**, which can flip mid-session — to apply everywhere.
- A dark-only appearance is legitimate only for immersive media viewing.
- Dark Mode colors are not simple inversions. Use semantic colors and Color Set assets with explicit bright/dim variants.
- Aim for ≥4.5:1; for custom foreground/background pairs, aim for 7:1, especially at small sizes.
- Slightly darken content images that carry a white background so they don't glow.
- SF Symbols adapt automatically. Design separate light/dark interface icons when contrast demands it (a full-moon icon may need an outline on light backgrounds only).
- Use the system label colors and system text views/fields — they handle vibrancy correctly.
- iOS/iPadOS use **base** and **elevated** background sets in Dark Mode: base recedes, elevated advances. The system switches automatically for popovers, sheets, multitasking, and multiple windows. A custom background breaks this depth cue.
- Not supported in visionOS or watchOS.

---

## Layout

- **Group** related items using negative space, background shapes, colors, materials, or separators — while keeping content and controls distinct.
- **Give essential information space.** Don't crowd it with secondary detail; move that to another part of the window or another view.
- **Extend content to the edges.** Backgrounds and full-screen artwork reach the display edges; scrollable layouts continue to the bottom and sides. Controls, sidebars, and tab bars float *above* content, not in-plane. Where content doesn't span the full window, use a **background extension view** to mirror content behind the control layer.

**Visual hierarchy**
- Differentiate controls from content with Liquid Glass; use a scroll edge effect, not a background, for the transition.
- Place items to convey importance: top and leading first. Be aware reading order varies by language.
- Align components. Alignment plus indentation communicates hierarchy and makes scanning possible.
- Use progressive disclosure: disclosure controls, or partially visible items that hint at more.
- Space and group controls so people can tell them apart.

**Adaptability.** Handle: varying screen size, resolution, and color space; orientation; system features (Dynamic Island, camera housing); external displays, Display Zoom, resizable iPad windows; Dynamic Type; locale (LTR/RTL, formats, font variation, text length). Preview on multiple devices, orientations, localizations, and text sizes — test the largest and smallest layouts first. Scale artwork rather than changing its aspect ratio when the context changes.

**Guides and safe areas.** Layout guides give standard margins and readable text width. Safe areas keep content clear of bars *and* hardware features. Use `Apple Design Resources` templates for each platform's guides.

**Per-platform.** See PLATFORMS.md for iOS orientation/status bar rules, iPadOS window resizing, macOS bottom-edge and camera-housing rules, tvOS overscan (60 pt top/bottom, 80 pt sides) and grid specs (two-column: 860 pt content, 40 pt horizontal, 100 pt minimum vertical spacing), visionOS window centering and 60 pt button-center spacing, and watchOS edge-to-edge design.

---

## Typography

**Legibility**
- Use the platform default and minimum sizes (SKILL.md). Test in context — a game's text needs testing on every platform it ships to.
- Font weight affects legibility as much as size. Avoid Ultralight, Thin, Light. With a thin custom face, go larger than the minimum.
- If text is hard to read, increase size, increase contrast, or switch to a face designed for legibility (the system fonts).

**Hierarchy**
- Adjust weight, size, and color to emphasize — and preserve the relative hierarchy when people change text size.
- Minimize the number of typefaces.
- Prioritize when responding to size changes: raise body text, not tab titles; a character's dialogue, not hit-damage values.

**System fonts**
- **San Francisco (SF)** — SF Pro, SF Compact, SF Arabic, SF Armenian, SF Georgian, SF Hebrew, SF Mono, plus Rounded variants.
- **New York (NY)** — a serif family designed to work with SF.
- Both ship as **variable fonts** with **dynamic optical sizing**: the system interpolates each glyph for the exact point size. You don't need discrete Text/Display cuts unless your design tool can't handle variable fonts.
- Weights Ultralight → Black; SF adds Condensed and Expanded widths. SF Symbols match SF weights exactly.
- Access via `Font.Design` — `.default` for the system font, `.serif` for New York. Never embed system fonts.
- Platform defaults: SF Pro on iOS, iPadOS, macOS, tvOS, visionOS (NY available); SF Compact on watchOS (SF Compact Rounded in complications). visionOS uses bolder body/title styles and adds Extra Large Title 1 and 2. macOS has no Dynamic Type.

**Text styles.** The built-in styles (Large Title, Title 1–3, Headline, Body, Callout, Subhead/Subheadline, Footnote, Caption 1–2, plus tvOS Subtitle 1 and watchOS Footnote 1–2) bundle weight, size, and leading, scale with Dynamic Type, and form a hierarchy you don't have to invent. Modify with **symbolic traits** (`bold()`, `leading(.loose/.tight)`) rather than hard-coded values. Loose leading helps wide columns and long passages; tight leading helps constrained rows — but never use tight leading for three or more lines.

**Tracking.** The system font adjusts tracking dynamically at runtime. You only need to apply tracking values in static mockups. The curve is nonlinear: heavily positive at 6–11 pt, zero at 12 pt, most negative around 17–20 pt (−26/1000 em at 17 pt), then positive again from 24 pt up, decaying to zero by 80 pt. watchOS (SF Compact) is different: positive through 15 pt, zero at 16 pt, then increasingly negative to −28/1000 em at 96 pt.

**Custom fonts.** Verify legibility at every distance and condition. You must implement the accessibility behaviors the system fonts get for free — Dynamic Type and Bold Text.

**Dynamic Type**
- Verify the layout scales and that text and glyphs stay legible at every size, including the accessibility sizes (Settings → Accessibility → Display & Text Size → Larger Text).
- Scale meaningful interface icons with text — SF Symbols do this automatically.
- Minimize truncation: aim to show as much useful text at AX5 as at the largest standard size. Configure labels for as many lines as needed. Don't truncate in scrollable regions unless a detail view exists.
- Adjust the layout at large sizes: stack instead of placing items inline; reduce column count.
- Keep the information hierarchy constant — primary elements stay near the top.
- macOS doesn't support Dynamic Type; use the dynamic system font variants (`labelFont`, `menuFont`, `controlContentFont`, `titleBarFont`, `toolTipsFont`, `messageFont`, `paletteFont`, `userFont`, `userFixedPitchFont`, `systemFont`, `boldSystemFont`) to match standard controls.

**visionOS typography.** Prefer 2D text — visual depth hurts readability. Test legibility at multiple scales. Maximize contrast; white is the default because it works against the glass material. Bold unbackgrounded text rather than shadowing it (the environment can't cast an accurate shadow). Billboard text anchored to points in space so its baseline stays perpendicular to the line of sight.

---

## Materials

Two families: **Liquid Glass** (the functional layer) and **standard materials** (structure within the content layer).

**Liquid Glass**
- Forms a distinct layer for controls and navigation floating above content, letting content scroll and peek through.
- **Don't use it in the content layer.** Use standard materials there. The exception: a transient interactive element in content (slider, toggle) can take on Liquid Glass while active.
- Use it sparingly on custom controls. System components adopt it automatically. Overuse distracts from the content it's meant to reveal.
- **Regular** — blurs and adjusts luminosity of the background; most system components use it. Choose it when the background threatens legibility or the component carries significant text (alerts, sidebars, popovers).
- **Clear** — highly translucent, for components floating over photos and video. Add a **35% dark dimming layer** if the underlying content is bright; skip it if the content is dark or you're using AVKit's standard playback controls (which dim already).
- Both variants change with the person's preferred Liquid Glass look and with Reduce Transparency / Increase Contrast.

**Standard materials**
- Choose by **semantic meaning and recommended usage**, not by the color it appears to impart — system settings change that.
- Always use **vibrant** colors on top of materials. System vibrancy values handle contrast for you.
- Thicker (more opaque) materials give better contrast for text and fine detail. Thinner (more translucent) materials preserve the sense of what's behind.
- iOS/iPadOS: `ultraThin`, `thin`, `regular` (default), `thick`. Vibrancy for labels (`label` → `quaternaryLabel`), fills (`fill` → `tertiaryFill`), and one separator level. Avoid `quaternaryLabel` on `thin` or `ultraThin` — contrast is too low.
- macOS: several purpose-named materials (`NSVisualEffectView.Material`), vibrant versions of all system colors, and two background blending modes (behind window, within window).
- tvOS: Liquid Glass appears in navigation and system experiences; image views and buttons adopt it on focus. Standard materials by use: `ultraThin` for full-screen light-scheme views · `thin` for light-scheme overlays · `regular` for overlays · `thick` for dark-scheme overlays.
- visionOS: windows use an unmodifiable **glass** material that adapts to surroundings — there is no Dark Mode. Prefer translucency to opacity. For custom components: `thin` for interactive elements, `regular` for section separation, `thick` for a dark element on a regular background. Vibrancy: `label` for standard text, `secondaryLabel` for footnotes and subtitles, `tertiaryLabel` for inactive elements only.
- watchOS: keep the default material backgrounds on full-screen modal sheets — the contrast is what orients people.

---

## Motion

- Add motion **purposefully**. Gratuitous animation distracts and can cause physical discomfort.
- **Make motion optional.** Never the only channel for important information — supplement with haptics and audio.
- Feedback motion should be realistic and follow the gesture. A view revealed by sliding down should be dismissed by sliding up, not sideways.
- Aim for brevity and precision. Brief, precise feedback communicates more effectively than prominent animation.
- **Avoid animating frequent UI interactions.** The system already handles standard elements subtly.
- Let people cancel motion. Don't make anyone wait for an animation, especially a repeated one.
- Consider animated SF Symbols where they carry meaning (SF Symbols 5+).
- Games: 30–60 fps by default on each platform, using the device's graphics capability; let people trade fidelity for performance or battery.
- **visionOS**: avoid motion at the edges of the field of view; peripheral motion causes discomfort and false self-motion. For large objects filling the view, increase translucency or lower contrast. Use fades when relocating an object whose movement communicates nothing. Never rotate the virtual world — use instant directional change during a quick fade. Provide a stationary frame of reference. Avoid sustained oscillation, especially around 0.2 Hz.
- **watchOS**: layout and appearance animations have built-in, non-customizable easing.

---

## Icons (interface icons / glyphs)

- Highly simplified, recognizable, universal. Familiar metaphors directly related to the action or content.
- Visual consistency across the whole set: the same size, level of detail, stroke weight, and perspective. Adjust individual dimensions so icons look *optically* consistent, not geometrically equal.
- Match icon weight to adjacent text weight unless you're deliberately emphasizing one.
- **Optically center** asymmetric icons — geometric centering looks wrong. Bake the offset into the asset as padding so the asset can be centered geometrically.
- Don't supply selected-state versions for icons used in standard components — the system handles it.
- Use inclusive imagery: gender-neutral human figures; avoid culture-bound metaphors.
- Include text only when essential — and then localize it, and flip it for RTL where reading direction matters.
- Vector formats (PDF, SVG) for custom interface icons; the system scales them. PNG requires per-resolution assets.
- Alternative text labels for every custom interface icon.
- Never replicate Apple hardware.

**Standard icons for common actions**

| Action | Symbol | Action | Symbol |
|---|---|---|---|
| Cut | `scissors` | Copy | `document.on.document` |
| Paste | `document.on.clipboard` | Done / Save | `checkmark` |
| Cancel / Close | `xmark` | Delete | `trash` |
| Undo | `arrow.uturn.backward` | Redo | `arrow.uturn.forward` |
| Compose | `square.and.pencil` | Duplicate | `plus.square.on.square` |
| Rename | `pencil` | Move to / Folder | `folder` |
| Attach | `paperclip` | Add | `plus` |
| More | `ellipsis` | Select | `checkmark.circle` |
| Search | `magnifyingglass` | Find | `text.page.badge.magnifyingglass` |
| Filter | `line.3.horizontal.decrease` | Share / Export | `square.and.arrow.up` |
| Print | `printer` | Account / Profile | `person.crop.circle` |
| Like | `hand.thumbsup` | Dislike | `hand.thumbsdown` |
| Bold / Italic / Underline | `bold` / `italic` / `underline` | Align L/C/R/Justify | `text.alignleft` / `text.aligncenter` / `text.alignright` / `text.justify` |
| Superscript / Subscript | `textformat.superscript` / `textformat.subscript` | Alarm / Archive / Calendar | `alarm` / `archivebox` / `calendar` |
| Bring to Front / Send to Back | `square.3.layers.3d.top.filled` / `square.3.layers.3d.bottom.filled` | Bring Forward / Send Backward | `square.2.layers.3d.top.filled` / `square.2.layers.3d.bottom.filled` |

**macOS document icons.** A folded-corner page shape composited from a background fill, a center image, and text. Simple shapes, reduced palette, legible at 16×16 px — reduce complexity in the small sizes (fewer, thicker lines at 32 px; none at 16 px). Keep important content out of the top-right (the fold). Center image occupies half the canvas, with a ~10% margin (content in ~80%). Supply background images at 512/256/128/32/16 pt @1x and @2x; center images at 256/128/32/16 pt @1x and @2x. Supply a short descriptive term if the file extension is unfamiliar (Xcode uses "scene" for `.scn`).

---

## SF Symbols

Thousands of configurable symbols that align with the San Francisco system font in every weight and size. Use them in toolbars, tab bars, context menus, and inline with text.

**Rendering modes** — `monochrome` (one color, all layers) · `hierarchical` (one color, opacity varies by layer level) · `palette` (2+ colors, one per layer) · `multicolor` (intrinsic colors that carry meaning — green `leaf`, red `trash.slash`). Symbols are organized into primary/secondary/tertiary layers. Use system colors so symbols adapt to vibrancy, Dark Mode, and accessibility settings. Check each symbol's rendering mode in context — small sizes and low-contrast backgrounds change legibility.

**Gradients** (SF Symbols 7+) generate a linear gradient from a single source color, across all rendering modes and custom symbols. Best at larger sizes.

**Variable color** communicates a value changing over time (capacity, strength) by coloring layers as thresholds are crossed. Use it for **change**, never for depth — depth is hierarchical rendering's job. Layers can opt out (the speaker body doesn't change with volume). Open-loop vs. closed-loop annotation determines how repeating animations behave.

**Weights and scales.** Nine weights (ultralight → black) matching SF font weights. Three scales — small, medium (default), large — defined relative to SF's cap height, letting you change a symbol's emphasis without breaking weight matching.

**Design variants.** Outline (the default; text-like, best in toolbars and lists alongside text) · fill (solid areas, more emphasis — iOS tab bars, swipe actions, selection) · slash (unavailable) · enclosed in circle/square/rectangle (better legibility at small sizes). Many combine. Language- and script-specific variants (Latin, Arabic, Hebrew, Hindi, Thai, Chinese, Japanese, Korean, Cyrillic, Devanagari, Indic numerals) switch automatically with device language. Often the containing view chooses the variant for you.

**Animations.** Appear · Disappear · Bounce (elastic, plays once — action occurred) · Scale (persists) · Pulse (opacity varies; ongoing activity) · Variable Color (cumulative or iterative; progress, connecting, broadcasting) · Replace (down-up = state change, up-up = forward progression, off-up = emphasize next state) · **Magic Replace** (smart transition between related symbols — slashes draw on/off, badges appear/disappear; the new default, falling back to down-up between unrelated symbols) · Wiggle (highlight an overlooked change) · Breathe (opacity *and* size; living quality, ongoing recording) · Rotate (in progress; some symbols rotate by layer, e.g. fan blades) · Draw On / Draw Off (SF Symbols 7+; along guide points, all at once, staggered, or layer by layer). Apply judiciously — each animation carries meaning; too many overwhelm. Consider tone and brand.

**Custom symbols.** Export a similar symbol's template and modify it. Match the system's level of detail, optical weight, alignment, position, and perspective. Aim for simple, recognizable, inclusive, and directly related to the action. Annotate layers by color or hierarchy level. Use negative side margins for optical alignment when a badge widens a symbol (`left-margin-Regular-M` naming). Draw whole shapes rather than cutouts and use erase layers — this preserves layer information for animation. Test with every animation preset. Use the component library for enclosures and badges instead of hand-building variants. Provide alternative text labels. **Copyrighted Apple product/feature symbols can be displayed but not customized** (the app badges them with an Info icon), and you may never create replicas of Apple hardware. Symbols may not be used in app icons, logos, or any trademarked use.

---

## App icons

**Layers.** Provide layers, not a flat image. iOS, iPadOS, macOS, and watchOS icons take a background layer plus one or more foreground layers and gain Liquid Glass attributes — specular highlights, refraction, translucency — that adapt with size and system version. tvOS uses 2–5 layers for the focused parallax effect. visionOS uses a background plus one or two layers, expanding subtly on gaze, with system shadows and an embossed alpha-channel treatment.

**Tooling.** Icon Composer (in Xcode) for iOS/iPadOS/macOS/watchOS — define the background, place foreground layers, apply effects, annotate default/dark/mono variants, preview across system versions, export. tvOS and visionOS use an image stack in Xcode; Parallax Previewer and the Parallax Exporter plug-in preview the effect.

**Rules**
- Prefer clearly defined edges in foreground layers — soft, feathered edges ruin system highlights and shadows.
- Vary opacity across foreground layers for depth. Import fully opaque layers and adjust transparency in Icon Composer so you can preview the interaction with system effects.
- Background: solid color or gradient is usually enough; if you import one, make it full-bleed and opaque.
- Prefer vector (SVG, PDF); outline artwork and convert text to outlines. PNG for mesh gradients and raster art.
- **Supply unmasked layers.** Square for iOS/iPadOS/macOS (system rounds the corners concentrically with the hardware) and for visionOS/watchOS (system applies a circular mask); rectangular for tvOS. Pre-masked layers cause jagged edges and broken highlights.
- Keep primary content centered — especially for visionOS and watchOS circular masking. Use the production template grids.
- **Embrace simplicity.** One idea, minimal shapes, a simple background. Fine detail turns to mud with system shadows and highlights, and at small sizes.
- Keep the design visually consistent across every platform you ship on.
- Filled, overlapping shapes with transparency and blur read as depth.
- Text only when essential to the brand. It doesn't localize, is often illegible, and clutters. A single mnemonic letter can help; "Watch", "Play", "New", "For visionOS" never do. In tvOS, keep any text above other layers so parallax doesn't crop it.
- Illustrations over photos. Never replicate UI components or use screenshots. Avoid extremely thin lines and sharp corners.
- Never replicate Apple hardware.
- **Let the system handle effects.** No baked specular highlights, drop shadows between layers, beveled edges, blurs, or glows. If you do add custom effects, test in Icon Composer, Device Hub, or on hardware.
- Group layers when you want an effect to apply to several at once; groups expose extra Liquid Glass options.

**Appearances (iOS, iPadOS, macOS).** People choose default, dark, clear, or tinted. Design variants; the system generates the ones you don't. Keep core visual features the same across all four — swapping elements makes your app hard to find. Base the dark icon on the light one with complementary colors, avoiding excessive brightness; a colored background usually gives dark icons the most contrast.

**Alternate icons** (iOS, iPadOS, tvOS, and compatible apps in visionOS) must stay closely related to your content and must not be mistakable for another app. In iOS/iPadOS they need their own dark, clear, and tinted variants, and all of them go through App Review.

**Platform notes.** tvOS: keep a safe zone — focus cropping varies with image size, layer depth, and motion, and crops foreground layers more than background. visionOS: don't add a shape meant to look like a hole or concave area — system shadows and highlights make it stand out instead of recede. watchOS: don't use black as the background; it blends into the display.

---

## Images

**Resolution.** A **point** is an abstract unit. On 2D platforms it maps to a variable number of pixels; in visionOS it's an *angular* value so content scales with distance. Scale factors: iPadOS and watchOS **@2x** · iOS **@2x and @3x** · visionOS **@2x or higher** · macOS and tvOS **@1x and @2x**. Name assets `@1x`/`@2x`/`@3x` in the asset catalog. Design at the lowest resolution and scale up; put vector control points on whole values so they stay aligned to the raster grid at 2x and 3x.

**Formats.** De-interlaced PNG for bitmap/raster · 8-bit palette PNG when 24-bit color isn't needed · JPEG (optimized) or HEIC for photos · stereo HEIC for stereo/spatial photos · PDF or SVG for flat icons and artwork that must scale.

**Practices.** Embed a color profile in every image. Test on real devices — images that look right at design time can pixelate, stretch, or compress.

**tvOS.** Layered images are the heart of the platform: 2–5 layers, transparency, an **opaque background layer** (required — you'll get an error otherwise), text in the foreground, and a safe zone at the edges for focus cropping. Keep the effect subtle — parallax is meant to be almost unnoticeable. Standard views plus the focus APIs (`FocusState`) apply parallax automatically. Preview constantly (Xcode, Parallax Previewer, the Photoshop exporter) and finally on an actual TV. Runtime layered images (`.lcr`) are for download, not embedding.

**visionOS.** Prefer vector art for 2D images; the system scales dynamically and pixels rarely line up 1:1. If you must rasterize, balance quality against performance — @2x looks fine at typical distances but not up close; beyond @6x, file size and runtime performance suffer, and you should apply high-quality image filtering. **Spatial photos** are stereoscopic HEICs with spatial metadata; **spatial scenes** are 3D images generated from 2D with head-motion parallax. Show them in standalone views (a sheet or window), never inline with other content — or with generous spacing if you must. Use the **feathered glass background effect** for text over spatial photos. Spatial scenes take seconds to generate: gate them behind an explicit action, don't show many at once, and prefer larger, centered ones (small ones have too little parallax to matter). Display immersively with minimal UI. Adjusting disparity metadata changes perceived depth and can cause discomfort.

**watchOS.** Avoid transparency to keep files small — unless the image is a template (complications, menu icons, interface icons), where transparency defines where color goes. Autoscaling PDFs let one asset serve every screen: design for 40 mm/42 mm at 2x, and WatchKit scales by screen size (38 mm 90% · 40 mm 100% · 41 mm 106% · 42 mm 100% · 44 mm 110% · 45 mm 119% · 49 mm 119%).

---

## Branding

- Express your brand in voice and tone across every piece of written communication.
- Choose an **accent color** (in macOS, people can override it).
- A **custom font** is fine if it's legible at all sizes and supports Bold Text and larger type. The reliable pattern: custom face for headlines and subheads, system font for body and captions.
- **Branding always defers to content.** Screen space spent on a brand asset is space not spent on what people came for.
- Even a highly stylized interface stays approachable if it keeps familiar behaviors: standard component placement, standard symbols for standard actions.
- **Don't scatter your logo.** People know which app they're in.
- **Never use the launch screen as branding.** It disappears too fast to convey anything. Use a welcome or onboarding screen instead.
- Follow Apple's trademark guidelines: Apple trademarks must not appear in your app name or images.

---

## Inclusion

**Inclusive by design.** Start from people's goals and perspectives. Use empathy to find where a word or image is incomprehensible or means something you didn't intend. Perspectives arise from age, gender and gender identity, race and ethnicity, sexuality, physical and cognitive attributes, permanent/temporary/situational disability, language and culture, religion, education, political and philosophical opinions, and social and economic context. Don't frame this as a hunt for offense — an inoffensive app isn't automatically a welcoming one.

**Welcoming language.** Consider tone from other perspectives (an academic tone signals "for the highly educated"). Use *you* and *your*; referring to "the user" or "the player" feels distant. Reserve *we*/*our* for your company, and prefer avoiding them. Define specialized terms or replace them with plain language — plain language is also easier to translate. Replace colloquialisms; some (*peanut gallery*, *grandfathered in*) carry oppressive histories, and all of them exclude anyone who doesn't know them. Be very careful with humor — it's subjective, hard to translate, and grating on repetition.

**Approachability.** No prerequisite skills or knowledge; a clear path to deeper understanding. Present a straightforward interface. Build in ways to learn (see Onboarding in PATTERNS.md).

**Gender identity.** Avoid unnecessary gender references. "Subscribers can post recipes to your shared folder" beats "You can let a subscriber post his or her recipes" — and localizes better into gendered languages. Avoid gendering avatars, emoji, glyphs, and game characters; give people the tools to customize. Use nongendered human imagery (`person.crop.circle`, `person.3.fill`, `figure.wave`) for generic people. Most apps don't need gender at all; if you have a health or legal reason to collect it, offer nonbinary, self-identify, and decline-to-state options, and consider letting people specify their pronouns.

**People and settings.** Portray a range of characteristics and activities — racial backgrounds, body types, ages, physical capabilities. Avoid occupational stereotypes (only male doctors, only female nurses) and racialized hero/villain casting. Review settings and objects too: high affluence can read as out of touch. Prefer familiar, relatable places and things.

**Avoiding stereotypes.** Everyone holds unconscious biases. Some assumptions are obvious (a "family" as one woman, one man, and their biological children excludes most families). Others aren't: security questions like "What was your favorite subject in college?" or "What was the make of your first car?" assume experiences not everyone has. Prefer universal ones: "What's your favorite activity?", "What was the name of your first friend?", "What quality describes you best?"

**Accessibility as inclusion.** Every disability is a spectrum (visual disability spans low vision, complete blindness, color blindness, blurry vision, light sensitivity, peripheral vision loss). Everyone experiences disability — permanent, temporary (short-term hearing loss), or situational (a noisy train). Avoid imagery and language that excludes people with disabilities, and never use a disability to express a negative quality. Take a people-first approach in writing — and find out how a specific person or community self-identifies.

**Languages.** Internationalize first (handle other languages and regions), then localize. Inclusive design is a head start on localization: plain language, no unnecessary gender, varied representation, and no culture-specific content all translate more cleanly. SF Symbols provides language-specific and bidirectional glyphs. Watch color meanings per locale — white signifies death or grief in some places, purity or peace in others.

---

## Privacy

- Your App Store product page shows the privacy details you declare. People decide before downloading.
- **Request only what you need**, as specifically as you can, at the moment the feature needs it. Asking for more than a feature requires, or asking before someone shows interest, destroys trust.
- **Be transparent** about collection and use. Respect Hide My Email and Mail Privacy Protection. Understand your obligations around app tracking.
- **Process on device** where possible (Apple Neural Engine, CreateML models) to avoid risky round trips.
- Adopt system protections — CloudKit encryption and key management for strings, numbers, dates.

**What requires permission:** personal data (location, health, financial, contacts, other PII) · user-generated content (email, messages, calendar, contacts, gameplay info, Apple Music activity, HomeKit data, audio/video/photos) · protected resources (Bluetooth peripherals, home automation, Wi-Fi, local networks) · device capabilities (camera, microphone) · ARKit data in a visionOS Full Space (hand tracking, plane estimation, image anchoring, world tracking) · the advertising identifier.

**Purpose strings.** One brief, complete sentence, active voice, sentence case, ending period, stating how and why.
- ✅ "The app records during the night to detect snoring sounds."
- ❌ "Microphone access is needed for a better experience." (passive, vague)
- ❌ "Turn on microphone access." (imperative, no justification)

**Pre-alert screens.** If context genuinely isn't enough, you may show one screen before the system alert. It must have exactly **one** button labeled Continue or Next — never Allow (people conflate it with the system button), never a Cancel or close option, never an additional action. No incentives, no imitation of the system alert, no image of the alert, no annotation of the screen behind it. Tracking requests in particular: any custom screen that exploits fast-dismissal behavior will be rejected under App Review Guideline 5.1.1(iv). You cannot compensate people for granting permission, or withhold functionality until they allow tracking.

**Location button.** Core Location (iOS, iPadOS, watchOS) provides a button granting one-time location access at the moment of use. The first tap shows a standard explanatory alert; after that, tapping is enough. Customize the title (from the system-provided set), glyph (filled or outlined), background color, title/glyph color, and corner radius — nothing else. The system warns about low contrast or excessive translucency, and if problems persist it stops granting location access on tap. You are responsible for text fitting at all accessibility sizes and in every language.

**Protecting data.** Prefer passkeys over passwords; add two-factor authentication if you keep passwords; use Face ID / Optic ID / Touch ID for logged-in apps. Store secrets in the keychain. Never store passwords or secure content in plain text, even with restrictive file permissions. Don't invent custom auth schemes — use passkeys, Sign in with Apple, or Password AutoFill.

**macOS.** Sign with a valid Developer ID. Sandbox (required for Mac App Store). Don't assume a single signed-in user.

**visionOS.** ARKit algorithms (persistence, world mapping, segmentation, matting, environment lighting) always run, but ARKit sends no data to apps in the Shared Space — you need a Full Space plus permission for Plane Estimation, Scene Reconstruction, Image Anchoring, and Hand Tracking. **User input is private by design**: the system applies hover effects out of process so your app never learns where someone is looking before they tap. The back camera returns blank input; the front camera serves spatial Personas only, with permission.

---

## Right to left

System frameworks flip standard components automatically. If you use system elements and standard layouts, you may need no changes. Fine-tune as follows.

**Text alignment.** Mirror alignment to match the interface direction. But align a **paragraph** (three or more lines) to match *its own language*, not the current context — right-aligning an LTR paragraph makes the start of each line hard to find. One- and two-line blocks follow the context. Keep alignment consistent for every item in a list, including items in another script.

**Numbers and characters.** Hebrew uses Western Arabic numerals; Arabic may use Western or Eastern Arabic numerals depending on country and region. If your app is number-centric, determine the right representation per locale; otherwise rely on system formatting. **Never reverse the digits within a number** — "541", a phone number, a credit card number always read the same. **Do** reverse the *order* of numerals that show progress, counting direction, or an explicit sequence — and never flip the numerals themselves.

**Controls.** Flip anything that shows progress from one value to another (sliders, progress indicators) and reverse the accompanying start/end glyphs. Flip navigation and ordered-access controls — a back button must point right in RTL. **Preserve** the direction of a control that refers to an actual direction or points at an onscreen area. Arabic and Hebrew have no uppercase, so they look small beside all-caps Latin text; increasing the RTL font size by about 2 pt restores balance.

**Images.** Don't flip photographs, illustrations, or general artwork — flipping changes meaning and can violate copyright. If an image's content is bound to reading direction, make a new version. **Do** reverse the *positions* of images whose order is meaningful (chronological, alphabetical, ranked).

**Interface icons.** SF Symbols supplies RTL variants and localized symbols; custom symbols can declare directionality. Flip icons that represent text or reading direction (left-aligned bars → right-aligned). Consider localized versions of icons that display actual characters (signature, rich-text, I-beam pointer symbols exist for Latin, Hebrew, and Arabic); if letters are used for a concept unrelated to reading, design a non-text alternative. Flip icons depicting forward or backward motion — a speaker's sound waves emanate in the reading direction. **Never flip** logos or universal marks (a checkmark). Generally don't flip icons of real-world objects — a clock works the same everywhere, and right-handed tools stay right-handed because most people are right-handed. For complex icons, consider components individually: SF Symbols keeps the same backslash for prohibition in both directions; a badge representing real UI should flip if that UI flips, while a badge that modifies meaning should stay where it preserves visual balance; preserve a tool's orientation while flipping the base image.

---

## Immersive experiences (visionOS)

**Passthrough** is live video from the external cameras that keeps people connected to their surroundings. The Digital Crown adjusts it at any time — press and hold to recenter, double-click to briefly reveal surroundings. The system dims content when someone gets too close to a physical object in mixed immersion. In progressive and full styles it defines a boundary ~1.5 m from the wearer's initial head position: approaching it fades the experience and increases passthrough; crossing it replaces the visuals with the app icon until the person returns or recenters.

**Immersion styles.** Dimmed/tinted passthrough (draws attention without hiding other apps; custom tint allowed) · **mixed** (unbounded 3D blended with passthrough, no boundary, ARKit access with permission) · **progressive** (partial custom environment, Digital Crown adjustable within 120°–360° or a custom range, portrait or landscape) · **full** (360° environment replacing passthrough).

**Practices**
- Offer multiple ways to use the app, and support accessibility personalization.
- **Prefer launching in the Shared Space or the mixed style.** People can reference other apps and choose when to go deeper.
- Reserve immersion for meaningful moments. Not every task benefits, and not every immersive task needs to be *fully* immersive. Photos: browse albums in a Shared Space window; expand one photo into a Full Space.
- Use cues — dimming, tinting, motion, scale, Spatial Audio — to draw attention. Start subtle; strengthen only with reason.
- Keep passthrough tints subtle. Bright or dramatic tints distract and break immersion.
- Comfort: place 3D content within the field of view; follow the Motion rules.
- Choose a style that matches the movement your experience invites. Excessive movement interrupts progressive and full experiences — if people may need to move beyond 1.5 m, use mixed. Avoid encouraging movement at all; some people can't or won't move. Let people bring an object closer instead of walking to it.
- In mixed style, don't obscure too much passthrough. If virtual objects would block a lot of the view, switch to progressive or full.
- **Transitions**: gentle, predictable, visually trackable. Never sudden.
- **Let people choose** when to enter or exit. Provide a prominent, clearly labeled exit control that says whether it returns to a less immersive context or quits. Offer a way to pause or save before quitting. Don't force people to use system controls to reduce immersion.

**Virtual hands.** With permission, a Full Space app can hide the wearer's hands and show virtual ones. Match position and gesture so interactions still feel natural. Be careful with oversized hands — they occlude content, make interaction clumsy, and look out of proportion. If hand tracking drops, fade the virtual hands out and reveal the real ones; never freeze them. Fade back in when tracking returns.

**Creating an environment.** Minimize distraction — avoid high movement and high-contrast detail; use high-quality textures and shapes where you want attention and lower-quality, dimmer assets elsewhere. Proximity signals interactivity: people reach for near objects and don't reach for far ones. Keep animation small and gentle (drifting clouds), never near the edges of vision. Make it **expansive** — small environments feel claustrophobic. Use Spatial Audio for atmosphere, avoiding obvious loops and lowering or stopping it when other audio plays. **Avoid a flat 360° image** — it gives no sense of scale; prefer object meshes with lighting and shaders for subtle animation. **Always provide a ground plane mesh** so people don't feel like they're floating. Minimize asset repetition.

---

## Spatial layout (visionOS)

**Field of view.** The space a person sees without moving their head; it varies by Light Seal fit and peripheral acuity, and **the system doesn't tell you what it is**. Center important content — visionOS launches apps directly in front of people. In an immersive experience, keep attention centered and avoid distracting motion or bright, high-contrast objects in the periphery. **Never anchor content to the head** — it feels confining, obscures passthrough, destabilizes the surroundings, and blocks Pointer Control. Anchor in the person's *space* instead.

**Depth.** People read depth from distance, occlusion, and shadow; the system adds color temperature, reflections, and shadows automatically. Small amounts of depth throughout the interface — even in standard windows — look natural. Use depth to communicate hierarchy: a sheet comes forward while its window recedes along the z-axis. Provide cues that *accurately* communicate depth; missing or conflicting cues cause visual discomfort. **Never add depth to text.** Make sure depth adds value — it separates large, important elements (a tab bar or toolbar from a window) but harms small ones (a button's symbol lifted off its background becomes less legible). Each depth difference forces the eyes to refocus; doing that often or quickly is tiring.

**Scale.** **Dynamic scale** (the default for windows) increases a window's scale as it moves away and decreases it as it approaches, so it appears the same size at any distance — this is why visionOS defines a point as an angle. **Fixed scale** keeps real-world size, so objects shrink with distance like physical ones. Use fixed scale sparingly, for noninteractive objects that need real-world size (a product you're previewing in your room); interactive content needs to scale to stay usable.

**Practices.** Avoid too many windows — they obscure surroundings, overwhelm, and make relocating the app tedious. **Prioritize indirect gestures**; reserve direct gestures for nearby objects that invite close inspection for short periods. Rely on the Digital Crown for recentering (you don't have to build anything). Space interactive components generously: centers ≥60 pt apart, ≥16 pt between them, and never overlapping other interactive elements or views. Let people use the app with minimal or no physical movement. For a large immersive experience, place content on a flat horizontal plane aligned with the floor.

---

## Writing

**Getting started.** Determine your app's **voice** — who you're talking to, what vocabulary they know, how you want them to feel. A banking app conveys trust and stability; a game conveys excitement. Keep a list of common terms and use it. Vary **tone** by situation, in both the physical and in-app context: a missed goal and a failed payment need different registers. Be clear — check every word, cut what you can, read it aloud. Write for everyone: plain language, accessibility and localization in mind, no jargon, no gendered terminology.

**Best practices**
- Consider each screen's purpose; put the most important information first; format for scanning; split multiple ideas across screens and think about the flow between them.
- **Be action oriented.** Active voice, clear labels. Buttons and links almost always start with a verb. "Send" beats "Let's do it!" Avoid "Click here" — "Learn more about UX Writing" is better, and essential for screen readers.
- **Build language patterns.** Consistency builds familiarity and makes writing easier.
- Adopt capitalization rules and apply them consistently. Title case reads formal; sentence case reads casual. Pick a style per UI element type.
- Multi-step flows: decide the labels up front. "Get Started" to begin, "Continue"/"Next" or a hint at the next step in between, "Done" at the end. Be consistent.
- Use possessive pronouns sparingly. "Favorites" says the same as "Your Favorites," more succinctly. **Avoid *we* altogether** — "Unable to load content" beats "We're having trouble loading this content."
- Write for each device. Keep language consistent but adjust for context: never say "click" on iPhone. Small screens demand brevity for space; big screens demand brevity because text must be large enough to read from across a room — and TVs are shared, so consider who else is present.
- **Empty states** are an opportunity: welcome people, educate them, show your voice — but keep it useful and contextual. Guide people to a next action with a button or link. They're temporary, so don't put crucial information there.
- **Error messages**: prevent errors first. Display them as close to the problem as possible, avoid blame, and say what to do. "Choose a password with at least 8 characters" ≫ "That password is too short" ≫ "Invalid password." No "oops" or "uh-oh" — they read as insincere. If language alone can't fix an error that affects many people, rethink the interaction.
- **Choose the right delivery method** based on urgency, importance, context, whether it needs immediate action, and how much supporting information is needed. (Notifications, alerts, action sheets — see PATTERNS.md.)
- **Settings labels**: as practical as possible. Add an explanation if the label isn't enough — describe what happens when it's on and let people infer the opposite. Link directly to a setting instead of describing its location.
- **Text fields**: label every field, use hint/placeholder text to show the expected format ("name@example.com" or "Your name"). Show errors next to the field, instructing rather than scolding: "Use only letters for your name" beats "Don't use numbers or symbols" beats "Invalid name."
