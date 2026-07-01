import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'studentprofile_page.dart';
import 'findtutor_page.dart';

class StudentDrawerPage extends StatefulWidget {
  const StudentDrawerPage({super.key});

  @override
  State<StudentDrawerPage> createState() => _StudentDrawerPageState();
}

class _StudentDrawerPageState extends State<StudentDrawerPage> {
  String _userName = 'Student';

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = doc.data();
    if (data != null && data['name'] != null) {
      if (!mounted) return;
      setState(() {
        _userName = data['name'].toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          bottomLeft: Radius.circular(20),
        ),
      ),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF6200EE),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, color: Color(0xFF6200EE), size: 28),
                ),
                const SizedBox(height: 12),
                Text(
                  _userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Quick access to your account',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline, color: Color(0xFF6200EE)),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StudentProfilePage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.search_outlined, color: Color(0xFF6200EE)),
            title: const Text('Find Tutor'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FindTutorPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today_outlined, color: Color(0xFF6200EE)),
            title: const Text('Bookings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/student-booking');
            },
          ),
          ListTile(
            leading: const Icon(Icons.rate_review_outlined, color: Color(0xFF6200EE)),
            title: const Text('Review Tutor'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/student-review');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Logout'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
          ),
        ],
      ),
    );
  }
}
