import 'package:building_services/screens/chat/chats_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'firebase_options.dart';

// Theme
import 'theme/app_theme.dart';

// Core screens
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/public_search_screen.dart';
import 'screens/customer_home_screen.dart';
import 'provider/provider_home_screen.dart';

// Provider types screens
import 'screens/companies_screen.dart';
import 'screens/establishments_screen.dart';
import 'screens/professionals_screen.dart';

// Services
import 'screens/services/services_list_screen.dart';

// Bookings
import 'screens/bookings/customer_bookings_screen.dart';
import 'screens/bookings/provider_bookings_screen.dart';

// Categories
import 'screens/categories/categories_screen.dart';

// Admin (lib/Admin)
import 'Admin/admin_home_screen.dart';
import 'Admin/admin_users_screen.dart';
import 'Admin/admin_services_screen.dart';
import 'Admin/admin_categories_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const String _appTitle = 'Building Services';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: _appTitle,
      theme: AppTheme.lightTheme,
      home: const AuthGate(),

      // ✅ Force English app language (even if device is Arabic)
      locale: const Locale('en'),
      supportedLocales: const [
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // ✅ Force LTR for the whole app (optional but matches English UI)
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: child ?? const SizedBox.shrink(),
        );
      },

      routes: {
        // Auth
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),

        // Public
        '/publicSearch': (_) => const PublicSearchScreen(),

        // Home
        '/customerHome': (_) => const CustomerHomeScreen(),
        '/providerHome': (_) => const ProviderHomeScreen(),

        // Main flows
        '/services': (_) => const ServicesListScreen(),
        '/customerBookings': (_) => const CustomerBookingsScreen(),
        '/providerBookings': (_) => const ProviderBookingsScreen(),
        '/categories': (_) => const CategoriesScreen(),

        // Provider Types
        '/companies': (_) => const CompaniesScreen(),
        '/establishments': (_) => const EstablishmentsScreen(),
        '/professionals': (_) => const ProfessionalsScreen(),

        // Admin
        '/admin': (_) => const AdminHomeScreen(),
        '/adminUsers': (_) => const AdminUsersScreen(),
        '/adminServices': (_) => const AdminServicesScreen(),
        '/adminCategories': (_) => const AdminCategoriesScreen(),

        // Chats
        '/chats': (_) => const ChatsListScreen(),
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<String?> _getRole(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (!doc.exists) return null;

    final data = doc.data();
    return (data?['role'] as String?)?.trim();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final user = authSnap.data;
        if (user == null) {
          // Before login
          return const PublicSearchScreen();
        }

        return FutureBuilder<String?>(
          future: _getRole(user.uid),
          builder: (context, roleSnap) {
            if (roleSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            final role = roleSnap.data;

            if (role == 'admin') return const AdminHomeScreen();
            if (role == 'provider') return const ProviderHomeScreen();

            // Default: customer
            return const CustomerHomeScreen();
          },
        );
      },
    );
  }
}
