import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:android_app/screens/login_screen.dart';
import 'package:android_app/screens/register_screen.dart';

void main() {
  testWidgets('login form shows a validation error for an invalid email', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    await tester.enterText(find.byType(TextFormField).at(0), 'not-an-email');
    await tester.enterText(find.byType(TextFormField).at(1), '123456');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pump();

    expect(find.text('Email must contain @'), findsOneWidget);
  });

  testWidgets('login navigates to home on success', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          '/': (ctx) => const Text('HOME'),
          '/login': (ctx) => const LoginScreen(),
        },
        initialRoute: '/login',
      ),
    );

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'user@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), '123456');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pumpAndSettle();

    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('register form shows a validation error for an invalid email', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));

    await tester.enterText(find.byType(TextFormField).at(0), 'Daniel');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'seongchunlaw050gmail.com',
    );
    await tester.enterText(find.byType(TextFormField).at(2), '+1234567890');
    await tester.enterText(find.byType(TextFormField).at(3), '123 Main St');
    await tester.enterText(find.byType(TextFormField).at(4), '123456');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Create account'));
    await tester.pump();

    expect(find.text('Email must contain @'), findsOneWidget);
  });

  testWidgets('register form validates the full name and password length', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));

    await tester.enterText(find.byType(TextFormField).at(0), 'A');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'user@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(2), '+1234567890');
    await tester.enterText(find.byType(TextFormField).at(3), '123 Main St');
    await tester.enterText(find.byType(TextFormField).at(4), '123');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Create account'));
    await tester.pump();

    expect(find.text('Name must be at least 2 characters'), findsOneWidget);
    expect(find.text('Password must be at least 6 characters'), findsOneWidget);
  });
}
