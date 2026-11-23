import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revol_portal/features/home/presentation/views/report_view.dart';

void main() {
  for (final size in [const Size(375, 812), const Size(1440, 900)]) {
    testWidgets('report view lays out at ${size.width}px', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ReportView(isMobile: size.width < 768),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Report library'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
