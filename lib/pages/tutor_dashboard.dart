import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'forum_page.dart';
import 'tutorProfile_page.dart';
import '../services/notification_service.dart';

class TutorDashboard extends StatefulWidget {
  const TutorDashboard({super.key});

  @override
  State<TutorDashboard> createState() => _TutorDashboardState();
}

class SessionInfo {
  final String id;
  final String studentId;
  final String subject;
  final String status;
  final String dateLabel;
  final String studentName;
  final String avatar;

  SessionInfo({
    required this.id,
    required this.studentId,
    required this.subject,
    required this.status,
    required this.dateLabel,
    required this.studentName,
    required this.avatar,
  });
}

class BookingRequest {
  final String id;
  final String subject;
  final String status;
  final String dateLabel;
  final String studentName;
  final String avatar;
  final String studentId;

  BookingRequest({
    required this.id,
    required this.subject,
    required this.status,
    required this.dateLabel,
    required this.studentName,
    required this.avatar,
    required this.studentId,
  });
}

class _TutorDashboardState extends State<TutorDashboard> {
  int _selectedIndex = 0;
  String _tutorName = 'Tutor';
  int _studentsTaught = 0;
  double _rating = 0.0;
  int _hours = 0;
  SessionInfo? _liveSession;
  SessionInfo? _nextSession;
  List<BookingRequest> _pendingBookings = [];
  List<BookingRequest> _allBookings = [];
  StreamSubscription<QuerySnapshot>? _bookingSubscription;

  @override
  void initState() {
    super.initState();
    _loadTutorData();
    _subscribeToBookingUpdates();
  }

  Future<void> _loadTutorData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final userData = userDoc.data() ?? {};
    final role = userData['role']?.toString() ?? '';
    final tutorStatus = userData['tutorStatus']?.toString() ?? '';

    if (role != 'tutor' || tutorStatus != 'approved') {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tutor access requires admin approval.'),
          backgroundColor: Colors.orange,
        ),
      );
      Navigator.of(context).pushReplacementNamed('/student-dashboard');
      return;
    }

    final studentsTaught = userData['studentsTaught'];
    final rating = userData['rating'];
    final hours = userData['hours'];

    SessionInfo? liveSession;
    SessionInfo? nextSession;
    final pendingBookings = <BookingRequest>[];
    final allBookings = <BookingRequest>[];

    final bookingSnapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('tutorId', isEqualTo: user.uid)
        .get();

    for (final doc in bookingSnapshot.docs) {
      final data = doc.data();
      final status = (data['status'] ?? '').toString().toLowerCase();
      final subject = data['subject']?.toString() ?? 'Unknown subject';
      final requestedDate = data['requestedDate'];
      final requestedTime = data['requestedTime']?.toString() ?? '';
      final studentName = data['studentName']?.toString() ?? 'Pending student';
      final studentId = data['studentId']?.toString() ?? '';
      final dateLabel = requestedDate is Timestamp
          ? '${requestedDate.toDate().day}/${requestedDate.toDate().month}/${requestedDate.toDate().year} ${requestedTime.isNotEmpty ? requestedTime : ''}'.trim()
          : requestedTime.isNotEmpty
              ? requestedTime
              : 'To be scheduled';
      final avatar = subject.isNotEmpty ? subject.trim()[0].toUpperCase() : 'T';

      final sessionInfo = SessionInfo(
        id: doc.id,
        studentId: studentId,
        subject: subject,
        status: status,
        dateLabel: dateLabel,
        studentName: studentName,
        avatar: avatar,
      );

      final bookingRequest = BookingRequest(
        id: doc.id,
        subject: subject,
        status: status,
        dateLabel: dateLabel,
        studentName: studentName,
        avatar: avatar,
        studentId: studentId,
      );

      if (status == 'pending') {
        pendingBookings.add(bookingRequest);
      }
      allBookings.add(bookingRequest);

      if (liveSession == null && status == 'live') {
        liveSession = sessionInfo;
      }

      if (nextSession == null && (status == 'pending' || status == 'confirmed')) {
        nextSession = sessionInfo;
      }
    }

    if (!mounted) return;
    setState(() {
      _tutorName = userData['name']?.toString() ?? 'Tutor';
      _studentsTaught = studentsTaught is num ? studentsTaught.toInt() : 0;
      _rating = rating is num ? rating.toDouble() : 0.0;
      _hours = hours is num ? hours.toInt() : 0;
      _liveSession = liveSession;
      _nextSession = nextSession;
      _pendingBookings = pendingBookings;
      _allBookings = allBookings;
    });
  }

  void _subscribeToBookingUpdates() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _bookingSubscription = FirebaseFirestore.instance
        .collection('bookings')
        .where('tutorId', isEqualTo: user.uid)
        .snapshots()
        .listen((snapshot) async {
      await _loadTutorData();
    });
  }

  @override
  void dispose() {
    _bookingSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF6200EE),
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Color(0xFF6200EE), size: 18),
            ),
            onPressed: () {
              // Open drawer or profile
            },
          ),
        ),
        title: const Text(
          'UITM Student Tutor',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          _buildNotificationMenu(),
        ],
      ),
      body: _selectedIndex == 0
          ? _buildHomeTab()
          : _selectedIndex == 1
              ? _buildBookingsTab()
              : _selectedIndex == 2
                  ? _buildForumTab()
                  : _buildProfileTab(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.forum_outlined),
            activeIcon: Icon(Icons.forum),
            label: 'Forum',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outlined),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Welcome Banner
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6200EE), Color(0xFF03DAC6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, $_tutorName! 👨‍🏫',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage your sessions and students',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          // Quick Stats
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildStatCard(
                  icon: Icons.people_outlined,
                  title: 'Students',
                  value: '$_studentsTaught',
                  color: Colors.blue,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  icon: Icons.star_outlined,
                  title: 'Rating',
                  value: _rating.toStringAsFixed(1),
                  color: Colors.amber,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  icon: Icons.schedule_outlined,
                  title: 'Hours',
                  value: '$_hours',
                  color: Colors.green,
                ),
              ],
            ),
          ),

          if (_liveSession != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Live Session',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildLiveSessionCard(
                    studentName: _liveSession!.studentName,
                    subject: _liveSession!.subject,
                    duration: 'Live now',
                    avatar: _liveSession!.avatar,
                  ),
                ],
              ),
            ),

          if (_liveSession != null) const SizedBox(height: 24),

          if (_nextSession != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Next Session',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSessionCard(
                    studentName: _nextSession!.studentName,
                    subject: _nextSession!.subject,
                    date: _nextSession!.dateLabel,
                    status: _nextSession!.status == 'pending'
                        ? 'Pending'
                        : _nextSession!.status == 'confirmed'
                            ? 'Confirmed'
                            : _nextSession!.status[0].toUpperCase() + _nextSession!.status.substring(1),
                    avatar: _nextSession!.avatar,
                  ),
          if (_nextSession!.status == 'confirmed')
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: ElevatedButton(
                onPressed: () => _endSession(_nextSession!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('End Session'),
              ),
            ),
                ],
              ),
            ),

          if (_nextSession != null) const SizedBox(height: 24),

          if (_nextSession == null && _liveSession == null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No active sessions yet',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Your next session will appear here once students book with you.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),

          if (_nextSession != null || _liveSession != null)
            const SizedBox(height: 24),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
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
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(12),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionCard({
    required String studentName,
    required String subject,
    required String date,
    required String status,
    required String avatar,
  }) {
    return Container(
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
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6200EE), Color(0xFF03DAC6)],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                avatar,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  studentName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subject,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: status.toLowerCase() == 'confirmed'
                  ? Colors.green.withValues(alpha: 0.1)
                  : status.toLowerCase() == 'completed'
                      ? Colors.blue.withValues(alpha: 0.1)
                      : status.toLowerCase() == 'pending'
                          ? Colors.orange.withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(
              status,
              style: TextStyle(
                color: status.toLowerCase() == 'confirmed'
                    ? Colors.green
                    : status.toLowerCase() == 'completed'
                        ? Colors.blue
                        : status.toLowerCase() == 'pending'
                            ? Colors.orange
                            : Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveSessionCard({
    required String studentName,
    required String subject,
    required String duration,
    required String avatar,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.15),
            blurRadius: 15,
            spreadRadius: 1,
          ),
        ],
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B6B), Color(0xFFFF8E72)],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                avatar,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  studentName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subject,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  duration,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF6B6B),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'LIVE',
                  style: TextStyle(
                    color: Color(0xFFFF6B6B),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Student Bookings',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Manage your student booking requests and sessions here.',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 24),
          const Text(
            'Pending Requests',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (_pendingBookings.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text('No pending booking requests at the moment.'),
            )
          else
            Column(
              children: _pendingBookings.map((booking) {
                return GestureDetector(
                  onTap: () async {
                    final updated = await Navigator.pushNamed(
                      context,
                      '/tutor-booking',
                      arguments: {
                        'id': booking.id,
                        'studentId': booking.studentId,
                        'studentName': booking.studentName,
                        'subject': booking.subject,
                        'dateLabel': booking.dateLabel,
                        'status': booking.status,
                      },
                    );

                    if (updated == true) {
                      await _loadTutorData();
                    }
                  },
                  child: _buildPendingBookingCard(booking),
                );
              }).toList(),
            ),
          const SizedBox(height: 24),
          const Text(
            'All Bookings',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (_allBookings.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text('There are no bookings yet.'),
            )
          else
            Column(
              children: _allBookings.map(_buildBookingHistoryCard).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildForumTab() {
    return const ForumPage();
  }

  Future<void> _updateBookingStatus(BookingRequest booking, String newStatus) async {
    try {
      final updateData = {
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (newStatus == 'confirmed') {
        updateData['approvedAt'] = FieldValue.serverTimestamp();
      } else if (newStatus == 'rejected') {
        updateData['rejectedAt'] = FieldValue.serverTimestamp();
      }

      await FirebaseFirestore.instance.collection('bookings').doc(booking.id).update(updateData);

      await NotificationService.addNotification(
        userId: booking.studentId,
        title: newStatus == 'confirmed' ? 'Booking Approved' : 'Booking Rejected',
        body: newStatus == 'confirmed'
            ? 'Your booking for ${booking.subject} with $_tutorName has been approved.'
            : 'Your booking for ${booking.subject} with $_tutorName has been rejected.',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus == 'confirmed'
                ? 'Booking approved for ${booking.studentName}.'
                : 'Booking rejected for ${booking.studentName}.',
          ),
          backgroundColor: Colors.green,
        ),
      );
      await _loadTutorData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to update booking status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _endSession(SessionInfo session) async {
    try {
      await FirebaseFirestore.instance.collection('bookings').doc(session.id).update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await NotificationService.addNotification(
        userId: session.studentId,
        title: 'Session Completed',
        body: 'Your session for ${session.subject} has been marked complete by $_tutorName.',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session ended successfully.'),
          backgroundColor: Colors.green,
        ),
      );
      await _loadTutorData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to end session: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildPendingBookingCard(BookingRequest booking) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                booking.studentName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                booking.status[0].toUpperCase() + booking.status.substring(1),
                style: const TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Subject: ${booking.subject}'),
          const SizedBox(height: 4),
          Text('Requested: ${booking.dateLabel}'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _updateBookingStatus(booking, 'confirmed'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6200EE),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Approve'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _updateBookingStatus(booking, 'rejected'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Reject'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBookingHistoryCard(BookingRequest booking) {
    final status = booking.status[0].toUpperCase() + booking.status.substring(1);
    final statusColor = booking.status == 'confirmed'
        ? Colors.green
        : booking.status == 'rejected'
            ? Colors.red
            : Colors.orange;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                booking.avatar,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.studentName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text('Subject: ${booking.subject}'),
                const SizedBox(height: 4),
                Text('Requested: ${booking.dateLabel}'),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(color: statusColor, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    return const TutorProfilePage();
  }

  Widget _buildNotificationMenu() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return IconButton(
        icon: const Icon(Icons.notifications_outlined, color: Colors.white),
        onPressed: () {},
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data?.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data['read'] != true;
            }).length ?? 0;

        return PopupMenuButton<String>(
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_outlined, color: Colors.white),
              if (unreadCount > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        unreadCount > 9 ? '9+' : '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          color: Colors.white,
          itemBuilder: (context) {
            if (snapshot.hasError) {
              return const [
                PopupMenuItem<String>(
                  value: 'error',
                  child: Text('Unable to load notifications'),
                ),
              ];
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const [
                PopupMenuItem<String>(
                  value: 'loading',
                  child: Text('Loading notifications...'),
                ),
              ];
            }

            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return const [
                PopupMenuItem<String>(
                  value: 'empty',
                  child: Text('No notifications yet'),
                ),
              ];
            }

            return docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final title = data['title']?.toString() ?? 'Notification';
              final body = data['body']?.toString() ?? '';
              final read = data['read'] as bool? ?? false;
              return PopupMenuItem<String>(
                value: doc.id,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: read ? Colors.black54 : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[700], fontSize: 12),
                    ),
                  ],
                ),
              );
            }).toList();
          },
          onSelected: (selectedId) async {
            if (selectedId == 'loading' || selectedId == 'empty' || selectedId == 'error') {
              return;
            }
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('notifications')
                .doc(selectedId)
                .update({'read': true});
          },
        );
      },
    );
  }
}
