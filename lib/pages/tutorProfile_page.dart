import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TutorProfilePage extends StatefulWidget {
  const TutorProfilePage({super.key});

  @override
  State<TutorProfilePage> createState() => _TutorProfilePageState();
}

class _TutorProfilePageState extends State<TutorProfilePage> {
  String name = 'Loading...';
  String matric = 'Loading...';
  String email = 'Loading...';
  String phoneNumber = 'Loading...';
  String specialization = 'Loading...';
  double rating = 0.0;
  int studentsTaught = 0;
  int hours = 0;
  String status = 'Tutor';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (!mounted) return;

    setState(() {
      name = doc.data()?['name']?.toString() ?? 'No name';
      matric = doc.data()?['matric']?.toString() ?? 'No matric';
      email = doc.data()?['email']?.toString() ?? 'No email';
      phoneNumber = doc.data()?['phone']?.toString() ?? 'No phone';
      specialization = doc.data()?['subject']?.toString() ?? 'Not specified';
      rating = doc.data()?['rating'] is num ? (doc.data()?['rating'] as num).toDouble() : 0.0;
      studentsTaught = doc.data()?['studentsTaught'] is num ? (doc.data()?['studentsTaught'] as num).toInt() : 0;
      hours = doc.data()?['hours'] is num ? (doc.data()?['hours'] as num).toInt() : 0;
      status = (doc.data()?['role']?.toString() ?? 'tutor').toUpperCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF6200EE),
        elevation: 0,
        title: const Text(
          'Tutor Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Profile Title
                  Center(
                    child: Text(
                      'PROFILE',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Avatar with initial
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6200EE), Color(0xFF03DAC6)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'T',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Profile Information Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProfileField('Name:', name),
                        const SizedBox(height: 16),
                        _buildProfileField('Matric:', matric),
                        const SizedBox(height: 16),
                        _buildProfileField('Email:', email),
                        const SizedBox(height: 16),
                        _buildProfileField('Phone No:', phoneNumber),
                        const SizedBox(height: 16),
                        _buildProfileField('Specialization:', specialization),
                        const SizedBox(height: 16),
                        _buildProfileField('Status:', status),
                        const SizedBox(height: 20),
                        // Stats Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildStatItem('Students', studentsTaught.toString()),
                            _buildStatItem('Hours', hours.toString()),
                            _buildRatingItem('Rating', rating.toStringAsFixed(1)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Edit Profile Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        await Navigator.of(context).pushNamed('/tutor-edit-profile');
                        _loadProfile();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6200EE),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Edit Profile',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Log Out Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        _showLogoutConfirmation(context);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF6200EE),
                        side: const BorderSide(
                          color: Color(0xFF6200EE),
                          width: 2,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Log Out',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF6200EE),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildRatingItem(String label, String value) {
    return Column(
      children: [
        Row(
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 16),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6200EE),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Log Out'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (!mounted) return;
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacementNamed('/login');
              },
              child: const Text(
                'Log Out',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}
