# BookSwap - Student Textbook Exchange App

A Flutter mobile application that enables students to list textbooks for exchange and initiate swap offers with other users. Built with Firebase for authentication, real-time data storage, and cloud messaging.

## Features

- **User Authentication**: Email/password signup, login, logout with email verification
- **Book Listings**: Create, read, update, delete book listings with cover images
- **Swap System**: Initiate swap offers with real-time status updates (Pending/Accepted/Rejected)
- **Chat System**: Real-time messaging between users after swap initiation
- **Settings**: Profile information, theme toggle, and notification preferences
- **Real-time Sync**: All data syncs instantly across devices using Firestore streams
- **Responsive Design**: Adaptive UI that works across different screen sizes
- **Dark Mode**: Toggle between light and dark themes

## Architecture

```
lib/
├── main.dart                 # App entry point with Provider setup
├── models/
│   └── book.dart            # Book data model
├── providers/               # State management (Provider pattern)
│   ├── book_provider.dart   # Book CRUD operations & swap functionality
│   ├── chat_provider.dart   # Real-time messaging
│   └── theme_provider.dart  # Dark/Light theme management
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
│   ├── firestore_service.dart # Database operations
│   ├── notification_service.dart # Push notifications
│   └── message_listener.dart # FCM message handling
├── widgets/
│   ├── book_card.dart      # Reusable book display component
│   └── swap_bottom_sheet.dart # Swap request modal
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
  "authorBookId": "string",
  "userBookId": "string",
  "authorId": "user UID",
  "userId": "user UID",
  "preferredDate": "timestamp",
  "returningDate": "timestamp",
  "status": "Pending|Accepted|Rejected|Returned",
  "createdAt": "timestamp",
  "approvedAt": "timestamp",
  "rejectedAt": "timestamp",
  "returnedAt": "timestamp"
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

- **BookProvider**: Manages book CRUD operations, swap functionality, loading states, and error handling
- **ChatProvider**: Handles real-time messaging with automatic thread creation
- **ThemeProvider**: Manages dark/light theme switching with SharedPreferences persistence
- **AuthService**: Manages user authentication state with email verification flow

Real-time updates achieved through Firestore streams (`snapshots()`) that automatically update UI when data changes. All providers extend `ChangeNotifier` and use `notifyListeners()` for reactive updates.

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
1. **AuthGate** routes users based on authentication state
2. Welcome screen → Login/Signup → Email verification → Main app
3. Email verification required with resend functionality
4. Persistent login state with automatic session management

### Book Management
- **Image Upload**: Base64 encoding stored directly in Firestore documents
- **Real-time CRUD**: Instant UI updates via Firestore streams
- **Input Validation**: Comprehensive form validation with error messages
- **Responsive Cards**: Adaptive layout that prevents text overflow
- **Status Tracking**: Visual indicators for book availability and swap states

### Swap System
- **Detailed Requests**: Select offered book and preferred return date
- **Real-time Status**: Pending → Accepted/Rejected → Returned flow
- **Dual Updates**: Both swap and book documents updated atomically
- **My Offers Tracking**: Users can monitor all sent swap requests
- **Incoming Management**: Book owners can approve/reject offers

### Chat System
- **Automatic Creation**: Chat threads created on swap initiation
- **Deterministic IDs**: Sorted UID pairs prevent duplicate conversations
- **Real-time Messaging**: Firestore streams for instant message delivery
- **Thread Management**: Last message tracking and read status

## Dependencies

```yaml
dependencies:
  flutter: sdk
  firebase_core: ^4.2.0
  firebase_auth: ^6.1.1
  cloud_firestore: ^6.0.3
  firebase_storage: ^13.0.3
  firebase_messaging: ^16.0.4
  flutter_local_notifications: ^19.5.0
  provider: ^6.1.5+1
  image_picker: ^1.2.0
  shared_preferences: ^2.2.2
  intl: ^0.20.2
  uuid: ^4.5.1
```

## Testing & Quality

**Code Analysis:**
```bash
flutter analyze
```

**Performance Testing:**
```bash
flutter run --profile
```

**Build Verification:**
```bash
# iOS
flutter build ios

# Android
flutter build apk
```

## 📱 Screenshots

*Add screenshots of key screens here:*
- Welcome & Authentication
- Browse Listings
- Book Details & Swap Request
- My Listings (Books, Offers, Incoming)
- Chat Interface
- Settings & Profile

## Assignment Requirements Met

✅ **Authentication**: Email/password with verification  
✅ **CRUD Operations**: Complete book management  
✅ **Swap Functionality**: Real-time offer system  
✅ **State Management**: Provider pattern implementation  
✅ **Navigation**: 4-screen bottom navigation  
✅ **Settings**: Profile info and preferences  
✅ **Chat System**: Real-time messaging (Bonus)  
✅ **Real-time Sync**: Firestore streams throughout  

## 🚀 Performance Optimizations

- **Efficient Queries**: Firestore queries with proper indexing
- **Image Optimization**: Base64 encoding with size limits
- **Memory Management**: Proper stream disposal and lifecycle management
- **Loading States**: User feedback during async operations
- **Error Handling**: Comprehensive error boundaries and user notifications

## Contributing

1. Fork the repository
2. Create feature branch
3. Commit changes with clear messages
4. Submit pull request

## License

This project is for educational purposes as part of a mobile development course assignment.

## 👨‍💻 Developer

Developed as a comprehensive Flutter application demonstrating:
- Firebase integration and real-time data synchronization
- Provider state management pattern
- Cross-platform mobile development
- Modern UI/UX design principles
- Production-ready code architecture

---

**Built using Flutter & Firebase**