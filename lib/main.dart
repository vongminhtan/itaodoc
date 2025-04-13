// File: lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'view_models/browser_view_model.dart';
import 'screens/content_screen.dart';

void main() {
  runApp(ReadingApp());
}

class ReadingApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<BrowserViewModel>(
      create: (_) => BrowserViewModel(),
      child: MaterialApp(
        title: 'Flutter Reading Mode',
        theme: ThemeData(
          primaryColor: Color(0xFF2196F3),
          scaffoldBackgroundColor: Color(0xFFDEF1FD),
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
          fontFamily: 'Noto Sans',
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            elevation: 0,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
            ),
          ),
        ),
        locale: const Locale('vi', 'VN'),
        supportedLocales: const [
          Locale('vi', 'VN'),
          Locale('en', 'US'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: ContentScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
