import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uitm_student_tutor/pages/studentbooking_page.dart';

void main() {
  testWidgets('Student booking page shows booking form', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: StudentBookingPage()));

    expect(find.text('Book a Subject Class'), findsOneWidget);
    expect(find.text('Subject'), findsOneWidget);
    expect(find.text('Select date'), findsOneWidget);
    expect(find.text('Select time'), findsOneWidget);
    expect(find.text('Request Booking'), findsOneWidget);
  });
}
