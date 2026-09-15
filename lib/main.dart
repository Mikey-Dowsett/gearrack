import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gearrack/pages/inventory_page.dart';
import 'package:gearrack/widgets/paper_texture.dart';
import 'package:gearrack/theme/app_theme.dart';
import 'package:gearrack/database/database_helper.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await DatabaseHelper.instance.database;

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(
    ScreenUtilInit(
      designSize: const Size(412, 915),
      minTextAdapt: true,
      builder: (context, child) {
        return const GearRackApp();
      },
      child: const MainNavigationScreen(),
    ),
  );
}

class GearRackApp extends StatefulWidget {
  const GearRackApp({super.key});

  @override
  State<GearRackApp> createState() => _GearRackAppState();
}

class _GearRackAppState extends State<GearRackApp> {
  @override
  void initState() {
    super.initState();
  }

  void _onThemeChanged() {}

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GearRack',
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      home: MainNavigationScreen(onThemeChanged: _onThemeChanged),
      builder: (context, child) {
        return Stack(
          children: [
            child!,
            const Positioned.fill(child: PaperTexture()),
          ],
        );
      },
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  final VoidCallback? onThemeChanged;

  const MainNavigationScreen({super.key, this.onThemeChanged});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  @override
  Widget build(BuildContext context) {
    return InventoryPage(onThemeChanged: widget.onThemeChanged);
  }
}