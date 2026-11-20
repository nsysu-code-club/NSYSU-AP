# Designing for each platform

Every platform has a different display, ergonomic model, input set, and session length. Those four facts drive almost every layout decision. Approach every platform you support with the same level of care — a scaled-up phone layout reads as an unfinished port.

---

## iOS — iPhone

**Characteristics.** Medium, high-resolution display. Held in one or both hands, rotated freely, viewed from a foot or two. Multi-Touch, virtual keyboards, voice; gyroscope and accelerometer. Sessions swing between one-minute checks and hour-long stretches, with frequent app switching.

**System features to integrate:** Widgets · Home Screen quick actions · Spotlight · Shortcuts · Activity views · Live Activities · Controls · Action button (16/16 Pro and later) · Camera Control (16 series).

**Rules**
- Limit onscreen controls; make secondary details discoverable with minimal interaction.
- Adapt seamlessly to orientation, Dark Mode, and Dynamic Type.
- Design for how people hold the device: the middle and bottom of the display are the reachable zone. Support swipe-to-go-back and swipe actions in rows.
- Support both orientations when you can. If you're landscape-only, work equally well rotated left or right. Don't tell people to rotate — they'll try it.
- Avoid full-width buttons; respect system margins. A full-width button must harmonize with the hardware corner radius.
- Keep the status bar visible unless you're offering an immersive media or game experience.
- Games: prefer a full-bleed interface that accommodates the corner radius, sensor housing, and Dynamic Island.
- Use platform capabilities (payments, biometrics, location) to *avoid* asking people to type.

**Multitasking:** PiP and FaceTime over other apps.

---

## iPadOS — iPad

**Characteristics.** Large, high-resolution display. Held, propped, or docked; ~3 ft viewing distance. Touch, virtual and physical keyboards, trackpad/mouse, Apple Pencil, voice — often combined. Sessions range from quick actions to hours of creation. Multiple windows onscreen.

**System features:** Multitasking · Widgets · Drag and drop · Menu bar (iPadOS) · Apple Pencil and Scribble.

**Rules**
- Windows are freely resizable down to a minimum. Design for the *full* range of sizes, not two breakpoints.
- Defer switching to a compact layout as long as possible. Design full-screen first; collapse only when a version of the full layout no longer fits. For split views, hide tertiary columns (inspectors) first.
- Test at the system tiling sizes — halves, thirds, quadrants — on several devices, and check that transitions between them are smooth.
- Prefer a **convertible tab bar** (`sidebarAdaptable`) so people can switch between a tab bar and a sidebar.
- When windowed, window controls sit at the leading edge of the toolbar — move your leading toolbar buttons inward so they aren't covered.
- Use viewing distance and input mode to set content size and density.
- Support Multi-Touch, physical keyboard/trackpad, and Apple Pencil; consider interactions that combine them.
- The iPadOS **menu bar** is hidden until revealed (pointer to top edge or swipe down), centered, with no Apple menu, no menu bar extras, and no About/Services items. Because it's hidden, every function must also be reachable in the UI. Reserve `Settings` for the iPadOS Settings page; link an in-app preferences area separately. Consider listing each tab in the View menu. Group items into submenus more aggressively than on Mac — rows are taller.
- Support drag and drop everywhere it makes sense, including multi-item and mid-drag additions.

---

## macOS — Mac

**Characteristics.** Large display(s), extendable. Stationary use at a desk, 1–3 ft away. Keyboard, pointing device, game controllers, Siri. Sessions from minutes to hours, with many apps open and constant switching.

**System features:** The menu bar · File management · Full-screen mode · Dock menus · Menu bar extras.

**Rules**
- Use the extra space to present more content in fewer nested levels and with less modality — without cramming.
- Let people resize, hide, show, and move windows. Support full-screen mode via the system mechanism (`toggleFullScreen(_:)`), never a custom window-mode menu.
- The menu bar is the contract: every command lives there, in the standard order (App · File · Edit · Format · View · app-specific · Window · Help). Always show the same items; dim rather than hide.
- Support standard keyboard shortcuts. Only redefine one if its action genuinely doesn't exist in your app.
- Support personalization: customizable toolbars, saved window configurations, user-chosen colors and fonts.
- Support pixel-precise selection and editing.
- Never place critical information or actions at the bottom edge of a window.
- Don't put content under the camera housing at the top edge.
- Window states — **main**, **key**, **inactive** — have distinct system appearances. If you build custom windows, replicate them exactly or you'll look broken.
- macOS-specific controls exist for a reason: push buttons, square (gradient) buttons, help buttons, image buttons, checkboxes, radio buttons, combo boxes, color wells, image wells, path controls, token fields, outline views, column views, panels/HUDs, tab views.
- Desktop tinting: when the graphite accent is chosen, window backgrounds pick up desktop color. Add transparency to custom neutral-state component backgrounds so they harmonize; don't add it to colored states.
- Sign with a Developer ID; sandbox the app; don't assume a single signed-in user (fast user switching).

**Mac Catalyst.** Good candidates already support drag and drop, keyboard navigation and shortcuts, multitasking, and multiple windows. Poor candidates depend on gyroscope, rear camera, HealthKit, ARKit, marking, or navigation. Start with the **iPad idiom** (interface scales to 77%); move to the **Mac idiom** for text- or art-heavy apps, and expect a real layout audit — avoid fixed font/view/layout sizes. Replace tab bars with a split view + sidebar (preferred) or a segmented control, and list top-level items in the View menu. Move edge-hugging buttons into the toolbar. Add context menus liberally — Mac users expect one on everything.

---

## tvOS — Apple TV

**Characteristics.** Very large display. Viewed from 8+ ft, sometimes while moving around the room. Siri Remote, game controllers, voice, companion devices. Deep, hours-long immersion; PiP for a second stream.

**System features:** Integrating with the TV app · SharePlay · Top Shelf · TV provider accounts.

**Rules**
- Support fluid Siri Remote gestures; distinguish deliberate **press** from incidental **tap** (a thumb resting on the remote will tap).
- Embrace the **focus system**. Focus, not a pointer, is how people navigate. Every element must be reachable by directional movement. Design for five focus states (unfocused, focused, selected/pressed, chosen, unavailable), and supply assets at the enlarged focused size.
- Layouts don't adapt to TV size — the same interface ships to every display. Inset primary content **60 pt** top/bottom, **80 pt** sides for overscan.
- Use layered images (2–5 layers, opaque background layer, text in the foreground, safe zone at the edges) for the parallax effect. Keep parallax subtle.
- Edge-to-edge artwork, fluid animation, and engaging audio; legible from across the room.
- Multiuser: make sign-in easy and rare; handle shared sign-in; switch profiles automatically.
- The tab bar is 68 pt tall, 46 pt from the top; it scrolls away in single-view tabs and pins in split views. Menu always returns focus to it.
- Avoid displaying a pointer. If a game requires one, make it highly visible and integrated.
- Don't place focusable elements too close to a segmented control — segments select on focus.
- Live-viewing apps: live content in the first tab, one tap (or zero) to play, visibly mark live vs. VOD, order tabs Live → DVR → other. See PATTERNS.md.

---

## visionOS — Apple Vision Pro

**Characteristics.** An infinite canvas. Content lives in the **Shared Space** (multiple apps side by side) or a **Full Space** (yours alone). **Passthrough** keeps people connected to their surroundings. **Spatial Audio** models the room. People target with their **eyes** and act with **hands** (indirect) or by touching (direct). The system places content relative to the head, so people can sit, stand, or recline.

> Safety: not for use while driving or operating machinery, or while moving through unsafe environments. 13+.

**Rules**
- Prefer launching in the Shared Space, or using the mixed immersion style, even for an immersive app. Let people choose when to go deeper, and give them an obvious, clearly-labeled way out.
- **Reserve immersion for meaningful moments.** For each key moment, use the *minimum* level of immersion that suits it.
- Immersion styles: **mixed** (blends with passthrough, no boundary; the system fades nearby content when a person gets close to a physical object) · **progressive** (partial custom environment, adjustable with the Digital Crown, 120°–360°, ~1.5 m boundary) · **full** (360° environment, ~1.5 m boundary). Also: dimmed/tinted passthrough for focus without hiding other apps.
- **Comfort is the primary constraint.** Content within the field of view, positioned relative to the head. Prefer horizontal layouts to vertical (neck strain). No motion in the periphery. No world rotation. Give a stationary frame of reference. Avoid ~0.2 Hz oscillation. Don't anchor content to the head — it feels confining and blocks Pointer Control.
- **Prefer indirect gestures.** Hands can rest in the lap. Reserve direct gestures for nearby objects and short interactions.
- Windows use an unmodifiable **glass** material. Keep it — removing it hurts legibility and grounding. Default window: 1280×720 pt, placed ~2 m away. Set sensible min and max sizes. Keep content inside the window's bounds — system controls live just outside the top and bottom edges. Use **ornaments** for controls that don't fit inside.
- Use a **volume** for bounded 3D content that people walk around; use a window for UI-centric tasks.
- Tab bars are **vertical**, on the leading side; they expand when looked at. Toolbars sit along the bottom edge as ornaments. Never build a vertical toolbar (it reads as a tab bar).
- Depth communicates hierarchy — but never add depth to text, and don't add depth to small elements like a button's symbol. Each depth change forces the eyes to refocus.
- Dynamic scale keeps windows legible at any distance; fixed scale is for noninteractive real-world-size objects.
- Prefer 2D text, white by default, bold if it's not on a background. Billboard any text anchored to a point in space.
- Use color sparingly, especially on glass. Prefer bold text and larger areas. Keep brightness balanced in immersive scenes.
- The area around a person's palm is reserved for system overlays (Home, Control Center) — don't anchor content there, and be careful with custom rolling hand/wrist gestures.
- No haptics — audio feedback carries that weight. Use standard controls to get the sounds people already know, and design sounds for custom elements.
- ARKit data (hand tracking, plane estimation, scene reconstruction, image anchoring) requires a Full Space *and* permission. The back camera returns blank input; the front camera serves spatial Personas only, with permission.
- No Dark Mode setting — glass adapts to the luminance behind it.
- Prefer split views and sheets over opening extra windows.

---

## watchOS — Apple Watch

**Characteristics.** Small display on the wrist, within a foot, one-handed operation with the other hand. Always On display shows information on wrist-down. Digital Crown, Action button, standard gestures, double tap, sensors. Interactions last seconds. People use complications, notifications, and Siri more than the app itself.

**System features:** Complications · Notifications · Always On · Watch faces · Smart Stack.

**Rules**
- Design for glanceable, single-screen interactions that finish in a gesture or two.
- Minimize hierarchy depth. **Anchor navigation to the Digital Crown** — vertical lists, vertical tab views, scroll views — and always back it with an equivalent touch interaction.
- Extend content edge to edge; the bezel supplies the visual padding. Minimize inter-element padding.
- No more than two or three side-by-side controls (three glyph buttons, or two short text buttons). Prefer full-width buttons for primary actions.
- Toolbar buttons go in the top corners or along the bottom and stay visible over scrolling content; a scrolling toolbar button hides until people scroll up.
- Use background color to convey meaning, not decoration — and avoid full-screen background color in long-lived views.
- Materials give modal sheets their sense of place; don't strip them.
- Support autorotation for views people show to others (a QR code, a photo).
- Always On: hide sensitive data, dim nonessential content, keep the layout stable, transition motion gracefully to rest.
- Text entry is expensive. Prefer lists of options, dictation, Scribble, or the paired iPhone.
- Complications are the highest-value surface: support every family you can, offer multiple complications, deep-link each one to a different place, keep images legible in tinted mode, use ≥2 pt line widths, supply placeholder images.
- Double tap runs the **first nondestructive action** in a notification and the designated primary action in a view — don't set a primary action in lists, scroll views, or vertical tab views.

---

## Games

Games are held to the same platform standards, plus:

**Jump into gameplay.** Playable content in the initial install; keep the download ≤30 minutes and stream the rest in the background. Great defaults (resolution, detected controllers, accessibility settings) so nobody configures before playing. Teach through play; make written tutorials optional. Defer permission requests to the moment they're needed.

**Look stunning on every display.** Use the platform text minimums (see SKILL.md). Button minimums: iOS/iPadOS 44×44 (min 28×28), macOS 28×28 (min 20×20), tvOS 66×66 (min 56×56), visionOS 60×60 (min 28×28), watchOS 44×44 (min 28×28). Prefer resolution-independent assets; vector art in visionOS. Accommodate rounded corners, sensor housings, and safe areas. Design in-game menus for 16:10, 19.5:9, and 4:3 with dynamic, relative layouts. Support full-screen / Full Space.

**Enable intuitive interactions.** Default interaction methods per platform: iOS touch (+controller) · iPadOS touch (+controller, keyboard, mouse, trackpad, Pencil) · macOS keyboard/mouse/trackpad (+controller) · tvOS remote (+controller, keyboard, mouse, trackpad) · visionOS eyes+hands (+controller, keyboard, mouse, trackpad, spatial controller) · watchOS touch only. Support physical controllers *and* an alternative.

**Welcome everyone.** Perceivability first; never color alone. Let players customize type size, control mapping, motion intensity, and sound balance. Give players tools to represent themselves. Review stories and characters for stereotypes.

**Adopt platform technologies.** Game Center, GameSave (cross-device saves), Core Haptics, Spatial Audio, ARKit/ML/HealthKit where they enable real mechanics.

Frame rate: 30–60 fps for smooth motion; let people trade visual fidelity for performance or battery.
