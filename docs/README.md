# Publishing this folder to GitHub Pages

This `docs/` folder is ready to be served as a website. Once published, you
get the URLs you need for App Store Connect:

- Site home:      `https://tsainez.github.io/Inkwell/`
- Privacy policy: `https://tsainez.github.io/Inkwell/privacy/`  ← use this as the **Privacy Policy URL** in App Store Connect
- Licenses:       `https://tsainez.github.io/Inkwell/licenses/`

## Steps (about 2 minutes)

1. Commit and push this folder to the `main` branch of the
   `tsainez/Inkwell` repo (the repo must be public — it already is if the
   in-app privacy link works).
2. On GitHub, open the repo → **Settings** → **Pages** (left sidebar).
3. Under **Build and deployment**:
   - Source: **Deploy from a branch**
   - Branch: **main**, folder: **/docs**
   - Click **Save**.
4. Wait a minute or two, then visit
   `https://tsainez.github.io/Inkwell/privacy/` to confirm it renders.

That's it. GitHub rebuilds the site automatically on every push to `main`.

## What the files here do

- `_config.yml` — site title, theme, and an exclude list so internal
  planning docs (`RELEASE_CHECKLIST.md`, `DARK_MODE_LIQUID_GLASS_PLAN.md`,
  this README) are **not** published.
- `index.md` — tiny landing page.
- `PRIVACY.md` — the privacy policy, served at `/privacy/`.
- `LICENSES.md` — stroke-data attribution + full Arphic Public License,
  served at `/licenses/`.

## Notes

- The in-app Settings link points to
  `https://tsainez.github.io/Inkwell/privacy/`, so publish Pages **before**
  submitting the build.
- If you ever rename the repo or your GitHub username, update the URLs in
  `SettingsView.swift`, `index.md`, and App Store Connect.
