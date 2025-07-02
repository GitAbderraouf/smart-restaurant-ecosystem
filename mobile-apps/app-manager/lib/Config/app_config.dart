// import 'package:hungerz_store/Locale/arabic.dart';
// import 'package:hungerz_store/Locale/english.dart';
// import 'package:hungerz_store/Locale/french.dart';
// import 'package:hungerz_store/Locale/german.dart';
// import 'package:hungerz_store/Locale/indonesian.dart';
// import 'package:hungerz_store/Locale/italian.dart';
// import 'package:hungerz_store/Locale/portuguese.dart';
// import 'package:hungerz_store/Locale/romanian.dart';
// import 'package:hungerz_store/Locale/spanish.dart';
// import 'package:hungerz_store/Locale/swahili.dart';
// import 'package:hungerz_store/Locale/turkish.dart';

class AppConfig {
  static const String baseUrl = "http://192.168.207.160:5000/api";
  static const String socketUrl = "http://192.168.207.160:5000"; // Re-asserting to potentially refresh analyzer
  static final String appName = "Hungerz store";
  static final bool isDemoMode = true;
  static const String languageDefault = "en";
  static final Map<String, AppLanguage> languagesSupported = {
    "en": AppLanguage("English", {}), // Assuming english() returned a Map<String, String>
    // "ar": AppLanguage("عربى", arabic()),
    // "fr": AppLanguage("Français", french()),

  };
}

class AppLanguage {
  final String name;
  final Map<String, String> values;
  AppLanguage(this.name, this.values);
}
