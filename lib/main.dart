import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'providers/book_provider.dart';
import 'providers/chat_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/verify_email_screen.dart';
import 'screens/home/browse_listings.dart';
import 'screens/home/my_listings.dart';
import 'screens/chat/threads_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/auth/welcome_screen.dart'; // 

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const BookSwapApp());
}

class BookSwapApp extends StatelessWidget {
  const BookSwapApp({super.key});

  static const _navy = Color(0xFF0A0A23);
  static const _amber = Color(0xFFFFC107);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => BookProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'BookSwap',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: _amber, primary: _amber),
          scaffoldBackgroundColor: const Color.fromARGB(255, 238, 234, 234),
          appBarTheme: const AppBarTheme(
            backgroundColor: _navy,
            foregroundColor: Color.fromARGB(255, 205, 152, 7),
            elevation: 0,
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: _navy,
          selectedItemColor: Color(0xFFFFC107), 
          unselectedItemColor: Colors.white70,  
          showUnselectedLabels: true,           
          showSelectedLabels: true,             
          type: BottomNavigationBarType.fixed,  
),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(backgroundColor: _amber, foregroundColor: Colors.black),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),

        // ✅ CHANGED: show WelcomeScreen first
        home: const WelcomeScreen(),

        routes: {
          LoginScreen.route: (_) => const LoginScreen(),
          SignupScreen.route: (_) => const SignupScreen(),
        },
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    return StreamBuilder(
      stream: auth.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData) return const LoginScreen();
        final user = auth.currentUser!;
        if (!user.emailVerified) return const VerifyEmailScreen();
        return const MainNav();
      },
    );
  }
}

class MainNav extends StatefulWidget {
  const MainNav({super.key});

  @override
  State<MainNav> createState() => _MainNavState();
}

class _MainNavState extends State<MainNav> {
  int idx = 0;
  final pages = const [BrowseListings(), MyListings(), ThreadsScreen(), SettingsScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[idx],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: idx,
        onTap: (i) => setState(() => idx = i),
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


// main.dart
// import 'dart:io' show Platform;
// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart';

// import 'package:provider/provider.dart';
// import 'services/auth_service.dart';
// import 'providers/book_provider.dart';
// import 'providers/chat_provider.dart';

// import 'screens/auth/login_screen.dart';
// import 'screens/auth/signup_screen.dart';
// import 'screens/auth/verify_email_screen.dart';
// import 'screens/home/browse_listings.dart';
// import 'screens/home/my_listings.dart';
// import 'screens/chat/threads_screen.dart';
// import 'screens/settings/settings_screen.dart';
// import 'screens/auth/welcome_screen.dart';

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_storage/firebase_storage.dart';

// /// Toggle this when you want to use the Firebase Emulators locally.
// /// Make sure your emulators are running (Auth:9099, Firestore:8080, Storage:9199).
// const bool USE_EMULATOR = false;

// /// Point all Firebase SDKs to the local emulators (sync config calls).
// void connectToFirebaseEmulators() {
//   final host = Platform.isAndroid ? '10.0.2.2' : 'localhost';
//   FirebaseAuth.instance.useAuthEmulator(host, 9099);
//   FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
//   FirebaseStorage.instance.useStorageEmulator(host, 9199);
// }

// /// Quick Storage sanity check: uploads a tiny text file and reads it back.
// /// - If it prints a URL, Storage is configured correctly for the current environment.
// Future<void> storageSanityCheck() async {
//   final ref = FirebaseStorage.instance.ref('diagnostics/hello.txt');
//   try {
//     await ref.putString('hello world @ ${DateTime.now().toIso8601String()}');
//     final url = await ref.getDownloadURL();
//     // ignore: avoid_print
//     print('✅ Storage OK. ${ref.fullPath} → $url');
//   } on FirebaseException catch (e) {
//     // ignore: avoid_print
//     print('❌ Storage check failed: ${e.code} at ${ref.fullPath} | ${e.message}');
//   }
// }

// /// Safe helper: returns a download URL or null if the object is missing.
// /// Use this to avoid crashes and show a placeholder when files aren’t there.
// Future<String?> safeGetDownloadUrl(String path) async {
//   final ref = FirebaseStorage.instance.ref(path);
//   // ignore: avoid_print
//   print('🔎 Trying Storage path: ${ref.fullPath}');
//   try {
//     return await ref.getDownloadURL();
//   } on FirebaseException catch (e) {
//     if (e.code == 'object-not-found') {
//       // ignore: avoid_print
//       print('⚠️ Missing object at ${ref.fullPath}');
//       return null;
//     }
//     rethrow;
//   }
// }

// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );

//   if (USE_EMULATOR) {
//     connectToFirebaseEmulators();
//   }

//   // Optional: Run once at startup (comment out later).
//   // await storageSanityCheck();

//   runApp(const BookSwapApp());
// }

// class BookSwapApp extends StatelessWidget {
//   const BookSwapApp({super.key});

//   static const _navy = Color(0xFF0A0A23);
//   static const _amber = Color(0xFFFFC107);

//   @override
//   Widget build(BuildContext context) {
//     return MultiProvider(
//       providers: [
//         Provider<AuthService>(create: (_) => AuthService()),
//         ChangeNotifierProvider(create: (_) => BookProvider()),
//         ChangeNotifierProvider(create: (_) => ChatProvider()),
//       ],
//       child: MaterialApp(
//         debugShowCheckedModeBanner: false,
//         title: 'BookSwap',
//         theme: ThemeData(
//           colorScheme: ColorScheme.fromSeed(seedColor: _amber, primary: _amber),
//           scaffoldBackgroundColor: const Color.fromARGB(255, 238, 234, 234),
//           appBarTheme: const AppBarTheme(
//             backgroundColor: _navy,
//             foregroundColor: Color.fromARGB(255, 205, 152, 7),
//             elevation: 0,
//           ),
//           bottomNavigationBarTheme: const BottomNavigationBarThemeData(
//             backgroundColor: _navy,
//             selectedItemColor: Color(0xFFFFC107),
//             unselectedItemColor: Colors.white70,
//             showUnselectedLabels: true,
//             showSelectedLabels: true,
//             type: BottomNavigationBarType.fixed,
//           ),
//           elevatedButtonTheme: ElevatedButtonThemeData(
//             style: ElevatedButton.styleFrom(
//               backgroundColor: _amber,
//               foregroundColor: Colors.black,
//             ),
//           ),
//           inputDecorationTheme: InputDecorationTheme(
//             border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
//           ),
//         ),

//         // Use the auth-aware gate as the entry point.
//         home: const _AuthGate(),

//         routes: {
//           LoginScreen.route: (_) => const LoginScreen(),
//           SignupScreen.route: (_) => const SignupScreen(),
//           // Add other named routes here if needed
//         },
//       ),
//     );
//   }
// }

// /// Auth gate: routes to Login → Verify Email → MainNav depending on auth state.
// class _AuthGate extends StatelessWidget {
//   const _AuthGate();

//   @override
//   Widget build(BuildContext context) {
//     final auth = context.read<AuthService>();
//     return StreamBuilder<User?>(
//       stream: auth.authStateChanges,
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Scaffold(body: Center(child: CircularProgressIndicator()));
//         }
//         if (!snapshot.hasData) return const WelcomeScreen(); // or LoginScreen()
//         final user = auth.currentUser!;
//         if (!user.emailVerified) return const VerifyEmailScreen();
//         return const MainNav();
//       },
//     );
//   }
// }

// class MainNav extends StatefulWidget {
//   const MainNav({super.key});

//   @override
//   State<MainNav> createState() => _MainNavState();
// }

// class _MainNavState extends State<MainNav> {
//   int idx = 0;
//   final pages = const [
//     BrowseListings(),
//     MyListings(),
//     ThreadsScreen(),
//     SettingsScreen(),
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: pages[idx],
//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: idx,
//         onTap: (i) => setState(() => idx = i),
//         showUnselectedLabels: true,
//         type: BottomNavigationBarType.fixed,
//         items: const [
//           BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
//           BottomNavigationBarItem(icon: Icon(Icons.library_books), label: 'My Listings'),
//           BottomNavigationBarItem(icon: Icon(Icons.chat_bubble), label: 'Chats'),
//           BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
//         ],
//       ),
//     );
//   }
// }
