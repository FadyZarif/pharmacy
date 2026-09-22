# Releasing Emad Fawzy Pharmacy

Runbook for the App Store. Google Play is unchanged and unaffected by any of
this — Android keeps package name `com.emadfawzy.pharmacies`.

---

## 1. Identity

| | |
|---|---|
| Apple team | `C64KS6GF44` — COWDLLY FOR DIGITAL SOLUTIONS SERVICES |
| App Store Connect app | `6812895180` · SKU `emad-fawzy-pharmacy` · primary locale `ar-SA` |
| iOS bundle id | `com.cowdlly.emadFawzyPharmacy` — App ID `LTL4C44ZR7`, Push capability on |
| Android package | `com.emadfawzy.pharmacies` (unchanged) |
| Distribution certificate | `Apple Distribution: COWDLLY…` id `3LZ3MRGZ7R`, expires 2027-09-07 |
| App Store profile | `Emad Fawzy Pharmacy App Store` uuid `39a287ef-8cf9-430a-827b-14583b400922` |
| Firebase iOS app | `1:412302383494:ios:359d31c7635676b1257407` |
| ASC API key | `TAR9L6995V`, issuer `d93c7a73-4684-4f8c-bde9-cce3899c9e80` |

**The iOS bundle id differs from Android on purpose.** `com.emadfawzy.pharmacies`
is registered to another Apple team (the free personal team the app was first
built with) and Apple will not release it — `POST /v1/bundleIds` answers
*"not available"*. iOS had never shipped, so the identifier was changed rather
than fought over. Apple matches App IDs case-insensitively: once
`com.cowdlly.emadFawzyPharmacy` existed, `com.cowdlly.emadfawzypharmacy` was
refused too.

Firebase iOS apps cannot have their bundle id edited, hence the second iOS app
in the project. The first one (`…81ffdc332be89fba257407`) is now unused.

## 2. Build and upload

```sh
flutter build ipa --release --export-options-plist=ios/ExportOptions.plist

xcrun altool --validate-app --type ios -f build/ios/ipa/pharmacy.ipa \
  --apiKey TAR9L6995V --apiIssuer d93c7a73-4684-4f8c-bde9-cce3899c9e80

xcrun altool --upload-app --type ios -f build/ios/ipa/pharmacy.ipa \
  --apiKey TAR9L6995V --apiIssuer d93c7a73-4684-4f8c-bde9-cce3899c9e80
```

**The export must be manual.** An App Store Connect API key with the App
Manager role cannot use Apple's cloud-managed signing, so
`signingStyle: automatic` fails no matter how it is configured.
`ios/ExportOptions.plist` already names the profile from §1.

Bump `version:` in `pubspec.yaml` before every upload — Apple rejects a build
number it has already seen, even for a rejected build.

A first clean release build takes ~50 minutes (the pods build from scratch);
later ones are minutes.

## 3. Metadata, from the command line

`tool/asc.mjs` is a dependency-free App Store Connect client;
`tool/asc_screenshots.mjs` does the reserve/upload/commit dance screenshots
need. Both read `ASC_ISSUER_ID` from the environment.

```sh
export ASC_ISSUER_ID=d93c7a73-4684-4f8c-bde9-cce3899c9e80
node tool/asc.mjs GET '/v1/apps/6812895180/appStoreVersions'
node tool/asc.mjs PATCH /v1/appStoreVersions/<id> '{"data":{...}}'
```

Everything is scriptable **except three things**:

1. **Creating the app record.** `POST /v1/apps` returns 403 *"The resource
   'apps' does not allow 'CREATE'"* — a restriction on the resource, not on the
   role. Browser only.
2. **App Privacy.** No API at all. Until the answers are *published* in the
   browser, `POST /v1/reviewSubmissionItems` refuses the version with
   `STATE_ERROR.APP_DATA_USAGES_REQUIRED`. Selecting the data types is not
   enough — each one needs its three answers and then the **Publish** button.
3. **The unlisted distribution request** (§5).

### Published App Privacy answers

Collected, all *linked to the user*, all *App Functionality*, none used for
tracking: Contact Info (name, email, phone) · Financial Info (other) · User
Content (photos, other) · Identifiers (user id, device id).

Not collected: location, contacts, health, search or browsing history,
purchases, **usage data, diagnostics**. The last two matter — no
`firebase_analytics` and no Crashlytics are linked, so declaring them would be
a false disclosure. Check `ios/Podfile.lock` before changing this.

## 4. Screenshots

App Store Connect wants 1320×2868 in the `APP_IPHONE_67` set (the API has no
`_69`; 6.9" images go in the 6.7" slot). An iPhone 17 Pro Max simulator
screenshots at exactly that size.

```sh
xcrun simctl boot <udid> && open -a Simulator
flutter run -d <udid>                       # --release is unsupported on simulators
xcrun simctl io booted screenshot out.png
node tool/asc_screenshots.mjs <versionLocalizationId> shot1.png shot2.png …
```

**Scrub personal data before uploading.** The screenshots come from live
production data. Employees' own profile photos were replaced with the app's
built-in placeholder avatar, and a third party's logo used as an avatar was
painted out. Names and figures were kept — the listing is link-only and the
names are the publishing company's own staff.

## 5. Unlisted distribution

The app is staff-only with no public sign-up, which is what guideline 3.2(f)
is written about. Requesting unlisted distribution is therefore not optional
recovery — it is the plan, and **the order matters**:

1. Review Notes open with a section stating the app is intended for unlisted
   distribution. (The sibling app `Badr Travel Admin` was rejected twice for
   omitting this.)
2. Submit the version for App Review.
3. Only then request unlisted at
   <https://developer.apple.com/contact/request/unlisted-app/> — Apple declines
   the request if the app has not been submitted to review.
4. Wait for Apple's email, 5–7 business days. Change nothing meanwhile.

Once approved, the install link lives in App Store Connect under **Pricing and
Availability**. That link is the only way anyone reaches the app, and it is not
secret — which is why the app issues every account itself.

Availability is set to all 175 territories, not Egypt only. An unlisted app
appears in no search anywhere, so the wider setting costs nothing and avoids
staff with a non-Egyptian Apple Account being unable to open the link.

## 6. What is configured, so you can verify rather than redo

| Concern | State |
|---|---|
| `AppDelegate.swift` | No `FirebaseApp.configure()` — `Firebase.initializeApp()` in Dart handles it, and there is no `GoogleService-Info.plist` in the project. `UNUserNotificationCenter.current().delegate = self` plus `super` forwarding, or notification taps never reach Dart. |
| Entitlements | Per configuration: Debug → `Runner/Runner.entitlements` (`aps-environment: development`), Release and Profile → `Runner/RunnerRelease.entitlements` (`production`). App Store builds are rejected with the development value. |
| Privacy manifest | `ios/Runner/PrivacyInfo.xcprivacy`, referenced by the Runner target and copied by its Resources phase. Empty arrays — Runner hosts the engine and nothing else; pods carry their own. |
| Deployment target | 15.6 in `ios/Podfile` (including the `post_install` loop) and in the Runner configurations. Firebase iOS 12.x will not build below 15. |
| Device family | `TARGETED_DEVICE_FAMILY = 1` — iPhone only, so no iPad screenshot set is demanded. |
| App icon | Generated by `tool/generate_ios_icons.py` from `assets/images/app_launcher_icon.png`, flattened onto white. The set shipped as the **Flutter placeholder** until 2026-09-16; Apple rejects that under 4.3. Icons must have no alpha channel. |
| Usage strings | Camera and photo library only, in Arabic. Microphone, photo-library-add and `UISupportsDocumentBrowser` were removed — the app uses none of them, and unused permission strings invite review questions. |
| Export compliance | `ITSAppUsesNonExemptEncryption = false`. Apple never asks. |
| Legal pages | `web_legal/`, deployed with `firebase deploy --only hosting`, live at <https://pharmacy-employee-system-new.web.app>. Linked in-app below the sign-in form — guideline 5.1.1(i) requires the policy to be reachable *inside* the app. The branch-picker link was removed in 1.2.6; the sign-in one must stay, it is where a reviewer finds it without an account. |
| Force update | `minimum_build_number_ios` on iOS, `minimum_build_number` on Android. The field used to be shared, which would have locked every iPhone user out the moment an Android minimum was set. **Renamed in 1.2.6** from `ios_minimum_build_number`: set the new field in Firestore or iOS force-update stays inert. A missing field reads as 0, so it fails open rather than locking anyone out. |

## 7. Open items

- **APNs key.** Not created yet. Without it iOS receives no push at all — the
  app runs, but the notifications the whole workflow depends on never arrive.
  developer.apple.com → Keys → **+** → Apple Push Notifications service, then
  upload the `.p8` to Firebase → Project settings → Cloud Messaging. The `.p8`
  downloads exactly once, and a team may hold at most two APNs keys.
- **A Firebase Admin service-account private key is hardcoded in
  `lib/core/services/notification_service.dart`.** It is in the shipped Play
  build and now in the iOS build. `--obfuscate` renames identifiers and cannot
  touch string constants, so anyone who unpacks the binary gets full admin
  access to Firestore, Storage and Auth for the whole project — Firestore rules
  do not apply to the Admin SDK. Move sending to a Cloud Function and revoke
  the key in Google Cloud.
- **UIScene migration.** Flutter warns on every build and
  `FLTFirebaseAuthPlugin uses deprecated application lifecycle events`. Not yet
  an error.
- **`rive_native` has no Swift Package Manager support.** A warning today, an
  error in a future Flutter release.
