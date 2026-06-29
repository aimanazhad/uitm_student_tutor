import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Utility untuk create admin dalam Firestore
/// Gunakan ini ONE TIME ONLY untuk setup admin account
class AdminSetupUtil {
  static const String adminEmail = 'admin@gmail.com';
  static const String adminPassword = '12345'; // Change ini to your password

  /// Create admin entry dalam Firestore (tanpa Firebase Auth)
  /// Gunakan cara ini kalau nak simple hardcoded credentials
  static Future<void> createAdminFirestoreOnly() async {
    try {
      await FirebaseFirestore.instance.collection('users').doc('admin_001').set({
        'name': 'Administrator',
        'email': adminEmail,
        'role': 'admin',
        'roles': ['admin'],
        'isAdmin': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Admin created successfully in Firestore');
    } catch (e) {
      print('❌ Error creating admin: $e');
    }
  }

  /// Create admin dengan Firebase Auth (RECOMMENDED)
  /// Run ini once to setup admin account
  static Future<void> createAdminWithAuth() async {
    try {
      // Check if admin already exists
      final existingAdmin = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: adminEmail)
          .where('isAdmin', isEqualTo: true)
          .get();

      if (existingAdmin.docs.isNotEmpty) {
        print('⚠️ Admin already exists');
        return;
      }

      // Create Firebase Auth account
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: adminEmail,
        password: adminPassword,
      );

      // Create Firestore document
      await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .set({
        'name': 'Administrator',
        'email': adminEmail,
        'role': 'admin',
        'roles': ['admin'],
        'isAdmin': true,
        'phone': '',
        'matric': 'ADMIN',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Admin created successfully with Firebase Auth');
      print('Email: $adminEmail');
      print('Password: $adminPassword');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        print('⚠️ Admin email already registered in Firebase Auth');
        // Just create Firestore entry
        try {
          final users = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: adminEmail,
            password: adminPassword,
          );

          await FirebaseFirestore.instance
              .collection('users')
              .doc(users.user!.uid)
              .set({
            'isAdmin': true,
            'role': 'admin',
            'roles': ['admin'],
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          print('✅ Admin Firestore entry created');
        } catch (e) {
          print('❌ Error: $e');
        }
      } else {
        print('❌ Error creating admin: $e');
      }
    }
  }
}
