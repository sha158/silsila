# Firebase Setup Instructions

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add Project"
3. Enter project name: `attendance-management-system`
4. Disable Google Analytics (optional)
5. Click "Create Project"

## Step 2: Add Android App

1. Click on the Android icon in Firebase Console
2. Enter Android package name: `com.example.silsila_dawrah`
3. Download `google-services.json`
4. Place the file in: `android/app/google-services.json`

## Step 3: Configure Android

### 3.1 Edit `android/build.gradle`
Add this to the dependencies section:
```gradle
dependencies {
    classpath 'com.google.gms:google-services:4.3.15'
}
```

### 3.2 Edit `android/app/build.gradle`
Add at the bottom of the file:
```gradle
apply plugin: 'com.google.gms.google-services'
```

Also, ensure minSdkVersion is at least 21:
```gradle
android {
    defaultConfig {
        minSdkVersion 21
    }
}
```

## Step 4: Enable Firestore

1. In Firebase Console, go to "Firestore Database"
2. Click "Create Database"
3. Select "Start in test mode" (we'll add rules later)
4. Choose a location close to your users
5. Click "Enable"

## Step 5: Add Firestore Security Rules

Go to Firestore Database > Rules and paste:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /admins/{adminId} {
      allow read: if true;
      allow write: if false;
    }
    match /students/{studentId} {
      allow read: if true;
      allow update: if true;
      allow create, delete: if false;
    }
    match /classes/{classId} {
      allow read: if true;
      allow write: if false;
    }
    match /attendance/{attendanceId} {
      allow read: if true;
      allow create: if true;
      allow update, delete: if false;
    }
  }
}
```

Click "Publish"

## Step 6: Create Initial Admin Account

1. Go to Firestore Database > Data
2. Click "Start Collection"
3. Collection ID: `admins`
4. Document ID: Click "Auto-ID"
5. Add fields:
   - `email`: `admin@attendance.com` (string)
   - `password`: `Admin@123` (string)
   - `name`: `Super Admin` (string)
   - `role`: `super_admin` (string)
   - `createdAt`: Click "Add field" > Select timestamp > Use current timestamp

## Step 7: Add Sample Students (Optional)

1. Create collection: `students`
2. Create document with ID: `STU001`
3. Add fields:
   - `name`: `John Doe` (string)
   - `phoneNumber`: `1234567890` (string)
   - `deviceId`: `null` (null)
   - `deviceModel`: `null` (null)
   - `isActive`: `true` (boolean)
   - `registeredOn`: `null` (null)
   - `createdAt`: Current timestamp
   - `lastLoginAt`: `null` (null)

Repeat for more students with IDs: STU002, STU003, etc.

## Step 8: Add Sample Class (Optional)

1. Create collection: `classes`
2. Click "Add Document" (Auto-ID)
3. Add fields:
   - `subjectName`: `Mathematics` (string)
   - `scheduledDate`: `2025-12-08` (string) - YYYY-MM-DD format
   - `startTime`: `06:00` (string) - HH:mm format
   - `endTime`: `08:00` (string)
   - `password`: `758392` (string) - 6 digits
   - `passwordActiveFrom`: Timestamp - Set to 5 min before class
   - `passwordActiveUntil`: Timestamp - Set to end time
   - `isPasswordActive`: `true` (boolean)
   - `autoGenerate`: `false` (boolean)
   - `createdAt`: Current timestamp

**Important:** Make sure `passwordActiveFrom` and `passwordActiveUntil` are within the current time for testing!

## Step 9: Enable Storage Permissions (Android)

Edit `android/app/src/main/AndroidManifest.xml` and add:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>

    <!-- For Android 11+ -->
    <uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE"/>

    <application
        android:requestLegacyExternalStorage="true"
        ...
    </application>
</manifest>
```

## Step 10: Run the App

```bash
flutter clean
flutter pub get
flutter run
```

## Testing the App

### Test Student Login:
1. Click "Student Login"
2. Enter: `STU001`
3. First login will bind your device
4. You should see active classes if any exist

### Test Admin Login:
1. Click "Admin Login"
2. Email: `admin@attendance.com`
3. Password: `Admin@123`
4. Access admin dashboard

### Test Attendance:
1. Login as student
2. See active class with password
3. Click "Mark Attendance"
4. Enter the password shown
5. See success animation!

## Troubleshooting

### Firebase not connecting:
- Ensure `google-services.json` is in correct location
- Check package name matches in Firebase Console
- Run `flutter clean && flutter pub get`

### Firestore permission errors:
- Check security rules are published
- Verify rules allow read/write as specified

### Device binding not working:
- Check device_info_plus and flutter_udid are installed
- For iOS, ensure proper permissions in Info.plist

### Excel export not working:
- Grant storage permissions in Android settings
- Check `MANAGE_EXTERNAL_STORAGE` permission for Android 11+

## Production Checklist

Before deploying to production:

1. ✅ Update Firestore security rules with proper authentication
2. ✅ Remove test mode from Firebase
3. ✅ Add proper error logging
4. ✅ Enable Firebase Authentication for admins
5. ✅ Set up backup strategy for Firestore data
6. ✅ Configure proper Android signing
7. ✅ Test on multiple devices
8. ✅ Add push notifications (optional)
9. ✅ Set up CI/CD pipeline
10. ✅ Create privacy policy and terms of service
