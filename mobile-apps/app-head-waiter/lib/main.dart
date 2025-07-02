import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';

import 'package:hungerz_ordering/Pages/table_selection.dart';
import 'package:hungerz_ordering/cubits/tables_status_cubit.dart';
import 'package:hungerz_ordering/services/chef_socket_service.dart';
import 'Locale/language_cubit.dart';
import 'Locale/locales.dart';
import 'Routes/routes.dart';
import 'Theme/style.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeRight,
    DeviceOrientation.landscapeLeft,
  ]);
  runApp(Phoenix(child: HungerzOrdering()));
}

class HungerzOrdering extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ChefSocketService>(
          create: (context) => ChefSocketService()..connectAndListen(), // Crée et connecte le service socket
          // Le service est un singleton et sera disposé quand le RepositoryProvider sera retiré de l'arbre,
          // mais la méthode dispose() du service est plus explicitement appelée dans le close() du Cubit qui l'utilise
          // si le Cubit est le seul à le "posséder".
          // Ici, on le laisse vivre tant que le RepositoryProvider existe.
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<TablesStatusCubit>(
            create: (context) => TablesStatusCubit(
              RepositoryProvider.of<ChefSocketService>(context),
            ),
          ),
          BlocProvider<LanguageCubit>(
            create: (context) => LanguageCubit(),
          ),
        ],
        child: BlocBuilder<LanguageCubit, Locale>(
          builder: (_, locale) {
            return MaterialApp(
              localizationsDelegates: [
                const AppLocalizationsDelegate(),
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.getSupportedLocales(),
              locale: locale,
              theme: appTheme,
              home: TableSelectionPage(),
              routes: PageRoutes().routes(),
            );
          },
        ),
      ),
    );
  }
}
