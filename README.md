# Campus Digital Twin AI

A smart campus management application built with Flutter. The aim of this project is to bring different college-related activities and information into one place, making it easier for students, teachers, HODs and administrators to access the features they need.

The application includes separate screens for academic activities, attendance, timetable, library, canteen, notices, events and other campus-related modules. It also includes Firebase-based authentication, role-based access and an AI assistant integration.

## About the Project

Managing different college activities through separate systems can be difficult. Students may need to check their attendance in one place, find timetable information somewhere else and contact different departments for academic updates.

Campus Digital Twin AI is an attempt to make these activities accessible through a single application.

The application is designed around different user roles. Based on the logged-in user's role, the application provides access to relevant sections and functionalities.

The project is being developed using Flutter and Firebase, with a focus on a simple interface and a modular structure.

## Main Features

### 1. Role-Based Login

The application supports different user roles:

* Student
* Teacher
* HOD
* Principal

Authentication is handled using Firebase Authentication. After login, the application retrieves the user's profile and role from Cloud Firestore.

Access permissions are determined according to the user's role.

### 2. Student Dashboard

The student section includes screens and modules for accessing academic and campus-related information.

Available modules include:

* Dashboard
* Attendance
* Timetable
* Examination
* Fees
* Library
* Canteen
* Hostel
* Events
* Notices
* Notifications
* Digital ID
* Profile and Settings

### 3. Teacher Section

The project includes teacher-related screens for academic and classroom activities.

* My Teaching
* Class Environment

### 4. HOD Section

The HOD section includes screens for academic management.

* Subject Management
* Teacher Assignment

### 5. Administration

The project includes an Admin Panel screen for administrative activities.

### 6. AI Assistant

The application includes an AI Assistant screen connected to Google's Gemini API.

The assistant is intended to help with campus-related questions, academics, timetable information, attendance, library-related queries and general questions.

The Gemini integration currently uses the `gemini-2.5-flash` model through an HTTP API request.

**Note:** A valid Gemini API key must be configured before AI responses can work. The API key should not be exposed in a publicly distributed application.

### 7. Campus Map

The project includes a Map screen and uses the Google Maps Flutter package for map-related functionality.

### 8. Search and Analytics

The application also includes:

* Global Search
* Analytics Dashboard
* Placement Dashboard

These screens provide a foundation for accessing and presenting different types of campus information.

### 9. Theme Support

The application supports light and dark themes.

Theme handling is managed through a separate `ThemeController`.

### 10. Multiple Language Support

The application declares support for:

* English
* Hindi
* Marathi

## Technologies Used

The project is built using the following technologies and packages.

| Technology              | Purpose                           |
| ----------------------- | --------------------------------- |
| Flutter                 | Application development           |
| Dart                    | Programming language              |
| Firebase Authentication | User authentication               |
| Cloud Firestore         | User profile and application data |
| Firebase Core           | Firebase initialization           |
| Firebase Storage        | Storage integration dependency    |
| Google Gemini API       | AI assistant integration          |
| Google Maps Flutter     | Map-related functionality         |
| Google Fonts            | Application typography            |
| Shared Preferences      | Local preference storage          |
| FL Chart                | Charts and analytics              |
| Mobile Scanner          | QR and barcode scanning           |
| QR Flutter              | QR code generation                |
| Speech To Text          | Speech recognition integration    |
| Google Sign-In          | Sign-in integration dependency    |
| Geolocator              | Location-related functionality    |
| Image Picker            | Image selection                   |
| Share Plus              | Sharing integration               |
| HTTP                    | API communication                 |

The packages listed above are project dependencies. Their presence in `pubspec.yaml` does not necessarily mean every package is already connected to a completed application feature.

## Project Structure

The project follows a modular structure, with screens, services, models and role-specific sections organized inside the `lib` directory.

```text
campus_digital_twin_ai/
│
├── android/
├── ios/
├── linux/
├── macos/
├── web/
├── windows/
│
├── lib/
│   │
│   ├── academic_class_model.dart
│   ├── academic_year_model.dart
│   ├── admin_panel_screen.dart
│   ├── ai_screen.dart
│   ├── analytics_dashboard.dart
│   ├── attendance_screen.dart
│   ├── canteen_screen.dart
│   ├── dashboard_screen.dart
│   ├── digital_id_screen.dart
│   ├── drawer_widget.dart
│   ├── dummy_users.dart
│   ├── edit_profile_screen.dart
│   ├── events_screen.dart
│   ├── examination_screen.dart
│   ├── fees_screen.dart
│   ├── global_search_screen.dart
│   ├── hostel_screen.dart
│   ├── library_screen.dart
│   ├── login_screen.dart
│   ├── main.dart
│   ├── map_screen.dart
│   ├── notice_screen.dart
│   ├── notification_screen.dart
│   ├── permission_model.dart
│   ├── placement_dashboard_screen.dart
│   ├── profile_screen.dart
│   ├── settings_screen.dart
│   ├── splash_screen.dart
│   ├── subject_assignment_model.dart
│   ├── subject_model.dart
│   ├── teaching_context.dart
│   ├── theme_controller.dart
│   ├── timetable_model.dart
│   ├── timetable_screen.dart
│   ├── user_model.dart
│   ├── user_role.dart
│   │
│   ├── services/
│   │   ├── academic_class_service.dart
│   │   ├── academic_year_service.dart
│   │   ├── ai_command_service.dart
│   │   ├── auth_service.dart
│   │   ├── gemini_service.dart
│   │   ├── subject_assignment_service.dart
│   │   └── subject_service.dart
│   │
│   ├── hod/
│   │   ├── subject_management_screen.dart
│   │   └── teacher_assignment_screen.dart
│   │
│   └── teacher/
│       ├── class_environment_screen.dart
│       └── my_teaching_screen.dart
│
├── test/
├── .gitignore
├── analysis_options.yaml
├── pubspec.yaml
├── pubspec.lock
└── README.md
```

## Application Flow

The application follows a simple login and navigation flow.

1. The application starts from `main.dart`.
2. Firebase is initialized.
3. The theme settings are initialized.
4. The Splash Screen is displayed.
5. The application checks whether a previous Firebase session can be restored.
6. If a valid session exists, the user's profile and role are retrieved from Firestore.
7. The user is directed to the appropriate dashboard.
8. If no valid session exists, the Login Screen is displayed.

## Authentication and Permissions

Authentication is managed in:

`lib/services/auth_service.dart`

The authentication service handles:

* Firebase email and password authentication.
* College ID to email mapping.
* Retrieving user information from Firestore.
* Checking the user's account status.
* Identifying the user's role.
* Restoring an existing login session.
* Logging out users.

User information is retrieved from the Firestore `users` collection.

The project also includes a permission model for controlling access to application modules and actions based on user roles.

**Security consideration:** Client-side permission checks alone are not sufficient for production security. Appropriate Firebase Security Rules or backend authorization must also be configured.

## AI Integration

The AI-related implementation is mainly handled through:

`lib/ai_screen.dart`

`lib/services/gemini_service.dart`

The Gemini service sends HTTP requests to Google's Gemini API and processes the generated response.

Current model:

`gemini-2.5-flash`

Before using the AI assistant, configure a valid API key.

For production use, API requests should be handled through a secure backend instead of keeping a private API key inside the Flutter application.

## Getting Started

Follow these steps to run the project locally.

### Prerequisites

Make sure you have installed:

* Flutter SDK
* Dart SDK
* Android Studio or Visual Studio Code
* Git
* A Firebase project

### 1. Clone the Repository

Open your terminal and run:

```bash
git clone https://github.com/Prasad1-coder/Campus-Digital-Twin-AI.git
```

### 2. Open the Project

```bash
cd Campus-Digital-Twin-AI
```

### 3. Install Dependencies

```bash
flutter pub get
```

### 4. Configure Firebase

Connect the application to your Firebase project.

Make sure Firebase Authentication and Cloud Firestore are configured correctly for your target platform.

The application expects user profile documents in the Firestore `users` collection.

### 5. Configure Gemini API

Add a valid Gemini API key to the Gemini service configuration.

Do not upload your actual API key to GitHub. For production, use a secure backend to communicate with the Gemini API.

### 6. Run the Application

Connect an Android device or start an emulator.

Then run:

```bash
flutter run
```

## Important Notes

* Firebase must be configured for authentication and Firestore-dependent functionality.
* The Firestore user profile must contain a valid role.
* The Gemini API requires a valid API key.
* Google Maps functionality may require platform-specific configuration.
* Some packages may require additional Android, iOS or platform-level setup.
* Client-side permissions should be supported by proper backend security rules before production deployment.

## Future Improvements

Some areas that can be improved as development continues:

* Complete integration of all campus modules with Firestore.
* Stronger backend authorization and security rules.
* Improved AI assistant responses using actual campus data.
* Better analytics and reporting.
* More complete academic management workflows.
* Improved testing and error handling.
* Production-ready configuration for all supported platforms.

## Project Status

Campus Digital Twin AI is an ongoing development project.

The project includes the main application structure, role-based authentication flow, multiple campus-related screens, Firebase integration and a Gemini API service.

Some integrations and modules may require further configuration or development before production use.

## Author

**Prasad Deshmane**

B.Sc. Computer Science Student

GitHub: https://github.com/Prasad1-coder

---

*Built with Flutter and Firebase.*
