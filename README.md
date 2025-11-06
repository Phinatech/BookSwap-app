# BookSwap - Student Textbook Exchange App

A Flutter mobile application that enables students to list textbooks for exchange and initiate swap offers with other users. Built with Firebase for authentication, real-time data storage, and cloud messaging.

## Features

- **User Authentication**: Email/password signup, login, logout with email verification
- **Book Listings**: Create, read, update, delete book listings with cover images
- **Swap System**: Initiate swap offers with real-time status updates
- **Chat System**: Real-time messaging between users after swap initiation
- **Settings**: Profile information and notification preferences
- **Real-time Sync**: All data syncs instantly across devices using Firestore

## Architecture

```
lib/
├── main.dart                 # App entry point with Provider setup
├── models/
│   └── book.dart            # Book data model
├── providers/               # State management (Provider pattern)
│   ├── book_provider.dart   # Book CRUD operations
│   └── chat_provider.dart   # Chat functionality
├── screens/
│   ├── auth/               # Authentication screens
│   │   ├── welcome_screen.dart
│   │   ├── login_screen.dart
│   │   ├── signup_screen.dart
│   │   └── verify_email_screen.dart
│   ├── home/               # Main app screens
│   │   ├── browse_listings.dart
│   │   ├── my_listings.dart
│   │   └── post_book_screen.dart
│   ├── chat/               # Chat functionality
│   │   ├── threads_screen.dart
│   │   └── chat_screen.dart
│   └── settings/
│       └── settings_screen.dart
├── services/               # Firebase integration
│   ├── auth_service.dart   # Authentication logic
│   └── firestore_service.dart # Database operations
├── widgets/
│   └── book_card.dart      # Reusable book display component
└── firebase_options.dart   # Firebase configuration
```

## Firebase Schema

### Collections

**books**
```json
{
  "id": "auto-generated",
  "title": "string",
  "author": "string", 
  "condition": "New|Like New|Good|Used",
  "swapFor": "string",
  "imageUrl": "base64 data URL",
  "ownerId": "user UID",
  "ownerEmail": "string",
  "status": "string",
  "createdAt": "timestamp"
}
```

**swaps**
```json
{
  "id": "auto-generated",
  "bookId": "string",
  "senderId": "user UID",
  "receiverId": "user UID", 
  "status": "Pending|Accepted|Rejected",
  "createdAt": "timestamp"
}
```

**threads**
```json
{
  "id": "chatId (sorted UIDs)",
  "members": ["uid1", "uid2"],
  "lastText": "string",
  "updatedAt": "timestamp"
}
```

**messages** (subcollection of threads)
```json
{
  "id": "auto-generated",
  "from": "user UID",
  "to": "user UID",
  "text": "string",
  "createdAt": "timestamp"
}
```

## State Management

Uses **Provider** pattern for reactive state management:

- **BookProvider**: Manages book CRUD operations and swap functionality
- **ChatProvider**: Handles real-time messaging
- **AuthService**: Manages user authentication state

Real-time updates achieved through Firestore streams that automatically update UI when data changes.

## Build Instructions

### Prerequisites
- Flutter SDK (3.9.2+)
- Firebase project with Authentication, Firestore, and Storage enabled
- Android Studio / VS Code with Flutter extensions

### Setup Steps

1. **Clone Repository**
   ```bash
   git clone <repository-url>
   cd individual_final
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Configuration**
   - Create Firebase project at https://console.firebase.google.com
   - Enable Authentication (Email/Password)
   - Enable Firestore Database
   - Enable Firebase Storage
   - Download configuration files:
     - `google-services.json` → `android/app/`
     - `GoogleService-Info.plist` → `ios/Runner/`

4. **Generate Firebase Options**
   ```bash
   flutter packages pub run build_runner build
   flutterfire configure
   ```

5. **Run Application**
   ```bash
   flutter run
   ```

### Firebase Security Rules

**Firestore Rules:**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /books/{document} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == resource.data.ownerId;
      allow create: if request.auth != null;
    }
    
    match /swaps/{document} {
      allow read, write: if request.auth != null && 
        (request.auth.uid == resource.data.senderId || 
         request.auth.uid == resource.data.receiverId);
    }
    
    match /threads/{document} {
      allow read, write: if request.auth != null && 
        request.auth.uid in resource.data.members;
    }
  }
}
```

## Key Features Implementation

### Authentication Flow
1. Welcome screen with clickable "Sign up to get started" text → Login/Signup
2. Email verification required
3. Persistent login state with Provider

### Book Management
- Image upload using base64 encoding stored in Firestore
- Real-time CRUD operations with instant UI updates
- Confirmation dialogs for destructive actions

### Swap System
- Tap "Swap" → creates swap document
- Real-time status updates for both users
- Book status reflects swap state

### Chat System
- Automatic thread creation on swap initiation
- Real-time messaging with Firestore streams
- Message timestamps and user identification

## Dependencies

```yaml
dependencies:
  flutter: sdk
  firebase_core: ^4.2.0
  firebase_auth: ^6.1.1
  cloud_firestore: ^6.0.3
  firebase_storage: ^13.0.3
  provider: ^6.1.5+1
  image_picker: ^1.2.0
  shared_preferences: ^2.2.2
  intl: ^0.20.2
  uuid: ^4.5.1
```

## Testing

Run Dart analyzer to ensure code quality:
```bash
flutter analyze
```

## Contributing

1. Fork the repository
2. Create feature branch
3. Commit changes with clear messages
4. Submit pull request

## License

This project is for educational purposes as part of a mobile development course assignment.