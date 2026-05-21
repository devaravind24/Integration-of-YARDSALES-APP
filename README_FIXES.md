# Yard Sale – First Integrations Milestone: Code Fixes

This folder contains every file you need to replace in your project, plus the
logo asset. Drop them into the matching paths inside your project and you’re
done.

---

## 1. Where every file goes (mirror this layout in your project)

```
<your-project-root>/
├── assets/
│   └── logo.png                          ← NEW (your Figma logo, drop in here)
├── pubspec.yaml                          ← REPLACE
└── lib/
    ├── core/widgets/
    │   ├── yard_sale_logo.dart           ← NEW
    │   └── custom_drawer.dart            ← REPLACE
    ├── services/
    │   └── auth_service.dart             ← REPLACE
    └── screens/
        ├── auth/
        │   ├── login_screen.dart         ← REPLACE
        │   └── signup_screen.dart        ← REPLACE
        ├── home/
        │   ├── splash_screen.dart        ← REPLACE
        │   ├── discovery_screen.dart     ← REPLACE
        │   ├── listing_screen.dart       ← REPLACE
        │   └── sales_details_screen.dart ← REPLACE
        └── profile/
            └── profile_screen.dart       ← REPLACE
```

> **You do NOT need to touch:** `main.dart`, `app.dart`, `app_routes.dart`,
> `firebase_options.dart`, `map_screen.dart`, `schedule_screen.dart`,
> `create_listing.dart`, `filter_modal.dart`, `sale_card.dart`, `home_screen.dart`,
> `bottom_nav_screen.dart`. They’re fine as-is.

---

## 2. Set the logo up correctly in VS Code

1. In VS Code, right-click the project root → **New Folder** → name it **`assets`**.
2. Drop `logo.png` (provided here) into `assets/`.
3. Replace your `pubspec.yaml` with the one in this folder. The key parts are:

   ```yaml
   dependencies:
     # ...
     font_awesome_flutter: ^10.7.0

   flutter:
     uses-material-design: true
     assets:
       - assets/logo.png
   ```

4. In the VS Code terminal:

   ```bash
   flutter pub get
   ```

---

## 3. Run the app

```bash
flutter clean
flutter pub get
flutter run
```

---

## 4. What each fix does (so you can speak to it during the demo)

| # | Problem | Fix |
|---|---------|-----|
| 1 | Sales details page shows an empty grey image box | `sales_details_screen.dart` — image hero only rendered when `sale['imageUrl']` is a real, non-empty string |
| 2 | Welcome page Google / Facebook / X / Instagram icons were wrong (random Material icons) | `login_screen.dart` — uses `font_awesome_flutter` brand glyphs with real brand colors + Instagram gradient |
| 3 | Profile page hard-coded "Aravind Nanneboina" | `profile_screen.dart` reads `FirebaseAuth.currentUser.displayName` + email, with a Firestore `users/{uid}` fallback |
| 4 | "Hi, Aravind" on Discovery screen was hard-coded | `discovery_screen.dart` resolves a dynamic name via `AuthService.resolveDisplayName()` and updates on auth state changes |
| 5 | Home map looked flat / unrealistic | `discovery_screen.dart` — new `_RealisticMapPainter` with water, parks, building blocks, multi-width streets, dashed centerlines, animated pulse, drop-shadowed pins, live sales counter |
| 6 | Logo on welcome page didn’t match Figma | New `YardSaleLogo` widget loads `assets/logo.png` (your exact Figma file) — used on splash, login, listing header, and drawer |

> **Why the user name now actually works:** the old signup screen never saved
> the first/last name anywhere — only email + password. The new `AuthService.signUp`
> sets `displayName` on the FirebaseAuth user AND writes a `users/{uid}` doc in
> Firestore. Everywhere we read the name, we use `currentUser.displayName` with
> a Firestore fallback.

---

## 5. Testing checklist (do this before submission)

1. **Fresh signup** – create a new account with a name like "Test User", log in, open Profile → confirm "Test User" appears (not Aravind).
2. **Discovery greeting** – the greeting should say "Hi, Test" right after login.
3. **Logout & login as Aravind** – Profile should now show Aravind. Logout → log back in as Test User → name flips back. This proves it's dynamic.
4. **Sales details** – tap any listing. No grey image box on top unless the listing has an `imageUrl` field in Firestore.
5. **Welcome page social icons** – Google = white circle with multi-color G; Facebook = blue circle with white f; X = black circle with white X; Instagram = colorful gradient with white camera glyph.
6. **Splash / Welcome / Drawer / Listing** – all show the actual Figma logo (house + green pin + orange bag with tag), not three flat Material icons.
7. **Map** – streets feel layered (water, park, blocks), pins have shadows, your location has an animated pulse, top-right chip shows "N nearby sales".

---

## 6. If something fails to compile

Almost always one of these:

```bash
flutter clean
flutter pub get
flutter run
```

If you get `Unable to load asset: assets/logo.png`, then:
- The file is not at `<project_root>/assets/logo.png`, OR
- `pubspec.yaml` is missing the `assets:` block (re-check section 2 above).

If you get `Target of URI doesn't exist: package:font_awesome_flutter`:
- You skipped `flutter pub get` after updating `pubspec.yaml`.
