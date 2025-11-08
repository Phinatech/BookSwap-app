// Core Flutter and Firebase imports
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// State management
import 'package:provider/provider.dart';

// Services - Firebase integration layer
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/message_listener.dart';

// Providers - State management layer
import 'providers/book_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/theme_provider.dart';

// Screen imports - Authentication flow
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/auth/verify_email_screen.dart';

// Screen imports - Main app screens
import 'screens/home/browse_listings.dart';
import 'screens/home/my_listings.dart';
import 'screens/chat/threads_screen.dart';
import 'screens/settings/settings_screen.dart';

// Firebase Auth for user state
import 'package:firebase_auth/firebase_auth.dart';

/// Application entry point
/// Initializes Firebase, notification services, and starts the app
Future<void> main() async {
  // Ensure Flutter framework is initialized before Firebase
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with platform-specific configuration
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize push notification services (graceful failure)
  try {
    await NotificationService().initialize();
    MessageListener().startListening();
  } catch (e) {
    debugPrint('Notification service failed to initialize: $e');
  }
  
  // Start the Flutter application
  runApp(const BookSwapApp());
}

/// Main application widget with Provider setup and theme configuration
class BookSwapApp extends StatelessWidget {
  const BookSwapApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Setup dependency injection with Provider pattern
    return MultiProvider(
      providers: [
        // AuthService - Firebase authentication wrapper (singleton)
        Provider<AuthService>(create: (_) => AuthService()),
        // BookProvider - Manages book CRUD and swap operations
        ChangeNotifierProvider(create: (_) => BookProvider()),
        // ChatProvider - Real-time messaging functionality
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        // ThemeProvider - Dark/light mode management
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      // Listen to theme changes for dynamic theme switching
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'BookSwap',
            // Dynamic theme configuration
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            // AuthGate handles authentication routing
            home: const AuthGate(),
            // Named routes for navigation
            routes: {
              LoginScreen.route: (_) => const LoginScreen(),
              SignupScreen.route: (_) => const SignupScreen(),
            },
          );
        },
      ),
    );
  }
}

/// Authentication gate that routes users based on auth state:
/// Not authenticated → WelcomeScreen
/// Authenticated but unverified → VerifyEmailScreen  
/// Authenticated and verified → MainNav
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    
    // Listen to Firebase Auth state changes for reactive routing
    return StreamBuilder<User?>(
      stream: auth.authStateChanges,
      builder: (context, snapshot) {
        // Debug logging for authentication flow tracking
        debugPrint('AuthGate - Connection state: ${snapshot.connectionState}');
        debugPrint('AuthGate - Has data: ${snapshot.hasData}');
        debugPrint('AuthGate - User: ${snapshot.data?.email}');
        debugPrint('AuthGate - Email verified: ${snapshot.data?.emailVerified}');
        
        // Show loading spinner while connecting to Firebase
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        // No user signed in - show welcome/login flow
        if (!snapshot.hasData) {
          debugPrint('AuthGate - Showing WelcomeScreen');
          return const WelcomeScreen();
        }
        
        // User signed in but email not verified - require verification
        final user = auth.currentUser!;
        if (!user.emailVerified) {
          debugPrint('AuthGate - Showing VerifyEmailScreen');
          return const VerifyEmailScreen();
        }
        
        // User authenticated and verified - show main app
        debugPrint('AuthGate - Showing MainNav');
        return const MainNav();
      },
    );
  }
}

/// Main navigation with bottom tab bar for authenticated users
class MainNav extends StatefulWidget {
  const MainNav({super.key});

  @override
  State<MainNav> createState() => _MainNavState();
}

class _MainNavState extends State<MainNav> {
  // Current selected tab index
  int idx = 0;
  
  // Main app screens corresponding to bottom navigation tabs
  final pages = const [
    BrowseListings(),    // Tab 0: Browse all book listings
    MyListings(),        // Tab 1: User's books, offers, and incoming swaps
    ThreadsScreen(),     // Tab 2: Chat conversations
    SettingsScreen(),    // Tab 3: Profile and app settings
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Display current selected page
      body: pages[idx],
      // Bottom navigation with 4 main tabs
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: idx,
        onTap: (i) => setState(() => idx = i), // Update selected tab
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.library_books), label: 'My Listings'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble), label: 'Chats'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}


