import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kp_business_users/main.dart' as app;
import 'package:kp_business_users/app/modules/auth/login/login_view.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Login with wrong credentials test', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Verify we are on login screen
    expect(find.text('Welcome Back!'), findsOneWidget);

    // Find text fields
    final emailField = find.widgetWithText(TextFormField, 'Email / Phone');
    final passwordField = find.widgetWithText(TextFormField, 'Password');
    final loginButton = find.widgetWithText(ElevatedButton, 'Sign In');

    // Enter wrong credentials
    await tester.enterText(emailField, 'test@test.com');
    await tester.enterText(passwordField, 'wrongpassword');
    await tester.pumpAndSettle();

    // Tap login button
    await tester.tap(loginButton);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Verify error message appears
    expect(
      find.text('Login failed'),
      findsOneWidget,
    ); // Or whatever the error message is for connection error

    // Verify text fields still have content (not disposed/cleared)
    expect(find.text('test@test.com'), findsOneWidget);
    expect(find.text('wrongpassword'), findsOneWidget);
  });
}
