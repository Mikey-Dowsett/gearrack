import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gearrack/pages/gear.dart';
import 'package:gearrack/pages/packs.dart';
import 'package:gearrack/theme/app_theme.dart';
import 'package:gearrack/database/database_helper.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // On desktop platforms, sqflite needs the FFI backend.
  // Mobile (Android/iOS) uses the native plugin automatically.
  if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Initialize the database before running the app.
  await DatabaseHelper.instance.database;

  // Use edge-to-edge so system UI (status/navigation bars) remain visible
  // and the app can respect device safe areas (camera cutouts / notches).
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  runApp(
    ScreenUtilInit(
      designSize: const Size(412, 915), // Reference design size
      minTextAdapt: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'GearRack',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light,
          home: child,
        );
      },
      child: const MainNavigationScreen(),
    ),
  );
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [HomePage(), PacksPage()];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        top: true,
        bottom: false,
        child: IndexedStack(index: _selectedIndex, children: _pages),
      ),
      // Wrap the BottomNavigationBar in a SafeArea so it won't overlap
      // device navigation bars / gesture areas on phones with cutouts.
      bottomNavigationBar: SafeArea(
        left: false,
        right: false,
        bottom: true,
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: FaIcon(FontAwesomeIcons.tent),
              label: 'Gear',
            ),
            BottomNavigationBarItem(
              icon: FaIcon(FontAwesomeIcons.suitcase),
              label: 'Packs',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: colors.primary,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
