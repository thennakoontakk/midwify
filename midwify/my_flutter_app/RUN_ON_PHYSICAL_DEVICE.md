# Run This Flutter App on a Physical Device

This app is in:

```powershell
c:\Desktop\midwife\midwify\my_flutter_app
```

Android app id: `com.midwify.app`  
Minimum Android version: API 24 (Android 7.0)

## 1. Prerequisites

1. Install Flutter SDK and Android Studio (Android SDK + platform-tools).
2. On your Android phone:
   - Enable **Developer options**
   - Enable **USB debugging**
   - Connect with a data-capable USB cable
   - Accept the RSA trust prompt on the phone
3. On Windows, install your phone OEM USB driver if the device is not detected.

## 2. Open the project

```powershell
cd c:\Desktop\midwife\midwify\my_flutter_app
```

## 3. Install dependencies

```powershell
flutter pub get
```

If `flutter` is not in PATH, run Flutter with its full `flutter.bat` path instead.

## 4. Verify setup and detect device

```powershell
flutter doctor -v
flutter devices
```

You should see your phone listed with a device id (for example `112203741T000658`).

## 5. Run on the physical device

```powershell
flutter run -d <device-id>
```

Example:

```powershell
flutter run -d 112203741T000658
```

## 6. First launch checks

1. Grant camera permission when prompted (this app uses camera/ML features).
2. Wait for the first build; it is usually slower than subsequent runs.

## 7. Useful troubleshooting

```powershell
adb devices
adb kill-server
adb start-server
flutter clean
flutter pub get
flutter run -d <device-id>
```

- If device shows `unauthorized`, reconnect USB and accept the RSA prompt again.
- If no device appears, check cable, USB mode (File Transfer), USB debugging, and OEM driver.
- If install fails for SDK level, use Android 7.0+ device/emulator (project min SDK is 24).

## Firebase note

This project already initializes Firebase through [`lib/firebase_options.dart`](lib/firebase_options.dart).  
If you switch to a different Firebase project, regenerate that file with `flutterfire configure`.
