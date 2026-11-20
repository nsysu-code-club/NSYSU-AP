# Patterns

Guidance for common actions, tasks, and experiences.

Charting data · Collaboration and sharing · Drag and drop · Entering data · Feedback · File management · Going full screen · Launching · Live-viewing apps · Loading · Managing accounts · Managing notifications · Modality · Multitasking · Offering help · Onboarding · Playing audio · Playing haptics · Playing video · Printing · Ratings and reviews · Searching · Settings · Undo and redo · Workouts

---

## Launching

Launching starts when someone opens the app and ends when the first screen is ready. Onboarding comes *after*.

- **Launch instantly.** People don't want to wait more than a couple of seconds.
- **Launch screens** (iOS, iPadOS, tvOS — not macOS, visionOS, watchOS): the launch screen's only job is to make the app feel fast. It is not onboarding, not a splash screen, and not artistic expression.
  - Make it **nearly identical to your first screen**, or a solid color if that's what you show first. Anything that differs produces an unpleasant flash.
  - **No text.** It can't be localized.
  - **No logos or branding** unless they're a fixed part of the first screen.
  - Match the current orientation and appearance mode.
  - tvOS launch screens are static, unlike the rest of the platform's layered images.
- If you need a **splash screen**, put it at the start of onboarding — or immediately after launch if you have no onboarding.
- **Restore the previous state** granularly: scroll position, window state and location.
- iOS/iPadOS: launch in the device's current orientation if you support both. If you're single-orientation, launch in it and let people rotate — no instructions needed. Landscape-only apps must work rotated either way.
- tvOS live-viewing apps: consider auto-starting playback after a few seconds of inactivity.
- visionOS: consider launching in the Shared Space even for a fully immersive app — it gives context, time to load, and a control to enter immersion.

---

## Onboarding

- Ideally people understand the app by using it. If onboarding is necessary, make it **fast, fun, and optional**.
- **Teach through interactivity.** People retain what they do, not what they read.
- **Prefer context-specific tips** over one upfront flow. A tip lets someone concentrate on one action while making progress. Display instructions near the UI they refer to. (TipKit.)
- If you need a prerequisite flow, keep it brief and enjoyable, with nothing to memorize.
- A separate tutorial should be skippable — and once skipped, never shown again on launch, but easy to find in help, account, or settings.
- Keep content focused on your app. People don't need to learn the system or the device from you.
- **Splash screens** should be brief — long enough to absorb at a glance, not long enough to feel like a delay.
- **Don't let downloads block onboarding.** Ship enough content to start immediately.
- Don't put licensing details in onboarding. Let the App Store show agreements. If you must include them, integrate them without disrupting the flow.
- **Postpone nonessential setup.** Provide good defaults so people can start immediately.
- If the app can't function without private data, integrate that permission request into onboarding — you get to show why and what the benefit is. Otherwise, ask at the moment the feature is used.
- Let people experience the app before you ask for ratings or purchases.

---

## Loading

The best loading experience finishes before anyone notices it.

- **Show something as soon as possible.** An empty screen reads as a bug. Use placeholder text, graphics, or animation and replace them as content arrives.
- Let people do other things while content loads in the background.
- If loading is unavoidably long, give people something worth looking at — gameplay hints, tips, new features. Gauge the remaining time so the filler neither flashes by nor repeats.
- Download large assets in the background (Background Assets framework) right after installation, during updates, or at other nondisruptive times.
- Communicate that loading is happening and roughly how long: determinate when you know, indeterminate when you don't. See Progress indicators in COMPONENTS.md.
- Games can justify a custom loading view matching the game's style.
- watchOS: avoid loading indicators as much as possible. If content needs a second or two, an indicator still beats a blank screen.

---

## Feedback

Feedback tells people what's happening, what's next, what an action produced, and how to avoid mistakes. **Match the delivery to the significance**: passive display for status, interruption for possible data loss.

- **Make all feedback accessible.** Use color *and* text *and* sound *and* haptics so people receive it whether they've silenced the device, looked away, or are using VoiceOver.
- **Integrate status feedback into the interface** so people get it without leaving their context (Mail shows the last-update time and unread count in the mailbox toolbar).
- Use **alerts** only for critical, ideally actionable information. Alerts lose impact through overuse.
- **Warn about unexpected, irreversible data loss** — and *don't* warn when data loss is the expected result (the Finder doesn't warn every time you throw away a file).
- Confirm a significant action's completion when it matters (a successful Apple Pay transaction). People expect success, so mostly they only need to hear about failure.
- When a command can't be carried out, say so and say why.
- watchOS: avoid indeterminate progress indicators — an animated indicator implies the person should keep watching. Promise a notification instead.

---

## Modality

Modality presents content in a dedicated mode that blocks the parent view and requires an explicit dismissal. It can ensure critical information is received, offer options that confirm or modify a recent action, support a narrowly scoped task without losing context, or create immersion.

- **Only when there's a clear benefit.** Modality removes people from their context.
- **Keep modal tasks simple, short, and streamlined.** A complicated modal task makes people lose track of what they suspended.
- **Don't build an app within your app.** A hierarchy of views inside a modal task makes retracing steps impossible. If subviews are required, provide a single path through them and avoid buttons that could be mistaken for the dismissal.
- Full-screen modal style suits in-depth content or complex multistep tasks — video, photos, camera, markup, editing. In visionOS, a full-screen modal fills the window in the Shared Space and can become more immersive in a Full Space.
- **Always give an obvious dismissal**, following platform convention: top toolbar button or swipe-down (iOS, iPadOS, watchOS); a button in the main content view (macOS, tvOS).
- **Confirm before closing** if dismissal would lose user-generated content — regardless of whether people used a gesture or a button. On iOS an action sheet with a save option works well.
- **Title the modal view** with its task, or add descriptive text. People may not return right away.
- **One at a time.** Multiple visible modal views create clutter and cognitive load. Dismiss one before presenting another. An alert may appear above anything — but never two alerts.

---

## Searching

- If search is important, **give it a primary position** — a bottom toolbar item alongside other important actions, or a dedicated tab.
- Aim for a **single search location** covering all of your content. Apps with genuinely distinct sections can add local search that filters the current view.
- **Display the scope clearly** — descriptive placeholder text, a scope bar, or a title. Mail always shows which mailbox you're searching.
- **Provide suggestions**: recent searches before typing, predictive suggestions while typing.
- **Start searching as people type** — continuously refined results feel responsive.
- **Take privacy into account** before showing search history, and give people a way to clear it.
- Consider letting people filter results with a scope bar.

**Systemwide search (Spotlight).** Index your content with descriptive metadata so people find it without opening the app. Define metadata for custom file types (`CSImportExtension`). Offer advanced file search inside your app via Spotlight — a button that initiates a Spotlight search on the current selection, with results in a custom or filtered view. Prefer system open and save views (they include search that filters the whole system). Implement a Quick Look generator for custom file types so Spotlight and other apps can preview them.

---

## Settings

- **Aim for defaults that give the best experience to the most people** — detect the device, the accessory, the appearance, and configure accordingly. Ideally nobody has to adjust anything.
- **Minimize the number of settings.** Too many make an app feel unapproachable and make any one setting hard to find.
- Make settings available where people expect: Command-Comma on Mac and with a hardware keyboard; Esc in games.
- **Don't use settings to ask for information you can get another way.**
- **Respect systemwide settings and never duplicate them.** A custom version of a global option implies system settings might not apply to you, and that yours might affect other apps.
- **General settings** — infrequently changed, app-wide (window configuration, game-save behavior, keyboard mappings, account options) — belong in your settings area.
- **Task-specific options** belong in the screen they affect: showing/hiding parts of a view, reordering, filtering. Putting them in a settings area disconnects them from context and hides the result.
- Add only the most rarely changed options to the system Settings app; if you do, provide a button that opens it directly.
- **macOS**: settings open from the App menu (or File for document-level options). Never a toolbar button. Dim the minimize and maximize buttons. Use a noncustomizable toolbar that always shows the active pane. Update the window title to the current pane (or "App Name Settings" for a single pane). Restore the most recently viewed pane.
- **watchOS**: no custom settings in the system Settings app. Put a small number of essential options at the bottom of the main view, or in a More menu.

---

## Entering data

- **Get information from the system whenever possible** — settings, or with permission, location and calendar.
- **Be clear about what you need**: a placeholder like "username@company.com" or an introductory label like "Email." Prefill reasonable defaults.
- **Secure text-entry fields** for sensitive data. tvOS digit entry views can obscure numerals. In visionOS, the system shows entered data to the wearer only — a secure field blurs under AirPlay.
- **Never prepopulate a password field.**
- **Offer choices instead of text entry** where you can — pickers, menus, selection components are faster than typing even with a keyboard at hand.
- Support **drag and drop** and **paste**.
- **Validate dynamically** and give feedback immediately, so nobody discovers ten errors after filling a long form. For numeric data, use a number formatter (it restricts input and formats output as decimals, percentages, or currency).
- If data is required to proceed, make that visible — keep the Next/Continue button unavailable until the required fields are filled.
- macOS: expansion tooltips reveal clipped or truncated field text on hover.

---

## Undo and redo

People will try undo repeatedly until something changes — often without remembering what they're undoing.

- **Help people predict the result.** On iPhone, describe it in the shake alert. In menu items, label the target: "Undo Typing", "Redo Bold".
- **Show the result.** If the affected content has scrolled offscreen, scroll it back — otherwise people think nothing happened and undo again.
- **Let people undo multiple times.** Don't cap it arbitrarily; people expect to undo everything since opening a document or saving.
- Consider reverting a *batch* of related changes at once (incremental adjustments to one property), or offering a way to undo everything since the last save.
- **Provide undo/redo buttons only when necessary.** People use the Edit menu, keyboard shortcuts, or shake. If you do need buttons, use the standard symbols in a toolbar.
- iOS/iPadOS: don't redefine the standard three-finger swipe or shake gestures. Alert titles automatically get an "Undo "/"Redo " prefix — supply a word or two after it ("Undo Name", "Redo Address Change").
- macOS: Edit menu, Command-Z and Shift-Command-Z.
- Not supported in tvOS or watchOS.

---

## Offering help

- **Let the task determine the help.** A one- or two-step task needs an inline view; a complex multistep task may warrant a tutorial. Relate help to what's happening right now, and make it easy to dismiss or avoid.
- Use relevant, consistent language and imagery — don't show a game-controller image to someone using a Siri Remote; don't say "click" on iPhone or "tap a menu item" on Mac.
- Make all help content inclusive.
- **Don't explain standard components.** Describe what the standard element does *in your app*. If you introduce a genuinely unique control or nonstandard input use, orient people quickly with animation or graphics, not prose.

**Tips (TipKit).** A tip is a small, transient view describing how to use a feature.
- Types: **popover** (preserves content flow) · **inline** (keeps surrounding information visible) — as an **annotation** pointing to a specific element, or a **hint** when it isn't tied to one.
- Use tips for simple features. More than three actions is too complex for a tip.
- Short, actionable, engaging: one or two sentences, direct action-oriented language, no promotion, nothing off-topic.
- **Define eligibility rules** — parameter- or event-based — so people who already use a feature never see its tip. Set a display frequency (e.g. once every 24 hours) when you have more than one.
- Include an associated symbol or image, preferring the filled variant — but don't repeat an image that the tip already points at.
- Add a button to reach settings or more resources.

**Tooltips (macOS, visionOS).** Appear on hover (macOS, visionOS) or gaze (visionOS).
- Describe **only** the control the person indicated interest in.
- Explain the action, usually starting with a verb: "Restore default settings", "Add or remove a language from the list."
- Don't repeat the control's name — it wastes space.
- **60–75 characters maximum** (localization will lengthen it). Sentence fragments and omitted articles are fine. If you need a lot of text, simplify the interface instead.
- Sentence case. Omit ending punctuation on complete sentences unless your style requires it.
- Context-sensitive tooltips per control state are worth considering.

---

## Managing accounts

- **Ask for an account only if core functionality requires it.** Otherwise let people use the app without one.
- **Explain the benefits** in the sign-in view, briefly and warmly.
- **Delay sign-in as long as possible.** Forced early sign-in is a major cause of abandonment. Let a shopping app be browsed; require sign-in at purchase.
- Prefer **Sign in with Apple**; otherwise prefer **passkeys**. If you must keep passwords, add two-factor authentication.
- **Always name the authentication method**: "Sign In with Face ID", not "Sign In."
- Reference only methods available on the current device (`LABiometryType`).
- **Don't offer an app-specific biometric opt-in** — biometrics are a system-level choice, and duplicating it confuses.
- **Avoid the term *passcode*** for account authentication; people will think you're asking for their device passcode.

**Deleting accounts.** If people can create an account in your app, you must let them **delete** it — not just deactivate it — and comply with regional right-to-be-forgotten law.
- Provide a clear in-app path, or a direct link to the webpage that does it. Don't bury it in a Privacy Policy or Terms page.
- Keep the in-app and web deletion flows equivalent in length and complexity.
- Consider letting people schedule deletion (to use up remaining service or wait for a renewal) — but always also offer immediate deletion.
- Say when deletion will complete, and notify when it's done.
- If you support in-app purchases, explain that auto-renewable subscription billing continues through Apple until cancelled, regardless of account deletion; that people need to cancel or request a refund afterward; and how to do both. **You must support account deletion even if the subscription wasn't purchased in your app.**
- If legal requirements force you to retain records or follow a specific process, describe that clearly.
- Revoke Sign in with Apple tokens on deletion.

**TV provider accounts (tvOS).** Use TV Provider Authentication so people sign in once at the system level. Don't show a sign-out option when they're signed in at system level; if you must, direct them to Settings > TV Provider. **Never** tell people to sign out via privacy controls — Settings > Privacy manages which apps can access the account, it isn't a sign-out.

**Platform notes.** tvOS: minimize data entry; prefer signing up or authenticating on another device via associated domains; support shared-credential, per-profile keychain storage so people don't pick a profile every time; show the email keyboard with recent addresses when you need an address. watchOS: use iCloud Keychain sync for autofill and settings.

---

## Managing notifications

You need permission before sending any notification. People can change that decision, and can silence everything except government alerts in some locales.

**Focus and delivery.** A **Focus** filters notifications during an activity. **Delivery scheduling** batches alerts into a summary. People choose which contacts and apps break through. To participate, classify your notifications: **communication notifications** (calls, messages — adopt SiriKit intents so people can customize via Siri) or **noncommunication notifications**, which need an **interruption level**:

| Level | Overrides scheduled delivery | Breaks through Focus | Overrides Ring/Silent |
|---|---|---|---|
| **Passive** — view at leisure (a restaurant recommendation) | No | No | No |
| **Active** (default) — worth knowing on arrival (a score update) | No | No | No |
| **Time Sensitive** — directly impacts the person, needs immediate attention (account security, package delivery) | Yes | Yes | No |
| **Critical** — urgent health/safety; extremely rare, usually governmental | Yes | Yes | Yes |

Critical notifications require an entitlement. A Focus may delay the *alert*, but the notification itself arrives immediately.

- **Build trust by representing urgency accurately.** People can turn all of your notifications off.
- **Time Sensitive only for the moment**: the event is happening now or within the hour. The first time you send one, the system explains it and offers a way to turn it off — and periodically re-offers.

**Marketing notifications.** Only with explicit, separate permission — an alert, modal view, or other interface describing what you'd send and offering a clear opt in/out. **Never** send a marketing notification at the Time Sensitive level. You must also provide an in-app settings screen where people can change their choice.

**watchOS.** iPhone notification settings apply by default; people manage them in the Watch app or per-notification by swiping left on arrival.

---

## Drag and drop

Content moves from a **source** to a **destination**. General rule: dropping within the same container **moves**; dropping in a different container **copies**. Between apps it's always a copy.

- **Support it broadly.** People try it everywhere. System components (text fields, text views) get it for free.
- **Always offer an alternative** — menu commands to copy and move. In iOS/iPadOS, expose sources and destinations to accessibility APIs (`accessibilityDragSourceDescriptors`, `accessibilityDropPointDescriptors`).
- Decide move vs. copy deliberately, favoring what people expect and what's least likely to cause frustration or data loss.
- **Support multi-item drags.** iPadOS lets people add items to a drag in progress; macOS lets people gather items from several apps.
- **Prefer letting people undo** a drop. Ask for confirmation before an irreversible one (the Finder does this for write-only folders). Where undo isn't possible, offer a way to reverse the result (Photos lets people cancel sharing after the drop).
- **Offer multiple representations**, highest to lowest fidelity, so the destination takes the best it can handle (native chart object → PDF → lossless PNG → JPEG).
- Consider **spring loading** — activating a control by dragging content over it (force-click on a Magic Trackpad, hover on iPad) without dropping.

**Feedback**
- Show a **drag image** as soon as the selection moves ~3 points. Make it translucent so it reads as a representation and lets destinations show through. Keep it until the drop.
- Modify the drag image when it clarifies the result (expanding to the photo's default size in a document). Use **drag flocking** to group multiple items visually and ungroup them on drop. Don't make it change constantly.
- **Show whether a destination accepts the content** — insertion point or highlight when it does, nothing or an explicit `circle.slash` when it doesn't. Only while the content is over the destination. With multiple candidates, indicate one at a time.
- On an invalid drop or a failure, animate: return to source if visible, or scale up and fade out to "evaporate."

**Accepting drops**
- Auto-scroll a scrolling destination while an item hovers over it; stop when the drag leaves.
- Take the richest representation you can use.
- Extract only the relevant portion (Mail takes name and address from a dragged contact, not the postal address).
- With a keyboard attached, check the **Option** key at drop time — holding it forces a copy within the same container.
- Show progress for transfers that take time; place a placeholder at the drop location in collections, lists, and tables. Show progress when a drop initiates a task like printing.
- **Styling**: preserve the original font, size, and attributes when both sides support them; otherwise apply the destination's style.
- **Selection**: keep dropped content selected in the destination. On a move, it disappears from the source. On a same-container copy, deselect the original. On a cross-container drag, deselect in the source.

**Platform notes.** iOS/iPadOS: support multiple simultaneous drag activities with flocking. macOS: allow drags to the Finder in a format you can reopen (Calendar exports `.ics`; text becomes a clipping); allow dragging a **background selection** from an inactive window without activating it, and individual items without disturbing that selection; badge multi-item drags with a count; change the pointer (copy, drag link, disappearing item, operation not allowed); allow select-and-drag in a single motion. visionOS: handle content dropped into empty space by launching a window or scene via `NSUserActivity`. Not supported in tvOS or watchOS.

---

## Collaboration and sharing

- **Put the Share button somewhere convenient**, like a toolbar. The system share sheet handles method selection and permissions. SwiftUI's `ShareLink` presents it.
- Customize the share sheet to offer the sharing types you support. With CloudKit, pass both the file and the collaboration object to enable "send a copy"; iCloud Drive does it by default; for custom collaboration, include a file or plain-text representation.
- **Write succinct permission summaries** — "Only invited people can edit", "Everyone can make changes." The system uses your text in the button that reveals sharing options.
- Keep custom sharing options minimal and grouped so they're understandable at a glance: who can access, read vs. edit, whether collaborators can invite others.
- **Show the Collaboration button as soon as collaboration starts**, next to the Share button. It reminds people the content is shared and identifies who's sharing.
- The collaboration popover has three sections: collaborators with Messages/FaceTime buttons (top), your custom items (middle), the manage-file button (bottom). Offer only essentials in the middle.
- Customize the management button's title if "Manage Shared File" doesn't fit. CloudKit provides the management view; otherwise build your own.
- Post collaboration events to Messages (content changes, membership changes, mentions) with a universal link into the relevant view (`SWHighlightEvent`).
- Custom collaboration infrastructure requires **universal links** support.

**visionOS.** Screen sharing streams the current window for apps in the Shared Space; transitioning to a Full Space pauses the stream for others until you return. **watchOS**: use `ShareLink`. Not available in tvOS.

---

## File management

- Use **app menus and keyboard shortcuts** for creating and opening documents. Provide New and Open; iPadOS surfaces them in the Command-key shortcut interface, macOS in the File menu. Regardless, include an Add (+) button.
- A custom file browser must respect the platform's file system. Open at the most relevant location, but let people reach the rest of it.
- **Save automatically.** Periodic saves while editing, plus on close and on app switch. Don't make saving an explicit action.
- **Hide file extensions by default**, but let people show them — and reflect the choice in every open and save interface.
- **Quick Look**: use a **viewer** so people can preview files your app can't open; implement a **generator** for your custom file types so the Finder, Files, and Spotlight can preview them.

**iOS/iPadOS document launcher** (18+). A full-screen browse-and-create experience with three parts: a **title card** (app title plus two app-specific buttons), a **background image** with optional **accessory** images around the card, and a **sheet** containing the file browser and optional controls.
- Assign the title card's buttons to your most important functions — primary usually creates a new document (Numbers: "Start Writing"), secondary offers alternatives ("Choose a Template").
- Background clearly distinct from accessories and card; solid color, gradient, or simple pattern; no complex imagery.
- Place accessories in front of and behind the card for depth, but keep the app name and both buttons visible. Don't clutter. Test across screen sizes and orientations.
- Animate sparingly — gentle, repeating breathe or sway at most.

**File provider extension** (iOS/iPadOS). Displays only contextually appropriate documents (only PDFs for a PDF editor), optionally with modification dates, sizes, and local/remote status. Let people choose a destination when exporting or moving, and consider letting them add subdirectories. **Don't add a custom top toolbar** — the modal view already has one.

**macOS.** Use the default file browser unless you have an important reason not to. Make a custom open interface convenient: "open recent," filters, multi-select, a customized Open button title ("Insert"). Provide a save interface for renaming, reformatting, and relocating; default title "Untitled"; offer format choice if you support several; consider a custom accessory view in the Save dialog (Mail's "include attachments"). **Finder Sync extensions** show sync badges, contextual menu items, and toolbar buttons. If people turn off autosaving ("Ask to keep changes when closing documents"), show a dot on the window's close button and next to the name in the Window menu, and present a save dialog on close/quit/logout/restart. When autosave is *on*, showing that dot is confusing — but appending "Edited" to the title bar is fine, as long as you remove it on save.

Not applicable to tvOS or watchOS, which don't provide document browsing.

---

## Multitasking

With rare exceptions (some games, visionOS Full Space apps), every app needs to work well with multitasking.

- Always be ready to save and restore context — you can't predict when people switch.
- **Pause anything requiring attention or participation** when people switch away, and let them resume as if they never left.
- **Respond smoothly to audio interruptions**: pause indefinitely for primary audio interruptions (music, podcasts, audiobooks); duck or briefly pause for short ones (GPS prompts) and restore afterward.
- **Finish user-initiated tasks in the background** — a download or a video export should complete even after a switch.
- **Use notifications sparingly.** Notify when an important, time-sensitive task the person started completes. Don't notify for routine or secondary completions.

**Platform notes.** iOS: PiP and FaceTime over other apps. iPadOS: multiple windows, freely resizable, with system tiling controls; the frontmost window has colored controls and casts a shadow; apps don't control or learn about the multitasking configuration. macOS: the default mode; system drop shadows and visual effects distinguish window states. tvOS: PiP where supported. visionOS: multiple apps in the Shared Space, but only one active window — looking away makes a window more translucent and recede along the z-axis, and the system applies a feathered edge mask, **so don't change the appearance of window edges**. Closing a window backgrounds the app without quitting; closing the Now Playing app's window pauses audio (resumable from Control Center). **Don't pause video when someone looks away.** Be ready for your audio to duck when you're not the Now Playing app. Not supported in watchOS.

---

## Going full screen

Available on iPhone, iPad, and Mac. Apple TV and Apple Watch already fill the screen. Apple Vision Pro instead expands windows or transitions to a Full Space.

- Support it where it helps: games, media, photo slideshows, in-depth focused tasks.
- **Adjust the layout, don't resize the window programmatically.** Keep essential content prominent, use the extra space well, and keep adjustments subtle enough to avoid a jarring transition.
- **Keep essential controls reachable** without exiting — persistent or easily revealed playback controls, for instance.
- Except in games, **let people reveal the Dock** in iPadOS and macOS. To prevent accidental reveals during a game, defer the initial bottom-edge swipe (iPadOS) or hide the Dock (macOS).
- When people switch away, help them resume — pause games and slideshows automatically.
- **Let people choose when to exit.** Don't exit automatically when they switch apps or finish an activity.
- Hiding toolbars and navigation for a distraction-free view is fine when content is the point — but restore them with a familiar gesture (tap, swipe down, pointer to the top edge), and keep controls visible when they're essential.
- iOS/iPadOS: the Home Screen indicator hides shortly after launch and reappears on interaction near the bottom. Preserve that. Only enable two-swipe exit if single-swipe causes unexpected exits.
- macOS: use the system full-screen support (`toggleFullScreen(_:)`) — it handles the camera housing automatically. **Don't change the display mode** when a game goes full screen. Let people enter via the window button, the View menu, or Control-Command-F; avoid a custom window-modes menu (a game may add a simple toggle).

---

## Charting data

Charts communicate complex information without a wall of text — and give you room for personality. Use them for analyzing trends, visualizing a changing state, and comparing across categories. **Not every dataset needs a chart** — if you just need to present data, a scrollable, searchable, sortable list or table may serve better.

- Use a chart when you want to **highlight** something about a dataset. Charts are visually prominent; be clear about what people can learn.
- **Keep it simple**, with progressive disclosure for depth. Too much data obscures the very relationship you're showing. Offer levels of detail or subsets; consider several versions of increasing capability to teach the interaction.
- **Make every chart accessible.** Accessibility labels that describe values and components, plus accessibility elements for interaction.
- **Prefer common chart types** — bar and line charts carry built-in reading skills.
- If you must invent a representation, teach it (Activity introduces its rings by animating them individually during Watch pairing).
- **Examine the data from multiple levels**: macro (totals, averages), mid (useful subsets), individual (outliers, notable values). Surfacing several perspectives invites engagement.
- **Add descriptive text** — titles, subtitles, annotations, and a headline summary. Weather's "Chance of light rain in the next hour" above the hourly forecast is the model. A headline helps but does **not** replace accessibility labels.
- **Match size to function.** Big enough for the labels and interaction you support; small enough to serve as a glanceable preview when that's the role.
- **Prefer consistency** across charts serving similar purposes; deviate only to highlight a real difference. Multiple views of one dataset should share type, colors, annotations, layout, and descriptive text (Health Trends → expanded view).

See **Charts** in COMPONENTS.md for marks, axes, color, and accessibility mechanics.

---

## Playing audio

People control sound through volume buttons, the iPhone Ring/Silent switch, headphone controls, Control Center, and third-party accessories. Match their expectations:
- **Silence** — people switch to silent to avoid unexpected sound. Silence nonessential sounds: keyboard clicks, effects, soundtracks, audible feedback. Media playback, alarms, and A/V messaging still play.
- **Volume** — system volume governs everything (except the iPhone ringer, adjusted separately).
- **Headphones** — reroute automatically without interruption on connect; **pause immediately** on disconnect.

**Practices**
- Adjust relative levels for a good mix; never change the overall volume.
- **Permit rerouting** (stereo, car radio, Apple TV) unless there's a compelling reason not to.
- Use the system volume view (`MPVolumeView`) — slider plus output routing — customizing only the slider's appearance.
- **Choose the right audio category**:

| Category | Meaning | Behavior |
|---|---|---|
| Solo ambient | Nonessential, silences other audio (a game soundtrack) | Respects silent switch · doesn't mix · no background |
| Ambient | Nonessential, doesn't silence others (a game that lets you play your own music) | Respects silent switch · mixes · no background |
| Playback | Essential; may mix (audiobook, language app) | Ignores silent switch · may mix · plays in background |
| Record | Recording (note-taking with audio) | Ignores silent switch · doesn't mix · records in background |
| Play and record | Both, possibly at once (messaging, video calls) | Ignores silent switch · may mix · both in background |

- **Respond to external audio controls only when it makes sense** — when you're actively playing, in a clear audio context, or connected via Bluetooth/AirPlay. Otherwise don't halt another app's audio.
- **Never repurpose audio controls.** If you don't support a control, don't respond to it.
- Build custom player controls only for commands the system lacks (custom skip increments, related content like a sports score).
- Flag your session so other apps know when they can resume (`notifyOthersOnDeactivation`).

**Interruptions.** Decide how to respond; you can ask the system not to interrupt current audio for an incoming call unless the person accepts. Consider the VoIP case: closing an iPad Smart Folio mutes the mic and interrupts the session — restarting it on reopen would unmute without the person's knowledge. On interruption end, decide whether to resume: **resumable** (an incoming call) vs. **nonresumable** (a new playlist). A media app should check the type; a game can just resume, since its audio wasn't an explicit choice.

**Platform notes.** iOS/iPadOS: Audio Services for short sounds and vibrations. macOS: notification sounds mix by default. tvOS: audio plays only when people initiate it — no sounds for alerts or notifications. visionOS: **prefer playing sound** — a silent app feels lifeless or broken. Design custom sounds for custom elements, since system components already sound. Use **Spatial Audio**: ambient audio anchors the world; positional sources locate objects, moving with them. Vary repeated sounds (the virtual keyboard subtly randomizes pitch and volume) — randomizing at playback beats authoring many files. Decide between **fixed** sound (always pointed at the wearer, as in Mindfulness) and **tracked** sound (from a specific object). Never communicate important information by sound alone. watchOS: the system manages playback; short clips while foregrounded, longer audio continues across wrist-down and app switches. Use **64 kbps HE-AAC**. Consider a Now Playing view.

---

## Playing video

The system provides video players for iOS, iPadOS, macOS, tvOS, and visionOS. Default playback mode depends on aspect ratio: **full-screen (aspect-fill)** for wide video (2:1 to 2.40:1), **fit-to-screen (aspect)** for standard (4:3, 16:9, up to 2:1) and ultrawide (above 2.40:1). In visionOS and tvOS the player adds **transport controls** (subtitles, audio language, favoriting) and **content tabs** (Info, Episodes, Chapters); in visionOS the controls appear as an ornament.

- **Use the system player.** If you truly need a custom one, mirror the system player's behavior and interface — small divergences frustrate people whose habits stop working.
- **Always display video at its original aspect ratio.** Embedded letterbox/pillarbox padding breaks scaling, makes video appear smaller in both modes, and prevents correct display in edge-to-edge contexts like PiP.
- Provide additional information (image, title, description) where it adds value, without obscuring playback (`externalMetadata`).
- Support the interactions people expect from whatever input they have — Space to play/pause on a connected keyboard everywhere; Siri Remote gestures on Apple TV.
- tvOS: add a transport control or a custom content tab only for genuinely useful actions and succinct information; people are watching, so nothing should take more than a step or two.
- **Prevent audio from mixing across modes.** The classic failure: a full-screen video is moved to PiP (auto-muted), a game starts in full screen with background music, then the person unmutes the PiP video — if the game mishandles secondary audio, both play. (`silenceSecondaryAudioHintNotification`.)

**TV app integration.** The TV app fades to black and doesn't show your launch screen: present your own black screen immediately and jump straight into content. **No splash screens, detail screens, or intro animations** before playback. Don't ask whether to resume — just resume, at the previous stop point for long clips. Play/pause on Space from a Bluetooth keyboard. If you support profiles, switch to the one the TV app specifies; if none is specified, ask once and remember.

**Loading.** Avoid loading screens. If loading exceeds ~2 seconds, show a black screen with a centered spinner and nothing else. Show it only until enough content has loaded to begin, and continue loading in the background. Keep any branding minimal on that black background.

**Exiting.** People stay in your app, so show a contextually relevant screen — a detail view for what they just watched with a resume option, or a menu of that content, or your main menu. Prepare the exit view as soon as you get a playback notification, in case they exit immediately.

**Platform notes.** tvOS: defer to content with overlays — small and unobtrusive; some displays suffer image retention, so prefer short, translucent SDR graphics over bright opaque ones. Interactive overlays (quizzes, surveys) need a minimum 0.5 s delay before pausing, and a clear way to dismiss and resume. visionOS: help people stay comfortable — let them start playback, use a small resizable window, keep surroundings visible. In a fully immersive context, don't let virtual content occlude the system-placed player or its ornament. **Never auto-start a fully immersive video.** Supply a **thumbnail track** at 160 px wide for scrubbing. Don't expand an inline player to fill a window — inline video must be 2D, with window content visible around it. Use a **RealityKit video player** for splash and transitional video (correct aspect ratio for 2D and 3D, closed captions, no playback controls) and for video on a custom surface. watchOS: short clips only, ideally ≤30 seconds — long clips consume space and force people to hold their wrist up. Encode H.264 High Profile, 160 kbps up to 30 fps, 208×260 px full screen (portrait) or 320×180 px (16:9 landscape), audio 64 kbps HE-AAC. Don't scale clips. Poster images should represent the content and must not look like a system control.

---

## Playing haptics

- **Use system haptic patterns for their documented meanings.** People recognize them from standard controls. If the documented use doesn't fit, use a generic pattern or build a custom one — don't repurpose.
- **Be consistent.** Build a clear causal relationship between a haptic and its trigger. Using the same pattern for a failure and a level completion is genuinely confusing.
- **Complement other feedback.** Match intensity and sharpness to the accompanying animation; synchronize with sound.
- **Don't overuse.** A haptic that delights occasionally becomes tiresome at high frequency. The best haptic experience is often one people don't notice until it's gone.
- **Prefer short haptics on discrete events** in apps. Long-running haptics can enhance gameplay flow but dilute meaning in an app — and on Apple Pencil Pro they make the pencil unpleasant to hold.
- **Make haptics optional** and ensure the app works without them.
- Haptics produce real physical force — make sure they don't disrupt the camera, gyroscope, or microphone.

**Custom haptics.** Two building blocks: **transient** events (brief, tap-like — the Flashlight button) and **continuous** events (sustained vibrations — the lasers message effect). Control **sharpness** (soft/rounded/organic vs. crisp/precise/mechanical) and **intensity**. Combine with optional audio via Core Haptics. Vary dynamically with input or context — a character jumping from a tree should feel stronger than jumping in place.

**iOS feedback generators** (`UIFeedbackGenerator`):
- **Notification** — Success (task completed) · Warning (produced a warning) · Error (an error occurred).
- **Impact** — Light (small/lightweight objects) · Medium · Heavy · Rigid (hard/inflexible) · Soft (soft/flexible).
- **Selection** — values changing.

**macOS** (Magic Trackpad, on drag or force click): **Alignment** (a dragged item aligns, scales to fit, reaches a preferred position, or hits a min/max) · **Level change** (movement between discrete pressure levels) · **Generic**.

**watchOS**: Notification · Up · Down · Success · Failure · Retry · Start · Stop · Click. Series 4 and later add Digital Crown haptic detents — linear by default; tables can use row-based detents instead.

**Other**: iPadOS, macOS, tvOS, and visionOS game controllers can play haptics. Apple Pencil Pro and some trackpads provide haptics on compatible iPads.

---

## Printing

Available in iOS, iPadOS, macOS, and visionOS.

- **Make printing discoverable** in standard locations: a Print item in the macOS File menu; a toolbar button opening an action sheet in iOS/iPadOS. A macOS toolbar Print button is fine as an optional, customizable item.
- **Present the option only when it's possible.** Dim the File menu item or remove the action when there's nothing to print or no printers available. Dim or hide custom print buttons.
- Use the system view to present relevant options (page range, copies, duplex) that the printer supports.

**macOS.** Add a **custom category** to the print panel for app-specific options the system doesn't offer — name it after your app (Keynote offers presenter notes, slide backgrounds, skipped slides). Present a **page setup dialog** for rarely changed, document-specific settings (size, orientation, scaling) — but don't duplicate what the system already handles. Make interdependencies clear (double-sided rules out transparencies). Separate advanced options behind a disclosure control labeled "Advanced Options." Let people preview a setting's effect. Store modified settings with the document, at minimum until it closes.

---

## Ratings and reviews

- **Ask only after demonstrated engagement** — a completed level, a significant task. Never on first launch or during onboarding; people haven't formed an opinion, and asking early biases it negatively.
- **Don't interrupt a task or a game.** Look for natural breaks.
- **Don't pester.** At least a week or two between requests, and only after additional engagement.
- **Prefer the system prompt** (`RequestReviewAction`). It checks for prior feedback, allows a rating and optional written review in one tap, can be opted out of globally, and is automatically limited to three appearances per app per 365 days.
- Weigh resetting your summary rating on a new release: it reflects the current version, but fewer total ratings can discourage downloads.

---

## Live-viewing apps (tvOS)

- **Feature live content prominently** and make it easy to reach — minimize the interval between launch and playing. Live content in the first tab means one tap.
- **One tap, or zero.** A Watch Now button over featured or recently viewed content that disappears on tap, replacing the UI with a full-screen viewing experience.
- **Make live content look live.** Playing it is best; otherwise mark it — a "Live" collection row, a badge, symbol, or sash on each item.
- Indicate the progress of in-progress live content so people know where they'll land.
- Offer additional actions — record, restart, download, favorite — in a consistent order throughout the app, with playback always primary. Show alternative airtimes when the content repeats.
- A **content footer** lets people browse channels during playback. Give it a subtle darkening for legibility, badge or tint the currently playing thumbnail, match its categories to the EPG, and make invoking and dismissing symmetric (swipe up / swipe down).
- **Instant visual feedback on channel change** — confirmation plus cover for streaming latency.
- **Match audio to context.** Audio continues while browsing within the live tab; navigating away from the live tab stops it.

**EPG.** Prominently display the current program, channel, and time so people can jump back. Make paging, scrolling, and jumping easy. Offer My Channels or Favorites. Group into familiar categories (Movies, TV Shows, Kids, Sports, Popular) and mirror them in the content footer. Let people browse the EPG without leaving their content (PiP or background playback).

**Cloud DVR.** Start and stop recording from the info panel. Let people schedule a future program with an option for that episode or all future episodes. Support precise rules (current episode, new episodes only, specific teams). Allow playback and deletion inside the DVR area, plus recording settings. Offer storage management, ideally automatic overwriting of oldest or already-viewed content.

---

## Workouts

- In a watchOS fitness app, use **workout sessions** so the app stays visible between wrist raises. Show the metrics people care about — elapsed/remaining time, calories, distance — and relevant controls like lap or interval markers.
- **Don't distract during a workout.** People don't need your workout catalog or other app areas mid-session. The common arrangement: large session controls (End, Resume, New) on the leftmost screen; metrics on a dedicated, glanceable screen; media controls on the rightmost.
- **Distinguish an active workout visually** — real-time updating values plus a unique layout.
- Controls must be easy to find and tap, with clear feedback on start and stop.
- **Explain unavailable sensor data.** Water blocks heart rate, GPS doesn't work in a pool — but the accelerometer still tracks calories, laps, and distance. Match the system Workout app's language: "GPS is not used during a Pool Swim, and water may prevent a heart-rate measurement, but Apple Watch will still track your calories, laps, and distance using the built-in accelerometer."
- **Provide a summary** at the end, ideally including Activity rings.
- **Discard extremely brief sessions** automatically, or ask.
- **Legible in motion**: large fonts, high contrast, most important information easy to read.
- Use Activity rings only for their documented purpose (see FOUNDATIONS.md and TECHNOLOGIES.md).
