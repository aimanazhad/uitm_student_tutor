import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class StudentReviewPage extends StatefulWidget {
  final String? bookingId;
  final String? tutorId;
  final String? tutorName;
  final String? subject;

  const StudentReviewPage({
    super.key,
    this.bookingId,
    this.tutorId,
    this.tutorName,
    this.subject,
  });

  @override
  State<StudentReviewPage> createState() => _StudentReviewPageState();
}

class _StudentReviewPageState extends State<StudentReviewPage> {
  final _reviewController = TextEditingController();
  double _rating = 4.0;
  bool _isSubmitting = false;
  String? _bookingId;
  String? _tutorId;
  String? _tutorName;
  String? _subject;
  List<Map<String, dynamic>> _pendingReviewBookings = [];
  String? _selectedBookingId;

  @override
  void initState() {
    super.initState();
    _bookingId = widget.bookingId;
    _tutorId = widget.tutorId;
    _tutorName = widget.tutorName;
    _subject = widget.subject;
    _selectedBookingId = widget.bookingId;
    _loadPendingReviewBookingIfNeeded();
  }

  Future<void> _loadPendingReviewBookingIfNeeded() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('studentId', isEqualTo: user.uid)
          .where('reviewRequested', isEqualTo: true)
          .get();

      final bookings = snapshot.docs.map<Map<String, dynamic>>((doc) {
        final data = doc.data();
        return {
          'bookingId': doc.id,
          'tutorId': data['tutorId']?.toString() ?? '',
          'tutorName': data['tutorName']?.toString() ?? 'Unknown Tutor',
          'subject': data['subject']?.toString() ?? '',
          'completedAt': data['completedAt'],
          'reviewed': data['reviewed'] == true,
        };
      }).toList();

      bookings.sort((a, b) {
        final aTs = a['completedAt'] as Timestamp?;
        final bTs = b['completedAt'] as Timestamp?;
        if (aTs == null && bTs == null) return 0;
        if (aTs == null) return 1;
        if (bTs == null) return -1;
        return bTs.compareTo(aTs);
      });

      final pendingBookings = bookings.where((booking) => booking['reviewed'] != true).toList();

      String? selectedBookingId = _selectedBookingId;
      if (selectedBookingId == null || selectedBookingId.isEmpty) {
        selectedBookingId = bookings.isNotEmpty ? bookings.first['bookingId'] as String : null;
      }

      final selectedBooking = selectedBookingId != null
          ? pendingBookings.firstWhere(
              (booking) => booking['bookingId'] == selectedBookingId,
              orElse: () => pendingBookings.isNotEmpty ? pendingBookings.first : <String, dynamic>{},
            )
          : null;

      if (!mounted) return;
      setState(() {
        _pendingReviewBookings = pendingBookings;
        _selectedBookingId = selectedBookingId;
        _bookingId = selectedBooking?['bookingId'] ?? _bookingId;
        _tutorId = selectedBooking?['tutorId'] ?? _tutorId;
        _tutorName = selectedBooking?['tutorName'] ?? _tutorName;
        _subject = selectedBooking?['subject'] ?? _subject;
      });

      if (!mounted) return;
      setState(() {
        _pendingReviewBookings = bookings;
        _selectedBookingId = selectedBookingId;
        _bookingId = selectedBooking?['bookingId'] ?? _bookingId;
        _tutorId = selectedBooking?['tutorId'] ?? _tutorId;
        _tutorName = selectedBooking?['tutorName'] ?? _tutorName;
        _subject = selectedBooking?['subject'] ?? _subject;
      });
    } catch (_) {
      // Ignore load failure; page will show placeholder.
    }
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    final reviewText = _reviewController.text.trim();
    if (reviewText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a review before submitting.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final bookingId = _selectedBookingId ?? _bookingId;
      if (bookingId == null || bookingId.isEmpty || _tutorId == null || _tutorId!.isEmpty) {
        throw Exception('No tutor booking selected for review.');
      }

      final tutorRef = FirebaseFirestore.instance.collection('users').doc(_tutorId);
      final bookingRef = FirebaseFirestore.instance.collection('bookings').doc(bookingId);

      await FirebaseFirestore.instance.collection('reviews').add({
        'bookingId': bookingId,
        'tutorId': _tutorId ?? '',
        'tutorName': _tutorName ?? '',
        'subject': _subject ?? '',
        'rating': _rating,
        'review': reviewText,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await bookingRef.update({
        'reviewed': true,
      });

      final tutorDoc = await tutorRef.get();
      final currentRating = tutorDoc.data()?['rating'] as num? ?? 0;
      final reviewCount = tutorDoc.data()?['reviewCount'] as int? ?? 0;
      final newReviewCount = reviewCount + 1;
      final newAverageRating = ((currentRating * reviewCount) + _rating) / newReviewCount;

      await tutorRef.update({
        'rating': newAverageRating,
        'reviewCount': newReviewCount,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Review submitted successfully.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit review: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6200EE),
        title: const Text(
          'Review Tutor',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Review Tutor',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6200EE),
                ),
              ),
              const SizedBox(height: 8),
              if (_pendingReviewBookings.isEmpty)
                const Text(
                  'No tutors are waiting for a review right now.',
                  style: TextStyle(color: Colors.black54, fontSize: 16),
                )
              else ...[
                DropdownButtonFormField<String>(
                  initialValue: _selectedBookingId,
                  decoration: InputDecoration(
                    labelText: 'Select tutor',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: _pendingReviewBookings.map((booking) {
                    return DropdownMenuItem<String>(
                      value: booking['bookingId'] as String?,
                      child: Text(booking['tutorName'] as String? ?? 'Unknown Tutor'),
                    );
                  }).toList(),
                  onChanged: (bookingId) {
                    if (bookingId == null) return;
                    final booking = _pendingReviewBookings.firstWhere(
                      (element) => element['bookingId'] == bookingId,
                      orElse: () => {},
                    );
                    if (booking.isEmpty) return;
                    setState(() {
                      _selectedBookingId = bookingId;
                      _bookingId = bookingId;
                      _tutorId = booking['tutorId'];
                      _tutorName = booking['tutorName'];
                      _subject = booking['subject'];
                    });
                  },
                ),
                const SizedBox(height: 12),
                Text(
                  _tutorName != null && _tutorName!.isNotEmpty ? 'Tutor: $_tutorName' : 'Tutor: Unknown',
                  style: const TextStyle(color: Colors.black54, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  _subject != null && _subject!.isNotEmpty ? 'Subject: $_subject' : 'Subject: Not specified',
                  style: const TextStyle(color: Colors.black54, fontSize: 16),
                ),
              ],
              const SizedBox(height: 24),
              const Text(
                'Your rating',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Slider(
                value: _rating,
                min: 1,
                max: 5,
                divisions: 4,
                label: _rating.toStringAsFixed(1),
                activeColor: const Color(0xFF6200EE),
                onChanged: (value) {
                  setState(() {
                    _rating = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Review',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _reviewController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Tell us about the tutoring session',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReview,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6200EE),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    _isSubmitting ? 'Submitting...' : 'Submit Review',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
