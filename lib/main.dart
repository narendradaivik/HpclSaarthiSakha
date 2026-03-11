import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const HighwayRewardsApp());
}

class HighwayRewardsApp extends StatelessWidget {
  const HighwayRewardsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final _notoTextTheme = GoogleFonts.notoSansDevanagariTextTheme();
    return MaterialApp(
      title: 'Highway Rewards',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: GoogleFonts.notoSansDevanagari().fontFamily,
        textTheme: _notoTextTheme,
        primaryTextTheme: _notoTextTheme,
      ),
      home: const SplashScreen(),
    );
  }
}
