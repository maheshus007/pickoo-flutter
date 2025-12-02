# Pickoo AI - Photo Editing App

🎨 AI-powered photo editing application built with Flutter

## Features

- ✨ Auto Enhance
- 🖼️ Background Removal
- 👤 Face Retouch
- 🧹 Object Eraser
- 🌅 Sky Replacement
- 🔍 Super Resolution
- 💳 Google Play In-App Purchases
- 📊 Subscription Management

## Tech Stack

- **Framework**: Flutter 3.24.0
- **State Management**: Riverpod
- **Backend**: FastAPI (Python)
- **Database**: MongoDB
- **AI Processing**: Google Gemini API
- **Payments**: Google Play Billing, Stripe

## Getting Started

### Prerequisites

- Flutter SDK 3.24.0 or higher
- Dart SDK
- Android Studio / Xcode
- Backend API running

### Installation

```bash
# Clone the repository
git clone https://github.com/maheshus007/pickoo-flutter.git

# Navigate to project
cd pickoo-flutter

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Configuration

Create a `.env` file or configure dart-defines:

```bash
flutter run --dart-define=BACKEND_URL=your_backend_url
```

## CI/CD

Automated build and deployment pipeline using GitHub Actions:
- Automatic builds on push to main/develop
- Deploy to Google Play Store (internal testing)
- Manual deployment workflow available

See `.github/workflows/README.md` for setup instructions.

## Project Structure

```
lib/
├── models/          # Data models
├── providers/       # Riverpod providers
├── screens/         # UI screens
├── services/        # API services
├── utils/           # Utilities
└── widgets/         # Reusable widgets
```

## License

Proprietary - All rights reserved

## Contact

**Developer**: Mahesh U S  
**Repository**: https://github.com/maheshus007/pickoo-flutter

---

**Version**: 1.0.0  
**Last Updated**: November 18, 2025

