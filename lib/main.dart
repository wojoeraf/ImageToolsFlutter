import 'package:flutter/material.dart';
import 'dart:io';
import 'package:window_manager/window_manager.dart';
import 'package:provider/provider.dart';
import 'package:image_tools/providers/app_state.dart';
import 'package:image_tools/screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Needed for plugins
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    // Initialize window manager and set window options
    await windowManager.ensureInitialized();
    const WindowOptions options = WindowOptions(
      size: Size(1000, 1200),
      minimumSize: Size(800, 600),
      center: true,
      title: 'Photographers Toolbox',
    );
    windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.show();
      await windowManager.focus();
    });
    // WindowManager.instance.setMinimumSize(const Size(1000, 600));
    // WindowManager.instance.setMaximumSize(const Size(1400, 600));
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppState(),
      child: MaterialApp(
        title: 'Photographers Toolbox',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          useMaterial3: true, // Optional: Use Material 3 design
          // Define other theme properties if needed
          cardTheme: CardTheme(
            elevation: 2.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 0),
          ),
          inputDecorationTheme: InputDecorationTheme(
             border: OutlineInputBorder(
               borderRadius: BorderRadius.circular(8.0),
             ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            ),
          ),
        ),
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false, // Hide debug banner
      ),
    );
  }
}