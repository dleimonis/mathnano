# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

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

### Core Data Flow
1. User captures/uploads image of handwritten math problem
2. `ImagePreprocessor` normalizes the image (lighting, contrast, noise reduction)
3. `GeminiService` sends image to Google Gemini Vision API with specialized prompts
4. API returns structured JSON: problem text, solution, step-by-step explanation
5. If confidence < 0.7, system retries with alternative preprocessing variants
6. Results displayed with animated handwriting effect in `SolutionView`

### Key Services

- **GeminiService** (`Services/GeminiService.swift`) - Google Gemini Vision API integration with retry logic
- **ImagePreprocessor** (`Utilities/ImagePreprocessor.swift`) - CoreImage pipeline for handwriting normalization (handles slant, spacing, line thickness variations)
- **APIUsageManager** (`Services/APIUsageManager.swift`) - Rate limiting and quota management with three tiers (Free: 50/day, Premium: 1000/day, Unlimited)

### API Configuration

- **Model**: `gemini-1.5-flash`
- **Endpoint**: `https://generativelanguage.googleapis.com/v1beta/models/`
- **API key storage**: iOS uses `@AppStorage("geminiAPIKey")`, Web uses `localStorage`
- **Get API key**: https://aistudio.google.com/apikey

### Admin Dashboard Access
The Admin Dashboard for managing API quotas is hidden from regular users. Access it by:
1. Long-press the Version number in Settings for 3 seconds, OR
2. If previously authenticated, the button appears in the API Usage section

### Localization
English (en) and Greek (el) - files in `Resources/Localizable/`

### Development Notes
- iOS app requires macOS with Xcode 15+ and iOS 17.0+ target
- Web version can be developed/tested on any OS
- Swift 5.9+ with iOS 17 Observation framework (`@Observable`)
- All API calls use `async/await`
