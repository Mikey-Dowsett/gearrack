import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gearrack/pages/inventory_page.dart';
import 'package:gearrack/pages/profile_page.dart';
import 'package:gearrack/widgets/paper_texture.dart';
import 'package:gearrack/theme/app_colors.dart';
import 'package:gearrack/theme/app_theme.dart';
import 'package:gearrack/theme/ui_constants.dart';
import 'package:gearrack/database/database_helper.dart';
import 'package:gearrack/database/app_settings_dao.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final dao = await AppSettingsDao.create();
      final settings = await dao.get();
      _applyTheme(settings.theme);
    } catch (_) {
      // Keep default
    }
  }

  void _applyTheme(String theme) {
    setState(() {
      _themeMode = switch (theme) {
        'dark' => ThemeMode.dark,
        'system' => ThemeMode.system,
        _ => ThemeMode.light,
      };
    });
  }

  void _onThemeChanged() {
    _loadTheme();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GearRack',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
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
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const InventoryPage(),
      ProfilePage(onThemeChanged: widget.onThemeChanged),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      body: SafeArea(
        top: true,
        bottom: false,
        child: IndexedStack(index: _selectedIndex, children: _pages),
      ),
      bottomNavigationBar: SafeArea(
        left: false,
        right: false,
        bottom: true,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: colors.borderStrong,
                width: UiConstants.borderWidth,
              ),
            ),
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: colors.surfaceRaised,
            elevation: 0,
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: FaIcon(FontAwesomeIcons.tent),
                label: 'Gear',
              ),
              BottomNavigationBarItem(
                icon: FaIcon(FontAwesomeIcons.solidUser),
                label: 'Profile',
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: colors.primary,
            unselectedItemColor: colors.textSecondary,
            showUnselectedLabels: true,
            onTap: _onItemTapped,
          ),
        ),
      ),
    );
  }
}