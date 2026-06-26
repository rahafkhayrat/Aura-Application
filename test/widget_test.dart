import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aura_app/Screens/SignUp.dart';
import 'package:aura_app/Screens/LoginPage.dart' as login_page;

void main() {
  testWidgets('LoginPage loads successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MaterialApp(home: login_page.LoginPage()));

    // Verify that our login page loads correctly
    expect(find.byType(login_page.LoginPage), findsOneWidget);
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Sign in to continue your journey'), findsOneWidget);
  });

  testWidgets('SignUp page loads successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SignUp()));

    // Verify signup page loads correctly
    expect(find.byType(SignUp), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget);
    expect(find.text('Join us and start your journey'), findsOneWidget);
  });

  testWidgets('ForgotPasswordPage loads successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: login_page.ForgotPasswordPage()));

    // Verify forgot password page loads correctly
    expect(find.byType(login_page.ForgotPasswordPage), findsOneWidget);
    expect(find.text('Reset Password'), findsOneWidget);
    expect(find.text('Enter your email to receive a reset link'), findsOneWidget);
  });
}
