# Yokai Gacha

A Flutter-based mobile game featuring Japanese yokai creatures, a gacha system, turn-based battles, and local data storage. Built with privacy-first principles and Apple's design guidelines.

## Features

### 🎮 Core Gameplay
- **Turn-based Battle System**: Strategic pet battles with unique abilities
- **Pet Collection**: Collect and upgrade various pet types and rarities
- **Gacha System**: Pull for rare pets with different variants
- **Achievement System**: Track progress and unlock rewards

### 📱 Platform Support
- **iOS**: Native iOS app with Apple design guidelines
- **Android**: Material Design with custom theming
- **Web**: Browser-based version for testing and development

### 🔒 Privacy & Data Protection
- **Local Storage**: All game data stored locally using SharedPreferences
- **Privacy Controls**: Granular consent management
- **Data Export**: GDPR-compliant data export functionality
- **No Tracking**: No analytics or tracking without explicit consent

### 🎨 Design & UX
- **Apple Design Guidelines**: Following iOS Human Interface Guidelines
- **Responsive UI**: Adaptive layouts for different screen sizes
- **Smooth Animations**: Flutter Animate for polished interactions
- **Accessibility**: Screen reader support and high contrast options

## Getting Started

### Prerequisites
- Flutter SDK (>=3.10.0)
- Dart SDK (>=3.0.0)
- Android Studio / Xcode (for mobile development)
- VS Code (recommended for development)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd yokai-gacha
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate code**
   ```bash
   flutter packages pub run build_runner build
   ```

4. **Run the app**
   ```bash
   # For web (testing)
   flutter run -d chrome
   
   # For mobile
   flutter run
   ```

## Project Structure

```
lib/
├── core/
│   ├── models/           # Data models and Hive adapters
│   ├── providers/        # State management (Provider pattern)
│   ├── services/         # Business logic and storage
│   └── theme/           # App theming and design system
├── screens/             # Main app screens
├── widgets/             # Reusable UI components
└── main.dart           # App entry point
```

## Key Components

### Data Models
- **Pet**: Core pet entity with stats, abilities, and variants
- **UserProgress**: Player progression and statistics
- **BattleResult**: Battle outcomes and rewards
- **GachaResult**: Gacha pull results and rewards

### State Management
- **GameProvider**: Core game state and battle logic
- **GachaProvider**: Gacha system and pull mechanics
- **UserProgressProvider**: Player progress and achievements

### Storage
- **StorageService**: SharedPreferences-based local storage
- **PrivacyService**: Privacy controls and data management

## Privacy & Compliance

This app is designed with privacy-first principles:

- **Local Storage Only**: No data leaves your device without consent
- **Granular Controls**: Separate consent for analytics, crash reports, etc.
- **Data Export**: Full GDPR compliance with data export functionality
- **Transparent Policies**: Clear privacy policy and terms of service

## Development

### Code Generation
The project uses code generation for:
- JSON serialization for data models

Run `flutter packages pub run build_runner build` after making changes to models.

### Testing
```bash
# Run tests
flutter test

# Run integration tests
flutter drive --target=test_driver/app.dart
```

### Building for Production

#### iOS
```bash
flutter build ios --release
```

#### Android
```bash
flutter build apk --release
# or for app bundle
flutter build appbundle --release
```

#### Web
```bash
flutter build web --release
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

MIT License - This project is for educational purposes. All original game concepts belong to their respective owners.

## Support

For questions or support, please open an issue on GitHub.

---

**Note**: This is an original game project created for educational purposes, featuring Japanese mythology-inspired yokai creatures.

