// models/unpaid_bill_model.dart

// Modèle pour un article détaillé dans la session/facture
class BillItemDetail {
  final String menuItemId;
  final String name;
  final double? price; // Le prix pourrait être nul si non trouvé, à gérer dans l'UI
  final String? image; // L'image pourrait être nulle
  final int quantity;

  BillItemDetail({
    required this.menuItemId,
    required this.name,
    this.price,
    this.image,
    required this.quantity,
  });

  factory BillItemDetail.fromJson(Map<String, dynamic> json) {
    // Cette factory suppose que 'menuItem' est l'objet populé
    // et que 'quantity' est au même niveau que 'menuItem' dans la structure
    // de l'item de la commande originale.
    // Adaptez si la structure de 'item' dans 'Order' est différente.

    Map<String, dynamic>? menuItemData = json['menuItem'] as Map<String, dynamic>?; // Si menuItem est l'objet populé
    if (menuItemData == null && json.containsKey('menuItemId')) { // Fallback si menuItem n'est pas populé mais on a l'ID et les autres infos
        menuItemData = json; // On suppose que name, price, image sont au même niveau que menuItemId
    }


    return BillItemDetail(
      menuItemId: (menuItemData?['_id'] ?? menuItemData?['menuItemId'] ?? json['menuItemId']) as String,
      name: (menuItemData?['name'] ?? 'Plat inconnu') as String,
      price: (menuItemData?['price'] as num?)?.toDouble(),
      image: menuItemData?['image'] as String?,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
    );
  }
}

// Modèle pour les détails de la session de table (révisé)
class BillTableSessionDetails {
  final String id;
  final String tableDisplayName; // Nom ou numéro de la table
  final DateTime startTime;
  final List<BillItemDetail> items; // Liste d'objets structurés pour les articles

  BillTableSessionDetails({
    required this.id,
    required this.tableDisplayName,
    required this.startTime,
    required this.items,
  });

  factory BillTableSessionDetails.fromJson(Map<String, dynamic> json) {
    String tableName = 'Table Inconnue';
    if (json['tableId'] is Map<String, dynamic>) {
      tableName = (json['tableId']['name'] ?? json['tableId']['number'] ?? 'Table Inconnue').toString();
    } else if (json['tableId'] is String) {
      tableName = json['tableId']; // Si c'est juste un ID non populé, mais ce n'est pas idéal
    }

    List<BillItemDetail> sessionItems = [];
    if (json['orders'] is List) {
      for (var order in (json['orders'] as List<dynamic>)) {
        if (order is Map<String, dynamic> && order['items'] is List) {
          for (var itemData in (order['items'] as List<dynamic>)) {
            if (itemData is Map<String, dynamic>) {
              sessionItems.add(BillItemDetail.fromJson(itemData));
            }
          }
        }
      }
    }

    return BillTableSessionDetails(
      id: json['_id'] ?? json['id'] as String,
      tableDisplayName: tableName,
      startTime: DateTime.parse(json['startTime'] as String),
      items: sessionItems,
    );
  }
}

// Modèle principal pour la facture impayée (inchangé, mais utilise BillTableSessionDetails révisé)
class UnpaidBillModel {
  final String id;
  final double total;
  final String paymentStatus;
  final BillTableSessionDetails tableSessionDetails;

  UnpaidBillModel({
    required this.id,
    required this.total,
    required this.paymentStatus,
    required this.tableSessionDetails,
  });

  factory UnpaidBillModel.fromJson(Map<String, dynamic> json) {
    return UnpaidBillModel(
      id: json['_id'] ?? json['id'] as String,
      total: (json['total'] as num).toDouble(),
      paymentStatus: json['paymentStatus'] as String,
      tableSessionDetails: BillTableSessionDetails.fromJson(json['tableSessionId'] as Map<String, dynamic>),
    );
  }
}