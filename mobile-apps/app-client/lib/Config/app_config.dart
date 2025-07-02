import 'package:hungerz/Locale/arabic.dart';
import 'package:hungerz/Locale/english.dart';
import 'package:hungerz/Locale/french.dart';
import 'package:hungerz/Locale/german.dart';
import 'package:hungerz/Locale/indonesian.dart';
import 'package:hungerz/Locale/italian.dart';
import 'package:hungerz/Locale/portuguese.dart';
import 'package:hungerz/Locale/romanian.dart';
import 'package:hungerz/Locale/spanish.dart';
import 'package:hungerz/Locale/swahili.dart';
import 'package:hungerz/Locale/turkish.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

  // Utiliser static pour un accès facile: AppConfig.baseUrl


class AppConfig {
  static final String appName = "Hungerz";
  static final bool isDemoMode = false;
  static const String languageDefault = "en";
  static final Map<String, AppLanguage> languagesSupported = {
    "en": AppLanguage("English", english()),
    "ar": AppLanguage("عربى", arabic()),
    "pt": AppLanguage("Portugal", portuguese()),
    "fr": AppLanguage("Français", french()),
    "id": AppLanguage("Bahasa Indonesia", indonesian()),
    "es": AppLanguage("Español", spanish()),
    "it": AppLanguage("italiano", italian()),
    "tr": AppLanguage("Türk", turkish()),
    "sw": AppLanguage("Kiswahili", swahili()),
    "de": AppLanguage("Deutsch", german()),
    "ro": AppLanguage("Română", romanian()),
  };

    static String get baseUrl {
    // Fournit une valeur par défaut si .env ou la clé manque
    return dotenv.env['BASE_URL'] ?? 'http://ERREUR_URL_NON_DEFINIE';
  }

  static String get googleApiKey {
    // Pour la clé API, une erreur est peut-être préférable si elle manque
    final key = dotenv.env['Maps_API_KEY'];
    if (key == null || key.isEmpty) {
       print("ERREUR CRITIQUE : Maps_API_KEY non trouvée dans le fichier .env !");
       // Vous pourriez lancer une exception ou retourner une clé invalide pour voir l'erreur
       return 'ERREUR_CLE_API_MANQUANTE';
    }
    return key;
  }
  static String get serverClientId {
    // Fournit une valeur par défaut si .env ou la clé manque
    return dotenv.env['SERVER_CLIENT_ID'] ?? 'ERREUR_CLIENT_ID_NON_DEFINI';
  }

  static String get serverClientSecret {
    // Fournit une valeur par défaut si .env ou la clé manque
    return dotenv.env['SERVER_CLIENT_SECRET'] ?? 'ERREUR_CLIENT_SECRET_NON_DEFINI';
  }
  static String get stripePublishableKey {
    // Fournit une valeur par défaut si .env ou la clé manque
    return dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? 'ERREUR_CLE_PUBLIQUE_STRIPE_NON_DEFINIE';
  }
  static String get stripeSecretKey {
    // Fournit une valeur par défaut si .env ou la clé manque
    return dotenv.env['STRIPE_SECRET_KEY'] ?? 'ERREUR_CLE_SECRETE_STRIPE_NON_DEFINIE';
}
}


class AppLanguage {
  final String name;
  final Map<String, String> values;
  AppLanguage(this.name, this.values);
}
