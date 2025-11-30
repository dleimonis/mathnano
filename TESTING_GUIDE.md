# Testing Guide for Lemon Math (Without a Mac)

Since you don't have a Mac, here are practical ways to test your iOS app before App Store submission:

## Option 1: GitHub Actions CI/CD (Recommended - Free)

GitHub Actions can build your iOS app on macOS runners for free (up to 2000 minutes/month).

### What it does:
- ✅ Verifies your code compiles
- ✅ Runs tests automatically
- ✅ Catches build errors before App Store submission
- ✅ Works on every push/PR

### Setup:
1. The workflow is already created at `.github/workflows/ios-build-test.yml`
2. Just push to GitHub - it will run automatically
3. Check the "Actions" tab in your GitHub repo

### Limitations:
- Can't run the simulator interactively
- Can't test UI manually
- Can't test on physical devices

---

## Option 2: Cloud Mac Services (For Full Testing)

### A. MacStadium Orka (Recommended)
- **Cost**: ~$0.10/hour (~$70/month)
- **What you get**: Full macOS VM with Xcode
- **Best for**: Full testing, TestFlight uploads
- **Link**: https://www.macstadium.com/orka

### B. AWS EC2 Mac Instances
- **Cost**: ~$1.00/hour (~$700/month)
- **What you get**: Dedicated Mac mini
- **Best for**: Enterprise, long-term use
- **Link**: https://aws.amazon.com/ec2/instance-types/mac/

### C. MacinCloud
- **Cost**: ~$20-50/month
- **What you get**: Shared Mac access
- **Best for**: Budget-friendly testing
- **Link**: https://www.macincloud.com/

### D. GitHub Codespaces (Limited)
- **Note**: Doesn't support macOS yet, but you can use it for web testing

---

## Option 3: Test the Web Version (Immediate Testing)

The web version (`web/`) uses the same API and logic. Test it thoroughly:

### Run locally:
```bash
cd web
python3 -m http.server 8000
# Open http://localhost:8000
```

### Deploy to test:
- **Netlify** (free): Drag & drop the `web/` folder
- **Vercel** (free): Connect GitHub repo
- **GitHub Pages**: Push to `gh-pages` branch

### What to test:
- ✅ Image upload/processing
- ✅ API calls to Gemini
- ✅ Solution display
- ✅ Step-by-step explanations
- ✅ Alternative methods
- ✅ Error handling
- ✅ Settings/API key management

---

## Option 4: Use a Friend's Mac (Temporary)

If you know someone with a Mac:
1. Clone your repo on their Mac
2. Open `LemonMath.xcodeproj` in Xcode
3. Run on simulator or their iPhone
4. Test all features

---

## Option 5: TestFlight Beta Testing (After Initial Build)

Once you have a build (via cloud Mac or friend's Mac):

1. **Upload to TestFlight**:
   - Build archive in Xcode
   - Upload via Xcode or Transporter app
   - Add beta testers (up to 10,000)

2. **Test on real devices**:
   - Install TestFlight app on iPhone/iPad
   - Get invite link
   - Test on actual hardware

3. **Collect feedback**:
   - TestFlight provides crash reports
   - Beta testers can submit feedback

---

## Recommended Testing Workflow

### Phase 1: Web Testing (Now)
1. Test web version thoroughly
2. Fix any API/logic issues
3. Verify all features work

### Phase 2: Build Verification (CI/CD)
1. Push code to GitHub
2. Let GitHub Actions verify builds
3. Fix compilation errors

### Phase 3: Full iOS Testing (Cloud Mac)
1. Rent MacStadium for 1-2 days ($2-5)
2. Build and test on simulator
3. Upload to TestFlight
4. Test on real iPhone/iPad

### Phase 4: Beta Testing
1. Invite 10-20 beta testers
2. Collect feedback for 1-2 weeks
3. Fix critical issues
4. Submit to App Store

---

## Quick Test Checklist

### Web Version:
- [ ] API key setup works
- [ ] Image upload works
- [ ] Math problem solving works
- [ ] Step-by-step display works
- [ ] Alternative methods show
- [ ] Real-world examples show
- [ ] Error handling works
- [ ] Settings save correctly
- [ ] Mobile responsive design

### iOS App (when you get Mac access):
- [ ] App launches without crashes
- [ ] Camera permission works
- [ ] Photo library access works
- [ ] Image preprocessing works
- [ ] API calls succeed
- [ ] Solutions display correctly
- [ ] History saves/loads
- [ ] Settings persist
- [ ] Dark mode works
- [ ] Localization works (English/Greek)
- [ ] Share functionality works
- [ ] Onboarding flow works

---

## Cost Breakdown

| Method | Cost | Time | Best For |
|--------|------|------|----------|
| Web Testing | Free | Immediate | Logic/API testing |
| GitHub Actions | Free | 5-10 min | Build verification |
| MacStadium (1 day) | ~$2-5 | 1 day | Full iOS testing |
| MacinCloud (monthly) | ~$20-50 | Ongoing | Regular testing |
| AWS EC2 Mac | ~$700/month | Ongoing | Enterprise |

---

## Next Steps

1. **Right now**: Test the web version thoroughly
2. **Push to GitHub**: Let CI/CD verify builds
3. **When ready**: Rent cloud Mac for 1-2 days
4. **Upload to TestFlight**: Get real device testing
5. **Submit to App Store**: After beta testing

---

## Need Help?

- GitHub Actions failing? Check the Actions tab for error logs
- Web version issues? Test in browser console
- Build errors? The CI/CD will show exact errors
- API issues? Test with Postman or curl first

