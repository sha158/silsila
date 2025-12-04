# Attendance Management System

A professional Flutter attendance management app with Firebase backend. The app serves both students and admins through a unified interface with smooth animations and modern UI design.

## Features

### Student Features
- **Device-Bound Login**: One device per student ID with automatic binding
- **Real-Time Class View**: See active classes with passwords 5 minutes before class
- **Quick Attendance**: Mark attendance with class password
- **Attendance History**: View all your attendance records
- **Profile Management**: View device info and student details

### Admin Features
- **Student Management**: Add, view, edit, and delete students
- **Class Management**: Create and manage classes with auto-generated passwords
- **Attendance Tracking**: View attendance records with filters
- **Excel Export**: Export attendance data to Excel spreadsheets
- **Device Control**: Reset device bindings for students
- **Settings**: Manage admin profile and app settings

## Tech Stack

- **Framework**: Flutter 3.x
- **Backend**: Firebase Firestore
- **State Management**: Provider
- **Device ID**: flutter_udid + device_info_plus
- **Excel Export**: excel package
- **Animations**: Lottie, Confetti

## Setup Instructions

### Prerequisites

- Flutter SDK (3.0 or higher)
- Android Studio / VS Code
- Firebase account
- Git

### Installation Steps

1. **Clone the repository**
   ```bash
   git clone <your-repo-url>
   cd silsila_dawrah
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Follow instructions in [FIREBASE_SETUP.md](FIREBASE_SETUP.md)
   - Add `google-services.json` to `android/app/`
   - Create admin account in Firestore
   - Add sample students and classes

4. **Run the app**
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── models/           # Data models (Student, Admin, Class, Attendance)
├── services/         # Business logic (Auth, Firebase, Device, Attendance, Excel)
├── screens/          # UI screens
│   ├── student/      # Student-related screens
│   └── admin/        # Admin-related screens
├── utils/            # Utilities (Constants, Validators, Helpers)
├── widgets/          # Reusable widgets
└── main.dart         # App entry point
```

## Default Credentials

### Admin Login
- **Email**: admin@attendance.com
- **Password**: Admin@123

### Student Login
- **Student ID**: STU001, STU002, etc.
- No password required (device-bound)

## Database Structure

### Collections

#### `students`
```javascript
{
  studentId: "STU001",          // Document ID
  name: "John Doe",
  phoneNumber: "1234567890",
  deviceId: "unique-device-id",
  deviceModel: "Samsung Galaxy",
  isActive: true,
  registeredOn: Timestamp,
  createdAt: Timestamp,
  lastLoginAt: Timestamp
}
```

#### `classes`
```javascript
{
  classId: "auto-generated",
  subjectName: "Mathematics",
  scheduledDate: "2025-12-08",    // YYYY-MM-DD
  startTime: "06:00",             // HH:mm
  endTime: "08:00",
  password: "758392",             // 6-digit code
  passwordActiveFrom: Timestamp,  // 5 min before class
  passwordActiveUntil: Timestamp, // Class end time
  isPasswordActive: true,
  autoGenerate: false,
  createdAt: Timestamp
}
```

#### `attendance`
```javascript
{
  attendanceId: "auto-generated",
  classId: "reference-to-class",
  studentId: "STU001",
  subjectName: "Mathematics",
  markedAt: Timestamp,
  status: "present",
  deviceId: "device-verification"
}
```

#### `admins`
```javascript
{
  adminId: "auto-generated",
  email: "admin@attendance.com",
  password: "Admin@123",
  name: "Super Admin",
  role: "super_admin",
  createdAt: Timestamp
}
```

## Security

### Device Binding
- First login captures device fingerprint
- Subsequent logins verify device match
- Prevents proxy attendance
- Admin can reset device binding if needed

### Firestore Rules
- Students: Read + Update (for device binding)
- Classes: Read only
- Attendance: Read + Create only
- Admins: Read only (managed server-side)

See [firestore.rules](firestore.rules) for complete security rules.

## Features in Detail

### Password System
- 6-digit numeric password per class
- Auto-generated or manually set
- Active 5 minutes before class starts
- Expires when class ends
- Real-time verification

### Attendance Marking
1. Student logs in (device verified)
2. Sees active classes with passwords
3. Enters password to mark attendance
4. System verifies:
   - Password is correct
   - Class is currently active
   - No duplicate attendance
   - Device matches registration
5. Success with confetti animation!

### Excel Export
- Export all attendance records
- Export by class or date range
- Includes student name, ID, subject, date, time
- Auto-saves to Downloads folder
- Shareable via any app

## Customization

### Colors (lib/utils/constants.dart)
```dart
static const Color primary = Color(0xFF1976D2);    // Blue
static const Color secondary = Color(0xFF64B5F6);  // Light Blue
static const Color success = Color(0xFF4CAF50);    // Green
static const Color error = Color(0xFFF44336);      // Red
```

### App Name (lib/utils/constants.dart)
```dart
static const String appName = 'Attendance Management System';
```

## Building for Production

### Android APK
```bash
flutter build apk --release
```

### Android App Bundle (for Play Store)
```bash
flutter build appbundle --release
```

### iOS (requires Mac)
```bash
flutter build ios --release
```

## Testing

### Test Scenarios

1. **Student Login**
   - First-time login (device binding)
   - Subsequent login (auto-login)
   - Wrong Student ID
   - Different device attempt

2. **Mark Attendance**
   - Correct password
   - Wrong password
   - Duplicate attendance
   - Expired class

3. **Admin Functions**
   - Add student
   - Create class
   - View attendance
   - Export to Excel

## Troubleshooting

### Firebase Connection Issues
```bash
flutter clean
flutter pub get
cd android && ./gradlew clean
cd .. && flutter run
```

### Permission Issues (Android)
- Go to App Settings > Permissions
- Enable Storage and all required permissions

### Device ID Issues
- Uninstall and reinstall app
- Check device_info_plus compatibility
- Verify flutter_udid is properly configured

## Future Enhancements

- [ ] Push notifications for class reminders
- [ ] QR code attendance marking
- [ ] Geofencing (verify student is on campus)
- [ ] Biometric authentication
- [ ] Analytics dashboard
- [ ] Parent portal
- [ ] Dark mode
- [ ] Multi-language support

## Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open Pull Request

## License

This project is licensed under the MIT License.

## Support

For issues and questions:
- Create an issue on GitHub
- Email: support@attendance.com

## Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend infrastructure
- All contributors and testers

---

**Built with ❤️ using Flutter**
