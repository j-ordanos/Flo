# Flo

A clean, modern, **local-first** personal expense tracker built with Flutter — inspired by Monzo and YNAB.

---

## 🚀 Current Status

The application is in a highly stable, production-ready, feature-complete state with all local and cloud capabilities fully integrated:
*   **Offline-First Relational DB**: Fully implemented using reactive [Drift](file:///home/sam/projects/class/flutter/Flo/lib/core/database/app_database.dart) SQLite tables with automatic migrations and robust local reactive query streams.
*   **Supabase Real-Time Sync**: Production-ready, debounced background synchronization pipeline ([SyncService](file:///home/sam/projects/class/flutter/Flo/lib/features/sync/data/sync_service.dart)) handling two-way updates with offline protection (last-write-wins without clobbering pending local changes).
*   **Offline-to-Online Transaction Migration**: Seamless data migration transaction ([AuthController.onAuthenticated](file:///home/sam/projects/class/flutter/Flo/lib/features/auth/presentation/providers/auth_providers.dart)) that transfers all offline data (`local-user` entries) to a newly authenticated Supabase account upon user sign-in.
*   **Rich Analytics Dashboard**: Fully functional donut and bar charts using [fl_chart](file:///home/sam/projects/class/flutter/Flo/lib/features/analytics/presentation/screens/analytics_screen.dart) supporting custom day/week/month period toggles, top merchant analysis, and CSV reporting export.
*   **Proactive Budgeting Alerts**: Real-time category budget trackers and limit overage push notifications using system-level local notifications ([NotificationService](file:///home/sam/projects/class/flutter/Flo/lib/features/notifications/data/notification_service.dart)).
*   **Declarative Shell Routing**: Indexed navigation shell mapping Home, Analytics, Budgets, and Profile, protected by active auth and onboarding GoRouter redirect guards.

---

## 🛠️ Tech Stack

*   **Framework**: Flutter (Dart 3.11)
*   **State Management & DI**: Riverpod (v3 Notifiers & Providers)
*   **Navigation**: GoRouter (declarative nested navigation shells)
*   **Local Storage**: Drift (reactive SQLite)
*   **Backend & Auth**: Supabase (Postgres database, email/password & Google OAuth authentication)
*   **Analytics & Reporting**: fl_chart & custom CSV export engine
*   **Alerting**: flutter_local_notifications

---

## 🚀 Getting Started

1.  **Install dependencies**:
    ```bash
    flutter pub get
    ```

2.  **Generate code assets** (Freezed, Riverpod, Drift):
    ```bash
    dart run build_runner build --delete-conflicting-outputs
    ```

3.  **Setup environment keys**:
    Copy `env/example.json` to `env/dev.json` and insert your Supabase API credentials:
    ```bash
    cp env/example.json env/dev.json
    ```

4.  **Run the application**:
    ```bash
    flutter run --dart-define-from-file=env/dev.json
    ```

---

## 📁 Project Layout

*   [lib/core](file:///home/sam/projects/class/flutter/Flo/lib/core): Core themes, GoRouter declaration, shared widgets, and core Drift database client.
*   [lib/features](file:///home/sam/projects/class/flutter/Flo/lib/features): Feature-sliced directories separating presentation (screens/widgets), domain (entities/repository contracts), and data (repositories impl/mappers/services).

