import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hungerz/Components/dish_card.dart';
import 'package:hungerz/Components/reccomanded_dish_card.dart';
import 'package:hungerz/HomeOrderAccount/Home/Models/category.dart';
import 'package:hungerz/Pages/address_search_page.dart';
import 'package:hungerz/Pages/categorie_dish_screen.dart';
import 'package:hungerz/common/enums.dart';
import 'package:hungerz/cubits/location_cubit/location_cubit.dart';
import 'package:hungerz/cubits/profile_cubit/profile_cubit.dart';
import 'package:hungerz/cubits/table_session_cubit/table_session_cubit.dart';
import 'package:hungerz/models/address_model.dart';
import 'package:hungerz/models/menu_item_model.dart';

import 'package:hungerz/Routes/routes.dart';
import 'package:hungerz/Themes/colors.dart';

import 'package:hungerz/cubits/cart_cubit/cart_cubit.dart';
import 'package:hungerz/cubits/dishes_cubit/dishes_cubit.dart';
import 'package:hungerz/models/place_model.dart';

import 'booking_row.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Home();
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  void initState() {
    super.initState();
    context.read<DishesCubit>().fetchDishes();
    context.read<LocationCubit>().getCurrentLocation();
  }

  @override
  Widget build(BuildContext context) {
    final profileState = context.read<ProfileCubit>().state;

    return BlocListener<TableSessionCubit, TableSessionState>(
      listener: (context, state) {
        if (state is TableSessionJoined) {
          // Le pop de la caméra est déjà géré par le Cubit.
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline_rounded,
                      color: Colors.white),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Connexion à la table réussie !',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color.fromRGBO(0, 153, 70,
                  1), // Use the theme's green color (make sure _orderGreen is defined in your state)
              behavior: SnackBarBehavior.floating, // Make it float
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0), // Rounded corners
              ),
              margin: EdgeInsets.only(
                // Position near top-center
                bottom: 50.0,
                // top: MediaQuery.of(context).size.height -
                //     500, // Adjust vertical position from bottom
                left:
                    MediaQuery.of(context).size.width * 0.2, // Indent from left
                right: MediaQuery.of(context).size.width *
                    0.2, // Indent from right
              ),
              duration: const Duration(seconds: 3), // Slightly longer duration
              elevation: 6.0,
            ),
          );
        } else if (state is TableSessionEnded) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline_rounded,
                      color: Colors.white),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Session à la table terminée.',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors
                  .blue, // Use the theme's green color (make sure _orderGreen is defined in your state)
              behavior: SnackBarBehavior.floating, // Make it float
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0), // Rounded corners
              ),
              margin: EdgeInsets.only(
                // Position near top-center
                bottom: 50.0,
                // top: MediaQuery.of(context).size.height -
                //     500, // Adjust vertical position from bottom
                left:
                    MediaQuery.of(context).size.width * 0.2, // Indent from left
                right: MediaQuery.of(context).size.width *
                    0.2, // Indent from right
              ),
              duration: const Duration(seconds: 3), // Slightly longer duration
              elevation: 6.0,
            ),
          );
          // Vous pouvez ajouter ici une logique de navigation si nécessaire après la fin de session
          // par exemple, si l'utilisateur était sur ViewCart, le ramener à l'accueil.
        } else if (state is TableSessionError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur : ${state.message}'),
              backgroundColor: Colors.red, // Personnalisez
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor:
              Theme.of(context).scaffoldBackgroundColor, // Pour fond blanc
          elevation: 0, // Pas d'ombre
          // leading: IconButton(...) // Si vous avez un Drawer
          titleSpacing: 16.0, // Espace à gauche du titre
          title: InkWell(
            onTap: () async {
              // Rendre async pour attendre le retour
              print("HomePage AppBar: Navigation vers AddressSearchPage");
              final result = await Navigator.push<Place?>(
                // Attendre un résultat Place ou null
                context,
                MaterialPageRoute(builder: (_) => AddressSearchPage()),
              );

              // --- Traiter le résultat retourné par AddressSearchPage ---
              if (result != null && context.mounted) {
                // L'utilisateur a sélectionné une adresse (cherchée OU actuelle)
                print("HomePage: Adresse sélectionnée reçue: ${result.name}");
                // Créer une AddressModel temporaire ou complète à partir de Place
                // Vérifier si lat/lng sont présents !
                if (result.latitude != null && result.longitude != null) {
                  AddressModel selectedAddrModel = AddressModel(
                    // Ces champs sont nécessaires pour l'affichage et l'état
                    label: result
                        .name, // Utiliser le nom du lieu comme label par défaut
                    address: result.address, // Adresse formatée
                    latitude: result.latitude!,
                    longitude: result.longitude!,
                    // Les autres champs peuvent être null ou avoir des valeurs par défaut
                    type: AddressType.other.name, // Ou déduire ?
                    placeId: result.id,
                  );
                  // Demander à ProfileCubit de définir cette adresse comme active
                  context
                      .read<ProfileCubit>()
                      .setActiveDisplayAddress(selectedAddrModel);
                } else {
                  print(
                      "HomePage: Coordonnées manquantes dans le résultat Place, ne peut pas définir comme active.");
                  // Afficher une erreur ?
                }
              } else if (context.mounted) {
                // L'utilisateur est revenu sans sélection (ex: bouton retour)
                // Optionnel: remettre à la localisation GPS ? Ou ne rien faire ?
                // Pour l'instant, on ne fait rien, l'adresse active précédente reste.
                print(
                    "HomePage: Retour depuis AddressSearchPage sans sélection.");
                // Pour forcer le retour au GPS:
                // context.read<ProfileCubit>().setActiveDisplayAddress(null);
              }
              // --------------------------------------------------------
            },
            // Le reste de l'UI (Row, Icon, Column...)
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_on_outlined, /*...*/
                ),
                SizedBox(width: 8),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // --- Écoute ProfileCubit pour le Label/Titre ---
                      BlocBuilder<ProfileCubit, ProfileState>(
                          buildWhen: (prev, curr) =>
                              prev.runtimeType != curr.runtimeType ||
                              (prev is ProfileLoaded &&
                                  curr is ProfileLoaded &&
                                  prev.activeDisplayAddress !=
                                      curr.activeDisplayAddress),
                          builder: (context, profileState) {
                            String topLabel = "Adresse Actuelle";
                            if (profileState is ProfileLoaded &&
                                profileState.activeDisplayAddress != null) {
                              // Si une adresse active existe, utiliser son label comme titre principal
                              topLabel =
                                  profileState.activeDisplayAddress!.label;
                            }
                            return Text(
                              topLabel,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                      fontSize: 11, color: Colors.grey[500]),
                            );
                          }),
                      SizedBox(height: 1),
                      // --- Écoute ProfileCubit pour l'adresse principale, fallback sur LocationCubit ---
                      BlocBuilder<ProfileCubit, ProfileState>(
                        // Reconstruire si l'état change ou si l'adresse active change
                        buildWhen: (prev, curr) =>
                            prev.runtimeType != curr.runtimeType ||
                            (prev is ProfileLoaded &&
                                curr is ProfileLoaded &&
                                prev.activeDisplayAddress !=
                                    curr.activeDisplayAddress),
                        builder: (context, profileState) {
                          // 1. Essayer d'afficher l'adresse active depuis ProfileCubit
                          if (profileState is ProfileLoaded &&
                              profileState.activeDisplayAddress != null) {
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                    child: Text(
                                        profileState
                                            .activeDisplayAddress!.address,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                                fontWeight: FontWeight.bold),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1)),
                                Icon(Icons.arrow_drop_down,
                                    size: 20, color: Colors.grey[700]),
                              ],
                            );
                          } else {
                            // 2. Fallback: Afficher l'état de LocationCubit
                            return BlocBuilder<LocationCubit, LocationState>(
                              builder: (context, locationState) {
                                // ... (Logique existante pour afficher l'état de LocationCubit : Loading, Loaded, Error...) ...
                                String displayText = "Définir l'adresse";
                                if (locationState is LocationLoaded)
                                  displayText = locationState.simpleAddress;
                                // ... autres états ...
                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                        child: Text(displayText,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  fontWeight:
                                                      FontWeight.bold, /*...*/
                                                ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1)),
                                    Icon(Icons.arrow_drop_down,
                                        size: 20, color: Colors.grey[700]),
                                  ],
                                );
                              },
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            Padding(
              padding: const EdgeInsets.only(right: 6.0),
              child: FadedScaleAnimation(
                fadeDuration: Duration(milliseconds: 200),
                child: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    /*.......*/
                  },
                ),
              ),
            ),
            BlocBuilder<CartCubit, CartState>(
              // Ce BlocBuilder écoute les états émis par CartCubit
              builder: (context, cartState) {
                int itemCount = 0;
                if (cartState is CartUpdated) {
                  // Utilise le getter pratique défini dans CartUpdated
                  itemCount = cartState.totalItemsQuantity;
                }
                return IconButton(
                  icon: Badge(
                    backgroundColor: kMainColor,
                    label: Text('$itemCount'),
                    isLabelVisible: itemCount > 0,
                    child: Icon(Icons.shopping_cart_outlined),
                  ),
                  tooltip: 'Voir le panier',
                  onPressed: () {
                    Navigator.pushNamed(context,
                        PageRoutes.viewCart); // Navigue vers la page panier
                  },
                );
              },
            ),
          ],
        ),
        body: BlocBuilder<DishesCubit, DishesState>(builder: (context, state) {
          if (state is DishesInitial || state is DishesLoading) {
            return Center(child: CircularProgressIndicator());
          } else if (state is DishesLoadFailure) {
            return Center(child: Text('Error loading dishes'));
          } else if (state is DishesLoadSuccess) {
            List<MenuItemModel> allDishes = state.dishes;
            List<MenuItemModel> recommendedDishes = [];
            List<MenuItemModel> popularDishes = [];
            List<String>? recommendedIds;
            if (profileState is ProfileLoaded) {
              recommendedIds =
                  profileState.user.recommandations; // Peut être null ?
            }
            if (recommendedIds != null && recommendedIds.isNotEmpty) {
              final recommendedIdsSet = Set<String>.from(recommendedIds);
              recommendedDishes = allDishes
                  .where((dish) => recommendedIdsSet.contains(dish.id))
                  .toList();
              popularDishes =
                  allDishes.where((dish) => dish.isPopular!).toList();
            }

            return ListView(
              children: <Widget>[
                SizedBox(
                  height: 20,
                ),
                // Padding(
                //   padding: EdgeInsets.all(20.0),
                //   child: Text(
                //     AppLocalizations.of(context)!.homeText1!,
                //     style: Theme.of(context).textTheme.bodyLarge,
                //   ),
                // ),
                Container(
                  height: 150.0,
                  margin: EdgeInsets.only(left: 10),
                  child: ListView.builder(
                      shrinkWrap: true,
                      physics: BouncingScrollPhysics(),
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        return InkWell(
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => CategoryDishesPage(
                                      categoryName: categories[index].title!))),
                          child: Padding(
                            padding: EdgeInsets.only(left: 5),
                            child: Container(
                              height: 100,
                              width: 100,
                              color:
                                  Colors.white, //Theme.of(context).cardColor,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  FadedScaleAnimation(
                                    fadeDuration: Duration(milliseconds: 200),
                                    child: Image.asset(
                                      categories[index].image,
                                      height: 70,
                                      width: 70,
                                    ),
                                  ),
                                  SizedBox(
                                    height: 5.0,
                                  ),
                                  Text(
                                    categories[index].title!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall!
                                        .copyWith(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15.0),
                                  )
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                ),
                SizedBox(
                  height: 18,
                ),
                Padding(
                  padding: EdgeInsets.all(20.0),
                  child: BookingRow(),
                ),
                SizedBox(height: 24),
                Padding(
                  padding: EdgeInsets.only(left: 20, bottom: 15, right: 20),
                  child: Text(
                    "Recommandé pour vous",
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                SizedBox(height: 12),
                Container(
                  margin: EdgeInsets.only(left: 10),
                  height: 230,
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: BouncingScrollPhysics(),
                    scrollDirection: Axis.horizontal, // Défilement horizontal
                    itemCount: recommendedDishes.length,
                    itemBuilder: (context, index) {
                      final dish = recommendedDishes[index];
                      // Utilisez votre widget de carte pour les plats recommandés
                      return RecommendedDishCard(
                          dish: dish); // Assurez-vous que ce widget existe
                    },
                  ),
                ),
                SizedBox(height: 24),
                Padding(
                  padding: EdgeInsets.only(left: 20, bottom: 15, right: 20),
                  child: Text(
                    "Populaires",
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                SizedBox(height: 12),
                Container(
                  margin: EdgeInsets.only(left: 10),
                  height: 230,
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: BouncingScrollPhysics(),
                    scrollDirection: Axis.horizontal, // Défilement horizontal
                    itemCount: popularDishes.length,
                    itemBuilder: (context, index) {
                      final dish = popularDishes[index];
                      // Utilisez votre widget de carte pour les plats recommandés
                      return RecommendedDishCard(
                        dish: dish,
                        showFlameIcon: true,
                      ); // Assurez-vous que ce widget existe
                    },
                  ),
                ),
                SizedBox(height: 24),
                Padding(
                  padding: EdgeInsets.only(left: 20, bottom: 15, right: 20),
                  child: Text(
                    "Nos plats",
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                SizedBox(height: 12),
                Container(
                  margin: EdgeInsets.only(left: 10),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: BouncingScrollPhysics(),
                    scrollDirection: Axis.vertical, // Défilement horizontal
                    itemCount: allDishes.length,
                    itemBuilder: (context, index) {
                      final dish = allDishes[index];
                      // Utilisez votre widget de carte pour les plats recommandés
                      return DishCard(
                          dish: dish); // Assurez-vous que ce widget existe
                    },
                  ),
                ),
              ],
            );
          } else {
            return Center(child: Text('Unknown state'));
          }
        }),
      ),
    );
  }
}
//   Widget quickGrid(BuildContext context, String image) {
//     return GestureDetector(
//       onTap: () {
//         Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) =>
//                   ItemsPage(AppLocalizations.of(context)!.store),
//             ));
//       },
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: <Widget>[
//           Image(
//             image: AssetImage(image),
//             height: 62.5,
//           ),
//           SizedBox(width: 13.3),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: <Widget>[
//                 Text(AppLocalizations.of(context)!.store!,
//                     style: Theme.of(context).textTheme.titleSmall!.copyWith(
//                         color: Theme.of(context).secondaryHeaderColor,
//                         fontWeight: FontWeight.bold)),
//                 SizedBox(height: 8.0),
//                 Text(AppLocalizations.of(context)!.type!,
//                     style: Theme.of(context)
//                         .textTheme
//                         .bodySmall!
//                         .copyWith(color: kLightTextColor, fontSize: 10.0)),
//                 SizedBox(height: 10.3),
//                 Expanded(
//                   child: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: <Widget>[
//                       Icon(
//                         Icons.location_on,
//                         color: kIconColor,
//                         size: 13,
//                       ),
//                       SizedBox(width: 10.0),
//                       Text('5.0 km ',
//                           style: Theme.of(context)
//                               .textTheme
//                               .bodySmall!
//                               .copyWith(
//                                   color: kLightTextColor, fontSize: 10.0)),
//                       Text('| ',
//                           style: Theme.of(context)
//                               .textTheme
//                               .bodySmall!
//                               .copyWith(color: kMainColor, fontSize: 10.0)),
//                       Text(AppLocalizations.of(context)!.storeAddress!,
//                           style: Theme.of(context)
//                               .textTheme
//                               .bodySmall!
//                               .copyWith(
//                                   color: kLightTextColor, fontSize: 10.0)),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
