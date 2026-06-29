import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TutorEditProfilePage extends StatefulWidget {
  const TutorEditProfilePage({super.key});

  @override
  State<TutorEditProfilePage> createState() => _TutorEditProfilePageState();
}

class _TutorEditProfilePageState extends State<TutorEditProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _matricController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _specializationController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _matricController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _specializationController = TextEditingController();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _matricController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _specializationController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (!mounted) return;

    setState(() {
      _nameController.text = doc.data()?['name']?.toString() ?? '';
      _matricController.text = doc.data()?['matric']?.toString() ?? '';
      _emailController.text = doc.data()?['email']?.toString() ?? '';
      _phoneController.text = doc.data()?['phone']?.toString() ?? '';
      _specializationController.text = doc.data()?['subject']?.toString() ?? '';
    });
  }

  Future<void> _saveChanges() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'name': _nameController.text.trim(),
        'matric': _matricController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'subject': _specializationController.text.trim(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save profile: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _cancelEdit() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF6200EE),
        elevation: 0,
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),

            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6200EE), Color(0xFF03DAC6)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Full Name Field
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Full Name:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[300],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Matric Number Field
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Matric Number:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _matricController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[300],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Email Field
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Email:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[300],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Phone Number Field
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Phone Number:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[300],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Specialization Field
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Specialization:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _specializationController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[300],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Save Changes Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6200EE),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'SAVE CHANGES',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Cancel Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _cancelEdit,
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
                        'CANCEL',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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
}
