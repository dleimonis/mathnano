# Quick Start: Testing Without a Mac

## 🚀 Immediate Testing (Right Now)

### 1. Test Web Version (5 minutes)

**Windows:**
```powershell
cd web
python -m http.server 8000
# Or use the batch script:
.\scripts\test-web.bat
```

**Mac/Linux:**
```bash
cd web
python3 -m http.server 8000
# Or use the shell script:
./scripts/test-web.sh
```

Then open: **http://localhost:8000**

### 2. Push to GitHub for CI/CD (2 minutes)

```bash
git add .
git commit -m "Add testing setup"
git push
```

Check the **Actions** tab in GitHub - it will automatically:
- ✅ Build your iOS app
- ✅ Verify it compiles
- ✅ Run tests (if any)
- ✅ Show any errors

---

## 📱 Full iOS Testing Options

### Option A: Cloud Mac (Recommended for Testing)

**MacStadium** - Rent a Mac for 1-2 days:
1. Sign up at https://www.macstadium.com/orka
2. Get Mac access (~$0.10/hour = $2-5 for a day)
3. Install Xcode
4. Clone your repo
5. Build and test

**Cost**: ~$2-5 for 1-2 days of testing

### Option B: Use Friend's Mac

1. Clone repo on their Mac
2. Open in Xcode
3. Run on simulator
4. Test all features

**Cost**: Free (if you have a friend 😊)

### Option C: TestFlight (After Initial Build)

Once you have a build:
1. Upload to TestFlight
2. Install TestFlight app on iPhone
3. Test on real device
4. Invite beta testers

**Cost**: Free (up to 10,000 testers)

---

## ✅ Testing Checklist

### Web Version (Do This First)
- [ ] API key setup works
- [ ] Image upload works
- [ ] Math solving works
- [ ] Solutions display correctly
- [ ] Error handling works
- [ ] Mobile responsive

### iOS App (When You Get Mac Access)
- [ ] App launches
- [ ] Camera works
- [ ] Photo library works
- [ ] All features work
- [ ] No crashes
- [ ] Settings persist

---

## 🎯 Recommended Path

1. **Now**: Test web version thoroughly
2. **Now**: Push to GitHub, verify CI/CD builds
3. **When ready**: Rent cloud Mac for 1-2 days ($2-5)
4. **Upload to TestFlight**: Get real device testing
5. **Submit to App Store**: After beta feedback

---

## 💡 Pro Tips

- **Web version = 90% of testing**: Same API, same logic
- **CI/CD catches build errors**: Free, automatic
- **Cloud Mac = Full testing**: Only need 1-2 days
- **TestFlight = Real devices**: Best for final testing

---

## 🆘 Troubleshooting

**GitHub Actions failing?**
- Check the Actions tab for error logs
- Fix compilation errors shown

**Web version not working?**
- Check browser console (F12)
- Verify API key is set
- Test with a simple math problem image

**Need help?**
- Check `TESTING_GUIDE.md` for detailed info
- Check `web/TESTING.md` for web-specific tests

