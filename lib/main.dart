import 'package:camera/camera.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:savdo_uz/core/theme/app_theme.dart';
import 'package:savdo_uz/firebase_options.dart';
import 'package:savdo_uz/providers/auth_provider.dart';
import 'package:savdo_uz/providers/cart_provider.dart';
import 'package:savdo_uz/providers/theme_provider.dart';
import 'package:savdo_uz/providers/locale_provider.dart';
import 'package:savdo_uz/screens/splash/splash_screen.dart'; // Splash Screen'ni chaqirish
import 'package:savdo_uz/services/auth_service.dart';
import 'package:savdo_uz/services/face_recognition_service.dart';
import 'package:savdo_uz/services/firestore_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:savdo_uz/models/inventory_item.dart';

/// Qurilma kameralarini global saqlash
List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await Hive.initFlutter();
  Hive.registerAdapter(InventoryItemAdapter());
  await Hive.openBox<InventoryItem>('inventory');
  try {
    cameras = await availableCameras();
  } catch (e, stack) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: e,
        stack: stack,
        library: 'camera',
        context: ErrorDescription('Kamerani initsializatsiya qilishda xatolik'),
      ),
    );
  }

  // Firebase Messaging permission va listener
  await FirebaseMessaging.instance.requestPermission();
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Push notification: ${message.notification?.title}');
  });

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        Provider<FaceRecognitionService>(
          create: (context) => FaceRecognitionService(
            Provider.of<FirestoreService>(context, listen: false),
          ),
          dispose: (_, service) => service.dispose(),
        ),
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
        ChangeNotifierProxyProvider<AuthService, AuthProvider>(
          create: (context) => AuthProvider(
            Provider.of<AuthService>(context, listen: false),
          ),
          update: (context, authService, previous) => AuthProvider(authService),
        ),
        ChangeNotifierProvider<CartProvider>(create: (_) => CartProvider()),
        ChangeNotifierProvider<LocaleProvider>(create: (_) => LocaleProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Mavzu (theme) provider'ini olish
    final themeProvider = Provider.of<ThemeProvider>(context);

    final localeProvider = Provider.of<LocaleProvider>(context);
    return MaterialApp(
      title: 'Savdo-UZ',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
      locale: localeProvider.locale,
      supportedLocales: const [
        Locale('uz'),
        Locale('ru'),
        Locale('en'),
        Locale('tr'),
      ],
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
