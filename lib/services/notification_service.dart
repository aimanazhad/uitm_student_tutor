import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static Future<void> addNotification({
    required String userId,
    required String title,
    required String body,
  }) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .add({
      'title': title,
      'body': body,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
