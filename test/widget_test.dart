import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gearrack/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(412, 915),
        minTextAdapt: true,
        builder: (context, child) {
          return const MaterialApp(home: MainNavigationScreen());
        },
      ),
    );

    expect(find.text('Gear'), findsOneWidget);
    expect(find.text('Packs'), findsOneWidget);
    expect(find.text('Trips'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });
}
