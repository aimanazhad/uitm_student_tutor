import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uitm_student_tutor/pages/studdrawer_page.dart';

void main() {
  testWidgets('Student drawer opens and shows menu items', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          drawer: StudentDrawerPage(),
          body: SizedBox(),
        ),
      ),
    );

    final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
    scaffoldState.openDrawer();
    await tester.pumpAndSettle();

    expect(find.text('Student Menu'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Find Tutor'), findsOneWidget);
  });
}
