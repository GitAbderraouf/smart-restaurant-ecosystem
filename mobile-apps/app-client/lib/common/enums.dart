

enum AddressType { home, office, other }

enum DeliveryMethod { delivery, takeAway }


enum PaymentMethod { wallet, cash, card }

String addressTypeToString(AddressType type) {
   // Assurez-vous d'importer Locales
  switch (type) {
    case AddressType.home: return 'Home';
    case AddressType.office: return 'Office';
    case AddressType.other: return 'Other';
  }
}

// Helper pour obtenir le nom affichable (optionnel)
