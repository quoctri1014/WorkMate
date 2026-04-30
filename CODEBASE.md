# WorkMate Codebase Map

## Core Dependencies
- `lib/core/constants/app_colors.dart` -> Global color palette and gradients.
- `lib/core/constants/app_routes.dart` -> Navigation routing table.
- `lib/core/utils/date_utils.dart` -> Vietnamese date/time formatting logic.

## Data Layer
- `lib/data/models/models.dart` -> All entities (User, Attendance, Leave, etc.).
- `lib/data/repositories/mock_data.dart` -> Centralized mock database for the entire app.

## Presentation Layer (MVVM)
- **ViewModels** (`lib/presentation/viewmodels/`):
    - `auth_viewmodel.dart` -> Logic for Login/Logout/OTP.
    - `viewmodels.dart` -> Unified ViewModels for features (Attendance, Leave, OT).
- **Views** (`lib/presentation/views/`):
    - `home/`: Dashboard and Navigation.
    - `attendance/`: Face ID, GPS Verification, Supplement requests.
    - `leave/`: Request form, History, Details.
    - `overtime/`: OT registration and tracking.
    - `profile/`: Account settings, Bank, QR, Seniority.
    - `admin/`: Management dashboard and approval flows.

## Global Entry
- `lib/main.dart`: Provider registration and Material App configuration.
