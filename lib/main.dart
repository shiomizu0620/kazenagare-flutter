import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'screens/title_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  // Flutterのエンジンを初期化（非同期処理の前に必須）
  WidgetsFlutterBinding.ensureInitialized();

  // 👇 Supabaseの初期化を追加
  // TODO: ご自身のSupabaseプロジェクトのURLとAnon Keyに書き換えてください
  await Supabase.initialize(
    url: 'https://zpvgyntquyirtwbxdurv.supabase.co',
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
        // 全体的に暗く、風流なテーマに設定
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF05080C), // wa-blackに近い色
        fontFamily: 'Noto Serif JP', // ※あとでpubspec.yamlにフォントを追加推奨
        useMaterial3: true,
      ),
      home: const TitleScreen(),
    );
  }
}
