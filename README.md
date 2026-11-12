CleanDrop — On-Demand Blanket Care & Multi-Vendor Laundry AppWalter Sisulu University | Department of Business and Application DevelopmentModule: Application Technology IV (APT 41P2) — 2026 Individual Mobile ProjectDeveloper: Hlokoma Mtshelwane Project OverviewCleanDrop is a native Android multi-vendor mobile marketplace built with Flutter (Dart) and Google Firebase. It connects residents, university students, and working households in the Eastern Cape (tested in KuGompo City / Belgravia and Mthatha Central) with local laundromats and dry cleaners for doorstep collection, heavy winter blanket washing, stain pre-treatment, and tracked delivery.Washing heavy 2-ply winter blankets, mink throws, and duvets in small domestic washing machines often damages drum motors, and indoor drying during wet or cold weather takes days. CleanDrop solves this by offering an Uber Eats–style directory of local laundry hubs, photographic garment condition intake prior to pickup, dynamic 2-hour courier scheduling, and 4-digit security PIN handovers. Quick Links for Assessors & Lecturers Download Installable Android APK (Latest Release) View Full APT 41P2 Technical Documentation (.docx / PDF) Key Mobile Features & Rubric AlignmentMobile FeaturePackage / API UsedImplementation DetailsLive GPS & Street Lookupgeolocator & geocodingDetects real-time device coordinates (e.g., 75 Belgravia Cres, Belgravia, KuGompo City, 5201) and calculates distance in km to nearby shops (Vincent Park CleanDrop Express, Mthatha Central CleanDrop Hub).Interactive OpenStreetMapflutter_map & latlong2Displays interactive pickup zone maps and live polyline courier routes between the laundromat and the customer's door without requiring paid proprietary map keys.Camera Condition & Stain Triageimage_picker & firebase_storageLets customers select blanket materials (Plush Microfibre, Wool, Synthetic, Down), flag pre-existing stains (+R15.00 Mud/Dirt pre-treatment surcharge), and snap photos of care tags/stains.Dynamic Calendar & Schedulingintl (DateTime.now())Generates real upcoming calendar dates dynamically, offers four 2-hour pickup windows, and calculates Standard 48-Hour Return (Free) vs. Express 24-Hour Return (+R45.00).Multi-Method Checkoutcloud_firestoreItemizes base blanket prices (R130.00), stain care (+R15.00), and delivery (R35.00 = R180.00 total) with support for Credit/Debit Card (Stripe), Instant EFT / Ozow, and Cash on Driver Pickup.Driver Telephony & Security PINurl_launcher (tel: / smsto:)Generates a unique 4-digit Handover Security PIN (e.g., PIN: 2293) and provides one-tap phone call and SMS buttons to contact courier Lwazi M. (White Toyota HiAce • EC 492-910).Push Notificationsflutter_local_notificationsFires native Android notification banners upon order confirmation and real-time wash stage updates.Official PDF Tax Invoicepdf & printingGenerates and exports downloadable A4 PDF receipts (#CD-8918, #CD-9048, #CD-9977) directly on the phone. UI Design PaletteDeep Navy (#0F172A): Primary app headers, promotional cards, and sticky checkout bars.Teal (#0D9488): Active selection borders, verified badges, and route polylines.Cyan / Mint Accent (#06B6D4 / #6EE7B7): Active bottom navigation pills, action buttons, and price highlights.Slate (#64748B): Secondary labels, timestamps, and subtitles.Dark Theme Support: Built-in light/dark mode toggle inside the Profile tab. Modular Code ArchitectureThe project separates UI screens, domain models, and theme/notification logic inside lib/:cleandrop/
├── android/
│   └── app/src/main/AndroidManifest.xml   # GPS, Camera, Notification & Dialer permissions
├── lib/
│   ├── main.dart                          # App entry, Firebase init & AuthGate stream
│   ├── theme/
│   │   └── app_theme.dart                 # Color tokens, Light/Dark themes & local push alerts
│   ├── models/
│   │   └── laundry_models.dart            # LaundromatVendor, ServiceCatalogItem & BasketLineItem
│   └── screens/
│       ├── auth_screen.dart               # Firebase Email/Password login & phone number sync
│       ├── main_navigation_shell.dart     # 4-tab shell, live GPS lookup & vendor search
│       ├── blanket_customizer_screen.dart # Fabric selector, +R15 stain logic & camera intake
│       ├── schedule_service_screen.dart   # Pickup map pin, dynamic dates & 2hr time slots
│       ├── order_summary_payment_screen.dart # Itemized invoice & Stripe/Ozow/Cash checkout
│       ├── live_tracking_tab.dart         # Live route map, Handover PIN & driver call/SMS
│       ├── orders_receipts_tab.dart       # Firestore order history & A4 PDF receipt generator
│       └── profile_settings_tab.dart      # Customer phone sync, GPS refresh & dark mode toggle
├── pubspec.yaml                           # Project dependencies
└── README.md                              # Project documentation

How to Run the Project LocallyPrerequisitesFlutter SDK: >=3.9.0 <4.0.0Android Studio (with Android SDK 35 & an Android Emulator or physical Android device)Firebase Project (google-services.json placed in android/app/)Installation StepsClone the repository:git clone https://github.com/YOUR_GITHUB_USERNAME/CleanDrop-APT41P2.git
cd CleanDrop-APT41P2
Install dependencies:flutter pub get
Run on a connected Android device or emulator:flutter run
Build a release APK (optional):flutter build apk --release

Firebase Security RulesEnsure Email/Password Authentication, Cloud Firestore, and Firebase Storage are enabled in your Firebase Console with the following Firestore rules:rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /laundromats/{vendorId} {
      allow read, write: if request.auth != null;
    }
    match /orders/{orderId} {
      allow read, write: if request.auth != null;
    }
  }
}
Academic DeclarationSubmitted in partial fulfilment of the requirements for Application Technology IV (APT 41P2) at Walter Sisulu University (2026).
