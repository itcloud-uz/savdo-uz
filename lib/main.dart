import 'package:camera/camera.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:savdo_uz/app.dart';
import 'package:savdo_uz/firebase_options.dart';
import 'package:savdo_uz/providers/auth_provider.dart';
import 'package:savdo_uz/providers/cart_provider.dart';
import 'package:savdo_uz/providers/theme_provider.dart';
import 'package:savdo_uz/services/auth_service.dart';
import 'package:savdo_uz/services/face_recognition_service.dart';
import 'package:savdo_uz/services/firestore_service.dart';

/// Qurilma kameralarini global saqlash
List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        /// Servislar
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<FirestoreService>(create: (_) => FirestoreService()),

        /// FaceRecognitionService FirestoreService’ga bog‘liq
        Provider<FaceRecognitionService>(
          create: (context) => FaceRecognitionService(
            Provider.of<FirestoreService>(context, listen: false),
          ),
          dispose: (_, service) => service.dispose(),
        ),

        /// State management providerlar
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(),
        ),
        ChangeNotifierProxyProvider<AuthService, AuthProvider>(
          create: (context) => AuthProvider(
            Provider.of<AuthService>(context, listen: false),
          ),
          update: (context, authService, previous) => AuthProvider(authService),
        ),
        ChangeNotifierProvider<CartProvider>(
          create: (_) => CartProvider(),
        ),
      ],
      child: const App(),
    );
  }
}
