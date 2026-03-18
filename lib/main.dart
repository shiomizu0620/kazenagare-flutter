import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'screens/title_screen.dart';

void main() {
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
