import 'package:flutter/material.dart';
import 'pages/admin_login.dart';
import 'pages/login_page.dart';
import 'pages/signup_page.dart';
import 'pages/student_dashboard.dart';
import 'pages/studentprofile_page.dart';
import 'pages/studenteditprofile_page.dart';

void main() {
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
        '/admin-login': (context) => const AdminLoginPage(),
        '/admin-dashboard': (context) => const AdminDashboard(),
      },
    );
  }
}
