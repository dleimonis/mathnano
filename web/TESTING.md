# Web Version Testing Guide

Test the web version thoroughly before iOS testing. It uses the same API and logic.

## Quick Start

```bash
cd web
python3 -m http.server 8000
# Open http://localhost:8000 in your browser
```

## Test Scenarios

### 1. API Key Setup
- [ ] Enter API key
- [ ] Key saves to localStorage
- [ ] Key persists after refresh
- [ ] Invalid key shows error
- [ ] Settings modal updates key

### 2. Image Upload
- [ ] Camera capture works (mobile)
- [ ] File upload works (desktop)
- [ ] Image preview displays
- [ ] Clear button works
- [ ] Invalid file types rejected

### 3. Problem Solving
- [ ] Upload math problem image
- [ ] Loading state shows
- [ ] Solution displays correctly
- [ ] Confidence badge shows
- [ ] Problem type identified
- [ ] Steps display properly
- [ ] Alternative methods show (if enabled)
- [ ] Real-world examples show (if enabled)

### 4. Error Handling
- [ ] Network error handled
- [ ] Invalid API key error
- [ ] Rate limit error
- [ ] Invalid image error
- [ ] Parse error handled

### 5. Settings
- [ ] Language changes work
- [ ] Alternative methods toggle
- [ ] Real-world examples toggle
- [ ] Settings persist
- [ ] Clear data works

### 6. Mobile Testing
- [ ] Responsive on phone
- [ ] Touch interactions work
- [ ] Camera access works
- [ ] Keyboard doesn't cover inputs
- [ ] Buttons are tappable

## Test Images

Create test images with:
- Clear handwriting
- Faint handwriting (test preprocessing)
- Blurry image (test error handling)
- Different math types (algebra, geometry, etc.)
- Greek text (if testing localization)

## Browser Testing

Test in:
- [ ] Chrome (desktop)
- [ ] Firefox (desktop)
- [ ] Safari (desktop)
- [ ] Chrome (mobile)
- [ ] Safari (mobile iOS)

## Performance

- [ ] Page loads quickly
- [ ] API calls complete in < 10 seconds
- [ ] Images compress properly
- [ ] No memory leaks on repeated use

## Accessibility

- [ ] Keyboard navigation works
- [ ] Screen reader compatible
- [ ] High contrast readable
- [ ] Text scales properly

