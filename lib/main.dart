import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart'; // Para encender el motor de Firebase
import 'firebase_options.dart';                    // Las credenciales de tu proyecto
import 'app.dart';

void main() async { // Convertimos la función en asíncrona con 'async'
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Inicializamos Firebase antes de cargar las vistas
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // 2. Mantenemos intacta la configuración visual de tu compañera
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  
  // 3. Arrancamos la aplicación que ella diseñó
  runApp(const WatiApp());
}