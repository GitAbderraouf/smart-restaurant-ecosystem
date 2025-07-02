import 'dart:async';
import 'package:flutter/material.dart';
//import '../Models/bill.dart'; // Assurez-vous que ce modèle existe si vous l'utilisez ailleurs (non utilisé dans le reset direct)
import '../Models/menu_item.dart';
import '../Services/api_service.dart';
import '../Services/socket_service.dart';
import '../Pages/home_page.dart'; // For ItemCategory

class HomePageViewModel extends ChangeNotifier {
  final ApiService _apiService;
  final SocketService _socketService;

  HomePageViewModel(this._apiService, this._socketService) {
    // Initialize state from services
    _socketConnected = _socketService.isConnected;
    _currentSessionId = _socketService.sessionId;
    _tableId = _socketService.tableId; // Store initial tableId

    // Listen to socket events
    _listenToSocketEvents();

    // Fetch initial category
    if (foodCategories.isNotEmpty && foodCategories[0].name != null) {
      fetchMenuItems(foodCategories[0].name!);
    } else {
      _isLoading = false;
      _fetchErrorMessage = "No categories defined.";
      notifyListeners();
    }
  }

  // --- State Variables ---
  Map<String, List<MenuItem>> _cachedItems = {};
  bool _isLoading = true;
  String? _fetchErrorMessage;
  int _orderingIndex = 0;
  int _currentIndex = 0; // Category index
  String? _currentlyFetchingCategory;

  // Socket/Session related state
  bool _socketConnected = false;
  String? _socketErrorMsg;
  String? _currentSessionId;
  String? _tableId; // Keep track of table ID
  String? _customerName; // Added for customer name
  StreamSubscription? _connectionSubscription;
  StreamSubscription? _errorSubscription;
  StreamSubscription? _sessionStartSubscription; // Not used in the provided code, but declared
  StreamSubscription? _sessionEndSubscription;
  StreamSubscription? _tableRegisteredSubscription; // To update tableId
  StreamSubscription? _cartUpdateSubscription; // For live cart updates

  // final _onTableSessionCartUpdatedController = StreamController<Map<String, dynamic>>.broadcast(); // Pas utilisé directement ici

  // Hardcoded categories (could be fetched too) - Keep accessible
  final List<ItemCategory> foodCategories = [
      ItemCategory('assets/ItemCategory/burger.png', "burgers"),
      ItemCategory('assets/ItemCategory/pizza.png', "pizzas"),
      ItemCategory('assets/ItemCategory/pates.png', "pates"),
      ItemCategory('assets/ItemCategory/kebbabs.png', "kebabs"),
      ItemCategory('assets/ItemCategory/tacos.png', "tacos"),
      ItemCategory('assets/ItemCategory/poulet.png', "poulet"),
      ItemCategory('assets/ItemCategory/healthy.png', "healthy"),
      ItemCategory('assets/ItemCategory/traditional.png', "traditional"),
      ItemCategory('assets/ItemCategory/dessert.png', "dessert"),
      ItemCategory('assets/ItemCategory/sandwitch.jpg', "sandwich"),
  ];

  // --- Getters for UI ---
  bool get isLoading => _isLoading;
  String? get fetchErrorMessage => _fetchErrorMessage;
  int get orderingIndex => _orderingIndex;
  int get currentIndex => _currentIndex;
  bool get socketConnected => _socketConnected;
  bool get isConnecting => _socketService.isConnecting; // Delegate to service
  String? get socketErrorMsg => _socketErrorMsg;
  String? get currentSessionId => _currentSessionId;
  String? get tableId => _tableId ?? _socketService.tableId; // Use service value if local is null
  String? get currentCategoryName => _currentIndex < foodCategories.length ? foodCategories[_currentIndex].name : null;
  String? get customerName => _customerName; // Added getter

  // Derived State Getters
  List<MenuItem> get displayedItems {
    final categoryName = currentCategoryName;
    if (categoryName == null) return [];
    return List<MenuItem>.from(_cachedItems[categoryName] ?? []);
  }

  List<MenuItem> get itemsInCart {
    List<MenuItem> items = [];
    _cachedItems.values.forEach((categoryItems) {
      items.addAll(categoryItems.where((item) => item.count > 0));
    });
     final itemIds = items.map((item) => item.id).toSet();
     items.retainWhere((item) => itemIds.remove(item.id));
    return items;
  }

  int get totalItemsInCart => itemsInCart.fold(0, (sum, item) => sum + item.count);

  double get totalAmountCart => itemsInCart.fold(0.0, (sum, item) => sum + (item.price * item.count));

  bool get isCartSelected => totalItemsInCart > 0;

  // Stream<Map<String, dynamic>> get onTableSessionCartUpdated => _onTableSessionCartUpdatedController.stream; // Pas utilisé

  // --- Public Methods (Actions) ---

  void changeCategory(int index) {
    if (index != _currentIndex && index >= 0 && index < foodCategories.length) {
       _currentIndex = index;
       final categoryName = foodCategories[index].name;
       if (categoryName != null) {
           fetchMenuItems(categoryName); 
       } else {
           _isLoading = false;
           _fetchErrorMessage = "Selected category is invalid.";
           notifyListeners();
       }
    }
  }

  void setOrderingIndex(int index) {
    if (index != _orderingIndex) {
      _orderingIndex = index;
      notifyListeners();
    }
  }

  Future<void> fetchMenuItems(String categoryName) async {
    _isLoading = true;
    _fetchErrorMessage = null;
    _currentlyFetchingCategory = categoryName;
    notifyListeners(); 

    try {
      final items = await _apiService.getMenuItemsByCategory(categoryName);
      if (categoryName == _currentlyFetchingCategory && _cachedItems.containsKey(categoryName)) {
         final Map<String, int> previousCounts = {
            for (var item in _cachedItems[categoryName]!) item.id: item.count
         };
         for (var fetchedItem in items) {
            fetchedItem.count = previousCounts[fetchedItem.id] ?? 0; 
            fetchedItem.isSelected = fetchedItem.count > 0;
         }
      } else if (categoryName == _currentlyFetchingCategory) {
           for (var fetchedItem in items) {
               fetchedItem.count = 0;
               fetchedItem.isSelected = false;
           }
      }

      if (categoryName == _currentlyFetchingCategory) {
        _cachedItems[categoryName] = items; 
        _isLoading = false;
        _fetchErrorMessage = null;
      }
    } catch (e) {
      if (categoryName == _currentlyFetchingCategory) { 
        _fetchErrorMessage = "Failed to load items. ${e.toString()}";
        _isLoading = false;
        _cachedItems.remove(categoryName); 
      }
    } finally {
       if (categoryName == _currentlyFetchingCategory) {
           notifyListeners(); 
       }
    }
  }

  void updateItemCount(MenuItem item, int change) {
      if (_cachedItems.containsKey(item.category)) {
          var categoryList = _cachedItems[item.category]!;
          int itemIndex = categoryList.indexWhere((i) => i.id == item.id);
          if (itemIndex != -1) {
              int newCount = categoryList[itemIndex].count + change;
              if (newCount >= 0) { 
                 categoryList[itemIndex].count = newCount;
                 categoryList[itemIndex].isSelected = newCount > 0;
                 notifyListeners(); 
              }
          }
      } else {
          print("Warning: Attempted to update item count for category '${item.category}' not found in cache.");
      }
  }

   void incrementItem(MenuItem item) {
       updateItemCount(item, 1);
   }

   void decrementItem(MenuItem item) {
       updateItemCount(item, -1);
   }

   void toggleItemSelection(MenuItem item) {
        if (_cachedItems.containsKey(item.category)) {
            var categoryList = _cachedItems[item.category]!;
            int itemIndex = categoryList.indexWhere((i) => i.id == item.id);
            if (itemIndex != -1) {
                bool wasSelected = categoryList[itemIndex].isSelected;
                categoryList[itemIndex].isSelected = !wasSelected;

                if (categoryList[itemIndex].isSelected) {
                   if (categoryList[itemIndex].count == 0) {
                      categoryList[itemIndex].count = 1;
                   }
                } else {
                   categoryList[itemIndex].count = 0;
                }
                notifyListeners();
            }
        } else {
           print("Warning: Attempted to toggle selection for category '${item.category}' not found in cache.");
        }
   }


  void cancelOrder() { // Cette méthode vide le panier en cours (côté Kiosk)
    _cachedItems.forEach((key, itemList) {
      for (var item in itemList) {
        item.count = 0;
        item.isSelected = false;
      }
    });
    notifyListeners();
  }

  Future<Map<String, dynamic>> placeOrder() async {
      final items = itemsInCart; 
      final String orderType = _orderingIndex == 0 ? 'Take Away' : 'Dine In';
      final String? currentTableId = tableId; 
      final String? currentSessionId = _currentSessionId;

      if (items.isEmpty) {
          throw Exception("Cart is empty.");
      }
      if (currentTableId == null) {
          throw Exception("Table not registered.");
      }
      if (currentSessionId == null && orderType == 'Dine In') { 
          throw Exception("Active session ID is missing for Dine In order.");
      }
      if (!_socketConnected) { 
           throw Exception("Not connected to server.");
      }

      return await _apiService.createOrder(
          items: items,
          orderType: orderType,
          tableId: currentTableId,
          sessionId: currentSessionId, 
      );
  }

   void endCurrentSession() { // Méthode appelée par le Kiosk pour terminer sa session
       if (_currentSessionId == null) {
           _socketErrorMsg = "No active session to end."; 
           notifyListeners();
           return;
       }
       if (!_socketConnected) {
           _socketErrorMsg = "Not connected to server."; 
           notifyListeners();
           return;
       }
       _socketService.endCurrentSession(); // Le SocketService du Kiosk émet 'end_session'
       // La mise à jour de _currentSessionId se fera via le listener _sessionEndSubscription
   }

   Future<void> manualReconnect() async {
      _socketErrorMsg = "Attempting manual reconnect...";
      notifyListeners();
      await _socketService.manualReconnect();
   }

  void setCurrentSessionId(String? id) {
    if (_currentSessionId != id) {
      _currentSessionId = id;
      print("HomePageViewModel: Session ID set to $id");
      notifyListeners();
    }
  }

  void setTableId(String? id) {
    if (_tableId != id) {
      _tableId = id;
      print("HomePageViewModel: Table ID set to $id");
      notifyListeners();
    }
  }

  void setCustomerName(String? name) {
    if (_customerName != name) {
      _customerName = name;
      print("HomePageViewModel: Customer name set to $name");
      notifyListeners();
    }
  }

  void _listenToSocketEvents() {
    _connectionSubscription = _socketService.onConnected.listen((isConnected) {
      _socketConnected = isConnected;
      if (!isConnected) {
        _socketErrorMsg = "Disconnected. Attempting to reconnect...";
      } else {
        _socketErrorMsg = null; // Effacer l'erreur si reconnecté
      }
      notifyListeners();
    });

    _errorSubscription = _socketService.onError.listen((error) {
      _socketErrorMsg = error.toString();
      _socketConnected = false; 
      notifyListeners();
    });

    _tableRegisteredSubscription = _socketService.onTableRegistered.listen((data) {
      print("HomePageViewModel: Table registered event received: $data");
      if (data['tableId'] != null) {
        setTableId(data['tableId'] as String?); 
      }
    });

    _sessionEndSubscription = _socketService.onSessionEnded.listen((data) {
      print("HomePageViewModel: Session ended event received: $data");
      _currentSessionId = null;
      _customerName = null;
      cancelOrder(); 
      _socketErrorMsg = null; // MODIFIÉ: Effacer les messages d'erreur socket
      print("HomePageViewModel: ViewModel reset by onSessionEnded. Waiting for new QR scan. Kiosk Table ID: $tableId");
      notifyListeners();
    });

    _cartUpdateSubscription = _socketService.onTableSessionCartUpdated.listen((cartData) {
      print("HomePageViewModel: Cart update received: $cartData");
      if (cartData['sessionId'] == _currentSessionId && cartData['items'] != null) {
        syncCartFromServer(List<Map<String, dynamic>>.from(cartData['items']));
      }
    });
  }

  void syncCartFromServer(List<Map<String, dynamic>> serverItems) {
    print("HomePageViewModel: Syncing cart from server with ${serverItems.length} items.");
    _cachedItems.forEach((category, itemList) {
      for (var localItem in itemList) {
        localItem.count = 0;
        localItem.isSelected = false;
      }
    });

    for (var serverItem in serverItems) {
      final String? menuItemId = serverItem['menuItemId'] as String?;
      final int quantity = (serverItem['quantity'] as num?)?.toInt() ?? 0;

      if (menuItemId != null) {
        MenuItem? foundItem;
        String? foundCategory;

        for (var entry in _cachedItems.entries) {
          try {
            foundItem = entry.value.firstWhere((item) => item.id == menuItemId);
            foundCategory = entry.key;
            break; 
          } catch (e) {
            // non trouvé
          }
        }

        if (foundItem != null && foundCategory != null) {
          if (quantity > 0) {
            foundItem.count = quantity;
            foundItem.isSelected = true;
          } else {
            foundItem.count = 0; 
            foundItem.isSelected = false;
          }
        } else {
          print("HomePageViewModel: syncCartFromServer - MenuItem with ID '$menuItemId' not found in local cache.");
        }
      }
    }
    _updateCartStatus(); 
  }

  void _updateCartStatus() {
    notifyListeners();
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    _errorSubscription?.cancel();
    _sessionStartSubscription?.cancel(); // Était déjà là, même si non initialisé dans listenToSocketEvents
    _sessionEndSubscription?.cancel();
    _tableRegisteredSubscription?.cancel();
    _cartUpdateSubscription?.cancel();
    // _onTableSessionCartUpdatedController.close(); // Pas utilisé
    super.dispose();
  }
}