# Lemon Math - App Store Submission Checklist

## 1. App Icon

### Requirements
- **Size**: 1024 x 1024 pixels (PNG format)
- **No transparency** (will be auto-rejected)
- **No rounded corners** (iOS adds them automatically)
- **No alpha channel**

### Design Suggestions for Lemon Math
Create an icon featuring:
- A cute lemon character (the mascot)
- A mathematical symbol (∑, π, or √)
- Soft yellow/green gradient background
- Simple, recognizable design

### Where to Place
Save as `AppIcon-1024.png` in:
```
LemonMath/LemonMath/Assets.xcassets/AppIcon.appiconset/
```

### Tools to Create
- **Figma** (free): figma.com
- **Canva** (free): canva.com
- **Adobe Illustrator** (paid)
- **Sketch** (paid, Mac only)

---

## 2. Screenshots

### Required Sizes

| Device | Size (Portrait) | Size (Landscape) |
|--------|-----------------|------------------|
| iPhone 6.9" (15 Pro Max) | 1320 x 2868 | 2868 x 1320 |
| iPhone 6.7" (14 Pro Max) | 1290 x 2796 | 2796 x 1290 |
| iPhone 6.5" (11 Pro Max) | 1242 x 2688 | 2688 x 1242 |
| iPhone 5.5" (8 Plus) | 1242 x 2208 | 2208 x 1242 |
| iPad Pro 12.9" | 2048 x 2732 | 2732 x 2048 |

### Screenshot Ideas (5-10 per device)

1. **Hero Shot**: Main screen with mascot and "Scan Problem" button
2. **Camera Scanning**: Taking a photo of a math problem
3. **Solution Display**: Solved problem with step-by-step explanation
4. **Step-by-Step**: Detailed explanation view
5. **History**: Problem history with search
6. **Settings**: Showing accessibility features
7. **Dark Mode**: Same screens in dark mode
8. **Achievements**: Badge collection screen
9. **Real-World Examples**: Showing practical applications
10. **Multi-language**: Greek language support

### Tips
- Use iOS Simulator (Xcode) to capture screenshots
- Add text captions highlighting features
- Keep consistent style/branding
- Show the most impressive features first

---

## 3. App Store Metadata

### App Name
**Lemon Math - AI Math Solver**
(30 characters max, include keywords)

### Subtitle
**Scan & Solve Any Math Problem**
(30 characters max)

### Keywords (100 characters total)
```
math solver,homework help,equation solver,algebra,calculus,geometry,AI tutor,step by step,greek
```

### Description (4000 characters max)

```
Lemon Math is your magical AI-powered math tutor! Simply take a photo of any handwritten or printed math problem, and watch as our friendly lemon mascot guides you through the solution step by step.

FEATURES:

📸 INSTANT SCANNING
• Point your camera at any math problem
• Works with handwritten and printed equations
• Supports algebra, geometry, calculus, trigonometry & more

🧠 AI-POWERED SOLUTIONS
• Powered by Google Gemini AI
• Accurate step-by-step explanations
• Alternative solving methods shown
• Real-world application examples

🎯 LEARNING FOCUSED
• Understand the "why" behind each step
• Build mathematical intuition
• Track your progress with achievements
• Practice with related problems

♿ ACCESSIBILITY
• Voice guidance for vision impaired users
• Large text support
• Haptic feedback
• Dark mode for comfortable viewing

🌍 MULTI-LANGUAGE
• Full support for English and Greek
• More languages coming soon!

🔒 PRIVACY FIRST
• Your data stays on your device
• Use your own API key
• Offline mode available
• No ads, no tracking

Perfect for:
• Students struggling with homework
• Parents helping kids with math
• Teachers creating lesson plans
• Anyone who wants to understand math better

Download Lemon Math today and make math fun again!
```

### Promotional Text (170 characters)
```
NEW: Now with Google Gemini AI! Solve any math problem instantly with step-by-step explanations. Try it free today!
```

### What's New (4000 characters)
```
Version 1.0 - Initial Release

• AI-powered math problem solving with Google Gemini
• Step-by-step explanations with visual guides
• Camera scanning for handwritten problems
• History tracking and favorites
• Achievement system for motivation
• Dark mode and accessibility features
• English and Greek language support
• Privacy-focused design
```

---

## 4. App Store Connect Setup

### Categories
- **Primary**: Education
- **Secondary**: Utilities

### Age Rating
- **4+** (educational content, no objectionable material)

### Pricing
- **Free** (or choose your price tier)
- Consider In-App Purchases for premium features

### Privacy Labels

#### Data Collected
1. **Photos** (for scanning)
   - Linked to User: No
   - Used for Tracking: No
   - Purpose: App Functionality

2. **Usage Data**
   - Linked to User: No
   - Used for Tracking: No
   - Purpose: Analytics, App Functionality

### Privacy Policy URL
Host your privacy policy at a URL like:
- `https://yourdomain.com/lemonmath/privacy`
- Or use a free service like GitHub Pages

---

## 5. Required Certificates & Profiles

### Apple Developer Account
1. Sign up at developer.apple.com ($99/year)
2. Create App ID: `com.yourcompany.lemonmath`
3. Create Distribution Certificate
4. Create App Store Provisioning Profile

### Steps in Xcode
1. Open project settings
2. Select "LemonMath" target
3. Signing & Capabilities tab
4. Select your team
5. Set bundle identifier
6. Enable "Automatically manage signing"

---

## 6. Build & Upload

### In Xcode
1. Select "Any iOS Device (arm64)"
2. Product → Archive
3. Wait for archive to complete
4. Click "Distribute App"
5. Select "App Store Connect"
6. Follow the prompts

### Or via Command Line
```bash
xcodebuild -scheme LemonMath -configuration Release archive
```

---

## 7. TestFlight (Recommended First)

Before public release:
1. Upload build to App Store Connect
2. Add internal testers (up to 100)
3. Add external testers (up to 10,000)
4. Collect feedback
5. Fix issues
6. Repeat until ready

---

## 8. Final Submission Checklist

- [ ] App icon (1024x1024) created and added
- [ ] All screenshots prepared
- [ ] App name and subtitle finalized
- [ ] Keywords optimized
- [ ] Description written
- [ ] Privacy policy URL live
- [ ] Privacy labels completed
- [ ] Support URL configured
- [ ] Age rating questionnaire completed
- [ ] TestFlight testing done
- [ ] No crashes or major bugs
- [ ] API key instructions clear to users
- [ ] Build uploaded to App Store Connect
- [ ] App Review notes added (if needed)

---

## 9. Common Rejection Reasons to Avoid

1. **Crashes**: Test thoroughly on real devices
2. **Incomplete functionality**: All features must work
3. **Placeholder content**: Remove all "Lorem ipsum" or TODOs
4. **Missing privacy policy**: Must be accessible
5. **Misleading screenshots**: Must match actual app
6. **Guideline 4.2**: App must provide value beyond a website
7. **API issues**: Handle API errors gracefully

---

## 10. After Submission

- Review typically takes 24-48 hours
- Respond quickly to any questions
- Be prepared to make changes
- Plan your launch marketing
- Set up App Store Connect analytics

Good luck with your submission! 🍋
