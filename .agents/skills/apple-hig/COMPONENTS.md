# Components

System-defined components give people a familiar, consistent experience — and give you accessibility support, appearance adaptation, and interaction states for free. Prefer them. Build custom only when nothing fits, and then make it behave *exactly* like the system equivalent or make it obviously different.

Availability is noted where a component isn't universal.

---

# Menus and actions

## Buttons

A button initiates an instantaneous action. Three attributes: **style** (size, color, shape), **content** (symbol, label, or both), **role** (semantic meaning).

- **Hit region of at least 44×44 pt** (60×60 pt in visionOS), with enough space around it to be visually distinguishable.
- **Always include a press state for a custom button.** Without one it feels unresponsive.
- Use a **prominent style for the most likely action** — the system applies the accent color to the background. Keep prominent buttons to **one or two per view**; more increases cognitive load.
- **Distinguish the preferred choice by style, not size.** Equal-size buttons signal a coherent set; different sizes look inconsistent.
- Avoid label colors similar to your content-layer background. Over colorful content, prefer the monochromatic label appearance.
- Make each button's purpose obvious. Associate familiar actions with familiar symbols (`square.and.arrow.up` for share) — see Standard icons in FOUNDATIONS.md. Use text when a short label communicates better: a few words, title case, ideally starting with a verb ("Add to Cart").

**Roles**
- **Normal** — no specific meaning.
- **Primary** — the default; responds to Return, and in a temporary view (sheet, editable view, alert) closing it on Return.
- **Cancel** — cancels the current action.
- **Destructive** — can destroy data; renders in system red.

**Never assign the primary role to a destructive button**, even when it's the most likely choice. Prominence makes people press before reading.

**iOS/iPadOS.** Configure a button to show an **activity indicator** for actions that don't complete instantly, optionally with an alternative label ("Checkout" → "Checking out…"). The system hides the button's image and shows the indicator beside the label.

**macOS button types**
- **Push button** — the standard type. Text, symbol, icon, image, or text+image. Can be the default button and can be tinted. A **flexible-height** push button (same corner radius and padding) handles two lines of text or a tall icon. Append a **trailing ellipsis** when the button opens another window, view, or app. Consider spring loading.
- **Square (gradient) button** — initiates an action related to a view (adding or removing table rows). Symbols or icons, no text. Lives *in* the view, usually within or beneath it — never in a toolbar or status bar. Prefer an SF Symbol. No introductory label needed.
- **Help button** — a circular button with a question mark that opens help documentation. **One per window, maximum.** Open the topic related to the current context, or the top level if nothing applies. Position: in a dialog with dismissal buttons, the lower corner opposite them, vertically aligned; in a dialog without them, or a settings window/pane, the lower-left or lower-right corner. Use it in a view, never in the window frame. No explanatory text.
- **Image button** — displays an image, symbol, or icon in a view (never the window frame; use a toolbar item there). Include ~10 px of padding between the image and the button edges so near-misses register. Generally omit the system border. Place any label below it.

**visionOS.** Buttons have a visible background and play sound on interaction. Three shapes: circle (icon only), rounded rectangle or capsule (text only), capsule (icon + text). Four states: idle, hover, selected, unavailable — **custom hover effects aren't supported**. Sizes: mini 28 pt · small 32 pt · regular 44 pt · large 52 pt · extra large 64 pt.
- Prefer a discernible background shape and fill — except inside a toolbar, context menu, alert, or ornament, where the container already provides visibility. On a glass window, use the **thin** material for the background; floating in space, use **glass**.
- **Never use a white fill with black text/icons** — the system reserves that for the toggled state.
- **Prefer circular or capsule shapes.** Eyes are drawn to corners, making it hard to hold gaze on a shape's center; the rounder the shape, the easier to look at steadily. A standalone button should be a capsule.
- Centers ≥60 pt apart; if buttons are ≥60 pt, add 4 pt padding so hover effects don't overlap. Avoid vertical stacks or horizontal rows of small/mini buttons.
- Rounded rectangles in a vertical stack; capsules in a horizontal row.
- Use standard controls to get the audible feedback people know — visionOS has no haptics.

**watchOS.** All inline buttons use the capsule shape and gain a material effect against content. Toolbar buttons go in the corners (the system moves the time and title to accommodate) and adopt Liquid Glass. **Prefer full-width buttons for primary actions.** Two side-by-side buttons must share a height and use images or short titles. Use toolbar buttons for navigation to related areas or contextual actions. Keep vertical stacks of one- and two-line text buttons the same height.

## Menus

A menu reveals options on interaction. The labeling and organization rules below apply to every kind of menu.

**Labels**
- Clear and succinct. A menu item that initiates an action gets a verb or verb phrase (View, Close, Select).
- **Title-style capitalization** — capitalize everything except articles, coordinating conjunctions, and short prepositions, and always the last word.
- **Remove articles** (a, an, the) — they lengthen without clarifying.
- **Dim unavailable items.** Keep the parent menu itself available so people can discover what's in it.
- **Append an ellipsis** when the action needs more input before completing.

**Icons.** Represent common actions with the standard symbols. Use icons sparingly and purposefully — to highlight common actions and key features, file locations, connected devices, visual concepts (rotate, flip), and user content (folders, documents). Don't use one if you can't find a clear representation. **Give every item in a group an icon, or none.**

**Organization**
- **List important or frequent items first** — people scan from the top.
- **Group logically** and separate groups with a separator (a line or a gap depending on platform).
- **Keep related commands together** even when they differ in importance (Paste and Match Style belongs with Copy, Cut, Paste).
- **Be mindful of length.** A long menu costs attention and hides its own contents. Divide it, or use a submenu. The exception is user-defined or dynamically generated content (Safari's History and Bookmarks) — people expect it to grow, and scrolling is fine.

**Submenus.** Use sparingly; each one adds complexity and hides items. A good trigger is a term repeated in more than two items in a group (Sort by Date / Score / Time → a "Sort by" item with a submenu). **Limit to one level.** More than ~5 items suggests a new menu instead. A submenu must stay available even when all its items are unavailable. **Prefer a submenu to indentation** — indentation is inconsistent with the system and doesn't express relationships clearly.

**Toggled items.** Use a changeable label describing the current state (Show Map ↔ Hide Map). Add a verb if the label is ambiguous (HDR On is a state or an action; Turn HDR On isn't). Sometimes showing both items is clearer — a game listing both Take Account Online and Take Account Offline, with only the applicable one available. Use a **checkmark** to show an attribute currently in effect; checkmarks are easy to scan. Consider an item that removes several toggled attributes at once ("Plain").

**In-game menus.** Navigate with the platform's default interaction method. Verify menus are readable and tappable on every platform — scaling game content down for a phone often shrinks menus past usability. See Touch controls in INPUTS.md.

**iOS/iPadOS layouts.** **Small** — a row of four unlabeled symbol items above a list. **Medium** — a row of three symbol-plus-label items above a list. **Large** (default) — everything in a list. Use medium for three important, frequent actions (Notes: Scan, Lock, Pin). Use small only for closely related actions that group naturally (Bold, Italic, Underline, Strikethrough), with symbols recognizable without labels.

**visionOS.** Supports the small and large layouts. Menus can be presented from 3D content, can extend outside window bounds, and support a **breakthrough effect** so they stay visible through occluding content. **Prefer subtle** — it blends with surrounding content while preserving depth and context, and is what `automatic` resolves to. Use `prominent` only when the menu must display over the entire scene (it can disrupt and cause discomfort); use `none` deliberately, e.g. a puzzle game where occlusion is the point. **Display the menu near the content it controls** — people must look at an item before tapping, and a distant effect goes unseen.

## Toolbars

A toolbar provides frequently used commands, controls, navigation, and search along the top or bottom edge, holding three kinds of content: the current view's **title**, **navigation controls** and search, and **actions** (bar items).

- **Choose items deliberately.** Define which items move to the overflow menu as the view narrows. The system adds an overflow menu automatically in macOS and iPadOS — don't add one manually, and don't design a layout that overflows by default.
- Add a **More** menu for less important extra actions, and only if you really need it.
- In iPadOS and macOS, consider letting people **customize** the toolbar — especially valuable in apps with many items, advanced functionality, or long sessions.
- **Reduce toolbar backgrounds and tinted controls.** Custom backgrounds interfere with system background effects. Let the content layer inform the toolbar's appearance and use a `ScrollEdgeEffectStyle` to distinguish the bar from the content.
- Avoid label colors similar to your content backgrounds; over colorful content prefer the monochromatic appearance.
- Prefer standard components — their corner radii are concentric with the bar's. Custom components must match.
- Consider hiding toolbars for a distraction-free experience, contextually and reversibly.

**Titles.** Give each window a useful title so people can confirm location and distinguish windows. Leave it empty if it's redundant (a single Notes window doesn't title the note; multiple windows get titled by first line). **Never use your app name as a title.** Keep it under ~15 characters.

**Navigation.** A navigation toolbar sits at the top (in iOS, sometimes called a navigation bar). **Use the standard Back and Close buttons** with the standard symbols — not text labels reading "Back" or "Close." Custom versions must look the same, behave the same, and be used consistently.

**Actions.** Prioritize what people are most likely to want — usually the most frequent commands, sometimes the ones mapping to the most important objects. Make every control's meaning clear; prefer simple recognizable symbols over text, except for actions like *edit* that symbols represent poorly. **Prefer system symbols without borders** — the section already provides a container, and the system defines hover and selection appearances. Use the `.prominent` style for one key action (Done, Submit), placed on the trailing side.

**Item groupings** — three positions:
- **Leading** — return-to-previous-document and sidebar toggle at the far edge, then the view title, then optionally a document menu (Duplicate, Rename, Move, Export). **Not customizable**, so these stay available.
- **Center** — common useful controls, and the title if it isn't leading. Customizable in macOS and iPadOS; collapses into the system overflow menu as the window narrows.
- **Trailing** — items that must remain available, inspector buttons, an optional search field, the More menu, and the primary action (Done). **Always visible at every size.**

Group by function and frequency. Put navigation and critical actions (Done, Close, Save) in dedicated, visually distinct sections. Keep groupings and placement consistent across platforms. **Aim for a maximum of three groups.** Keep text-labeled actions separate — a text button beside a symbol button reads as one combined control, and adjacent text buttons run together; insert fixed space between them.

**iOS.** Space is tight — include only the essentials and put the rest in a More menu. Use a **large title** that collapses on scroll and returns at the top (`prefersLargeTitles`). **iPadOS.** A toolbar and a tab bar can share the top horizontal space. **macOS.** The toolbar lives in the window frame, below or integrated with the title bar; titles can be inline; toolbar items have no bezel. **Every toolbar item must also be a menu bar command** (people can customize or hide the toolbar) — but not every menu command deserves a toolbar item. **visionOS.** The system toolbar sits along the bottom edge, above the window controls, slightly forward on the z-axis, with a variable blur anchoring it above scrolling content. Supply a symbol or a text label per item; looking at a symbol reveals its label. **Never create a vertical toolbar** — tab bars are vertical in visionOS. Prevent windows from resizing below the toolbar's width, since there's no menu bar fallback. Offer contextually relevant toolbar controls in modal states, and restore the standard ones on exit. **Avoid pull-down menus in a toolbar** — they're hard to discover and may obscure the window controls below. **watchOS.** Toolbar buttons in the top corners (`topBarLeading`, `topBarTrailing`) or along the bottom (`bottomBar`) stay visible over scrolling content. A **scrolling toolbar button** (`primaryAction`) stays hidden until people scroll up — well suited to an important action that isn't the view's primary function (Mail's New Message at the top of the Inbox).

## Context menus

A context menu gives access to functionality directly related to an item, without cluttering the interface. It's hidden by default, revealed by touch-and-hold or pinch-and-hold (visionOS, iOS, iPadOS), Control-click (macOS, iPadOS), or secondary click on a Magic Trackpad.

- **Prioritize relevance.** Not for advanced or rare items — for what people most likely need right now. Mail's inbox context menu has reply and move, not message editing or mailbox management.
- **Keep it short.** A long context menu is hard to scan and scroll.
- **Be consistent throughout the app.** Partial support makes people think something's broken.
- **Always duplicate context menu items in the main interface.** In macOS, every command belongs in the menu bar.
- Submenus: **one level maximum**, with an intuitive title.
- **Hide unavailable items — don't dim them.** (macOS Cut/Copy/Paste are the exception.)
- Place frequent items where people will encounter them first. Menus open above or below the content depending on space, so consider reversing the order to match.
- **Don't show keyboard shortcuts** — the context menu *is* the shortcut.
- Use separators; aim for no more than about three groups.
- iOS, iPadOS, visionOS: list destructive items at the end and mark them `destructive` so the system can color them red.
- **Title**: usually none. Include one only when it clarifies scope (Mail shows the number of selected messages).
- Represent actions with the standard system icons.

**iOS/iPadOS.** Provide either a context menu or an edit menu for an item, never both. In iPadOS, consider a context menu on empty space for creating new objects (Files creates a folder this way). A context menu can show a **preview** of the content near the commands — people can tap it to open or drag it elsewhere. Prefer a graphical preview that clarifies the target. Adjust the preview's clipping path to match the image's contours so the corners don't appear to change during the emergence animation. **visionOS.** Consider a context menu instead of a panel or inspector to keep the space uncluttered. Don't let its height exceed the window's — system controls sit above and below the window edges. Not supported in watchOS.

## Edit menus

An edit menu applies to selected content — text, images, files, and objects like contact cards, charts, or map locations. In iOS, iPadOS, and visionOS the system detects the selected data type and can add related actions (selecting an address adds "Get directions").

Appearance varies: iOS shows a compact horizontal list on touch-and-hold or double-tap, with a trailing chevron expanding it into a context menu. iPadOS shows the compact list for touch and a context menu for keyboard or pointer. macOS puts editing commands in a context menu and in the menu bar Edit menu. visionOS opens a horizontal bar on pinch-and-hold, or a context menu. tvOS and watchOS have no edit menu.

- **Prefer the system-provided edit menu** (`UIResponderStandardEditActions`). A custom menu presenting the same commands is redundant and confusing.
- Let people use the system interactions they know — don't invent a custom reveal.
- Offer only contextually relevant commands; remove or dim the rest (no Copy with nothing selected, no Paste with an empty pasteboard).
- List custom commands near related system ones — custom formatting after the system format section. Don't overwhelm.
- Let people **select and copy noneditable text** where it's useful (a caption, a status) — but not control labels.
- Support undo and redo. Edit menus act without confirmation.
- **Avoid duplicate controls** for edit menu functions. People look in the edit menu or use keyboard shortcuts; redundant controls crowd out things people don't already know about.
- Differentiate deletion types: **Delete** behaves like the Delete key; **Cut** copies to the pasteboard first.
- Short labels: verbs or verb phrases.
- iOS/iPadOS: your menu must work in both the compact and vertical styles. Adjust placement if the default (above or below the selection) would cover important content — you can move it, but not reshape it or its pointer.

## Pop-up buttons

Displays a menu of **mutually exclusive options**; the menu closes on selection and the button can update to show the current selection.

- Use for a **flat list of mutually exclusive options or states**. Use a pull-down button instead if you need a list of *actions*, multi-selection, or a submenu.
- **Provide a useful default** — the item most people are likely to want.
- Give people a way to predict the options without opening it: an introductory label, or a button label describing the effect.
- Good when space is limited and the options don't all need to be visible.
- Add a **Custom** option for occasionally useful extras rather than cluttering the interface. Explanatory text below the list can help.
- iPadOS: inside a popover or modal view, a pop-up button can replace a disclosure indicator for a small, well-defined option set — no navigation to a detail view required.
- Not supported in tvOS or watchOS.

## Pull-down buttons

Displays a menu of items or **actions** directly related to the button's purpose; the menu closes and the action runs.

- Use for commands related to the button's own action — an Add button that specifies what to add, a Sort button that picks an attribute, a Back button that picks a destination. If you need mutually exclusive non-command choices, use a pop-up button.
- **Don't hide a view's primary actions in one.** They must be discoverable.
- **Balance length**: **at least three items** makes the interaction worthwhile; one or two are better served by buttons or toggles. Too many slows people down.
- Show a menu title only if it adds meaning — usually the button's content plus descriptive items is enough.
- Mark destructive items and confirm intent. Menus color them red; on selection the system shows an action sheet (iOS) or popover (iPadOS) for confirmation, in a different location requiring deliberate dismissal.
- Include a symbol with an item when it adds value; SF Symbols stay aligned with the text at every scale.
- iOS/iPadOS: a specific gesture can reveal a pull-down menu (touch-and-hold on Safari's Tabs button). A **More** button offers range in constrained space but hurts discoverability — the ellipsis doesn't predict its contents. Weigh convenience against discoverability.
- Not supported in tvOS or watchOS.

## The menu bar (macOS, iPadOS)

**Order:** *YourAppName* · File · Edit · Format · View · app-specific menus · Window · Help. macOS adds the Apple menu at the leading edge and menu bar extras at the trailing edge.

- **Support the default menus and their order.** The system implements much of the standard functionality (Edit > Copy works on selected text in a standard field automatically).
- **Always show the same set of items.** Keeping them visible teaches people what your app can do. Disable, don't hide.
- Use the standard icons for common actions.
- **Support the standard keyboard shortcuts.** Define custom ones only when necessary.
- **Prefer short, one-word menu titles.** They take little space and scan quickly. Multi-word titles use title case.

**App menu** — About *App* (short name, ≤16 characters, no version number; followed by a separator so it stands alone) · Settings… (app-level only; document-specific settings go in File; custom app-configuration items follow Settings in the same group) · Services (macOS) · Hide *App* / Hide Others / Show All (macOS) · Quit *App* (Option changes it to Quit and Keep Windows).

**File menu** — New *Item* (name the type your app creates) · Open (ellipsis if a separate interface is needed) · Open Recent (recognizable names, not paths, most recent first, with Clear Menu) · Close (Option → Close All; Close Tab in tabbed windows — consider adding Close Window) · Close Tab (Option → Close Other Tabs) · Close File (all windows for a file) · Save (autosave periodically; prompt for name and location on a new document; offer format choice via a pop-up in the Save sheet) · Save All · **Duplicate** (Option → Save As; prefer Duplicate to Save As/Export/Copy To/Save To, which don't clarify the relationship between original and new file) · Rename… · Move To… · Export As… (reserve for formats your app doesn't normally handle) · Revert To (submenu of recent versions plus the version browser) · Page Setup… (only for document-specific print parameters; global or frequently changed ones belong in the Print panel) · Print…

**Edit menu** — Undo / Redo (clarify the target: "Undo Paste and Match Style", "Redo Typing") · Cut · Copy · Paste · Paste and Match Style · **Delete** (name it Delete, not Erase or Clear — it's the Delete key's equivalent) · Select All · Find (submenu: Find, Find and Replace, Find Next, Find Previous, Use Selection for Find, Jump to Selection) · Spelling and Grammar · Substitutions · Transformations (Make Uppercase / Lowercase / Capitalize) · Speech (Start/Stop Speaking) · Start Dictation and Emoji & Symbols (added automatically at the bottom). Decide whether Find belongs here or in File — if you search files or objects rather than text, File may be better.

**Format menu** — Font (Show Fonts, Bold, Italic, Underline, Bigger, Smaller, Show Colors, Copy Style, Paste Style) · Text (Align Left, Align Center, Justify, Align Right, Writing Direction, Show Ruler, Copy Ruler, Paste Ruler). Omit the menu if you don't support formatted text.

**View menu** — customizes the appearance of *all* windows (not navigation or window management). Show/Hide Tab Bar · Show All Tabs / Exit Tab Overview · Show/Hide Toolbar · Customize Toolbar · Show/Hide Sidebar · Enter/Exit Full Screen. **Provide a View menu even for a subset** — an app with only full-screen support still gets a View menu with that one item. Each show/hide title must reflect the current state.

**App-specific menus** sit between View and Window. Put custom commands here — it's where people look, it enables keyboard shortcuts, and it makes commands available to Full Keyboard Access. Excluding commands, even advanced ones, makes them hard for everyone to find. Reflect your app's hierarchy (Mail: Mailbox → Message → Format) and order from most to least general.

**Window menu** — navigate, organize, and manage windows (not appearance, not closing). Minimize (Option → Minimize All) · Zoom (Option → Zoom All; **never use Zoom for full screen**) · Show Previous/Next Tab · Move Tab to New Window · Merge All Windows · Enter/Exit Full Screen (only if you have no View menu) · Bring All to Front (Option → Arrange in Front) · the list of open windows, **alphabetically**, excluding panels and modal views. **Provide a Window menu even with one window**, including Minimize and Zoom, for Full Keyboard Access. Consider items for showing and hiding panels (the font and text color panels are already in Format).

**Help menu** — trailing end. Send *App* Feedback to Apple · *App* Help (Help Book format gets an automatic search field). Separate additional items (registration, release notes) with a separator, and keep the total small — link the rest from inside your documentation.

**Dynamic menu items** change behavior with a modifier key (Option turns Minimize into Minimize All). **Never make one the only way to do something** — they're hidden by default. Use them primarily in menu bar menus (they're even harder to find in contextual or Dock menus). **Require only a single modifier key** — chording while opening a menu is physically awkward and further hurts discoverability. macOS sizes menus to the widest item, dynamic ones included.

**iPadOS differences.** Hidden until revealed (pointer to the top edge or swipe down), centered rather than leading-aligned, no menu bar extras, no Apple menu, window controls appear in it when full screen, and the App menu omits About, Services, and visibility items. Because it's often hidden, **every function must be reachable through the UI**, and dynamic menu items (keyboard-only) always need an alternative. Don't use the menu bar as a catch-all. Reserve `YourAppName > Settings` for the iPadOS Settings page and link an in-app preferences area beneath it in the same group. For tab-style navigation, consider adding each tab to the View menu with a key binding. Group into submenus more aggressively — rows are taller than on Mac.

**Menu bar extras (macOS).** An icon at the trailing end exposing app functionality while your app runs, even when it isn't frontmost. The system hides extras to make room for app menus. Use a symbol; black and clear define the shape, and the system colors it for light/dark bars and selection. The menu bar is **24 pt** tall. **Show a menu, not a popover**, unless the functionality is genuinely too complex. **Let people decide** whether your extra appears — usually a setting, though offering it during setup helps discoverability. Don't rely on its presence or predict its location. Expose the same functionality elsewhere too, such as a Dock menu.

## Activity views (share sheets)

An activity view presents sharing activities (Messages) and actions (Copy, Print) plus frequently used apps. People usually reveal it from an Action button. It appears as a sheet or popover depending on device and orientation. App-specific actions are listed before system-wide ones by default, and people can edit the list.

- **Don't duplicate common actions.** A second Print action is confusing. If you need similar app-specific functionality, give it a distinct title ("Print Transaction").
- Use a symbol for a custom activity; a custom interface icon should be centered in a ~70×70 px area.
- **Write a succinct title** — a verb or brief verb phrase. Long titles wrap and truncate. No company or product name (share activities display the company name below the icon already).
- Make activities contextually appropriate. You can't reorder system tasks, but you can exclude irrelevant ones and control which custom tasks appear.
- **Use the Share button** to display it. Don't offer an alternative path to the same thing.

**Share and action extensions.** Share extensions send information to apps, accounts, and services; action extensions perform content-specific tasks in place (bookmark, copy a link, edit an inline image, translate). iOS and iPadOS show both in the share sheet; macOS shows share extensions via a toolbar Share button or context menu, and action extensions on hover over embedded content, via a toolbar button, or as a Finder quick action.
- **Prefer the system composition view** for a share extension. For an action extension, include your app name, and include recognizable elements of your app's interface so the relationship is clear.
- **Streamline and limit interaction** — ideally a single tap.
- **Don't place a modal view above your extension** (an alert may be necessary; nothing else).
- A share extension uses your app icon automatically. For an action extension, prefer a symbol or an interface icon that identifies the task.
- The activity view dismisses immediately on completion. For a lengthy operation, continue in the background and let people check status in your main app — notify only about a *problem*, never about routine completion.
- Not supported in macOS (share sheet), tvOS, or watchOS.

## Ornaments (visionOS only)

An ornament floats in a plane parallel to and slightly in front of its window, moving with the window and unaffected by scrolling. It can sit on any edge and contain buttons, segmented controls, and other views. The system builds toolbars, tab bars, and video playback controls as ornaments; you can build custom ones.

- Use one for frequently needed controls or information in a consistent location (Music's Now Playing controls).
- **Keep it visible** in most cases; hiding is reasonable when people dive into content (a video, a photo).
- With multiple ornaments, prioritize the window's overall visual balance — they add visual weight and complexity. Consider moving elements back into the window.
- **Keep the ornament's width at or below the window's** — a wider ornament interferes with a tab bar or vertical content on the side.
- Consider borderless buttons: the glass background usually makes borders unnecessary, and the system applies the hover effect automatically.
- Use system toolbars and tab bars rather than rebuilding them as custom ornaments.

## Dock menus (macOS only)

Revealed by secondary-clicking the app's Dock icon; combines system-provided and custom items. (iOS and iPadOS have **Home Screen quick actions** instead.)

- Label and organize items following the general Menus rules.
- **Make custom Dock menu items available elsewhere** — not everyone uses the Dock menu.
- Prefer high-value items: currently or recently open windows, and a few actions useful when your app isn't frontmost or has no open windows (Mail offers Get New Mail and New Message alongside its windows).

## Home Screen quick actions (iOS, iPadOS)

Revealed by touch-and-hold on an app icon. Each has a title, an interface icon (leading or trailing depending on the icon's Home Screen position), and an optional subtitle, always left-aligned in LTR. Actions can update dynamically.

- **Create quick actions for compelling, high-value tasks.** People expect at least one; you can provide **four**.
- **Avoid unpredictable changes.** Dynamic updates based on location, recent activity, time of day, or settings are good — as long as people can anticipate them.
- **Succinct titles** that communicate the result ("Directions Home", "Create New Contact", "New Message"). Add a subtitle for context (Mail indicates unread counts). No app name, no extraneous information, short enough to avoid truncation, written with localization in mind.
- Use SF Symbols; for custom icons use the Quick Action Icon Template in Apple Design Resources.
- **Don't use an emoji** in place of a symbol — quick action symbols are monochromatic and change appearance in Dark Mode.

---

# Navigation and search

## Tab bars

A tab bar lets people navigate between the top-level sections of an app, preserving each section's navigation state.

- **Navigation, not actions.** If you need controls that act on the current view, use a toolbar.
- **Keep it visible** as people navigate. Hiding it makes people lose track of where they are. The exception is a modal view covering it.
- **Use the right number of tabs.** Weigh the complexity of more tabs against the need for frequent access; fewer is easier. For complex information structures, consider a sidebar or an adaptive tab bar.
- **Avoid overflow tabs.** When space runs out, the trailing tab becomes a More tab in iOS/iPadOS, which buries content. Limit scenarios where that happens.
- **Never disable or hide a tab**, even when its content is unavailable — it makes the app look unstable. If a section is empty, explain why.
- **Include labels.** A single word beneath or beside the icon.
- Use SF Symbols so icons adapt to compact and regular contexts (icons above labels in compact; side by side in regular). **Prefer filled variants** for platform consistency.
- Use a **badge** (a red oval with a number or exclamation point) only for critical information; overuse dilutes it.
- Avoid label colors similar to your content backgrounds; over colorful content prefer monochrome or a well-differentiated accent color.

**iOS.** The tab bar floats above content at the bottom on a Liquid Glass background. With an attached accessory (Music's MiniPlayer) you can **minimize** the tab bar and move the accessory inline on scroll-down; tapping a tab or scrolling to the top restores it (`TabBarMinimizeBehavior`, `UITabBarController.MinimizeBehavior`). A dedicated **search tab** can occupy the trailing end. **iPadOS.** The tab bar sits near the top and can be fixed (`tabBarOnly`) or convertible to a sidebar (`sidebarAdaptable`); for a sidebar with no tab-bar option, use a navigation split view instead. **Prefer a tab bar for navigation**, converting to a sidebar for a wider set of options. **Let people customize** — add frequently used items (a favorite playlist in Music), remove rarely used ones — but keep the default list to five or fewer for continuity between compact and regular sizes. **tvOS.** Highly customizable (background tint/color/image, per-state fonts, selected/unselected tints, button icons). Translucent by default with only the selected tab opaque; a drop shadow emphasizes selection when the bar has focus. **68 pt tall, 46 pt from the top — neither is changeable.** Overflowing items fade at the right; scrolling adds a left fade. The bar scrolls offscreen when a tab holds a single main view, and pins when the tab holds a split view. Menu always returns focus to it. Live-viewing apps order tabs: live → cloud DVR/recorded → other. **visionOS.** Always vertical, fixed relative to the window's leading side, expanding on gaze (temporarily obscuring content behind it). **Supply a symbol and a short text label per tab** — the symbol is always visible; labels appear on expansion. A sidebar can provide secondary navigation *within* a tab, as long as sidebar selections don't change the current tab. Not supported in watchOS.

## Sidebars

A sidebar on the leading side lets people navigate between areas or top-level collections. It needs substantial vertical and horizontal space — a tab bar may serve better when space is tight or content deserves the room.

- **Extend visually rich content beneath the sidebar** — let it scroll horizontally, or apply a **background extension effect** that mirrors adjacent content under the sidebar (`backgroundExtensionEffect()`).
- **Let people customize the contents** where possible.
- Group hierarchy with **disclosure controls** when there's a lot of content.
- Use familiar symbols; prefer a custom SF Symbol to a bitmap.
- **Let people hide it** using the platform interaction they know (edge swipe in iPadOS; a button or View menu commands in macOS). In visionOS the window expands to accommodate a sidebar, so hiding is rarely needed. **Don't hide it by default** — it must stay discoverable.
- **Show no more than two levels of hierarchy.** Deeper structures want a split view with a content list between the sidebar and the detail view.
- With two levels, title each group succinctly.
- **Sidebar icon colors serve a purpose.** They use your accent color by default; in macOS people can change the system accent and expect all sidebar icons to follow. A **fixed** color is for meaning or emphasis, used sparingly (Mail's yellow VIP icon).

**iOS/iPadOS.** The `sidebarAdaptable` tab view style lets you open with either presentation and includes a switch button; it adapts to platform, rotation, and window resizing. For a sidebar only, use `NavigationSplitView` or `UISplitViewController`. **Consider a tab bar first** — more room for content, enough flexibility for most apps, with the convertible sidebar for less frequent areas. Outside SwiftUI, use `UICollectionLayoutListConfiguration.Appearance.sidebar`. **macOS.** Row height, text, and glyph size scale with the sidebar size (small, medium, large) — settable programmatically, but people can also change it in General settings. Consider auto-hiding and revealing on window resize. **Don't put critical information or actions at the bottom.** **visionOS.** A sidebar within a tab supports secondary navigation, as long as it doesn't change the active tab. Not supported in watchOS.

## Search fields

An editable text field with a Search icon, a Clear button, and placeholder text, optionally with a scope bar and tokens.

- **Use placeholder text** to communicate what people can search for and reinforce the scope.
- **Start searching as people type** where possible — continuously refined results feel responsive.
- **Show suggested terms**: recent searches before typing, predictive suggestions during.
- **Simplify results**: most relevant first, categorized when that helps.
- Consider letting people filter results with a scope bar in the results area.

**Scope bars and tokens.** A **scope bar** filters and adjusts search scope — use it to move from a broad scope to a narrower one (Mail on iPhone narrows from the whole mailbox to the current one). **Default to a broader scope**; the full result set gives people the context to narrow usefully. A **token** is a selectable, editable visual representation of a search term acting as a filter for the remaining terms — a specific contact in Mail, photos in Messages. **Pair tokens with search suggestions**, since people may not know which tokens exist. (macOS has a related standalone **token field**.)

**iOS placements**
- **As a tab.** Always visible as people switch sections. Two styles: **standard tab** (uniform with the rest of the bar; opens a search landing page with the field at the top) and **button appearance** (a separate button; focuses the field and shows the keyboard immediately). Choose the standard tab to provide suggestions, promote discovery, and encourage exploration — good for rich, browsable content (Apple TV shows genres and categories first). Choose the button appearance for a transient experience that resolves quickly and returns people to their previous tab.
- **In a toolbar.** At the bottom as an expanded field or a button (animating into a field above the keyboard), or at the top as a button (animating into a field above the keyboard, or at the top if there's no room). **Place search at the bottom if there's room** — it's easy to reach (Settings uses a bottom toolbar for search alone; Mail and Notes fit it alongside other controls). Place it at the top when the bottom of the screen matters (Wallet's pass stack) or when there's no bottom toolbar.
- **Inline.** When search's position next to the content strengthens the relationship — filtering within a single view, or a second search field where location matters (Music's library filter). At the top, position it above the list it searches, and consider pinning it to the top toolbar on scroll.

**iPadOS and macOS.** Keep the experience consistent across both if you ship on both.
- **Trailing side of the toolbar** for many common uses, especially split-view apps searching across columns (Mail, Notes, Voice Memos) — people can navigate results while keeping their selection visible. Also good when results appear in the detail view (Freeform).
- **Top of the sidebar** when search filters the sidebar or navigation (Settings exposes sections several levels deep) — useful when the detail view is rich and needs separation from the filtered sidebar.
- **As a sidebar or tab bar item** when you want a dedicated discovery area with rich suggestions, categories, and content (Music, TV).
- In a dedicated area, consider focusing the field on arrival — except on iPad with only a virtual keyboard, where the keyboard would unexpectedly cover the view.
- **Account for window resizing.** On iPad the field resizes fluidly like Mac; in compact views, put search where it's contextually useful (Notes and Mail place it above the content-list column).

**tvOS.** A search screen is a specialized keyboard screen with fully customizable results beneath. **Provide suggestions** — popular, context-specific, and recent — because typing on a TV is slow. **watchOS.** Tapping the field opens a full-screen text-input control; the app returns to the field only after Cancel or Search.

## Path controls (macOS only)

Shows the file system path of a selected file or folder. Two styles: **standard** (a linear list of root disk, parent folders, and item, each with an icon and a name; names between the first and last item are hidden when it doesn't fit) and **pop up** (shows the selected item and opens a menu of the path). If editable, people can drag an item onto the control to select it; the pop-up style then also gains a Choose command.

Use it in the window **body**, not the frame — not in a toolbar or status bar. (Even the Finder's path bar is at the bottom of the body, not in the status bar.)

## Token fields (macOS only)

A text field that converts text into selectable, manipulable tokens — Mail's address fields. Tokens can be selected, dragged to reorder, or moved between fields. You can offer suggestions as people type, and give each token a context menu (edit the name, mark as VIP, view the contact card).

- **Add value with a context menu.**
- **Provide additional ways to tokenize.** Text becomes a token on a comma by default; you can add shortcuts like Return.
- **Consider customizing the suggestion delay.** Suggestions appear immediately by default, which can distract while typing.

---

# Layout and organization

## Split views

Manages multiple adjacent panes, typically to show several levels of hierarchy at once. Selecting in the primary pane fills the secondary; a tertiary pane can follow. The common form is a sidebar for navigation plus content and detail. Rarely, a split view supplements a main view with functional groups (Keynote's slide navigator, presenter notes, and inspector around the canvas).

- **Persistently highlight the current selection** in each pane that leads to the detail view — it clarifies the relationship between panes and keeps people oriented.
- Consider letting people **drag and drop between panes**.

**iOS.** Prefer a split view in a **regular**, not compact, environment; a compact width forces wrapping or truncation. **iPadOS.** Two panes (Mail) or three (Keynote). Account for narrow, compact, and intermediate window widths, and make sure people can navigate between panes logically at every size. **macOS.** Panes can be vertical, horizontal, or both, with draggable dividers. Set reasonable minimum and maximum pane sizes so the divider never appears to vanish. Consider letting people hide a pane to reduce distraction or gain editing room, and provide multiple ways to restore it (a toolbar button, a menu command with a shortcut). **Prefer the thin divider** (1 pt) — use a thicker style only when strong linear elements on both sides would obscure it. **tvOS.** Works well for filtering: category in the primary pane, results in the secondary. Choose a balanced layout — one-third/two-thirds by default, or half and half. **Display a single title above the whole split view**, not per-pane. Center it when the secondary pane holds a collection; place it above the primary pane when the secondary holds one important main view. **visionOS.** **Prefer a split view to a new window** for supplementary information — it keeps context, avoids window-management complexity, and doesn't confuse navigation. For a small request or a simple blocking task, use a sheet. **watchOS.** Shows either the list or a detail view full-screen. Display the most relevant detail view on launch (based on location, time, or recent actions). For multiple detail pages, use a vertical tab view so people can scroll with the Digital Crown, with a page indicator beside the Crown.

## Tab views (macOS, watchOS)

Presents mutually exclusive panes in one area, switched by a tabbed control at the top edge.

- Use for **closely related** content — the enclosure implies similarity.
- **Controls in a pane affect only that pane.** Panes are self-contained.
- **Label each tab** so people can predict its contents: nouns or short noun phrases (a verb phrase occasionally), title case.
- **Avoid a pop-up button for switching tabs** — a tabbed control needs one click and shows every choice at once. (A pop-up is a reasonable fallback when there are too many panes for tabs.)
- **No more than six tabs.** More is overwhelming and creates layout problems.
- You can hide the tabbed control for programmatic switching; then the content area can be borderless (solid or transparent), bezeled, or line-bordered.
- **Inset the tab view** with a margin of window-body area on all sides. Extending to the window edges is unusual.
- iOS/iPadOS: use a segmented control for similar functionality. watchOS: tab views render as page controls.

## Collections

Manages an ordered set of content in a customizable, highly visual layout. Ideal for **image-based** content.

- **Use the standard row or grid layout.** A custom layout risks confusing people and drawing attention to itself.
- **Consider a table instead for text** — a scrollable list is simpler and more efficient to read.
- **Make it easy to choose an item.** Adequate padding around images keeps focus and hover effects visible and prevents overlap.
- Add custom gestures only when the app requires it — tap to select, touch-and-hold to edit, and swipe to scroll are the defaults.
- Consider animating insertion, deletion, and reordering. Standard animations exist for all three.
- iOS/iPadOS: use caution with dynamic layout changes. Avoid changing the layout while people are interacting, unless it's a response to an explicit action. Not supported in watchOS.

## Lists and tables

Data in one or more columns of rows, representing groups or hierarchies and supporting selection, addition, deletion, and reordering.

- **Prefer lists and tables for text.** The row format makes text scannable. Use a collection for widely varying item sizes or lots of images.
- **Let people edit** when it makes sense; reordering is appreciated even without add/remove. iOS and iPadOS require entering an edit mode first.
- **Give appropriate selection feedback.** Navigation tables persistently highlight the selected row; option lists highlight briefly then show a checkmark.
- **Keep item text succinct** to minimize truncation and wrapping. For long content, list titles only and show the content in a detail view.
- Consider a **middle ellipsis** to preserve both the beginning and end of clipped text.
- **Descriptive column headings** in multicolumn tables: nouns or short noun phrases, title case, no ending punctuation. A single-column table without a heading needs a label or header for context.
- **Choose a style that fits the data and platform**: iOS/iPadOS `grouped` (headers, footers, and space between groups); watchOS `elliptical` (items roll off a curved surface); macOS `bordered` (alternating row backgrounds for large tables). Choose a row style that fits the content (`UIListContentConfiguration`).

**iOS/iPadOS/visionOS.** An **info button** (a *detail disclosure button* in a list row) reveals more information about a row's content — it does **not** navigate. A **disclosure indicator** reveals the next hierarchy level — it does **not** show details. Don't add an index to a table whose rows have trailing controls; the index and the controls occupy the same edge and interfere. **macOS.** Let people click a column heading to sort, and re-click to reverse. Let people resize columns. Consider alternating row colors in multicolumn tables. Use an **outline view** for hierarchical data. **tvOS.** Rows highlight and grow on focus, and corners can round — prepare images accordingly and don't add your own corner masks. **watchOS.** Limit rows where possible, but don't hide expected content (people with many podcast subscriptions expect to see them all) — list the most relevant items and offer a way to see more. Keep detail views short if you want vertical page-based navigation between rows; scrolling detail views break it.

## Outline views (macOS only)

Hierarchical data in a scrolling list of columns and rows, with disclosure triangles on parent containers. Typically on the leading side of a split view.

- Use a **table** instead for non-hierarchical data.
- **Expose hierarchy in the first column only.** Other columns show supplementary attributes.
- Descriptive column headings (nouns or short noun phrases, title case, no trailing colon). Always in multicolumn views; a single-column view without one needs another source of context.
- Consider click-to-sort, with sorting applied at each hierarchy level when the primary column is clicked (the Finder sorts top-level folders, then contents within each), and reversing on a repeat click.
- **Let people resize columns.**
- **Make expanding and collapsing easy** — Option-click a disclosure triangle to expand all subfolders.
- **Retain expansion state** so people don't re-navigate.
- Consider alternating row colors in multicolumn views.
- Let people edit where it makes sense: single-click to edit a cell, with double-click reserved for a different action (opening the file).
- Consider a centered ellipsis rather than clipping.
- Consider a search field in the toolbar for lengthy outlines.

## Column views (macOS only)

Also called a browser: a series of vertical columns, each one level of the hierarchy, with a triangle marking parents. Selecting a parent fills the next column. (In iPadOS or visionOS, use a split view instead.)

- Use for a **deep** hierarchy people navigate back and forth through frequently, when you don't need list/table sorting.
- **Show the root level in the first column** so people can scroll back and start over.
- Show information about the selected item when it has no children (the Finder previews it with creation date, modification date, type, and size).
- **Let people resize columns** — long item names need it.

## Disclosure controls

- **Hide details until they're relevant.** Put the controls people are most likely to use at the top, always visible, with advanced functionality hidden by default.

**Disclosure triangles** show and hide information associated with a view or list of items (Keynote's advanced export options; the Finder's list view). The triangle points inward from the leading edge when collapsed and down when expanded. **Provide a descriptive label** indicating what's disclosed ("Advanced Options"). (`NSButton.BezelStyle.disclosure`)

**Disclosure buttons** show and hide functionality associated with a specific control (the macOS Save sheet's button next to Save As). The button points down when collapsed and up when expanded. **Place it near the content it controls**, and use **no more than one per view**. (`NSButton.BezelStyle.pushDisclosure`)

iOS, iPadOS, and visionOS have SwiftUI's `DisclosureGroup`. Not supported in tvOS or watchOS.

## Boxes

A visually distinct group of logically related information and components, with a visible border or background color and an optional title.

- **Keep a box relatively small** compared to its container. As it approaches the window size it stops communicating separation and crowds other content.
- **Use padding and alignment for subgrouping.** A box border is a distinct visual element — nested boxes make an interface feel busy and constrained.
- Provide a succinct introductory title if it clarifies the contents — it also helps VoiceOver users predict what's inside. Brief phrase, sentence case, no ending punctuation (except a colon in a settings pane).
- iOS/iPadOS use the secondary and tertiary background colors by default. macOS displays the title above the box. Not supported in tvOS or watchOS.

## Labels

Static, readable, often copyable, uneditable text — in buttons, menu items, and views.

- Use a label for a **small amount** of uneditable text. Use a text field for small editable text, a text view for large amounts.
- **Prefer system fonts.** Labels support Dynamic Type by default. If you restyle or use a custom font, verify legibility.
- **Use the system label colors to communicate relative importance**: `label`/`labelColor` (primary) · `secondaryLabel` (subheading or supplemental) · `tertiaryLabel` (unavailable item or behavior) · `quaternaryLabel` (watermark).
- **Make useful label text selectable** — an error message, a location, an IP address.
- watchOS provides **date and time** text components (configurable format, calendar, and time zone) and **countdown timer** components. The system fits them to the available space and updates them without input from your app. Both are well suited to complications.

## Lockups (tvOS only)

Combine separate views — a content view, a header above, and a footer below — into a single interactive unit that expands and contracts together on focus.

- **Allow adequate space between lockups.** A focused lockup grows; leave room so it doesn't overlap or displace neighbors.
- **Use consistent lockup sizes within a row or group.**

Four types: **cards** (header + footer + content, for ratings and reviews of media) · **caption buttons** (an image or text with a title and subtitle beneath; they tilt with the swipe direction — vertically when stacked, horizontally when in a row, both in a grid) · **monograms** (a circular photo and name identifying people, usually cast and crew; **prefer images over initials** — a photo creates a more intimate connection) · **posters** (an image plus optional title and subtitle hidden until focused; any size appropriate to the content).

---

# Presentation

## Alerts

An alert gives people critical information they need right away.

- **Use alerts sparingly.** They interrupt. Each one should carry essential information and useful actions, or people stop reading them.
- **Never use an alert merely to inform.** People don't appreciate an interruption they can't act on. Find a contextual way to communicate (Mail shows an indicator when a server connection is unavailable).
- **Don't alert for common, undoable destructive actions.** Deleting an email is intentional and reversible. **Do** alert for an uncommon destructive action that can't be undone, in case it was accidental.
- **Don't show an alert at launch.** If people need to know something the moment they open your app, make it discoverable in the interface. For a startup problem like no network, show cached or placeholder data with a nonintrusive label.

**Content.** All platforms: a title, optional informative text, and up to three buttons. iOS, iPadOS, macOS, and visionOS can add a text field. macOS and visionOS can add an icon and an accessory view. macOS can add a suppression checkbox and a Help button.
- **Direct, neutral, approachable tone.** Alerts describe problems — don't be oblique, accusatory, or evasive about severity.
- **Write a title that describes the situation** clearly and succinctly: what happened, in what context, and why. Not "Error" or "Error 329347 occurred." Not so long it wraps past two lines. A complete sentence gets sentence case and ending punctuation; a fragment gets title case and none.
- **Include informative text only if it adds value** — short, complete sentences, sentence case, proper punctuation.
- **Don't explain the buttons.** If the text and titles are clear, you don't need to. Where you must reference a button, use "choose" (not tap or click) and the exact title without quotes.
- Add a text field only when input is needed to resolve the situation.

**Buttons**
- **Succinct, logical titles** — one or two words describing the result. Verbs and verb phrases tied to the alert text: "View All", "Reply", "Ignore". Title case, no ending punctuation.
- **Avoid "OK" as the default title** except in a purely informational alert. Does "OK" mean "OK, do it" or "OK, I understand what I almost did"? "Erase", "Convert", "Clear", "Delete" are unambiguous. Avoid "Yes" and "No" entirely.
- **Place buttons where people expect**: the most likely choice on the trailing side of a row or at the top of a stack; the default button always trailing or top; Cancel leading or bottom.
- **Use the destructive style** for a destructive action people **didn't** deliberately choose. When the destructive action *is* their stated intent (Empty Trash), don't style it destructively — the convenience of pressing Return outweighs restating the obvious.
- **Include a Cancel button whenever there's a destructive action**, always titled "Cancel", and never as the default. If you want people to actually read the alert, make no button the default. A single-button alert that is also the default should say **Done**, not Cancel.
- Support the platform's alternative dismissals: exit to the Home Screen (iOS/iPadOS) · Escape or Command-Period (iOS, iPadOS, macOS, visionOS) · Menu on the remote (tvOS).

**iOS/iPadOS.** Use an **action sheet**, not an alert, for choices related to an intentional action. **Avoid a scrolling alert** — keep titles short and messages brief. **macOS.** Your app icon appears automatically (you may substitute another icon or symbol). You can offer suppression of repeat alerts, append a custom accessory view, and include a Help button. **Use a caution symbol sparingly** — `exclamationmark.triangle` loses significance through overuse. Reserve it for unexpected data loss, not for tasks whose whole purpose is removing data. **visionOS.** In the Shared Space the alert appears in front of its window, slightly forward on the z-axis, and stays anchored to that window if the window moves. In a Full Space it's centered in the field of view. An accessory view has a maximum height of **154 pt** and a **16 pt** corner radius.

## Action sheets

A modal view presenting choices related to an action people initiated. (In SwiftUI, use a **confirmation dialog** presentation modifier; in UIKit, `UIAlertController.Style.actionSheet`.)

- **Use an action sheet, not an alert, for choices related to an intentional action.** Canceling a Mail draft offers delete or save — an alert would only confirm or cancel. An alert is also usually *unexpected*, telling people about a problem or a change.
- **Use them sparingly.** They interrupt too.
- **Keep titles to a single line.**
- **Provide a message only if necessary** — the title plus the context of the action is usually enough.
- Provide a **Cancel** button at the bottom (upper-left in watchOS) when the action could destroy data. SwiftUI confirmation dialogs include one by default.
- **Make destructive choices prominent**: destructive style, placed at the top where they're most noticeable.
- iOS/iPadOS: use an action sheet, not a menu, for choices related to an action — people expect a sheet to appear *as a result of* an action and a menu to appear when they *choose to reveal it*. **Avoid a scrolling action sheet** — more buttons cost more time, and scrolling risks an accidental tap.
- watchOS: title, optional message, Cancel, and one or more buttons, each with a style (Default, Destructive, Cancel). **No more than four buttons including Cancel** — so at most three choices.
- Not supported in visionOS.

## Sheets

A sheet helps people perform a scoped task closely related to their current context — supplying information needed to complete an action, attaching a file, choosing a save location.

In macOS, tvOS, visionOS, and watchOS a sheet is always modal. In iOS and iPadOS it can be **nonmodal**: people use it to affect the parent view without dismissing it (Notes' format sheet applies formatting to successive text selections).

**Buttons.** **Cancel** (or Close) dismisses without saving — common in most sheets. **Done** dismisses after completing or explicitly saving. **Back** moves to a previous step or parent view — it does *not* dismiss.

- For complex or prolonged flows, consider alternatives: a full-screen modal (`UIModalPresentationStyle.fullScreen`) for video, photos, camera, or multistep editing; a new window or full-screen mode in macOS; a Full Space in visionOS.
- **One sheet at a time from the main interface.** If something in a sheet produces another sheet, close the first one first, and re-present it afterward if needed.
- Use a **nonmodal** presentation for supplementary items that affect the parent's main task: a split view in visionOS, a panel in macOS, a nonmodal sheet in iOS/iPadOS.
- **Always pair Done with Cancel** (or Back). Done alone implies completing the task is the only way out.
- **Never show Cancel, Done, and Back together.**

**iOS/iPadOS.** Single-view sheets: Cancel on the leading edge of the top toolbar, Done on the trailing edge. Multi-step flows: first step has Cancel leading and (if present) an inactive Done trailing; later steps introduce Back. **Detents** define the heights a resizable sheet rests at — `large` (fully expanded) and `medium` (about half), plus custom values. Sheets support `large` automatically. Adding `medium` allows both; specifying only `medium` prevents full expansion. Support `medium` for progressive disclosure (a share sheet shows the most relevant items without resizing); skip it when content is more useful at full height (Messages and Mail compose sheets). **Include a grabber** in a resizable sheet — it shows resizability, cycles detents on tap, and works with VoiceOver. **Support swipe-to-dismiss**, and use an action sheet to confirm if there are unsaved changes. In iPadOS prefer the page or form sheet presentation styles.

**macOS.** A cardlike view with rounded corners floating over its parent, which dims. Use a **reasonable default size** — people don't expect to resize sheets, though supporting resizing is a good idea. **Let people interact with other app windows** without dismissing the sheet: bring the parent (and its modeless document panels) forward when the sheet opens, but keep other windows reachable. Use a **panel** instead when people need to provide input and observe results repeatedly (find and replace).

**visionOS.** Floats in front of its parent window, dimming it and becoming the target of interaction. **Avoid a sheet emerging from the bottom edge** — center it in the field of view. Use a default size that preserves context (don't cover the whole window), and consider allowing resizing.

**watchOS.** A full-screen semitransparent view sliding over content, with a material blurring and desaturating what's beneath. Use it **only when your modal task needs a custom title or custom content presentation** — otherwise an alert or action sheet. **Keep interactions brief and occasional**; a sheet is a temporary interruption, not navigation. If you change the default label, prefer an SF Symbol. Avoid anything that looks like a page or app title in the top-leading corner — people won't know how to dismiss it.

## Popovers

A transient view above other content, shown when people click or tap a control or interactive area.

- Use it for **a small amount** of information or functionality. It disappears after interaction, so limit it to a few related tasks (a calendar event popover changes the date, time, or calendar and then dismisses).
- **Consider popovers when you want more room** — sidebars and panels are expensive; a temporary popover streamlines the interface.
- **Position them so the arrow points as directly as possible** at the element that revealed it, and so the popover covers neither that element nor essential content.
- **Use a Close button only for confirmation and guidance** (exiting with or without saving). Otherwise a popover closes on an outside click/tap or on selection. For multiple selections, keep it open until explicit dismissal or an outside tap.
- **Always save work** when a nonmodal popover closes automatically — people dismiss them accidentally. Discard only on an explicit Cancel.
- **One at a time.** Never cascade or nest popovers. Close the open one before showing a new one.
- **Nothing displays over a popover** except an alert.
- Where possible, let one click or tap close one popover and open another — especially when several bar buttons each open one.
- **Don't make it too big.** Just big enough for its contents. The system may adjust the size to fit.
- Animate size changes so it doesn't look like a new popover replaced the old.
- **Don't use the word "popover" in help documentation** — refer to the task or the control.
- **Don't use a popover for a warning.** People miss or accidentally close them; use an alert.
- **iOS/iPadOS**: avoid popovers in compact views — use a sheet or another full-screen modal. **macOS**: a **detachable** popover becomes a panel when dragged, staying visible while people work elsewhere. Consider offering it, and keep the panel's appearance close to the popover's so people maintain context. Not supported in tvOS or watchOS.

## Panels (macOS only)

A panel floats above other windows providing supplementary controls, options, or information related to the active window or selection. It has a less prominent appearance than a main window, and can adopt a dark translucent HUD style.

- Use a panel for **quick access to important controls or information** related to the content people are working with.
- Consider one for **inspector** functionality — details of the current selection, updating as the selection changes. An **Info window** (unchanging contents regardless of selection) should be a regular window, not a panel. A split view pane is another option.
- **Prefer simple adjustment controls** — sliders and steppers give direct control; text entry and item selection require multiple steps.
- **Write a brief title** describing the purpose — a noun or noun phrase in title case ("Fonts", "Colors", "Inspector"). The title bar is what lets people position it.
- **Show and hide appropriately**: bring all open panels forward when your app becomes active, regardless of which window was active; hide them all when your app is inactive.
- **Don't list panels in the Window menu's document list.** Show/hide commands are fine.
- **Generally disable the minimize button** — a panel appears when needed and disappears when the app is inactive.
- **Refer to panels by title.** In menus, omit "panel": "Show Fonts", "Show Colors", "Show Inspector". In help documentation, use the title, appending "window" when it adds clarity ("Fonts window" reads better than "Fonts").

**HUD-style panels.** Same function, darker and translucent. They suit apps with highly visual content or immersive experiences — media editing, full-screen slideshows (QuickTime Player's inspector). **Prefer standard panels.** A HUD without a logical reason distracts and may not match the current appearance setting. Use a HUD only in a media-oriented app, when a standard panel would obscure essential content, or when you don't need controls (most system controls don't match a HUD's appearance; the disclosure triangle is an exception). **Maintain one panel style** across mode changes. **Use color sparingly** — small amounts of high-contrast color for important information. **Keep HUDs small**; they must not obscure the content they adjust or compete for attention.

## Windows (iPadOS, macOS, visionOS)

A window presents views and components, defines the visual boundaries of app content, and enables multitasking. Two conceptual types: a **primary window** (main navigation, content, and associated actions) and an **auxiliary window** (one specific task or area, no navigation to other app areas, with a close button).

- **Adapt fluidly to different sizes** to support multitasking and multiwindow workflows.
- **Choose the right moment to open one.** New windows help people multitask and preserve context (Mail's Compose). Excessive windows create clutter. Don't make new windows the default unless it fits your app.
- **Consider offering the option** to view content in a new window — a context menu item or a File menu command (`OpenWindowAction`).
- **Avoid custom window UI.** Custom frames and controls that don't perfectly match the system make an app feel broken.
- **Use the term *window*** in user-facing content, not "scene."

**iPadOS.** Two presentations depending on Multitasking & Gestures settings: **full screen** (windows fill the screen, switched via the app switcher) and **windowed** (freely resizable, repositionable, and layered; the system remembers size and placement across launches). Window controls appear at the leading edge of the toolbar when windowed — **move leading toolbar buttons inward** so they aren't hidden. Consider a gesture to open content in a new window (pinch to expand a Notes item).

**macOS.** A window has a **frame** (above the body, containing window controls and optionally a toolbar, and rarely a bottom bar below body content) and a **body area**. Three states: **main** (frontmost, one per app), **key** (active, accepts input, one onscreen at a time — usually the main window, but a floating panel may be key instead), and **inactive**. The system gives each a distinct appearance: the key window colors its close/minimize/zoom controls while inactive and non-key main windows gray them, and inactive windows drop vibrancy so they appear subdued and farther away. Some windows (Colors, Fonts) become key only when people click the title bar or a component needing keyboard input. **Custom windows must use the system-defined appearances** — with system components the states update automatically; with custom implementations you must do it. **Avoid putting critical information or actions in a bottom bar** (people hide the bottom edge). If you need one, use it for a small amount of information directly related to the window's contents or selection (the Finder's item count, selection count, and free space). For more, use an inspector on the trailing side of a split view.

**visionOS.** Two styles: **default** (a *window*) and **volumetric** (a *volume*). Both display 2D and 3D content, in the Shared Space or a Full Space. The system places the first one; people can move both. (A **plain** window style exists — like default, without the glass background.)

*Windows.* An upright plane with an unmodifiable **glass** background, a close button, a window bar, and resize controls; optionally a Share button, tab bar, toolbar, and ornaments. Dynamic scale keeps the apparent size consistent at any distance. **Prefer a window for familiar interfaces and tasks** — reserve immersion for meaningful content. **Retain the glass background**: it grounds content, adapts to lighting, and uses reflections and shadows to communicate scale and position. Removing it hurts legibility and cohesion; an opaque background obscures surroundings and feels heavy. **Default size 1280×720 pt**, placed ~2 m away (an apparent width of ~3 m). Minimize empty space. **Shape the window to the content** — Keynote opens wide for slides, Safari tall for webpages; a tower-building game opens taller than a driving game. **Set minimum and maximum sizes** or people can shrink it until elements overlap or grow it until it's unusable. **Minimize the depth of 3D content in a window** — the system clips content that extends too far from the surface. Use a volume for greater depth.

*Volumes.* For rich 3D content viewed from any angle. Includes window-management controls, but the close button and window bar rotate to face the viewer as they move. **Place 2D content so it looks good from multiple angles**; use an **attachment** to pin 2D content to specific areas of the 3D content. **Use dynamic scaling** in general; use fixed scaling only when the content should be real-world size (a retail product). **Take advantage of the default baseplate glow** — visionOS 2+ shows a gentle glow around the volume's horizontal floor on gaze, revealing the edges and the resize control. Skip it if your content is full-bleed or you supply a custom baseplate. **Consider an ornament** for high-value views or controls (visionOS 2+); anchor it (`topBack`, `bottomFront`) so it holds position relative to the viewer, avoid the edge already used by a toolbar or tab bar, and prefer just one. **Choose an alignment**: a baseplate parallel to the floor suits content people don't interact with much; one that tilts to match the gaze keeps content usable even when reclining.

## Scroll views

Lets people view content larger than the view's bounds. The view itself has no appearance, but shows a translucent indicator after scrolling starts.

- **Support default scrolling gestures and keyboard shortcuts.** If you build custom scrolling, keep the elastic behavior people expect.
- **Make it apparent when content is scrollable.** Indicators aren't always visible — showing partial content at the edge signals more.
- **Don't nest scroll views of the same orientation.** Horizontal inside vertical (or the reverse) is fine.
- Consider **page-by-page scrolling** where it suits the content: define a page size (usually the view's height or width) and subtract a unit of overlap — a line of text, a row of glyphs, part of a picture — to maintain context (`PagingScrollTargetBehavior`).
- **Scroll automatically only to help people find their place**: when an operation selects content or places the insertion point offscreen; when people start entering information in a hidden location; when the pointer moves past the edge during a selection; when people scroll away before acting on a selection. In every case, scroll **only as much as necessary** — if part of a selection is visible, don't scroll it all into view.
- If you support zoom, set sensible maximum and minimum scales.

**Scroll edge effects** (iOS, iPadOS, macOS) visually separate floating elements like toolbars from the content behind them. **Prefer the `automatic` style** — it renders more opaque for top toolbars with many controls, text outside Liquid Glass controls, and pinned table headers. If you choose `soft`, test legibility thoroughly. **Only use a scroll edge effect when a scroll view sits behind floating interface elements** — they are not decorative and don't function as overlays. **One per view**; in split views each pane can have its own, kept at consistent heights.

**Platform notes.** iOS/iPadOS: show a page control when a scroll view is in page-by-page mode, and hide the scroll indicator on the same axis to avoid redundancy. macOS: called a scroll bar; small or mini bars are acceptable in a space-constrained panel, with consistent control sizes throughout. tvOS: views scroll, but there are no distinct scroll indicators — the system scrolls to keep focused items visible. visionOS: a small, fixed-size indicator in a predictable location (vertically centered at the trailing edge for vertical scrolling; horizontally centered at the bottom for horizontal). Swiping reveals it; **looking at it and dragging enables a jog bar** that controls scrolling *speed* rather than position, with tick marks accelerating and decelerating. The indicator is thicker than iOS's — increase tight margins so it doesn't overlap content. **Look to Scroll** lets people scroll with their eyes by looking near a scroll view's boundary. It's off by default and must be added per scroll view. **Support it for reading and browsing views**; **avoid it for secondary content** with UI controls or dense information needing precise scrolling (Notes supports it in the main view, not in the notes list). **Be consistent** across similar views. **Define clear scroll areas** — prefer full-width or full-height views; if you inset one, give it clear boundaries. **Remove custom scroll-driven effects** (parallax, scroll-position animations) before adopting it — they make it behave unexpectedly. watchOS: prefer vertical scrolling with the Digital Crown. Use tab views for page-by-page scrolling; in a vertical stack, the Crown moves through full-screen pages with a page indicator beside it. Consider limiting each page to a single screen height for glanceability; variable-height pages are possible (the page indicator expands into a scroll indicator) but use them judiciously and place them after fixed-height pages.

## Page controls

A row of indicator dots representing pages in a **flat** list, with a solid dot for the current page. Handles an arbitrary number of pages, clipping when they don't fit.

- **For movement between an ordered list of pages** — not hierarchical or nonsequential relationships. For complex navigation use a sidebar or split view.
- **Center it horizontally near the bottom** of the view or window.
- **Don't display too many.** More than about ten dots can't be counted at a glance; for more peer pages, use a grid or another arrangement people can navigate in any order.
- **Custom indicator images** must be simple and clear — no complex shapes, negative space, text, or inner lines, all of which turn to mud at that size. Consider simple SF Symbols.
- Customize the default image only when it enhances meaning (every page contains bookmarks → `bookmark.fill`).
- **No more than two different images** in one control. One unique image marks one special page (Weather's `location.fill` for the current location); several unique images force people to memorize a legend and look haphazard.
- **Don't color indicator images.** Custom colors reduce the contrast that distinguishes the current page and keeps the control visible.

**iOS/iPadOS.** The control highlights the current page and shrinks indicators at both sides when there are more than fit. People **tap** (a discrete interaction) on either side of the current indicator to move one page, and **scrub** (a continuous interaction — touch and drag) to move through pages in sequence, with scrubbing past an edge jumping to the first or last page. iPadOS pointers can target a specific indicator. **Don't animate page transitions during scrubbing** — people scrub fast, and the scrolling animation causes lag and visual flashes. Use it only for tapping. **Background styles**: `automatic` (background only during interaction — use when the page control isn't the primary navigation), `prominent` (always — only when it *is* the primary navigation), `minimal` (never — when you only need to show position and don't need scrubbing feedback). **Don't support scrubbing with the minimal style.** **tvOS.** Use page controls on collections of full-screen peer pages; additional controls make it hard to maintain focus while moving between pages. **visionOS.** Page controls indicate position but aren't interactive. **watchOS.** At the bottom for horizontal pagination, or beside the Digital Crown for a vertical tab view — where the indicator shows position both within the current page and within the set, transitioning between scrolling content and scrolling pages. Not supported in macOS.

---

# Selection and input

## Text fields

A rectangular area for entering or editing small, specific pieces of text.

- Use one for a **small amount** of information — a name, an email address. For larger amounts use a text view.
- **Show a hint** ("Email", "Password") when the field is empty; because placeholder text disappears on typing, a separate label is often also useful.
- **Use secure fields** for sensitive data (`SecureField`).
- **Match the field size to the anticipated text** — size is a visual cue about how much to provide.
- **Space multiple fields evenly** so labels pair unambiguously with fields. Stack vertically where possible and use consistent widths (first/last name one width, address/city another).
- Ensure tabbing moves focus in a logical sequence.
- **Validate when it makes sense**: an email address on field exit; a username or password *before* leaving the field.
- **Use a number formatter** for numeric data — it restricts input and formats output (decimals, percentage, currency), though presentation varies by locale.
- **Adjust line breaks**: text beyond the bounds is clipped by default; you can wrap at the character or word level, or truncate at the beginning, middle, or end. Consider an expansion tooltip to reveal clipped text on hover.
- iOS, iPadOS, tvOS, visionOS: **show the appropriate keyboard type** for the content.
- **Minimize text entry in tvOS and watchOS.** Gather information with buttons or lists instead.

**iOS/iPadOS.** Display a **Clear button** at the trailing end. Use custom images and system buttons purposefully — the leading end indicates the field's purpose, the trailing end offers extra features like bookmarking. **macOS.** Consider a combo box when you need text input paired with a list of choices. **watchOS.** Present a text field only when necessary; prefer a list of options.

## Text views

Displays multiline, styled, optionally editable text, of any height, scrolling when the content exceeds it. Leading-aligned with the system label color by default; in iOS, iPadOS, and visionOS a keyboard appears when an editable text view is selected.

- Use a text view for text that's **long, editable, or specially formatted**. For a small amount, a label (or a text field, if editable) is simpler.
- **Keep text legible.** Multiple fonts, colors, and alignments can be used creatively, but readability comes first. Adopt Dynamic Type and test with Bold Text on.
- **Make useful text selectable** — an error message, a serial number, an IP address.
- iOS/iPadOS: show the appropriate keyboard type. tvOS: text views display text; editable text uses text fields, since text input is minimal by design.

## Toggles

A toggle lets people choose between a pair of opposing states, using a different appearance for each. Styles include switch and checkbox, applied differently per platform. All platforms also support buttons that behave like toggles.

- Use a toggle to **manage state**. If you need other kinds of actions (choosing from a list), use a different component.
- **Clearly identify what the toggle affects.** Usually context is enough; macOS often adds a label. A button-style toggle uses an icon to communicate purpose and changes its background to show state.
- **Make the visual difference obvious** — add or remove a color fill, show or hide the background shape, change the inner detail (a checkmark or dot). **Never rely on color alone.**

**iOS/iPadOS.** Use the **switch** style **only in a list row** — the row content supplies the context, so no label is needed. Change the default green only if needed (your accent color), keeping enough contrast with the off state. **Outside a list, use a button that behaves like a toggle**, not a switch — Phone's filter button adds a blue highlight when active and removes it when inactive. Don't add a label explaining a button-toggle's purpose; the icon plus the background states communicate it (`changesSelectionAsPrimaryAction`).

**macOS.** Adds checkboxes and radio buttons. Use all three in the window **body**, never the frame — not in a toolbar or status bar.
- **Switches** — for settings you want to emphasize. More visual weight than a checkbox, so they suit controls governing more functionality (turning a *group* of settings on or off). In a grouped form, a **mini switch** matches the height of buttons and other controls, keeping row heights consistent; a regular switch for the primary setting with mini switches for subordinates expresses a hierarchy. **Don't replace an existing checkbox with a switch.**
- **Checkboxes** — a small square: empty (off), checkmark (on), dash (mixed). Usually titled on the trailing side; untitled in an editable checklist. **Use checkboxes rather than switches for a hierarchy of settings** — their visual style aligns well, and leading-edge alignment plus indentation expresses dependency. **Reflect the state accurately**, including the **mixed** state when subordinate checkboxes differ (`allowsMixedState`). Consider a label introducing a group whose relationship isn't obvious, with its baseline aligned to the first checkbox.
- **Radio buttons** — a small circle plus label, typically in groups of two to five, for **mutually exclusive** choices. Selected (filled) or deselected (empty); a mixed state exists but is rarely useful — use a checkbox for that. **Use radio buttons for mutually exclusive options; checkboxes for multiple selection.** More than about five options should become a pop-up button. **For a single on/off setting, prefer a checkbox** — the presence or absence of the checkmark reads faster. Use consistent horizontal spacing sized to the longest label.

## Sliders

A horizontal track with a **thumb** people drag between a minimum and maximum. The portion between the minimum and the thumb fills with color; optional icons illustrate the endpoints.

- **Customize the appearance if it adds value** — track color, thumb image and tint, endpoint icons (a small image icon on the left, a large one on the right for an image-size slider).
- **Use familiar directions.** Minimum leading / maximum trailing for horizontal; minimum bottom / maximum top for vertical.
- **Consider pairing with a text field and stepper** for wide ranges, so people can see and enter an exact value and increment in whole units.
- **iOS/iPadOS**: don't use a slider for audio volume — use a volume view, which includes a volume slider and an output-device control.
- **macOS**: sliders can include tick marks. A **linear** slider has a narrow lozenge thumb and a filled track, often with endpoint icons. A **circular** slider has a small circular thumb with tick marks as evenly spaced dots around the circumference. **Consider live feedback** as the value changes (the Dock icons scale as you drag the Size slider). **Choose the style by expectation**: horizontal for a fixed start and end (0–100% opacity); circular when values repeat or continue indefinitely (0–360° rotation, or four full rotations = four spins). Consider an introductory label (sentence case, ending colon). **Use tick marks for clarity and accuracy**, and label them when it helps — numbers or words. Labeling every tick is usually unnecessary; the minimum and maximum are often enough; periodic labels help for nonlinear values. Consider a tooltip showing the thumb's value on hover.
- **visionOS**: prefer horizontal sliders — side-to-side gestures are easier than up and down.
- **watchOS**: a horizontal track shown as discrete steps or a continuous bar, with buttons on the sides that increment and decrement by a set amount. Create custom glyphs if plus and minus don't communicate the action.
- Not supported in tvOS.

## Steppers

A two-segment control for incrementing and decrementing a value. The stepper doesn't display the value, so it sits next to a field that does.

- **Make the affected value obvious.**
- **Consider pairing with a text field** when large changes are likely — steppers suit small changes of a few taps; a field suits widely varying values (a print screen benefits from both).
- macOS: consider Shift-click to change the value by a larger increment (e.g. 10×).
- Not supported in watchOS or tvOS.

## Pickers

One or more scrollable lists of distinct values. Date pickers add calendar and numeric-keypad entry. Exact values and their order depend on the device language.

- **For medium-to-long lists.** A short list is better served by a pull-down button — a picker adds too much visual weight. A very large set is better served by a list or table, which can adjust in height and offer an index.
- **Use predictable, logically ordered values** — much of a picker is hidden, so people need to anticipate what's there (an alphabetized country list).
- **Avoid switching views to show a picker.** It works in context, below or near the field being edited — typically at the bottom of a window or in a popover.
- **Consider coarser minute granularity** in a date picker. The default is 0–59; any interval dividing evenly into 60 works (quarter hours: 0, 15, 30, 45).

**iOS/iPadOS date picker styles**: **compact** (a button opening editable content in a modal view — use when space is constrained; the button shows the current value in your accent color, and the modal offers a calendar-style editor and time picker where people can make several edits before tapping outside to confirm) · **inline** (wheels for time only; an inline calendar for dates and times) · **wheels** (scrolling wheels, also supporting keyboard entry) · **automatic**. **Modes**: date · time · date and time · countdown timer (up to 23 h 59 m; not available in the inline or compact styles).

**macOS**: **textual** (limited space, specific selections) and **graphical** (browsing days, selecting a range, or when a clock face suits the app). **tvOS**: available via SwiftUI's `Picker`. **watchOS**: navigated with the Digital Crown for precise, engaging selection. The `wheels` style handles lists, dates, and times, with optional outline, caption, and scrolling indicator. For longer lists, the `navigationLink` style shows a button that reveals the options — and people can scrub with the Crown without tapping it first.

## Segmented controls

A linear set of two or more segments, each functioning as a button, usually of equal width, containing text or images (optionally with labels beneath). Offers a single choice — or in macOS, single or multiple. It can also act as a set of momentary action buttons with no selection state (`isMomentary`, `NSSegmentedControl.SwitchTracking.momentary`).

- **Use it for closely related choices affecting an object, state, or view** — attributes in an inspector, actions on the current view in a toolbar.
- **Consider one when grouping matters** or when selection state should be visible at a glance. Unlike other button styles, segmented controls preserve their grouping regardless of view size or placement.
- **Keep control types consistent within one control.** Don't mix selection-state segments and action segments.
- **Limit the number of segments** — aim for no more than about five to seven in a wide interface, five on iPhone.
- **Keep segment size consistent.** Equal widths feel balanced; keep icon and title widths consistent too.
- **Prefer either text or images, not a mix** — mixing reads as disconnected.
- Use content of similar size in each segment; equal widths make partial fills look wrong.
- **Nouns or noun phrases**, title case. A text-labeled segmented control needs no introductory text.

**iOS/iPadOS.** Good for switching between closely related subviews (Calendar's New Event sheet switches between event and reminder). For completely separate app sections, use a tab bar. **macOS.** Consider introductory text to clarify purpose; with symbols or icons, consider a label below each segment, and provide a tooltip per segment. **Use a tab view, not a segmented control, for view switching in the main window area** — a segmented control is for switching views in a toolbar or inspector pane. Consider spring loading. **tvOS.** Consider a split view instead on content-filtering screens — moving between content and filters is easier there. **Avoid putting other focusable elements close to a segmented control**: segments become selected when focus moves to them, not on click, so people may focus a neighbor by accident. **visionOS.** Looking at an icon segment shows the tooltip text you supply. Not supported in watchOS.

## Combo boxes (macOS only)

A text field combined with a pull-down button: people can type a custom value or choose a predefined one. A typed custom value is not added to the list.

- **Populate the field with a meaningful default** from the list — it doesn't have to be the first item, and an empty default misses the chance to hint at the hidden choices.
- **Use an introductory label** so people know what to expect (title case, ending colon).
- **Provide relevant choices** — people value both the custom entry and the convenience of likely options.
- **Keep list items no wider than the text field**, or they'll truncate.

## Color wells

Adjusts the color of text, shapes, guides, and other elements, presenting a color picker on tap or click.

- **Prefer the system color picker** for a consistent experience and a shared saved palette across apps — and for a familiar experience across iOS, iPadOS, and macOS.
- macOS: the well highlights on click to confirm it's active, then opens the picker, then updates to show the new color. Color wells support drag and drop between wells and from the picker.
- Not supported in tvOS or watchOS.

## Image wells (macOS only)

An editable image view. People can copy, paste, or delete its image after selecting it, and can drag a new image in without selecting first.

- **Revert to a default image** if the well requires one and people clear it.
- If it supports copy and paste, make sure the standard Edit menu items are available — people expect to use them and the standard keyboard shortcuts.

## Digit entry views (tvOS only)

A full-screen view prompting for a series of digits — a PIN — using a digit-specific keyboard, with an optional title and prompt above.

- **Use secure digit fields** (asterisks instead of digits) for sensitive data.
- **State the purpose clearly** in the title and prompt.

## Virtual keyboards

On devices without physical keyboards, the system offers keyboard types optimized for the current task (an email keyboard includes "@", ".", and even ".com"). Virtual keyboards don't support keyboard shortcuts.

- **Choose the keyboard that matches the content** being edited (`keyboardType(_:)`, `textContentType(_:)`, `UIKeyboardType`, `UITextContentType`). Specifying a semantic meaning also lets the system refine corrections. Types include ASCII capable, ASCII capable number pad, decimal pad, default, email address, name phone pad, number pad, numbers and punctuation, phone pad, Twitter, URL, and web search.
- **Consider customizing the Return key type** when it clarifies the experience — a search Return key for a search field (`submitLabel(_:)`, `UIReturnKeyType`).

**Custom input views** replace the system keyboard within your app (Numbers' numeric-entry view for spreadsheets). Make sure the benefit is obvious — otherwise people wonder why they can't get the system keyboard back. **Play the standard keyboard sound** (`playInputClick()`); people expect it, and they can turn it off globally.

**Custom keyboards** (iOS, iPadOS, tvOS) are app extensions that replace the system keyboard systemwide — except in secure text fields and phone number fields. They make sense for genuinely new input methods or for languages the system doesn't support. If you only want a custom keyboard inside your app, build a custom input view instead. **Provide an obvious way to switch keyboards** — people know the Globe key. **Don't duplicate system keyboard features** — the Emoji/Globe and Dictation keys appear automatically on some devices and you can't affect them. **Consider a tutorial in your app** covering how to choose, activate, use, and switch back from your keyboard — but don't put help content in the keyboard itself.

**iOS/iPadOS.** Use the **keyboard layout guide** so the keyboard feels integrated and important UI stays visible. Place custom controls above the keyboard thoughtfully, only when they're relevant to the current task (Numbers' calculation controls). If other views in your app use Liquid Glass, or your view looks out of place, apply Liquid Glass to the container; a standard toolbar adopts it automatically. Use the layout guide and standard padding for positioning. **tvOS.** A linear virtual keyboard appears when people select a text field with the Siri Remote; a grid keyboard screen appears for other devices, and content adapts to it. **visionOS.** The system keyboard supports direct and indirect gestures and appears in a separate, movable window — you don't need to account for its location. **watchOS.** A keyboard appears if the screen is large enough; otherwise dictation or Scribble. You can't change the keyboard type, but you can set the field's content type so the system can offer better suggestions. People can also type on a paired iPhone. Not supported in macOS.

---

# Content

## Image views

Displays a single image, or an animated sequence, on a transparent or opaque background. Images can be stretched, scaled, sized to fit, or pinned. Typically not interactive.

- Use an image view when the view's purpose is **simply to display an image**. For an interactive image, configure a system button to display it rather than adding button behavior to an image view.
- **For an icon, use a symbol or an interface icon**, not an image view. SF Symbols renders with various colors and opacities; an interface icon is typically a bitmap whose nontransparent pixels receive color. Both can use the accent color.
- **Take care overlaying text on images** — it reduces both image clarity and text legibility. Ensure contrast and consider a text shadow or background layer.
- **Use a consistent size for all images in an animated sequence** — prescaling avoids runtime scaling, and same-size, same-shape images perform better when the system must scale.
- macOS: use an **image well** for an editable image view, and an **image button** for a clickable image. tvOS: many images combine layers with transparency for depth — see Layered images in FOUNDATIONS.md. visionOS: image views display 2D and stereoscopic images and spatial photos; with RealityKit you can display images beside 3D content or generate a spatial scene from a 2D image. watchOS: prefer SwiftUI for animations; WatchKit's `WKImageAnimatable` is the alternative.

## Web views

Loads and displays rich web content — embedded HTML and websites — inside your app (Mail uses one for HTML messages).

- **Support forward and back navigation when appropriate.** Web views support it, but it isn't on by default; if people are likely to visit multiple pages, enable it and provide the controls.
- **Don't build a web browser with a web view.** Brief access to a website without leaving your app is fine; replicating Safari is unnecessary and discouraged.
- Not supported in tvOS or watchOS.

## Charts

An effective chart highlights a few key pieces of information so people can gain insight and make decisions. See **Charting data** in PATTERNS.md for when and why; this section covers how.

**Anatomy.** A **mark** is a visual representation of a data value; you choose a mark type (bar, line, point) to determine the chart style. The area containing marks is the **plot area**; depicting values there is **plotting**. A **scale** maps data values to visual characteristics — position, color, height. An **axis** defines a frame of reference, usually one horizontal and one vertical at the plot area's edges. **Ticks** mark reference points along an axis; **grid lines** extend from ticks across the plot area so people can estimate values away from an axis. **Labels** name axes, grid lines, ticks, and marks; **accessibility labels** describe elements for assistive technologies; **titles, subtitles, and annotations** provide context; a **legend** describes properties unrelated to position, like color or shape coding.

**Marks.** **Bar marks** compare values across categories or show parts of a whole; over time they work best when each value is a sum (total steps in a day). **Line marks** show change over time — the slope reveals magnitude and overall trend. **Point marks** show individual values as distinct marks, revealing relationships between two properties and exposing outliers and clusters. **Combine mark types when it adds clarity** — points on a line highlight individual values while the line carries the trend.

**Axes.** Choose a **fixed** range when specific minimum and maximum values are meaningful for all data (battery charge: 0–100%). Choose a **dynamic** range when values vary widely and you want the marks to fill the plot area (Health's Steps chart varies the upper bound per period). **Define the lower bound by mark type and use**: zero works well for bar charts, because relative heights then estimate values — but a heart-rate chart forced to zero hides the meaningful differences between resting and active readings. **Prefer familiar tick sequences** — 0, 5, 10 is read instantly; 1, 6, 11 follows the same rule but costs thought. **Tailor grid line density and weight** to the use case: too many overwhelm and distract from the data; too few make estimation impossible. If people can inspect individual points interactively, use fewer grid lines and lighter label colors.

**Descriptive content.** **Write descriptions that explain the chart before people read it** — information-rich titles and labels give people the context to dive in, and are especially important for VoiceOver users and people with certain cognitive disabilities. **Summarize the main message**: Weather's title and subtitle state the expected precipitation for the next hour without requiring anyone to examine the chart.

**Best practices.** Establish a visual hierarchy where the data is most prominent and descriptions and axes provide context without competing. In a compact environment, **maximize the plot area's width** — keep vertical axis labels as short as possible, describe units in the title, and place a long category label inside the plot area when it doesn't obscure anything. **Let people interact when it makes sense, but never require interaction to reveal critical information** (Stocks shows performance over the chosen period; dragging an indicator reveals individual values). **Make interaction easy for everyone**: chart marks are often too small to target, so consider expanding the hit target to the whole plot area and letting people scrub. **Make an interactive chart navigable by keyboard and Switch Control** — these visit elements linearly by default; use accessibility APIs (`accessibilityRespondsToUserInteraction(_:)`) to define a logical path (along the X axis rather than jumping around), or let people move focus among *subsets* of values for very large datasets. Both customizations also improve the VoiceOver experience even in a static chart. **Help people notice important changes** — animate mark and axis changes, but also convey them another way for VoiceOver users and people who turn off animations (`UIAccessibility.Notification`, `NSAccessibility.Notification`). **Align the chart with surrounding elements**: align leading edges, and keep the leading edge clean by putting vertical grid line labels on their trailing side, or by moving the Y axis to the trailing side so its tick labels don't protrude. Anchor a stranded label to a grid line with a tick.

**Color.** **Never rely solely on color** to differentiate data or communicate essential information — supplement with different shapes or patterns (Health uses two shapes as well as two colors for the two components of blood pressure). **Add visual separation between contiguous areas of color** — separators between stacked bar marks make individual marks distinguishable.

**Accessibility.** Swift Charts gives you a default Audio Graphs implementation plus a default accessibility element per mark or group. **Customize Audio Graphs** with a chart title and descriptive summary. If you don't use Audio Graphs, you must provide an overview yourself: the chart type, what each axis represents, and details like the upper and lower bounds. Unlike an image, a chart usually needs a label per important or interactive element — decide, based on purpose and mark density, whether to describe each mark or groups of marks. (A small chart inside a button that reveals a detailed version may need only one high-level label.)

Writing accessibility labels:
- **Prioritize clarity and comprehensiveness.** A bare value is rarely enough — include the context (date, location) that makes it meaningful, without repeating what Audio Graphs or your overview already says.
- **Match the chart's purpose.** Maps' cycling-elevation chart summarizes elevation change over a *portion* of the route, because the point is the terrain overall; Health labels each bar in the Steps chart, because the point is the step count per period.
- **Avoid subjective terms** — *rapidly*, *gradually*, *almost* impose your interpretation. Use actual values.
- **Avoid ambiguous formats and abbreviations** — "June 6" beats "6/6"; "60 minutes" and "60 meters" beat "60m".
- **Describe what the details represent, not what they look like.** Identify what the red and blue series *are*, not that they're red and blue.
- **Be consistent** about which axis you mention first.
- **Hide visible axis and tick labels from assistive technologies** — VoiceOver users get values and trends from accessibility labels and Audio Graphs.

**watchOS.** Avoid complex chart interactions. Prefer glanceable information with simple interactions. If you also ship on another platform, use it for details and richer interaction (Heart Rate on Apple Watch shows the day; Health on iPhone shows multiple periods and individual marks).

---

# Status

## Progress indicators

Transient indicators that appear only while an operation runs.

- **Determinate** for a known duration — a linear bar filling leading-to-trailing, or a circular track filling clockwise.
- **Indeterminate** (an activity indicator) for an unquantifiable task — a spinning image on every platform, plus an indeterminate bar in macOS.

- **When possible, use a determinate indicator.** It lets people decide whether to do something else, restart later, or abandon the task.
- **Be accurate**, and consider evening out the pace. 90% in five seconds and the last 10% in five minutes makes people doubt the app and feel deceived.
- **Keep them moving.** A stationary indicator reads as a stalled process or a frozen app. If a process actually stalls, explain the problem and what to do.
- **Switch indeterminate → determinate** when you learn the duration. **Never switch between the circular and bar styles** — different shapes and sizes disrupt the interface and confuse people.
- Display a description if it adds context — accurate and succinct. Avoid vague terms like "loading" or "authenticating."
- **Use a consistent location** across platforms and within your app.
- **Let people halt processing** when it's safe: a Cancel button. If interruption has a negative side effect (losing a partial download), add a Pause button alongside Cancel, and alert people about the consequence of canceling.

**iOS/iPadOS refresh controls.** A specialized activity indicator, hidden until people drag down the view to reload. **Still perform automatic content updates** — an immediate refresh is a convenience, not a substitute. **Supply a short title only if it adds value** — usually the animation is enough; if you include one, don't explain how to refresh, give information about the content (Podcasts shows when the last update occurred). **macOS.** **Prefer a spinner** for a background operation's status or when space is constrained — inside a text field, next to a button. **Avoid labeling a spinner**; it appears in response to an action, so the context is clear. **watchOS.** Progress indicators are white over the scene's background by default; set the tint color to change them.

## Gauges

Displays a specific numerical value within a range, using a circular or linear path. A standard gauge shows an indicator at the value's position; a **capacity** style fills the path up to it. An **accessory** variant resembles watchOS complications and works well in iOS Lock Screen widgets.

- **Write succinct labels** describing the current value and both endpoints. Not every style displays every label, but VoiceOver reads the visible ones.
- **Consider a gradient fill** to communicate purpose — red to blue for hot to cold.

**macOS level indicators.** In addition to gauges, macOS defines a level indicator conveying **capacity**, **rating**, or (rarely) **relevance**. Capacity can be **continuous** (a translucent track filling with a solid bar) or **discrete** (equally sized rectangular segments, filling completely — never partially). **Use continuous for large ranges** — discrete segments become too small to be useful. **Consider changing the fill color** to signal significant thresholds (very low, very high, past the middle); the default is green, and the **tiered** state shows a sequence of colors in one indicator. The **relevance** style shows relevancy as a shaded horizontal bar, useful when sorting or comparing search results. For the rating style, see Rating indicators.

## Activity rings (iOS, iPadOS, watchOS)

Show an individual's daily progress toward Move, Exercise, and Stand goals. watchOS always shows all three; iOS shows a single Move ring, or all three when an Apple Watch is paired.

- **Display them when they're relevant** to your app's purpose — health and fitness apps, especially those contributing to HealthKit. Consider them on a workout metrics screen and on a workout summary screen.
- **Only for Move, Exercise, and Stand.** Never replicate or modify them for other purposes. Never show Move/Exercise/Stand progress in another ring-like element.
- **For a single person only**, and make it obvious whose progress it is — a label, a photo, an avatar.
- **Keep the appearance identical everywhere**: never change ring colors, apply filters, or modify opacity; always display on a **black background**; prefer enclosing the rings and background in a circle by adjusting the enclosing view's corner radius, not by applying a circular mask; keep the black background visible around the outermost ring (add a thin black stroke if needed) with no gradient, shadow, or other effect; scale appropriately so they don't look disconnected. **Design the surrounding interface to blend with the rings — never the reverse.**
- Label or value text directly associated with a ring uses the matching ring color.
- **Maintain margins**: a minimum outer margin no smaller than the distance between rings. Nothing may crop, obstruct, or encroach on it.
- **Differentiate other ring-like elements** with padding, lines, labels, color, or scale.
- **Don't duplicate Activity notifications.** The system already sends Move, Exercise, and Stand updates. Don't show Activity rings in your notifications; referencing progress in a way unique to your app is fine.
- **Not for decoration and not for branding.** Never in labels, background graphics, app icons, or marketing materials.

## Rating indicators (macOS only)

A horizontal series of symbols — stars by default — communicating a ranking level. Only complete symbols are shown (the value rounds); symbols are equidistant and don't expand or shrink to fit.

- **Make it easy to change rankings** — let people adjust an item's rank inline, without navigating to a separate editing screen.
- If you replace the star with a custom symbol, **make sure its purpose is clear**. The star is deeply associated with rating; other symbols may not read as a scale.

---

# System experiences

## Notifications

A notification gives timely, high-value information understandable at a glance. Styles include a banner or view on the Lock Screen, Home Screen, Home View, or desktop; a badge on the app icon; and an item in Notification Center. Communication notifications (calls, messages) use a distinct interface featuring contact images or avatars and group names instead of the app icon. See **Managing notifications** in PATTERNS.md for permission, Focus, and interruption levels.

- **Concise and informative.** People turn on notifications for quick updates.
- **Don't send multiple notifications for the same thing**, even without a response. It fills Notification Center and gets your notifications turned off.
- **Don't tell people to perform tasks in your app.** Offer notification actions for simple tasks; otherwise skip the instruction, because people won't remember it after dismissal.
- **Use an alert, not a notification, for an error message.**
- **Handle the foreground gracefully.** Your notifications don't appear while your app is frontmost, but you still get the information. Present it discoverably but unobtrusively — increment a badge, insert data into the current view (Mail simply adds a new message to the list rather than sending a distracting notification about it).
- **Avoid sensitive, personal, or confidential information.** You can't predict who's looking at the screen.

**Content.** The title appears at the top where it's most visible. In a communication notification, the system uses the sender's name; in a noncommunication one, it uses your app name if you don't supply a title.
- **Create a short title if it provides context** — a headline, an event name, an email subject. Brief enough to read at a glance, especially on Apple Watch. If you can only manage a generic title like "New Document," let the system show your app name instead. Title case, no ending punctuation.
- **Succinct, readable body**: complete sentences, sentence case, proper punctuation, and no manual truncation — the system truncates.
- **Provide generic descriptive text for hidden previews.** When previews are off, the system shows only your icon and the title "Notification." Write body text giving enough context to decide whether to look — "Friend request", "New comment", "Reminder", "Shipment" (`hiddenPreviewsBodyPlaceholder`), in sentence case.
- **Don't include your app name or icon** — the system displays a large version of your icon at the leading edge automatically (badged onto the sender's contact image in a communication notification).
- **Consider a sound.** Custom sounds should be short, distinctive, and professionally produced; system alert sounds also work. Never rely on sound to communicate anything important, and note that you can't programmatically add a vibration.

**Actions.** Up to four buttons in a customizable detail view let people act without opening the app (Calendar's Snooze).
- **Provide beneficial, time-saving actions** that eliminate the need to open the app.
- Short, title-case terms clearly describing the result. No app name, no extras, short enough to avoid truncation, written with localization in mind.
- **Don't provide an action that merely opens your app** — tapping the notification already does that.
- **Prefer nondestructive actions.** If a destructive one is necessary, give enough context to avoid unintended consequences; the system styles it distinctly.
- **Provide a recognizable interface icon per action.** The system places it on the trailing side of the title.

**Badging.** A small filled oval with a number on the app icon indicating unread notifications.
- **Only for unread notification counts.** Not for weather data, dates, times, stock prices, or game scores.
- **Never the only channel** — people can turn badges off. Make important information easy to find as soon as they open the app.
- **Keep badges current.** Update as soon as people open the corresponding notifications. Reducing a badge to zero removes all related notifications from Notification Center.
- **Never mimic a badge** with a custom image or component — people who turned badges off will be frustrated by what looks like one.

**watchOS.** Notifications arrive in two stages. A **short look** appears on wrist raise and disappears on wrist drop — brief, so **never the only way to communicate important information**, and **discreet**, so keep potentially sensitive information out of the title. A **long look** provides detail, scrollable with a swipe or the Digital Crown, dismissed by tapping or lowering the wrist. A custom long look can be **static** (a message plus additional static text and images) or **dynamic** (full content, more configuration options). You can customize the content area of both, but not the overall structure: a **sash** at the top with your app icon and name (customizable color, or a blurred appearance that works well beneath a photo at the top of the content area), and a **Dismiss** button at the bottom below all custom buttons. **At minimum provide a static interface** — the system falls back to it when there's no network or the iPhone companion is unreachable, so package its resources with your app. **Prefer providing a dynamic interface too.** Background color: transparent by default; **white at 18% opacity** matches other system notifications, or use a custom brand color. Provide **up to four custom actions**; the system picks which to show based on the notification's type, and always adds Dismiss at the bottom. **Double tap runs the first nondestructive action** — order your actions with the most frequently used first.

## Widgets

A widget provides quick access to essential information and focused interactions in additional contexts — Home Screen and Lock Screen (iPhone, iPad), desktop and Notification Center (Mac), horizontal and vertical surfaces (Apple Vision Pro), and the Smart Stack (Apple Watch).

**System family sizes:** small, medium, large, extra large, extra large portrait.

| Size | iPhone | iPad | Mac | Apple Vision Pro |
|---|---|---|---|---|
| Small | Home Screen, Today View, StandBy, CarPlay | Home Screen, Today View, Lock Screen | Desktop, Notification Center | Horizontal and vertical surfaces |
| Medium | Home Screen, Today View | Home Screen, Today View | Desktop, Notification Center | Horizontal and vertical surfaces |
| Large | Home Screen, Today View | Home Screen, Today View | Desktop, Notification Center | Horizontal and vertical surfaces |
| Extra large | — | Home Screen, Today View | Desktop, Notification Center | Horizontal and vertical surfaces |
| Extra large portrait | — | — | — | Horizontal and vertical surfaces |

**Accessory sizes:** circular, corner, inline, rectangular. Circular, inline, and rectangular appear on the iPhone and iPad Lock Screen, as Apple Watch complications, and (circular and rectangular) in the Smart Stack. Corner is watch complications only.

**Appearances and rendering modes.** **Full color** — the system doesn't change your view colors. **Accented** — the system removes the background and applies a tint (tinted appearance) or a Liquid Glass background (clear appearance), dividing your views into an accent group and a primary group and applying a solid color to each; on iPhone, iPad, and Mac it tints both white, on Apple Watch it tints primary white and accent with the watch face color. **Vibrant** — for the iPhone and iPad Lock Screen and iPhone StandBy in low light: desaturates text, images, and gauges and colors content appropriately for the background.

Availability: iPhone — full color on Home Screen, Today View, StandBy, CarPlay; accented on Home Screen and Today View; vibrant on Lock Screen and StandBy in low light. iPad — full color and accented on Home Screen and Today View; vibrant on Lock Screen. Apple Watch — full color and accented in the Smart Stack and complications. Mac — full color on desktop and Notification Center; vibrant on desktop. Apple Vision Pro — full color and accented on surfaces.

**Best practices**
- **Choose simple ideas tied to your app's main purpose.** Weather widgets lead with the current high, low, and conditions.
- **Give quick access to the content people want** — meaningful content, useful actions, deep links. A widget that replicates your app icon adds nothing and won't stay on the screen.
- **Prefer dynamic information** that changes through the day. Widgets don't update minute to minute, but stale content stops inviting a look.
- **Look for opportunities to surprise and delight** — a special treatment on a birthday or holiday.
- **Offer multiple sizes when it adds value.** Small widgets typically show one piece of information; larger ones support layers and actions. **Don't expand a small widget's content to fill a larger area.** One widget in the *right* size beats one in every size.
- **Balance information density.** Sparse looks unnecessary; dense isn't glanceable. Provide the essentials at a glance and detail on a longer look. If it's too dense, consider a larger size or replacing text with graphics.
- **Show only what relates to the widget's main purpose.** All Calendar widgets center on upcoming events; the larger sizes expand the range, not the subject.
- **Use brand elements thoughtfully.** Colors, typefaces, and stylized glyphs make a widget recognizable — but must not overpower the information or look out of place. You rarely need a logo; if you do (a widget aggregating multiple sources), a small one in the top-right corner is enough.
- **Choose between automatic content and configuration.** Stocks needs configuring; Podcasts shows recent content automatically.
- **Don't mirror your widget's appearance inside your app.** A widget-looking element that doesn't behave like one is confusing, and people may not try other interactions with it.
- **Say when authentication adds value** — "Sign in to view reservations".

**Updating.** Widgets refresh periodically; they don't support continuous real-time updates, and the system adjusts limits by context. Find the frequency that matches how often the data changes and when people need it — an hourly tide widget is useful even though tides change constantly. If people check more often than you can update, show when the data was last updated. **Let the system refresh dates and times** to preserve your update opportunities. Show content quickly rather than hiding stale data behind placeholders. **Use animated transitions** (standard or custom, up to **two seconds**) to draw attention to updates.

**Interactivity.** Tapping or clicking launches the app; buttons and toggles offer functionality without launching it (Reminders' completion toggles). Interactions outside buttons and toggles launch the app. **Offer simple, relevant functionality** directly related to the content, and reserve complexity for the app. **Deep link to the right location** — don't make people navigate. **Stay glanceable and uncluttered**; multiple targets are fine but avoid app-like layouts, and size targets so people don't hit the wrong one. Inline accessory widgets have only one tap target.

**Margins and padding.** Widgets scale across devices — supply appropriately sized content and let the system resize. In iOS the system resizes content designed for large devices; in iPadOS it renders large then scales down. **Use the standard margin — 16 pt for most widgets.** For tighter content groupings (graphics, buttons, background shapes), **11 pt** works. Widgets use smaller margins on the Mac desktop and on the Lock Screen, including StandBy. **Coordinate your content's corner radius with the widget's** using a SwiftUI container (`ContainerRelativeShape`).

**Text.** Prefer the system font, text styles, and SF Symbols — they look at home on any platform and give you weights, styles, and sizes. Use a custom font sparingly, ensuring glanceable legibility; a common pattern is a custom face for large text with SF Pro for smaller text. **Avoid font sizes below 11 pt.** **Never rasterize text** — it must scale and VoiceOver must speak it. In iOS, iPadOS, and visionOS, widgets support Dynamic Type from Large to AX5 with `Font` or `custom(_:size:)`.

**Color.** Use it to enhance without competing with content. Specify the colors the system should use for your widget's editing-mode UI in your asset catalog. **Convey meaning without relying on specific colors** — widgets can appear monochrome, tinted, or clear, and watchOS may invert colors depending on the face. **Use full-color images judiciously**: in tinted or clear appearances the system desaturates them by default; forcing full color draws special attention and can make the widget feel foreign to the platform. Reserve it for media content like album art, at dimensions smaller than the widget.

Per rendering mode: **Full color** — support light and dark appearances with matching backgrounds, semantic colors for text and backgrounds, or asset-catalog color variants. **Accented** — group views into an accent group and a primary group (`widgetAccentable(_:)`). **Vibrant** — offer enough contrast: pixel opacity determines the strength of the blurred material effect (fully transparent pixels pass the material through unchanged) and pixel brightness determines vibrancy (brighter grays give more contrast). Render images, numbers, and text at full opacity; use white or light gray for the most prominent content and darker grayscale for secondary elements; verify grayscale contrast; **use opaque grayscale values rather than opacities of white**.

**Previews and placeholders.** Design a **realistic preview** for the widget gallery that highlights capabilities — real data if it loads fast, realistic simulated data otherwise. Design **placeholder content** that helps people recognize your widget while data loads: static components plus semi-opaque shapes standing in for dynamic content (rectangles of varying widths for lines of text, circles or squares for glyphs and images). **Write a succinct description** beginning with an action verb — "See the current weather conditions and forecast for a location" — avoiding "This widget shows…", "Use this widget to…", or "Add this widget," in approachable language and sentence case. **Group your sizes together with a single description** so people don't think each size is a different widget. Consider coloring the Add button to reinforce your brand.

**iOS/iPadOS.** Lock Screen widgets follow complication design principles as well as widget principles — provide useful information, don't treat them merely as launchers. Because designs often transfer between Lock Screen widgets and complications, consider creating them in tandem. Three Lock Screen shapes: inline text above the clock; circular and rectangular below it. **Support the Always-On display** — reduced luminance means you need grays with enough contrast. **Offer Live Activities for real-time updates**; widgets don't show real-time information, and the two share frameworks and design language, so develop them together.

**StandBy and CarPlay.** In StandBy the system shows two small system widgets side by side, scaled up to fill the Lock Screen; supporting StandBy also covers CarPlay, which uses the small widget with the background removed and scaled to fit. **Glanceable information and large text matter most in CarPlay.** **Limit rich images and color in StandBy** — use the extra space to scale up and rearrange text so it reads from a distance, and **don't use background colors**, so the widget blends with the black background. In low light the system renders widgets monochrome with a red tint.

**visionOS.** Widgets are 3D objects placed on horizontal or vertical surfaces, persisting through power cycles, at a consistent real-world scale. They appear in full color by default and in accented mode when people apply a tint from the system palettes. People can customize the frame width of elevated widgets, and any custom options you offer (the Music poster widget offers a light or dark theme generated from the album art).
- **Adapt design and content for the spatial experience.** Widgets are part of living rooms, kitchens, and offices. The Music widget becomes a poster with large typography and a high-resolution image, glanceable across the room; a productivity app might offer a small widget that fits on a desk.
- **Test across the full range of system color palettes and lighting conditions.** If you exclude UI elements from tinting, verify they stay legible in every palette.
- **Two thresholds**: **simplified** (viewed from a distance — fewer details, larger type, no interactive elements) and **default** (viewed nearby — more detail, smaller type). **Maintain shared elements across both** so the transition feels continuous.
- **Match the family size to the surroundings.** Think about where people will place it — a wall, a sideboard, a desk. A small widget for a desk; an extra large one for visually rich decoration.
- **Stay legible at a range of distances.** People can scale a widget from 75% to 125%. Use print design principles — hierarchy, strong typography, scale — and include high-resolution assets.
- **Mounting styles**: **elevated** (the default; on horizontal surfaces it tilts back slightly for readability and casts a soft shadow; on vertical surfaces it sits flush like a picture frame) and **recessed** (vertical surfaces only; content set back into the surface like a cutout). Choose by content: elevated for content that should stand out and feel present — reminders, media, glanceable data; recessed for immersive or ambient content — weather, editorial. You can opt out of either per widget (`supportedMountingStyles(_:)`), but supporting only recessed means people can't place it horizontally. **Test elevated designs with each system frame width** — you can't change the layout based on the width someone picks.
- **Treatment styles**: **paper** (grounded, print-like, solid; the whole widget darkens and lightens with ambient light — the Music poster widget) and **glass** (layered, with depth and separation between foreground and background; foreground elements stay bright and legible regardless of ambient light — a News widget with editorial images behind crisp headlines). Choose paper for a real-object look; glass for information-rich widgets.

**watchOS.** **Provide a colorful background that conveys meaning** — Smart Stack widgets default to black; Stocks uses red for falling values and green for rising. **Provide relevance information** (`RelevanceKit`) — location-based or tied to ongoing system actions like a workout — so the system can elevate your widget when it matters. Not supported in tvOS.

## Controls (iOS, iPadOS, macOS)

A control provides quick access to an app feature from Control Center, the Lock Screen, or the Action button. A **control button** performs an action, links to a specific area, or launches a camera experience on a locked device; a **control toggle** switches between two states.

**Anatomy.** A symbol, a title, and optionally a value. In Control Center a control shows its symbol and, at larger sizes, its title and value. On the Lock Screen it shows only its symbol. Assigned to the Action button, pressing and holding shows the symbol in the Dynamic Island along with its value.

- **Offer controls for actions that provide the most benefit without launching the app** — launching a Live Activity from a control is a strong pattern.
- **Update controls** on interaction, on completion, or remotely via push, so the state and in-progress status are accurate.
- **Choose a descriptive symbol.** Depending on placement, the title and value may not appear, so the symbol must carry the meaning. Provide symbols for both states of a toggle (`door.garage.open` / `door.garage.closed`).
- **Use symbol animations** for state changes: animate between on and off for a toggle; animate indefinitely while a durational action runs and stop when it completes.
- **Select a tint color** matching your brand. The system applies it to a toggle's symbol in the on state and to the value and symbol in the Dynamic Island.
- **Prompt for required configuration** when people first add a control (choosing which light to control), and let them reconfigure later (`promptsForUserConfiguration()`).
- **Provide hint text for the Action button**, using verbs (`controlWidgetActionHint(_:)`).
- **Include a placeholder** if your title or value is situational — the system shows it in the controls gallery and before assignment to the Action button.
- **Hide sensitive information when the device is locked.** Have the system redact the title and value, and specify whether the symbol state should be redacted too (it then shows the off state).
- **Require authentication for security-affecting actions** — unlocking a door, starting a car (`IntentAuthenticationPolicy`).

**Camera experiences on a locked device** (iOS 18+). A control can launch your camera experience while the device is locked; anything beyond capture requires unlocking. **Use the same camera UI** in the app and the locked experience so the transition is seamless. **Provide instructions for adding the control.** Not supported in watchOS, tvOS, or visionOS.

## Live Activities (iOS, iPadOS; surfaced on Mac, Apple Watch, CarPlay)

Lets people track the progress of an activity, event, or task at a glance, with frequent updates over a few hours and optional interaction. Started on iPhone or iPad, they appear on the Lock Screen, Home Screen, Dynamic Island, and StandBy (iPhone); the Mac menu bar; the Apple Watch Smart Stack; and the CarPlay Dashboard.

**Presentations you must support:** **compact** (Dynamic Island, one active activity — leading and trailing elements either side of the camera) · **minimal** (Dynamic Island, multiple activities — one attached, one detached, circular or oval by size) · **expanded** (touch and hold a compact or minimal presentation) · **Lock Screen** (a banner at the bottom of the Lock Screen; also briefly overlays the Home Screen or other apps on devices without the Dynamic Island). **StandBy** shows the minimal presentation, transitioning on tap to the Lock Screen presentation scaled 2×, with a custom background color extended to fill the screen.

**Best practices**
- **For tasks and events with a defined beginning and end**, ideally **no longer than eight hours**.
- **Focus on glanceable information.** Not everything — the most useful thing, concisely. Tapping opens the app for detail.
- **No ads or promotions.**
- **Avoid sensitive information** — Live Activities are prominently visible, including on the Always-On display. Show an innocuous summary and reveal detail in the app, or redact and let people configure it.
- **Match your app's visual aesthetic and personality** in both appearances.
- **A logo mark goes without a container**, and never the whole app icon.
- **Don't draw attention to the Dynamic Island** from within your app — it appears while your app isn't in use, and other things appear there while it is.
- **Large, heavier-weight text** (medium or above); small text sparingly.

**Layout.** Adapt to different screen sizes and presentations; use the Apple Design Resources templates. Adjust element size and placement so the layout uses only the space it needs. **Use consistent margins and concentric placement** — match a rounded rectangle's corner radius to the Live Activity's outer radius minus the margin (`ContainerRelativeShape`) so nothing pokes into the rounded shape. Separate blocks of content with an inset container shape or a thick line; **don't draw content to the edge of the Dynamic Island**. (Tip: blur your layout in your drawing tool to check alignment against the rounded perimeter.) **Dynamically change the height** on the Lock Screen and in the expanded presentation — a rideshare app shows a compact activity while locating a driver and extends as pickup time, driver details, and more arrive.

**Color.** You can't customize backgrounds for the compact, minimal, and expanded presentations; you can for the Lock Screen. **Ensure contrast** — especially for tints on an Always-On display with reduced luminance. **Use bold colors** for text and objects to express your app's personality, make the activity recognizable at a glance, and reinforce relationships between elements. **Tint the key line color** to match your content — when the background is dark, a key line appears around the Dynamic Island.

**Animation.** System and custom animations up to **two seconds** (none on Always-On displays with reduced luminance). **Reinforce the information and draw attention to updates** — the default content-replace transition, or custom scale, opacity, and movement (numeric transitions for score changes; a timer fading out at zero). **Animate layout changes** by moving existing elements to new positions rather than removing and re-adding them. **Avoid overlapping elements** — sometimes animating an element out and back in at a new position avoids a collision. When animating list items, animate only the one that moves and fade the others.

**Interactivity.** **Tapping opens the app at the right location.** **Focus on simple, direct actions** — buttons and toggles consume space that could show information. Include them only for essential functionality directly related to the activity and activated once or temporarily (music playback, workouts, live audio recording). **Prefer limiting interactivity to a single element** so people don't hit the wrong control. Consider letting people respond to updates (contacting a driver while waiting).

**Lifecycle.** **Start at appropriate times** — after a food order, a rideshare request, or when a followed match begins — and **make it easy to turn them off in your app** (a button to unfollow a game). Unexpected Live Activities are surprising and unwanted, and people who can't control them turn the feature off entirely. **Offer an App Shortcut that starts your Live Activity** so people can trigger it from the Action button. **Update only when new content is available.** **Alert only for essential updates** — alerts light up the screen, play the notification sound, and show the expanded presentation or a banner. Don't also send push notifications for the same updates. **Prefer a single Live Activity that rotates through multiple events** rather than several activities people must jump between. **Always end it immediately when the task or event ends**, and consider a custom dismissal time proportional to the duration — usually **15 to 30 minutes** is right (a rideshare app keeps a summary visible for 30 minutes so people can tip). On ending, the system removes it immediately from the Dynamic Island and CarPlay; it remains up to four hours on the Lock Screen, the Mac menu bar, and the watchOS Smart Stack.

**Per presentation.** **Compact** — the most important, dynamic information, easy to understand (two team logos and the score). **Design the leading and trailing elements to read as one piece of information** with consistent color and typography, despite the camera between them. **Keep content narrow and snug against the camera**, without obscuring key status bar information and without padding. Keep the leading and trailing views similarly sized — use shortened units or less precise data to balance them. Both elements link to the same screen. **Minimal** — make it recognizable; prefer updated information over a static logo (Timer shows remaining time). **Expanded** — an enlarged version of the compact or minimal presentation. **Maintain the relative placement of elements** so information expands predictably. **Wrap content tightly around the camera** to use space efficiently and diminish the camera's presence. **Lock Screen** — **don't replicate notification layouts**; create a layout specific to the information. **Choose colors that work on a personalized Lock Screen** — use custom background and tint colors and opacity sparingly. Verify contrast in Dark Mode and on an Always-On display with reduced luminance; the default is a light background in light appearance and dark in dark. **Verify the generated dismiss button color** (`activitySystemActionForegroundColor(_:)`). **Standard margin: 14 pt.** **StandBy** — update the layout for the larger scale, and consider a custom one. **Consider the default background color** — it blends with the bezel, achieves a softer look, and lets the system scale slightly larger because it needn't account for camera margins. **Use standard margins** and don't extend graphics to the screen edge; without margins content gets cut off as the activity extends. **Verify in Night Mode**, where the system applies a red tint.

**CarPlay.** The system combines the compact presentation's leading and trailing elements into a single Dashboard layout. **Your design applies to both CarPlay and Apple Watch.** The system **deactivates interactive elements in CarPlay** — if people are likely to start or watch your activity while driving, prefer timely content over buttons and toggles. Consider a custom layout via the `ActivityFamily.small` supplemental family if you'd benefit from larger text or more information.

**macOS.** Active Live Activities appear in the menu bar of a paired Mac using the compact, minimal, and expanded presentations; clicking launches iPhone Mirroring. **watchOS.** A Live Activity started on iPhone appears at the top of the Smart Stack, defaulting to the combined compact leading and trailing elements. Tapping opens your watchOS app, or a full-screen view with a button to open the iPhone app. **Consider a custom watchOS layout** for more information and interactivity — but remember it also applies to CarPlay, where interactive elements are deactivated, so omit buttons and toggles if people may be driving. Focus on progress (a delivery ETA), interactive elements (stopwatch or timer controls), and significant updates (score changes). Not supported in tvOS or visionOS.

## Complications (watchOS)

A complication displays timely, relevant information on the watch face. Most faces show at least one; some show four or more. watchOS 9+ organizes complications (accessories) into **families** — circular, inline, and others — with recommended layouts. Prefer **WidgetKit**; use ClockKit only to support earlier versions.

- **Identify essential, dynamic content people want at a glance.** People value up-to-date information more than a launcher; a static complication won't keep its spot.
- **Support all families when possible** — more families means more watch faces. If you can't display useful information for a family, provide an image (your app icon) so people can still launch the app.
- **Consider multiple complications per family.** A triathlon app could offer three circular complications, one per segment, each deep-linking into its own area — and a shareable watch face preconfigured with all three, so people can start immediately.
- **Define a different deep link per complication.** If they all open the same place, they seem less useful.
- **Keep privacy in mind** — the Always-On Retina display makes the face visible to others.
- **Choose update times carefully.** You supply a timeline of entries with display times; different data implies different timing (a meeting app might show the next meeting an hour ahead; a weather app shows the forecast at the time the conditions are expected). You can update the timeline a limited number of times per day and the system stores a limited number of entries.

**Visual design.** **Choose a ring or gauge style by data**: **closed** for a percentage of a whole (a battery gauge) · **open** when minimum and maximum are arbitrary (a speed indicator) · **segmented** for values within an app-defined range that can change rapidly (Noise). **Make images look good in tinted mode** — the system applies a solid color to text, gauges, and images and desaturates full-color images unless you supply tinted versions. Never use color as the only carrier of important information; supply an alternative tinted-mode image when desaturation looks bad; and recognize that people may prefer tinted mode over full color. **Use line widths of 2 pt or greater** — thinner lines are hard to see at a glance, especially in motion — with weights suited to the image's size and complexity. **Provide static placeholder images** per complication; the system uses them when there's no content (right after install, while it checks whether you can generate a localized placeholder) and in the complication picker carousel. Sizes vary by layout, and a placeholder's size may not match the actual image's.

**Circular layouts** include text, gauges, and full-color images for the Infograph and Infograph Modular faces, plus extra-large layouts for the X-Large face: closed gauge image · closed gauge text · open gauge image · open gauge text · open gauge range · image · stack image · stack text. Text can curve along the bezel of faces like Infograph, filling nearly 180° before truncating. Regular-size circular image sizes: 40 mm 42×42 pt · 41 mm 44.5×44.5 pt · 44 mm 47×47 pt · 45/49 mm 50×50 pt (all @2x). Closed gauge: 27 / 28.5 / 31 / 32 pt. Open gauge: 11 / 11.5 / 12 / 13 pt. Stack (non-text): 28×14 / 29.5×15 / 31×16 / 33.5×16.5 pt.

## App Shortcuts

An App Shortcut gives access to your app's key functions or content throughout the system — Siri, Spotlight, the Shortcuts app, the Action button on iPhone or Apple Watch, and an Apple Pencil squeeze. Because they're part of your app, they're available immediately after installation (a journaling app can offer "new entry" before first launch) and can reflect people's choices over time (FaceTime's recent contacts). App Shortcuts are built on **App Intents**; each combines one or more actions. **Up to 10 per app.**

- **Consider adopting app schemas instead** for common domains (email, music, photos) — schemas let Siri and other Apple Intelligence experiences surface your features contextually without individual App Shortcuts. **App Shortcuts are for unique features and custom content not covered by schemas.**
- **Offer them for your most common and important tasks.** Straightforward tasks completed without leaving the current context work best, though opening your app is fine for multistep tasks.
- **Add flexibility with a single optional parameter**: "Start [morning, daily, sleep] meditation." Use predictable, familiar option values — people won't have a list in front of them.
- **Ask for clarification** when optional information is missing — suggest the most recently used option or one based on the time of day. If one option is most likely, make it the default and offer a short list of alternatives.
- **Keep voice interactions simple.** If the phrase feels complicated aloud, it's too hard to remember. "Start [sleep] meditation with nature sounds" implies two parameters — ask for the second in a follow-up step.
- **Make App Shortcuts discoverable in your app** — show occasional tips when people perform the corresponding common action (`SiriTipUIView`).

**Responding.** Your app can respond with spoken dialogue and custom visuals. **Snippets** suit static information or dialog options — the weather at a location, an order confirmation. **Live Activities** suit information that stays relevant and changes over time — timers and countdowns until an event completes. **Provide enough detail for audio-only devices**: people receive responses on AirPods and HomePod, so put all critical information in the full dialogue text (`init(full:supporting:systemImageName:)`).

**Editorial.** **Brief, memorable activation phrases with natural variants.** You must include your app name, but you can be creative — Keynote accepts both "Create a Keynote" and "Add a new presentation in Keynote." **Title case and plural for "App Shortcuts" and "Shortcuts"** when referring to the feature or the app ("MyApp integrates with Shortcuts…", "offers App Shortcuts you can place on the Action button"). **Lowercase for individual shortcuts** ("Run a shortcut by asking Siri"). Not supported in tvOS; macOS doesn't support App Shortcuts, though App Intents actions work in the Shortcuts app on Mac.

## Snippets (iOS, iPadOS, macOS)

A compact view shown in response to an action taken via Siri, Spotlight, or the Shortcuts app. **Confirmation snippets** let people confirm or cancel an action and may include options affecting the result; **result snippets** provide information requiring no further action. An intent that displays a snippet always shows a result; the confirmation step is optional.

**Anatomy.** **Dialogue** — the intent dialogue Siri speaks, placed above the custom view by default. **Custom view** — a view communicating the information visually, optionally with buttons to modify content, get more information, or take another action. **System-provided buttons** — a confirmation snippet gets a secondary Cancel and a primary button with a customizable label; a result snippet gets a single Done button.

- **Ensure legibility** — sufficient contrast against the system background in both appearances, and consistent margins.
- **Keep content concise.** Snippets are lightweight and quick. **Custom views must be no taller than 400 pt.** Remember that fonts render at various sizes based on the person's text size setting. For more detail in a result snippet, deep-link into your app.
- **Choose a descriptive label for a confirmation snippet's primary button** — "Order" beats "OK" or "Proceed" for a coffee order. The system default is "Continue."
- **Communicate the purpose visually.** Don't rely on the dialogue text: the spoken dialogue is essential when nobody's looking at the screen, but in a snippet's visual representation, prefer omitting it and letting the custom view carry the information.

Not supported in tvOS, visionOS, or watchOS.

## Status bars (iOS, iPadOS)

Displays device state — time, carrier, battery — along the upper edge.

- **Obscure content under the status bar.** The background is transparent by default, so content shows through and can make the status bar unreadable — and if controls are visible behind it, people will try to interact with them and can't. **Prefer a scroll edge effect** to place a blurred view behind it.
- **Consider temporarily hiding it** for full-screen media (Photos hides it while browsing full-screen photos).
- **Avoid permanently hiding it** — people would have to leave your app to check the time or their Wi-Fi. Let a simple, discoverable gesture bring it back (a single tap in Photos).

## Top Shelf (tvOS)

The area at the top of the Apple TV Home Screen that showcases your content when your app is in the Dock, giving people a path straight into what they care about.

- **Help people jump right into your content.** The carousel actions and carousel details templates each include a primary button (begin playback) and a More Info button (open a detail view).
- **Feature new content** — new releases and episodes, upcoming titles — and avoid promoting content people have already purchased, rented, or watched.
- **Personalize.** People put their most-used apps in the Dock; show targeted recommendations, let people resume playback or return to active gameplay.
- **Avoid advertisements and prices.** People already chose your app. Purchasable content is fine, but lead with what's new and exciting and show prices only once people show interest.
- **Showcase compelling dynamic content**, preferably layered images. Static images are a fallback.
- **If you don't provide full-screen content, supply at least one static image** — the system flips and blurs it to fit 1920 px wide at 16:9. **2320×720 pt** (2320×720 px @1x, 4640×1440 px @2x). **Avoid implying interactivity** in a static image; it isn't focusable.

**Dynamic layouts.** **Carousel actions** — full-screen video and images with a few unobtrusive controls; great for content people already know something about (user-generated photos, new content from a familiar franchise). **Provide a succinct title** (the show, movie, or album title) and, if useful, a brief subtitle (a date range for a photo album, the show name for an episode). **Carousel details** — extends carousel actions with information (plot summary, cast, metadata). **Provide a title identifying the currently playing content**, near the top where it's easy to read; above it you can add a succinct phrase or app attribution ("Featured on My App"). **Sectioned content row** — a single labeled row of focusable content for recently viewed, new, or favorite items, with a label appearing on focus and small remote movements bringing the focused image to life. **Provide enough content to span the full width of the screen**, and include at least one label for platform consistency and context. Image sizes — poster (2:3): 404×608 pt actual, 380×570 pt focused/safe, 333×570 pt unfocused. Square (1:1): 608×608 / 570×570 / 500×500 pt. 16:9: 908×512 / 852×479 / 782×440 pt (all @1x; @2x doubles). **Be aware of scaling when mixing sizes** — images scale up to match the tallest, so a 16:9 image beside a poster or square scales to 500 px high. **Scrolling inset banner** — large images spanning nearly the full width, auto-scrolling on a timer until focused, then cycling back to the start. A small circular gesture on the Touch surface triggers the focus effect (animation, lighting, and a 3D effect for layered images); swiping pans. **Provide three to eight images** — fewer than three feels ineffective, more than eight makes navigation hard. **Text must be part of the image** (this layout shows no labels) — in layered images, put text on a dedicated top layer, and **add the text to the image's accessibility label** so VoiceOver can read it. **1940×692 pt** actual, 1740×620 pt focused/safe, 1740×560 pt unfocused.

## Watch faces (watchOS)

The heart of the watchOS experience: the view people choose to see on every wrist raise, customized with their favorite complications, often switched by context.

Since watchOS 7 people can **share** configured watch faces — a fitness instructor might configure the Gradient face with their favorite health complications and share it with students, who get a curated experience with no setup. You can share a face from your app, your website, Messages, Mail, or social media.

- **Help people discover your app by sharing watch faces featuring your complications.** Ideally support several so you can showcase them together. Some faces also let you specify a system accent color, images, or styles. If people add your face without your app installed, the system prompts them to install it.
- **Display a preview of each shared face.** Email the face to yourself from the iOS Watch app to get one — it includes an illustrated device bezel suitable for websites and apps, or you can composite a high-fidelity hardware bezel from Apple Design Resources.
- **Aim to offer shareable faces for all devices.** California, Chronograph Pro, Gradient, Infograph, Infograph Modular, Meridian, Modular Compact, and Solar Dial require Series 4 or later; Explorer requires Series 3 (cellular) or later. If you use one of these, consider a similar configuration on a face available on Series 3 and earlier, and label each shared face with the devices it supports.
- **Respond gracefully to an incompatible choice.** The system returns an error on Series 3 or earlier; **immediately offer an alternative configuration** rather than showing an error, and set expectations in your previews.
