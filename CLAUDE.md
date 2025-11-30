# Lemon Math - Claude Code Guide

## Project Overview

Lemon Math is an AI-powered math problem solver that recognizes handwritten math problems from photos and provides step-by-step solutions. The project consists of:

1. **iOS App** (`LemonMath/`) - SwiftUI native app for iOS 17+
2. **Web App** (`web/`) - Vanilla HTML/CSS/JS web version for testing
3. **App Store Assets** (`AppStore/`) - Privacy policy and store preparation materials

## Build & Run Commands

### iOS App (requires macOS with Xcode 15+)
```bash
# Open in Xcode
open LemonMath/LemonMath.xcodeproj

# Or build via command line
cd LemonMath
xcodebuild -scheme LemonMath -destination 'platform=iOS Simulator,name=iPhone 15'

# Run tests
xcodebuild test -scheme LemonMath -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Web App (cross-platform)
```bash
# Using Python (simplest)
cd web
python3 -m http.server 8000
# Then open http://localhost:8000

# Using Node.js
npx serve web

# Using PHP
cd web && php -S localhost:8000
```

## Architecture

### iOS App Structure
```
LemonMath/
├── App/                    # App entry point
│   └── LemonMathApp.swift
├── Views/                  # SwiftUI views
│   ├── Home/              # Main home screen
│   ├── Camera/            # Photo capture & Apple Pencil input
│   ├── Solution/          # Animated solution display
│   ├── Explanation/       # Step-by-step explanations
│   ├── History/           # Problem history
│   ├── Settings/          # Settings & admin dashboard
│   ├── Onboarding/        # Tutorial for first-time users
│   └── Shared/            # Reusable components (mascot, share sheet)
├── Services/              # Core business logic
│   ├── GeminiService.swift      # Google Gemini API integration
│   ├── APIUsageManager.swift    # Rate limiting & quota management
│   ├── SettingsManager.swift    # User preferences
│   ├── HistoryManager.swift     # Problem history storage
│   └── AchievementManager.swift # Gamification/badges
├── Utilities/             # Helper utilities
│   ├── ImagePreprocessor.swift    # Image enhancement for OCR
│   ├── VoiceGuidanceManager.swift # Accessibility
│   └── OfflineModeManager.swift   # Offline capabilities
├── Models/                # Data models
│   ├── MathProblem.swift
│   └── Achievement.swift
├── Extensions/            # Swift extensions
└── Resources/             # Colors, localization
```

### Key Services

#### GeminiService (`Services/GeminiService.swift`)
- Main AI integration using Google Gemini Vision API
- Handles image-to-text recognition for handwritten math
- Returns structured JSON with problem, solution, steps, and alternatives
- Implements retry logic with alternative image preprocessing when confidence is low

#### ImagePreprocessor (`Utilities/ImagePreprocessor.swift`)
- Preprocessing pipeline for handwriting recognition
- Handles variations in slant, spacing, line thickness, lighting
- Creates multiple preprocessing variants for ensemble recognition
- Uses CoreImage filters: noise reduction, edge enhancement, contrast normalization

#### APIUsageManager (`Services/APIUsageManager.swift`)
- Tracks API usage with daily/monthly quotas
- Rate limiting (per minute/hour/day)
- Three subscription tiers: Free (50 req/day), Premium (1000 req/day), Unlimited
- Admin controls for managing quotas

### Web App Structure
```
web/
├── index.html          # Main HTML structure
├── styles.css          # CSS styling (responsive, modern UI)
├── app.js              # JavaScript logic & Gemini API calls
└── privacy-policy.html # Privacy policy page
```

## API Configuration

### Google Gemini API
The app uses Google Gemini Pro Vision API for math problem recognition.

- **Model**: `gemini-1.5-flash` (fast and cost-effective)
- **Endpoint**: `https://generativelanguage.googleapis.com/v1beta/models/`
- **Get API key**: https://aistudio.google.com/apikey

API key storage:
- iOS: Stored in `@AppStorage("gemini_api_key")` (UserDefaults)
- Web: Stored in `localStorage.getItem('gemini_api_key')`

## Supported Math Types
- Algebra (equations, inequalities)
- Geometry (shapes, proofs)
- Calculus (derivatives, integrals)
- Trigonometry
- Statistics
- Linear Algebra
- Number Theory
- Arithmetic

## Localization
- English (en) - default
- Greek (el)

Files: `Resources/Localizable/en.lproj/` and `el.lproj/`

## Important Notes

### Development Environment
- iOS app requires macOS with Xcode 15+
- Web version can be developed/tested on any OS (Windows, Linux, macOS)
- Minimum iOS version: 17.0
- Swift version: 5.9+

### Privacy & Data
- All user data stored locally on device
- Images sent to Google Gemini API for processing only (not stored)
- API keys stored in device's local storage
- No backend servers operated by the app

### Handwriting Recognition Tips
The `ImagePreprocessor` is crucial for good recognition. It:
1. Normalizes lighting and removes color
2. Reduces noise while preserving edges
3. Enhances thin strokes (important for math symbols)
4. Normalizes line thickness
5. Creates multiple variants for retry on low-confidence results

## Code Patterns

### SwiftUI Patterns Used
- `@MainActor` for main thread operations
- `@AppStorage` for persistent user preferences
- `@Observable` (iOS 17 Observation framework)
- `async/await` for all API calls
- `NavigationStack` for navigation

### Common Tasks

**Adding a new math type:**
1. Update `MathProblemType` enum in `Models/MathProblem.swift`
2. Add corresponding prompts in `GeminiService.swift`
3. Update UI in `SolutionView.swift` if special display needed

**Modifying image preprocessing:**
1. Edit `ImagePreprocessor.swift`
2. Adjust `PreprocessingOptions` for different scenarios
3. Test with various handwriting styles

**Adding new API rate limit tier:**
1. Add tier in `APIUsageManager.SubscriptionTier` enum
2. Configure limits in `getRateLimits(for:)` method
3. Update `AdminDashboardView.swift` UI if needed
