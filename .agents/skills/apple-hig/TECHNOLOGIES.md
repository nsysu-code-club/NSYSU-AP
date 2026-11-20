# Technologies

Apple technologies, features, and services you can integrate — and the design rules that come with each.

AirPlay · App Clips · Apple Pay · Augmented reality · CareKit · CarPlay · Game Center · Generative AI · HealthKit · HomeKit · iCloud · ID Verifier · iMessage apps and stickers · In-app purchase · Live Photos · Mac Catalyst · Machine learning · Maps · NFC · Photo editing · ResearchKit · SharePlay · ShazamKit · Sign in with Apple · Siri · Tap to Pay on iPhone · VoiceOver · Wallet

**Recurring themes across all of them:** ask for the minimum data at the moment you need it · never replicate an Apple-provided button, badge, icon, or UI · never translate an Apple trademark, and never make one plural or possessive · give people an alternative when the technology isn't available.

---

## Siri

People use Siri to find, know, and do things — by voice, by swiping down from the Dynamic Island, or in the Siri app. On supported devices, **Siri AI** is powered by Apple Intelligence: when an app integrates its content and features, people can start the app's actions from anywhere in the system, interact with what's onscreen, and reach features that would otherwise require deep navigation. "Send a message to Marisa in AppName" from anywhere; "Add this photo to my Landscapes album," then "And email it to Josh"; "Make this black and white" faster than navigating menus.

**Getting your app to work with Siri.** By default the system knows nothing about what your app can do. You expose your **actions (intents)** and **content (entities)** through the **App Intents** framework, which makes them available to Siri, Spotlight, and the Shortcuts app. To get more, adopt **app schemas** — preset templates for functionality the system already understands. Apps in common domains (email, music, photos) inherit built-in logic for handling requests with natural conversation and deeper contextual understanding.

**Sharing contextual information.** Annotate your views and content with **app entities** so Siri understands references to onscreen things — buttons, graphics — during a conversation. **Donate entities to the on-device Spotlight index** so your information is searchable. **Donate actions as intents** so Siri can anticipate what people might do next and surface it at the right time.

**Best practices**
- **Identify your most popular actions, and when and where they occur.** Understanding the contexts (hands-free, a particular device) tells you what to expose and how to design for it.
- **Use familiar terms.** You choose the terminology for an intent or entity — track, song, or podcast. Pick what people are most likely to recognize.
- **Offer relevant content.** Rather than telling Spotlight about everything, prefer what's personally relevant — recent searches, favorites, bookmarks, wishlists. Some categories (email, messaging) reasonably treat the whole catalog as relevant.
- **Don't advertise.** No ads, marketing, or in-app purchase pitches in content Siri delivers.
- **Only provide a custom response if the built-in ones don't meet your needs.** Siri anticipates a wide variety of natural language requests without configuration.

**Customizing.** Apps outside the existing schema domains can expose custom actions with **App Shortcuts** (see COMPONENTS.md). Within a schema, you can define optional properties that contextually enhance a response — a playback control snippet Siri displays while audio plays. Because responses appear in many contexts, some nonvisual, **optional properties may not always appear.**

**Writing responses**
- **Clear and descriptive.** An effective response conveys what happens when Siri performs the action. Customize default dialogue for follow-up questions: "Which soup?" beats "Which one?"
- **As succinct as possible.** People hear the same response repeatedly. Use conversational context to remove details. **Avoid humor** — it becomes irritating over time.
- **Provide responses Siri can deliver audibly and visually** so it can choose. A weather request shows a forecast onscreen; on AirPods, Siri speaks it. **The voice response must stand alone** without depending on visuals.
- **Design inclusive interactions.** Avoid unnecessary pronouns — for "Send a message to my best friend," say "Who should I send it to?" not "What's his or her name?"
- **Ask an open-ended question when the option list is too long** — "What kind of shoes are you interested in?" rather than reading everything.
- **Keep responses device-independent.** People start a request on one device and it takes effect on another. If you must reference a device, be accurate and contextual.
- **Omit your app name** — the system already attributes verbally and visually.
- **Use appropriate language and respect parental controls.** No offensive language; many families restrict explicit content, and Siri may respond aloud where others can hear.
- **Help people understand errors.** Enhance the system's default error descriptions with something specific: "Sorry, we're out of chicken noodle soup" beats "Sorry, we can't complete your order."

**Editorial.** Refer to Siri by name — **never with pronouns** (she, him, her). "After you add a shortcut to Siri, you can run the shortcut anytime by asking Siri." **Never impersonate Siri**, reproduce its functionality, or provide a response appearing to come from Apple. **Don't use reserved phrases** like "Call 911" or "Hey Siri." In localized contexts, **translate only the word "Hey"** — Siri is a trademark and is never translated (Dis Siri · Hey Siri · Hej Siri · Oye Siri · Ehi Siri · Hé Siri · Hei Siri · Hai Siri · E aí Siri · привет Siri · หวัดดี Siri · 嘿Siri · 喂 Siri · يا Siri · Siri야).

---

## Generative AI

- **Design responsibly.** Consider direct and indirect impacts on people, systems, and society. Generative AI is easy to prototype and hard to make robust — small input changes (or the *same* input twice) produce very different outcomes, and you can't anticipate every request. Orient the process around inclusivity, care, and privacy.
- **Keep people in control.** Respect agency; people make the decisions. Honor in-scope requests with clear expected output; handle sensitive content carefully. **Let people dismiss content they don't want and revert or retry transformations.** **Clearly identify when and where you use AI.**
- **Ensure an inclusive experience.** Models learn from data and favor the most common information, producing biased and stereotyped output. **Ask people for the information the feature needs** rather than inferring personal or cultural characteristics. **Seek clarity before assuming** — gender identities, relationship types. **Test across a diverse set of people** to find and correct stereotypes.
- **Design engaging and useful features.** Generative AI isn't right for every situation. Offer it where it provides clear, specific value — time savings, better communication, enhanced creativity.
- **Ensure a great experience when it isn't available or people opt out.** Genmoji is fun, but regular emoji still work; notification summaries speed catching up, but notifications remain readable. **Offer a non-AI fallback when you can.**

**Transparency.** **Communicate where you use AI** so people can knowingly choose. **Never trick someone into thinking they're interacting with a human.** Align disclosure with regional regulations. **Set clear expectations** about capabilities and limitations — a brief tutorial on introduction; curated suggestions for open-ended prompts; up-front disclosure of known limitations, how to get good results, and why inferior results occur.

**Privacy.** **Choose a model type that fits and protects privacy.** On-device models keep information on the device, respond quickly, and work offline. Server-based models offer more processing power and a larger context size. **Weigh privacy alongside capability and performance**, process as much locally as possible, and minimize what's shared. **Be transparent** about what goes to a server, what's stored off-device, and what's used for training. **Ask permission before using personal information and usage data**, use the minimum, and offer a clear opt-out. Get explicit permission for model improvement or storage. Understand third parties' privacy practices. **Be aware that model outputs can inadvertently contain sensitive information.** Apps for kids have stricter rules and laws. **Disclose clearly how your app and model use and store personal information** — concise, specific, easy to understand, including whether you train on it.

**Models and datasets.** **Thoughtfully evaluate capabilities** — some models carry general knowledge, others are task-specific. Get hands-on early to orient your design. Some model types may be unavailable due to device compatibility, network access, or battery (the Foundation Models framework needs a compatible device with Apple Intelligence on). **Be intentional about your dataset** — it shapes behavior more than anything else. Choose diverse representations, know where the data came from and how it was gathered, license anything you don't own, and offer appropriate choices when using people's data. Most real-world datasets are imperfect; **allow time for testing and evaluation to proactively mitigate bias and misinformation**.

**Inputs.** **Guide people toward good results** — diverse predefined example inputs hint at what's possible. **Raise awareness of and minimize hallucinations.** An unsure model produces plausible, made-up content, often presented convincingly as fact — dates, information about people. **Clearly communicate that AI-generated content may contain errors.** Minimize the risk by carefully scoping what you ask a model to generate. **Avoid requesting factual information** unless you're confident the model has verified, up-to-date information. **Never use AI-generated content where a hallucination could misinform and harm someone.** **Consider consequences and get permission before irreversible or problematic tasks** — never automate destructive actions like deleting photos, or hard-to-undo ones like making a purchase. Generally ask for confirmation before a significant action on someone's behalf. Review model usage policies and applicable government and regulatory AI policy per locale.

**Outputs.** **Make it easy to refine or revert, and acknowledge when corrections take effect.** Surface Edit, Undo, Retry, or Adjust near the generated content. When people adjust output, give a clear signal their action had an effect — this builds an accurate mental model and fosters trust. **Help people improve blocked requests** — Image Playground says "Unable to use that description"; consider offering example requests likely to work better. **Reduce unexpected and harmful outcomes through design and testing.** Harm arises from accidental and purposeful misuse and from sensitive topics. Identify risks, devise policies, and evaluate: test out-of-scope requests, requests unrelated to your experience, and requests poorly represented in training data; try poorly phrased, vague, and ambiguous requests; include personal, sensitive, and controversial topics; actively encourage harmful or incorrect results. **Strive to avoid replicating copyrighted content** — build on models that already protect against it, curate inputs carefully (a set of pre-approved prompts), and explicitly instruct the model to avoid mimicking specific content or styles. **Factor processing time into your design** — non-generative models (ARKit body tracking, Vision) run in real time, but generative models take longer. Design a loading experience or generate in the background. **Give specific, reassuring feedback during generation** — "Finding substitutions for ingredients" or "Summarizing key themes from your notes" beats "Processing…". If something goes wrong, describe it in plain language and offer a next step. **Consider offering alternate versions** — a choice gives people control and bridges the gap between the model's interpretation and what they want (Image Playground generates several representations of a person).

**Continuous improvement.** Plan for updating your model — behavior changes, feedback, new data, better capabilities. Some improvements (a blocked-word list) can ship independent of the app cycle; significant ones align with app updates. Moving to a newer base model requires fine-tuning, retesting, and prompt engineering. **Let people share feedback on outputs** to catch what testing missed — always voluntary, in a clear place that doesn't interrupt, ideally quick (thumbs up/down) with an option for detail. **Take feedback seriously and resolve issues quickly.** **Design flexible, adaptable features** — separate the model from the user experience so you can swap models over time.

---

## Machine learning

Features powered by machine learning depend on well-designed models as much as well-designed UI. Because behavior is derived from data, you can't design reactions to a static set of scenarios — you design how the app interprets data and reacts.

**Defining the role of ML in your app**
- **Critical or complementary.** Face ID cannot work without ML (critical); QuickType suggestions are optional (complementary). The more central a feature is, the more people expect accuracy and reliability; for secondary features they're more forgiving.
- **Private or public.** The more sensitive the data, the more serious an inaccurate result. A misinterpreted health recommendation causes anxiety and lost trust; a bad music recommendation is inconsequential. Sensitive-data features must prioritize accuracy and reliability, and **all** apps must protect privacy.
- **Proactive or reactive.** Proactive features deliver results nobody asked for (Siri Suggestions); reactive ones respond to a request or action (QuickType). **People have less tolerance for low-quality proactive results**, and you may need more data to avoid intrusive or irrelevant suggestions.
- **Visible or invisible.** Visible features offer suggestions or choices people interact with (Image Playground); invisible ones improve the experience without people noticing (News's proactive topic suggestions). Visible features let people judge reliability; invisible ones can't communicate reliability or gather feedback easily.
- **Dynamic or static.** Some models improve as people interact; others improve offline and change only on app update. Dynamic features often incorporate calibration and feedback; static ones might not.

**Explicit feedback** is information people provide in response to a specific request from your app. (Favoriting and social reactions are **implicit** feedback — people use them for their own goals, not to answer your question.)
- **Request it only when necessary.** It costs people effort; prefer implicit feedback.
- **Always voluntary.** Communicate that it helps without making it feel mandatory.
- **Simple, direct language describing each option and its consequence.** Avoid imprecise terms like *dislike* — they don't convey consequences and translate badly. "Suggest less pop music", "Suggest more thrillers", "Mute politics for a week."
- **Add icons only when they clarify.** Never an icon alone — it can't communicate granularity or consequences.
- **Consider multiple, progressively more specific options.** A sense of control, and a way to identify and remove unwanted suggestions.
- **Act immediately and persist the change.** Hide identified content everywhere. Reacting visibly builds trust in the value of giving feedback.
- **Consider feedback about when and where to show results** — people may like a result but not at certain times or in certain contexts.

**Implicit feedback** arises as people use your features, giving broad information about behavior and preferences without extra effort.
- **Always secure people's information.**
- **Help people control their information.** People may be surprised when what they do in one app affects another, and may assume apps are sharing private information. Tell people how you get and share information and give them ways to restrict it.
- **Don't let implicit feedback shrink exploration.** It reinforces behavior — good short-term, potentially worse long-term. Matching everything someone likes now doesn't encourage discovering anything new.
- **Use multiple signals.** Implicit feedback is indirect; viewing, sharing, and adding a photo to an album doesn't necessarily mean someone likes it.
- **Consider withholding private or sensitive suggestions.** People share accounts and devices, and switch to communal ones.
- **Prioritize recent feedback.** Tastes change; Face ID prioritizes recent facial input. Fall back to history when recent data isn't available.
- **Update predictions at a cadence matching the mental model.** Typing suggestions update immediately; continuously updated song recommendations make people feel rushed and overwhelmed.
- **Expect UI changes to change your feedback.** Even moving a button changes how it's used, without changing its value. Account for that when interpreting.
- **Beware confirmation bias.** Implicit feedback is constrained by what people can see and do — it rarely reveals new things they'd like.

**Calibration** is information people provide up front so a feature can function (scanning your face for Face ID). **Use it only when the feature can't work without it**; otherwise gather what you need implicitly or explicitly.
- **Always secure the information.**
- **Be clear about why you need it.** People must understand the value; emphasize **what the feature does**, not how it works.
- **Collect only the essential minimum.** A unique experience requesting little makes people comfortable and builds trust.
- **Avoid asking more than once**, and do it early. Evolve your understanding through feedback afterward. (The exception is calibration with an *object* rather than a person — a swing-analysis app may need to calibrate at each new baseball field.)
- **Make it quick and easy**: prioritize a few important pieces and infer the rest; avoid asking for information people would have to look up; avoid actions that might be difficult.
- **Make success achievable.** Give an explicit goal and show progress — Face ID describes the task and changes the tick marks encircling the face as you go.
- **Provide assistance immediately if progress stalls.** People feel powerless and lose trust. Give actionable recommendations, **never imply something's wrong or that they're at fault**, and never leave them without a next step.
- **Confirm success.** Reward the effort with a clear path into the feature; an explicit completion helps people switch focus.
- **Let people cancel at any time**, without judgment and without messaging about the cancellation — they'll get another chance next time.
- **Let people update or remove calibration information**, inside and outside the calibration experience.

**Mistakes.** Your app will make them. **Anticipate** them and design ways to avoid and mitigate. **Help people handle** them with tools matching the consequences. **Learn from** them when doing so improves the app — sometimes learning causes unpredictability.
- **Understand the significance of the consequences.** Incorrect keyboard suggestions annoy; a travel route causing a missed flight is serious. Match the corrective tools to the seriousness.
- **Make frequent or predictable mistakes easy to correct**, or people lose trust.
- **Continuously update** to reflect evolving interests, and add domain-specific information (current entertainment trends) — ideally people benefit without doing anything.
- **Address mistakes without complicating the UI** where possible. Corrections and limitations integrate seamlessly; attributions are harder — and an attribution that turns out to be wrong magnifies the original mistake.
- **Be especially careful with proactive features.** People have less patience for mistakes in something they didn't ask for, and those mistakes reduce their sense of control.
- **Watch the effect on other areas.** Optimizing dog recognition may degrade cat recognition. As models evolve, mistakes evolve; use what you know about preferences to prioritize.

**Corrections** fix your app's mistakes.
- **Familiar, easy ways to correct.** Show the steps your app took — Photos highlights the controls it used to auto-crop, so people use the same ones to refine or undo.
- **Provide immediate value.** Display corrected content instantly, especially for critical features or direct input, and persist it so nobody corrects the same thing twice.
- **Let people correct their corrections**, with the same immediacy and persistence.
- **Balance benefit against effort.** People tolerate mistakes in an automated task — but stop using the feature if doing it themselves is easier.
- **Never rely on corrections to make up for low-quality results.** It erodes trust and devalues the feature.
- **Learn from corrections when it makes sense** — verify the correction will lead to higher-quality results first.
- **Prefer guided corrections to freeform ones.** Guided suggests specific alternatives (speech-to-text alternatives); freeform requires more input (adjusting a crop). A combination works too.

**Multiple options** give a greater sense of control and bridge the gap between the model's prediction and what people want. Contexts: **suggested options** (proactive, based on past interactions — Apple Music's For You) · **requested options** (reactive, based on recent actions — QuickType) · **corrections**.
- **Prefer diverse options.** Balance accuracy with diversity — Maps suggests a no-tolls route, a scenic route, and a highway route.
- **Avoid too many.** Each option must be evaluated. Where possible, fit them on one screen without scrolling.
- **List the most likely first.** Use confidence values if you know how they correlate with quality, and contextual information (time of day, location). Consider selecting the first by default.
- **Make options easy to distinguish and choose.** In a routing app people must choose fast to avoid going the wrong way. Describe each briefly, highlighting the differences. Group into scannable categories when there are too many for one view.
- **Learn from selections** when it doesn't hurt the experience. Continuing to offer incorrect results decreases trust.

**Confidence** is a measure of certainty for a result. Not all models produce it. **Higher confidence doesn't automatically mean a higher-quality result** — verify the correlation (review values across multiple thresholds, compare across app versions). **If you're not sure how confidence correlates with quality, don't convey it to people.**
- **Know what your values mean before deciding how to present them.** Presenting low-quality results prominently erodes trust.
- **Translate confidence into concepts people already understand.** "97% match" next to a song doesn't help anyone choose. "Because you listen to pop music" is actionable.
- **Where attributions don't help, imply confidence through ranking or ordering.** If you must display it directly, use semantic categories — "high chance", "low chance" — to give the numbers context.
- **Display values where people expect statistical information** — weather, sports statistics, polling.
- **Convey confidence as actionable suggestions** wherever possible. For a price-prediction feature, "This is a good time to buy" or "Consider waiting for a better price" beats a percentage.
- **Consider changing your presentation at different thresholds.** Photos displays photos of a person when confidence is high, and asks people to confirm when it's lower.
- **Avoid showing results at low confidence**, especially in a proactive feature. Set a threshold below which you offer nothing.

**Attribution** expresses the basis for a result without explaining how the model works — "Because you've read mysteries." Use it to encourage people to change what they do, minimize the impact of mistakes, help build a mental model, and promote trust over time.
- **Use attributions to help distinguish among options** — "New books by authors you've read."
- **Avoid being too specific or too general.** Overly specific attributions demand interpretive work and can feel like surveillance; overly general ones provide nothing and make people feel unindividuated.
- **Keep attributions factual and objective.** An attribution helps people reason — it shouldn't provoke an emotional response or imply judgment of feelings, preferences, or beliefs. "Because you've read nonfiction", not "Because you love nonfiction."
- **Avoid technical or statistical jargon** unless the result itself is statistical (weather, sports, polling, election results, scientific data).

**Limitations** are things a feature can't do well and things it can't do at all. When expectations and capability diverge, a limitation looks like a defect.
- **Help people establish realistic expectations.** For a serious but rare limitation, make people aware before they use the feature — in marketing materials or within the feature's context — so they can decide how much to rely on it. For less serious effects, attributions help set expectations.
- **Demonstrate how to get the best results.** Photos' search bar shows "Photos, People, Places…" and describes how it scans the library. Memoji responds to conditions and suggests adjusting the lighting or moving closer. **Suggest alternative ways to accomplish the goal** rather than showing no results — which requires understanding the goal well enough to suggest something sensible.
- **Explain how limitations cause unsatisfactory results.** Intermittent-seeming failure is frustrating; Memoji tells people it doesn't work well in the dark.
- **Consider telling people when limitations are resolved** so they can adjust their mental model and return to interactions they'd learned to avoid.

---

## VoiceOver

A screen reader that lets people experience your interface without seeing the screen. Supported on all Apple platforms and in Unity via Apple's plug-ins.

**Descriptions**
- **Provide alternative labels for all key interface elements.** System controls have generic labels by default — supply descriptive ones conveying your app's functionality, and add labels to custom elements. **Keep them up to date** as the interface changes.
- **Describe meaningful images.** Without a description people can't fully experience them. Describe only what the image conveys — VoiceOver already handles the surrounding interface, including captions.
- **Make charts and infographics fully accessible** with a concise description of what each conveys. If people can interact with an infographic for more information, make those interactions available to VoiceOver users too.
- **Exclude purely decorative images.** Describing them wastes time and adds cognitive load (`accessibilityHidden(_:)`, `isAccessibilityElement`).

**Navigation**
- **Use titles and headings.** The title is the first thing an assistive technology reports on arriving at a page. Give each page a unique, succinct title, and use accurate section headings so people can build a mental model of the hierarchy.
- **Specify how elements are grouped, ordered, or linked.** Proximity and alignment convey relationships visually; find the places where a relationship is *only* visual and describe it. VoiceOver reads in the reading order of the active language and locale — in US English, top to bottom, left to right. Ungrouped images and captions get read as all images, then all captions; **grouped** elements get read as image-with-caption pairs (`shouldGroupAccessibilityChildren`).
- **Inform VoiceOver when visible content or layout changes.** An unexpected change invalidates people's mental map (`AccessibilityNotification`).
- **Support the VoiceOver rotor**, which lets people navigate by headings, links, and other content types, and brings up the braille keyboard (`AccessibilityRotorEntry`, `UIAccessibilityCustomRotor`, `NSAccessibilityCustomRotor`).

**visionOS.** When VoiceOver is on, apps and games defining custom gestures **don't receive hand input by default**, so people can explore the interface by voice without the app responding to their hands simultaneously. People can opt out with Direct Gesture mode, which disables standard VoiceOver gestures and passes hand input to the app.

---

## Always On (iPhone 14 Pro and later, Apple Watch)

The system continues displaying information in a low-power, privacy-preserving way when people stop interacting — dimming the display and minimizing motion. On iPhone it shows Lock Screen items like widgets and Live Activities when the device is set down face up; on Apple Watch it dims the face and continues showing the frontmost app or one running a background session. Notifications still appear, and a tap exits Always On.

- **Hide sensitive information.** Bank balances, health data, and anything personal visible in a notification.
- **Keep other personal information glanceable** where it makes sense — pace and heart rate during a workout, a flight arrival, a ride-share arrival. People who want nothing visible can turn Always On off.
- **Keep important content legible and dim nonessential content.** Increase dimming on secondary text, images, and color fills. A to-do app might remove row backgrounds and dim item details to highlight titles. Consider removing rich images and large color areas and using dimmed colors.
- **Maintain a consistent layout.** Avoid distracting changes when Always On begins or ends, and make infrequent, subtle updates within it. A sports app might pause play-by-play and update only the score. **Unnecessary changes are especially distracting on iPhone**, because a face-up device makes onscreen motion visible even to someone not looking at it.
- **Transition motion gracefully to a resting state** rather than stopping instantly, so it doesn't look like something went wrong.

Not supported in iPadOS, macOS, tvOS, or visionOS.

---

## Sign in with Apple

A fast, private way to sign in using an existing Apple Account — no forms, no email verification, no new password. People can share a unique random relay email address that forwards to their personal address. Available on every platform, including non-Apple platforms, with Face ID / Touch ID / Optic ID and built-in two-factor authentication. Apple doesn't use it to profile people.

**Offering it**
- **Ask people to sign in only in exchange for value.** A brief, approachable description of the benefits — personalization, additional features, synchronization.
- **Delay sign-in as long as possible.** People abandon apps forced to sign in before doing anything useful. A live-streaming app can let people explore before signing in to stream.
- **If you require an account, ask people to set it up before offering sign-in options.** Explain why the account is required, then let them choose a sign-in method.
- **Consider letting people link an existing account.** If a shared email matches an existing account, suggest linking. If people signed in with a username and password, offer linking in their account settings.
- **In commerce, wait until after a purchase to ask for an account.** With guest checkout, offer account creation on the order confirmation page — and if Apple Pay already provided a name and email, don't ask again.
- **Welcome people immediately** after sign-in completes; don't delay with unnecessary requests.
- **Indicate when people are signed in** — "Using Sign in with Apple" in a settings or account view.

**Collecting data.** Some apps need more (date of birth, region) — but minimize requests during setup and build on the trust people place in Sign in with Apple by explaining why you need each item and clearly displaying what you receive.
- **Clarify whether additional data is required or recommended.** Legally or contractually required data (terms agreement, country, birth date, real-identity information) must be presented as required; optional data that improves the experience must be presented as optional, with the benefit explained.
- **Don't ask for a password.** The whole point is not creating another one.
- **Avoid asking for a personal email address when people supply a relay address.** Respect the choice. If you need email-based identification for customer service or retail, let people view their relay address in your app, or direct them to Settings > Apple Account > Password & Security > Apps using Apple Account, or use another identifier like an order or phone number.
- **Let people engage before asking for optional data.** Suggest a phone number when they want text updates, or social information when they want to play with friends. **Never block account access or features because someone declined optional data.**
- **Be transparent about what you collect.** Welcoming people by the name or email they shared establishes how you use it — and for a relay address, shows them where to find it. If you ask for data you never display, people wonder why you asked.

**Buttons.** Use the system APIs (`ASAuthorizationAppleIDButton`, `WKInterfaceAuthorizationAppleIDButton`, the web equivalents) for an approved appearance, correct proportions at any size, automatic title translation, configurable corner radius (iOS, macOS, web), and VoiceOver alternative text. **Display the button prominently** — no smaller than other sign-in buttons, and not below the fold.

**Titles**: Sign in with Apple · Sign up with Apple · Continue with Apple (watchOS provides only "Sign in"). **Styles**: **white** (all platforms; on dark backgrounds with sufficient contrast) · **white with outline** (iOS, macOS, web; on white or light backgrounds where white alone lacks contrast — avoid on dark or saturated backgrounds, where the black outline adds clutter; use plain white there instead) · **black** (all platforms; on white or light backgrounds with sufficient contrast — never on black or dark). The watchOS black button uses a system dark gray, not pure black, to contrast with the display.

**Size.** Adjust the corner radius to match your other buttons — square, default rounded, or capsule. **Minimum 140×30 pt**, with a margin of **1/10 of the button's height**. Remember the title length varies by locale.

**Custom buttons** (iOS, macOS, web) are permitted for aligning logos across sign-in buttons, logo-only buttons, or matching your font, bezel, or background. **People must instantly recognize it as a Sign in with Apple button** — App Review evaluates all custom ones. **Use only the Apple-provided logo artwork** from Apple Design Resources (PNG, SVG, PDF, black and white), which includes the padding needed for correct proportions. Use the logo file to position the logo in a button; **never use the logo as a button**. Match the logo file's height to the button's height; don't crop it; don't add vertical padding.

**Don't change**: the titles (only the three above), the general shape (logo+text buttons are always rectangular; logo-only can be circular or rectangular), or the logo and title colors (both black or both white — no custom colors).

**You may change**: the title font (and its weight and size), the title case (all caps is allowed), the background appearance (overall color must stay black or white; a subtle texture or gradient is allowed), the corner radius, and the bezel and shadow.

**Logo+text buttons.** SVG and PDF at any height; **PNG only at 44 pt tall** (the iOS default and recommended height). Logos come in small, medium, and large. **Prefer the system font.** Regardless of font, keep the system's proportions: the title's font size is **43% of the button's height** (the button is **233%** of the font size, rounded to the nearest integer). **Preserve the default capitalization** (first word and Apple capitalized) unless your interface is all uppercase. **Vertically align the title to the middle of the button, then add the logo at the button's height** — the logo's built-in padding then aligns everything. Inset the logo if you need to align it with other authentication logos. **Minimum 8% of the button's width** as the margin between the title and the right edge. Minimum **140×30 pt**, margin **1/10 of the height**.

**Logo-only buttons.** SVG and PDF at any size; **PNG only at 44×44 pt**. **Don't add horizontal padding** — the aspect ratio is always 1:1 and the artwork includes correct padding on all sides. **Use a mask** to change the default square shape (circular, rounded rectangle). **Never crop the artwork to reduce its padding, use the logo alone, or add padding.** Margin: **1/10 of the button's height**.

---

## In-app purchase

For **virtual** goods — premium content, digital goods, subscriptions. (Use **Apple Pay** for physical goods, services, and donations.)

**Four content types:** **consumable** (lives, gems — depletes and can be repurchased) · **non-consumable** (premium features — never expires) · **auto-renewable subscriptions** (renew until cancelled) · **non-renewing subscriptions** (a fixed period, repurchased to extend).

- **Let people experience your app before purchasing.**
- **Design an integrated shopping experience** — people shouldn't feel they've entered a different app. Present products and handle transactions in your app's style.
- **Simple, succinct product names and descriptions** that don't truncate or wrap.
- **Display the total billing price** for every purchase, regardless of type.
- **Display your store only when people can make payments.** If they can't (parental restrictions), hide the store or explain why it's unavailable (`canMakePayments`).
- **Use the default confirmation sheet.** Don't modify or replicate it.

**Family Sharing.** Up to five additional family members can share auto-renewable subscriptions and non-consumable purchases across their devices. **Mention Family Sharing prominently** where people learn about your content — "Family" or "Shareable" in the name, a reference in the sign-up screen. **Help people understand the benefits and how to participate** — people receive system notifications about sharing changes. **Customize your in-app messaging for both purchasers and family members** — a family member seeing shared content for the first time should read something like "Your family subscription includes…".

**Refunds and help.** Present custom UI providing assistance, offering alternatives, and initiating the system refund flow (`beginRefundRequest(for:in:)`).
- **Provide help people can view before requesting a refund** — missing purchases, FAQs, feedback and direct support.
- **Use a simple title** — "Refund" or "Request a Refund." The system flow already makes clear the request goes to Apple.
- **Help people find the purchase**: a product image, name, description, and original purchase date.
- **Consider alternative solutions** — immediate fulfillment or a conciliatory item if the purchase didn't arrive — while making clear people can still request a refund.
- **Make requesting a refund easy.** Don't make people scroll or open another screen to find the button.
- **Don't characterize or interpret Apple's refund policies.** Don't speculate about outcomes. Link to Apple's refund page.

**Auto-renewable subscriptions**
- **Call attention to benefits during onboarding**, with a strong call to action and a clear summary of terms.
- **Offer a range** of content choices, service levels, and durations.
- **Consider a free trial** — a freemium app, a metered paywall, or a time-limited trial.
- **Prompt at relevant times** — approaching a free-content limit — and make subscribing possible at any time from relevant points.
- **Don't encourage a new subscription from an existing subscriber** — it makes people think their subscription lapsed. If you offer the same subscription across apps or a website, provide a sign-in option.

**Sign-up.** **Clear, distinguishable options** with short self-explanatory names, prices, and durations. If you offer an introductory price, list it, its duration, and the standard price afterward. **Ask only for necessary information** — a long sign-up lowers conversion; defer the rest. **In tvOS, let people sign up or authenticate on another device** by sending a code. **The in-app sign-up screen must include**: the subscription name, duration, and content or services per period; the billing amount, correctly localized for every territory and currency; and a way for existing subscribers to sign in or restore purchases. Alongside these, include links to your Terms of Service and Privacy Policy in the app and App Store metadata. **Clearly describe how a free trial works** — especially that a payment is automatically initiated for the next period when it ends. **Include a sign-up opportunity in your app's settings**, where people look.

**Offer codes** (iOS, iPadOS) give new, existing, and lapsed subscribers free or discounted access. **One-time use codes** are unique codes generated in App Store Connect, redeemable via a redemption URL, within your app, or in the App Store — good for small distribution or restricted access. **Custom codes** (NEWYEAR, SPRINGSALE) are redeemable via a URL or within your app — good for large campaigns. **Explain offer details clearly** in your marketing. **Custom codes use alphanumeric ASCII only** — no special, Chinese, or Arabic characters. **Tell people how to redeem a custom code**, since it can't be entered in App Store account settings. **Consider supporting in-app redemption** — the system provides the whole flow, so the only custom UI you need is what initiates it (`presentOfferCodeRedeemSheet(in:)`, `offerCodeRedemption(isPresented:onCompletion:)`). Natural places: your paywall, onboarding screens, or settings. **Supply an engaging promotional image** (the system falls back to your app icon). **Help people benefit immediately after redemption** — a welcome experience for new subscribers, a tour of new features for an upgrading one, and a smooth path for people who subscribe *before* opening your app for the first time.

**Subscription management** in your app lets people upgrade, downgrade, or cancel without leaving, and gives you a place to offer help and alternatives. **Provide summaries of the customer's subscriptions**, especially the upcoming renewal date, near the management option. **Consider the system-provided management UI** (`showManageSubscriptions(in:)`). **Consider encouraging retention** — a personalized offer as an alternative to cancellation, or an exit survey. **Always make cancellation easy.** A management action buried deep or hard to recognize feels like an obstruction. **Consider a branded, contextual experience** complementing the system UI — a popular premium tier, personalized alternatives, a promotional offer, or offer codes to win back lapsed subscribers.

**watchOS.** Show the same required information as elsewhere. **Clearly describe how versions differ across devices** — if the watchOS app offers a subset, say so, honestly, without implying identical experiences. **Consider a modal sheet** to present all required information in a single scrollable view, whose default Close button returns people to your free content in one tap. (If you build a custom view instead, design a complete flow with a Close or Cancel button.) **Make options easy to compare on a small screen**: one option per button (start signup in one tap; lock up each button with its description so the relationship survives scrolling), or a list of options followed by a button that updates to reflect the choice. Not supported in tvOS for the watchOS-specific guidance; in-app purchase itself works across iOS, iPadOS, macOS, tvOS, and visionOS.

---

## Apple Pay

For **physical** goods, services, donations, and subscriptions, in apps and any browser. (Use **In-app purchase** for virtual goods.) During checkout the payment sheet shows the linked card, the amount including tax and fees, shipping options, contact information, and other details. People authorize with Face ID, Touch ID, Optic ID, a double-click on Apple Watch, or — in browsers — a nearby iPhone or Apple Watch, or by scanning a code.

**Offering it**
- **Offer it on all devices and browsers that support it**, and don't present it where it isn't supported.
- **Make it the primary payment option when credentials are available.** If you use the APIs to check for an active card, you **must** make Apple Pay the primary (not necessarily sole) option everywhere you use them. **Don't separate it into a different step or flow** — pre-select it when displaying it alongside other options.
- **Use Apple Pay buttons only to initiate payment** or, where appropriate, the Apple Pay setup process. If someone's device doesn't have Apple Pay set up, choosing the button offers setup. **No other use.**
- **A custom button must not display "Apple Pay" or the Apple Pay logo.** In that case you must indicate that you accept Apple Pay by displaying the **Apple Pay mark** graphic or referencing Apple Pay in text on the same page.
- **The Apple Pay mark communicates acceptance only.** It doesn't facilitate payment. **Never use it as a button or position it as one.** When using it to indicate the selected payment method, create a separate custom button matching your design to initiate payment.
- **Don't hide an Apple Pay button or make it appear unavailable.** If it can't be used yet (no size or color selected), point out the problem gracefully *after* someone taps it.
- **Tell search engines you accept Apple Pay** in your semantic markup.
- All websites offering Apple Pay must include a privacy statement and follow the Acceptable use guidelines.

**Streamlining checkout**
- **Provide a cohesive experience.** Keep your branding throughout and avoid opening new pages or windows — on the web especially, a new window can look like a handoff to another site.
- **Assume people want to use it.** Present the Apple Pay button first, larger, or visually separated.
- **Accelerate single-item purchases** with Apple Pay buttons on product detail pages, purchasing that item only (excluding the cart) and removing it from the cart afterward if it was there.
- **Accelerate multi-item purchases with express checkout** — immediately show the payment sheet, using a single shipping method and destination.
- **Support coupons and promotional codes in the payment sheet** rather than as a separate step, especially in express checkout.
- **Collect necessary information (color, size) before people reach the button.** When something is missing at checkout, point it out gracefully with highlighting or warning text and navigate automatically to the field.
- **Collect optional information (gift messages, delivery instructions) beforehand or afterward** — there's no way to enter it on the payment sheet.
- **Gather multiple shipping methods and destinations before showing the sheet.** The sheet supports one shipping method and destination for the whole order.
- **For in-store pickup, choose the location before the sheet**, then show its address on the sheet.
- **Prefer checkout information from Apple Pay.** Assume it's complete and current; fetch the latest even if you have existing details.
- **Avoid requiring account creation before purchase.** Ask on the order confirmation page and prepopulate from checkout.
- **Report transaction results in the payment sheet**, including error messages for problems like a bad address.
- **Display an order confirmation page** thanking people, giving shipping details and how to check status. Listing Apple Pay isn't necessary; if you do, show it after the last four digits — "1234 (Apple Pay)" or "Paid with Apple Pay."

**Customizing the sheet**
- **Present and request only essential information.** A shipping address on an electronically delivered gift card raises privacy concerns and falsely implies physical delivery.
- **Display the active coupon or promotional code**, or let people enter one — reassurance that it applied.
- **Let people choose the shipping method in the sheet**: a clear description, a cost, and optionally an estimated delivery or pickup date or range, using the shipping method's calendar and time-zone support so it's accurate regardless of location (`PKDateComponentsRange`). For in-store pickup, consider offering a window of dates and times.
- **Use line items** for additional charges, discounts, pending costs, add-on donations, recurring payments, and future payments — a label and cost, plus a frequency for recurring payments. **Don't use line items to itemize the products** (`paymentSummaryItems`). **Keep line items short**, specific, and ideally on one line.
- **Provide a business name after the word Pay on the total line** — the same name people will see on their statement. `Pay [Business_Name]`.
- **If you're not the end merchant, identify both businesses**: `Pay [End_Merchant_Business_Name (via Your_Business_Name)]`.
- **Disclose when people may incur additional costs after authorization.** For a car ride priced by distance or a post-delivery tip, and where local regulations allow, explain clearly in the sheet and show a subtotal marked **Amount Pending**. If you're preauthorizing a specific amount, reflect that accurately.
- **Handle data entry and payment errors gracefully.**
- **Defer to the payment sheet for progress information.** It presents loading states and progress clearly; additional spinners confuse people about the transaction state.

**Website icon.** Websites supporting Apple Pay can supply an icon for payment authorization — most notably during Handoff, when someone authorizes on a connected device — and in Wallet for subscription flows. **60×60 pt** (120×120 px @2x, 180×180 px @3x).

**Handling problems.** Your app or website can respond when the sheet appears, when people change certain field values, and after authentication. **For privacy, you have limited access to data until people attempt to authorize** — before that, only the card type and a redacted shipping address. **Display errors when authorization fails**, but also validate available information and report problems *before* authorization where you can.
- **Avoid forcing compliance with your business logic.** Ignore irrelevant data and infer missing data — if you require a five-digit zip and someone enters Zip+4, ignore the extra digits. Accept phone numbers in multiple formats, with and without dashes and country codes.
- **Report problems accurately to the system** with a custom message and the correct status code (`PKPaymentError`, Apple Pay Status Codes) so the sheet shows the most relevant error.
- **Explain the problem clearly and succinctly.** Reference the field and say what's expected: "Zip code doesn't match city" beats "Address is invalid"; "Shipping not available for this state" explains an unserviceable address. Noun phrases, sentence case, no ending punctuation, **≤128 characters** to avoid truncation.
- **Handle interruptions correctly.** A cancellation or timeout dismisses the sheet — **you must cancel any in-progress payment.** People restart by choosing the button again.

**Subscriptions.** Apple Pay can authorize recurring payments — a fixed amount (a monthly movie ticket) or, where local regulations allow, a variable one (a weekly grocery order). The initial authorization can include discounts and fees.
- **Clarify subscription details before showing the sheet** — billing frequency and other terms. You can show the frequency on the sheet.
- **Include line items reiterating billing frequency, discounts, and upfront fees.** If no payment is due at authorization, clearly disclose when billing begins.
- **Communicate trial terms clearly** with line items: the trial amount (including $0), the regular amount after, and the date regular billing starts.
- **Clarify the current payment amount in the total line.**
- **Show the sheet only when a subscription change results in additional fees.** No authorization needed when the cost decreases or stays the same.
- **Treat the billing agreement field as a plain-language summary, not a substitute for formal terms.** Be concise, don't duplicate what's elsewhere, and **leave it blank when in doubt** to keep the sheet clean.

**Donations** (approved nonprofits). **Use a line item to identify the donation** — "Donation $50.00". **Offer predefined amounts** ($25, $50, $100) plus an **Other Amount** option.

**Buttons.** Always use the Apple-provided APIs (`PKPaymentButtonType`, `PKPaymentButtonStyle`, `WKInterfacePaymentButton`, the web equivalents) — approved captions, fonts, colors, and styles; proportional scaling at any size; automatic localization; corner radius customization; and built-in VoiceOver support. **Never create or replicate a custom Apple Pay button design.**

*Types* by terminology and flow: **Apple Pay** (generic; smaller minimum width, no call to action — also the automatic replacement when a chosen type isn't supported by the OS version) · **Buy** · **Pay** (bills and invoices) · **Check Out** · **Continue** · **Book** · **Donate** · **Subscribe** · **Reload** / **Add Money** / **Top Up** (adding money to a card, account, or system like transit or prepaid phone) · **Order** · **Rent** · **Support** / **Contribute** (giving to projects, causes, organizations) · **Tip**. In some contexts the system automatically shows an image of the default card on payment buttons.

*Set Up Apple Pay button*: when a device supports Apple Pay but it isn't set up, use this button to show acceptance and offer setup. Display it in Settings, a user profile, or an interstitial page.

*Styles*: **automatic** (system appearance decides) · **black** (white or light backgrounds with sufficient contrast; never black or dark) · **white with outline** (white or light backgrounds without sufficient contrast; never dark or saturated) · **white** (dark backgrounds with sufficient contrast).

*Size and position*: **display prominently** — no smaller than other payment buttons, and not below the fold. In a side-by-side layout, place the Apple Pay button **to the right** of an Add to Cart button; in a stacked layout, **above** it. Adjust the corner radius to match your other buttons (square, default, capsule). **Apple Pay button: minimum 100×30 pt.** **Book / Buy / Check Out / Donate / Set Up / Subscribe: minimum 140×30 pt.** Margins: **1/10 of the button's height**. If the size you specify can't fit the translated title, the system replaces it with the plain Apple Pay button (there's no automatic replacement for Set Up Apple Pay).

**Apple Pay mark.** Shows Apple Pay is available when you list payment options. **Not a button.** Use only the Apple-provided artwork with no alteration other than height, and make its height **equal to or larger than other payment brand marks**. Don't adjust width, corner radius, or aspect ratio; don't add a trademark symbol or other content; don't remove the border; no shadows, glows, or reflections; don't flip, rotate, or animate it. **Minimum clear space: 1/10 of its height**, and don't share a border with another graphic or button.

**Referring to Apple Pay.** Use it exactly as in the Apple Trademark List — **never plural or possessive**. Two words, uppercase A and P, lowercase otherwise; all uppercase only to conform to an established all-caps typographic style. **Never use the Apple logo to represent "Apple" in text.** In the US, use ® on the first appearance in body text, but not when Apple Pay appears as a checkout selection option. **Coordinate the font face and size with your app or website** — don't mimic Apple typography. **Never translate Apple Pay or any Apple trademark**, even within non-English text. In a payment selection context, a text-only description of Apple Pay is allowed **only when every payment option is text-only** — if any other option includes an icon or logo, you must use the Apple Pay mark. Not supported in tvOS.

---

## Augmented reality (iOS, iPadOS)

The device camera presents the physical world live while your app superimposes 3D virtual objects. **Offer AR features only on capable devices** — if AR is your app's primary purpose, restrict availability to ARKit-capable devices; if AR features are optional, **don't show an error on unsupported devices — just don't offer the feature.**

**Best practices**
- **Let people use the entire display.** Devote as much of the screen as possible to the physical world and your virtual objects; controls and information clutter dilute the immersion.
- **Strive for convincing illusions.** Detailed 3D assets with lifelike textures. Use ARKit information to scale objects properly, position them on detected surfaces, reflect environmental lighting and simulate camera grain, cast top-down diffuse shadows on real surfaces, and update visuals as the camera moves. **Update scenes 60 times per second** so objects don't jump or flicker.
- **Consider reflective surfaces carefully.** ARKit reflections are approximations based on what the camera captures — **prefer small or coarse reflective surfaces** that downplay the approximation.
- **Use audio and haptics** to confirm contact between a virtual object and a physical surface or another object. Background music helps envelop people.
- **Minimize text in the environment.**
- **Display additional information or controls in screen space** — content fixed to a consistent location, which stays stationary while the AR environment moves with the device, making it easy to find and view.
- **Consider indirect controls for persistent controls** — 2D controls in screen space. Place them so people don't have to adjust their grip, and consider translucency so they don't block the scene (Measure mixes translucent and opaque controls).
- **Anticipate a wide variety of real-world environments.** People may have little room or no large flat surfaces. Communicate requirements and expectations up front, and consider different feature sets for different environments.
- **Be mindful of comfort.** Holding a device at a fixed distance or angle for a long time is fatiguing. Place objects at a distance that reduces the need to move the device closer; in a game, keep levels short with downtime between.
- **Introduce motion gradually** if you encourage movement. Don't make people dodge a projectile the moment they enter.
- **Be mindful of safety.** Immersed people aren't aware of their surroundings, so rapid, sweeping, or expansive motions can be dangerous.

**Coaching.** Before an AR experience works, ARKit must evaluate the surroundings and detect surfaces. **Use the built-in coaching view** to show people what to do and give feedback during initialization, and again during **relocalization** after an interruption (`ARCoachingOverlayView`). **Hide unnecessary app UI while the coaching view is up** — it appears automatically by default, so be ready. If you need a custom coaching experience — for additional information or a different visual style — use the system view as your reference.

**Placing objects.** Use the coaching view to find a horizontal or vertical surface, then display a custom indicator when placement is possible, **aligned with the plane of the detected surface** so people understand how the object will sit. **Integrate the object immediately** on placement — surface detection refines accuracy progressively, so don't wait; respond instantly and subtly refine the position when detection completes (gently nudging an object back onto the surface if it landed beyond the bounds). **Consider guiding people toward offscreen objects** with visual or audible cues — an indicator along the screen edge. **Don't try to precisely align objects with the edges of detected surfaces** — boundaries are approximations that change as analysis continues. **Use plane classification** to inform placement: furniture only on a "floor" plane; a game board only on a "table."

**Object interaction.** **Prefer direct manipulation** — touching onscreen 3D objects is more immersive and intuitive than indirect controls (though indirect controls work better when people are moving around). **Use standard, familiar gestures** — single-finger drag to move, two-finger rotation to spin. **Keep interactions simple**: touch gestures are 2D and AR is 3D, so limit movement to the surface the object rests on and limit rotation to a single axis. **Respond to gestures within reasonable proximity** of small, thin, or distant objects — assume a nearby gesture targets that object. **Let people scale objects when it makes sense** — an imaginary environment yes; furniture shopping no, since scaling a chair defeats the purpose. **Never use scaling to adjust distance** — enlarging a distant object just makes a larger object that still looks far away. **Be wary of conflicting gestures** (two-finger pinch vs. two-finger rotation) and test that they're interpreted properly. **Keep movement consistent with your AR environment's physics** — people don't expect smooth movement over a rough surface, but they do expect objects to stay visible; keep moving objects attached to real surfaces and avoid jumping or vanishing during resize, rotate, and move. **Explore other interaction methods** — motion and proximity can bring content to life, like a character turning its head as someone walks toward it.

**Multiuser.** Each participant maps the environment independently and ARKit merges the maps. **Consider people occlusion** — letting people in the camera feed occlude virtual objects behind them enhances realism. **Let new participants join** an ongoing experience via implicit map merging, unless everyone must join before it begins (`isCollaborationEnabled`).

**Reacting to real-world objects.** Supply 2D reference images or 3D reference objects and ARKit tells you when and where it detects them — theater posters spawning spaceships, a museum sculpture triggering a virtual guide. **When a detected image first disappears, delay removing attached objects** — ARKit doesn't track changes to a detected image's position or orientation, so **wait up to one second** before fading them out. **Limit active reference images to 100 or fewer** for best detection performance; change the active set by context (a museum app using location services to look only for images in the current wing). **Limit the number of reference images requiring an accurate position** — position updates cost resources. Use a tracked image when the image may move, or when the attached animation or object is small relative to the image.

**Communicating.** **Use approachable terminology.** AR is an advanced concept — avoid ARKit, world detection, tracking, plane, features, and motion. Use friendly, conversational language:

| Do | Don't |
|---|---|
| Unable to find a surface. Try moving to the side or repositioning your phone. | Unable to find a plane. Adjust tracking. |
| Tap a location to place the [object]. | Tap a plane to anchor an object. |
| Try turning on more lights and moving around. | Insufficient features. |
| Try moving your phone more slowly. | Excessive motion detected. |

**In a 3D context, prefer 3D hints** — a 3D rotation indicator around an object beats text in a 2D overlay. Avoid textual overlay hints in 3D unless people aren't responding to contextual ones. **Make important text readable** — use screen space for critical labels, annotations, and instructions. If you must place text in 3D space, make it face people and use the same type size regardless of distance. **Provide a way to get more information** with a visual indicator that fits your experience.

**Interruptions.** ARKit can't track position and orientation during an interruption (a brief app switch, a phone call), so placed objects will appear in the wrong real-world positions afterward. **Support relocalization** so ARKit can restore them (`Managing Session Life Cycle and Tracking Quality`). **Consider the coaching view** to help people return the device to its previous position and orientation. **Consider hiding previously placed objects during relocalization** to avoid flickering. **Minimize interruptions** if your app supports both AR and non-AR experiences — embed the non-AR task inside the AR experience (changing upholstery without leaving AR). **Let people cancel relocalization** — if they don't return the device near its previous position, relocalization continues indefinitely; provide a reset button or another way to restart. **Indicate when the front-facing camera can't track a face for more than about half a second**, with a visual indicator and minimal text.

**Resolving problems.** **Let people reset the experience.** Don't force people to wait for conditions to improve or struggle with placement.

| Problem | Suggestion |
|---|---|
| Insufficient features detected | Try turning on more lights and moving around. |
| Excessive motion detected | Try moving your phone slower. |
| Surface detection takes too long | Try moving around, turning on more lights, and making sure your phone is pointed at a sufficiently textured surface. |

**Icons and badges.** The **AR glyph** launches ARKit-based experiences only. **Never alter it** (other than size and color), use it for other purposes, or use it with non-ARKit AR. **Minimum clear space: 10% of its height.** **AR badges** (collapsed and expanded forms) identify items viewable in AR. **Use them as intended and don't alter them.** **Prefer the AR badge to the glyph-only badge**, reserving the glyph-only form for constrained spaces. **Use badging only when your app contains a mixture** of AR-viewable and non-viewable objects — if everything is viewable, badging is redundant. **Keep placement consistent** — the same corner of every object's photo, large enough to see clearly but not so large it occludes detail. **Minimum clear space: 10% of the badge's height.**

**visionOS.** With permission, ARKit detects surfaces, provides hand and finger positions for custom gestures, and supports interactions incorporating nearby physical objects. Not supported in macOS, tvOS, or watchOS.

---

## SharePlay

Lets multiple people share activities — watching a movie, listening to music, playing a game, sketching on a whiteboard — during a FaceTime call or Messages conversation, with synchronized playback across devices. In visionOS, people share these experiences in the same virtual space.

When someone shares content during a call, the system asks each participant to launch the app; people without it are encouraged to download it. Making platform versions available as a **Universal Purchase** means one purchase covers your app and its in-app purchases everywhere.

- **Let people know you support SharePlay** — the `shareplay` SF Symbol identifies shareable content.
- **Help nonsubscribers join** if part of your app requires a subscription — temporary or provisional access, or a one-time pass an existing subscriber can send. **Support Family Sharing** so family members can share your content. If people can subscribe during a SharePlay experience, present a **streamlined** sign-up so others aren't waiting.
- **Support Picture in Picture** where possible. On iPhone and iPad, people can open a shared video in a PiP window; on Mac it opens in a background window.
- **Use the term correctly.** SharePlay is a noun ("Join SharePlay") and can be a verb for a direct action ("SharePlay Movie"). **Don't use an adjective with it** — no "virtual" or "spatial" in visionOS. **Don't modify it** — no SharePlayed, SharePlays, SharePlaying.

**Activities.** An activity is an app-defined shareable experience; a video app might define separate activities for movies, TV shows, and uploaded videos. **Briefly describe each activity** — a movie-viewing activity might show the title, plot summary, and poster. Write something simple, meaningful, and short enough to avoid truncation. **Make it easy to start sharing** — if no session is available when someone starts a shareable activity, present UI to start a group activity, and the system asks whether to share or continue solo. **Help people prepare before displaying the activity** — logging in, downloading content, or paying should happen in views shown *before* the activity UI, made as effortless as possible. **Defer app tasks that might delay a shared activity** — ask for a participant's profile when playback pauses or finishes.

**visionOS.** People expect most visionOS apps to support SharePlay, choosing the **Spatial** option in FaceTime. FaceTime shows other participants as **spatial Personas** within each wearer's space, so people can speak and gesture directly to each other and tell when someone is paying attention. **Shared context** describes the characteristics that make people feel physically present together over the same content — it gives people confidence they're experiencing the same thing, which enables authentic social dynamics like making plans, taking turns, and sharing resources.

> The system preserves privacy by obscuring some visual details about wearers, and people can adjust their spatial Persona. Personas can be placed shoulder to shoulder and support shared gestures like a handshake or high five, but remain apart.

**Spatial Persona templates**: **side-by-side** places participants along a curved segment facing the content — the best view for everyone, ideal for watching media together, but encourages less nonverbal interaction since people don't face each other. **Surround** arranges participants all the way around centered content — excellent for 3D content, since each person sees a different angle, and it promotes both verbal and nonverbal interaction as if grouped around a table. **Conversational** groups participants around a center point with the content along the circle — not everyone has the same view or convenient access, so use it when the experience is about being together while the app performs a background task like playing music. (`SystemCoordinator`, `SpatialTemplatePreference`)

- **Be prepared to launch directly into the shared activity.** The system launches your app automatically for everyone. **Avoid displaying windows unrelated to the activity** — if people must sign in first, present it in an autodismissible window that disappears on completion.
- **Help people enter a shared activity together, but don't force them.** When one participant changes immersion level, the system tells you so you can synchronize. **Check whether the change would disrupt their current task** — if someone is editing in an unshared window, present an alert letting them choose.
- **Smoothly update when new participants join.** Integrate them without disrupting the experience, keep shared immersive content synchronized, and accommodate up to five participants, updating positions as needed.

**Maintaining shared context.** In a Full Space the system arranges your content and all participants in a single coordinate system, synchronizing size, position, and orientation for everyone. You're responsible for displaying objects, playing sounds, and supporting interactions that enhance the sense of sharing.
- **Make sure everyone views the same state.** Different participants seeing different states (minimal vs. theater viewing modes) diminishes the sense of being together.
- **Use Spatial Audio** to strengthen the realism.
- **Let people discover natural, social solutions to confusion or conflict.** If only one person can use a virtual tool at a time, avoid tool-use controls and notifications and let people speak or gesture to the group. For conflicts like simultaneous edits, consider a simple rule — last change wins — and let people define acceptable behavior around it.
- **Keep private and shared content separate.** The system differentiates shared and unshared windows by default (a shared Music window appears as a new window for everyone while individual library windows stay private). If your app opens multiple windows, help people share the right one, make shared vs. unshared obvious, and where possible let people drag content from a private window to a shared one.

**Adjusting shared context.** Sometimes each participant needs their own version, for comfort, accessibility, or viewing angle. **Let people personalize without changing the experience for others** — volume, subtitles. **Consider giving each participant a unique view** when content has one ideal perspective: a Spatial Capture shared in a standard window shows other Personas around it, but perceiving its depth requires the right angle, so a person could temporarily transition to a Full Space that hides other participants while everyone else continues in the standard window. Keep synchronizing positions and app context so the shared experience holds. **Make it easy to exit and rejoin.** People need to perform unrelated tasks or engage with their surroundings; present a control to rejoin quickly, and consider continuing to display the shared content so people stay informed while their Persona is hidden. Not supported in watchOS.

---

## App Clips (iOS, iPadOS)

A lightweight version of your app providing an on-the-go or demo experience that's instantly available, without downloading the full app. It stays on the device for a limited time and preserves privacy.

People launch an App Clip by scanning an **App Clip Code**, NFC tag, or QR code at a physical location; or from location-based Siri Suggestions, the Maps app, Smart App Banners, App Clip cards in Safari, and shared Messages links. Since iOS 17, an app can include links and App Clip previews that launch another app's App Clip.

**Good uses.** In-the-moment tasks over a finite time: renting a bike from an App Clip Code on the bike · advance coffee orders from a Smart App Banner or a shared link · a food truck's seasonal dish from a poster · paying for a meal from Maps, Siri Suggestions, or a table-side code · a museum's AR content or audio commentary from labels beside works. Also **demos**: a game's tutorial and first level · a fitness app's free workout and guided meditation · a text editor letting people create and save a document.

**Designing**
- **Let people complete a task or a demo.** Don't require installing the full app to finish a task, a level, or the demo.
- **Focus on essential features.** Reserve advanced or complex features for the app; for a demo, focus on what conveys the app's or game's character.
- **Don't use App Clips solely for marketing.** They must provide real value. **No ads.**
- **Avoid web views.** App Clips use native components for an app-quality experience. If only web components are available, offer a link to your website instead.
- **Design a linear, focused interface.** No tab bars, no complex navigation, no settings. Minimal screens and entry forms.
- **On launch, show the most relevant part** for the person's context. Skip unnecessary steps.
- **Ensure immediate usability.** Include all required assets, omit splash screens, never make people wait on launch.
- **Keep it small.** Smaller launches faster, especially on limited bandwidth. Reduce unnecessary code, remove unused assets, and **avoid downloading additional data**, which destroys the sense of immediacy.
- **Make it shareable.** People can launch a shared App Clip from within Messages. Offer links to specific points and encourage sharing.
- **Make paying easy** — Apple Pay gives express checkout and shipping information with no typing.
- **Avoid requiring an account.** Consider not requiring one, or asking after the task completes. If value depends on an account, minimize what people must provide — Sign in with Apple.
- **Provide a familiar, focused experience in your app.** Installing the full app replaces the App Clip, and future invocations launch the app instead. Don't require additional steps — **don't make people log in again.**

**Privacy.** App Clips can't perform background operations. **Limit stored data** and store anything you must securely. **Don't rely on data you previously stored on the device** — the system may have removed the App Clip and its data between launches. Store login information off-device securely. **Consider Sign in with Apple** and **Apple Pay**.

**Showcasing your app.** People don't manage App Clips, they don't appear on the Home Screen, and the system removes one after a period of inactivity. The system helps people find the full app: on the **App Clip card**, people can launch the clip or visit the App Store page; on first launch, an app banner at the top of the screen offers the same; and you can display an overlay allowing download from within the clip.
- **Don't compromise the experience by asking people to install.** For an on-the-go clip, consider whether the card and banner are enough. For a demo, let people finish it first.
- **Pick the right time** — a completed task or a natural pause, via `SKOverlay`.
- **Recommend nonintrusively and politely.** Never repeatedly, never mid-task, never by push notification. Clearly communicate the app's additional features.

**Notifications.** App Clips can schedule and receive notifications for **up to 8 hours** after launch. **Only request extended permission if you really need it** — a car rental clip reminding people to return a car spans more than a day. **Keep notifications focused** — no purely promotional notifications, and only in response to an explicit action. If someone completes their task without leaving the clip, you may need none at all. **Use notifications to help people complete a task** — a scheduled food delivery.

**App Clips for businesses.** As a platform provider you can create several App Clip experiences in App Store Connect powered by a single App Clip, appearing with each business's branding. **Use consistent branding** — the business's brand is front and center on the card, so tone down yours. **Consider multiple businesses or locations** — people may use it for more than one, so handle that case, update the UI accordingly, offer a way to switch between recent businesses or locations, and verify location on launch.

**App Clip card.** People's first interaction. **Be informative** — the image should communicate the features, tasks, or content. **Prefer photography and graphics** to a UI screenshot, which rarely communicates the purpose; a photo of the business or point of interest also works. **Avoid text** — it isn't localizable, is hard to read, and looks worse. **1800×1200 px PNG or JPEG without transparency.** **Concise copy**: title ≤30 characters, subtitle ≤56 characters. **Pick the action verb**: **View** for media or informational/educational content, **Play** for games, **Open** for everything else.

**App Clip Codes.** The best discovery mechanism — immediately recognizable, fast, and secure. Two variants: **scan-only** (a camera icon at the center; scan with the Camera app or Control Center's Code Scanner) and **NFC-integrated** (an iPhone icon; hold the device close, or scan with the NFC Tag Reader, Camera app, or Code Scanner). Choose the design **with** the App Clip logo where space allows, or **without** it when space is constrained.

*Which variant.* **NFC-integrated** where people can physically reach the code: a restaurant tabletop, near a register, a storefront window, signage, a gift card or coupon. **Scan-only** where it's physically inaccessible or displayed digitally: posters and printed advertising, signage behind a counter, digital displays, emails, social media images.

*Displaying.* **Include the App Clip logo when space allows** — it clarifies that the code launches an App Clip. Use the version **without** it if you can't meet the clear space requirements, or if the code goes on disposable paper or plastic items, or items associated with gambling or drinking (playing cards, poker chips, bar coasters). **Never use the App Clip logo on its own.** **Flat or cylindrical surfaces only** — on a cylinder, the code's width must not exceed **one-sixth of the circumference**. **Keep it as flat as possible** — avoid paper, plastic, and fabric that fold or crumple; on a bag or flexible box, attach it to something rigid; make stickers that adhere well to flat surfaces. **Place it where scanning is reliable** — enough light for scan-only codes, no wide required angle. **Unobstructed** — no overlaid text, logos, or images; never animated or dimmed. **Upright** — don't rotate the code or angle the center glyph.

*Sizes.* Printed: **minimum diameter 3/4 inch (1.9 cm)**. Digital: **minimum 256×256 px**, PNG or SVG. NFC-integrated: the embedded tag must be **at least 35 mm in diameter or equivalent** — with a 35 mm tag, the printed code must be at least **1.37 inches (3.48 cm)** in diameter. **Distance-to-size ratio no more than 20:1**, ideally **10:1** — a code scanned from 40 inches (101 cm) away needs to be at least 4 inches (10.16 cm) in diameter. If displayed near a QR code or other scannable item, make the App Clip Code **at least** that item's size. **Minimum clear space equals the space between the center glyph and the circular code**; leave enough between adjacent codes for reliable scanning of each.

*Messaging.* Add a clear call to action, especially with the logo-less design. Scan-only: "Scan to [what people can do]" or "Scan using the camera on your iPhone or iPad to […]". NFC-integrated: "Scan to […]" or "Hold your iPhone near the [object] to launch an App Clip that […]".

*Customizing.* Generate codes with App Store Connect or the App Clip Code Generator command-line tool. **Always use the generated code.** Never design your own or modify a generated one — no filters, augmented colors, glows, shadows, gradients, or reflections. When scaling, **don't change the aspect ratio**, and scale **all** attributes including stroke widths. **Choose colors with enough contrast**: each code uses a foreground color, a background color, and a third generated from them. Both tools offer default pairs and custom colors — and refuse to generate a code whose colors would scan poorly, with suggestions for a better foreground color.

*Printing.* **Always test printed codes** from a variety of angles before distribution. **High-quality, non-textured materials**: matte finishes; avoid shine, gloss, reflective or holographic overlays, and thin laminates (use a matte laminate if you must laminate). Outdoors, use UV-resistant materials or coatings. **Flexographic printing** with a professional service; **inkjet** for desktop printing. **High resolution**: rasterize the SVG at **≥600 ppi**, print at **≥300 dpi**. Level and calibrate the printer; avoid poor color channel alignment, inaccurate gamma, artifacts, and elliptical or distorted codes. On receipt printers, print as close to the paper's maximum bounds as possible. **Correct color conversion**: codes generate as SVG in sRGB — convert to CMYK using a **relative colorimetric (media-relative)** intent, with the Generic CMYK ICC profile on CMYK printers or Gracol 2013 on CMYKOV printers, allowing a color tolerance of **CIELab Delta E of 2.5**. **Grayscale printers must use grayscale-generated codes** — color codes printed in grayscale scan less reliably. NFC-integrated codes need **Type 5 NFC tags**, at least 35 mm in diameter or equivalent. For large batches, test the printing workflow with small print runs and templates with padded regions displaying the encoded invocation URL and SVG filename alongside each code for validation. Apple provides **printer calibration test sheets** — one showing text boxes for each default color pair, one showing two grayscale bars (if specific grays are light or missing, the printer needs calibration or isn't suitable).

*Legal.* Only Apple-provided codes created in App Store Connect or with the generator tool, following these guidelines, are approved. Apple may update the design at its discretion. **Stop displaying a code when its App Clip is no longer active.** You may not use App Clip Codes (including the Apple Logo, the App Clip mark, and the code designs) as part of your company or product name, and may not seek copyright or trademark registration for them or their elements. They must not be used in a way likely to reduce, diminish, or damage the goodwill, value, or reputation associated with Apple or App Clips; that infringes third-party rights; or that causes confusion as to the source of products or services. **Don't add a symbol** to generated codes. **Don't translate any Apple trademark.** Not supported in macOS, tvOS, visionOS, or watchOS.

---

## CarPlay

Shows compatible iPhone apps on the car's built-in display with simplified, driving-optimized interfaces. **CarPlay is designed for drivers to use while driving** — provide features that let people perform tasks quickly with minimal interaction. You build the interface from **system-defined templates** by type (audio, communication, navigation, fueling); iOS renders your content, so you don't adjust for resolutions or handle touchscreens, knobs, or touch pads.

**iPhone interactions**
- **Eliminate app interactions on iPhone when CarPlay is active.** All interaction happens through the car's controls and display. If your app requires setup on iPhone, make sure it happens before the vehicle moves.
- **Never lock people out of CarPlay because the connected iPhone requires input.** The app must work when the iPhone is inaccessible — in a bag, in the trunk. Problems requiring the iPhone must wait until the vehicle stops.
- **Work without requiring people to unlock iPhone.** Most people use CarPlay with a locked phone.

**Audio.** Your app coexists with the car's radio and navigation prompts.
- **Let people choose when to start playback.** Avoid starting automatically unless your app's purpose is a single audio source, or you're resuming interrupted audio. **Don't start an audio session until you're ready to play** — starting one silences other sources like the car radio.
- **Start playback as soon as audio has sufficiently loaded.** The system keeps the selection highlighted with a spinner until you signal readiness.
- **Display the Now Playing screen when audio is ready.** Don't delay playback for descriptive information — load it in the background and show it when available.
- **Resume after an interruption only when appropriate** — resume after a temporary interruption like a phone call, if audio was actively playing; a permanent interruption like a Siri-initiated playlist is nonresumable.
- **Adjust relative levels automatically when necessary, but never the overall volume.**

**Layout.** CarPlay supports many resolutions, pixel densities, and aspect ratios; the system scales app icons and interfaces so they appear at roughly the same size. Common sizes: 800×480 (5:3) · 960×540 (16:9) · 1280×720 (16:9) · 1920×720 (8:3).
- **Provide useful, high-value information in a clean layout scannable from the driver's seat.** No clutter, no unnecessary visual embellishment.
- **Maintain a consistent appearance** — elements with similar functions look similar.
- **Make primary content stand out and feel actionable.** Large items read as more important and are easier to tap. **Put the most important content and controls in the upper half.**

**Color.** **Prefer a limited palette coordinating with your app logo.** **Never use the same color for interactive and noninteractive elements** — people can't tell where to tap. **Test under a variety of lighting conditions in an actual car** — time of day, weather, window tinting all change what you see. Consider how brightness affects night driving and how low-contrast colors wash out in direct sunlight. **Look great in both dark and light environments** — CarPlay supports both and may switch automatically based on lighting. **Choose colors that communicate effectively with everyone.**

**Icons and images.** CarPlay supports landscape and portrait displays at **@2x and @3x**. **Supply both scale factors for all CarPlay artwork.** **Mirror your iPhone app icon** — a well-designed icon works in both places. **Don't use black for the icon's background** — lighten it or add a border so it doesn't blend into the display. App icon sizes: **120×120 px @2x, 180×180 px @3x**.

**Errors.** **Report errors in CarPlay, not on the connected iPhone.** Never direct people to pick up their iPhone to read or resolve an error. Not supported in iPadOS, macOS, tvOS, visionOS, or watchOS.

---

## Maps

A map displays outdoor or indoor geographical data, supporting zooming, panning, rotation, annotations, overlays, and routing, in a standard, satellite, or hybrid view.

- **Make your map interactive.** People expect to zoom, pan, and interact in familiar ways; noninteractive elements obscuring the map interfere with those expectations.
- **Pick an emphasis style**: **default** (fully saturated — good for most standard applications without many custom elements, and for visual alignment with the Maps app when people switch between them) or **muted** (desaturated — good when information-rich custom content should stand out).
- **Help people find places** — a search feature combined with category filters (a shopping mall map filtering by clothing, housewares, electronics, jewelry, toys).
- **Clearly identify selected elements** with distinct styling — an outline and color variation.
- **Cluster overlapping points of interest.** A single pin represents several nearby points, expanding progressively as people zoom in.
- **Keep the Apple logo and legal link visible.** Temporarily covering them is fine; permanently covering them isn't. Use adequate padding (about **7 pt** on the sides, **10 pt** above and below). **Avoid moving them with your interface** — they should appear fixed to the map. If a custom element can move relative to the map, place them based on its **lowest** position — for a pull-up card, **10 pt above its lowest resting position**. (The logo and link don't appear on maps smaller than 200×100 px.)

**Custom information.** **Use annotations matching your app's visual style** — the default marker is red-tinted with a white pin icon; you can change the tint and replace the icon with a string or image. An icon string can contain any characters including Unicode, but **keep it to two or three characters** for readability. **Consider making standard map features independently selectable** — the system treats Apple-provided features (points of interest, territories, physical features) separately from your annotations, so you can configure custom appearances and information for them (`MKMapFeatureOptions`). **Use overlays** to define areas related to your content: **above roads** (the default — above roads but below buildings, trees, and other features, giving a sense of what's beneath while clearly marking a defined space) or **above labels** (above roads and labels, hiding everything beneath — for content fully abstracted from the map, or to hide irrelevant areas). **Ensure enough contrast between custom controls and the map** — a thin stroke, a light drop shadow, or blend modes on the map area.

**Place cards** display rich place information — hours, phone numbers, addresses — in your app or website, adding depth to search results.

*In a map.* Present a place card when someone selects a place (a map of an author's book-signing bookstores), or for points of interest, territories, and physical features to give context about nearby places. **Styles**: **automatic** (the system decides based on your map view's size) · **callout** (a popover beside the selected place — **full callout** shows a large, detailed card; **compact callout** shows a space-saving concise one; **automatic callout** decides by view size) · **caption** (an "Open in Apple Maps" link) · **sheet**. The full callout appears as a popover in iPadOS and macOS and as a sheet in iOS.
- **Consider your map presentation when choosing a style.** The full callout is the richest, but a small map with many annotations may be better served by the compact callout, which shows place information while keeping the other places in view.
- **Look great on different devices and window sizes.** For full callouts you can set a minimum width to prevent text overflow on small devices.
- **Avoid duplicating information** your app already shows — if the full callout would repeat it, a compact callout or caption may complement better.
- **Keep the location visible** when displaying a place card, so people keep their sense of where it is. Set an offset and point the card at the location (`offset(_:)`, `accessoryOffset`, `selectionAccessoryOffset`).

*Outside a map.* You can display place information in a list — search results, a store locator — and present a place card on selection. **If the card isn't displayed within a map view, you must include a map in the card** (`mapItemDetailSheet(item:displaysMap:)`). **Use location-related cues in surrounding content** so people understand a card is available — place names and addresses beside a details button, or a map pin icon with a place name for a space-efficient design.

**Indoor maps** (shopping malls, stadiums) can include overlays highlighting rooms, kiosks, and other locations, plus text labels, icons, and routes. **Adjust detail by zoom level** — show large areas like rooms and buildings at all levels, and progressively add features and labels as people zoom in (an airport shows terminals and gates zoomed out, individual stores and restrooms zoomed in). **Use distinctive styling** — color plus icons to distinguish types of areas, stores, and services. **Offer a floor picker** for multi-level venues, keeping the entries concise — a list of floor *numbers* is usually enough.

---

## Wallet

Securely stores credit and debit cards, driver's licenses and state IDs, transit cards, event tickets, keys, and more on iPhone and Apple Watch, for Apple Pay purchases, order tracking, identity confirmation, boarding, and discounts.

**Passes.** Digital representations people add to Wallet — event tickets, boarding passes, reward cards, coupons.
- **Offer to add new passes.** When an action produces a pass, present system UI to add it in one tap. For frequent, predictable actions like flight check-in, you can add passes in the background after a one-time authorization; Wallet notifies people each time. If someone wants to review first, show a custom view with an Add to Apple Wallet button.
- **Help people add a pass created outside your app** — suggest adding it the next time they open your app. **If they decline, don't ask again.**
- **Add related passes as a group** — all boarding passes for a multi-connection flight at once; a bundled set of event tickets from your website.
- **Display an Add to Apple Wallet button** wherever corresponding pass information appears, in case someone declined or removed the pass. (An Add to Apple Wallet badge exists for emails and webpages.)
- **Let people jump from your app to the pass in Wallet** — a link labeled something like "View in Wallet."
- **Tell the system when passes expire.** Wallet hides expired passes and offers a button to revisit them — set the expiration date, relevant date, and voided properties correctly.
- **Always get permission before deleting passes.** An in-app setting for manual vs. automatic removal, or an alert before deleting.
- **Help the system suggest a pass when relevant.** Supply information about when and where a pass is relevant, and the system can show a Lock Screen link at the right moment (a gym membership card as people enter the gym), or start a Live Activity for certain types like event tickets.
- **Keep passes up to date** — a boarding pass reflecting delays and gate changes.
- **Use change messages only for time-critical updates.** A gate change, yes. A customer service phone number change, no. **Never for marketing.**

**Anatomy.** Content and structure come from **pass fields** (what appears and how it's arranged) and **semantic tags** (describing content to the system, enabling relevance-based surfacing and **featured actions** — quick links to venue directions or event guides). Poster event and semantic boarding passes **require** semantic tags and get automatic layout — include pass fields alongside them so the passes display correctly on older iOS versions.

*Field types*: **logo and logo text** (brand icon and name — visible when the pass is collapsed) · **header** (critical information — also visible when collapsed) · **primary** (the most important information) · **secondary and auxiliary** (useful but less critical) · **footer** (supplemental, like pass category — "Family", "Annual") · **back** (details people rarely need, shown in pass details).

**Designing.** Wallet uses a consistent visual style to build familiarity and trust. **Don't merely replicate the physical counterpart** — design a clean, simple pass that feels at home in Wallet. Use **Pass Designer** to design and preview.
- **Work well on all devices.** A pass on Apple Watch shows less information and fewer images. **Don't put essential information in elements that might be unavailable**, and **avoid padding in images** — watchOS crops white space from some of them.
- **Keep the front uncluttered.** Essential information (event date, account balance) in the header so it's visible when collapsed; the rest of the front for what people need quick access to; everything else on the additional information sheet.
- **Make it instantly identifiable** with brand colors and visual elements.
- **Ensure sufficient contrast** between background and text, against both solid backgrounds and background images.
- **Use language that works on any device.** "Slide to view" means nothing on Apple Watch.

**Styles.** **Boarding passes** — airline, train, bus, boat, generic transit; typically one trip with a start and end. Use semantic tags for airline boarding passes, pass fields for other transit. **Coupons** — coupons, special offers, discounts. **Event tickets** — sporting events, concerts, movies, plays; typically one event, but a season ticket can cover many. A poster event ticket supports a full-art background; non-poster event tickets use standard fields with a background image and thumbnail. **Store cards** — loyalty, discount, points, and gift cards, usually showing a balance. **Poster generic passes** — a full background image and a distinct field layout; flexible and not tied to a category. **Generic passes** — anything else (a gym membership, a coat-check ticket).

**Images.** PNG at **@2x and @3x**. **Reserve images for visual content** — embedded text isn't accessible and may not appear on all devices; use text fields and semantic tags instead, and add barcodes with Pass Designer or the APIs rather than embedding them. **Keep file sizes small** — passes arrive by email and webpage. **Provide a pass icon** (your app icon or a separate design) for the Lock Screen, Mail, and Wallet.

| Image | Styles | Filename | Size |
|---|---|---|---|
| **Logo** (top leading corner; typically a horizontal text logo, optionally with a graphic) | Non-semantic airline boarding passes, non-airline boarding passes, coupons, non-poster event tickets, generic passes, store cards | `logo.png` | 50–160 pt wide × **50 pt** tall. **Avoid inner drop shadows** — they reduce legibility. |
| **Primary logo** (top leading corner, semantic passes only) | Airline boarding passes, poster event tickets, poster generic passes | `primaryLogo.png` | 30–126 pt wide × **30 pt** tall |
| **Secondary logo** (bottom trailing corner; ticket issuer or event organizer) | Poster event ticket | `secondaryLogo.png` | 12–135 pt wide × **12 pt** tall |
| **Icon** (square; Lock Screen, Mail, Wallet — the system rounds the corners) | All | `icon.png` | **38×38 pt** |
| **Strip image** (reinforces brand or offer) | Coupon, store card | `strip.png` | **375×144 pt**. Text appears over it — ensure contrast, keep areas behind text uncluttered, put important visual elements toward the bottom or trailing edge, **don't embed text**. |
| **Thumbnail** (square; a movie poster) | Event ticket, generic pass | `thumbnail.png` | 60–90 pt wide × **90 pt** tall. Round the corners in your artwork and export a transparent PNG. |
| **Background** (non-poster; appears blurred behind content) | Event tickets | `background.png` | **343×503 pt** |
| **Background** (poster; unblurred) | Poster event tickets, poster generic passes | `artwork.png` | **358×448 pt**. **Position content within the safe area** — a material strip covers the bottom edge, and a barcode needs accounting for. Preview in Pass Designer. |
| **Footer** | Airline boarding passes | `footer.png` | **268×15 pt** |

**Order tracking.** Wallet can display an order placed through your app or website, updating as the status changes. Since iOS 17 you can start tracking from your app or website. Wallet presents a dashboard of active and completed orders; choosing one shows items and fulfillment information for shipping and pickup. The **Wallet Orders schema** defines properties for product descriptions, order status, contact information, and shipping and pickup details including estimated arrival dates, addresses, tracking numbers, and pickup instructions — Wallet displays them in consistent, system-defined interfaces. **Supply as much information as you can.**
- **Make it easy to add an order.** After an Apple Pay transaction, use `PKPaymentOrderDetails` (app) or `ApplePayPaymentOrderDetails` (web) to add it automatically. Since iOS 17 you can display the system **Track with Apple Wallet** button (`AddOrderToWalletButton`) on order confirmation, status, and tracking pages, or in emails. Adding an already-added order opens Wallet and displays it.
- **Make order information available immediately.** People need confirmation even while payment, processing, and fulfillment are pending — supply what you have and a status like "Check back later for full order details."
- **Provide fulfillment information as soon as it's available and keep it current.** The system updates the order and can notify customers, mapping your reported status to Order Placed, Processing, Ready for Pickup, Picked Up, Out for Delivery, Delivered, Issue, or Canceled.
- **Supply a high-resolution logo image with a nontransparent background** — PNG or JPEG, **300×300 px** — shown in the dashboard and detail view.
- **Supply distinct, high-resolution product images with nontransparent backgrounds** — straightforward depictions on a solid background (a lifestyle context or busy background makes items hard to distinguish at small sizes). PNG or JPEG, **300×300 px** each.
- **Keep text brief** — the system truncates. **Use clear, approachable, localized language**, and make sure the price matches what the customer confirmed.

*Details.* **Provide a link to where people manage their order** — a universal link works even without your app installed. **Clearly describe each item** with `LineItem` (price, name, image); an order lists every item, a fulfillment lists only its own. You can attach a PDF receipt to an individual transaction. **Supply a prioritized list of your apps** so the system can link to the right one (the highest installed app on your list, or the first if none are installed). **Avoid duplicate notifications** — tell the system to skip order notifications when the customer has one of your apps. **Make it easy to contact the merchant** with multiple methods: at minimum a website or landing page link, optionally a Messages for Business link, a phone number, an email address, and a support page link. **Help people track the order** — a multi-item order can have multiple fulfillments, each shipping or pickup. Beyond an ETA, people appreciate: a **direct link to the carrier's page** (in addition to a tracking number), displayed on any intermediate tracking page you open; a **scannable barcode** when one is needed for pickup, so people can present it from Wallet instead of hunting through email; and **clear, detailed instructions**. **Keep the fulfillment screen centered on order tracking** — prioritize it over app or service recommendations. **Choose shipping values matching what you know**: enter the carrier's name if you know it, otherwise leave the default "Track Shipment"; use specific statuses (`onTheWay`, `outForDelivery`, `delivered`) when you have interim details, and `shipped` when you don't — providing a tracking link either way. **Keep customers informed with relevant status descriptions** — approachable, accurate, clearly related to the status, and an opportunity for your brand's voice. **Be direct and thorough about an Issue or Canceled status** — people need to know why and what they can do.

**Identity verification.** On iOS 16+ people can store an ID card in Wallet and let an app or App Clip access information to verify their identity without leaving their context — confirming identity while applying for a credit card in a banking app.

> Apple doesn't create or see the ID documents people add to Wallet, and when people agree to share, you receive only encrypted data that isn't readable on the device.

Apple provides a **Verify with Wallet** button that reveals a sheet describing your request, letting people agree or cancel.
- **Present the option only when the device supports it.** If the device can't return the information, don't show the button, and be ready with a fallback verification method (`VerifyIdentityWithWalletButton`).
- **Ask only at the precise moment you need it.** Wait until people are completing the process or transaction that requires it — never before they're ready to start, and never at account creation.
- **Clearly and succinctly describe why.** The purpose string appears in the verification sheet. "Federal law requires this information to verify your identity and also to help [App Name] prevent fraud." "Applicable state law requires [App Name] to verify your driving privileges." A brief, complete sentence: direct, specific, easy to understand, sentence case, active voice, ending period.
- **Ask only for the data you need.** To check a minimum age, use an age threshold request (`age(atLeast:)`) rather than requesting the current age or birth date.
- **Clearly indicate whether you will keep the data and for how long.** Specify a duration through the PassKit APIs — a particular period, indefinitely, or only as long as the verification takes — and the system displays explanatory content in the sheet (`PKIdentityIntentToStore`).
- **Choose the matching button label**: verify **age** to complete a transaction after an age check (making a car available to lease) · verify **identity** to complete one after an identity check (a car rental) · **continue** when Verify with Wallet is one part of a process also requiring information it doesn't provide (a Social Security number or phone number for a financial account or background check) · a **generic** label when the flow completes without additional steps but the others don't fit (signing up for a government service). Multiline variants exist for constrained horizontal space (`PKIdentityButton.Label`). The button always uses **white letters on a black background**; a light-outline style exists for dark backgrounds, and you can adjust the corner radius to match related buttons (`PKIdentityButton.Style.blackOutline`).

**watchOS.** Wallet displays passes in a scrolling carousel of cards. **People can add your pass to Apple Watch even without a watch-specific app**, so understand how it will look. Tapping a pass reveals a scrollable details screen; in some cases people can tap a transaction for more. Each style defines the fields and images that fit the basic layout areas; anything that doesn't fit appears in the details screen. **In every style, watchOS crops the strip image to the card's aspect ratio and may crop white space from other images.** Not supported in tvOS.

---

## HealthKit (iOS, iPadOS, watchOS)

The central repository for health and fitness data. **If your app doesn't provide health and fitness functionality, don't request access to private health data.** A nutrition app might read weight and activity data to set calorie goals and make recommendations, and write logged calories back so HealthKit can include them in global progress metrics.

**Privacy**
- **Provide a coherent privacy policy.** You must supply a URL during app submission so people can view it from your App Store page.
- **Request access only when you need it** — when people log their weight, not at launch. A contextual request helps people understand your intentions. People can change permissions, so **request every time you need access** (`requestAuthorization(toShare:read:completion:)`).
- **Clarify your intent with descriptive messages on the standard permission screen.** A few succinct sentences explaining why you need the information and how people benefit. **Don't add custom screens replicating the standard screen's behavior or content.**
- **Manage health data sharing solely through the system's privacy settings.** People expect to manage access globally in Settings > Privacy. **Don't build additional screens affecting the flow of health data.**

**Activity rings.** See COMPONENTS.md for the full rules. In summary: **Move, Exercise, and Stand only** · never replicate or modify them for other purposes · never show that progress in another ring-like element · **for a single person**, obviously identified · **never for ornamentation or branding** · maintain ring and background colors exactly (no filters, no color changes, no opacity changes) · maintain a minimum outer margin no smaller than the distance between rings · differentiate other ring-like elements · **provide app-specific information only in Activity notifications** — the system already sends Move, Exercise, and Stand updates, and you must never show an Activity ring element in your notifications.

**The Apple Health icon** shows that an app works with HealthKit and the Health app. **Use only the Apple-provided icon** from Apple Design Resources. **Display the name Apple Health close to it.** **Display it consistently with other health-related app icons**, no smaller than they are. **Never use it as a button** — it indicates compatibility only. **Don't alter it**: no masking to change the corner radius or make it circular, no borders, color overlays, gradients, shadows, or other effects. **Minimum clear space: 1/10 of its height**, never composited onto another graphic. **Don't use it within text or as a replacement for the words** Health, Apple Health, or HealthKit. **Don't display Health app images or screenshots** — they're copyrighted.

**Editorial.** Refer to the Health app as **Apple Health** or **the Apple Health app**. **Don't use the term HealthKit** in user-facing text — it names the developer framework; say your app "works with the Apple Health app" or "uses data from the Apple Health app." Apple Health is two words, uppercase A and H, lowercase otherwise; all uppercase only to conform to an all-caps interface style. **Use the system-provided translation of Health** so people see the same word they see on their device. Not supported in macOS, tvOS, or visionOS.

---

## HomeKit

Lets people securely control connected accessories using Siri or the Home app on iPhone, iPad, Apple Watch, and Mac. Your iOS, tvOS, or watchOS app can integrate to help people set up, name, and organize accessories; allow fine-grained configuration and control; provide access to custom features; show people how to create hands-free automations; and provide support.

**Terminology and layout.** HomeKit models a home as a hierarchy and defines a vocabulary. **It's crucial to use HomeKit's terminology and object model** so you reinforce people's understanding and make home automation feel approachable. The **home** object is the root; **rooms**, **accessories**, and **zones** live beneath it. Each home is the root of a separate hierarchy.
- **Acknowledge the hierarchical model.** Even if your UI doesn't organize by rooms and zones, reference the model when helping people set up or control accessories — people need to know where accessories are so voice commands like "Siri, turn on the lights upstairs" work.
- **Make an accessory's HomeKit details easy to find** — don't bury the zone or room in a hard-to-discover settings screen; put it in the accessory detail view.
- **Recognize people can have more than one home.** Even without multi-home support, provide the relevant home information in the accessory detail view.
- **Don't present duplicate home settings.** Always defer to what people set up in the Home app; don't ask them to set up their home again.

**Model terms.** A **home** is a physical home, office, or other location; a person can have several. A **room** is a physical room, with no attributes beyond a meaningful name — Bedroom, Office. An **accessory** is a physical connected device (a ceiling fan, lamp, lock, camera); its **category** is its type (thermostat, fan, light), usually assigned by the manufacturer — your app can help assign it, and a switch connected to a fan or lamp must be assigned to the same category as what it controls. A **service** is a controllable feature of an accessory (the switch on a connected light); some accessories offer several (a garage door with separate light and door control; an outlet with separate top and bottom control). **Apps don't use the word "service"** — they use descriptive names like *garage door opener* and *ceiling fan light*, and **people speak the service name to Siri, not the accessory name**. A **characteristic** is a controllable attribute of a service (a fan's speed, a light's brightness); apps use descriptive terms, not the word "characteristic." A **service group** groups services people control as a unit — a floor lamp and two table lamps as *reading lamps*. An **action** changes a service's characteristic. A **scene** groups actions across services and accessories — *Movie Time* lowering shades and dimming lights; *Good Morning* turning on lights, raising shades, and starting the coffee maker. (The API says *action set*; **your UI must say scene**.) **Automations** cause accessories to react to situations — location changes, times of day, another accessory's state, a sensor. A **zone** is an area containing multiple rooms — *upstairs*, *downstairs* — optional, but it enables "Siri, turn off all the lights downstairs."

**Setup**
- **Use the system-provided setup flow.** It's faster than traditional flows — naming, network joining, HomeKit pairing, room and service category assignment, and favorites in a few steps — letting you concentrate on what makes your accessory unique.
- **Provide context for why you need Home data.** "Lets you control this accessory with the Apple Home app and Siri across your Apple devices."
- **Don't require an account or personal information.** Defer to HomeKit. If you offer additional services needing an account (cloud services), make setup optional and offer it *after* HomeKit setup.
- **Honor people's setup choices.** When people choose HomeKit, don't force them through other platforms' setup — it prevents immediate use and confuses by presenting too many ways to control the accessory.
- **Provide a custom setup experience carefully.** Always begin with the system flow. Once basic functionality works, offer a custom post-setup experience highlighting your accessory's unique features — a light manufacturer helping people create personalized scenes from colors scanned out of their photos.

**Naming.** **Suggest service names that suit your accessory** when your app detects a suboptimal one for voice control. **Never suggest company names or model numbers.** **Check names against HomeKit's rules**: alphanumeric, space, and apostrophe characters only; start and end with an alphabetic or numeric character; no emoji. ("Reading lamp" and "2nd garage door" pass; "📚 lamp" and "#2 garage door" don't.) The system flow checks original names; **if your app lets people rename services, you must check the new names**, briefly explaining any problem and suggesting working alternatives. **Help people avoid names including location information.** "Kitchen light" is natural but produces unpredictable voice results — detect duplicated location information and help people fix it, ideally with a post-setup experience that removes the room or zone from the name and encourages assigning the accessory to it instead.

**Siri interactions.** **Present example voice commands during setup** using the service name people chose, and encourage trying them. **After setup, teach more complex commands** in useful places — a scene detail view could say: You can say "Hey Siri, set 'Movie Time.'" Siri recognizes home, room, zone, service, and scene names, and also uses accessory category and characteristic — "brighter" or "dim" identify a service with a brightness characteristic without the service name.

| Phrase | Siri understands |
|---|---|
| "Turn on the floor lamp" | Service |
| "Turn on the light" | Accessory category |
| "Turn off the living room light" | Room + accessory category |
| "Make the living room a little bit brighter" | Room + implied category + brightness characteristic |
| "Turn on the recessed lights" | Service group |
| "Turn off the lights upstairs" | Accessory category + zone |
| "Dim the lights in the bedroom and nursery" | Category + brightness characteristic + two rooms |
| "Run Good night" | Scene |
| "Is someone in the living room?" | Implied category + implied occupancy characteristic |
| "Did I leave the garage door open?" | Accessory category + open characteristic |
| "It's dark in here" | Current home + current room (via HomePod) + implied category |

**Recommend zones and service groups** where they'd help — a light, switch, or thermostat manufacturer suggesting an "upstairs" zone or a "media center" service group. **Offer shortcuts only for accessory-specific functionality HomeKit doesn't support.** HomeKit already handles natural language control without configuration, so a duplicate shortcut just confuses; offer shortcuts for complementary functionality instead ("Order AC filters"). **If your app supports both, help people understand the difference** — clearly indicate what's possible with shortcuts, and **never encourage creating a shortcut for a scene or action HomeKit already supports**.

**Custom functionality.** **Be clear about what people can do in your app and when they need the Home app.** If your app supports only lights, guide people to create a scene with your accessory's actions (dimming the lights) and then suggest opening the Home app to add their shades and TV. **Defer to HomeKit when your database differs** — reflect changes made in the Home app or other HomeKit apps automatically. If people must manage a conflict, present it visually (both names side by side) so they can confirm. **Ask permission before updating the HomeKit database.** **Never overwrite HomeKit settings without explicit direction.**

**Cameras.** **Don't block camera images** — supplementing with an alert calling attention to activity is fine, but don't cover the images. **Show a microphone button only if the camera supports bidirectional audio** — a nonfunctioning button wastes space and confuses.

**Icons.** Use the HomeKit icon in setup or instructional communications; use the Apple Home app icon when referencing the app or in a button that opens its App Store page. **Use only Apple-provided icons.** Styles: **black** (on white or light backgrounds when other technology icons are black) · **white** (on black or dark backgrounds when others are white) · **custom color** (when others appear in the same color). **Position it consistently with other technology icons** — if others are contained within shapes, treat the HomeKit icon the same. **Use it noninteractively** — don't use the icon or the name HomeKit in custom interactive elements or buttons (the Apple Home app icon may open the App Store page). **Don't use it within text or as a replacement for the word HomeKit.** **Pair the icon with the name correctly** — below or beside it, if other technologies are referenced that way, in the same font as the rest of your layout.

**Referring to HomeKit.** **Emphasize your app over HomeKit** — references to HomeKit or Apple Home should be less prominent than your app name. **Adhere to Apple's trademark guidelines**: no Apple trademarks in your app name or images; singular form only, never possessive; never translated; no category descriptors ("iPad", not "tablet"); no implication of sponsorship, partnership, or endorsement; correct credit lines wherever legal information appears; refer to Apple devices and operating systems only in technical specifications or compatibility descriptions ("Use HomeKit to turn on your lights from your iPhone or iPad" ✅ — "from your iOS devices" ❌). **HomeKit** is one word, uppercase H and K; **Apple Home** is two words, uppercase A and H; all uppercase only to match an all-caps layout. **Don't use the name HomeKit as a descriptor** — use *works with*, *use*, *supports*, *compatible* ("[Brand] lightbulbs work with HomeKit" ✅ — "HomeKit-enabled thermostat" ❌ — "HomeKit lightbulbs" ❌). **Don't suggest HomeKit performs an action** ("Back door is unlocked with HomeKit" ✅ — "HomeKit unlocked the back door" ❌). You may use "Apple" with "HomeKit" ("Compatible with Apple HomeKit"), and the name HomeKit for setup, configuration, and instructions ("Open HomeKit settings"). **Use "Apple Home" when referring specifically to the app** — the full name on first mention in body copy, "the Home app" afterward. Never just "Home."

---

## iCloud

Lets people access their content from any device without explicit synchronization. **A fundamental aspect is transparency** — people don't need to know where content resides, and can assume they're always accessing the latest version.

- **Make it easy to use your app with iCloud.** People turn it on in Settings and expect apps to work with it automatically. If you think people might want a choice, offer a simple option the first time your app opens — **all data or not at all**.
- **Avoid asking which documents to keep in iCloud.** Most people expect everything to be available and don't want to manage individual documents. Perform more file management automatically.
- **Keep content up to date**, balanced against storage and bandwidth. For very large documents, let people control when updated content downloads — and design a way to indicate a more recent version exists in iCloud. Provide subtle feedback when a download takes more than a few seconds.
- **Respect iCloud storage space.** It's finite and people pay for it. Store what people create and understand; **don't store app resources or regenerable content**. Even without iCloud support, **backups include the contents of every app's Documents folder** — be picky about what goes there.
- **Behave appropriately when iCloud is unavailable.** If someone turns it off or enables Airplane Mode, you don't need an alert — but unobtrusively letting people know changes won't reach other devices until access is restored is helpful.
- **Keep app state information in iCloud.** A magazine app storing the last page viewed lets people continue on another device. **Only store settings people want applied to all devices** — some settings are more useful at work than at home.
- **Warn about the consequences of deleting a document.** Deleting removes it from iCloud and every other device — show a warning and ask for confirmation.
- **Make conflict resolution prompt and easy.** Detect and resolve automatically where possible; otherwise display an unobtrusive notification making it easy to differentiate and choose between versions. Resolve as early as possible so nobody wastes time in the wrong version.
- **Include iCloud content in search results.** People assume their content is universally available and expect results to reflect that.
- **For games, consider saving progress in iCloud.** The **GameSave** framework synchronizes save data across devices and provides built-in alerts for offline-play and conflict situations — or you can build custom UI using GameSave data.

---

## Game Center

Apple's social gaming network, letting players track progress and connect with friends across platforms, and boosting discovery of your game. Supporting it lets players discover games their friends play, invite friends seamlessly, and see recent activity across the system, in the Apple Games app, the App Store, and notifications. Built with **GameKit**, which provides full-featured UI or the data for your own.

**Accessing.** Determine whether the player is signed in when they launch, and **initialize them with Game Center at that time** if they aren't. This gives the most seamless experience and maximizes discovery — the Top Played chart, social recommendations through friends.

**The access point** is an Apple-designed element letting players view their Game Center profile and information without leaving your game. In iOS, iPadOS, and macOS it leads to the **Game Overlay**; in visionOS and tvOS it leads to the **in-game dashboard**, a full-screen view over your game.
- **Display it in menu screens** — the main menu or settings area. **Avoid it during active gameplay** or in temporary splash screens, cinematics, or tutorials preceding the main menu.
- **Avoid placing controls near it.** It can go in any of the four screen corners in a fixed position, and has collapsed and expanded versions — check whether either overlaps important UI. (In visionOS its location varies by game type — immersive or volume-based.)
- **Consider pausing your game** while the Game Overlay or dashboard is present, so players don't feel the game is continuing without them.

**Custom UI.** You can deep-link into specific areas — leaderboards, a player's profile. **Use the artwork Game Center provides** from Apple Design Resources, preserving its appearance and not adjusting dimensions or visual effects. **Use the correct terminology**: **Game Center** (not GameKit, GameCenter, game center — use the system-provided translation) · **Game Center Profile** (not Profile, Account, Player Info — system translation for Game Center, localize Profile) · **Achievements** (not Awards, Trophies, Medals) · **Leaderboards** (not Rankings, Scores, Leaders) · **Challenges** (not Competitions) · **Add Friends** (not Add, Add Profiles, Include Friends).

**Achievements** appear as collectible cards highlighting progress and showcasing your artwork.
- **Align with the four states**: locked, in-progress, hidden, completed. The system groups completed achievements in Completed and everything else in Locked. Mapping to these states gives players a consistent experience and shows what kinds of achievements you offer at a glance.
- **Determine a display order** — the upload order is the display order, so consider it before uploading. An order corresponding to the most common path through your game often works.
- **Be succinct.** The card limits the title and description to **two lines each**, truncating beyond that. Title case for the title, sentence case for the description.
- **Give players a sense of progress** with progressive achievements — the system displays progress and encouraging messages.
- **Design rich, high-quality images.** Achievements are prominent in Game Center UI. **Don't reuse an asset for more than one achievement.** Without an asset, the card shows a placeholder. The system applies a **circular mask** — keep content centered. PNG, TIF, or JPG · sRGB or P3 · ≥72 DPI · **512×512 pt (1024×1024 px @2x)** · mask diameter 512 pt (1024 px @2x).

**Leaderboards** let players check their ranking against friends and global players and get notified when friends challenge them or pass their score.
- **Choose a type.** A **classic** leaderboard tracks an all-time best and never ends — a perfect score in a rhythm game, the most coins in a dungeon run, the longest time in an endless runner. A **recurring** leaderboard resets on an interval you define — daily rotating puzzles, seasonal events, weekly battle-mode boards — increasing engagement by giving more people a chance to lead.
- **Use leaderboard sets** to make boards findable: difficulty modes (Easy, Standard, Hard), activity types (Combat, Crafting, Farming), genres and themes (Disco, Pop, Rock).
- **Add leaderboard images.** Aim for a unique image per leaderboard reflecting the gameplay involved. Leaderboards appear across the system, so compelling images attract players. iOS, iPadOS, macOS: a single image. tvOS: a set that animates on focus (download the tvOS template from Apple Design Resources). JPEG, JPG, or PNG · sRGB or P3 · ≥72 DPI · **512×512 pt (1024×1024 px @2x)**, cropped area **512×312 pt**. **Be mindful of cropping** — the system crops artwork for leaderboards in a set, and the tvOS focus effect may crop layer edges.

**Challenges** turn single-player activities into multiplayer experiences with friends, built on leaderboards with time limits.
- **Create engaging challenges** — short, skill-based activities with a clear measure, **1–5 minutes**, completable individually: the fastest lap, the most enemies in a round, a daily puzzle with the fewest mistakes.
- **Avoid challenges tracking overall progress or personal bests** — they give regular players an unfair advantage. **Track the most recent score after each attempt** so everyone starts level.
- **Make it easy to jump in.** Players access challenges through invitation links, the Game Overlay, or the Games app. **Always deep-link to the exact mode or level.** Help first-time players through any required onboarding first — launch them into the tutorial and tell them the game jumps into the challenge afterward.
- **Create high-quality artwork.** Shown in the Game Overlay, the Games app, and invitation link previews. **Avoid placing primary content where the title and description might cover it.** Provide localized versions through App Store Connect or Xcode if you use text. JPEG, JPG, or PNG · sRGB or P3 · ≥72 DPI · **1920×1080 pt (3840×2160 px @2x)**, cropped area **1465×767 pt**.

**Multiplayer activities.** Real-time and turn-based, accessible through party codes, the Game Overlay, the dashboard, or the Games app. **Use party codes** for real-time sessions, whether you use Game Center matchmaking and networking or your own. Codes are alphanumeric, typically eight characters ("2MP4-9CMF"). **Allow players to join late, leave early, and return.** **Provide a way to view the current party code in your game.** **Allow manual party code entry.** **Support multiplayer through in-game UI** — the Game Overlay and dashboard let players find people without leaving your game, and the default interface lets a player invite nearby or recent players, Game Center friends, and contacts (or build your own). **Provide engaging activity artwork** — the preview image appears in party codes, the Games app, and in-game UI. JPEG, JPG, or PNG · sRGB or P3 · ≥72 DPI · **1920×1080 pt (3840×2160 px @2x)**, cropped area **1465×767 pt**.

**tvOS.** You can add an optional image at the top of the dashboard. **Use a simple, easily recognizable image that looks great at a distance** — your game's logo or wordmark, **not your app icon**. **600×180 pt (1200×360 px @2x)** · PNG, TIF, or JPG · sRGB or P3 · ≥72 DPI. **watchOS.** GameKit features and APIs are available, but **there's no system-supported Game Center UI you can invoke** — Game Center content for watchOS games appears on a connected iPhone.

---

## NFC (iOS, iPadOS)

Lets devices within a few centimeters exchange information wirelessly. Apps on supported devices can read data from electronic tags attached to real-world objects — scanning a toy to connect it with a game, an in-store sign for coupons, products for inventory.

**In-app tag reading.** Support single- or multiple-object scanning while your app is active, showing a scanning sheet.
- **Don't encourage people to make contact with physical objects.** The device only needs to be in close proximity. **Use *scan* and *hold near*, not *tap* and *touch*.**
- **Use approachable terminology.** NFC may be unfamiliar — avoid *NFC*, *Core NFC*, *near-field communication*, and *tag*.

| Use | Don't use |
|---|---|
| Scan the [object name]. | Scan the NFC tag. |
| Hold your iPhone near the [object name] to learn more about it. | To use NFC scanning, tap your phone to the [object]. |

- **Provide succinct instructional text for the scanning sheet** — a complete sentence, sentence case, ending punctuation, identifying the object, revised for subsequent scans and short enough to avoid truncation. First scan: "Hold your iPhone near the [object name] to learn more about it." Subsequent: "Now hold your iPhone near another [object name]."

**Background tag reading** lets people scan any time without opening your app first. On supported devices the system looks for nearby compatible tags whenever the screen is illuminated, then shows a notification people tap to send the tag data to your app. It **isn't available** when an NFC scanning sheet is visible, when Wallet or Apple Pay are in use, when cameras are in use, in Airplane Mode, or when the device is locked after a restart. **Support both background and in-app tag reading** — your app must still provide an in-app path for devices that don't support background reading. Not supported in macOS, tvOS, visionOS, or watchOS.

---

## Tap to Pay on iPhone (iOS)

Lets merchants accept contactless payments using an app on their iPhone, with no external hardware. It works alongside existing payment-acceptance hardware. You need a supported **payment service provider (PSP)**, the Tap to Pay on iPhone entitlement, and the **ProximityReader** APIs (directly or through your PSP's SDK). If your PSP's SDK supplies its own interfaces for things like showing a tap result, follow their documentation.

**Enabling.** Merchants must accept the terms and conditions before initial device configuration.
- **Help merchants accept the terms before they start interacting with customers** — offer buttons to accept from in-app messaging or onboarding flows.
- **Present the terms only to an administrative user.** If a nonadministrator tries to activate, explain that administrator access is required. If your primary users are enterprise or nonadministrative, an administrator can accept through a web interface or a different app, including on non-iPhone devices.
- **Help merchants keep their device up to date** if your PSP requires specific iOS versions — present the terms only after they update.

**Educating merchants.** **Provide a tutorial** describing supported payment types and how to accept each — in a Learn More option, automatically after accepting the terms, automatically for new users, or in a consistent place like your help content or settings. Build it from Apple-approved assets in the Tap to Pay on iPhone marketing guidelines, or use the **ProximityReaderDiscovery** API for a pre-built, always-current, region-localized merchant education experience. A custom tutorial must show how to launch checkout for each payment type, help a customer position their card or wallet, and handle PIN entry including accessibility mode — and should end with an opportunity to accept the terms.

**Checking out.** Checkout is time-sensitive.
- **Provide Tap to Pay on iPhone as a checkout option whether or not it's enabled**, presenting the terms if necessary and automatically showing the Tap to Pay screen once configuration completes.
- **Don't make merchants wait.** Beyond initial per-device configuration, you must configure again each time your app becomes frontmost — **prepare as soon as your app starts and immediately after each foreground transition** (`prepare(using:)`).
- **Keep the option available during background configuration.** Let merchants select it and show a progress indicator — usually indeterminate, but **determinate** if the ProximityReader API reports ongoing configuration progress (`PaymentCardReader.Event.updateProgress(_:)`).
- **Make the button easy to find** if you support multiple payment methods — no scrolling. If it's your only method, open Tap to Pay automatically when checkout begins.
- **Make switching between Tap to Pay and hardware accessories easy** — set both up at the same time, and let merchants choose the method during checkout without visiting settings.
- **Label the button "Tap to Pay on iPhone"** or, if space is constrained, **"Tap to Pay."** The exception: if it's your only payment-acceptance method, you can reuse your existing Charge or Checkout buttons. With multiple methods using icons, use the `wave.3.right.circle` or `wave.3.right.circle.fill` SF Symbols. **Never include the Apple logo.** **Use these labels only for payment actions.**
- **Match the button to your app's other buttons** in color and shape (the labels are fixed).
- **Determine the final amount before merchants initiate the experience** — tipping and other customer interactions affecting the total must come first, so the Tap to Pay screen shows the final amount.
- **Display pre-payment options before the Tap to Pay screen** — payment type selection can appear in your checkout screen after the merchant taps the button.

**Displaying results.** After a successful tap (and PIN entry, if required), Tap to Pay displays a checkmark and gives your app the encrypted payment information for your PSP. A failed tap shows an error screen. **Your app displays transaction results and offers alternatives after a failure.**
- **Start processing as soon as possible** — you can request the result before the checkmark animation finishes (`returnReadResultImmediately`).
- **Display a progress indicator while payment authorizes**, *after* the Tap to Pay screen animation finishes, for a smooth transition (`PaymentCardReader.Event.readyForTap`). Authorization can take several seconds depending on PSP and merchant connectivity.
- **Clearly display the result**, declined or successful. Declines happen for insufficient funds, suspected fraud, or an incorrect PIN. Where possible, give the merchant ways to offer a digital receipt — a QR code or text message.
- **Help merchants complete checkout when Tap to Pay can't.** A tap fails when a card isn't readable, isn't from a supported network, doesn't allow the amount, or doesn't allow online PIN entry. Present a new screen or reuse checkout so merchants can accept cash; support a different method like external hardware or a payment link; or relaunch Tap to Pay for another card.
- Some regions require **Strong Customer Authentication** — the issuing bank can request a PIN after receiving the processing request, so your app may need to display the PIN entry screen instead of the result. Some regions have additional requirements for cards in **Offline PIN markets**; some PSPs support PIN fallback collecting partial tap data so merchants can continue with another method. Contact your PSP.
- **Display a clear description and recommended resolution** for errors merchants must address — an alert recommending an iOS update if the version doesn't support the feature (`PaymentCardReaderSession.ReadError`).
- **Make it easy to get help** — direct merchants to in-app or website help content and provide an action that contacts support.

**Additional interactions.** Tap to Pay can read a payment card with no transaction amount — looking up a past transaction, retaining card information for future payment, issuing refunds, verifying customer information. **Use a generic label** for that button: "Look Up", "Store Card", "Verify", "Refund" — **not** "Tap to Pay on iPhone" or "Tap to Pay." Merchants can also read other NFC-compatible Wallet cards and passes (loyalty, discount, points) alongside a payment card or independently. **If you support an independent loyalty card transaction, distinguish it from a payment flow** with a separate, clearly labeled button that avoids payment-related terms. Not supported in iPadOS, macOS, tvOS, visionOS, or watchOS.

---

## ID Verifier (iOS)

Lets your iPhone app read ISO18013-5 compliant mobile IDs in person without external hardware — venue personnel verifying customers' ages. Customers present the minimum data needed without handing over their ID or showing their device, and Apple provides the certificate issuance, management, and validation components for a consistent, trusted experience.

**Request types.** A **Display Only** request shows data — a name or age alongside a photo portrait — in system-provided UI on the requester's iPhone for visual confirmation. **The customer's data stays in the system UI and isn't transmitted to your app** (`MobileDriversLicenseDisplayRequest`). A **Data Transfer** request is only for cases where you have a **legal verification requirement** and need to store or process information like an address or date of birth; it needs an additional entitlement (`MobileDriversLicenseDataRequest`, `MobileDriversLicenseRawDataRequest`).

- **Ask only for the data you need.** For a minimum age, use an age threshold request (`ageAtLeast(_:)`) rather than requesting the current age or birth date.
- **Register for ID Verifier with Apple Business Register** if your app qualifies, so people see your official organization name and logo as part of the verification UI.
- **Provide a button that initiates verification** — "Verify Age" for a simple age check, "Verify Identity" for a detailed data request. **Don't include a symbol specifying a communication type** like NFC or QR codes. **Never include the Apple logo.**
- **In a Display Only request, help the person using your app provide feedback on the visual confirmation** — buttons labeled *Matches Person* and *Doesn't Match Person* so your app receives an approved or rejected value. Not supported in iPadOS, macOS, tvOS, visionOS, or watchOS.

---

## AirPlay

Streams media wirelessly from iOS, iPadOS, macOS, and tvOS to Apple TV, HomePod, and AirPlay-compatible TVs and speakers.

- **Prefer the system-provided media player** (`AVPlayerViewController`) — standard controls, chapter navigation, subtitles, closed captioning, AirPlay streaming, and a consistent playback experience. Design a custom player only if the system player genuinely doesn't meet your needs.
- **Provide content in the highest possible resolution.** Your HLS playlist must include the full range of resolutions so AVFoundation can select the right one — content that looks great on iPhone at 720p looks poor streamed to a 4K TV.
- **Stream only the content people expect.** Not background loops or short video experiences that only make sense inside the app (`usesExternalPlaybackWhileExternalScreenIsActive`).
- **Support both AirPlay streaming and mirroring.**
- **Support remote control events** so people can play, pause, and fast forward from the Lock Screen, Siri, and HomePod.
- **Don't stop playback when your app backgrounds or the device locks.** People expect a streaming show to continue while they check mail or sleep the device. **Avoid automatic mirroring** in this scenario — people don't want other content on their device streamed without choosing to.
- **Don't interrupt another app's playback** unless you're starting immersive content. A video playing on launch or an auto-played inline video should play on the local device only, letting current playback continue (`ambient`).
- **Let people use other parts of your app during playback.** Your app must stay functional while AirPlay is active, and navigating away from the playback screen must not start other in-app videos that interrupt the stream.
- **A custom player** must provide custom buttons matching the appearance and behavior of the system ones, with distinct visual states for playback started, occurring, and unavailable. **Use only Apple-provided symbols** in custom controls that initiate AirPlay, positioned in the **lower-right corner** (iOS 16 and iPadOS 16 and later).

**Icons.** Styles: **black** (white or light backgrounds when other technology icons are black) · **white** (black or dark backgrounds when others are white) · **custom color** (when others appear in the same color). **Position it consistently with other technology icons**, including within shapes if that's how you present others. **Don't use the AirPlay icon or name in custom buttons or interactive elements** — noninteractive use only. **Pair the icon with the name correctly**, below or beside it, in the same font as the rest of your layout, and **avoid using the icon within text or as a replacement for the name**. **Emphasize your app over AirPlay.**

**Referring to AirPlay.** One word, uppercase A and P; all uppercase only to match an all-caps layout. **Always a noun** ("Use AirPlay to listen on your speaker" ✅ — "AirPlay to your speaker" ❌ — "You can AirPlay with [App Name]" ❌). Use *works with*, *use*, *supports*, *compatible* ("[App Name] is compatible with AirPlay" ✅ — "AirPlay-enabled speaker" ❌ — "[App Name] has AirPlay" ❌). You may use "Apple" with it ("Compatible with Apple AirPlay"). Refer to it where it adds clarity, and in technical specifications ("[App Name] now supports AirPlay"). Not supported in watchOS.

---

## ShazamKit

Supports audio recognition by matching a sample against the ShazamKit catalog or a custom catalog — graphics matching the genre of currently playing music, closed captions or sign language synced to audio for people with hearing disabilities, in-app experiences synchronized with virtual content in online learning and retail. If you need the microphone, you must request access and explain why.

- **Stop recording as soon as possible.** People don't expect the microphone to stay on. **Record only as long as it takes to get the sample.**
- **Let people opt in to storing recognized songs to their iCloud library.** Even though the Music Recognition control and the Shazam app show your app as the source, people appreciate controlling which apps store content in their library.

---

## Live Photos

Captures audio and extra frames before and after a photo; people press a Live Photo to see it spring to life.

- **Apply adjustments to all frames.** If you let people apply effects or adjustments, apply them to the entire photo. If you can't, offer to convert it to a still photo.
- **Keep Live Photo content intact.** People expect a consistent visual treatment and interaction model across apps. **Don't disassemble a Live Photo and present its frames or audio separately.**
- **Implement a great sharing experience.** Let people preview the entire contents before sharing, and **always offer the option to share as a traditional photo.**
- **Clearly indicate when a Live Photo is downloading and when it's playable** — a progress indicator during download, and an indication when it's complete.
- **Display Live Photos as traditional photos in unsupported environments.** Don't attempt to replicate the experience — show a still representation.
- **Make Live Photos distinguishable from still photos.** The best way is a hint of movement. **There are no built-in motion effects** — the one in Photos' full-screen browser is custom, so you need to design and implement your own. Where movement isn't possible, show the **system-provided badge** above the photo, with or without text. **Never include a playback button** that could be mistaken for video playback. **Keep badge placement consistent** — the same corner on every photo.
- visionOS: people can view a Live Photo but can't capture one. Not supported in watchOS.

---

## iMessage apps and stickers

An iMessage app helps people share content, collaborate, and play games within a conversation; stickers decorate conversations. Both are available in Messages and in effects in Messages and FaceTime, as a standalone app or an extension within your iOS or iPadOS app.

- **Prefer one primary experience.** People are in a conversational flow — your functionality or content must be immediately understandable and available. For multiple types of functionality or different content collections, create separate iMessage apps.
- **Consider surfacing content from your iOS or iPadOS app** — app-specific information people might share (a shopping list, a trip itinerary), or a simple collaborative task (deciding where to eat, what movie to watch).
- **Present essential features in the compact view.** People experience your app in a compact view below the transcript, or expanded to occupy most of the window. Put the most frequently used items in the compact view and reserve additional content and features for the expanded one.
- **Let people edit text only in the expanded view.** The compact view occupies roughly the keyboard's space, so displaying the keyboard there hides your content.
- **Create expressive, inclusive, versatile stickers.** Rich static images or short animations, legible against a wide range of backgrounds and when rotated or scaled. Use transparency to help people integrate a sticker with text, photos, and other stickers.
- **Provide a localized alternative description for each sticker** so VoiceOver can speak it.

---

## Photo editing

Photo-editing extensions let people modify photos and videos inside the Photos app. **Edits always save as new files**, preserving the originals. A photo must be in edit mode; tapping the extension icon in the toolbar shows an action menu of available extensions, and selecting one displays its interface in a modal view with a top toolbar. Dismissing confirms and saves, or cancels.

- **Confirm cancellation of edits.** Editing takes time — don't discard changes immediately on Cancel. Ask people to confirm and tell them edits will be lost. (No confirmation is needed if no edits have been made.)
- **Don't provide a custom top toolbar.** The modal view already includes one — a second is confusing and takes space from the content.
- **Let people preview edits.** It's hard to approve an edit you can't see.
- **Use your app icon for the extension icon** so people are confident the extension comes from your app.

Not supported in tvOS, visionOS, or watchOS.

---

## CareKit

For managing care plans related to a chronic illness, recovery from an injury or surgery, or health and wellness goals. **CareKit UI** provides prebuilt views; **CareKit Store** defines a database schema incorporating patients, care plans, tasks, and contacts, with seamless synchronization between database and UI.

**Data and privacy.** Nothing is more important than protecting privacy and safeguarding the extremely sensitive data a CareKit app collects. **Provide a coherent privacy policy** at a URL supplied during app submission. Beyond what people enter, you may access data through iOS features and capabilities — **you must receive permission before accessing it, and you must protect all of it**, whether entered by people or obtained from the device or system.

**HealthKit integration** lets you ask permission to access and share health and fitness data with designated caregivers. **Request access only when you need it** — when people log their weight, not at launch — and request every time, since permissions can change. **Clarify your intent with descriptive messages on the standard permission screen** — a few succinct sentences on why you need the information and how people benefit. **Don't add custom screens replicating the standard one.** **Manage health data sharing solely through the system's privacy settings.**

**Motion data.** With permission, your app can determine whether people are standing still, walking, running, cycling, or driving, and for walking and running, the step count, pace, and flights of stairs. Motion information can also include custom data collected as part of physical therapy — some ResearchKit tasks use device sensors to test flexibility, range of motion, and ambulatory capability.

**Photos.** With permission, your app can access the camera and photo library to share pictures with a care team — a care plan might request periodic photos of an injury so a physician can monitor healing.

**ResearchKit integration.** Your CareKit app can incorporate ResearchKit features to display related surveys, tasks, and charts, and can use its **informed consent module** to request permission to collect and share data.

**CareKit views** come in three categories, each designed for specific content and interaction. **Use each view type for its intended purpose.** **Tasks** present things like taking medication or doing physical therapy, and support logging symptoms and other data. (Charts and contacts are the other two categories.)
