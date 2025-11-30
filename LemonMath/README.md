# Lemon Math

A magical iOS app that solves handwritten math problems with beautiful animations and detailed explanations.

## Features

### Core Functionality
- **Scan Math Problems**: Point your camera at any handwritten or printed math problem
- **Apple Pencil Support**: Write directly on iPad using Apple Pencil
- **AI-Powered Solutions**: Uses Nano Banana Pro model for accurate problem solving
- **Animated Solutions**: Watch solutions appear with beautiful handwriting animations
- **Step-by-Step Explanations**: Understand the "why" and "how" of every step

### Supported Math Types
- Algebra
- Geometry
- Calculus
- Trigonometry
- Statistics
- Linear Algebra
- Number Theory
- Arithmetic

### UI/UX
- Clean, modern design with soft colors
- Cute magical pen mascot
- Intuitive one-tap controls
- Smooth animations throughout
- Dark/Light mode with animated transitions
- Large text and accessibility support
- Voice guidance option

### Learning Features
- Detailed step-by-step breakdowns
- Alternative solving methods
- Real-world examples
- Interactive graphs and diagrams

### Sharing & Social
- Share solutions as images or PDFs
- Export to Messages, Email, AirDrop
- Challenge friends to solve problems
- Achievement badges and streaks

### Advanced Features
- High-accuracy handwriting recognition
- Multi-language support (English, Greek)
- Offline mode for basic calculations
- Problem history
- Privacy controls
- Fast processing (under 10 seconds)

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Installation

1. Clone the repository
2. Open `LemonMath.xcodeproj` in Xcode
3. Add your Nano Banana Pro API key to the environment
4. Build and run

## Project Structure

```
LemonMath/
├── App/
│   └── LemonMathApp.swift
├── Views/
│   ├── Home/
│   ├── Camera/
│   ├── Solution/
│   ├── Explanation/
│   ├── History/
│   ├── Settings/
│   ├── Onboarding/
│   └── Shared/
├── ViewModels/
├── Models/
│   ├── MathProblem.swift
│   └── Achievement.swift
├── Services/
│   ├── NanoBananaProService.swift
│   ├── SettingsManager.swift
│   ├── HistoryManager.swift
│   └── AchievementManager.swift
├── Utilities/
│   ├── VoiceGuidanceManager.swift
│   └── OfflineModeManager.swift
├── Extensions/
│   └── ViewExtensions.swift
└── Resources/
    ├── LemonMathColors.swift
    └── Localizable/
        ├── en.lproj/
        └── el.lproj/
```

## Configuration

### API Key Setup

Set the `NANO_BANANA_PRO_API_KEY` environment variable or add it to your xcconfig file.

### Privacy Settings

The app respects user privacy with three levels:
- **Minimal**: Basic analytics for app improvement
- **Standard**: No personal data uploaded
- **Maximum**: Full offline mode

## Localization

Currently supported languages:
- English (en)
- Greek (el)

## Accessibility

- VoiceOver support
- Large text option
- Voice guidance for solutions
- Haptic feedback
- High contrast support

## License

Copyright 2024. All rights reserved.
