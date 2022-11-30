// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.
import 'dart:io';
import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

const String longStr = 'Lorem Ipsum is simply dummy text of the printing and '
    'typesetting industry. Lorem Ipsum has been the industry\'s standard '
    'dummy text ever since the 1500s, when an unknown printer took a galley '
    'of type and scrambled it to make a type specimen book. It has survived '
    'not only five centuries, but also the leap into electronic typesetting, '
    'remaining essentially unchanged. It was popularised in the 1960s with '
    'the release of Letraset sheets containing Lorem Ipsum passages, and more'
    ' recently with desktop publishing software like Aldus PageMaker '
    'including versions of Lorem Ipsum.';

void main() {
  group('Basic tests', () {
    // First, define the Finders and use them to locate widgets from the

    // test suite. Note: the Strings provided to the `byValueKey` method must

    // be the same as the Strings we used for the Keys in step 1.

    late FlutterDriver driver;

    // Connect to the Flutter driver before running any tests.

    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });

    // Close the connection to the driver after the tests have completed.

    tearDownAll(() async {
      if (driver != null) {
        driver.close();
      }
    });

    test("check health", () async {
      Health health = await driver.checkHealth();

      print(health.status);
    });

    test("check health", () async {
      File file = File('screenshots/initial.png');
      await file.writeAsBytes(await driver.screenshot());

      await driver.tap(find.byValueKey('plainTextField'));
      await driver.enterText(longStr);
      file = File('screenshots/entered_text.png');
      await file.writeAsBytes(await driver.screenshot());

      await driver.tap(find.byValueKey('encrypt_button'));
      file = File('screenshots/encrypt_cbc.png');
      await file.writeAsBytes(await driver.screenshot());

      await driver.tap(find.byValueKey('cipher_switch'));
      file = File('screenshots/cipher_switched.png');
      await file.writeAsBytes(await driver.screenshot());

      await driver.tap(find.byValueKey('encrypt_button'));
      file = File('screenshots/encrypt_ecb.png');
      await file.writeAsBytes(await driver.screenshot());

      await driver.tap(find.byValueKey('cipher_switch'));
      file = File('screenshots/cipher_switched_again.png');
      await file.writeAsBytes(await driver.screenshot());

      await driver.tap(find.byValueKey('decrypt_button'));
      file = File('screenshots/decryption_error.png');
      await file.writeAsBytes(await driver.screenshot());
    });
  });
}

String bytesToHex(List<int> bytes, {bool spaced = false}) {
  var result = StringBuffer();
  for (var part in bytes) {
    if (spaced && result.length > 0) {
      result.write(' ');
    }
    result.write(
        '${part < 16 ? '0' : ''}${part.toRadixString(16).toUpperCase()}');
  }
  return result.toString();
}
