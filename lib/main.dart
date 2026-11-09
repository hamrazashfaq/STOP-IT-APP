import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'models/app_data.dart';
import 'theme.dart';
import 'localization/strings.dart';
import 'screens/app_shell.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(StopItApp(data: AppData()..load()));
}

class StopItApp extends StatelessWidget {
  const StopItApp({super.key, required this.data});
  final AppData data;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: data,
    builder: (context, _) => MaterialApp(
      title: 'STOP IT!', debugShowCheckedModeBanner: false,
      locale: Locale(data.language), supportedLocales: AppStrings.supported,
      localizationsDelegates: const [GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
      builder: (context, child) => Directionality(textDirection: AppStrings(Locale(data.language)).isRtl ? TextDirection.rtl : TextDirection.ltr, child: child ?? const SizedBox.shrink()),
      theme: ThemeData(
        brightness: Brightness.dark, scaffoldBackgroundColor: ink,
        colorScheme: const ColorScheme.dark(primary: emerald, secondary: gold, surface: panel, onSurface: Colors.white),
        useMaterial3: true, fontFamily: null,
        textTheme: const TextTheme(bodyMedium: TextStyle(color: Colors.white, height: 1.45), bodySmall: TextStyle(color: muted, height: 1.45)),
        appBarTheme: const AppBarTheme(backgroundColor: ink, foregroundColor: Colors.white, elevation: 0, centerTitle: false),
        navigationBarTheme: NavigationBarThemeData(backgroundColor: const Color(0xFF0C130F), indicatorColor: emerald.withValues(alpha: .28), labelTextStyle: WidgetStateProperty.all(const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
        cardTheme: CardThemeData(color: panel, elevation: 0, margin: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: BorderSide(color: Colors.white.withValues(alpha: .055)))),
        inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: panelLight, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none), hintStyle: const TextStyle(color: muted)),
        elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(backgroundColor: gold, foregroundColor: ink, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14), textStyle: const TextStyle(fontWeight: FontWeight.w700), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)))),
        outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(foregroundColor: gold, side: const BorderSide(color: gold), padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)))),
        snackBarTheme: SnackBarThemeData(backgroundColor: panelLight, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      ),
      home: AppShell(data: data),
    ),
  );
}
