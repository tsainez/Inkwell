# Inkwell — App Store Release Checklist

Status of everything standing between this repo and a 1.0 on the App Store.
Items marked ✅ were fixed in the codebase; items marked 🔲 need you (mostly
in App Store Connect — they can't be done from the repo).

## ✅ Fixed in the repo

- **App icon** — `AppIcon.appiconset` now has all three iOS 18 variants
  (light / dark / tinted), generated from the app's own stroke data for 永:
  stroke 1 fully inked in vermilion, each later stroke fading toward
  invisible. Regenerate anytime with `python3 scripts/generate_app_icon.py`
  (needs `pip install cairosvg`). The light icon is alpha-free, as App Store
  validation requires.
- **Privacy policy** — `docs/PRIVACY.md`, also linked from Settings → About.
  Use its GitHub URL as the Privacy Policy URL in App Store Connect.
- **Privacy manifest** — `Inkwell/PrivacyInfo.xcprivacy` declares no
  tracking, no collected data, and the UserDefaults required-reason API
  (`CA92.1`, from `@AppStorage`). Required for all submissions since
  spring 2024.
- **Export compliance** — `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO`
  is set on the app target (the app uses no encryption beyond Apple's OS
  services), so uploads skip the compliance questionnaire. If App Store
  Connect still asks, answer "None of the algorithms mentioned above" —
  and check that the key made it into the built app's Info.plist.
- **Dark-mode ink** — user strokes now resolve against the active appearance
  (cream ink on the dark pad) instead of drawing black-on-black.
- **Placeholder UI removed** — the inert "Audio" chip in the practice screen
  is gone; non-functional controls are a common Guideline 2.1 rejection.

## ✅ Already in good shape (verified, no action)

- iPad-only (`TARGETED_DEVICE_FAMILY = 2`), all four iPad orientations
  supported — satisfies the iPad multitasking expectation.
- Launch screen generated (`UILaunchScreen_Generation`).
- App category set: Education. Deployment target iOS 17.0.
- No third-party SDKs, no network calls — nothing else to declare in the
  privacy manifest or App Privacy questionnaire.
- Stroke-data attribution (Make Me a Hanzi / hanzi-writer-data, Arphic PL)
  is bundled (`StrokeData-ATTRIBUTION.txt`) and shown in Settings → About.
- Finger drawing works (`drawingPolicy = .anyInput`) — App Review will test
  without an Apple Pencil.

## 🔲 Decide before the first upload

- **Bundle identifier is `tsainez.Inkwell`.** It works, but it's frozen
  forever after the first upload to App Store Connect. If you'd rather have
  the conventional reverse-DNS form (e.g. `com.tsainez.inkwell`), change it
  *now* in the target's Signing & Capabilities.
- **App name availability.** "Inkwell" must be unique on the App Store and
  short names are usually taken. Check when you create the app record; have
  a fallback like "Inkwell — Hanzi & Kanji" ready. (The display name on the
  home screen stays "Inkwell" either way via `CFBundleDisplayName`.)

## 🔲 App Store Connect (manual)

1. Enroll in the Apple Developer Program ($99/yr) if you haven't.
2. Create the app record (name, primary language, bundle ID, SKU).
3. **Privacy Policy URL** → `https://github.com/tsainez/Inkwell/blob/main/docs/PRIVACY.md`
   (or host it on GitHub Pages if you want it prettier).
4. **App Privacy questionnaire** → "Data Not Collected" (true as of this
   release: everything is on-device).
5. **Age rating questionnaire** → should come out 4+.
6. **Screenshots** — required for the 13" iPad size class (2064×2752 or
   2048×2732). Take them in the iPad Pro simulator (⌘S saves to Desktop).
   Include at least: Library, Practice mid-character, Session complete.
   Take a matching dark-mode set if you want them in the listing.
7. Description, keywords, **support URL** (the GitHub repo works), and
   promotional text.
8. Archive & upload from Xcode (Product → Archive → Distribute App), then
   submit for review. Expect the reviewer to use the app iPad-with-finger.

## 🔲 Before submitting: one real smoke test

You've only tested in the simulator. Two things the simulator can't tell
you, in priority order:

1. **TestFlight on any physical iPad** (borrow one if needed) — pencil
   latency, palm rejection, and PencilKit input behave differently on
   hardware. `drawingPolicy = .anyInput` means a finger works, but grading
   thresholds were tuned in the simulator with a mouse.
2. Toggle Light/Dark both from the in-app Theme setting **and** from
   Control Center mid-practice-session, and confirm the wet ink stays
   visible (this PR re-inks existing strokes on appearance flips).
