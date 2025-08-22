# App Signing Setup Guide

This guide will help you set up app signing for the Exhibae Android app and configure Google Services.

## 🔐 Step 1: Generate Keystore

### Option A: Using the provided script (Recommended)
```bash
# Make the script executable
chmod +x generate_keystore.sh

# Run the script
./generate_keystore.sh
```

### Option B: Manual keystore generation
```bash
keytool -genkey -v \
    -keystore android/app/upload-keystore.jks \
    -alias upload \
    -keyalg RSA \
    -keysize 2048 \
    -validity 10000 \
    -storepass your_store_password \
    -keypass your_key_password \
    -dname "CN=Exhibae, OU=Development, O=Exhibae, L=City, S=State, C=IN"
```

## 📱 Step 2: Upload google-services.json

### 2.1 Get google-services.json from Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project (or create a new one)
3. Click on the gear icon ⚙️ next to "Project Overview"
4. Select "Project settings"
5. Scroll down to "Your apps" section
6. Click "Add app" and select Android
7. Enter your package name: `com.ameetpandey.exhibae`
8. Download the `google-services.json` file

### 2.2 Place the file in the correct location

Upload the `google-services.json` file to:
```
android/app/src/main/google-services.json
```

### 2.3 Verify the file structure
Your project should now have:
```
android/
├── app/
│   ├── src/
│   │   └── main/
│   │       ├── google-services.json  ← Upload here
│   │       ├── AndroidManifest.xml
│   │       └── ...
│   ├── upload-keystore.jks          ← Generated keystore
│   ├── build.gradle
│   └── proguard-rules.pro
└── build.gradle
```

## 🔧 Step 3: Update Passwords (Optional)

If you want to use different passwords than the defaults, update them in `android/app/build.gradle`:

```gradle
signingConfigs {
    release {
        keyAlias = "upload"
        keyPassword = "your_actual_key_password"
        storeFile = file("upload-keystore.jks")
        storePassword = "your_actual_store_password"
    }
}
```

## 🚀 Step 4: Build Release APK

### Build the signed APK:
```bash
flutter build apk --release
```

### Build App Bundle (for Google Play Store):
```bash
flutter build appbundle --release
```

## 📋 Important Notes

### 🔑 Security
- **NEVER commit your keystore file to version control**
- Keep your keystore passwords secure
- Store a backup of your keystore file in a safe location
- If you lose your keystore, you won't be able to update your app on Google Play Store

### 📁 Files to add to .gitignore
Make sure these files are in your `.gitignore`:
```
android/app/upload-keystore.jks
android/app/src/main/google-services.json
```

### 🔍 Verify the setup
After uploading `google-services.json`, you should see:
- No build errors related to Google Services
- Firebase services working in your app
- Successful release builds

## 🛠️ Troubleshooting

### Common Issues:

1. **"google-services.json not found"**
   - Make sure the file is in `android/app/src/main/google-services.json`
   - Check file permissions

2. **"Keystore not found"**
   - Run the keystore generation script again
   - Check the file path in `build.gradle`

3. **"Invalid keystore format"**
   - Make sure you're using the correct keystore file
   - Verify the passwords match

4. **Build fails with ProGuard errors**
   - Check the `proguard-rules.pro` file
   - Add specific rules for any third-party libraries

## 📞 Support

If you encounter any issues:
1. Check the build logs for specific error messages
2. Verify all files are in the correct locations
3. Ensure all passwords and aliases match

---

**Next Steps:**
1. ✅ Generate keystore
2. ✅ Upload google-services.json
3. ✅ Build release APK
4. 🎉 Deploy to Google Play Store!
