// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mesh_validate_auth_header/main.dart';

void main() {
  testWidgets('generate header', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    const size = Size(2048, 1024);
    await tester.binding.setSurfaceSize(size);
    tester.binding.window.physicalSizeTestValue = size;
    await tester.pumpWidget(const MyApp());

    final generateTab = find.text('generate header');
    expect(generateTab, findsOneWidget);
    await tester.tap(generateTab);
    await tester.pumpAndSettle();

    final mailbox = find.byKey(const Key('mailbox_id'));
    expect(mailbox, findsOneWidget);
    await tester.enterText(mailbox, "X26");

    final mailboxPassword = find.byKey(const Key('mailbox_password'));
    expect(mailboxPassword, findsOneWidget);
    await tester.enterText(mailboxPassword, "testing");

    final sharedKey = find.byKey(const Key('shared_key'));
    expect(sharedKey, findsOneWidget);
    await tester.enterText(sharedKey, "SharedKey");

    final nonce = find.byKey(const Key('nonce'));
    expect(nonce, findsOneWidget);
    await tester.enterText(nonce, "97bf007e-3027-4127-ac9d-f9a25de4de68");

    final nonceCount = find.byKey(const Key('nonce_count'));
    expect(nonceCount, findsOneWidget);
    await tester.enterText(nonceCount, "1");
    await tester.pump();

    final timestamp = find.byKey(const Key('timestamp'));
    expect(timestamp, findsOneWidget);
    await tester.enterText(timestamp, "202210241155");
    await tester.pump();

    await tester.ensureVisible(find.byKey(const Key('generate_button')));
    await tester.pumpAndSettle();
    final generateButton = find.byKey(const Key('generate_button'));
    expect(generateButton, findsOneWidget);
    await tester.tap(generateButton);
    await tester.pumpAndSettle();

    final generated = find.byKey(const Key('generated_token'));
    expect(generated, findsOneWidget);

    final generatedText = tester.widget<TextField>(generated);
    var controllerText = generatedText.controller!.text;

    expect(controllerText, equals("NHSMESH X26:97bf007e-3027-4127-ac9d-f9a25de4de68:1:202210241155:b1a882d3615305602f10b8f9a0453865284ce3e4b9e88e7899fb8bb5339da179"));


  });

  testWidgets('validate header', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    const size = Size(2048, 1024);
    await tester.binding.setSurfaceSize(size);
    tester.binding.window.physicalSizeTestValue = size;
    await tester.pumpWidget(const MyApp());

    final generateTab = find.text('validate header');
    expect(generateTab, findsOneWidget);
    await tester.tap(generateTab);
    await tester.pumpAndSettle();

    final mailbox = find.byKey(const Key('mailbox_id'));
    expect(mailbox, findsOneWidget);
    await tester.enterText(mailbox, "X26");

    final mailboxPassword = find.byKey(const Key('mailbox_password'));
    expect(mailboxPassword, findsOneWidget);
    await tester.enterText(mailboxPassword, "testing");

    final sharedKey = find.byKey(const Key('shared_key'));
    expect(sharedKey, findsOneWidget);
    await tester.enterText(sharedKey, "SharedKey");

    final token = find.byKey(const Key('token'));
    expect(token, findsOneWidget);
    await tester.enterText(token, "NHSMESH X26:97bf007e-3027-4127-ac9d-f9a25de4de68:1:202210241155:b1a882d3615305602f10b8f9a0453865284ce3e4b9e88e7899fb8bb5339da179");

    await tester.ensureVisible(find.byKey(const Key('validate_button')));
    await tester.pumpAndSettle();
    final generateButton = find.byKey(const Key('validate_button'));
    expect(generateButton, findsOneWidget);
    await tester.tap(generateButton);
    await tester.pumpAndSettle();

    final validationText = find.text("token is valid! and hmac matches mailbox password and shared key");
    expect(validationText, findsOneWidget);
    Text validationTextWid = tester.widget<Text>(validationText);
    expect(validationTextWid.style!.color, equals(Colors.green));

  });

}
