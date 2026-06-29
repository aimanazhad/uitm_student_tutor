import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'pages/admin_login.dart';
import 'pages/admin_dashboard.dart';
import 'pages/login_page.dart';
import 'pages/signup_page.dart';
import 'pages/student_dashboard.dart';
import 'pages/studentprofile_page.dart';
import 'pages/studenteditprofile_page.dart';
import 'pages/studentbooking_page.dart';
import 'pages/findtutor_page.dart';
import 'pages/student_notifications.dart';
import 'pages/tutor_dashboard.dart';
import 'pages/tutorProfile_page.dart';
import 'pages/tutoreditprofile_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UITM Student Tutor',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6200EE),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const LoginPage(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignUpPage(),
        '/student-dashboard': (context) => const StudentDashboard(),
        '/student-profile': (context) => const StudentProfilePage(),
        '/student-edit-profile': (context) => const StudentEditProfilePage(),
        '/student-booking': (context) => const StudentBookingPage(),
        '/find-tutor': (context) => const FindTutorPage(),
        '/student-notifications': (context) => const StudentNotificationsPage(),
        '/tutor-dashboard': (context) => const TutorDashboard(),
        '/tutor-profile': (context) => const TutorProfilePage(),
        '/tutor-edit-profile': (context) => const TutorEditProfilePage(),
        '/admin-login': (context) => const AdminLoginPage(),
        '/admin-dashboard': (context) => const AdminDashboard(),
      },
    );
  }
}
