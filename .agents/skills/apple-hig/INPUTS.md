# Inputs

Action button · Apple Pencil and Scribble · Camera Control · Digital Crown · Eyes · Focus and selection · Game controls · Gestures · Gyroscope and accelerometer · Keyboards · Nearby interactions · Pointing devices · Remotes

**The rule that spans all of them:** never make an input method the only way to do something. People switch between voice, keyboard, touch, eyes, pointer, and assistive technology — often within a single session, and sometimes because they have no choice.

---

## Gestures

Every platform supports tap, swipe, and drag. The precise motions vary, but people know what these gestures *do* and expect them everywhere.

- **Give people more than one way to interact.** Don't assume anyone can perform a given gesture.
- **Respond consistently with expectations.** Don't repurpose a familiar gesture for something unique to your app, and don't invent a gesture for a standard action like activating a button or scrolling.
- **Handle gestures responsively.** Provide immediate feedback that helps people predict the result and, when needed, communicates how much movement is required.
- **Indicate when a gesture isn't available.** Without a signal, people assume the app froze or that they're doing it wrong. A locked object that doesn't move, or an unavailable button that looks available, both cause this.

**Custom gestures.** Add them only for specialized, frequent tasks not covered by existing gestures — a game, a drawing app. A custom gesture must be discoverable, straightforward to perform, distinct from other gestures, and **never the only way to perform an important action**. Make it easy to learn: create moments in your app that teach it, and test in real scenarios. *If it's hard to describe in simple language and graphics, people will find it hard to learn.* **Use shortcut gestures to supplement standard ones, not replace them** — an app with hierarchical navigation still needs a Back button in the toolbar, even if it also supports an edge swipe. **Avoid conflicting with system gestures** — edge swipes in watchOS, the hand-roll for system overlays in visionOS. Games and immersive experiences can defer some system gestures.

**iOS/iPadOS additions**

| Gesture | Common action |
|---|---|
| Three-finger swipe | Undo (left) / redo (right) |
| Three-finger pinch | Copy (in) / paste (out) |
| Four-finger swipe (iPadOS) | Switch apps |
| Shake | Undo / redo |

Consider simultaneous recognition when it helps — a game with an onscreen joystick and fire buttons.

**macOS.** Primarily keyboard and mouse; standard gestures on a Magic Trackpad, Magic Mouse, or a game controller with a touch surface.

**tvOS.** Standard gestures with a compatible remote, Siri Remote, or game controller with a touch surface. See Remotes.

**visionOS.** Two categories. **Indirect** — look at an object to target it, then act with your hand at a distance (a quick pinch of finger and thumb). Comfortable at any distance, minimal movement, quick focus changes. **Direct** — physically touch an interactive object (typing on the virtual keyboard). Best within reach and for infrequent use, since raised arms tire; visionOS supports direct versions of all standard gestures.

| Direct gesture | Common use |
|---|---|
| Touch | Select or activate |
| Touch and hold | Open a contextual menu |
| Touch and drag | Move an object |
| Double touch | Preview an object or file; select a word |
| Swipe | Reveal actions and controls; dismiss; scroll |
| Two-handed pinch and drag together/apart | Zoom |
| Two-handed pinch and drag in a circle | Rotate |

- **Support standard gestures everywhere.** Tap is the first thing people try after looking at something.
- **Offer both indirect and direct interactions.** Prefer indirect for UI and common components; reserve direct and custom gestures for objects inviting close-up interaction or specific motions.
- **Avoid requiring specific body movements or positions.** Disability, spatial constraints, and environment all interfere. If movement is required, support alternative inputs.

*Custom gestures in visionOS* require running in a Full Space and permission to access hand information. **Prioritize comfort** — continually test ergonomics; raised arms tire quickly and repeated similar motions stress muscles and joints. **Be careful with complex gestures involving multiple fingers or both hands** — people may not have both hands free; offer a lower-effort alternative. **Avoid gestures requiring a specific hand** — it increases cognitive load and excludes people with strong hand dominance or limb differences.

*System overlays.* In visionOS 2+, looking at your palm reveals the Home indicator, and turning your hand reveals the status bar (tap for Control Center). These are systemwide and reserved. **Don't anchor content to hands or wrists**; if a game must, place it outside the immediate area of the hand. **Consider deferring the system overlay behavior** in an immersive app or game — a game with virtual hands can require a tap to reveal the Home indicator instead (`persistentSystemOverlays(_:)`); apps built for visionOS 1 defer by default in a Full Space. **Use caution with custom rolling motions of the hand, wrist, and forearm** — that motion is reserved, system overlays always display on top of app content, and your app never learns when they're visible, so test carefully.

**watchOS double tap.** In watchOS 11+, double tap scrolls lists and scroll views and advances vertical tab views. You can designate a toggle or button as the **primary action** in a view, or in a widget or Live Activity shown in the Smart Stack; double-tapping highlights it and performs the action. It also runs the first nondestructive custom action in a notification. **Don't set a primary action in views with lists, scroll views, or vertical tabs** — it conflicts with the default navigation. **Choose the most commonly used button** as the primary action (play/pause in a media controls view).

---

## Keyboards

A physical keyboard connects to every device except Apple Watch. Mac users use one constantly; iPad users often do.

- **Support Full Keyboard Access** (iOS, iPadOS, macOS, visionOS) — navigate and activate windows, menus, controls, and system features from the keyboard alone.
- **iPadOS caveat:** iPadOS supports keyboard navigation in text fields, text views, and sidebars, and provides APIs for collection views and custom views — but **avoid supporting keyboard navigation for controls** like buttons, segmented controls, and switches. Let Full Keyboard Access handle activating controls, reaching all onscreen components, and gesture-based interactions like drag and drop.
- **Respect standard keyboard shortcuts.** For a unique frequent action, create a custom shortcut rather than repurposing a standard one. Only redefine a standard shortcut when its action genuinely doesn't exist in your app — an app with no text editing has no use for Command-I and might repurpose it for Get Info.
- In games, people expect a few standard shortcuts (Command-Q to quit) but also expect to remap key bindings freely.

**Custom keyboard shortcuts**
- **Define them only for the most frequently used app-specific commands.** Too many make an app feel hard to learn.
- **Use modifiers as people expect** — Command while dragging moves items as a group; Shift while drag-resizing constrains the aspect ratio; holding an arrow key moves the selection by the smallest app-defined unit.

| Modifier | Recommended use |
|---|---|
| **Command** | The main modifier in a custom shortcut |
| **Shift** | A secondary modifier complementing a related shortcut |
| **Option** | Sparingly, for less-common commands and power features |
| **Control** | **Avoid** — the system uses it heavily for focus movement and screenshots |

- Some languages need modifiers to produce characters (Option-5 gives "{" on a French keyboard). Command is generally safe; if you must use another modifier, prefer alphabetic characters.
- **List modifiers in order: Control, Option, Shift, Command.**
- **Don't add Shift to a shortcut using the upper character of a two-key.** People already know Shift produces the upper character, so list it directly: Hide Status Bar is Command-Slash; Help is Command-Question mark, **not** Shift-Command-Slash.
- **Let the system localize and mirror your shortcuts** for the connected keyboard and for RTL layouts.
- **Don't create a new shortcut by adding a modifier to an unrelated command's shortcut.** Shift-Command-Z for something unrelated to undo is confusing.

**Standard shortcuts people expect** (a working subset; the full table is in the HIG): Command-Space (Spotlight) · Option-Command-Space (Spotlight results window) · Control-Command-Space (Special Characters) · Shift-Tab (reverse control navigation) · Command-Tab / Shift-Command-Tab (app switching) · Control-Tab / Control-Shift-Tab (control groups and tables) · Esc (cancel) · Option-Command-Esc (Force Quit) · Control-F1 (toggle full keyboard access) · Control-F2 (menu bar) · Control-F3 (Dock) · Control-F4 / Control-Shift-F4 (windows) · Control-F5 (toolbar) · Command-F5 (VoiceOver) · Control-F6 / Control-Shift-F6 (panels) · Control-F7 (override keyboard access mode) · F11 (Show desktop) · Command-Grave / Shift-Command-Grave (cycle windows) · Command-Hyphen (decrease selection size) · Option-Command-Hyphen (zoom out) · Shift-Command-Equal (increase selection size) · Option-Command-Equal (zoom in) · Command-Left/Right bracket (left/right align) · Command-Pipe (center align) · Command-Colon (Spelling window) · Command-Semicolon (find misspelled words) · **Command-Comma (settings)** · **Command-Period (cancel)** · Command-Question mark (Help menu) · Shift-Command-3 / 4 (screen and selection capture to file) · Control-Shift-Command-3 / 4 (to Clipboard) · Control-Option-Command-Comma / Period (screen contrast). Arrow keys with Shift/Option/Command extend selection by character, word, line, paragraph, or to the document boundary; Control-arrow moves focus among values or cells within a view. Input source shortcuts: Control-Space (toggle current and last input source) · Control-Option-Space (next input source) · Command-Right/Left arrow (Roman / system script layout).

**visionOS.** Holding Command shows a shortcut interface organized like menu bar menus (File, Edit, View), but displaying **all** categories in one view and listing only available commands that have shortcuts. **Write descriptive shortcut titles** — there are no submenu titles to supply context (`discoverabilityTitle`). Note that connecting a physical keyboard puts a virtual keyboard overlay onscreen offering typing completion and other controls. Not supported in watchOS.

---

## Pointing devices

- **Be consistent when responding to mouse and trackpad gestures.** People expect a gesture like "swipe between pages" to behave identically everywhere.
- **Don't redefine systemwide trackpad gestures.** Even a game using app-specific gestures must leave the Dock and Mission Control gestures alone — and Mac users can customize them.
- **Provide a consistent experience across gestures, eyes, pointer, and keyboard.** People move fluidly between input types and don't want to learn a different set of interactions per mode.
- **Let the pointer reveal and hide auto-minimizing controls** — holding the pointer over the minimized Safari toolbar in iPadOS reveals it; moving away minimizes it again. The same applies to playback controls in full-screen video.
- **Behave consistently with modifier keys.** If Option-dragging duplicates an object, it must duplicate whether people drag with touch or the pointer.

**iPadOS.** The pointer adapts to context with rich visual feedback. **It supplements touch — it doesn't replace it.**
- **Allow multiple selection in custom views** where appropriate. iPadOS 15+ lets people drag the pointer over items to select them, the pointer expanding into a selection rectangle. Standard nonlist collection views support it; custom views need `UIBandSelectionInteraction`.
- **Distinguish pointer from finger input only when it adds value** — a scrubber can let people click a precise seek destination with the pointer while still supporting dragging with either.

*Pointer shape and content effects.* The pointer is a circle by default, taking system or custom shapes over specific elements (the I-beam over text). A **content effect** changes the element's appearance under the pointer:
- **Highlight** — the pointer becomes a translucent rounded rectangle behind the control, with gentle parallax. Default for bar buttons, tab bars, segmented controls, and edit menus.
- **Lift** — subtle parallax plus apparent elevation; the pointer fades out beneath the element as it scales up with a shadow below and a soft specular highlight on top. Default for app icons and Control Center buttons.
- **Hover** — a generic effect applying custom scale, tint, or shadow without transforming the pointer shape.

Use **highlight for a small element with a transparent background**, **lift for a small element with an opaque background**, and **hover for large elements** with customized scale, tint, and shadow.

*Pointer accessories* are secondary visual indicators that combine with any pointer to communicate additional information — small arrows on a resizable element (`UIPointerAccessory`). **Use clear, simple images** — the accessory is small. **Consider the accessory transition** to signal a state change (plus → `circle.slash` when an add action becomes unavailable).

*Pointer magnetism.* Elements appear to attract the pointer. Moving close: the pointer starts transforming as soon as it enters the element's hit region, which extends beyond the visible bounds — creating the illusion of attraction. Flicking: the system examines the trajectory and pulls the pointer toward the most likely target's center. By default, magnetism applies to lift and highlight elements but **not** to hover elements — a hover element doesn't transform the pointer, so magnetism would feel like a loss of control. The system also applies magnetism in text-entry areas so unintended vertical movement doesn't skip lines during selection.

*Standard effects.* **Support the system content effects where possible** — people expect their experience across the system to carry into your app. **Prefer system pointer appearances for standard buttons and text-entry areas.** **Add padding around interactive elements** to create comfortable hit regions: too small and people must be extra precise; too large and pulling away feels effortful. About **12 pt** around bezeled elements, **24 pt** around unbezeled ones. **Create contiguous hit regions for custom bar buttons** — a gap between adjacent buttons causes a distracting flash as the pointer reverts to its default shape. **Specify the corner radius of a nonstandard element receiving the lift effect** so the pointer animates seamlessly into its shape (`UIPointerShape.roundedRect(_:radius:)`).

*Customizing.* **Prefer system effects for custom elements that behave like standard ones** — buttons in a custom toolbar without the standard highlight read as broken. **Be consistent throughout your app.** **Avoid gratuitous effects** — people expect a pointer change to be useful, and purely decorative ones distract and irritate. **Keep custom shapes simple** — the shape should signal the available action without drawing attention to itself; if people don't understand it instantly, they'll waste time on it. **Consider useful annotations** — X and Y values over a graphing area; Keynote shows an image's width and height while resizing. **Avoid instructional text with a pointer** — it makes an app look complicated. Prioritize clarity in the interface instead. **Consider the interplay of shadow, scale, and spacing in custom hover effects**: reserve scaling for elements that can grow without crowding (a table row can't). For an element with little space, use tint without scale and shadow. **Don't use shadow without scale** — an unscaled element doesn't appear closer even when its shadow says it is.

**macOS.** Standard interactions people can customize: **primary click** (select or activate) · **secondary click** (contextual menus) · **scrolling** · **smart zoom** · **swipe between pages** · **swipe between full-screen apps** · **Mission Control** (two-finger double-tap on a mouse, three- or four-finger swipe up on a trackpad). Trackpad only: **lookup and data detectors** (one-finger force click or three-finger tap) · **tap to click** · **force click** (click then press firmly for Quick Look or lookup, or apply variable pressure to pressure-sensitive controls like variable-speed media controls) · **pinch to zoom** · **two-finger rotate** · **Notification Center** (swipe from the trackpad edge) · **App Exposé** (three- or four-finger swipe down) · **Launchpad** (pinch with thumb and three fingers) · **Show Desktop** (spread with thumb and three fingers).

*Standard macOS pointers:* `arrow` (standard) · `closedHand` (dragging to reposition content) · `contextualMenu` (a contextual menu is available; usually shown only with Control pressed) · `crosshair` (precise rectangular selection) · `disappearingItem` (a dragged item will disappear on drop; the original is unaffected) · `dragCopy` (Option during a drag — duplicates on drop) · `dragLink` (Option-Command during a drag — creates an alias) · `iBeam` (horizontal text selection and insertion) · `openHand` (repositioning is possible) · `operationNotAllowed` (can't drop here) · pointing hand (a URL link). Not supported in tvOS or watchOS.

---

## Focus and selection

Focus visually confirms which object an interaction targets, supporting component-based navigation with a remote, game controller, or keyboard. Focusing often selects too — except where automatic selection would cause a distracting context shift. In tvOS, moving focus is separate from selecting, because selection opens or activates.

Platforms communicate focus differently: iPadOS and macOS draw a ring or highlight; tvOS uses the parallax effect to give the focused item depth and liveliness.

- **Rely on system-provided focus effects.** They're tuned to feel responsive, fluid, and lifelike, and give your app consistency and predictability. Create custom effects only if absolutely necessary.
- **Avoid changing focus without interaction.** People rely on focus to know where they are. The one exception: when someone is moving focus with a discrete directional input (keyboard, remote, game controller) and the focused item disappears — then only a small number of items are one step away, so moving focus to one keeps the indicator findable. When people aren't using such an input, you can't predict their next target, so **hide the focus indicator** instead.
- **Be consistent with the platform.** In iPadOS and macOS, full keyboard access reaches every control, so you only need focus for content elements — list items, text fields, search fields — not buttons, sliders, and toggles. In tvOS, people reach *everything* by directional movement, so every element must be focusable.
- **Indicate focus with platform-consistent appearances.** In iPadOS and macOS, a focused list item uses white text on a background highlight in the accent color; an unfocused one uses the standard text color and a gray highlight.
- **Use a focus ring for text and search fields; a highlight in lists and collections.** A ring can work for an item filling a cell (a photo), but a highlighted row is easier to read.

**iPadOS.** iPadOS 15+ supports keyboard navigation of text fields, text views, sidebars, collection views, and custom views. Unlike tvOS's purely directional model, iPadOS defines **focus groups** — sidebars, grids, lists — supporting two interactions: **Tab** moves focus *between* focus groups; **arrow keys** move focus *within* one. Two indications: the **halo effect** (focus ring) around custom views and fully opaque content in a list or collection cell, and the **highlighted appearance** (text in the accent color), which happens automatically on cell selection and is not a focus effect. **Customize the halo when necessary** — the system infers its shape from the item, but you can refine it for rounded corners or Bézier paths, and adjust its position when another component occludes or clips it, or when a badge must sit above it (`UIFocusHaloEffect`). **Ensure focus moves through custom views sensibly** — Tab moves through groups in reading order (leading to trailing, top to bottom); if you want focus to move down a vertical stack before moving trailing, identify the stack container as a single focus group (`focusGroupIdentifier`). **Adjust item priority** so a group's primary item receives focus when the group does (`UIFocusGroupPriority`).

**tvOS.** **In a full-screen experience, gestures interact with the content, not focus** — a full-screen item shows no focus, so people naturally expect gestures to affect the object. **Avoid displaying a pointer** — people navigate a fixed number of items by changing focus, not by dragging a tiny pointer around a huge screen. Free-form movement makes sense during gameplay (finding a hidden object, flying a plane); menus and interface elements use the focus model. If a pointer is genuinely required, make it highly visible and integrated. **Design for five focus states**: unfocused (less prominent) · focused (elevated, illuminated, animated) · pressed (instant visual feedback — a button might briefly invert its colors and animate) · selected (chosen or activated — a filled heart vs. an empty one) · unavailable (can't be focused or chosen; appears inactive). Because focusing often scales an item up, **supply assets at the larger focused size**, and make sure the enlarged item doesn't crowd its surroundings.

**visionOS.** Supports the same focus system as iPadOS and tvOS for connected keyboards and game controllers. **The hover effect people see when looking at an object is not a focus effect** — see Eyes. Not supported in iOS or watchOS.

---

## Eyes (visionOS)

People look at a virtual object to identify it as a target. The system highlights it — the **hover effect** — signaling that an indirect gesture like tap will work. Some components expand automatically on gaze: looking at a tab bar resizes the whole bar to reveal text labels (an individual tab still highlights first, so people can select before the expansion), and a button can reveal a tooltip.

> **Privacy:** visionOS gives you no direct information about where people are looking before they tap. With system components, you're told when people tap. The hover effect is applied out of process.

- **Always give people multiple ways to interact.** Support accessibility personalization.
- **Design for visual comfort.** Keep the objects people need within their field of view. In the Shared Space or a Full Space, the system places the first window or volume conveniently; in a Full Space you can request head-pose information to place 3D content. **Avoid requiring multiple quick eye adjustments**, either across a large area or through several depth levels.
- **Place content at a comfortable viewing distance** — at least a meter for anything people read or engage with over time. Don't place content very close unless the interaction is brief.
- **Prefer standard UI components** — they respond consistently to gaze; custom components with different visual feedback are hard to learn and remember.

**Making items easy to see**
- **Minimize visual distractions.** Visual noise makes targets hard to find, and **movement is worse** — people automatically look toward motion, especially in the periphery. Revealing content near a button someone is looking at can pull their gaze off the button involuntarily.
- **Provide enough space around each item.** Eyes make small, quick adjustments even while fixating, so crowded items are hard to hold gaze on. **≥16 pt margin around each interactive item, or centers ≥60 pt apart.**
- **Avoid a repeating pattern or texture filling the field of view.** Eyes can lock onto different elements of a pattern, making them appear to be at different depths.

**Encouraging interaction**
- **Use subtle cues** to draw attention to the most likely item: place it near the center, or use gentle motion, increased contrast, or variations in color or scale. Prefer noticeable over flashy.
- **Give interactive items rounded shapes.** Eyes are drawn to corners, making it hard to hold gaze on a shape's center. The rounder the shape, the easier to target.
- **Give a multi-element interactive component a containing shape** the system can highlight — an image with a label beneath it needs a custom region covering both, so the whole thing highlights when people look at either part.

**Custom hover effects.** You can design an effect that animates when people look at an element — a system or custom UI element, or a RealityKit entity — replacing or augmenting the standard effect. **Understand how they work first:** you create two states of the element, one showing the effect and one not, and the system applies the effect **out of process**. That means **you never learn when the effect is applied or which state the element is in**, and the effect can't run code that depends on knowing someone is looking. (A photo app can specify a different symbol for a favorited vs. unfavorited photo's hover effect — but the effect can't *perform* the favoriting, because the app is never told someone is looking.)
- **Prefer custom hover effects to emphasize or enhance a special moment.** People are used to the standard effects, so a custom one is especially noticeable. Too many — or using one where a standard effect suffices — dilutes your design, distracts, and can cause visual discomfort.
- **Choose the right delay.** **No delay** (default) for a subtle effect or one that invites interaction, like a knob appearing on a slider. **Short delay** so people can look and act without waiting — how tab bar expansion works. **Long delay** when the effect shows additional information, like a tooltip, since most people won't need it every time.
- **Keep one or more primary views unchanged across both states.** A constant element provides visual stability that helps people follow the transition; if everything moves or changes, people lose track of what happened.
- **Thoroughly test** — while wearing Apple Vision Pro. It's the only way to know whether an effect looks good, responds appropriately, and enlivens without distracting.

---

## Action button (iPhone, Apple Watch)

Gives quick access to a favorite feature. People choose the function during setup and can change it in Settings; App Shortcuts assigned to it run the way they would from Siri or Spotlight. On Apple Watch Ultra it supports activity actions including workouts and dives.

- **Support it with your app's essential functions** — a cooking app's "Start Egg Timer." **You don't need a shortcut that opens your app** — the system provides that, and your app icon, widgets, and complications already do it.
- **Write a short label per action.** People see these in Settings. Title case, starting with a verb, present tense, no articles or prepositions, **maximum three words**: "Start Race", not "Started Race" or "Start the Race."
- **Let the system teach people how to use it.** Don't repeat the guidance Settings already provides.

**iOS.** Let people use your actions without leaving their context — Live Activities and custom snippets provide functionality without opening the app (Set Timer prompts for a duration then starts a Live Activity countdown, never launching Clock).

**watchOS.** The first press can drop a waypoint, start a dive, or begin a workout. **Consider a secondary function that supports or advances the primary action** — people often press without looking, so a subsequent press must flow logically from the first and make sense in context (marking a segment, transitioning during a multi-part workout). **Think carefully before offering more than one secondary function** — it raises cognitive load. **Prefer subsequent presses for additional functionality, not stopping** — put stopping in your interface. **Pause on Action button + side button together** — the exception is a diving app, where pausing a dive can be dangerous. Not supported in iPadOS, macOS, tvOS, or visionOS.

---

## Digital Crown (Apple Vision Pro, Apple Watch)

**Apple Vision Pro.** People use it to adjust volume, adjust immersion in a portal, Environment, or Full Space, recenter content in front of them, open Accessibility settings, and exit to the Home View.

**Apple Watch.** Since watchOS 10, the primary input for navigation: turning it moves through Smart Stack widgets on the watch face, moves vertically through apps on the Home Screen, and within apps switches vertically paginated tabs and scrolls lists and variable-height pages. It also generates data you can use for inspecting values and operating controls.

> Apps don't respond to Digital Crown **presses** — watchOS reserves those for system functionality.

Most models provide haptic detents as the Crown turns; system controls like table views provide detents as new items scroll on.

- **Anchor your app's navigation to the Digital Crown.** List, tab, and scroll views are vertically oriented so people can move between the important parts of your interface. **Always back Crown interactions with corresponding touchscreen interactions.**
- **Consider using it to inspect data** where navigation isn't needed — World Clock advances the time of day at a selected location so people can compare it to their own.
- **Provide visual feedback.** Pickers change their displayed value. If you track turns directly, update your interface programmatically — without feedback, people assume the Crown does nothing in your app.
- **Match your interface's update rate to the turn speed.** People expect precise control. Don't update so fast that selecting a value becomes difficult.
- **Use default haptic feedback when it fits.** If it doesn't — if the detents don't match your animation — turn them off. Tables can use linear detents instead of row-based ones, which gives a more consistent experience when row heights vary a lot.

Not supported in iOS, iPadOS, macOS, or tvOS.

---

## Apple Pencil and Scribble (iPadOS)

- **Support what people intuitively expect from a marking instrument.** Draw on real-world experience — people want to write in the margins of documents and books.
- **Let people choose when to switch between Apple Pencil and finger input.** If you support marking, your *controls* must also respond to Apple Pencil — a control that doesn't looks unresponsive, like a malfunction or a dead battery. (Scribble is Pencil-only.)
- **Let people mark the moment Apple Pencil touches the screen.** No mode button, no tap first.
- **Respond to how people use it.** Apple Pencil may sense **tilt (altitude)**, **force (pressure)**, **orientation (azimuth)**, and **barrel roll**. Vary thickness and intensity. Keep pressure response simple and intuitive — continuous properties like ink opacity or brush size feel natural.
- **Provide visual feedback indicating a direct connection with content.** Apple Pencil should appear to manipulate what it touches directly and immediately; avoid disconnected actions or effects elsewhere on the screen.
- **Design for left- and right-handed use.** Don't place controls where either hand obscures them; if that's unavoidable, let people reposition them.

**Hover.** Use it to help people **predict** what will happen on contact — a preview showing the dimensions and color of the mark the current tool would make. **Avoid continuously modifying the preview with height** — it doesn't clarify the mark, and frequent variation is very distracting. **Don't use hover to initiate an action** — hovering is imprecise and doesn't require thinking about distance, so people would trigger actions (especially destructive ones) accidentally. **Preview a value near the middle of a dynamic range** — the maximum-pressure mark could occlude the marking area, and the minimum-pressure mark could be invisible, making the preview inaccurate. **Consider hover for relevant nearby interactions** — a contextual menu of tool sizes on squeeze or a modifier key, revealed near where people are marking so they don't move their hands. **Prefer hover previews for Apple Pencil, not for a pointing device** — the same feedback for both is confusing; you can restrict the preview to Apple Pencil.

**Double tap.** By default it toggles between the current tool and the eraser, but people can set it to toggle current/previous tool, show and hide the color picker, or do nothing. **Respect people's settings** where they make sense in your app. If the system settings don't apply, you can still use the gesture for a mode change — a 3D app toggling a mesh tool's raise and lower modes. **If you offer custom double-tap behavior, provide a control that lets people choose it**, so they know which mode they're in — make it discoverable, but **don't turn it on by default**. **Avoid using double tap to modify content** — accidental double taps happen, and people may not notice. Prefer easily undone actions; never a potentially destructive one.

**Squeeze (Apple Pencil Pro).** Available only when the paired iPad screen is on and the Pencil isn't touching it, so people may not see the result. People may also configure it to run an App Shortcut instead of your action. **Treat it as a single, quick gesture performing a discrete action** — people squeeze hard, so holding or repeating is tiring. **Display any revealed UI close to the Pencil** to strengthen the connection and keep people engaged. **Define nondestructive, easily undone actions.**

**Barrel roll (Apple Pencil Pro).** Changes the type of mark while marking — rotating the angle of a highlighter in Notes. **Use it only to modify marking behavior**, never for navigation or revealing controls; unlike double tap and squeeze, it's naturally tied to marking.

**Scribble.** People write wherever text is accepted; it's integrated into iPadOS and available to all apps by default in all standard text components except password fields.
- **Make text entry fluid and effortless.** With a custom text field, don't make people tap or select it before writing.
- **Make Scribble available everywhere people might want to enter text.** Apple Pencil encourages treating the screen like paper — in Reminders it's natural to create a reminder by writing in the blank space below the last item, even though there's no text field there (`UIIndirectScribbleInteraction`).
- **Avoid distracting people while they write.** Autocompletion text visually interferes with handwriting; hide placeholder text the moment writing begins so input doesn't appear to overlap it.
- **Keep the text field stationary while people write.** Moving a focused field is fine for keyboard input but makes handwriting feel out of control. If you can't prevent it, delay the change until people pause.
- **Prevent autoscrolling** while people write and edit. People avoid writing on top of scrolling text, and scrolling during selection selects the wrong range.
- **Give people enough space to write.** Increase a small text field's size before people begin or when they pause — but **never resize while they're writing** (`UIScribbleInteraction`).

**Custom drawing (PencilKit).** Low-latency notes, annotation, and drawing, plus a custom canvas with a state-of-the-art tool picker and ink palette. **Help people draw on top of existing content** — PencilKit canvas colors adapt to Dark Mode by default, which you want to prevent when marking up a PDF or photo so the markup stays sharp and visible. **Consider custom undo and redo buttons in a compact environment** — the tool picker includes them in a regular environment but not a compact one; a toolbar works, and supporting the standard three-finger undo/redo gesture covers both. Not supported in iOS, macOS, tvOS, visionOS, or watchOS.

---

## Camera Control (iPhone 16 and 16 Pro)

Provides direct access to your camera experience. A light press opens an overlay extending from the device bezel; a light double-press shows the available controls; sliding a finger adjusts the selected control's value.

**Two control types:** a **slider** provides a range of values (contrast); a **picker** offers discrete options (grid on/off). The system also provides standard zoom factor and exposure bias controls you can include.

- **Use SF Symbols.** Custom symbols aren't supported — choose one that clearly denotes the behavior (`bolt.fill` for flash, `camera.filters` for filters). See the Camera & Photos section of the SF Symbols app. Symbols don't represent current state.
- **Keep control names short.** Labels follow Dynamic Type sizes and long names obscure the viewfinder.
- **Include units or symbols with slider values** for context — EV, %, or a custom string (`localizedValueFormat`).
- **Define prominent values** — the ones people choose most often, or evenly spaced increments like major zoom factors. Sliding lands on them more easily (`prominentValues`).
- **Make space for the overlay in the viewfinder.** It occupies the screen area adjacent to the Camera Control in both orientations. Place your UI outside those areas, maximize the viewfinder, and let the overlay appear and disappear over it.
- **Minimize distractions** — a large preview with as few distractions as possible. **Don't duplicate controls** between your UI and the overlay.
- **Enable or disable controls by camera mode** (disable video controls while taking photos). The overlay supports multiple controls, but you can't add or remove them at runtime.
- **Arrange controls thoughtfully** — common controls toward the middle for quick access, less used ones on either side. The system remembers the last control used in your app.
- **Let people launch your experience from anywhere** with a locked camera capture extension, so the Camera Control can open your camera from the locked device, the Home Screen, or within other apps.

Not supported in iPadOS, macOS, watchOS, tvOS, or visionOS.

---

## Remotes (tvOS)

The Siri Remote combines specific buttons with a clickpad and touch surface.

- **Prefer standard gestures for standard actions.** Outside active gameplay, people expect the remote to behave the same in every app. Redefining standard behaviors causes confusion.
- **Be consistent with the tvOS focus experience.** Combine gestures with focus in familiar ways — always move focus in the same direction as the gesture.
- **Provide clear feedback.** Resting a thumb lightly on the remote shows people where to swipe down to reveal an info area.
- **Define new gestures only when it makes sense.** Custom gestures can be part of the fun in gameplay; elsewhere people expect standard ones.
- **Differentiate press from tap, and ignore inadvertent taps.** Pressing is intentional — good for choosing a button, confirming a selection, and initiating actions during gameplay. Tapping suits navigation and revealing information, but people tap by accident when resting a thumb, picking up the remote, moving it, or handing it over — so it's often best not to respond to taps during live video playback.
- **Consider tap position** — the remote distinguishes up, down, left, and right taps on the touch surface. Respond to positional taps only when it's intuitive and discoverable.
- **Open the parent of the current screen on Back.** At the top level, the parent is the Apple TV Home Screen; within an app, the parent is defined by your hierarchy and isn't necessarily the previous screen. **The exception is active gameplay**, where repeated accidental Back presses are easy: respond by opening an in-game pause menu with a different interaction to reach the main menu, and close the menu and resume on a subsequent Back press. (Press and hold always goes to the Home Screen.)
- **Respond correctly to Play/Pause** during media playback.

**Gestures.** **Swipe** scrolls large numbers of items with movement that starts fast and slows by swipe strength; swiping up or down at the remote's edge speeds through items very quickly. **Press** activates a control or selects an item, and precedes a swipe to activate scrubbing mode.

**Expected button behavior**

| Button or area | In an app | In a game |
|---|---|---|
| Touch surface (swipe) | Navigates; changes focus | Directional pad behavior |
| Touch surface (press) | Activates a control or item; navigates deeper | Primary button behavior |
| Back | Returns to previous screen; exits to Home Screen | Pauses/resumes; returns to previous screen, main menu, or Home Screen |
| Play/Pause | Activates, pauses, resumes playback | Secondary button behavior; skips intro video |

**Compatible remotes** may include buttons for browsing live TV — an EPG button, page up/down, channel change. **If your live-viewing app provides an EPG, respond to those buttons as people expect**: a guide or browse button opens the EPG, page up/down navigates it, and nothing else co-opts them while people are browsing. People can also tap the upper or lower area of the Touch surface to browse. Without an EPG, the system routes those presses to the default guide app. **While your content plays, page up/down changes the channel** — the same buttons behave differently in the two contexts. Not supported in iOS, iPadOS, macOS, visionOS, or watchOS.

---

## Game controls

A game can support physical game controllers or the platform's default interaction. **Support both.** Not every player has a controller, and players appreciate using the interaction method they know on the platform they're on.

**Touch controls (iOS, iPadOS).** Virtual controls on top of game content, plus direct interaction with game elements (Touch Controller framework).
- **Decide whether virtual controls are warranted.** They benefit games with many actions or continuous movement; sometimes direct interaction with in-game objects is more immersive. **Look for ways to replace virtual controls with in-game gestures** — tapping an object to select it instead of adding a selection button.
- **Place virtual buttons where they're easy to reach.** Account for device boundaries and safe areas. **Don't overlap system features** like the Home indicator or Dynamic Island. Put frequently used buttons near a player's thumbs, avoiding the circular regions reserved for movement and camera input. Put secondary controls like menus at the top.
- **Size controls adequately**: frequently used controls **≥44×44 pt**, less important ones like menus **≥28×28 pt**.
- **Always include visible and tactile press states.** A virtual control without one feels unresponsive. Use a visual effect visible even under a finger — a glow — and combine it with sound and haptics.
- **Use symbols that communicate the action.** A weapon graphic for attack. **Avoid abstract shapes and controller-based naming** (A, X, R1) — they're harder to learn and remember.
- **Show and hide controls to reflect gameplay.** Hide a control when its action is unavailable or irrelevant; hide movement controls until the player touches the screen. Touch controls are dynamic — use it.
- **Combine functionality into a single control.** Redesign mechanics requiring simultaneous or sequential button presses. Use double tap and touch-and-hold for variations of one action (touch and hold for a powered-up attack), and merge related actions (walk and sprint) into one control.
- **Map movement and camera controls predictably.** Movement on the left, camera on the right. Maximize the input area for both. For movement, **show a virtual thumbstick wherever the player's thumb lands** rather than at a fixed position. For camera, **prefer direct touch panning** to a virtual thumbstick.

**Physical controllers**
- **Support the platform's default interaction method** as a fallback. A controller is an optional purchase; every iPhone and iPad has a touchscreen, every Mac a keyboard and pointing device, every Apple TV a remote, every Apple Vision Pro eyes and hands.
- **Tell people about controller requirements.** tvOS and visionOS let you require a controller, and the App Store shows a "Game Controller Required" badge. People can open your game without one connected — check for it and prompt gracefully.
- **Automatically detect a paired controller** and get its profile rather than making people set it up.
- **Customize onscreen content to match the connected controller.** The Game Controller framework assigns standard names by placement, but real controllers differ in colors and symbols — use the connected controller's labeling scheme.
- **Map controller buttons to expected UI behavior** outside gameplay, across all Apple platforms:

| Button | UI behavior |
|---|---|
| A | Activates a control |
| B | Cancels an action or returns to the previous screen |
| X, Y, left/right trigger | — |
| Left shoulder / right shoulder | Navigates left / right to a different screen or section |
| Left/right thumbstick, directional pad | Moves selection |
| Home / logo | Reserved for system controls |
| Menu | Opens game settings or pauses gameplay |

- **Support multiple connected controllers**, using labels and glyphs matching the one actively in use, and the right per-player labels in multiplayer. When referring to buttons on multiple controllers, list them together.
- **Prefer symbols to text** for controller elements. The Game Controller framework provides SF Symbols for most elements across brands — especially helpful for players not experienced with controllers, who otherwise hunt for a labeled button mid-game.

**Keyboards**
- **Prioritize single-key commands** — faster to perform, especially while using a mouse or trackpad. Use the first letter of a menu item (I for Inventory, M for Map), and consider mapping the main action to the Space bar for its size.
- **Test key binding comfort on an Apple keyboard.** A binding using Control on a non-Apple keyboard might be better on Command, which sits next to the Space bar and is easy to reach from W, A, S, D.
- **Take key proximity into account.** If players navigate with WASD, use nearby keys for other high-value commands; map closely related actions to physically adjacent keys (number keys for inventory categories).
- **Let players customize key bindings.** Provide reasonable defaults, but many people need to remap for comfort and play style.

**visionOS.** Match spatial game controller behavior to hand input. In addition to wireless controllers, visionOS supports spatial controllers like the PlayStation VR2 Sense controller. Let players interact the way they would with their hands: **looking at an object and pressing the left or right trigger for indirect interaction, and reaching out and pressing a trigger for direct interaction.** Not supported in watchOS.

---

## Gyroscope and accelerometer

Available in iOS, iPadOS, and watchOS; tvOS apps can use gyroscope data from the Siri Remote (Core Motion).

- **Use motion data only for a tangible benefit** — activity and health feedback, enhanced gameplay. Don't gather data just to have it.
- **You must supply a purpose string** explaining why you need motion data; the system displays it in the permission request.
- **Outside active gameplay, avoid motion for direct manipulation of your interface.** Motion gestures are hard to replicate precisely, physically challenging for some people, and costly to battery.

---

## Nearby interactions

Support on-device experiences that integrate the presence of nearby people and objects — playing music on iPhone and continuing on a HomePod mini by bringing them together. Requires Ultra Wideband hardware and the Nearby Interaction framework. People grant permission for their device to interact while using your app; the APIs preserve privacy with randomly generated identifiers lasting only as long as the session.

- **Look at the task from the perspective of the physical world.** People can transfer a song through your UI — but initiating it by bringing the devices together roots the task in the physical world and makes it feel easy and natural.
- **Use distance, direction, and context to inform the interaction.** Prioritizing nearby, contextually relevant information makes experiences feel organic. The iOS share sheet suggests a likely recipient from frequent and recent contacts, and combines that with nearby-device information to suggest the closest contact the person is facing.
- **Let changes in physical distance guide the interaction.** People expect perception to sharpen as they approach. When people use iPhone to find an AirTag, the display transitions from a directional arrow to a pulsing circle as they get closer.
- **Provide continuous feedback.** Uninterrupted response to movement reflects the dynamism of the physical world and strengthens the connection between the interaction and the task.
- **Use multiple feedback types.** Fluidly transitioning among visual, audible, and haptic feedback makes the task feel more real, and lets you match the feedback to the context — visual while people look at the screen, audible and haptic while they interact with their environment.
- **Never make a nearby interaction the only way to do something.** Not everyone can experience one.
