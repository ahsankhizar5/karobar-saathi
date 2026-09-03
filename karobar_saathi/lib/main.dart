/// Karobar Saathi — voice-first financial evidence for Pakistani
/// micro-businesses.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens/home_shell.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: KarobarSaathiApp()));
}

class KarobarSaathiApp extends StatelessWidget {
  const KarobarSaathiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Karobar Saathi',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      builder: (BuildContext context, Widget? child) {
        // Respect the user's font-size preference but keep the layout intact.
        final MediaQueryData media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: media.textScaler.clamp(
              minScaleFactor: 0.9,
              maxScaleFactor: 1.4,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const HomeShell(),
    );
  }
}
