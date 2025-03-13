import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sign_in_life/widgets/battery_page.dart';
import 'package:sign_in_life/state/app_state.dart';
import 'package:sign_in_life/widgets/ble_page.dart';
import 'package:sign_in_life/widgets/camera_page.dart';
import 'package:sign_in_life/widgets/settings_page.dart';
import 'package:sign_in_life/widgets/video_page.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => AppState(), // 创建全局状态实例
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '测试APP',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    BatteryPage(),
    VideoPage(),
    BlePage(),
    CameraScreen(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        animationDuration: const Duration(seconds: 1),
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: _navBarItems,
      ),
    );
  }
}

const _navBarItems = [
  NavigationDestination(
    icon: Icon(Icons.battery_0_bar),
    selectedIcon: Icon(Icons.battery_full),
    label: 'Battery',
  ),
  NavigationDestination(
    icon: Icon(Icons.video_call_outlined),
    selectedIcon: Icon(Icons.video_call_rounded),
    label: 'Video',
  ),
  NavigationDestination(
    icon: Icon(Icons.bluetooth_outlined),
    selectedIcon: Icon(Icons.bluetooth_rounded),
    label: 'BLE',
  ),
  NavigationDestination(
    icon: Icon(Icons.camera_alt_outlined),
    selectedIcon: Icon(Icons.camera_alt_rounded),
    label: 'Camare',
  ),
  NavigationDestination(
    icon: Icon(Icons.settings_outlined),
    selectedIcon: Icon(Icons.settings_rounded),
    label: 'Settings',
  ),
];
