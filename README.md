# Flood Light

### Report. Respond. Protect.

[![Flutter](https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white)](https://flutter.dev/)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com/)
[![Gemini](https://img.shields.io/badge/Gemini%20AI-4285F4?logo=google&logoColor=white)](https://ai.google.dev/)
[![BuildHybridAI](https://img.shields.io/badge/Hackathon-BuildHybridAI-indigo)](#)

**Flood Light** is a Flutter disaster-response application that helps citizens report flooding hazards and receive AI-assisted guidance, even when internet connectivity is unreliable. It uses Firebase Cloud AI for connected, multimodal reasoning and local/on-device fallback logic for resilient emergency guidance.

> **Hackathon:** #BuildHybridAI Hackathon  
> **Project type:** Mobile application / disaster response / hybrid AI  
> **Primary platform:** Android

---

## Elevator Pitch

**When disasters cut connectivity, Flood Light keeps AI-powered flood reporting and emergency guidance working.**

Citizens capture a hazard photo, automatically attach their GPS location, and receive an AI-generated severity assessment and restoration recommendations. A cloud model provides advanced analysis when connected, while local fallback guidance remains available on unstable or disconnected devices. Submitted reports feed an admin command center where authorities can review severity, location, photo evidence, and suggested actions.

---

## The Problem

Flooding and urban waterlogging require fast, accurate community reporting and coordinated action. However, affected areas frequently experience:

- Mobile data and Wi-Fi outages
- Overloaded emergency communication channels
- Incomplete descriptions of hazards
- Delayed verification and response
- Difficulty sharing precise location and photo evidence

Cloud-only applications can stop working exactly when residents need them most.

---

## The Solution

Flood Light provides a single field-ready workflow:

1. **Capture** — Take a live photo or select an image from the gallery.
2. **Locate** — Automatically collect a high-accuracy GPS position.
3. **Analyze** — Use Gemini through Firebase in cloud-connected conditions.
4. **Fallback** — Preserve emergency guidance through local, on-device logic when network AI is unavailable.
5. **Report** — Submit the analysis, photo, and location to Firebase.
6. **Coordinate** — Review reports in the Admin Command Center and open locations in Google Maps.

The app is designed to reduce the information gap between citizens and authorities during rapidly changing flood conditions.

---

## Hybrid AI Implementation

### Cloud AI mode

When connectivity is available, Flood Light uses:

- Firebase AI Logic SDK
- Gemini 3.8 Flash
- Firebase App Check
- Structured prompts for hazard title, severity, category, description, and suggested actions

The native Android integration in `MainActivity` sends a prompt through Firebase AI and exposes the response and inference source to Flutter through a named Method Channel.

### Hybrid image analysis flow

The image-report flow uses a native Android hybrid method:

```text
Citizen photo
     |
     v
Flutter report workflow
     |
     +--> Precise GPS location
     |
     +--> Native Firebase AI Method Channel
                  |
                  +--> Gemini 3.8 Flash / Firebase hybrid inference
                  |
                  v
        Structured JSON assessment
                  |
                  +--> Severity
                  +--> Hazard category
                  +--> Description
                  +--> Recommended actions
                  |
                  v
     Firebase Storage + Cloud Firestore
```

The native service requests valid JSON and maps the result into a typed `AnalysisResult`. It reports `ON_DEVICE`, `CLOUD`, or `FALLBACK` as source metadata where the platform inference source is available.

### Offline chat mode

The chat screen rechecks network status before every message.

- **Connected:** The app calls the Gemini 3.8 Flash model through `firebase_ai`.
- **Disconnected or cloud request failure:** The app uses `OfflineAiEngine`, a bundled on-device keyword and protocol fallback.
- **Emergency guidance:** Water purification, evacuation, electrical safety, SOS, and generic flood-safety prompts remain accessible.

If the app says **Gemini Nano Edge AI** in the UI, this indicates the product's intended on-device edge mode. In the current source, the chat's offline fallback is an explicit local emergency rule engine rather than a downloaded generative model; the native Firebase AI integration is the implementation responsible for Firebase hybrid inference and inference-source metadata.

---

## Key Features

### Citizen reporting

- Live camera capture
- Gallery image selection
- Photo preview and confirmation
- Automatic high-accuracy location collection
- AI-generated problem title and description
- Severity and hazard categorization
- Restoration and safety suggestions
- Firebase photo and report submission

### Hybrid AI assistant

- Automatic network detection
- Automatic cloud/edge routing
- Clear cloud versus offline source badges
- Quick prompts for common emergencies
- Scrollable chat interface
- Local fallback after cloud failure

### Admin Command Center

- Cloud-synchronized report list
- Filterable issues
- Critical/high and pending counters
- AI analysis details
- Captured image review
- Suggested restoration actions
- Google Maps integration
- AI/cloud versus local/offline source indicator

### Emergency Support

- National and disaster helpline information
- Immediate-danger guidance
- Flood survival steps
- Utility and electrical safety reminders

---

## Application Screens

| Screen | Purpose |
|---|---|
| Splash | App entry and startup |
| Home | Navigate to reporting, chat, admin, and emergency support |
| Camera | Capture or select a hazard image |
| Review | Confirm the selected photo |
| Analysis & Submit | Display AI assessment and submit report |
| Success | Confirm report submission |
| Hybrid Chat | Cloud or offline emergency assistance |
| Admin Dashboard | View and filter community reports |
| Emergency Support | Static safety guidance and helplines |

---

## Architecture

```text
+-----------------------+
| Citizen / Responder   |
| Camera + Location     |
+-----------+-----------+
            |
            v
+-----------------------+
| Flutter / Dart UI     |
| Reporting + Chat      |
+-----------+-----------+
            |
     +------+------+
     |             |
     v             v
+------------+  +---------------------+
| Firebase   |  | On-Device Fallback  |
| Gemini AI  |  | Emergency Protocol  |
| App Check  |  | Local Rule Engine   |
+-----+------+  +----------+----------+
      |                    |
      +---------+----------+
                v
+--------------------------------+
| Firebase Storage / Firestore   |
| Reports, Photos, AI Metadata   |
+----------------+---------------+
                 |
                 v
+--------------------------------+
| Admin Command Center           |
| Filters, Details, Google Maps  |
+--------------------------------+
```

---

## Technology Stack

| Area | Technology |
|---|---|
| Mobile UI | Flutter, Dart |
| Material design | Material 3 / `material_ui` |
| Cloud AI | Firebase AI Logic / Gemini 3.8 Flash |
| Native Android AI bridge | Kotlin, Flutter Method Channels |
| On-device fallback | Local Dart emergency protocol engine |
| Authentication/security | Firebase App Check |
| Database | Cloud Firestore |
| Media storage | Firebase Storage |
| Camera | `camera` and `image_picker` |
| Location | `geolocator` |
| Permissions | `permission_handler` |
| Connectivity | `connectivity_plus` |
| External navigation | `url_launcher` / Google Maps |

---

## Project Structure

```text
lib/
├── main.dart                         # Firebase and App Check startup
├── firebase_options.dart             # Generated Firebase configuration
├── models/
│   └── situation_analysis.dart       # Situation data model
├── services/
│   ├── hybrid_ai_service.dart        # Native hybrid AI bridge
│   ├── offline_ai_engine.dart        # Offline emergency guidance
│   ├── location_service.dart         # GPS handling
│   ├── issue_repository.dart         # Firestore and Storage reports
│   └── admin_ai_service.dart         # Admin AI support
└── screens/
    ├── home_screen.dart
    ├── chat/chat_screen.dart
    ├── report/
    ├── admin/admin_dashboard_screen.dart
    └── support/emergency_support_screen.dart

android/
├── app/google-services.json
└── app/src/main/kotlin/com/example/floodlight/
    └── MainActivity.kt               # Firebase hybrid AI native channel
```

---

## Prerequisites

- Windows, macOS, or Linux
- Flutter SDK with Dart 3.14 or compatible
- Android Studio or Android SDK
- Android device or emulator
- Firebase project
- Firebase AI / Gemini API access enabled for the project
- Google Services configuration
- A configured Firebase App Check provider

Check your environment:

```bash
flutter doctor
flutter --version
```

---

## Setup and Installation

### 1. Clone the repository

```bash
git clone <YOUR_REPOSITORY_URL>
cd floodlight
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Configure Firebase

Install FlutterFire CLI if needed:

```bash
dart pub global activate flutterfire_cli
```

Configure the application:

```bash
flutterfire configure
```

Ensure these services and resources exist in the Firebase project:

- Cloud Firestore
- Firebase Storage
- Firebase AI Logic
- Firebase App Check

The Android application must reference your `google-services.json` from:

```text
android/app/google-services.json
```

> Firebase configuration and API keys in a client application identify the project; they must be combined with appropriate Firebase security rules and App Check enforcement.

### 4. Configure Android permissions

The app requests:

- Camera access
- Fine location access
- Coarse location access

Grant these permissions on the test device.

### 5. Run the application

```bash
flutter run
```

For a release build:

```bash
flutter build apk --release
```

---

## Firebase Configuration

### Cloud Firestore

Reports are written to the `issues` collection. Each document contains:

```text
problemTitle
severity
category
description
suggestedActions
locationTag
latitude
longitude
timestamp
status
photoUrl
isOfflineAi
createdAt
```

### Firebase Storage

Captured photographs are uploaded under:

```text
issue_photos/{issueId}.{extension}
```

The public download URL is stored in the Firestore report.

### Recommended security rules

Before public deployment, add application-specific Firestore and Storage rules. The rules should:

- Restrict writes to authorized users
- Limit accepted image formats and file sizes
- Protect report reads according to citizen/admin roles
- Validate required report fields
- Prefer App Check enforcement where supported
- Restrict direct public modification of status fields

The repository does not include production authentication or role-based authorization for the admin view. The Admin Command Center should not be exposed as an unauthenticated role in a production release.

---

## Demo Instructions

### Demo 1: Complete hazard-report workflow

1. Open the app.
2. Select **Create Issue**.
3. Grant camera permission.
4. Capture a flood or waterlogging photo.
5. Review and confirm the image.
6. Wait for location collection and AI analysis.
7. Review severity, category, description, and actions.
8. Submit the report.
9. Open **Admin Command Center** and find the report.
10. Open the report details and show it in Google Maps.

### Demo 2: Connected cloud AI

1. Connect the device to the internet.
2. Open **Chat with AI**.
3. Ask: `What should I do during a flood?`
4. Show the cloud response and `Gemini 3.8 Flash` source badge.

### Demo 3: Offline fallback

1. Enable airplane mode or disable Wi-Fi and mobile data.
2. Open **Chat with AI**.
3. Ask one of the quick prompts:
   - Purify flood water
   - Nearest high ground
   - Electrical safety
   - SOS SMS template
4. Show the offline source badge and local emergency response.

### Demo 4: Cloud failure fallback

1. Keep the network enabled but force a Gemini request to fail.
2. Send a chat message.
3. Show that the app catches the exception and returns the local emergency fallback.

---

## Testing Checklist

- [ ] Camera captures an image
- [ ] Gallery image selection works
- [ ] Location permission is requested
- [ ] GPS coordinates appear in the analysis
- [ ] Cloud analysis returns valid JSON
- [ ] Cloud failure falls back safely
- [ ] Offline chat responds
- [ ] Report image uploads to Firebase Storage
- [ ] Report is saved in Cloud Firestore
- [ ] Admin dashboard shows submitted reports
- [ ] Severity filters return correct items
- [ ] Google Maps opens the report location
- [ ] App Check works in debug and release configurations

---

## Impact

Flood Light addresses a critical resilience problem: digital emergency tools often disappear or degrade as local infrastructure fails.

Potential benefits include:

- Faster hazard discovery
- More consistent report structure
- Better geotagged evidence for responders
- Lower dependence on manual emergency descriptions
- Immediate safety information for citizens
- Centralized report visibility for municipal teams
- Continued emergency guidance during network disruption

The app is intended as a decision-support system, not a replacement for official emergency services or local authorities.

---

## Responsible AI and Safety

- AI-generated assessments may be incomplete or incorrect.
- Emergency users must verify conditions and follow official alerts.
- The app does not replace 112, 911, local disaster authorities, or professional rescue teams.
- Safety instructions should be reviewed and localized for the target community.
- Location and photos are sensitive information and require clear user consent.
- Production deployments require Firebase rules, authentication, audit logging, and abuse prevention.
- Medical, structural, or public-safety claims should be reviewed by qualified organizations.

---

## Hackathon Highlights

- **Hybrid by design:** The experience continues across connected and disconnected states.
- **Automatic routing:** The user does not manually choose cloud or local behavior.
- **Native Android Firebase integration:** Kotlin uses Firebase AI Logic and inference-source metadata.
- **Flutter end-to-end workflow:** Citizens move from camera to structured report to admin coordination.
- **Real infrastructure:** Firebase is used for AI, App Check, Storage, and Firestore.
- **Offline utility:** Emergency guidance remains accessible when internet AI cannot be reached.
- **Public-value use case:** Flood response has clear safety, social, and operational impact.

---

## Known Limitations

- Android is currently the configured platform.
- The offline chat fallback is a local keyword/protocol engine, not a general-purpose on-device language model.
- The native image flow assumes Firebase AI returns JSON matching the requested schema.
- The admin dashboard loads reports from memory/Firestore and may require a refresh flow in extended use.
- Admin status updates are not yet implemented.
- Authentication and role-based authorization are not present in the demo flow.
- Emergency numbers should be localized before deployment outside the app's target region.
- Report submission currently requires network connectivity because it writes to Firebase Storage and Firestore.

---

## Future Improvements

- True multimodal on-device image analysis through Gemini Nano
- Background report synchronization and offline queueing
- Authenticated citizen and municipal-admin roles
- Real-time report status updates
- Map clustering and flood-severity heat maps
- Multi-language safety guidance
- Push notifications and emergency alerts
- Automatic flood-level and weather integration
- Image verification and duplicate-report detection
- End-to-end encryption and stronger privacy controls
- iOS support and responsive tablet/web layouts
- Verified helpline numbers for each supported region

---

## Team

Add each member's name, role, and contribution before submission:

| Name | Role | Contribution |
|---|---|---|
| [Team Member] | Flutter Developer | Mobile experience and reporting workflow |
| [Team Member] | Firebase/AI Developer | Gemini integration and cloud services |
| [Team Member] | UI/UX Designer | Product experience and visual design |

---

## Submission Links

Add the following before final submission:

- [ ] Public GitHub repository
- [ ] Demo video
- [ ] Presentation/deck
- [ ] APK or test build
- [ ] Test credentials, if applicable
- [ ] Firebase setup instructions
- [ ] Hackathon submission URL

---

## Build

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

---

## Disclaimer

Flood Light is a hackathon prototype for disaster-response research and demonstration. AI output, GPS accuracy, local fallback information, and Firebase availability may vary. Always follow verified government alerts and emergency authority instructions.
