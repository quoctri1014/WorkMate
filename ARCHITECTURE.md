# WorkMate Architecture

## Overview
WorkMate is a smart attendance management application built with Flutter following the **MVVM (Model-View-ViewModel)** architectural pattern. It focuses on high-performance biometric authentication (Face ID) and location-based verification (GPS/WiFi).

## Tech Stack
- **Framework**: Flutter (Dart)
- **State Management**: Provider
- **Local Storage**: Shared Preferences
- **Backend**: Firebase (Auth, Firestore, Storage) - Currently using **MockDataService** for development.
- **Design System**: Custom design tokens (AppColors, AppTextStyles) with a premium "Glassmorphism" aesthetic.

## Folder Structure
- `lib/core/`: Constants, global themes, and utility classes.
- `lib/data/`: Models and Repositories (Data layer).
- `lib/presentation/`: ViewModels and Views (UI layer).
- `assets/`: Lottie animations, images, and fonts.

## Authentication Flow
- **Employee**: Splash -> Onboarding -> Login (Code/OTP/Google) -> Main Navigation.
- **Admin**: Login (Role: Admin) -> Admin Dashboard -> Management Screens.

## Biometric & Location Logic
- **Verification**: Parallel validation of Face ID (Biometrics) and GPS/WiFi (Geofencing).
- **Security**: Data is synced to Firestore only after both validations pass.
