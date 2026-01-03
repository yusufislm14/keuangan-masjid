// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:masjid_alanwar/main.dart';

void main() {
  setUp(() async {
    // Clear SharedPreferences before each test
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Masjid Al-Anwar app shows login screen when not authenticated', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MasjidAlAnwarApp());
    
    // Wait for async operations (auth check) to complete
    await tester.pumpAndSettle();

    // Verify that our app shows the login screen
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('MASJID AL-ANWAR'), findsOneWidget);
  });

  testWidgets('Masjid Al-Anwar app shows home screen when authenticated', (WidgetTester tester) async {
    // Set up mock authentication state
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('username', 'admin');

    // Build our app and trigger a frame.
    await tester.pumpWidget(const MasjidAlAnwarApp());
    
    // Wait for async operations (auth check) to complete
    await tester.pumpAndSettle();

    // Verify that our app shows the home screen
    expect(find.text('Masjid Al-Anwar'), findsOneWidget);
    expect(find.text('Sisa Saldo Total'), findsOneWidget);
  });
}
