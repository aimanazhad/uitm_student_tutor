import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'forum_page.dart';
import 'tutorProfile_page.dart';

class TutorDashboard extends StatefulWidget {
  const TutorDashboard({super.key});

  @override
  State<TutorDashboard> createState() => _TutorDashboardState();
}

class SessionInfo {
  final String subject;
  final String status;
  final String dateLabel;
  final String studentName;
  final String avatar;

  SessionInfo({
    required this.subject,
    required this.status,
    required this.dateLabel,
    required this.studentName,
    required this.avatar,
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

  @override
  void initState() {
    super.initState();
    _loadTutorData();
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

    final bookingQuery = await FirebaseFirestore.instance
        .collection('bookings')
        .where('tutorId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .get();

    SessionInfo? liveSession;
    SessionInfo? nextSession;

    for (final doc in bookingQuery.docs) {
      final data = doc.data();
      final status = (data['status'] ?? '').toString().toLowerCase();
      final subject = data['subject']?.toString() ?? 'Unknown subject';
      final requestedDate = data['requestedDate'];
      final requestedTime = data['requestedTime']?.toString() ?? '';
      final studentName = data['studentName']?.toString() ?? 'Pending student';
      final dateLabel = requestedDate is Timestamp
          ? '${requestedDate.toDate().day}/${requestedDate.toDate().month}/${requestedDate.toDate().year} ${requestedTime.isNotEmpty ? requestedTime : ''}'.trim()
          : requestedTime.isNotEmpty
              ? requestedTime
              : 'To be scheduled';
      final avatar = subject.isNotEmpty ? subject.trim()[0].toUpperCase() : 'T';

      final sessionInfo = SessionInfo(
        subject: subject,
        status: status,
        dateLabel: dateLabel,
        studentName: studentName,
        avatar: avatar,
      );

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
    });
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
                    status: _nextSession!.status == 'pending' ? 'Pending' : 'Confirmed',
                    avatar: _nextSession!.avatar,
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
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(
              status,
              style: const TextStyle(
                color: Colors.green,
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
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.people_outlined, color: Color(0xFF6200EE)),
                    SizedBox(width: 8),
                    Text(
                      'Pending Requests',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('Review and accept/reject booking requests from students.'),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate to bookings management
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6200EE),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text(
                      'View All Bookings',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: const [
                Icon(Icons.info_outline, color: Color(0xFF6200EE)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Student booking requests will appear here for your review.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForumTab() {
    return const ForumPage();
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
