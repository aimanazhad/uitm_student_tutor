import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class TutorBookingPage extends StatefulWidget {
  const TutorBookingPage({super.key});

  @override
  State<TutorBookingPage> createState() => _TutorBookingPageState();
}

class _TutorBookingPageState extends State<TutorBookingPage> {
  bool _isProcessing = false;
  bool _hasInitializedArgs = false;
  String _bookingId = '';
  String _studentId = '';
  String _studentName = 'Student';
  String _subject = 'Unknown subject';
  String _dateLabel = 'To be scheduled';
  String _status = 'pending';
  String? _errorMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasInitializedArgs) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _bookingId = args['id']?.toString() ?? '';
      _studentId = args['studentId']?.toString() ?? '';
      _studentName = args['studentName']?.toString() ?? 'Student';
      _subject = args['subject']?.toString() ?? 'Unknown subject';
      _dateLabel = args['dateLabel']?.toString() ?? 'To be scheduled';
      _status = args['status']?.toString().toLowerCase() ?? 'pending';
    }
    _hasInitializedArgs = true;
  }

  Future<void> _updateBookingStatus(String newStatus) async {
    if (_isProcessing || _bookingId.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    final updateData = {
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (newStatus == 'confirmed') {
      updateData['approvedAt'] = FieldValue.serverTimestamp();
    } else if (newStatus == 'rejected') {
      updateData['rejectedAt'] = FieldValue.serverTimestamp();
    }

    try {
      await FirebaseFirestore.instance.collection('bookings').doc(_bookingId).update(updateData);

      await NotificationService.addNotification(
        userId: _studentId,
        title: newStatus == 'confirmed' ? 'Booking Approved' : 'Booking Rejected',
        body: newStatus == 'confirmed'
            ? 'Your booking for $_subject has been approved by $_studentName.'
            : 'Your booking for $_subject has been rejected. Please try again later.',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus == 'confirmed'
                ? 'Booking approved successfully.'
                : 'Booking rejected successfully.',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop(true);
    } catch (error) {
      debugPrint('TutorBookingPage update error: $error');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unable to update booking status. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6200EE),
        title: const Text('Booking Request'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _studentName,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('Subject: $_subject', style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 6),
                  Text('Requested: $_dateLabel', style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 6),
                  Text(
                    'Status: ${_status[0].toUpperCase()}${_status.substring(1)}',
                    style: TextStyle(
                      fontSize: 16,
                      color: _status == 'pending'
                          ? Colors.orange
                          : _status == 'confirmed'
                              ? Colors.green
                              : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            if (_errorMessage != null) const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _status == 'pending' && !_isProcessing
                  ? () => _updateBookingStatus('confirmed')
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6200EE),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isProcessing && _status == 'pending'
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Approve Booking'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _status == 'pending' && !_isProcessing
                  ? () => _updateBookingStatus('rejected')
                  : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Reject Booking'),
            ),
          ],
        ),
      ),
    );
  }
}
