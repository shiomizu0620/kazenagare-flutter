import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/title_screen.dart';

// 🔴追加：Supabaseにアクセスするための「窓口」を変数として用意
final supabase = Supabase.instance.client;

Future<void> main() async {
  // Flutterのエンジンを初期化（非同期処理の前に必須）
  WidgetsFlutterBinding.ensureInitialized();

  // Supabaseの初期化
  await Supabase.initialize(
    url: 'https://zpvgyntquyirtwbxdurv.supabase.co/',
    anonKey: 'sb_publishable_kPIEeLz2GeVdeXgKPhEQRA_n8BZiCn9',
  );

  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => const KazenagareApp(),
    ),
  );
}

class KazenagareApp extends StatelessWidget {
  const KazenagareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      title: '風流れ - Kazenagare',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF05080C),
        fontFamily: 'Noto Serif JP',
        useMaterial3: true,
      ),
      home: const TitleScreen(),
    );
  }
}
