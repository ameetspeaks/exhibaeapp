@echo off
echo 🔐 Generating Android App Signing Keystore...
echo.

REM Set keystore details
set KEYSTORE_FILE=android\app\upload-keystore.jks
set KEY_ALIAS=upload
set KEY_PASSWORD=your_key_password
set STORE_PASSWORD=your_store_password

REM Check if keystore already exists
if exist "%KEYSTORE_FILE%" (
    echo ⚠️  Keystore file already exists at: %KEYSTORE_FILE%
    echo    If you want to create a new one, please delete the existing file first.
    pause
    exit /b 1
)

echo 📝 Creating keystore with the following details:
echo    Keystore file: %KEYSTORE_FILE%
echo    Key alias: %KEY_ALIAS%
echo    Key password: %KEY_PASSWORD%
echo    Store password: %STORE_PASSWORD%
echo.

REM Generate the keystore
keytool -genkey -v -keystore "%KEYSTORE_FILE%" -alias "%KEY_ALIAS%" -keyalg RSA -keysize 2048 -validity 10000 -storepass "%STORE_PASSWORD%" -keypass "%KEY_PASSWORD%" -dname "CN=Exhibae, OU=Development, O=Exhibae, L=City, S=State, C=IN"

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ✅ Keystore generated successfully!
    echo 📁 Location: %KEYSTORE_FILE%
    echo.
    echo 🔑 IMPORTANT: Keep this keystore file and passwords secure!
    echo    - Keystore file: %KEYSTORE_FILE%
    echo    - Key alias: %KEY_ALIAS%
    echo    - Key password: %KEY_PASSWORD%
    echo    - Store password: %STORE_PASSWORD%
    echo.
    echo 📋 Next steps:
    echo    1. Update the passwords in android/app/build.gradle if needed
    echo    2. Upload google-services.json to android/app/src/main/
    echo    3. Build your release APK with: flutter build apk --release
) else (
    echo.
    echo ❌ Failed to generate keystore!
    echo    Make sure you have Java JDK installed and keytool is available.
)

pause
