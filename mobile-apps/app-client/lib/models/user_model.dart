// Fichier: lib/models/user_model.dart (Version Corrigée)

import 'package:equatable/equatable.dart';
// --- IMPORTS NÉCESSAIRES (ADAPTEZ LES CHEMINS) ---
// Garder les imports pour les modèles qui sont *toujours* imbriqués
import 'package:hungerz/models/address_model.dart';
import 'package:hungerz/models/wallet_transaction_model.dart';
// MenuItemModel n'est plus directement importé ici car non imbriqué
// import 'package:votre_app/models/menu_item_model.dart';
// --- FIN IMPORTS ---


// --- SOUS-MODÈLES (Inchangés) ---

class SocialInfo extends Equatable { /* ... Définition inchangée ... */
  final String? id;
  final String? email;
  final String? name;

  const SocialInfo({this.id, this.email, this.name});

  factory SocialInfo.fromJson(Map<String, dynamic> json) {
    return SocialInfo(
      id: json['id'] as String?,
      email: json['email'] as String?,
      name: json['name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'email': email, 'name': name,};

  SocialInfo copyWith({ String? id, String? email, String? name}) => SocialInfo(
      id: id ?? this.id, email: email ?? this.email, name: name ?? this.name);

  @override
  List<Object?> get props => [id, email, name];
}
class UserSocial extends Equatable { /* ... Définition inchangée ... */
  final SocialInfo? google;
  final SocialInfo? facebook;

  const UserSocial({this.google, this.facebook});

  factory UserSocial.fromJson(Map<String, dynamic> json) {
    return UserSocial(
      google: json['google'] == null ? null : SocialInfo.fromJson(json['google']),
      facebook: json['facebook'] == null ? null : SocialInfo.fromJson(json['facebook']),
    );
  }

  Map<String, dynamic> toJson() => {'google': google?.toJson(), 'facebook': facebook?.toJson()};

  UserSocial copyWith({ SocialInfo? google, SocialInfo? facebook }) => UserSocial(
      google: google ?? this.google, facebook: facebook ?? this.facebook);

  @override
  List<Object?> get props => [google, facebook];
}
class Wallet extends Equatable { /* ... Définition inchangée ... */
  final double? balance;
  final List<WalletTransactionModel>? transactions; // Utilise WalletTransactionModel importé

  const Wallet({this.balance, this.transactions});

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      transactions: (json['transactions'] as List<dynamic>?)
          ?.map((e) => WalletTransactionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

   Map<String, dynamic> toJson() => {
        'balance': balance,
        'transactions': transactions?.map((e) => e.toJson()).toList(),
      };

  Wallet copyWith({ double? balance, List<WalletTransactionModel>? transactions}) => Wallet(
      balance: balance ?? this.balance, transactions: transactions ?? this.transactions);

  @override
  List<Object?> get props => [balance, transactions];
}
class DietaryProfile extends Equatable { /* ... Définition inchangée ... */
  final bool? vegetarian;
  final bool? vegan;
  final bool? glutenFree;
  final bool? dairyFree;

  const DietaryProfile({ this.vegetarian, this.vegan, this.glutenFree, this.dairyFree });

  factory DietaryProfile.fromJson(Map<String, dynamic> json) {
    return DietaryProfile(
      vegetarian: json['vegetarian'] as bool? ?? false,
      vegan: json['vegan'] as bool? ?? false,
      glutenFree: json['glutenFree'] as bool? ?? false,
      dairyFree: json['dairyFree'] as bool? ?? false, // Schéma original n'avait pas dairyFree, ajouté ici
    );
  }

   Map<String, dynamic> toJson() => {
        'vegetarian': vegetarian, 'vegan': vegan, 'glutenFree': glutenFree, 'dairyFree': dairyFree,
      };

  DietaryProfile copyWith({ bool? vegetarian, bool? vegan, bool? glutenFree, bool? dairyFree}) => DietaryProfile(
      vegetarian: vegetarian ?? this.vegetarian, vegan: vegan ?? this.vegan, glutenFree: glutenFree ?? this.glutenFree, dairyFree: dairyFree ?? this.dairyFree);

  @override
  List<Object?> get props => [vegetarian, vegan, glutenFree, dairyFree];
}
class HealthProfile extends Equatable { /* ... Définition inchangée ... */
    final bool? lowCarb;
    final bool? lowFat;
    final bool? lowSugar;
    final bool? lowSodium;

  const HealthProfile({ this.lowCarb, this.lowFat, this.lowSugar, this.lowSodium });

  factory HealthProfile.fromJson(Map<String, dynamic> json) {
    return HealthProfile(
      lowCarb: json['low_carb'] as bool? ?? false,
      lowFat: json['low_fat'] as bool? ?? false,
      lowSugar: json['low_sugar'] as bool? ?? false,
      lowSodium: json['low_sodium'] as bool? ?? false,
    );
  }

   Map<String, dynamic> toJson() => {
        'low_carb': lowCarb, 'low_fat': lowFat, 'low_sugar': lowSugar, 'low_sodium': lowSodium,
      };

  HealthProfile copyWith({ bool? lowCarb, bool? lowFat, bool? lowSugar, bool? lowSodium}) => HealthProfile(
      lowCarb: lowCarb ?? this.lowCarb, lowFat: lowFat ?? this.lowFat, lowSugar: lowSugar ?? this.lowSugar, lowSodium: lowSodium ?? this.lowSodium);

  @override
  List<Object?> get props => [lowCarb, lowFat, lowSugar, lowSodium];
}
class CfParams extends Equatable { /* ... Définition inchangée ... */
    final List<double>? w;
    final double? b;
    final DateTime? lastTrained;

  const CfParams({this.w, this.b, this.lastTrained});

  factory CfParams.fromJson(Map<String, dynamic> json) {
    return CfParams(
      w: (json['w'] as List<dynamic>?)?.map((e) => (e as num).toDouble()).toList(),
      b: (json['b'] as num?)?.toDouble() ?? 0.0,
      lastTrained: json['lastTrained'] == null ? null : DateTime.tryParse(json['lastTrained'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'w': w, 'b': b, 'lastTrained': lastTrained?.toIso8601String(),
      };

  CfParams copyWith({ List<double>? w, double? b, DateTime? lastTrained}) => CfParams(
      w: w ?? this.w, b: b ?? this.b, lastTrained: lastTrained ?? this.lastTrained);

  @override
  List<Object?> get props => [w, b, lastTrained];
}

// --- CLASSE PRINCIPALE USERMODEL (Champs favoris/recommandations modifiés) ---

class UserModel extends Equatable {
  final String? id;
  final String? fullName;
  final String? email;
  final String mobileNumber; // Requis
  final String? countryCode;
  final String? profileImage;
  final bool? isVerified;
  final bool? isMobileVerified;
  final bool? isAdmin;
  final bool? isRestaurantOwner;
  final String? deviceToken;
  final String? language;
  final UserSocial? social;
  final List<AddressModel>? addresses;
  final Wallet? wallet;
  // --- REVERT MODIFICATION ICI ---
  final List<String>? favorites; // <- Type revenu à List<String>
  // --- FIN REVERT ---
  final String? stripeCustomerId;
  final DietaryProfile? dietaryProfile;
  final HealthProfile? healthProfile;
  final int? matrixIndex;
  final CfParams? cfParams;
  // --- REVERT MODIFICATION ICI ---
  final List<String>? recommandations; // <- Type revenu à List<String>
  // --- FIN REVERT ---
  final DateTime? createdAt;
  final DateTime? updatedAt;


  const UserModel({
    this.id,
    this.fullName,
    this.email,
    required this.mobileNumber,
    this.countryCode,
    this.profileImage,
    this.isVerified,
    this.isMobileVerified,
    this.isAdmin,
    this.isRestaurantOwner,
    this.deviceToken,
    this.language,
    this.social,
    this.addresses,
    this.wallet,
    this.favorites, // Modifié
    this.stripeCustomerId,
    this.dietaryProfile,
    this.healthProfile,
    this.matrixIndex,
    this.cfParams,
    this.recommandations, // Modifié
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Helper pour parser les listes d'IDs String (peut être null)
    List<String>? parseStringList(dynamic jsonList) {
        if (jsonList is List) {
            // Convertit chaque élément en String (au cas où ce seraient des ObjectId ou autres)
            return jsonList.map((e) => e.toString()).toList();
        }
        return null;
    }
     // Helper pour parser les adresses (reste le même)
     List<AddressModel>? parseAddressList(dynamic jsonList) {
        if (jsonList is List) {
            return jsonList
                .where((e) => e is Map<String, dynamic>)
                .map((e) => AddressModel.fromJson(e as Map<String, dynamic>))
                .toList();
        }
        return null;
    }

    return UserModel(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      fullName: json['fullName'] as String?,
      email: json['email'] as String?,
      mobileNumber: json['mobileNumber'] as String, // Requis
      countryCode: json['countryCode'] as String? ?? '+213',
      profileImage: json['profileImage'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
      isMobileVerified: json['isMobileVerified'] as bool? ?? false,
      isAdmin: json['isAdmin'] as bool? ?? false,
      isRestaurantOwner: json['isRestaurantOwner'] as bool? ?? false,
      deviceToken: json['deviceToken'] as String?,
      language: json['language'] as String? ?? 'en',
      social: json['social'] == null ? null : UserSocial.fromJson(json['social']),
      addresses: parseAddressList(json['addresses']),
      wallet: json['wallet'] == null ? null : Wallet.fromJson(json['wallet']),
      // --- REVERT MODIFICATION fromJson ---
      favorites: parseStringList(json['favorites']), // Utilise le helper pour parser les IDs String
      // --- FIN REVERT ---
      stripeCustomerId: json['stripeCustomerId'] as String?,
      dietaryProfile: json['dietaryProfile'] == null ? null : DietaryProfile.fromJson(json['dietaryProfile']),
      healthProfile: json['HealthProfile'] == null ? null : HealthProfile.fromJson(json['HealthProfile']),
      matrixIndex: (json['matrixIndex'] as num?)?.toInt(),
      cfParams: json['cfParams'] == null ? null : CfParams.fromJson(json['cfParams']),
      // --- REVERT MODIFICATION fromJson ---
      recommandations: parseStringList(json['recommandations']), // Utilise le helper pour parser les IDs String
      // --- FIN REVERT ---
      createdAt: json['createdAt'] == null ? null : DateTime.tryParse(json['createdAt'].toString()),
      updatedAt: json['updatedAt'] == null ? null : DateTime.tryParse(json['updatedAt'].toString()),
    );
  }

   Map<String, dynamic> toJson() {
    // Assurez-vous que TOUS les champs sont inclus ici
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'mobileNumber': mobileNumber,
      'countryCode': countryCode,
      'profileImage': profileImage,
      'isVerified': isVerified,
      'isMobileVerified': isMobileVerified,
      'isAdmin': isAdmin,
      'isRestaurantOwner': isRestaurantOwner,
      'deviceToken': deviceToken,
      'language': language,
      'social': social?.toJson(),
      'addresses': addresses?.map((e) => e.toJson()).toList(),
      'wallet': wallet?.toJson(),
      // --- REVERT MODIFICATION toJson ---
      'favorites': favorites, // Directement la liste de String
      // --- FIN REVERT ---
      'stripeCustomerId': stripeCustomerId,
      'dietaryProfile': dietaryProfile?.toJson(),
      'HealthProfile': healthProfile?.toJson(), // Clé originale
      'matrixIndex': matrixIndex,
      'cfParams': cfParams?.toJson(),
      // --- REVERT MODIFICATION toJson ---
      'recommandations': recommandations, // Directement la liste de String
      // --- FIN REVERT ---
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

   // Revert copyWith pour favorites/recommandations
   UserModel copyWith({
    String? id, String? fullName, String? email, String? mobileNumber,
    String? countryCode, String? profileImage, bool? isVerified,
    bool? isMobileVerified, bool? isAdmin, bool? isRestaurantOwner,
    String? deviceToken, String? language, UserSocial? social,
    List<AddressModel>? addresses, Wallet? wallet,
    List<String>? favorites, // <-- MODIFIÉ: List<String>?
    String? stripeCustomerId, DietaryProfile? dietaryProfile, HealthProfile? healthProfile,
    int? matrixIndex, CfParams? cfParams,
    List<String>? recommandations, // <-- MODIFIÉ: List<String>?
    DateTime? createdAt, DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      countryCode: countryCode ?? this.countryCode,
      profileImage: profileImage ?? this.profileImage,
      isVerified: isVerified ?? this.isVerified,
      isMobileVerified: isMobileVerified ?? this.isMobileVerified,
      isAdmin: isAdmin ?? this.isAdmin,
      isRestaurantOwner: isRestaurantOwner ?? this.isRestaurantOwner,
      deviceToken: deviceToken ?? this.deviceToken,
      language: language ?? this.language,
      social: social ?? this.social,
      addresses: addresses ?? this.addresses,
      wallet: wallet ?? this.wallet,
      favorites: favorites ?? this.favorites, // <-- MODIFIÉ
      stripeCustomerId: stripeCustomerId ?? this.stripeCustomerId,
      dietaryProfile: dietaryProfile ?? this.dietaryProfile,
      healthProfile: healthProfile ?? this.healthProfile,
      matrixIndex: matrixIndex ?? this.matrixIndex,
      cfParams: cfParams ?? this.cfParams,
      recommandations: recommandations ?? this.recommandations, // <-- MODIFIÉ
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }


  @override
  List<Object?> get props => [ // Revert props
        id, fullName, email, mobileNumber, countryCode, profileImage, isVerified,
        isMobileVerified, isAdmin, isRestaurantOwner, deviceToken, language, social,
        addresses, wallet, favorites, stripeCustomerId, dietaryProfile, healthProfile, // <-- MODIFIÉ
        matrixIndex, cfParams, recommandations, createdAt, updatedAt, // <-- MODIFIÉ
      ];

  // Helper inchangé
  bool get needsPhoneNumber => mobileNumber.isEmpty;

}