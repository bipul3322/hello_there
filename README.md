# Hello There Calling App

A Flutter-based real-time audio/video calling app foundation, built from
scratch with Firebase as the backend. Focused on a fully functional
demo-scale foundation — auth, contacts, and a real signaling/call
lifecycle — with the actual audio/video engine left as a clean
integration point for a future RTC SDK.

## Tech Stack

- **Flutter** — UI framework
- **Firebase Authentication** — email/password login
- **Cloud Firestore** — user profiles, contacts, call logs, and
  real-time call signaling
- **Riverpod** — state management
- **go_router** — navigation and route protection
- **permission_handler** — runtime microphone/camera permissions

## Features

- **Authentication** — register, log in, log out, with automatic
  redirect based on auth state.
- **Home shell** — bottom navigation (Contacts / Recent), a search
  bar, and a speed-dial FAB for adding a contact or placing a quick
  call.
- **Contacts** — added by searching another user's unique username
  (not a phone number). Tap a contact's avatar to view/edit/delete;
  tap the row body to reveal inline Audio/Video call buttons.
- **Recent calls (Call Log)** — shows call history with direction
  (incoming/outgoing/missed) and call type. Tap a row body to redial
  with an inline Audio/Video choice.
- **Real-time call signaling** — calls are modeled as documents in a
  Firestore `calls` collection (`ringing` → `accepted`/`declined` →
  `ended`), so ringing, accept/decline, and the ongoing call screen
  work live across two separate devices, independent of the RTC
  engine.
- **Call screen** — shows connection state, a live duration timer,
  and mute/speaker/end-call controls. Un-answered calls automatically
  time out after 30 seconds and log as missed.
- **Call log writing** — every call writes a log entry to both the
  caller's and callee's history, including missed/declined/timed-out
  calls.
- **Profile** — view mode shows name, unique username, and bio, with
  an Edit toggle to a form (including username-uniqueness validation)
  and a Log Out button.
- **Permissions** — microphone (and camera, for video) permission is
  requested before a call starts, with a graceful path to Settings if
  permanently denied.

## Known Limitations

- **No real audio/video yet.** The call screen's "connected" state is
  currently a simulated timer, not a live media stream. An RTC SDK
  integration (Agora) was attempted but reverted after persistent,
  unresolved local Windows/Gradle build issues unrelated to the app's
  own code; the call data model (`callId` as a ready-made
  channel/room name) is already structured to plug a real SDK in
  later.
- **No push notifications.** Incoming calls only ring while the
  recipient's app is open, since call signaling relies on a live
  Firestore listener rather than FCM (deferred to stay within
  Firebase's free tier, which requires no billing plan for
  Auth/Firestore but does for Cloud Functions).
- **No profile photo upload.** Deferred in favor of the app's other
  functional priorities.
- **Single-region tested.** Verified across two Android emulators /
  devices on the same developer's network; not load- or scale-tested.

## Project Structure

```
lib/
├── main.dart
├── core/
│   ├── permissions/       # mic/camera permission handling
│   ├── routing/           # go_router config + auth redirect
│   └── widgets/           # shared UI (CallableListItem, etc.)
├── features/
│   ├── auth/               # login, register, auth service/providers
│   ├── home/                # HomeShell: tabs, search bar, FAB
│   ├── contacts/            # contact list, detail/edit, add-by-username
│   ├── call_logs/           # recent calls list + model
│   ├── calls/                # call signaling, call screen, incoming call
│   └── profile/             # profile view/edit
```

## Firestore Data Model

```
usernames/{username}              → { uid }
users/{uid}                       → { name, username, bio, email, ... }
users/{uid}/contacts/{contactId}  → { uid, name, username, photoUrl, addedAt }
users/{uid}/callLogs/{logId}      → { contactId, contactName, type, direction,
                                        timestamp, durationSeconds }
calls/{callId}                    → { callerId, callerName, calleeId, calleeName,
                                        type, status, createdAt }
```

## Setup

1. **Install Flutter** and confirm `flutter doctor` is clean.
2. **Create a Firebase project** at [console.firebase.google.com](https://console.firebase.google.com),
   enable **Authentication → Email/Password** and **Firestore Database**.
3. **Connect the project:**
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
4. **Install dependencies:**
   ```bash
   flutter pub get
   ```
5. **Publish the Firestore security rules** (see `firestore.rules`
   section below) via the Firebase console's Rules tab.
6. **Run:**
   ```bash
   flutter run
   ```

## Firestore Security Rules

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    match /usernames/{username} {
      allow read: if true;
      allow write: if request.auth != null;
    }

    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;

      match /contacts/{contactId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }

      match /callLogs/{logId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }

    match /calls/{callId} {
      allow read: if request.auth != null &&
        (request.auth.uid == resource.data.callerId || request.auth.uid == resource.data.calleeId);
      allow create: if request.auth != null && request.auth.uid == request.resource.data.callerId;
      allow update: if request.auth != null &&
        (request.auth.uid == resource.data.callerId || request.auth.uid == resource.data.calleeId);
    }

  }
}
```

## Testing the Call Flow

Real-time signaling can be tested across two devices (two emulators,
or an emulator + a physical device) logged into two different test
accounts that have added each other as contacts:

1. Run the app on both devices.
2. From one device, tap a contact to place a call.
3. The other device should ring live via the incoming-call screen,
   with working Accept/Decline.
4. Both sides' Recent tab will show the resulting call log entry.