/// Employee Productivity Tracker
/// Main entry point of the application
/// Initializes providers, database, window management, and system tray
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'providers/task_provider.dart';
import 'providers/screenshot_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/sign_in_screen.dart';
import 'screens/home_screen.dart';
import 'core/constants/app_constants.dart';
import 'core/constants/azure_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize window manager for desktop
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();

    // Set window properties
    WindowOptions windowOptions = const WindowOptions(
      size: Size(AppConstants.defaultWindowWidth, AppConstants.defaultWindowHeight),
      minimumSize: Size(AppConstants.minWindowWidth, AppConstants.minWindowHeight),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
      title: AppConstants.appName,
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => ScreenshotProvider()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.dark(
            primary: const Color(0xFF1c4d2c), // Main green
            secondary: const Color(0xFF2d7a47), // Lighter green
            tertiary: const Color(0xFF0f2619), // Darkest green
            surface: const Color(0xFF1a1a1a), // Pure dark background
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onSurface: const Color(0xFFe8e8e8),
            error: const Color(0xFFff5252),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFF0d0d0d),
          cardTheme: CardThemeData(
            elevation: 8,
            shadowColor: const Color(0xFF1c4d2c).withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: const Color(0xFF1a1a1a),
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Color(0xFF1c4d2c),
            foregroundColor: Colors.white,
            elevation: 8,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1c4d2c),
              foregroundColor: Colors.white,
              elevation: 4,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF2d7a47),
            ),
          ),
          textTheme: const TextTheme(
            displayLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            displayMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            displaySmall: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            headlineLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            headlineMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            headlineSmall: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            titleMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            titleSmall: TextStyle(color: Color(0xFFb0b0b0)),
            bodyLarge: TextStyle(color: Color(0xFFe8e8e8)),
            bodyMedium: TextStyle(color: Color(0xFFb0b0b0)),
            bodySmall: TextStyle(color: Color(0xFF808080)),
            labelLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFF1a1a1a),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2a2a2a)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2a2a2a)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1c4d2c), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFff5252)),
            ),
            labelStyle: const TextStyle(color: Color(0xFFb0b0b0)),
            hintStyle: const TextStyle(color: Color(0xFF606060)),
          ),
          dividerTheme: const DividerThemeData(
            color: Color(0xFF2a2a2a),
            thickness: 1,
          ),
        ),
        home: const AppInitializer(),
      ),
    );
  }
}

/// AppInitializer
/// Handles app initialization and checks if user needs to setup profile
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> with TrayListener {
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
    _initializeTray();
  }

  Future<void> _initializeApp() async {
    final authProvider = context.read<AuthProvider>();
    final taskProvider = context.read<TaskProvider>();
    final screenshotProvider = context.read<ScreenshotProvider>();

    // Initialize providers
    await authProvider.initialize();
    await taskProvider.initialize();

    // Load settings and initialize screenshot provider
    final prefs = await SharedPreferences.getInstance();
    final azureAccount = prefs.getString(AppConstants.settingsAzureStorageAccount) ?? '';
    final azureKey = prefs.getString(AppConstants.settingsAzureAccessKey) ?? '';
    final azureContainer = prefs.getString(AppConstants.settingsAzureContainerName) ?? 'employee-screenshots';

    await screenshotProvider.initialize(
      azureConfig: AzureConfig(
        storageAccount: azureAccount,
        accessKey: azureKey,
        containerName: azureContainer,
      ),
    );

    setState(() => _isInitializing = false);
  }

  Future<void> _initializeTray() async {
    if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
      return;
    }

    trayManager.addListener(this);

    await trayManager.setIcon(
      Platform.isWindows
          ? 'assets/app_icon.ico'
          : 'assets/app_icon.png',
    );

    Menu menu = Menu(
      items: [
        MenuItem(
          key: 'show_window',
          label: 'Show Window',
        ),
        MenuItem.separator(),
        MenuItem(
          key: 'exit_app',
          label: 'Exit',
        ),
      ],
    );

    await trayManager.setContextMenu(menu);
  }

  @override
  void onTrayIconMouseDown() {
    windowManager.show();
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    if (menuItem.key == 'show_window') {
      windowManager.show();
    } else if (menuItem.key == 'exit_app') {
      windowManager.destroy();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initializing...'),
            ],
          ),
        ),
      );
    }

    // Check if user is logged in
    final authProvider = context.watch<AuthProvider>();
    if (authProvider.isLoggedIn) {
      return const HomeScreen();
    } else {
      return const SignInScreen();
    }
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: .center,
          children: [
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
