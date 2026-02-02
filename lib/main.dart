import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/config/routes.dart';
import 'core/config/themes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Preload fonts
  GoogleFonts.config.allowRuntimeFetching = true;
  
  runApp(
    const ProviderScope(
      child: RideConnectApp(),
    ),
  );
}

class RideConnectApp extends ConsumerWidget {
  const RideConnectApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    
    return MaterialApp.router(
      title: 'RideConnect',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
