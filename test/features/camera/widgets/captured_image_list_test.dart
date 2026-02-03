import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_to_pdf/features/camera/widgets/captured_image_list.dart';

void main() {
  testWidgets('CapturedImageList shows nothing when empty',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CapturedImageList(
            images: [],
          ),
        ),
      ),
    );

    // Should return SizedBox.shrink() effectively, so no Image widgets
    expect(find.byType(Image), findsNothing);
    expect(find.byType(ListView), findsNothing);
  });
}
